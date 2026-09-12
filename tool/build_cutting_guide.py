# ============================================================
# Le guide de bouturage : six sequences d'images, une par etape, que
# l'application joue quand on cree une bouture.
#
# Meme scene, memes materiaux et meme cadrage que l'icone et l'onboarding :
# argile mate, lumiere de studio, vue 3/4 orthographique, fond transparent
# et sans ombre portee — l'ombre et le flottement sont dessines par
# l'application.
#
# Les six etapes, dans l'ordre du geste :
#   1. la tige : la plante mere pousse, un anneau se pose sur le noeud choisi ;
#   2. la coupe : les ciseaux arrivent, se ferment sous le noeud, la bouture
#      se detache ;
#   3. les feuilles : la feuille du bas se decroche, le noeud reste nu ;
#   4. l'eau : la bouture descend dans un verre, le noeud sous la surface ;
#   5. les racines : elles sortent du noeud et s'allongent ;
#   6. le pot : la bouture racinee descend dans la terre.
#
# Chaque etape est cadree une fois pour toutes sur l'union de ses images :
# sans cela le cadre suivrait le sujet et c'est le monde qui semblerait
# bouger.
#
# Execution :
#   blender -b -noaudio -P tool/build_cutting_guide.py -- <res> <samples> <dossier> [apercu|complet [etape_N]]
# puis, pour chaque etape :
#   python3 tool/pack_growth.py <dossier>/etape_1 assets/cutting/etape_1.webp --fps 14
# ============================================================
import bpy, bmesh, sys, os
from mathutils import Vector, Matrix
from math import cos, sin, pi, radians

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from clay_scene import (  # noqa: E402  — le chemin doit etre pose avant
    POT_PROFIL, TERRE_PROFIL, VUE, Z_TERRE,
    grain, make_mat, purge, rendu_transparent, revolve, studio, tube_along,
)

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
RES = int(argv[0]) if len(argv) > 0 else 768
SAMPLES = int(argv[1]) if len(argv) > 1 else 32
DOSSIER = argv[2] if len(argv) > 2 else "/tmp/bouture"
# En apercu, quatre images par etape suffisent a juger la scene. Le quatrieme
# argument peut etre « complet », pour ne rendre qu'une etape en entier.
APERCU = len(argv) > 3 and argv[3] == "apercu"
SEULE = argv[4] if len(argv) > 4 else None

UP = Vector((0, 0, 1))
# Vers la droite de l'ecran : la camera regarde depuis l'azimut -58 degres.
DROITE = Vector((cos(radians(32.0)), sin(radians(32.0)), 0.0))


def borne(u):
    return min(max(u, 0.0), 1.0)


def adouci(u):
    u = borne(u)
    return u * u * (3.0 - 2.0 * u)


def rebond(u):
    """Comme [adouci], avec un leger depassement a l'arrivee."""
    u = borne(u)
    s = 1.35
    u -= 1.0
    return u * u * ((s + 1.0) * u + s) + 1.0


def bezier(P0, P1, P2, t):
    u = 1.0 - t
    return P0 * (u * u) + P1 * (2.0 * u * t) + P2 * (t * t)


def tangente(P0, P1, P2, t):
    return ((P1 - P0) * (2.0 * (1.0 - t)) + (P2 - P1) * (2.0 * t)).normalized()


def tr(M, p):
    return M @ Vector(p)


def rot(M, v):
    return (M.to_3x3() @ Vector(v)).normalized()


# ------------------------------------------------------------
# primitives de plus : sphere, anneau, lame
# ------------------------------------------------------------
def _objet(name, bm, mat, lisse=True):
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me); bm.free()
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    if mat:
        me.materials.append(mat)
    for p in me.polygons:
        p.use_smooth = lisse
    return ob


def sphere(name, centre, r, mat, seg=24):
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=seg, v_segments=seg // 2, radius=r,
                              matrix=Matrix.Translation(Vector(centre)))
    return _objet(name, bm, mat)


