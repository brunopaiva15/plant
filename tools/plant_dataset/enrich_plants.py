#!/usr/bin/env python3
"""Complète `plants.csv` avec les identifiants externes.

- GBIF : clé du taxon accepté, et la famille selon l'ossature GBIF ; les noms
  que GBIF ne reconnaît pas franchement sont listés pour relecture.
- Wikidata : l'identifiant Q de l'élément dont le nom scientifique (P225)
  est le nôtre, en une seule requête SPARQL.

    python3 enrich_plants.py [--gbif] [--wikidata]     (les deux par défaut)
"""
from __future__ import annotations

import argparse
import sys
import time
import urllib.parse

import requests

from plant_dataset.fetchers.gbif import GbifClient
from plant_dataset.taxonomy import load_plants, save_plants

PLANTS = 'plants.csv'
WIKIDATA = 'https://query.wikidata.org/sparql'


def enrich_gbif(entries) -> list[str]:
    client = GbifClient()
    doubtful = []
    for i, e in enumerate(entries, 1):
        if e.gbif_key:
            continue
        m = client.match(e.scientific_name)
        if m is None or not m.usable:
            doubtful.append(f'{e.scientific_name} → {m.match_type if m else "aucune"} {m.scientific_name if m else ""}')
            continue
        e.gbif_key = m.accepted_key or m.key
        if not e.family and m.family:
            e.family = m.family
        if i % 25 == 0:
            print(f'  gbif {i}/{len(entries)}', file=sys.stderr, flush=True)
    return doubtful


def enrich_wikidata(entries) -> None:
    todo = [e for e in entries if not e.wikidata_id]
    for start in range(0, len(todo), 150):
        chunk = todo[start:start + 150]
        values = ' '.join('"%s"' % e.scientific_name.replace('"', '') for e in chunk)
        query = f'SELECT ?name ?item WHERE {{ VALUES ?name {{ {values} }} ?item wdt:P225 ?name . }}'
        r = requests.get(WIKIDATA, params={'query': query, 'format': 'json'},
                         headers={'User-Agent': 'FloraPlantDataset/0.1 (github.com/brunopaiva15/plant)'}, timeout=120)
        r.raise_for_status()
        found = {}
        for b in r.json()['results']['bindings']:
            found.setdefault(b['name']['value'], b['item']['value'].rsplit('/', 1)[-1])
        for e in chunk:
            e.wikidata_id = found.get(e.scientific_name)
        time.sleep(1)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument('--gbif', action='store_true')
    ap.add_argument('--wikidata', action='store_true')
    ap.add_argument('--plants', default=PLANTS)
    args = ap.parse_args()
    do_all = not (args.gbif or args.wikidata)
    entries = load_plants(args.plants)
    if args.gbif or do_all:
        doubtful = enrich_gbif(entries)
        save_plants(args.plants, entries)
        print(f'gbif : {sum(1 for e in entries if e.gbif_key)}/{len(entries)} résolues')
        for d in doubtful:
            print('  à revoir :', d)
    if args.wikidata or do_all:
        enrich_wikidata(entries)
        save_plants(args.plants, entries)
        print(f'wikidata : {sum(1 for e in entries if e.wikidata_id)}/{len(entries)} trouvées')
    return 0


if __name__ == '__main__':
    sys.exit(main())
