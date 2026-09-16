# ============================================================
# Le coin de jardin du diorama : une pelouse qui court jusqu'aux bords du
# cadre, une palissade de bois au fond, une haie qui tient lieu de coupe-vent
# a gauche et le boisement qui ferme l'horizon derriere la palissade — le
# soleil vient de la gauche, comme dans la piece, pour que la table des
# emplacements reste valable d'une scene a l'autre.
#
# Meme camera fixe, memes bornes, meme direction de soleil que la piece
# (care_scene/common.py) : seuls le decor et les lumieres changent. Les six
# variantes vont du coin ombrage au plein soleil ; la plante, rendue a part,
# est la meme dans les deux scenes.
#
# Le decor ne pose jamais de dalle visible : la pelouse depasse le cadre sur
# l'avant et les cotes, et son bord arriere se cache derriere la palissade.
# Ce qui reste transparent en haut, c'est le ciel.
#
# Rien ne s'execute a l'import.
# ============================================================
from mathutils import Vector
from math import cos, sin
import os, sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from clay_scene import revolve  # noqa: E402  — le chemin doit etre pose avant
from cutting.common import sphere  # noqa: E402  — primitives partagees des guides
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

# La palissade : sa ligne au fond, la hauteur des lames, l'espacement.
CLOTURE_Y = PIECE_Y + 0.35
LAME_H = 1.00
LAME_L = 0.14
LAME_PAS = 0.27
LAME_X = 2.55


def _materiaux(v):
    return {
        "terre": materiau("MAT_PleineTerre", "6E5B47", rough=0.82, relief=0.032),
        "pelouse": materiau("MAT_Pelouse", "8FB27A", rough=0.78, relief=0.020),
        "pelouse_fonce": materiau("MAT_PelouseFonce", "7CA06A", rough=0.78, relief=0.022),
        "bois": materiau("MAT_Palissade", "CBA878", rough=0.64, relief=0.012),
        "bois_fonce": materiau("MAT_PalissadeFonce", "A9855A", rough=0.66, relief=0.014),
        "tronc": materiau("MAT_Tronc", "8A6B4F", rough=0.72, relief=0.018),
        "feuille_haie": materiau("MAT_Haie", "4F7F50", rough=0.66, relief=0.022),
        "feuille_arbre": materiau("MAT_Arbre", "3F6F45", rough=0.66, relief=0.022),
        "feuille_lointaine": materiau("MAT_Boisement", "567F55", rough=0.70, relief=0.020),
        "pierre": materiau("MAT_Pierre", "CFC6B4", rough=0.70, relief=0.018),
        "fleur_blanc": materiau("MAT_FleurBlanc", "F7F2E6", rough=0.60, relief=0.004),
        "fleur_coeur": materiau("MAT_FleurCoeur", "E8B84B", rough=0.58, relief=0.006),
    }


def _terrain(m):
    # La pelouse depasse le cadre sur l'avant et les cotes : aucun bord de
    # dalle ne doit se lire. Le sol de terre reste dessous, pour l'epaisseur.
    boite("Terre", (0.0, -2.0, -0.30), (30.0, 30.0, 0.60), m["terre"], 0.06)
    boite("Pelouse", (0.0, -2.0, -0.02), (29.6, 29.6, 0.06), m["pelouse"], 0.04)


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


def _boisement(m):
    # Le boisement derriere la palissade : une rangee de houppiers qui se
    # chevauchent. Ils depassent la claie et ferment l'horizon sans mimer un
    # mur ; leur silhouette reste bosselee.
    cimes = [
        (-3.6, 2.9, 0.62, 1.35), (-2.8, 3.1, 0.70, 1.55), (-1.9, 2.9, 0.60, 1.30),
        (-1.0, 3.2, 0.72, 1.60), (-0.1, 3.0, 0.58, 1.30), (0.9, 3.3, 0.75, 1.70),
        (1.9, 3.0, 0.62, 1.35), (2.9, 3.2, 0.70, 1.60), (3.8, 2.9, 0.55, 1.25),
        (4.6, 3.1, 0.66, 1.50),
    ]
    for i, (x, y, r, z) in enumerate(cimes):
        mat = m["feuille_arbre"] if i % 2 == 0 else m["feuille_lointaine"]
        sphere("Cime_%02d" % i, (x, y, z), r, mat, seg=32, echelle=(1.0, 1.0, 0.88))
        sphere("CimeB_%02d" % i, (x + 0.35, y - 0.25, z - 0.25), r * 0.72, m["feuille_lointaine"], seg=28, echelle=(1.0, 1.0, 0.82))


