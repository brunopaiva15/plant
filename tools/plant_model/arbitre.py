#!/usr/bin/env python3
"""Iris 9 et Iris 10 ensemble : quelle règle de choix, et combien elle vaut.

    python3 arbitre.py --embeddings ~/plant-data/iris10-pnd/banc-e10

Les deux modèles ne se trompent pas sur les mêmes images (§ 20 octies et
20 nonies de `docs/14`) : en indoor, 79 images qu'Iris 10 réussit seul, 101
qu'Iris 9 réussit seul. Un arbitre parfait vaudrait 0,88. Ce script mesure
ce que valent des règles **qu'on pourrait livrer** :

- **seuil sur Iris 10** : sa réponse quand il est sûr de lui, celle d'Iris 9
  sinon ;
- **seuil sur Iris 9** : l'inverse ;
- **fusion** : les deux distributions multipliées, `p9^a · p10^(1−a)`, sur les
  espèces que les deux connaissent ;
- **Iris 10 masqué** : Iris 10 seul, restreint au masque du lieu comme Iris 9
  l'est dans l'application.

**Le réglage ne se fait pas sur les images qu'il note.** Choisir le seuil
sur le banc, puis lire le top-1 sur le même banc, flatterait la règle. Le
banc est coupé en deux moitiés fixes : le paramètre est choisi sur l'une et
lu sur l'autre, puis l'inverse, et c'est la moyenne des deux lectures qui
est rendue. Les lignes « choisi » disent quel paramètre chaque moitié a
retenu : s'ils diffèrent beaucoup, la règle est fragile.

**Iris 9 comme dans l'application** : masque du lieu, et les classes qui
désignent la même plante additionnées (`SYNONYMES` de `voisins.py`, comme
`maskedCandidates` côté app). Ses sorties sont gardées dans
`iris9-<tranche>.npy` à côté des vecteurs : la seconde lecture ne fait
plus tourner TensorFlow.

Demande TensorFlow (le venv `~/venv`) pour Iris 9. Sur le processeur : lancer
avec `CUDA_VISIBLE_DEVICES=` quand un entraînement occupe la carte.
"""
from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np

from voisins import (canonique, charger_references, classer, lire_banc, lire_embeddings,
                     restreindre)

SEUILS = tuple(round(x, 2) for x in np.arange(0.0, 1.0001, 0.05))
POIDS = (0.25, 0.5, 0.75)


# --------------------------------------------------------------------------
# Lectures pures
# --------------------------------------------------------------------------

def fusionner_synonymes(probas: np.ndarray, labels: list[str]) -> tuple[list[str], np.ndarray]:
    """Les sorties d'Iris 9 regroupées par plante : deux classes d'une même
    plante s'additionnent, puisque leurs probabilités s'excluent."""
    especes: list[str] = []
    rang: dict[str, int] = {}
    for lab in labels:
        e = canonique(lab)
        if e not in rang:
            rang[e] = len(especes)
            especes.append(e)
    sortie = np.zeros((len(probas), len(especes)), dtype=np.float64)
    for j, lab in enumerate(labels):
        sortie[:, rang[canonique(lab)]] += probas[:, j]
    return especes, sortie


def masquer(probas: np.ndarray, especes: list[str], garde: set[str] | None) -> np.ndarray:
    """Restreint au masque du lieu et renormalise, comme l'application.

    Une plante est du lieu dès qu'un de ses noms l'est : `garde` est d'abord
    ramené aux clés canoniques.
    """
    if not garde:
        return probas
    g = {canonique(x) for x in garde}
    m = np.array([e in g for e in especes])
    p = np.where(m, probas, 0.0)
    s = p.sum(axis=1, keepdims=True)
    return np.divide(p, s, out=np.zeros_like(p), where=s > 0)


def aligner(especes_a: list[str], pa: np.ndarray, especes_b: list[str],
            pb: np.ndarray) -> tuple[list[str], np.ndarray, np.ndarray]:
    """Les deux distributions sur les espèces qu'elles ont en commun."""
    rb = {e: i for i, e in enumerate(especes_b)}
    communes = [e for e in especes_a if e in rb]
    ia = [especes_a.index(e) for e in communes]
    ib = [rb[e] for e in communes]
    return communes, pa[:, ia], pb[:, ib]


def regle_seuil(conf_a: np.ndarray, pred_a: list[str], pred_b: list[str],
                seuil: float) -> list[str]:
    """La réponse de A quand il est sûr à `seuil` au moins, celle de B sinon."""
    return [a if c >= seuil else b for c, a, b in zip(conf_a, pred_a, pred_b)]


def fusion(especes: list[str], p9: np.ndarray, p10: np.ndarray, poids: float,
           plancher: float = 1e-6) -> list[str]:
    """`p9^poids · p10^(1−poids)`, en logarithmes, sur des distributions
    alignées. Le plancher empêche une probabilité nulle d'opposer un veto."""
    score = (poids * np.log(np.maximum(p9, plancher))
             + (1 - poids) * np.log(np.maximum(p10, plancher)))
    return [especes[i] for i in score.argmax(axis=1)]


def justesse(verites: list[str], preds: list[str], indices=None) -> float:
    idx = range(len(verites)) if indices is None else indices
    idx = list(idx)
    return sum(verites[i] == preds[i] for i in idx) / len(idx) if idx else 0.0


