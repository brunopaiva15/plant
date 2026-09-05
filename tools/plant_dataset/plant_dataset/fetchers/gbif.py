"""GBIF : résolution du nom, puis occurrences avec images.

GBIF agrège des observations de nombreux réseaux — iNaturalist en tête —
et expose, pour chaque occurrence, ses médias avec leur propre licence,
leur auteur et leur URL. On demande au serveur de ne renvoyer que les
occurrences sous CC0 ou CC BY (`license=`), puis on revérifie la licence
*de chaque média* côté client : l'occurrence et sa photo peuvent différer.

Le service demande un User-Agent identifiable et une cadence raisonnable.
"""
from __future__ import annotations

import time
from dataclasses import dataclass
from typing import Iterator

import requests

from ..licenses import GBIF_LICENSE_CODES, is_allowed, parse_license
from . import ImageCandidate
from .inaturalist import photo_id_of

API = 'https://api.gbif.org/v1'
DEFAULT_UA = 'FloraPlantDataset/0.1 (github.com/brunopaiva15/plant; dataset builder)'
PAGE = 100
INATURALIST_DATASET = '50c9509d-22c7-4a22-a47d-8c48425ef4a7'


@dataclass
class TaxonMatch:
    key: int
    canonical_name: str
    scientific_name: str
    rank: str
    status: str
    match_type: str
    confidence: int
    family: str
    genus: str
    accepted_key: int | None

    @property
    def usable(self) -> bool:
        """Une correspondance qu'on accepte sans relecture : exacte ou floue
        mais sûre, au rang de l'espèce."""
        if self.rank not in ('SPECIES', 'SUBSPECIES', 'VARIETY', 'FORM'):
            return False
        if self.match_type == 'EXACT':
            return True
        return self.match_type == 'FUZZY' and self.confidence >= 95


class GbifClient:
    def __init__(self, session: requests.Session | None = None, user_agent: str = DEFAULT_UA, pause: float = 0.25, timeout: float = 60.0):
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
                time.sleep(2 ** attempt)
        raise RuntimeError('unreachable')

    def match(self, name: str) -> TaxonMatch | None:
        d = self._get('/species/match', name=name, kingdom='Plantae', strict='false')
        if d.get('matchType') in (None, 'NONE') or 'usageKey' not in d:
            return None
        return TaxonMatch(
            key=d['usageKey'],
            canonical_name=d.get('canonicalName', ''),
            scientific_name=d.get('scientificName', ''),
            rank=d.get('rank', ''),
            status=d.get('status', ''),
            match_type=d.get('matchType', ''),
            confidence=int(d.get('confidence', 0)),
            family=d.get('family', ''),
            genus=d.get('genus', ''),
            accepted_key=d.get('acceptedUsageKey'),
        )

    def image_candidates(self, taxon_key: int, license_codes: list[str] = GBIF_LICENSE_CODES, max_occurrences: int = 2000,
                         allow_share_alike: bool = False) -> Iterator[ImageCandidate]:
        """Toutes les images des occurrences sous licence acceptée, une
        licence à la fois. Ne rend que les médias dont la licence propre
        passe le filtre."""
        for code in license_codes:
            offset = 0
            seen = 0
            while seen < max_occurrences:
                d = self._get('/occurrence/search', taxonKey=taxon_key, mediaType='StillImage', license=code,
                              basisOfRecord='HUMAN_OBSERVATION', limit=PAGE, offset=offset)
                results = d.get('results', [])
                if not results:
                    break
                for occ in results:
                    seen += 1
                    yield from candidates_from_occurrence(occ, allow_share_alike=allow_share_alike)
                if d.get('endOfRecords', True):
                    break
                offset += PAGE


def candidates_from_occurrence(occ: dict, allow_share_alike: bool = False) -> Iterator[ImageCandidate]:
    """Les médias d'une occurrence, filtrés sur leur licence propre.

    Sans licence sur le média, celle de l'occurrence fait foi ; sans licence
    nulle part, rien ne passe.
    """
    key = str(occ.get('key', ''))
    occ_license = occ.get('license') or ''
    author_fallback = occ.get('recordedBy') or occ.get('rightsHolder') or ''
    page = occ.get('references') or (f'https://www.gbif.org/occurrence/{key}' if key else '')
    for i, m in enumerate(occ.get('media') or []):
        if m.get('type') != 'StillImage':
            continue
        url = m.get('identifier') or ''
        if not url.startswith('http'):
            continue
        raw = m.get('license') or occ_license
        if not is_allowed(parse_license(raw), allow_share_alike=allow_share_alike):
            continue
        yield ImageCandidate(
            source='gbif',
            source_id=f'{key}#{i}',
            observation_id=key,
            original_url=page,
            image_url=url,
            author=m.get('creator') or m.get('rightsHolder') or author_fallback,
            license_raw=raw,
            publisher=m.get('publisher') or occ.get('publishingOrgKey', '') or '',
            dataset_key=occ.get('datasetKey', ''),
            extra={'format': m.get('format', ''), 'basisOfRecord': occ.get('basisOfRecord', ''),
                   'inaturalist': occ.get('datasetKey') == INATURALIST_DATASET, 'photo_id': photo_id_of(url) or ''},
        )
