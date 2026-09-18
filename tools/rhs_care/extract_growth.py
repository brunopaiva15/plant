"""Lit la maturité RHS et dérive engrais / rempotage.

Usage :
    python extract_growth.py           # cache, puis le réseau s'il manque
    python extract_growth.py --apply   # reprend growth.json
    python extract_growth.py --dry-run # mapping, sans écrire le Dart
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

from extract_light import (
    CACHE,
    PROFILES,
    index_sitemaps,
    load_sitemap_urls,
    slug as rhs_slug,
)
from extract_prop import page_fits
from extract_soil import html_for, load_light_index, strip_html
from growth_map import apply_growth, parse_maturity
from sourcing import SOURCING_LIT, ensure_constants, fields_of, name_of

OUT = Path(__file__).resolve().parent / "growth.json"


def _list_enum(inner: str, field: str, enum: str) -> list[str]:
    m = re.search(rf"{field}: \[([^\]]*)\]", inner)
    if not m:
        return []
    return re.findall(rf"{enum}\.(\w+)", m.group(1))


def parse_profiles(text: str) -> dict[str, dict]:
    maps: dict[str, dict] = {}
    for map_name in ("bySpecies", "byGenus", "byFamily"):
        m = re.search(rf"static const {map_name} = <String, CareProfile>\{{(.*?)}}\s*;", text, re.S)
        if not m:
            continue
        body = m.group(1)
        for block in re.finditer(r"    '([^']+)': CareProfile\((.*?)    \),", body, re.S):
            key, inner = block.group(1), block.group(2)
            days = re.search(r"fertilizingDays: (null|\d+)", inner)
            repot = re.search(r"repotEveryMonths: (\d+)", inner)
            soil = re.search(r"soil: SoilKind\.(\w+)", inner)
            pot = re.search(r"pot: PotPreference\.(\w+)", inner)
            damage = re.search(r"damageBelowC: (-?\d+)", inner)
            fert = re.search(r"fertilizer: FertilizerKind\.(\w+)", inner)
            tips = re.search(r"tipKeys: \[([^\]]*)\]", inner)
            sourcing = SOURCING_LIT.search(inner)
            maps.setdefault(map_name, {})[key] = {
                "fertilizingDays": None
                if not days or days.group(1) == "null"
                else int(days.group(1)),
                "repotEveryMonths": int(repot.group(1)) if repot else None,
                "has_fertilizing": bool(days),
                "soil": soil.group(1) if soil else None,
                "pot": pot.group(1) if pot else None,
                "damageBelowC": int(damage.group(1)) if damage else None,
                "fertilizer": fert.group(1) if fert else None,
                "tips": re.findall(r"'([^']+)'", tips.group(1)) if tips else [],
                "issues": _list_enum(inner, "issues", "CommonIssue"),
                "sourcing": sourcing.group(1) if sourcing else None,
            }
    return maps


def sourcing_name(current: str | None, rec: dict) -> str | None:
    fields = fields_of(current)
    if rec.get("feeding"):
        fields.add("feeding")
    if rec.get("repotting"):
        fields.add("repotting")
    return name_of(fields)


def _set_int_or_null(inner: str, field: str, value: int | None) -> str:
    exists = re.search(rf"{field}: (\d+|null)", inner)
    if value is None:
        if exists:
            return re.sub(rf"{field}: (\d+|null)", f"{field}: null", inner, count=1)
        return inner
    if exists:
        return re.sub(rf"{field}: (\d+|null)", f"{field}: {value}", inner, count=1)
    anchor = (
        r"(fertilizingWindow: MonthWindow\([^)]+\),)"
        if field == "repotEveryMonths"
        else r"(dryDown: DryDown\.\w+,)"
    )
    if re.search(anchor, inner):
        return re.sub(anchor, rf"\1\n      {field}: {value},", inner, count=1)
    return inner.rstrip() + f"\n      {field}: {value},\n"


def patch_inner(inner: str, rec: dict) -> str:
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
        if not rec.get("feeding") and not rec.get("repotting"):
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
        rec = None
        for bucket in ("bySpecies", "byGenus", "byFamily"):
            rec = extracted.get(f"{bucket}:{key.group(1)}")
            if rec:
                break
        if not rec or (not rec.get("feeding") and not rec.get("repotting")):
            return match.group(0)
        return prefix + patch_inner(inner, rec) + suffix

    return re.sub(r"(    '[^']+': CareProfile\()(.*?)(\n    \),)", patch_block, text, flags=re.S)


def extract(maps: dict[str, dict], light: dict, by_slug: dict[str, list[str]] | None) -> dict:
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
            "query": key,
            "current_fertilizingDays": profile["fertilizingDays"],
            "current_repotEveryMonths": profile["repotEveryMonths"],
            "current_sourcing": profile["sourcing"],
            "soil": profile["soil"],
            "pot": profile["pot"],
            "tips": profile["tips"],
        }
        if bucket == "byFamily":
            rec["error"] = "not-a-taxon"
            out[f"{bucket}:{key}"] = rec
            print(f"[{i}/{total}] {key}: not-a-taxon", flush=True)
            continue
        prev = light.get(f"{bucket}:{key}")
        if prev and page_fits(bucket, key, prev):
            rec["query"] = prev.get("query") or key
            rec["url"] = prev.get("url")
            rec["slug"] = prev.get("slug")
        elif bucket == "bySpecies":
            rec["query"] = key
            rec["slug"] = rhs_slug(key)
        elif bucket == "byGenus" and prev:
            rec["error"] = "rep-other-genus"
            out[f"{bucket}:{key}"] = rec
            print(f"[{i}/{total}] {key}: rep-other-genus", flush=True)
            continue
        html = html_for(rec, by_slug)
        maturity = parse_maturity(strip_html(html)) if html else None
        rec["maturity"] = maturity
        if html is None:
            rec["error"] = rec.get("error") or "no-html"
        applied = apply_growth(
            soil=profile["soil"],
            pot=profile["pot"],
            tips=profile["tips"],
            issues=profile["issues"],
            fertilizer=profile["fertilizer"],
            repot_months=profile["repotEveryMonths"],
            damage_below_c=profile["damageBelowC"],
            maturity=maturity,
        )
        if not applied:
            out[f"{bucket}:{key}"] = rec
            print(f"[{i}/{total}] {key}: {rec.get('error') or 'no-maturity'}", flush=True)
            continue
        rec.update(applied)
        out[f"{bucket}:{key}"] = rec
        print(
            f"[{i}/{total}] {key} {maturity or '-'} feed {profile['fertilizingDays']}"
            f"=>{applied.get('fertilizingDays')} repot {profile['repotEveryMonths']}"
            f"=>{applied.get('repotEveryMonths')}",
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
    maps = parse_profiles(text)
    light = load_light_index()

    if args.apply and OUT.exists():
        extracted = json.loads(OUT.read_text(encoding="utf-8"))
    else:
        by_slug = None
        need_sitemap = args.fetch
        if not need_sitemap:
            for bucket, entries in maps.items():
                for key in entries:
                    prev = light.get(f"{bucket}:{key}")
                    if bucket != "byFamily" and (not prev or not prev.get("url")):
                        need_sitemap = True
                        break
                if need_sitemap:
                    break
        if need_sitemap:
            print("Index du sitemap RHS…", flush=True)
            urls = load_sitemap_urls()
            by_slug = index_sitemaps(urls)
            print(f"{len(urls)} pages plantes", flush=True)
        extracted = extract(maps, light, by_slug)
        OUT.write_text(json.dumps(extracted, ensure_ascii=False, indent=2), encoding="utf-8")

    feed_n = sum(1 for v in extracted.values() if v.get("feeding"))
    repot_n = sum(1 for v in extracted.values() if v.get("repotting"))
    miss = sum(1 for v in extracted.values() if not v.get("feeding") and not v.get("repotting"))
    print(f"Engrais : {feed_n} · rempotage : {repot_n} · sans règle : {miss}", flush=True)

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
