"""Propagation RHS → méthodes Auxine.

`water` n'est pas une méthode : c'est le milieu d'enracinement déjà écrit
dans certaines fiches. On le garde s'il y est ; on n'en invente pas. Le
greffage n'a pas d'entrée Auxine : une page qui ne dit que ça n'est pas
sourcée.
"""

from __future__ import annotations

import re

# Ordre de Propagation dans care_profile.dart.
PROP_ORDER = (
    "stemCutting",
    "leafCutting",
    "division",
    "offsets",
    "layering",
    "seed",
    "water",
    "tuber",
)

BLOCK_RE = re.compile(
    r"\bPropagation\s+(.+?)(?:\s+Suggested planting|\s+Pruning\s|\s+Pests\s|\s+Diseases\s)",
    re.I,
)

_NEEDLES: tuple[tuple[re.Pattern[str], str], ...] = (
    (re.compile(r"leaf[- ]bud"), "stemCutting"),
    (re.compile(r"leaf bud"), "stemCutting"),
    (re.compile(r"bud cuttings?"), "stemCutting"),
    (re.compile(r"stem[- ]tip"), "stemCutting"),
    (re.compile(r"stem tip"), "stemCutting"),
    # « take tip or leaf cuttings » : une bouture de tête est une bouture
    # de tige, et la feuille seule à côté ne la remplace pas.
    (re.compile(r"tip cuttings?"), "stemCutting"),
    (re.compile(r"tip or leaf cuttings?"), "stemCutting"),
    (re.compile(r"stem[- ]cuttings?"), "stemCutting"),
    (re.compile(r"basal stem"), "stemCutting"),
    (re.compile(r"semi[- ]hardwood"), "stemCutting"),
    (re.compile(r"semi[- ]ripe"), "stemCutting"),
    (re.compile(r"\bhardwood\b"), "stemCutting"),
    (re.compile(r"\bsoftwood\b"), "stemCutting"),
    (re.compile(r"\bgreenwood\b"), "stemCutting"),
    (re.compile(r"basal cuttings?"), "stemCutting"),
    (re.compile(r"internodal"), "stemCutting"),
    (re.compile(r"root cuttings?"), "stemCutting"),
    (re.compile(r"root tip"), "stemCutting"),
    (re.compile(r"\bnodal\b"), "stemCutting"),
    (re.compile(r"stem sections"), "stemCutting"),
    (re.compile(r"shoot tips"), "stemCutting"),
    (re.compile(r"rhizome cuttings?"), "stemCutting"),
    (re.compile(r"root, stem or leaf cuttings"), "stemCutting"),
    (re.compile(r"stem or leaf cuttings"), "stemCutting"),
    (re.compile(r"leaf[- ]cuttings?"), "leafCutting"),
    (re.compile(r"leaflets?"), "leafCutting"),
    (re.compile(r"\bleaf or\b"), "leafCutting"),
    (re.compile(r"root, stem or leaf cuttings"), "leafCutting"),
    (re.compile(r"stem or leaf cuttings"), "leafCutting"),
    (re.compile(r"\bdivision\b"), "division"),
    (re.compile(r"\bdivide\b"), "division"),
    (re.compile(r"\bdividing\b"), "division"),
    (re.compile(r"\bcrowns?\b"), "division"),
    (re.compile(r"\boffsets?\b"), "offsets"),
    (re.compile(r"\boffshoots?\b"), "offsets"),
    (re.compile(r"\bkeikis?\b"), "offsets"),
    (re.compile(r"\bsuckers?\b"), "offsets"),
    (re.compile(r"\bpups\b"), "offsets"),
    (re.compile(r"\bplantlets?\b"), "offsets"),
    (re.compile(r"\brunners?\b"), "offsets"),
    (re.compile(r"\brosettes?\b"), "offsets"),
    (re.compile(r"\bbulbils?\b"), "offsets"),
    (re.compile(r"\bcormlets?\b"), "offsets"),
    (re.compile(r"basal shoots"), "offsets"),
    (re.compile(r"air[- ]layering"), "layering"),
    (re.compile(r"\blayering\b"), "layering"),
    (re.compile(r"\bstooling\b"), "layering"),
    (re.compile(r"\bseeds?\b"), "seed"),
    (re.compile(r"\bsown\b"), "seed"),
    (re.compile(r"\bsowing\b"), "seed"),
    (re.compile(r"\bsow\b"), "seed"),
    (re.compile(r"\bspores?\b"), "seed"),
    (re.compile(r"\btubers?\b"), "tuber"),
    (re.compile(r"\bcorms?\b"), "tuber"),
    (re.compile(r"\bbulbs\b"), "tuber"),
)

_GENERIC_CUTTINGS = re.compile(r"\bcutt+ings?\b")
_GENERIC_SKIP = re.compile(
    r"cutt+\w*\s+or\s+(?:offshoots?|keikis?|offsets?|suckers)|"
    r"cutt+\w*\s+of\s+rosettes|"
    r"rooting as cuttings",
    re.I,
)


def parse_propagation(text: str) -> dict | None:
    """None si la page n'a pas de bloc Propagation lisible."""
    m = BLOCK_RE.search(text)
    if not m:
        return None
    raw = re.sub(r"\s+", " ", m.group(1)).strip()
    if re.fullmatch(r"see cultivation notes\.?", raw, re.I):
        return None
    return {"raw": raw}


def methods_from_rhs(raw: str) -> list[str]:
    text = raw.lower()
    found: list[str] = []
    seen: set[str] = set()
    for needle, method in _NEEDLES:
        if needle.search(text) and method not in seen:
            seen.add(method)
            found.append(method)
    if (
        _GENERIC_CUTTINGS.search(text)
        and "stemCutting" not in seen
        and "leafCutting" not in seen
        and not _GENERIC_SKIP.search(text)
    ):
        seen.add("stemCutting")
        found.append("stemCutting")
    return [m for m in PROP_ORDER if m in seen and m != "water"]


def apply_prop(current: list[str], parsed: dict | None) -> list[str] | None:
    """Nouvelle liste, ou None si on n'a rien lu et qu'on ne source pas."""
    if parsed is None:
        return None
    mapped = methods_from_rhs(parsed["raw"])
    if not mapped:
        return None
    keep_water = "water" in current
    result: list[str] = []
    seen: set[str] = set()
    for method in current:
        if method == "water":
            continue
        if method in mapped and method not in seen:
            seen.add(method)
            result.append(method)
    for method in PROP_ORDER:
        if method in mapped and method not in seen:
            seen.add(method)
            result.append(method)
    if keep_water:
        result.append("water")
    return result
