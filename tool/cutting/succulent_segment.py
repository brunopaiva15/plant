# ============================================================
# succulent_segment — la bouture de segment.
#
# La plante : un cactus a segments plats articules, type cactus de Noel. Pas
# de feuille, pas de noeud : des raquettes charnues emboitees bout a bout.
# Le geste tient en deux temps — detacher, puis laisser secher —, et c'est
# le sechage qui doit se voir, faute de quoi le segment pourrit en terre.
#
# Ce que l'utilisateur doit comprendre :
#   1. qu'on prend un segment terminal, ferme et sain ;
#   2. qu'on le detache a l'articulation, en le tournant, sans ciseaux ;
#   3. a quoi ressemble une plaie fraiche ;
#   4. que la plaie doit secher avant d'aller en terre ;
#   5. qu'on l'enfonce a peine, dans un substrat tres drainant ;
#   6. que les racines viennent d'abord, le nouveau segment ensuite.
# ============================================================
from mathutils import Matrix, Vector
from math import cos, radians, sin

from .common import (
    DROITE, UP, VUE,
    adouci, creux_pot, faisceau_racines, limbe, marque, melange, pivote, plaie_ovale,
    pot_et_terre, rebond, repere_face, z_terre,
)

L_SEG = 0.52


def _profil_raquette(t):
    """Une raquette : un peu pincee au depart, large au milieu, coupee net
    au bout — et deux crans sur les bords, comme les segments d'un cactus
    de Noel."""
    t = min(max(t, 0.0), 1.0)
    base = 0.255 * (0.34 + 0.66 * min(1.0, (t / 0.20) ** 0.7)) * (1.0 - 0.30 * t * t)
    for c in (0.42, 0.78):
        base *= 1.0 - 0.16 * max(0.0, 1.0 - ((t - c) / 0.055) ** 2)
    return base


def raquette(name, base, direction, roulis, L, mats, matiere="cactus", ep=0.075, t0=0.0):
    repere = repere_face(base, direction, roulis=roulis, vers_camera=0.66)
    return limbe(name, repere, _profil_raquette, mats[matiere], L=L, t0=t0, nu=34, M=9, ep=ep,
                 releve=lambda t: 0.0, creux=0.10, bevel=0.022)


def plaie_segment(name, base, direction, roulis, L, sechage, ep=0.075, serre=None):
    """La tranche de l'articulation : un ovale pose dans le plan de la
    section, qui pale et se mate en sechant. Pas de realisme, une matiere
    qui change — mais assez grande pour se voir sur un telephone."""
    _, X, Y, Z = repere_face(base, direction, roulis=roulis, vers_camera=0.66)
    # Un cal se resserre en sechant : la tranche perd un rien de sa largeur.
    k = melange(1.10, 0.96, sechage if serre is None else serre)
    return plaie_ovale(name, Vector(base), Y, Z, _profil_raquette(0.07) * L * k, ep * 0.58 * k, sechage)


# La chaine de segments : (azimut, inclinaison, roulis, longueur relative).
# Trois branches qui partent de la terre, la plus haute portant le segment
# qu'on prend.
def _dir(az, tilt):
    a, ti = radians(az), radians(tilt)
    return Vector((cos(a) * cos(ti), sin(a) * cos(ti), sin(ti)))


TIGE_HERO = [(22.0, 84.0, -4.0, 1.00), (34.0, 70.0, 6.0, 0.96), (46.0, 52.0, -8.0, 0.92), (58.0, 32.0, 4.0, 0.86)]
TIGES_AUTRES = [
    [(190.0, 86.0, 5.0, 0.98), (204.0, 66.0, -6.0, 0.92), (216.0, 44.0, 8.0, 0.84)],
    [(292.0, 82.0, -6.0, 0.94), (306.0, 58.0, 7.0, 0.86)],
]

Z_SOL = z_terre(0.82)
BASE = Vector((0.0, 0.0, Z_SOL - 0.06))
# Le segment qu'on detache : le dernier de la branche haute.
CHOISI = 3


def chaine(prefix, mats, depart, segments, jusqu_a=None, matiere="cactus"):
    """Une branche : les raquettes bout a bout. Rend (objets, articulations)
    — les points ou deux segments se touchent."""
    objets, points = [], []
    p = Vector(depart)
    for i, (az, tilt, roulis, L) in enumerate(segments):
        d = _dir(az, tilt)
        points.append((p.copy(), d, roulis, L_SEG * L))
        if jusqu_a is None or i < jusqu_a:
            objets += raquette("%s_S%d" % (prefix, i), p, d, roulis, L_SEG * L, mats, matiere=matiere)
        p = p + d * (L_SEG * L * 0.96)
    return objets, points


def plante(mats, mats_sans=None, jusqu_a=None):
    objets = pot_et_terre(mats, 0.82, terre="terre_drainante")
    for i, segs in enumerate(TIGES_AUTRES):
        objets += chaine("Tige%d" % (i + 2), mats, BASE, segs)[0]
    hero, points = chaine("Tige1", mats, BASE, TIGE_HERO, jusqu_a=jusqu_a)
    return objets + hero, points


def _articulation():
    _, points = chaine("X", None, BASE, TIGE_HERO, jusqu_a=0)
    return points[CHOISI]


