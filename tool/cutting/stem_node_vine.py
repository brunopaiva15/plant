# ============================================================
# stem_node_vine — la bouture de tige a noeud.
#
# La plante : une liane a feuilles en coeur, pothos ou philodendron, dont le
# noeud se lit bien. Chaque noeud porte une feuille ; le noeud choisi porte
# en plus une racine aerienne, celle qui deviendra racine.
#
# Ce que l'utilisateur doit comprendre, image par image :
#   1. a quoi ressemble un noeud, et lequel on garde ;
#   2. que la coupe passe SOUS le noeud, jamais au-dessus ;
#   3. qu'on degage le noeud des feuilles qui tremperaient ;
#   4. que le noeud va sous l'eau et les feuilles au-dessus ;
#   5. que les racines sortent du noeud, pas du bas de la tige ;
#   6. que la bouture racinee passe en pot sans enterrer le noeud.
# ============================================================
from mathutils import Vector, Matrix
from math import cos, sin, radians

from .common import (
    DROITE, UP, VUE, Z_TERRE,
    adouci, anneau, bezier, borne, creux_pot, creux_verre, faisceau_racines, geste_ciseaux,
    limbe, marque, melange, pot_et_terre, rebond, repere_face, sphere, tangente, tr,
    tube_along, verre_et_eau,
)

N_PETIOLE = 10
N_TIGE = 26


def feuille_coeur(name, repere, L, mats, ep=0.018):
    """Une feuille en coeur, comme celle d'un pothos : deux lobes a la base,
    la plus large au premier tiers, une pointe effilee."""
    EA, EB = 0.32, 0.80
    tm = EA / (EA + EB)
    envmax = (tm ** EA) * ((1.0 - tm) ** EB)
    W = 0.76

    def demi(t):
        t = min(max(t, 1e-4), 1.0 - 1e-4)
        env = (t ** EA) * ((1.0 - t) ** EB) / envmax
        lobe = 0.66 * (1.0 - (t / 0.30) ** 2) if t < 0.30 else 0.0
        return W * max(env, lobe)

    return limbe(name, repere, demi, mats["feuille"], L=L, nu=52, M=13, ep=ep,
                 releve=lambda t: -0.14 * t * t, creux=0.05, nervure=mats["tige"])


# Un noeud : (t sur la tige, azimut de la feuille, petiole, limbe,
# inclinaison, roulis, racine aerienne).
LIANE_HERO = {
    "P0": Vector((0.08, -0.06, Z_TERRE - 0.03)),
    "P1": Vector((0.26, 0.04, Z_TERRE + 0.84)),
    "P2": Vector((0.98, 0.42, Z_TERRE + 1.18)),
    "r": (0.052, 0.036),
    "noeuds": [
        (0.30, -110.0, 0.30, 0.44, 22.0, -6.0, False),
        (0.62, 35.0, 0.32, 0.46, 24.0, 8.0, True),
        (0.84, -80.0, 0.30, 0.44, 30.0, -10.0, False),
        (1.00, 20.0, 0.24, 0.44, 44.0, 4.0, False),
    ],
}
LIANES_AUTRES = [
    {
        "P0": Vector((-0.08, 0.06, Z_TERRE - 0.03)),
        "P1": Vector((-0.16, 0.08, Z_TERRE + 0.62)),
        "P2": Vector((-0.44, -0.08, Z_TERRE + 0.86)),
        "r": (0.050, 0.034),
        "noeuds": [
            (0.46, 60.0, 0.24, 0.38, 26.0, 6.0, False),
            (1.00, -30.0, 0.22, 0.40, 40.0, -6.0, False),
        ],
    },
    {
        "P0": Vector((0.00, 0.10, Z_TERRE - 0.03)),
        "P1": Vector((-0.04, 0.22, Z_TERRE + 0.56)),
        "P2": Vector((-0.18, 0.44, Z_TERRE + 0.92)),
        "r": (0.048, 0.032),
        "noeuds": [
            (0.52, -70.0, 0.24, 0.38, 30.0, 4.0, False),
            (1.00, -60.0, 0.22, 0.38, 36.0, -4.0, False),
        ],
    },
]

# Ou l'on coupe : juste sous le noeud choisi (le second).
NOEUD_CHOISI = 1
T_NOEUD = LIANE_HERO["noeuds"][NOEUD_CHOISI][0]
T_COUPE = 0.555


def _point_tige(spec, t):
    return bezier(spec["P0"], spec["P1"], spec["P2"], t)


def _rayon(spec, t):
    r0, r1 = spec["r"]
    return r0 + (r1 - r0) * t


