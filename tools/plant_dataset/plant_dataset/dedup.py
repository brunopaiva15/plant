"""Déduplication : doublons exacts par sha256, quasi-doublons par empreinte.

Les quasi-doublons sont groupés par union-find ; le premier arrivé de chaque
groupe reste, les autres passent en `duplicate` avec le checksum de
l'original. Un quasi-doublon entre deux espèces différentes n'est pas un
doublon mais un signal d'étiquette douteuse : il part en `review`.
"""
from __future__ import annotations

from collections import defaultdict

from .images import hamming
from .manifest import STATUS_DUPLICATE, STATUS_KEPT, STATUS_REVIEW, ImageRecord

NEAR_THRESHOLD = 6   # bits de différence, sur 64


class UnionFind:
    def __init__(self):
        self.parent: dict[str, str] = {}

    def find(self, x: str) -> str:
        self.parent.setdefault(x, x)
        while self.parent[x] != x:
            self.parent[x] = self.parent[self.parent[x]]
            x = self.parent[x]
        return x

    def union(self, a: str, b: str) -> None:
        ra, rb = self.find(a), self.find(b)
        if ra != rb:
            self.parent[rb] = ra


def near_duplicate_groups(records: list[ImageRecord], threshold: int = NEAR_THRESHOLD) -> dict[str, list[ImageRecord]]:
    """Groupes de quasi-doublons parmi les images gardées, clés par checksum
    du représentant. Comparaison exhaustive par espèce : quelques centaines
    d'images par classe, c'est instantané."""
    uf = UnionFind()
    by_species: dict[str, list[ImageRecord]] = defaultdict(list)
    for r in records:
        if r.status == STATUS_KEPT and r.phash:
            by_species[r.species].append(r)
    for rows in by_species.values():
        hashes = [(r, int(r.phash, 16)) for r in rows]
        for i in range(len(hashes)):
            for j in range(i + 1, len(hashes)):
                if hamming(hashes[i][1], hashes[j][1]) <= threshold:
                    uf.union(hashes[i][0].checksum, hashes[j][0].checksum)
    groups: dict[str, list[ImageRecord]] = defaultdict(list)
    for rows in by_species.values():
        for r in rows:
            groups[uf.find(r.checksum)].append(r)
    return {k: v for k, v in groups.items() if len(v) > 1}


def mark_duplicates(records: list[ImageRecord], threshold: int = NEAR_THRESHOLD) -> dict[str, int]:
    """Passe complète : exacts d'abord, quasi ensuite. Modifie les statuts en
    place et rend le décompte."""
    exact = 0
    seen: dict[str, ImageRecord] = {}
    for r in records:
        if r.status != STATUS_KEPT:
            continue
        first = seen.get(r.checksum)
        if first is None:
            seen[r.checksum] = r
        else:
            r.status = STATUS_DUPLICATE
            r.duplicate_of = first.checksum
            r.reason = 'doublon exact'
            exact += 1
    near = 0
    for group in near_duplicate_groups(records, threshold).values():
        group.sort(key=lambda r: r.downloaded_at)
        keeper = group[0]
        for r in group[1:]:
            r.status = STATUS_DUPLICATE
            r.duplicate_of = keeper.checksum
            r.reason = 'quasi-doublon (empreinte)'
            near += 1
    return {'exact': exact, 'near': near}


def flag_cross_species(records: list[ImageRecord], threshold: int = NEAR_THRESHOLD) -> int:
    """Deux images quasi identiques sous deux espèces : l'une des deux étiquettes
    est fausse. On les envoie toutes les deux à la revue manuelle."""
    kept = [r for r in records if r.status == STATUS_KEPT and r.phash]
    flagged = 0
    hashes = [(r, int(r.phash, 16)) for r in kept]
    for i in range(len(hashes)):
        for j in range(i + 1, len(hashes)):
            a, b = hashes[i][0], hashes[j][0]
            if a.species != b.species and hamming(hashes[i][1], hashes[j][1]) <= threshold:
                for r in (a, b):
                    if r.status == STATUS_KEPT:
                        r.status = STATUS_REVIEW
                        r.reason = f'quasi identique à une image de {b.species if r is a else a.species}'
                        flagged += 1
    return flagged
