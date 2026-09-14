#!/usr/bin/env python3
"""Retire du catalogue de collecte les lignes qui sont la même plante.

    python3 fusionner.py                 # ce qui serait fait, sans rien écrire
    python3 fusionner.py --ecrire        # écrit plants.csv

`doublons.py --catalogue` dit **lesquelles** ; cet outil dit **laquelle
garder** et le fait. Les deux sont séparés parce que trouver se relance
sans risque et qu'écrire le catalogue de collecte, non.

**Pourquoi ce n'est pas un choix de confort.** `build_dataset.py` collecte
les images **par la clé GBIF** (`image_candidates(taxon['key'], …)`). Deux
lignes qui partagent une clé téléchargent donc *exactement les mêmes
photos* dans deux classes : les garder toutes deux ne conserve aucune
distinction, ça fabrique une confusion qu'aucune photo ne peut trancher —
il n'y a rien à trancher. Le § 12.14 l'avait mesuré sur six couples ; le
catalogue en porte 46.

**Et ça ne retire rien à l'application.** Le § 13.5 le pose : `plants.csv`
est le catalogue de *collecte*, une ligne y est une **classe du modèle**.
Le catalogue de l'app est un autre fichier. La clémentine garde sa fiche,
qu'elle soit ou non une classe.

## Quel nom survit

Dans cet ordre, et la première règle qui décide l'emporte :

1. **Ce que l'app possède** — fiche soignée à la main d'abord, catalogue
   étendu ensuite (§ 12.14). Suivre le nom accepté de GBIF donnerait
   *Coleus scutellarioides*, que ni l'une ni l'autre ne portent : la plante
   ne serait plus reconnue du tout. Décide 32 groupes sur 46.
2. **Le nom accepté par GBIF**, quand l'app n'a pas de préférence à
   protéger — soit elle ignore les deux noms, soit tous deux sont dans le
   catalogue étendu, qui est lui-même tiré de Wikidata et de GBIF. La
   comparaison ignore le signe d'hybride : GBIF écrit *Citrus
   aurantiifolia* là où le catalogue écrit *Citrus × aurantiifolia*, et
   c'est la même plante.
3. **Faute de mieux, le premier dans l'ordre alphabétique** — et l'outil le
   **dit**, au lieu de choisir en silence. Le cas se produit quand le nom
   accepté de GBIF est un *troisième* nom, absent du catalogue :
   *Grindelia camporum* et *G. stricta* sont deux synonymes de *G.
   hirsutula*, que nous n'avons pas. Le nom retenu n'est alors qu'une
   étiquette : la collecte ira chercher la clé, pas le nom.

## Ce que la ligne retirée laisse derrière elle

Son nom passe en synonyme du survivant — donc `build_dataset.py` continue
de le résoudre (`_first_usable` essaie le nom puis les synonymes) — et ses
synonymes à elle suivent. Ses noms communs, son identifiant Wikidata, son
identifiant Pl@ntNet et son image ne sont repris que **là où le survivant
n'a rien** : une fusion ne doit rien perdre, et surtout pas les quatre
langues d'une fiche soignée.
"""
from __future__ import annotations

import argparse
import csv
import json
import sys
from collections import defaultdict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from plant_dataset.taxonomy import PlantEntry, internal_id, load_plants, save_plants  # noqa: E402

RACINE = Path(__file__).resolve().parents[2]
CATALOGUE_ETENDU = RACINE / 'assets' / 'species' / 'catalog.tsv'
LANGUES = ('fr', 'en', 'de', 'it')


def sans_hybride(nom: str) -> str:
    """La clé de comparaison, signe d'hybride en moins.

    GBIF rend *Citrus aurantiifolia* pour ce que le catalogue écrit *Citrus
    × aurantiifolia*. Comparer les deux tels quels ferait passer un nom
    accepté pour un inconnu, et l'outil tomberait sur la règle 3 en croyant
    n'avoir pas le choix.
    """
    return internal_id(nom).replace('-x-', '-').removeprefix('x-')


def rang_app(nom: str, soignees: set[str], etendu: set[str]) -> int:
    """0 fiche soignée, 1 catalogue étendu, 2 inconnu de l'app."""
    return 0 if nom in soignees else (1 if nom in etendu else 2)


def choisir(groupe: list[PlantEntry], soignees: set[str], etendu: set[str],
            canonique: str = '') -> tuple[PlantEntry, str]:
    """Le survivant du groupe, et la règle qui l'a désigné."""
    rangs = {e.internal_id: rang_app(e.scientific_name, soignees, etendu) for e in groupe}
    meilleur = min(rangs.values())
    candidats = [e for e in groupe if rangs[e.internal_id] == meilleur]
    if len(candidats) == 1:
        return candidats[0], 'app'
    if canonique:
        cle = sans_hybride(canonique)
        exact = [e for e in candidats if sans_hybride(e.scientific_name) == cle]
        if exact:
            return exact[0], 'gbif'
    return sorted(candidats, key=lambda e: e.scientific_name)[0], 'alphabétique'


