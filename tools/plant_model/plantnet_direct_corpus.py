#!/usr/bin/env python3
"""Les plantes en pot de Pl@ntNet comme corpus de distillation.

**Pourquoi ce corpus.** Les bras Pl@ntNet-300K et iNaturalist (§ 20 ter et
20 quater de `docs/14`) ont ajouté 840 000 photos prises dehors : l'outdoor
a gagné un point et demi, l'indoor rien. Ce qui manque au student, ce sont
des plantes d'intérieur. Pl@ntNet en a : ce que les gens photographient chez
eux ou en jardinerie pour savoir ce qu'ils ont acheté (§ 15 de `docs/09`).

**L'accès est autorisé par écrit par Pl@ntNet** (§ 15.5 de `docs/09`). Le
client est celui de `tools/plant_dataset` : `fetchers/plantnet.py`.

**Les espèces.** Toutes celles de `disponibilite_plantnet.csv` qui ont des
photos libres, quel que soit leur verdict : le student apprend à reproduire
le vecteur du teacher, il ne lit aucun nom. Une photo d'*Anthurium
andraeanum* rangée sous *A. scherzerianum* (§ 15.4) est inutilisable pour
une classe, et une bonne photo de plante en pot pour la distillation. Les
espèces « déjà dans le modèle » en font partie : ce sont les plus
photographiées, et la même plante vue en pot.

**Au plus 2 000 photos par espèce** (`--max-par-espece`), la plante entière
d'abord. Sans plafond, *Dieffenbachia seguine* ferait à elle seule un dixième
du corpus.

**Le banc ne doit pas rentrer dans l'entraînement.** Les mêmes trois gardes
que pour iNaturalist (§ 20 quater), adaptées à Pl@ntNet :

- **par identifiant d'image** : GBIF relaie les observations de Pl@ntNet avec
  leurs URL, donc une image de nos manifestes peut en venir. Tout
  identifiant `bs.plantnet.org` qu'on y trouve est écarté — celles du banc
  pour la fuite, les autres parce qu'elles sont déjà au corpus. Même chose
  pour les images du corpus Pl@ntNet-300K, dont les noms de fichier sont ces
  identifiants ;
- **par observation** : toutes les photos d'une observation dont une image
  est au banc sont écartées. Le détail d'une espèce donne l'observation de
  chaque image, aucune requête de plus ;
- **par empreinte perceptuelle**, sur l'image entière téléchargée : une même
  photo publiée sur iNaturalist et sur Pl@ntNet par son auteur n'a pas le
  même identifiant, mais la même empreinte à quelques bits près.

L'image téléchargée est l'originale (`o`), pas la vignette carrée (`m`) :
l'empreinte doit être prise sur la même chose que celles du banc.

**La licence est lue image par image** par `licenses.py`. CC BY-SA est
acceptée, comme dans `build_dataset.py --allow-sa` (décision du 6 septembre
2026). `attributions.csv` porte, pour chaque image gardée, la mention
demandée : « Photo : <auteur> / Pl@ntNet, CC BY-SA 4.0 ».

**Ce script ne touche pas au GPU.** Il peut tourner pendant une distillation,
au prix d'un peu de processeur.

    python3 plantnet_direct_corpus.py --especes 2     # essai sur deux espèces
    python3 plantnet_direct_corpus.py                 # le tout, reprenable

La sortie est au format de `tools/plant_dataset` — `images/` et `splits.csv`
— et `distiller.py --dataset` la lit comme les autres.
"""
import argparse
import csv
import json
import re
import sys
import threading
import time
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'plant_dataset'))

from inat_corpus import SEUIL, TAILLE, ecrire_splits, preparer_image, proche_du_banc  # noqa: E402
from plantnet_avis import binome, noms_du_catalogue                                  # noqa: E402
from plantnet_corpus import ecrire, verrou_vivant                                    # noqa: E402
from plant_dataset.fetchers.plantnet import (                                         # noqa: E402
    image_id_of, images_par_organe, licence_de)
from plant_dataset.licenses import is_allowed                                         # noqa: E402

