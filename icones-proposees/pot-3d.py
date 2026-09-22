import bpy, bmesh, math, sys, os
# YEUX=1 pose deux yeux sur le pot
YEUX=os.environ.get('YEUX')=='1'
from mathutils import Vector
argv=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
SAMPLES=int(argv[0]) if argv else 64; OUT=argv[1] if len(argv)>1 else '/tmp/r.png'
# fond : deux teintes du dégradé et teinte de la lumière d'ambiance
BG0,BG1,AMB=(argv[2:5] if len(argv)>=5 else ['#2F7D52','#5FA87A','#DDEFE2'])
bpy.ops.wm.read_factory_settings(use_empty=True)
sc=bpy.context.scene
def hexc(h,a=1):
    h=h.lstrip('#');c=[int(h[i:i+2],16)/255 for i in (0,2,4)]
    c=[x/12.92 if x<=0.04045 else ((x+0.055)/1.055)**2.4 for x in c];return (*c,a)
def mat(name,col,rough=.35,coat=.4,sss=0):
    m=bpy.data.materials.new(name);m.use_nodes=True;b=m.node_tree.nodes['Principled BSDF']
    b.inputs['Base Color'].default_value=hexc(col);b.inputs['Roughness'].default_value=rough
    b.inputs['Coat Weight'].default_value=coat;b.inputs['Coat Roughness'].default_value=.15
    if sss: b.inputs['Subsurface Weight'].default_value=sss;b.inputs['Subsurface Radius'].default_value=(.3,.15,.1)
    return m
def obj(name,me,m=None):
    o=bpy.data.objects.new(name,me);sc.collection.objects.link(o)
    if m: o.data.materials.append(m)
    return o
def subsurf(o,l=3):
    md=o.modifiers.new('s','SUBSURF');md.levels=l;md.render_levels=l
    for p in o.data.polygons: p.use_smooth=True

# ---- pot: profil tourné
prof=[(0.0,-1.6),(0.70,-1.6),(0.72,-1.55),(0.93,0.50),(0.94,0.55),(0.97,0.57),(1.10,0.585),(1.15,0.63),(1.165,0.72),(1.165,0.86),
      (1.15,0.93),(1.10,0.955),(1.03,0.95),(0.99,0.92),(0.98,0.86),(0.0,0.86)]
me=bpy.data.meshes.new('pot');bm=bmesh.new()
vs=[bm.verts.new((r,0,z)) for r,z in prof]
for a,b in zip(vs,vs[1:]): bm.edges.new((a,b))
bm.to_mesh(me);bm.free()
potm=bpy.data.materials.new('terre');potm.use_nodes=True;nt=potm.node_tree;N=nt.nodes;L=nt.links
bs=N['Principled BSDF'];bs.inputs['Roughness'].default_value=.62;bs.inputs['Coat Weight'].default_value=0;bs.inputs['Subsurface Weight'].default_value=.12;bs.inputs['Subsurface Radius'].default_value=(.3,.15,.1)
# joues : deux taches roses en coordonnées objet
tc=N.new('ShaderNodeTexCoord');base=N.new('ShaderNodeRGB');base.outputs[0].default_value=hexc('#FF7B45')
cur=base.outputs[0]
for x in ():
    d=N.new('ShaderNodeVectorMath');d.operation='DISTANCE';d.inputs[1].default_value=(x,-0.72,0.17)
    L.new(tc.outputs['Object'],d.inputs[0])
    mr=N.new('ShaderNodeMapRange');mr.inputs[1].default_value=0.05;mr.inputs[2].default_value=0.24;mr.inputs[3].default_value=.75;mr.inputs[4].default_value=0
    L.new(d.outputs['Value'],mr.inputs[0])
    mx=N.new('ShaderNodeMix');mx.data_type='RGBA';mx.inputs['B'].default_value=hexc('#FF7E95')
    L.new(mr.outputs[0],mx.inputs['Factor']);L.new(cur,mx.inputs['A']);cur=mx.outputs['Result']
# assombrir la terre cuite vers le bas
sep=N.new('ShaderNodeSeparateXYZ');L.new(tc.outputs['Object'],sep.inputs[0])
mr=N.new('ShaderNodeMapRange');mr.inputs[1].default_value=-1.5;mr.inputs[2].default_value=0.5;mr.inputs[3].default_value=.45;mr.inputs[4].default_value=0
L.new(sep.outputs['Z'],mr.inputs[0])
mx=N.new('ShaderNodeMix');mx.data_type='RGBA';mx.inputs['B'].default_value=hexc('#EA4F1E')
L.new(mr.outputs[0],mx.inputs['Factor']);L.new(cur,mx.inputs['A']);L.new(mx.outputs['Result'],bs.inputs['Base Color'])
pot=obj('pot',me,potm)
sw=pot.modifiers.new('tour','SCREW');sw.steps=96;sw.render_steps=96;sw.use_merge_vertices=True;sw.use_smooth_shade=True
subsurf(pot,2)

