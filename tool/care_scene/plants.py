# ============================================================
# Les plantes de la scene « environnement ideal », rendues seules au centre
# du monde, dans la camera fixe commune : l'application les pose ensuite sur
# l'emplacement qui dit leur besoin de lumiere.
#
# Vague 1 : huit archétypes. `monstera` et `broad_leaf` (le repli) sortent
# des recettes de la collection de l'onboarding (tool/build_collection.py) ;
# les autres sont construits ici a partir des primitives de clay_scene et de
# `ruban_along`/`limbe` de tool/cutting/common.py.
#
# Rien ne s'execute a l'import.
# ============================================================
from mathutils import Vector
from math import cos, sin, pi, radians
import os, sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from clay_scene import (  # noqa: E402  — le chemin doit etre pose avant
    POT_PROFIL, TERRE_PROFIL, Z_TERRE, make_leaf, make_mat, revolve, tube_along,
)
from cutting.common import bezier, borne, limbe, repere_face, ruban_along, sphere  # noqa: E402  — primitives partagees des guides
from care_scene.common import VUE  # noqa: E402

UP = Vector((0, 0, 1))

# L'echelle de la piece. Les recettes viennent de la collection de
# l'onboarding, ou la plante est rendue seule : sa taille absolue n'y veut
# rien dire. Ici elle partage le cadre avec une piece de 4,2 m sur 3,6 m, un
# gueridon et un humidificateur, tous a l'echelle reelle — telles quelles,
# les recettes donnaient un monstera de 3,3 m de large, dans un pot de
# 1,3 m, qui traversait les murs et sortait du diorama.
ECHELLE_PIECE = 0.50

# ------------------------------------------------------------
# les parametres des deux recettes `make_leaf` (collection)
# ------------------------------------------------------------
# Une feuille : (azimut, inclinaison, petiole, limbe, largeur relative,
# fentes, trous, roulis).
RECETTES = {
    "monstera": {
        "pot": ("C87A57", 1.0),
        "feuille": "0E6B34",
        "feuilles": [
            (206.0, 38.0, 0.62, 1.14, 0.435, 4, 2, -8.0),
            (28.0, 34.0, 0.74, 1.08, 0.435, 4, 2, 6.0),
            (272.0, 41.0, 0.58, 1.02, 0.430, 4, 2, -11.0),
            (96.0, 30.0, 0.80, 0.96, 0.435, 4, 1, -10.0),
            (320.0, 26.0, 0.82, 0.98, 0.435, 4, 1, 9.0),
            (158.0, 22.0, 0.86, 0.90, 0.430, 3, 1, 7.0),
            (58.0, 17.0, 0.72, 0.74, 0.420, 3, 1, -6.0),
            (238.0, 13.0, 0.64, 0.62, 0.405, 2, 0, 8.0),
            (128.0, 8.0, 0.48, 0.48, 0.390, 2, 0, -5.0),
        ],
    },
    "broad_leaf": {
        "pot": ("B87050", 0.92),
        "feuille": "18693C",
        "feuilles": [
            (20.0, 46.0, 0.68, 0.84, 0.60, 0, 0, -12.0),
            (157.0, 49.0, 0.72, 0.86, 0.60, 0, 0, 9.0),
            (295.0, 44.0, 0.66, 0.80, 0.59, 0, 0, -7.0),
            (72.0, 40.0, 0.70, 0.82, 0.60, 0, 0, 13.0),
            (210.0, 42.0, 0.64, 0.78, 0.58, 0, 0, -10.0),
            (347.0, 36.0, 0.68, 0.80, 0.59, 0, 0, 6.0),
            (125.0, 31.0, 0.58, 0.72, 0.57, 0, 0, -14.0),
            (262.0, 27.0, 0.56, 0.70, 0.57, 0, 0, 11.0),
            (40.0, 22.0, 0.50, 0.64, 0.55, 0, 0, -5.0),
            (177.0, 16.0, 0.42, 0.56, 0.53, 0, 0, 8.0),
            (300.0, 9.0, 0.32, 0.44, 0.50, 0, 0, -9.0),
        ],
    },
}


# Le pot et la feuille de chaque plante : (pot, feuille).
COULEURS = {
    "monstera": ("C87A57", "0E6B34"),
    "broad_leaf": ("B87050", "18693C"),
    "upright_leaf": ("CE8462", "2A7A4C"),
    "vine": ("C0764F", "2E8B57"),
    "fern": ("C87A57", "2C8A50"),
    "rosette": ("C87A57", "5D9A6B"),
    "cactus": ("B87050", "3E8C5A"),
    "conifer": ("91452E", "235A38"),
    "orchid": ("B87050", "2F7348"),
}