def _dehors(spec, t):
    p = _point_tige(spec, t)
    d = Vector((p.x, p.y, 0.0))
    if d.length < 1e-3:
        d = Vector((spec["P2"].x, spec["P2"].y, 0.0))
    return d.normalized()


def feuille_et_petiole(prefix, spec, noeud, M, echelle=1.0, mats=None, balancement=0.0, chute=None):
    """Le petiole et la feuille d'un noeud. [echelle] les fait pousser ;
    [balancement] (degres) et [chute] (vecteur) les detachent."""
    t, az, Lp, L, tilt, roll, _ = noeud
    if echelle <= 0.02:
        return []
    N = _point_tige(spec, t)
    dehors = _dehors(spec, t)
    a = radians(az)
    if spec.get("absolu"):
        # L'azimut est donne dans le monde : c'est la bouture seule, dont
        # chaque feuille est placee pour la camera.
        dehors = Vector((cos(a), sin(a), 0.0))
        horiz = dehors
    else:
        horiz = Vector((dehors.x * cos(a) - dehors.y * sin(a), dehors.x * sin(a) + dehors.y * cos(a), 0.0))
    ti = radians(tilt + balancement)
    dirn = (horiz * cos(ti) + UP * sin(ti)).normalized()
    Lp_i = Lp * (0.3 + 0.7 * echelle)
    L_i = L * (0.15 + 0.85 * echelle)
    Q0, Q2 = N, N + dirn * Lp_i
    Q1 = N + dirn * (Lp_i * 0.5) + UP * (0.10 * Lp_i)
    pts, radii = [], []
    for i in range(N_PETIOLE + 1):
        s = i / float(N_PETIOLE)
        pts.append(tr(M, bezier(Q0, Q1, Q2, s) + (chute or Vector((0, 0, 0)))))
        radii.append((0.030 - 0.012 * s) * (0.6 + 0.4 * echelle))
    objets = [tube_along(prefix + "_Petiole", pts, radii, mat=mats["tige"])]
    T = (pts[-1] - pts[-2]).normalized()
    # Le limbe ne prolonge pas le petiole : il s'inflechit vers le bas a
    # l'articulation, comme une feuille qui pend.
    pli = radians(38.0)
    fil = (T * cos(pli) - UP * sin(pli)).normalized()
    repere = repere_face(pts[-1] - T * 0.02, fil, roulis=roll, appoint=(M.to_3x3() @ dehors).normalized())
    objets += feuille_coeur(prefix + "_Feuille", repere, L_i, mats, ep=0.018 * (0.7 + 0.3 * echelle))
    return objets


def liane(prefix, spec, mats, t0=0.0, t1=1.0, M=None, pousse=1.0, feuilles=None, racine_aerienne=1.0):
    """La tige de [t0] a [t1], ses noeuds et leurs feuilles, dans le repere
    [M]. [pousse] (0 a 1) la fait sortir de terre."""
    M = M or Matrix.Identity(4)
    feuilles = feuilles or {}
    fin = t0 + (t1 - t0) * adouci(pousse / 0.72) if pousse < 1.0 else t1
    if fin - t0 < 0.02:
        return []
    pts, radii = [], []
    n = max(4, int(N_TIGE * (fin - t0)))
    for i in range(n + 1):
        t = t0 + (fin - t0) * i / float(n)
        pts.append(tr(M, _point_tige(spec, t)))
        radii.append(_rayon(spec, t) * (0.6 + 0.4 * pousse))
    objets = [tube_along(prefix + "_Tige", pts, radii, mat=mats["tige"])]
    for k, noeud in enumerate(spec["noeuds"]):
        t = noeud[0]
        if t < t0 - 1e-6 or t > fin + 1e-6:
            continue
        naissance = (t - t0) / max(t1 - t0, 1e-6) * 0.72
        echelle = adouci((pousse - naissance) / 0.30) if pousse < 1.0 else 1.0
        if echelle <= 0.0:
            continue
        centre = _point_tige(spec, t)
        # Le noeud est un renflement franc : c'est lui qu'on apprend a voir.
        objets.append(sphere(prefix + "_Noeud_%d" % k, tr(M, centre),
                             _rayon(spec, t) * 1.62 * (0.5 + 0.5 * echelle), mats["tige"], echelle=(1.0, 1.0, 0.82)))
        if noeud[6] and racine_aerienne > 0.0:
            # La racine aerienne : un bout de tube qui descend du noeud, et
            # qui s'ecarte de la tige pour se detacher a l'oeil.
            d = (UP * -0.78 + _dehors(spec, t) * 0.50).normalized()
            L = 0.20 * racine_aerienne * echelle
            rp = [tr(M, centre + d * (L * s) + UP * (0.02 * s * s)) for s in (0.0, 0.35, 0.70, 1.0)]
            objets.append(tube_along(prefix + "_Aerienne", rp, [0.021, 0.019, 0.016, 0.010], mat=mats["racine"]))
        reglage = feuilles.get(k, {})
        objets += feuille_et_petiole(prefix + "_N%d" % k, spec, noeud, M, echelle=echelle * reglage.get("echelle", 1.0),
                                     mats=mats, balancement=reglage.get("balancement", 0.0), chute=reglage.get("chute"))
    return objets


