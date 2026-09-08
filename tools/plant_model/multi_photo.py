#!/usr/bin/env python3
"""Ce que gagne le modèle quand l'utilisateur prend deux ou trois photos.

    python3 multi_photo.py --dataset ../plant_dataset/dataset --model .cache/v6_out

`CascadeIdentifier` reçoit déjà une `List<File>` et n'en exploite qu'une.
Demander une seconde photo est le levier principal de Pl@ntNet, et il ne
coûte aucun entraînement : il suffit de moyenner les sorties. Reste à savoir
ce qu'il rapporte vraiment — d'où cette mesure, avant d'écrire la moindre
ligne dans l'application.

Le jeu de test s'y prête sans rien collecter : `splits.csv` porte une
colonne `group` où toutes les photos d'une même observation sont réunies, et
la répartition ne sépare jamais un groupe. Deux photos du même groupe, ce
sont deux photos de la même plante — le scénario exact.

**Ce que la mesure surestime, et qu'il faut garder en tête :** les photos
d'une observation ont été prises dans la même séance, sous la même lumière,
souvent au même endroit. Un utilisateur qui photographie une feuille puis la
plante entière apporte plus de diversité, mais aussi plus d'écart de
cadrage. Les quasi-doublons ayant déjà été écartés à la collecte (empreinte
perceptuelle, distance ≤ 6), les photos restantes sont visuellement
distinctes ; le chiffre reste un plafond optimiste, pas une promesse.

Deux façons de combiner sont comparées : la moyenne des probabilités, et la
moyenne géométrique (moyenne des logarithmes). La première pardonne à une
photo ratée, la seconde exige que les deux soient d'accord.
"""
from __future__ import annotations

import argparse
import csv
import random
from collections import defaultdict

import numpy as np

from compare_models import load_model, predict

THRESHOLD = 0.70  # le seuil de l'application (FallbackPolicy)


def test_groups(dataset, min_photos: int):
    """Les observations de test ayant assez de photos, avec leur espèce."""
    groups = defaultdict(list)
    meta = {}
    with open(dataset / 'splits.csv', newline='', encoding='utf-8') as f:
        for row in csv.DictReader(f):
            if row['split'] != 'test':
                continue
            path = dataset / row['path']
            if path.exists():
                groups[row['group']].append(str(path))
                meta[row['group']] = (row['internal_plant_id'], row.get('captive') == '1')
    return {g: (paths, *meta[g]) for g, paths in groups.items() if len(paths) >= min_photos}


def combine(probs: list[np.ndarray], geometric: bool) -> np.ndarray:
    """Fusionne les avis de plusieurs photos en un seul."""
    stack = np.stack(probs)
    if geometric:
        # La moyenne des logarithmes : une espèce que l'une des photos juge
        # très improbable ne remonte pas, même si l'autre en est sûre.
        return np.exp(np.mean(np.log(np.clip(stack, 1e-9, None)), axis=0))
    return stack.mean(axis=0)


def like_app(probs: list[np.ndarray], top_k: int, cut: float = 0.01) -> np.ndarray:
    """Exactement ce que l'application peut calculer, et rien de plus.

    `LocalPlantModel.classify` ne rend que les `top_k` premiers candidats
    au-dessus de `cut` : la cascade ne voit jamais le vecteur entier. Une
    espèce absente d'une liste n'y vaut pas zéro — elle vaut *au plus* le
    plus petit score rendu, et au plus `cut`. On lui donne cette borne, qui
    la pénalise sans l'annuler.

    Le résultat est renormalisé. Moyenner aplatit la distribution et fait
    chuter la confiance du premier candidat, donc le taux d'acceptation,
    alors même que le classement s'améliore. La renormalisation est une
    division par une constante : elle ne change aucun ordre, elle rend
    seulement les scores comparables à ceux d'une photo seule — et donc au
    seuil de `FallbackPolicy`.
    """
    kept = []
    for p in probs:
        order = np.argsort(-p)[:top_k]
        order = [i for i in order if p[i] >= cut]
        floor = min(float(p[order[-1]]), cut) if order else cut
        kept.append(({int(i): float(p[i]) for i in order}, floor))
    union = sorted({i for d, _ in kept for i in d})
    if not union:
        return np.zeros_like(probs[0])
    merged = np.zeros_like(probs[0])
    for i in union:
        merged[i] = np.exp(np.mean([np.log(max(d.get(i, floor), 1e-9)) for d, floor in kept]))
    total = merged.sum()
    return merged / total if total > 0 else merged


