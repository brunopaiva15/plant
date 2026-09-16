# ============================================================
# keiki — separer le rejet d'une orchidee.
#
# La plante : un phalaenopsis en pot, ses feuilles larges et charnues, sa
# hampe fleurie. Le rejet ne pousse pas au pied comme celui d'un aloe : il
# nait sur un noeud de la hampe, au-dessus de la terre, et fait ses racines
# en l'air.
#
# Ce que l'utilisateur doit comprendre :
#   1. a quoi ressemble un keiki assez developpe pour partir ;
#   2. que ses racines aériennes doivent s'allonger avant la separation ;
#   3. qu'on coupe la hampe de part et d'autre, jamais qu'on arrache ;
#   4. que le keiki part avec ses racines, sa petite base de hampe comprise ;
#   5. qu'un petit pot d'ecorces suffit, base affleurante ;
#   6. a quoi ressemble une reprise.
# ============================================================
from mathutils import Matrix, Vector
from math import atan2, cos, degrees, pi, radians, sin

from .common import (
    DROITE, UP, VUE,
    adouci, bezier, borne, creux_pot, faisceau_racines, geste_ciseaux, limbe, marque,
    melange, pivote, plaie_ovale, pot_et_terre, rebond, repos, repere_face, sphere,
    tube_along, z_terre,
)

# ------------------------------------------------------------
# la plante mere
# ------------------------------------------------------------
ECH_POT = 0.68
Z_SOL = z_terre(ECH_POT)
BASE = Vector((0.0, 0.0, Z_SOL - 0.02))

# La hampe, tracee une fois : son point et sa tangente servent partout.
HAMPE_H = 1.00
P0 = BASE + UP * 0.05
P1 = P0 + UP * (HAMPE_H * 0.62) + DROITE * 0.02
P2 = P0 + UP * HAMPE_H + DROITE * 0.27

# Le noeud du keiki, et les deux coupes qui l'encadrent.
T_KEIKI = 0.44
T_LO, T_HI = T_KEIKI - 0.075, T_KEIKI + 0.075

# Dehors de la hampe, cote camera : le keiki ne passe jamais derriere.
SENS = (VUE * 0.66 + DROITE * 0.75).normalized()
AZ_SENS = degrees(atan2(SENS.y, SENS.x))
SENS_RACINE = (SENS * 0.55 - UP * 0.84).normalized()


def _pt(t):
    return bezier(P0, P1, P2, t)


def _tang(t, eps=0.012):
    return (_pt(min(1.0, t + eps)) - _pt(max(0.0, t - eps))).normalized()


def _rayon(t):
    return 0.022 * (1.0 - 0.55 * t) + 0.005


def _portion(nom, t0, t1, mats, decalage=None, cap=2, n=16):
    """Un morceau de hampe entre deux hauteurs. Les bouts d'une coupe
    restent presque francs : la plaie pose dessus suffit a les lire."""
    D = Vector(decalage) if decalage is not None else Vector((0.0, 0.0, 0.0))
    pts, rayons = [], []
    for k in range(n + 1):
        t = t0 + (t1 - t0) * k / float(n)
        pts.append(_pt(t) + D)
        rayons.append(_rayon(t))
    return tube_along(nom, pts, rayons, mat=mats["tige"], seg=10, cap=cap)


def _plaie(nom, t, sechage, mats, decalage=None):
    """La tranche d'une coupe de hampe, vue de face : fraiche puis seche."""
    D = Vector(decalage) if decalage is not None else Vector((0.0, 0.0, 0.0))
    r = _rayon(t)
    return plaie_ovale(nom, _pt(t) + D, _tang(t), VUE, r * 1.15, r * 1.15, sechage)


def _pose(objets, M):
    if M is None:
        return objets
    for ob in objets:
        ob.matrix_world = M @ ob.matrix_world
    return objets


# ------------------------------------------------------------
# les feuilles et les fleurs
# ------------------------------------------------------------
def feuille_orchidee(name, base, az, tilt, L, W, mats, roulis=0.0, matiere="feuille",
                     retombee=0.34, ep=0.030):
    """Une feuille d'orchidee : large au milieu, creusee en gouttiere, la
    pointe qui retombe — la recette de la silhouette de la scene d'entretien."""
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


