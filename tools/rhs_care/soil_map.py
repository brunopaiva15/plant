"""Soil Types / Moisture / pH RHS → soil et water Auxine.

La RHS cote un sol de jardin (texture, drainage, pH). Auxine cote un mélange
de pot et l'eau d'arrosage. Ce n'est pas la même chose : un phalaenopsis en
écorce, une tillandsie sans substrat, un nymphéa dans l'eau ne se lisent pas
sur « Loam, Well-drained, Neutral ».

« Acid or Neutral » n'est pas une terre de bruyère : la tomate, l'hibiscus,
le philodendron y poussent. La terre de bruyère (`acidic`) et l'eau stricte
ne se posent que si la RHS refuse tout sauf l'acide — ou pour confirmer une
fiche déjà calcifuge.

Règle, posée par docs/14 :

- acide seul → `acidic` + `strict` ;
- acide sans alcalin, déjà `acidic` / `strict` → on confirme ;
- bien drainé seul → `draining`, ou `cactus` si l'espèce l'est déjà ;
- orchid / none : le jardin RHS ne dit pas le mélange, on n'y touche pas ;
- on ne relâche pas une eau déjà sensible ou stricte : le pH de jardin est
  plus grossier que le calcaire du robinet.
"""

from __future__ import annotations

import re

SOIL_TOKENS = ("chalk", "clay", "loam", "sand")
PH_TOKENS = ("acid", "alkaline", "neutral")

GROWING_RE = re.compile(
    r"Growing Conditions\s+((?:Chalk|Clay|Loam|Sand)(?:\s+(?:Chalk|Clay|Loam|Sand))*)"
    r"\s+Moisture\s+(.+?)\s+pH\s+(.+?)\s+Position\b",
    re.I,
)

SPECIAL_SOIL = frozenset({"orchid", "none"})


def parse_growing(text: str) -> dict:
    """Extrait types, moisture, pH d'une page RHS déjà dépouillée de ses balises."""
    m = GROWING_RE.search(text)
    if not m:
        return {"types": frozenset(), "moisture": frozenset(), "ph": frozenset(), "raw": None}
    raw_types, raw_moist, raw_ph = m.group(1), m.group(2), m.group(3)
    types = frozenset(tok for tok in SOIL_TOKENS if re.search(rf"\b{tok}\b", raw_types, re.I))
    moist_l = raw_moist.lower()
    moisture: set[str] = set()
    if "moist but well-drained" in moist_l or "moist but well drained" in moist_l:
        moisture.add("moist_well")
    if "poorly-drained" in moist_l or "poorly drained" in moist_l:
        moisture.add("poorly")
    rest = moist_l.replace("moist but well-drained", " ").replace("moist but well drained", " ")
    if re.search(r"\bwell-drained\b|\bwell drained\b", rest):
        moisture.add("well_drained")
    ph = frozenset(tok for tok in PH_TOKENS if re.search(rf"\b{tok}\b", raw_ph, re.I))
    return {
        "types": types,
        "moisture": frozenset(moisture),
        "ph": ph,
        "raw": {"types": raw_types.strip(), "moisture": raw_moist.strip(), "ph": raw_ph.strip()},
    }


def is_ericaceous(ph: frozenset[str]) -> bool:
    """La RHS ne cote que l'acide : Neutral et Alkaline sont exclus."""
    return ph == frozenset({"acid"})


def is_acid_leaning(ph: frozenset[str]) -> bool:
    """Acide, et pas de craie — camélia, gardenia, et aussi la tomate."""
    return bool(ph) and "acid" in ph and "alkaline" not in ph


def drainage_from_moisture(moisture: frozenset[str]) -> str | None:
    """dry / mesic / wet, ou None si Moisture est vide."""
    if not moisture:
        return None
    if moisture == frozenset({"well_drained"}):
        return "dry"
    if moisture == frozenset({"poorly"}):
        return "wet"
    return "mesic"


def apply_soil(
    current_soil: str,
    current_water: str,
    types: frozenset[str],
    moisture: frozenset[str],
    ph: frozenset[str],
) -> tuple[str | None, str | None]:
    """(soil, water) à écrire, ou None pour ne pas sourcer ce champ.

    None veut dire : on garde la valeur actuelle, et on ne la marque pas RHS.
    """
    if not types and not moisture and not ph:
        return None, None

    if current_soil in SPECIAL_SOIL:
        return None, None

    water: str | None = None
    if is_ericaceous(ph):
        water = "strict"
    elif is_acid_leaning(ph) and current_water == "strict":
        water = "strict"
    elif ph and current_water == "tolerant":
        water = "tolerant"

    drainage = drainage_from_moisture(moisture)

    if current_soil == "cactus":
        if "well_drained" in moisture or drainage == "dry":
            return "cactus", water
        return None, water

    if is_ericaceous(ph):
        return "acidic", water
    if current_soil == "acidic" and is_acid_leaning(ph):
        return "acidic", water

    if drainage == "dry":
        return "draining", water
    if drainage == "wet":
        return "rich", water

    if current_soil in {"draining", "cactus", "acidic", "rich"}:
        return None, water
    if drainage == "mesic" or types:
        return "standard", water
    return None, water