def anneau(name, centre, axe, R, r, mat, seg=48, sec=16, long=None, etire=1.0):
    """Un tore de rayon [R], de section [r], autour de [axe]. Donne [long]
    et [etire] pour l'allonger dans cette direction : les anneaux d'une
    paire de ciseaux sont ovales."""
    Z = Vector(axe).normalized()
    if long is not None:
        X = Vector(long) - Vector(long).dot(Z) * Z
    else:
        X = UP.cross(Z)
    if X.length < 1e-4:
        X = Vector((1, 0, 0)).cross(Z)
    X.normalize()
    Y = Z.cross(X)
    verts, faces = [], []
    for i in range(seg):
        a = 2.0 * pi * i / seg
        c = Vector(centre) + X * (cos(a) * R * etire) + Y * (sin(a) * R)
        radial = (X * (cos(a) / etire) + Y * sin(a)).normalized()
        for j in range(sec):
            b = 2.0 * pi * j / sec
            verts.append(c + radial * (r * cos(b)) + Z * (r * sin(b)))
    for i in range(seg):
        for j in range(sec):
            a0 = i * sec + j
            a1 = i * sec + (j + 1) % sec
            b0 = ((i + 1) % seg) * sec + j
            b1 = ((i + 1) % seg) * sec + (j + 1) % sec
            faces.append((a0, b0, b1, a1))
    me = bpy.data.meshes.new(name)
    me.from_pydata([tuple(v) for v in verts], [], faces); me.update()
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    me.materials.append(mat)
    for p in me.polygons:
        p.use_smooth = True
    return ob


def lame(name, M, longueur, base, pointe, ep, mat):
    """Une lame de ciseaux : une dalle effilee, le long de +Y du repere [M],
    adoucie par un biseau."""
    pts = [(-base / 2, 0, -ep / 2), (base / 2, 0, -ep / 2), (pointe / 2, longueur, -ep / 2), (-pointe / 2, longueur, -ep / 2),
           (-base / 2, 0, ep / 2), (base / 2, 0, ep / 2), (pointe / 2, longueur, ep / 2), (-pointe / 2, longueur, ep / 2)]
    faces = [(0, 1, 2, 3), (4, 7, 6, 5), (0, 4, 5, 1), (1, 5, 6, 2), (2, 6, 7, 3), (3, 7, 4, 0)]
    me = bpy.data.meshes.new(name)
    me.from_pydata([tuple(M @ Vector(p)) for p in pts], [], faces); me.update()
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    me.materials.append(mat)
    bev = ob.modifiers.new("Adoucissement", "BEVEL")
    bev.width = min(ep, pointe) * 0.45; bev.segments = 4
    for p in me.polygons:
        p.use_smooth = True
    return ob


def feuille_coeur(name, origine, X, Y, Z, L, W, mats, ep=0.018, nu=56, M=14, retombee=0.14, creux=0.05):
    """Une feuille en coeur, comme celle d'un pothos : deux lobes a la base,
    la plus large au premier tiers, une pointe effilee. Le limbe se creuse
    un peu en gouttiere, la pointe retombe, et une nervure court au milieu.

    Le repere : [X] en travers, [Y] le long du limbe, [Z] vers la face."""
    from math import exp
    EA, EB = 0.32, 0.80
    tm = EA / (EA + EB)
    envmax = (tm ** EA) * ((1.0 - tm) ** EB)

    def demi(t):
        t = min(max(t, 1e-4), 1.0 - 1e-4)
        env = (t ** EA) * ((1.0 - t) ** EB) / envmax
        lobe = 0.66 * (1.0 - (t / 0.30) ** 2) if t < 0.30 else 0.0
        return W * max(env, lobe)

    def pos(t, f):
        x = f * demi(t)
        # Les lobes descendent sous le point d'attache : c'est l'echancrure.
        y = L * t - L * 0.15 * (abs(f) ** 1.6) * ((1.0 - t) ** 5)
        z = creux * W * f * f - retombee * L * t * t \
            - 0.035 * W * exp(-(f / 0.14) ** 2) * (1.0 - t)
        return origine + X * x + Y * y + Z * z

    verts, faces = [], []
    cols = 2 * M + 1
    for i in range(nu):
        t = i / float(nu)
        for j in range(cols):
            f = (j - M) / float(M)
            verts.append(pos(t, f))
    pointe = len(verts)
    verts.append(pos(1.0, 0.0))
    for i in range(nu - 1):
        for j in range(cols - 1):
            a = i * cols + j
            faces.append((a, a + 1, a + cols + 1, a + cols))
    haut = (nu - 1) * cols
    for j in range(cols - 1):
        faces.append((haut + j, haut + j + 1, pointe))

    me = bpy.data.meshes.new(name)
    me.from_pydata([tuple(v) for v in verts], [], faces); me.update()
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    me.materials.append(mats["feuille"])
    bm = bmesh.new(); bm.from_mesh(me)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me); bm.free()
    for p in me.polygons:
        p.use_smooth = True
    sol = ob.modifiers.new("Epaisseur", "SOLIDIFY")
    sol.thickness = ep; sol.offset = 0.0
    bev = ob.modifiers.new("Adoucissement", "BEVEL")
    bev.width = 0.005; bev.segments = 2
    bev.limit_method = "ANGLE"; bev.angle_limit = radians(25)
    bev.use_clamp_overlap = True
    # La nervure centrale, posee sur la face, dans le vert plus clair de la tige.
    nerv = [pos(t, 0.0) + Z * (ep * 0.55) for t in (0.0, 0.2, 0.4, 0.6, 0.8, 0.92)]
    rayons = [ep * 0.75, ep * 0.62, ep * 0.50, ep * 0.38, ep * 0.26, ep * 0.14]
    nervure = tube_along(name + "_Nervure", nerv, rayons, mat=mats["tige"], seg=8, cap=3)
    return [ob, nervure]


