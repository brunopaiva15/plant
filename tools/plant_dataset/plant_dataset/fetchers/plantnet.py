"""Pl@ntNet en direct : les plantes en pot que les autres sources n'ont pas.

GBIF et iNaturalist montrent surtout une espèce à l'état sauvage. Pl@ntNet
montre ce que les gens photographient pour savoir ce qu'ils ont acheté : le
*Calathea* 'White Fusion' a 103 photos ici, une seule chez GBIF, iNaturalist
et Commons réunis (§ 15.1 de `docs/09`).

**L'accès est autorisé par écrit par Pl@ntNet** (§ 15.5 et 15.6 de
`docs/09`). Sans cette autorisation, ce connecteur ne devait pas exister :
l'API est celle du site `identify.plantnet.org`, sans clé ni documentation.
Il reste désactivé par défaut (`build_dataset.py --plantnet`).

Trois appels, tous sous le référentiel `k-world-flora` (l'ancien,
`the-plant-list`, ne connaît pas les noms récents) :

- la recherche d'espèce, par préfixe et par synonyme ;
- le détail d'une espèce : **toutes** ses images, rangées par organe, chacune
  avec son auteur, sa licence et son observation ;
- une observation : les votes, pour le filtre facultatif.

**La licence est lue image par image**, par `licenses.py`, comme ailleurs.
99,5 % des images sont en CC BY-SA : sans `--allow-sa`, il ne reste presque
rien, et c'est voulu — la règle du projet ne change pas pour une source.

**La plante entière d'abord** (`habit`), puis les feuilles : c'est ce qui
ressemble à une photo d'utilisateur (§ 12.8 de `docs/09`). Les fleurs, les
fruits et les écorces viennent après.

**Les votes ne rattrapent pas tout** (§ 15.4) : quatre voix concordantes
peuvent confirmer un *Anthurium andraeanum* rangé sous *A. scherzerianum*.
Le filtre écarte les observations à une seule voix non revues ; il ne rend
pas propre une espèce qui ne l'est pas.
"""
from __future__ import annotations

import json
import re
import time
from pathlib import Path
from typing import Iterator
from urllib.parse import quote

import requests

from ..licenses import is_allowed, parse_license
from . import ImageCandidate

API = 'https://api.plantnet.org/v1'
PROJET = 'k-world-flora'
DEFAULT_UA = 'FloraPlantDataset/0.1 (github.com/brunopaiva15/plant; dataset builder)'
RETRIES = 5

#: L'ordre de collecte des organes. Ce qui n'est pas listé passe en dernier.
ORGANES = ('habit', 'leaf', 'flower', 'fruit', 'bark', 'other')

_IMAGE = re.compile(r'bs\.plantnet\.org/image/[a-z]+/([0-9a-f]{16,64})', re.I)


def image_id_of(url: str) -> str | None:
    """L'identifiant d'une image Pl@ntNet dans une URL, ou None.

    GBIF relaie les observations de Pl@ntNet avec leurs URL d'origine : une
    image « gbif » d'un manifeste peut être une image Pl@ntNet, et c'est
    l'URL qui le dit, pas la source.
    """
    m = _IMAGE.search(url or '')
    return m.group(1).lower() if m else None


def nom_complet(espece: dict) -> str:
    """« Goeppertia lietzei (É.Morren) Saka » : la clé du détail d'une espèce."""
    return ' '.join(f"{espece.get('name', '')} {espece.get('author') or ''}".split())


def choisir_espece(resultats: list[dict], nom: str) -> dict | None:
    """La réponse de la recherche qui porte exactement ce nom, sinon la
    première.

    La recherche est un préfixe : « Begonia rex » rend aussi « Begonia
    rex-cultorum ». La première réponse n'est la bonne que si aucune ne porte
    le nom exact — c'est le cas d'un synonyme, que Pl@ntNet résout vers le
    nom accepté (« Calathea lietzei » rend *Goeppertia lietzei*).
    """
    if not resultats:
        return None
    cible = ' '.join(nom.lower().split())
    for r in resultats:
        if ' '.join((r.get('name') or '').lower().split()) == cible:
            return r
    return resultats[0]


def images_par_organe(detail: dict, organes: tuple[str, ...] = ORGANES) -> list[dict]:
    """Les images du détail d'une espèce, à plat, chacune avec son organe,
    dans l'ordre de `organes`."""
    par_organe = detail.get('images') or {}
    if not isinstance(par_organe, dict):
        return []
    rang = {o: i for i, o in enumerate(organes)}
    sortie = []
    for organe in sorted(par_organe, key=lambda o: rang.get(o, len(organes))):
        for im in par_organe.get(organe) or []:
            if im.get('id'):
                sortie.append({**im, 'organ': organe})
    return sortie


def licence_de(image: dict):
    """La licence d'une image : l'URL d'abord, le code (`cc-by-sa`) sinon."""
    return parse_license(image.get('licenseUrl') or image.get('license') or '')