def absorber(gagnant: PlantEntry, perdants: list[PlantEntry]) -> PlantEntry:
    """Le survivant, enrichi de ce que les retirés savaient et qu'il ignore."""
    connus = {gagnant.scientific_name, *gagnant.synonyms}
    for p in perdants:
        for n in [p.scientific_name, *p.synonyms]:
            if n not in connus:
                gagnant.synonyms.append(n)
                connus.add(n)
        for lang in LANGUES:
            if not gagnant.common_names.get(lang) and p.common_names.get(lang):
                gagnant.common_names[lang] = p.common_names[lang]
        for champ in ('wikidata_id', 'plantnet_id', 'image', 'family'):
            if not getattr(gagnant, champ) and getattr(p, champ):
                setattr(gagnant, champ, getattr(p, champ))
    return gagnant


def groupes_de(cles: dict[str, int | None], entrees: list[PlantEntry]) -> list[list[PlantEntry]]:
    par_id = {e.internal_id: e for e in entrees}
    par_cle: dict[int, list[PlantEntry]] = defaultdict(list)
    for interne, cle in cles.items():
        if cle is not None and interne in par_id:
            par_cle[cle].append(par_id[interne])
    return sorted((sorted(v, key=lambda e: e.scientific_name) for v in par_cle.values() if len(v) > 1),
                  key=lambda g: g[0].scientific_name)


def fusionner(entrees: list[PlantEntry], groupes: list[list[PlantEntry]], soignees: set[str],
              etendu: set[str], canoniques: dict[str, str]) -> tuple[list[PlantEntry], list[tuple]]:
    """Le catalogue sans les doublons, et le compte rendu de chaque groupe."""
    retires: set[str] = set()
    rapport = []
    for g in groupes:
        gagnant, regle = choisir(g, soignees, etendu, canoniques.get(g[0].internal_id, ''))
        perdants = [e for e in g if e.internal_id != gagnant.internal_id]
        absorber(gagnant, perdants)
        retires.update(e.internal_id for e in perdants)
        rapport.append((regle, gagnant, perdants, canoniques.get(g[0].internal_id, '')))
    return [e for e in entrees if e.internal_id not in retires], rapport


def _lire_etendu(path: Path) -> set[str]:
    if not path.exists():
        return set()
    return {l.split('\t')[0] for l in path.read_text(encoding='utf-8').splitlines() if l.strip()}


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--plants', default='plants.csv')
    ap.add_argument('--cache', default='.cache/doublons.json', help='les clés résolues par doublons.py --catalogue')
    ap.add_argument('--canoniques', default='.cache/canoniques.json',
                    help='nom accepté par clé GBIF ; demandé au besoin, puis mémorisé')
    ap.add_argument('--etendu', default=str(CATALOGUE_ETENDU))
    ap.add_argument('--ecrire', action='store_true', help='sans quoi rien n\'est écrit')
    args = ap.parse_args(argv)

    cache = Path(args.cache)
    if not cache.exists():
        print(f'{cache} absent : lancer d\'abord `doublons.py --catalogue`.', file=sys.stderr)
        return 1
    cles = json.loads(cache.read_text())['cles']

    entrees = load_plants(args.plants)
    from export_plants import read_catalog
    soignees = {e.scientific_name for e in read_catalog()}
    etendu = _lire_etendu(Path(args.etendu))
    groupes = groupes_de(cles, entrees)

    # Le nom accepté ne sert qu'aux groupes que l'app ne tranche pas : on ne
    # demande à GBIF que ceux-là.
    chemin_canon = Path(args.canoniques)
    canoniques: dict[str, str] = json.loads(chemin_canon.read_text()) if chemin_canon.exists() else {}
    a_demander = [g for g in groupes
                  if choisir(g, soignees, etendu)[1] != 'app' and g[0].internal_id not in canoniques]
    if a_demander:
        from plant_dataset.fetchers.gbif import GbifClient
        client = GbifClient(pause=0.15)
        print(f'{len(a_demander)} noms acceptés à demander à GBIF…', file=sys.stderr, flush=True)
        for g in a_demander:
            d = client._get(f'/species/{cles[g[0].internal_id]}')
            canoniques[g[0].internal_id] = d.get('canonicalName') or d.get('scientificName', '')
        chemin_canon.parent.mkdir(parents=True, exist_ok=True)
        chemin_canon.write_text(json.dumps(canoniques, ensure_ascii=False))

    restant, rapport = fusionner(entrees, groupes, soignees, etendu, canoniques)
    par_regle: dict[str, int] = defaultdict(int)
    for regle, *_ in rapport:
        par_regle[regle] += 1

    print(f'{len(groupes)} groupes, {len(entrees) - len(restant)} lignes retirées '
          f'sur {len(entrees)} — il en reste {len(restant)}.\n')
    for regle in ('app', 'gbif', 'alphabétique'):
        choisis = [r for r in rapport if r[0] == regle]
        if not choisis:
            continue
        print(f'### {regle} — {len(choisis)}')
        for _, gagnant, perdants, canon in choisis:
            note = f'   (GBIF dit « {canon} », absent du catalogue)' if regle == 'alphabétique' else ''
            print(f'  garde {gagnant.scientific_name:<34} retire {", ".join(p.scientific_name for p in perdants)}{note}')
        print()

    if not args.ecrire:
        print('Rien n\'a été écrit. Relancer avec --ecrire.')
        return 0
    save_plants(args.plants, restant)
    print(f'{args.plants} réécrit : {len(restant)} lignes.')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
