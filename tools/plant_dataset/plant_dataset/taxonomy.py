"""Noms scientifiques : normalisation, et la liste des plantes de référence.

Le nom canonique est « Genre épithète », sans auteur ni année, avec le signe
d'hybride conservé (« Citrus × aurantium ») et les rangs infraspécifiques
gardés en abrégé (« Ficus benjamina var. nuda »). C'est la clé qui relie le
catalogue de l'app, les sources d'images et les classes du modèle.
"""
from __future__ import annotations

import csv
import re
import unicodedata
from dataclasses import dataclass, field
from pathlib import Path

_RANKS = {'subsp', 'ssp', 'var', 'f', 'forma', 'cv', 'subvar'}
_HYBRID = '×'


def _fold(s: str) -> str:
    s = unicodedata.normalize('NFKD', s)
    return ''.join(c for c in s if not unicodedata.combining(c))


def normalize_scientific_name(raw: str) -> str:
    """Ramène un nom à sa forme canonique.

    >>> normalize_scientific_name('Monstera deliciosa Liebm.')
    'Monstera deliciosa'
    >>> normalize_scientific_name('citrus x aurantium L.')
    'Citrus × aurantium'
    >>> normalize_scientific_name('Ficus benjamina var. nuda (Miq.) Barrett')
    'Ficus benjamina var. nuda'
    """
    s = _fold(raw or '').replace('_', ' ').strip()
    # Le signe d'hybride est parfois collé à l'épithète (« Citrus ×sinensis »
    # chez GBIF comme dans les flores). Sans ce décollement, le nom donne une
    # classe distincte de « Citrus × sinensis » : la même plante apprise deux
    # fois, sous deux étiquettes.
    s = re.sub(r'×(?=\S)', '× ', s)
    s = re.sub(r'\s+', ' ', s)
    if not s:
        return ''
    words = s.split(' ')
    out: list[str] = []
    expecting_epithet = False
    for i, w in enumerate(words):
        token = w.strip(',;')
        if not token:
            continue
        if i == 0:
            out.append(token[:1].upper() + token[1:].lower())
            expecting_epithet = True
            continue
        low = token.lower().rstrip('.')
        if token in ('x', 'X', _HYBRID) and expecting_epithet:
            out.append(_HYBRID)
            continue
        if low in _RANKS:
            out.append(low + '.')
            expecting_epithet = True
            continue
        if token[0] in ("'", '"', '‘', '“'):
            # Un cultivar garde ses majuscules : Rosa 'Peace'.
            out.append("'" + token.strip('\'"‘’“”') + "'")
            expecting_epithet = False
            continue
        if expecting_epithet:
            # L'épithète est en minuscules ; tout ce qui commence par une
            # majuscule, une parenthèse ou contient un chiffre est un auteur.
            shouting = token.isalpha() and token.isupper() and len(token) >= 3  # « DELICIOSA » : un nom crié, pas un auteur
            if (token[0].isupper() and not shouting) or token[0] == '(' or any(ch.isdigit() for ch in token):
                break
            out.append(low)
            expecting_epithet = False
            continue
        # Après l'épithète : soit un rang (traité plus haut), soit l'auteur.
        break
    # Un hybride sans épithète après le signe n'a pas de sens : on le retire.
    if out and out[-1] == _HYBRID:
        out.pop()
    return ' '.join(out)


def species_slug(canonical: str) -> str:
    """« Monstera deliciosa » → « Monstera_deliciosa », pour un nom de dossier."""
    s = _fold(canonical).replace(_HYBRID, 'x')
    s = re.sub(r'[^A-Za-z0-9]+', '_', s).strip('_')
    return s


def internal_id(name: str) -> str:
    """Identifiant interne stable : le nom canonique en minuscules, tirets.

    Le nom est normalisé d'abord, comme le fait `internalPlantId` côté Dart :
    les deux implémentations doivent rendre la même clé pour la même plante,
    y compris quand on leur donne un nom brut.
    """
    return species_slug(normalize_scientific_name(name)).lower().replace('_', '-')


