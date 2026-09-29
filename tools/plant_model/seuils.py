#!/usr/bin/env python3
"""L'étape 12 : quand Iris 10, seul ou fusionné avec Iris 9, peut affirmer.

    python3 seuils.py --embeddings ~/plant-data/iris10-int/banc-e10

**Ce que l'application fait d'un score** (`FallbackPolicy`,
`lib/domain/identification/identification_policy.dart`) : elle **affirme**
le premier candidat s'il atteint `acceptThreshold` (0,70) avec
`minMargin` (0,25) d'avance sur le deuxième, elle **propose** la liste
au-dessus de 0,25, et elle se tait sous 0,10. Dehors, le modèle local
n'affirme jamais.

**Un seuil ne se transporte pas d'un modèle à l'autre** — c'est écrit dans
la politique elle-même. Le score de la fusion n'est pas celui d'Iris 9 :
0,70 n'y veut pas dire la même chose. Ce script rend, pour Iris 9 tel que
l'application le lit, Iris 10 et leur fusion :

- **la courbe** : pour chaque seuil, la part des photos affirmées
  (l'autonomie) et la part de ces réponses qui sont justes ;
- **l'affirmation à tort** sur `ood_plante` : des plantes qu'aucun des deux
  modèles ne peut nommer, lues avec le masque d'intérieur. Toute
  affirmation y est une erreur — celle qui coûte le plus, parce qu'elle
  s'affiche sûre d'elle (§ 12.7 de `docs/09`).

**Le seuil recommandé** est le plus bas qui fait au moins aussi bien
qu'Iris 9 aujourd'hui (0,70 et 0,25) sur les deux fronts : justesse des
réponses affirmées en indoor, affirmation à tort hors répertoire. Il est
choisi sur une moitié du banc et lu sur l'autre, dans les deux sens.

Demande TensorFlow pour Iris 9 (`~/venv`), comme `arbitre.py`, dont il
reprend les sorties en cache.
"""
from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np

from arbitre import aligner, fusionner_synonymes, masquer, moities, probas_iris9
from voisins import (canonique, charger_references, classer, lire_banc, lire_embeddings,
                     restreindre)

SEUILS = tuple(round(x, 2) for x in np.arange(0.30, 0.96, 0.05))
MARGE = 0.25
SEUIL_APP = 0.70


# --------------------------------------------------------------------------
# Lectures pures
# --------------------------------------------------------------------------

def normaliser_lignes(p: np.ndarray) -> np.ndarray:
    s = p.sum(axis=1, keepdims=True)
    return np.divide(p, s, out=np.zeros_like(p, dtype=np.float64), where=s > 0)


def fusion_probas(p9: np.ndarray, p10: np.ndarray, poids: float = 0.5,
                  plancher: float = 1e-6) -> np.ndarray:
    """`p9^poids · p10^(1−poids)`, **renormalisé** : une distribution, que
    la politique de l'application peut lire comme celle d'Iris 9."""
    log = (poids * np.log(np.maximum(p9, plancher))
           + (1 - poids) * np.log(np.maximum(p10, plancher)))
    log -= log.max(axis=1, keepdims=True)
    return normaliser_lignes(np.exp(log))


def tete(probas: np.ndarray) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    """(indice du premier, son score, son avance sur le deuxième)."""
    ordre = np.argsort(-probas, axis=1)[:, :2]
    rangs = np.arange(len(probas))
    s1 = probas[rangs, ordre[:, 0]]
    s2 = probas[rangs, ordre[:, 1]] if probas.shape[1] > 1 else np.zeros(len(probas))
    return ordre[:, 0], s1, s1 - s2


def affirmees(s1: np.ndarray, marge: np.ndarray, seuil: float,
              marge_min: float = MARGE) -> np.ndarray:
    """Le masque des photos que la politique affirmerait."""
    return (s1 >= seuil) & (marge >= marge_min)


