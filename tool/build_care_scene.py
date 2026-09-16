#!/usr/bin/env python3
"""Rend les décors isométriques des fiches d'entretien Auxine.

Le script tourne dans Blender en mode headless. Il produit des PNG RGBA sous
le dossier donné ; `tool/build_care_scene_assets.py` les convertit ensuite en
WebP livrables.

  blender -b -noaudio -P tool/build_care_scene.py -- --out /tmp/care_scene
"""
from __future__ import annotations

import argparse
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
from clay_scene import POT_PROFIL, TERRE_PROFIL, VUE, Z_TERRE, grain, make_leaf, make_mat, purge, revolve, tube_along

LIGHTS = ("shade", "low_light", "indirect", "bright_indirect", "some_sun", "full_sun")
PLANTS = ("monstera", "broad_leaf", "upright_leaf", "vine", "fern", "rosette", "cactus", "tree", "conifer")

CREAM = "FBF6EE"
CREAM_DARK = "E8D9C7"
TERRA = "B96849"
TERRA_DARK = "7A4938"
SAGE = "2C774E"
SAGE_LIGHT = "5D9A72"
WATER = "4F83B4"
SUN = "D9B85B"
INK = "4A3528"
WOOD = "9B7258"
SOIL = "49372D"
GRASS = "78936A"


def mat(name: str, color: str, rough: float = .66, relief: float = .010):
    return make_mat(name, color, rough=rough, spec=.18, grain=46.0, relief=relief, sss=.08)


def box(name, location, scale, material, bevel=.06):
    bpy.ops.mesh.primitive_cube_add(location=location)
    ob = bpy.context.object
    ob.name = name
    ob.scale = (scale[0] / 2, scale[1] / 2, scale[2] / 2)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    ob.data.materials.append(material)
    if bevel:
        mod = ob.modifiers.new("Adoucissement", "BEVEL")
        mod.width = bevel
        mod.segments = 4
    return ob


def sphere(name, location, scale, material):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=36, ring_count=20, location=location)
    ob = bpy.context.object
    ob.name = name
    ob.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    ob.data.materials.append(material)
    for p in ob.data.polygons:
        p.use_smooth = True
    return ob


def cylinder(name, location, radius, depth, material, vertices=32):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=location)
    ob = bpy.context.object
    ob.name = name
    ob.data.materials.append(material)
    bevel = ob.modifiers.new("Adoucissement", "BEVEL")
    bevel.width = min(radius * .22, .05)
    bevel.segments = 3
    return ob


def cone(name, location, radius1, radius2, depth, material):
    bpy.ops.mesh.primitive_cone_add(vertices=40, radius1=radius1, radius2=radius2, depth=depth, location=location)
    ob = bpy.context.object
    ob.name = name
    ob.data.materials.append(material)
    bevel = ob.modifiers.new("Adoucissement", "BEVEL")
    bevel.width = .045
    bevel.segments = 3
    return ob


def camera(target=(0, 0, 1.1), scale=7.3, plant=False):
    bpy.ops.object.camera_add(location=(6.6, -7.2, 5.9) if not plant else (4.6, -6.0, 4.2))
    cam = bpy.context.object
    tgt = Vector(target)
    cam.rotation_euler = (tgt - cam.location).to_track_quat("-Z", "Y").to_euler()
    cam.data.type = "ORTHO"
    cam.data.ortho_scale = scale
    bpy.context.scene.camera = cam
    return cam


