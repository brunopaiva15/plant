"""Habitat (GBIF, littérature) → besoin d'humidité de l'air.

La RHS ne cote pas l'hygrométrie. On lit l'habitat d'origine — forêt
humide, maquis, désert — et on en déduit `low` / `average` / `high`.
Une plage chiffrée déjà écrite sur la fiche n'est pas touchée.
"""

from __future__ import annotations

import re

KEEP_TYPES = {
    "biology_ecology",
    "distribution",
    "ecology",
    "environment",
    "geographic distribution",
    "habitat",
    "occurrence",
}
_INTRODUCED = ("alien", "escaped", "introduced", "invasive", "naturalis", "weed")

# Forêt humide, nuage, marais : l'air y est saturé.
_HIGH = [
    r"rain[\s-]?forests?",
    r"cloud forests?",
    r"moist forests?",
    r"wet forests?",
    r"humid forests?",
    r"tropical moist",
    r"tropical wet",
    r"premontane rain",
    r"atlantic forests?",
    r"mata atl[aâ]ntica",
    r"mangroves?",
    r"peat(?:land| bogs?)",
    r"raised bogs?",
    r"in bogs",
    r"\bswamps?\b",
    r"\bmarsh(?:es)?\b",
    r"moist woodlands?",
    r"wet woodlands?",
    r"damp woodlands?",
    r"gallery forests?",
    r"elfin forests?",
    r"mossy forests?",
    r"fog forests?",
    r"tropical rain",
]

# Désert, maquis, climat méditerranéen : l'air y est sec.
_LOW = [
    r"\bdeserts?\b",
    r"\barid\b",
    r"semi[\s-]?arid",
    r"\bxeric\b",
    r"xerophyt",
    r"succulent karoo",
    r"\bkaroo\b",
    r"\bmaquis\b",
    r"\bgarrigue\b",
    r"\bchaparral\b",
    r"\bmatorral\b",
    r"\bmacchia\b",
    r"mediterranean basin",
    r"mediterranean europe",
    r"native to the mediterranean",
    r"arabian peninsula",
    r"\bsahara\b",
    r"\bsahel\b",
    r"\bnamib\b",
    r"\bkalahari\b",
    r"\bsonoran\b",
    r"\bmojave\b",
    r"\batacama\b",
    r"dry scrub",
    r"thorn scrub",
    r"dry thicket",
    r"spiny forest",
]

# Savane, forêt sèche : ni désert ni sous-bois saturé.
_AVERAGE = [
    r"seasonally dry",
    r"tropical dry",
    r"dry forests?",
    r"dry evergreen",
    r"\bsavannah?s?\b",
    r"\bcerrado\b",
    r"\bmiombo\b",
    r"\bwoodlands?\b",
    r"\bmeadows?\b",
    r"\bgrasslands?\b",
    r"\bprairies?\b",
]


def _compile(patterns: list[str]) -> list[re.Pattern[str]]:
    return [re.compile(p, re.I) for p in patterns]


HIGH_RE = _compile(_HIGH)
LOW_RE = _compile(_LOW)
AVERAGE_RE = _compile(_AVERAGE)


def keep_description(entry: dict) -> bool:
    """Les notices d'introduction, la morphologie et les listes d'aires ne disent pas l'habitat."""
    typ = (entry.get("type") or "").strip().lower()
    lang = (entry.get("language") or "eng").lower()
    if lang not in {"", "en", "en-gb", "en-us", "eng"}:
        return False
    text = (entry.get("description") or "").strip()
    if not text:
        return False
    if typ not in KEEP_TYPES:
        return False
    src = (entry.get("source") or "").lower()
    if any(m in src for m in _INTRODUCED):
        return False
    return True


FOCUS_CAP = 12


def focus_descriptions(descriptions: list[dict], genus: str | None) -> list[dict]:
    """Un article GBIF collé en bloc mélange les taxons : on ne garde que
    les notices qui nomment le genre, dès qu'elles sont trop nombreuses."""
    if not genus or len(descriptions) <= FOCUS_CAP:
        return descriptions
    token = genus.lower()
    return [d for d in descriptions if token in (d.get("description") or "").lower()]


def harvest_corpus(
    descriptions: list[dict],
    wiki_extract: str | None,
    genus: str | None = None,
) -> str:
    parts = []
    for d in focus_descriptions(descriptions, genus):
        if not keep_description(d):
            continue
        text = d["description"].strip()
        if genus and not _same_genus(text, genus):
            continue
        parts.append(text)
    extract = (wiki_extract or "").strip()
    if extract and "may refer to" not in extract.lower():
        parts.append(extract)
    return " ".join(parts)


def _same_genus(text: str, genus: str) -> bool:
    """Une notice GBIF qui nomme un autre binôme ne source pas la fiche.

    Un genre en italique sans épithète (Brachystegia woodland) est de la
    végétation, pas un autre taxon collé.
    """
    want = genus.lower()
    for match in re.finditer(
        r"<(?:em|i)[^>]*>\s*([A-Z][a-z]+)(?:\s+([a-z-]+))?",
        text,
    ):
        other, epithet = match.group(1), match.group(2)
        if epithet and other.lower() != want:
            return False
    return True


def _hits(text: str, patterns: list[re.Pattern[str]]) -> int:
    return sum(1 for p in patterns if p.search(text))


def classify_habitat(text: str | None) -> str | None:
    """`low` / `average` / `high`, ou None si le texte ne tranche pas."""
    if not text or not text.strip():
        return None
    high = _hits(text, HIGH_RE)
    low = _hits(text, LOW_RE)
    average = _hits(text, AVERAGE_RE)
    if high and low:
        return None
    if high:
        return "high"
    if low:
        return "low"
    if average:
        return "average"
    return None


def apply_humidity(current: str | None, classified: str | None) -> str | None:
    """Nouveau besoin, ou None si on n'a rien lu et qu'on ne source pas."""
    if classified is None:
        return None
    return classified
