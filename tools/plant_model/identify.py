#!/usr/bin/env python3
"""Passe une photo dans un ou plusieurs modèles exportés et montre leurs avis.

    python3 identify.py photo.jpg --model ../../assets/model --model .cache/v6_out

Le rejeu d'une vraie photo, prise par quelqu'un dans son salon, dit des
choses qu'aucune moyenne sur le jeu de test ne dit : ce que le modèle répond
quand la plante est de travers, le fond encombré, la lumière d'intérieur.
C'est ainsi qu'on a trouvé le yucca pris pour du maïs (§ 6.3 de docs/09).

La décision affichée est celle de `FallbackPolicy` côté application : le
modèle ne répond seul que si sa confiance dépasse le seuil et que l'écart
avec le second candidat est suffisant.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

import numpy as np

from compare_models import load_model, predict

THRESHOLD, MIN_MARGIN = 0.70, 0.25


def species_names(folder: Path) -> dict:
    meta = json.loads((folder / 'model.json').read_text())
    return meta.get('species', {})


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('photos', nargs='+')
    ap.add_argument('--model', action='append', required=True, help='dossier d\'un modèle exporté ; répétable')
    ap.add_argument('--top', type=int, default=5)
    args = ap.parse_args()

    models = [(load_model(Path(m)), species_names(Path(m))) for m in args.model]
    for photo in args.photos:
        print(f'\n=== {photo} ===')
        for model, names in models:
            probs = predict(model, photo)
            order = np.argsort(-probs)[:max(args.top, 2)]
            best, second = probs[order[0]], probs[order[1]]
            seul = best >= THRESHOLD and (best - second) >= MIN_MARGIN
            print(f"\n  v{model['version']} ({len(model['labels'])} classes) — "
                  f"{'répond seule' if seul else 'hésite, l’app consulterait Pl@ntNet'}"
                  f"  [confiance {best:.3f}, écart {best - second:.3f}]")
            for rank, i in enumerate(order[:args.top], 1):
                internal = model['labels'][i]
                print(f'    {rank}. {names.get(internal, internal):38s} {probs[i]:6.1%}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