def setup_render(output: Path, resolution: int, samples: int, plant=False):
    sc = bpy.context.scene
    try:
        sc.render.engine = "BLENDER_EEVEE_NEXT"
    except TypeError:
        sc.render.engine = "BLENDER_EEVEE"
    if hasattr(sc, "eevee"):
        sc.eevee.taa_render_samples = samples
    sc.render.resolution_x = resolution
    sc.render.resolution_y = resolution
    sc.render.resolution_percentage = 100
    sc.render.image_settings.file_format = "PNG"
    sc.render.image_settings.color_mode = "RGBA"
    sc.render.film_transparent = True
    sc.render.filepath = str(output)
    sc.render.resolution_percentage = 100
    sc.view_settings.look = "Medium High Contrast"
    camera(scale=5.0 if plant else 7.3, plant=plant)

    bpy.ops.object.light_add(type="AREA", location=(2.6, -3.8, 7.2))
    key = bpy.context.object
    key.data.energy = 820 if plant else 720
    key.data.shape = "DISK"
    key.data.size = 5.5
    key.rotation_euler = (math.radians(18), 0, math.radians(28))
    bpy.ops.object.light_add(type="AREA", location=(-4.0, -1.5, 4.0))
    fill = bpy.context.object
    fill.data.energy = 320
    fill.data.size = 5.0
    bpy.ops.object.light_add(type="AREA", location=(0.5, 4.0, 3.5))
    rim = bpy.context.object
    rim.data.energy = 220
    rim.data.size = 4.0


def light_strength(key: str) -> float:
    return {
        "shade": .34,
        "low_light": .48,
        "indirect": .67,
        "bright_indirect": .88,
        "some_sun": 1.05,
        "full_sun": 1.22,
    }[key]


def add_window(material_frame, material_glass):
    # Fenêtre sur le mur du fond, légèrement à gauche : sa position est
    # stable entre les six rendus, seule la lumière change.
    box("Fenetre", (-1.55, 2.57, 2.15), (2.1, .10, 2.45), material_glass, .03)
    for x in (-2.60, -1.55, -.50):
        box("Montant", (x, 2.49, 2.15), (.08, .10, 2.55), material_frame, .02)
    for z in (.90, 2.15, 3.40):
        box("Traverse", (-1.55, 2.49, z), (2.18, .10, .08), material_frame, .02)


def indoor_scene(light_key: str):
    cream = mat("Creme", CREAM)
    cream_dark = mat("CremeOmbre", CREAM_DARK)
    wood = mat("Bois", WOOD, .72)
    glass = mat("Ciel", "AFC9D8", .48)
    sage = mat("Sauge", SAGE)
    sun = mat("Soleil", "E8C96F", .58)

    box("Sol", (0, 0, -.12), (5.6, 5.4, .24), cream_dark, .08)
    box("MurFond", (0, 2.65, 1.75), (5.6, .22, 3.7), cream, .06)
    box("MurDroit", (2.70, .15, 1.75), (.22, 5.0, 3.7), cream, .06)
    add_window(cream_dark, glass)

    # Quelques volumes simples suffisent à lire « pièce » sans voler la scène.
    box("Meuble", (1.70, 1.95, .52), (1.45, .55, .95), wood, .08)
    box("Livre", (1.55, 1.61, 1.04), (.55, .25, .08), sage, .025)
    cylinder("Lampe", (1.95, 1.62, 1.18), .16, .34, cream_dark)
    sphere("AbatJour", (1.95, 1.62, 1.47), (.30, .30, .24), sun)

    strength = light_strength(light_key)
    for ob in [o for o in bpy.context.scene.objects if o.type == "LIGHT"]:
        ob.data.energy *= strength

    # La tache sur le sol encode direct/indirect. En vive indirecte elle reste
    # proche de la fenêtre mais à gauche du slot de la plante.
    patch = {
        "bright_indirect": (-1.65, .55, 1.55, .70),
        "some_sun": (-1.15, .30, 2.00, 1.00),
        "full_sun": (-.75, .05, 2.55, 1.30),
    }.get(light_key)
    if patch:
        x, y, w, h = patch
        box("LumiereSol", (x, y, .025), (w, h, .025), sun, .08)

    if light_key in ("shade", "low_light"):
        # Un paravent matérialise la zone reculée sans appliquer un filtre gris.
        box("Paravent", (1.95, -.65, 1.05), (.18, 1.55, 2.10), wood, .05)