# ------------------------------------------------------------
# la liane : une tige en arc, des noeuds, des feuilles entieres
# ------------------------------------------------------------
# La plante mere est une liane a feuilles entieres (un pothos, un
# philodendron) : c'est la bouture de tige la plus courante, et le noeud s'y
# lit bien. Chaque noeud porte une feuille ; le noeud choisi porte en plus une
# petite racine aerienne, celle qui deviendra racine.
#
# Un noeud : (t sur la tige, azimut de la feuille par rapport a la direction
# de la tige, petiole, limbe, inclinaison, roulis, racine aerienne).
LIANE_HERO = {
    "P0": Vector((0.08, -0.06, Z_TERRE - 0.03)),
    "P1": Vector((0.30, 0.05, Z_TERRE + 0.78)),
    "P2": Vector((1.28, 0.52, Z_TERRE + 0.98)),
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
        "P1": Vector((-0.18, 0.08, Z_TERRE + 0.66)),
        "P2": Vector((-0.70, -0.10, Z_TERRE + 0.58)),
        "r": (0.050, 0.034),
        "noeuds": [
            (0.46, 60.0, 0.26, 0.42, 26.0, 6.0, False),
            (1.00, -30.0, 0.24, 0.44, 40.0, -6.0, False),
        ],
    },
    {
        "P0": Vector((0.00, 0.10, Z_TERRE - 0.03)),
        "P1": Vector((-0.06, 0.26, Z_TERRE + 0.60)),
        "P2": Vector((-0.30, 0.62, Z_TERRE + 0.80)),
        "r": (0.048, 0.032),
        "noeuds": [
            (0.52, -70.0, 0.26, 0.42, 30.0, 4.0, False),
            (1.00, -60.0, 0.24, 0.42, 36.0, -4.0, False),
        ],
    },
]

# Ou l'on coupe la liane principale : juste sous le noeud choisi (le second).
T_COUPE = 0.555
NOEUD_CHOISI = 1
N_PETIOLE = 10
N_TIGE = 26


def _point_tige(spec, t):
    return bezier(spec["P0"], spec["P1"], spec["P2"], t)


def _rayon(spec, t):
    r0, r1 = spec["r"]
    return r0 + (r1 - r0) * t


