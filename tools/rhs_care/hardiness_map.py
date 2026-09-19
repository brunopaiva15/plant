"""Cote de rusticité RHS → seuil de dégâts Auxine.

La RHS ne donne pas une température : elle range la plante dans une plage
(H1A à H7). Auxine écrit un seuil unique, `damageBelowC`. La règle suit
celle des campagnes de rusticité déjà faites à la main :

- la valeur déjà écrite tombe dans la plage → on la confirme telle quelle,
  c'est elle qui devient sourcée ;
- elle en sort → on prend le milieu de la plage, arrondi du côté chaud,
  celui qui protège la fiche ;
- H1A (« sous verre toute l'année, plus de 15 °C ») et H7 (« moins de
  -20 °C ») sont ouvertes : 15 et -25.

La cote est lue sur la page de l'espèce elle-même. Une famille n'est pas un
taxon, un genre n'hérite pas de la page d'un autre.
"""

from __future__ import annotations

import math
import re

# Cote → (minimum de la plage, maximum), en degrés Celsius. `None` = plage
# ouverte : au-dessus de 15 pour H1A, en dessous de -20 pour H7.
BANDS: dict[str, tuple[int | None, int | None]] = {
    "H1A": (15, None),
    "H1B": (10, 15),
    "H1C": (5, 10),
    "H2": (1, 5),
    "H3": (-5, 1),
    "H4": (-10, -5),
    "H5": (-15, -10),
    "H6": (-20, -15),
    "H7": (None, -20),
}

_RATINGS = "|".join(BANDS)

# La légende du modal se termine par H7 ; la cote de la plante la suit.
_AFTER_LEGEND = re.compile(rf"\(<\s*-20\s*C?\)\s*({_RATINGS})\b", re.I)
_DD = re.compile(rf"<dd[^>]*>\s*({_RATINGS})\s*</dd>", re.I)
_PLAIN = re.compile(rf"Hardiness\s+({_RATINGS})\b", re.I)


def parse_hardiness(text: str) -> str | None:
    """Cote de la plante sur une page RHS dépouillée de ses balises."""
    if not text:
        return None
    compact = re.sub(r"\s+", " ", text.replace("–", "-").replace("—", "-"))
    m = _AFTER_LEGEND.search(compact) or _PLAIN.search(compact)
    return m.group(1).upper() if m else None


def parse_hardiness_html(raw: str | bytes) -> str | None:
    """Cote lue sur le HTML brut : la définition, jamais la légende."""
    html = raw.decode("utf-8", "replace") if isinstance(raw, bytes) else raw
    m = _DD.search(html)
    return m.group(1).upper() if m else None


def band_holds(current: int | None, rating: str) -> bool:
    """La valeur écrite tient-elle dans la plage de la cote ?"""
    if current is None or rating not in BANDS:
        return False
    low, high = BANDS[rating]
    if low is not None and current < low:
        return False
    if high is not None and current > high:
        return False
    return True


def temperature_for(rating: str) -> int | None:
    """Le milieu de la plage, arrondi du côté chaud."""
    if rating not in BANDS:
        return None
    low, high = BANDS[rating]
    if low is None:
        return high - 5 if high is not None else None
    if high is None:
        return low
    return math.ceil((low + high) / 2)


def apply_hardiness(current: int | None, rating: str | None) -> int | None:
    """Seuil à écrire, ou None si on n'a rien lu et qu'on ne source pas."""
    if not rating or rating not in BANDS:
        return None
    if band_holds(current, rating):
        return current
    return temperature_for(rating)
