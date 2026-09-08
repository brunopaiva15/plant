#!/usr/bin/env python3
"""Les quatre symboles d'argile des familles de problemes.

ABIOTIQUE, RAVAGEUR, MALADIE, AFFECTION : les quatre valeurs du champ `type`
de assets/problems/catalog.txt. Meme studio et memes materiaux que l'icone et
que les illustrations de l'onboarding (tool/clay_scene.py), pour que les
symboles soient de la meme argile que le reste.

Rend des PNG 1024 RGBA sans ombre au sol : l'ombre est dessinee par
l'application. tool/pack_category_logos.py les reduit ensuite en WebP 512,
qui sont les fichiers embarques.

Execution :
  blender -b -noaudio -t 4 -P tool/build_category_logos.py -- --output build/category_logos
"""
import argparse
import math
import sys
from pathlib import Path

import bpy
import bmesh
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
from clay_scene import AZIMUT, ELEVATION, VUE, make_mat, purge, studio, rendu_transparent, tube_along, grain

R = Vector((-math.sin(AZIMUT), math.cos(AZIMUT), 0))
C = VUE.copy()
U = C.cross(R).normalized()
BASIS = Matrix((R, -C, U)).transposed()
CATEGORIES = ('abiotique', 'ravageur', 'maladie', 'affection')
M = {}


def world(x, depth, z):
    return R * x + C * depth + U * z


def material(name, color, rough=.64, relief=.009):
    return make_mat(name, color, rough=rough, spec=.20, grain=48., relief=relief, sss=.08)


def palette():
    global M
    M = {
        'sage': material('Sauge_2F7F53', '2F7F53'),
        'sage_light': material('Nervure_72A477', '72A477'),
        'sage_dark': material('Bord_286342', '286342'),
        'terra': material('Terracotta_BD5836', 'BD5836'),
        'terra_light': material('Terre_claire_C87A57', 'C87A57'),
        'terra_deep': material('Terre_sombre_91452E', '91452E'),
        'ochre': material('Ocre_C4903A', 'C4903A'),
        'ochre_light': material('Ocre_claire_E0B96A', 'E0B96A'),
        'water': material('Eau_4A82BC', '4A82BC', .52),
        'cream': material('Creme_FBF6EE', 'FBF6EE'),
        'ink': material('Encre_4A3528', '4A3528', .76),
        'soot': material('Fumagine_342D26', '342D26', .90, .014),
        'soot_light': material('Fumagine_50483A', '50483A', .86, .012),
        'honey': material('Miellat_D5A047', 'D5A047', .53),
    }


def mesh(name, verts, faces, mat):
    data = bpy.data.meshes.new(name)
    data.from_pydata(verts, [], faces)
    data.update()
    bm = bmesh.new(); bm.from_mesh(data)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-6)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(data); bm.free()
    obj = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat)
    for p in data.polygons:
        p.use_smooth = True
    return obj


def ball(name, pos, scale, mat, angle=0):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=48, ring_count=32, location=world(*pos))
    ob = bpy.context.object
    ob.name = name
    ob.rotation_euler = (BASIS @ Matrix.Rotation(math.radians(angle), 3, 'Y')).to_euler()
    ob.scale = scale
    ob.data.materials.append(mat)
    for p in ob.data.polygons:
        p.use_smooth = True
    return ob


def tube(name, coords, radius, mat):
    radii = radius if isinstance(radius, list) else [radius] * len(coords)
    # Catmull–Rom rounds the bends before sweeping: no hard elbows in clay.
    points = [Vector(p) for p in coords]
    smooth, sizes = [], []
    for i in range(len(points)-1):
        a,b,c,d=points[max(0,i-1)],points[i],points[i+1],points[min(len(points)-1,i+2)]
        for j in range(6):
            t=j/6
            p=.5*((2*b)+(-a+c)*t+(2*a-5*b+4*c-d)*t*t+(-a+3*b-3*c+d)*t*t*t)
            smooth.append(world(*p)); sizes.append(radii[i]*(1-t)+radii[i+1]*t)
    smooth.append(world(*points[-1])); sizes.append(radii[-1])
    return tube_along(name, smooth, sizes, n1=tuple(C), seg=20, cap=6, mat=mat)


