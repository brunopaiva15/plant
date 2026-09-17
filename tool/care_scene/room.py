# ============================================================
# La piece du diorama : une dalle, deux murs, une fenetre a gauche, un
# voilage, un coin salon — assez pour lire « une piece », assez sobre pour
# que la plante reste le sujet. Le gueridon n'est pas bake ici : c'est un
# prop (props.py), pose par l'application sur l'emplacement lumineux.
#
# Les six variantes de lumiere partagent la meme geometrie ; seuls la
# lumiere, la vitre et la tache de soleil au sol changent. La plante n'est
# pas dans ces images : elle est rendue a part (plants.py) et posee par
# l'application sur l'emplacement qui dit son besoin de lumiere.
#
# Rien ne s'execute a l'import.
# ============================================================
import bpy
from mathutils import Vector
from math import sin, pi
import os, sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from clay_scene import revolve, tube_along  # noqa: E402  — le chemin doit etre pose avant
from care_scene.common import (  # noqa: E402
    EPAIS_MUR, FENETRE, PIECE_X, PIECE_Y, PIECE_Z, SOLEIL,
    aire, boite, maille, materiau, materiau_faisceau, materiau_vitre, monde,
)

# Les six situations de lumiere, de la plus sombre au plein soleil.
#   monde    : la lumiere ambiante de la piece
#   clef     : le grand panneau doux cote camera
#   fenetre  : le panneau qui pousse la lumiere a travers la fenetre
#   appoint  : le contre-jour froid qui degage les ombres
#   chaleur  : 0 = lumiere froide, 1 = soleil dore
#   faisceau : la force de la tache de soleil au sol (0 = pas de soleil direct)
#   vitre    : l'eclat de la vitre
VARIANTES = {
    "shade":           {"monde": 0.16, "clef": 430.0,  "fenetre": 240.0,  "appoint": 120.0, "chaleur": 0.00, "faisceau": 0.00, "vitre": 0.50},
    "low_light":       {"monde": 0.26, "clef": 620.0,  "fenetre": 430.0,  "appoint": 160.0, "chaleur": 0.05, "faisceau": 0.00, "vitre": 0.90},
    "indirect":        {"monde": 0.38, "clef": 900.0,  "fenetre": 720.0,  "appoint": 220.0, "chaleur": 0.10, "faisceau": 0.00, "vitre": 1.40},
    "bright_indirect": {"monde": 0.48, "clef": 1100.0, "fenetre": 1250.0, "appoint": 270.0, "chaleur": 0.35, "faisceau": 0.45, "vitre": 2.00},
    "some_sun":        {"monde": 0.55, "clef": 1220.0, "fenetre": 1650.0, "appoint": 300.0, "chaleur": 0.60, "faisceau": 0.70, "vitre": 2.60},
    "full_sun":        {"monde": 0.62, "clef": 1380.0, "fenetre": 2100.0, "appoint": 330.0, "chaleur": 0.85, "faisceau": 1.00, "vitre": 3.20},
}


def _materiaux(v):
    return {
        "mur": materiau("MAT_Mur", "F7EDDB", rough=0.70, relief=0.012),
        "sol": materiau("MAT_Sol", "DCC7A4", rough=0.66, relief=0.016),
        "cadre": materiau("MAT_Cadre", "FDFBF4", rough=0.55, relief=0.006),
        "rideau": materiau("MAT_Rideau", "D8E0CC", rough=0.72, relief=0.010),
        "tissu": materiau("MAT_Tissu", "A9BE99", rough=0.80, relief=0.014),
        "tissu_clair": materiau("MAT_TissuClair", "C4D3B5", rough=0.80, relief=0.012),
        "bois": materiau("MAT_Bois", "C99A6B", rough=0.60, relief=0.010),
        "tringle": materiau("MAT_Tringle", "8A6B4F", rough=0.55, relief=0.006),
        "vitre": materiau_vitre(v["chaleur"], v["vitre"]),
    }


def _dalle(m):
    # La dalle depasse les murs : le diorama est une maquette posee, pas une
    # piece infinie. Elle s'etend surtout cote camera (avant et droite).
    boite("Dalle", (0.05, -0.075, -0.075), (4.8, 4.15, 0.15), m["sol"], 0.05)


