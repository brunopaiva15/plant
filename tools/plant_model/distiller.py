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
import math
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


def corpus(datasets: list[Path], cache: Path,
           splits: tuple[str, ...] = ('train',)) -> list[tuple[str, str, int]]:
    """Plusieurs jeux dans un seul lot d'entraînement, sans doublon de chemin.

    La distillation n'a pas besoin d'étiquettes : elle lit un chemin et le
    vecteur que le teacher a rendu pour lui. Deux corpus se concatènent donc
    sans aligner quoi que ce soit — c'est ce qui rend Pl@ntNet-300K utilisable
    tel quel (§ 20 ter de `docs/14`), là où Iris 9 aurait demandé de mapper
    1 081 classes sur 1 569.

    Le garde-fou est le chemin absolu : deux jeux qui se recouvriraient
    entraîneraient deux fois sur les mêmes images, et l'époque durerait plus
    longtemps pour rien.
    """
    vus, sortie = set(), []
    for d in datasets:
        for ligne in paires(d, cache, splits):
            if ligne[0] not in vus:
                vus.add(ligne[0])
                sortie.append(ligne)
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

def taux_du_pas(pas: int, total: int, base: float, calendrier: str = 'constant') -> float:
    """Le taux d'apprentissage au pas global `pas` sur `total`.

    **`constant` est la recette des deux premières passes, et c'est un défaut
    qui n'a jamais été décidé.** Le § 19 nonies de `docs/14` le relève : le top-1
    indoor plafonne en fin de passe pendant que l'outdoor progresse encore, et
    un pas trop grand empêche de gagner les écarts fins là où il ne reste
    qu'eux. Le bras MobileNetV4 l'a confirmé à sa façon : 2,7 fois la capacité,
    une pente plus faible (§ 19 decies).

    `cosinus` descend de `base` à zéro en demi-période, sans échauffement :
    ajouter un échauffement serait une seconde variable, et la passe constante
    n'en avait pas.

    Le pas est **global** — époque × pas par époque + pas — pour qu'une reprise
    retombe exactement au même endroit de la courbe.
    """
    if calendrier == 'constant' or total <= 0:
        return base
    if calendrier != 'cosinus':
        raise ValueError(f'calendrier inconnu : {calendrier}')
    avance = min(max(pas / total, 0.0), 1.0)
    return base * 0.5 * (1.0 + math.cos(math.pi * avance))


def desaccord_de_reprise(etat: dict, student: str, contrastive: float,
                         calendrier: str = 'constant') -> str:
    """Ce qui a changé entre la passe écrite et celle qu'on relance, s'il y a.

    **Une reprise ne renégocie pas la recette.** Un dorsal différent ferait
    échouer le chargement des poids, donc bruyamment ; un poids contrastif
    différent, lui, passerait sans un mot et la passe finirait sous une
    recette que personne n'a décidée. Le § 13.6 de `docs/09` raconte ce que
    coûte une variable changée sans décision : trois points inexplicables et
    une nuit.
    """
    ecarts = []
    if etat.get('student') not in (None, student):
        ecarts.append(f"dorsal {etat['student']} → {student}")
    ancien = etat.get('contrastive')
    if ancien is not None and float(ancien) != float(contrastive):
        ecarts.append(f'contrastive {ancien} → {contrastive}')
    # Un état écrit avant que le calendrier existe a tourné à taux constant.
    if etat.get('calendrier', 'constant') != calendrier:
        ecarts.append(f"calendrier {etat.get('calendrier', 'constant')} → {calendrier}")
    return ' ; '.join(ecarts)


def largeur_de_sortie(dorsal, entree: int = 224) -> int:  # pragma: no cover - demande torch
    """Ce que le dorsal rend vraiment, mesuré plutôt que déduit.

    **`num_features` n'est pas la sortie de tous les dorsaux.** Chez
    `fastvit_sa12` les deux coïncident à 1 024 ; chez `mobilenetv4_conv_large`
    `num_features` vaut 960 quand `num_classes=0` en rend 1 280, parce que sa
    tête garde une couche avant le classifieur. Le projecteur était donc bâti
    à la mauvaise dimension, et la passe mourait au premier lot — après avoir
    téléchargé les poids.

    Une passe à vide sur une image coûte quelques millisecondes et ne peut pas
    se tromper, quel que soit le dorsal qu'on essaiera ensuite.

    **En mode évaluation, et le mode est rendu comme il était.** Une
    `BatchNorm` refuse un lot d'une seule image à l'entraînement — « expected
    more than 1 value per channel » — et `timm` rend ses modèles en mode
    entraînement. Mesurer la sortie ne doit pas non plus laisser le dorsal
    dans un état que l'appelant n'a pas demandé.
    """
    import torch
    entrainait = dorsal.training
    dorsal.eval()
    try:
        with torch.no_grad():
            return int(dorsal(torch.zeros(1, 3, entree, entree)).shape[-1])
    finally:
        dorsal.train(entrainait)


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
    largeur = largeur_de_sortie(dorsal)
    if largeur != getattr(dorsal, 'num_features', largeur):
        print(f'{nom} : sortie {largeur} et non {dorsal.num_features} '
              f'(tête conservée), projecteur {largeur}→{dim}')
    return nn.Sequential(dorsal, nn.Linear(largeur, dim, bias=False))