# ---- terre
bpy.ops.mesh.primitive_cylinder_add(vertices=96,radius=0.985,depth=0.1,location=(0,0,0.855))
soil=bpy.context.object;soil.data.materials.append(mat('terreau','#5E3A2A',rough=.95,coat=0))
dm=soil.modifiers.new('d','DISPLACE');tx=bpy.data.textures.new('n','CLOUDS');tx.noise_scale=.08;dm.texture=tx;dm.strength=.035
bpy.ops.object.shade_smooth()

if YEUX:
    eyem=mat('oeil','#14121C',rough=.12,coat=1)
    for x,r in ((-0.27,0.12),(0.28,0.13)):
        bpy.ops.mesh.primitive_uv_sphere_add(segments=48,ring_count=24,radius=r,location=(x,-0.84,0.33))
        e=bpy.context.object;e.scale=(1,.55,1.12);e.data.materials.append(eyem);bpy.ops.object.shade_smooth()
green=mat('tige','#1FB05A',rough=.6,coat=0,sss=.1)
# ---- tige
cu=bpy.data.curves.new('tige','CURVE');cu.dimensions='3D';cu.bevel_depth=.07;cu.bevel_resolution=6;cu.use_fill_caps=True
sp=cu.splines.new('BEZIER');sp.bezier_points.add(2)
for p,(co,h1,h2) in zip(sp.bezier_points,[((-0.03,0,0.80),(-0.03,0,0.6),(-0.03,0,1.0)),((0.0,0,1.35),(-0.05,0,1.2),(0.05,0,1.5)),((0.10,0.02,1.70),(0.07,0.02,1.62),(0.13,0.02,1.78))]):
    p.co=co;p.handle_left=h1;p.handle_right=h2
t=obj('tige',cu,green)
bpy.ops.mesh.primitive_uv_sphere_add(radius=.072,location=(0.10,0.02,1.70));bpy.context.object.data.materials.append(green);bpy.ops.object.shade_smooth()
# ---- feuilles
def leaf(name,L_,W,fold,curl,loc,rot,col):
    me=bpy.data.meshes.new(name);bm=bmesh.new();nu,nv=28,10;g=[]
    uvl=bm.loops.layers.uv.new()
    for i in range(nu+1):
        t=i/nu;w=W*(math.sin(math.pi*min(t*1.05,1))**0.85)*(1-0.15*t);row=[]
        for j in range(nv+1):
            v=j/nv*2-1
            row.append(bm.verts.new((t*L_, v*w, -abs(v)**1.3*w*fold+curl*t*t + 0.04*math.sin(t*math.pi))))
        g.append(row)
    for i in range(nu):
        for j in range(nv):
            f=bm.faces.new((g[i][j],g[i+1][j],g[i+1][j+1],g[i][j+1]))
            for lp,(a,b) in zip(f.loops,[(i,j),(i+1,j),(i+1,j+1),(i,j+1)]): lp[uvl].uv=(a/nu,b/nv)
    bm.to_mesh(me);bm.free()
    m=bpy.data.materials.new(name);m.use_nodes=True;nt=m.node_tree;N=nt.nodes;Lk=nt.links;b=N['Principled BSDF']
    b.inputs['Roughness'].default_value=.58;b.inputs['Coat Weight'].default_value=0
    b.inputs['Subsurface Weight'].default_value=.15
    uv=N.new('ShaderNodeUVMap');se=N.new('ShaderNodeSeparateXYZ');Lk.new(uv.outputs[0],se.inputs[0])
    # nervure : |v-0.5| petit
    m1=N.new('ShaderNodeMath');m1.operation='SUBTRACT';m1.inputs[1].default_value=.5;Lk.new(se.outputs['Y'],m1.inputs[0])
    m2=N.new('ShaderNodeMath');m2.operation='ABSOLUTE';Lk.new(m1.outputs[0],m2.inputs[0])
    mr=N.new('ShaderNodeMapRange');mr.inputs[1].default_value=.008;mr.inputs[2].default_value=.03;mr.inputs[3].default_value=.45;mr.inputs[4].default_value=0
    Lk.new(m2.outputs[0],mr.inputs[0])
    # dégradé base → pointe
    ramp=N.new('ShaderNodeValToRGB');ramp.color_ramp.elements[0].color=hexc(col[0]);ramp.color_ramp.elements[1].color=hexc(col[1])
    Lk.new(se.outputs['X'],ramp.inputs[0])
    mx=N.new('ShaderNodeMix');mx.data_type='RGBA';mx.inputs['B'].default_value=hexc('#9CF0A0')
    Lk.new(mr.outputs[0],mx.inputs['Factor']);Lk.new(ramp.outputs[0],mx.inputs['A']);Lk.new(mx.outputs['Result'],b.inputs['Base Color'])
    o=obj(name,me,m);o.location=loc;o.rotation_euler=[math.radians(a) for a in rot]
    s=o.modifiers.new('e','SOLIDIFY');s.thickness=.025;s.offset=0;subsurf(o,2)
    return o