def _dehors(spec, t):
    """La direction qui s'ecarte de l'axe du pot, a cet endroit de la tige."""
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
        horiz = Vector((cos(a), sin(a), 0.0))
        dehors = horiz
    else:
        horiz = Vector((dehors.x * cos(a) - dehors.y * sin(a), dehors.x * sin(a) + dehors.y * cos(a), 0.0))
    ti = radians(tilt + balancement)
    dirn = (horiz * cos(ti) + UP * sin(ti)).normalized()
    Lp_i = Lp * (0.3 + 0.7 * echelle)
    L_i = L * (0.15 + 0.85 * echelle)
    Q0 = N
    Q2 = N + dirn * Lp_i
    Q1 = N + dirn * (Lp_i * 0.5) + UP * (0.10 * Lp_i)
    pts, radii = [], []
    for i in range(N_PETIOLE + 1):
        s = i / float(N_PETIOLE)
        pts.append(tr(M, bezier(Q0, Q1, Q2, s) + (chute or Vector((0, 0, 0)))))
        radii.append((0.030 - 0.012 * s) * (0.6 + 0.4 * echelle))
    objets = [tube_along(prefix + "_Petiole", pts, radii, mat=mats["tige"])]
    T = (pts[-1] - pts[-2]).normalized()
    dehors_m = rot(M, dehors)
    # Le limbe ne prolonge pas le petiole : il s'inflechit vers le bas a
    # l'articulation, comme une feuille qui pend. Sa face regarde la camera
    # d'abord, le ciel ensuite, avec un appoint vers l'exterieur : de face
    # elle serait une affiche, de dessus une lame.
    pli = radians(38.0)
    Yl = (T * cos(pli) - UP * sin(pli)).normalized()
    F = (VUE * 0.70 + UP * 0.40 + dehors_m * 0.20).normalized()
    Zl = (F - F.dot(Yl) * Yl)
    if Zl.length < 0.2:
        # Petiole tourne vers l'arriere : la face garde le regard de la
        # camera, sinon la feuille se presenterait de chant.
        Zl = VUE - VUE.dot(Yl) * Yl
    Zl.normalize()
    Xl = Yl.cross(Zl)
    rr = radians(roll)
    Xl2 = Xl * cos(rr) + Zl * sin(rr)
    Zl2 = -Xl * sin(rr) + Zl * cos(rr)
    objets += feuille_coeur(prefix + "_Feuille", pts[-1] - T * 0.02, Xl2, Yl, Zl2, L=L_i, W=0.76 * L_i,
                            mats=mats, ep=0.018 * (0.7 + 0.3 * echelle))
    return objets


def liane(prefix, spec, mats, t0=0.0, t1=1.0, M=None, pousse=1.0, feuilles=None, racine_aerienne=1.0):
    """La tige de [t0] a [t1], ses noeuds et leurs feuilles, dans le repere
    [M]. [pousse] (0 a 1) la fait sortir de terre ; [feuilles] donne, par
    rang de noeud, les reglages d'une feuille qui se detache."""
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
        # Le noeud sort de terre avec la tige, la feuille s'ouvre ensuite.
        naissance = (t - t0) / max(t1 - t0, 1e-6) * 0.72
        echelle = adouci((pousse - naissance) / 0.30) if pousse < 1.0 else 1.0
        if echelle <= 0.0:
            continue
        centre = _point_tige(spec, t)
        objets.append(sphere(prefix + "_Noeud_%d" % k, tr(M, centre), _rayon(spec, t) * 1.42 * (0.5 + 0.5 * echelle), mats["tige"]))
        if noeud[6] and racine_aerienne > 0.0:
            # La racine aerienne : un bout de tube qui descend du noeud.
            d = (UP * -0.85 + _dehors(spec, t) * 0.35).normalized()
            rp = [tr(M, centre + d * (0.13 * racine_aerienne * s * echelle)) for s in (0.0, 0.4, 0.75, 1.0)]
            objets.append(tube_along(prefix + "_Aerienne", rp, [0.017, 0.016, 0.013, 0.008], mat=mats["racine"]))
        reglage = feuilles.get(k, {})
        objets += feuille_et_petiole(prefix + "_N%d" % k, spec, noeud, M, echelle=echelle * reglage.get("echelle", 1.0),
                                     mats=mats, balancement=reglage.get("balancement", 0.0), chute=reglage.get("chute"))
    return objets


def pot_et_terre(mats, echelle=1.0):
    pot = revolve("Pot", POT_PROFIL, 96, [mats["pot"]], 34.0)
    terre = revolve("Terre", TERRE_PROFIL, 96, [mats["terre"]], 40.0)
    for ob in (pot, terre):
        ob.scale = (echelle, echelle, echelle)
    return [pot, terre]


def plante_mere(mats, pousse=1.0, hero_t1=1.0):
    objets = pot_et_terre(mats)
    for i, spec in enumerate(LIANES_AUTRES):
        objets += liane("Liane%d" % (i + 2), spec, mats, pousse=borne(pousse * 1.15 - 0.10 * i))
    objets += liane("Liane1", LIANE_HERO, mats, t1=hero_t1, pousse=pousse)
    return objets


