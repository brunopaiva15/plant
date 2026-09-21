#!/usr/bin/env python3
"""La porte C : nommer par la référence la plus proche, plutôt que par un softmax.

    python3 voisins.py --banc benchmark.csv --cache ~/plant-data/bioclip \\
        --iris ../../assets/model

Le § 19 de `docs/14` pose cinq portes qui peuvent tuer Iris 10. Celle-ci est
la plus fondamentale : **un embedding comparé à des références vaut-il mieux
qu'une couche de sortie apprise ?** Tant qu'on ne l'a pas mesuré, la
distillation des étapes 5 et 6 est un pari.

Elle ne coûte presque rien, et c'est le point. Les images du banc sont des
images de test, donc `bioclip.py cache` les a déjà encodées — le teacher n'a
rien à recalculer. Classer une photo devient un produit scalaire contre les
références, et la mesure entière tient en quelques secondes de numpy.

## Les deux chiffres, et pourquoi le second compte davantage

1. **sur les espèces qu'Iris expose** — à armes égales, references restreintes
   aux 1 569 classes d'Iris 9. C'est la question « l'espace fait-il aussi
   bien que la tête apprise ? », et l'espace part avec un handicap : il n'a
   jamais vu nos étiquettes ;
2. **sur `ood_plante`** — les espèces qu'Iris **ne peut pas** nommer, où il
   est à zéro par construction. L'espace, lui, porte une référence par espèce
   du catalogue, soit ~5 800 au lieu de 1 569. C'est là que le changement de
   paradigme se justifie ou s'effondre, et c'est exactement la mesure qui a
   tué le second avis de PlantNet-300K (4,85 % de rattrapage, § 5 de
   `docs/14`).

## Ce qu'on ne peut pas encore dire : un seuil

Un cosinus n'est pas une probabilité. Iris 9 accepte au-dessus de 0,70 parce
que ce seuil a été réglé sur ses sorties (§ 3.1), et **un seuil ne se
transporte pas d'un modèle à l'autre** — encore moins d'un softmax vers une
similarité.

Top-1 et top-3 ne demandent aucune calibration : ils sont comparables tels
quels. L'autonomie, non. On la rend donc sous `--temperature`, en disant
qu'elle est **arbitraire** : c'est une courbe à lire, pas un chiffre à citer.
Le vrai réglage viendra d'une calibration sur la validation, quand la
géométrie sera figée.

## Références textuelles ou centroïdes

Les deux, et elles ne disent pas la même chose (§ 7 de `docs/14`) :

- **textes** — une par espèce du catalogue, y compris celles dont on n'a
  aucune photo. C'est ce qui permet de nommer hors du répertoire appris ;
- **centroïdes** — la direction moyenne des photos d'une espèce. Plus juste
  là où il y a des images, muet ailleurs.

`--references texte,centroide` les mesure séparément, parce que les fondre
avant de savoir laquelle porte le résultat rendrait la lecture illisible.
"""
from __future__ import annotations

import argparse
import csv
from pathlib import Path

import numpy as np

from bioclip import lire_index, lire_signature

# Les deux jeux de références que `bioclip.py` écrit dans le cache.
FICHIERS = {'texte': 'references-textes', 'centroide': 'references-centroides'}


# --------------------------------------------------------------------------
# Les références
# --------------------------------------------------------------------------

def charger_references(cache: Path, nom: str) -> tuple[list[str], np.ndarray]:
    """Les clés et la matrice unitaire d'un jeu de références."""
    base = cache / FICHIERS[nom]
    if not base.with_suffix('.npy').exists():
        raise SystemExit(f"{base}.npy absent — lancer `bioclip.py {nom_commande(nom)}` d'abord")
    vecteurs = np.load(base.with_suffix('.npy')).astype(np.float32)
    with open(base.with_suffix('.csv'), newline='', encoding='utf-8') as f:
        cles = [r['internal_id'] for r in csv.DictReader(f)]
    if len(cles) != len(vecteurs):
        raise SystemExit(f'{base} : {len(cles)} clés pour {len(vecteurs)} vecteurs')
    return cles, vecteurs


def nom_commande(nom: str) -> str:
    return 'textes' if nom == 'texte' else 'centroides'