def main() -> int:  # pragma: no cover - demande PyTorch, timm et les images
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('commande', choices=['mesure', 'entrainer'])
    ap.add_argument('--dataset', action='append', default=[],
                    help='répétable : plusieurs corpus se concatènent '
                         '(§ 20 ter de docs/14)')
    ap.add_argument('--cache', default='~/plant-data/bioclip')
    ap.add_argument('--sortie', default='~/plant-data/iris10')
    ap.add_argument('--student', default='fastvit_sa12',
                    help="le dorsal timm ; fastvit_sa12 reprend l'architecture du "
                         'modèle public, ce qui isole la recette')
    ap.add_argument('--batch', type=int, default=64, help='8 Go de VRAM')
    ap.add_argument('--epoques', type=int, default=10)
    ap.add_argument('--taux', type=float, default=1e-3)
    ap.add_argument('--calendrier', choices=['constant', 'cosinus'], default='constant',
                    help='constant reproduit les passes du 22 septembre ; '
                         'cosinus descend à zéro sur la passe (§ 19 decies de docs/14)')
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
    ap.add_argument('--banc', default='benchmark.csv',
                    help='le manifeste figé ; chaque point de contrôle en écrit un '
                         'cache que voisins.py lit tel quel')
    ap.add_argument('--graine', type=int, default=20260919)
    args = ap.parse_args()

    datasets = [Path(d).expanduser()
                for d in (args.dataset or ['~/plant-data/dataset-v8-indoor'])]
    cache = Path(args.cache).expanduser()
    lot_complet = corpus(datasets, cache)
    if not lot_complet:
        raise SystemExit(f'aucune image de {datasets} n\'a de vecteur dans {cache}')
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

    # ----------------------------------------------------------------------
    # entrainer
    # ----------------------------------------------------------------------
    from student import lire_banc, preparer, signature_student
    from bioclip import accorder_signature

    sortie = Path(args.sortie).expanduser()
    sortie.mkdir(parents=True, exist_ok=True)
    optimiseur = torch.optim.AdamW(modele.parameters(), lr=args.taux)
    echelle = torch.amp.GradScaler('cuda') if args.demi else None
    if args.demi:
        modele = modele.to(memory_format=torch.channels_last)

    # La reprise. Contrairement à `train.py` (§ 13.6 de docs/09), l'état de
    # l'optimiseur est **rechargé** : un AdamW neuf au milieu d'une descente
    # coûte des points, et ici rien n'empêche de le sauver.
    etat = sortie / 'etat.json'
    depart = 0
    if etat.exists():
        e = json.loads(etat.read_text())
        ecart = desaccord_de_reprise(e, args.student, args.contrastive, args.calendrier)
        if ecart:
            raise SystemExit(
                f'{sortie} a été écrit sous une autre recette : {ecart}.\n'
                f'Reprendre changerait une variable en cours de route. '
                f'Choisir un autre --sortie pour le nouveau bras.')
        point = torch.load(sortie / 'poids.pt', map_location=appareil, weights_only=True)
        modele.load_state_dict(point['modele'])
        optimiseur.load_state_dict(point['optimiseur'])
        if echelle is not None and point.get('echelle'):
            echelle.load_state_dict(point['echelle'])
        depart = int(e['epoque'])
        print(f'reprise à l\'époque {depart}')

    # Sans banc, la passe tourne huit heures et ne rend aucune mesure : le
    # point de contrôle du § 19 bis est précisément ce qui décide. Le chemin
    # est relatif au répertoire courant — le dire plutôt que le taire.
    fichier_banc = Path(args.banc).expanduser()
    banc = lire_banc(fichier_banc) if fichier_banc.exists() else []
    if not banc:
        print(f'ATTENTION : banc introuvable ({fichier_banc}) — aucune époque '
              f'n\'écrira de point de contrôle. Lancer depuis tools/plant_model, '
              f'ou passer --banc avec un chemin absolu.', flush=True)
    journal = open(sortie / 'journal.csv', 'a', newline='', encoding='utf-8')
    if journal.tell() == 0:
        csv.writer(journal).writerow(['epoque', 'pas', 'perte', 'accord', 'cone'])

    for epoque in range(depart, args.epoques):
        ordre = melanger(len(lot_complet), args.graine + epoque)
        lots = [[lot_complet[i] for i in ordre[d:d + args.batch]]
                for d in range(0, len(ordre), args.batch)]
        lots = [l for l in lots if len(l) == args.batch]
        memo: dict = {}
        modele.train()
        debut = time.perf_counter()
        for pas, (lot, images) in enumerate(
                flux_de_lots(lots, lambda t: preparer(t[0])[0], args.fils)):
            x = torch.from_numpy(np.stack(images)).to(appareil)
            if args.demi:
                x = x.to(memory_format=torch.channels_last)
            y = torch.from_numpy(cibles(cache, lot, memo)).to(appareil)
            taux = taux_du_pas(epoque * len(lots) + pas, args.epoques * len(lots),
                               args.taux, args.calendrier)
            for groupe in optimiseur.param_groups:
                groupe['lr'] = taux
            optimiseur.zero_grad()
            with torch.autocast('cuda', dtype=torch.float16, enabled=args.demi):
                s = modele(x)
                perte = (perte_cosinus(s.float(), y)
                         + args.contrastive * perte_contrastive(s.float(), y))
            if echelle is not None:
                echelle.scale(perte).backward()
                echelle.step(optimiseur)
                echelle.update()
            else:
                perte.backward()
                optimiseur.step()
            if pas % 200 == 0:
                lu = etat_du_lot(s.float(), y)
                csv.writer(journal).writerow(
                    [epoque, pas, round(float(perte.detach()), 4),
                     round(lu['accord'], 4), round(lu['cone'], 4)])
                journal.flush()
                vitesse = (pas + 1) * args.batch / (time.perf_counter() - debut)
                print(f'  é{epoque} pas {pas}/{len(lots)}  perte {float(perte.detach()):.4f}  '
                      f"accord {lu['accord']:.4f}  cône {lu['cone']:.4f}  "
                      f'{vitesse:.0f} img/s  taux {taux:.1e}', flush=True)

        torch.save({'modele': modele.state_dict(),
                    'optimiseur': optimiseur.state_dict(),
                    'echelle': echelle.state_dict() if echelle else None},
                   sortie / 'poids.pt')
        etat.write_text(json.dumps({'epoque': epoque + 1, 'student': args.student,
                                    'contrastive': args.contrastive,
                                    'calendrier': args.calendrier}))

        # Le point de contrôle qui décide : un cache du banc, lisible tel quel
        # par `voisins.py --embeddings`. On arrête sur le top-1 par référence,
        # jamais sur la perte (§ 19 bis de docs/14).
        if banc:
            dossier = sortie / f'banc-e{epoque + 1}'
            sig = signature_student(f'{args.student}-e{epoque + 1}', 'carre')
            accorder_signature(dossier, sig)
            modele.eval()
            vecteurs = np.empty((len(banc), DIM), dtype=np.float16)
            paquets = [banc[d:d + args.batch] for d in range(0, len(banc), args.batch)]
            ecrit = 0
            with torch.no_grad():
                for paquet, images in flux_de_lots(paquets, lambda c: preparer(c)[0],
                                                   args.fils):
                    x = torch.from_numpy(np.stack(images)).to(appareil)
                    if args.demi:
                        x = x.to(memory_format=torch.channels_last)
                    with torch.autocast('cuda', dtype=torch.float16, enabled=args.demi):
                        v = modele(x).float()
                    v = v / v.norm(dim=-1, keepdim=True)
                    vecteurs[ecrit:ecrit + len(paquet)] = v.cpu().numpy().astype(np.float16)
                    ecrit += len(paquet)
            np.save(dossier / 'emb-0-0000.npy', vecteurs[:ecrit])
            with open(dossier / 'index-0.csv', 'w', newline='', encoding='utf-8') as f:
                csv.writer(f).writerows([[c, 'emb-0-0000', i]
                                         for i, c in enumerate(banc[:ecrit])])
            print(f'  point de contrôle é{epoque + 1} — '
                  f'voisins.py --embeddings {dossier}', flush=True)
    journal.close()
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