MAX_PAR_ESPECE = 2000
ESPECES = Path(__file__).resolve().parents[1] / 'plant_dataset' / 'disponibilite_plantnet.csv'
COLONNES = ['path', 'internal_plant_id', 'species_name', 'photo_id', 'observation_id',
            'organ', 'author', 'license', 'url']
MOTIFS = ('licence', 'déjà au corpus', 'observation du banc', 'proche du banc',
          'illisible', 'échec réseau')


# --------------------------------------------------------------------------
# Ce qu'on collecte
# --------------------------------------------------------------------------

def especes_a_collecter(lignes, verdicts: set[str] | None = None) -> list[tuple[str, str]]:
    """(nom Pl@ntNet, nom du dépôt) des espèces à collecter, dans l'ordre du
    tableau.

    Une espèce sans photo libre est sautée : « absente de Pl@ntNet » et « nom
    corrigé » n'en ont aucune. `verdicts` à None les prend toutes.
    """
    sortie, vus = [], set()
    for r in lignes:
        nom = ' '.join((r.get('espece_plantnet') or '').split())
        if not nom or nom in vus:
            continue
        if verdicts is not None and r.get('verdict') not in verdicts:
            continue
        try:
            libres = int(r.get('photos_libres') or 0)
        except ValueError:
            libres = 0
        if libres <= 0:
            continue
        vus.add(nom)
        sortie.append((nom, ' '.join((r.get('noms_du_depot') or '').split())))
    return sortie


def identite(espece: str, depot: str, catalogue: dict[str, str]) -> str:
    """Notre identifiant quand l'espèce est au catalogue, `pnd:<nom>` sinon.

    Le nom du dépôt d'abord : Pl@ntNet range *Dracaena angolensis* là où nous
    avons `sansevieria-cylindrica` (§ 15.3). Le préfixe `pnd:` joue le rôle
    de `pn:` et `inat:` : une clé qui ne se confond jamais avec les nôtres, et
    que `bioclip.py centroides` ne prendra pas pour une espèce du catalogue.
    """
    for nom in (depot, espece):
        interne = catalogue.get(binome(nom or ''))
        if interne:
            return interne
    return 'pnd:' + '_'.join(binome(espece).split())


_SUR = re.compile(r'[^A-Za-z0-9_.-]+')


def destination(espece: str, photo_id: str) -> str:
    dossier = _SUR.sub('_', '_'.join(binome(espece).split())) or 'inconnue'
    return f'images/{dossier}/{photo_id}.jpg'


# --------------------------------------------------------------------------
# Ce qui est déjà chez nous
# --------------------------------------------------------------------------

def ids_des_manifestes(lignes_de_manifeste, racine: Path,
                       banc: set[str]) -> tuple[set[str], set[str]]:
    """(identifiants Pl@ntNet de nos manifestes, ceux des images du banc).

    L'URL dit d'où vient l'image, pas la source : GBIF relaie Pl@ntNet. Une
    image du banc est reconnue à son chemin, comme dans `inat_corpus.py`.
    """
    import os
    banc_norm = {os.path.normpath(c) for c in banc}
    connues, du_banc = set(), set()
    for ligne in lignes_de_manifeste:
        try:
            r = json.loads(ligne)
        except (json.JSONDecodeError, TypeError):
            continue
        ids = {i for i in (image_id_of(r.get('image_url') or ''),
                           image_id_of(r.get('original_url') or '')) if i}
        if r.get('source') == 'plantnet' and (r.get('extra') or {}).get('photo_id'):
            ids.add(str(r['extra']['photo_id']).lower())
        if not ids:
            continue
        connues |= ids
        if r.get('path') and os.path.normpath(str(racine / r['path'])) in banc_norm:
            du_banc |= ids
    return connues, du_banc


def ids_des_corpus(lignes_de_splits) -> set[str]:
    """Les identifiants d'un corpus déjà extrait, lus dans les noms de fichier.

    Les images de Pl@ntNet-300K portent l'identifiant Pl@ntNet de la photo :
    les reprendre ici ne ferait qu'un doublon.
    """
    ids = set()
    for r in lignes_de_splits:
        tronc = Path(r.get('path') or '').stem.lower()
        if re.fullmatch(r'[0-9a-f]{16,64}', tronc):
            ids.add(tronc)
    return ids


