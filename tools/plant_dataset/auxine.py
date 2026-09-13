#!/usr/bin/env python3
"""Les photos que les utilisateurs ont étiquetées en enregistrant.

    SUPABASE_URL=… SUPABASE_SERVICE_KEY=… python3 auxine.py --out dataset --plants plants.csv
    python3 auxine.py --out dataset --plants plants.csv --dry-run          # lister, sans télécharger

Chaque ligne de `iris_feedback` est une identification qu'une personne a
enregistrée dans l'application, avec son consentement : une à trois photos,
ce qu'Iris proposait, le nom retenu, et d'où il venait. C'est la seule
source qui photographie les plantes **telles qu'on les cultive**, au
téléphone, dans un salon — le domaine que 991 000 images de GBIF ne
couvrent pas (§ 13.1 de docs/09), et la seule qui étiquette par un humain
qui possède la plante.

Trois types de retour, et tous entrent au jeu :

- **confirmée** — la première proposition d'Iris, acceptée. Une photo du
  bon domaine, et une étiquette où l'humain et le modèle sont d'accord ;
- **reclassée** — une proposition d'Iris, mais pas la première ;
- **corrigée** — un nom pris ailleurs, Pl@ntNet ou le sélecteur. C'est ce
  qu'Iris rate, avec ce pour quoi il l'avait pris.

**L'étiquette est l'opinion de la personne.** Une correction où elle a pris
exactement ce que Pl@ntNet proposait avec un bon score est solide ; un nom
que ni Iris ni Pl@ntNet ne proposaient ne l'est pas. `fiable()` tranche à
l'ingestion : ce qui ne l'est pas entre en `review`, dans `_review/`, pour
l'écran de validation du § 13.5 — jamais directement à l'entraînement.

Une identification est **un groupe d'observation** : ses photos vont
ensemble au découpage, comme celles d'une observation iNaturalist. Et elles
sont toutes `captive` : c'est ce que l'application voit vraiment.
"""
from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from plant_dataset.images import ImageRejected, prepare, store
from plant_dataset.manifest import STATUS_DUPLICATE, STATUS_KEPT, STATUS_REVIEW, ImageRecord, Manifest, now_iso
from plant_dataset.taxonomy import PlantEntry, load_plants, species_slug

SOURCE = 'auxine'
BUCKET = 'iris-feedback'
TABLE = 'iris_feedback'
KINDS = ('confirmee', 'reclassee', 'corrigee')

# En dessous, l'accord entre la personne et Pl@ntNet ne dit plus grand-chose.
SCORE_SOLIDE = 0.5

# Dossier des images qui attendent l'écran de validation (build_dataset.STATUS_DIR).
REVIEW_DIR = '_review'


def fiable(row: dict) -> bool:
    """L'étiquette est-elle assez solide pour entrer directement au jeu ?

    Confirmée : l'humain et Iris sont d'accord, oui. Autrement, oui si le nom
    retenu est celui que Pl@ntNet proposait avec un score d'au moins
    `SCORE_SOLIDE` — deux avis indépendants. Un nom que personne ne proposait
    attend une validation.
    """
    if row.get('kind') == 'confirmee':
        return True
    remote = row.get('remote_top1') or {}
    if not remote:
        return False
    meme_nom = (remote.get('name') or '').strip().lower() == (row.get('species_name') or '').strip().lower()
    return meme_nom and float(remote.get('score') or 0) >= SCORE_SOLIDE


def resoudre(rows: list[dict], plants: list[PlantEntry]) -> tuple[list[tuple[dict, PlantEntry]], list[dict]]:
    """Rattache chaque ligne à sa plante du catalogue de collecte.

    Une ligne dont l'espèce n'est pas au catalogue ne peut pas devenir une
    classe : elle est rendue à part. Ce sont des **candidates au
    catalogue** — quelqu'un possède cette plante, et l'a nommée.
    """
    par_id = {p.internal_id: p for p in plants}
    connues, inconnues = [], []
    for row in rows:
        plant = par_id.get(row.get('species_id', ''))
        (connues if plant else inconnues).append((row, plant) if plant else row)
    return connues, inconnues


def chemin_objet(row: dict, n: int) -> str:
    """Le chemin d'une photo dans le seau."""
    return f"{row['storage_path']}/{n}.jpg"