def _murs(m):
    F = FENETRE
    # Le mur du fond (+y), plein.
    boite("Mur_Fond", (0.0, PIECE_Y + EPAIS_MUR / 2, PIECE_Z / 2),
          (2 * PIECE_X + 2 * EPAIS_MUR, EPAIS_MUR, PIECE_Z), m["mur"], 0.03)
    # Le mur de gauche (-x), en quatre boites autour de l'ouverture : pas de
    # booleenne, la fenetre est simplement laissee vide.
    xm = -PIECE_X - EPAIS_MUR / 2
    zc = (F["z0"] + F["z1"]) / 2
    boite("Mur_Gauche_Bas", (xm, 0.0, F["z0"] / 2),
          (EPAIS_MUR, 2 * PIECE_Y, F["z0"]), m["mur"], 0.02)
    haut = PIECE_Z - F["z1"]
    boite("Mur_Gauche_Haut", (xm, 0.0, F["z1"] + haut / 2),
          (EPAIS_MUR, 2 * PIECE_Y, haut), m["mur"], 0.02)
    boite("Mur_Gauche_Avant", (xm, (-PIECE_Y + F["y0"]) / 2, zc),
          (EPAIS_MUR, F["y0"] + PIECE_Y, F["z1"] - F["z0"]), m["mur"], 0.02)
    boite("Mur_Gauche_Arriere", (xm, (F["y1"] + PIECE_Y) / 2, zc),
          (EPAIS_MUR, PIECE_Y - F["y1"], F["z1"] - F["z0"]), m["mur"], 0.02)


def _fenetre(m):
    F = FENETRE
    ym = (F["y0"] + F["y1"]) / 2
    zm = (F["z0"] + F["z1"]) / 2
    ly = F["y1"] - F["y0"]
    lz = F["z1"] - F["z0"]
    # Le cadre, dans l'epaisseur du mur, un peu saillant cote piece.
    x = -PIECE_X - 0.03
    boite("Cadre_Bas", (x, ym, F["z0"]), (0.10, ly + 0.16, 0.08), m["cadre"], 0.015)
    boite("Cadre_Haut", (x, ym, F["z1"]), (0.10, ly + 0.16, 0.08), m["cadre"], 0.015)
    boite("Cadre_Avant", (x, F["y0"], zm), (0.10, 0.08, lz + 0.16), m["cadre"], 0.015)
    boite("Cadre_Arriere", (x, F["y1"], zm), (0.10, 0.08, lz + 0.16), m["cadre"], 0.015)
    # La croisée.
    boite("Croix_V", (x, ym, zm), (0.07, 0.06, lz), m["cadre"], 0.01)
    boite("Croix_H", (x, ym, zm), (0.07, ly, 0.06), m["cadre"], 0.01)
    # La vitre, plaque lumineuse au fond de l'epaisseur du mur.
    boite("Vitre", (-PIECE_X - 0.09, ym, zm), (0.03, ly, lz), m["vitre"], 0.008)
    # Le rebord, qui avance dans la piece.
    boite("Rebord", (-PIECE_X + 0.06, ym, F["z0"] - 0.02), (0.20, ly + 0.22, 0.07), m["cadre"], 0.02)


def _rideau(m):
    # Un voilage plisse, devant le bord avant de la fenetre : quelques plis
    # suffisent a le lire, il ne doit pas attirer l'oeil.
    y0, y1 = -0.95, -0.28
    z0, z1 = 0.55, 2.42
    nu, nv = 20, 12
    verts, faces = [], []
    for i in range(nu + 1):
        u = i / float(nu)
        z = z1 + (z0 - z1) * u
        for j in range(nv + 1):
            t = j / float(nv)
            y = y0 + (y1 - y0) * t
            x = -1.93 + 0.045 * sin(t * pi * 5.0) * (0.6 + 0.4 * sin(u * pi))
            verts.append((x, y, z))
    for i in range(nu):
        for j in range(nv):
            a = i * (nv + 1) + j
            faces.append((a, a + 1, a + nv + 2, a + nv + 1))
    ob = maille("Rideau", verts, faces, m["rideau"], lisse=True)
    sol = ob.modifiers.new("Epaisseur", "SOLIDIFY")
    sol.thickness = 0.02
    sol.offset = 0.0
    tube_along("Tringle", [(-1.93, -1.08, 2.46), (-1.93, 1.08, 2.46)],
               [0.022, 0.022], mat=m["tringle"], seg=10, cap=3)


