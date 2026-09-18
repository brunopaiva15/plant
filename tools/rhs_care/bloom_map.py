"""Colour & Scent RHS → fenêtre de floraison Auxine.

Le tableau saisonnier dit si la plante a des fleurs au printemps, en été,
en automne ou en hiver. Auxine n'a qu'une plage de mois : on la pose quand
les saisons forment un arc continu. Les déclencheurs (nuits fraîches, jours
courts) restent ceux de la fiche : le jardin RHS ne les dit pas.
"""

from __future__ import annotations

import re
from html import unescape

SEASON_ORDER = ("Spring", "Summer", "Autumn", "Winter")
SEASON_MONTHS = {
    "Spring": (3, 5),
    "Summer": (6, 8),
    "Autumn": (9, 11),
    "Winter": (12, 2),
}

ROW_RE = re.compile(
    r'<th scope="row"[^>]*>(Spring|Summer|Autumn|Winter)</th>\s*'
    r"<td[^>]*data-label=\"Stem\"[^>]*>.*?</td>\s*"
    r"<td[^>]*data-label=\"Flower\"[^>]*>(.*?)</td>",
    re.S | re.I,
)


def parse_flower_seasons(html: str | bytes) -> list[str] | None:
    """Saisons où la colonne Flower n'est pas vide, ou None sans tableau."""
    raw = html.decode("utf-8", "replace") if isinstance(html, bytes) else html
    if not ROW_RE.search(raw):
        return None
    found: list[str] = []
    for match in ROW_RE.finditer(raw):
        season, cell = match.group(1), match.group(2)
        text = unescape(re.sub(r"<[^>]+>", " ", cell))
        has_mark = "<svg" in cell.lower() or bool(re.sub(r"\s+", "", text))
        if has_mark:
            name = season[:1].upper() + season[1:].lower()
            if name in SEASON_MONTHS and name not in found:
                found.append(name)
    return found


def window_from_seasons(seasons: list[str]) -> tuple[int, int] | None:
    """Plage de mois, ou None si les saisons ne tiennent pas en un arc."""
    bits = [False] * 4
    for season in seasons:
        if season in SEASON_ORDER:
            bits[SEASON_ORDER.index(season)] = True
    if not any(bits):
        return None
    if all(bits):
        return (1, 12)
    start = None
    for i in range(4):
        if bits[i] and not bits[(i - 1) % 4]:
            start = i
            break
    if start is None:
        return None
    length = 0
    i = start
    while bits[i]:
        length += 1
        i = (i + 1) % 4
        if length > 4:
            break
    if length != sum(bits):
        return None
    from_m = SEASON_MONTHS[SEASON_ORDER[start]][0]
    to_m = SEASON_MONTHS[SEASON_ORDER[(start + length - 1) % 4]][1]
    return (from_m, to_m)


def apply_bloom(current: dict | None, seasons: list[str] | None) -> dict | None:
    """Nouvelle fenêtre, ou None si on n'a rien lu et qu'on ne source pas."""
    if seasons is None:
        return None
    window = window_from_seasons(seasons)
    if window is None:
        return None
    from_m, to_m = window
    if current:
        return {
            "from": from_m,
            "to": to_m,
            "triggers": list(current.get("triggers") or []),
            "indoors": current.get("indoors", True),
        }
    return {"from": from_m, "to": to_m, "triggers": [], "indoors": True}
