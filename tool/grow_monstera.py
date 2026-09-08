# ============================================================
# La plante de l'icone qui pousse : sequence d'images pour le premier
# ecran de l'onboarding.
#
# Meme scene, memes materiaux et meme cadrage que l'icone (build_monstera),
# mais la plante est reconstruite a chaque image pour un age donne. Le pot
# et la terre ne bougent pas : c'est la plante qui pousse dedans.
#
# Ce qui se passe entre deux images, et qui vient de la vraie plante :
#   - les feuilles sortent l'une apres l'autre, la plus vieille d'abord ;
#   - chacune emerge en fuseau presque vertical, etroite et entiere ;
#   - elle s'allonge, s'ecarte, s'elargit, puis se decoupe : les fentes
#     d'abord, les fenestrations ensuite. Une jeune feuille de Monstera n'a
#     ni fente ni trou, ils viennent avec l'age.
#
# Fond transparent, sans ombre portee : l'ombre est dessinee par
# l'application, qui fait aussi flotter l'objet.
#
# Execution :
#   blender -b -noaudio -P tool/grow_monstera.py -- <images> <res> <samples> <dossier>
# ============================================================
import bpy, bmesh, sys, os
from mathutils import Vector
from math import pi, sin, cos, exp, radians, sqrt

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
IMAGES = int(argv[0]) if len(argv) > 0 else 40
RES = int(argv[1]) if len(argv) > 1 else 1024
SAMPLES = int(argv[2]) if len(argv) > 2 else 40
DOSSIER = argv[3] if len(argv) > 3 else "/tmp/pousse"
os.makedirs(DOSSIER, exist_ok=True)


# ------------------------------------------------------------
# outils communs (identiques a ceux de l'icone)
# ------------------------------------------------------------
def purge():
    for ob in list(bpy.data.objects):
        bpy.data.objects.remove(ob, do_unlink=True)
    for coll in (bpy.data.meshes, bpy.data.materials, bpy.data.lights,
                 bpy.data.cameras, bpy.data.collections):
        for d in list(coll):
            try:
                if d.users == 0:
                    coll.remove(d)
            except Exception:
                pass


def s2l(c):
    c = c / 255.0
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def hexcol(h, a=1.0):
    h = h.lstrip("#")
    return (s2l(int(h[0:2], 16)), s2l(int(h[2:4], 16)), s2l(int(h[4:6], 16)), a)


def make_mat(name, hexval, rough=0.45, spec=0.30, grain=45.0, relief=0.010, sss=0.10):
    """Materiau « clay » : plastique mat, micro-relief granuleux, rugosite
    irreguliere et un peu de diffusion sous-surfacique."""
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    b = nt.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = hexcol(hexval)
    b.inputs["Roughness"].default_value = rough
    for key, val in (("Metallic", 0.0), ("Specular IOR Level", spec), ("Specular", spec),
                     ("IOR", 1.45), ("Coat Weight", 0.0), ("Sheen Weight", 0.0),
                     ("Subsurface Weight", sss), ("Subsurface Scale", 0.045)):
        if key in b.inputs:
            try:
                b.inputs[key].default_value = val
            except Exception:
                pass
    if "Subsurface Radius" in b.inputs:
        try:
            b.inputs["Subsurface Radius"].default_value = (1.0, 0.55, 0.35)
        except Exception:
            pass

    co = nt.nodes.new("ShaderNodeTexCoord"); co.location = (-900, 0)
    n1 = nt.nodes.new("ShaderNodeTexNoise"); n1.location = (-680, 120)
    n1.inputs["Scale"].default_value = grain
    n1.inputs["Detail"].default_value = 8.0
    n1.inputs["Roughness"].default_value = 0.62
    bump = nt.nodes.new("ShaderNodeBump"); bump.location = (-420, 120)
    bump.inputs["Strength"].default_value = 0.55
    bump.inputs["Distance"].default_value = relief
    nt.links.new(co.outputs["Object"], n1.inputs["Vector"])
    nt.links.new(n1.outputs["Fac"], bump.inputs["Height"])
    nt.links.new(bump.outputs["Normal"], b.inputs["Normal"])
    n2 = nt.nodes.new("ShaderNodeTexNoise"); n2.location = (-680, -180)
    n2.inputs["Scale"].default_value = 7.0
    n2.inputs["Detail"].default_value = 3.0
    mr = nt.nodes.new("ShaderNodeMapRange"); mr.location = (-420, -180)
    mr.inputs["From Min"].default_value = 0.25
    mr.inputs["From Max"].default_value = 0.75
    mr.inputs["To Min"].default_value = max(0.0, rough - 0.09)
    mr.inputs["To Max"].default_value = min(1.0, rough + 0.09)
    nt.links.new(co.outputs["Object"], n2.inputs["Vector"])
    nt.links.new(n2.outputs["Fac"], mr.inputs["Value"])
    nt.links.new(mr.outputs["Result"], b.inputs["Roughness"])
    mat.diffuse_color = hexcol(hexval)
    return mat


