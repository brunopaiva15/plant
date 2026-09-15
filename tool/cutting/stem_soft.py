# ============================================================
# stem_soft — la bouture de tige tendre.
#
# La plante : une herbacee a tige fine et droite, feuilles simples opposees
# deux par deux, type basilic ou menthe. La tige est tendre, sans racine
# aerienne, et la touffe fait plusieurs brins — rien a voir avec la liane du
# pack stem_node_vine, et c'est le but : la silhouette doit se distinguer
# d'un coup d'oeil.
#
# Ce que l'utilisateur doit comprendre :
#   1. qu'on prend un jeune brin sain, pas la vieille tige ligneuse ;
#   2. que la coupe passe juste sous une paire de feuilles ;
#   3. que les feuilles du bas partent, pour ne pas pourrir dans l'eau ;
#   4. que la tige nue trempe et les feuilles restent au sec ;
#   5. que les racines d'une tige tendre sont fines et nombreuses ;
#   6. qu'on repique vite, des que les racines tiennent.
# ============================================================
from mathutils import Matrix, Vector
from math import cos, radians, sin

from .common import (
    DROITE, UP, VUE,
    adouci, bezier, creux_pot, creux_verre, faisceau_racines, geste_ciseaux, limbe, marque,
    melange, pivote, pot_et_terre, rebond, repere_face, tube_along, verre_et_eau, z_terre,
)


def feuille_ovale(name, repere, L, mats, ep=0.013, matiere="feuille"):
    """Une feuille simple, ovale, a peine plus longue que large : celle des
    herbes aromatiques."""
    def demi(t):
        t = min(max(t, 1e-4), 1.0 - 1e-4)
        return 0.30 * (t ** 0.36) * ((1.0 - t) ** 0.56) / 0.492

    return limbe(name, repere, demi, mats[matiere], L=L, nu=36, M=10, ep=ep,
                 releve=lambda t: -0.08 * t * t, creux=0.12, bevel=0.004, nervure=mats["tige_tendre"])


# Un brin : la courbe de sa tige, son rayon, et ses paires de feuilles
# (hauteur sur la tige, azimut, longueur du petiole, longueur du limbe,
# inclinaison). Les paires sont opposees et tournent d'un quart a chaque
# etage : c'est ce qui donne sa silhouette au basilic.
def brin(P0, P1, P2, r, etages):
    return {"P0": Vector(P0), "P1": Vector(P1), "P2": Vector(P2), "r": r, "etages": etages}


Z_SOL = z_terre(0.78)

BRIN_HERO = brin((0.06, -0.02, Z_SOL - 0.04), (0.02, 0.02, Z_SOL + 0.52), (0.14, 0.10, Z_SOL + 1.12),
                 (0.034, 0.022),
                 [(0.26, 18.0, 0.11, 0.46, 8.0),
                  (0.52, 104.0, 0.10, 0.42, 12.0),
                  (0.76, 188.0, 0.09, 0.34, 18.0),
                  (0.95, 272.0, 0.07, 0.23, 26.0)])
BRINS_AUTRES = [
    brin((-0.22, 0.08, Z_SOL - 0.04), (-0.30, 0.10, Z_SOL + 0.44), (-0.44, 0.04, Z_SOL + 0.88),
         (0.032, 0.021),
         [(0.30, 60.0, 0.10, 0.40, 10.0), (0.62, 146.0, 0.09, 0.35, 16.0), (0.92, 232.0, 0.07, 0.24, 24.0)]),
    brin((0.04, 0.20, Z_SOL - 0.04), (0.10, 0.30, Z_SOL + 0.40), (0.30, 0.44, Z_SOL + 0.78),
         (0.030, 0.020),
         [(0.34, 140.0, 0.09, 0.36, 12.0), (0.70, 226.0, 0.08, 0.30, 18.0), (0.98, 312.0, 0.06, 0.21, 26.0)]),
]

# La paire de feuilles sous laquelle on coupe, et la coupe elle-meme.
ETAGE_COUPE = 1
T_COUPE = 0.46


def _point(spec, t):
    return bezier(spec["P0"], spec["P1"], spec["P2"], t)


def _rayon(spec, t):
    r0, r1 = spec["r"]
    return r0 + (r1 - r0) * t