def restreindre(cles: list[str], vecteurs: np.ndarray,
                garder: set[str] | None) -> tuple[list[str], np.ndarray]:
    """Les seules références de cet ensemble d'espèces.

    C'est le « à armes égales » du § 6.7 : comparer l'espace à Iris sur les
    espèces qu'Iris expose, sinon on compte comme un gain le simple fait
    d'avoir un répertoire plus large — ce qui est vrai, mais se mesure à
    part.
    """
    if garder is None:
        return cles, vecteurs
    indices = [i for i, c in enumerate(cles) if c in garder]
    return [cles[i] for i in indices], vecteurs[indices]


def sans_suffixe(cle: str) -> str:
    """`monstera-deliciosa#captive` → `monstera-deliciosa`.

    `bioclip.py centroides --captive-a-part` produit une seconde référence
    par espèce, tirée des seules photos en pot. Elle vise la même plante :
    la retenir comme une classe distincte compterait une bonne réponse
    comme fausse.
    """
    return cle.split('#', 1)[0]


# --------------------------------------------------------------------------
# Le classement
# --------------------------------------------------------------------------

def classer(embeddings: np.ndarray, references: np.ndarray, cles: list[str],
            temperature: float = 100.0) -> tuple[list[str], list[np.ndarray]]:
    """Les scores de chaque image contre chaque **espèce**.

    Les deux côtés étant unitaires, le cosinus est un produit scalaire. Le
    passage en probabilités suit la convention CLIP — un softmax de la
    similarité multipliée par une température — et il ne sert qu'à lire une
    courbe d'autonomie : **il n'est pas calibré**.

    Quand plusieurs références visent la même espèce (`#captive`, plusieurs
    prototypes), on garde **la meilleure**, pas leur somme : une espèce est
    reconnue si l'une de ses vues correspond, et additionner favoriserait
    mécaniquement celles qui en ont le plus.
    """
    especes: list[str] = []
    rang: dict[str, int] = {}
    for c in cles:
        e = sans_suffixe(c)
        if e not in rang:
            rang[e] = len(especes)
            especes.append(e)
    groupes = np.array([rang[sans_suffixe(c)] for c in cles])

    sortie = []
    for v in embeddings:
        sim = references @ v.astype(np.float32)
        meilleur = np.full(len(especes), -np.inf, dtype=np.float32)
        np.maximum.at(meilleur, groupes, sim)
        x = np.exp(temperature * (meilleur - meilleur.max()))
        sortie.append(x / x.sum())
    return especes, sortie


def degrader(embeddings: np.ndarray, cible: float, graine: int = 20260919) -> np.ndarray:
    """Les mêmes vecteurs, écartés jusqu'à ce cosinus exactement.

    **Répond à « quel cosinus la distillation doit-elle viser ? » sans
    entraîner quoi que ce soit.** On sait qu'un student à 0,748 ne garde que
    39 % du top-1 du teacher ; on ignore où est le seuil. Bruiter les vecteurs
    du teacher à un cosinus donné et relire le top-1 rend toute la courbe en
    quelques secondes de numpy.

    Le bruit est tiré **orthogonalement** à chaque vecteur, puis dosé : le
    cosinus obtenu vaut la cible au flottant près, et non « environ ». Un
    bruit isotrope ajouté puis renormalisé donnerait une cible approchée, et
    c'est justement la précision qui fait l'intérêt de la courbe.

    C'est un **plancher optimiste** : un vrai student ne s'écarte pas au
    hasard, il se trompe de façon structurée — sur les espèces proches, là où
    ça coûte le plus. La courbe dit donc le cosinus **minimum** nécessaire,
    pas le cosinus suffisant.
    """
    alea = np.random.default_rng(graine)
    v = np.asarray(embeddings, dtype=np.float32)
    v = v / np.linalg.norm(v, axis=1, keepdims=True)
    u = alea.standard_normal(v.shape).astype(np.float32)
    u -= (u * v).sum(axis=1, keepdims=True) * v      # orthogonal à chaque vecteur
    u /= np.linalg.norm(u, axis=1, keepdims=True)
    return cible * v + np.sqrt(max(0.0, 1.0 - cible ** 2)) * u