leaf('feuilleD',1.25,.40,.45,.10,(0.10,0.02,1.66),(70,-28,0),('#14A34F','#5FE67A'))
leaf('feuilleG',0.95,.31,.45,.08,(0.0,0.0,1.44),(-70,-18,180),('#14A34F','#52DE70'))

# ---- monde : fond lilas vu par la caméra, lumière douce ailleurs
w=bpy.data.worlds.new('w');sc.world=w;w.use_nodes=True;nt=w.node_tree;N=nt.nodes;L=nt.links
bg=N['Background'];tc=N.new('ShaderNodeTexCoord');se=N.new('ShaderNodeSeparateXYZ');L.new(tc.outputs['Window'],se.inputs[0])
ma=N.new('ShaderNodeMath');ma.operation='ADD';L.new(se.outputs['X'],ma.inputs[0]);mb=N.new('ShaderNodeMath');mb.operation='SUBTRACT';mb.inputs[0].default_value=1;L.new(se.outputs['Y'],mb.inputs[1]);L.new(mb.outputs[0],ma.inputs[1])
mm=N.new('ShaderNodeMath');mm.operation='MULTIPLY';mm.inputs[1].default_value=.5;L.new(ma.outputs[0],mm.inputs[0])
ramp=N.new('ShaderNodeValToRGB');e=ramp.color_ramp.elements;e[0].color=hexc(BG0);e[1].color=hexc(BG1);L.new(mm.outputs[0],ramp.inputs[0])
amb=N.new('ShaderNodeBackground');amb.inputs[0].default_value=hexc(AMB);amb.inputs[1].default_value=.4
lp=N.new('ShaderNodeLightPath');mix=N.new('ShaderNodeMixShader');bg.inputs[1].default_value=1
L.new(ramp.outputs[0],bg.inputs[0]);L.new(lp.outputs['Is Camera Ray'],mix.inputs[0]);L.new(amb.outputs[0],mix.inputs[1]);L.new(bg.outputs[0],mix.inputs[2])
L.new(mix.outputs[0],N['World Output'].inputs[0])

def area(name,loc,size,energy,col='#FFFFFF'):
    l=bpy.data.lights.new(name,'AREA');l.size=size;l.energy=energy;l.color=hexc(col)[:3]
    o=obj(name,l);o.location=loc
    d=Vector((0,0,0.4))-Vector(loc);o.rotation_euler=d.to_track_quat('-Z','Y').to_euler()
area('cle',(-4,-5,6),6,1250,'#FFF4EA')
area('remplissage',(5,-4,1),5,200,'#DCD2FF')
area('contre',(3,4,5),5,350,'#FFFFFF')

cam=bpy.data.cameras.new('cam');cam.lens=132;co=obj('cam',cam);sc.camera=co
co.location=(0,-11.5,3.2);d=Vector((0,0,1.22))-co.location;co.rotation_euler=d.to_track_quat('-Z','Y').to_euler()

sc.render.engine='CYCLES';sc.cycles.device='CPU';sc.cycles.samples=SAMPLES;sc.cycles.use_denoising=True
sc.render.resolution_x=sc.render.resolution_y=1024;sc.view_settings.view_transform='Standard';sc.view_settings.look='None'
sc.render.filepath=OUT;bpy.ops.render.render(write_still=True)
import numpy as np
im=bpy.data.images.load(OUT);px=np.array(im.pixels[:],dtype=np.float32).reshape(-1,4)
lum=(px[:,:3]@np.array([.2126,.7152,.0722],dtype=np.float32))[:,None];px[:,:3]=np.clip(lum+(px[:,:3]-lum)*1.12,0,1)
rng=np.random.default_rng(7);g=rng.normal(0,.018,(px.shape[0],1)).astype(np.float32)
px[:,:3]=np.clip(px[:,:3]+g,0,1);im.pixels[:]=px.ravel();im.filepath_raw=OUT;im.file_format='PNG';im.save()