def candidat(image: dict, espece: str, allow_share_alike: bool = False) -> ImageCandidate | None:
    """Une image de l'API en candidat, ou None si sa licence est refusée."""
    brute = image.get('licenseUrl') or image.get('license') or ''
    if not is_allowed(parse_license(brute), allow_share_alike=allow_share_alike):
        return None
    url = image.get('o') or image.get('m')
    if not url:
        return None
    iid = str(image['id']).lower()
    obs = str(image.get('observationId') or iid)
    return ImageCandidate(
        source='plantnet',
        source_id=f'plantnet:{iid}',
        # Deux photos de la même observation restent ensemble à la
        # répartition, comme pour iNaturalist.
        observation_id=f'plantnet:{obs}',
        # L'URL de l'image : la seule adresse publique stable que l'API
        # donne. L'attribution demandée cite l'auteur et Pl@ntNet.
        original_url=image.get('o') or url,
        image_url=url,
        author=' '.join(str(image.get('author') or '').split())[:200],
        license_raw=brute,
        publisher='Pl@ntNet',
        extra={'photo_id': iid, 'organ': image.get('organ', ''),
               'plantnet_species': espece, 'plantnet_observation': obs},
    )


def votes_suffisent(observation: dict, nom: str, voix_min: int = 2,
                    proba_min: float = 0.9) -> bool:
    """L'observation est-elle confirmée sous ce nom ?

    Une observation revue par un curateur (`isRevised`) passe. Sinon il faut
    que la détermination retenue porte ce nom, avec au moins `voix_min` voix
    et une probabilité d'au moins `proba_min`. Mesuré sur *Rhaphidophora
    tetrasperma* (§ 15.4) : ce seuil écarte les erreurs visibles, et quelques
    bonnes photos avec elles.
    """
    if observation.get('isRevised') and observation.get('isValid', True):
        return True
    cible = ' '.join(nom.lower().split())
    for d in (observation.get('votes') or {}).get('determinations') or []:
        espece = ' '.join(((d.get('species') or {}).get('name') or '').lower().split())
        if espece == cible:
            return (int(d.get('count') or 0) >= voix_min
                    and float(d.get('proba') or 0) >= proba_min)
    return False


class PlantnetClient:
    def __init__(self, session: requests.Session | None = None, user_agent: str = DEFAULT_UA,
                 pause: float = 1.0, timeout: float = 120.0, cache: Path | None = None):
        self.session = session or requests.Session()
        self.session.headers['User-Agent'] = user_agent
        self.pause = pause
        self.timeout = timeout
        # Les observations, une requête chacune : gardées sur disque, pour
        # qu'une reprise ne redemande rien.
        self.cache = Path(cache) if cache else None
        self._observations: dict = {}
        if self.cache and self.cache.exists():
            self._observations = json.loads(self.cache.read_text())

    def _get(self, chemin: str, **params) -> object:
        url = f'{API}/projects/{PROJET}/{chemin}'
        for attempt in range(RETRIES):
            try:
                r = self.session.get(url, params=params or None, timeout=self.timeout)
                if r.status_code == 429:
                    time.sleep(float(r.headers.get('Retry-After') or min(15 * (attempt + 1), 60)))
                    raise requests.HTTPError('429', response=r)
                if r.status_code >= 500:
                    raise requests.HTTPError(str(r.status_code), response=r)
                r.raise_for_status()
                data = r.json()
                time.sleep(self.pause)
                return data
            except (requests.ConnectionError, requests.Timeout, requests.HTTPError,
                    requests.exceptions.JSONDecodeError):
                if attempt == RETRIES - 1:
                    raise
                time.sleep(min(2 ** attempt, 30))
        raise RuntimeError('unreachable')

    def espece(self, nom: str) -> dict | None:
        """L'espèce acceptée pour ce nom, ou None si Pl@ntNet ne la connaît pas.

        Les erreurs réseau ne sont pas avalées : une panne rendrait l'espèce
        introuvable, et le journal dirait « 0 image » pour une plante qui en a
        mille. `build_dataset` les écrit `ÉCHEC`, et la reprise rattrape.
        """
        resultats = self._get('species', search=nom)
        return choisir_espece(resultats if isinstance(resultats, list) else [], nom)

    def detail(self, espece: dict) -> dict:
        return self._get(f'species/{quote(nom_complet(espece), safe="")}') or {}

    def observation(self, identifiant: str) -> dict:
        identifiant = str(identifiant)
        if identifiant not in self._observations:
            self._observations[identifiant] = self._get(f'observations/{identifiant}') or {}
            if self.cache:
                self.cache.parent.mkdir(parents=True, exist_ok=True)
                self.cache.write_text(json.dumps(self._observations, ensure_ascii=False))
        return self._observations[identifiant]

    def image_candidates(self, scientific_name: str, max_files: int = 300,
                         allow_share_alike: bool = False, voix_min: int = 0,
                         proba_min: float = 0.9) -> Iterator[ImageCandidate]:
        """Les images d'une espèce, licence acceptable seulement, la plante
        entière d'abord.

        `voix_min` à 0 ne regarde pas les votes. Au-dessus, chaque
        observation est demandée une fois, et celles qui ne confirment pas le
        nom sont écartées avec toutes leurs images.
        """
        espece = self.espece(scientific_name)
        if espece is None:
            return
        nom = espece.get('name') or scientific_name
        rendues = 0
        for image in images_par_organe(self.detail(espece)):
            if rendues >= max_files:
                return
            c = candidat(image, nom, allow_share_alike=allow_share_alike)
            if c is None:
                continue
            if voix_min and not votes_suffisent(
                    self.observation(c.extra['plantnet_observation']), nom, voix_min, proba_min):
                continue
            rendues += 1
            yield c
