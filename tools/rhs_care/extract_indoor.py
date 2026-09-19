"""Crée les profils espèce des plantes du masque Iris Indoor.

Les autres scripts sourcent des fiches qui existent déjà. Celui-ci en écrit
de nouvelles, pour les espèces qu'Iris Indoor exposera et qui n'ont encore
que le profil de leur genre ou de leur famille.

La méthode ne change pas :

1. la page RHS doit être celle de l'espèce — son propre nom, un de ses
   cultivars ou son synonyme ; jamais celle d'une voisine du genre ;
2. la fiche part de ce que l'espèce hérite aujourd'hui (genre, à défaut
   famille), sans sa provenance : un héritage n'est pas une source ;
3. chaque champ passe par le mapping déjà écrit et testé — rusticité,
   lumière, substrat, ennemis, multiplication, floraison, humidité
   d'habitat, arrosage, engrais et rempotage ;
4. une fiche qui ne dit rien de plus que son genre n'est pas écrite : elle
   n'ajouterait qu'une copie à maintenir.

Usage :
    python extract_indoor.py            # réseau, journal, patch Dart
    python extract_indoor.py --dry-run  # journal seulement
    python extract_indoor.py --apply    # reprend indoor.json
    python extract_indoor.py --limit N  # les N premières, pour essayer
"""

from __future__ import annotations

import argparse
import csv
import json
import re
import sys
from pathlib import Path

from bloom_map import apply_bloom, parse_flower_seasons
from extract_bloom import BLOOM_LIT, dart_bloom, parse_bloom
from extract_growth import _set_int_or_null
from extract_humidity import fetch_habitat
from extract_light import CACHE, PROFILES, SYNONYMS, get, index_sitemaps, load_sitemap_urls
from extract_light import slug as rhs_slug
from extract_prop import PROP_CONSTS, dart_prop, parse_prop
from extract_soil import strip_html
from growth_map import apply_growth, parse_maturity
from hardiness_map import apply_hardiness, parse_hardiness, parse_hardiness_html
from humidity_map import apply_humidity, classify_habitat
from issue_map import apply_issues, parse_pests_diseases
from light_map import apply_floor, ideal_from_positions, parse_positions
from prop_map import apply_prop, parse_propagation
from soil_map import apply_soil, parse_growing
from sourcing import SOURCING_LIT, ensure_constants, fields_of, name_of
from watering_map import apply_watering

ROOT = Path(__file__).resolve().parents[2]
MASK = ROOT / "tools" / "plant_dataset" / "masque_indoor.txt"
PLANTS = ROOT / "tools" / "plant_dataset" / "plants.csv"
MODEL = ROOT / "assets" / "model" / "model.json"
INDEX = ROOT / "assets" / "species" / "catalog.tsv"
OUT = Path(__file__).resolve().parent / "indoor.json"
_NAMED = "|".join(sorted(PROP_CONSTS, key=len, reverse=True))


def _families() -> dict[str, str]:
    """Famille par nom scientifique, d'après le catalogue étendu."""
    out: dict[str, str] = {}
    for line in INDEX.read_text(encoding="utf-8").splitlines():
        cells = line.split("\t")
        if len(cells) >= 2 and cells[0] and cells[1]:
            out[cells[0]] = cells[1]
    return out


def indoor_species() -> list[tuple[str, str]]:
    """(nom scientifique, famille) des espèces d'Iris Indoor.

    Le masque figé (`masque_indoor.txt`) dit ce que la spécialiste doit
    apprendre ; `model.json` dit ce qu'elle expose vraiment. Les deux
    comptent : une classe livrée sans fiche à elle reste une plante qu'on
    identifie sans savoir l'arroser.
    """
    rows: dict[str, dict] = {}
    with PLANTS.open(encoding="utf-8") as handle:
        for row in csv.DictReader(handle):
            rows[row["internal_id"]] = row
    by_name = {row["scientific_name"].strip(): row for row in rows.values()}
    families = _families()

    out: list[tuple[str, str]] = []
    seen: set[str] = set()

    def add(name: str, family: str) -> None:
        name = name.strip()
        if not name or name in seen:
            return
        seen.add(name)
        out.append((name, family.strip()))

    for line in MASK.read_text(encoding="utf-8").splitlines():
        key = line.strip()
        if key in rows:
            add(rows[key]["scientific_name"], rows[key]["family"])

    model = json.loads(MODEL.read_text(encoding="utf-8"))
    for name in (model.get("species") or {}).values():
        row = by_name.get(name.strip())
        add(name, row["family"] if row else families.get(name.strip(), ""))
    return out