def _materiaux(nom):
    """Le jeu de matieres de la plante [nom] : pot, terre, tige, feuille, et
    les matieres alternatives (charnu, pousse, tronc)."""
    pot_hex, feuille_hex = COULEURS.get(nom, ("C87A57", "1F7A44"))
    return {
        "pot": make_mat("MAT_Pot_" + nom, pot_hex, 0.68, 0.18, grain=34.0, relief=0.024, sss=0.10),
        "terre": make_mat("MAT_Terre_" + nom, "3B302A", 0.90, 0.06, grain=20.0, relief=0.040, sss=0.0),
        "tige": make_mat("MAT_Tige_" + nom, "2C7A4C", 0.55, 0.26, grain=55.0, relief=0.008, sss=0.12),
        "feuille": make_mat("MAT_Feuille_" + nom, feuille_hex, 0.52, 0.32, grain=60.0, relief=0.008, sss=0.14),
        "charnu": make_mat("MAT_Charnu_" + nom, "5D9A6B", 0.50, 0.30, grain=52.0, relief=0.009, sss=0.24),
        "pousse": make_mat("MAT_Pousse_" + nom, "5FAE63", 0.50, 0.34, grain=62.0, relief=0.007, sss=0.20),
        "tronc": make_mat("MAT_Tronc_" + nom, "8A6B4F", 0.72, 0.16, grain=40.0, relief=0.018, sss=0.05),
        # La fleur d'orchidee : un blanc rose mat, et un coeur qui tire sur
        # l'ocre — assez loin des verts pour que la hampe se lise.
        "fleur": make_mat("MAT_Fleur_" + nom, "EFDAD6", 0.56, 0.22, grain=58.0, relief=0.007, sss=0.30),
        "fleur_coeur": make_mat("MAT_FleurCoeur_" + nom, "D9A85C", 0.60, 0.20, grain=50.0, relief=0.010, sss=0.18),
    }


def _pot_et_terre(mats, echelle, D):
    pot = revolve("Pot", POT_PROFIL, 96, [mats["pot"]], 34.0)
    terre = revolve("Terre", TERRE_PROFIL, 96, [mats["terre"]], 40.0)
    for ob in (pot, terre):
        ob.scale = (echelle, echelle, echelle)
        ob.location = D
    return [pot, terre]


# ------------------------------------------------------------
# monstera / broad_leaf : les recettes de la collection
# ------------------------------------------------------------
def _en_feuilles(nom, mats, D, echelle_pot):
    recette = RECETTES[nom]
    objets = []
    sol = Z_TERRE * echelle_pot
    for idx, (az, tilt, Lp, L, larg, nfe, ntr, roll) in enumerate(recette["feuilles"]):
        a, t = radians(az), radians(tilt)
        P0 = D + Vector((0.10 * echelle_pot * cos(a), 0.10 * echelle_pot * sin(a), sol - 0.03))
        dirn = Vector((sin(t) * cos(a), sin(t) * sin(a), cos(t)))
        P2 = P0 + dirn * Lp
        P1 = P0 + Vector((0, 0, Lp * 0.58))
        npt = 14
        pts, radii = [], []
        for i in range(npt + 1):
            s = i / float(npt)
            u = 1.0 - s
            pts.append(P0 * (u * u) + P1 * (2 * u * s) + P2 * (s * s))
            radii.append(0.052 - 0.020 * s)
        objets.append(tube_along("Tige_%02d" % (idx + 1), pts, radii, mat=mats["tige"]))

        T = (pts[-1] - pts[-2]).normalized()
        outward = Vector((cos(a), sin(a), 0.0))
        F = (VUE * 0.78 + Vector((0, 0, 1)) * 0.34 + outward * 0.26).normalized()
        Zl = (F - F.dot(T) * T)
        if Zl.length < 1e-4:
            Zl = UP
        Zl.normalize()
        Yl = T
        Xl = Yl.cross(Zl)
        rr = radians(roll)
        Xl2 = Xl * cos(rr) + Zl * sin(rr)
        Zl2 = -Xl * sin(rr) + Zl * cos(rr)
        objets.append(make_leaf("Feuille_%02d" % (idx + 1), P2 - T * 0.03,
                                Xl2, Yl, Zl2, L=L, n_fentes=nfe, mat=mats["feuille"],
                                n_trous=ntr, w_ratio=larg))
    return objets