def feuilles_mere(mats, base=None):
    base = base if base is not None else BASE
    objets = []
    feuilles = [
        (16.0, 20.0, 0.68, 1.24, -10.0),
        (112.0, 16.0, 0.62, 1.16, 8.0),
        (202.0, 24.0, 0.72, 1.22, -7.0),
        (292.0, 18.0, 0.58, 1.12, 10.0),
    ]
    for idx, (az, tilt, L, W, roulis) in enumerate(feuilles):
        objets += feuille_orchidee("Feuille_%02d" % (idx + 1), base, az, tilt, L, W, mats, roulis=roulis)
    objets += feuille_orchidee("Feuille_Coeur", base, 252.0, 46.0, 0.30, 0.56, mats, matiere="pousse")
    return objets


def fleur_orchidee(nom, mats, centre, axe, taille=1.0):
    """Une fleur simple : cinq petales clairs autour d'un coeur ocre."""
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


def fleurs_hampe(mats):
    """Les fleurs du haut de hampe, en quinconce, chacune sur son pedicelle.
    Le guide montre un keiki : deux fleurs suffisent, elles ne doivent pas
    manger la place du jeune plant."""
    droite = UP.cross(VUE).normalized()
    objets = []
    for i, (t, cote) in enumerate(((0.86, -1.0), (1.0, 0.75))):
        P = _pt(t)
        direction = (VUE * 0.78 + droite * (0.34 * cote) + UP * 0.22).normalized()
        C = P + direction * 0.130
        objets.append(tube_along("Pedicelle_%d" % (i + 1), [P, C],
                                 [0.013, 0.009], mat=mats["tige"], seg=8, cap=2))
        axe = (VUE * 0.90 + UP * (0.20 * cote)).normalized()
        objets += fleur_orchidee("Fleur_%d" % (i + 1), mats, C, axe, taille=1.30)
    bouton = _pt(0.68)
    ax = (VUE * 0.74 + UP * 0.44).normalized()
    objets.append(sphere("Bouton", bouton + ax * 0.070, 0.040, mats["fleur"], seg=16,
                         echelle=(0.78, 0.78, 1.30)))
    return objets


# ------------------------------------------------------------
# le keiki
# ------------------------------------------------------------
KEIKI_BASE = _pt(T_KEIKI) + SENS * 0.060


def keiki_rosette(mats, base, echelle=1.0, racines=0.0, dans=None, coeur=0.0, M=None):
    """Le jeune plant : deux ou trois petites feuilles et ses racines
    aériennes, qui pendent le long de la hampe."""
    base = Vector(base)
    objets = []
    feuilles = [
        (AZ_SENS - 48.0, 34.0, 0.300, 1.00, -10.0),
        (AZ_SENS + 40.0, 26.0, 0.340, 1.05, 12.0),
        (AZ_SENS - 4.0, 42.0, 0.250, 0.90, 0.0),
    ]
    for idx, (az, tilt, L, W, roulis) in enumerate(feuilles):
        objets += feuille_orchidee("Keiki_F%02d" % (idx + 1), base, az, tilt,
                                   L * echelle, W, mats, roulis=roulis,
                                   matiere="pousse", ep=0.024, retombee=0.52)
    if coeur > 0.02:
        objets += feuille_orchidee("Keiki_Coeur", base, AZ_SENS + 4.0, 66.0,
                                   0.120 * echelle * coeur, 0.80, mats, matiere="pousse", ep=0.020)
    if racines > 0.0:
        objets += faisceau_racines("RacineKeiki", base - UP * 0.012, SENS_RACINE, mats,
                                   racines, brins=4, longueur=0.30, epaisseur=0.019,
                                   matiere="racine_fine", graine=3, ecart=1.2, aplati=0.45,
                                   dans=dans)
    return _pose(objets, M)


