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
PHOTO_LICENSES = 'cc0,cc-by'
PHOTO_LICENSES_WITH_SA = 'cc0,cc-by,cc-by-sa'
_PHOTO_ID = re.compile(r'/photos/(\d+)/')


@dataclass
class InatTaxon:
    id: int
    name: str
    rank: str
    observations: int


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
        for attempt in range(4):
            try:
                r = self.session.get(f'{API}{path}', params=params, timeout=self.timeout)
                if r.status_code == 429 or r.status_code >= 500:
                    raise requests.HTTPError(f'{r.status_code}', response=r)
                r.raise_for_status()
                time.sleep(self.pause)
                return r.json()
            except (requests.ConnectionError, requests.Timeout, requests.HTTPError):
                if attempt == 3:
                    raise
                time.sleep(3 * 2 ** attempt)
        raise RuntimeError('unreachable')

    def match(self, name: str) -> InatTaxon | None:
        """Le taxon dont le nom est exactement celui demandé, au rang espèce."""
        d = self._get('/taxa', q=name, rank='species', per_page=10)
        wanted = name.strip().lower()
        for r in d.get('results', []):
            if (r.get('name') or '').lower() == wanted and r.get('is_active', True):
                return InatTaxon(id=r['id'], name=r['name'], rank=r.get('rank', ''), observations=int(r.get('observations_count') or 0))
        return None

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
