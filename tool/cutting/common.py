# ============================================================
# La boite a outils commune aux six guides de multiplication.
#
# Tout ce qui se repete d'un guide a l'autre est ici : les fonctions
# d'amorti, les primitives de geometrie (limbe plat, lame charnue, anneau,
# ciseaux, pot, verre, motte, racines), la palette, et la boucle de rendu.
# Un guide (tool/cutting/<nom>.py) n'ecrit plus que sa plante et ses gestes.
#
# Rien ne s'execute a l'import : les scripts qui s'en servent construisent
# leur propre scene.
# ============================================================
import bpy, bmesh, os, sys
from mathutils import Vector, Matrix
from math import cos, sin, pi, radians, sqrt

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from clay_scene import (  # noqa: E402  — le chemin doit etre pose avant
    POT_PROFIL, TERRE_PROFIL, VUE, Z_TERRE,
    grain, hexcol, make_mat, purge, rendu_transparent, revolve, studio, tube_along,
)

UP = Vector((0, 0, 1))
# Vers la droite de l'ecran : la camera regarde depuis l'azimut -58 degres.
DROITE = Vector((cos(radians(32.0)), sin(radians(32.0)), 0.0))
# Vers le fond de l'ecran, a plat : ce qui s'eloigne de la camera.
FOND = Vector((VUE.x, VUE.y, 0.0)).normalized()


# ------------------------------------------------------------
# amortis et courbes
# ------------------------------------------------------------
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


def repos(u, n=3.0):
    """Amorti qui part vite et se pose : pour un objet qu'on lache."""
    u = borne(u)
    return 1.0 - (1.0 - u) ** n


def melange(a, b, t):
    return a + (b - a) * borne(t)


def bezier(P0, P1, P2, t):
    u = 1.0 - t
    return P0 * (u * u) + P1 * (2.0 * u * t) + P2 * (t * t)


def tangente(P0, P1, P2, t):
    return ((P1 - P0) * (2.0 * (1.0 - t)) + (P2 - P1) * (2.0 * t)).normalized()


def tr(M, p):
    return M @ Vector(p)


def rot(M, v):
    return (M.to_3x3() @ Vector(v)).normalized()


def pivote(centre, axe, angle_deg):
    """Une rotation de [angle_deg] autour de [axe] passant par [centre]."""
    C = Vector(centre)
    return Matrix.Translation(C) @ Matrix.Rotation(radians(angle_deg), 4, Vector(axe)) @ Matrix.Translation(-C)


# ------------------------------------------------------------
# primitives
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


def _maille(name, verts, faces, mat, lisse=True, souder=True):
    me = bpy.data.meshes.new(name)
    me.from_pydata([tuple(v) for v in verts], [], faces); me.update()
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    if mat:
        me.materials.append(mat)
    if souder:
        bm = bmesh.new(); bm.from_mesh(me)
        bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
        bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        bm.to_mesh(me); bm.free()
    for p in me.polygons:
        p.use_smooth = lisse
    return ob


def sphere(name, centre, r, mat, seg=24, echelle=(1.0, 1.0, 1.0)):
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=seg, v_segments=seg // 2, radius=r,
                              matrix=Matrix.Translation(Vector(centre)))
    ob = _objet(name, bm, mat)
    if echelle != (1.0, 1.0, 1.0):
        # Mise a l'echelle autour du centre : un caillou de terre, un bulbe.
        C = Vector(centre)
        me = ob.data
        for v in me.vertices:
            d = Vector(v.co) - C
            v.co = C + Vector((d.x * echelle[0], d.y * echelle[1], d.z * echelle[2]))
    return ob


def anneau(name, centre, axe, R, r, mat, seg=48, sec=16, long=None, etire=1.0):
    """Un tore de rayon [R], de section [r], autour de [axe]. Donne [long] et
    [etire] pour l'allonger dans cette direction : les anneaux d'une paire de
    ciseaux sont ovales."""
    Z = Vector(axe).normalized()
    X = Vector(long) - Vector(long).dot(Z) * Z if long is not None else UP.cross(Z)
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
            a0, a1 = i * sec + j, i * sec + (j + 1) % sec
            b0, b1 = ((i + 1) % seg) * sec + j, ((i + 1) % seg) * sec + (j + 1) % sec
            faces.append((a0, b0, b1, a1))
    return _maille(name, verts, faces, mat, souder=False)