# ------------------------------------------------------------
# upright_leaf : les lames presque droites d'une sansevieria
# ------------------------------------------------------------
def _upright(nom, mats, D, echelle_pot):
    objets = []
    sol = Z_TERRE * echelle_pot
    # (azimut, inclinaison, hauteur, largeur relative, roulis) : presque pas
    # de petiole, les lames partent de la terre.
    lames = [
        (210.0, 9.0, 1.42, 0.115, 0.0),
        (330.0, 14.0, 1.24, 0.105, 4.0),
        (90.0, 6.0, 1.55, 0.100, -3.0),
        (30.0, 17.0, 1.10, 0.095, 6.0),
        (150.0, 12.0, 1.32, 0.105, -5.0),
        (260.0, 20.0, 0.92, 0.110, 3.0),
        (12.0, 11.0, 1.36, 0.098, -6.0),
        (188.0, 16.0, 1.16, 0.102, 5.0),
        (68.0, 21.0, 0.86, 0.092, -4.0),
        (292.0, 8.0, 1.48, 0.096, 2.0),
        (238.0, 13.0, 1.04, 0.088, -7.0),
    ]
    for idx, (az, tilt, L, larg, roll) in enumerate(lames):
        a, t = radians(az), radians(tilt)
        P0 = D + Vector((0.10 * echelle_pot * cos(a), 0.10 * echelle_pot * sin(a), sol - 0.02))
        dirn = Vector((sin(t) * cos(a), sin(t) * sin(a), cos(t)))
        P2 = P0 + dirn * 0.10
        P1 = P0 + Vector((0, 0, 0.06))
        pts, radii = [], []
        for i in range(10):
            s = i / 9.0
            u = 1.0 - s
            pts.append(P0 * (u * u) + P1 * (2 * u * s) + P2 * (s * s))
            radii.append(0.030 - 0.010 * s)
        objets.append(tube_along("Base_%02d" % (idx + 1), pts, radii, mat=mats["tige"]))
        T = (pts[-1] - pts[-2]).normalized()
        outward = Vector((cos(a), sin(a), 0.0))
        F = (VUE * 0.62 + UP * 0.52 + outward * 0.30).normalized()
        Zl = (F - F.dot(T) * T)
        if Zl.length < 1e-4:
            Zl = UP
        Zl.normalize()
        Yl = T
        Xl = Yl.cross(Zl)
        rr = radians(roll)
        Xl2 = Xl * cos(rr) + Zl * sin(rr)
        Zl2 = -Xl * sin(rr) + Zl * cos(rr)
        objets.append(make_leaf("Lame_%02d" % (idx + 1), P2 - T * 0.02,
                                Xl2, Yl, Zl2, L=L, n_fentes=0, mat=mats["feuille"],
                                n_trous=0, w_ratio=larg))
    return objets


