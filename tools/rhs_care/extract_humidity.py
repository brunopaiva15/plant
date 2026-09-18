"""Déduit l'humidité de l'air depuis l'habitat (GBIF + Wikipedia).

Usage :
    python extract_humidity.py           # GBIF / Wikipedia, puis le Dart
    python extract_humidity.py --apply   # reprend humidity.json
    python extract_humidity.py --dry-run # mapping, sans écrire le Dart
"""

from __future__ import annotations

import argparse
import json
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

from extract_light import CACHE, PROFILES, slug as rhs_slug
from extract_prop import page_fits
from extract_soil import load_light_index
from humidity_map import apply_humidity, classify_habitat, harvest_corpus
from sourcing import SOURCING_LIT, ensure_constants, fields_of, name_of

OUT = Path(__file__).resolve().parent / "humidity.json"
GBIF_CACHE = CACHE / "gbif"
WIKI_CACHE = CACHE / "wiki"
UA = "AuxineCare/0.1 (https://github.com/brunopaiva15/plant; habitat humidity sourcing)"
DELAY_S = 0.35


def get_json(url: str, dest: Path, retries: int = 4) -> dict | None:
    if dest.exists() and dest.stat().st_size > 0:
        return json.loads(dest.read_text(encoding="utf-8"))
    last: Exception | None = None
    for attempt in range(retries):
        req = urllib.request.Request(
            url,
            headers={"User-Agent": UA, "Accept": "application/json"},
        )
        try:
            with urllib.request.urlopen(req, timeout=40) as resp:
                data = json.loads(resp.read().decode("utf-8", "replace"))
            dest.parent.mkdir(parents=True, exist_ok=True)
            dest.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
            time.sleep(DELAY_S)
            return data
        except urllib.error.HTTPError as e:
            last = e
            if e.code == 404:
                dest.parent.mkdir(parents=True, exist_ok=True)
                dest.write_text("{}", encoding="utf-8")
                time.sleep(DELAY_S)
                return {}
            if e.code in {403, 429, 500, 503}:
                time.sleep(DELAY_S * (attempt + 2) * 2)
                continue
            raise
        except Exception as e:  # noqa: BLE001
            last = e
            time.sleep(DELAY_S * (attempt + 1))
    raise RuntimeError(f"{url}: {last}")


def parse_profiles(text: str) -> dict[str, dict]:
    maps: dict[str, dict] = {}
    for map_name in ("bySpecies", "byGenus", "byFamily"):
        m = re.search(rf"static const {map_name} = <String, CareProfile>\{{(.*?)}}\s*;", text, re.S)
        if not m:
            continue
        body = m.group(1)
        for block in re.finditer(r"    '([^']+)': CareProfile\((.*?)    \),", body, re.S):
            key, inner = block.group(1), block.group(2)
            humidity = re.search(r"humidity: HumidityNeed\.(\w+)", inner)
            sourcing = SOURCING_LIT.search(inner)
            maps.setdefault(map_name, {})[key] = {
                "humidity": humidity.group(1) if humidity else None,
                "sourcing": sourcing.group(1) if sourcing else None,
            }
    return maps


def sourcing_name(current: str | None, sourced: bool) -> str | None:
    fields = fields_of(current)
    if sourced:
        fields.add("humidity")
    return name_of(fields)


def patch_inner(inner: str, rec: dict) -> str:
    humidity = rec.get("humidity")
    if humidity is None:
        return inner
    if re.search(r"humidity: HumidityNeed\.\w+", inner):
        inner = re.sub(
            r"humidity: HumidityNeed\.\w+",
            f"humidity: HumidityNeed.{humidity}",
            inner,
            count=1,
        )
    else:
        inner = inner.rstrip() + f"\n      humidity: HumidityNeed.{humidity},\n"
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
        if rec.get("humidity") is None:
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
        if not rec or rec.get("humidity") is None:
            return match.group(0)
        return prefix + patch_inner(inner, rec) + suffix

    return re.sub(r"(    '[^']+': CareProfile\()(.*?)(\n    \),)", patch_block, text, flags=re.S)


def taxon_query(bucket: str, key: str, prev: dict | None) -> str | None:
    """L'espèce elle-même ; un genre seulement via un représentant du même genre."""
    if bucket == "byFamily":
        return None
    if bucket == "bySpecies":
        return key
    if bucket == "byGenus":
        if prev and page_fits(bucket, key, prev):
            return prev.get("query") or None
        return None
    return None