def marque(name, centre, R, mat, axe=None, epaisseur=0.030, taille=1.0):
    """L'anneau pedagogique : celui qui dit « c'est ici ». Toujours de la
    couleur d'accent, toujours de face — il est lu, pas regarde."""
    if taille <= 0.02:
        return []
    return [anneau(name, centre, axe or VUE, R * taille, epaisseur * taille, mat, seg=56, sec=12)]


def lame(name, M, longueur, base, pointe, ep, mat):
    """Une lame de ciseaux : une dalle effilee, le long de +Y du repere [M],
    adoucie par un biseau."""
    pts = [(-base / 2, 0, -ep / 2), (base / 2, 0, -ep / 2), (pointe / 2, longueur, -ep / 2), (-pointe / 2, longueur, -ep / 2),
           (-base / 2, 0, ep / 2), (base / 2, 0, ep / 2), (pointe / 2, longueur, ep / 2), (-pointe / 2, longueur, ep / 2)]
    faces = [(0, 1, 2, 3), (4, 7, 6, 5), (0, 4, 5, 1), (1, 5, 6, 2), (2, 6, 7, 3), (3, 7, 4, 0)]
    ob = _maille(name, [M @ Vector(p) for p in pts], faces, mat, souder=False)
    bev = ob.modifiers.new("Adoucissement", "BEVEL")
    bev.width = min(ep, pointe) * 0.45; bev.segments = 4
    return ob


def ruban_along(name, pts, demi_l, demi_e, face=(0, 0, 1), seg=18, mat=None,
                cap_debut=0.0, cap_fin=0.0):
    """Une lame charnue : une section elliptique de demi-largeur [demi_l] et
    de demi-epaisseur [demi_e] promenee le long de [pts]. [face] donne la
    normale de la lame ; [cap_debut] et [cap_fin], en unites de section,
    arrondissent les bouts (0 les laisse francs).

    C'est ce qui porte les feuilles d'aloe, les tiges tendres et les
    segments de cactus : un tube, mais aplati."""
    P = [Vector(p) for p in pts]
    T = []
    for i in range(len(P)):
        if i == 0:
            t = P[1] - P[0]
        elif i == len(P) - 1:
            t = P[-1] - P[-2]
        else:
            t = P[i + 1] - P[i - 1]
        T.append(t.normalized())
    N = Vector(face).normalized()

    # Les bouts arrondis sont donnes en fraction de la section : un cap de
    # 0.5 avance d'une demi-largeur, quelle que soit l'echelle de l'objet.
    l0 = max(demi_l[0], demi_e[0], 1e-6)
    l1 = max(demi_l[-1], demi_e[-1], 1e-6)
    ech = []
    for j in range(4, 0, -1):
        s = j / 4.0
        ech.append((-cap_debut * l0 * s, 0, sqrt(max(0.0, 1.0 - s * s))))
    for i in range(len(P)):
        ech.append((0.0, i, 1.0))
    for j in range(1, 5):
        s = j / 4.0
        ech.append((cap_fin * l1 * s, len(P) - 1, sqrt(max(0.0, 1.0 - s * s))))

    verts, rings = [], []
    for (avance, i, k) in ech:
        i = int(i)
        c = P[i] + T[i] * avance
        a = (N.cross(T[i]))
        if a.length < 1e-4:
            a = Vector((1, 0, 0)).cross(T[i])
        a.normalize()
        b = T[i].cross(a).normalized()
        rl, re = demi_l[i] * k, demi_e[i] * k
        if rl < 1e-5 and re < 1e-5:
            rings.append(("P", [len(verts)])); verts.append(c)
            continue
        idx = []
        for m in range(seg):
            ang = 2.0 * pi * m / seg
            idx.append(len(verts))
            verts.append(c + a * (rl * cos(ang)) + b * (re * sin(ang)))
        rings.append(("R", idx))

    faces = []
    for i in range(len(rings) - 1):
        ti, ri = rings[i]; tj, rj = rings[i + 1]
        if ti == "P" and tj == "P":
            # Deux pointes qui se suivent : rien a coudre. C'est le cas d'un
            # bout effile, ou le cap et la derniere section se confondent.
            continue
        if ti == "P":
            for k in range(seg):
                faces.append((ri[0], rj[k], rj[(k + 1) % seg]))
        elif tj == "P":
            for k in range(seg):
                faces.append((rj[0], ri[(k + 1) % seg], ri[k]))
        else:
            for k in range(seg):
                k2 = (k + 1) % seg
                faces.append((ri[k], ri[k2], rj[k2], rj[k]))
    return _maille(name, verts, faces, mat)


