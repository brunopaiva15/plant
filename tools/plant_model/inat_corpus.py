#!/usr/bin/env python3
"""Les plantes d'iNaturalist comme corpus de distillation, sans leurs étiquettes.

**La source.** `philipp-zettl/inaturalist-enriched` sur Hugging Face :
1 487 090 photos iNaturalist sous CC0 ou CC-BY, instantané du 27 mars 2026,
595 fichiers Parquet d'environ 330 Mo avec les images dedans — 197 Go en tout.
C'est `inaturalist-s3-massive` enrichi de `taxon_id`, `species_name` et
`taxonomic_rank`.

**Pourquoi elles servent telles quelles.** Comme pour Pl@ntNet-300K (§ 20 ter
de `docs/14`), le student apprend à reproduire le vecteur du teacher, pas à
nommer. Une observation « casual » ou mal identifiée, inutilisable pour
entraîner un classifieur, est ici une photo de plante comme une autre.

**Ce que le script trie, et pourquoi c'est lui qui le fait :**

1. **Tout le vivant est là.** `species_name` ne dit pas si c'est une plante ;
   l'arbre le dit. `taxa.csv.gz`, publié par iNaturalist sur son seau public
   (40 Mo), donne l'ascendance de chaque taxon : une plante descend de
   *Plantae*, taxon 47126. Une photo sans taxon est écartée — rien ne dit
   qu'elle montre une plante.
2. **Le banc ne doit pas rentrer dans l'entraînement.** Il est bâti sur notre
   corpus GBIF/iNaturalist, donc une partie de ses photos est très
   probablement dans ce jeu. L'entraîner dessus gonflerait tous les chiffres
   suivants sans qu'un seul le signale. Trois gardes, parce qu'aucune ne
   suffit seule :
   - par `photo_id` : toutes les photos iNaturalist de nos manifestes,
     retrouvées dans leurs URL, sont écartées — celles du banc pour la fuite,
     les autres parce qu'elles sont déjà au corpus ;
   - par empreinte perceptuelle contre chaque image du banc : une copie
     relayée par GBIF sous une autre URL, recompressée ou redimensionnée,
     tombe à quelques bits de l'original. Même empreinte et même seuil que la
     déduplication de `tools/plant_dataset` ;
   - **par observation** : `splits.py` regroupe les photos d'une même
     observation, parce que deux prises de la même plante le même jour sont
     une fuite. Ce jeu peut contenir la photo *sœur* d'une image du banc —
     autre `photo_id`, autre cadrage, qu'aucune des deux gardes précédentes
     n'attrape. Les observations iNaturalist du banc sont donc demandées à
     l'API (par lots de 200, une trentaine de requêtes), et toutes leurs
     photos écartées, par `photo_id` comme par `observation_uuid`.
3. **Aucun gigaoctet inutile.** Chaque fichier Parquet est téléchargé, trié,
   réduit à 320 px, puis supprimé. On ne garde que les plantes retenues.

**Ce qu'il ne vérifie pas : la licence.** Le jeu n'a pas de colonne licence,
son auteur annonce CC0 et CC-BY. Notre règle (§ 4.1) veut qu'on vérifie ;
c'est un contrôle par échantillon, séparé, noté au § 20 quater de `docs/14`.

**Ce script ne touche pas au GPU.** Il peut tourner pendant une distillation.

    python3 inat_corpus.py --fragments 2      # essai : la part de plantes
    python3 inat_corpus.py                    # le tout, reprenable

La sortie est au format de `tools/plant_dataset` — `images/` et `splits.csv`
— et `distiller.py --dataset` la lit comme les autres.
"""
import argparse
import csv
import gzip
import io
import json
import os
import re
import sys
import threading
import time
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'plant_dataset'))

from plantnet_avis import binome, noms_du_catalogue          # noqa: E402
from plantnet_corpus import ecrire, verrou_vivant             # noqa: E402

DEPOT = 'philipp-zettl/inaturalist-enriched'
TAXA = 'https://inaturalist-open-data.s3.amazonaws.com/taxa.csv.gz'
PLANTAE = '47126'
TAILLE = 320
SEUIL = 6    # bits sur 64 — `NEAR_THRESHOLD` de plant_dataset/dedup.py