# ------------------------------------------------------------
# la bouture seule : le brin coupe, tenu droit
# ------------------------------------------------------------
# A partir de la troisieme etape, la bouture est le sujet : elle a sa propre
# tige, presque verticale, penchee d'un rien vers la droite de l'ecran, et
# ses feuilles sont placees pour la camera (azimuts absolus). Le noeud choisi
# est le premier, juste au-dessus de la coupe ; sa feuille est celle qu'on
# retire, sa racine aerienne celle qui devient racine.
LIANE_BOUTURE = {
    "P0": Vector((0.0, 0.0, 0.0)),
    "P1": Vector((0.02, 0.00, 0.70)),
    "P2": Vector((0.16, 0.10, 1.50)),
    "r": (0.046, 0.036),
    "absolu": True,
    "noeuds": [
        (0.14, 15.0, 0.30, 0.44, 18.0, 6.0, True),
        (0.62, 222.0, 0.30, 0.46, 28.0, -8.0, False),
        (1.00, 300.0, 0.24, 0.46, 42.0, 4.0, False),
    ],
}
NOEUD_BOUTURE = 0


def repere_bouture(cible=Vector((0, 0, 0))):
    """La bouture posee en [cible] : c'est la que se trouve sa coupe."""
    return Matrix.Translation(cible)


def bouture(mats, M, feuilles=None, racines=0.0, garde_basse=True):
    """Le brin coupe, avec ou sans sa feuille du bas, et des racines qui
    poussent du noeud choisi ([racines] de 0 a 1)."""
    feuilles = dict(feuilles or {})
    if not garde_basse:
        feuilles[NOEUD_BOUTURE] = {"echelle": 0.0}
    objets = liane("Bouture", LIANE_BOUTURE, mats, M=M, feuilles=feuilles)
    if racines > 0.0:
        objets += racines_du_noeud(M, mats, racines)
    return objets


# Les racines : cinq brins qui partent du noeud, chacun a son heure, en
# serpentant vers le bas. Leur trace est fixe ; seule la longueur parcourue
# change d'une image a l'autre, si bien qu'une racine s'allonge sans jamais
# se tordre.
RACINES = [
    (0.00, (0.55, -0.30), 0.55),
    (0.10, (-0.45, 0.45), 0.50),
    (0.18, (0.10, 0.62), 0.44),
    (0.28, (-0.62, -0.25), 0.40),
    (0.36, (0.30, 0.10), 0.34),
]


def racines_du_noeud(M, mats, avancement):
    t = LIANE_BOUTURE["noeuds"][NOEUD_BOUTURE][0]
    N = tr(M, _point_tige(LIANE_BOUTURE, t))
    objets = []
    for i, (depart, (dx, dy), longueur) in enumerate(RACINES):
        part = adouci((avancement - depart) / 0.55)
        if part <= 0.03:
            continue
        chemin = []
        n = 18
        for k in range(n + 1):
            s = k / float(n)
            # Ondulation qui s'amplifie en descendant, propre a chaque racine.
            ond = 0.045 * sin(s * 5.5 + i * 1.7) * s
            p = N + Vector((dx, dy, 0.0)) * (0.16 * s + ond) + UP * (-longueur * s) \
                + Vector((-dy, dx, 0.0)) * (0.035 * sin(s * 4.0 + i))
            chemin.append(p)
        m = max(2, int(round(part * n)))
        pts = chemin[:m + 1]
        # L'extremite avance entre deux points, pour que la pousse soit continue.
        if m < n:
            reste = part * n - m
            pts[-1] = chemin[m] * (1.0 - reste) + chemin[m + 1] * reste
        radii = [0.034 - 0.020 * (k / float(len(pts) - 1)) for k in range(len(pts))]
        objets.append(tube_along("Racine_%d" % i, pts, radii, mat=mats["racine"], seg=10))
    return objets


# ------------------------------------------------------------
# les ciseaux
# ------------------------------------------------------------
LAME = 0.56


