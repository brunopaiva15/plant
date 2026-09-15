# ============================================================
# leaf_cutting — la bouture de feuille.
#
# La plante : une touffe de feuilles en glaive, type sansevieria. Pas de
# tige : des lames epaisses et droites qui sortent de terre. C'est la ou le
# geste de la bouture de feuille se lit le mieux — et ou l'orientation du
# segment compte, puisqu'un morceau plante a l'envers ne racinera jamais.
#
# Ce que l'utilisateur doit comprendre :
#   1. qu'on prend une feuille mature, pas la plus jeune ;
#   2. qu'on la coupe a sa base, proprement ;
#   3. qu'on peut la partager en segments — et que le V taille en bas de
#      chacun dit quel bout va en terre ;
#   4. que la coupe seche avant d'etre plantee ;
#   5. que le V s'enfonce de deux ou trois centimetres, jamais l'inverse ;
#   6. que les racines viennent d'abord, la jeune pousse ensuite.
# ============================================================
from mathutils import Matrix, Vector
from math import cos, radians, sin

from .common import (
    DROITE, UP, VUE,
    adouci, creux_pot, faisceau_racines, geste_ciseaux, limbe, marque, materiau_plaie,
    melange, pivote, pot_et_terre, rebond, repos, repere_face, z_terre,
)

# Une lame : (azimut, inclinaison, longueur, largeur, roulis).
TOUFFE = [
    (200.0, 86.0, 1.36, 1.00, -7.0),
    (150.0, 80.0, 1.12, 0.92, 9.0),
    (20.0, 84.0, 1.54, 1.06, 5.0),
    (330.0, 78.0, 0.96, 0.86, -12.0),
    (65.0, 82.0, 1.24, 0.94, 12.0),
]
# La lame qu'on prend : la troisieme, la plus haute et la plus large.
CHOISIE = 2


def _profil_glaive(W):
    """Etroit au pied, large au milieu haut, une pointe franche : la
    silhouette d'une feuille en glaive."""
    def demi(t):
        t = min(max(t, 0.0), 1.0)
        montee = min(1.0, (t / 0.16) ** 0.8)
        chute = (1.0 - t) ** 0.45
        return 0.074 * W * montee * chute / 0.86

    return demi


def _repere_lame(base, az, tilt, roulis):
    a = radians(az)
    horiz = Vector((cos(a), sin(a), 0.0))
    ti = radians(tilt)
    fil = (horiz * cos(ti) + UP * sin(ti)).normalized()
    return repere_face(base, fil, roulis=roulis, appoint=horiz, vers_camera=0.50)


def lame_feuille(name, base, az, tilt, L, W, roulis, mats, t0=0.0, t1=1.0, encoche=0.0,
                 matiere="feuille", ep=0.052):
    """Une lame de sansevieria, ou l'un de ses segments ([t0], [t1]).
    [encoche] creuse le V de la base."""
    return limbe(name, _repere_lame(base, az, tilt, roulis), _profil_glaive(W), mats[matiere],
                 L=L, t0=t0, t1=t1, nu=46, M=9, ep=ep, encoche=encoche,
                 releve=lambda t: 0.05 * t * t, creux=0.26, bevel=0.016)


def plaie(name, base, az, tilt, L, W, roulis, t0, sechage, encoche=0.0):
    """La tranche fraiche d'une coupe : une lamelle posee sous le segment,
    de la couleur de la plaie, qui pale en sechant."""
    mat = materiau_plaie(sechage)
    return limbe(name, _repere_lame(base, az, tilt, roulis), _profil_glaive(W), mat,
                 L=L, t0=t0 - 0.030, t1=t0 + 0.008, nu=5, M=9, ep=0.058, encoche=encoche,
                 releve=lambda t: 0.05 * t * t, creux=0.26, bevel=0.010)


ECH_TOUFFE = 0.82
Z_SOL = z_terre(ECH_TOUFFE)
BASE_TOUFFE = Vector((0.0, 0.0, Z_SOL - 0.04))


def touffe(mats, sauf=None, pousse=1.0, base=None, feuilles=None):
    base = base if base is not None else BASE_TOUFFE
    objets = []
    for i, (az, tilt, L, W, roulis) in enumerate(feuilles or TOUFFE):
        if sauf is not None and i == sauf:
            continue
        objets += lame_feuille("Lame%d" % i, base + Vector((0.10 * cos(radians(az)), 0.10 * sin(radians(az)), 0.0)),
                               az, tilt, L * pousse, W, roulis, mats)
    return objets


