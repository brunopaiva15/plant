#!/usr/bin/env python3
"""Régénère les scènes isométriques des fiches d'entretien.

Une commande fait tout : Blender rend les PNG hors du dépôt, Pillow les
convertit en WebP dans `assets/care_scene/`, puis le script affiche leur poids.

    python3 tool/build_care_scene_assets.py
    python3 tool/build_care_scene_assets.py --preview
    python3 tool/build_care_scene_assets.py --poids
"""
from __future__ import annotations

import argparse
import glob
import os
from pathlib import Path
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parent.parent
BLENDER_SCRIPT = ROOT / "tool" / "build_care_scene.py"
ASSETS = ROOT / "assets" / "care_scene"
RAW = Path("/tmp/care_scene")
LIGHTS = ("shade", "low_light", "indirect", "bright_indirect", "some_sun", "full_sun")
PLANTS = ("monstera", "broad_leaf", "upright_leaf", "vine", "fern", "rosette", "cactus", "tree", "conifer")
QUALITY = 78


def find_blender() -> str | None:
    found = shutil.which("blender")
    if found:
        return found
    candidates = [
        "/usr/local/bin/blender",
        "/usr/bin/blender",
        "/snap/bin/blender",
        "/Applications/Blender.app/Contents/MacOS/Blender",
        os.path.expanduser("~/blender/blender"),
        *sorted(glob.glob("/opt/blender*/blender")),
    ]
    return next((p for p in candidates if os.path.isfile(p) and os.access(p, os.X_OK)), None)


def render(blender: str, raw: Path, preview: bool, resolution: int, samples: int) -> None:
    cmd = [
        blender,
        "-b",
        "-noaudio",
        "-P",
        str(BLENDER_SCRIPT),
        "--",
        "--out",
        str(raw),
        "--resolution",
        str(resolution),
        "--samples",
        str(samples),
    ]
    if preview:
        cmd.append("--preview")
    print("→ Blender", flush=True)
    code = subprocess.call(cmd)
    if code != 0:
        raise SystemExit(f"Blender a échoué (code {code})")


def pack(raw: Path, quality: int) -> list[tuple[Path, int]]:
    try:
        from PIL import Image
    except ImportError as exc:
        raise SystemExit("Pillow est requis : python3 -m pip install Pillow") from exc

    delivered: list[tuple[Path, int]] = []
    for png in sorted(raw.rglob("*.png")):
        rel = png.relative_to(raw).with_suffix(".webp")
        target = ASSETS / rel
        target.parent.mkdir(parents=True, exist_ok=True)
        with Image.open(png) as image:
            image.convert("RGBA").save(target, "WEBP", quality=quality, method=6)
        delivered.append((target, target.stat().st_size))
    return delivered


def expected() -> list[Path]:
    return [
        *[ASSETS / "indoor" / f"{light}.webp" for light in LIGHTS],
        *[ASSETS / "outdoor" / f"{light}.webp" for light in LIGHTS],
        *[ASSETS / "plants" / f"{plant}.webp" for plant in PLANTS],
    ]


def print_weight() -> int:
    files = expected()
    missing = [p for p in files if not p.exists()]
    if missing:
        print("Manquants:")
        for p in missing:
            print("  -", p.relative_to(ROOT))
    total = sum(p.stat().st_size for p in files if p.exists())
    print(f"TOTAL care_scene: {total / 1e6:.2f} Mo ({len(files) - len(missing)}/{len(files)} assets)")
    return total


def contact_sheet(raw: Path) -> None:
    try:
        from PIL import Image, ImageDraw
    except ImportError:
        return
    paths = [raw / "indoor" / f"{x}.png" for x in LIGHTS] + [raw / "outdoor" / f"{x}.png" for x in LIGHTS]
    paths += [raw / "plants" / f"{x}.png" for x in PLANTS]
    paths = [p for p in paths if p.exists()]
    if not paths:
        return
    thumb = 220
    cols = 4
    rows = (len(paths) + cols - 1) // cols
    sheet = Image.new("RGBA", (cols * thumb, rows * (thumb + 28)), (246, 239, 228, 255))
    draw = ImageDraw.Draw(sheet)
    for i, path in enumerate(paths):
        with Image.open(path) as image:
            image.thumbnail((thumb - 12, thumb - 12))
            x = (i % cols) * thumb + (thumb - image.width) // 2
            y = (i // cols) * (thumb + 28) + (thumb - image.height) // 2
            sheet.alpha_composite(image.convert("RGBA"), (x, y))
        draw.text(((i % cols) * thumb + 8, (i // cols) * (thumb + 28) + thumb + 4), path.stem, fill=(74, 53, 40, 255))
    target = raw / "contact_sheet.png"
    sheet.save(target)
    print("Aperçu:", target)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preview", action="store_true")
    parser.add_argument("--poids", action="store_true")
    parser.add_argument("--out", type=Path, default=RAW)
    parser.add_argument("--resolution", type=int, default=768)
    parser.add_argument("--samples", type=int, default=32)
    parser.add_argument("--q", type=int, default=QUALITY)
    args = parser.parse_args()

    if args.poids:
        print_weight()
        return

    blender = find_blender()
    if not blender:
        raise SystemExit("Blender est introuvable. Installez-le ou ajoutez-le au PATH.")
    version = subprocess.run([blender, "--version"], capture_output=True, text=True).stdout.splitlines()
    print("Blender:", version[0] if version else blender)
    shutil.rmtree(args.out, ignore_errors=True)
    render(blender, args.out, args.preview, args.resolution, args.samples)
    delivered = pack(args.out, args.q)
    for target, size in delivered:
        print(f"  {target.relative_to(ROOT)!s:<48} {size / 1024:6.0f} ko")
    if args.preview:
        contact_sheet(args.out)
    total = print_weight()
    if total > 8_000_000:
        raise SystemExit("Les scènes dépassent le budget de 8 Mo.")


if __name__ == "__main__":
    main()