def revolve(name, profile, segs=96, mats=None, split=38.0):
    verts, rings = [], []
    for (r, z) in profile:
        if abs(r) < 1e-6:
            rings.append(("P", [len(verts)])); verts.append((0.0, 0.0, z))
        else:
            idx = []
            for k in range(segs):
                a = 2.0 * pi * k / segs
                idx.append(len(verts)); verts.append((r * cos(a), r * sin(a), z))
            rings.append(("R", idx))
    faces = []
    for (i, j) in [(i, i + 1) for i in range(len(profile) - 1)]:
        ti, ri = rings[i]; tj, rj = rings[j]
        if ti == "P":
            for k in range(segs):
                faces.append((ri[0], rj[k], rj[(k + 1) % segs]))
        elif tj == "P":
            for k in range(segs):
                faces.append((rj[0], ri[(k + 1) % segs], ri[k]))
        else:
            for k in range(segs):
                k2 = (k + 1) % segs
                faces.append((ri[k], ri[k2], rj[k2], rj[k]))
    me = bpy.data.meshes.new(name)
    me.from_pydata(verts, [], faces); me.update()
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    for m in (mats or []):
        me.materials.append(m)
    bm = bmesh.new(); bm.from_mesh(me)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me); bm.free()
    for p in me.polygons:
        p.use_smooth = True
    md = ob.modifiers.new("Lissage", "EDGE_SPLIT")
    md.split_angle = radians(split)
    return ob


def tube_along(name, pts, radii, n1=(0, 0, 1), seg=14, cap=5, mat=None):
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
    ref = Vector(n1)
    samples = []
    r0 = radii[0]
    for j in range(cap, 0, -1):
        s = r0 * sin(j * (pi / 2.0) / cap)
        samples.append((P[0] - T[0] * s, T[0], sqrt(max(0.0, r0 * r0 - s * s))))
    for i in range(len(P)):
        samples.append((P[i], T[i], radii[i]))
    r1 = radii[-1]
    for j in range(1, cap + 1):
        s = r1 * sin(j * (pi / 2.0) / cap)
        samples.append((P[-1] + T[-1] * s, T[-1], sqrt(max(0.0, r1 * r1 - s * s))))
    verts, rings = [], []
    for (c, t, r) in samples:
        a1 = ref.cross(t)
        if a1.length < 1e-4:
            a1 = Vector((1, 0, 0)).cross(t)
        a1.normalize()
        a2 = t.cross(a1).normalized()
        if r < 1e-5:
            rings.append(("P", [len(verts)])); verts.append(c)
        else:
            idx = []
            for k in range(seg):
                a = 2.0 * pi * k / seg
                idx.append(len(verts))
                verts.append(c + a1 * (r * cos(a)) + a2 * (r * sin(a)))
            rings.append(("R", idx))
    faces = []
    for i in range(len(rings) - 1):
        ti, ri = rings[i]; tj, rj = rings[i + 1]
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
    me = bpy.data.meshes.new(name)
    me.from_pydata([tuple(v) for v in verts], [], faces); me.update()
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    if mat:
        me.materials.append(mat)
    bm = bmesh.new(); bm.from_mesh(me)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me); bm.free()
    for p in me.polygons:
        p.use_smooth = True
    return ob


