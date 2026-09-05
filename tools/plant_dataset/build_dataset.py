#!/usr/bin/env python3
"""Construit le jeu d'images, espèce par espèce.

    python3 build_dataset.py --plants plants.csv --target-per-species 200
    python3 build_dataset.py --plants plants.csv --only "Monstera deliciosa,Ficus elastica" --target-per-species 20

Pour chaque plante : résolution du nom chez GBIF, collecte des images sous
licence acceptée, téléchargement, vérification, enregistrement dans le
manifeste. Puis, sur l'ensemble : déduplication, répartition, statistiques,
attributions. Relançable : ce qui est déjà dans le manifeste n'est pas
retéléchargé.

Sortie :
    dataset/
      manifest.jsonl          une ligne par image, quel que soit son statut
      splits.csv              train / val / test des images gardées
      stats.json              décomptes par espèce, licence, source
      ATTRIBUTIONS.md         auteurs et licences, à livrer avec le modèle
      attributions.csv
      species.json            ce que GBIF a répondu pour chaque nom
      <Genre_epithete>/       les images gardées
      _rejected/  _duplicates/  _review/
"""
from __future__ import annotations

import argparse
import json
import sys
import time
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

import requests

from plant_dataset.fetchers.gbif import GbifClient
from plant_dataset.fetchers.inaturalist import InatClient
from plant_dataset.images import ImageRejected, download, prepare, store
from plant_dataset.licenses import GBIF_LICENSE_CODES, GBIF_LICENSE_CODES_WITH_SA, parse_license
from plant_dataset.manifest import (STATUS_DUPLICATE, STATUS_KEPT, STATUS_REJECTED, STATUS_REVIEW, ImageRecord, Manifest,
                                    now_iso, write_attributions)
from plant_dataset.dedup import flag_cross_species, mark_duplicates
from plant_dataset.splits import write_splits
from plant_dataset.taxonomy import PlantEntry, load_plants, species_slug

STATUS_DIR = {STATUS_REJECTED: '_rejected', STATUS_DUPLICATE: '_duplicates', STATUS_REVIEW: '_review'}


def log(msg: str) -> None:
    print(msg, file=sys.stderr, flush=True)


def resolve(client: GbifClient, plant: PlantEntry, cache: dict) -> dict | None:
    """Le taxon GBIF d'une plante, mémorisé dans species.json.

    Les échecs ne sont pas mémorisés : un nom qui n'a rien donné hier peut
    en donner aujourd'hui, parce que la source a changé ou — plus souvent —
    parce que notre façon de chercher s'est améliorée. Un cache d'échecs
    rend les corrections invisibles ; une requête par nom irrésolu et par
    exécution est un prix négligeable.
    """
    if cache.get(plant.scientific_name) is not None:
        return cache[plant.scientific_name]
    m = client.match(plant.scientific_name)
    entry = None if m is None else {
        'key': m.accepted_key or m.key, 'matched_key': m.key, 'canonical': m.canonical_name, 'scientific': m.scientific_name,
        'rank': m.rank, 'status': m.status, 'match': m.match_type, 'confidence': m.confidence, 'family': m.family, 'usable': m.usable,
    }
    cache[plant.scientific_name] = entry
    return entry


def resolve_inat(client: InatClient, plant: PlantEntry, cache: dict) -> dict | None:
    """Le taxon iNaturalist d'une plante, mémorisé dans species_inat.json.

    Comme pour GBIF, les échecs ne sont pas mémorisés — c'est précisément ce
    qui avait masqué la prise en charge des synonymes : les `null` écrits
    avant la correction empêchaient de réessayer.
    """
    if cache.get(plant.scientific_name) is not None:
        return cache[plant.scientific_name]
    t = client.match(plant.scientific_name)
    entry = None if t is None else {'id': t.id, 'name': t.name, 'rank': t.rank, 'observations': t.observations,
                                    'matched_as': t.matched_as, 'synonym': t.is_synonym}
    cache[plant.scientific_name] = entry
    return entry