# ------------------------------------------------------------
# vine : des tiges qui retombent et de petites feuilles en coeur
# ------------------------------------------------------------
def _vine(nom, mats, D, echelle_pot):
    objets = []
    sol = Z_TERRE * echelle_pot
    rebord_z = 0.945 * echelle_pot
    rebord_r = 0.64 * echelle_pot
    # (azimut, longueur, tombant) : les tiges retombent dehors, c'est ce qui
    # lit « grimpante ».
    tiges = [
        (25.0, 1.00, 0.85),
        (78.0, 0.86, 0.48),
        (110.0, 0.90, 0.55),
        (200.0, 1.05, 0.75),
        (248.0, 0.92, 0.66),
        (290.0, 0.95, 0.60),
    ]
    for idx, (az, lon, tombant) in enumerate(tiges):
        a = radians(az)
        outward = Vector((cos(a), sin(a), 0.0))
        # Un chemin explicite : le centre, le haut du pot, sur le rebord,
        # puis la retombee dehors — jamais a travers la paroi.
        pts = [
            D + Vector((0.05 * cos(a), 0.05 * sin(a), sol - 0.02)),
            D + outward * 0.16 + UP * (rebord_z + 0.06),
            D + outward * (rebord_r + 0.05) + UP * (rebord_z + 0.07),
            D + outward * (rebord_r + 0.28 * lon) + UP * (rebord_z - 0.22 * lon * tombant),
            D + outward * (rebord_r + 0.42 * lon) + UP * (rebord_z - 0.52 * lon * tombant),
        ]
        radii = [0.024, 0.022, 0.020, 0.016, 0.012]
        objets.append(tube_along("Tige_%02d" % (idx + 1), pts, radii, mat=mats["tige"], seg=10, cap=4))
        # Deux feuilles par tige : une drapee sur le rebord, une au bout de
        # la retombee — toutes dehors.
        # Reparties le long de la retombee, pas empilees au meme point : une
        # tige de misere porte des feuilles sur toute sa longueur.
        for j, s in enumerate((0.05, 0.42, 0.74, 1.0)):
            u = s * (len(pts) - 3)
            k = min(int(u) + 2, len(pts) - 2)
            f = u - (k - 2)
            P = pts[k] * (1.0 - f) + pts[k + 1] * f
            T = (pts[k + 1] - pts[k]).normalized()
            F = (VUE * 0.72 + UP * 0.42 + outward * 0.22).normalized()
            # Les feuilles alternent d'un cote puis de l'autre de la tige et
            # s'inclinent differemment : alignees pareil, elles faisaient un
            # peigne le long du fil.
            cote = outward.cross(UP).normalized() * (1.0 if j % 2 else -1.0)
            Yl = (outward * (0.40 - 0.22 * s) + UP * (0.52 - 0.60 * s)
                  + T * 0.34 + cote * 0.46).normalized()
            Zl = (F - F.dot(Yl) * Yl)
            if Zl.length < 1e-4:
                Zl = UP
            Zl.normalize()
            Xl = Yl.cross(Zl)
            L = 0.30 + 0.10 * s
            Pp = P + Yl * 0.16
            objets.append(tube_along("Petiole_%02d_%d" % (idx + 1, j), [P, Pp],
                                     [0.016, 0.012], mat=mats["tige"], seg=8, cap=3))
            objets.append(make_leaf("Feuille_%02d_%d" % (idx + 1, j), Pp - Yl * 0.02,
                                    Xl, Yl, Zl, L=L, n_fentes=0, mat=mats["feuille"],
                                    n_trous=0, w_ratio=0.46))
    # Le dessus du pot n'est pas chauve : deux feuilles dressees au centre.
    for k, az in enumerate((60.0, 150.0, 240.0, 330.0)):
        a = radians(az)
        outward = Vector((cos(a), sin(a), 0.0))
        P = D + Vector((0.05 * cos(a), 0.05 * sin(a), sol - 0.02))
        Yl = (outward * 0.35 + UP * 0.85).normalized()
        F = (VUE * 0.75 + UP * 0.40).normalized()
        Zl = (F - F.dot(Yl) * Yl)
        if Zl.length < 1e-4:
            Zl = UP
        Zl.normalize()
        Xl = Yl.cross(Zl)
        Pp = P + Yl * 0.30
        objets.append(tube_along("Petiole_Haut_%d" % (k + 1), [P, Pp],
                                 [0.018, 0.014], mat=mats["tige"], seg=8, cap=3))
        objets.append(make_leaf("Feuille_Haut_%d" % (k + 1), Pp - Yl * 0.02,
                                Xl, Yl, Zl, L=0.40, n_fentes=0, mat=mats["feuille"],
                                n_trous=0, w_ratio=0.48))
    return objets


# ------------------------------------------------------------
# fern : des frondes divisees qui arquent vers l'exterieur
# ------------------------------------------------------------
def _pinnee(name, origine, direction, az, L, W, mats):
    """Une pinnule, en goutte : large au milieu, pointue aux deux bouts."""
    Y = Vector(direction).normalized()
    F = (VUE * 0.72 + UP * 0.44).normalized()
    Z = F - F.dot(Y) * Y
    if Z.length < 1e-4:
        Z = UP - UP.dot(Y) * Y
    Z.normalize()
    X = Y.cross(Z)

    def demi(t):
        return W * (t * (1.0 - t)) ** 0.5

    return limbe(name, (origine, X, Y, Z), demi, mats["feuille"], L=L, nu=24, ep=0.012, creux=0.10)


