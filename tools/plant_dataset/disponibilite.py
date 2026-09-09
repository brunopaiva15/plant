#!/usr/bin/env python3
"""Combien d'images une espèce a-t-elle, avant de décider de la collecter.

    python3 disponibilite.py --species-file candidates.txt --seuil 25

Agrandir le catalogue coûte du top-1 : 78 classes en rendaient 63,8 %, 542
en rendaient 44,2 % (§ 6.2). Ce n'est pas une fatalité — la v6 a ajouté 551
espèces sans perdre — mais ça l'est **si les espèces ajoutées n'ont pas
d'images**. Une classe sous les 25 images d'entraînement est écartée par
`--min-train` ; entre 25 et 50, elle entre dans le modèle sans rien y
apprendre et dilue la mesure.

D'où cet outil, à passer **avant** une collecte : il ne télécharge aucune
image, il demande à GBIF combien d'occurrences photographiées existent par
espèce. Quelques heures de requêtes contre une collecte de douze.

**C'est une borne basse, et il faut le savoir.** GBIF ne sait filtrer que
CC0 et CC BY à la requête (`licenses.py`) : le partage à l'identique, que le
projet accepte depuis le 6 septembre, ne se voit qu'au média. Et iNaturalist
en direct, qui apporte les plantes cultivées (§ 4.3), n'est pas interrogé du
tout. Une espèce annoncée à 40 ici en aura souvent davantage ; une espèce
annoncée à 3 n'en aura jamais 25.
"""
from __future__ import annotations

import argparse
import statistics
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from plant_dataset.fetchers.gbif import GBIF_LICENSE_CODES  # noqa: E402

#: Le seuil de `train.py --min-train` : en dessous, la classe est écartée.
SEUIL = 25


def verdict(comptes: dict[str, int], seuil: int = SEUIL) -> dict:
    """Trie les espèces candidates selon ce qu'on peut en attendre.

    Quatre populations, parce qu'elles appellent quatre décisions :

    - **absentes** : GBIF ne connaît pas le nom. C'est `synonyms.txt` qui
      répond, pas une collecte (§ 6.5).
    - **vides** : le nom est résolu mais aucune occurrence photographiée. La
      collecte les traversera pour rien.
    - **maigres** : sous le seuil. Elles entreraient au catalogue et
      sortiraient du modèle — le pire des deux mondes, un coût de collecte
      sans classe au bout.
    - **solides** : de quoi apprendre. C'est le seul nombre qui compte quand
      on annonce « le modèle passe à N espèces ».
    """
    absentes = sorted(e for e, n in comptes.items() if n < 0)
    vides = sorted(e for e, n in comptes.items() if n == 0)
    maigres = sorted((e for e, n in comptes.items() if 0 < n < seuil), key=lambda e: -comptes[e])
    solides = sorted((e for e, n in comptes.items() if n >= seuil), key=lambda e: -comptes[e])
    valeurs = [comptes[e] for e in solides]
    return {
        'demandees': len(comptes),
        'absentes': absentes,
        'vides': vides,
        'maigres': maigres,
        'solides': solides,
        'mediane': statistics.median(valeurs) if valeurs else 0,
        'comptes': comptes,
    }


def disponibles(client, nom: str, codes: list[str] = GBIF_LICENSE_CODES) -> int:
    """Occurrences photographiées et librement réutilisables, sans rien lire.

    `limit=0` : GBIF rend le décompte et aucun résultat. Une requête par
    licence, parce que le paramètre n'accepte qu'une valeur.

    Rend -1 quand le nom n'est pas résolu — à distinguer de zéro, qui veut
    dire « connue, mais jamais photographiée ».
    """
    taxon = client.match(nom)
    if taxon is None or not taxon.key:
        return -1
    total = 0
    for code in codes:
        d = client._get('/occurrence/search', taxonKey=taxon.key, mediaType='StillImage',
                        basisOfRecord='HUMAN_OBSERVATION', license=code, limit=0)
        total += int(d.get('count', 0))
    return total


def _afficher(r: dict, seuil: int, detail: int) -> None:
    n = r['demandees']
    print(f'\n{n} espèces interrogées :')
    print(f"  {len(r['solides']):5d} au-dessus de {seuil} occurrences  ← les classes réelles")
    print(f"  {len(r['maigres']):5d} entre 1 et {seuil - 1}  ← collectées pour rien, écartées du modèle")
    print(f"  {len(r['vides']):5d} connues de GBIF, jamais photographiées")
    print(f"  {len(r['absentes']):5d} nom non résolu — c'est `synonyms.txt` qui répond")
    if r['solides']:
        print(f"\nmédiane des solides : {r['mediane']:.0f} occurrences")
        print(f"→ un catalogue de {n} noms donnerait environ **{len(r['solides'])} classes**")
    if r['maigres'][:detail]:
        print(f"\nles plus proches du seuil, à surveiller :")
        for e in r['maigres'][:detail]:
            print(f'  {e:38s} {r["comptes"][e]:4d}')


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--species-file', required=True, help='un nom scientifique par ligne')
    ap.add_argument('--seuil', type=int, default=SEUIL, help="le `--min-train` de l'entraînement")
    ap.add_argument('--limit', type=int, help='ne mesurer que les N premières')
    ap.add_argument('--pause', type=float, default=0.25, help='cadence GBIF, en secondes')
    ap.add_argument('--detail', type=int, default=15)
    ap.add_argument('--csv', help='écrire le décompte par espèce')
    args = ap.parse_args(argv)

    from plant_dataset.fetchers.gbif import GbifClient   # réseau : pas à l'import du module

    especes = [l.strip() for l in Path(args.species_file).read_text(encoding='utf-8').splitlines() if l.strip()]
    if args.limit:
        especes = especes[:args.limit]
    client = GbifClient(pause=args.pause)

    comptes: dict[str, int] = {}
    for i, espece in enumerate(especes, 1):
        try:
            comptes[espece] = disponibles(client, espece)
        except Exception as e:      # une source qui tombe ne doit jamais être lue comme un zéro
            print(f'  [{i}/{len(especes)}] {espece} : ÉCHEC ({type(e).__name__}: {e})', file=sys.stderr)
            continue
        if i % 25 == 0 or i == len(especes):
            print(f'  [{i}/{len(especes)}]', flush=True)

    r = verdict(comptes, args.seuil)
    _afficher(r, args.seuil, args.detail)
    if args.csv:
        import csv as _csv
        with open(args.csv, 'w', newline='', encoding='utf-8') as f:
            w = _csv.writer(f)
            w.writerow(['espece', 'occurrences'])
            for e in sorted(comptes, key=lambda x: -comptes[x]):
                w.writerow([e, comptes[e]])
        print(f'\ndécompte écrit dans {args.csv}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