def _pied(i):
    az = TOUFFE[i][0]
    return BASE_TOUFFE + Vector((0.10 * cos(radians(az)), 0.10 * sin(radians(az)), 0.0))


# ------------------------------------------------------------
# 1. choisir la feuille
# ------------------------------------------------------------
def etape_choose_leaf(mats, f):
    objets = pot_et_terre(mats, ECH_TOUFFE) + touffe(mats)
    az, tilt, L, W, roulis = TOUFFE[CHOISIE]
    centre = _pied(CHOISIE) + UP * (L * 0.52) + VUE * 0.34
    objets += marque("Marque_Lame", centre, 0.30, mats["anneau"], taille=rebond((f - 0.22) / 0.38))
    return objets


# ------------------------------------------------------------
# 2. couper la feuille a sa base
# ------------------------------------------------------------
def etape_cut_leaf(mats, f):
    az, tilt, L, W, roulis = TOUFFE[CHOISIE]
    pied = _pied(CHOISIE)
    coupe_z = 0.13
    cible = pied + UP * (L * coupe_z)
    lames, coupe = geste_ciseaux(mats, cible, DROITE, f, echelle=0.86,
                                 arrivee=DROITE * 0.95 + UP * 0.30, sortie=DROITE * 0.35 + UP * 0.95)
    objets = pot_et_terre(mats, ECH_TOUFFE) + touffe(mats, sauf=CHOISIE)
    objets += lame_feuille("Souche", pied, az, tilt, L, W, roulis, mats, t1=coupe_z - (0.01 if coupe else 0.0))
    if not coupe:
        return objets + lame_feuille("Choisie", pied, az, tilt, L, W, roulis, mats, t0=coupe_z) + lames
    # Coupee, la feuille se souleve — et sa tranche fraiche part avec elle.
    levee = adouci((f - 0.52) / 0.44)
    M = Matrix.Translation((UP * 0.34 + DROITE * 0.16) * levee) @ pivote(cible, VUE, -10.0 * levee)
    haut = lame_feuille("Choisie", pied, az, tilt, L, W, roulis, mats, t0=coupe_z + 0.012)
    haut += plaie("Plaie", pied, az, tilt, L, W, roulis, coupe_z + 0.012, 0.0)
    for ob in haut:
        ob.matrix_world = M @ ob.matrix_world
    return objets + haut + lames


# ------------------------------------------------------------
# 3. partager la lame en segments
# ------------------------------------------------------------
# La lame posee seule, droite, pour le partage. Les segments gardent l'ordre
# du pied vers la pointe : c'est ce qui rend l'orientation lisible.
SEUL_AZ, SEUL_TILT, SEUL_L, SEUL_W, SEUL_ROULIS = 26.0, 89.0, 1.50, 1.04, 0.0
SEUL_BASE = Vector((0.0, 0.0, 0.0))
COUPES = [0.10, 0.40, 0.70, 1.0]
ENCOCHE = 0.055
# Ou chaque segment part une fois range en rangee, de gauche a droite.
RANGEE = [-0.34, 0.0, 0.34]


def segment(name, i, mats, M=None, encoche=ENCOCHE, matiere="feuille", sechage=None, base=None):
    t0, t1 = COUPES[i], COUPES[i + 1]
    base = base if base is not None else SEUL_BASE
    objets = lame_feuille(name, base, SEUL_AZ, SEUL_TILT, SEUL_L, SEUL_W, SEUL_ROULIS, mats,
                          t0=t0, t1=t1, encoche=encoche, matiere=matiere)
    if sechage is not None:
        objets += plaie(name + "_Plaie", base, SEUL_AZ, SEUL_TILT, SEUL_L, SEUL_W, SEUL_ROULIS,
                        t0, sechage, encoche=encoche)
    if M is not None:
        for ob in objets:
            ob.matrix_world = M @ ob.matrix_world
    return objets


def _en_rangee(i, part, hauteur=0.0):
    """Le segment [i] quitte la lame et vient se ranger : il descend a la
    hauteur de ses voisins et s'ecarte, sans jamais se retourner."""
    depart = SEUL_L * COUPES[i]
    return Matrix.Translation(DROITE * (RANGEE[i] * part) + UP * ((hauteur - depart) * part))