def _fronde(name, base, az, tilt, L, mats, n_paire=9):
    """Une fronde : son rachis, arque vers l'exterieur, et ses pinnules en
    deux ranges, plus courtes vers le bout."""
    a, t = radians(az), radians(tilt)
    horiz = Vector((cos(a), sin(a), 0.0))
    dirn = (horiz * cos(t) + UP * sin(t)).normalized()
    P0 = Vector(base)
    n = 18
    pts, rayons = [], []
    for k in range(n + 1):
        s = k / float(n)
        p = P0 + dirn * (L * s) + horiz * (0.30 * L * s * s) - UP * (0.22 * L * s * s)
        pts.append(p)
        rayons.append(0.018 * (1.0 - 0.7 * s) + 0.004)
    objets = [tube_along(name, pts, rayons, mat=mats["tige"], seg=8, cap=3)]
    tangentes = []
    for k in range(n):
        tangentes.append((pts[k + 1] - pts[k]).normalized())
    cote = horiz.cross(UP)
    if cote.length < 1e-3:
        cote = horiz.cross(Vector((1, 0, 0)))
    cote.normalize()
    for j in range(n_paire):
        s = (j + 1.6) / (n_paire + 1.2)
        P = pts[int(s * n)]
        T = tangentes[int(s * n) - 1]
        Lp = (0.34 - 0.24 * s) * L
        W = 0.16 * Lp
        for signe in (-1, 1):
            dpin = (cote * (1.0 if signe > 0 else -1) * 0.82 + T * 0.42 + UP * 0.10).normalized()
            objets += _pinnee("%s_P%d_%d" % (name, j, signe), P + dpin * 0.012, dpin, az, Lp, W, mats)
    return objets


def _fern(nom, mats, D, echelle_pot):
    objets = []
    sol = Z_TERRE * echelle_pot
    base = Vector((0, 0, sol - 0.01)) + D
    # (azimut, inclinaison, longueur) : une couronne de frondes.
    frondes = [
        (0.0, 38.0, 1.05),
        (33.0, 46.0, 0.88),
        (52.0, 30.0, 1.15),
        (85.0, 50.0, 0.82),
        (104.0, 42.0, 0.95),
        (156.0, 28.0, 1.10),
        (186.0, 48.0, 0.86),
        (208.0, 40.0, 1.00),
        (240.0, 52.0, 0.78),
        (262.0, 32.0, 1.12),
        (312.0, 44.0, 0.90),
    ]
    for idx, (az, tilt, L) in enumerate(frondes):
        objets += _fronde("Fronde_%02d" % (idx + 1), base, az, tilt, L, mats)
    return objets


# ------------------------------------------------------------
# rosette : des feuilles charnues en spirale, type echeveria/aloe
# ------------------------------------------------------------
def _feuille_charnue(name, base, az, tilt, L, W, courbure, mats, matiere="charnu", n=12):
    """Une feuille epaisse et pointue, un peu recourbee vers l'exterieur —
    la recette de la rosette du guide « offset »."""
    a = radians(az)
    horiz = Vector((cos(a), sin(a), 0.0))
    ti = radians(tilt)
    montee = (horiz * cos(ti) + UP * sin(ti)).normalized()
    pts, dl, de = [], [], []
    for k in range(n + 1):
        s = k / float(n)
        p = Vector(base) + montee * (L * s) + horiz * (courbure * L * s * s) - UP * (0.12 * courbure * L * s * s)
        pts.append(p)
        epaule = 0.42 + 0.58 * min(1.0, s * 6.0)
        dl.append(0.118 * W * ((1.0 - s) ** 0.62) * epaule)
        de.append(0.056 * W * ((1.0 - s) ** 0.70) * epaule)
    dl[-1] = de[-1] = 0.0
    return [ruban_along(name, pts, dl, de, face=UP, seg=14, mat=mats[matiere], cap_debut=0.4)]


# (azimut, inclinaison, longueur, largeur, courbure) — la rosette du guide,
# recentree sur le pot.
ROSETTE = [
    (18.0, 48.0, 1.04, 1.02, 0.32),
    (52.0, 54.0, 0.98, 0.99, 0.29),
    (76.0, 64.0, 0.88, 0.94, 0.24),
    (110.0, 51.0, 1.00, 1.00, 0.30),
    (142.0, 58.0, 0.96, 0.98, 0.28),
    (172.0, 66.0, 0.86, 0.92, 0.23),
    (205.0, 70.0, 0.82, 0.90, 0.20),
    (232.0, 60.0, 0.92, 0.95, 0.26),
    (256.0, 55.0, 0.94, 0.96, 0.30),
    (288.0, 68.0, 0.84, 0.89, 0.21),
    (312.0, 74.0, 0.76, 0.86, 0.18),
    (348.0, 82.0, 0.62, 0.80, 0.12),
]


def _rosette(nom, mats, D, echelle_pot):
    objets = []
    sol = Z_TERRE * echelle_pot
    base = Vector((0, 0, sol - 0.02)) + D
    for i, (az, tilt, L, W, courbure) in enumerate(ROSETTE):
        objets += _feuille_charnue("Rosette_%02d" % (i + 1), base, az, tilt, L * 0.75, W * 0.65, courbure, mats)
    # Le coeur, plus clair.
    objets += _feuille_charnue("Coeur", base, 40.0, 80.0, 0.38, 0.48, 0.06, mats, matiere="pousse", n=8)
    return objets