def paire(prefix, spec, etage, M, mats, echelle=1.0, chute=None, matiere="feuille"):
    """Les deux feuilles opposees d'un etage, et leurs petioles."""
    t, az, Lp, L, tilt = etage
    if echelle <= 0.03:
        return []
    N = _point(spec, t)
    objets = []
    for k, signe in enumerate((1.0, -1.0)):
        a = radians(az) + (0.0 if signe > 0 else radians(180.0))
        horiz = Vector((cos(a), sin(a), 0.0))
        ti = radians(tilt)
        dirn = (horiz * cos(ti) + UP * sin(ti)).normalized()
        Lp_i = Lp * (0.4 + 0.6 * echelle)
        pts, radii = [], []
        for i in range(6):
            s = i / 5.0
            pts.append(M @ (N + dirn * (Lp_i * s) + (chute or Vector((0, 0, 0)))))
            radii.append((0.016 - 0.005 * s) * echelle)
        objets.append(tube_along("%s_P%d" % (prefix, k), pts, radii, mat=mats["tige_tendre"], seg=8, cap=3))
        T = (pts[-1] - pts[-2]).normalized()
        pli = radians(24.0)
        fil = (T * cos(pli) - UP * sin(pli)).normalized()
        repere = repere_face(pts[-1], fil, roulis=6.0 * (1 if k else -1),
                             appoint=(M.to_3x3() @ horiz).normalized(), vers_camera=0.58)
        objets += feuille_ovale("%s_F%d" % (prefix, k), repere, L * echelle, mats, matiere=matiere)
    return objets


def tige(prefix, spec, mats, t0=0.0, t1=1.0, M=None, etages=None, matiere="tige_tendre"):
    """La tige de [t0] a [t1] et les paires de feuilles qu'elle porte.
    [etages] donne, par rang, les reglages d'une paire qu'on retire."""
    M = M or Matrix.Identity(4)
    etages = etages or {}
    if t1 - t0 < 0.02:
        return []
    pts, radii = [], []
    n = 18
    for i in range(n + 1):
        t = t0 + (t1 - t0) * i / float(n)
        pts.append(M @ _point(spec, t))
        radii.append(_rayon(spec, t))
    objets = [tube_along(prefix + "_Tige", pts, radii, mat=mats[matiere], seg=10)]
    for k, etage in enumerate(spec["etages"]):
        if etage[0] < t0 - 1e-6 or etage[0] > t1 + 1e-6:
            continue
        reglage = etages.get(k, {})
        objets += paire("%s_E%d" % (prefix, k), spec, etage, M, mats,
                        echelle=reglage.get("echelle", 1.0), chute=reglage.get("chute"))
    return objets


def touffe(mats, hero_t1=1.0, hero=True):
    objets = pot_et_terre(mats, 0.78)
    for i, spec in enumerate(BRINS_AUTRES):
        objets += tige("Brin%d" % (i + 2), spec, mats)
    if hero:
        objets += tige("Brin1", BRIN_HERO, mats, t1=hero_t1)
    return objets


# ------------------------------------------------------------
# la bouture seule
# ------------------------------------------------------------
BOUTURE = brin((0.0, 0.0, 0.0), (0.01, 0.0, 0.62), (0.08, 0.05, 1.30),
               (0.030, 0.021),
               [(0.12, 20.0, 0.10, 0.38, 10.0),
                (0.52, 106.0, 0.09, 0.36, 16.0),
                (0.92, 194.0, 0.07, 0.26, 24.0)])
ETAGE_BAS = 0


def bouture(mats, M, etages=None, racines=0.0, garde_basse=True, longueur_racines=0.23, dans=None):
    etages = dict(etages or {})
    if not garde_basse:
        etages[ETAGE_BAS] = {"echelle": 0.0}
    objets = tige("Bouture", BOUTURE, mats, M=M, etages=etages)
    if racines > 0.0:
        # Fines et nombreuses : une tige tendre ne fait pas les grosses
        # racines blanches d'une liane.
        depart = M @ _point(BOUTURE, 0.02)
        objets += faisceau_racines("Racine", depart, -UP, mats, racines, brins=7,
                                   longueur=longueur_racines, epaisseur=0.022,
                                   matiere="racine_fine", graine=5, ecart=1.7, seg=8, dans=dans)
        objets += faisceau_racines("RacineHaute", M @ _point(BOUTURE, BOUTURE["etages"][ETAGE_BAS][0]),
                                   -UP, mats, max(0.0, racines - 0.25), brins=4,
                                   longueur=longueur_racines * 0.8, epaisseur=0.018,
                                   matiere="racine_fine", graine=9, ecart=1.5, seg=8, dans=dans)
    return objets


# ------------------------------------------------------------
# les six etapes
# ------------------------------------------------------------
def etape_choose_stem(mats, f):
    # Le brin choisi est designe dans la touffe : jeune, droit, sain.
    objets = touffe(mats)
    centre = _point(BRIN_HERO, 0.70) + VUE * 0.30
    objets += marque("Marque_Brin", centre, 0.30, mats["anneau"], taille=rebond((f - 0.06) / 0.54))
    return objets


