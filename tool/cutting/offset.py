# ============================================================
# offset — separer un rejet de sa plante mere.
#
# La plante : une rosette charnue, type aloe, et son rejet a cote. Pas de
# tige, pas de noeud : des feuilles epaisses qui partent toutes d'un meme
# coeur, et un court stolon qui relie le rejet a la mere sous la terre.
#
# Ce que l'utilisateur doit comprendre :
#   1. a quoi ressemble un rejet assez developpe pour partir ;
#   2. qu'il tient a la mere par un lien, sous la terre ;
#   3. qu'on le separe en le degageant, pas en le coupant au ras ;
#   4. qu'il part avec SES racines — sans elles, il ne reprendra pas ;
#   5. qu'un petit pot suffit ;
#   6. a quoi ressemble une reprise.
# ============================================================
from mathutils import Matrix, Vector
from math import cos, radians, sin

from .common import (
    DROITE, FOND, UP, VUE,
    adouci, creux_pot, faisceau_racines, marque, melange, miettes, pivote, pot_et_terre,
    rebond, repos, ruban_along, tube_along, z_terre,
)

# Une feuille de rosette : (azimut, inclinaison, longueur, largeur, courbure).
# Sept feuilles, aucune identique : ni la meme longueur, ni la meme pente.
ROSETTE = [
    (18.0, 52.0, 1.00, 1.00, 0.30),
    (76.0, 64.0, 0.88, 0.94, 0.24),
    (142.0, 58.0, 0.96, 0.98, 0.28),
    (205.0, 70.0, 0.82, 0.90, 0.20),
    (256.0, 55.0, 0.94, 0.96, 0.30),
    (312.0, 74.0, 0.76, 0.86, 0.18),
    (348.0, 82.0, 0.62, 0.80, 0.12),
]


def feuille_charnue(name, base, az, tilt, L, W, courbure, mats, matiere="charnu", n=12):
    """Une feuille epaisse et pointue : large a la base, effilee au bout,
    un peu recourbee vers l'exterieur. Section aplatie, pas un boudin."""
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


def rosette(prefix, mats, base, echelle=1.0, ouverture=1.0, coeur=0.0, matiere="charnu"):
    """La rosette entiere, construite autour de [base] dans le monde.
    [ouverture] (0 a 1) la fait grandir ; [coeur] fait sortir une jeune
    feuille du centre, plus claire que les autres."""
    objets = []
    for i, (az, tilt, L, W, courbure) in enumerate(ROSETTE):
        croissance = melange(0.30, 1.0, adouci((ouverture - 0.05 * i) / 0.72))
        if croissance <= 0.05:
            continue
        objets += feuille_charnue("%s_F%d" % (prefix, i), base, az, tilt,
                                  L * echelle * croissance, W * echelle * melange(0.82, 1.0, croissance),
                                  courbure, mats, matiere=matiere)
    if coeur > 0.02:
        objets += feuille_charnue(prefix + "_Coeur", base, 40.0, 86.0,
                                  0.46 * echelle * coeur, 0.60 * echelle, 0.06, mats, matiere="pousse")
    return objets


def pose(objets, M):
    """Place des objets construits dans le monde. Leur geometrie porte deja
    leurs coordonnees : il suffit de poser [M] par-dessus."""
    for ob in objets:
        ob.matrix_world = M @ ob.matrix_world
    return objets


# Le pot est un peu plus petit que nature : c'est la rosette et son rejet
# qu'on regarde, pas la terre cuite. Il reste assez large pour que le rejet
# et ses racines tiennent dedans — un rejet pose sur le bord aurait des
# racines qui sortiraient par la paroi.
ECH_POT = 0.74
Z_SOL = z_terre(ECH_POT)
MERE = Vector((-0.30, -0.08, Z_SOL - 0.02))
# Le rejet est devant, du cote de la camera : il doit se voir par-dessus le
# bord du pot, sinon rien de l'etape ne se lit.
REJET = Vector((0.36, -0.06, Z_SOL + 0.02))
ECH_MERE, ECH_REJET = 0.70, 0.46


def stolon(mats, casse=0.0):
    """Le lien entre la mere et le rejet : un court stolon charnu, sous la
    terre. [casse] le raccourcit quand le rejet s'en va."""
    if casse >= 0.99:
        return []
    n = 8
    fin = melange(1.0, 0.40, casse)
    A, B = MERE + UP * 0.04, REJET + UP * 0.04
    chemin = []
    for k in range(n + 1):
        s = k / float(n)
        chemin.append(A + (B - A) * (s * fin) - UP * (0.12 * s * (1.0 - s)))
    rayons = [0.038 - 0.012 * (k / float(n)) for k in range(n + 1)]
    return [tube_along("Stolon", chemin, rayons, mat=mats["tige"], seg=10, cap=3)]


# ------------------------------------------------------------
# les six etapes
# ------------------------------------------------------------
def etape_identify_offset(mats, f):
    # Le rejet grossit a cote de la mere, puis l'anneau le designe : un rejet
    # bon a prendre a deja sa propre rosette.
    pousse = melange(0.52, 1.0, adouci(f / 0.52))
    objets = pot_et_terre(mats, ECH_POT)
    objets += rosette("Mere", mats, MERE, echelle=ECH_MERE)
    objets += rosette("Rejet", mats, REJET, echelle=ECH_REJET * pousse)
    objets += marque("Marque_Rejet", REJET + UP * 0.16 + VUE * 0.30, 0.30, mats["anneau"],
                     taille=rebond((f - 0.54) / 0.34))
    return objets


