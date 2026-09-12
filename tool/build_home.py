#!/usr/bin/env python3
"""La maison d'argile de l'onboarding (« Votre intérieur », Apple Maison).

Meme studio, memes materiaux et meme grain que les autres objets de la scene
(tool/clay_scene.py) : murs creme, toit de terre cuite, porte sauge, une
fenetre ronde couleur d'eau, une cheminee. Vue de trois quarts par la camera
commune, sans ombre au sol : l'application dessine la sienne.

Rend assets/onboarding/onboarding_7.png (PNG 1024 RGBA).

Execution :
  blender -b -noaudio -t 4 -P tool/build_home.py -- --output assets/onboarding/onboarding_7.png
  # apercu rapide : --resolution 512 --samples 16
"""
import argparse
import sys
from math import radians
from pathlib import Path

import bpy
import bmesh
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
from clay_scene import POT_PROFIL, TERRE_PROFIL, make_mat, purge, revolve, studio, rendu_transparent, grain

# La camera commune regarde depuis +x / -y : la face -y est la plus frontale,
# c'est elle qui porte la porte ; la face +x, de profil, porte la fenetre.
W, D, H = 2.00, 1.60, 1.25      # murs : largeur (x), profondeur (y), hauteur
ROOF_H, OVER, ROOF_T = 0.95, 0.16, 0.11   # toit : hauteur, debord, epaisseur


def material(name, color, rough=.62, relief=.009):
    return make_mat(name, color, rough=rough, spec=.20, grain=48., relief=relief, sss=.08)


def mesh(name, verts, faces, mat, bevel=0.03, segments=4):
    data = bpy.data.meshes.new(name)
    data.from_pydata(verts, [], faces)
    data.update()
    bm = bmesh.new(); bm.from_mesh(data)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-6)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(data); bm.free()
    ob = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(ob)
    ob.data.materials.append(mat)
    if bevel > 0:
        md = ob.modifiers.new('Adoucissement', 'BEVEL')
        md.width = bevel; md.segments = segments
        md.limit_method = 'ANGLE'; md.angle_limit = radians(30)
        md.use_clamp_overlap = True
    for p in data.polygons:
        p.use_smooth = True
    return ob


def box(name, center, size, mat, bevel=0.03):
    cx, cy, cz = center; sx, sy, sz = size
    x0, x1 = cx - sx / 2, cx + sx / 2
    y0, y1 = cy - sy / 2, cy + sy / 2
    z0, z1 = cz - sz / 2, cz + sz / 2
    verts = [(x0, y0, z0), (x1, y0, z0), (x1, y1, z0), (x0, y1, z0),
             (x0, y0, z1), (x1, y0, z1), (x1, y1, z1), (x0, y1, z1)]
    faces = [(0, 1, 2, 3), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]
    return mesh(name, verts, faces, mat, bevel=bevel)


def prism(name, mat):
    """Le toit : un toit a deux pans, faitiere le long de x, avec un debord et
    une epaisseur — une plaque d'argile pliee, pas une feuille."""
    x0, x1 = -W / 2 - OVER, W / 2 + OVER
    y0, y1 = -D / 2 - OVER, D / 2 + OVER
    zb = H - 0.02                      # les bords du toit, juste sous le haut des murs
    zt = H + ROOF_H
    # Dessous (fin), dessus (epais) : deux triangles extrudes le long de x.
    lo = [(x0, y0, zb), (x0, 0, zt), (x0, y1, zb), (x1, y0, zb), (x1, 0, zt), (x1, y1, zb)]
    hi = [(x0, y0 - ROOF_T * .35, zb + ROOF_T), (x0, 0, zt + ROOF_T), (x0, y1 + ROOF_T * .35, zb + ROOF_T),
          (x1, y0 - ROOF_T * .35, zb + ROOF_T), (x1, 0, zt + ROOF_T), (x1, y1 + ROOF_T * .35, zb + ROOF_T)]
    verts = lo + hi
    faces = [
        (0, 1, 4, 3), (1, 2, 5, 4),          # dessous des deux pans
        (6, 9, 10, 7), (7, 10, 11, 8),       # dessus des deux pans
        (0, 3, 9, 6), (2, 8, 11, 5),         # chants bas
        (0, 6, 7, 1), (1, 7, 8, 2),          # pignon x0
        (3, 4, 10, 9), (4, 5, 11, 10),       # pignon x1
    ]
    return mesh(name, verts, faces, mat, bevel=0.035, segments=5)