def _haie(m):
    # La haie taillee, a gauche : une rangee de masses arrondies qui se
    # touchent. Elle fait coupe-vent et c'est elle que le soleil doit passer
    # pour toucher la pelouse ; sa silhouette reste organique, pas un bloc.
    masses = [
        (-2.30, -1.5, 0.62, 0.70), (-2.40, -0.7, 0.70, 0.85),
        (-2.34, 0.1, 0.64, 0.74), (-2.44, 0.9, 0.72, 0.92),
        (-2.30, 1.6, 0.60, 0.66),
    ]
    for i, (x, y, r, z) in enumerate(masses):
        mat = m["feuille_haie"] if i % 2 == 0 else m["feuille_arbre"]
        sphere("Haie_%02d" % i, (x, y, z), r, mat, seg=36, echelle=(1.0, 1.0, 0.95))


def _arbre(m):
    # Un arbre au fond a droite : son tronc et sa couronne donnent l'echelle
    # et disent le jardin mieux qu'un mur.
    tronc_profil = [
        (0.0, 0.0), (0.075, 0.0), (0.065, 0.55), (0.055, 1.00),
        (0.045, 1.35), (0.0, 1.42),
    ]
    tronc = revolve("Tronc_Arbre", tronc_profil, 40, [m["tronc"]], 28.0)
    tronc.location = (2.45, 1.55, 0.0)
    for i, (dx, dy, dz, r) in enumerate([
        (0.0, 0.0, 1.62, 0.62), (0.42, 0.16, 1.45, 0.44),
        (-0.38, -0.12, 1.48, 0.42), (0.08, 0.22, 1.92, 0.44),
    ]):
        sphere("Couronne_%d" % i, (2.45 + dx, 1.55 + dy, dz), r, m["feuille_arbre"], seg=32, echelle=(1.0, 1.0, 0.88))


def _fleur(m, x, y):
    # Une fleur des champs : cinq petales clairs autour d'un coeur ocre.
    for i in range(5):
        a = 0.4 + i * 1.2566
        sphere("Petale", (x + 0.055 * cos(a), y + 0.055 * sin(a), 0.075), 0.040, m["fleur_blanc"], seg=14,
               echelle=(1.0, 1.0, 0.55))
    sphere("Coeur", (x, y, 0.086), 0.030, m["fleur_coeur"], seg=14, echelle=(1.0, 1.0, 0.6))


def _fleurs(m):
    # Des fleurs des champs, sur l'avant et les cotes, a l'ecart des
    # emplacements ou la plante se pose.
    coins = [
        (-1.70, -1.55), (-2.05, -1.10), (-2.20, -1.85),
        (1.75, -1.30), (2.15, -0.55), (1.95, -1.75),
        (0.30, -2.35), (-0.45, -2.05), (2.85, 0.05),
    ]
    for i, (x, y) in enumerate(coins):
        _fleur(m, x, y)
        _fleur(m, x + 0.14, y + 0.06)
    # Quelques pierres plates, pour l'echelle, sur le bord droit.
    for i, (x, y, r) in enumerate([(2.85, -1.55, 0.20), (3.10, -1.15, 0.15), (2.70, -1.95, 0.17)]):
        sphere("Pierre_%d" % i, (x, y, 0.03), r, m["pierre"], seg=20, echelle=(1.0, 0.8, 0.28))


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
    """Le coin de jardin pour une variante de lumiere : pelouse, palissade,
    haie et boisement, plus les lumieres. La camera est posee par l'appelant
    (common.camera_fixe)."""
    v = VARIANTES[nom_variante]
    m = _materiaux(v)
    _terrain(m)
    _boisement(m)
    _palissade(m)
    _haie(m)
    _arbre(m)
    _fleurs(m)
    _faisceau(v["faisceau"])
    _lumieres(v, Rv, Uv, Cv)
