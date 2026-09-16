# ============================================================
# division — separer une touffe en deux plantes.
#
# La plante : une touffe a couronnes multiples, type spathiphyllum. Pas de
# tige aerienne, pas de noeud : des feuilles lanceolees portees par de longs
# petioles qui partent tous du meme point, sous la terre, et un chevelu de
# racines qui tient la motte.
#
# Ce que l'utilisateur doit comprendre :
#   1. que la plante se sort de son pot en entier ;
#   2. ce qu'est une motte ;
#   3. que la terre se degage jusqu'a voir les racines ;
#   4. que la touffe est faite de deux groupes distincts ;
#   5. que la separation se fait a la main, sans ciseaux ;
#   6. que chaque moitie garde SES feuilles ET SES racines.
# ============================================================
from mathutils import Matrix, Vector
from math import cos, pi, radians, sin

from .common import (
    DROITE, FOND, UP, VUE,
    adouci, bezier, creux_pot, limbe, marque, melange, miettes, motte, pot_et_terre,
    racines_motte, repere_face, repos, sphere, tube_along, z_terre,
)

# Une couronne : (azimut du bouquet, nombre de feuilles, echelle).
COURONNES = [
    {"pos": Vector((-0.15, -0.05, 0.0)), "az": 168.0, "feuilles": 5, "ech": 1.00},
    {"pos": Vector((0.17, 0.07, 0.0)), "az": -14.0, "feuilles": 4, "ech": 0.86},
]

# Les feuilles d'une couronne : (ecart d'azimut, longueur du petiole, longueur
# du limbe, inclinaison, roulis). Pas deux pareilles : une touffe clonee se
# voit tout de suite.
BOUQUET = [
    (-66.0, 0.62, 0.74, 80.0, -8.0),
    (-24.0, 0.76, 0.86, 86.0, 6.0),
    (10.0, 0.52, 0.64, 76.0, 12.0),
    (46.0, 0.68, 0.80, 83.0, -6.0),
    (92.0, 0.44, 0.58, 74.0, 14.0),
]


def feuille_lanceolee(name, repere, L, mats, ep=0.016, matiere="feuille"):
    """Un limbe lanceole : etroit a la base, le plus large au milieu, une
    pointe franche. Trois fois plus long que large — c'est la feuille des
    plantes en touffe, rien a voir avec le coeur d'un pothos."""
    # Le maximum de t^0.42 (1-t)^0.55 vaut 0.515 : on normalise dessus pour
    # que [demi] rende bien la demi-largeur voulue.
    def demi(t):
        t = min(max(t, 1e-4), 1.0 - 1e-4)
        return 0.165 * (t ** 0.42) * ((1.0 - t) ** 0.55) / 0.515

    return limbe(name, repere, demi, mats[matiere], L=L, nu=44, M=10, ep=ep,
                 releve=lambda t: -0.10 * t * t, creux=0.30, nervure=mats["tige"])


def couronne(prefix, mats, base, az, nombre, echelle=1.0, M=None, pousse=1.0, matiere="feuille"):
    """Un bouquet de feuilles arquees partant d'un meme point."""
    M = M or Matrix.Identity(4)
    objets = []
    for i, (decal, Lp, L, tilt, roll) in enumerate(BOUQUET[:nombre]):
        croissance = melange(0.55, 1.0, adouci((pousse - 0.06 * i) / 0.70))
        a = radians(az + decal)
        horiz = Vector((cos(a), sin(a), 0.0))
        ti = radians(tilt)
        montee = (horiz * cos(ti) + UP * sin(ti)).normalized()
        Lp_i = Lp * echelle * croissance
        Q0 = Vector(base)
        Q2 = Q0 + montee * Lp_i + UP * (0.10 * Lp_i)
        Q1 = Q0 + UP * (0.80 * Lp_i) + horiz * (0.10 * Lp_i)
        pts, radii = [], []
        for k in range(11):
            s = k / 10.0
            pts.append(M @ bezier(Q0, Q1, Q2, s))
            radii.append((0.028 - 0.010 * s) * echelle)
        objets.append(tube_along("%s_Petiole_%d" % (prefix, i), pts, radii, mat=mats["tige"], seg=10))
        T = (pts[-1] - pts[-2]).normalized()
        # Le limbe prolonge le petiole en retombant un peu : une feuille de
        # touffe s'arque, elle ne pointe pas le ciel.
        pli = radians(26.0)
        fil = (T * cos(pli) - UP * sin(pli)).normalized()
        repere = repere_face(pts[-1], fil, roulis=roll, appoint=(M.to_3x3() @ horiz).normalized(), vers_camera=0.40)
        objets += feuille_lanceolee("%s_Feuille_%d" % (prefix, i), repere, L * echelle * croissance,
                                    mats, matiere=matiere)
    return objets


