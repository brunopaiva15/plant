#!/usr/bin/env python3
"""Où sont les points qui manquent : les erreurs d'une tranche du banc, lues
une à une.

    python3 erreurs.py --embeddings ~/plant-data/iris10-pnd/banc-e10
    python3 erreurs.py --embeddings ~/plant-data/iris10-pnd/banc-e10 --avec-iris \\
        --masque ../plant_dataset/masque_indoor.txt

`voisins.py` rend un chiffre ; ce script dit d'où il vient. Même banc, mêmes
références, même lecture « textes à armes égales » : le top-1 qu'il affiche
est celui du tableau de suivi, à l'arrondi près.

**Trois lectures, dans l'ordre où elles décident du levier suivant :**

1. **Le student contre le teacher, image par image.** Le cache contient déjà
   le vecteur de BioCLIP pour chaque image du banc. Une erreur que le teacher
   fait aussi n'est pas une perte de distillation : aucune recette de
   distillation ne la corrigera, il faut une autre source (données
   supervisées, centroïdes, taxonomie). Une erreur du seul student, si ;
2. **La distance de l'erreur** : même genre, même famille, ou ailleurs. Une
   erreur de genre est une affaire de détail ; une erreur de famille dit que
   le student n'a pas vu la plante, au sens large (§ 12.4 de `docs/09`) ;
3. **Les espèces et les paires** qui concentrent les erreurs, pour savoir si
   l'écart est diffus ou tient en quelques plantes.

Avec `--avec-iris`, une quatrième : **les images qu'Iris 9 réussit et
qu'Iris 10 rate**. C'est l'écart à combler, au sens propre.

Rien ici ne touche au GPU. `erreurs-<tranche>.csv`, écrit à côté des
vecteurs, garde une ligne par image pour les regarder.
"""
from __future__ import annotations

import argparse
import csv
from collections import Counter
from pathlib import Path

import numpy as np

from voisins import charger_references, classer, lire_banc, lire_embeddings, restreindre

NIVEAUX = ('juste', 'même genre', 'même famille', 'autre famille', 'inconnu')


# --------------------------------------------------------------------------
# Lectures pures
# --------------------------------------------------------------------------

def taxonomie(lignes) -> dict[str, tuple[str, str, str]]:
    """{identifiant: (nom scientifique, genre, famille)} depuis `plants.csv`."""
    return {r['internal_id']: (r.get('scientific_name', ''), r.get('genus', ''),
                               r.get('family', '')) for r in lignes}


def niveau(verite: str, prediction: str, taxo: dict) -> str:
    """À quelle distance de la vérité tombe une réponse."""
    if prediction == verite:
        return 'juste'
    v, p = taxo.get(verite), taxo.get(prediction)
    if v is None or p is None:
        return 'inconnu'
    if v[1] and v[1] == p[1]:
        return 'même genre'
    if v[2] and v[2] == p[2]:
        return 'même famille'
    return 'autre famille'


def croiser(verites: list[str], a: list[str], b: list[str]) -> dict[str, int]:
    """Les quatre cases de deux lecteurs sur les mêmes images."""
    c = Counter()
    for v, x, y in zip(verites, a, b):
        c[('juste' if x == v else 'faux') + ' / ' + ('juste' if y == v else 'faux')] += 1
    return {k: c.get(k, 0) for k in ('juste / juste', 'faux / juste', 'juste / faux',
                                     'faux / faux')}


def par_espece(verites: list[str], predictions: list[str]) -> list[tuple[str, int, int]]:
    """(espèce, images, erreurs), les plus coûteuses d'abord.

    Trié par nombre d'erreurs, pas par taux : une espèce à 3 images toutes
    fausses coûte moins de points au banc qu'une espèce à 40 images dont 12
    fausses.
    """
    n, faux = Counter(verites), Counter(v for v, p in zip(verites, predictions) if v != p)
    return sorted(((e, n[e], faux[e]) for e in n if faux[e]),
                  key=lambda t: (-t[2], -t[1], t[0]))