def plante_mere(mats, pousse=1.0, hero_t1=1.0):
    objets = pot_et_terre(mats)
    for i, spec in enumerate(LIANES_AUTRES):
        objets += liane("Liane%d" % (i + 2), spec, mats, pousse=borne(pousse * 1.15 - 0.10 * i))
    objets += liane("Liane1", LIANE_HERO, mats, t1=hero_t1, pousse=pousse)
    return objets


# ------------------------------------------------------------
# la bouture seule : le brin coupe, tenu droit
# ------------------------------------------------------------
LIANE_BOUTURE = {
    "P0": Vector((0.0, 0.0, 0.0)),
    "P1": Vector((0.02, 0.00, 0.62)),
    "P2": Vector((0.16, 0.10, 1.30)),
    "r": (0.046, 0.036),
    "absolu": True,
    "noeuds": [
        (0.22, 15.0, 0.30, 0.44, 18.0, 6.0, True),
        (0.62, 222.0, 0.30, 0.46, 28.0, -8.0, False),
        (1.00, 300.0, 0.24, 0.46, 42.0, 4.0, False),
    ],
}
NOEUD_BOUTURE = 0


def repere_bouture(cible=Vector((0, 0, 0))):
    return Matrix.Translation(cible)


def noeud_bouture(M):
    return tr(M, _point_tige(LIANE_BOUTURE, LIANE_BOUTURE["noeuds"][NOEUD_BOUTURE][0]))


def bouture(mats, M, feuilles=None, racines=0.0, garde_basse=True, longueur_racines=0.32, dans=None):
    feuilles = dict(feuilles or {})
    if not garde_basse:
        feuilles[NOEUD_BOUTURE] = {"echelle": 0.0}
    objets = liane("Bouture", LIANE_BOUTURE, mats, M=M, feuilles=feuilles)
    if racines > 0.0:
        # Les racines partent du noeud, jamais du bas de la tige.
        objets += faisceau_racines("Racine", noeud_bouture(M), -UP, mats, racines, brins=5,
                                   longueur=longueur_racines, epaisseur=0.030, graine=2, ecart=1.5, dans=dans)
    return objets


def anneau_du_noeud(mats, taille, t=T_NOEUD, rayon=0.150):
    """L'anneau entoure le noeud choisi : c'est lui qu'il faut apprendre a
    voir, et lui qui doit rester du cote de la bouture."""
    centre = _point_tige(LIANE_HERO, t)
    axe = tangente(LIANE_HERO["P0"], LIANE_HERO["P1"], LIANE_HERO["P2"], t)
    if taille <= 0.02:
        return []
    return [anneau("Anneau_Noeud", centre, axe, rayon * taille, 0.032 * taille, mats["anneau"])]


# ------------------------------------------------------------
# les six etapes
# ------------------------------------------------------------
def etape_identify_node(mats, f):
    # La plante finit de se mettre en place — elle est deja la a la premiere
    # image —, puis l'anneau se pose autour du noeud choisi.
    pousse = melange(0.62, 1.0, adouci(f / 0.50))
    return plante_mere(mats, pousse=pousse) + anneau_du_noeud(mats, rebond((f - 0.52) / 0.32))


