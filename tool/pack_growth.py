#!/usr/bin/env python3
"""Assemble la sequence de pousse en une seule image animee (WebP).

Les images sortent de `grow_monstera.py` en PNG avec transparence. Le WebP
anime garde la transparence, ne pese qu'une fraction de la somme des PNG, et
se decode image par image : l'application n'en garde jamais plus de deux en
memoire, la ou une planche de sprites les tiendrait toutes.

    python3 tool/pack_growth.py <dossier> <sortie.webp> [--fps 14] [--q 82]
"""
import argparse
import glob
import os
import sys

try:
    from PIL import Image
except ImportError:  # pragma: no cover - outil de developpement
    sys.exit("Pillow est requis : pip install pillow")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("dossier")
    ap.add_argument("sortie")
    ap.add_argument("--fps", type=float, default=14.0)
    ap.add_argument("--q", type=int, default=82, help="qualite WebP (0-100)")
    ap.add_argument("--une-sur", type=int, default=1, help="ne garder qu'une image sur N")
    args = ap.parse_args()

    chemins = sorted(glob.glob(os.path.join(args.dossier, "*.png")))[:: args.une_sur]
    if not chemins:
        sys.exit("aucune image dans %s" % args.dossier)
    images = [Image.open(c).convert("RGBA") for c in chemins]

    # `loop=1` : la plante pousse une fois. L'application pilote de toute
    # facon la lecture image par image, mais un lecteur naif fera bien.
    images[0].save(
        args.sortie,
        save_all=True,
        append_images=images[1:],
        duration=int(round(1000.0 / args.fps)),
        loop=1,
        quality=args.q,
        method=6,
    )
    poids = os.path.getsize(args.sortie)
    print("%d images %dx%d -> %s (%.2f Mo, %.1f fps, %.1f s)"
          % (len(images), images[0].width, images[0].height, args.sortie,
             poids / 1e6, args.fps, len(images) / args.fps))


if __name__ == "__main__":
    main()