def drop(name, x, z, radius, height, mat, depth=.40, angle=-10):
    # Closed, softened teardrop: a rounded belly and a gently drawn clay tip.
    profile = [(0, -.45), (.38, -.43), (.73, -.32), (.98, -.13),
               (1., .02), (.92, .19), (.71, .39), (.44, .63),
               (.20, .88), (.08, 1.03), (0, 1.09)]
    verts, faces = [], []
    a = math.radians(angle)
    for width, level in profile:
        for j in range(64):
            phi = 2 * math.pi * j / 64
            dx = radius * width * math.cos(phi)
            dz = height * level / 1.54
            dep = .62 * radius * width * math.sin(phi)
            verts.append(world(x + dx*math.cos(a)-dz*math.sin(a), depth+dep,
                               z + dx*math.sin(a)+dz*math.cos(a)))
    for i in range(len(profile)-1):
        for j in range(64):
            k=i*64+j; nj=i*64+(j+1)%64
            faces.append((k,nj,nj+64,k+64))
    ob = mesh(name, verts, faces, mat)
    sub = ob.modifiers.new('Argile_arrondie', 'SUBSURF'); sub.levels=2
    return ob


class Leaf:
    def __init__(self, x=0, z=0, scale=1, lean=30):
        self.x=x; self.z=z; self.scale=scale
        self.a=math.radians(lean)

    def coords(self, t, f, offset=0):
        width=.68*math.sin(math.pi*max(.00001,min(.99999,t)))**.72
        w=width*f*(1+.025*math.sin(t*11+f*2))
        h=(t-.5)*2.24
        # Broad clay leaf, convex in section with a small midrib fold.
        d=.08 + .19*math.sqrt(max(0,1-f*f))*math.sin(math.pi*t)**.65
        d+=.025*math.sin(t*math.pi*1.5) - .032*abs(f)
        d+=.006*math.sin(19*t+f*3)*math.sin(7*f)
        return (self.x+self.scale*(w*math.cos(self.a)+h*math.sin(self.a)),
                self.scale*d+offset,
                self.z+self.scale*(-w*math.sin(self.a)+h*math.cos(self.a)))

    def build(self):
        verts=[]; faces=[]; nt=72; nf=32
        for back in (False,True):
            for i in range(nt+1):
                t=max(.0001,min(.9999,i/nt))
                for j in range(nf+1):
                    f=-1+2*j/nf
                    x,d,z=self.coords(t,f)
                    if back:
                        d -= self.scale*(.055+.14*math.sqrt(max(0,1-f*f))*math.sin(math.pi*t)**.6)
                    verts.append(world(x,d,z))
        count=(nt+1)*(nf+1)
        for back in range(2):
            base=back*count
            for i in range(nt):
                for j in range(nf):
                    a=base+i*(nf+1)+j
                    face=(a,a+1,a+nf+2,a+nf+1)
                    faces.append(tuple(reversed(face)) if back else face)
        for i in range(nt):
            for j in (0,nf):
                a=i*(nf+1)+j; b=(i+1)*(nf+1)+j
                faces.append((a,b,b+count,a+count))
        for i in (0,nt):
            for j in range(nf):
                a=i*(nf+1)+j
                faces.append((a,a+count,a+count+1,a+1))
        leaf=mesh('Feuille_argile',verts,faces,M['sage'])
        # Raised veins are fully modelled; no bitmap decals.
        tube('Nervure_principale',[self.coords(t,0,.012) for t in [.015,.12,.25,.40,.56,.72,.88,.97]],
             [.035,.035,.032,.028,.025,.021,.015,.009],M['sage_light'])
        for side in (-1,1):
            for i,t in enumerate((.24,.40,.56,.72)):
                pts=[self.coords(t+u*.11,side*u*.80,.008) for u in (0,.2,.4,.6,.8,1)]
                tube(f'Nervure_{side}_{i}',pts,[.017,.016,.014,.012,.009,.005],M['sage_light'])
        p0=Vector(self.coords(.018,0,-.02)); p1=Vector(self.coords(.11,0,-.02))
        end=p0-(p1-p0).normalized()*.28*self.scale
        tube('Petiole',[tuple(end),tuple(p0),self.coords(.10,0,-.018)],.048*self.scale,M['sage_dark'])
        return leaf