def limbe(name, repere, demi, mat, L=1.0, t0=0.0, t1=1.0, nu=48, M=12, ep=0.018,
          encoche=0.0, releve=None, creux=0.06, bevel=0.005, nervure=None):
    """Un limbe plat : la surface reglee d'une feuille, epaissie ensuite.

    [repere] est (origine, X, Y, Z) : X en travers, Y le long, Z vers la face.
    [demi](t) donne la demi-largeur a l'abscisse t (0 a 1), en unites de [L].
    [releve](t) donne la hauteur du nervure centrale hors du plan (la
    courbure de la feuille), [creux] la gouttiere, [encoche] la profondeur
    du V de la base — celui qui dit, sur un segment de sansevieria, quel
    bout va en terre.

    Rend la liste des objets : le limbe, et sa nervure si [nervure] donne un
    materiau."""
    origine, X, Y, Z = repere
    releve = releve or (lambda t: 0.0)

    def pos(t, f):
        w = demi(t)
        x = f * w * L
        return origine + X * x + Y * (L * t) + Z * (releve(t) * L + creux * L * (f * f) * w)

    verts, faces = [], []
    cols = 2 * M + 1
    for i in range(nu + 1):
        u = i / float(nu)
        for j in range(cols):
            f = (j - M) / float(M)
            depart = t0 + encoche * (1.0 - abs(f))
            verts.append(pos(depart + (t1 - depart) * u, f))
    for i in range(nu):
        for j in range(cols - 1):
            a = i * cols + j
            faces.append((a, a + 1, a + cols + 1, a + cols))

    ob = _maille(name, verts, faces, mat)
    sol = ob.modifiers.new("Epaisseur", "SOLIDIFY")
    sol.thickness = ep; sol.offset = 0.0
    bev = ob.modifiers.new("Adoucissement", "BEVEL")
    bev.width = bevel; bev.segments = 2
    bev.limit_method = "ANGLE"; bev.angle_limit = radians(28)
    bev.use_clamp_overlap = True
    objets = [ob]
    if nervure is not None:
        ts = [t0 + (t1 - t0) * s for s in (0.02, 0.22, 0.45, 0.68, 0.88, 0.99)]
        pts = [pos(t, 0.0) + Z * (ep * 0.55) for t in ts]
        rayons = [ep * 0.80 * (1.0 - 0.75 * s / 5.0) for s in range(6)]
        objets.append(tube_along(name + "_Nervure", pts, rayons, mat=nervure, seg=8, cap=3))
    return objets


def repere_face(origine, direction, roulis=0.0, appoint=None, vers_camera=0.72):
    """Un repere de feuille : [direction] est le fil du limbe, sa face
    regarde la camera d'abord, le ciel ensuite. [roulis] en degres la fait
    tourner sur son fil ; [vers_camera] dose le regard vers l'objectif — a
    le baisser, les feuilles se presentent plus librement et la touffe cesse
    d'etre une affiche."""
    Y = Vector(direction).normalized()
    F = (VUE * vers_camera + UP * 0.38 + (appoint or Vector((0, 0, 0))) * 0.22)
    Z = F - F.dot(Y) * Y
    if Z.length < 0.2:
        Z = VUE - VUE.dot(Y) * Y
    Z.normalize()
    X = Y.cross(Z)
    r = radians(roulis)
    return (Vector(origine), X * cos(r) + Z * sin(r), Y, -X * sin(r) + Z * cos(r))


# ------------------------------------------------------------
# la palette
# ------------------------------------------------------------
def materiau_voile(name, hexval, transparence, rough, spec=0.5):
    """Un verre d'illustration : une surface mate et claire, melee de
    transparence pure, sans refraction. Un vrai verre en transmission
    grouille de bruit a ces reglages, assombrit ce qu'il contient et porte
    le fond gris du monde ; le voile laisse voir les racines et passe le
    fond transparent tel quel."""
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    b = nt.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = hexcol(hexval)
    b.inputs["Roughness"].default_value = rough
    for key in ("Specular IOR Level", "Specular"):
        if key in b.inputs:
            b.inputs[key].default_value = spec
    transparent = nt.nodes.new("ShaderNodeBsdfTransparent")
    mix = nt.nodes.new("ShaderNodeMixShader")
    mix.inputs["Fac"].default_value = transparence
    nt.links.new(b.outputs["BSDF"], mix.inputs[1])
    nt.links.new(transparent.outputs["BSDF"], mix.inputs[2])
    nt.links.new(mix.outputs["Shader"], nt.nodes["Material Output"].inputs["Surface"])
    mat.blend_method = "BLEND"
    return mat