def measure(cached, labels, k: int, geometric: bool, only_captive: bool | None = None,
            app_top_k: int | None = None) -> dict:
    seen = hit1 = hit3 = accepted = accepted_ok = 0
    for probs, truth, captive in cached:
        if only_captive is not None and captive != only_captive:
            continue
        if app_top_k is not None:
            merged = like_app(probs[:k], app_top_k)
        else:
            merged = combine(probs[:k], geometric) if k > 1 else probs[0]
        order = np.argsort(-merged)[:3]
        top = [labels[i] for i in order]
        seen += 1
        hit1 += top[0] == truth
        hit3 += truth in top
        if merged[order[0]] >= THRESHOLD:
            accepted += 1
            accepted_ok += top[0] == truth
    if not seen:
        return {}
    return {
        'observations': seen,
        'top1': round(hit1 / seen, 4),
        'top3': round(hit3 / seen, 4),
        'accepted_rate': round(accepted / seen, 4),
        'precision_when_accepted': round(accepted_ok / accepted, 4) if accepted else None,
    }


def show(title: str, rows: list[tuple[str, dict]]) -> None:
    print(f'— {title}')
    base = rows[0][1]
    for label, r in rows:
        if not r:
            continue
        delta = f"  ({r['top1'] - base['top1']:+.4f})" if r is not base else ''
        print(f"   {label:24s} top1 {r['top1']}  top3 {r['top3']}  "
              f"seuil {THRESHOLD} → {r['accepted_rate']} acceptées, "
              f"précision {r['precision_when_accepted']}{delta}")
    print()


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--dataset', default='../plant_dataset/dataset')
    ap.add_argument('--model', default='.cache/v6_out')
    ap.add_argument('--photos', type=int, default=3, help='jusqu\'à combien de photos combiner')
    ap.add_argument('--sample', type=int, default=2500, help='observations tirées au hasard')
    ap.add_argument('--seed', type=int, default=20260905)
    args = ap.parse_args()

    from pathlib import Path
    model = load_model(Path(args.model))
    groups = test_groups(Path(args.dataset), args.photos)
    keys = sorted(groups)
    rng = random.Random(args.seed)
    if args.sample and len(keys) > args.sample:
        keys = rng.sample(keys, args.sample)
    print(f"modèle v{model['version']} — {len(keys)} observations d'au moins {args.photos} photos\n")

    cached = []
    for n, key in enumerate(keys, 1):
        paths, truth, captive = groups[key]
        if truth not in model['index']:
            continue
        cached.append(([predict(model, p) for p in paths[:args.photos]], truth, captive))
        if n % 250 == 0:
            print(f'  {n}/{len(keys)} observations', flush=True)
    print()

    for geometric in (False, True):
        nom = 'moyenne géométrique' if geometric else 'moyenne des probabilités'
        show(f'toutes espèces — {nom}',
             [(f'{k} photo{"s" if k > 1 else ""}', measure(cached, model['labels'], k, geometric))
              for k in range(1, args.photos + 1)])
    for top_k in (5, 40):
        show(f'toutes espèces — comme l\'app (listes de {top_k}, renormalisé)',
             [(f'{k} photo{"s" if k > 1 else ""}', measure(cached, model['labels'], k, False, app_top_k=top_k))
              for k in range(1, args.photos + 1)])
        show(f'plantes cultivées — comme l\'app (listes de {top_k}, renormalisé)',
             [(f'{k} photo{"s" if k > 1 else ""}',
               measure(cached, model['labels'], k, False, only_captive=True, app_top_k=top_k))
              for k in range(1, args.photos + 1)])
    show('plantes cultivées — moyenne des probabilités',
         [(f'{k} photo{"s" if k > 1 else ""}', measure(cached, model['labels'], k, False, only_captive=True))
          for k in range(1, args.photos + 1)])
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
