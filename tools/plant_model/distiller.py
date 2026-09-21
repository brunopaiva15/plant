#!/usr/bin/env python3
"""L'étape 5 : notre student, entraîné sur ce que le teacher a déjà dit.

    python3 distiller.py mesure --dataset ~/plant-data/dataset-v8-indoor \\
        --cache ~/plant-data/bioclip
    python3 distiller.py entrainer --dataset ~/plant-data/dataset-v8-indoor \\
        --cache ~/plant-data/bioclip --sortie ~/plant-data/iris10

Le teacher est passé une fois (§ 20 bis), la porte C est franchie (§ 19), et
le student public a montré ce qu'il ne faut pas faire (§ 19 bis). Ce script
est ce qui reste : un petit réseau qui apprend à rendre les vecteurs déjà
cachés.

## Trois choses que le § 19 bis impose, et qui ne se discutent plus

**1. La perte cosinus seule ne suffit pas.** Le student public affiche 0,748
d'accord moyen avec son teacher et ne garde que 39 % de son top-1. Son cône
s'est refermé — 0,4179 contre 0,2889 — parce que rien, dans une perte
cosinus, ne pousse deux images *différentes* à s'écarter. On ajoute donc dès
la baseline un terme **contrastif** sur les négatifs du lot.

**2. Le cosinus n'est pas le critère d'arrêt.** À 0,80 d'accord, un écart
isotrope ne coûte que 3 % du top-1 ; l'écart réel du student en coûtait 61 %.
Chaque point de contrôle écrit donc un **cache d'embeddings du banc**, que
`voisins.py --embeddings` lit directement. On arrête sur le top-1 par
référence, pas sur la perte.

**3. Le cône se surveille.** `student.py --accord` le rend en une ligne. Un
cône qui se referme pendant l'entraînement est le signal d'alarme, même si
la perte descend.

## La discipline, la même que partout ici

Une recette à la fois (§ 12 de `docs/09`). Le student de départ est
**FastViT `sa12`**, exactement l'architecture du modèle public : si le nôtre
fait mieux que ses 0,3132, c'est la recette qui l'explique et rien d'autre.
MobileNetV4 Hybrid vient après, à recette figée.

Et `mesure` avant d'entraîner : un s/lot mesuré vaut mieux qu'une nuit
perdue, et la VRAM se lit plutôt qu'elle ne s'espère (8 Go, § 2 de
`docs/10`).
"""
from __future__ import annotations

import argparse
import csv
import json
import time
from pathlib import Path

import numpy as np

from bioclip import flux_de_lots, lire_index

DIM = 1024
ENTREE = 224


# --------------------------------------------------------------------------
# Les cibles : ce que le teacher a déjà dit
# --------------------------------------------------------------------------

def paires(dataset: Path, cache: Path, splits: tuple[str, ...] = ('train',)
           ) -> list[tuple[str, str, int]]:
    """(chemin, fragment, ligne) pour les images qui ont une cible cachée.

    Une image sans vecteur de teacher n'a rien à apprendre : elle est
    écartée, pas approchée par un voisin. Le compte des écartées est rendu à
    l'appelant, parce qu'un jeu d'entraînement plus petit qu'annoncé change
    le nombre de pas par époque sans que rien ne le signale.
    """
    index = lire_index(cache)
    sortie = []
    with open(dataset / 'splits.csv', newline='', encoding='utf-8') as f:
        for r in csv.DictReader(f):
            if r['split'] not in splits:
                continue
            chemin = str(dataset / r['path'])
            place = index.get(chemin)
            if place is not None:
                sortie.append((chemin, place[0], place[1]))
    return sortie


def cibles(cache: Path, lot: list[tuple[str, str, int]],
           fragments: dict[str, np.ndarray] | None = None) -> np.ndarray:
    """Les vecteurs du teacher pour ce lot, dans l'ordre reçu.

    `fragments` sert de mémo entre les appels : un fragment fait 16 Mo et un
    lot en touche rarement plus de deux ou trois. Sans lui, chaque lot
    relirait des dizaines de mégaoctets pour en extraire trente-deux lignes.
    """
    memo = {} if fragments is None else fragments
    sortie = np.empty((len(lot), DIM), dtype=np.float32)
    for i, (_, fragment, ligne) in enumerate(lot):
        if fragment not in memo:
            memo[fragment] = np.load(cache / f'{fragment}.npy')
        sortie[i] = memo[fragment][ligne]
    return sortie


# --------------------------------------------------------------------------
# Les pertes
# --------------------------------------------------------------------------

