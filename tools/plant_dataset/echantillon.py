#!/usr/bin/env python3
"""Un petit jeu de données taillé pour mesurer une machine, pas un modèle.

    python3 echantillon.py --dataset ~/plant-data/dataset-v8-indoor \\
        --out ~/plant-data/dataset-echantillon

Déplacer des dizaines de gigaoctets pour découvrir qu'une machine n'est pas
plus rapide, c'est une journée perdue. Ce script prélève quelques centaines
de mégaoctets qui suffisent à mesurer un débit : mêmes images, même tuyau,
même recette — seul le nombre de classes change.

**Et le nombre de classes ne fausse presque rien.** À 320 px, le dorsal
MobileNetV3Large coûte environ 0,45 GFLOP par image ; la tête, `960 ×
classes`, en coûte 0,01 à 5 376 classes. Moins de 3 % du calcul. Un débit
mesuré sur 120 classes décrit donc bien la machine, à quelques pour cent
près — ce qui est très au-dessous de l'écart qu'on cherche à voir.

Ce qui est copié respecte les seuils de `train.py` (`--min-train`,
`--min-val`) : les classes retenues sont celles qui ont de quoi les passer,
sinon le modèle les écarterait et l'échantillon serait plus petit qu'annoncé.
"""
from __future__ import annotations

import argparse
import csv
import json
import shutil
from collections import defaultdict
from pathlib import Path


def lire(dataset: Path) -> dict[str, dict[str, list[dict]]]:
    """{internal_id: {split: [lignes]}}, dans l'ordre du fichier."""
    par_classe: dict[str, dict[str, list[dict]]] = defaultdict(lambda: defaultdict(list))
    with open(dataset / 'splits.csv', newline='', encoding='utf-8') as f:
        for ligne in csv.DictReader(f):
            par_classe[ligne['internal_plant_id']][ligne['split']].append(ligne)
    return par_classe


def choisir(par_classe: dict, classes: int, train: int, val: int, test: int) -> list[str]:
    """Les classes les mieux nourries, pour qu'aucune ne tombe sous un seuil.

    On prend les plus grandes plutôt qu'un tirage au sort : l'échantillon ne
    sert pas à mesurer une justesse, seulement un débit, et une classe
    écartée par `--min-train` serait du travail de copie pour rien.
    """
    eligibles = [
        (len(s['train']), c) for c, s in par_classe.items()
        if len(s['train']) >= train and len(s['val']) >= val and len(s['test']) >= test
    ]
    eligibles.sort(key=lambda e: (-e[0], e[1]))
    return [c for _, c in eligibles[:classes]]


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--dataset', required=True)
    ap.add_argument('--out', required=True)
    ap.add_argument('--classes', type=int, default=120)
    ap.add_argument('--train', type=int, default=60)
    ap.add_argument('--val', type=int, default=5)
    ap.add_argument('--test', type=int, default=5)
    args = ap.parse_args()

    dataset = Path(args.dataset).expanduser()
    out = Path(args.out).expanduser()
    if not (dataset / 'splits.csv').exists():
        raise SystemExit(f'splits.csv introuvable dans {dataset}')

    par_classe = lire(dataset)
    gardees = choisir(par_classe, args.classes, args.train, args.val, args.test)
    if not gardees:
        raise SystemExit('aucune classe ne tient les seuils demandés ; baisse --train / --val')
    if len(gardees) < args.classes:
        print(f'{len(gardees)} classes seulement tiennent les seuils, au lieu de {args.classes}')

    out.mkdir(parents=True, exist_ok=True)
    quotas = {'train': args.train, 'val': args.val, 'test': args.test}
    lignes, especes, octets, manquantes = [], {}, 0, 0
    for classe in gardees:
        for split, quota in quotas.items():
            for ligne in par_classe[classe][split][:quota]:
                source = dataset / ligne['path']
                if not source.exists():
                    manquantes += 1
                    continue
                cible = out / ligne['path']
                cible.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(source, cible)
                octets += cible.stat().st_size
                lignes.append(ligne)
                especes[ligne['internal_plant_id']] = ligne['species']

    with open(out / 'splits.csv', 'w', newline='', encoding='utf-8') as f:
        w = csv.writer(f)
        w.writerow(['path', 'species', 'internal_plant_id', 'split', 'group', 'captive'])
        for l in lignes:
            w.writerow([l['path'], l['species'], l['internal_plant_id'],
                        l['split'], l.get('group', ''), l.get('captive', '0')])

    # `train.py` lit les noms d'espèces dans le manifeste, à l'export. Un
    # manifeste minimal suffit : l'échantillon ne sert pas à livrer un modèle.
    with open(out / 'manifest.jsonl', 'w', encoding='utf-8') as f:
        for interne, espece in sorted(especes.items()):
            f.write(json.dumps({'internal_plant_id': interne, 'species': espece},
                               ensure_ascii=False) + '\n')

    if manquantes:
        print(f'{manquantes} image(s) annoncée(s) par splits.csv et absente(s) du disque, ignorée(s)')
    print(f'{len(gardees)} classes, {len(lignes)} images, {octets / 1e6:.0f} Mo → {out}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