def make_leaf(name, origine, X, Y, Z, L=1.40, n_fentes=4, nu=170, M=22,
              mat=None, ep=0.020, n_trous=2, w_ratio=0.435):
    """Limbe de Monstera deliciosa. [w_ratio] est la largeur relative : une
    jeune feuille sort en fuseau etroit et s'elargit en se deployant."""
    W = w_ratio * L
    K = 0.18
    EA, EB = 0.24, 0.74
    EMAX = (EA / (EA + EB)) ** EA * (EB / (EA + EB)) ** EB
    fentes = [0.14 + 0.70 * (i + 0.5) / n_fentes for i in range(n_fentes)]
    SIG, CMIN = 0.020, 0.32
    M1 = int(M * 0.42)
    inters = [0.5 * (fentes[i] + fentes[i + 1]) for i in range(len(fentes) - 1)]
    trous = inters[:max(0, n_trous)]
    DT, FC, HG = 0.062, 0.47, 0.30

    def env(t):
        t = min(max(t, 1e-4), 1.0 - 1e-4)
        return W * (t ** EA) * ((1.0 - t) ** EB) / EMAX

    def cut(t):
        c = 1.0
        for tc in fentes:
            c = min(c, 1.0 - (1.0 - CMIN) * exp(-((t - tc) / SIG) ** 2))
        return c

    def hw(t):
        return env(t) * cut(t)

    def gap(t):
        for tc in trous:
            e = 1.0 - ((t - tc) / DT) ** 2
            if e > 1e-4:
                w = 0.5 * HG * sqrt(e)
                return (FC - w, FC + w)
        return None

    def colonnes(t):
        g = gap(t)
        if g is None:
            return [i / float(M) for i in range(M + 1)], False
        lo, hi = g
        n2 = M - M1
        vals = [lo * i / float(M1) for i in range(M1 + 1)]
        vals += [hi + (1.0 - hi) * (j + 1) / float(n2) for j in range(n2)]
        return vals, True

    def place(xl, yl, zl):
        return origine + X * xl + Y * yl + Z * zl

    def pos(t, f):
        w = hw(t)
        x = f * w
        return place(x, L * (t + K * abs(f)),
                     -0.10 * (x * x) / max(W, 1e-6) - 0.15 * L * (t ** 2.1))

    verts, rings, ouverts = [], [], []
    rings.append(("P", [len(verts)])); verts.append(pos(0.0, 0.0)); ouverts.append(False)
    for i in range(1, nu):
        t = i / float(nu)
        vals, ouvert = colonnes(t)
        row = []
        for v in reversed(vals[1:]):
            row.append(len(verts)); verts.append(pos(t, -v))
        row.append(len(verts)); verts.append(pos(t, 0.0))
        for v in vals[1:]:
            row.append(len(verts)); verts.append(pos(t, v))
        rings.append(("R", row)); ouverts.append(ouvert)
    rings.append(("P", [len(verts)])); verts.append(pos(1.0, 0.0)); ouverts.append(False)

    GAPS = ((M - M1 - 1, M - M1), (M + M1, M + M1 + 1))
    faces = []
    for i in range(len(rings) - 1):
        ti, ri = rings[i]; tj, rj = rings[i + 1]
        if ti == "P":
            for k in range(len(rj) - 1):
                faces.append((ri[0], rj[k], rj[k + 1]))
        elif tj == "P":
            for k in range(len(ri) - 1):
                faces.append((rj[0], ri[k + 1], ri[k]))
        else:
            saut = ouverts[i] and ouverts[i + 1]
            for k in range(len(ri) - 1):
                if saut and any(k == g0 for (g0, g1) in GAPS):
                    continue
                faces.append((ri[k], ri[k + 1], rj[k + 1], rj[k]))

    me = bpy.data.meshes.new(name)
    me.from_pydata([tuple(v) for v in verts], [], faces); me.update()
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    if mat:
        me.materials.append(mat)
    bm = bmesh.new(); bm.from_mesh(me)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me); bm.free()
    for p in me.polygons:
        p.use_smooth = True
    sol = ob.modifiers.new("Epaisseur", "SOLIDIFY")
    sol.thickness = ep; sol.offset = 0.0
    bev = ob.modifiers.new("Adoucissement", "BEVEL")
    bev.width = 0.006; bev.segments = 2
    bev.limit_method = "ANGLE"; bev.angle_limit = radians(25)
    bev.use_clamp_overlap = True
    return ob


