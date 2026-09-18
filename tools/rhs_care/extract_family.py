"""Ancre les profils de famille sur l'espèce représentative de light.json.

Usage :
    python extract_family.py           # cache, puis le réseau s'il manque
    python extract_family.py --apply   # reprend family.json
    python extract_family.py --dry-run # mapping, sans écrire le Dart
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

from bloom_map import apply_bloom, parse_flower_seasons
from extract_bloom import BLOOM_LIT, dart_bloom, parse_bloom
from extract_growth import _set_int_or_null
from extract_humidity import fetch_habitat
from extract_light import CACHE, PROFILES, index_sitemaps, load_sitemap_urls
from extract_prop import PROP_CONSTS, dart_prop, parse_prop
from extract_soil import html_for, load_light_index, strip_html
from family_map import (
    filter_family_bloom,
    filter_family_growth,
    filter_family_humidity,
    filter_family_prop,
)
from growth_map import apply_growth, parse_maturity
from humidity_map import classify_habitat
from prop_map import apply_prop, parse_propagation
from sourcing import SOURCING_LIT, ensure_constants, fields_of, name_of
from watering_map import apply_watering

OUT = Path(__file__).resolve().parent / "family.json"
HUMIDITY = Path(__file__).resolve().parent / "humidity.json"
_NAMED = "|".join(sorted(PROP_CONSTS, key=len, reverse=True))


def _list_enum(inner: str, field: str, enum: str) -> list[str]:
    m = re.search(rf"{field}: \[([^\]]*)\]", inner)
    if not m:
        return []
    return re.findall(rf"{enum}\.(\w+)", m.group(1))


def parse_families(text: str) -> dict[str, dict]:
    m = re.search(r"static const byFamily = <String, CareProfile>\{(.*?)\}\s*;", text, re.S)
    if not m:
        return {}
    out: dict[str, dict] = {}
    for block in re.finditer(r"    '([^']+)': CareProfile\((.*?)    \),", m.group(1), re.S):
        key, inner = block.group(1), block.group(2)
        days = re.search(r"fertilizingDays: (null|\d+)", inner)
        repot = re.search(r"repotEveryMonths: (\d+)", inner)
        summer = re.search(r"wateringSummerDays: (\d+)", inner)
        winter = re.search(r"wateringWinterDays: (\d+)", inner)
        dry = re.search(r"dryDown: DryDown\.(\w+)", inner)
        soil = re.search(r"soil: SoilKind\.(\w+)", inner)
        pot = re.search(r"pot: PotPreference\.(\w+)", inner)
        growth = re.search(r"growthMedium: GrowthMedium\.(\w+)", inner)
        damage = re.search(r"damageBelowC: (-?\d+)", inner)
        fert = re.search(r"fertilizer: FertilizerKind\.(\w+)", inner)
        humidity = re.search(r"humidity: HumidityNeed\.(\w+)", inner)
        tips = re.search(r"tipKeys: \[([^\]]*)\]", inner)
        sourcing = SOURCING_LIT.search(inner)
        out[key] = {
            "propagation": parse_prop(inner),
            "bloom": parse_bloom(inner),
            "humidity": humidity.group(1) if humidity else None,
            "summer": int(summer.group(1)) if summer else None,
            "winter": int(winter.group(1)) if winter else None,
            "dryDown": dry.group(1) if dry else None,
            "soil": soil.group(1) if soil else None,
            "pot": pot.group(1) if pot else None,
            "growth": growth.group(1) if growth else "terrestrial",
            "fertilizingDays": None
            if not days or days.group(1) == "null"
            else int(days.group(1)),
            "has_fertilizing": bool(days),
            "repotEveryMonths": int(repot.group(1)) if repot else None,
            "damageBelowC": int(damage.group(1)) if damage else None,
            "fertilizer": fert.group(1) if fert else None,
            "tips": re.findall(r"'([^']+)'", tips.group(1)) if tips else [],
            "issues": _list_enum(inner, "issues", "CommonIssue"),
            "sourcing": sourcing.group(1) if sourcing else None,
        }
    return out


def load_humidity_index() -> dict:
    if not HUMIDITY.exists():
        return {}
    return json.loads(HUMIDITY.read_text(encoding="utf-8"))


def humidity_from_journal(query: str, journal: dict) -> str | None:
    rec = journal.get(f"bySpecies:{query}")
    if rec and rec.get("humidity"):
        return rec["humidity"]
    genus = query.split()[0]
    rec = journal.get(f"byGenus:{genus}")
    if rec and rec.get("humidity"):
        return rec["humidity"]
    return None


def sourced_fields(rec: dict) -> set[str]:
    fields: set[str] = set()
    if rec.get("propagation") is not None:
        fields.add("propagation")
    if rec.get("bloom") is not None:
        fields.add("bloom")
    if rec.get("humidity") is not None:
        fields.add("humidity")
    if rec.get("dryDown") is not None:
        fields.add("watering")
    if rec.get("feeding"):
        fields.add("feeding")
    if rec.get("repotting"):
        fields.add("repotting")
    return fields


def sourcing_name(current: str | None, rec: dict) -> str | None:
    fields = fields_of(current) | sourced_fields(rec)
    return name_of(fields)


def patch_inner(inner: str, rec: dict) -> str:
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
    bloom = rec.get("bloom")
    if bloom is not None:
        rendered = dart_bloom(bloom)
        if BLOOM_LIT.search(inner):
            inner = BLOOM_LIT.sub(f"bloom: {rendered}", inner, count=1)
        elif re.search(r"\n      tipKeys:", inner):
            inner = re.sub(
                r"\n      tipKeys:",
                f"\n      bloom: {rendered},\n      tipKeys:",
                inner,
                count=1,
            )
    humidity = rec.get("humidity")
    if humidity is not None:
        if re.search(r"humidity: HumidityNeed\.\w+", inner):
            inner = re.sub(
                r"humidity: HumidityNeed\.\w+",
                f"humidity: HumidityNeed.{humidity}",
                inner,
                count=1,
            )
        else:
            inner = inner.rstrip() + f"\n      humidity: HumidityNeed.{humidity},\n"
    if rec.get("dryDown") is not None:
        summer, winter, rule = rec["wateringSummerDays"], rec["wateringWinterDays"], rec["dryDown"]
        inner = re.sub(r"wateringSummerDays: \d+", f"wateringSummerDays: {summer}", inner, count=1)
        if re.search(r"wateringWinterDays: \d+", inner):
            inner = re.sub(
                r"wateringWinterDays: \d+",
                f"wateringWinterDays: {winter}",
                inner,
                count=1,
            )
        if re.search(r"dryDown: DryDown\.\w+", inner):
            inner = re.sub(r"dryDown: DryDown\.\w+", f"dryDown: DryDown.{rule}", inner, count=1)
        else:
            inner = re.sub(
                r"(wateringWinterDays: \d+,)",
                rf"\1\n      dryDown: DryDown.{rule},",
                inner,
                count=1,
            )
    if rec.get("feeding"):
        inner = _set_int_or_null(inner, "fertilizingDays", rec.get("fertilizingDays"))
    if rec.get("repotting"):
        inner = _set_int_or_null(inner, "repotEveryMonths", rec.get("repotEveryMonths"))
    name = sourcing_name(rec.get("current_sourcing"), rec)
    if name:
        if SOURCING_LIT.search(inner):
            inner = SOURCING_LIT.sub(f"sourcing: {name},", inner, count=1)
        else:
            inner = inner.rstrip() + f"\n      sourcing: {name},\n"
    return inner


def patch_dart(text: str, extracted: dict) -> str:
    needed = set()
    for rec in extracted.values():
        if not sourced_fields(rec):
            continue
        name = sourcing_name(rec.get("current_sourcing"), rec)
        if name:
            needed.add(name)
    text = ensure_constants(text, needed)

    def patch_block(match: re.Match[str]) -> str:
        prefix, inner, suffix = match.group(1), match.group(2), match.group(3)
        key = re.search(r"'([^']+)'", prefix)
        if not key:
            return match.group(0)
        rec = extracted.get(f"byFamily:{key.group(1)}")
        if not rec or not sourced_fields(rec):
            return match.group(0)
        return prefix + patch_inner(inner, rec) + suffix

    return re.sub(r"(    '[^']+': CareProfile\()(.*?)(\n    \),)", patch_block, text, flags=re.S)


def extract(
    families: dict[str, dict],
    light: dict,
    humidity_journal: dict,
    by_slug: dict[str, list[str]] | None,
) -> dict:
    out: dict[str, dict] = {}
    total = len(families)
    for i, (key, profile) in enumerate(families.items(), 1):
        rec: dict = {
            "map": "byFamily",
            "key": key,
            "current_sourcing": profile["sourcing"],
        }
        prev = light.get(f"byFamily:{key}")
        query = (prev or {}).get("query")
        if prev:
            rec["query"] = query
            rec["url"] = prev.get("url")
            rec["slug"] = prev.get("slug")
        if not query:
            rec["error"] = "no-representative"
            out[f"byFamily:{key}"] = rec
            print(f"[{i}/{total}] {key}: no-representative", flush=True)
            continue
        rec["query"] = query

        classified = humidity_from_journal(query, humidity_journal)
        if classified is None:
            try:
                corpus, meta = fetch_habitat(query)
                rec.update(meta)
                classified = classify_habitat(corpus)
            except Exception as e:  # noqa: BLE001
                rec["humidity_error"] = str(e)
                classified = None
        humidity = filter_family_humidity(profile["soil"], classified)
        if humidity:
            rec["humidity"] = humidity

        if profile["summer"] is not None and profile["winter"] is not None:
            watered = apply_watering(
                profile["soil"],
                profile["growth"],
                profile["summer"],
                profile["winter"],
                explicit=profile["dryDown"],
            )
            if watered:
                rec.update(watered)

        html = html_for(rec, by_slug)
        if html:
            text = strip_html(html)
            parsed_prop = parse_propagation(text)
            methods = filter_family_prop(key, apply_prop(profile["propagation"], parsed_prop))
            if methods is not None:
                rec["propagation"] = methods
            seasons = parse_flower_seasons(html)
            bloom = filter_family_bloom(profile["bloom"], apply_bloom(profile["bloom"], seasons))
            if bloom is not None:
                rec["bloom"] = bloom
            maturity = parse_maturity(text)
            rec["maturity"] = maturity
            grown = filter_family_growth(
                profile["damageBelowC"],
                maturity,
                apply_growth(
                    soil=profile["soil"],
                    pot=profile["pot"],
                    tips=profile["tips"],
                    issues=profile["issues"],
                    fertilizer=profile["fertilizer"],
                    repot_months=profile["repotEveryMonths"],
                    damage_below_c=profile["damageBelowC"],
                    maturity=maturity,
                ),
            )
            if grown:
                rec.update(grown)
        elif not rec.get("url"):
            rec["error"] = rec.get("error") or "no-html"

        out[f"byFamily:{key}"] = rec
        bits = sorted(sourced_fields(rec))
        print(
            f"[{i}/{total}] {key} via {query}: {', '.join(bits) or rec.get('error') or 'rien'}",
            flush=True,
        )
    return out


def main() -> int:
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    except AttributeError:
        pass
    parser = argparse.ArgumentParser()
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--fetch", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    CACHE.mkdir(parents=True, exist_ok=True)

    text = PROFILES.read_text(encoding="utf-8")
    families = parse_families(text)
    light = load_light_index()
    humidity_journal = load_humidity_index()

    if args.apply and OUT.exists():
        extracted = json.loads(OUT.read_text(encoding="utf-8"))
    else:
        by_slug = None
        need_sitemap = args.fetch
        if not need_sitemap:
            for key in families:
                prev = light.get(f"byFamily:{key}")
                if not prev or not prev.get("url"):
                    need_sitemap = True
                    break
        if need_sitemap:
            print("Index du sitemap RHS…", flush=True)
            urls = load_sitemap_urls()
            by_slug = index_sitemaps(urls)
            print(f"{len(urls)} pages plantes", flush=True)
        extracted = extract(families, light, humidity_journal, by_slug)
        OUT.write_text(json.dumps(extracted, ensure_ascii=False, indent=2), encoding="utf-8")

    n = len(extracted)
    sourced = sum(1 for v in extracted.values() if sourced_fields(v))
    print(f"Familles sourcées : {sourced} / {n}", flush=True)
    for field in ("propagation", "bloom", "humidity", "watering", "feeding", "repotting"):
        if field == "watering":
            count = sum(1 for v in extracted.values() if v.get("dryDown"))
        elif field in {"feeding", "repotting"}:
            count = sum(1 for v in extracted.values() if v.get(field))
        else:
            count = sum(1 for v in extracted.values() if v.get(field) is not None)
        print(f"  {field}: {count}", flush=True)

    if args.dry_run:
        print("Dry-run : Dart intact", flush=True)
        return 0

    patched = patch_dart(text, extracted)
    if patched != text:
        PROFILES.write_text(patched, encoding="utf-8")
        print(f"Mis a jour {PROFILES}", flush=True)
    else:
        print("Aucun changement Dart", flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
