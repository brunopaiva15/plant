#!/usr/bin/env python3
"""Récupère les genres de plantes et leur famille dans l'ossature GBIF.

La correspondance genre → famille sert deux fois : à donner sa famille à
chaque espèce moissonnée, et à reconnaître les synonymes latins déguisés en
noms vernaculaires.

Usage : python3 tool/fetch_genera.py genus_family.json all_genera.txt
"""
import json
import os
import sys
import time
import urllib.request

BACKBONE = 'd7dddbf4-2cf0-4f39-9b2a-bb099caae36c'
PLANTAE = 6
UA = {'User-Agent': 'FloraApp/1.0 (offline species catalogue; github.com/brunopaiva15/plant)'}


def fetch_page(offset):
    url = ('https://api.gbif.org/v1/species/search?rank=GENUS'
           f'&highertaxonKey={PLANTAE}&status=ACCEPTED&datasetKey={BACKBONE}'
           f'&limit=1000&offset={offset}')
    req = urllib.request.Request(url, headers=UA)
    for attempt in range(4):
        try:
            return json.load(urllib.request.urlopen(req, timeout=90))
        except Exception:
            if attempt == 3:
                raise
            time.sleep(2 ** attempt)


def main(json_out, list_out):
    # Reprise : le fichier partiel évite de tout refaire après une coupure.
    partial = json_out + '.partial'
    out = json.load(open(partial)) if os.path.exists(partial) else {}
    offset = len(out) // 1000 * 1000
    while True:
        page = fetch_page(offset)
        for r in page['results']:
            genus, family = r.get('genus'), r.get('family')
            if genus and family:
                out.setdefault(genus, family)
        offset += 1000
        json.dump(out, open(partial, 'w'))
        print('%d → %d genres' % (offset, len(out)), file=sys.stderr, flush=True)
        if page.get('endOfRecords') or not page['results']:
            break
        time.sleep(0.15)
    os.replace(partial, json_out)
    with open(list_out, 'w') as f:
        f.write('\n'.join(sorted(out)) + '\n')
    print('%d genres avec leur famille' % len(out))


if __name__ == '__main__':
    main(*sys.argv[1:3])
