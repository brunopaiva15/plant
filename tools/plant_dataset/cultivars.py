#!/usr/bin/env python3
"""Les cultivars connus de chaque espèce du catalogue, depuis Wikidata.

    python3 cultivars.py --out cultivars.csv

**Ceci n'est pas un jeu d'entraînement, et c'est le point.** Un cultivar est
une plante que l'horticulture a sélectionnée : *Monstera deliciosa* « Thai
Constellation » est une *Monstera deliciosa* panachée, pas une autre espèce.
Les gens en possèdent beaucoup, et ils veulent le nom.

Mais on ne peut pas en faire des classes, pour une raison mesurée :

- **iNaturalist ne modélise pas les cultivars.** Sur les 2 000 taxons
  cultivés les plus observés : 1 935 espèces, 65 hybrides, zéro cultivar.
  Une photo de « Thai Constellation » y est enregistrée *Monstera
  deliciosa* ;
- **Commons a les rayons, et ils sont vides.** La hiérarchie existe —
  `Monstera deliciosa (cultivars)`, avec une sous-catégorie par cultivar
  nommé — mais elle porte **1** fichier pour la Monstera, **3** pour
  *Epipremnum aureum* « Marble Queen », **6** pour « N'Joy ». Le seuil
  d'entrée d'une classe est de 25 images ;
- et des centaines de classes visuellement quasi identiques recréeraient à
  grande échelle le défaut du § 12.14 : les images d'une plante partagées
  entre deux étiquettes, une confusion qu'aucune photo ne peut trancher.

Le cultivar est donc un **second axe**, pas une classe de plus : le modèle
répond l'espèce, et l'application propose les cultivars connus de cette
espèce. Ce fichier est cette liste — un catalogue, pas des pixels.

Wikidata la donne : un cultivar y est une instance de `Q4886`, rattachée à
son taxon parent par `P171`.
"""
from __future__ import annotations

import argparse
import csv
import re
import sys
from collections import defaultdict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

WIKIDATA = 'https://query.wikidata.org/sparql'
UA = 'FloraPlantDataset/0.1 (github.com/brunopaiva15/plant; cultivar catalogue)'

#: Wikidata écrit l'épithète de cultivar avec tout ce que l'Unicode compte
#: d'apostrophes : « Hosta ʽFortunei’ », « Hosta 'Gold Standard' ». La règle
#: horticole n'en connaît qu'une, l'apostrophe droite.
_APOSTROPHES = re.compile('[‘’ʻʼʽ′`´]')


#: Les rangs botaniques : ce qui les suit est une variété ou une
#: sous-espèce, pas un cultivar.
_RANG = re.compile(r'^(var|subsp|ssp|f|forma|subvar|cv)\b\.?', re.I)


def epithete(nom: str, parent: str) -> str | None:
    """L'épithète de cultivar seule : « Ficus elastica ʽRobusta’ » → « Robusta ».

    Deux écritures, et la seconde demande de la prudence. Le code
    horticole met l'épithète entre apostrophes simples, et c'est net.
    Quand Wikidata les omet, il reste à deviner — or `Q4886` porte aussi des
    taxons qui n'en sont pas : *Hosta decorata* est une espèce, « Agave
    americana var. medio-picta alba » une variété. Les laisser passer
    remplirait la liste des cultivars de choses qui n'en sont pas.

    D'où la règle du code horticole comme garde-fou : **un nom de cultivar
    prend une majuscule**, une épithète d'espèce ou de variété jamais.
    """
    propre = _APOSTROPHES.sub("'", nom or '').strip()
    m = re.search(r"'([^']+)'", propre)
    if m:
        return m.group(1).strip() or None
    if not parent or not propre.lower().startswith(parent.lower()):
        return None
    reste = propre[len(parent):].strip()
    if not reste or _RANG.match(reste) or not reste[0].isupper():
        return None
    return reste


def grouper(lignes: list[tuple[str, str]]) -> dict[str, list[str]]:
    """espèce → ses cultivars, dédoublonnés et triés.

    `lignes` est une liste de (nom du parent, nom du cultivar).
    """
    out: dict[str, set] = defaultdict(set)
    for parent, nom in lignes:
        e = epithete(nom, parent)
        if e:
            out[parent].add(e)
    return {k: sorted(v) for k, v in sorted(out.items())}


def _interroger(noms: list[str], timeout: float) -> list[tuple[str, str]]:
    import requests
    valeurs = ' '.join('"%s"' % n.replace('"', '') for n in noms)
    requete = (
        'SELECT ?parentName ?cultivarLabel WHERE { '
        f'VALUES ?parentName {{ {valeurs} }} '
        '?parent wdt:P225 ?parentName . '
        '?cultivar wdt:P31 wd:Q4886 ; wdt:P171 ?parent . '
        'SERVICE wikibase:label { bd:serviceParam wikibase:language "fr,en". } }'
    )
    r = requests.get(WIKIDATA, params={'query': requete, 'format': 'json'},
                     headers={'User-Agent': UA}, timeout=timeout)
    r.raise_for_status()
    return [(b['parentName']['value'], b['cultivarLabel']['value'])
            for b in r.json()['results']['bindings']]


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--plants', default='plants.csv')
    ap.add_argument('--out', default='cultivars.csv')
    ap.add_argument('--lot', type=int, default=120, help='espèces par requête SPARQL')
    ap.add_argument('--timeout', type=float, default=120)
    ap.add_argument('--limit', type=int, help='ne traiter que les N premières espèces')
    args = ap.parse_args(argv)

    especes = [r['scientific_name'] for r in csv.DictReader(Path(args.plants).open(encoding='utf-8'))]
    if args.limit:
        especes = especes[:args.limit]

    lignes: list[tuple[str, str]] = []
    for debut in range(0, len(especes), args.lot):
        lot = especes[debut:debut + args.lot]
        try:
            lignes += _interroger(lot, args.timeout)
        except Exception as e:      # une requête qui tombe ne doit pas passer pour « aucun cultivar »
            print(f'  [{debut}/{len(especes)}] ÉCHEC ({type(e).__name__}: {e})', file=sys.stderr)
            continue
        print(f'  [{min(debut + args.lot, len(especes))}/{len(especes)}] {len(lignes)} cultivars',
              file=sys.stderr, flush=True)

    par_espece = grouper(lignes)
    total = sum(len(v) for v in par_espece.values())
    print(f'\n{total} cultivars sur {len(par_espece)} espèces '
          f'({len(par_espece) / len(especes):.0%} du catalogue en a au moins un)')
    for nom, liste in list(par_espece.items())[:10]:
        print(f'  {nom:30s} {", ".join(liste[:6])}{" …" if len(liste) > 6 else ""}')

    with open(args.out, 'w', newline='', encoding='utf-8') as f:
        w = csv.writer(f)
        w.writerow(['espece', 'cultivars'])
        for nom, liste in par_espece.items():
            w.writerow([nom, '|'.join(liste)])
    print(f'\nécrit dans {args.out}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