def lesion(leaf,t,f,r,index):
    x,d,z=leaf.coords(t,f,.014)
    ball(f'Lesion_{index}_halo',(x,d,z),(r*1.25,.031,r*1.16),M['ochre'])
    ball(f'Lesion_{index}_necrose',(x-.004,d+.024,z),(r,.028,r*.93),M['terra_deep'])
    ball(f'Lesion_{index}_centre',(x+.014,d+.045,z+.004),(r*.48,.014,r*.44),M['ink'])


def abiotic():
    leaf=Leaf(-.23,-.11,.88,25); leaf.build()
    ball('Soleil_disque',(.70,-.10,.83),(.30,.15,.30),M['ochre'])
    for i in range(8):
        a=i*math.pi/4+.13
        coords=[(.70+r*math.cos(a),-.09,.83+r*math.sin(a)) for r in (.405,.47,.525)]
        tube(f'Soleil_rayon_{i}',coords,.052,M['ochre_light'])
    drop('Goutte_eau',.68,-.63,.26,.79,M['water'],depth=.38,angle=-12)


def pest():
    # A six-legged weevil, without ladybird dots or a mascot smile.
    for side in (-1,1):
        for i,(z,tip) in enumerate(((.28,.70),(-.10,-.11),(-.48,-.86))):
            coords=[(side*.27,.025,z),(side*.44,.055,z+.03),
                    (side*.66,.065,tip+.12),(side*.77,.10,tip),
                    (side*.90,.105,tip-.055)]
            tube(f'Patte_{side}_{i}',coords,[.073,.069,.062,.053,.038],M['ink'])
    ball('Abdomen', (0,0,-.26),(.54,.31,.71),M['terra_deep'])
    ball('Elytre_gauche',(-.235,.105,-.28),(.30,.255,.65),M['terra'])
    ball('Elytre_droite',(.235,.105,-.28),(.30,.255,.65),M['terra_light'])
    tube('Suture_des_elytres',[(0,.354,z) for z in (-.74,-.52,-.29,-.06,.22)],
         [.015,.019,.021,.019,.014],M['terra_deep'])
    ball('Pronotum',(0,.025,.36),(.33,.23,.28),M['terra_deep'])
    ball('Tete',(0,.065,.63),(.245,.20,.24),M['terra'])
    tube('Rostre',[(0,.17,.69),(0,.20,.81),(.015,.22,.94),(.055,.25,1.015)],
         [.115,.100,.086,.066],M['terra_deep'])
    for side in (-1,1):
        ball(f'Oeil_{side}',(side*.185,.217,.68),(.049,.043,.047),M['ink'])
        pts=[(side*.11,.13,.80),(side*.30,.10,.92),(side*.41,.12,1.115),(side*.52,.13,1.16)]
        tube(f'Antenne_{side}',pts,[.038,.035,.030,.026],M['ink'])
        ball(f'Massue_antenne_{side}',pts[-1],(.060,.045,.069),M['terra_deep'])


def disease():
    leaf=Leaf(0,-.01,1,29); leaf.build()
    for i,(t,f,r) in enumerate(((.29,-.48,.145),(.49,.44,.185),(.72,-.31,.127),(.80,.37,.079))):
        lesion(leaf,t,f,r,i)


def affection():
    leaf=Leaf(-.10,-.015,.99,27); leaf.build()
    # A thin irregular surface film: a distinct symbol for sooty mould,
    # the sole AFFECTION entry (181) in the current 200-problem catalogue.
    verts=[]; faces=[]; nt=54; nf=28
    for i in range(nt+1):
        t=.33+.59*i/nt
        edge=-.28+.12*math.sin(t*38)+.055*math.sin(t*81)
        fade=math.sin(math.pi*i/nt)**.30
        for j in range(nf+1):
            f=edge+(.96-edge)*j/nf
            f=.58+(f-.58)*fade
            verts.append(world(*leaf.coords(t,f,.033+.007*math.sin(t*74+f*18))))
    for i in range(nt):
        for j in range(nf):
            a=i*(nf+1)+j; faces.append((a,a+1,a+nf+2,a+nf+1))
    film=mesh('Depot_superficiel_fumagine',verts,faces,M['soot'])
    sol=film.modifiers.new('Film_fin','SOLIDIFY'); sol.thickness=.010
    for i,(t,f,r) in enumerate(((.30,.55,.045),(.40,-.43,.054),(.55,-.31,.040),(.81,-.25,.038))):
        x,d,z=leaf.coords(t,f,.04)
        ball(f'Fragment_depot_{i}',(x,d,z),(r,.014,r*.72),M['soot_light'])
    drop('Goutte_de_miellat',-.72,-.57,.255,.74,M['honey'],depth=.45,angle=14)
    ball('Perle_miellat',(-.93,.38,-.78),(.085,.056,.090),M['honey'])