def _list_enum(inner: str, field: str, enum: str) -> list[str]:
    m = re.search(rf"{field}: \[([^\]]*)\]", inner)
    if not m:
        return []
    return re.findall(rf"{enum}\.(\w+)", m.group(1))


def parse_map(text: str, map_name: str) -> dict[str, dict]:
    """Les blocs d'un map de care_profiles.dart, champs utiles déjà lus."""
    m = re.search(rf"static const {map_name} = <String, CareProfile>\{{(.*?)\}}\s*;", text, re.S)
    if not m:
        return {}
    out: dict[str, dict] = {}
    for block in re.finditer(r"    '([^']+)': CareProfile\((.*?)    \),", m.group(1), re.S):
        key, inner = block.group(1), block.group(2)
        days = re.search(r"fertilizingDays: (null|\d+)", inner)
        repot = re.search(r"repotEveryMonths: (\d+)", inner)
        summer = re.search(r"wateringSummerDays: (\d+)", inner)
        winter = re.search(r"wateringWinterDays: (\d+)", inner)
        out[key] = {
            "inner": inner,
            "light": (re.search(r"light: LightNeed\.(\w+)", inner) or _N).group(1),
            "soil": (re.search(r"soil: SoilKind\.(\w+)", inner) or _N).group(1),
            "water": (re.search(r"water: WaterTolerance\.(\w+)", inner) or _N).group(1) or "tolerant",
            "growth": (re.search(r"growthMedium: GrowthMedium\.(\w+)", inner) or _N).group(1)
            or "terrestrial",
            "pot": (re.search(r"pot: PotPreference\.(\w+)", inner) or _N).group(1),
            "fertilizer": (re.search(r"fertilizer: FertilizerKind\.(\w+)", inner) or _N).group(1),
            "humidity": (re.search(r"humidity: HumidityNeed\.(\w+)", inner) or _N).group(1),
            "damageBelowC": int(re.search(r"damageBelowC: (-?\d+)", inner).group(1))
            if re.search(r"damageBelowC: (-?\d+)", inner)
            else None,
            "summer": int(summer.group(1)) if summer else None,
            "winter": int(winter.group(1)) if winter else None,
            "dryDown": (re.search(r"dryDown: DryDown\.(\w+)", inner) or _N).group(1),
            "fertilizingDays": None if not days or days.group(1) == "null" else int(days.group(1)),
            "repotEveryMonths": int(repot.group(1)) if repot else None,
            "propagation": parse_prop(inner),
            "bloom": parse_bloom(inner),
            "issues": _list_enum(inner, "issues", "CommonIssue"),
            "tips": re.findall(r"'([^']+)'", (re.search(r"tipKeys: \[([^\]]*)\]", inner) or _E).group(1)),
        }
    return out


class _Empty:
    """Un faux match : `group(1)` vaut None, pour lire un champ absent."""

    @staticmethod
    def group(_: int) -> None:
        return None


class _EmptyList:
    @staticmethod
    def group(_: int) -> str:
        return ""


_N = _Empty()
_E = _EmptyList()


def strict_url(name: str, by_slug: dict[str, list[str]]) -> tuple[str, str] | None:
    """La page de l'espèce : elle-même, un de ses cultivars, ou son synonyme."""
    names = [name]
    if name in SYNONYMS:
        names.append(SYNONYMS[name])
    stripped = re.sub(r"\s+[×x]\s+", " ", name).strip()
    if stripped != name:
        names.append(stripped)
    for candidate in names:
        target = rhs_slug(candidate)
        if not target or "-" not in target:
            continue
        if target in by_slug:
            return by_slug[target][0], target
        cultivars = sorted(
            (k for k in by_slug if k.startswith(target + "-") and "%27" not in k),
            key=len,
        )
        if cultivars:
            return by_slug[cultivars[0]][0], cultivars[0]
    return None


def inherited(name: str, family: str, genera: dict, families: dict) -> tuple[str, dict] | None:
    """Ce que l'espèce reçoit aujourd'hui : son genre, à défaut sa famille."""
    genus = name.split()[0]
    if genus in genera:
        return f"byGenus:{genus}", genera[genus]
    if family in families:
        return f"byFamily:{family}", families[family]
    return None