def ciseaux(mats, pivot, Y, Z, ouverture):
    """Deux lames et deux anneaux ovales, articules en [pivot], dans le plan
    (Y, Z) ou Y est l'axe des lames et Z regarde la camera. [ouverture] en
    degres."""
    Y = Vector(Y).normalized()
    Z = Vector(Z).normalized()
    X = Y.cross(Z).normalized()
    base = Matrix((
        (X.x, Y.x, Z.x, pivot.x),
        (X.y, Y.y, Z.y, pivot.y),
        (X.z, Y.z, Z.z, pivot.z),
        (0, 0, 0, 1),
    ))
    objets = []
    for signe, nom in ((1.0, "A"), (-1.0, "B")):
        R = Matrix.Rotation(radians(ouverture / 2.0) * signe, 4, "Z")
        M = base @ R @ Matrix.Translation(Vector((0, 0, 0.011 * signe)))
        objets.append(lame("Lame_" + nom, M, LAME, 0.10, 0.024, 0.022, mats["acier"]))
        # Le bras, puis l'anneau ovale, allonge dans l'axe du bras.
        bras = [M @ Vector((0, -0.02, 0)), M @ Vector((0, -0.20, 0))]
        objets.append(tube_along("Bras_" + nom, bras, [0.036, 0.034], mat=mats["poignee"], seg=12, cap=3))
        centre = M @ Vector((0.0, -0.36, 0.0))
        objets.append(anneau("Anneau_" + nom, centre, rot(M, (0, 0, 1)), 0.115, 0.038, mats["poignee"],
                             long=rot(M, (0, 1, 0)), etire=1.38))
    objets.append(sphere("Rivet", pivot, 0.040, mats["poignee"], seg=18))
    return objets


# ------------------------------------------------------------
# les six etapes
# ------------------------------------------------------------
def materiaux():
    return {
        "feuille": make_mat("MAT_Feuille", "18693C", 0.52, 0.32, grain=60.0, relief=0.008, sss=0.14),
        "tige": make_mat("MAT_Tige", "2E8B57", 0.55, 0.26, grain=55.0, relief=0.008, sss=0.12),
        "pot": make_mat("MAT_Pot", "C87A57", 0.68, 0.18, grain=34.0, relief=0.024, sss=0.10),
        "terre": make_mat("MAT_Terre", "3B302A", 0.90, 0.06, grain=20.0, relief=0.040, sss=0.0),
        "racine": make_mat("MAT_Racine", "C9A472", 0.60, 0.20, grain=50.0, relief=0.010, sss=0.15),
        "anneau": make_mat("MAT_Anneau", "F2B84B", 0.48, 0.30, grain=40.0, relief=0.006, sss=0.10),
        "acier": make_mat("MAT_Acier", "D6DBDF", 0.30, 0.60, grain=80.0, relief=0.003, sss=0.0),
        "poignee": make_mat("MAT_Poignee", "D9694B", 0.58, 0.22, grain=40.0, relief=0.012, sss=0.10),
        "verre": None,
        "eau": None,
    }


def materiau_voile(name, hexval, transparence, rough, spec=0.5):
    """Un verre d'illustration : une surface mate et claire, melee de
    transparence pure, sans refraction. Un vrai verre en transmission
    grouille de bruit a ces reglages, assombrit ce qu'il contient et porte
    le fond gris du monde ; le voile laisse voir les racines et passe le
    fond transparent tel quel."""
    from clay_scene import hexcol
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    b = nt.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = hexcol(hexval)
    b.inputs["Roughness"].default_value = rough
    for key in ("Specular IOR Level", "Specular"):
        if key in b.inputs:
            b.inputs[key].default_value = spec
    sortie = nt.nodes["Material Output"]
    transparent = nt.nodes.new("ShaderNodeBsdfTransparent")
    mix = nt.nodes.new("ShaderNodeMixShader")
    mix.inputs["Fac"].default_value = transparence
    nt.links.new(b.outputs["BSDF"], mix.inputs[1])
    nt.links.new(transparent.outputs["BSDF"], mix.inputs[2])
    nt.links.new(mix.outputs["Shader"], sortie.inputs["Surface"])
    mat.blend_method = "BLEND"
    return mat


VERRE_H = 1.25
VERRE_PROFIL = [(r, z * VERRE_H) for (r, z) in [
    (0.0, 0.0), (0.29, 0.0), (0.335, 0.018), (0.348, 0.10), (0.372, 0.58), (0.388, 0.94), (0.388, 0.965),
    (0.362, 0.965), (0.348, 0.58), (0.322, 0.10), (0.30, 0.066), (0.0, 0.066),
]]


