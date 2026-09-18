"""Noms des constantes `sourcing` dans care_profiles.dart.

Huit champs, des combinaisons : plutôt que les énumérer, on les lit et on
les écrit. Les deux noms historiques avec « And » restent, le reste concatène.
L'humidité n'est pas une cote RHS : elle est déduite de l'habitat.
L'arrosage, l'engrais et le rempotage non plus : ce sont des sorties de règle.
"""

from __future__ import annotations

import re

ORDER = (
    "hardiness",
    "light",
    "soil",
    "water",
    "humidity",
    "watering",
    "feeding",
    "repotting",
    "issues",
    "propagation",
    "bloom",
)
_LABEL = {
    "hardiness": "Hardiness",
    "light": "Light",
    "soil": "Soil",
    "water": "Water",
    "humidity": "Humidity",
    "watering": "Watering",
    "feeding": "Feeding",
    "repotting": "Repotting",
    "issues": "Issues",
    "propagation": "Propagation",
    "bloom": "Bloom",
}
_COMMENT = {
    "hardiness": "rusticité",
    "light": "lumière",
    "soil": "substrat",
    "water": "eau",
    "humidity": "humidité",
    "watering": "arrosage",
    "feeding": "engrais",
    "repotting": "rempotage",
    "issues": "problèmes",
    "propagation": "multiplication",
    "bloom": "floraison",
}
_HABITAT = "_habitatHumidity"
_DERIVED_KEYS = ("watering", "feeding", "repotting")
_SRC = {
    "humidity": "CareSource.habitat",
    "watering": "CareSource.derived",
    "feeding": "CareSource.derived",
    "repotting": "CareSource.derived",
}

# Water est un préfixe de Watering : le jeton doit les distinguer.
SOURCING_TOKEN = r"(_rhs\w+|_habitatHumidity(?:Derived\w+)?|_derived\w+)"
SOURCING_LIT = re.compile(r"sourcing: " + SOURCING_TOKEN + r",")


def _consume_labels(rest: str, keys: tuple[str, ...] | None = None) -> set[str]:
    found: set[str] = set()
    items = _LABEL.items() if keys is None else ((k, _LABEL[k]) for k in keys)
    for key, label in sorted(items, key=lambda kv: -len(kv[1])):
        if label in rest:
            found.add(key)
            rest = rest.replace(label, "", 1)
    return found


def fields_of(name: str | None) -> set[str]:
    if not name:
        return set()
    if name.startswith("_habitatHumidity"):
        found = {"humidity"}
        rest = name[len("_habitatHumidity") :]
        if rest.startswith("Derived"):
            found |= _consume_labels(rest[len("Derived") :], _DERIVED_KEYS)
        return found
    if name.startswith("_derived"):
        return _consume_labels(name[len("_derived") :], _DERIVED_KEYS)
    if not name.startswith("_rhs"):
        return set()
    rest = name[4:].replace("And", "")
    return _consume_labels(rest)


def name_of(fields: set[str]) -> str | None:
    ordered = [_LABEL[k] for k in ORDER if k in fields]
    if not ordered:
        return None
    rhs = [k for k in ORDER if k in fields and k not in _SRC]
    derived = [k for k in _DERIVED_KEYS if k in fields]
    has_h = "humidity" in fields
    if not rhs:
        if has_h and not derived:
            return _HABITAT
        der = "".join(_LABEL[k] for k in derived)
        if has_h:
            return "_habitatHumidityDerived" + der if der else _HABITAT
        if der:
            return "_derived" + der
        return None
    if ordered == ["Hardiness", "Light"]:
        return "_rhsHardinessAndLight"
    if ordered == ["Soil", "Water"]:
        return "_rhsSoilAndWater"
    if len(ordered) == 1:
        return "_rhs" + ordered[0]
    return "_rhs" + "".join(ordered)


def dart_map(fields: set[str]) -> str:
    parts = []
    for k in ORDER:
        if k not in fields:
            continue
        src = _SRC.get(k, "CareSource.rhs")
        parts.append(f"CareField.{k}: {src}")
    return "{" + ", ".join(parts) + "}"


def dart_comment(fields: set[str]) -> str:
    rhs = [_COMMENT[k] for k in ORDER if k in fields and k not in _SRC]
    extras = []
    if "humidity" in fields:
        extras.append("humidité déduite de l'habitat")
    if "watering" in fields:
        extras.append("arrosage dérivé de la règle de séchage")
    feed = "feeding" in fields
    repot = "repotting" in fields
    if feed and repot:
        extras.append("engrais et rempotage dérivés de la maturité RHS")
    elif feed:
        extras.append("engrais dérivé de la maturité RHS")
    elif repot:
        extras.append("rempotage dérivé de la maturité RHS")
    parts: list[str] = []
    if rhs:
        if len(rhs) == 1:
            parts.append(rhs[0].capitalize() + " lu à la RHS")
        else:
            *rest, last = rhs
            head = ", ".join(w.capitalize() if i == 0 else w for i, w in enumerate(rest))
            parts.append(f"{head} et {last} lus à la RHS")
    for extra in extras:
        parts.append(extra.capitalize() if not parts else extra)
    if not parts:
        return ""
    return " ; ".join(parts) + "."


def ensure_constants(text: str, needed: set[str]) -> str:
    """Insère les constantes manquantes après `_rhsLight`."""
    if "static const _rhsLight" not in text:
        return text
    block = []
    for name in sorted(needed, key=lambda n: (len(fields_of(n)), n)):
        if name in {
            "_rhsHardiness",
            "_rhsLight",
            "_rhsHardinessAndLight",
        }:
            continue
        if f"static const {name} =" in text:
            continue
        fields = fields_of(name)
        if not fields:
            continue
        block.append(f"\n\n  /// {dart_comment(fields)}\n  static const {name} = {dart_map(fields)};")
    if not block:
        return text
    return text.replace(
        "  static const _rhsLight = {CareField.light: CareSource.rhs};",
        "  static const _rhsLight = {CareField.light: CareSource.rhs};" + "".join(block),
        1,
    )
