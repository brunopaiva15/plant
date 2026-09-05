"""Licences : ce qu'on accepte, et rien d'autre.

Par défaut, seules les licences qui permettent un usage commercial sans
condition de partage à l'identique entrent dans le jeu : CC0, domaine public,
CC BY (toutes versions). CC BY-SA est refusée pour l'instant — elle est
compatible avec un usage commercial, mais impose des obligations sur les
œuvres dérivées que le projet préfère ne pas porter. Tout le reste est refusé :
NC, ND, licence inconnue, droits réservés.

Une licence qu'on ne sait pas lire est une licence refusée.
"""
from __future__ import annotations

import re
from dataclasses import dataclass

_CC_URL = re.compile(r'creativecommons\.org/(licenses|publicdomain)/([a-z\-]+)/(\d\.\d)', re.I)
_CC_CODE = re.compile(r'^cc[\s_\-]*(0|by(?:[\s_\-]*(?:nc|sa|nd))*)(?:[\s_\-]*(\d)[\s_\.\-]*(\d))?$', re.I)


@dataclass(frozen=True)
class License:
    code: str          # « CC BY 4.0 », « CC0 1.0 », « Public Domain Mark 1.0 »
    url: str
    commercial: bool   # usage commercial permis
    share_alike: bool  # obligation de partage à l'identique
    derivatives: bool  # œuvres dérivées permises


def _build(kind: str, version: str) -> License:
    kind = kind.lower()
    if kind in ('zero', '0'):
        return License(f'CC0 {version}', f'https://creativecommons.org/publicdomain/zero/{version}/', True, False, True)
    if kind == 'mark':
        return License(f'Public Domain Mark {version}', f'https://creativecommons.org/publicdomain/mark/{version}/', True, False, True)
    parts = kind.split('-')
    if parts[0] != 'by':
        raise ValueError(kind)
    flags = set(parts[1:])
    code = 'CC ' + '-'.join(p.upper() for p in parts) + f' {version}'
    return License(code, f'https://creativecommons.org/licenses/{kind}/{version}/', 'nc' not in flags, 'sa' in flags, 'nd' not in flags)


def parse_license(value: str | None) -> License | None:
    """Reconnaît une licence sous ses formes courantes ; `None` si inconnue.

    Formes lues : URL Creative Commons, codes GBIF (`CC_BY_4_0`, `CC0_1_0`),
    libellés (`CC BY 4.0`, `cc-by-sa-4.0`, `CC0`).
    """
    if not value:
        return None
    v = value.strip()
    m = _CC_URL.search(v)
    if m:
        kind, version = m.group(2), m.group(3)
        try:
            return _build(kind, version)
        except ValueError:
            return None
    if re.search(r'creativecommons\.org/publicdomain/zero', v, re.I):
        return _build('zero', '1.0')
    m = _CC_CODE.match(v)
    if m:
        body = m.group(1).lower()
        version = f'{m.group(2)}.{m.group(3)}' if m.group(2) else ('1.0' if body == '0' else '4.0')
        kind = 'zero' if body == '0' else re.sub(r'[\s_]+', '-', body)
        try:
            return _build(kind, version)
        except ValueError:
            return None
    if v.lower() in ('public domain', 'pd', 'publicdomain', 'pdm'):
        return License('Public Domain Mark 1.0', 'https://creativecommons.org/publicdomain/mark/1.0/', True, False, True)
    return None


def is_allowed(lic: License | None, *, allow_share_alike: bool = False) -> bool:
    """La règle du projet : commercial, dérivés permis, pas de SA sauf demande."""
    if lic is None:
        return False
    if not lic.commercial or not lic.derivatives:
        return False
    if lic.share_alike and not allow_share_alike:
        return False
    return True


# Codes du filtre `license=` de l'API d'occurrences GBIF, dans l'ordre où on
# les demande : le domaine public d'abord, l'attribution ensuite.
GBIF_LICENSE_CODES = ['CC0_1_0', 'CC_BY_4_0']
GBIF_LICENSE_CODES_WITH_SA = GBIF_LICENSE_CODES + ['CC_BY_SA_4_0']
