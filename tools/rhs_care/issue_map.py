"""Pests / Diseases RHS → CommonIssue Auxine.

La RHS nomme les ennemis de jardin. Auxine y mêle des troubles de culture
(trop d'eau, moucherons du terreau) que la fiche RHS ne dit pas. On remplace
les ravageurs et maladies qu'on sait nommer ; on garde les troubles.

« Generally pest-free » est une cote : les pucerons collés à tout le monde
s'en vont.
"""

from __future__ import annotations

import re

# Ordre de CommonIssue dans care_profile.dart.
ISSUE_ORDER = (
    "overwatering",
    "underwatering",
    "rootRot",
    "spiderMites",
    "thrips",
    "mealybugs",
    "scale",
    "aphids",
    "fungusGnats",
    "whitefly",
    "trueBugs",
    "slugs",
    "powderyMildew",
    "greyMould",
    "leafSpot",
    "blight",
    "sunburn",
    "dryTips",
    "leafDrop",
    "etiolation",
    "chlorosis",
    "blossomEndRot",
)

# Troubles de culture : la RHS ne les cote pas, on ne les retire pas.
KEEP = frozenset(
    {
        "overwatering",
        "underwatering",
        "rootRot",
        "fungusGnats",
        "sunburn",
        "dryTips",
        "leafDrop",
        "etiolation",
        "chlorosis",
        "blossomEndRot",
    }
)

# Ravageurs / maladies qu'on sait lire chez la RHS : on les remplace.
REPLACEABLE = frozenset(ISSUE_ORDER) - KEEP

BLOCK_RE = re.compile(
    r"Pests\s+((?:May be susceptible to|Generally pest[- ]free).*?)\s+"
    r"Diseases\s+((?:May be susceptible to|Generally disease[- ]free|high risk).*?)\s+Grow\b",
    re.I,
)

# Plus long d'abord, pour ne pas prendre « scale » dans un mot isolé trop tôt.
_PEST_NEEDLES: tuple[tuple[str, str], ...] = (
    ("glasshouse red spider mite", "spiderMites"),
    ("fruit tree red spider mite", "spiderMites"),
    ("red spider mite", "spiderMites"),
    ("spider mite", "spiderMites"),
    ("glasshouse whitefly", "whitefly"),
    ("whitefly", "whitefly"),
    ("mealy bugs", "mealybugs"),
    ("mealybugs", "mealybugs"),
    ("scale insects", "scale"),
    ("mussel scale", "scale"),
    ("fluted scale", "scale"),
    ("horse chestnut scale", "scale"),
    ("cuckoo spit", "trueBugs"),
    ("froghoppers", "trueBugs"),
    ("capsid", "trueBugs"),
    ("aphids", "aphids"),
    ("adelgids", "aphids"),
    ("thrips", "thrips"),
    ("slugs and snails", "slugs"),
    ("snails", "slugs"),
    ("slugs", "slugs"),
    ("scale", "scale"),
)

_DISEASE_NEEDLES: tuple[tuple[str, str], ...] = (
    ("blossom end rot", "blossomEndRot"),
    ("phytophthora root rot", "rootRot"),
    ("root rot", "rootRot"),
    ("root rots", "rootRot"),
    ("powdery mildews", "powderyMildew"),
    ("powdery mildew", "powderyMildew"),
    ("grey moulds", "greyMould"),
    ("grey mould", "greyMould"),
    ("gray mold", "greyMould"),
    ("botrytis", "greyMould"),
    ("leaf blight", "blight"),
    ("box blight", "blight"),
    ("fireblight", "blight"),
    ("fire blight", "blight"),
    ("leaf spot", "leafSpot"),
    ("blight", "blight"),
    ("magnesium deficiency", "chlorosis"),
)


def parse_pests_diseases(text: str) -> dict | None:
    """None si la page n'a pas de bloc Pests/Diseases lisible."""
    m = BLOCK_RE.search(text)
    if not m:
        return None
    pests_raw = re.sub(r"\s+", " ", m.group(1)).strip()
    diseases_raw = re.sub(r"\s+", " ", m.group(2)).strip()
    return {
        "pests_raw": pests_raw,
        "diseases_raw": diseases_raw,
        "pest_free": bool(re.search(r"generally pest[- ]free", pests_raw, re.I)),
        "disease_free": bool(re.search(r"generally disease[- ]free", diseases_raw, re.I))
        and not re.search(r"may be susceptible", diseases_raw, re.I),
    }


def _map_needles(raw: str, needles: tuple[tuple[str, str], ...]) -> list[str]:
    text = raw.lower()
    found: list[str] = []
    seen: set[str] = set()
    for needle, issue in needles:
        if needle in text and issue not in seen:
            seen.add(issue)
            found.append(issue)
    return found


def issues_from_rhs(pests_raw: str, diseases_raw: str) -> list[str]:
    return _map_needles(pests_raw, _PEST_NEEDLES) + _map_needles(diseases_raw, _DISEASE_NEEDLES)


def apply_issues(current: list[str], parsed: dict | None) -> list[str] | None:
    """Nouvelle liste, ou None si on n'a rien lu et qu'on ne source pas."""
    if parsed is None:
        return None
    kept = [i for i in current if i in KEEP]
    mapped = issues_from_rhs(parsed["pests_raw"], parsed["diseases_raw"])
    merged = []
    seen: set[str] = set()
    for issue in ISSUE_ORDER:
        if issue in kept or issue in mapped:
            if issue not in seen:
                seen.add(issue)
                merged.append(issue)
    return merged