def enregistrement(row: dict, n: int, prepared, plant: PlantEntry, downloaded_at: str | None = None) -> ImageRecord:
    """La ligne de manifeste d'une photo de retour, telle que `build_dataset`
    l'écrirait pour n'importe quelle source."""
    record = ImageRecord(
        species=plant.scientific_name, internal_plant_id=plant.internal_id, source=SOURCE,
        source_id=f"{row['id']}#{n}", original_url='', image_url=chemin_objet(row, n), author='',
        license='consent', license_url='', downloaded_at=downloaded_at or now_iso(),
        checksum=prepared.sha256, width=prepared.width, height=prepared.height, phash=prepared.phash,
        observation_id=row['id'],
        extra={'captive': True, 'kind': row.get('kind', ''), 'chosen_source': row.get('chosen_source', ''),
               'model_version': row.get('model_version', ''), 'fiable': fiable(row)},
    )
    rel = f'{species_slug(plant.scientific_name)}/{prepared.sha256[:16]}.jpg'
    if fiable(row):
        record.path = rel
    else:
        record.status = STATUS_REVIEW
        record.reason = 'étiquette à valider : ni confirmée par Iris, ni par Pl@ntNet'
        record.path = f'{REVIEW_DIR}/{rel}'
    return record


class Supabase:
    """Le strict nécessaire : lire la table, télécharger un objet."""

    def __init__(self, url: str, key: str):
        import requests
        self.base = url.rstrip('/')
        self.http = requests.Session()
        self.http.headers.update({'apikey': key, 'Authorization': f'Bearer {key}'})

    def rows(self, kinds: tuple[str, ...]) -> list[dict]:
        out, offset, page = [], 0, 500
        while True:
            r = self.http.get(f'{self.base}/rest/v1/{TABLE}', timeout=30,
                              params={'select': '*', 'order': 'created_at.asc',
                                      'kind': f'in.({",".join(kinds)})',
                                      'offset': offset, 'limit': page})
            r.raise_for_status()
            lot = r.json()
            out.extend(lot)
            if len(lot) < page:
                return out
            offset += page

    def download(self, path: str) -> bytes:
        r = self.http.get(f'{self.base}/storage/v1/object/{BUCKET}/{path}', timeout=60)
        r.raise_for_status()
        return r.content


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--out', default='dataset')
    ap.add_argument('--plants', default='plants.csv')
    ap.add_argument('--kinds', default=','.join(KINDS), help='types de retour à prendre')
    ap.add_argument('--dry-run', action='store_true', help='lister ce qui entrerait, sans rien télécharger')
    args = ap.parse_args()

    url, key = os.environ.get('SUPABASE_URL', ''), os.environ.get('SUPABASE_SERVICE_KEY', '')
    if not url or not key:
        raise SystemExit('SUPABASE_URL et SUPABASE_SERVICE_KEY sont attendues dans l\'environnement')
    kinds = tuple(k for k in args.kinds.split(',') if k in KINDS)

    plants = load_plants(args.plants)
    client = Supabase(url, key)
    rows = client.rows(kinds)
    connues, inconnues = resoudre(rows, plants)
    solides = sum(1 for row, _ in connues if fiable(row))
    print(f'{len(rows)} retours, {len(connues)} sur des espèces du catalogue '
          f'({solides} solides, {len(connues) - solides} à valider), {len(inconnues)} hors catalogue')

    if inconnues:
        print('\nhors catalogue — des candidates à y inscrire, quelqu\'un possède la plante :')
        vus: dict[str, int] = {}
        for row in inconnues:
            vus[row.get('species_name', '?')] = vus.get(row.get('species_name', '?'), 0) + 1
        for nom, n in sorted(vus.items(), key=lambda kv: -kv[1])[:30]:
            print(f'   {n:>3}  {nom}')
    if args.dry_run:
        return 0

    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    manifest = Manifest(out / 'manifest.jsonl')
    gardees = doublons = rejetees = 0
    for row, plant in connues:
        for n in range(int(row.get('photos', 1))):
            if manifest.has_source(SOURCE, f"{row['id']}#{n}"):
                continue
            try:
                prepared = prepare(client.download(chemin_objet(row, n)))
            except ImageRejected as e:
                rejetees += 1
                print(f"   rejetée {row['id']}#{n} : {e}")
                continue
            record = enregistrement(row, n, prepared, plant)
            existing = manifest.by_checksum(prepared.sha256)
            if existing is not None:
                record.status, record.duplicate_of, record.reason = STATUS_DUPLICATE, existing.checksum, 'doublon exact'
                record.path = f'_duplicates/{record.path}'
                doublons += 1
            elif record.status == STATUS_KEPT:
                gardees += 1
            store(prepared, out / record.path)
            manifest.append(record)
    print(f'\n{gardees} images gardées, {doublons} doublons, {rejetees} rejetées ; '
          f'les étiquettes à valider sont dans {out / REVIEW_DIR}/')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