def genus_of(canonical: str) -> str:
    return canonical.split(' ')[0] if canonical else ''


def epithet_of(canonical: str) -> str:
    parts = canonical.split(' ')
    if len(parts) < 2:
        return ''
    return parts[2] if parts[1] == _HYBRID and len(parts) > 2 else parts[1]


@dataclass
class PlantEntry:
    """Une plante du catalogue de référence."""

    internal_id: str
    scientific_name: str
    genus: str
    epithet: str
    family: str
    common_names: dict[str, str] = field(default_factory=dict)
    synonyms: list[str] = field(default_factory=list)
    gbif_key: int | None = None
    wikidata_id: str | None = None
    plantnet_id: str | None = None
    image: str | None = None

    @classmethod
    def from_name(cls, name: str, family: str = '', **common) -> 'PlantEntry':
        canonical = normalize_scientific_name(name)
        return cls(
            internal_id=internal_id(canonical),
            scientific_name=canonical,
            genus=genus_of(canonical),
            epithet=epithet_of(canonical),
            family=family,
            common_names={k: v for k, v in common.items() if v},
        )


COLUMNS = ['internal_id', 'scientific_name', 'genus', 'epithet', 'family', 'common_fr', 'common_en', 'common_de', 'common_it',
           'synonyms', 'gbif_key', 'wikidata_id', 'plantnet_id', 'image']


def load_plants(path: str | Path) -> list[PlantEntry]:
    """Lit `plants.csv`. Les noms sont renormalisés à la lecture : la liste
    reste correcte même si quelqu'un y colle un nom avec son auteur."""
    entries: list[PlantEntry] = []
    with open(path, newline='', encoding='utf-8') as f:
        for row in csv.DictReader(f):
            canonical = normalize_scientific_name(row['scientific_name'])
            if not canonical:
                continue
            common = {lang: row.get(f'common_{lang}', '') for lang in ('fr', 'en', 'de', 'it')}
            entries.append(PlantEntry(
                internal_id=row.get('internal_id') or internal_id(canonical),
                scientific_name=canonical,
                genus=genus_of(canonical),
                epithet=epithet_of(canonical),
                family=row.get('family', ''),
                common_names={k: v for k, v in common.items() if v},
                synonyms=[s.strip() for s in (row.get('synonyms') or '').split('|') if s.strip()],
                gbif_key=int(row['gbif_key']) if row.get('gbif_key') else None,
                wikidata_id=row.get('wikidata_id') or None,
                plantnet_id=row.get('plantnet_id') or None,
                image=row.get('image') or None,
            ))
    return entries


def save_plants(path: str | Path, entries: list[PlantEntry]) -> None:
    with open(path, 'w', newline='', encoding='utf-8') as f:
        w = csv.DictWriter(f, fieldnames=COLUMNS)
        w.writeheader()
        for e in entries:
            w.writerow({
                'internal_id': e.internal_id,
                'scientific_name': e.scientific_name,
                'genus': e.genus,
                'epithet': e.epithet,
                'family': e.family,
                'common_fr': e.common_names.get('fr', ''),
                'common_en': e.common_names.get('en', ''),
                'common_de': e.common_names.get('de', ''),
                'common_it': e.common_names.get('it', ''),
                'synonyms': '|'.join(e.synonyms),
                'gbif_key': e.gbif_key or '',
                'wikidata_id': e.wikidata_id or '',
                'plantnet_id': e.plantnet_id or '',
                'image': e.image or '',
            })


def match_to_catalog(name: str, entries: list[PlantEntry]) -> PlantEntry | None:
    """Retrouve une plante du catalogue à partir d'un nom venu d'ailleurs
    (Pl@ntNet, GBIF, PlantNet-300K) : nom canonique d'abord, synonymes ensuite."""
    canonical = normalize_scientific_name(name)
    if not canonical:
        return None
    by_name = {e.scientific_name: e for e in entries}
    if canonical in by_name:
        return by_name[canonical]
    for e in entries:
        if canonical in (normalize_scientific_name(s) for s in e.synonyms):
            return e
    return None
