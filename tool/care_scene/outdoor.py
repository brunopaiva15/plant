# ============================================================
# Le coin de jardin du diorama : une pelouse, un muret au fond, une haie a
# gauche qui tient lieu de coupe-vent et de repere de lumiere — le soleil
# vient de la gauche, comme dans la piece, pour que la table des emplacements
# reste valable d'une scene a l'autre.
#
# Meme camera fixe, memes bornes, meme direction de soleil que la piece
# (care_scene/common.py) : seuls le decor et les lumieres changent. Les six
# variantes vont du coin ombrage au plein soleil ; la plante, rendue a part,
# est la meme dans les deux scenes.
#
# Rien ne s'execute a l'import.
# ============================================================
from mathutils import Vector
import os, sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from care_scene.common import (  # noqa: E402  — le chemin doit etre pose avant
    FENETRE, PIECE_X, PIECE_Y, SOLEIL,
    aire, boite, maille, materiau, materiau_faisceau, monde,
)

# Les six situations de lumiere, memes noms qu'en interieur. `soleil` est le
# panneau chaud qui passe par-dessus la haie ; `faisceau` la tache au sol.
VARIANTES = {
    "shade":           {"monde": 0.20, "clef": 480.0,  "soleil": 300.0,  "appoint": 130.0, "chaleur": 0.00, "faisceau": 0.00},
    "low_light":       {"monde": 0.30, "clef": 660.0,  "soleil": 480.0,  "appoint": 170.0, "chaleur": 0.05, "faisceau": 0.00},
    "indirect":        {"monde": 0.42, "clef": 920.0,  "soleil": 760.0,  "appoint": 230.0, "chaleur": 0.10, "faisceau": 0.00},
    "bright_indirect": {"monde": 0.52, "clef": 1120.0, "soleil": 900.0,  "appoint": 270.0, "chaleur": 0.30, "faisceau": 0.45},
    "some_sun":        {"monde": 0.58, "clef": 1240.0, "soleil": 1100.0, "appoint": 300.0, "chaleur": 0.55, "faisceau": 0.70},
    "full_sun":        {"monde": 0.66, "clef": 1380.0, "soleil": 1300.0, "appoint": 330.0, "chaleur": 0.85, "faisceau": 1.00},
}


def _materiaux(v):
    return {
        "terre": materiau("MAT_PleineTerre", "7A6B5A", rough=0.80, relief=0.030),
        "pelouse": materiau("MAT_Pelouse", "93AC7C", rough=0.78, relief=0.020),
        "muret": materiau("MAT_Muret", "EFE6D2", rough=0.68, relief=0.012),
        "haie": materiau("MAT_Haie", "4F7F50", rough=0.66, relief=0.022),
    }


def _terrain(m):
    # La dalle de terre, qui tranche comme celle de la piece, et la pelouse
    # posee dessus.
    boite("Dalle", (0.05, -0.075, -0.075), (4.8, 4.15, 0.15), m["terre"], 0.05)
    boite("Pelouse", (0.05, -0.075, 0.015), (4.62, 3.97, 0.05), m["pelouse"], 0.04)


def _muret(m):
    # Un muret de pierre claire au fond, avec son couronnement un peu plus
    # large — assez haut pour fermer le fond, assez bas pour lire le jardin.
    boite("Muret", (0.0, PIECE_Y + 0.08, 0.50), (2 * PIECE_X + 0.30, 0.16, 1.00), m["muret"], 0.04)
    boite("Muret_Chapeau", (0.0, PIECE_Y + 0.08, 1.02), (2 * PIECE_X + 0.44, 0.24, 0.09), m["muret"], 0.03)


def _haie(m):
    # La haie taillee, a gauche : un grand bloc adouci. Elle fait coupe-vent
    # et c'est elle que le soleil doit passer pour toucher la pelouse.
    boite("Haie", (-PIECE_X - 0.02, 0.0, 0.75), (0.42, 3.30, 1.50), m["haie"], 0.24)


def _faisceau(force):
    if force <= 0.0:
        return
    # La meme tache que dans la piece : l'ouverture-equivalent de la haie,
    # projetee au sol le long de la direction du soleil — les emplacements
    # gardent exactement leur sens d'une scene a l'autre.
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
    """Le coin de jardin pour une variante de lumiere : terrain, muret, haie
    et lumieres. La camera est posee par l'appelant (common.camera_fixe)."""
    v = VARIANTES[nom_variante]
    m = _materiaux(v)
    _terrain(m)
    _muret(m)
    _haie(m)
    _faisceau(v["faisceau"])
    _lumieres(v, Rv, Uv, Cv)