# ------------------------------------------------------------
# la plante a un age donne
# ------------------------------------------------------------
purge()
sc = bpy.context.scene
sc.name = "Pousse_Monstera"

MAT_FEUILLE = make_mat("MAT_Feuille", "0E6B34", 0.52, 0.32, grain=60.0, relief=0.008, sss=0.14)
MAT_TIGE = make_mat("MAT_Tige", "227A45", 0.55, 0.26, grain=55.0, relief=0.008, sss=0.12)
MAT_POT = make_mat("MAT_Pot_Terracotta", "C87A57", 0.68, 0.18, grain=34.0, relief=0.024, sss=0.10)
MAT_TERRE = make_mat("MAT_Terre", "3B302A", 0.90, 0.06, grain=20.0, relief=0.040, sss=0.0)

POT_PROFIL = [
    (0.0, 0.02), (0.30, 0.0), (0.40, 0.005), (0.44, 0.035),
    (0.470, 0.14), (0.505, 0.34), (0.545, 0.56), (0.575, 0.72),
    (0.600, 0.84), (0.628, 0.90), (0.640, 0.945), (0.634, 0.975),
    (0.610, 0.985), (0.585, 0.965), (0.578, 0.92),
    (0.556, 0.80), (0.530, 0.62), (0.505, 0.42), (0.487, 0.24),
    (0.470, 0.12), (0.30, 0.075), (0.0, 0.085),
]
TERRE_PROFIL = [(0.0, 0.905), (0.20, 0.900), (0.38, 0.888), (0.50, 0.872),
                (0.560, 0.855), (0.578, 0.840)]
Z_TERRE = 0.90

_AZ, _EL = radians(-58.0), radians(14.0)
VUE = Vector((cos(_AZ) * cos(_EL), sin(_AZ) * cos(_EL), sin(_EL)))

# (azimut, inclinaison, petiole, limbe, fentes, trous, roulis) — l'etat adulte,
# celui de l'icone. L'ordre est celui de la pousse : la plus vieille d'abord.
FEUILLES = [
    (212.0, 31.0, 0.74, 1.38, 4, 2, -9.0),
    (32.0, 28.0, 0.86, 1.30, 4, 2, 6.0),
    (322.0, 13.0, 1.22, 1.00, 3, 1, -13.0),
    (168.0, 52.0, 0.54, 0.84, 3, 1, 10.0),
    (78.0, 45.0, 0.62, 0.90, 3, 1, 16.0),
]

# Quand chaque feuille commence, et le temps qu'elle met. La derniere finit
# avec la sequence : la plante est alors exactement celle de l'icone.
DEPART = [0.03, 0.16, 0.29, 0.42, 0.55]
DUREE = 0.45

# Inclinaison du fuseau qui sort de terre : presque droit.
FUSEAU = 5.0


def borne(u):
    return min(max(u, 0.0), 1.0)


def adouci(u):
    u = borne(u)
    return u * u * (3.0 - 2.0 * u)