def outdoor_scene(light_key: str):
    grass = mat("Herbe", GRASS, .80, .018)
    cream = mat("Muret", CREAM)
    wood = mat("Bois", WOOD, .76)
    sage = mat("Sauge", SAGE)
    sun = mat("Soleil", "E8C96F", .58)

    box("Terrain", (0, 0, -.12), (5.8, 5.4, .24), grass, .10)
    box("Muret", (0, 2.55, .65), (5.8, .25, 1.35), cream, .07)
    for x in (-2.2, 2.2):
        cylinder("ArbusteTronc", (x, 1.80, .75), .10, 1.3, wood)
        sphere("Arbuste", (x, 1.75, 1.55), (.70, .62, .68), sage)

    strength = light_strength(light_key)
    for ob in [o for o in bpy.context.scene.objects if o.type == "LIGHT"]:
        ob.data.energy *= strength

    if light_key in ("shade", "low_light", "indirect"):
        # Une pergola simple crée une zone abritée lisible.
        for x in (-2.05, -.35):
            cylinder("Poteau", (x, -.15, 1.45), .08, 2.9, wood)
        box("TraversePergola", (-1.20, -.15, 2.90), (2.0, .18, .16), wood, .03)
        for y in (-.70, -.20, .30):
            box("LamePergola", (-1.20, y, 2.95), (2.05, .12, .10), wood, .02)

    patch = {
        "bright_indirect": (-1.50, .15, 1.55, .75),
        "some_sun": (-.95, -.05, 2.05, 1.00),
        "full_sun": (-.55, -.20, 2.65, 1.35),
    }.get(light_key)
    if patch:
        x, y, w, h = patch
        box("SoleilSol", (x, y, .025), (w, h, .025), sun, .10)


def make_pot(scale=1.0):
    terracotta = mat("Pot", TERRA, .72, .022)
    soil = mat("Terre", SOIL, .92, .035)
    pot = revolve("Pot", POT_PROFIL, 72, [terracotta], 36.0)
    dirt = revolve("Terre", TERRE_PROFIL, 72, [soil], 40.0)
    for ob in (pot, dirt):
        ob.scale = (scale, scale, scale)
    return pot, dirt, Z_TERRE * scale


def leaf_on_stem(idx, az, tilt, petiole, length, width, cuts, holes, green, origin_z):
    a, t = math.radians(az), math.radians(tilt)
    p0 = Vector((.08 * math.cos(a), .08 * math.sin(a), origin_z - .02))
    direction = Vector((math.sin(t) * math.cos(a), math.sin(t) * math.sin(a), math.cos(t)))
    p2 = p0 + direction * petiole
    p1 = p0 + Vector((0, 0, petiole * .55))
    pts, radii = [], []
    for i in range(12):
        s = i / 11.0
        u = 1 - s
        pts.append(p0 * (u * u) + p1 * (2 * u * s) + p2 * (s * s))
        radii.append(.045 - .018 * s)
    stem = mat("Tige", "2F6F43", .62, .008)
    tube_along("Tige_%02d" % idx, pts, radii, mat=stem)
    tangent = (pts[-1] - pts[-2]).normalized()
    face = (VUE * .76 + Vector((0, 0, 1)) * .36).normalized()
    normal = face - face.dot(tangent) * tangent
    if normal.length < 1e-4:
        normal = Vector((0, 1, 0))
    normal.normalize()
    xaxis = tangent.cross(normal).normalized()
    make_leaf(
        "Feuille_%02d" % idx,
        p2 - tangent * .02,
        xaxis,
        tangent,
        normal,
        L=length,
        n_fentes=cuts,
        n_trous=holes,
        mat=green,
        w_ratio=width,
        nu=90,
        M=16,
    )


