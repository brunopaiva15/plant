#!/usr/bin/env python3
"""Compare deux modèles exportés sur les mêmes images, à armes égales.

    python3 compare_models.py --dataset ../plant_dataset/dataset \\
        --a ../../assets/model --b .cache/v6_out --sample 6000

Les chiffres de `model.json` de deux versions ne se comparent pas : ils ont
été mesurés sur des jeux de test différents, chacun tiré de sa propre
collecte. Un modèle qui gagne trois points a peut-être seulement reçu un
test plus facile.

Ici les deux modèles voient **les mêmes images** — celles du test du jeu
courant — et l'on ne retient que les espèces qu'ils connaissent **tous les
deux**. C'est la seule mesure qui dise si remplacer le modèle livré fait
gagner ou perdre l'utilisateur sur les plantes qu'il avait déjà.

Trois lectures sont rendues :

- **classes communes** : le match nul, sur le terrain partagé ;
- **plantes cultivées** : les photos en pot, c'est-à-dire ce que
  l'application voit vraiment ;
- **couverture** : ce que le nouveau modèle sait nommer et que l'ancien
  ignorait, mesuré sur ses propres images.

Le prétraitement de chaque modèle est lu dans son `model.json` : deux
versions peuvent avoir été entraînées avec des tailles différentes, et les
appliquer à l'envers coûterait plusieurs points (§ 6.2 de docs/09).
"""
from __future__ import annotations

import argparse
import csv
import json
import random
from collections import Counter
from pathlib import Path

import numpy as np
import tensorflow as tf


def load_model(folder: Path):
    """Un modèle exporté : son interpréteur, ses étiquettes, sa recette de
    prétraitement."""
    meta = json.loads((folder / 'model.json').read_text())
    labels = (folder / 'labels.txt').read_text().split()
    interpreter = tf.lite.Interpreter(model_path=str(folder / 'plants.tflite'))
    interpreter.allocate_tensors()
    return {
        'name': folder.name,
        'version': meta.get('version', '?'),
        'labels': labels,
        'index': {c: i for i, c in enumerate(labels)},
        'input_size': int(meta.get('input_size', 224)),
        'load_size': int(meta.get('load_size', 256)),
        'interpreter': interpreter,
        'in': interpreter.get_input_details()[0],
        'out': interpreter.get_output_details()[0],
    }


def prepare(path: str, load_size: int, input_size: int) -> np.ndarray:
    """Le carré central réduit à `load_size`, puis recadré à `input_size` —
    exactement la recette écrite dans `model.json` et appliquée par
    l'application."""
    image = tf.io.decode_jpeg(tf.io.read_file(path), channels=3)
    side = tf.reduce_min(tf.shape(image)[:2])
    image = tf.image.resize_with_crop_or_pad(image, side, side)
    image = tf.image.resize(image, [load_size, load_size])
    offset = (load_size - input_size) // 2
    image = tf.image.crop_to_bounding_box(image, offset, offset, input_size, input_size)
    return tf.cast(image, tf.float32).numpy()[None, ...]


def predict(model, path: str) -> np.ndarray:
    x = prepare(path, model['load_size'], model['input_size'])
    if model['in']['dtype'] != np.float32:
        x = x.astype(model['in']['dtype'])
    model['interpreter'].set_tensor(model['in']['index'], x)
    model['interpreter'].invoke()
    return model['interpreter'].get_tensor(model['out']['index'])[0]


def score(rows, model, restrict: set[str] | None) -> dict:
    """Top-1, top-3 et taux d'acceptation à 0,70 — le seuil de l'application."""
    seen = hit1 = hit3 = accepted = accepted_ok = 0
    for path, truth in rows:
        if truth not in model['index']:
            continue
        probs = predict(model, path)
        if restrict is not None:
            # À armes égales : on masque les classes que l'autre modèle
            # n'a pas. Sans cela, le plus large est puni pour en savoir plus.
            mask = np.zeros_like(probs)
            for c in restrict:
                i = model['index'].get(c)
                if i is not None:
                    mask[i] = 1.0
            probs = probs * mask
        order = np.argsort(-probs)[:3]
        top = [model['labels'][i] for i in order]
        seen += 1
        hit1 += top[0] == truth
        hit3 += truth in top
        if probs[order[0]] >= 0.70:
            accepted += 1
            accepted_ok += top[0] == truth
    return {
        'images': seen,
        'top1': round(hit1 / seen, 4) if seen else None,
        'top3': round(hit3 / seen, 4) if seen else None,
        'accepted_rate': round(accepted / seen, 4) if seen else None,
        'precision_when_accepted': round(accepted_ok / accepted, 4) if accepted else None,
    }


def read_test(dataset: Path) -> list[tuple[str, str, bool]]:
    rows = []
    with open(dataset / 'splits.csv', newline='', encoding='utf-8') as f:
        for row in csv.DictReader(f):
            if row['split'] != 'test':
                continue
            path = dataset / row['path']
            if path.exists():
                rows.append((str(path), row['internal_plant_id'], row.get('captive') == '1'))
    return rows


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--dataset', default='../plant_dataset/dataset')
    ap.add_argument('--a', required=True, help='modèle de référence (celui qui est livré)')
    ap.add_argument('--b', required=True, help='modèle candidat')
    ap.add_argument('--sample', type=int, default=6000, help='images de test tirées au hasard, 0 = toutes')
    ap.add_argument('--seed', type=int, default=20260905)
    args = ap.parse_args()

    a, b = load_model(Path(args.a)), load_model(Path(args.b))
    rows = read_test(Path(args.dataset))
    shared = set(a['index']) & set(b['index'])
    only_b = set(b['index']) - set(a['index'])
    print(f"A = v{a['version']} ({len(a['labels'])} classes)   B = v{b['version']} ({len(b['labels'])} classes)")
    print(f'{len(shared)} classes communes, {len(only_b)} connues de B seul, {len(set(a["index"]) - set(b["index"]))} de A seul\n')

    common = [(p, t) for p, t, _ in rows if t in shared]
    captive = [(p, t) for p, t, c in rows if t in shared and c]
    new = [(p, t) for p, t, _ in rows if t in only_b]
    rng = random.Random(args.seed)

    def take(items, n):
        return rng.sample(items, n) if n and len(items) > n else items

    for title, subset, restrict in (
        ('classes communes', take(common, args.sample), shared),
        ('plantes cultivées, classes communes', take(captive, args.sample // 3), shared),
    ):
        print(f'— {title} ({len(subset)} images)')
        for model in (a, b):
            r = score(subset, model, restrict)
            print(f"   v{model['version']} : top1 {r['top1']}  top3 {r['top3']}  "
                  f"seuil 0,70 → {r['accepted_rate']} acceptées, précision {r['precision_when_accepted']}")
        print()

    if new:
        subset = take(new, args.sample // 3)
        r = score(subset, b, None)
        espèces = len({t for _, t in subset})
        print(f'— couverture gagnée : {espèces} espèces que v{a["version"]} ne connaît pas ({len(subset)} images)')
        print(f"   v{b['version']} : top1 {r['top1']}  top3 {r['top3']}")
        print(f'   (v{a["version"]} y est nécessairement à 0 : ces espèces ne sont pas dans ses sorties)')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
