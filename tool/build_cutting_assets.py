#!/usr/bin/env python3
"""Régénère les guides de multiplication, de Blender au WebP livré.

Une seule commande fait tout : trouver Blender, rendre les images sous
`/tmp` (ou le dossier donné), les emballer en WebP animés transparents dans
`assets/cutting/<archétype>/`, et afficher le poids de chaque pack.

    python3 tool/build_cutting_assets.py                 # tout, en qualité livrée
    python3 tool/build_cutting_assets.py --preview       # quatre images par étape
    python3 tool/build_cutting_assets.py division offset # deux packs seulement
    python3 tool/build_cutting_assets.py --etape cut division
    python3 tool/build_cutting_assets.py --poids         # juste le récapitulatif

Blender est cherché dans le PATH, puis aux endroits usuels. Rien n'est
installé, rien n'est modifié hors du dépôt et du dossier de rendu.
"""
import argparse
import glob
import os
import shutil
import subprocess
import sys

RACINE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCRIPT = os.path.join(RACINE, "tool", "build_cutting_guide.py")
SORTIE = os.path.join(RACINE, "assets", "cutting")

PACKS = ["stem_node_vine", "stem_soft", "leaf_cutting", "division", "offset", "succulent_segment"]

# Les images sortent de Blender en PNG ; le WebP animé les fond, garde la
# transparence et se décode image par image dans l'application.
FPS = 14.0
# 74 plutôt que 82 : à ce niveau le grain d'argile est intact à la loupe, et
# chaque séquence pèse un cinquième de moins.
QUALITE = 74


def trouve_blender():
    """Le binaire Blender, ou rien. On cherche, on n'installe pas."""
    trouve = shutil.which("blender")
    if trouve:
        return trouve
    pistes = [
        "/usr/local/bin/blender",
        "/usr/bin/blender",
        "/snap/bin/blender",
        "/Applications/Blender.app/Contents/MacOS/Blender",
        os.path.expanduser("~/blender/blender"),
    ]
    pistes += sorted(glob.glob("/opt/blender*/blender"))
    for p in pistes:
        if os.path.isfile(p) and os.access(p, os.X_OK):
            return p
    return None


def rend(blender, pack, dossier, res, samples, apercu, etape):
    argv = [
        blender, "-b", "-noaudio", "-P", SCRIPT, "--",
        "apercu" if apercu else "complet", pack,
    ]
    if etape:
        argv.append(etape)
    argv += ["--res", str(res), "--samples", str(samples), "--out", dossier]
    print("→ %s" % pack, flush=True)
    code = subprocess.call(argv, stdout=subprocess.DEVNULL)
    if code != 0:
        sys.exit("Blender a échoué sur %s (code %d)" % (pack, code))


def emballe(pack, dossier, fps, qualite):
    """Assemble chaque étape rendue en une image animée."""
    from PIL import Image

    source = os.path.join(dossier, pack)
    if not os.path.isdir(source):
        return []
    cible = os.path.join(SORTIE, pack)
    os.makedirs(cible, exist_ok=True)
    faits = []
    for etape in sorted(os.listdir(source)):
        chemins = sorted(glob.glob(os.path.join(source, etape, "*.png")))
        if not chemins:
            continue
        images = [Image.open(c).convert("RGBA") for c in chemins]
        fichier = os.path.join(cible, etape + ".webp")
        # `loop=1` : le geste se joue une fois. L'application pilote de toute
        # façon la lecture image par image, mais un lecteur naïf fera bien.
        images[0].save(
            fichier,
            save_all=True,
            append_images=images[1:],
            duration=int(round(1000.0 / fps)),
            loop=1,
            quality=qualite,
            method=6,
        )
        for im in images:
            im.close()
        faits.append((etape, len(chemins), os.path.getsize(fichier)))
    return faits


def poids(packs):
    """Le récapitulatif : ce que pèse chaque pack, et le total."""
    total = 0
    print()
    for pack in packs:
        dossier = os.path.join(SORTIE, pack)
        p = sum(os.path.getsize(f) for f in glob.glob(os.path.join(dossier, "*.webp")))
        total += p
        print("%-18s %6.2f Mo" % (pack + ":", p / 1e6))
    print("%-18s %6.2f Mo" % ("TOTAL:", total / 1e6))


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("packs", nargs="*", help="archétypes à régénérer (par défaut : tous)")
    ap.add_argument("--preview", action="store_true", help="quatre images par étape, pour juger la scène")
    ap.add_argument("--etape", help="ne rendre qu'une étape du pack")
    ap.add_argument("--res", type=int, default=768)
    ap.add_argument("--samples", type=int, default=24)
    ap.add_argument("--fps", type=float, default=FPS)
    ap.add_argument("--q", type=int, default=QUALITE, help="qualité WebP (0-100)")
    ap.add_argument("--out", default="/tmp/multiplication", help="dossier de rendu, hors dépôt")
    ap.add_argument("--poids", action="store_true", help="afficher seulement le poids des assets livrés")
    args = ap.parse_args()

    packs = args.packs or PACKS
    for p in packs:
        if p not in PACKS:
            sys.exit("archétype inconnu : %s (parmi %s)" % (p, ", ".join(PACKS)))

    if args.poids:
        poids(packs)
        return

    blender = trouve_blender()
    if not blender:
        sys.exit("Blender est introuvable. Installez-le, ou mettez-le dans le PATH.")
    version = subprocess.run([blender, "--version"], capture_output=True, text=True).stdout.splitlines()
    print("Blender : %s (%s)" % (version[0].strip() if version else "?", blender))

    for pack in packs:
        rend(blender, pack, args.out, args.res, args.samples, args.preview, args.etape)
        for etape, images, taille in emballe(pack, args.out, args.fps, args.q):
            print("   %-20s %2d images  %5.0f ko  %.1f s" % (etape, images, taille / 1024, images / args.fps))

    poids(packs)


if __name__ == "__main__":
    main()
