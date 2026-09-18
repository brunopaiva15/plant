"""Ancre un profil de famille sur une espèce représentative.

Une famille n'est pas un taxon. On lit la page du représentant (la même
que pour la rusticité et la lumière), on écrit la valeur sur la famille,
jamais comme donnée d'espèce. Les traits trop étroits restent chez
l'espèce : keiki d'un phalaenopsis, floraison d'hiver d'un cactus de
Noël, air saturé d'une forêt sur un substrat cactus, annuelle collée à
une famille rustique.
"""

from __future__ import annotations


def months_set(from_m: int, to_m: int) -> set[int]:
    if from_m <= to_m:
        return set(range(from_m, to_m + 1))
    return set(range(from_m, 13)) | set(range(1, to_m + 1))


def months_overlap(a_from: int, a_to: int, b_from: int, b_to: int) -> bool:
    return bool(months_set(a_from, a_to) & months_set(b_from, b_to))


def filter_family_prop(family: str, methods: list[str] | None) -> list[str] | None:
    """Le keiki d'un phalaenopsis n'est pas la multiplication des Orchidaceae."""
    if not methods:
        return None
    out = [m for m in methods]
    if family == "Orchidaceae":
        out = [m for m in out if m != "offsets"]
    if not out or set(out) <= {"water"}:
        return None
    return out


def filter_family_bloom(current: dict | None, applied: dict | None) -> dict | None:
    """Pas d'invention, et pas une saison opposée à celle déjà écrite."""
    if not current or not applied:
        return None
    if not months_overlap(
        current["from"],
        current["to"],
        applied["from"],
        applied["to"],
    ):
        return None
    return applied


def filter_family_humidity(soil: str | None, classified: str | None) -> str | None:
    """Un cactus de Noël n'humidifie pas toute la famille Cactaceae."""
    if classified is None:
        return None
    if soil == "cactus" and classified == "high":
        return None
    return classified


def filter_family_growth(
    damage_below_c: int | None,
    maturity: str | None,
    applied: dict | None,
) -> dict | None:
    """Un basilic annuel n'efface pas le rempotage d'une Lamiaceae rustique."""
    if not applied:
        return None
    out = dict(applied)
    annual = maturity in {"1 year", "1-2 years"}
    hardy = damage_below_c is not None and damage_below_c < 0
    if annual and hardy and out.get("repotting") and out.get("repotEveryMonths") is None:
        out.pop("repotting", None)
        out.pop("repotEveryMonths", None)
    if not out.get("feeding") and not out.get("repotting"):
        return None
    return out
