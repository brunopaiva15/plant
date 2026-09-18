"""Écrit la règle de séchage, puis dérive les jours d'arrosage.

Usage :
    python extract_watering.py           # lit les profils, écrit watering.json
    python extract_watering.py --apply   # reprend watering.json
    python extract_watering.py --dry-run # mapping, sans écrire le Dart
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

from extract_light import PROFILES
from sourcing import SOURCING_LIT, ensure_constants, fields_of, name_of
from watering_map import apply_watering

OUT = Path(__file__).resolve().parent / "watering.json"


def parse_profiles(text: str) -> dict[str, dict]:
    maps: dict[str, dict] = {}
    for map_name in ("bySpecies", "byGenus", "byFamily"):
        m = re.search(rf"static const {map_name} = <String, CareProfile>\{{(.*?)}}\s*;", text, re.S)
        if not m:
            continue
        body = m.group(1)
        for block in re.finditer(r"    '([^']+)': CareProfile\((.*?)    \),", body, re.S):
            key, inner = block.group(1), block.group(2)
            summer = re.search(r"wateringSummerDays: (\d+)", inner)
            winter = re.search(r"wateringWinterDays: (\d+)", inner)
            dry = re.search(r"dryDown: DryDown\.(\w+)", inner)
            soil = re.search(r"soil: SoilKind\.(\w+)", inner)
            growth = re.search(r"growthMedium: GrowthMedium\.(\w+)", inner)
            sourcing = SOURCING_LIT.search(inner)
            maps.setdefault(map_name, {})[key] = {
                "summer": int(summer.group(1)) if summer else None,
                "winter": int(winter.group(1)) if winter else None,
                "dryDown": dry.group(1) if dry else None,
                "soil": soil.group(1) if soil else None,
                "growth": growth.group(1) if growth else "terrestrial",
                "sourcing": sourcing.group(1) if sourcing else None,
            }
    return maps


def sourcing_name(current: str | None, sourced: bool) -> str | None:
    fields = fields_of(current)
    if sourced:
        fields.add("watering")
    return name_of(fields)


def patch_inner(inner: str, rec: dict) -> str:
    if rec.get("dryDown") is None:
        return inner
    summer, winter, rule = rec["wateringSummerDays"], rec["wateringWinterDays"], rec["dryDown"]
    inner = re.sub(r"wateringSummerDays: \d+", f"wateringSummerDays: {summer}", inner, count=1)
    if re.search(r"wateringWinterDays: \d+", inner):
        inner = re.sub(
            r"wateringWinterDays: \d+",
            f"wateringWinterDays: {winter}",
            inner,
            count=1,
        )
    else:
        inner = re.sub(
            r"(wateringSummerDays: \d+,)",
            rf"\1\n      wateringWinterDays: {winter},",
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
    name = sourcing_name(rec.get("current_sourcing"), True)
    if name:
        if SOURCING_LIT.search(inner):
            inner = SOURCING_LIT.sub(f"sourcing: {name},", inner, count=1)
        else:
            inner = inner.rstrip() + f"\n      sourcing: {name},\n"
    return inner


def patch_dart(text: str, extracted: dict) -> str:
    needed = set()
    for rec in extracted.values():
        if rec.get("dryDown") is None:
            continue
        name = sourcing_name(rec.get("current_sourcing"), True)
        if name:
            needed.add(name)
    text = ensure_constants(text, needed)

    def patch_block(match: re.Match[str]) -> str:
        prefix, inner, suffix = match.group(1), match.group(2), match.group(3)
        key = re.search(r"'([^']+)'", prefix)
        if not key:
            return match.group(0)
        rec = None
        for bucket in ("bySpecies", "byGenus", "byFamily"):
            rec = extracted.get(f"{bucket}:{key.group(1)}")
            if rec:
                break
        if not rec or rec.get("dryDown") is None:
            return match.group(0)
        return prefix + patch_inner(inner, rec) + suffix

    return re.sub(r"(    '[^']+': CareProfile\()(.*?)(\n    \),)", patch_block, text, flags=re.S)


def extract(maps: dict[str, dict]) -> dict:
    out: dict[str, dict] = {}
    jobs: list[tuple[str, str]] = []
    for bucket, entries in maps.items():
        for key in entries:
            jobs.append((bucket, key))
    total = len(jobs)
    for i, (bucket, key) in enumerate(jobs, 1):
        profile = maps[bucket][key]
        rec = {
            "map": bucket,
            "key": key,
            "current_summer": profile["summer"],
            "current_winter": profile["winter"],
            "current_dryDown": profile["dryDown"],
            "current_sourcing": profile["sourcing"],
            "soil": profile["soil"],
            "growth": profile["growth"],
        }
        if bucket == "byFamily":
            rec["error"] = "not-a-taxon"
            rec["dryDown"] = None
            out[f"{bucket}:{key}"] = rec
            print(f"[{i}/{total}] {key}: not-a-taxon", flush=True)
            continue
        if profile["summer"] is None or profile["winter"] is None:
            rec["error"] = "no-days"
            rec["dryDown"] = None
            out[f"{bucket}:{key}"] = rec
            print(f"[{i}/{total}] {key}: no-days", flush=True)
            continue
        applied = apply_watering(
            profile["soil"],
            profile["growth"],
            profile["summer"],
            profile["winter"],
            explicit=profile["dryDown"],
        )
        if applied is None:
            rec["error"] = "no-substrate"
            rec["dryDown"] = None
            out[f"{bucket}:{key}"] = rec
            print(f"[{i}/{total}] {key}: no-substrate", flush=True)
            continue
        rec.update(applied)
        out[f"{bucket}:{key}"] = rec
        print(
            f"[{i}/{total}] {key} {profile['summer']}/{profile['winter']}"
            f" -> {applied['dryDown']} {applied['wateringSummerDays']}/{applied['wateringWinterDays']}",
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
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    text = PROFILES.read_text(encoding="utf-8")
    maps = parse_profiles(text)

    if args.apply and OUT.exists():
        extracted = json.loads(OUT.read_text(encoding="utf-8"))
    else:
        extracted = extract(maps)
        OUT.write_text(json.dumps(extracted, ensure_ascii=False, indent=2), encoding="utf-8")

    sourced = sum(1 for v in extracted.values() if v.get("dryDown") is not None)
    miss = sum(1 for v in extracted.values() if v.get("dryDown") is None)
    print(f"Sourcés : {sourced} · sans règle : {miss}", flush=True)

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
