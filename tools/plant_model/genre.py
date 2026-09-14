#!/usr/bin/env python3
"""Ce que répondre au genre rapporterait, quand l'espèce hésite.

    python3 genre.py --modele ../../assets/model --dataset /data2/dataset-v8
    python3 genre.py --modele ../../assets/model --dataset /data2/dataset-v8 --seuils 0.6,0.7,0.8

Le § 12.15 n'a qu'un **plancher** : 64,3 % au genre contre 59,0 % à
l'espèce, tiré de la matrice de confusion, qui ne compte que les cas où la
*première* réponse tombait déjà dans le bon genre. Il ignore ceux où la
masse du genre était juste mais **répartie** entre cinq espèces — c'est-à-dire
précisément ceux qui nous intéressent.

Ici on garde les distributions. La masse d'un genre est la somme des
probabilités de ses espèces : cinq *Picea* à 0,15 pèsent 0,75, et « un
épicéa, espèce incertaine » devient une réponse **vraie** là où cinq noms
n'en sont pas une.

La question n'est pas académique, elle est produit : **sur les photos que
l'application n'accepte pas aujourd'hui — celles qui partent chez Pl@ntNet
sur le quota — combien le genre sauverait-il, et à quel prix en justesse ?**

Un genre qui n'a qu'une espèce au catalogue ne change rien : sa masse *est*
le score de l'espèce. Le gain vient des genres fournis, et grandit donc avec
le catalogue — contrairement au top-1.

`--top N` répond à la question d'implémentation : l'application ne garde que
**cinq** candidates (`classify`, `tflite_plant_model.dart`). Sommer sur ces
cinq-là suffirait-il ? Si oui, le genre se calcule dans la cascade sans rien
changer au modèle ; sinon, il faut le calculer sur le vecteur entier, là où
il est encore disponible, et le faire remonter. La différence entre les deux
colonnes est le prix de la simplicité.
"""
from __future__ import annotations

import argparse
import random
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'plant_dataset'))


def genres_des(labels: list[str], noms: dict[str, str] | None = None) -> list[str]:
    """Le genre de chaque classe, dans l'ordre du modèle."""
    from confusions import genre
    return [genre(c, noms) for c in labels]


def table_genres(genres: list[str]) -> tuple[list[str], np.ndarray]:
    """Les genres distincts, et la matrice creuse qui somme les espèces vers
    eux : `probs @ M` rend la masse de chaque genre, en une multiplication.
    """
    distincts = sorted(set(genres))
    rang = {g: i for i, g in enumerate(distincts)}
    M = np.zeros((len(genres), len(distincts)), dtype=np.float32)
    M[np.arange(len(genres)), [rang[g] for g in genres]] = 1.0
    return distincts, M


def tronquer(P: np.ndarray, k: int) -> np.ndarray:
    """Ne garder que les `k` meilleurs scores de chaque ligne, le reste à zéro.

    C'est ce que voit la cascade : `classify` trie, coupe à cinq, et la masse
    d'un genre étalé sur vingt espèces à 0,04 lui échappe entièrement.
    """
    if k <= 0 or k >= P.shape[1]:
        return P
    garde = np.argpartition(-P, k - 1, axis=1)[:, :k]
    out = np.zeros_like(P)
    lignes = np.arange(len(P))[:, None]
    out[lignes, garde] = P[lignes, garde]
    return out


def repondre(probs: np.ndarray, masses: np.ndarray, seuil: float) -> tuple[str, int, float]:
    """Ce que l'application rendrait pour une photo : une espèce si elle
    passe le seuil, sinon un genre s'il le passe, sinon rien.

    L'ordre compte. Un nom d'espèce est plus utile qu'un nom de genre, donc
    l'espèce garde la priorité ; le genre ne sert que là où l'espèce
    renonçait — c'est du gain net, jamais un remplacement.
    """
    e = int(np.argmax(probs))
    if probs[e] >= seuil:
        return 'espece', e, float(probs[e])
    g = int(np.argmax(masses))
    if masses[g] >= seuil:
        return 'genre', g, float(masses[g])
    return 'rien', e, float(probs[e])