def compose(name: str, family: str, base: dict, html: bytes) -> dict:
    """Les champs que la page RHS de l'espèce donne, passés par les mappings."""
    text = strip_html(html)
    rec: dict = {}

    rating = parse_hardiness_html(html) or parse_hardiness(text)
    rec["rating"] = rating
    damage = apply_hardiness(base["damageBelowC"], rating)
    if damage is not None:
        rec["damageBelowC"] = damage

    positions = parse_positions(
        (re.search(r"Position\s+(.{0,180}?)\s+(?:Soil Types|Growing Conditions|Aspect|Size)", text, re.I) or _E)
        .group(1)
        or ""
    )
    ideal = ideal_from_positions(frozenset(positions))
    if ideal and base["light"]:
        light, floor = apply_floor(ideal, base["light"])
        rec["light"] = light
        rec["lightTolerance"] = floor

    growing = parse_growing(text)
    soil, water = apply_soil(
        base["soil"] or "standard",
        base["water"] or "tolerant",
        growing["types"],
        growing["moisture"],
        growing["ph"],
    )
    if soil is not None:
        rec["soil"] = soil
    if water is not None:
        rec["water"] = water

    issues = apply_issues(base["issues"], parse_pests_diseases(text))
    if issues is not None:
        rec["issues"] = issues

    # La page de l'espèce ajoute et ordonne ; elle n'efface pas ce que le
    # genre sait. Le bloc Propagation de la RHS est un conseil de jardin, pas
    # un inventaire : il ne nomme pas le keiki du dendrobium. Quand la fiche
    # garde une méthode que la page ne dit pas, la liste n'est plus celle de
    # la RHS — on l'écrit sans la dire sourcée.
    methods = apply_prop(base["propagation"], parse_propagation(text))
    if methods is not None:
        kept = [m for m in base["propagation"] if m not in methods and m != "water"]
        if kept:
            merged = [m for m in methods if m != "water"] + kept
            if "water" in methods:
                merged.append("water")
            rec["propagation"] = merged
            rec["propagation_sourced"] = False
        else:
            rec["propagation"] = methods
            rec["propagation_sourced"] = True

    bloom = apply_bloom(base["bloom"], parse_flower_seasons(html))
    if bloom is not None:
        rec["bloom"] = bloom

    rec["maturity"] = parse_maturity(text)
    return rec


def add_humidity(name: str, base: dict, rec: dict) -> None:
    """L'hygrométrie se déduit de l'habitat : la RHS ne la cote pas."""
    corpus, meta = fetch_habitat(name)
    rec["habitat"] = meta
    humidity = apply_humidity(base["humidity"], classify_habitat(corpus))
    if humidity is not None:
        rec["humidity"] = humidity


def add_derived(base: dict, rec: dict) -> None:
    """Arrosage, engrais, rempotage : des sorties de règle, pas des cotes."""
    soil = rec.get("soil", base["soil"])
    summer, winter = base["summer"], base["winter"]
    if summer is not None and winter is not None:
        watering = apply_watering(soil, base["growth"], summer, winter, base["dryDown"])
        if watering is not None:
            rec.update(watering)

    growth = apply_growth(
        soil=soil,
        pot=base["pot"],
        tips=base["tips"],
        issues=rec.get("issues", base["issues"]),
        fertilizer=base["fertilizer"],
        repot_months=base["repotEveryMonths"],
        damage_below_c=rec.get("damageBelowC", base["damageBelowC"]),
        maturity=rec.get("maturity"),
    )
    if growth:
        rec.update(growth)


def sourced_fields(rec: dict) -> set[str]:
    fields: set[str] = set()
    if rec.get("damageBelowC") is not None:
        fields.add("hardiness")
    if rec.get("light"):
        fields.add("light")
    if rec.get("soil"):
        fields.add("soil")
    if rec.get("water"):
        fields.add("water")
    if rec.get("issues") is not None:
        fields.add("issues")
    if rec.get("propagation") is not None and rec.get("propagation_sourced"):
        fields.add("propagation")
    if rec.get("bloom") is not None:
        fields.add("bloom")
    if rec.get("humidity"):
        fields.add("humidity")
    if rec.get("dryDown"):
        fields.add("watering")
    if rec.get("feeding"):
        fields.add("feeding")
    if rec.get("repotting"):
        fields.add("repotting")
    return fields


