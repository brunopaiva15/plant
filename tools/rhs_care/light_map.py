"""Position RHS → LightNeed Auxine.

La RHS cote des positions de jardin (plein soleil, mi-ombre, ombre), parfois
plusieurs. Auxine a six crans, et sépare l'idéal ([light]) du plancher
([lightTolerance]).

Règle, posée par docs/14 et le commit de l'idéal/plancher :

- l'idéal est la lecture de Position, pas de la fiche actuelle ;
- si la valeur actuelle est plus basse, elle devient le plancher ;
- si elle est plus haute, on la baisse : c'est le biais « trop de soleil ».
"""

from __future__ import annotations

LIGHT_ORDER = (
    "shade",
    "lowLight",
    "indirect",
    "brightIndirect",
    "someSun",
    "fullSun",
)

_POS = {
    "full sun": "full_sun",
    "partial shade": "partial",
    "full shade": "shade",
    "partial or full shade": "partial",
    "full or partial shade": "partial",
}


def parse_positions(raw: str) -> frozenset[str]:
    """Extrait l'ensemble {full_sun, partial, shade} d'un libellé RHS."""
    text = raw.lower().replace("–", "-").replace("—", "-")
    found: set[str] = set()
    for needle, token in _POS.items():
        if needle in text:
            found.add(token)
    return frozenset(found)


def ideal_from_positions(positions: frozenset[str]) -> str | None:
    """L'idéal Auxine, ou None si Position est vide ou illisible."""
    if not positions:
        return None
    has_sun = "full_sun" in positions
    has_partial = "partial" in positions
    has_shade = "shade" in positions
    if has_sun and not has_partial and not has_shade:
        return "fullSun"
    if has_sun:
        # Plein soleil et autre chose : elle prend le soleil, pas 6 h obligées.
        return "someSun"
    if has_partial and has_shade:
        return "indirect"
    if has_partial:
        return "brightIndirect"
    return "shade"


def apply_floor(ideal: str, current: str) -> tuple[str, str | None]:
    """(light, lightTolerance). Le plancher n'existe que s'il est plus bas."""
    if LIGHT_ORDER.index(current) < LIGHT_ORDER.index(ideal):
        return ideal, current
    return ideal, None