def rayon_interieur(z):
    """Le rayon de la paroi interieure du verre a la hauteur [z]."""
    paroi = [(0.322, 0.10 * VERRE_H), (0.348, 0.58 * VERRE_H), (0.362, 0.965 * VERRE_H)]
    for (r0, z0), (r1, z1) in zip(paroi, paroi[1:]):
        if z <= z1:
            return r0 + (r1 - r0) * borne((z - z0) / (z1 - z0))
    return paroi[-1][0]


def verre_et_eau(mats, niveau):
    verre = revolve("Verre", VERRE_PROFIL, 96, [mats["verre"]], 30.0)
    fond = 0.066 * VERRE_H
    profil = [(0.0, fond + 0.004), (0.30, fond + 0.004), (0.322 + 0.003, 0.10 * VERRE_H),
              (rayon_interieur(niveau) + 0.003, niveau), (0.0, niveau)]
    eau = revolve("Eau", profil, 96, [mats["eau"]], 40.0)
    return [verre, eau]


def anneau_du_noeud(mats, taille):
    """L'anneau marque l'endroit de la coupe : juste sous le noeud choisi,
    la ou les ciseaux se fermeront a l'etape suivante."""
    if taille <= 0.02:
        return []
    t = T_COUPE
    centre = _point_tige(LIANE_HERO, t)
    axe = tangente(LIANE_HERO["P0"], LIANE_HERO["P1"], LIANE_HERO["P2"], t)
    return [anneau("Anneau_Noeud", centre, axe, 0.160 * taille, 0.034 * taille, mats["anneau"])]


def etape_tige(mats, f):
    # La plante pousse, puis l'anneau se pose sur le noeud choisi.
    pousse = adouci(f / 0.55)
    return plante_mere(mats, pousse=pousse) + anneau_du_noeud(mats, rebond((f - 0.58) / 0.30))


def etape_coupe(mats, f):
    approche = adouci(f / 0.30)
    fermeture = adouci((f - 0.34) / 0.11)
    retrait = adouci((f - 0.54) / 0.32)
    levee = adouci((f - 0.52) / 0.42)
    coupe = fermeture >= 0.999
    C = _point_tige(LIANE_HERO, T_COUPE)
    T = tangente(LIANE_HERO["P0"], LIANE_HERO["P1"], LIANE_HERO["P2"], T_COUPE)
    # L'axe des lames : en travers de la tige, dans le plan de l'ecran, et
    # vers le bas. Les ciseaux viennent d'en haut, comme une main qui coupe.
    Y = T.cross(VUE).normalized()
    if Y.dot(UP) > 0:
        Y = -Y
    objets = pot_et_terre(mats)
    for i, spec in enumerate(LIANES_AUTRES):
        objets += liane("Liane%d" % (i + 2), spec, mats)
    # Le pied de la liane reste ; le brin coupe se souleve.
    objets += liane("Liane1", LIANE_HERO, mats, t1=T_COUPE - (0.012 if coupe else 0.0))
    if coupe:
        M = Matrix.Translation((UP * 0.50 + DROITE * 0.16 + VUE * 0.06) * levee) \
            @ Matrix.Translation(C) @ Matrix.Rotation(radians(-14.0) * levee, 4, VUE) @ Matrix.Translation(-C)
        objets += liane("Liane1_Bouture", LIANE_HERO, mats, t0=T_COUPE + 0.012, M=M)
    else:
        objets += liane("Liane1_Haut", LIANE_HERO, mats, t0=T_COUPE)
    # La tige repose sur les lames, a un tiers de leur longueur depuis le
    # pivot : c'est la que des ciseaux coupent, pas au rivet.
    cible = C - Y * (0.36 * LAME) + VUE * 0.03
    depart = UP * 0.85 + DROITE * 0.60
    pivot = cible + depart * (1.0 - approche) + (UP * 0.55 + DROITE * 0.42) * retrait
    ouverture = 38.0 * (1.0 - fermeture) + 24.0 * retrait
    # Un leger balancement a l'arrivee : les ciseaux se redressent en se posant.
    bascule = Matrix.Rotation(radians(-18.0) * (1.0 - approche) + radians(10.0) * retrait, 3, VUE)
    objets += ciseaux(mats, pivot, bascule @ Y, VUE, ouverture)
    return objets


