#!/usr/bin/env python3
"""Remesure `common.ENVELOPPE_PLANTE` sur les silhouettes livrees.

L'enveloppe est en fractions du cadre : elle change avec le cadre et avec
les silhouettes. `verifie_couloir` s'en sert pour dire si un meuble passe
devant la plante — une enveloppe perimee la rend muette, ou bavarde.

    python3 tool/mesure_enveloppe.py
"""
import glob
import os
import re
import sys

from PIL import Image

RACINE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PLANTES = os.path.join(RACINE, "assets", "care_scene", "plants")
COMMON = os.path.join(RACINE, "tool", "care_scene", "common.py")
DART = os.path.join(RACINE, "lib", "features", "species", "application",
                    "care_environment_slots.dart")


def ancre():
    """Le point d'ancrage, lu dans la table generee."""
    texte = open(DART, encoding="utf-8").read()
    m = re.search(r"anchor = \((0\.\d+), (0\.\d+)\)", texte)
    if not m:
        sys.exit("ancre introuvable dans %s" % DART)
    return float(m.group(1)), float(m.group(2))


def main():
    ax, ay = ancre()
    x0 = y0 = 1.0
    x1 = y1 = 0.0
    for chemin in sorted(glob.glob(os.path.join(PLANTES, "*.webp"))):
        im = Image.open(chemin).convert("RGBA")
        bb = im.split()[3].point(lambda v: 255 if v > 64 else 0).getbbox()
        if bb is None:
            sys.exit("silhouette vide : %s" % chemin)
        w, h = im.size
        x0 = min(x0, bb[0] / w); x1 = max(x1, bb[2] / w)
        y0 = min(y0, bb[1] / h); y1 = max(y1, bb[3] / h)
        im.close()
    enveloppe = (round(x0 - ax, 4), round(y0 - ay, 4),
                 round(x1 - ax, 4), round(y1 - ay, 4))
    actuelle = re.search(r"ENVELOPPE_PLANTE = \(([^)]*)\)",
                         open(COMMON, encoding="utf-8").read())
    print("mesurée : ENVELOPPE_PLANTE = %s" % (enveloppe,))
    print("en place : (%s)" % (actuelle.group(1) if actuelle else "?"))
    if actuelle and tuple(float(v) for v in actuelle.group(1).split(",")) == enveloppe:
        print("à jour.")
    else:
        print("→ reporter la valeur mesurée dans tool/care_scene/common.py")


if __name__ == "__main__":
    main()