# --------------------------------------------------------------------------
# Ce qui est une plante
# --------------------------------------------------------------------------

def taxons_plantes(lignes) -> set[int]:
    """Les `taxon_id` qui descendent de *Plantae*, *Plantae* compris.

    `lignes` sont les dictionnaires de `taxa.csv` : `ancestry` y est la liste
    des ancêtres séparés par `/`, du plus large au plus proche. Les taxons
    inactifs sont gardés : une observation ancienne peut pointer vers un nom
    depuis fusionné, et la photo n'en montre pas moins une plante.
    """
    sortie = set()
    for r in lignes:
        tid = r.get('taxon_id', '')
        if tid == PLANTAE or PLANTAE in (r.get('ancestry') or '').split('/'):
            try:
                sortie.add(int(tid))
            except ValueError:
                pass
    return sortie


def lire_taxa(chemin: Path) -> set[int]:  # pragma: no cover - fichier réel
    with gzip.open(chemin, 'rt', encoding='utf-8', newline='') as f:
        return taxons_plantes(csv.DictReader(f, delimiter='\t'))


# --------------------------------------------------------------------------
# Ce qui est déjà chez nous
# --------------------------------------------------------------------------

def photos_connues(lignes_de_manifeste) -> set[str]:
    """Les `photo_id` iNaturalist de nos manifestes, quelle que soit la source.

    GBIF relaie les URL iNaturalist telles quelles, donc une image « gbif » du
    manifeste peut être une photo iNaturalist : on lit l'URL, pas la source.
    Le statut n'est pas regardé non plus — une image rejetée chez nous pour
    une raison de qualité ne devient pas bonne en passant par ce jeu.
    """
    from plant_dataset.fetchers.inaturalist import photo_id_of
    ids = set()
    for ligne in lignes_de_manifeste:
        try:
            r = json.loads(ligne)
        except (json.JSONDecodeError, TypeError):
            continue
        for cle in ('image_url', 'original_url'):
            pid = photo_id_of(r.get(cle) or '')
            if pid:
                ids.add(str(pid))
    return ids


_OBSERVATION = re.compile(r'inaturalist\.org/observations/(\d+)')


def observations_du_banc(lignes_de_manifeste, racine: Path, banc: set[str]) -> set[str]:
    """Les identifiants d'observation iNaturalist des images du banc.

    Une image du banc est reconnue à son chemin : le manifeste le donne
    relatif à son dossier, le banc absolu. Source iNaturalist, l'observation
    est dans `observation_id` ; source GBIF, `observation_id` est une clé
    d'occurrence GBIF, mais une occurrence publiée par iNaturalist pointe vers
    l'observation dans `original_url`.
    """
    banc_norm = {os.path.normpath(c) for c in banc}
    ids = set()
    for ligne in lignes_de_manifeste:
        try:
            r = json.loads(ligne)
        except (json.JSONDecodeError, TypeError):
            continue
        if not r.get('path'):
            continue
        if os.path.normpath(str(racine / r['path'])) not in banc_norm:
            continue
        if r.get('source') == 'inaturalist' and r.get('observation_id'):
            ids.add(str(r['observation_id']))
            continue
        m = _OBSERVATION.search(r.get('original_url') or '')
        if m:
            ids.add(m.group(1))
    return ids


def soeurs(observations: list[dict]) -> tuple[set[str], set[str]]:
    """(photo_id, observation_uuid) de toutes les photos de ces observations,
    telles que l'API iNaturalist les rend."""
    photos, uuids = set(), set()
    for o in observations:
        if o.get('uuid'):
            uuids.add(str(o['uuid']))
        for ph in o.get('photos') or []:
            if ph.get('id') is not None:
                photos.add(str(ph['id']))
    return photos, uuids


def distances(h: int, banc: np.ndarray) -> np.ndarray:
    """Bits de différence entre une empreinte et chacune de celles du banc."""
    x = np.bitwise_xor(banc, np.uint64(h))
    return np.unpackbits(x.view(np.uint8).reshape(-1, 8), axis=1).sum(axis=1)


def proche_du_banc(h: int, banc: np.ndarray, seuil: int = SEUIL) -> bool:
    return bool(len(banc)) and int(distances(h, banc).min()) <= seuil