def _salon(m):
    # Un petit canape et sa table basse, contre le mur de gauche, face a la
    # piece : la piece dit « salon », pas seulement « coin de fenetre ». Ils
    # restent hors de tout ce qui bouge : les six emplacements, leur
    # humidificateur et le guéridon posé par l'application sont plus loin
    # dans la piece ou plus a droite. Le canape s'arrete avant le voilage.
    for i, (x, y) in enumerate([(-2.02, -1.66), (-1.58, -1.66),
                                (-2.02, -1.04), (-1.58, -1.04)]):
        boite("Pied_%d" % i, (x, y, 0.05), (0.06, 0.06, 0.10), m["bois"], 0.015)
    boite("Canape_Assise", (-1.80, -1.35, 0.21), (0.52, 0.70, 0.30), m["tissu"], 0.05)
    boite("Canape_Dossier", (-1.985, -1.35, 0.44), (0.15, 0.70, 0.54), m["tissu"], 0.05)
    boite("Canape_Bras_A", (-1.80, -1.665, 0.38), (0.55, 0.13, 0.46), m["tissu"], 0.045)
    boite("Canape_Bras_B", (-1.80, -1.035, 0.38), (0.55, 0.13, 0.46), m["tissu"], 0.045)
    boite("Coussin_A", (-1.87, -1.53, 0.43), (0.26, 0.32, 0.16), m["tissu_clair"], 0.06)
    boite("Coussin_B", (-1.87, -1.17, 0.43), (0.26, 0.32, 0.16), m["tissu_clair"], 0.06)
    # La table basse reprend le profil du gueridon, en plus bas et plus
    # petite : un meuble de la meme famille, pas un second sujet. Devant le
    # canape, visible depuis la camera, avec de l'air entre les deux — et
    # sans toucher la zone de sol que le masque du gueridon echantillonne.
    profil = [(0.0, 0.0), (0.208, 0.0), (0.228, 0.027), (0.072, 0.050),
              (0.052, 0.081), (0.052, 0.216), (0.20, 0.243), (0.224, 0.270),
              (0.212, 0.284), (0.0, 0.288)]
    ob = revolve("TableBasse", profil, 48, [m["bois"]], 26.0)
    ob.location = (-1.05, -1.55, 0.0)


def _faisceau(force):
    if force <= 0.0:
        return
    # La tache de soleil : l'ouverture de la fenetre projetee au sol le long
    # de la direction du soleil. Deux plaques superposees — une auréole large
    # et un coeur plus net — pour un bord doux sans texture.
    F = FENETRE
    coins = []
    for (y, z) in ((F["y0"], F["z0"]), (F["y1"], F["z0"]), (F["y1"], F["z1"]), (F["y0"], F["z1"])):
        t = z / -SOLEIL.z
        coins.append(Vector((-PIECE_X + SOLEIL.x * t, y + SOLEIL.y * t, 0.008)))
    maille("Faisceau", coins, [(0, 3, 2, 1)], materiau_faisceau("MAT_Faisceau", 0.28 * force))
    c = sum(coins, Vector()) / 4.0
    coeur = [c + (p - c) * 0.72 + Vector((0.0, 0.0, 0.004)) for p in coins]
    maille("Faisceau_Coeur", coeur, [(0, 3, 2, 1)], materiau_faisceau("MAT_Faisceau_Coeur", 0.50 * force))


def _lumieres(v, Rv, Uv, Cv):
    O = Vector((0.0, 0.0, 1.0))
    aire("LGT_Clef", O + 1.5 * Rv + 4.5 * Uv + 3.5 * Cv, O, 6.5, v["clef"], (1.0, 0.985, 0.960))
    # La lumiere de la fenetre : un panneau dehors, derriere la vitre, qui
    # pousse vers le sol de la piece — c'est lui qui dessine le declive
    # lumineux de gauche a droite.
    chaud = (1.0, 0.985 - 0.06 * v["chaleur"], 0.96 - 0.16 * v["chaleur"])
    aire("LGT_Fenetre", (-3.4, 0.3, 2.1), (0.9, 0.25, 0.2), 1.8, v["fenetre"], chaud,
         forme="RECTANGLE", taille_y=2.2)
    aire("LGT_Appoint", O + 4.5 * Rv - 1.5 * Uv + 2.0 * Cv, O, 5.0, v["appoint"], (0.955, 0.975, 1.0))
    monde(v["monde"])


def construire(nom_variante, Rv, Uv, Cv):
    """La piece complete pour une variante de lumiere : geometrie, matieres
    et lumieres. La camera est posee par l'appelant (common.camera_fixe)."""
    v = VARIANTES[nom_variante]
    m = _materiaux(v)
    _dalle(m)
    _murs(m)
    _fenetre(m)
    _rideau(m)
    _salon(m)
    _faisceau(v["faisceau"])
    _lumieres(v, Rv, Uv, Cv)