def etape_expose(mats, f):
    # La terre s'ecarte, le rejet se souleve d'un rien : son pied, ses
    # premieres racines et le lien avec la mere paraissent.
    degage = adouci(f / 0.62)
    leve = 0.16 * adouci((f - 0.30) / 0.60)
    M = Matrix.Translation(UP * leve)
    objets = pot_et_terre(mats, ECH_POT)
    objets += rosette("Mere", mats, MERE, echelle=ECH_MERE)
    objets += pose(rosette("Rejet", mats, REJET, echelle=ECH_REJET), M)
    objets += stolon(mats)
    objets += faisceau_racines("RacineRejet", REJET + UP * (leve - 0.04), -UP, mats, degage, brins=4,
                               longueur=0.24, epaisseur=0.022, matiere="racine_fine", graine=4,
                               dans=creux_pot(ECH_POT))
    objets += miettes(mats, decalage=REJET - UP * 0.16, chute=degage, nombre=6, graine=3)
    return objets


def etape_separate(mats, f):
    # Le rejet s'ecarte et le lien cede : on le detache, on ne le coupe pas.
    part = repos(adouci(f / 0.84), 2.2)
    M = Matrix.Translation((DROITE * 0.50 + UP * 0.28 + FOND * 0.04) * part) @ pivote(REJET, VUE, 12.0 * part)
    objets = pot_et_terre(mats, ECH_POT)
    objets += rosette("Mere", mats, MERE, echelle=ECH_MERE)
    objets += pose(rosette("Rejet", mats, REJET, echelle=ECH_REJET), M)
    # Les racines sont d'abord celles d'un rejet encore en terre : elles
    # tiennent dans le pot, puis suivent le rejet qui s'en va.
    objets += pose(faisceau_racines("RacineRejet", REJET - UP * 0.04, -UP, mats, 1.0, brins=4,
                                    longueur=0.26, epaisseur=0.022, matiere="racine_fine", graine=4,
                                    dans=creux_pot(ECH_POT)), M)
    objets += stolon(mats, casse=adouci((f - 0.16) / 0.24))
    objets += miettes(mats, decalage=REJET - UP * 0.16, chute=1.0, nombre=6, graine=3)
    return objets


# Le rejet seul, presente plus grand : c'est la que ses racines se comptent.
SEUL = Vector((0.0, 0.0, 0.30))
ECH_SEUL = 0.70


def etape_roots(mats, f):
    # Le rejet tourne d'un quart et ses racines s'etalent : sans racines, il
    # ne reprend pas.
    M = pivote(SEUL, UP, 26.0 * adouci(f / 0.70))
    objets = pose(rosette("Rejet", mats, SEUL, echelle=ECH_SEUL), M)
    objets += faisceau_racines("Racine", SEUL - UP * 0.06, -UP, mats, adouci(f / 0.86), brins=5,
                               longueur=0.44, epaisseur=0.028, matiere="racine_fine", graine=4, ecart=1.6)
    return objets


def etape_pot(mats, f):
    # Dans un petit pot : un rejet n'a pas besoin de plus.
    echelle = 0.64
    descente = adouci(f / 0.72)
    cible = Vector((0.0, 0.0, z_terre(echelle) - 0.04))
    haut = UP * (0.44 * (1.0 - descente))
    M = Matrix.Translation(cible - SEUL + haut)
    objets = pot_et_terre(mats, echelle)
    objets += pose(rosette("Rejet", mats, SEUL, echelle=ECH_SEUL), M)
    # Le creux du pot, vu depuis le repere du rejet : il descend a mesure que
    # le rejet descend, si bien qu'aucune racine ne traverse jamais la paroi.
    objets += pose(faisceau_racines("Racine", SEUL - UP * 0.06, -UP, mats, 1.0, brins=5,
                                    longueur=0.30, epaisseur=0.026, matiere="racine_fine", graine=4, ecart=1.4,
                                    dans=creux_pot(echelle, decalage=SEUL - cible - haut)), M)
    return objets


def etape_establish(mats, f):
    # La reprise : les feuilles s'allongent et une jeune feuille, plus
    # claire, sort du coeur.
    echelle = 0.64
    cible = Vector((0.0, 0.0, z_terre(echelle) - 0.04))
    M = Matrix.Translation(cible - SEUL)
    grandit = melange(1.0, 1.20, adouci(f / 0.88))
    objets = pot_et_terre(mats, echelle)
    objets += pose(rosette("Rejet", mats, SEUL, echelle=ECH_SEUL * grandit,
                           coeur=adouci((f - 0.28) / 0.64)), M)
    return objets


PACK = "offset"
ETAPES = [
    ("identify_offset", 28, etape_identify_offset, (0.0, 0.55, 1.0)),
    ("expose", 26, etape_expose, (0.0, 1.0)),
    ("separate", 30, etape_separate, (0.0, 1.0)),
    ("roots", 28, etape_roots, (0.0, 1.0)),
    ("pot", 28, etape_pot, (0.0, 1.0)),
    ("establish", 26, etape_establish, (0.0, 1.0)),
]