def plante(g):
    """Construit le pot, la terre et les feuilles a l'age [g] (0 a 1)."""
    objets = [revolve("Pot", POT_PROFIL, 96, [MAT_POT], 34.0),
              revolve("Terre", TERRE_PROFIL, 96, [MAT_TERRE], 40.0)]
    for idx, (az, tilt, Lp, L, nfe, ntr, roll) in enumerate(FEUILLES):
        pousse = adouci((g - DEPART[idx]) / DUREE)
        if pousse <= 0.0:
            continue
        # Le limbe se deploie apres s'etre allonge : d'abord un fuseau qui
        # monte, ensuite une feuille qui s'ouvre et se decoupe.
        ouvre = adouci((pousse - 0.22) / 0.78)
        Lp_i = Lp * (0.10 + 0.90 * pousse)
        L_i = L * (0.14 + 0.86 * pousse)
        tilt_i = FUSEAU + (tilt - FUSEAU) * ouvre
        w_i = 0.13 + (0.435 - 0.13) * ouvre
        nfe_i = int(round(nfe * borne((ouvre - 0.30) / 0.45)))
        ntr_i = int(round(ntr * borne((ouvre - 0.55) / 0.35)))

        a, t = radians(az), radians(tilt_i)
        P0 = Vector((0.10 * cos(a), 0.10 * sin(a), Z_TERRE - 0.03))
        dirn = Vector((sin(t) * cos(a), sin(t) * sin(a), cos(t)))
        P2 = P0 + dirn * Lp_i
        P1 = P0 + Vector((0, 0, Lp_i * 0.58))
        npt = 14
        pts, radii = [], []
        for i in range(npt + 1):
            s = i / float(npt); u = 1.0 - s
            pts.append(P0 * (u * u) + P1 * (2 * u * s) + P2 * (s * s))
            # Le petiole s'epaissit en meme temps qu'il s'allonge.
            radii.append((0.062 - 0.026 * s) * (0.55 + 0.45 * pousse))
        objets.append(tube_along("Tige_%02d" % (idx + 1), pts, radii, mat=MAT_TIGE))

        T = (pts[-1] - pts[-2]).normalized()
        outward = Vector((cos(a), sin(a), 0.0))
        F = (VUE * 0.78 + Vector((0, 0, 1)) * 0.34 + outward * 0.26).normalized()
        Zl = (F - F.dot(T) * T)
        if Zl.length < 1e-4:
            Zl = Vector((0, 0, 1))
        Zl.normalize()
        Yl = T
        Xl = Yl.cross(Zl)
        rr = radians(roll)
        Xl2 = Xl * cos(rr) + Zl * sin(rr)
        Zl2 = -Xl * sin(rr) + Zl * cos(rr)
        objets.append(make_leaf("Feuille_%02d" % (idx + 1), P2 - T * 0.03,
                                Xl2, Yl, Zl2, L=L_i, n_fentes=nfe_i,
                                mat=MAT_FEUILLE, n_trous=ntr_i, w_ratio=w_i,
                                ep=0.020 * (0.7 + 0.3 * pousse)))
    return objets


def efface(objets):
    for ob in objets:
        me = ob.data
        bpy.data.objects.remove(ob, do_unlink=True)
        if me and me.users == 0:
            bpy.data.meshes.remove(me)


# ------------------------------------------------------------
# camera, cadree une fois pour toutes sur la plante adulte
# ------------------------------------------------------------
adulte = plante(1.0)

cam_data = bpy.data.cameras.new("CAM_Pousse")
cam_data.type = "ORTHO"; cam_data.clip_start = 0.1; cam_data.clip_end = 300.0
cam = bpy.data.objects.new("CAM_Pousse", cam_data)
sc.collection.objects.link(cam)
sc.camera = cam
DIST, FILL = 20.0, 0.80
Cvec = Vector((cos(_AZ) * cos(_EL), sin(_AZ) * cos(_EL), sin(_EL)))
cam.rotation_euler = (radians(90.0) - _EL, 0.0, _AZ + radians(90.0))
cam.location = Cvec * DIST
bpy.context.view_layer.update()
M = cam.matrix_world.to_3x3()
Rv = (M @ Vector((1, 0, 0))).normalized()
Uv = (M @ Vector((0, 1, 0))).normalized()
Cv = (M @ Vector((0, 0, 1))).normalized()

dg = bpy.context.evaluated_depsgraph_get()
pts_all = []
for ob in adulte:
    ev = ob.evaluated_get(dg); me = ev.to_mesh(); mw = ev.matrix_world
    for v in me.vertices:
        pts_all.append(mw @ v.co)
    ev.to_mesh_clear()
mn = Vector((min(p.x for p in pts_all), min(p.y for p in pts_all), min(p.z for p in pts_all)))
mx = Vector((max(p.x for p in pts_all), max(p.y for p in pts_all), max(p.z for p in pts_all)))
O = (mn + mx) / 2.0
a_ = [(p - cam.location).dot(Rv) for p in pts_all]
b_ = [(p - cam.location).dot(Uv) for p in pts_all]
MIX = 0.55
ac = (1.0 - MIX) * ((min(a_) + max(a_)) / 2.0) + MIX * (sum(a_) / len(a_))
bc = (1.0 - MIX) * ((min(b_) + max(b_)) / 2.0) + MIX * (sum(b_) / len(b_))
half = max(max(abs(v - ac) for v in a_), max(abs(v - bc) for v in b_))
cam_data.ortho_scale = 2.0 * half / FILL
cam.location = cam.location + Rv * ac + Uv * bc
bpy.context.view_layer.update()

