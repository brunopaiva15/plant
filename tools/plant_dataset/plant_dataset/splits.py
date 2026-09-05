"""Répartition train / validation / test.

L'unité n'est pas l'image mais le groupe : toutes les photos d'une même
observation, et tout ce qui a été jugé quasi-doublon de l'une d'elles, vont
ensemble. Sinon le test verrait des images qu'il a déjà vues en train, et
la précision mesurée serait un mensonge.

L'affectation est déterministe (empreinte du groupe) : relancer la
répartition après avoir ajouté des images ne déplace pas les anciennes.
"""
from __future__ import annotations

import csv
import hashlib
from collections import defaultdict
from pathlib import Path

from .dedup import NEAR_THRESHOLD, UnionFind, near_duplicate_groups
from .manifest import STATUS_KEPT, ImageRecord

RATIOS = {'train': 0.8, 'val': 0.1, 'test': 0.1}


def group_key(r: ImageRecord) -> str:
    return f'{r.source}:{r.observation_id}' if r.observation_id else f'{r.source}:{r.source_id}'


def assign_groups(records: list[ImageRecord], threshold: int = NEAR_THRESHOLD) -> dict[str, str]:
    """Checksum → identifiant de groupe, après fusion des observations liées
    par un quasi-doublon."""
    uf = UnionFind()
    kept = [r for r in records if r.status == STATUS_KEPT]
    for r in kept:
        uf.union(group_key(r), r.checksum)
    # Deux observations dont des photos se ressemblent trop finissent ensemble.
    for group in near_duplicate_groups(kept, threshold).values():
        for r in group[1:]:
            uf.union(group[0].checksum, r.checksum)
    return {r.checksum: uf.find(r.checksum) for r in kept}


def split_for(group_id: str, ratios: dict[str, float] = RATIOS, salt: str = 'flora-v1') -> str:
    h = int(hashlib.sha256(f'{salt}:{group_id}'.encode()).hexdigest()[:8], 16) / 0xFFFFFFFF
    acc = 0.0
    for name, ratio in ratios.items():
        acc += ratio
        if h < acc:
            return name
    return list(ratios)[-1]


def make_splits(records: list[ImageRecord], threshold: int = NEAR_THRESHOLD) -> dict[str, str]:
    """Checksum → train | val | test, pour les images gardées."""
    groups = assign_groups(records, threshold)
    return {ck: split_for(g) for ck, g in groups.items()}


def write_splits(records: list[ImageRecord], path: str | Path, threshold: int = NEAR_THRESHOLD) -> dict[str, dict[str, int]]:
    splits = make_splits(records, threshold)
    groups = assign_groups(records, threshold)
    counts: dict[str, dict[str, int]] = defaultdict(lambda: defaultdict(int))
    with open(path, 'w', newline='', encoding='utf-8') as f:
        w = csv.writer(f)
        w.writerow(['path', 'species', 'internal_plant_id', 'split', 'group'])
        for r in sorted((r for r in records if r.status == STATUS_KEPT), key=lambda r: (r.species, r.path)):
            s = splits[r.checksum]
            w.writerow([r.path, r.species, r.internal_plant_id, s, groups[r.checksum]])
            counts[r.species][s] += 1
    return {k: dict(v) for k, v in counts.items()}