def lire_embeddings(cache: Path, chemins: list[str]) -> tuple[list[int], np.ndarray]:
    """Les vecteurs déjà cachés pour ces images, et lesquelles en ont un.

    Une image absente du cache n'est pas une erreur : la passe a pu être
    coupée, ou le manifeste pointer sur un jeu plus récent. Elle est écartée,
    et le compte rendu dit combien — un chiffre calculé sur la moitié des
    images sans le dire serait pire qu'une erreur.
    """
    index = lire_index(cache)
    par_fragment: dict[str, list[tuple[int, int]]] = {}
    gardes = []
    for rang, chemin in enumerate(chemins):
        place = index.get(chemin)
        if place is None:
            continue
        par_fragment.setdefault(place[0], []).append((place[1], len(gardes)))
        gardes.append(rang)
    if not gardes:
        return [], np.zeros((0, 0), dtype=np.float32)

    sortie = None
    for fragment, lignes in par_fragment.items():
        tableau = np.load(cache / f'{fragment}.npy')
        if sortie is None:
            sortie = np.zeros((len(gardes), tableau.shape[1]), dtype=np.float32)
        for ligne, place in lignes:
            sortie[place] = tableau[ligne]
    return gardes, sortie


def compter(verites: list[str], especes: list[str], scores: list[np.ndarray],
            seuil: float) -> dict:
    """Top-1, top-3 et autonomie, dans le format de `compare_models.tally`."""
    vus = t1 = t3 = acceptees = justes = 0
    for verite, p in zip(verites, scores):
        ordre = np.argsort(-p)[:3]
        tete = [especes[i] for i in ordre]
        vus += 1
        t1 += tete[0] == verite
        t3 += verite in tete
        if p[ordre[0]] >= seuil:
            acceptees += 1
            justes += tete[0] == verite
    return {
        'images': vus,
        'top1': round(t1 / vus, 4) if vus else None,
        'top3': round(t3 / vus, 4) if vus else None,
        'accepted_rate': round(acceptees / vus, 4) if vus else None,
        'precision_when_accepted': round(justes / acceptees, 4) if acceptees else None,
    }


# --------------------------------------------------------------------------
# Le banc
# --------------------------------------------------------------------------

def lire_banc(chemin: Path, tranche: str) -> list[tuple[str, str]]:
    lignes = []
    with open(chemin, newline='', encoding='utf-8') as f:
        for r in csv.DictReader(f):
            if r['tranche'] == tranche and r['verite']:
                lignes.append((r['chemin'], r['verite']))
    return lignes


_modele_iris = {}


def _iris(dossier: str):  # pragma: no cover - demande TensorFlow
    """Iris 9 chargé une fois, partagé entre les tranches."""
    if 'm' not in _modele_iris:
        from compare_models import load_model
        _modele_iris['m'] = load_model(Path(dossier).expanduser())
    return _modele_iris['m']