def patch_inner(inner: str, rec: dict) -> str:
    """Écrit les champs tranchés dans le bloc hérité."""
    if rec.get("damageBelowC") is not None:
        value = rec["damageBelowC"]
        if re.search(r"damageBelowC: -?\d+", inner):
            inner = re.sub(r"damageBelowC: -?\d+", f"damageBelowC: {value}", inner, count=1)
        else:
            inner = inner.rstrip() + f"\n      damageBelowC: {value},\n"
    if rec.get("light"):
        inner = re.sub(r"light: LightNeed\.\w+", f"light: LightNeed.{rec['light']}", inner, count=1)
        inner = re.sub(r"\n      lightTolerance: LightNeed\.\w+,", "", inner)
        if rec.get("lightTolerance"):
            inner = re.sub(
                rf"(light: LightNeed\.{rec['light']},)",
                rf"\1\n      lightTolerance: LightNeed.{rec['lightTolerance']},",
                inner,
                count=1,
            )
    if rec.get("soil"):
        inner = re.sub(r"soil: SoilKind\.\w+", f"soil: SoilKind.{rec['soil']}", inner, count=1)
    # « tolerant » est la valeur par défaut de la fiche : elle s'écrit en
    # retirant la ligne, comme dans extract_soil.py, pas en la posant.
    if rec.get("water") == "strict":
        if re.search(r"water: WaterTolerance\.\w+", inner):
            inner = re.sub(
                r"water: WaterTolerance\.\w+", "water: WaterTolerance.strict", inner, count=1
            )
        else:
            inner = re.sub(
                r"(soil: SoilKind\.\w+,)",
                r"\1\n      water: WaterTolerance.strict,",
                inner,
                count=1,
            )
    elif rec.get("water") == "tolerant":
        inner = re.sub(r"\n      water: WaterTolerance\.(strict|sensitive),", "", inner)
    if rec.get("issues") is not None:
        rendered = "[" + ", ".join(f"CommonIssue.{i}" for i in rec["issues"]) + "]"
        if re.search(r"issues: \[[^\]]*\],", inner, re.S):
            inner = re.sub(r"issues: \[[^\]]*\],", f"issues: {rendered},", inner, count=1, flags=re.S)
        else:
            inner = inner.rstrip() + f"\n      issues: {rendered},\n"
    if rec.get("propagation") is not None:
        rendered = dart_prop(rec["propagation"])
        if re.search(rf"propagation: ({_NAMED}|\[.*?\]),", inner, re.S):
            inner = re.sub(
                rf"propagation: ({_NAMED}|\[.*?\]),",
                f"propagation: {rendered},",
                inner,
                count=1,
                flags=re.S,
            )
        else:
            inner = inner.rstrip() + f"\n      propagation: {rendered},\n"
    if rec.get("bloom") is not None:
        rendered = dart_bloom(rec["bloom"])
        if BLOOM_LIT.search(inner):
            inner = BLOOM_LIT.sub(f"bloom: {rendered}", inner, count=1)
        elif re.search(r"\n      tipKeys:", inner):
            inner = re.sub(r"\n      tipKeys:", f"\n      bloom: {rendered},\n      tipKeys:", inner, count=1)
        else:
            inner = inner.rstrip() + f"\n      bloom: {rendered},\n"
    else:
        # La floraison héritée vient de la page d'un autre taxon. Sans
        # déclencheur à elle, la fiche n'a rien à en dire : le calendrier du
        # genre n'est pas le sien.
        held = BLOOM_LIT.search(inner)
        if held and "triggers" not in held.group(0):
            inner = inner.replace(f"\n      {held.group(0)},", "")
    if rec.get("humidity"):
        inner = re.sub(
            r"humidity: HumidityNeed\.\w+", f"humidity: HumidityNeed.{rec['humidity']}", inner, count=1
        )
    if rec.get("dryDown"):
        inner = re.sub(
            r"wateringSummerDays: \d+", f"wateringSummerDays: {rec['wateringSummerDays']}", inner, count=1
        )
        inner = re.sub(
            r"wateringWinterDays: \d+", f"wateringWinterDays: {rec['wateringWinterDays']}", inner, count=1
        )
        if re.search(r"dryDown: DryDown\.\w+", inner):
            inner = re.sub(r"dryDown: DryDown\.\w+", f"dryDown: DryDown.{rec['dryDown']}", inner, count=1)
        else:
            inner = re.sub(
                r"(wateringWinterDays: \d+,)",
                rf"\1\n      dryDown: DryDown.{rec['dryDown']},",
                inner,
                count=1,
            )
    if rec.get("feeding"):
        inner = _set_int_or_null(inner, "fertilizingDays", rec.get("fertilizingDays"))
    if rec.get("repotting"):
        inner = _set_int_or_null(inner, "repotEveryMonths", rec.get("repotEveryMonths"))

    name = name_of(sourced_fields(rec))
    inner = SOURCING_LIT.sub("", inner)
    inner = re.sub(r"\n\s*\n", "\n", inner)
    if name:
        inner = inner.rstrip() + f"\n      sourcing: {name},\n"
    return inner