# ------------------------------------------------------------
# les six etapes
# ------------------------------------------------------------
def etape_choose_segment(mats, f):
    # Le segment terminal, ferme et sain, est designe.
    objets, points = plante(mats)
    p, d, _, L = points[CHOISI]
    objets += marque("Marque_Segment", p + d * (L * 0.5) + VUE * 0.30, 0.26, mats["anneau"],
                     taille=rebond((f - 0.06) / 0.54))
    return objets


def etape_cut(mats, f):
    # On le tourne d'un quart et il vient : un segment se detache a
    # l'articulation, il ne se coupe pas.
    p, d, roulis, L = _articulation()
    torsion = adouci(f / 0.34)
    depart = adouci((f - 0.34) / 0.56)
    objets, _ = plante(mats, jusqu_a=CHOISI)
    M = pivote(p, d, 34.0 * torsion) \
        @ Matrix.Translation((d * 0.22 + UP * 0.10 + DROITE * 0.08) * depart) \
        @ pivote(p, VUE, -16.0 * depart)
    piece = raquette("Detache", p, d, roulis, L, mats)
    piece += plaie_segment("PlaieDetache", p, d, roulis, L, 0.0)
    for ob in piece:
        ob.matrix_world = M @ ob.matrix_world
    return objets + piece


# Le segment seul. Tenu, il s'ecarte de la camera en montant : sa tranche
# regarde alors l'objectif, et c'est elle qu'on vient voir. Plante, il se
# redresse et sa tranche disparait sous le substrat — c'est la le geste.
SEUL = Vector((0.0, 0.0, 0.0))
DIR_TENU = (UP * 0.78 - VUE * 0.46 + DROITE * 0.18).normalized()
DIR_PLANTE = _dir(64.0, 84.0)
SEUL_L = L_SEG * TIGE_HERO[CHOISI][3] * 1.32


def _seul(mats, sechage, direction=None, matiere="cactus", roulis=-12.0):
    direction = direction if direction is not None else DIR_TENU
    objets = raquette("Segment", SEUL, direction, roulis, SEUL_L, mats, matiere=matiere)
    objets += plaie_segment("Plaie", SEUL, direction, roulis, SEUL_L, sechage)
    return objets


def etape_fresh_cut(mats, f):
    # Le segment se retourne pour montrer sa tranche : fraiche, tendre,
    # encore verte. C'est cet etat qu'il faut savoir reconnaitre.
    M = pivote(SEUL, UP, -24.0 * adouci(f / 0.66))
    objets = _seul(mats, 0.0)
    for ob in objets:
        ob.matrix_world = M @ ob.matrix_world
    objets += marque("Marque_Plaie", SEUL + VUE * 0.24, 0.20, mats["anneau"], epaisseur=0.020,
                     taille=rebond((f - 0.40) / 0.36))
    return objets


def etape_callus(mats, f):
    # Quelques jours passent : la plaie pale, se mate, et forme un cal. Le
    # segment ne bouge pas — c'est la matiere qui raconte l'attente.
    M = pivote(SEUL, UP, -24.0)
    objets = _seul(mats, adouci((f - 0.10) / 0.76))
    for ob in objets:
        ob.matrix_world = M @ ob.matrix_world
    return objets


ECH_POT = 0.48


def etape_substrate(mats, f):
    # A peine enfonce, dans un substrat tres drainant : un segment couche a
    # plat ou enterre pourrit.
    descente = adouci(f / 0.74)
    sol = z_terre(ECH_POT)
    M = Matrix.Translation(UP * (sol - 0.05 + 0.44 * (1.0 - descente)))
    objets = pot_et_terre(mats, ECH_POT, terre="terre_drainante")
    piece = _seul(mats, 1.0, direction=DIR_PLANTE)
    for ob in piece:
        ob.matrix_world = M @ ob.matrix_world
    return objets + piece


def etape_roots(mats, f):
    sol = z_terre(ECH_POT)
    M = Matrix.Translation(UP * (sol - 0.05))
    objets = pot_et_terre(mats, ECH_POT, terre="terre_drainante")
    piece = _seul(mats, 1.0, direction=DIR_PLANTE)
    # Le nouveau segment bourgeonne au bout, plus clair que son porteur.
    neuf = adouci((f - 0.48) / 0.50)
    if neuf > 0.03:
        bout = SEUL + DIR_PLANTE * (SEUL_L * 0.94)
        piece += raquette("Neuf", bout, _dir(78.0, 58.0), 8.0, SEUL_L * 0.62 * neuf, mats,
                          matiere="pousse", ep=0.062)
    for ob in piece:
        ob.matrix_world = M @ ob.matrix_world
    # Les racines courent sous la surface du substrat plutot que de plonger :
    # c'est ce qu'elles font vraiment, et c'est la seule facon de les voir.
    objets += faisceau_racines("Racine", M @ SEUL + UP * 0.075, -UP, mats, adouci(f / 0.66),
                               brins=5, longueur=0.22, epaisseur=0.018, matiere="racine_fine",
                               graine=6, ecart=1.2, seg=8, aplati=0.16, dans=creux_pot(ECH_POT))
    return objets + piece


PACK = "succulent_segment"
ETAPES = [
    ("choose_segment", 26, etape_choose_segment, (0.0, 1.0)),
    ("cut", 30, etape_cut, (0.0, 0.34, 1.0)),
    ("fresh_cut", 24, etape_fresh_cut, (0.0, 1.0)),
    ("callus", 24, etape_callus, (0.0, 1.0)),
    ("substrate", 26, etape_substrate, (0.0, 1.0)),
    ("roots", 30, etape_roots, (0.0, 1.0)),
]