def confusions(verites: list[str], predictions: list[str]) -> list[tuple[str, str, int]]:
    """(vérité, réponse, fois), les plus fréquentes d'abord."""
    c = Counter((v, p) for v, p in zip(verites, predictions) if v != p)
    return sorted(((v, p, k) for (v, p), k in c.items()), key=lambda t: (-t[2], t[0], t[1]))


def top1(scores_especes: list[str], scores: list[np.ndarray]) -> list[str]:
    return [scores_especes[int(np.argmax(p))] for p in scores]


# --------------------------------------------------------------------------
# Le rapport
# --------------------------------------------------------------------------

def nom(cle: str, taxo: dict) -> str:
    return (taxo.get(cle) or (cle,))[0] or cle


def pourcent(k: int, n: int) -> str:
    return f'{k:5d}  {100 * k / n:5.1f} %' if n else f'{k:5d}'


def rapport(tranche: str, verites: list[str], student: list[str], teacher: list[str],
            taxo: dict, iris: list[str] | None = None, combien: int = 20) -> list[str]:
    n = len(verites)
    out = [f'— {tranche} — {n} images, textes à armes égales', '']
    t_s = sum(v == p for v, p in zip(verites, student))
    t_t = sum(v == p for v, p in zip(verites, teacher))
    out.append(f'  top-1 student {t_s / n:.4f}   teacher {t_t / n:.4f}'
               + (f'   Iris 9 {sum(v == p for v, p in zip(verites, iris)) / n:.4f}'
                  if iris else ''))
    out += ['', '  student / teacher']
    for k, c in croiser(verites, student, teacher).items():
        explication = {'faux / juste': '← perdu par la distillation',
                       'faux / faux': '← le teacher non plus : hors de portée de la distillation',
                       'juste / faux': '← le student fait mieux que le teacher'}.get(k, '')
        out.append(f'    {k:<14} {pourcent(c, n)}  {explication}')

    if iris:
        out += ['', '  Iris 10 / Iris 9']
        for k, c in croiser(verites, student, iris).items():
            explication = {'faux / juste': "← l'écart à combler",
                           'juste / faux': "← ce qu'Iris 10 apporte"}.get(k, '')
            out.append(f'    {k:<14} {pourcent(c, n)}  {explication}')
        rates = [i for i, (v, s, r) in enumerate(zip(verites, student, iris))
                 if s != v and r == v]
        if rates:
            dist = Counter(niveau(verites[i], student[i], taxo) for i in rates)
            prof = Counter('teacher juste' if teacher[i] == verites[i] else 'teacher faux'
                           for i in rates)
            out.append(f'    parmi les {len(rates)} qu\'Iris 9 réussit seul : '
                       + ', '.join(f'{k} {dist[k]}' for k in NIVEAUX[1:] if dist[k])
                       + f' ; {prof["teacher juste"]} que le teacher réussit')

    out += ['', '  distance des erreurs du student']
    erreurs = [niveau(v, p, taxo) for v, p in zip(verites, student) if v != p]
    d = Counter(erreurs)
    for k in NIVEAUX[1:]:
        if d[k]:
            out.append(f'    {k:<14} {pourcent(d[k], len(erreurs))}')

    out += ['', f'  les {combien} espèces qui coûtent le plus  (images, erreurs, part du banc)']
    for e, k, f in par_espece(verites, student)[:combien]:
        out.append(f'    {nom(e, taxo):<34} {k:4d} {f:4d}   {100 * f / n:4.1f} pt')
    out += ['', f'  les {combien} confusions les plus fréquentes']
    for v, p, k in confusions(verites, student)[:combien]:
        out.append(f'    {k:3d}  {nom(v, taxo):<30} → {nom(p, taxo):<30} {niveau(v, p, taxo)}')
    return out


