"""Extrait Pests / Diseases RHS et met à jour « À surveiller ».

Usage :
    python extract_issues.py           # cache, puis le réseau s'il manque
    python extract_issues.py --apply   # reprend issues.json
    python extract_issues.py --dry-run # mapping, sans écrire le Dart
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
    SYNONYMS,
    get,
    index_sitemaps,
    load_sitemap_urls,
    pick_url,
    slug as rhs_slug,
)
from extract_soil import html_for, load_light_index, strip_html
from issue_map import apply_issues, parse_pests_diseases
from sourcing import SOURCING_LIT, ensure_constants, fields_of, name_of

OUT = Path(__file__).resolve().parent / "issues.json"

ISSUE_CONSTS = {
    "_tropicalIssues": [
        "overwatering",
        "rootRot",
        "spiderMites",
        "thrips",
        "mealybugs",
        "scale",
        "fungusGnats",
        "leafSpot",
        "dryTips",
    ],
    "_succulentIssues": [
        "overwatering",
        "rootRot",
        "etiolation",
        "mealybugs",
        "fungusGnats",
    ],
    "_outdoorIssues": [
        "aphids",
        "trueBugs",
        "slugs",
        "powderyMildew",
        "greyMould",
    ],
}
_CONST_FROM_LIST = {tuple(v): k for k, v in ISSUE_CONSTS.items()}


def parse_issues(inner: str) -> list[str]:
    named = re.search(r"issues: (_tropicalIssues|_succulentIssues|_outdoorIssues)", inner)
    if named:
        return list(ISSUE_CONSTS[named.group(1)])
    m = re.search(r"issues: \[([^\]]*)\]", inner)
    if not m:
        return []
    return re.findall(r"CommonIssue\.(\w+)", m.group(1))


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
                "issues": parse_issues(inner),
                "sourcing": sourcing.group(1) if sourcing else None,
            }
    return maps


def dart_issues(issues: list[str]) -> str:
    key = tuple(issues)
    if key in _CONST_FROM_LIST:
        return _CONST_FROM_LIST[key]
    if not issues:
        return "[]"
    return "[" + ", ".join(f"CommonIssue.{i}" for i in issues) + "]"


def sourcing_name(current: str | None, sourced: bool) -> str | None:
    fields = fields_of(current)
    if sourced:
        fields.add("issues")
    return name_of(fields)


def patch_inner(inner: str, rec: dict) -> str:
    issues = rec.get("issues")
    if issues is None:
        return inner
    rendered = dart_issues(issues)
    if re.search(r"issues: (_tropicalIssues|_succulentIssues|_outdoorIssues|\[.*?\]),", inner, re.S):
        inner = re.sub(
            r"issues: (_tropicalIssues|_succulentIssues|_outdoorIssues|\[.*?\]),",
            f"issues: {rendered},",
            inner,
            count=1,
            flags=re.S,
        )
    else:
        inner = inner.rstrip() + f"\n      issues: {rendered},\n"
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
        if rec.get("issues") is None:
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
        if not rec or rec.get("issues") is None:
            return match.group(0)
        return prefix + patch_inner(inner, rec) + suffix

    return re.sub(r"(    '[^']+': CareProfile\()(.*?)(\n    \),)", patch_block, text, flags=re.S)


def light_is_self(bucket: str, key: str, prev: dict) -> bool:
    """Une autre espèce du genre (tirucalli ≠ poinsettia) ne source pas la fiche."""
    if bucket != "bySpecies":
        return True
    query = prev.get("query") or ""
    if query == key or SYNONYMS.get(key) == query:
        return True
    key_slug = rhs_slug(key)
    slug = prev.get("slug") or ""
    return slug == key_slug or slug.startswith(key_slug + "-")


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
            "current_issues": profile["issues"],
            "current_sourcing": profile["sourcing"],
        }
        prev = light.get(f"{bucket}:{key}")
        if prev and light_is_self(bucket, key, prev):
            rec["query"] = prev.get("query") or key
            rec["url"] = prev.get("url")
            rec["slug"] = prev.get("slug")
        elif bucket == "bySpecies":
            rec["query"] = key
            rec["slug"] = rhs_slug(key)
        html = html_for(rec, by_slug)
        if html is None:
            rec["error"] = rec.get("error") or "no-html"
            out[f"{bucket}:{key}"] = rec
            print(f"[{i}/{total}] {key}: pas de page", flush=True)
            continue
        parsed = parse_pests_diseases(strip_html(html))
        if parsed:
            rec["pests_raw"] = parsed["pests_raw"]
            rec["diseases_raw"] = parsed["diseases_raw"]
            rec["pest_free"] = parsed["pest_free"]
            rec["disease_free"] = parsed["disease_free"]
        issues = apply_issues(profile["issues"], parsed)
        rec["issues"] = issues
        out[f"{bucket}:{key}"] = rec
        print(
            f"[{i}/{total}] {key} -> {profile['issues']} => {issues}",
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

    sourced = sum(1 for v in extracted.values() if v.get("issues") is not None)
    miss = sum(1 for v in extracted.values() if v.get("issues") is None)
    emptied = sum(1 for v in extracted.values() if v.get("issues") == [])
    print(f"Sourcés : {sourced} · sans bloc : {miss} · listes vides : {emptied}", flush=True)

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