def animate_native(root, ortho):
    # Optional native Blender animation, in the image plane. Runtime assets
    # remain still: Flutter rotates the already lit image with BreathPose.
    root.rotation_mode='QUATERNION'
    sc=bpy.context.scene; sc.render.fps=30; sc.frame_start=1; sc.frame_end=102
    for frame in range(1,104):
        phase=(frame-1)/102
        lift=math.sin(phase*2*math.pi)
        tilt=math.sin(phase*2*math.pi-math.pi/2)*.018
        root.location=U*(lift*ortho*.02)
        root.rotation_quaternion=__import__('mathutils').Quaternion(C, -tilt)
        root.keyframe_insert('location',frame=frame)
        root.keyframe_insert('rotation_quaternion',frame=frame)
    if root.animation_data and root.animation_data.action:
        root.animation_data.action.name='Respiration_3_4_secondes'
        for fc in root.animation_data.action.fcurves:
            for k in fc.keyframe_points: k.interpolation='LINEAR'
            fc.modifiers.new('CYCLES')
    sc.timeline_markers.new('Respiration / cycle 3.4 s',frame=1)
    sc.timeline_markers.new('Pose haute',frame=26)
    sc.timeline_markers.new('Pose basse',frame=77)


def build(category, output, res, samples):
    purge(); palette()
    {'abiotique':abiotic,'ravageur':pest,'maladie':disease,'affection':affection}[category]()
    objects=[o for o in bpy.context.scene.objects if o.type=='MESH']
    camera,*_=studio(objects,fill=.80)
    # Fixed framing and scale across the family; reserve room for motion.
    camera.data.ortho_scale=3.35
    camera.location=C*20+U*.04
    root=bpy.data.objects.new('Logo_'+category,None)
    bpy.context.collection.objects.link(root)
    for ob in objects: ob.parent=root
    rendu_transparent(res,samples)
    sc=bpy.context.scene
    sc.render.resolution_percentage=100
    sc.render.threads_mode='FIXED'; sc.render.threads=4
    sc['source_repo']='https://github.com/brunopaiva15/plant'
    sc['source_commit']='5176dcc595c441575410f6e2c11fc42bfa6646b5'
    sc['category']=category.upper()
    sc['motion']='3.4 s; dy=-sin(phase*2pi)*side*.02; angle=sin(phase*2pi-pi/2)*.018'
    sc['delivery']='RGBA still for Flutter. No baked ground shadow. Frame 103 closes frame 1; export 1..102.'
    png=output/'renders'/f'clay_{category}.png'
    sc.render.filepath=str(png)
    bpy.ops.render.render(write_still=True)
    grain(str(png),amplitude=.010,graine=7)
    animate_native(root,camera.data.ortho_scale)
    sc.frame_set(1)
    bpy.ops.wm.save_as_mainfile(filepath=str(output/'blend'/f'clay_{category}.blend'),compress=True)
    print('DELIVERED',category,str(png),flush=True)


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--output',type=Path,default=Path(__file__).resolve().parent.parent/'build'/'category_logos')
    parser.add_argument('--resolution',type=int,default=1024)
    parser.add_argument('--samples',type=int,default=64)
    parser.add_argument('--category',choices=CATEGORIES)
    args=parser.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
    for d in ('renders','blend'): (args.output/d).mkdir(parents=True,exist_ok=True)
    for category in ([args.category] if args.category else CATEGORIES):
        build(category,args.output,args.resolution,args.samples)


if __name__=='__main__': main()
