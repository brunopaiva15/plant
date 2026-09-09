#!/usr/bin/env python3
"""Ce que PlantNet-300K apporterait à notre modèle, mesuré avant d'écrire un
connecteur.

    python3 plantnet300k.py --labels ../../assets/model/labels.txt

Le § 4.6 de `docs/09-plant-recognition.md` écartait ce jeu sur une intuition :
sa flore est européenne et sauvage, la nôtre est d'appartement. L'intuition
méritait un chiffre, et le chiffre dit autre chose — voir le § 12.8.

Deux fichiers de métadonnées suffisent, 66 Mo en tout, sans télécharger les
306 000 images ni les 32 Go du jeu complet. Ils sont publiés à part par
Pl@ntNet, précisément pour ça.

Ce que l'outil rend, et pourquoi chaque ligne compte :

- **le recouvrement d'espèces**, qui borne tout : une image ne sert que si
  l'espèce est une de nos classes ;
- **les licences**, filtrées par la même règle que la collecte (§ 4.1) ;
- **la répartition par organe**, qui est la vraie question. `habit` est la
  plante entière ; `flower` et `leaf` sont des gros plans. Un modèle nourri
  de gros plans de fleurs européennes ne reconnaîtra pas mieux un
  zamioculcas dans un salon — c'est l'erreur que le § 6.3 a déjà coûtée une
  fois.
"""
from __future__ import annotations

import argparse
import json
import sys
import urllib.request
from collections import Counter
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from plant_dataset.taxonomy import internal_id, normalize_scientific_name  # noqa: E402

#: Les métadonnées seules, sans les images. Adresse donnée par le dépôt
#: PlantNet-300K lui-même, Zenodo ne permettant pas de les télécharger à part.
SEAFILE = 'https://seafile.plantnet.org/d/bed81bc15e8944969cf6/files/?p=%2F{}&dl=1'
NOMS = 'plantnet300K_species_id_2_name.json'
METADONNEES = 'plantnet300K_metadata.json'

#: La règle du § 4.1, dans le vocabulaire de PlantNet.
LICENCES_ACCEPTEES = {'cc0', 'cc-by', 'cc-by-sa'}

#: La plante entière. Le seul organe dont le cadrage ressemble à ce que
#: photographie un utilisateur de l'application.
ENTIERE = 'habit'


def correspondance(species_id_2_name: dict[str, str], labels: set[str]) -> dict[str, str]:
    """Identifiant d'espèce PlantNet → notre identifiant interne.

    Leurs noms portent leur auteur (« Lactuca virosa L. ») ; on passe par la
    même normalisation que la collecte, sinon rien ne se rencontre. Plusieurs
    de leurs identifiants peuvent tomber sur une seule de nos espèces —
    synonymes ou sous-espèces — et c'est bien : leurs images se rejoindraient.
    """
    out = {}
    for sid, nom in species_id_2_name.items():
        canonique = normalize_scientific_name(nom)
        if canonique and internal_id(canonique) in labels:
            out[sid] = internal_id(canonique)
    return out


def compter(metadonnees: dict[str, dict], correspondances: dict[str, str],
            licences: set[str] = LICENCES_ACCEPTEES) -> dict:
    """Ce que les espèces communes offrent : images, licences, organes.

    Les images dont la licence est refusée sont comptées à part plutôt
    qu'ignorées : savoir qu'un jeu est utilisable à 100 % ou à 18 % change la
    décision, et c'est ce qui avait écarté Kew (§ 4.5).
    """
    par_espece, par_organe, par_licence, entieres = Counter(), Counter(), Counter(), Counter()
    for image in metadonnees.values():
        interne = correspondances.get(image.get('species_id'))
        if interne is None:
            continue
        par_licence[image.get('license', '?')] += 1
        if image.get('license') not in licences:
            continue
        par_espece[interne] += 1
        par_organe[image.get('organ', '?')] += 1
        if image.get('organ') == ENTIERE:
            entieres[interne] += 1
    return {
        'especes': len(par_espece),
        'images': sum(par_espece.values()),
        'images_toutes_licences': sum(par_licence.values()),
        'par_espece': par_espece,
        'par_organe': par_organe,
        'par_licence': par_licence,
        'entieres': entieres,
    }


def telecharger(nom: str, dossier: Path) -> Path:
    cible = dossier / nom
    if cible.exists():
        return cible
    dossier.mkdir(parents=True, exist_ok=True)
    print(f'  téléchargement de {nom}…', file=sys.stderr, flush=True)
    urllib.request.urlretrieve(SEAFILE.format(nom), cible)
    return cible


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--labels', default='../../assets/model/labels.txt',
                    help='les classes du modèle livré, un identifiant interne par ligne')
    ap.add_argument('--cache', default='.cache/plantnet300k', help='où garder les deux fichiers de métadonnées')
    ap.add_argument('--plants', default='plants.csv', help='pour nommer les espèces dans le rapport')
    ap.add_argument('--top', type=int, default=15, help='combien d\'espèces détailler')
    args = ap.parse_args(argv)

    labels = {l.strip() for l in Path(args.labels).read_text().splitlines() if l.strip()}
    cache = Path(args.cache)
    noms = json.loads(telecharger(NOMS, cache).read_text())
    corr = correspondance(noms, labels)

    canoniques = {normalize_scientific_name(n) for n in noms.values()}
    canoniques.discard('')
    print(f'PlantNet-300K : {len(noms)} identifiants, {len(canoniques)} espèces')
    print(f'notre modèle  : {len(labels)} classes')
    communes = set(corr.values())
    print(f'\nrecouvrement : {len(communes)} espèces — {len(communes) / len(labels):.1%} de nos classes\n')
    if not communes:
        return 0

    stats = compter(json.loads(telecharger(METADONNEES, cache).read_text()), corr)
    utiles = stats['images']
    total = stats['images_toutes_licences']
    print(f"images sur ces espèces : {total}, dont {utiles} sous licence acceptée ({utiles / total:.0%})")
    print('  licences :', dict(stats['par_licence'].most_common(5)))
    print('  organes  :', dict(stats['par_organe'].most_common(8)))
    entieres = sum(stats['entieres'].values())
    print(f"  plante entière ({ENTIERE}) : {entieres} images, {entieres / utiles:.1%} du total")

    par = stats['par_espece']
    noms_lisibles = {}
    plants = Path(args.plants)
    if plants.exists():
        import csv
        noms_lisibles = {r['internal_id']: r['scientific_name'] for r in csv.DictReader(plants.open())}
    print(f'\nles {args.top} espèces qui gagneraient le plus :')
    for i, n in par.most_common(args.top):
        print(f'  {noms_lisibles.get(i, i):36s} {n:6d} images  dont {stats["entieres"][i]:4d} entières')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
