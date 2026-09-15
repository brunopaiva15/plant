#!/usr/bin/env python3
"""Le manifeste remis d'accord avec le catalogue, après une fusion de doublons.

    python3 reetiqueter.py --dataset dataset          # ce qui serait fait
    python3 reetiqueter.py --dataset dataset --ecrire

`fusionner.py` retire du catalogue les lignes qui sont la même plante sous
deux noms. Mais le **manifeste** garde l'étiquette figée à la collecte : les
images ramenées sous *Sansevieria trifasciata* restent étiquetées ainsi,
même une fois la ligne disparue de `plants.csv`.

Sans ce passage, le redécoupage produirait un jeu qui contredit son propre
catalogue — des classes dont aucune ligne ne répond, et les images
toujours séparées en deux alors que la fusion existait pour les réunir.

**Aucune image n'est retéléchargée ni déplacée.** `train.py` lit `path` et
`internal_plant_id` de `splits.csv` comme deux colonnes indépendantes : il
ne relit jamais l'étiquette depuis le chemin du fichier. Réétiqueter est
donc une réécriture de colonne, pas une collecte.

## Ce qui suit, et qu'il ne faut pas oublier

Une fois le manifeste réétiqueté :

    python3 build_dataset.py --skip-fetch --plants plants.csv --out dataset

`--skip-fetch` ne télécharge rien : il **déduplique, répartit et compte**.
C'est ce qui rejoint les images des classes fusionnées, refait `splits.csv`
et rend au passage les ~112 espèces que le § 12.19 avait écartées pour une
image de validation manquante.

Et ça rattrape un effet de bord : `flag_cross_species` envoie en `review`
tout quasi-doublon entre deux **espèces différentes**, au motif que
l'étiquette est douteuse. Deux noms pour une seule plante ressemblaient
exactement à ça — des paires légitimement identiques ont donc été écartées
parce que le catalogue les comptait deux fois. Une fois réétiquetées, la
déduplication les traite normalement.

## D'où vient la correspondance

De `plants.csv` seul, et c'est voulu : le fichier porte en colonne
`synonyms` les noms que la fusion a retirés, puisque `fusionner.py` les y
range. Un nom de cette colonne qui **n'est pas** lui-même une ligne
survivante est donc une étiquette morte, et pointe vers la ligne qui l'a
absorbé. Rien à mémoriser entre les deux outils, rien qui puisse se
désynchroniser.
"""
from __future__ import annotations

import argparse
import sys
from collections import Counter
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from plant_dataset.manifest import Manifest  # noqa: E402
from plant_dataset.taxonomy import internal_id, load_plants  # noqa: E402


def correspondance(entrees) -> dict[str, tuple[str, str]]:
    """étiquette morte → (identifiant survivant, nom scientifique survivant).

    Une étiquette est morte quand elle est le synonyme d'une ligne sans
    être elle-même une ligne : c'est la signature d'un nom que la fusion a
    retiré du catalogue.
    """
    vivants = {e.internal_id for e in entrees}
    morte: dict[str, tuple[str, str]] = {}
    for e in entrees:
        for syn in e.synonyms:
            cle = internal_id(syn)
            if cle and cle not in vivants:
                morte.setdefault(cle, (e.internal_id, e.scientific_name))
    return morte


def reetiqueter(manifeste: Manifest, morte: dict[str, tuple[str, str]]) -> Counter:
    """Réécrit les étiquettes mortes. Rend le compte par étiquette touchée."""
    faits: Counter = Counter()
    for r in manifeste.records:
        cible = morte.get(r.internal_plant_id)
        if cible is None:
            continue
        faits[f'{r.internal_plant_id} → {cible[0]}'] += 1
        r.internal_plant_id, r.species = cible
    return faits


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--dataset', default='dataset')
    ap.add_argument('--plants', default='plants.csv')
    ap.add_argument('--ecrire', action='store_true', help='sans quoi rien n\'est écrit')
    args = ap.parse_args(argv)

    chemin = Path(args.dataset) / 'manifest.jsonl'
    if not chemin.exists():
        print(f'{chemin} introuvable.', file=sys.stderr)
        return 1

    entrees = load_plants(args.plants)
    morte = correspondance(entrees)
    print(f'{len(entrees)} lignes au catalogue, {len(morte)} étiquettes mortes reconnues\n')

    manifeste = Manifest(chemin)
    faits = reetiqueter(manifeste, morte)
    if not faits:
        print(f'{len(manifeste.records)} enregistrements, aucun à réétiqueter : '
              'le manifeste est déjà d\'accord avec le catalogue.')
        return 0

    total = sum(faits.values())
    print(f'{total} image(s) à réétiqueter, sur {len(manifeste.records)} — '
          f'{len(faits)} étiquette(s) concernée(s) :\n')
    for mouvement, n in faits.most_common():
        print(f'  {n:>6}  {mouvement}')

    if not args.ecrire:
        print('\nRien n\'a été écrit. Relancer avec --ecrire.')
        return 0
    manifeste.rewrite()
    print(f'\n{chemin} réécrit.')
    print('Enchaîner avec : build_dataset.py --skip-fetch '
          f'--plants {args.plants} --out {args.dataset}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
