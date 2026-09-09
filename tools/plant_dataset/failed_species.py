#!/usr/bin/env python3
"""Relit les journaux de collecte et rend les espèces à reprendre.

    python3 failed_species.py shard*.log            # la liste, une par ligne
    python3 failed_species.py --write retry shard*.log   # retry0.txt, retry1.txt…
    python3 failed_species.py --why shard*.log      # combien d'échecs, et de quoi

Une espèce dont une source tombe est écrite `ÉCHEC` et sautée : c'est son
problème, pas celui des 300 autres (`build_dataset.py`). Le prix à payer est
qu'il faut ensuite les rattraper, et sur 1 558 espèces réparties en quatre
parts on ne va pas les recopier à la main.

La reprise est peu coûteuse et réussit presque toujours : les échecs de
collecte sont massivement des limitations de débit, et deux cents espèces
relancées seules ne pèsent plus rien sur les serveurs. C'est la même
commande que la collecte, avec `--only-file` sur la liste rendue ici et la
**même** part de sortie — pour qu'une espèce ne se retrouve pas éclatée
entre deux dossiers.
"""
from __future__ import annotations

import argparse
import collections
import re
import sys
from pathlib import Path

#: `[12/390] Monstera deliciosa: ÉCHEC (HTTPError: 429), espèce sautée`
LINE = re.compile(r'^\[\d+/\d+\]\s+(?P<nom>.+?):\s+ÉCHEC\s+\((?P<type>[A-Za-z_][\w.]*)[:)]')


def failures(text: str) -> list[tuple[str, str]]:
    """Les couples (espèce, type d'erreur) d'un journal, sans doublon.

    Une même espèce peut échouer deux fois si le journal contient deux
    passes ; on la reprend une seule fois, sur son premier motif.
    """
    out: dict[str, str] = {}
    for line in text.splitlines():
        m = LINE.match(line.strip())
        if m:
            out.setdefault(m.group('nom').strip(), m.group('type'))
    return list(out.items())


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('logs', nargs='+', help='journaux de collecte, p. ex. shard*.log')
    ap.add_argument('--write', metavar='PRÉFIXE',
                    help='écrire une liste par journal : PRÉFIXE0.txt, PRÉFIXE1.txt…, '
                         'dans l\'ordre des journaux donnés')
    ap.add_argument('--why', action='store_true', help='le décompte par type d\'erreur')
    args = ap.parse_args(argv)

    motifs: collections.Counter = collections.Counter()
    total = 0
    for i, chemin in enumerate(args.logs):
        rates = failures(Path(chemin).read_text(encoding='utf-8', errors='replace'))
        motifs.update(t for _, t in rates)
        total += len(rates)
        noms = [n for n, _ in rates]
        if args.write:
            cible = Path(f'{args.write}{i}.txt')
            cible.write_text('\n'.join(noms) + ('\n' if noms else ''), encoding='utf-8')
            print(f'{cible} : {len(noms)} espèce(s)  ← {chemin}', file=sys.stderr)
        elif not args.why:
            print('\n'.join(noms))
    if args.why or args.write:
        print(f'\n{total} échec(s) au total :', file=sys.stderr)
        for t, n in motifs.most_common():
            print(f'   {n:5d}  {t}', file=sys.stderr)
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