# ------------------------------------------------------------
# cactus : des raquettes plates qui montent, type opuntia
# ------------------------------------------------------------
def _raquette(name, base, az, tilt, L, W, ep, mats, n=10):
    """Une raquette : large au milieu, arrondie en haut, presque verticale
    ([tilt] s'en écarte, en degrés). Aplatie mais charnue, pas une lame."""
    a, t = radians(az), radians(tilt)
    horiz = Vector((cos(a), sin(a), 0.0))
    dirn = (horiz * sin(t) + UP * cos(t)).normalized()
    pts, dl, de = [], [], []
    for k in range(n + 1):
        s = k / float(n)
        p = Vector(base) + dirn * (L * s) + horiz * (0.10 * L * s * s)
        pts.append(p)
        dl.append(W * (s * (1.0 - s)) ** 0.45 if 0.0 < s < 1.0 else 0.0)
        de.append(ep * 0.72 * (1.0 - 0.25 * s))
    dl[0], dl[-1] = 0.004, 0.0
    return [ruban_along(name, pts, dl, de, face=(VUE + horiz * 0.6).normalized(), seg=16, mat=mats["charnu"],
                        cap_debut=0.6, cap_fin=0.5)]


def _cactus(nom, mats, D, echelle_pot):
    objets = []
    sol = Z_TERRE * echelle_pot
    # (azimut, écart à la verticale, hauteur, largeur, epaisseur) : des
    # raquettes dressées, legerement evasees.
    raquettes = [
        (0.0, 10.0, 0.95, 0.34, 0.10),
        (75.0, 14.0, 0.78, 0.30, 0.09),
        (140.0, 9.0, 0.86, 0.32, 0.095),
        (210.0, 7.0, 0.68, 0.28, 0.085),
        (265.0, 13.0, 0.60, 0.27, 0.082),
        (320.0, 12.0, 0.56, 0.26, 0.08),
    ]
    for idx, (az, tilt, L, W, ep) in enumerate(raquettes):
        a = radians(az)
        base = D + Vector((0.14 * cos(a), 0.14 * sin(a), sol - 0.02))
        objets += _raquette("Raquette_%02d" % (idx + 1), base, az, tilt, L, W, ep, mats, n=10)
    # Une petite raquette latérale sur la principale : l'opuntia se lit en
    # un coup d'oeil.
    base = D + Vector((0.14, 0.0, sol - 0.02)) + (UP * 0.42) + Vector((0.10, 0.0, 0.0))
    objets += _raquette("Raquette_Jeune", base, 40.0, 55.0, 0.34, 0.18, 0.07, mats, n=8)
    a2 = radians(140.0)
    base2 = D + Vector((0.14 * cos(a2), 0.14 * sin(a2), sol - 0.02)) + UP * 0.38
    objets += _raquette("Raquette_Jeune_2", base2, 195.0, 58.0, 0.28, 0.15, 0.062, mats, n=8)
    return objets


# ------------------------------------------------------------
# conifer : un tronc effile et ses etages de branches
# ------------------------------------------------------------
def _conifere(nom, mats, D, echelle_pot):
    """Un jeune conifere en pot.

    Trois cones empiles sur un baton donnaient un sapin de Noel en
    plastique : la silhouette d'un conifere ne tient pas au nombre de
    volumes mais a la suite serree d'etages qui retombent, du plus large en
    bas au plus fin au sommet, chacun legerement decale.
    """
    objets = []
    sol = Z_TERRE * echelle_pot
    base = D + Vector((0.0, 0.0, sol - 0.02))
    H = 1.52

    tronc_profil = [(0.0, 0.0), (0.062, 0.0), (0.068, 0.03), (0.050, 0.40),
                    (0.034, 0.72), (0.020, 0.92), (0.0, 1.0)]
    tronc = revolve("Tronc", [(r, z * H) for (r, z) in tronc_profil], 40,
                    [mats["tronc"]], 26.0)
    tronc.location = base
    objets.append(tronc)

    # Une jupe : elle part du tronc, descend jusqu'au bord, et revient par
    # le dessous — une coquille fine, pas une boule.
    jupe = [(0.0, 0.58), (0.30, 0.50), (0.62, 0.33), (0.86, 0.14), (1.0, 0.0),
            (0.90, 0.03), (0.64, 0.21), (0.32, 0.38), (0.0, 0.46)]
    n = 9
    for i in range(n):
        s_ = i / (n - 1.0)
        # Une variation tres faible : plus haut, les etages se mettaient a
        # tourner et l'arbre devenait une glace a l'italienne.
        r = (0.455 * (1.0 - s_) ** 0.82 + 0.055) * (1.0 + 0.025 * sin(i * 2.9))
        h = 0.30 * (1.0 - 0.42 * s_)
        z = (0.13 + 0.78 * s_) * H
        etage = revolve("Etage_%02d" % (i + 1),
                        [(rr * r, zz * h) for (rr, zz) in jupe], 44,
                        [mats["feuille"]], 30.0)
        # Un decalage infime par etage : sans lui, la pile est trop reguliere
        # pour etre un arbre.
        etage.location = base + Vector((0.008 * sin(i * 2.3),
                                        0.008 * cos(i * 1.7), z))
        objets.append(etage)

    # La fleche : le conifere finit en pointe, pas sur un etage tronque.
    fleche = revolve("Fleche", [(0.0, 0.0), (0.085, 0.02), (0.060, 0.09),
                                (0.028, 0.16), (0.0, 0.21)], 32,
                     [mats["feuille"]], 30.0)
    fleche.location = base + Vector((0.0, 0.0, 0.93 * H))
    objets.append(fleche)
    return objets