def plant_scene(kind: str):
    green = mat("Feuille", "267447", .55, .008)
    green2 = mat("FeuilleClaire", SAGE_LIGHT, .58, .008)
    trunk = mat("Tronc", TERRA_DARK, .78, .015)

    if kind in ("tree", "conifer"):
        cylinder("Tronc", (0, 0, .95), .16, 1.9, trunk)
        if kind == "tree":
            for i, (x, y, z, s) in enumerate(((-.45, 0, 1.95, .72), (.35, .10, 2.00, .78), (0, -.22, 2.42, .70), (.10, .25, 1.65, .62))):
                sphere("Couronne_%d" % i, (x, y, z), (s, s * .88, s * .80), green if i % 2 == 0 else green2)
        else:
            for i, (z, r) in enumerate(((1.00, 1.00), (1.48, .82), (1.92, .62), (2.30, .42))):
                cone("Etage_%d" % i, (0, 0, z + .35), r, .08, .70, green if i % 2 == 0 else green2)
        return

    _, _, soil_z = make_pot(.78 if kind in ("rosette", "cactus") else .88)

    if kind == "monstera":
        for i, values in enumerate(((205, 34, .72, 1.14, .44, 4, 2), (30, 30, .82, 1.06, .44, 4, 2), (105, 18, .96, .82, .42, 3, 1), (300, 40, .60, .78, .43, 2, 1))):
            leaf_on_stem(i, *values, green, soil_z)
    elif kind == "broad_leaf":
        for i, values in enumerate(((205, 40, .58, .90, .60, 0, 0), (35, 34, .72, .95, .58, 0, 0), (115, 20, .84, .78, .56, 0, 0), (300, 45, .55, .72, .58, 0, 0))):
            leaf_on_stem(i, *values, green if i % 2 == 0 else green2, soil_z)
    elif kind == "upright_leaf":
        for i, az in enumerate((20, 85, 150, 215, 285, 335)):
            leaf_on_stem(i, az, 8 + (i % 3) * 5, .12, 1.28 - .08 * (i % 2), .13, 0, 0, green if i % 2 == 0 else green2, soil_z)
    elif kind == "vine":
        for i, az in enumerate((35, 125, 215, 305, 70)):
            leaf_on_stem(i, az, 42, .62 + .05 * i, .52, .54, 0, 0, green if i % 2 == 0 else green2, soil_z)
    elif kind == "fern":
        for i, az in enumerate(range(0, 360, 30)):
            leaf_on_stem(i, az, 58, .28, .78 + .08 * (i % 3), .15, 0, 0, green if i % 2 == 0 else green2, soil_z)
    elif kind == "rosette":
        for i, az in enumerate(range(0, 360, 30)):
            leaf_on_stem(i, az, 68, .08, .70 if i % 2 == 0 else .55, .18, 0, 0, green if i % 2 == 0 else green2, soil_z)
    elif kind == "cactus":
        cactus = mat("Cactus", "3D8052", .68, .015)
        cylinder("CactusCentral", (0, 0, soil_z + .68), .24, 1.35, cactus, 40)
        sphere("CactusSommet", (0, 0, soil_z + 1.35), (.24, .24, .25), cactus)
        for side in (-1, 1):
            cylinder("Bras", (side * .34, 0, soil_z + .65), .13, .62, cactus, 32)
            cylinder("Liaison", (side * .18, 0, soil_z + .46), .12, .42, cactus, 32).rotation_euler[1] = math.radians(90)


def render_one(output: Path, resolution: int, samples: int, build, plant=False):
    purge()
    setup_render(output, resolution, samples, plant=plant)
    build()
    output.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.render.render(write_still=True)
    grain(str(output), amplitude=.008 if plant else .006, graine=11)
    print("RENDER", output, flush=True)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", type=Path, default=Path("/tmp/care_scene"))
    parser.add_argument("--resolution", type=int, default=768)
    parser.add_argument("--samples", type=int, default=32)
    parser.add_argument("--preview", action="store_true")
    args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else [])
    if args.preview:
        args.resolution = min(args.resolution, 384)
        args.samples = min(args.samples, 8)

    for scene in ("indoor", "outdoor"):
        for light in LIGHTS:
            out = args.out / scene / f"{light}.png"
            render_one(out, args.resolution, args.samples, lambda s=scene, l=light: indoor_scene(l) if s == "indoor" else outdoor_scene(l))

    for kind in PLANTS:
        out = args.out / "plants" / f"{kind}.png"
        render_one(out, args.resolution, args.samples, lambda k=kind: plant_scene(k), plant=True)


if __name__ == "__main__":
    main()