def perte_cosinus(sortie, cible):  # pragma: no cover - demande PyTorch
    """1 − cos(student, teacher), moyennée. Le terme d'alignement."""
    import torch.nn.functional as F
    return (1.0 - F.cosine_similarity(sortie, cible, dim=-1)).mean()


def perte_contrastive(sortie, cible, temperature: float = 0.07):  # pragma: no cover
    """InfoNCE sur les négatifs du lot — le terme qui **écarte**.

    C'est la correction du § 19 bis. Chaque image doit être plus proche de
    *sa* cible que de celle de ses voisines de lot ; sans ce terme, un
    student minimise la perte cosinus en rapprochant tout le monde d'une
    direction moyenne, ce qui referme le cône et détruit la recherche.

    Symétrique image→cible et cible→image : une cible aussi doit reconnaître
    son image. La version à sens unique laisse le student regrouper
    plusieurs images sur une même cible sans être puni.
    """
    import torch
    import torch.nn.functional as F
    s = F.normalize(sortie, dim=-1)
    c = F.normalize(cible, dim=-1)
    logits = s @ c.T / temperature
    vrais = torch.arange(len(s), device=s.device)
    return 0.5 * (F.cross_entropy(logits, vrais) + F.cross_entropy(logits.T, vrais))


def melanger(total: int, graine: int) -> np.ndarray:
    """L'ordre des images d'une époque.

    `splits.csv` est trié par espèce. Sans mélange global, un lot serait
    quasi monospécifique et la contrastive n'aurait que des négatifs de la
    même plante — elle apprendrait alors à séparer ce qu'il faut rapprocher.
    C'est le défaut du § 6.2, avec une conséquence nouvelle.
    """
    ordre = np.arange(total)
    np.random.default_rng(graine).shuffle(ordre)
    return ordre


def etat_du_lot(sortie, cible) -> dict:  # pragma: no cover - demande PyTorch
    """Ce qu'on lit d'un lot : l'accord, et la largeur du cône.

    Le second est le signal d'alarme du § 19 bis. Une perte qui descend
    pendant que le cône se referme annonce un student qui ne saura rien
    retrouver, et c'est invisible sur la seule courbe de perte.
    """
    import torch
    import torch.nn.functional as F
    with torch.no_grad():
        s = F.normalize(sortie, dim=-1)
        accord = F.cosine_similarity(s, F.normalize(cible, dim=-1), dim=-1).mean()
        entre = s @ s.T
        n = len(s)
        cone = (entre.sum() - entre.diagonal().sum()) / max(1, n * (n - 1))
    return {'accord': float(accord), 'cone': float(cone)}


# --------------------------------------------------------------------------
# Le student
# --------------------------------------------------------------------------

def construire(nom: str, dim: int = DIM):  # pragma: no cover - demande timm
    """Le dorsal `timm` et son projecteur vers l'espace du teacher.

    Le projecteur est linéaire et sans biais : il change de repère, il
    n'apprend pas de fonction. Tout ce qui doit être appris l'est par le
    dorsal — un projecteur profond masquerait un dorsal faible, et on
    mesurerait le projecteur.
    """
    try:
        import timm
        import torch.nn as nn
    except ImportError as e:
        raise SystemExit(f'{e}. pip install timm') from e
    dorsal = timm.create_model(nom, pretrained=True, num_classes=0)
    return nn.Sequential(dorsal, nn.Linear(dorsal.num_features, dim, bias=False))


