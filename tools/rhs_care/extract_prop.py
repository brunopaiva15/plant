"""Extrait Propagation RHS et met à jour les méthodes de multiplication.

Usage :
    python extract_prop.py           # cache, puis le réseau s'il manque
    python extract_prop.py --apply   # reprend prop.json
    python extract_prop.py --dry-run # mapping, sans écrire le Dart
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

from extract_issues import light_is_self
from extract_light import (
    CACHE,
    PROFILES,
    index_sitemaps,
    load_sitemap_urls,
    slug as rhs_slug,
)
from extract_soil import html_for, load_light_index, strip_html
from prop_map import apply_prop, parse_propagation
from sourcing import SOURCING_LIT, ensure_constants, fields_of, name_of

OUT = Path(__file__).resolve().parent / "prop.json"

PROP_CONSTS = {
    "_cutting": ["stemCutting"],
    "_cuttingWater": ["stemCutting", "water"],
    "_division": ["division"],
    "_offsets": ["offsets"],
    "_seed": ["seed"],
    "_tubers": ["tuber", "division"],
    "_leaf": ["leafCutting"],
    "_layering": ["layering"],
}
_CONST_FROM_LIST = {tuple(v): k for k, v in PROP_CONSTS.items()}
_NAMED = "|".join(sorted(PROP_CONSTS, key=len, reverse=True))


def parse_prop(inner: str) -> list[str]:
    named = re.search(rf"propagation: ({_NAMED})\b", inner)
    if named:
        return list(PROP_CONSTS[named.group(1)])
    m = re.search(r"propagation: \[([^\]]*)\]", inner)
    if not m:
        return []
    return re.findall(r"Propagation\.(\w+)", m.group(1))


def parse_profiles(text: str) -> dict[str, dict]:
    maps: dict[str, dict] = {}
    for map_name in ("bySpecies", "byGenus", "byFamily"):
        m = re.search(rf"static const {map_name} = <String, CareProfile>\{{(.*?)}}\s*;", text, re.S)
        if not m:
            continue
        body = m.group(1)
        for block in re.finditer(r"    '([^']+)': CareProfile\((.*?)    \),", body, re.S):
            key, inner = block.group(1), block.group(2)
            sourcing = SOURCING_LIT.search(inner)
            maps.setdefault(map_name, {})[key] = {
                "propagation": parse_prop(inner),
                "sourcing": sourcing.group(1) if sourcing else None,
            }
    return maps


def dart_prop(methods: list[str]) -> str:
    key = tuple(methods)
    if key in _CONST_FROM_LIST:
        return _CONST_FROM_LIST[key]
    if not methods:
        return "[]"
    return "[" + ", ".join(f"Propagation.{m}" for m in methods) + "]"


def sourcing_name(current: str | None, sourced: bool) -> str | None:
    fields = fields_of(current)
    if sourced:
        fields.add("propagation")
    return name_of(fields)


def patch_inner(inner: str, rec: dict) -> str:
    methods = rec.get("propagation")
    if methods is None:
        return inner
    rendered = dart_prop(methods)
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
        if rec.get("propagation") is None:
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
        if not rec or rec.get("propagation") is None:
            return match.group(0)
        return prefix + patch_inner(inner, rec) + suffix

    return re.sub(r"(    '[^']+': CareProfile\()(.*?)(\n    \),)", patch_block, text, flags=re.S)


def page_fits(bucket: str, key: str, prev: dict | None) -> bool:
    """Une famille n'est pas un taxon ; un genre n'hérite pas d'un autre."""
    if bucket == "byFamily":
        return False
    if not prev:
        return True
    if bucket == "bySpecies":
        return light_is_self(bucket, key, prev)
    if bucket == "byGenus":
        slug = prev.get("slug") or ""
        genus = rhs_slug(key)
        return slug == genus or slug.startswith(genus + "-")
    return False


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
            "current_propagation": profile["propagation"],
            "current_sourcing": profile["sourcing"],
        }
        prev = light.get(f"{bucket}:{key}")
        if bucket == "byFamily":
            rec["error"] = "not-a-taxon"
            rec["propagation"] = None
            out[f"{bucket}:{key}"] = rec
            print(f"[{i}/{total}] {key}: not-a-taxon", flush=True)
            continue
        if prev and page_fits(bucket, key, prev):
            rec["query"] = prev.get("query") or key
            rec["url"] = prev.get("url")
            rec["slug"] = prev.get("slug")
        elif bucket == "bySpecies":
            rec["query"] = key
            rec["slug"] = rhs_slug(key)
        elif bucket == "byGenus" and prev:
            rec["error"] = "rep-other-genus"
            rec["propagation"] = None
            out[f"{bucket}:{key}"] = rec
            print(f"[{i}/{total}] {key}: rep-other-genus", flush=True)
            continue
        html = html_for(rec, by_slug)
        if html is None:
            rec["error"] = rec.get("error") or "no-html"
            out[f"{bucket}:{key}"] = rec
            print(f"[{i}/{total}] {key}: pas de page", flush=True)
            continue
        parsed = parse_propagation(strip_html(html))
        if parsed:
            rec["raw"] = parsed["raw"]
        methods = apply_prop(profile["propagation"], parsed)
        rec["propagation"] = methods
        out[f"{bucket}:{key}"] = rec
        print(
            f"[{i}/{total}] {key} -> {profile['propagation']} => {methods}",
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

    sourced = sum(1 for v in extracted.values() if v.get("propagation") is not None)
    miss = sum(1 for v in extracted.values() if v.get("propagation") is None)
    print(f"Sourcés : {sourced} · sans bloc : {miss}", flush=True)

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