# ------------------------------------------------------------
# orchid : des feuilles larges, une hampe arquee et ses fleurs
# ------------------------------------------------------------
def _limbe_orchidee(name, base, az, tilt, L, W, mats, roulis=0.0, matiere="feuille",
                    retombee=0.34, ep=0.030):
    """Une feuille d'orchidee : large au milieu, creusee en gouttiere, la
    pointe qui retombe."""
    a = radians(az)
    horiz = Vector((cos(a), sin(a), 0.0))
    ti = radians(tilt)
    fil = (horiz * cos(ti) + UP * sin(ti)).normalized()
    repere = repere_face(base, fil, roulis=roulis, appoint=horiz, vers_camera=0.55)

    def demi(t):
        t = borne(t)
        return 0.30 * W * (t ** 0.30) * ((1.0 - t) ** 0.45)

    return limbe(name, repere, demi, mats[matiere], L=L, nu=40, M=10, ep=ep,
                 releve=lambda t: 0.16 * t - retombee * t * t, creux=0.24, bevel=0.016)


def _fleur_orchidee(nom, mats, centre, axe, taille=1.0):
    """Une fleur simple : cinq petales clairs autour d'un coeur ocre, la
    face tournee vers la camera comme le reste du decor."""
    A = Vector(axe).normalized()
    X = A.cross(VUE)
    if X.length < 1e-3:
        X = A.cross(UP)
    X.normalize()
    Y = A.cross(X).normalized()
    C = Vector(centre)
    objets = []
    for i in range(5):
        a = 2.0 * pi * i / 5.0 + 0.35
        sens = (X * cos(a) + Y * sin(a)).normalized()
        direction = (sens * 0.86 + A * 0.50).normalized()
        L = 0.150 * taille

        def demi(t):
            t = borne(t)
            return 0.62 * (t * (1.0 - t)) ** 0.25

        objets += limbe("%s_P%d" % (nom, i + 1),
                        repere_face(C + direction * (0.02 * taille), direction, vers_camera=0.92),
                        demi, mats["fleur"], L=L, nu=24, M=8, ep=0.012,
                        creux=0.10, bevel=0.006)
    objets.append(sphere(nom + "_Coeur", C + A * (0.024 * taille), 0.028 * taille,
                         mats["fleur_coeur"], seg=18, echelle=(1.0, 1.0, 0.55)))
    return objets