def main() -> int:  # pragma: no cover - demande le cache et le banc
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--banc', default='benchmark.csv')
    ap.add_argument('--cache', default='~/plant-data/bioclip')
    ap.add_argument('--embeddings',
                    help="lire les vecteurs d'images dans ce cache-ci plutôt que dans "
                         '--cache, dont on garde les références. C\'est le montage '
                         "livré : le téléphone encode, les références restent "
                         'pré-calculées hors app (§ 7 de docs/14)')
    ap.add_argument('--iris', default='../../assets/model',
                    help="pour restreindre aux classes qu'Iris expose")
    ap.add_argument('--tranches', default='indoor,outdoor,ood_plante')
    ap.add_argument('--references', default='texte,centroide')
    ap.add_argument('--temperature', type=float, default=100.0)
    ap.add_argument('--seuil', type=float, default=0.70,
                    help='autonomie lue à ce seuil — non calibré, à lire comme une courbe')
    ap.add_argument('--masque', action='append', default=[], metavar='TRANCHE=FICHIER',
                    help="restreindre Iris 9 au masque du lieu pour cette tranche, "
                         "comme le fait l'application (§ 14 de docs/09). Sans lui, "
                         'Iris répond sur ses 1 569 classes, ce que l\'app ne fait pas')
    ap.add_argument('--degrader', default='',
                    help='cosinus cibles séparés par des virgules : relit le top-1 sur '
                         'des vecteurs du teacher écartés à ce cosinus. Dit quel accord '
                         'la distillation doit viser, sans entraîner')
    ap.add_argument('--avec-iris', action='store_true',
                    help="faire aussi tourner Iris 9 sur les mêmes images (demande "
                         'TensorFlow). Sans lui, ce script ne dit pas si l\'espace fait '
                         'mieux — il dit seulement ce que l\'espace rend')
    args = ap.parse_args()

    masques = dict(m.split('=', 1) for m in args.masque if '=' in m)
    cache = Path(args.cache).expanduser()
    sig = lire_signature(cache)
    if sig is None:
        raise SystemExit(f"{cache} n'a pas de signature : lancer `bioclip.py cache` d'abord")
    print(f"références : {sig['teacher']}, signature {sig['empreinte']}")
    source = Path(args.embeddings).expanduser() if args.embeddings else cache
    if args.embeddings:
        sigs = lire_signature(source)
        if sigs is None:
            raise SystemExit(f"{source} n'a pas de signature")
        if int(sigs.get('dim', 0)) != int(sig.get('dim', 0)):
            raise SystemExit(
                f"dimensions incompatibles : références {sig.get('dim')}, "
                f"vecteurs {sigs.get('dim')} — ils ne vivent pas dans le même espace")
        print(f"vecteurs   : {sigs['teacher']}, signature {sigs['empreinte']}")
    print()

    etiquettes = Path(args.iris).expanduser() / 'labels.txt'
    expose = {l.strip() for l in etiquettes.read_text(encoding='utf-8').splitlines() if l.strip()}
    print(f"Iris expose {len(expose)} classes")

    jeux = {}
    for nom in (n.strip() for n in args.references.split(',') if n.strip()):
        cles, vecteurs = charger_references(cache, nom)
        jeux[nom] = (cles, vecteurs)
        especes = {sans_suffixe(c) for c in cles}
        print(f'références {nom} : {len(cles)} vecteurs, {len(especes)} espèces, '
              f'{len(especes & expose)} exposées par Iris')

    for tranche in (t.strip() for t in args.tranches.split(',') if t.strip()):
        lignes = lire_banc(Path(args.banc).expanduser(), tranche)
        if not lignes:
            continue
        gardes, embeddings = lire_embeddings(source, [p for p, _ in lignes])
        if not gardes:
            print(f'\n— {tranche} — aucune image dans le cache, sautée')
            continue
        verites = [lignes[i][1] for i in gardes]
        manquantes = len(lignes) - len(gardes)
        print(f'\n— {tranche} — {len(gardes)} images'
              + (f' ({manquantes} absentes du cache)' if manquantes else ''))

        if args.avec_iris:
            # La moitié manquante : sans elle, on lit un chiffre, pas une
            # comparaison. Mêmes images, même vérité, même dénominateur.
            from compare_models import load_model, predict, tally
            modele = _iris(args.iris)
            chemins = [lignes[i][0] for i in gardes]
            predictions = [(v, predict(modele, c)) for v, c in zip(verites, chemins)]
            atteignable = sum(1 for x in verites if x in modele['index'])
            lectures = [(f'ses {len(modele["labels"])} classes', None, False)]
            fichier = masques.get(tranche)
            if fichier:
                garde = {l.strip() for l in Path(fichier).expanduser()
                         .read_text(encoding='utf-8').splitlines() if l.strip()}
                lectures.append((f'masque du lieu ({len(garde)})', garde, True))
            for titre, garde, renorm in lectures:
                r = tally(predictions, modele, garde, renormalise=renorm, seuil=args.seuil)
                print(f'  {"Iris 9":<10} {titre:<18} top-1 {r["top1"]}  '
                      f'top-3 {r["top3"]}  ({atteignable}/{len(verites)} nommables)')

        for cible in [float(c) for c in args.degrader.split(',') if c.strip()]:
            abimes = degrader(embeddings, cible)
            for nom, (cles, vecteurs) in jeux.items():
                c, v = restreindre(cles, vecteurs, expose)
                especes, scores = classer(abimes, v, c, args.temperature)
                r = compter(verites, especes, scores, args.seuil)
                print(f'  {nom:<10} {f"cosinus {cible:.2f}":<18} top-1 {r["top1"]}  '
                      f'top-3 {r["top3"]}')

        for nom, (cles, vecteurs) in jeux.items():
            for titre, garder in (('à armes égales', expose), ('répertoire entier', None)):
                c, v = restreindre(cles, vecteurs, garder)
                if len(c) == 0:
                    continue
                especes, scores = classer(embeddings, v, c, args.temperature)
                r = compter(verites, especes, scores, args.seuil)
                atteignable = sum(1 for x in verites if x in set(especes))
                print(f'  {nom:<10} {titre:<18} top-1 {r["top1"]}  top-3 {r["top3"]}'
                      f'  ({atteignable}/{len(verites)} nommables)')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