# --------------------------------------------------------------------------
# Le tri, ligne par ligne
# --------------------------------------------------------------------------

def motif_de_rejet(photo_id: str, taxon_id, plantes: set[int], connues: set[str],
                   observation_uuid: str = '', interdites: set[str] = frozenset()) -> str:
    """Pourquoi une ligne est écartée avant même d'ouvrir l'image, ou ''.

    L'ordre compte pour le bilan : une photo d'insecte déjà au corpus n'existe
    pas, mais une plante déjà au corpus doit être comptée comme telle — c'est
    le chiffre qui dit combien ce jeu apporte vraiment de neuf.
    """
    if taxon_id is None or taxon_id != taxon_id:       # None ou NaN
        return 'sans taxon'
    if int(taxon_id) not in plantes:
        return 'pas une plante'
    if observation_uuid and str(observation_uuid) in interdites:
        return 'observation du banc'
    if str(photo_id) in connues:
        return 'déjà au corpus'
    return ''


def destination(taxon_id: int, photo_id: str) -> str:
    return f'images/{int(taxon_id)}/{photo_id}.jpg'


def identite(nom: str, rang: str, taxon_id: int, catalogue: dict[str, str]) -> str:
    """Notre identifiant quand l'espèce est au catalogue, `inat:<id>` sinon.

    Seul un rang d'espèce ou inférieur se rattache : un binôme tiré d'un nom
    de genre (« Monstera ») ne désigne aucune espèce. Le préfixe `inat:` joue
    le rôle de `pn:` pour Pl@ntNet : une clé qu'on ne confond jamais avec les
    nôtres, et que `bioclip.py centroides` ne prendra pas pour une espèce.
    """
    if rang in ('species', 'subspecies', 'variety', 'form', 'hybrid'):
        interne = catalogue.get(binome(nom or ''))
        if interne:
            return interne
    return f'inat:{int(taxon_id)}'


def preparer_image(octets: bytes, taille: int = TAILLE) -> tuple[bytes, int]:
    """(JPEG réduit, empreinte perceptuelle), en un seul décodage.

    L'empreinte est prise sur l'image entière, avant réduction, comme celles
    du manifeste : c'est la même fonction, sur la même chose.
    """
    from PIL import Image, ImageOps
    from plant_dataset.images import phash64
    im = Image.open(io.BytesIO(octets))
    im = ImageOps.exif_transpose(im).convert('RGB')
    h = phash64(im)
    if max(im.size) > taille:
        im.thumbnail((taille, taille), Image.BICUBIC)
    tampon = io.BytesIO()
    im.save(tampon, format='JPEG', quality=90)
    return tampon.getvalue(), h


# --------------------------------------------------------------------------
# Le manifeste
# --------------------------------------------------------------------------

COLONNES = ['path', 'internal_plant_id', 'taxon_id', 'species_name',
            'taxonomic_rank', 'photo_id', 'observation_uuid']


def ecrire_splits(index: Path, sortie: Path) -> int:
    """`splits.csv` depuis l'index, sans doublon, sur les seuls fichiers
    présents.

    Un fragment interrompu puis repris réécrit ses lignes dans l'index : on
    dédoublonne par chemin. Une ligne sans fichier ferait un jeu plus petit
    qu'annoncé, et `distiller.py` changerait ses pas par époque sans le dire.
    """
    vus, lignes = set(), []
    if index.exists():
        with open(index, newline='', encoding='utf-8') as f:
            for r in csv.DictReader(f):
                if r['path'] not in vus and (sortie / r['path']).exists():
                    vus.add(r['path'])
                    lignes.append(r)
    with open(sortie / 'splits.csv', 'w', newline='', encoding='utf-8') as f:
        w = csv.writer(f)
        w.writerow(['internal_plant_id', 'path', 'split', 'captive'])
        for r in lignes:
            # `captive` reste vide : iNaturalist le sait, ce jeu ne l'a pas
            # gardé, et écrire 0 affirmerait une plante sauvage.
            w.writerow([r['internal_plant_id'], r['path'], 'train', ''])
    return len(lignes)


# --------------------------------------------------------------------------
# Le réseau et le disque
# --------------------------------------------------------------------------