def morceau_keiki(mats, origine, echelle=1.0, racines=0.0, sechage=1.0, dans=None, coeur=0.0, M=None):
    """Le keiki et le court morceau de hampe qu'il garde sous lui : c'est
    ainsi qu'il se presente une fois detache."""
    D = Vector(origine) - KEIKI_BASE
    objets = [_portion("Hampe_Keiki", T_LO, T_HI, mats, decalage=D)]
    objets += _plaie("Plaie_Keiki_Bas", T_LO, sechage, mats, decalage=D)
    objets += _plaie("Plaie_Keiki_Haut", T_HI, sechage, mats, decalage=D)
    objets += keiki_rosette(mats, Vector(origine), echelle=echelle, racines=racines,
                            dans=dans, coeur=coeur)
    return _pose(objets, M)


# ------------------------------------------------------------
# la plante entiere, entiere ou coupee
# ------------------------------------------------------------
def plante_mere(mats, keiki=1.0, racines=0.0, coupe=0, sechage=0.0, M_keiki=None, coeur=0.0):
    """[coupe] : 0 hampe entiere, 1 coupee au-dessus du keiki, 2 coupee des
    deux cotes. [M_keiki] emporte le morceau detache."""
    objets = pot_et_terre(mats, ECH_POT)
    objets += feuilles_mere(mats)
    if coupe == 0:
        objets.append(_portion("Hampe", 0.0, 1.0, mats))
        objets += fleurs_hampe(mats)
        objets += keiki_rosette(mats, KEIKI_BASE, echelle=keiki, racines=racines, coeur=coeur)
        return objets
    if coupe == 1:
        objets.append(_portion("Hampe_Basse", 0.0, T_HI, mats, cap=1))
        objets.append(_portion("Hampe_Haute", T_HI, 1.0, mats))
        objets += _plaie("Plaie_Coupe", T_HI, sechage, mats)
        objets += fleurs_hampe(mats)
        objets += keiki_rosette(mats, KEIKI_BASE, echelle=keiki, racines=racines, coeur=coeur)
        return objets
    objets.append(_portion("Hampe_Basse", 0.0, T_LO, mats, cap=1))
    objets += _plaie("Plaie_Basse", T_LO, sechage, mats)
    objets.append(_portion("Hampe_Haute", T_HI, 1.0, mats))
    objets += _plaie("Plaie_Haute", T_HI, sechage, mats)
    objets += fleurs_hampe(mats)
    objets += morceau_keiki(mats, KEIKI_BASE, echelle=keiki, racines=racines,
                            sechage=sechage, coeur=coeur, M=M_keiki)
    return objets


def _axe_lame(T):
    """L'axe des lames pour couper une hampe : en travers d'elle, vers le
    bas — les ciseaux se lisent toujours du meme cote."""
    Y = Vector(T).cross(VUE).normalized()
    if Y.dot(UP) > 0:
        Y = -Y
    return Y


# ------------------------------------------------------------
# les six etapes
# ------------------------------------------------------------
def etape_identify_keiki(mats, f):
    # Le keiki grossit sur son noeud, puis l'anneau le designe : un keiki
    # bon a prendre a ses feuilles et le debut de ses racines.
    pousse = melange(0.55, 1.0, adouci(f / 0.50))
    racines = 0.28 * adouci((f - 0.18) / 0.55)
    objets = plante_mere(mats, keiki=pousse, racines=racines)
    centre = KEIKI_BASE + SENS * 0.02 + UP * 0.085
    objets += marque("Marque_Keiki", centre, 0.185, mats["anneau"],
                     taille=rebond((f - 0.52) / 0.34))
    return objets


def etape_wait_roots(mats, f):
    # Les racines s'allongent le long de la hampe : sans elles, le keiki ne
    # vivrait pas seul. L'anneau les suit puis s'efface.
    avance = melange(0.28, 1.0, adouci(f / 0.82))
    objets = plante_mere(mats, keiki=1.0, racines=avance)
    centre = KEIKI_BASE + SENS_RACINE * 0.11
    objets += marque("Marque_Racines", centre, 0.135, mats["anneau"], epaisseur=0.022,
                     taille=melange(1.0, 0.0, adouci((f - 0.68) / 0.30)))
    return objets


