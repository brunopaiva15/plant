"""Répartition train / validation / test.

L'unité n'est pas l'image mais le groupe : toutes les photos d'une même
observation, et tout ce qui a été jugé quasi-doublon de l'une d'elles, vont
ensemble. Sinon le test verrait des images qu'il a déjà vues en train, et
la précision mesurée serait un mensonge.

L'affectation est déterministe (empreinte du groupe) : relancer la
répartition après avoir ajouté des images ne déplace pas les anciennes.

Elle ne regarde pas l'espèce, et c'est son défaut : une espèce dont les
photos viennent de peu d'observations peut voir ses tirages tomber tous du
même côté, et se faire écarter du modèle faute de validation.
`repair_species_coverage` répare ce seul cas, sans toucher au reste.
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


def repair_species_coverage(records: list[ImageRecord], splits: dict[str, str],
                            groups: dict[str, str]) -> dict[str, list[str]]:
    """Donne un groupe de validation, puis de test, aux espèces qui n'en ont aucun.

    `split_for` hache le groupe et ne regarde pas l'espèce. Sur
    une espèce dont les photos viennent de peu d'observations, les tirages
    peuvent tomber tous du même côté : `train.py` écarte alors la classe
    (`--min-val`), et ce sont des espèces qui avaient largement de quoi
    apprendre. *Howea forsteriana* est absente d'Iris 6 avec 95 images
    d'entraînement et aucune en validation ; le kentia n'a pas manqué de
    photos, il a manqué d'un tirage.

    **La réparation est minimale, et c'est essentiel.** On ne redistribue
    rien : on déplace le plus petit groupe d'entraînement des seules espèces à
    qui il manque un côté, et toutes les autres affectations restent
    exactement ce qu'elles étaient. Une re-répartition générale ferait passer
    en test des images que le modèle précédent a vues à l'entraînement — il y
    paraîtrait meilleur qu'il n'est, et la comparaison entre deux versions ne
    voudrait plus rien dire.

    Le plus petit groupe, parce que l'entraînement est ce qui coûte le plus à
    perdre. Une espèce qui n'a qu'un seul groupe d'entraînement n'est pas
    touchée : la vider pour la mesurer ne l'avancerait à rien. La validation
    passe avant le test, parce que c'est elle qui décide qu'une classe existe.

    Rend les espèces réparées et ce qu'elles ont reçu. `splits` est modifié
    sur place.
    """
    par_espece: dict[str, dict[str, list[str]]] = defaultdict(lambda: defaultdict(list))
    for r in records:
        if r.status == STATUS_KEPT:
            par_espece[r.species][groups[r.checksum]].append(r.checksum)

    repares: dict[str, list[str]] = {}
    for species in sorted(par_espece):
        tailles = par_espece[species]
        cote = {g: splits[cks[0]] for g, cks in tailles.items()}
        for manquant in ('val', 'test'):
            if manquant in cote.values():
                continue
            # Le plus petit d'abord ; l'identifiant de groupe départage, pour
            # que deux exécutions donnent le même résultat.
            candidats = sorted((g for g, s in cote.items() if s == 'train'),
                               key=lambda g: (len(tailles[g]), g))
            if len(candidats) < 2:      # il faut laisser au moins un groupe à l'entraînement
                continue
            g = candidats[0]
            cote[g] = manquant
            for ck in tailles[g]:
                splits[ck] = manquant
            repares.setdefault(species, []).append(manquant)
    return repares


def make_splits(records: list[ImageRecord], threshold: int = NEAR_THRESHOLD,
                groups: dict[str, str] | None = None, repair: bool = True) -> dict[str, str]:
    """Checksum → train | val | test, pour les images gardées.

    `repair=False` rend la répartition d'avant `repair_species_coverage` :
    c'est ce qu'il faut pour reproduire à l'identique un modèle entraîné
    avant elle.
    """
    if groups is None:
        groups = assign_groups(records, threshold)
    splits = {ck: split_for(g) for ck, g in groups.items()}
    if repair:
        repair_species_coverage(records, splits, groups)
    return splits


def write_splits(records: list[ImageRecord], path: str | Path, threshold: int = NEAR_THRESHOLD,
                 repair: bool = True) -> dict[str, dict[str, int]]:
    # Les groupes sont calculés une fois : `assign_groups` compare les
    # empreintes de toutes les images gardées, et c'est la partie chère.
    groups = assign_groups(records, threshold)
    splits = make_splits(records, threshold, groups=groups, repair=repair)
    counts: dict[str, dict[str, int]] = defaultdict(lambda: defaultdict(int))
    with open(path, 'w', newline='', encoding='utf-8') as f:
        w = csv.writer(f)
        # `captive` : la photo vient d'une plante cultivée (iNaturalist). Une
        # précision mesurée sur ces images-là est la seule qui décrit ce que
        # l'application fera sur les photos de ses utilisateurs.
        w.writerow(['path', 'species', 'internal_plant_id', 'split', 'group', 'captive'])
        for r in sorted((r for r in records if r.status == STATUS_KEPT), key=lambda r: (r.species, r.path)):
            s = splits[r.checksum]
            w.writerow([r.path, r.species, r.internal_plant_id, s, groups[r.checksum], '1' if (r.extra or {}).get('captive') else '0'])
            counts[r.species][s] += 1
    return {k: dict(v) for k, v in counts.items()}
