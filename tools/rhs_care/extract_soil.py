"""Extrait Soil Types / Moisture / pH RHS et met à jour substrat et eau.

Usage :
    python extract_soil.py           # cache, puis le réseau s'il manque
    python extract_soil.py --apply   # reprend soil.json
    python extract_soil.py --dry-run # mapping, sans écrire le Dart
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from html import unescape
from pathlib import Path

from extract_light import (
    CACHE,
    PROFILES,
    get,
    index_sitemaps,
    load_sitemap_urls,
    pick_url,
    slug as rhs_slug,
)
from soil_map import apply_soil, parse_growing
from sourcing import SOURCING_LIT, ensure_constants, fields_of, name_of

OUT = Path(__file__).resolve().parent / "soil.json"
LIGHT = Path(__file__).resolve().parent / "light.json"


def strip_html(html: bytes) -> str:
    text = html.decode("utf-8", "replace")
    text = re.sub(r"<script[\s\S]*?</script>", " ", text, flags=re.I)
    text = re.sub(r"<style[\s\S]*?</style>", " ", text, flags=re.I)
    text = re.sub(r"<[^>]+>", " ", text)
    text = unescape(text)
    text = re.sub(r"[\u2013\u2014]", "-", text)
    text = re.sub(r"\s+", " ", text)
    return text


def parse_profiles(text: str) -> dict[str, dict]:
    maps: dict[str, dict] = {}
    for map_name in ("bySpecies", "byGenus", "byFamily"):
        m = re.search(rf"static const {map_name} = <String, CareProfile>\{{(.*?)}}\s*;", text, re.S)
        if not m:
            continue
        body = m.group(1)
        for block in re.finditer(r"    '([^']+)': CareProfile\((.*?)    \),", body, re.S):
            key, inner = block.group(1), block.group(2)
            soil = re.search(r"soil: SoilKind\.(\w+)", inner)
            water = re.search(r"water: WaterTolerance\.(\w+)", inner)
            sourcing = SOURCING_LIT.search(inner)
            maps.setdefault(map_name, {})[key] = {
                "soil": soil.group(1) if soil else None,
                "water": water.group(1) if water else "tolerant",
                "sourcing": sourcing.group(1) if sourcing else None,
                "inner": inner,
            }
    return maps


def sourcing_name(current: str | None, soil: str | None, water: str | None) -> str | None:
    fields = fields_of(current)
    if soil:
        fields.add("soil")
    if water:
        fields.add("water")
    return name_of(fields)


def patch_inner(inner: str, rec: dict) -> str:
    soil, water = rec.get("soil"), rec.get("water")
    if not soil and not water:
        return inner
    if soil:
        inner = re.sub(r"soil: SoilKind\.\w+", f"soil: SoilKind.{soil}", inner, count=1)
    if water == "strict":
        if re.search(r"water: WaterTolerance\.\w+", inner):
            inner = re.sub(r"water: WaterTolerance\.\w+", "water: WaterTolerance.strict", inner, count=1)
        else:
            inner = re.sub(
                r"(soil: SoilKind\.\w+,)",
                r"\1\n      water: WaterTolerance.strict,",
                inner,
                count=1,
            )
    elif water == "tolerant":
        inner = re.sub(r"\n      water: WaterTolerance\.(strict|sensitive),", "", inner)
    name = sourcing_name(rec.get("current_sourcing"), soil, water)
    if name:
        if SOURCING_LIT.search(inner):
            inner = SOURCING_LIT.sub(f"sourcing: {name},", inner, count=1)
        else:
            inner = inner.rstrip() + f"\n      sourcing: {name},\n"
    return inner


def patch_dart(text: str, extracted: dict) -> str:
    needed = set()
    for rec in extracted.values():
        name = sourcing_name(rec.get("current_sourcing"), rec.get("soil"), rec.get("water"))
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
        if not rec or (not rec.get("soil") and not rec.get("water")):
            return match.group(0)
        return prefix + patch_inner(inner, rec) + suffix

    return re.sub(r"(    '[^']+': CareProfile\()(.*?)(\n    \),)", patch_block, text, flags=re.S)


def load_light_index() -> dict[str, dict]:
    if not LIGHT.exists():
        return {}
    data = json.loads(LIGHT.read_text(encoding="utf-8"))
    return data


def html_for(rec: dict, by_slug: dict[str, list[str]] | None) -> bytes | None:
    dest = None
    if rec.get("slug"):
        dest = CACHE / "pages" / f"{rec['slug']}.html"
        if dest.exists() and dest.stat().st_size > 0:
            return dest.read_bytes()
    url = rec.get("url")
    if not url and by_slug is not None and rec.get("query"):
        hit = pick_url(rec["query"], by_slug)
        if hit:
            url, page_slug = hit
            rec["url"] = url
            rec["slug"] = page_slug
            dest = CACHE / "pages" / f"{page_slug}.html"
    if not url:
        return None
    if dest is None:
        dest = CACHE / "pages" / f"{rhs_slug(rec.get('query') or 'page')}.html"
    try:
        return get(url, dest)
    except Exception as e:  # noqa: BLE001
        rec["error"] = str(e)
        return None


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
            "current_soil": profile["soil"],
            "current_water": profile["water"],
            "current_sourcing": profile["sourcing"],
        }
        prev = light.get(f"{bucket}:{key}")
        if prev:
            rec["query"] = prev.get("query") or key
            rec["url"] = prev.get("url")
            rec["slug"] = prev.get("slug")
        html = html_for(rec, by_slug)
        if html is None:
            rec["error"] = rec.get("error") or "no-html"
            out[f"{bucket}:{key}"] = rec
            print(f"[{i}/{total}] {key}: pas de page", flush=True)
            continue
        growing = parse_growing(strip_html(html))
        rec["types"] = sorted(growing["types"])
        rec["moisture"] = sorted(growing["moisture"])
        rec["ph"] = sorted(growing["ph"])
        rec["raw"] = growing["raw"]
        soil, water = apply_soil(
            profile["soil"] or "standard",
            profile["water"],
            growing["types"],
            growing["moisture"],
            growing["ph"],
        )
        rec["soil"] = soil
        rec["water"] = water
        out[f"{bucket}:{key}"] = rec
        print(
            f"[{i}/{total}] {key} -> soil {profile['soil']}=>{soil} water {profile['water']}=>{water}",
            flush=True,
        )
    return out


def main() -> int:
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    except AttributeError:
        pass
    parser = argparse.ArgumentParser()
    parser.add_argument("--apply", action="store_true", help="Relire soil.json et patcher le Dart")
    parser.add_argument("--fetch", action="store_true", help="Sitemap pour les pages manquantes")
    parser.add_argument("--dry-run", action="store_true", help="Extraire sans ecrire le Dart")
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
        for bucket, entries in maps.items():
            for key in entries:
                prev = light.get(f"{bucket}:{key}")
                if not prev or not prev.get("url"):
                    need_sitemap = True
                    break
            if need_sitemap and not args.fetch:
                break
        if need_sitemap:
            print("Index du sitemap RHS…", flush=True)
            urls = load_sitemap_urls()
            by_slug = index_sitemaps(urls)
            print(f"{len(urls)} pages plantes", flush=True)
        extracted = extract(maps, light, by_slug)
        OUT.write_text(json.dumps(extracted, ensure_ascii=False, indent=2), encoding="utf-8")

    soil_n = sum(1 for v in extracted.values() if v.get("soil"))
    water_n = sum(1 for v in extracted.values() if v.get("water"))
    miss = sum(1 for v in extracted.values() if not v.get("soil") and not v.get("water"))
    print(f"Substrat : {soil_n} · eau : {water_n} · sans cote : {miss}", flush=True)

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