def materiaux():
    """Les matieres de tous les guides. Un seul jeu : une racine a la meme
    couleur qu'elle sorte d'un noeud de pothos ou d'un rejet d'aloe."""
    m = {
        "feuille": make_mat("MAT_Feuille", "18693C", 0.52, 0.32, grain=60.0, relief=0.008, sss=0.14),
        "feuille_claire": make_mat("MAT_FeuilleClaire", "2F8B4C", 0.52, 0.32, grain=60.0, relief=0.008, sss=0.16),
        "pousse": make_mat("MAT_Pousse", "5FAE63", 0.50, 0.34, grain=62.0, relief=0.007, sss=0.20),
        "tige": make_mat("MAT_Tige", "2E8B57", 0.55, 0.26, grain=55.0, relief=0.008, sss=0.12),
        "tige_tendre": make_mat("MAT_TigeTendre", "4E9E5C", 0.54, 0.28, grain=58.0, relief=0.007, sss=0.18),
        "charnu": make_mat("MAT_Charnu", "5D9A6B", 0.50, 0.30, grain=52.0, relief=0.009, sss=0.24),
        "cactus": make_mat("MAT_Cactus", "3E8C5A", 0.53, 0.28, grain=56.0, relief=0.010, sss=0.18),
        "pot": make_mat("MAT_Pot", "C87A57", 0.68, 0.18, grain=34.0, relief=0.024, sss=0.10),
        "terre": make_mat("MAT_Terre", "3B302A", 0.90, 0.06, grain=20.0, relief=0.040, sss=0.0),
        # La motte est vue en entier, pas par un disque au fond d'un pot :
        # au noir de la terre tassee, elle prefere un brun qui garde du relief.
        "motte": make_mat("MAT_Motte", "5C4636", 0.92, 0.07, grain=18.0, relief=0.044, sss=0.0),
        "terre_drainante": make_mat("MAT_TerreDrainante", "7A6B5A", 0.92, 0.08, grain=16.0, relief=0.046, sss=0.0),
        "racine": make_mat("MAT_Racine", "C9A472", 0.60, 0.20, grain=50.0, relief=0.010, sss=0.15),
        "racine_fine": make_mat("MAT_RacineFine", "DCC59A", 0.58, 0.22, grain=64.0, relief=0.008, sss=0.18),
        "anneau": make_mat("MAT_Anneau", "F2B84B", 0.48, 0.30, grain=40.0, relief=0.006, sss=0.10),
        "acier": make_mat("MAT_Acier", "D6DBDF", 0.30, 0.60, grain=80.0, relief=0.003, sss=0.0),
        "poignee": make_mat("MAT_Poignee", "D9694B", 0.58, 0.22, grain=40.0, relief=0.012, sss=0.10),
    }
    m["verre"] = materiau_voile("MAT_Verre", "F4F8FA", 0.90, 0.12, spec=0.8)
    m["eau"] = materiau_voile("MAT_Eau", "8FCBDF", 0.76, 0.35, spec=0.4)
    return m


# Une plaie : fraiche (verte, humide, luisante) puis seche (ivoire, mate).
PLAIE_FRAICHE, PLAIE_SECHE = "86BC66", "E8DDC2"


def plaie_ovale(name, centre, axe, face, demi_l, demi_e, sechage, saillie=0.018):
    """La tranche d'une coupe, vue comme un ovale : une lentille posee dans
    le plan de la section, de la couleur de la plaie. C'est elle qui doit
    passer de fraiche a seche sous les yeux."""
    Y = Vector(axe).normalized()
    C = Vector(centre)
    pts = [C - Y * (saillie * 0.5), C + Y * (saillie * 0.5)]
    return [ruban_along(name, pts, [demi_l, demi_l], [demi_e, demi_e], face=face, seg=22,
                        mat=materiau_plaie(sechage), cap_debut=0.55, cap_fin=0.2)]


