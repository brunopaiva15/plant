"""Extrait la Position RHS et met à jour la lumière des fiches.

Usage :
    python extract_light.py          # sitemap + pages + patch Dart
    python extract_light.py --apply  # reprend le JSON déjà extrait
"""

from __future__ import annotations

import argparse
import json
import re
import sys
import time
import urllib.error
import urllib.request
from html import unescape
from pathlib import Path

from light_map import apply_floor, ideal_from_positions, parse_positions
from sourcing import SOURCING_LIT

ROOT = Path(__file__).resolve().parents[2]
PROFILES = ROOT / "lib" / "data" / "species" / "care_profiles.dart"
CACHE = Path(__file__).resolve().parent / "cache"
OUT = Path(__file__).resolve().parent / "light.json"
UA = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
)
SITEMAP_INDEX = "https://www.rhs.org.uk/sitemap_index.xml"
DELAY_S = 1.2

# Noms sous lesquels la RHS range encore une espèce au catalogue.
SYNONYMS = {
    "Dracaena trifasciata": "Sansevieria trifasciata",
    "Goeppertia orbifolia": "Calathea orbifolia",
    "Goeppertia makoyana": "Calathea makoyana",
    "Goeppertia roseopicta": "Calathea roseopicta",
    "Goeppertia zebrina": "Calathea zebrina",
    "Goeppertia rufibarba": "Calathea rufibarba",
    "Thaumatophyllum bipinnatifidum": "Philodendron bipinnatifidum",
    "Yucca gigantea": "Yucca elephantipes",
    "Curio rowleyanus": "Senecio rowleyanus",
    "Anemonoides blanda": "Anemone blanda",
    "Hesperocyparis arizonica": "Cupressus arizonica",
}

# Familles dont le premier taxon du catalogue n'a pas de fiche RHS.
FAMILY_ANCHORS = {
    "Bignoniaceae": "Campsis radicans",
}


def get(url: str, dest: Path | None = None, retries: int = 4) -> bytes:
    if dest and dest.exists() and dest.stat().st_size > 0:
        return dest.read_bytes()
    last: Exception | None = None
    for attempt in range(retries):
        req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept": "text/html,application/xml"})
        try:
            with urllib.request.urlopen(req, timeout=40) as resp:
                data = resp.read()
            if dest:
                dest.parent.mkdir(parents=True, exist_ok=True)
                dest.write_bytes(data)
            time.sleep(DELAY_S)
            return data
        except urllib.error.HTTPError as e:
            last = e
            if e.code in {403, 429, 500, 503}:
                time.sleep(DELAY_S * (attempt + 2) * 2)
                continue
            raise
        except Exception as e:  # noqa: BLE001 — réseau local, on retente
            last = e
            time.sleep(DELAY_S * (attempt + 1))
    raise RuntimeError(f"{url}: {last}")


def slug(name: str) -> str:
    s = name.lower().replace("×", "x").replace("×", "x")
    s = s.replace("'", "").replace(".", "")
    s = re.sub(r"[^a-z0-9]+", "-", s).strip("-")
    return s


def parse_profiles(text: str) -> dict[str, dict]:
    maps: dict[str, dict] = {}
    for map_name in ("bySpecies", "byGenus", "byFamily", "byCategory"):
        m = re.search(rf"static const {map_name} = <String, CareProfile>\{{(.*?)}}\s*;", text, re.S)
        if not m:
            continue
        body = m.group(1)
        for block in re.finditer(r"    '([^']+)': CareProfile\((.*?)    \),", body, re.S):
            key, inner = block.group(1), block.group(2)
            light = re.search(r"light: LightNeed\.(\w+)", inner)
            sourcing = SOURCING_LIT.search(inner)
            outdoor = "outdoorFriendly: true" in inner
            maps.setdefault(map_name, {})[key] = {
                "light": light.group(1) if light else None,
                "sourcing": sourcing.group(1) if sourcing else None,
                "outdoor": outdoor,
                "inner": inner,
            }
    return maps


def catalog_entries() -> list[tuple[str, str, str]]:
    """(scientific, family, category) depuis les catalogues Dart."""
    rows: list[tuple[str, str, str]] = []
    for path in (ROOT / "lib" / "data" / "species").rglob("*.dart"):
        text = path.read_text(encoding="utf-8")
        for m in re.finditer(
            r"SpeciesCatalogEntry\(\s*'([^']+)'\s*,\s*'([^']+)'\s*,\s*SpeciesCategory\.(\w+)",
            text,
        ):
            rows.append((m.group(1), m.group(2), m.group(3)))
    return rows


