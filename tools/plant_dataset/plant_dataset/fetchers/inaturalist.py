"""iNaturalist en direct : les observations « casual » aussi.

GBIF ne reçoit d'iNaturalist que les observations de qualité « research »,
c'est-à-dire des plantes sauvages identifiées par plusieurs personnes. Une
plante d'intérieur en pot est marquée « captive/cultivated », reste
« casual », et n'arrive jamais chez GBIF. Pour l'usage de l'app — des pots
sur un rebord de fenêtre — ce sont pourtant les meilleures photos.

L'API demande un User-Agent, au plus une requête par seconde environ, et
rend la licence de chaque photo. Le filtre `photo_license` côté serveur
puis la licence de chaque photo côté client, comme pour GBIF.
"""
from __future__ import annotations

import re
import time
from dataclasses import dataclass
from typing import Iterator

import requests

from ..licenses import is_allowed, parse_license
from . import ImageCandidate

API = 'https://api.inaturalist.org/v1'
DEFAULT_UA = 'FloraPlantDataset/0.1 (github.com/brunopaiva15/plant; dataset builder)'
PAGE = 200
RETRIES = 6
PHOTO_LICENSES = 'cc0,cc-by'
PHOTO_LICENSES_WITH_SA = 'cc0,cc-by,cc-by-sa'
_PHOTO_ID = re.compile(r'/photos/(\d+)/')


SPECIES_RANKS = {'species', 'subspecies', 'variety', 'form', 'hybrid'}


@dataclass
class InatTaxon:
    id: int
    name: str
    rank: str
    observations: int

    #: Le nom demandé, quand il diffère du nom accepté (synonyme).
    matched_as: str = ''

    @property
    def is_synonym(self) -> bool:
        return bool(self.matched_as) and self.matched_as.lower() != self.name.lower()


def photo_id_of(url: str) -> str | None:
    """L'identifiant iNaturalist d'une photo, depuis n'importe laquelle de ses
    URL (`.../photos/726492519/square.jpg`). Le même pour GBIF, qui relaie
    ces URL telles quelles : c'est la clé de dédoublonnage entre sources."""
    m = _PHOTO_ID.search(url or '')
    return m.group(1) if m else None


class InatClient:
    def __init__(self, session: requests.Session | None = None, user_agent: str = DEFAULT_UA, pause: float = 1.0, timeout: float = 60.0):
        self.session = session or requests.Session()
        self.session.headers['User-Agent'] = user_agent
        self.pause = pause
        self.timeout = timeout

    def _get(self, path: str, **params) -> dict:
        for attempt in range(RETRIES):
            try:
                r = self.session.get(f'{API}{path}', params=params, timeout=self.timeout)
                if r.status_code == 429 or r.status_code >= 500:
                    raise requests.HTTPError(f'{r.status_code}', response=r)
                r.raise_for_status()
                time.sleep(self.pause)
                return r.json()
            except (requests.ConnectionError, requests.Timeout, requests.HTTPError):
                if attempt == RETRIES - 1:
                    raise
                time.sleep(min(3 * 2 ** attempt, 45))
        raise RuntimeError('unreachable')

    def match(self, name: str) -> InatTaxon | None:
        """Le taxon correspondant au nom demandé, au rang de l'espèce ou en dessous.

        Beaucoup de plantes d'intérieur sont vendues sous un nom que la
        taxonomie a depuis abandonné : « Schefflera arboricola » est devenu
        « Heptapleurum arboricola », « Saintpaulia ionantha » est devenu
        « Streptocarpus ionanthus ». iNaturalist connaît ces synonymes et
        répond avec le nom accepté, en indiquant dans `matched_term` le nom
        qui a servi à trouver. Refuser ces réponses reviendrait à se priver
        des espèces les plus courantes du catalogue.

        Un synonyme n'est accepté que si `matched_term` est exactement le nom
        demandé — jamais sur une simple ressemblance — et que le rang est
        celui d'une espèce. « Alocasia amazonica » ramène le *genre* Alocasia :
        ce n'est pas une réponse, c'est un aveu d'ignorance.
        """
        d = self._get('/taxa', q=name, per_page=10)
        wanted = name.strip().lower()
        fallback = None
        for r in d.get('results', []):
            if not r.get('is_active', True) or (r.get('rank') or '') not in SPECIES_RANKS:
                continue
            taxon = InatTaxon(id=r['id'], name=r.get('name', ''), rank=r.get('rank', ''),
                              observations=int(r.get('observations_count') or 0), matched_as=name.strip())
            if taxon.name.lower() == wanted:
                return taxon
            if fallback is None and (r.get('matched_term') or '').strip().lower() == wanted:
                fallback = taxon
        return fallback

    def image_candidates(self, taxon_id: int, max_observations: int = 2000, allow_share_alike: bool = False) -> Iterator[ImageCandidate]:
        licenses = PHOTO_LICENSES_WITH_SA if allow_share_alike else PHOTO_LICENSES
        page = 1
        seen = 0
        while seen < max_observations:
            d = self._get('/observations', taxon_id=taxon_id, photo_license=licenses, quality_grade='any', photos='true',
                          per_page=PAGE, page=page, order_by='id', order='asc')
            results = d.get('results', [])
            if not results:
                break
            for obs in results:
                seen += 1
                yield from candidates_from_observation(obs, allow_share_alike=allow_share_alike)
            if len(results) < PAGE:
                break
            page += 1


def candidates_from_observation(obs: dict, allow_share_alike: bool = False) -> Iterator[ImageCandidate]:
    """Les photos d'une observation, filtrées sur leur licence propre. Une
    photo masquée par la modération est ignorée."""
    key = str(obs.get('id', ''))
    user = obs.get('user') or {}
    author = user.get('name') or user.get('login') or ''
    page = obs.get('uri') or (f'https://www.inaturalist.org/observations/{key}' if key else '')
    for p in obs.get('photos') or []:
        if p.get('hidden'):
            continue
        raw = p.get('license_code') or ''
        if not is_allowed(parse_license(raw), allow_share_alike=allow_share_alike):
            continue
        url = p.get('url') or ''
        if not url.startswith('http'):
            continue
        # `square` est une miniature de 75 px ; `large` fait 1024 px de grand
        # côté, ce que le pipeline garde de toute façon.
        url = url.replace('/square.', '/large.')
        dims = p.get('original_dimensions') or {}
        yield ImageCandidate(
            source='inaturalist',
            source_id=f'{key}#{p.get("id")}',
            observation_id=key,
            original_url=page,
            image_url=url,
            author=author,
            license_raw=raw,
            publisher='iNaturalist',
            dataset_key='',
            extra={'photo_id': str(p.get('id') or photo_id_of(url) or ''), 'quality_grade': obs.get('quality_grade', ''),
                   'captive': bool(obs.get('captive')), 'original_width': dims.get('width'), 'original_height': dims.get('height')},
        )