def etape_cut_below_node(mats, f):
    # L'anneau reste sur le noeud pendant que les ciseaux se ferment dessous :
    # impossible de croire qu'on coupe au-dessus.
    C = _point_tige(LIANE_HERO, T_COUPE)
    T = tangente(LIANE_HERO["P0"], LIANE_HERO["P1"], LIANE_HERO["P2"], T_COUPE)
    Y = T.cross(VUE).normalized()
    if Y.dot(UP) > 0:
        Y = -Y
    lames, coupe = geste_ciseaux(mats, C, Y, f)
    levee = adouci((f - 0.52) / 0.42)

    objets = pot_et_terre(mats)
    for i, spec in enumerate(LIANES_AUTRES):
        objets += liane("Liane%d" % (i + 2), spec, mats)
    objets += liane("Liane1", LIANE_HERO, mats, t1=T_COUPE - (0.012 if coupe else 0.0))
    if coupe:
        M = Matrix.Translation((UP * 0.32 + DROITE * 0.12 + VUE * 0.04) * levee) \
            @ Matrix.Translation(C) @ Matrix.Rotation(radians(-14.0) * levee, 4, VUE) @ Matrix.Translation(-C)
        objets += liane("Liane1_Bouture", LIANE_HERO, mats, t0=T_COUPE + 0.012, M=M)
        # L'anneau suit le noeud : il part avec la bouture.
        centre = tr(M, _point_tige(LIANE_HERO, T_NOEUD))
        axe = (M.to_3x3() @ tangente(LIANE_HERO["P0"], LIANE_HERO["P1"], LIANE_HERO["P2"], T_NOEUD)).normalized()
        objets.append(anneau("Anneau_Noeud", centre, axe, 0.150, 0.032, mats["anneau"]))
    else:
        objets += liane("Liane1_Haut", LIANE_HERO, mats, t0=T_COUPE)
        objets += anneau_du_noeud(mats, 1.0)
    return objets + lames


def etape_clear_node(mats, f):
    # La feuille du bas se decroche et tombe : le noeud reste nu.
    M = repere_bouture()
    balance = adouci((f - 0.15) / 0.30)
    chute = adouci((f - 0.32) / 0.45)
    reglage = {
        "balancement": -58.0 * balance,
        "chute": UP * (-0.34 * chute) + DROITE * (0.08 * chute),
        "echelle": 1.0 - adouci((chute - 0.30) / 0.45),
    }
    objets = bouture(mats, M, feuilles={NOEUD_BOUTURE: reglage})
    # L'anneau s'efface une fois le noeud degage : il a dit ce qu'il avait a dire.
    objets += marque("Marque_Noeud", noeud_bouture(M), 0.150, mats["anneau"],
                     taille=melange(1.0, 0.0, adouci((f - 0.55) / 0.30)))
    return objets


# Un verre trapu et large : le noeud immerge et ses racines s'y lisent mieux
# que dans une flute. La surface reste sous les feuilles.
VERRE_LARGE, VERRE_HAUT = 1.34, 0.80
NIVEAU_EAU = 0.64
POSE_VERRE = Vector((0.02, 0.0, 0.18))


def etape_place_in_water(mats, f):
    descente = adouci(f / 0.70)
    M = Matrix.Translation(UP * (0.42 * (1.0 - descente))) @ repere_bouture(cible=POSE_VERRE)
    niveau = NIVEAU_EAU + 0.03 * adouci((f - 0.45) / 0.25)
    return verre_et_eau(mats, niveau, large=VERRE_LARGE, haut=VERRE_HAUT) + bouture(mats, M, garde_basse=False)


def etape_roots_from_node(mats, f):
    M = repere_bouture(cible=POSE_VERRE)
    return verre_et_eau(mats, NIVEAU_EAU + 0.03, large=VERRE_LARGE, haut=VERRE_HAUT) \
        + bouture(mats, M, garde_basse=False, racines=adouci(f / 0.92),
                  dans=creux_verre(large=VERRE_LARGE, haut=VERRE_HAUT))


def etape_pot(mats, f):
    descente = adouci(f / 0.68)
    echelle = 0.90
    # La coupe finit dans le pot, le noeud juste sous la terre, les racines
    # au-dessus du fond.
    M = Matrix.Translation(UP * (0.46 * (1.0 - descente))) @ repere_bouture(cible=Vector((0.0, 0.0, Z_TERRE * echelle - 0.30)))
    return pot_et_terre(mats, echelle) \
        + bouture(mats, M, garde_basse=False, racines=1.0, longueur_racines=0.42, dans=creux_pot(echelle))


PACK = "stem_node_vine"
ETAPES = [
    ("identify_node", 30, etape_identify_node, (0.0, 0.55, 1.0)),
    ("cut_below_node", 36, etape_cut_below_node, (0.0, 0.30, 0.46, 1.0)),
    ("clear_node", 28, etape_clear_node, (0.0, 0.5, 1.0)),
    ("place_in_water", 28, etape_place_in_water, (0.0, 1.0)),
    ("roots_from_node", 32, etape_roots_from_node, (0.0, 1.0)),
    ("pot", 30, etape_pot, (0.0, 1.0)),
]