def touffe(mats, M=None, dz=0.0, pousse=1.0, groupes=None):
    """Les deux couronnes, chacune dans son repere. [groupes] donne, par
    rang, le repere propre d'une couronne — c'est ce qui les separe."""
    M = M or Matrix.Identity(4)
    groupes = groupes or {}
    objets = []
    for i, c in enumerate(COURONNES):
        Mi = M @ groupes.get(i, Matrix.Identity(4))
        # Les petioles partent du collet, juste sous la terre, pas du fond
        # du pot : sinon les limbes traversent sa paroi et la motte.
        base = c["pos"] + UP * (Z_SOL - 0.06 + dz)
        objets += couronne("Couronne%d" % i, mats, base, c["az"], c["feuilles"],
                           echelle=c["ech"], M=Mi, pousse=pousse)
    return objets


def racines_groupe(prefix, mats, centre, M=None, brins=6, longueur=0.42, etale=0.0, graine=0, dans=None):
    """Le chevelu d'un groupe : quelques racines principales qui descendent
    et s'ecartent. Elles restent attachees a leurs feuilles, c'est tout
    l'objet de l'etape."""
    M = M or Matrix.Identity(4)
    objets = []
    C = Vector(centre)
    for i in range(brins):
        a = 2.0 * pi * (i + 0.3 * ((i + graine) % 3)) / brins + 0.6 * graine
        horiz = Vector((cos(a), sin(a), 0.0))
        L = longueur * melange(0.74, 1.0, ((i * 3 + graine) % 4) / 3.0)
        pts, radii = [], []
        n = 12
        for k in range(n + 1):
            s = k / float(n)
            p = C + horiz * (L * (0.42 + etale * 0.30) * s * s) - UP * (L * s) \
                + Vector((-horiz.y, horiz.x, 0.0)) * (0.05 * L * sin(s * 4.2 + i))
            q = dans.ramene(p) if dans is not None else p
            # Deux points ramenes au meme endroit contre la paroi donneraient
            # une tangente nulle, et un tube pince.
            if pts and (M @ q - pts[-1]).length < 1e-4:
                q = q - UP * 1e-3
            pts.append(M @ q)
            radii.append(0.030 - 0.017 * s)
        objets.append(tube_along("%s_%d" % (prefix, i), pts, radii, mat=mats["racine"], seg=9, cap=3))
        # Une ramification simple, a mi-course : quelques racines seulement.
        if i % 2 == 0:
            branche = [C + horiz * (L * (0.42 + etale * 0.30) * 0.30) - UP * (L * 0.55) + horiz * (0.10 * L * s)
                       - UP * (0.22 * L * s) for s in (0.0, 0.5, 1.0)]
            d = [M @ (dans.ramene(q) if dans is not None else q) for q in branche]
            objets.append(tube_along("%s_%d_bis" % (prefix, i), d, [0.016, 0.013, 0.008], mat=mats["racine"], seg=8, cap=3))
    return objets


# ------------------------------------------------------------
# les six etapes
# ------------------------------------------------------------
Z_SOL = z_terre()
# Le point d'ou partent les racines de chaque couronne, dans la motte.
BASES = [c["pos"] + UP * (Z_SOL - 0.06) for c in COURONNES]


# La bascule du depotage : la plante est penchee sur le cote le temps que le
# pot la quitte. L'etape 1 l'y amene, l'etape 2 l'en ramene — le geste se
# poursuit d'une sequence a l'autre, il ne repart pas de zero.
BASCULE = 26.0
PIVOT = Vector((0.0, 0.0, 0.16))


def _bascule(angle):
    return Matrix.Translation(PIVOT) @ Matrix.Rotation(radians(angle), 4, FOND) @ Matrix.Translation(-PIVOT)


def etape_plant(mats, f):
    # La touffe finit de se poser, puis l'ensemble penche : le geste qui
    # precede le depotage, main sous la motte.
    pousse = melange(0.72, 1.0, adouci(f / 0.42))
    M = _bascule(BASCULE * adouci((f - 0.30) / 0.66))
    objets = pot_et_terre(mats)
    for ob in objets:
        ob.matrix_world = M @ ob.matrix_world
    return objets + touffe(mats, M=M, pousse=pousse)


def etape_remove_pot(mats, f):
    # Le pot glisse le long de la motte et la libere ; la plante se redresse.
    sortie = adouci(f / 0.74)
    M = _bascule(BASCULE * (1.0 - adouci((f - 0.20) / 0.72)))
    axe = (M.to_3x3() @ Vector((0, 0, -1))).normalized()
    Mpot = Matrix.Translation(axe * (1.10 * sortie)) @ M
    pot = pot_et_terre(mats)
    for ob in pot:
        ob.matrix_world = Mpot @ ob.matrix_world
    dessous = motte(mats) + racines_motte(mats, sortie=adouci((f - 0.36) / 0.52), graine=1)
    for ob in dessous:
        ob.matrix_world = M @ ob.matrix_world
    return pot + dessous + touffe(mats, M=M)