def main() -> int:  # pragma: no cover - demande le cache et le banc
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--banc', default='benchmark.csv')
    ap.add_argument('--cache', default='~/plant-data/bioclip',
                    help='les références, et les vecteurs du teacher pour le banc')
    ap.add_argument('--embeddings', required=True,
                    help='le point de contrôle du student, ex. ~/plant-data/iris10-pnd/banc-e10')
    ap.add_argument('--tranche', default='indoor')
    ap.add_argument('--iris', default='../../assets/model')
    ap.add_argument('--plants', default='../plant_dataset/plants.csv')
    ap.add_argument('--references', default='texte',
                    help='texte, centroide, ou le nom d\'un fichier de références du cache '
                         '(ex. references-centroides-pot)')
    ap.add_argument('--combien', type=int, default=20)
    ap.add_argument('--avec-iris', action='store_true',
                    help='faire aussi tourner Iris 9 sur les mêmes images (demande TensorFlow)')
    ap.add_argument('--masque', default=None,
                    help="restreindre Iris 9 au masque du lieu, comme l'application")
    args = ap.parse_args()

    cache = Path(args.cache).expanduser()
    source = Path(args.embeddings).expanduser()
    lignes = lire_banc(Path(args.banc).expanduser(), args.tranche)
    if not lignes:
        raise SystemExit(f'aucune image {args.tranche} dans {args.banc}')
    chemins = [c for c, _ in lignes]
    gardes_s, v_s = lire_embeddings(source, chemins)
    gardes_t, v_t = lire_embeddings(cache, chemins)
    communs = sorted(set(gardes_s) & set(gardes_t))
    if not communs:
        raise SystemExit('aucune image du banc dans les deux caches')
    rang_s = {g: i for i, g in enumerate(gardes_s)}
    rang_t = {g: i for i, g in enumerate(gardes_t)}
    v_s = v_s[[rang_s[g] for g in communs]]
    v_t = v_t[[rang_t[g] for g in communs]]
    verites = [lignes[g][1] for g in communs]

    expose = {l.strip() for l in (Path(args.iris).expanduser() / 'labels.txt')
              .read_text(encoding='utf-8').splitlines() if l.strip()}
    cles, vecteurs = restreindre(*charger_references(cache, args.references), expose)
    especes, scores = classer(v_s, vecteurs, cles)
    student = top1(especes, scores)
    especes_t, scores_t = classer(v_t, vecteurs, cles)
    teacher = top1(especes_t, scores_t)

    iris = None
    if args.avec_iris:
        from compare_models import load_model, predict
        modele = load_model(Path(args.iris).expanduser())
        garde = None
        if args.masque:
            garde = {l.strip() for l in Path(args.masque).expanduser()
                     .read_text(encoding='utf-8').splitlines() if l.strip()}
        iris = []
        for g in communs:
            p = np.asarray(predict(modele, lignes[g][0]), dtype=np.float64)
            if garde is not None:
                p = np.where([lab in garde for lab in modele['labels']], p, 0.0)
            iris.append(modele['labels'][int(np.argmax(p))])

    with open(Path(args.plants).expanduser(), newline='', encoding='utf-8') as f:
        taxo = taxonomie(csv.DictReader(f))
    print('\n'.join(rapport(args.tranche, verites, student, teacher, taxo, iris, args.combien)))

    sortie = source / f'erreurs-{args.tranche}.csv'
    with open(sortie, 'w', newline='', encoding='utf-8') as f:
        w = csv.writer(f)
        w.writerow(['chemin', 'verite', 'student', 'teacher', 'iris9', 'niveau'])
        for i, g in enumerate(communs):
            w.writerow([lignes[g][0], verites[i], student[i], teacher[i],
                        iris[i] if iris else '', niveau(verites[i], student[i], taxo)])
    print(f'\n{sortie} — une ligne par image')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
