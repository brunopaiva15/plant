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
HASH_BITS = 64


def candidate_pairs(items: list[tuple[ImageRecord, int]], threshold: int):
    """Les paires d'empreintes à `threshold` bits ou moins l'une de l'autre.

    Comparer toutes les paires coûte n² : sur 45 000 images cela fait un
    milliard de comparaisons, soit des heures — la collecte du catalogue
    complet s'y est arrêtée.

    Principe des tiroirs : si deux empreintes diffèrent d'au plus `threshold`
    bits et qu'on découpe les 64 bits en `threshold + 1` bandes, alors au
    moins une bande est identique de part et d'autre — sinon il faudrait au
    moins une différence par bande, donc plus de `threshold` au total. Il
    suffit donc de grouper par bande et de ne comparer qu'à l'intérieur des
    groupes. Aucune paire vraie n'est perdue ; on économise seulement les
    comparaisons qui n'avaient aucune chance.

    Chaque seau est comparé d'un bloc avec numpy, et seules les paires
    réellement proches sont rendues. La version précédente rendait toutes
    les paires d'un même seau et mémorisait celles déjà vues pour ne pas
    les répéter : à 236 000 images, cela faisait des centaines de millions
    de tuples en mémoire, et le processus mourait à la fin de la collecte
    de la v6.
    """
    import numpy as np

    bands = threshold + 1
    # Les bits sont répartis équitablement : découper en tranches de largeur
    # fixe laisserait une dernière bande de quelques bits seulement, donc peu
    # de valeurs possibles, donc des seaux énormes — et l'optimisation
    # disparaîtrait dans le dernier. 64 bits en 7 bandes donnent 9,9,9,9,9,9,10.
    offsets = []
    start = 0
    for band in range(bands):
        width = (HASH_BITS - start) // (bands - band)
        offsets.append((start, width))
        start += width
    values = np.array([v for _, v in items], dtype=np.uint64)
    buckets: dict[tuple[int, int], list[int]] = defaultdict(list)
    for index, value in enumerate(values.tolist()):
        for band, (start, width) in enumerate(offsets):
            buckets[(band, (value >> start) & ((1 << width) - 1))].append(index)
    seen: set[tuple[int, int]] = set()
    for group in buckets.values():
        if len(group) < 2:
            continue
        idx = np.array(group)
        h = values[idx]
        # Distance de Hamming de toutes les paires du seau, d'un coup.
        x = np.bitwise_xor.outer(h, h)
        d = np.zeros(x.shape, dtype=np.uint8)
        for shift in range(0, 64, 8):
            d += _POPCOUNT[((x >> np.uint64(shift)) & np.uint64(0xFF)).astype(np.uint8)]
        ai, bi = np.nonzero(np.triu(d <= threshold, k=1))
        for a, b in zip(idx[ai].tolist(), idx[bi].tolist()):
            pair = (a, b) if a < b else (b, a)
            if pair not in seen:
                seen.add(pair)
                yield pair


_POPCOUNT = __import__('numpy').array([bin(i).count('1') for i in range(256)], dtype='uint8')


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
    du représentant. La comparaison se fait espèce par espèce, et par bandes
    d'empreinte à l'intérieur de chacune."""
    uf = UnionFind()
    by_species: dict[str, list[ImageRecord]] = defaultdict(list)
    for r in records:
        if r.status == STATUS_KEPT and r.phash:
            by_species[r.species].append(r)
    for rows in by_species.values():
        hashes = [(r, int(r.phash, 16)) for r in rows]
        for i, j in candidate_pairs(hashes, threshold):
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
    for i, j in candidate_pairs(hashes, threshold):
        a, b = hashes[i][0], hashes[j][0]
        if a.species != b.species and hamming(hashes[i][1], hashes[j][1]) <= threshold:
            for r in (a, b):
                if r.status == STATUS_KEPT:
                    r.status = STATUS_REVIEW
                    r.reason = f'quasi identique à une image de {b.species if r is a else a.species}'
                    flagged += 1
    return flagged