def materiau_plaie(sechage):
    """La matiere d'une coupe, de fraiche (0) a cicatrisee (1). Pas de
    realisme : une teinte qui pale et une surface qui se mate, rien d'autre."""
    a, b = hexcol(PLAIE_FRAICHE), hexcol(PLAIE_SECHE)
    t = borne(sechage)
    mel = "".join("%02X" % round(melange(int(PLAIE_FRAICHE[i:i + 2], 16), int(PLAIE_SECHE[i:i + 2], 16), t))
                  for i in (0, 2, 4))
    del a, b
    return make_mat("MAT_Plaie_%03d" % round(t * 100), mel, melange(0.18, 0.92, t), melange(0.70, 0.06, t),
                    grain=70.0, relief=melange(0.004, 0.014, t), sss=melange(0.26, 0.02, t))


# ------------------------------------------------------------
# le pot, la terre, la motte
# ------------------------------------------------------------
def pot_et_terre(mats, echelle=1.0, decalage=None, terre="terre", nom="Pot"):
    pot = revolve(nom, POT_PROFIL, 96, [mats["pot"]], 34.0)
    sol = revolve(nom + "_Terre", TERRE_PROFIL, 96, [mats[terre]], 40.0)
    for ob in (pot, sol):
        ob.scale = (echelle, echelle, echelle)
        if decalage is not None:
            ob.location = Vector(decalage)
    return [pot, sol]


def z_terre(echelle=1.0, decalage=None):
    return Z_TERRE * echelle + (Vector(decalage).z if decalage is not None else 0.0)


# Le profil de la motte : ce que le pot laisse quand on l'ote.
MOTTE_PROFIL = [(0.0, 0.055), (0.20, 0.050), (0.34, 0.066), (0.425, 0.115),
                (0.470, 0.24), (0.505, 0.46), (0.536, 0.70), (0.556, 0.855),
                (0.500, 0.892), (0.30, 0.902), (0.0, 0.906)]


def motte(mats, echelle=1.0, decalage=None, serre=1.0, nom="Motte"):
    """La motte : la terre du pot, tenue par les racines. [serre] la resserre
    quand on l'emiette."""
    profil = [(r * melange(0.70, 1.0, serre), z * melange(0.94, 1.0, serre)) for (r, z) in MOTTE_PROFIL]
    ob = revolve(nom, profil, 72, [mats["motte"]], 46.0)
    ob.scale = (echelle, echelle, echelle)
    if decalage is not None:
        ob.location = Vector(decalage)
    return [ob]


def racines_motte(mats, echelle=1.0, decalage=None, densite=10, sortie=0.0, graine=0, nom="RacineMotte"):
    """Quelques racines qui courent sur la motte. [sortie] (0 a 1) les
    degage : d'abord plaquees, puis libres quand la terre tombe."""
    if sortie <= 0.02:
        return []
    D = Vector(decalage) if decalage is not None else Vector((0, 0, 0))
    objets = []
    for i in range(densite):
        a = 2.0 * pi * (i + 0.35 * ((i * 7 + graine) % 3)) / densite
        haut = 0.72 - 0.42 * ((i * 5 + graine) % 4) / 3.0
        pts, rayons = [], []
        n = 7
        for k in range(n + 1):
            s = k / float(n)
            z = melange(haut, 0.10, s)
            r = 0.50 - 0.16 * (z - 0.10)
            ecart = 0.035 * sortie * (0.4 + s)
            ang = a + 0.5 * s * (1 if i % 2 else -1)
            p = Vector((cos(ang) * (r + ecart), sin(ang) * (r + ecart), z))
            p.z += 0.02 * sin(s * 5.0 + i)
            pts.append(D + p * echelle)
            rayons.append((0.026 - 0.014 * s) * echelle)
        objets.append(tube_along("%s_%d" % (nom, i), pts, rayons, mat=mats["racine"], seg=8, cap=3))
    return objets