def main() -> int:  # pragma: no cover - demande PyTorch, timm et les images
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('commande', choices=['mesure', 'entrainer'])
    ap.add_argument('--dataset', default='~/plant-data/dataset-v8-indoor')
    ap.add_argument('--cache', default='~/plant-data/bioclip')
    ap.add_argument('--sortie', default='~/plant-data/iris10')
    ap.add_argument('--student', default='fastvit_sa12',
                    help="le dorsal timm ; fastvit_sa12 reprend l'architecture du "
                         'modèle public, ce qui isole la recette')
    ap.add_argument('--batch', type=int, default=64, help='8 Go de VRAM')
    ap.add_argument('--epoques', type=int, default=10)
    ap.add_argument('--taux', type=float, default=1e-3)
    ap.add_argument('--contrastive', type=float, default=1.0,
                    help='poids du terme qui écarte ; 0 reproduit la recette publique')
    ap.add_argument('--demi', action='store_true',
                    help='précision mixte : les convolutions en float16, les pertes et '
                         "les poids en float32. C'est le plus gros levier une fois le "
                         'décodage réparé, et il libère de la VRAM pour un lot plus grand')
    ap.add_argument('--images', type=int, default=0,
                    help="n'entraîner que sur ce nombre d'images ; 0 = toutes. Une "
                         'comparaison de recettes se tranche sur une fraction du jeu, '
                         'pas sur une passe complète')
    ap.add_argument('--fils', type=int, default=6,
                    help='fils de décodage. En série, le décodage tient 83 images/s '
                         "et la carte attend : c'est le défaut du § 2 bis de docs/10, "
                         'et il se reproduit à chaque nouvelle boucle')
    ap.add_argument('--pas', type=int, default=60, help='pas chronométrés par `mesure`')
    ap.add_argument('--graine', type=int, default=20260919)
    args = ap.parse_args()

    dataset, cache = Path(args.dataset).expanduser(), Path(args.cache).expanduser()
    lot_complet = paires(dataset, cache)
    if not lot_complet:
        raise SystemExit(f'aucune image de {dataset} n\'a de vecteur dans {cache}')
    print(f'{len(lot_complet)} images avec une cible cachée')
    if args.images and args.images < len(lot_complet):
        # Le tirage passe par le mélange, donc il reste réparti sur les espèces :
        # prendre les premières lignes de `splits.csv` donnerait le début de
        # l'alphabet (§ 20 bis de docs/14).
        garde = melanger(len(lot_complet), args.graine)[:args.images]
        lot_complet = [lot_complet[i] for i in garde]
        print(f'  restreint à {len(lot_complet)}, tirées au hasard sur tout le jeu')

    import torch
    appareil = 'cuda' if torch.cuda.is_available() else 'cpu'
    modele = construire(args.student).to(appareil)
    parametres = sum(p.numel() for p in modele.parameters())
    print(f'{args.student} — {parametres / 1e6:.1f} M de paramètres, {appareil}')

    if args.commande == 'mesure':
        from student import preparer
        optimiseur = torch.optim.AdamW(modele.parameters(), lr=args.taux)
        # Les pertes restent en float32 : un cosinus et un InfoNCE sur 1 024
        # dimensions perdent leurs petits écarts en float16, et ce sont
        # justement ces écarts qui font le classement (§ 19 bis de docs/14).
        echelle = torch.amp.GradScaler('cuda') if args.demi else None
        if args.demi:
            modele = modele.to(memory_format=torch.channels_last)
        ordre = melanger(len(lot_complet), args.graine)
        # Les lots sont bâtis d'avance, et leurs images décodées pendant que
        # la carte travaille sur le lot précédent. En série, le décodage tient
        # 83 images/s et la carte attend les neuf dixièmes du temps.
        lots = [[lot_complet[i] for i in ordre[d:d + args.batch]]
                for d in range(0, (args.pas + 5) * args.batch, args.batch)]
        lots = [l for l in lots if len(l) == args.batch]
        memo: dict = {}
        debut = None
        for pas, (lot, images) in enumerate(
                flux_de_lots(lots, lambda t: preparer(t[0])[0], args.fils)):
            x = torch.from_numpy(np.stack(images)).to(appareil)
            if args.demi:
                x = x.to(memory_format=torch.channels_last)
            y = torch.from_numpy(cibles(cache, lot, memo)).to(appareil)
            optimiseur.zero_grad()
            with torch.autocast('cuda', dtype=torch.float16, enabled=args.demi):
                sortie = modele(x)
                perte = (perte_cosinus(sortie.float(), y)
                         + args.contrastive * perte_contrastive(sortie.float(), y))
            if echelle is not None:
                echelle.scale(perte).backward()
                echelle.step(optimiseur)
                echelle.update()
            else:
                perte.backward()
                optimiseur.step()
            if pas == 4:                      # les cinq premiers paient la compilation
                if appareil == 'cuda':
                    torch.cuda.synchronize()
                debut = time.perf_counter()
            if pas >= args.pas + 4:
                break
        if appareil == 'cuda':
            torch.cuda.synchronize()
        secondes = time.perf_counter() - debut
        par_pas = secondes / args.pas
        images = par_pas and args.batch / par_pas
        print(f'\n{par_pas * 1000:.0f} ms par lot de {args.batch} — {images:.0f} images/s')
        print(f'une époque de {len(lot_complet)} images : '
              f'{len(lot_complet) / images / 60:.0f} min')
        print(f'{args.epoques} époques : {len(lot_complet) * args.epoques / images / 3600:.1f} h')
        if appareil == 'cuda':
            print(f'VRAM réservée : {torch.cuda.max_memory_allocated() / 2 ** 30:.2f} Gio sur 8')
        return 0

    raise SystemExit("`entrainer` n'est pas encore écrit — lancer `mesure` d'abord, "
                     'et décider du calendrier sur son chiffre')


if __name__ == '__main__':
    raise SystemExit(main())