def mesurer(P: np.ndarray, verite: np.ndarray, M: np.ndarray, genre_de: np.ndarray,
            seuil: float, top: int = 0) -> dict:
    """Les décisions de toutes les photos, comptées par type de réponse.

    `top` limite la masse des genres aux meilleures classes, comme le ferait
    une cascade qui n'a que les candidates sous la main. La réponse à
    l'espèce, elle, ne change pas : le meilleur score reste le meilleur.
    """
    masses = tronquer(P, top) @ M
    vrai_genre = genre_de[verite]
    compte = {'espece': 0, 'espece_juste': 0, 'genre': 0, 'genre_juste': 0, 'rien': 0}
    for i in range(len(P)):
        quoi, quel, _ = repondre(P[i], masses[i], seuil)
        if quoi == 'espece':
            compte['espece'] += 1
            compte['espece_juste'] += int(quel == verite[i])
        elif quoi == 'genre':
            compte['genre'] += 1
            compte['genre_juste'] += int(quel == vrai_genre[i])
        else:
            compte['rien'] += 1
    n = len(P)
    acceptees = compte['espece'] + compte['genre']
    justes = compte['espece_juste'] + compte['genre_juste']
    return {
        'images': n,
        'espece_taux': compte['espece'] / n,
        'espece_precision': compte['espece_juste'] / compte['espece'] if compte['espece'] else None,
        'genre_taux': compte['genre'] / n,
        'genre_precision': compte['genre_juste'] / compte['genre'] if compte['genre'] else None,
        'autonomie': acceptees / n,
        'precision': justes / acceptees if acceptees else None,
    }


def pour_cent(x) -> str:
    return '—' if x is None else f'{x:.1%}'


def main() -> int:
    from compare_models import load_model, predict_rows, read_test

    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--modele', default='../../assets/model')
    ap.add_argument('--dataset', required=True)
    ap.add_argument('--plants', default='../plant_dataset/plants.csv',
                    help='pour lire le genre dans le nom scientifique plutôt que dans l\'identifiant')
    ap.add_argument('--seuils', default='0.6,0.65,0.7,0.75,0.8')
    ap.add_argument('--top', type=int, default=0,
                    help='ne sommer que les N meilleures classes, comme le ferait la cascade '
                         'qui n\'en garde que cinq ; 0 = le vecteur entier')
    ap.add_argument('--sample', type=int, default=6000)
    ap.add_argument('--seed', type=int, default=20260905)
    args = ap.parse_args()

    modele = load_model(Path(args.modele))
    labels = modele['labels']

    noms = None
    plants = Path(args.plants)
    if plants.exists():
        import csv
        with open(plants, newline='', encoding='utf-8') as f:
            noms = {r['internal_id']: r['scientific_name'] for r in csv.DictReader(f)}

    genres = genres_des(labels, noms)
    distincts, M = table_genres(genres)
    rang = {g: i for i, g in enumerate(distincts)}
    genre_de = np.array([rang[g] for g in genres])

    tailles = np.bincount(genre_de, minlength=len(distincts))
    seules = int((tailles == 1).sum())
    print(f'{len(labels)} classes, {len(distincts)} genres — {seules} n\'ont qu\'une espèce '
          f'({seules / len(distincts):.0%}), le plus fourni en a {int(tailles.max())}')

    rows = [(p, t) for p, t, _ in read_test(Path(args.dataset)) if t in modele['index']]
    captive = {p for p, _, c in read_test(Path(args.dataset)) if c}
    rng = random.Random(args.seed)
    if args.sample and len(rows) > args.sample:
        rows = rng.sample(rows, args.sample)
    en_pot = np.array([p in captive for p, _ in rows])

    print(f'\ninférence sur {len(rows)} images de test…', flush=True)
    pred = predict_rows(rows, modele)
    P = np.stack([p for _, p in pred])
    verite = np.array([modele['index'][t] for t, _ in pred])
    en_pot = en_pot[:len(P)]

    part = (tailles[genre_de[verite]] > 1).mean()
    masses = P @ M
    print(f'{part:.0%} des images de test portent sur une espèce dont le genre en compte plusieurs — '
          'les seules où le genre ajoute quelque chose')
    print(f'\ntop-1 à l\'espèce {(np.argmax(P, axis=1) == verite).mean():.4f}   '
          f'au genre {(np.argmax(masses, axis=1) == genre_de[verite]).mean():.4f}   '
          '(le § 12.15 n\'en donnait qu\'un plancher)')

    for nom, masque in (('toutes les photos', np.ones(len(P), bool)), ('photos en pot', en_pot)):
        if not masque.any():
            continue
        print(f'\n— {nom} ({int(masque.sum())} images)')
        print(f"{'seuil':>6} {'espèce':>8} {'justes':>8}   {'+ genre':>8} {'justes':>8}   "
              f"{'autonomie':>10} {'justesse':>9}")
        for s in (float(x) for x in args.seuils.split(',')):
            r = mesurer(P[masque], verite[masque], M, genre_de, s, args.top)
            print(f'{s:>6.2f} {pour_cent(r["espece_taux"]):>8} {pour_cent(r["espece_precision"]):>8}   '
                  f'{pour_cent(r["genre_taux"]):>8} {pour_cent(r["genre_precision"]):>8}   '
                  f'{pour_cent(r["autonomie"]):>10} {pour_cent(r["precision"]):>9}')
    if args.top:
        print(f'\nMasses sommées sur les {args.top} meilleures classes seulement.')
    print('\nL\'espèce garde la priorité : le genre ne répond que là où elle renonçait.')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