def courbe(justes: np.ndarray, s1: np.ndarray, marge: np.ndarray,
           seuils=SEUILS, indices=None) -> list[dict]:
    """Pour chaque seuil : autonomie, et justesse des réponses affirmées."""
    idx = np.arange(len(justes)) if indices is None else np.asarray(indices)
    sortie = []
    for s in seuils:
        a = affirmees(s1[idx], marge[idx], s)
        n = int(a.sum())
        sortie.append({'seuil': s, 'autonomie': n / len(idx) if len(idx) else 0.0,
                       'justesse': float(justes[idx][a].mean()) if n else None})
    return sortie


def a_tort(s1: np.ndarray, marge: np.ndarray, seuil: float, indices=None) -> float:
    """La part des photos hors répertoire affirmées — toutes à tort."""
    idx = np.arange(len(s1)) if indices is None else np.asarray(indices)
    return float(affirmees(s1[idx], marge[idx], seuil).mean()) if len(idx) else 0.0


def recommander(candidat: dict, reference: dict, seuils=SEUILS) -> float | None:
    """Le plus bas seuil du candidat qui égale la référence sur les deux
    fronts : justesse des réponses affirmées, affirmation à tort.

    `candidat` et `reference` : {'justes', 's1', 'marge', 'ood_s1',
    'ood_marge', 'indices', 'ood_indices'}. La référence est lue à son seuil
    d'aujourd'hui, `SEUIL_APP`.
    """
    def lire(d, seuil):
        c = courbe(d['justes'], d['s1'], d['marge'], [seuil], d.get('indices'))[0]
        return c['justesse'], a_tort(d['ood_s1'], d['ood_marge'], seuil, d.get('ood_indices'))

    juste_ref, tort_ref = lire(reference, SEUIL_APP)
    for s in sorted(seuils):
        juste, tort = lire(candidat, s)
        if juste is not None and juste_ref is not None and juste >= juste_ref and tort <= tort_ref:
            return s
    return None


# --------------------------------------------------------------------------
# Le banc
# --------------------------------------------------------------------------

def lire_tranche(tranche, args, cles, vecteurs, source, dossier_iris, garde):  # pragma: no cover
    lignes = lire_banc(Path(args.banc).expanduser(), tranche)
    gardes, emb = lire_embeddings(source, [c for c, _ in lignes])
    chemins = [lignes[g][0] for g in gardes]
    verites = [lignes[g][1] for g in gardes]
    especes10, s10 = classer(emb, vecteurs, cles)
    labels, brutes = probas_iris9(dossier_iris, chemins, source / f'iris9-{tranche}.npy')
    especes9, p9 = fusionner_synonymes(brutes, labels)
    p9 = masquer(p9, especes9, garde)
    communes, a9, a10 = aligner(especes9, p9, especes10, masquer(np.stack(s10), especes10, garde))
    lectures = {'Iris 9': (especes9, p9),
                'Iris 10': (communes, normaliser_lignes(a10)),
                'fusion': (communes, fusion_probas(a9, a10, args.poids))}
    sortie = {}
    for nom, (especes, p) in lectures.items():
        i, s1, marge = tete(p)
        sortie[nom] = {'justes': np.array([especes[k] == v for k, v in zip(i, verites)]),
                       's1': s1, 'marge': marge}
    return sortie