def etape_cut(mats, f):
    # Juste sous la paire de feuilles : c'est de la que partiront les racines.
    C = _point(BRIN_HERO, T_COUPE)
    lames, coupe = geste_ciseaux(mats, C, DROITE, f, echelle=0.72,
                                 arrivee=DROITE * 0.80 + UP * 0.34, sortie=DROITE * 0.22 + UP * 0.78)
    objets = touffe(mats, hero_t1=T_COUPE - (0.012 if coupe else 0.0))
    levee = adouci((f - 0.54) / 0.42)
    if coupe:
        M = Matrix.Translation((UP * 0.26 + DROITE * 0.14) * levee) @ pivote(C, VUE, -12.0 * levee)
        objets += tige("Brin1_Haut", BRIN_HERO, mats, t0=T_COUPE + 0.012, M=M)
        centre = M @ _point(BRIN_HERO, BRIN_HERO["etages"][ETAGE_COUPE][0])
        objets += marque("Marque_Noeud", centre + VUE * 0.26, 0.20, mats["anneau"], epaisseur=0.024)
    else:
        objets += tige("Brin1_Haut", BRIN_HERO, mats, t0=T_COUPE)
        objets += marque("Marque_Noeud", _point(BRIN_HERO, BRIN_HERO["etages"][ETAGE_COUPE][0]) + VUE * 0.26,
                         0.20, mats["anneau"], epaisseur=0.024)
    return objets + lames


def etape_remove_lower_leaves(mats, f):
    # La paire du bas se detache : ce qui trempe pourrit.
    M = Matrix.Identity(4)
    chute = adouci((f - 0.20) / 0.52)
    reglage = {
        "chute": UP * (-0.26 * chute) + DROITE * (0.06 * chute),
        "echelle": 1.0 - adouci((chute - 0.24) / 0.50),
    }
    objets = bouture(mats, M, etages={ETAGE_BAS: reglage})
    objets += marque("Marque_Nu", _point(BOUTURE, 0.08) + VUE * 0.22, 0.16, mats["anneau"], epaisseur=0.020,
                     taille=melange(0.0, 1.0, adouci((f - 0.58) / 0.30)))
    return objets


# Un verre bas : les feuilles doivent passer par-dessus le bord, la tige
# nue rester dessous.
VERRE_LARGE, VERRE_HAUT = 1.15, 0.60
NIVEAU_EAU = 0.60
POSE_VERRE = Vector((0.0, 0.0, 0.28))


def etape_root(mats, f):
    # Dans l'eau : la tige nue dessous, les feuilles au-dessus du bord.
    descente = adouci(f / 0.70)
    M = Matrix.Translation(POSE_VERRE + UP * (0.34 * (1.0 - descente)))
    niveau = NIVEAU_EAU + 0.02 * adouci((f - 0.45) / 0.25)
    return verre_et_eau(mats, niveau, large=VERRE_LARGE, haut=VERRE_HAUT) \
        + bouture(mats, M, garde_basse=False)


def etape_roots(mats, f):
    M = Matrix.Translation(POSE_VERRE)
    return verre_et_eau(mats, NIVEAU_EAU + 0.02, large=VERRE_LARGE, haut=VERRE_HAUT) \
        + bouture(mats, M, garde_basse=False, racines=adouci(f / 0.92),
                  dans=creux_verre(large=VERRE_LARGE, haut=VERRE_HAUT))


def etape_pot(mats, f):
    # Repiquee tot : une tige tendre n'attend pas de grosses racines.
    echelle = 0.62
    descente = adouci(f / 0.70)
    cible = Vector((0.0, 0.0, z_terre(echelle) - 0.22))
    M = Matrix.Translation(cible + UP * (0.40 * (1.0 - descente)))
    return pot_et_terre(mats, echelle) \
        + bouture(mats, M, garde_basse=False, racines=1.0, longueur_racines=0.26, dans=creux_pot(echelle))


PACK = "stem_soft"
ETAPES = [
    ("choose_stem", 26, etape_choose_stem, (0.0, 1.0)),
    ("cut", 34, etape_cut, (0.0, 0.30, 0.46, 1.0)),
    ("remove_lower_leaves", 28, etape_remove_lower_leaves, (0.0, 0.5, 1.0)),
    ("root", 28, etape_root, (0.0, 1.0)),
    ("roots", 30, etape_roots, (0.0, 1.0)),
    ("pot", 28, etape_pot, (0.0, 1.0)),
]