def load_sitemap_urls() -> list[str]:
    idx_path = CACHE / "sitemap_index.xml"
    idx = get(SITEMAP_INDEX, idx_path).decode("utf-8", "replace")
    urls: list[str] = []
    for loc in re.findall(r"<loc>(.*?)</loc>", idx):
        if "sitemap-plants-" not in loc:
            continue
        name = loc.rstrip("/").rsplit("/", 1)[-1]
        xml = get(loc, CACHE / name).decode("utf-8", "replace")
        urls.extend(re.findall(r"<loc>(.*?)</loc>", xml))
    return [u for u in urls if "/plants/" in u and u.endswith("/details")]


def index_sitemaps(urls: list[str]) -> dict[str, list[str]]:
    """slug de page → URLs, et index par premier token (genre)."""
    by_slug: dict[str, list[str]] = {}
    for url in urls:
        parts = url.rstrip("/").split("/")
        try:
            i = parts.index("plants")
            s = parts[i + 2]
        except (ValueError, IndexError):
            continue
        by_slug.setdefault(s, []).append(url)
    return by_slug


def pick_url(query: str, by_slug: dict[str, list[str]]) -> tuple[str, str] | None:
    """Retourne (url, slug) pour un nom scientifique ou un genre."""
    names = [query]
    if query in SYNONYMS:
        names.append(SYNONYMS[query])
    # Hybrides : « Citrus × limon » → aussi « Citrus limon ».
    stripped = re.sub(r"\s+[×x]\s+", " ", query).strip()
    if stripped != query:
        names.append(stripped)

    is_genus = " " not in query.strip()

    def choose(s: str) -> tuple[str, str] | None:
        if s in by_slug and not (is_genus and s.count("-") == 0):
            return by_slug[s][0], s
        prefixed = sorted(
            ((k, v) for k, v in by_slug.items() if k == s or k.startswith(s + "-")),
            key=lambda kv: (0 if kv[0] == s else 1, 0 if kv[0] == s + "-f" else 1, len(kv[0])),
        )
        prefixed = [(k, v) for k, v in prefixed if "'" not in k and "%27" not in k]
        if is_genus:
            prefixed = [(k, v) for k, v in prefixed if k.count("-") >= 1]
        if prefixed:
            k, v = prefixed[0]
            return v[0], k
        return None

    for name in names:
        if not name:
            continue
        hit = choose(slug(name))
        if hit:
            return hit

    g = slug(query.split()[0] if " " in query else query)
    species_pages = sorted(
        (
            (k, v)
            for k, v in by_slug.items()
            if k.startswith(g + "-") and k.count("-") == 1 and "'" not in k
        ),
        key=lambda kv: len(kv[0]),
    )
    if species_pages:
        k, v = species_pages[0]
        return v[0], k
    return None


def parse_html(html: bytes) -> dict:
    text = html.decode("utf-8", "replace")
    text = re.sub(r"<script[\s\S]*?</script>", " ", text, flags=re.I)
    text = re.sub(r"<style[\s\S]*?</style>", " ", text, flags=re.I)
    text = re.sub(r"<[^>]+>", " ", text)
    text = unescape(text)
    text = re.sub(r"[\u2013\u2014]", "-", text)
    text = re.sub(r"\s+", " ", text)
    pos_m = re.search(r"Position\s+(.{0,180}?)\s+(?:Soil Types|Growing Conditions|Aspect|Size)", text, re.I)
    asp_m = re.search(r"Aspect\s+(.{0,160}?)\s+(?:Exposure|Hardiness|Colour)", text, re.I)
    position = pos_m.group(1).strip() if pos_m else ""
    aspect = asp_m.group(1).strip() if asp_m else ""
    title_m = re.search(r"\b([A-Z][a-z]+(?:\s+[×x]\s+|\s+)[a-z-]+)", text)
    return {
        "position": position,
        "aspect": aspect,
        "positions": sorted(parse_positions(position)),
        "title": title_m.group(1) if title_m else None,
    }


def representative_for_genus(genus: str, catalog: list[tuple[str, str, str]], species_keys: list[str]) -> str:
    for key in species_keys:
        if key.split()[0] == genus:
            return SYNONYMS.get(key, key)
    indoor = [n for n, _, c in catalog if n.split()[0] == genus and c == "indoor"]
    if indoor:
        return indoor[0]
    any_sp = [n for n, _, _ in catalog if n.split()[0] == genus]
    if any_sp:
        return any_sp[0]
    return genus


def representative_for_family(family: str, catalog: list[tuple[str, str, str]], genus_keys: list[str], species_keys: list[str]) -> str | None:
    if family in FAMILY_ANCHORS:
        return FAMILY_ANCHORS[family]
    in_family = [(n, c) for n, f, c in catalog if f == family]
    for n, _ in in_family:
        if n in species_keys:
            return n
    indoor = [n for n, c in in_family if c == "indoor"]
    if indoor:
        return indoor[0]
    genera = {n.split()[0] for n, _ in in_family}
    for g in genus_keys:
        if g in genera:
            return representative_for_genus(g, catalog, species_keys)
    if in_family:
        return in_family[0][0]
    return None