def collect_species(candidates, http: requests.Session, plant: PlantEntry, manifest: Manifest, out: Path,
                    target: int, workers: int = 6) -> dict:
    """Collecte une espèce depuis un itérateur de candidats, quelle que soit
    la source. Les téléchargements se font par petits lots en parallèle (le
    réseau est le goulot) ; l'écriture du manifeste reste séquentielle, dans
    l'ordre des candidats."""
    kept_before = sum(1 for r in manifest if r.species == plant.scientific_name and r.status == STATUS_KEPT)
    state = {'kept': kept_before, 'tried': 0, 'rejected': 0}
    slug = species_slug(plant.scientific_name)
    # Une même photo iNaturalist arrive par GBIF *et* par l'API directe :
    # son identifiant de photo la reconnaît avant tout téléchargement.
    known_photos = {r.extra.get('photo_id') for r in manifest if r.extra.get('photo_id')}

    def fetch(cand):
        try:
            return cand, prepare(download(cand.image_url, http)), None
        except (ImageRejected, requests.RequestException) as e:
            return cand, None, e

    def handle(cand, prepared, error) -> None:
        state['tried'] += 1
        lic = parse_license(cand.license_raw)
        base = dict(
            species=plant.scientific_name, internal_plant_id=plant.internal_id, source=cand.source, source_id=cand.source_id,
            original_url=cand.original_url, image_url=cand.image_url, author=cand.author, license=lic.code if lic else '',
            license_url=lic.url if lic else '', downloaded_at=now_iso(), observation_id=cand.observation_id,
            publisher=cand.publisher, dataset_key=cand.dataset_key, extra=cand.extra or {},
        )
        if error is not None:
            state['rejected'] += 1
            manifest.append(ImageRecord(checksum='', status=STATUS_REJECTED, reason=str(error)[:200], **base))
            return
        existing = manifest.by_checksum(prepared.sha256)
        rel = f'{slug}/{prepared.sha256[:16]}.jpg'
        record = ImageRecord(checksum=prepared.sha256, path=rel, width=prepared.width, height=prepared.height, phash=prepared.phash, **base)
        if existing is not None:
            record.status = STATUS_DUPLICATE
            record.duplicate_of = existing.checksum
            record.reason = 'doublon exact'
            record.path = f'{STATUS_DIR[STATUS_DUPLICATE]}/{rel}'
        else:
            state['kept'] += 1
        store(prepared, out / record.path)
        manifest.append(record)

    batch: list = []
    with ThreadPoolExecutor(max_workers=max(1, workers)) as pool:
        def flush() -> None:
            for cand, prepared, error in pool.map(fetch, batch):
                if state['kept'] >= target:
                    break
                handle(cand, prepared, error)
            batch.clear()

        for cand in candidates:
            if state['kept'] >= target:
                break
            if manifest.has_source(cand.source, cand.source_id):
                continue
            photo_id = (cand.extra or {}).get('photo_id')
            if photo_id and photo_id in known_photos:
                continue
            if photo_id:
                known_photos.add(photo_id)
            batch.append(cand)
            if len(batch) >= max(1, workers) * 2:
                flush()
        if batch and state['kept'] < target:
            flush()
    return {'kept': state['kept'], 'new': state['kept'] - kept_before, 'tried': state['tried'], 'rejected': state['rejected']}


