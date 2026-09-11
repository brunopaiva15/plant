"""Répartition train / validation / test.

L'unité n'est pas l'image mais le groupe : toutes les photos d'une même
observation, et tout ce qui a été jugé quasi-doublon de l'une d'elles, vont
ensemble. Sinon le test verrait des images qu'il a déjà vues en train, et
la précision mesurée serait un mensonge.

L'affectation est déterministe (empreinte du groupe) : relancer la
répartition après avoir ajouté des images ne déplace pas les anciennes.

Elle ne regarde pas l'espèce, et c'est son défaut : une espèce dont les
photos viennent de peu d'observations peut voir ses tirages tomber tous du
même côté, ou n'en recevoir qu'une poignée d'images, et se faire écarter du
modèle faute de validation. `repair_species_coverage` répare ce seul cas,
sans toucher au reste — en visant les seuils que `train.py` applique
vraiment, et non la simple présence d'un groupe.
"""
from __future__ import annotations

import csv
import hashlib
from collections import defaultdict
from pathlib import Path

from .dedup import NEAR_THRESHOLD, UnionFind, near_duplicate_groups
from .manifest import STATUS_KEPT, ImageRecord

RATIOS = {'train': 0.8, 'val': 0.1, 'test': 0.1}

# `train.py` n'admet une classe que si elle a `--min-train` images
# d'entraînement *et* `--min-val` en validation. La réparation doit viser ces
# nombres-là : remplir la colonne « val » d'une seule image satisfait le
# découpage et laisse quand même la classe dehors.
MIN_TRAIN = 25
MIN_VAL = 3


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


def _groupes_a_deplacer(tailles: dict[str, list[str]], cote: dict[str, str],
                        manque: int, min_train: int) -> list[str]:
    """Les groupes d'entraînement à passer de l'autre côté pour combler
    `manque` images — ou rien, si ça ne se peut pas sans abîmer l'espèce.

    Deux plans sont envisagés : le plus petit groupe qui comble à lui seul, et
    les plus petits accumulés. On garde celui qui sort le moins d'images de
    l'entraînement. Les deux sont nécessaires : sur des groupes de 2, 2 et 100
    images, le premier plan en déplacerait cent pour en combler trois ; sur des
    groupes de 1 et 4, le second en déplacerait cinq là où quatre suffisent.

    Deux garde-fous, et un plan qui viole l'un ou l'autre est abandonné entier
    plutôt que joué à moitié :

    - **il reste au moins un groupe à l'entraînement** — une espèce qui n'a
      qu'un groupe n'a rien à donner ;
    - **il reste au moins `min_train` images** — descendre sous le seuil de
      `train.py` ferait sortir la classe du modèle, ce que la réparation est
      précisément censée éviter. Une espèce déjà sous le seuil n'est pas
      touchée non plus : lui prendre des images ne la sauverait pas.

    L'identifiant de groupe départage à taille égale, pour que deux exécutions
    donnent le même découpage.
    """
    candidats = sorted((g for g, s in cote.items() if s == 'train'),
                       key=lambda g: (len(tailles[g]), g))
    en_train = sum(len(tailles[g]) for g in candidats)

    plans: list[list[str]] = []
    seul = next((g for g in candidats if len(tailles[g]) >= manque), None)
    if seul is not None:
        plans.append([seul])
    cumul, reste = [], manque
    for g in candidats:
        cumul.append(g)
        reste -= len(tailles[g])
        if reste <= 0:
            plans.append(list(cumul))
            break

    def taille(plan: list[str]) -> int:
        return sum(len(tailles[g]) for g in plan)

    valides = [plan for plan in plans
               if len(plan) < len(candidats) and en_train - taille(plan) >= min_train]
    return min(valides, key=lambda plan: (taille(plan), len(plan), plan)) if valides else []


def repair_species_coverage(records: list[ImageRecord], splits: dict[str, str],
                            groups: dict[str, str], min_val: int = MIN_VAL,
                            min_train: int = MIN_TRAIN) -> dict[str, list[str]]:
    """Donne de quoi valider, puis de quoi tester, aux espèces qui en manquent.

    `split_for` hache le groupe et ne regarde pas l'espèce. Sur une espèce dont
    les photos viennent de peu d'observations, les tirages peuvent tomber tous
    du même côté, ou ne laisser qu'une image en validation : `train.py` écarte
    alors la classe (`--min-val`), et ce sont des espèces qui avaient largement
    de quoi apprendre. *Howea forsteriana* est absente d'Iris 6 avec 95 images
    d'entraînement et aucune en validation ; le kentia n'a pas manqué de
    photos, il a manqué d'un tirage.

    **Le seuil compte autant que la présence.** Viser « au moins un groupe »
    remplissait la colonne sans faire entrer la classe : sur Iris 8, 112
    espèces à 47 images d'entraînement en médiane — jusqu'à 193 — sont restées
    dehors avec une ou deux images de validation, parce que la réparation leur
    avait donné leur plus petit groupe. On vise donc `min_val` images, et on
    répare aussi une validation qui existe mais reste sous le seuil.

    **La réparation est minimale, et c'est essentiel.** On ne redistribue
    rien : on déplace des groupes d'entraînement des seules espèces à qui il
    manque un côté, et toutes les autres affectations restent exactement ce
    qu'elles étaient. Une re-répartition générale ferait passer en test des
    images que le modèle précédent a vues à l'entraînement — il y paraîtrait
    meilleur qu'il n'est, et la comparaison entre deux versions ne voudrait
    plus rien dire. Une espèce qui satisfait déjà les seuils n'est jamais
    touchée : ce correctif ne peut donc pas déplacer une image d'une classe
    déjà présente dans le modèle précédent.

    La validation passe avant le test, parce que c'est elle qui décide qu'une
    classe existe. Le test n'a pas de seuil dans `train.py` : une image suffit.

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
        for manquant, vise in (('val', min_val), ('test', 1)):
            present = sum(len(tailles[g]) for g, s in cote.items() if s == manquant)
            if present >= vise:
                continue
            bouger = _groupes_a_deplacer(tailles, cote, vise - present, min_train)
            for g in bouger:
                cote[g] = manquant
                for ck in tailles[g]:
                    splits[ck] = manquant
            if bouger:
                repares.setdefault(species, []).append(manquant)
    return repares


def make_splits(records: list[ImageRecord], threshold: int = NEAR_THRESHOLD,
                groups: dict[str, str] | None = None, repair: bool = True,
                min_val: int = MIN_VAL, min_train: int = MIN_TRAIN) -> dict[str, str]:
    """Checksum → train | val | test, pour les images gardées.

    `repair=False` rend la répartition d'avant `repair_species_coverage` :
    c'est ce qu'il faut pour reproduire à l'identique un modèle entraîné
    avant elle.
    """
    if groups is None:
        groups = assign_groups(records, threshold)
    splits = {ck: split_for(g) for ck, g in groups.items()}
    if repair:
        repair_species_coverage(records, splits, groups, min_val, min_train)
    return splits


def write_splits(records: list[ImageRecord], path: str | Path, threshold: int = NEAR_THRESHOLD,
                 repair: bool = True, min_val: int = MIN_VAL,
                 min_train: int = MIN_TRAIN) -> dict[str, dict[str, int]]:
    # Les groupes sont calculés une fois : `assign_groups` compare les
    # empreintes de toutes les images gardées, et c'est la partie chère.
    groups = assign_groups(records, threshold)
    splits = make_splits(records, threshold, groups=groups, repair=repair,
                         min_val=min_val, min_train=min_train)
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