def etape_expose_roots(mats, f):
    # La terre s'emiette : la motte se resserre, les racines paraissent.
    degage = adouci(f / 0.78)
    objets = motte(mats, serre=1.0 - 0.60 * degage)
    objets += racines_motte(mats, sortie=1.0, densite=12, graine=1)
    objets += miettes(mats, chute=adouci(f / 0.92), nombre=8, graine=1)
    for i, base in enumerate(BASES):
        objets += racines_groupe("Chevelu%d" % i, mats, base - UP * 0.30, brins=5,
                                 longueur=0.34 * degage, graine=i)
    return objets + touffe(mats)


def etape_identify_clusters(mats, f):
    # Deux anneaux se posent, un par groupe : la touffe est faite de deux
    # plantes, chacune avec ses feuilles et ses racines.
    objets = motte(mats, serre=0.45)
    objets += racines_motte(mats, sortie=1.0, densite=12, graine=1)
    for i, base in enumerate(BASES):
        objets += racines_groupe("Chevelu%d" % i, mats, base - UP * 0.30, brins=5, longueur=0.34, graine=i)
    objets += touffe(mats)
    for i, c in enumerate(COURONNES):
        taille = adouci((f - 0.10 - 0.22 * i) / 0.34)
        # Devant le groupe, pas dedans : l'anneau doit se voir sur la motte.
        centre = c["pos"] * 2.7 + UP * (Z_SOL - 0.14) + VUE * 0.75
        objets += marque("Groupe_%d" % i, centre, 0.34 * c["ech"], mats["anneau"], epaisseur=0.030, taille=taille)
    return objets


def _ecartement(i, part):
    """Le repere d'un groupe pendant la separation : il s'ecarte du centre,
    en s'inclinant un peu, sans jamais se tordre."""
    signe = -1.0 if i == 0 else 1.0
    d = (DROITE * 0.64 + FOND * 0.06) * part * signe
    return Matrix.Translation(d) @ Matrix.Rotation(radians(11.0) * part * signe, 4, VUE)


def etape_separate(mats, f):
    # Les deux moities se separent a la main. Pas de ciseaux : on ne coupe
    # pas une touffe, on la partage.
    part = repos(adouci(f / 0.88), 2.4)
    objets = []
    for i, c in enumerate(COURONNES):
        Mi = _ecartement(i, part)
        objets += racines_groupe("Chevelu%d" % i, mats, c["pos"] + UP * (Z_SOL - 0.36), M=Mi,
                                 brins=6, longueur=0.44, etale=part, graine=i)
        # Un peu de terre reste prise dans chaque chevelu : chaque moitie
        # part avec sa motte, pas avec une coupe nette.
        objets.append(sphere("Terre%d" % i, Mi @ (c["pos"] + UP * (Z_SOL - 0.24)), 0.21 * c["ech"],
                             mats["motte"], seg=20, echelle=(1.05, 0.95, 0.62)))
    objets += touffe(mats, groupes={i: _ecartement(i, part) for i in range(len(COURONNES))})
    return objets


def etape_repot(mats, f):
    # Chaque moitie dans son pot. Les deux descendent ensemble, celle de
    # droite un peu apres : deux plantes, pas une qu'on a coupee en deux.
    echelle = 0.74
    objets = []
    for i, c in enumerate(COURONNES):
        cote = DROITE * (0.62 if i else -0.62) + FOND * (0.05 if i else -0.05)
        descente = adouci((f - 0.10 * i) / 0.74)
        objets += pot_et_terre(mats, echelle, decalage=cote, nom="Pot%d" % i)
        haut = UP * (0.62 * (1.0 - descente))
        Mi = Matrix.Translation(cote + haut + UP * (z_terre(echelle) - Z_SOL - 0.08) - c["pos"] * 0.30)
        # Le creux du pot, vu depuis le repere de la division : il suit sa
        # descente, si bien qu'aucune racine ne traverse jamais la paroi.
        creux = creux_pot(echelle, decalage=c["pos"] * 0.30 + UP * (Z_SOL + 0.08 - z_terre(echelle)) - haut)
        objets += racines_groupe("Chevelu%d" % i, mats, c["pos"] + UP * (Z_SOL - 0.30), M=Mi, brins=5,
                                 longueur=0.30, graine=i, dans=creux)
        objets += couronne("Rempote%d" % i, mats, c["pos"] + UP * Z_SOL, c["az"], c["feuilles"],
                           echelle=c["ech"] * 0.94, M=Mi)
    return objets


PACK = "division"
ETAPES = [
    ("plant", 26, etape_plant, (0.0, 1.0)),
    ("remove_pot", 32, etape_remove_pot, (0.0, 0.5, 1.0)),
    ("expose_roots", 30, etape_expose_roots, (0.0, 0.5, 1.0)),
    ("identify_clusters", 28, etape_identify_clusters, (0.0, 1.0)),
    ("separate", 30, etape_separate, (0.0, 1.0)),
    ("repot", 30, etape_repot, (0.0, 1.0)),
]
