# ============================================================
# Les guides de multiplication : une sequence d'images par etape, que
# l'application joue quand on multiplie une plante.
#
# Meme scene, memes materiaux et meme cadrage que l'icone et l'onboarding :
# argile mate, lumiere de studio, vue 3/4 orthographique, fond transparent
# et sans ombre portee — l'ombre et le flottement sont dessines par
# l'application.
#
# Six archetypes, six gestes differents :
#   stem_node_vine     bouture de tige a noeud (pothos, monstera)
#   stem_soft          bouture de tige tendre (basilic, menthe)
#   leaf_cutting       bouture de feuille (sansevieria)
#   division           division d'une touffe (spathiphyllum)
#   offset             separation d'un rejet (aloe, pilea)
#   succulent_segment  bouture de segment (cactus de Noel)
#
# Chaque etape est cadree une fois pour toutes sur l'union de ses images :
# sans cela le cadre suivrait le sujet et c'est le monde qui semblerait
# bouger.
#
# Execution — un pack, ou tous :
#   blender -b -noaudio -P tool/build_cutting_guide.py -- complet all
#   blender -b -noaudio -P tool/build_cutting_guide.py -- apercu stem_node_vine
#   blender -b -noaudio -P tool/build_cutting_guide.py -- complet division separate
#
# Options, dans cet ordre, toutes facultatives :
#   <apercu|complet> <pack|all> [etape] [--res N] [--samples N] [--out DOSSIER]
#
# L'emballage en WebP et le recapitulatif des poids sont dans
# `tool/build_cutting_assets.py`, qui appelle ce script.
# ============================================================
import importlib
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

PACKS = ["stem_node_vine", "stem_soft", "leaf_cutting", "division", "offset", "keiki", "succulent_segment"]


def _options(argv):
    mode, pack, etape = "complet", "all", None
    res, samples, dossier = 768, 32, "/tmp/multiplication"
    libres = []
    i = 0
    while i < len(argv):
        a = argv[i]
        if a == "--res":
            res = int(argv[i + 1]); i += 2
        elif a == "--samples":
            samples = int(argv[i + 1]); i += 2
        elif a == "--out":
            dossier = argv[i + 1]; i += 2
        else:
            libres.append(a); i += 1
    if libres and libres[0] in ("apercu", "complet"):
        mode = libres.pop(0)
    if libres:
        pack = libres.pop(0)
    if libres:
        etape = libres.pop(0)
    return mode, pack, etape, res, samples, dossier


argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
MODE, PACK, ETAPE, RES, SAMPLES, DOSSIER = _options(argv)

if PACK == "all":
    choisis = PACKS
elif PACK in PACKS:
    choisis = [PACK]
else:
    sys.exit("pack inconnu : %s (parmi %s)" % (PACK, ", ".join(PACKS + ["all"])))

from cutting.common import rendre  # noqa: E402  — le chemin doit etre pose avant

for nom in choisis:
    module = importlib.import_module("cutting." + nom)
    rendre(module.PACK, module.ETAPES, RES, SAMPLES, DOSSIER, apercu=(MODE == "apercu"), seule=ETAPE)

print("GUIDES:", DOSSIER, flush=True)