def extract(maps: dict[str, dict], by_slug: dict[str, list[str]], catalog: list[tuple[str, str, str]]) -> dict:
    species_keys = list(maps.get("bySpecies", {}))
    genus_keys = list(maps.get("byGenus", {}))
    out: dict[str, dict] = {}

    jobs: list[tuple[str, str, str]] = []  # map, key, query
    for key in species_keys:
        jobs.append(("bySpecies", key, key))
    for key in genus_keys:
        jobs.append(("byGenus", key, representative_for_genus(key, catalog, species_keys)))
    for key in maps.get("byFamily", {}):
        rep = representative_for_family(key, catalog, genus_keys, species_keys)
        if rep:
            jobs.append(("byFamily", key, rep))

    total = len(jobs)
    for i, (bucket, key, query) in enumerate(jobs, 1):
        rec = {
            "map": bucket,
            "key": key,
            "query": query,
            "current": maps[bucket][key]["light"],
            "sourcing": maps[bucket][key]["sourcing"],
        }
        hit = pick_url(query, by_slug)
        if not hit:
            rec["error"] = "no-url"
            out[f"{bucket}:{key}"] = rec
            print(f"[{i}/{total}] {key}: pas d'URL pour {query}", flush=True)
            continue
        url, page_slug = hit
        rec["url"] = url
        rec["slug"] = page_slug
        dest = CACHE / "pages" / f"{page_slug}.html"
        try:
            html = get(url, dest)
            parsed = parse_html(html)
        except Exception as e:  # noqa: BLE001
            rec["error"] = str(e)
            out[f"{bucket}:{key}"] = rec
            print(f"[{i}/{total}] {key}: echec {e}", flush=True)
            continue
        rec.update(parsed)
        ideal = ideal_from_positions(frozenset(parsed["positions"]))
        rec["ideal"] = ideal
        if ideal and rec["current"]:
            light, floor = apply_floor(ideal, rec["current"])
            rec["light"] = light
            rec["lightTolerance"] = floor
        out[f"{bucket}:{key}"] = rec
        print(f"[{i}/{total}] {key} <- {query} -> {rec.get('position')!r} -> {rec.get('light')}", flush=True)
    return out


def retry_empty(extracted: dict, by_slug: dict[str, list[str]], catalog: list[tuple[str, str, str]]) -> dict:
    """Pour les fiches sans Position, tente une autre espèce du même groupe."""
    for rec in extracted.values():
        if rec.get("light"):
            continue
        bucket, key = rec["map"], rec["key"]
        tried = {rec.get("slug"), rec.get("query"), rec.get("url")}
        if bucket == "bySpecies":
            # Une autre espèce du genre dirait faux (tirucalli ≠ poinsettia).
            candidates = [key]
            if key in SYNONYMS:
                candidates.append(SYNONYMS[key])
        elif bucket == "byGenus":
            candidates = [n for n, _, _ in catalog if n.split()[0] == key]
        else:
            candidates = [n for n, f, _ in catalog if f == key]
        for cand in candidates:
            hit = pick_url(cand, by_slug)
            if not hit:
                continue
            url, page_slug = hit
            if url in tried or page_slug in tried:
                continue
            tried.add(url)
            dest = CACHE / "pages" / f"{page_slug}.html"
            try:
                parsed = parse_html(get(url, dest))
            except Exception:
                continue
            ideal = ideal_from_positions(frozenset(parsed["positions"]))
            if not ideal or not rec.get("current"):
                continue
            rec.update(parsed)
            rec["url"] = url
            rec["slug"] = page_slug
            rec["query"] = cand
            rec["ideal"] = ideal
            light, floor = apply_floor(ideal, rec["current"])
            rec["light"] = light
            rec["lightTolerance"] = floor
            print(f"retry {key} <- {cand} -> {rec.get('position')!r} -> {light}", flush=True)
            break
    return extracted