def usable_match(match: dict) -> bool:
    rank = (match.get("rank") or "").upper()
    if rank not in {"SPECIES", "SUBSPECIES", "VARIETY", "FORM"}:
        return False
    kind = match.get("matchType")
    if kind == "EXACT":
        return True
    return kind == "FUZZY" and int(match.get("confidence") or 0) >= 95


def fetch_habitat(query: str) -> tuple[str, dict]:
    """Corpus d'habitat et métadonnées GBIF/Wikipedia."""
    slug = rhs_slug(query)
    match = get_json(
        "https://api.gbif.org/v1/species/match?"
        + urllib.parse.urlencode({"name": query, "kingdom": "Plantae"}),
        GBIF_CACHE / f"match-{slug}.json",
    ) or {}
    meta: dict = {
        "gbif_key": match.get("usageKey"),
        "canonical": match.get("canonicalName"),
        "rank": match.get("rank"),
        "match_type": match.get("matchType"),
        "confidence": match.get("confidence"),
    }
    descriptions: list[dict] = []
    if usable_match(match) and match.get("usageKey"):
        key = match["usageKey"]
        desc = get_json(
            f"https://api.gbif.org/v1/species/{key}/descriptions?limit=50",
            GBIF_CACHE / f"desc-{key}.json",
        ) or {}
        descriptions = desc.get("results") or []
        meta["descriptions"] = len(descriptions)
    wiki_extract = None
    wiki_title = match.get("canonicalName") or query
    wiki_slug = wiki_title.replace(" ", "_")
    wiki = get_json(
        "https://en.wikipedia.org/api/rest_v1/page/summary/"
        + urllib.parse.quote(wiki_slug, safe="()"),
        WIKI_CACHE / f"{rhs_slug(wiki_title)}.json",
    ) or {}
    wiki_extract = wiki.get("extract")
    meta["wiki"] = wiki.get("title")
    genus = (match.get("genus") or query.split()[0]).split()[0]
    corpus = harvest_corpus(descriptions, wiki_extract, genus=genus)
    return corpus, meta


def extract(maps: dict[str, dict], light: dict) -> dict:
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
            "current_humidity": profile["humidity"],
            "current_sourcing": profile["sourcing"],
        }
        prev = light.get(f"{bucket}:{key}")
        query = taxon_query(bucket, key, prev)
        if query is None:
            rec["error"] = "not-a-taxon" if bucket == "byFamily" else "rep-other-genus"
            rec["humidity"] = None
            out[f"{bucket}:{key}"] = rec
            print(f"[{i}/{total}] {key}: {rec['error']}", flush=True)
            continue
        rec["query"] = query
        try:
            corpus, meta = fetch_habitat(query)
        except Exception as e:  # noqa: BLE001
            rec["error"] = str(e)
            rec["humidity"] = None
            out[f"{bucket}:{key}"] = rec
            print(f"[{i}/{total}] {key}: {e}", flush=True)
            continue
        rec.update(meta)
        classified = classify_habitat(corpus)
        rec["classified"] = classified
        rec["corpus"] = corpus[:2000] if corpus else ""
        humidity = apply_humidity(profile["humidity"], classified)
        rec["humidity"] = humidity
        out[f"{bucket}:{key}"] = rec
        print(
            f"[{i}/{total}] {key} -> {profile['humidity']} => {humidity}",
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
    CACHE.mkdir(parents=True, exist_ok=True)
    GBIF_CACHE.mkdir(parents=True, exist_ok=True)
    WIKI_CACHE.mkdir(parents=True, exist_ok=True)

    text = PROFILES.read_text(encoding="utf-8")
    maps = parse_profiles(text)
    light = load_light_index()

    if args.apply and OUT.exists():
        extracted = json.loads(OUT.read_text(encoding="utf-8"))
    else:
        extracted = extract(maps, light)
        OUT.write_text(json.dumps(extracted, ensure_ascii=False, indent=2), encoding="utf-8")

    sourced = sum(1 for v in extracted.values() if v.get("humidity") is not None)
    miss = sum(1 for v in extracted.values() if v.get("humidity") is None)
    print(f"Sourcés : {sourced} · sans habitat : {miss}", flush=True)

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