def moities(n: int) -> tuple[np.ndarray, np.ndarray]:
    """Deux moitiés fixes et mélangées du banc — toujours les mêmes, pour
    que deux lectures se comparent."""
    ordre = np.random.default_rng(20260928).permutation(n)
    return np.sort(ordre[: n // 2]), np.sort(ordre[n // 2:])


def croisee(verites: list[str], preds_par_parametre: dict) -> tuple[float, list]:
    """Top-1 en validation croisée à deux plis : le paramètre choisi sur une
    moitié, lu sur l'autre, dans les deux sens. Rend (top-1, paramètres
    choisis)."""
    a, b = moities(len(verites))
    lu, choisis = [], []
    for apprend, note in ((a, b), (b, a)):
        meilleur = max(preds_par_parametre,
                       key=lambda k: justesse(verites, preds_par_parametre[k], apprend))
        choisis.append(meilleur)
        lu.append(justesse(verites, preds_par_parametre[meilleur], note))
    return float(np.mean(lu)), choisis


def oracle(verites: list[str], a: list[str], b: list[str]) -> float:
    return sum(v in (x, y) for v, x, y in zip(verites, a, b)) / len(verites)


# --------------------------------------------------------------------------
# Iris 9, une fois
# --------------------------------------------------------------------------

def probas_iris9(dossier: Path, chemins: list[str], fichier: Path) -> tuple[list[str], np.ndarray]:  # pragma: no cover
    """Les sorties brutes d'Iris 9 sur ces images, calculées une fois."""
    labels = (dossier / 'labels.txt').read_text(encoding='utf-8').split()
    if fichier.exists():
        p = np.load(fichier)
        if p.shape == (len(chemins), len(labels)):
            return labels, p
    from compare_models import load_model, predict
    modele = load_model(dossier)
    p = np.stack([np.asarray(predict(modele, c), dtype=np.float32) for c in chemins])
    np.save(fichier, p)
    return labels, p


def main() -> int:  # pragma: no cover - demande le cache, le banc et TensorFlow
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--banc', default='benchmark.csv')
    ap.add_argument('--cache', default='~/plant-data/bioclip')
    ap.add_argument('--embeddings', required=True)
    ap.add_argument('--references', default='centroide+references-centroides-potseul')
    ap.add_argument('--iris', default='../../assets/model')
    ap.add_argument('--tranches', default='indoor,outdoor')
    ap.add_argument('--masque', action='append', default=[], metavar='TRANCHE=FICHIER',
                    help='défaut : les masques de ../plant_dataset')
    args = ap.parse_args()

    masques = dict(m.split('=', 1) for m in args.masque if '=' in m) or {
        'indoor': '../plant_dataset/masque_indoor.txt',
        'outdoor': '../plant_dataset/masque_outdoor.txt'}
    cache = Path(args.cache).expanduser()
    source = Path(args.embeddings).expanduser()
    dossier_iris = Path(args.iris).expanduser()
    expose = {canonique(l) for l in (dossier_iris / 'labels.txt')
              .read_text(encoding='utf-8').split()}
    cles, vecteurs = restreindre(*charger_references(cache, args.references), expose)

    for tranche in (t.strip() for t in args.tranches.split(',') if t.strip()):
        lignes = lire_banc(Path(args.banc).expanduser(), tranche)
        gardes, emb = lire_embeddings(source, [c for c, _ in lignes])
        if not gardes:
            continue
        chemins = [lignes[g][0] for g in gardes]
        verites = [lignes[g][1] for g in gardes]
        garde = None
        if masques.get(tranche):
            garde = set(Path(masques[tranche]).expanduser().read_text(encoding='utf-8').split())

        especes10, s10 = classer(emb, vecteurs, cles)
        p10 = np.stack(s10)
        labels, brutes = probas_iris9(dossier_iris, chemins, source / f'iris9-{tranche}.npy')
        especes9, p9 = fusionner_synonymes(brutes, labels)
        p9 = masquer(p9, especes9, garde)
        p10m = masquer(p10, especes10, garde)

        communes, a9, a10 = aligner(especes9, p9, especes10, p10)
        pred9 = [especes9[i] for i in p9.argmax(axis=1)]
        pred10 = [especes10[i] for i in p10.argmax(axis=1)]
        pred10m = [especes10[i] for i in p10m.argmax(axis=1)]
        conf9, conf10 = p9.max(axis=1), p10.max(axis=1)

        print(f'\n— {tranche} — {len(verites)} images, Iris 10 lu par {args.references}\n')
        print(f'  {"Iris 9 (masque, synonymes additionnés)":<48} {justesse(verites, pred9):.4f}')
        print(f'  {"Iris 10":<48} {justesse(verites, pred10):.4f}')
        print(f'  {"Iris 10 masqué comme Iris 9":<48} {justesse(verites, pred10m):.4f}')
        print(f'  {"arbitre parfait (inatteignable)":<48} {oracle(verites, pred9, pred10):.4f}')
        print('\n  règles, top-1 en validation croisée (réglé sur une moitié, lu sur l\'autre)')
        regles = {
            'Iris 10 s\'il est sûr, sinon Iris 9': (
                {s: regle_seuil(conf10, pred10, pred9, s) for s in SEUILS}),
            'Iris 10 masqué s\'il est sûr, sinon Iris 9': (
                {s: regle_seuil(p10m.max(axis=1), pred10m, pred9, s) for s in SEUILS}),
            'Iris 9 s\'il est sûr, sinon Iris 10': (
                {s: regle_seuil(conf9, pred9, pred10, s) for s in SEUILS}),
            'fusion p9^a · p10^(1−a)': (
                {a: fusion(communes, a9, a10, a) for a in POIDS}),
        }
        for nom, preds in regles.items():
            t1, choisis = croisee(verites, preds)
            print(f'    {nom:<46} {t1:.4f}   choisi {choisis[0]} / {choisis[1]}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
