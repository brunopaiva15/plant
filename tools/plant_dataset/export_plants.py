#!/usr/bin/env python3
"""Exporte le catalogue de l'app vers `plants.csv`.

Le catalogue trié à la main (`lib/data/species/species_catalog.dart`, ~300
espèces courantes) est la référence du moteur de reconnaissance. Ce script
le lit tel quel — pas de seconde liste à maintenir — et produit le CSV que
`build_dataset.py` consomme. Les colonnes d'identifiants externes (GBIF,
Wikidata) sont remplies ensuite par `enrich_plants.py` ; l'export ne les
écrase pas si elles existent déjà.

    python3 export_plants.py            # écrit plants.csv
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

from plant_dataset.taxonomy import PlantEntry, load_plants, save_plants

HERE = Path(__file__).resolve().parent
CATALOG = HERE.parents[1] / 'lib' / 'data' / 'species' / 'species_catalog.dart'
OUT = HERE / 'plants.csv'

_ENTRY = re.compile(
    r"SpeciesCatalogEntry\(\s*'((?:[^'\\]|\\.)*)',\s*'((?:[^'\\]|\\.)*)',\s*SpeciesCategory\.\w+"
    r"(?:,\s*fr:\s*'((?:[^'\\]|\\.)*)')?(?:,\s*en:\s*'((?:[^'\\]|\\.)*)')?"
    r"(?:,\s*de:\s*'((?:[^'\\]|\\.)*)')?(?:,\s*it:\s*'((?:[^'\\]|\\.)*)')?"
)


def _unescape(s: str | None) -> str:
    return (s or '').replace("\\'", "'")


def read_catalog(path: Path = CATALOG) -> list[PlantEntry]:
    text = path.read_text(encoding='utf-8')
    entries = []
    for m in _ENTRY.finditer(text):
        name, family, fr, en, de, it = (_unescape(g) for g in m.groups())
        entries.append(PlantEntry.from_name(name, family, fr=fr, en=en, de=de, it=it))
    return entries


def main() -> int:
    entries = read_catalog()
    if not entries:
        print('catalogue vide ou illisible', file=sys.stderr)
        return 1
    # Conserve les identifiants déjà enrichis.
    previous = {e.scientific_name: e for e in load_plants(OUT)} if OUT.exists() else {}
    for e in entries:
        old = previous.get(e.scientific_name)
        if old:
            e.gbif_key, e.wikidata_id, e.plantnet_id, e.image, e.synonyms = old.gbif_key, old.wikidata_id, old.plantnet_id, old.image, old.synonyms
    save_plants(OUT, entries)
    dupes = {n for n in [e.scientific_name for e in entries] if [e.scientific_name for e in entries].count(n) > 1}
    print(f'{len(entries)} plantes → {OUT.name}' + (f' ; doublons : {sorted(dupes)}' if dupes else ''))
    return 0


if __name__ == '__main__':
    sys.exit(main())
