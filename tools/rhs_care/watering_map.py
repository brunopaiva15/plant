"""Stratégie hydrique → règle de séchage, puis jours d'arrosage.

La RHS ne cote pas « tous les 7 jours ». Le drainage du sol n'est pas
non plus une fréquence : un basilic en terre drainante a soif tous les
deux jours. On lit d'abord le milieu de vie et le substrat — aquatique
reste humide, cactus sèche à fond — puis, à défaut, l'intervalle déjà
écrit. Les jours ressortent de cette règle, en gardant le rapport
saison active / repos.
"""

from __future__ import annotations

DAYS = {
    "alwaysMoist": 2,
    "surfaceDry": 4,
    "topQuarterDry": 7,
    "halfDry": 10,
    "mostlyDry": 18,
    "fullyDry": 30,
}

_REST_CAP = 120


def dry_down_from_days(days: int) -> str:
    if days <= 2:
        return "alwaysMoist"
    if days <= 4:
        return "surfaceDry"
    if days <= 7:
        return "topQuarterDry"
    if days <= 13:
        return "halfDry"
    if days <= 24:
        return "mostlyDry"
    return "fullyDry"


def days_from_dry_down(rule: str) -> int:
    return DAYS[rule]


def infer_dry_down(
    soil: str | None,
    growth: str | None,
    summer: int,
    winter: int,
    explicit: str | None = None,
) -> str | None:
    """Règle de séchage : locks hydriques, sinon la valeur déjà écrite, sinon les jours."""
    if growth in {"aquatic", "semiAquatic"}:
        return "alwaysMoist"
    if soil == "cactus":
        return "fullyDry"
    if soil == "none":
        return None
    if explicit:
        return explicit
    active = summer if summer <= winter else winter
    return dry_down_from_days(active)


def watering_days_for(rule: str, summer: int, winter: int) -> tuple[int, int]:
    """Canonise les jours sur la règle, en conservant le rapport repos / actif."""
    new_active = DAYS[rule]
    if summer <= winter:
        old_active, old_rest = summer, winter
        summer_is_active = True
    else:
        old_active, old_rest = winter, summer
        summer_is_active = False
    factor = (old_rest / old_active) if old_active else 2.0
    new_rest = round(new_active * factor)
    new_rest = max(new_active, min(_REST_CAP, new_rest))
    if summer_is_active:
        return new_active, new_rest
    return new_rest, new_active


def apply_watering(
    soil: str | None,
    growth: str | None,
    summer: int,
    winter: int,
    explicit: str | None = None,
) -> dict | None:
    """None = pas de substrat à faire sécher (tillandsie), donc pas sourcé."""
    rule = infer_dry_down(soil, growth, summer, winter, explicit)
    if rule is None:
        return None
    new_summer, new_winter = watering_days_for(rule, summer, winter)
    return {
        "dryDown": rule,
        "wateringSummerDays": new_summer,
        "wateringWinterDays": new_winter,
    }