def miettes(mats, echelle=1.0, decalage=None, chute=0.0, nombre=7, graine=0):
    """Les miettes de terre qui tombent quand on degage la motte."""
    if chute <= 0.01:
        return []
    D = Vector(decalage) if decalage is not None else Vector((0, 0, 0))
    objets = []
    for i in range(nombre):
        a = 2.0 * pi * i / nombre + 0.4 * graine
        depart = 0.10 * i
        part = borne((chute - depart) / 0.55)
        if part <= 0.0:
            continue
        r = (0.046 + 0.018 * ((i * 3 + graine) % 3)) * echelle
        haut = melange(0.62, 0.30, ((i * 5 + graine) % 4) / 3.0)
        p = D + Vector((cos(a) * 0.52, sin(a) * 0.52, haut)) * echelle
        p += (Vector((cos(a), sin(a), 0.0)) * 0.16 * part - UP * (0.95 * part * part)) * echelle
        objets.append(sphere("Miette_%d_%d" % (graine, i), p, r, mats["motte"], seg=12,
                             echelle=(1.0, 0.85, 0.75)))
    return objets


# ------------------------------------------------------------
# le verre et l'eau
# ------------------------------------------------------------
VERRE_H = 1.25
VERRE_PROFIL = [(r, z * VERRE_H) for (r, z) in [
    (0.0, 0.0), (0.29, 0.0), (0.335, 0.018), (0.348, 0.10), (0.372, 0.58), (0.388, 0.94), (0.388, 0.965),
    (0.362, 0.965), (0.348, 0.58), (0.322, 0.10), (0.30, 0.066), (0.0, 0.066),
]]


def rayon_interieur(z_local):
    """Le rayon de la paroi interieure du verre, dans son propre repere."""
    paroi = [(0.322, 0.10 * VERRE_H), (0.348, 0.58 * VERRE_H), (0.362, 0.965 * VERRE_H)]
    for (r0, z0), (r1, z1) in zip(paroi, paroi[1:]):
        if z_local <= z1:
            return r0 + (r1 - r0) * borne((z_local - z0) / (z1 - z0))
    return paroi[-1][0]


def verre_et_eau(mats, niveau, large=1.0, haut=1.0, decalage=None):
    """Le verre et son eau. [niveau] est la hauteur de la surface, en
    coordonnees du monde. [large] et [haut] etirent le verre : un verre plus
    large et plus bas montre mieux un noeud et ses racines qu'une fluteue."""
    D = Vector(decalage) if decalage is not None else Vector((0, 0, 0))
    z_local = (niveau - D.z) / haut
    verre = revolve("Verre", [(r * large, z * haut) for (r, z) in VERRE_PROFIL], 96, [mats["verre"]], 30.0)
    fond = 0.066 * VERRE_H * haut
    profil = [(0.0, fond + 0.004), (0.30 * large, fond + 0.004), (0.322 * large + 0.003, 0.10 * VERRE_H * haut),
              (rayon_interieur(z_local) * large + 0.003, niveau - D.z), (0.0, niveau - D.z)]
    eau = revolve("Eau", profil, 96, [mats["eau"]], 40.0)
    for ob in (verre, eau):
        ob.location = D
    return [verre, eau]


def hauteur_verre(haut=1.0):
    """La hauteur du bord du verre."""
    return 0.965 * VERRE_H * haut


# ------------------------------------------------------------
# les ciseaux
# ------------------------------------------------------------
LAME = 0.56


def ciseaux(mats, pivot, Y, Z, ouverture, echelle=1.0):
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
    )) @ Matrix.Scale(echelle, 4)
    objets = []
    for signe, nom in ((1.0, "A"), (-1.0, "B")):
        R = Matrix.Rotation(radians(ouverture / 2.0) * signe, 4, "Z")
        M = base @ R @ Matrix.Translation(Vector((0, 0, 0.011 * signe)))
        objets.append(lame("Lame_" + nom, M, LAME, 0.10, 0.024, 0.022, mats["acier"]))
        bras = [M @ Vector((0, -0.02, 0)), M @ Vector((0, -0.20, 0))]
        objets.append(tube_along("Bras_" + nom, bras, [0.036 * echelle, 0.034 * echelle], mat=mats["poignee"], seg=12, cap=3))
        centre = M @ Vector((0.0, -0.36, 0.0))
        objets.append(anneau("Anneau_" + nom, centre, rot(M, (0, 0, 1)), 0.115 * echelle, 0.038 * echelle, mats["poignee"],
                             long=rot(M, (0, 1, 0)), etire=1.38))
    objets.append(sphere("Rivet", pivot, 0.040 * echelle, mats["poignee"], seg=18))
    return objets