def observations_interdites(images: list[dict], du_banc: set[str]) -> set[str]:
    """Les observations dont une image est au banc : leurs photos sœurs
    partent avec elle."""
    return {str(im.get('observationId')) for im in images
            if str(im.get('id', '')).lower() in du_banc and im.get('observationId')}


def motif_de_rejet(image: dict, connues: set[str], interdites: set[str]) -> str:
    """Pourquoi une image est écartée avant d'être téléchargée, ou ''."""
    if not is_allowed(licence_de(image), allow_share_alike=True):
        return 'licence'
    if str(image.get('observationId')) in interdites:
        return 'observation du banc'
    if str(image.get('id', '')).lower() in connues:
        return 'déjà au corpus'
    return ''


def attribution(ligne: dict) -> str:
    """La mention que demande Pl@ntNet, image par image."""
    auteur = ligne.get('author') or 'auteur inconnu'
    return f"Photo : {auteur} / Pl@ntNet, {ligne.get('license', '')}".strip().rstrip(',')


def ecrire_attributions(index: Path, sortie: Path) -> int:
    """`attributions.csv` depuis l'index, une ligne par image présente."""
    vus, lignes = set(), []
    if index.exists():
        with open(index, newline='', encoding='utf-8') as f:
            for r in csv.DictReader(f):
                if r['path'] not in vus and (sortie / r['path']).exists():
                    vus.add(r['path'])
                    lignes.append(r)
    with open(sortie / 'attributions.csv', 'w', newline='', encoding='utf-8') as f:
        w = csv.writer(f)
        w.writerow(['path', 'author', 'license', 'url', 'attribution'])
        for r in lignes:
            w.writerow([r['path'], r['author'], r['license'], r['url'], attribution(r)])
    return len(lignes)


# --------------------------------------------------------------------------
# Le réseau et le disque
# --------------------------------------------------------------------------

_sessions = threading.local()


def _session():  # pragma: no cover - réseau
    import requests
    s = getattr(_sessions, 's', None)
    if s is None:
        from plant_dataset.fetchers.plantnet import DEFAULT_UA
        s = _sessions.s = requests.Session()
        s.headers['User-Agent'] = DEFAULT_UA
    return s


def telecharger_image(url: str, tentatives: int = 4) -> bytes:  # pragma: no cover - réseau
    import requests
    for essai in range(tentatives):
        try:
            r = _session().get(url, timeout=60)
            if r.status_code == 429:
                time.sleep(float(r.headers.get('Retry-After') or 30))
                continue
            r.raise_for_status()
            return r.content
        except (requests.ConnectionError, requests.Timeout, requests.HTTPError):
            if essai == tentatives - 1:
                raise
            time.sleep(2 ** essai)
    raise RuntimeError('429 persistant')


def traiter_image(image: dict, espece: str, interne: str, sortie: Path, banc: np.ndarray,
                  taille: int, seuil: int, pause: float) -> tuple[str, dict | None]:  # pragma: no cover
    """(motif, ligne d'index) : motif vide et ligne quand l'image est gardée."""
    iid = str(image['id']).lower()
    relatif = destination(espece, iid)
    lic = licence_de(image)
    ligne = {'path': relatif, 'internal_plant_id': interne, 'species_name': espece,
             'photo_id': iid, 'observation_id': str(image.get('observationId') or ''),
             'organ': image.get('organ', ''),
             'author': ' '.join(str(image.get('author') or '').split()),
             'license': lic.code if lic else '', 'url': image.get('o') or ''}
    if (sortie / relatif).exists():
        return '', ligne            # une reprise : l'image est déjà là, entière
    try:
        octets = telecharger_image(image['o'])
    except Exception:
        return 'échec réseau', None
    finally:
        if pause:
            time.sleep(pause)
    try:
        reduite, h = preparer_image(octets, taille)
    except Exception:
        return 'illisible', None
    if proche_du_banc(h, banc, seuil):
        return 'proche du banc', None
    ecrire(sortie, relatif, reduite)
    return '', ligne


