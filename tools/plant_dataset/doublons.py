#!/usr/bin/env python3
"""Les classes du modèle qui sont la même plante sous deux noms.

    python3 doublons.py --labels ../../assets/model/labels.txt

*Sansevieria trifasciata* et *Dracaena trifasciata* sont une seule plante :
la sansevière a changé de genre en 2017. Les deux noms sont au catalogue,
donc le modèle a **deux classes** pour elle. Ça coûte trois fois :

- les images se **partagent** entre les deux classes, et chacune s'entraîne
  sur la moitié de ce qu'elle devrait ;
- la confusion est **imperdable** — aucune photo ne peut trancher, puisqu'il
  n'y a rien à trancher. Elle apparaît pourtant dans la matrice (§ 12.4)
  comme un défaut du modèle ;
- et le décompte de classes annoncé est faux d'autant.

Le premier réflexe — chercher les identifiants qui partagent leur épithète
dans une même famille — ne suffit pas : sur le catalogue de l'Iris 7 il rend
34 groupes dont **4** sont de vrais doublons. *Populus alba* et *Salix alba*
partagent leur épithète et ne sont pas la même plante ; `officinalis`,
`vulgaris` et `japonica` sont des passe-partout.

D'où le choix de tout demander à GBIF, sans heuristique : chaque nom du
catalogue est résolu vers son **taxon accepté**, et deux noms qui tombent
sur la même clé sont la même plante. C'est déjà l'arbitre de la collecte
(`fetchers/gbif.py`) et de `synonyms.txt` (§ 6.5) ; il n'y a pas de raison
d'en prendre un autre ici.

**Sa limite, à savoir avant de conclure.** GBIF suit sa propre dorsale
taxonomique et elle retarde sur certains transferts récents : *Schefflera
arboricola* et *Heptapleurum arboricola* y sont deux taxons acceptés, donc
cet outil ne les signale pas, alors que la littérature récente les tient
pour une seule plante. L'outil rend les doublons **certains**, pas tous les
doublons.
"""
from __future__ import annotations

import argparse
import csv
import json
import sys
from collections import defaultdict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))


def grouper(cles: dict[str, int | None]) -> list[list[str]]:
    """Les identifiants qui tombent sur le même taxon accepté.

    Une clé absente (`None`) veut dire « non résolu » : ceux-là ne se
    regroupent avec personne, sinon toutes les inconnues deviendraient un
    seul et même doublon.
    """
    par_cle: dict[int, list[str]] = defaultdict(list)
    for interne, cle in cles.items():
        if cle is not None:
            par_cle[cle].append(interne)
    return sorted((sorted(v) for v in par_cle.values() if len(v) > 1), key=lambda g: g[0])


def images_par_classe(dataset: Path) -> dict[str, int]:
    """Combien d'images chaque classe possède — pour dire ce que la scission
    coûte réellement, plutôt que de l'annoncer en principe."""
    splits = dataset / 'splits.csv'
    if not splits.exists():
        return {}
    compte: dict[str, int] = defaultdict(int)
    with splits.open(newline='', encoding='utf-8') as f:
        for row in csv.DictReader(f):
            compte[row['internal_plant_id']] += 1
    return dict(compte)


def cle_acceptee(client, nom: str) -> int | None:
    """Le taxon accepté d'un nom, ou `None` si GBIF ne le résout pas.

    `acceptedUsageKey` n'est renseigné que pour un synonyme ; pour un nom
    accepté, c'est `usageKey` qui fait foi. Prendre l'un ou l'autre au
    hasard rangerait chaque synonyme à part de son nom accepté, c'est-à-dire
    exactement ce qu'on cherche à repérer.
    """
    d = client._get('/species/match', name=nom, kingdom='Plantae')
    cle = d.get('acceptedUsageKey') or d.get('usageKey')
    return int(cle) if cle else None


def _afficher(groupes: list[list[str]], noms: dict[str, str], images: dict[str, int], total: int) -> None:
    if not groupes:
        print('aucun doublon : chaque classe est une plante distincte.')
        return
    perdues = sum(len(g) - 1 for g in groupes)
    print(f'**{len(groupes)} plantes comptées deux fois** — {perdues} classes de trop sur {total}.\n')
    for g in groupes:
        print('  ' + ' = '.join(noms.get(i, i) for i in g))
        if images:
            parts = ' + '.join(f'{images.get(i, 0)}' for i in g)
            somme = sum(images.get(i, 0) for i in g)
            print(f'    {parts} = {somme} images, aujourd\'hui séparées')
    print(f"\nÀ fusionner dans `plants.csv` : garder le nom accepté, mettre l'autre")
    print('en synonyme. Les images se rejoignent, la confusion disparaît — elle')
    print("n'était pas une erreur du modèle, il n'y avait rien à trancher.")


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--labels', default='../../assets/model/labels.txt')
    ap.add_argument('--plants', default='plants.csv')
    ap.add_argument('--dataset', default='dataset', help='pour dire combien d\'images chaque scission sépare')
    ap.add_argument('--cache', default='.cache/doublons.json', help='clés déjà résolues ; une reprise ne redemande rien')
    ap.add_argument('--pause', type=float, default=0.15)
    ap.add_argument('--limit', type=int)
    args = ap.parse_args(argv)

    labels = [l.strip() for l in Path(args.labels).read_text(encoding='utf-8').splitlines() if l.strip()]
    if args.limit:
        labels = labels[:args.limit]
    plants = Path(args.plants)
    noms = ({r['internal_id']: r['scientific_name'] for r in csv.DictReader(plants.open(encoding='utf-8'))}
            if plants.exists() else {})

    cache = Path(args.cache)
    cles: dict[str, int | None] = json.loads(cache.read_text()) if cache.exists() else {}
    manquants = [i for i in labels if i not in cles]
    if manquants:
        from plant_dataset.fetchers.gbif import GbifClient   # réseau : pas à l'import du module
        client = GbifClient(pause=args.pause)
        print(f'{len(manquants)} noms à résoudre chez GBIF…', file=sys.stderr, flush=True)
        for n, interne in enumerate(manquants, 1):
            try:
                cles[interne] = cle_acceptee(client, noms.get(interne, interne.replace('-', ' ')))
            except Exception as e:      # une source qui tombe ne doit pas passer pour « non résolu »
                print(f'  {interne} : ÉCHEC ({type(e).__name__}: {e})', file=sys.stderr)
            if n % 100 == 0:
                cache.parent.mkdir(parents=True, exist_ok=True)
                cache.write_text(json.dumps(cles))
                print(f'  {n}/{len(manquants)}', file=sys.stderr, flush=True)
        cache.parent.mkdir(parents=True, exist_ok=True)
        cache.write_text(json.dumps(cles))

    non_resolus = [i for i in labels if cles.get(i) is None]
    if non_resolus:
        print(f'{len(non_resolus)} noms non résolus, ignorés : {", ".join(non_resolus[:8])}'
              f'{" …" if len(non_resolus) > 8 else ""}\n')
    _afficher(grouper({i: cles.get(i) for i in labels}), noms,
              images_par_classe(Path(args.dataset)), len(labels))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