def etape_feuilles(mats, f):
    M = repere_bouture()
    balance = adouci((f - 0.15) / 0.30)
    chute = adouci((f - 0.32) / 0.45)
    reglage = {
        "balancement": -55.0 * balance,
        "chute": UP * (-0.55 * chute) + DROITE * (0.10 * chute),
        "echelle": 1.0 - adouci((chute - 0.45) / 0.55),
    }
    return bouture(mats, M, feuilles={NOEUD_BOUTURE: reglage})


NIVEAU_EAU = 0.84
# Ou se pose la coupe dans le verre : le noeud finit sous la surface, les
# feuilles au-dessus du bord.
POSE_VERRE = Vector((0.02, 0.0, 0.46))


def etape_eau(mats, f):
    descente = adouci(f / 0.70)
    # La bouture entre par le haut ; le noeud finit sous la surface.
    M = Matrix.Translation(UP * (0.80 * (1.0 - descente))) @ repere_bouture(cible=POSE_VERRE)
    # L'eau monte d'un rien quand la tige y entre.
    niveau = NIVEAU_EAU + 0.03 * adouci((f - 0.45) / 0.25)
    return verre_et_eau(mats, niveau) + bouture(mats, M, garde_basse=False)


def etape_racines(mats, f):
    M = repere_bouture(cible=POSE_VERRE)
    return verre_et_eau(mats, NIVEAU_EAU + 0.03) + bouture(mats, M, garde_basse=False, racines=adouci(f / 0.92))


def etape_pot(mats, f):
    descente = adouci(f / 0.68)
    echelle = 0.90
    # La coupe finit dans le pot, le noeud juste sous la terre, les racines
    # au-dessus du fond.
    M = Matrix.Translation(UP * (0.75 * (1.0 - descente))) @ repere_bouture(cible=Vector((0.0, 0.0, Z_TERRE * echelle - 0.25)))
    return pot_et_terre(mats, echelle) + bouture(mats, M, garde_basse=False, racines=1.0)


ETAPES = [
    ("etape_1", 30, etape_tige, (0.0, 0.55, 1.0)),
    ("etape_2", 38, etape_coupe, (0.0, 0.30, 0.46, 1.0)),
    ("etape_3", 30, etape_feuilles, (0.0, 0.5, 1.0)),
    ("etape_4", 30, etape_eau, (0.0, 1.0)),
    ("etape_5", 36, etape_racines, (0.0, 1.0)),
    ("etape_6", 32, etape_pot, (0.0, 1.0)),
]


def efface(objets):
    for ob in objets:
        me = ob.data
        bpy.data.objects.remove(ob, do_unlink=True)
        if me and me.users == 0:
            bpy.data.meshes.remove(me)


for nom, images, construire, cles in ETAPES:
    if SEULE and nom != SEULE:
        continue
    purge()
    bpy.context.scene.name = "Bouture_" + nom
    mats = materiaux()
    mats["verre"] = materiau_voile("MAT_Verre", "F4F8FA", 0.90, 0.12, spec=0.8)
    mats["eau"] = materiau_voile("MAT_Eau", "8FCBDF", 0.76, 0.35, spec=0.4)
    # Le cadre est celui de l'union des images clefs : il ne bouge pas
    # pendant la sequence.
    proxies = []
    for c in cles:
        proxies += construire(mats, c)
    studio(proxies, fill=0.80)
    efface(proxies)
    rendu_transparent(RES, SAMPLES)
    sc = bpy.context.scene
    # Le verre et l'eau sont des voiles : les rayons les traversent plusieurs
    # fois avant d'atteindre le fond.
    sc.cycles.transparent_max_bounces = 24
    dossier = os.path.join(DOSSIER, nom)
    os.makedirs(dossier, exist_ok=True)
    rangs = list(range(images))
    if APERCU:
        rangs = [0, images // 3, (2 * images) // 3, images - 1]
    for i in rangs:
        f = i / float(images - 1)
        objets = construire(mats, f)
        chemin = os.path.join(dossier, "%s_%03d.png" % (nom, i))
        sc.render.filepath = chemin
        bpy.ops.render.render(write_still=True)
        grain(chemin)
        efface(objets)
        print("IMAGE %s %d/%d" % (nom, i + 1, images), flush=True)

print("GUIDE:", DOSSIER)