def etape_prepare(mats, f):
    # La lame se partage en trois, puis les segments viennent en rangee.
    partage = adouci(f / 0.30)
    rangement = repos(adouci((f - 0.26) / 0.70), 2.2)
    objets = []
    for i in range(3):
        # Les coupes s'ouvrent d'abord dans l'axe de la lame ; les segments
        # viennent en rangee ensuite, et l'ecart se referme alors.
        ecart = Matrix.Translation(UP * (0.12 * i * partage * (1.0 - rangement)))
        objets += segment("Seg%d" % i, i, mats, M=_en_rangee(i, rangement, hauteur=0.10) @ ecart,
                          encoche=ENCOCHE * partage)
    return objets


# ------------------------------------------------------------
# 4. laisser secher la coupe
# ------------------------------------------------------------
def etape_callus(mats, f):
    # Les trois plaies palissent et se matent : la coupe a seche.
    sechage = adouci((f - 0.12) / 0.74)
    objets = []
    for i in range(3):
        objets += segment("Seg%d" % i, i, mats, M=_en_rangee(i, 1.0, hauteur=0.10), sechage=sechage)
    objets += marque("Marque_Plaie", Vector((0, 0, 0.11)) + VUE * 0.30, 0.15, mats["anneau"],
                     epaisseur=0.019, taille=melange(1.0, 0.0, adouci((f - 0.64) / 0.28)))
    return objets


# ------------------------------------------------------------
# 5. planter le V dans un substrat drainant
# ------------------------------------------------------------
ECH_POT = 0.76


def etape_substrate(mats, f):
    # Les segments descendent, V en bas, deux ou trois centimetres sous le
    # substrat. Jamais l'inverse : c'est tout l'objet de cette etape.
    descente = adouci(f / 0.76)
    sol = z_terre(ECH_POT)
    objets = pot_et_terre(mats, ECH_POT, terre="terre_drainante")
    for i in range(3):
        cible = sol - 0.10 + 0.40 * (1.0 - descente)
        objets += segment("Seg%d" % i, i, mats, M=_en_rangee(i, 1.0, hauteur=cible), sechage=1.0)
    return objets


# ------------------------------------------------------------
# 6. racines puis jeune pousse
# ------------------------------------------------------------
def etape_new_growth(mats, f):
    sol = z_terre(ECH_POT)
    objets = pot_et_terre(mats, ECH_POT, terre="terre_drainante")
    for i in range(3):
        objets += segment("Seg%d" % i, i, mats, M=_en_rangee(i, 1.0, hauteur=sol - 0.10), sechage=1.0)
        # Les racines courent sous la surface plutot que de plonger : c'est
        # ce qu'elles font, et c'est la seule facon qu'elles se voient.
        objets += faisceau_racines("Racine%d" % i, Vector((RANGEE[i], 0.0, sol + 0.012)), -UP, mats,
                                   adouci(f / 0.66), brins=3, longueur=0.20, epaisseur=0.018,
                                   matiere="racine_fine", graine=i, ecart=1.2, aplati=0.16,
                                   dans=creux_pot(ECH_POT))
    # La jeune pousse sort du substrat a cote du segment du milieu : une
    # bouture de feuille ne repart pas de la feuille, elle en fait une neuve.
    pousse = adouci((f - 0.46) / 0.52)
    if pousse > 0.02:
        for k, (az, h) in enumerate(((60.0, 0.46), (18.0, 0.32))):
            objets += lame_feuille("Pousse%d" % k, Vector((RANGEE[1] + 0.17, 0.04, sol - 0.02)),
                                   az, 87.0, h * pousse, 0.62, 4.0 * k, mats, matiere="pousse", ep=0.040)
    return objets


PACK = "leaf_cutting"
ETAPES = [
    ("choose_leaf", 26, etape_choose_leaf, (0.0, 1.0)),
    ("cut_leaf", 34, etape_cut_leaf, (0.0, 0.30, 0.46, 1.0)),
    ("prepare", 30, etape_prepare, (0.0, 0.30, 1.0)),
    ("callus", 24, etape_callus, (0.0, 1.0)),
    ("substrate", 28, etape_substrate, (0.0, 1.0)),
    ("new_growth", 30, etape_new_growth, (0.0, 1.0)),
]
