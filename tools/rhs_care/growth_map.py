"""Maturité RHS → fréquences d'engrais et de rempotage.

La RHS cote le temps jusqu'à la taille adulte, pas « tous les 30 jours ».
On en dérive un rythme, puis on applique les verrous du profil : pas
d'engrais (carnivores, lavande, lithops), cactus lent, orchidée diluée,
plante en pot hors gel (maturité de jardin ≠ famine), annuelle sans
rempotage, pot étroit.
"""

from __future__ import annotations

import re

# Temps jusqu'à maturité → (jours d'engrais, mois de rempotage).
PACE = {
    "1 year": (21, 12),
    "1-2 years": (21, 12),
    "2-5 years": (30, 24),
    "5-10 years": (45, 24),
    "10-20 years": (60, 36),
    "20-50 years": (60, 36),
    "more than 50 years": (60, 48),
}

_MATURITY = re.compile(
    r"Time to Maturity\s+"
    r"(1 year|1-2 years|2-5 years|5-10 years|10-20 years|20-50 years|more than 50 years)",
    re.I,
)
_NO_FEED = frozenset({"noFertilizer", "feedsOnInsects"})


def parse_maturity(text: str) -> str | None:
    """Lit « Time to Maturity » sur la page RHS déjà nettoyée."""
    if not text:
        return None
    compact = text.replace("\u2013", "-").replace("\u2014", "-")
    m = _MATURITY.search(compact)
    if not m:
        return None
    return m.group(1).lower()


def apply_growth(
    *,
    soil: str | None,
    pot: str | None,
    tips: list[str] | None,
    issues: list[str] | None,
    fertilizer: str | None,
    repot_months: int | None,
    damage_below_c: int | None,
    maturity: str | None,
) -> dict | None:
    """None = rien à sourcer. Les clés présentes sont celles qu'on a tranchées."""
    tips = tips or []
    issues = issues or []
    out: dict = {}
    pace = PACE.get(maturity) if maturity else None
    no_feed = bool(_NO_FEED & set(tips))
    vegetable = fertilizer == "vegetable" or "blossomEndRot" in issues

    if no_feed:
        out["fertilizingDays"] = None
        out["feeding"] = True
    elif pace:
        feed = pace[0]
        if soil == "cactus":
            feed = max(feed, 60)
        elif soil == "orchid":
            feed = min(max(feed, 14), 30)
        if vegetable:
            feed = min(feed, 14)
        elif soil != "cactus":
            # En pot, hors gel : la maturité de jardin n'est pas une famine.
            pot_grown = repot_months is not None and (damage_below_c is None or damage_below_c > 0)
            if pot_grown:
                feed = min(feed, 30)
        out["fertilizingDays"] = feed
        out["feeding"] = True

    annual = repot_months is None and maturity in {"1 year", "1-2 years"}
    if annual:
        out["repotEveryMonths"] = None
        out["repotting"] = True
    elif pace and repot_months is not None:
        repot = pace[1]
        if soil == "cactus" or pot == "snug":
            repot = max(repot, 24)
            if repot_months > repot:
                repot = repot_months
        out["repotEveryMonths"] = repot
        out["repotting"] = True

    if not out.get("feeding") and not out.get("repotting"):
        return None
    return out