def etape_separate(mats, f):
    # Deux coupes, l'une apres l'autre : au-dessus du keiki, puis en dessous.
    # On ne tire pas : la base du keiki se meurtrirait.
    f_haut = borne((f - 0.05) / 0.36)
    f_bas = borne((f - 0.40) / 0.34)
    lames_h, coupe_h = geste_ciseaux(mats, _pt(T_HI), _axe_lame(_tang(T_HI)), f_haut,
                                     echelle=0.74, arrivee=DROITE * 0.30 + UP * 0.80,
                                     sortie=DROITE * 0.70 + UP * 0.95)
    lames_b, coupe_b = geste_ciseaux(mats, _pt(T_LO), _axe_lame(_tang(T_LO)), f_bas,
                                     echelle=0.74, arrivee=-DROITE * 0.30 + UP * 0.80,
                                     sortie=-DROITE * 0.70 + UP * 0.95)
    coupe = 0
    if coupe_h:
        coupe = 1
    if coupe_b:
        coupe = 2
    sechage = adouci((f - 0.52) / 0.44)
    part = repos(adouci((f - 0.74) / 0.26), 2.2)
    M = Matrix.Translation((DROITE * 0.36 + UP * 0.16 + VUE * 0.05) * part) \
        @ pivote(KEIKI_BASE, VUE, -10.0 * part)
    objets = plante_mere(mats, keiki=1.0, racines=1.0, coupe=coupe, sechage=sechage, M_keiki=M)
    return objets + lames_h + lames_b


# Le keiki seul, presente plus grand : c'est la que ses racines se comptent.
SEUL = Vector((0.0, 0.0, 0.20))
ECH_SEUL = 1.15


def etape_roots(mats, f):
    # Le keiki tourne d'un quart et ses racines s'etalent : sans elles, il
    # ne reprend pas.
    M = pivote(SEUL, UP, 24.0 * adouci(f / 0.70))
    return morceau_keiki(mats, SEUL, echelle=ECH_SEUL, racines=1.0, sechage=0.0, M=M)


def etape_pot(mats, f):
    # Dans un petit pot d'ecorces : la base affleure, les racines pendent
    # dans le creux, jamais a travers la paroi.
    echelle = 0.60
    descente = adouci(f / 0.72)
    cible = Vector((0.0, 0.0, z_terre(echelle) - 0.05))
    haut = UP * (0.42 * (1.0 - descente))
    M = Matrix.Translation(cible - SEUL + haut)
    objets = pot_et_terre(mats, echelle)
    objets += morceau_keiki(mats, SEUL, echelle=1.0, racines=1.0, sechage=1.0,
                            dans=creux_pot(echelle, decalage=SEUL - haut), M=M)
    return objets


def etape_establish(mats, f):
    # La reprise : les feuilles s'allongent et une feuille neuve, plus
    # claire, sort du coeur.
    echelle = 0.60
    cible = Vector((0.0, 0.0, z_terre(echelle) - 0.05))
    M = Matrix.Translation(cible - SEUL)
    grandit = melange(1.0, 1.16, adouci(f / 0.88))
    objets = pot_et_terre(mats, echelle)
    objets += morceau_keiki(mats, SEUL, echelle=grandit, racines=0.0,
                            sechage=1.0, coeur=adouci((f - 0.30) / 0.62), M=M)
    return objets


PACK = "keiki"
ETAPES = [
    ("identify_keiki", 28, etape_identify_keiki, (0.0, 0.55, 1.0)),
    ("wait_roots", 26, etape_wait_roots, (0.0, 1.0)),
    ("separate", 30, etape_separate, (0.0, 0.30, 0.52, 0.75, 1.0)),
    ("roots", 28, etape_roots, (0.0, 1.0)),
    ("pot", 28, etape_pot, (0.0, 1.0)),
    ("establish", 26, etape_establish, (0.0, 1.0)),
]
