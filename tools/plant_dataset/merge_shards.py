#!/usr/bin/env python3
"""Fusionne des collectes menées en parallèle sur des parts disjointes.

    python3 merge_shards.py --out dataset shard0 shard1 shard2
    python3 build_dataset.py --out dataset --skip-fetch --plants plants.csv

Collecter 1 558 espèces d'affilée occupe un cœur et laisse le réseau
attendre. Découpé en parts disjointes, le même travail tient sur les quatre
cœurs de la machine. Les parts ne se chevauchent pas — une espèce est dans
une seule — donc la fusion est un déplacement de dossiers et une
concaténation de manifestes.

La déduplication, la répartition et les statistiques ne sont *pas* refaites
ici : elles portent sur l'ensemble et c'est `build_dataset.py --skip-fetch`
qui s'en charge, sur le jeu fusionné. C'est important pour les doublons
entre espèces, qu'aucune part ne peut voir seule.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

# Écrits par la finalisation de chaque part ; refaits sur l'ensemble.
PER_RUN = {'manifest.jsonl', 'splits.csv', 'stats.json', 'ATTRIBUTIONS.md', 'attributions.csv'}
CACHES = ('species.json', 'species_inat.json')


def move_into(source: Path, target: Path) -> int:
    """Déplace `source` sur `target`, en fusionnant ce qui existe des deux
    côtés. Rend le nombre de fichiers déplacés.

    Deux dossiers portent le même nom dans plusieurs parts, pour deux raisons
    différentes. Les dossiers de statut (`_rejected`, `_duplicates`,
    `_review`) existent dans chacune. Et deux noms du catalogue peuvent
    donner le même dossier d'espèce : `Citrus × sinensis` y figurait deux
    fois, et le découpage en parts a envoyé les deux copies à des parts
    différentes. Dans les deux cas, écraser la destination perdrait des
    images ; on descend donc dans l'arbre.

    Quand deux fichiers portent le même nom, c'est la même image : le nom est
    le début de son empreinte SHA-256. Écraser est alors sans effet.
    """
    if source.is_dir() and target.is_dir():
        moved = 0
        for child in sorted(source.iterdir()):
            moved += move_into(child, target / child.name)
        source.rmdir()
        return moved
    target.parent.mkdir(parents=True, exist_ok=True)
    source.replace(target)
    return 1


def merge_caches(shards: list[Path], out: Path) -> dict[str, int]:
    """Les résolutions de noms coûtent des heures de réseau. Chaque part a
    résolu les siennes ; le jeu fusionné les garde toutes."""
    sizes = {}
    for name in CACHES:
        merged: dict = {}
        for shard in shards:
            path = shard / name
            if path.exists():
                merged.update(json.loads(path.read_text()))
        (out / name).write_text(json.dumps(merged, ensure_ascii=False, indent=1))
        sizes[name] = len(merged)
    return sizes


def merge(shards: list[Path], out: Path) -> dict:
    out.mkdir(parents=True, exist_ok=True)
    lines, moved = 0, 0
    with open(out / 'manifest.jsonl', 'a', encoding='utf-8') as manifest:
        for shard in shards:
            source = shard / 'manifest.jsonl'
            if not source.exists():
                raise SystemExit(f'{shard} : pas de manifeste, la part n\'a rien produit')
            for line in source.read_text(encoding='utf-8').splitlines():
                if line.strip():
                    manifest.write(line + '\n')
                    lines += 1
            for entry in sorted(shard.iterdir()):
                if entry.name in PER_RUN or entry.name in CACHES:
                    continue
                moved += move_into(entry, out / entry.name)
    return {'lignes': lines, 'dossiers': moved}


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('shards', nargs='+', help='dossiers des parts à fusionner')
    ap.add_argument('--out', default='dataset', help='dossier du jeu fusionné')
    args = ap.parse_args()

    shards = [Path(s) for s in args.shards]
    out = Path(args.out)
    for shard in shards:
        if not shard.is_dir():
            raise SystemExit(f'{shard} : dossier introuvable')
        if shard.resolve() == out.resolve():
            raise SystemExit('une part ne peut pas être le jeu fusionné')

    counts = merge(shards, out)
    caches = merge_caches(shards, out)
    print(f'{counts["lignes"]} lignes de manifeste, {counts["dossiers"]} dossiers déplacés vers {out}')
    print('  ' + ', '.join(f'{k} : {v} noms' for k, v in caches.items()))
    print(f'\nÀ suivre, sur l\'ensemble :\n'
          f'  python3 build_dataset.py --out {out} --plants plants.csv --skip-fetch')
    return 0


if __name__ == '__main__':
    sys.exit(main())
