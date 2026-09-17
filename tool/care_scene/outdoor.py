# ============================================================
# Le coin de jardin du diorama : une pelouse sauge qui court jusqu'aux bords
# du cadre, un massif mineral et sobre la ou la plante se pose, une
# palissade de bois au fond, une haie basse a gauche qui tient lieu de
# coupe-vent et deux volumes lointains qui ferment l'horizon — le soleil
# vient de la gauche, comme dans la piece, pour que la table des
# emplacements reste valable d'une scene a l'autre.
#
# Le decor reste en retrait : peu de vegetation, des verts grises, du
# mineral clair, rien de haut derriere la plante. C'est elle, rendue a part,
# qui porte la scene — le decor dit « dehors », pas « jardin botanique ».
#
# Meme camera fixe, memes bornes, meme direction de soleil que la piece
# (care_scene/common.py) : seuls le decor et les lumieres changent. Les six
# variantes vont du coin ombrage au plein soleil ; la plante est la meme
# dans les deux scenes.
#
# Le decor ne pose jamais de dalle visible : la pelouse depasse le cadre sur
# l'avant et les cotes, et son bord arriere se cache derriere la palissade.
# Ce qui reste transparent en haut, c'est le ciel.
#
# Rien ne s'execute a l'import.
# ============================================================
from mathutils import Vector
import os, sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from cutting.common import sphere  # noqa: E402  — primitives partagees des guides
from care_scene.common import (  # noqa: E402  — le chemin doit etre pose avant
    FENETRE, PIECE_X, PIECE_Y, SOLEIL,
    aire, boite, maille, materiau, materiau_faisceau, monde,
)

# Les six situations de lumiere, memes noms qu'en interieur. `soleil` est le
# panneau chaud qui passe par-dessus la haie ; `faisceau` la tache au sol.
# L'ambiante est un cran au-dessus de la piece : dehors, le fond clair
# detache la plante au lieu de l'enfoncer.
VARIANTES = {
    "shade":           {"monde": 0.24, "clef": 480.0,  "soleil": 300.0,  "appoint": 130.0, "chaleur": 0.00, "faisceau": 0.00},
    "low_light":       {"monde": 0.35, "clef": 660.0,  "soleil": 480.0,  "appoint": 170.0, "chaleur": 0.05, "faisceau": 0.00},
    "indirect":        {"monde": 0.47, "clef": 920.0,  "soleil": 760.0,  "appoint": 230.0, "chaleur": 0.10, "faisceau": 0.00},
    "bright_indirect": {"monde": 0.57, "clef": 1120.0, "soleil": 900.0,  "appoint": 270.0, "chaleur": 0.30, "faisceau": 0.45},
    "some_sun":        {"monde": 0.63, "clef": 1240.0, "soleil": 1100.0, "appoint": 300.0, "chaleur": 0.55, "faisceau": 0.70},
    "full_sun":        {"monde": 0.70, "clef": 1380.0, "soleil": 1300.0, "appoint": 330.0, "chaleur": 0.85, "faisceau": 1.00},
}

# La palissade : sa ligne au fond, la hauteur des lames, l'espacement.
CLOTURE_Y = PIECE_Y + 0.35
LAME_H = 1.00
LAME_L = 0.14
LAME_PAS = 0.27
LAME_X = 2.55


def _materiaux(v):
    # La palette se tait : pelouse sauge, massif sable, bois clair, haie
    # grisee. Rien de sature ne dispute l'oeil a la plante.
    return {
        "terre": materiau("MAT_PleineTerre", "6E5B47", rough=0.82, relief=0.032),
        "pelouse": materiau("MAT_Pelouse", "A9BFA0", rough=0.78, relief=0.020),
        "massif": materiau("MAT_Massif", "CDBFA4", rough=0.80, relief=0.024),
        "bordure": materiau("MAT_Bordure", "9E9078", rough=0.76, relief=0.018),
        "bois": materiau("MAT_Palissade", "CBA878", rough=0.64, relief=0.012),
        "bois_fonce": materiau("MAT_PalissadeFonce", "A9855A", rough=0.66, relief=0.014),
        "feuille_haie": materiau("MAT_Haie", "8AA385", rough=0.68, relief=0.022),
        "feuille_lointaine": materiau("MAT_Boisement", "8CA184", rough=0.72, relief=0.020),
        "pierre": materiau("MAT_Pierre", "CFC6B4", rough=0.70, relief=0.018),
    }


def _terrain(m):
    # La pelouse depasse le cadre sur l'avant et les cotes : aucun bord de
    # dalle ne doit se lire. Le sol de terre reste dessous, pour l'epaisseur.
    boite("Terre", (0.0, -2.0, -0.30), (30.0, 30.0, 0.60), m["terre"], 0.06)
    boite("Pelouse", (0.0, -2.0, -0.02), (29.6, 29.6, 0.06), m["pelouse"], 0.04)


def _massif(m):
    # La zone ou la plante se pose : un massif sobre — terre claire, bordure
    # simple, a peine sureleve pour que la tache de soleil y tienne. Le pot
    # et son ombre s'en detachent ; la pelouse reste du decor. Les six
    # emplacements et leur humidificateur tiennent dedans, avec marge :
    # jamais un pied a cheval sur la bordure.
    boite("Bordure", (0.20, 0.35, 0.008), (3.30, 1.95, 0.024), m["bordure"], 0.02)
    boite("Massif", (0.20, 0.35, 0.020), (3.14, 1.79, 0.024), m["massif"], 0.02)