def geste_ciseaux(mats, cible, axe_lames, f, arrivee=None, sortie=None, echelle=1.0,
                  t_approche=0.30, t_fermeture=0.11, t_retrait=0.32):
    """Le geste complet : les ciseaux arrivent, se ferment sur [cible], puis
    repartent. Rend (objets, ferme) — [ferme] dit si la coupe est faite.

    La tige repose au tiers de la lame depuis le rivet : c'est la qu'une
    paire de ciseaux coupe, pas au rivet."""
    approche = adouci(f / t_approche)
    fermeture = adouci((f - (t_approche + 0.04)) / t_fermeture)
    retrait = adouci((f - (t_approche + 0.04 + t_fermeture + 0.09)) / t_retrait)
    Y = Vector(axe_lames).normalized()
    pivot_cible = Vector(cible) - Y * (0.36 * LAME * echelle) + VUE * 0.03
    arrivee = arrivee if arrivee is not None else (UP * 0.85 + DROITE * 0.60) * echelle
    sortie = sortie if sortie is not None else (UP * 1.08 - DROITE * 0.10) * echelle
    pivot = pivot_cible + arrivee * (1.0 - approche) + sortie * retrait
    ouverture = 38.0 * (1.0 - fermeture + retrait)
    bascule = Matrix.Rotation(radians(-18.0) * (1.0 - approche + retrait), 3, VUE)
    return ciseaux(mats, pivot, bascule @ Y, VUE, ouverture, echelle=echelle), fermeture >= 0.999


# ------------------------------------------------------------
# le creux d'un contenant
# ------------------------------------------------------------
# Une racine ne traverse pas la paroi de son pot. Ces profils donnent le
# volume intérieur — le rayon disponible à chaque hauteur, et le fond — et
# [Creux.ramene] y ramène un point qui en sortirait.

# La paroi intérieure du pot, de bas en haut.
POT_CREUX = [(0.30, 0.080), (0.470, 0.12), (0.487, 0.24), (0.505, 0.42),
             (0.530, 0.62), (0.556, 0.80), (0.585, 0.965)]
# Celle du verre, hauteurs déjà multipliées par VERRE_H.
VERRE_CREUX = [(0.30, 0.0865), (0.322, 0.125), (0.348, 0.725), (0.362, 1.206)]


class Creux:
    """Le volume intérieur d'un contenant. [large] et [haut] l'étirent comme
    le contenant lui-même ; [marge] tient compte de l'épaisseur des racines,
    pour qu'aucune ne vienne affleurer la paroi."""

    def __init__(self, profil, large=1.0, haut=None, decalage=None, marge=0.05):
        self.profil = profil
        self.large = large
        self.haut = large if haut is None else haut
        self.D = Vector(decalage) if decalage is not None else Vector((0, 0, 0))
        self.marge = marge

    @property
    def fond(self):
        return self.D.z + self.profil[0][1] * self.haut + self.marge

    def rayon(self, z):
        t = (z - self.D.z) / self.haut
        if t <= self.profil[0][1]:
            r = self.profil[0][0]
        elif t >= self.profil[-1][1]:
            r = self.profil[-1][0]
        else:
            r = self.profil[-1][0]
            for (r0, z0), (r1, z1) in zip(self.profil, self.profil[1:]):
                if t <= z1:
                    r = r0 + (r1 - r0) * (t - z0) / (z1 - z0)
                    break
        return max(0.0, r * self.large - self.marge)

    def ramene(self, p):
        """Le point [p], ramené dans le creux s'il en sortait."""
        p = Vector(p)
        z = max(p.z, self.fond)
        d = Vector((p.x - self.D.x, p.y - self.D.y, 0.0))
        rmax = self.rayon(z)
        if rmax > 0.0 and d.length > rmax:
            d *= rmax / d.length
        return Vector((self.D.x + d.x, self.D.y + d.y, z))


def creux_pot(echelle=1.0, decalage=None, marge=0.05):
    return Creux(POT_CREUX, large=echelle, decalage=decalage, marge=marge)


def creux_verre(large=1.0, haut=1.0, decalage=None, marge=0.045):
    return Creux(VERRE_CREUX, large=large, haut=haut, decalage=decalage, marge=marge)