def disc(name, center, radius, thickness, mat, axis='x'):
    bpy.ops.mesh.primitive_cylinder_add(vertices=64, radius=radius, depth=thickness, location=center)
    ob = bpy.context.object
    ob.name = name
    if axis == 'x':
        ob.rotation_euler = (0, radians(90), 0)
    elif axis == 'y':
        ob.rotation_euler = (radians(90), 0, 0)
    ob.data.materials.append(mat)
    for p in ob.data.polygons:
        p.use_smooth = True
    md = ob.modifiers.new('Adoucissement', 'BEVEL')
    md.width = min(0.02, thickness * .4); md.segments = 4
    md.limit_method = 'ANGLE'; md.angle_limit = radians(30)
    return ob


def ball(name, center, radius, mat):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=32, ring_count=20, radius=radius, location=center)
    ob = bpy.context.object
    ob.name = name
    ob.data.materials.append(mat)
    for p in ob.data.polygons:
        p.use_smooth = True
    return ob


def house():
    cream = material('Creme_FBF6EE', 'FBF6EE')
    terra = material('Terracotta_BD5836', 'BD5836')
    terra_deep = material('Terre_sombre_91452E', '91452E')
    sage = material('Sauge_2F7F53', '2F7F53')
    water = material('Eau_4A82BC', '4A82BC', .52)
    ink = material('Encre_4A3528', '4A3528', .76)

    # Les murs, sur une plinthe un peu plus large : la maison est posee.
    box('Murs', (0, 0, H / 2), (W, D, H), cream, bevel=0.04)
    box('Plinthe', (0, 0, 0.035), (W + 0.10, D + 0.10, 0.07), terra_deep, bevel=0.02)
    prism('Toit', terra)
    # La cheminee, pres de la faitiere, a droite, et qui la depasse.
    cz = H + ROOF_H * .80
    box('Cheminee', (W * .30, D * .10, cz), (0.26, 0.26, 0.80), cream, bevel=0.025)
    box('Cheminee_haut', (W * .30, D * .10, cz + 0.42), (0.32, 0.32, 0.08), terra_deep, bevel=0.02)
    # La porte, sur la face avant (-y), un peu a gauche, en relief.
    box('Porte', (-W * .16, -D / 2 - 0.025, 0.42), (0.50, 0.06, 0.84), sage, bevel=0.02)
    ball('Poignee', (-W * .16 + 0.17, -D / 2 - 0.06, 0.40), 0.030, ink)
    # La fenetre ronde, sur la face de profil (+x) : un cadre creme et un
    # disque couleur d'eau, les deux en relief.
    disc('Cadre_fenetre', (W / 2 + 0.02, 0.0, H * .60), 0.27, 0.05, cream, axis='x')
    disc('Fenetre', (W / 2 + 0.045, 0.0, H * .60), 0.20, 0.03, water, axis='x')
    # Une seconde fenetre, plus petite, sur la facade, a droite de la porte.
    disc('Cadre_fenetre_2', (W * .26, -D / 2 - 0.02, H * .64), 0.19, 0.05, cream, axis='y')
    disc('Fenetre_2', (W * .26, -D / 2 - 0.045, H * .64), 0.135, 0.03, water, axis='y')
    # Une plante en pot devant la maison, a droite de la porte : le pot de
    # l'icone, en petit, et une touffe sauge.
    k = 0.30
    pot = revolve('Pot', [(r * k, z * k) for (r, z) in POT_PROFIL], mats=[terra])
    pot.location = (W * .40, -D / 2 - 0.30, 0.07)
    terre = revolve('Terre', [(r * k, z * k) for (r, z) in TERRE_PROFIL], mats=[terra_deep])
    terre.location = pot.location
    for i, (dx, dy, dz, r) in enumerate(((0, 0, .17, .16), (-.10, -.05, .11, .11), (.10, .04, .12, .10), (.02, -.11, .10, .09))):
        ball(f'Feuillage_{i}', (pot.location[0] + dx, pot.location[1] + dy, 0.07 + 0.90 * k + dz), r, sage)


def build(output, res, samples):
    purge()
    house()
    objects = [o for o in bpy.context.scene.objects if o.type == 'MESH']
    studio(objects, fill=.78)
    rendu_transparent(res, samples)
    sc = bpy.context.scene
    sc.render.threads_mode = 'FIXED'; sc.render.threads = 4
    output.parent.mkdir(parents=True, exist_ok=True)
    sc.render.filepath = str(output)
    bpy.ops.render.render(write_still=True)
    grain(str(output), amplitude=.010, graine=7)
    print('DELIVERED', str(output), flush=True)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--output', type=Path, default=Path(__file__).resolve().parent.parent / 'assets' / 'onboarding' / 'onboarding_7.png')
    parser.add_argument('--resolution', type=int, default=1024)
    parser.add_argument('--samples', type=int, default=96)
    args = parser.parse_args(sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else [])
    build(args.output, args.resolution, args.samples)


if __name__ == '__main__':
    main()