def patch_dart(text: str, extracted: dict) -> str:
    if "static const _rhsLight" not in text:
        text = text.replace(
            "  static const _rhsHardinessAndLight = {CareField.hardiness: CareSource.rhs, CareField.light: CareSource.rhs};",
            "  static const _rhsHardinessAndLight = {CareField.hardiness: CareSource.rhs, CareField.light: CareSource.rhs};\n\n"
            "  /// Lumière lue à la RHS, rusticité encore estimée.\n"
            "  static const _rhsLight = {CareField.light: CareSource.rhs};",
        )

    def patch_block(match: re.Match[str]) -> str:
        prefix, inner, suffix = match.group(1), match.group(2), match.group(3)
        key = re.search(r"'([^']+)'", prefix)
        if not key:
            return match.group(0)
        # Quel map ? on le déduit plus tard via extracted keys — on essaie les trois.
        rec = None
        for bucket in ("bySpecies", "byGenus", "byFamily"):
            rec = extracted.get(f"{bucket}:{key.group(1)}")
            if rec:
                break
        if not rec or not rec.get("light"):
            return match.group(0)
        light = rec["light"]
        floor = rec.get("lightTolerance")
        inner = re.sub(r"light: LightNeed\.\w+", f"light: LightNeed.{light}", inner, count=1)
        inner = re.sub(r"\n      lightTolerance: LightNeed\.\w+,", "", inner)
        if floor:
            inner = re.sub(
                rf"(light: LightNeed\.{light},)",
                rf"\1\n      lightTolerance: LightNeed.{floor},",
                inner,
                count=1,
            )
        if rec.get("sourcing") == "_rhsHardinessAndLight" or "CareField.light" in (rec.get("sourcing") or ""):
            pass
        elif rec.get("sourcing") == "_rhsHardiness":
            inner = inner.replace("sourcing: _rhsHardiness,", "sourcing: _rhsHardinessAndLight,")
        elif "sourcing:" not in inner:
            inner = inner.rstrip() + "\n      sourcing: _rhsLight,\n"
        else:
            # déjà une autre table : on n'y touche pas
            if "sourcing: _rhsHardiness," in inner:
                inner = inner.replace("sourcing: _rhsHardiness,", "sourcing: _rhsHardinessAndLight,")
        return prefix + inner + suffix

    return re.sub(r"(    '[^']+': CareProfile\()(.*?)(\n    \),)", patch_block, text, flags=re.S)


def main() -> int:
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    except AttributeError:
        pass
    parser = argparse.ArgumentParser()
    parser.add_argument("--apply", action="store_true", help="Relire light.json et patcher le Dart")
    parser.add_argument("--fetch", action="store_true", help="Forcer l'extraction réseau")
    parser.add_argument("--retry", action="store_true", help="Reprendre les fiches sans Position")
    parser.add_argument("--dry-run", action="store_true", help="Sitemap et appariement, sans les pages")
    args = parser.parse_args()
    CACHE.mkdir(parents=True, exist_ok=True)

    text = PROFILES.read_text(encoding="utf-8")
    maps = parse_profiles(text)
    catalog = catalog_entries()

    if args.retry and OUT.exists():
        extracted = json.loads(OUT.read_text(encoding="utf-8"))
        print("Index du sitemap RHS…", flush=True)
        urls = load_sitemap_urls()
        by_slug = index_sitemaps(urls)
        extracted = retry_empty(extracted, by_slug, catalog)
        OUT.write_text(json.dumps(extracted, ensure_ascii=False, indent=2), encoding="utf-8")
    elif args.apply and OUT.exists() and not args.fetch:
        extracted = json.loads(OUT.read_text(encoding="utf-8"))
    else:
        print("Index du sitemap RHS…", flush=True)
        urls = load_sitemap_urls()
        print(f"{len(urls)} pages plantes", flush=True)
        by_slug = index_sitemaps(urls)
        if args.dry_run:
            species_keys = list(maps.get("bySpecies", {}))
            genus_keys = list(maps.get("byGenus", {}))
            jobs = []
            for key in species_keys:
                jobs.append((key, key))
            for key in genus_keys:
                jobs.append((key, representative_for_genus(key, catalog, species_keys)))
            for key in maps.get("byFamily", {}):
                rep = representative_for_family(key, catalog, genus_keys, species_keys)
                if rep:
                    jobs.append((key, rep))
            hit = miss = 0
            for key, query in jobs:
                found = pick_url(query, by_slug)
                if found:
                    hit += 1
                else:
                    miss += 1
                    print(f"manque: {key} ({query})", flush=True)
            print(f"Appariés {hit}, sans URL {miss}", flush=True)
            return 0
        extracted = extract(maps, by_slug, catalog)
        extracted = retry_empty(extracted, by_slug, catalog)
        OUT.write_text(json.dumps(extracted, ensure_ascii=False, indent=2), encoding="utf-8")

    ok = sum(1 for v in extracted.values() if v.get("light"))
    miss = sum(1 for v in extracted.values() if not v.get("light"))
    print(f"Sourcés : {ok} · sans Position : {miss}", flush=True)

    patched = patch_dart(text, extracted)
    if patched != text:
        PROFILES.write_text(patched, encoding="utf-8")
        print(f"Mis à jour {PROFILES}", flush=True)
    else:
        print("Aucun changement Dart", flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