def main() -> int:  # pragma: no cover - demande le cache, le banc et TensorFlow
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--banc', default='benchmark.csv')
    ap.add_argument('--cache', default='~/plant-data/bioclip')
    ap.add_argument('--embeddings', required=True)
    ap.add_argument('--references', default='centroide+references-centroides-potseul')
    ap.add_argument('--iris', default='../../assets/model')
    ap.add_argument('--poids', type=float, default=0.5, help='la part d\'Iris 9 dans la fusion')
    ap.add_argument('--masque-interieur', default='../plant_dataset/masque_indoor.txt')
    ap.add_argument('--masque-exterieur', default='../plant_dataset/masque_outdoor.txt')
    args = ap.parse_args()

    source = Path(args.embeddings).expanduser()
    dossier_iris = Path(args.iris).expanduser()
    expose = {canonique(l) for l in (dossier_iris / 'labels.txt').read_text(encoding='utf-8').split()}
    cles, vecteurs = restreindre(*charger_references(Path(args.cache).expanduser(), args.references),
                                 expose)
    interieur = set(Path(args.masque_interieur).expanduser().read_text(encoding='utf-8').split())
    exterieur = set(Path(args.masque_exterieur).expanduser().read_text(encoding='utf-8').split())

    indoor = lire_tranche('indoor', args, cles, vecteurs, source, dossier_iris, interieur)
    outdoor = lire_tranche('outdoor', args, cles, vecteurs, source, dossier_iris, exterieur)
    ood = lire_tranche('ood_plante', args, cles, vecteurs, source, dossier_iris, interieur)

    print(f'\nmarge minimale {MARGE} ; indoor et ood_plante sous le masque d\'intérieur, '
          f'outdoor sous celui d\'extérieur\n')
    for nom in ('Iris 9', 'Iris 10', 'fusion'):
        print(f'— {nom} —   seuil : autonomie / justesse indoor ; outdoor ; affirmées à tort hors répertoire')
        ci = courbe(indoor[nom]['justes'], indoor[nom]['s1'], indoor[nom]['marge'])
        co = courbe(outdoor[nom]['justes'], outdoor[nom]['s1'], outdoor[nom]['marge'])
        for a, b in zip(ci, co):
            t = a_tort(ood[nom]['s1'], ood[nom]['marge'], a['seuil'])
            j = lambda c: f"{c['justesse']:.3f}" if c['justesse'] is not None else '  —  '
            print(f"   {a['seuil']:.2f} : {a['autonomie']:.3f} / {j(a)} ; "
                  f"{b['autonomie']:.3f} / {j(b)} ; {t:.3f}"
                  + ('   ← l\'application aujourd\'hui' if nom == 'Iris 9' and a['seuil'] == SEUIL_APP else ''))
        print()

    # Le seuil recommandé, réglé sur une moitié et lu sur l'autre.
    ai, bi = moities(len(indoor['fusion']['justes']))
    ao, bo = moities(len(ood['fusion']['s1']))
    for nom in ('fusion', 'Iris 10'):
        print(f'seuil recommandé pour {nom} (égaler Iris 9 à {SEUIL_APP} : justesse indoor, '
              f'affirmation à tort) :')
        for (apprend, note, apprend_o, note_o) in ((ai, bi, ao, bo), (bi, ai, bo, ao)):
            cand = {**indoor[nom], 'ood_s1': ood[nom]['s1'], 'ood_marge': ood[nom]['marge'],
                    'indices': apprend, 'ood_indices': apprend_o}
            ref = {**indoor['Iris 9'], 'ood_s1': ood['Iris 9']['s1'], 'ood_marge': ood['Iris 9']['marge'],
                   'indices': apprend, 'ood_indices': apprend_o}
            s = recommander(cand, ref)
            if s is None:
                print('   aucun seuil n\'y parvient sur cette moitié')
                continue
            lu = courbe(indoor[nom]['justes'], indoor[nom]['s1'], indoor[nom]['marge'], [s], note)[0]
            lu9 = courbe(indoor['Iris 9']['justes'], indoor['Iris 9']['s1'], indoor['Iris 9']['marge'],
                         [SEUIL_APP], note)[0]
            print(f"   choisi {s:.2f} sur une moitié ; lu sur l'autre : autonomie {lu['autonomie']:.3f} "
                  f"(Iris 9 {lu9['autonomie']:.3f}), justesse {lu['justesse']:.3f} "
                  f"(Iris 9 {lu9['justesse']:.3f}), à tort "
                  f"{a_tort(ood[nom]['s1'], ood[nom]['marge'], s, note_o):.3f} "
                  f"(Iris 9 {a_tort(ood['Iris 9']['s1'], ood['Iris 9']['marge'], SEUIL_APP, note_o):.3f})")
        print()
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