def relocate(manifest: Manifest, out: Path) -> None:
    """Après la passe de déduplication, chaque fichier va dans le dossier de
    son statut ; le manifeste suit."""
    for r in manifest:
        if not r.path or not r.checksum:
            continue
        wanted = r.path
        base = r.path.split('/', 1)[1] if r.path.split('/', 1)[0] in STATUS_DIR.values() else r.path
        if r.status == STATUS_KEPT:
            wanted = base
        else:
            wanted = f'{STATUS_DIR[r.status]}/{base}'
        if wanted != r.path:
            src, dst = out / r.path, out / wanted
            if src.exists():
                dst.parent.mkdir(parents=True, exist_ok=True)
                src.replace(dst)
            r.path = wanted


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--plants', default='plants.csv')
    ap.add_argument('--out', default='dataset')
    ap.add_argument('--target-per-species', type=int, default=200)
    ap.add_argument('--only', help='noms scientifiques, séparés par des virgules')
    ap.add_argument('--limit-species', type=int, help='ne traiter que les N premières plantes')
    ap.add_argument('--allow-sa', action='store_true', help='accepter aussi CC BY-SA (refusé par défaut)')
    ap.add_argument('--max-candidates', type=int, default=1500, help='occurrences GBIF parcourues au plus, par licence')
    ap.add_argument('--skip-fetch', action='store_true', help='ne rien télécharger : dédupliquer, répartir, compter')
    ap.add_argument('--workers', type=int, default=6, help='téléchargements en parallèle')
    ap.add_argument('--only-file', help='fichier avec un nom scientifique par ligne (comme --only)')
    ap.add_argument('--no-inaturalist', action='store_true', help='ne pas compléter par l\'API iNaturalist')
    ap.add_argument('--inat-pause', type=float, default=1.0, help='pause entre requêtes iNaturalist, en secondes')
    args = ap.parse_args()

    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    plants = load_plants(args.plants)
    wanted = {n.strip().lower() for n in (args.only or '').split(',') if n.strip()}
    if args.only_file:
        wanted |= {line.strip().lower() for line in Path(args.only_file).read_text().splitlines() if line.strip()}
    if wanted:
        plants = [p for p in plants if p.scientific_name.lower() in wanted]
    if args.limit_species:
        plants = plants[:args.limit_species]
    if not plants:
        log('aucune plante à traiter')
        return 1

    manifest = Manifest(out / 'manifest.jsonl')
    species_path = out / 'species.json'
    species_cache = json.loads(species_path.read_text()) if species_path.exists() else {}
    license_codes = GBIF_LICENSE_CODES_WITH_SA if args.allow_sa else GBIF_LICENSE_CODES

    inat_path = out / 'species_inat.json'
    inat_cache = json.loads(inat_path.read_text()) if inat_path.exists() else {}

    if not args.skip_fetch:
        client = GbifClient()
        inat = None if args.no_inaturalist else InatClient(pause=args.inat_pause)
        http = requests.Session()
        http.headers['User-Agent'] = client.session.headers['User-Agent']
        for i, plant in enumerate(plants, 1):
            t0 = time.time()
            taxon = resolve(client, plant, species_cache)
            species_path.write_text(json.dumps(species_cache, ensure_ascii=False, indent=1))
            if taxon is None or not taxon['usable']:
                log(f'[{i}/{len(plants)}] {plant.scientific_name}: nom non résolu chez GBIF ({taxon and taxon["match"]}), à revoir')
                continue
            gbif_candidates = client.image_candidates(taxon['key'], license_codes, max_occurrences=args.max_candidates,
                                                      allow_share_alike=args.allow_sa)
            res = collect_species(gbif_candidates, http, plant, manifest, out, args.target_per_species, workers=args.workers)
            sources = f'gbif {res["kept"]}'

            # GBIF ne reçoit d'iNaturalist que les observations « research »,
            # donc presque aucune plante en pot. L'API directe complète.
            if inat is not None and res['kept'] < args.target_per_species:
                taxon_inat = resolve_inat(inat, plant, inat_cache)
                inat_path.write_text(json.dumps(inat_cache, ensure_ascii=False, indent=1))
                if taxon_inat is not None:
                    before = res['kept']
                    extra = collect_species(inat.image_candidates(taxon_inat['id'], max_observations=args.max_candidates,
                                                                  allow_share_alike=args.allow_sa),
                                            http, plant, manifest, out, args.target_per_species, workers=args.workers)
                    res = {'kept': extra['kept'], 'new': res['new'] + extra['new'],
                           'tried': res['tried'] + extra['tried'], 'rejected': res['rejected'] + extra['rejected']}
                    sources += f' + inat {extra["kept"] - before}'

            log(f'[{i}/{len(plants)}] {plant.scientific_name}: {res["kept"]} gardées (+{res["new"]}, {sources}), '
                f'{res["rejected"]} rejetées sur {res["tried"]} essayées, {time.time() - t0:.0f} s')

    dups = mark_duplicates(manifest.records)
    flagged = flag_cross_species(manifest.records)
    relocate(manifest, out)
    manifest.rewrite()
    counts = write_splits(manifest.records, out / 'splits.csv')
    stats = manifest.stats()
    stats['duplicates'] = dups
    stats['cross_species_review'] = flagged
    stats['splits'] = counts
    (out / 'stats.json').write_text(json.dumps(stats, ensure_ascii=False, indent=1))
    n = write_attributions(manifest.records, out / 'ATTRIBUTIONS.md', out / 'attributions.csv')

    log('')
    log(f'{stats["kept"]} images gardées sur {stats["images"]} ; doublons exacts {dups["exact"]}, quasi {dups["near"]} ; '
        f'{flagged} en revue (étiquette douteuse) ; {n} attributions')
    for species, st in stats['species'].items():
        sp = counts.get(species, {})
        log(f'  {species:32s} gardées {st.get(STATUS_KEPT, 0):4d}  rejetées {st.get(STATUS_REJECTED, 0):3d}  '
            f'doublons {st.get(STATUS_DUPLICATE, 0):3d}  revue {st.get(STATUS_REVIEW, 0):3d}  '
            f'train/val/test {sp.get("train", 0)}/{sp.get("val", 0)}/{sp.get("test", 0)}')
    log(f'licences : {stats["licenses"]}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