# ------------------------------------------------------------
# eclairage studio doux, pose lui aussi une fois pour toutes
# ------------------------------------------------------------
def add_area(name, offset, size, energy, color=(1, 1, 1)):
    ld = bpy.data.lights.new(name, type="AREA")
    ld.shape = "SQUARE"; ld.size = size; ld.energy = energy; ld.color = color
    ob = bpy.data.objects.new(name, ld)
    sc.collection.objects.link(ob)
    ob.location = O + offset
    ob.rotation_euler = (O - ob.location).to_track_quat("-Z", "Y").to_euler()
    return ob


add_area("LGT_Key", -3.4 * Rv + 4.4 * Uv + 3.0 * Cv, 11.0, 2600.0, (1.0, 0.985, 0.960))
add_area("LGT_Fill", 4.2 * Rv - 1.0 * Uv + 3.0 * Cv, 10.0, 520.0, (0.955, 0.975, 1.0))
add_area("LGT_Rim", -1.5 * Rv + 2.4 * Uv - 1.6 * Cv, 6.0, 900.0)

world = bpy.data.worlds.new("World")
sc.world = world
world.use_nodes = True
bgn = world.node_tree.nodes["Background"]
bgn.inputs[0].default_value = (0.85, 0.87, 0.86, 1.0)
bgn.inputs[1].default_value = 0.35

sc.render.engine = "CYCLES"
sc.cycles.device = "CPU"
sc.cycles.samples = SAMPLES
sc.cycles.use_denoising = True
sc.cycles.use_adaptive_sampling = True
sc.cycles.adaptive_threshold = 0.01
sc.cycles.max_bounces = 8
sc.cycles.caustics_reflective = False
sc.cycles.caustics_refractive = False
# Fond transparent : l'ombre et le flottement sont dessines par l'application.
sc.render.film_transparent = True
sc.render.resolution_x = RES
sc.render.resolution_y = RES
sc.render.image_settings.file_format = "PNG"
sc.render.image_settings.color_mode = "RGBA"
sc.render.image_settings.color_depth = "8"
sc.use_nodes = False
for nm in ("AgX", "Filmic", "Standard"):
    try:
        sc.view_settings.view_transform = nm
        break
    except Exception:
        continue
try:
    sc.view_settings.look = "None"
except Exception:
    pass


def grain(chemin, amplitude=0.018, graine=7):
    """Grain argentique, identique d'une image a l'autre.

    Un grain retire a chaque image grouillerait ; avec la meme graine il se
    tient tranquille, comme un grain de papier sous la plante.
    """
    import numpy as np
    img = bpy.data.images.load(chemin, check_existing=False)
    img.colorspace_settings.name = "Non-Color"
    w, h = img.size
    px = np.empty(w * h * 4, dtype=np.float32)
    img.pixels.foreach_get(px)
    a = px.reshape(h, w, 4)
    rng = np.random.default_rng(graine)
    bruit = rng.normal(0.0, 1.0, (h, w)).astype(np.float32)
    bruit = (bruit
             + 0.5 * np.roll(bruit, 1, 0) + 0.5 * np.roll(bruit, -1, 0)
             + 0.5 * np.roll(bruit, 1, 1) + 0.5 * np.roll(bruit, -1, 1)) / 2.45
    # Module par l'opacite : le fond transparent reste intact.
    masque = a[:, :, 3]
    a[:, :, :3] = np.clip(a[:, :, :3] + (bruit * masque * amplitude)[:, :, None], 0.0, 1.0)
    img.pixels.foreach_set(a.reshape(-1))
    img.filepath_raw = chemin
    img.file_format = "PNG"
    img.save()
    bpy.data.images.remove(img)


# ------------------------------------------------------------
# la sequence
# ------------------------------------------------------------
courant = adulte
for i in range(IMAGES):
    g = i / float(IMAGES - 1)
    efface(courant)
    courant = plante(g)
    chemin = os.path.join(DOSSIER, "pousse_%03d.png" % i)
    sc.render.filepath = chemin
    bpy.ops.render.render(write_still=True)
    grain(chemin)
    print("IMAGE %d/%d age=%.3f -> %s" % (i + 1, IMAGES, g, chemin), flush=True)

print("SEQUENCE:", DOSSIER)