# ------------------------------------------------------------
# les racines
# ------------------------------------------------------------
def faisceau_racines(nom, depart, direction, mats, avancement, brins=5, longueur=0.55,
                     epaisseur=0.032, matiere="racine", graine=0, ecart=0.9, seg=10, aplati=1.0,
                     dans=None):
    """Quelques racines qui partent de [depart] et descendent selon
    [direction]. Leur trace est fixe : seule la longueur parcourue change
    d'une image a l'autre, si bien qu'une racine s'allonge sans se tordre.

    Quelques racines principales, une legere ondulation, pas de plat de
    spaghettis. [dans] donne le creux du contenant : une racine s'y arrete
    plutot que d'en traverser la paroi ou le fond."""
    if avancement <= 0.02:
        return []
    D = Vector(depart)
    A = Vector(direction).normalized()
    # Deux axes en travers, pour eventer le faisceau.
    U = A.cross(UP)
    if U.length < 1e-3:
        U = A.cross(Vector((1, 0, 0)))
    U.normalize()
    V = A.cross(U).normalized()
    objets = []
    for i in range(brins):
        ang = 2.0 * pi * (i + 0.37 * ((i * 5 + graine) % 3)) / brins + graine
        retard = 0.10 * i
        part = adouci((avancement - retard) / 0.58)
        if part <= 0.03:
            continue
        L = longueur * melange(0.72, 1.0, ((i * 7 + graine) % 5) / 4.0)
        lateral = (U * cos(ang) + V * sin(ang)) * ecart
        chemin = []
        n = 16
        for k in range(n + 1):
            s = k / float(n)
            ond = 0.045 * sin(s * 5.0 + i * 1.7) * s
            p = D + A * (L * s * aplati) + lateral * (L * s * (1.0 - aplati) + 0.22 * L * s * s + ond * 0.5) \
                + (U * sin(ang) - V * cos(ang)) * (0.035 * L * sin(s * 4.0 + i))
            chemin.append(dans.ramene(p) if dans is not None else p)
        # Deux points ramenes au meme endroit contre la paroi donneraient une
        # tangente nulle, et un tube pince : on les ecarte d'un rien.
        for k in range(1, len(chemin)):
            if (chemin[k] - chemin[k - 1]).length < 1e-4:
                chemin[k] = chemin[k - 1] + A * 1e-3
        m = max(2, int(round(part * n)))
        pts = chemin[:m + 1]
        if m < n:
            reste = part * n - m
            pts[-1] = chemin[m] * (1.0 - reste) + chemin[m + 1] * reste
        rayons = [epaisseur * (1.0 - 0.60 * (k / float(len(pts) - 1))) for k in range(len(pts))]
        objets.append(tube_along("%s_%d" % (nom, i), pts, rayons, mat=mats[matiere], seg=seg, cap=3))
    return objets


# ------------------------------------------------------------
# la boucle de rendu
# ------------------------------------------------------------
def efface(objets):
    for ob in objets:
        me = ob.data
        try:
            bpy.data.objects.remove(ob, do_unlink=True)
        except ReferenceError:
            continue
        if me and me.users == 0:
            bpy.data.meshes.remove(me)


def rendre(pack, etapes, res, samples, dossier, apercu=False, seule=None, fill=0.82):
    """Rend les etapes d'un guide.

    Chaque etape est cadree une fois pour toutes sur l'union de ses images
    clefs : sans cela le cadre suivrait le sujet et c'est le monde qui
    semblerait bouger."""
    for nom, images, construire, cles in etapes:
        if seule and nom != seule:
            continue
        purge()
        bpy.context.scene.name = "%s_%s" % (pack, nom)
        mats = materiaux()
        proxies = []
        for c in cles:
            proxies += construire(mats, c)
        studio(proxies, fill=fill)
        efface(proxies)
        rendu_transparent(res, samples)
        sc = bpy.context.scene
        # Le verre et l'eau sont des voiles : les rayons les traversent
        # plusieurs fois avant d'atteindre le fond.
        sc.cycles.transparent_max_bounces = 24
        cible = os.path.join(dossier, pack, nom)
        os.makedirs(cible, exist_ok=True)
        rangs = list(range(images))
        if apercu:
            rangs = [0, images // 3, (2 * images) // 3, images - 1]
        for i in rangs:
            f = i / float(images - 1)
            objets = construire(mats, f)
            chemin = os.path.join(cible, "%s_%03d.png" % (nom, i))
            sc.render.filepath = chemin
            bpy.ops.render.render(write_still=True)
            grain(chemin)
            efface(objets)
            print("IMAGE %s/%s %d/%d" % (pack, nom, i + 1, images), flush=True)
    print("PACK:", pack, dossier, flush=True)