def _hampe_orchidee(mats, base, hauteur=1.02, port=0.28):
    """La hampe : une tige fine qui monte du coeur et s'arque vers la
    lumiere, portant trois fleurs ouvertes et un bouton."""
    a = radians(28.0)
    horiz = Vector((cos(a), sin(a), 0.0))
    droite = UP.cross(VUE).normalized()
    P0 = Vector(base) + UP * 0.05
    P1 = P0 + UP * (hauteur * 0.68)
    P2 = P0 + UP * hauteur + horiz * port
    n = 22
    pts, rayons = [], []
    for k in range(n + 1):
        t = k / float(n)
        pts.append(bezier(P0, P1, P2, t))
        rayons.append(0.024 * (1.0 - 0.58 * t) + 0.005)
    objets = [tube_along("Hampe", pts, rayons, mat=mats["tige"], seg=10, cap=3)]
    # Trois fleurs en quinconce sur le dernier tiers : chacune part d'un
    # court pedicelle vers la camera, ce qui les detache de la hampe.
    for i, (t, cote) in enumerate(((0.55, -1.0), (0.80, 1.0), (1.0, -0.55))):
        k = int(t * n)
        direction = (VUE * 0.78 + droite * (0.34 * cote) + UP * 0.22).normalized()
        C = pts[k] + direction * 0.130
        objets.append(tube_along("Pedicelle_%d" % (i + 1), [pts[k], C],
                                 [0.014, 0.010], mat=mats["tige"], seg=8, cap=3))
        axe = (VUE * 0.90 + UP * (0.20 * cote)).normalized()
        objets += _fleur_orchidee("Fleur_%d" % (i + 1), mats, C, axe, taille=1.30)
    bouton = pts[int(0.40 * n)]
    ax = (VUE * 0.74 + UP * 0.44).normalized()
    objets.append(sphere("Bouton", bouton + ax * 0.070, 0.045, mats["fleur"], seg=16,
                         echelle=(0.78, 0.78, 1.30)))
    return objets


def _orchid(nom, mats, D, echelle_pot):
    objets = []
    sol = Z_TERRE * echelle_pot
    base = D + Vector((0, 0, sol - 0.03))
    # Quatre feuilles etalees, deux de chaque cote de la hampe — une fleur
    # d'orchidee ne monte pas d'une rosette, elle pousse entre ses feuilles.
    feuilles = [
        (16.0, 30.0, 0.72, 1.24, -10.0),
        (66.0, 21.0, 0.60, 1.08, 6.0),
        (112.0, 24.0, 0.66, 1.16, 8.0),
        (158.0, 33.0, 0.70, 1.18, -9.0),
        (202.0, 34.0, 0.76, 1.22, -7.0),
        (248.0, 19.0, 0.58, 1.04, 11.0),
        (292.0, 26.0, 0.62, 1.12, 10.0),
        (338.0, 37.0, 0.68, 1.14, -5.0),
    ]
    for idx, (az, tilt, L, W, roulis) in enumerate(feuilles):
        objets += _limbe_orchidee("Feuille_%02d" % (idx + 1), base, az, tilt, L, W, mats, roulis=roulis)
    objets += _limbe_orchidee("Feuille_Coeur", base, 252.0, 58.0, 0.30, 0.56, mats, matiere="pousse")
    objets += _limbe_orchidee("Feuille_Coeur_2", base, 84.0, 64.0, 0.26, 0.48, mats, matiere="pousse")
    # Les racines aeriennes : c'est a elles qu'on reconnait une phalaenopsis
    # en pot, autant qu'a ses fleurs.
    for k, az in enumerate((40.0, 130.0, 226.0, 310.0)):
        a = radians(az)
        o = Vector((cos(a), sin(a), 0.0))
        d = base + o * 0.26 + UP * 0.10
        objets.append(tube_along("Racine_%d" % (k + 1),
                                 [base + o * 0.10 + UP * 0.12, d,
                                  d + o * 0.16 - UP * 0.14],
                                 [0.030, 0.026, 0.020], mat=mats["pousse"],
                                 seg=10, cap=3))
    objets += _hampe_orchidee(mats, base)
    return objets


# ------------------------------------------------------------
# la table de lancement
# ------------------------------------------------------------
PLANTES = {
    "monstera": (_en_feuilles, 1.0),
    "broad_leaf": (_en_feuilles, 0.92),
    "upright_leaf": (_upright, 0.92),
    "vine": (_vine, 0.80),
    "fern": (_fern, 0.85),
    "rosette": (_rosette, 0.55),
    "cactus": (_cactus, 0.75),
    "conifer": (_conifere, 0.80),
    "orchid": (_orchid, 0.80),
}


def construire(nom, position=(0.0, 0.0, 0.0)):
    """La plante [nom], en pot, les pieds a [position], a l'echelle de la
    piece : les recettes sont baties a leur taille d'icone, puis tout
    l'assemblage est reduit autour de [position] — le point que
    l'application pose sur l'emplacement."""
    batisseur, echelle = PLANTES[nom]
    D = Vector(position)
    mats = _materiaux(nom)
    objets = _pot_et_terre(mats, echelle, D)
    objets += batisseur(nom, mats, D, echelle)
    for ob in objets:
        ob.scale = ob.scale * ECHELLE_PIECE
        ob.location = D + (ob.location - D) * ECHELLE_PIECE
    return objets