def empreintes_du_banc(banc_csv: Path) -> np.ndarray:  # pragma: no cover - fichiers réels
    from inat_corpus import empreintes_du_banc as calculer
    return calculer(banc_csv)


def main() -> int:  # pragma: no cover - réseau et disque
    from plant_dataset.fetchers.plantnet import PlantnetClient
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--sortie', default='~/plant-data/plantnet-direct')
    ap.add_argument('--liste', default=str(ESPECES),
                    help='le tableau du § 15.3 de docs/09 : une espèce par ligne, et son verdict')
    ap.add_argument('--verdict', action='append', default=[],
                    help="répétable : ne collecter que ces verdicts. Défaut : tous, "
                         "puisque le student ne lit aucun nom")
    ap.add_argument('--manifeste', action='append', default=[],
                    help='répétable ; défaut : ~/plant-data/dataset-v8-indoor/manifest.jsonl')
    ap.add_argument('--corpus', action='append', default=[],
                    help='répétable : corpus déjà extraits dont les images sont des '
                         'photos Pl@ntNet ; défaut : ~/plant-data/plantnet-300k s\'il existe')
    ap.add_argument('--banc', default='benchmark.csv')
    ap.add_argument('--plants', default='../plant_dataset/plants.csv')
    ap.add_argument('--especes', type=int, default=0, help="n'en traiter que N — un essai")
    ap.add_argument('--max-par-espece', type=int, default=MAX_PAR_ESPECE)
    ap.add_argument('--taille', type=int, default=TAILLE)
    ap.add_argument('--seuil', type=int, default=SEUIL)
    ap.add_argument('--fils', type=int, default=4,
                    help='téléchargements en parallèle ; le serveur de Pl@ntNet est un '
                         'service public, on reste sobre')
    ap.add_argument('--pause', type=float, default=0.0,
                    help='pause après chaque image, par fil, en secondes')
    ap.add_argument('--pause-api', type=float, default=1.0,
                    help="pause entre requêtes à l'API d'espèces, en secondes")
    ap.add_argument('--forcer', action='store_true')
    args = ap.parse_args()

    sortie = Path(args.sortie).expanduser()
    sortie.mkdir(parents=True, exist_ok=True)
    verrou = sortie / '.passe-en-cours'
    if verrou_vivant(verrou) and not args.forcer:
        raise SystemExit(f'une autre passe écrit déjà dans {sortie}. `tmux ls` pour la retrouver.')
    verrou.touch()

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
                         f'Les empreintes du banc sont une des gardes contre la fuite.')

    from student import lire_banc
    chemins_du_banc = set(lire_banc(banc_csv))
    connues, du_banc = set(), set()
    for m in manifestes:
        with open(m, encoding='utf-8') as f:
            c, b = ids_des_manifestes(f, m.parent, chemins_du_banc)
        connues |= c
        du_banc |= b
    print(f'{len(connues)} images Pl@ntNet déjà dans nos manifestes, '
          f'dont {len(du_banc)} au banc')
    corpus = [Path(c).expanduser() for c in (args.corpus or ['~/plant-data/plantnet-300k'])]
    for c in corpus:
        splits = c / 'splits.csv'
        if splits.exists():
            with open(splits, newline='', encoding='utf-8') as f:
                ids = ids_des_corpus(csv.DictReader(f))
            connues |= ids
            print(f'{len(ids)} images Pl@ntNet dans {c}')
    print('empreintes du banc…', flush=True)
    banc = empreintes_du_banc(banc_csv)
    print(f'{len(banc)} empreintes, seuil {args.seuil} bits\n')

    with open(Path(args.liste).expanduser(), newline='', encoding='utf-8') as f:
        especes = especes_a_collecter(csv.DictReader(f), set(args.verdict) or None)
    catalogue = noms_du_catalogue(Path(args.plants).expanduser())
    faites_f = sortie / 'especes-faites.txt'
    faites = set(faites_f.read_text(encoding='utf-8').splitlines()) if faites_f.exists() else set()
    a_faire = [e for e in especes if e[0] not in faites]
    if args.especes:
        a_faire = a_faire[:args.especes]
    print(f'{len(especes)} espèces, {len(faites)} déjà faites, {len(a_faire)} cette passe\n')

    client = PlantnetClient(pause=args.pause_api)
    bilan_f = sortie / 'bilan.json'
    bilan = json.loads(bilan_f.read_text()) if bilan_f.exists() else {}
    index = sortie / 'index.csv'
    neuf = not index.exists()
    debut = time.perf_counter()
    echecs_de_suite = 0
    with open(index, 'a', newline='', encoding='utf-8') as index_f, \
            ThreadPoolExecutor(max_workers=args.fils) as pool:
        ecrivain = csv.DictWriter(index_f, fieldnames=COLONNES)
        if neuf:
            ecrivain.writeheader()
        for i, (espece, depot) in enumerate(a_faire, 1):
            verrou.touch()
            try:
                trouvee = client.espece(espece)
                images = images_par_organe(client.detail(trouvee)) if trouvee else []
            except Exception as e:
                echecs_de_suite += 1
                print(f'  espèce {i}/{len(a_faire)}  {espece}  ÉCHEC {type(e).__name__}: '
                      f'{str(e)[:120]} — laissée pour la prochaine passe', flush=True)
                if echecs_de_suite >= 5:
                    raise SystemExit('cinq espèces de suite en échec : le problème est le '
                                     'réseau ou l\'API, pas une espèce. Relancer la même '
                                     'commande une fois réglé, elle reprend.')
                continue
            echecs_de_suite = 0
            nom = (trouvee or {}).get('name') or espece
            interne = identite(nom, depot, catalogue)
            interdites = observations_interdites(images, du_banc)
            compte = {m: 0 for m in MOTIFS}
            compte['gardée'] = 0
            retenues = []
            for im in images:
                motif = motif_de_rejet(im, connues, interdites)
                if motif:
                    compte[motif] += 1
                elif len(retenues) < args.max_par_espece:
                    retenues.append(im)
            for motif, ligne in pool.map(
                    lambda im: traiter_image(im, nom, interne, sortie, banc, args.taille,
                                             args.seuil, args.pause), retenues):
                if motif:
                    compte[motif] += 1
                else:
                    compte['gardée'] += 1
                    ecrivain.writerow(ligne)
                verrou.touch()
            index_f.flush()
            compte['images'] = len(images)
            bilan[espece] = compte
            bilan_f.write_text(json.dumps(bilan, ensure_ascii=False, indent=1))
            # Une espèce dont des images ont échoué sur le réseau n'est pas
            # marquée faite : la prochaine passe reprend les manquantes, et
            # saute celles qui sont déjà écrites.
            if not compte['échec réseau']:
                with open(faites_f, 'a', encoding='utf-8') as f:
                    f.write(espece + '\n')
            total = sum(b.get('gardée', 0) for b in bilan.values())
            ecoule = time.perf_counter() - debut
            reste = ecoule / i * (len(a_faire) - i) / 60
            print(f'  espèce {i}/{len(a_faire)}  {nom}  gardées {compte["gardée"]}/{len(images)}'
                  f'  (banc {compte["observation du banc"] + compte["proche du banc"]}, '
                  f'déjà {compte["déjà au corpus"]}, licence {compte["licence"]}, '
                  f'réseau {compte["échec réseau"]})  — cumul {total}  reste {reste:.0f} min',
                  flush=True)

    ecrites = ecrire_splits(index, sortie)
    ecrire_attributions(index, sortie)
    print(f'\n{sortie} — {ecrites} images dans splits.csv, attributions.csv à jour')
    print('relancer la même commande reprend les espèces manquantes ; puis, GPU libre :')
    print(f'  python3 bioclip.py cache --dataset {args.sortie} --cache ~/plant-data/bioclip --batch 64')
    verrou.unlink(missing_ok=True)
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