def fragments_du_depot(depot: str) -> list[str]:  # pragma: no cover - réseau
    import requests
    r = requests.get(f'https://huggingface.co/api/datasets/{depot}', timeout=60,
                     headers=_entetes())
    r.raise_for_status()
    return sorted(s['rfilename'] for s in r.json()['siblings']
                  if s['rfilename'].endswith('.parquet'))


def _entetes() -> dict:
    jeton = os.environ.get('HF_TOKEN')
    return {'Authorization': f'Bearer {jeton}'} if jeton else {}


def telecharger(url: str, dest: Path, entetes: dict | None = None,
                essais: int = 8) -> Path:  # pragma: no cover - réseau
    """Téléchargement reprenable : un fichier `.part` qu'on complète par plage.

    Même leçon que Zenodo (§ 20 ter) : une connexion d'une demi-heure ne tient
    pas d'un bloc, et recommencer à zéro coûte tout.
    """
    import requests
    dest.parent.mkdir(parents=True, exist_ok=True)
    partiel = dest.with_name(dest.name + '.part')
    for n in range(essais):
        deja = partiel.stat().st_size if partiel.exists() else 0
        h = dict(entetes or {})
        if deja:
            h['Range'] = f'bytes={deja}-'
        try:
            with requests.get(url, headers=h, stream=True, timeout=120) as r:
                if r.status_code == 416:          # déjà complet
                    break
                r.raise_for_status()
                mode = 'ab' if deja and r.status_code == 206 else 'wb'
                with open(partiel, mode) as f:
                    for bloc in r.iter_content(1 << 20):
                        f.write(bloc)
            break
        except Exception as e:
            if n == essais - 1:
                raise
            print(f'  coupure ({type(e).__name__}), reprise dans {2 ** n} s', flush=True)
            time.sleep(2 ** n)
    partiel.rename(dest)
    return dest


def traiter_fragment(fichier: Path, sortie: Path, plantes, connues, banc, catalogue,
                     taille: int, seuil: int, fils: int, index_f,
                     interdites: set[str] = frozenset()) -> dict:
    import pyarrow.parquet as pq
    from concurrent.futures import ThreadPoolExecutor
    compte = {'lignes': 0, 'sans taxon': 0, 'pas une plante': 0, 'déjà au corpus': 0,
              'observation du banc': 0,
              'proche du banc': 0, 'illisible': 0, 'déjà écrite': 0, 'gardée': 0}
    verrou = threading.Lock()
    w = csv.DictWriter(index_f, fieldnames=COLONNES)

    def une(ligne):
        pid, tid = str(ligne['photo_id']), ligne['taxon_id']
        relatif = destination(tid, pid)
        if (sortie / relatif).exists():
            return 'déjà écrite', ligne, relatif
        try:
            jpeg, h = preparer_image(ligne['image'], taille)
        except Exception:
            return 'illisible', ligne, relatif
        if proche_du_banc(h, banc, seuil):
            return 'proche du banc', ligne, relatif
        ecrire(sortie, relatif, jpeg)
        return 'gardée', ligne, relatif

    colonnes = ['photo_id', 'observation_uuid', 'taxon_id', 'species_name',
                'taxonomic_rank', 'image']
    with ThreadPoolExecutor(max_workers=fils) as pool:
        for lot in pq.ParquetFile(fichier).iter_batches(batch_size=512, columns=colonnes):
            lignes = lot.to_pylist()
            compte['lignes'] += len(lignes)
            a_ouvrir = []
            for l in lignes:
                motif = motif_de_rejet(l['photo_id'], l['taxon_id'], plantes, connues,
                                       l.get('observation_uuid') or '', interdites)
                if motif:
                    compte[motif] += 1
                else:
                    a_ouvrir.append(l)
            for issue, l, relatif in pool.map(une, a_ouvrir):
                compte[issue] += 1
                if issue in ('gardée', 'déjà écrite'):
                    with verrou:
                        w.writerow({
                            'path': relatif,
                            'internal_plant_id': identite(l['species_name'], l['taxonomic_rank'],
                                                          l['taxon_id'], catalogue),
                            'taxon_id': int(l['taxon_id']), 'species_name': l['species_name'],
                            'taxonomic_rank': l['taxonomic_rank'],
                            'photo_id': l['photo_id'], 'observation_uuid': l['observation_uuid']})
            index_f.flush()
    return compte


