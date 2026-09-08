# ============================================================
# La scene « argile » commune aux images de l'application : les primitives de
# geometrie, les materiaux mats et le studio d'eclairage qui donnent a l'icone,
# a la pousse et a la petite collection le meme grain et la meme lumiere.
#
# Rien ne s'execute a l'import : ce fichier n'est qu'une boite a outils, les
# scripts qui s'en servent construisent leur propre scene.
# ============================================================
import bpy, bmesh
from mathutils import Vector
from math import pi, sin, cos, exp, radians, sqrt

# Vue de la camera : azimut et elevation, communs a toutes les images.
AZIMUT, ELEVATION = radians(-58.0), radians(14.0)
VUE = Vector((cos(AZIMUT) * cos(ELEVATION), sin(AZIMUT) * cos(ELEVATION), sin(ELEVATION)))

# Profil (rayon, hauteur) du pot en terre cuite, et de la terre dedans.
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

# Hauteur a laquelle les tiges sortent de la terre.
Z_TERRE = 0.90


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
# le studio : camera cadree sur le sujet, trois lumieres, rendu
# ------------------------------------------------------------
def points_de(objets):
    """Tous les sommets des objets, modificateurs appliques, en coordonnees
    du monde : de quoi cadrer sans rien laisser sortir."""
    dg = bpy.context.evaluated_depsgraph_get()
    pts = []
    for ob in objets:
        ev = ob.evaluated_get(dg)
        me = ev.to_mesh()
        mw = ev.matrix_world
        for v in me.vertices:
            pts.append(mw @ v.co)
        ev.to_mesh_clear()
    return pts


def studio(objets, fill=0.80, dist=20.0):
    """Camera orthographique 3/4 cadree sur [objets], plus l'eclairage.

    Rend (camera, centre, droite, haut, vers_camera) : le cadrage est fige
    une fois pour toutes, ce qui permet a une sequence de garder le meme
    cadre pendant que le sujet change.
    """
    sc = bpy.context.scene
    cam_data = bpy.data.cameras.new("CAM")
    cam_data.type = "ORTHO"
    cam_data.clip_start = 0.1
    cam_data.clip_end = 300.0
    cam = bpy.data.objects.new("CAM", cam_data)
    sc.collection.objects.link(cam)
    sc.camera = cam
    cam.rotation_euler = (radians(90.0) - ELEVATION, 0.0, AZIMUT + radians(90.0))
    cam.location = VUE * dist
    bpy.context.view_layer.update()
    M = cam.matrix_world.to_3x3()
    Rv = (M @ Vector((1, 0, 0))).normalized()
    Uv = (M @ Vector((0, 1, 0))).normalized()
    Cv = (M @ Vector((0, 0, 1))).normalized()

    pts = points_de(objets)
    mn = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    mx = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    O = (mn + mx) / 2.0
    a_ = [(p - cam.location).dot(Rv) for p in pts]
    b_ = [(p - cam.location).dot(Uv) for p in pts]
    # Le centre de la boite englobante et le centre de masse visuel ne
    # coincident pas : on vise entre les deux, puis on dimensionne pour que
    # rien ne sorte.
    MIX = 0.55
    ac = (1.0 - MIX) * ((min(a_) + max(a_)) / 2.0) + MIX * (sum(a_) / len(a_))
    bc = (1.0 - MIX) * ((min(b_) + max(b_)) / 2.0) + MIX * (sum(b_) / len(b_))
    half = max(max(abs(v - ac) for v in a_), max(abs(v - bc) for v in b_))
    cam_data.ortho_scale = 2.0 * half / fill
    cam.location = cam.location + Rv * ac + Uv * bc
    bpy.context.view_layer.update()

    def aire(name, offset, size, energy, color=(1, 1, 1)):
        ld = bpy.data.lights.new(name, type="AREA")
        ld.shape = "SQUARE"
        ld.size = size
        ld.energy = energy
        ld.color = color
        ob = bpy.data.objects.new(name, ld)
        sc.collection.objects.link(ob)
        ob.location = O + offset
        ob.rotation_euler = (O - ob.location).to_track_quat("-Z", "Y").to_euler()
        return ob

    aire("LGT_Key", -3.4 * Rv + 4.4 * Uv + 3.0 * Cv, 11.0, 2600.0, (1.0, 0.985, 0.960))
    aire("LGT_Fill", 4.2 * Rv - 1.0 * Uv + 3.0 * Cv, 10.0, 520.0, (0.955, 0.975, 1.0))
    aire("LGT_Rim", -1.5 * Rv + 2.4 * Uv - 1.6 * Cv, 6.0, 900.0)

    world = bpy.data.worlds.new("World")
    sc.world = world
    world.use_nodes = True
    bgn = world.node_tree.nodes["Background"]
    bgn.inputs[0].default_value = (0.85, 0.87, 0.86, 1.0)
    bgn.inputs[1].default_value = 0.35
    return cam, O, Rv, Uv, Cv


def rendu_transparent(res, samples):
    """Reglages de rendu communs : Cycles, fond transparent, sans ombre
    portee — l'application dessine la sienne, accordee a son theme."""
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.device = "CPU"
    sc.cycles.samples = samples
    sc.cycles.use_denoising = True
    sc.cycles.use_adaptive_sampling = True
    sc.cycles.adaptive_threshold = 0.01
    sc.cycles.max_bounces = 8
    sc.cycles.caustics_reflective = False
    sc.cycles.caustics_refractive = False
    sc.render.film_transparent = True
    sc.render.resolution_x = res
    sc.render.resolution_y = res
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