def _fields_only(inner: str) -> str:
    """Le bloc sans sa provenance ni ses blancs : pour comparer deux fiches."""
    cleaned = SOURCING_LIT.sub("", inner)
    return re.sub(r"\s+", " ", cleaned).strip()


def extract(species: list[tuple[str, str]], maps: dict, by_slug: dict, limit: int | None) -> dict:
    out: dict[str, dict] = {}
    todo = [(n, f) for n, f in species if n not in maps["bySpecies"]]
    if limit:
        todo = todo[:limit]
    total = len(todo)
    for i, (name, family) in enumerate(todo, 1):
        rec: dict = {"key": name, "family": family}
        out[name] = rec
        base = inherited(name, family, maps["byGenus"], maps["byFamily"])
        if not base:
            rec["error"] = "no-inherited"
            print(f"[{i}/{total}] {name}: ni genre ni famille au catalogue", flush=True)
            continue
        rec["inherits"] = base[0]
        hit = strict_url(name, by_slug)
        if not hit:
            rec["error"] = "no-url"
            print(f"[{i}/{total}] {name}: pas de page RHS", flush=True)
            continue
        url, page_slug = hit
        rec["url"], rec["slug"] = url, page_slug
        try:
            html = get(url, CACHE / "pages" / f"{page_slug}.html")
        except Exception as e:  # noqa: BLE001 — réseau, la fiche attendra
            rec["error"] = str(e)
            print(f"[{i}/{total}] {name}: echec {e}", flush=True)
            continue
        rec.update(compose(name, family, base[1], html))
        try:
            add_humidity(name, base[1], rec)
        except Exception as e:  # noqa: BLE001
            rec["habitat_error"] = str(e)
        add_derived(base[1], rec)

        fields = sourced_fields(rec)
        if not fields:
            rec["error"] = "rien-a-sourcer"
            print(f"[{i}/{total}] {name}: la page ne donne rien", flush=True)
            continue
        inner = patch_inner(base[1]["inner"], rec)
        if _fields_only(inner) == _fields_only(base[1]["inner"]):
            rec["error"] = "identique-au-genre"
            print(f"[{i}/{total}] {name}: rien de plus que {base[0]}", flush=True)
            continue
        rec["inner"] = inner
        rec["sourcing"] = name_of(fields)
        print(f"[{i}/{total}] {name} <- {page_slug} -> {rec['sourcing']}", flush=True)
    return out


def patch_dart(text: str, extracted: dict) -> str:
    """Ajoute les nouveaux blocs à la fin de `bySpecies`."""
    blocks = [
        f"    '{key}': CareProfile({rec['inner']}    ),"
        for key, rec in extracted.items()
        if rec.get("inner") and f"    '{key}': CareProfile(" not in text
    ]
    if not blocks:
        return text
    text = ensure_constants(text, {rec["sourcing"] for rec in extracted.values() if rec.get("sourcing")})
    m = re.search(r"(static const bySpecies = <String, CareProfile>\{.*?\n)(  \};)", text, re.S)
    if not m:
        raise SystemExit("bySpecies introuvable")
    return text[: m.end(1)] + "\n".join(blocks) + "\n" + text[m.start(2) :]


def main() -> int:
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    except Exception:  # noqa: BLE001 — sortie déjà utf-8
        pass
    parser = argparse.ArgumentParser()
    parser.add_argument("--apply", action="store_true", help="reprend indoor.json")
    parser.add_argument("--dry-run", action="store_true", help="journal seulement")
    parser.add_argument("--limit", type=int, default=None)
    args = parser.parse_args()

    text = PROFILES.read_text(encoding="utf-8")
    maps = {name: parse_map(text, name) for name in ("bySpecies", "byGenus", "byFamily")}

    if args.apply:
        extracted = json.loads(OUT.read_text(encoding="utf-8"))
    else:
        by_slug = index_sitemaps(load_sitemap_urls())
        extracted = extract(indoor_species(), maps, by_slug, args.limit)
        OUT.write_text(json.dumps(extracted, ensure_ascii=False, indent=2), encoding="utf-8")

    written = [k for k, rec in extracted.items() if rec.get("inner")]
    skipped: dict[str, int] = {}
    for rec in extracted.values():
        if rec.get("error"):
            skipped[rec["error"]] = skipped.get(rec["error"], 0) + 1
    print(f"\n{len(written)} profils espèce ; écartés : {skipped}")
    if args.dry_run:
        return 0
    PROFILES.write_text(patch_dart(text, extracted), encoding="utf-8")
    print(f"{PROFILES.relative_to(ROOT)} mis à jour")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