def demander_soeurs(ids: set[str], cache: Path) -> tuple[set[str], set[str]]:  # pragma: no cover - réseau
    """Les photos sœurs des observations du banc, demandées une fois et gardées.

    Lots de 200, le maximum de l'API ; le client de `plant_dataset` porte déjà
    les reprises et la pause entre requêtes. Le résultat est mis en cache : le
    banc est figé, ses observations aussi.
    """
    if cache.exists():
        d = json.loads(cache.read_text())
        if set(d.get('ids', [])) == ids:
            return set(d['photos']), set(d['uuids'])
    from plant_dataset.fetchers.inaturalist import InatClient
    client, rendues = InatClient(), []
    tri = sorted(ids)
    for i in range(0, len(tri), 200):
        d = client._get('/observations', id=','.join(tri[i:i + 200]), per_page=200)
        rendues += d.get('results') or []
        print(f'  observations du banc : {min(i + 200, len(tri))}/{len(tri)}', flush=True)
    photos, uuids = soeurs(rendues)
    manquantes = len(ids) - len({str(o.get('id')) for o in rendues})
    if manquantes:
        print(f'  {manquantes} observations introuvables (supprimées ou masquées) : '
              f'leurs photos restent gardées par photo_id et empreinte', flush=True)
    cache.write_text(json.dumps({'ids': tri, 'photos': sorted(photos), 'uuids': sorted(uuids)}))
    return photos, uuids


def empreintes_du_banc(banc_csv: Path) -> np.ndarray:  # pragma: no cover - fichiers réels
    from PIL import Image, ImageOps
    from student import lire_banc
    from plant_dataset.images import phash64
    chemins = lire_banc(banc_csv)
    sortie = []
    for i, c in enumerate(chemins):
        try:
            im = ImageOps.exif_transpose(Image.open(c)).convert('RGB')
            sortie.append(phash64(im))
        except Exception:
            continue
        if (i + 1) % 1000 == 0:
            print(f'  empreintes du banc : {i + 1}/{len(chemins)}', flush=True)
    if len(sortie) < len(chemins):
        print(f'  {len(chemins) - len(sortie)} images du banc illisibles, '
              f'gardées par leur seul photo_id', flush=True)
    return np.array(sortie, dtype=np.uint64)