def _palissade(m):
    # Des lames de bois debout, une legere variation de hauteur, deux
    # traverses derriere : la palette dit « jardin », pas « interieur ».
    n = int(2 * LAME_X / LAME_PAS) + 1
    for i in range(n):
        x = -LAME_X + i * LAME_PAS
        haut = LAME_H + 0.05 * ((i * 7) % 3 - 1)
        boite("Lame_%02d" % i, (x, CLOTURE_Y, haut / 2), (LAME_L, 0.045, haut), m["bois"], 0.015)
    for j, z in enumerate((0.32, 0.70)):
        boite("Traverse_%d" % j, (0.0, CLOTURE_Y + 0.05, z), (2 * LAME_X + 0.3, 0.05, 0.09), m["bois_fonce"], 0.012)
    # Quelques poteaux plus larges et plus hauts, tous les cinq pas.
    for k in range(-2, 3):
        x = k * (LAME_PAS * 5)
        boite("Poteau_%d" % (k + 2), (x, CLOTURE_Y + 0.02, 0.66), (0.11, 0.11, 1.34), m["bois_fonce"], 0.02)


def _lointain(m):
    # Deux volumes lointains derriere la palissade : l'horizon reste dehors
    # sans raconter un boisement. Ils ne depassent la claie que d'un dôme —
    # desatures, ils ferment le fond sans passer derriere la plante.
    sphere("Lointain_0", (-2.75, 3.35, 0.62), 0.58, m["feuille_lointaine"], seg=28, echelle=(1.0, 1.0, 0.80))
    sphere("Lointain_1", (-0.15, 3.60, 0.72), 0.64, m["feuille_lointaine"], seg=28, echelle=(1.0, 1.0, 0.78))


def _haie(m):
    # La haie basse, a gauche : trois masses arrondies qui se touchent, d'un
    # seul ton sauge. Elle fait coupe-vent — le soleil la franchit pour
    # toucher le massif — sans densifier le fond.
    masses = [
        (-2.34, -1.10, 0.55, 0.46),
        (-2.42, -0.10, 0.60, 0.52),
        (-2.32, 0.90, 0.55, 0.45),
    ]
    for i, (x, y, r, z) in enumerate(masses):
        sphere("Haie_%02d" % i, (x, y, z), r, m["feuille_haie"], seg=36, echelle=(1.0, 1.0, 0.95))


def _pierres(m):
    # Quelques pierres plates, pour l'echelle, sur le bord droit : l'indice
    # mineral qui ne vole jamais la vedette.
    for i, (x, y, r) in enumerate([(2.85, -1.55, 0.20), (3.10, -1.15, 0.15), (2.70, -1.95, 0.17)]):
        sphere("Pierre_%d" % i, (x, y, 0.03), r, m["pierre"], seg=20, echelle=(1.0, 0.8, 0.28))


def _faisceau(force):
    if force <= 0.0:
        return
    # La meme tache que dans la piece : l'ouverture-equivalent de la haie,
    # projetee au sol le long de la direction du soleil — les emplacements
    # gardent exactement leur sens d'une scene a l'autre. Elle repose sur le
    # massif comme sur la pelouse : les deux sont quasiment au meme niveau.
    coins = []
    for (y, z) in ((FENETRE["y0"], FENETRE["z0"]), (FENETRE["y1"], FENETRE["z0"]),
                   (FENETRE["y1"], FENETRE["z1"]), (FENETRE["y0"], FENETRE["z1"])):
        t = z / -SOLEIL.z
        coins.append(Vector((-PIECE_X + SOLEIL.x * t, y + SOLEIL.y * t, 0.045)))
    maille("Faisceau", coins, [(0, 3, 2, 1)], materiau_faisceau("MAT_Faisceau", 0.26 * force))
    c = sum(coins, Vector()) / 4.0
    coeur = [c + (p - c) * 0.72 + Vector((0.0, 0.0, 0.004)) for p in coins]
    maille("Faisceau_Coeur", coeur, [(0, 3, 2, 1)], materiau_faisceau("MAT_Faisceau_Coeur", 0.44 * force))


def _lumieres(v, Rv, Uv, Cv):
    O = Vector((0.0, 0.0, 0.8))
    aire("LGT_Clef", O + 1.5 * Rv + 4.5 * Uv + 3.5 * Cv, O, 6.5, v["clef"], (1.0, 0.985, 0.960))
    # Le soleil : un grand panneau chaud au-dessus de la haie, qui verse vers
    # la pelouse a droite.
    chaud = (1.0, 0.985 - 0.06 * v["chaleur"], 0.96 - 0.16 * v["chaleur"])
    aire("LGT_Soleil", (-3.6, 0.3, 2.6), (0.9, 0.25, 0.0), 2.6, v["soleil"], chaud)
    aire("LGT_Appoint", O + 4.5 * Rv - 1.5 * Uv + 2.0 * Cv, O, 5.0, v["appoint"], (0.955, 0.975, 1.0))
    monde(v["monde"], couleur=(0.84, 0.88, 0.92))


def construire(nom_variante, Rv, Uv, Cv):
    """Le coin de jardin pour une variante de lumiere : pelouse, massif,
    palissade, haie basse et deux lointains, plus les lumieres. La camera
    est posee par l'appelant (common.camera_fixe)."""
    v = VARIANTES[nom_variante]
    m = _materiaux(v)
    _terrain(m)
    _massif(m)
    _palissade(m)
    _lointain(m)
    _haie(m)
    _pierres(m)
    _faisceau(v["faisceau"])
    _lumieres(v, Rv, Uv, Cv)
