#!/usr/bin/env python3
"""Reduit les rendus des symboles de familles en WebP embarquables.

Les PNG sortent de Blender en 1024 px (tool/build_category_logos.py) avec une
large marge transparente : le cadrage reserve de la place au mouvement, dont
l'application n'a pas besoin. On recadre donc sur le contenu avant de reduire,
ce qui gagne un tiers de taille apparente a l'affichage.

Le recadrage est commun aux quatre : chacun sur sa propre boite ferait grandir
le scarabee et retrecir la feuille, et la famille perdrait son unite d'echelle.

512 px suffit pour une icone affichee autour de quarante points, meme sur un
ecran a trois pixels par point, et le fichier passe de ~800 Ko a ~25 Ko.

Execution :
  python3 tool/pack_category_logos.py build/category_logos/renders
"""
import sys
from pathlib import Path

from PIL import Image

CATEGORIES = ('abiotique', 'ravageur', 'maladie', 'affection')
COTE = 512

# Marge autour du dessin, en part du cote : de l'air, sans plus.
MARGE = 0.04
DEST = Path(__file__).resolve().parent.parent / 'assets' / 'problems'


def carre_commun(images):
    """Le plus petit carre qui contient les quatre dessins, avec une marge."""
    boites = [im.getchannel('A').getbbox() for im in images]
    x0 = min(b[0] for b in boites)
    y0 = min(b[1] for b in boites)
    x1 = max(b[2] for b in boites)
    y1 = max(b[3] for b in boites)
    cote = max(x1 - x0, y1 - y0)
    marge = round(cote * MARGE)
    cote += 2 * marge
    cx, cy = (x0 + x1) // 2, (y0 + y1) // 2
    return (cx - cote // 2, cy - cote // 2, cx - cote // 2 + cote, cy - cote // 2 + cote)


def main():
    source = Path(sys.argv[1]) if len(sys.argv) > 1 else Path('build/category_logos/renders')
    DEST.mkdir(parents=True, exist_ok=True)
    rendus = {}
    for key in CATEGORIES:
        png = source / f'clay_{key}.png'
        if not png.exists():
            raise SystemExit(f'rendu manquant : {png}')
        rendus[key] = Image.open(png).convert('RGBA')
    boite = carre_commun(rendus.values())
    print(f'recadrage commun {boite}')
    for key, image in rendus.items():
        # `Image.crop` accepte de deborder du rendu et complete en transparent,
        # ce qui laisse le carre centre meme quand il mord sur le bord.
        vignette = image.crop(boite).resize((COTE, COTE), Image.LANCZOS)
        cible = DEST / f'clay_{key}.webp'
        # `exact` garde les couleurs sous les pixels transparents. Sans danger
        # ici : c'est une image fixe, pas une animation.
        vignette.save(cible, quality=90, method=6, exact=True)
        print(f'{cible} — {cible.stat().st_size // 1024} Ko')


if __name__ == '__main__':
    main()