def main() -> int:  # pragma: no cover - réseau et disque
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--sortie', default='~/plant-data/inat-plantes')
    ap.add_argument('--depot', default=DEPOT)
    ap.add_argument('--telechargements', default='~/plant-data/inat-fragments',
                    help='où poser un fragment le temps de le trier')
    ap.add_argument('--taxa', default='~/plant-data/inat/taxa.csv.gz')
    ap.add_argument('--manifeste', action='append', default=[],
                    help='répétable ; défaut : ~/plant-data/dataset-v8-indoor/manifest.jsonl')
    ap.add_argument('--banc', default='benchmark.csv')
    ap.add_argument('--plants', default='../plant_dataset/plants.csv')
    ap.add_argument('--fragments', type=int, default=0,
                    help="n'en traiter que N — un essai pour mesurer la part de plantes")
    ap.add_argument('--taille', type=int, default=TAILLE)
    ap.add_argument('--seuil', type=int, default=SEUIL)
    ap.add_argument('--fils', type=int, default=6)
    ap.add_argument('--garder', action='store_true',
                    help='ne pas supprimer les fragments une fois triés')
    ap.add_argument('--forcer', action='store_true')
    args = ap.parse_args()

    sortie = Path(args.sortie).expanduser()
    sortie.mkdir(parents=True, exist_ok=True)
    verrou = sortie / '.passe-en-cours'
    if verrou_vivant(verrou) and not args.forcer:
        raise SystemExit(f'une autre passe écrit déjà dans {sortie}. `tmux ls` pour la retrouver.')
    verrou.touch()

    # Les deux gardes contre la fuite. Sans elles, pas de passe.
    manifestes = [Path(m).expanduser() for m in
                  (args.manifeste or ['~/plant-data/dataset-v8-indoor/manifest.jsonl'])]
    absents = [str(m) for m in manifestes if not m.exists()]
    if absents:
        raise SystemExit(f'manifeste introuvable : {", ".join(absents)}\n'
                         f'Sans lui, les photos déjà au corpus — banc compris — '
                         f'entreraient dans l\'entraînement. --manifeste pour le chemin exact.')
    banc_csv = Path(args.banc).expanduser()
    if not banc_csv.exists():
        raise SystemExit(f'{banc_csv} introuvable — lancer depuis tools/plant_model. '
                         f'Les empreintes du banc sont la seconde garde contre la fuite.')

    taxa = Path(args.taxa).expanduser()
    if not taxa.exists():
        print('téléchargement de taxa.csv.gz…', flush=True)
        telecharger(TAXA, taxa)
    plantes = lire_taxa(taxa)
    print(f'{len(plantes)} taxons sous Plantae')

    from student import lire_banc
    chemins_du_banc = set(lire_banc(banc_csv))
    connues, ids_banc = set(), set()
    for m in manifestes:
        with open(m, encoding='utf-8') as f:
            connues |= photos_connues(f)
        with open(m, encoding='utf-8') as f:
            ids_banc |= observations_du_banc(f, m.parent, chemins_du_banc)
    print(f'{len(connues)} photos iNaturalist déjà dans nos manifestes')
    print(f'{len(ids_banc)} observations iNaturalist dans le banc', flush=True)
    photos_soeurs, interdites = demander_soeurs(ids_banc, sortie / 'observations-du-banc.json')
    connues |= photos_soeurs
    print(f'{len(photos_soeurs)} photos de ces observations écartées, '
          f'{len(interdites)} observation_uuid interdits')
    print('empreintes du banc…', flush=True)
    banc = empreintes_du_banc(banc_csv)
    print(f'{len(banc)} empreintes, seuil {args.seuil} bits\n')

    catalogue = noms_du_catalogue(Path(args.plants).expanduser())
    faits_f = sortie / 'fragments-faits.txt'
    faits = set(faits_f.read_text().split()) if faits_f.exists() else set()
    tous = fragments_du_depot(args.depot)
    a_faire = [f for f in tous if f not in faits]
    if args.fragments:
        a_faire = a_faire[:args.fragments]
    print(f'{len(tous)} fragments, {len(faits)} déjà triés, {len(a_faire)} cette passe\n')

    bilan_f = sortie / 'bilan.json'
    bilan = json.loads(bilan_f.read_text()) if bilan_f.exists() else {}
    telech = Path(args.telechargements).expanduser()
    index = sortie / 'index.csv'
    neuf = not index.exists()
    debut = time.perf_counter()
    with open(index, 'a', newline='', encoding='utf-8') as index_f:
        if neuf:
            csv.DictWriter(index_f, fieldnames=COLONNES).writeheader()
        for i, nom in enumerate(a_faire, 1):
            verrou.touch()
            url = f'https://huggingface.co/datasets/{args.depot}/resolve/main/{nom}'
            fichier = telecharger(url, telech / Path(nom).name, _entetes())
            c = traiter_fragment(fichier, sortie, plantes, connues, banc, catalogue,
                                 args.taille, args.seuil, args.fils, index_f, interdites)
            bilan[nom] = c
            bilan_f.write_text(json.dumps(bilan, ensure_ascii=False, indent=1))
            with open(faits_f, 'a') as f:
                f.write(nom + '\n')
            if not args.garder:
                fichier.unlink(missing_ok=True)
            total = {k: sum(b.get(k, 0) for b in bilan.values()) for k in c}
            ecoule = time.perf_counter() - debut
            reste = ecoule / i * (len(a_faire) - i) / 60
            print(f'  fragment {i}/{len(a_faire)}  {nom}  gardées {c["gardée"]}/{c["lignes"]}  '
                  f'— cumul : {total["gardée"]} gardées, {total["pas une plante"]} hors plantes, '
                  f'{total["déjà au corpus"]} déjà au corpus, '
                  f'{total["proche du banc"] + total["observation du banc"]} écartées pour le banc  '
                  f'reste {reste:.0f} min', flush=True)

    ecrites = ecrire_splits(index, sortie)
    print(f'\n{sortie} — {ecrites} images dans splits.csv')
    print('relancer la même commande reprend les fragments manquants ; puis, GPU libre :')
    print(f'  python3 bioclip.py cache --dataset {args.sortie} --cache ~/plant-data/bioclip --batch 64')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
