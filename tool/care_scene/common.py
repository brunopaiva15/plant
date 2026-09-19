# ============================================================
# La boite a outils de la scene « environnement ideal » des fiches
# d'entretien : la camera fixe, la palette de la piece, les materiaux qui ne
# sont pas dans clay_scene (vitre lumineuse, tache de soleil), et la
# projection des emplacements de plante vers l'image.
#
# A la difference des objets clay habituels, TOUTES les couches partagent le
# meme cadre : la camera est posee une fois pour toutes par des constantes,
# pas sur le contenu de chaque couche. C'est ce qui permet a
# l'application de superposer decor, plante et props sans decallage — et la
# raison pour laquelle `studio()` de clay_scene, qui cadre sur le contenu,
# n'est pas utilise ici.
#
# Rien ne s'execute a l'import : les scripts qui s'en servent construisent
# leur propre scene.
# ============================================================
import bpy, bmesh
from mathutils import Vector
from math import sin, cos, radians
import os, sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from clay_scene import make_mat, revolve, tube_along, hexcol  # noqa: E402  — le chemin doit etre pose avant

# ------------------------------------------------------------
# la camera fixe : une vue orthographique 3/4, plus haute que celle des
# objets clay (14°) pour lire le sol de la piece
# ------------------------------------------------------------
AZ = radians(-52.0)
EL = radians(32.0)
VUE = Vector((cos(AZ) * cos(EL), sin(AZ) * cos(EL), sin(EL)))
CIBLE = Vector((0.0, 0.05, 0.80))
DIST = 30.0

# ------------------------------------------------------------
# le cadre
# ------------------------------------------------------------
# Le cadre est pose en constantes explicites, jamais calcule sur le contenu :
# c'est la meme raison qui fait que la camera ne cadre pas chaque couche
# separement. S'il suivait la geometrie, ajouter un prop deplacerait le
# cadre, et avec lui toute la table des emplacements et toutes les images.
#
# Il etait carre. Le contenu des trois decors et des silhouettes tient en
# 6,34 de large sur 5,64 de haut : le carre perdait donc pres d'un quart de
# sa surface, surtout en hauteur, et la plante s'en trouvait d'autant plus
# petite. Les valeurs ci-dessous portent deja leur marge de 5 %.
# Le cadre livre, en pixels : c'est lui qui fixe le format, et l'`aspect`
# lu par Flutter en decoule. Un apercu rendu plus petit garde le meme
# rapport a l'arrondi pres.
CADRE_RES = (1024, 910)
CADRE_RATIO = CADRE_RES[0] / float(CADRE_RES[1])
CADRE_DEMI_L = 3.33
# Le contenu est plus haut que bas autour de la visee : la camera monte
# d'autant le long de l'axe vertical de l'image pour le centrer.
CADRE_VISEE_U = 0.30

# Les dimensions de la piece, dont se servent les trois decors pour se
# superposer exactement. Le cadre, lui, ne s'en deduit plus : il est pose
# par les constantes CADRE_* ci-dessus.
PIECE_X, PIECE_Y, PIECE_Z = 2.1, 1.8, 2.7
EPAIS_MUR = 0.12

# La fenetre, sur le mur de gauche (-x) : elle apparait a gauche de l'image,
# la lumiere decline vers la droite.
FENETRE = {"y0": -0.45, "y1": 1.05, "z0": 0.75, "z1": 2.25}

# La direction du soleil a travers la fenetre : vers +x, en descendant.
SOLEIL = Vector((1.0, 0.18, -1.05))

# Les emplacements de la plante (x, y au sol), nommes comme les valeurs de
# `CarePlantSlot` cote application. La distance a la fenetre encode le besoin
# lumineux : plus la plante est loin de la fenetre, moins elle demande de
# lumiere.
#
# Les six tiennent sur UNE droite, a pas constant : du fond de la piece
# jusque dans la tache de soleil, la plante glisse d'un cran a chaque cran
# de lumiere, toujours du meme pas et dans le meme sens. Un emplacement pose
# au hasard dans la piece se lirait comme un hasard — d'une fiche a l'autre,
# la plante sauterait d'un coin a l'autre sans rien dire.
#
# La tache de soleil (room._faisceau, bakee dans le decor) va de x = -1.386
# (bord cote fenetre) a x = 0.043 (bord cote piece) : c'est elle qui decide
# des trois derniers crans — a cote (x = 0.16), sur le bord (-0.17), dedans
# (-0.50).
#
# Marge de securite autour de l'interieur de la piece : le depart reste
# assez loin des murs du fond et de droite pour que la silhouette la plus
# large (le monstera, 1,65 m) n'y touche jamais — il reste environ 0,10 m
# d'air entre son feuillage et le mur, a quelque cran que ce soit.
MARGE_PIECE = 0.95
PAS = (-0.33, -0.06)
_DEPART = (round(PIECE_X - MARGE_PIECE, 2), round(PIECE_Y - MARGE_PIECE, 2))
SLOTS = {
    nom: (round(_DEPART[0] + i * PAS[0], 2), round(_DEPART[1] + i * PAS[1], 2))
    for i, nom in enumerate(
        ["backCorner", "back", "middle", "besideBeam", "beamEdge", "sunZone"]
    )
}

# La plante est rendue seule, au centre du monde ; l'application la translate
# ensuite de (slot - ancre) en coordonnees fractionnaires.
ANCRE_MONDE = Vector((0.0, 0.0, 0.0))


def camera_fixe():
    """La camera orthographique commune a toutes les couches.

    Le cadre (position, `ortho_scale`, visee) ne depend que des constantes
    CADRE_* definies plus haut : deux couches au contenu different obtiennent
    exactement le meme cadrage, condition de la composition cote application.
    """
    sc = bpy.context.scene
    donnees = bpy.data.cameras.new("CAM")
    donnees.type = "ORTHO"
    donnees.clip_start = 0.1
    donnees.clip_end = 200.0
    cam = bpy.data.objects.new("CAM", donnees)
    sc.collection.objects.link(cam)
    sc.camera = cam
    cam.rotation_euler = (radians(90.0) - EL, 0.0, AZ + radians(90.0))
    cam.location = CIBLE + VUE * DIST
    bpy.context.view_layer.update()
    M = cam.matrix_world.to_3x3()
    Rv = (M @ Vector((1, 0, 0))).normalized()
    Uv = (M @ Vector((0, 1, 0))).normalized()
    Cv = (M @ Vector((0, 0, 1))).normalized()
    # Recentrer le cadre sur le contenu : monter la camera le long de l'axe
    # vertical de l'image fait descendre le contenu d'autant.
    cam.location = cam.location + Uv * CADRE_VISEE_U
    # `ortho_scale` porte sur la plus grande dimension du rendu — ici la
    # largeur, le cadre etant plus large que haut.
    donnees.ortho_scale = 2.0 * CADRE_DEMI_L
    bpy.context.view_layer.update()
    return cam, Rv, Uv, Cv


def resolution(largeur):
    # Les deux dimensions du rendu pour une largeur donnee. Le cadre n'est
    # plus carre : toute projection et tout rendu doivent partager ce
    # format, sinon `world_to_camera_view` rend des y compresses et la
    # plante ne tombe plus sur son ombre.
    return int(largeur), int(round(largeur * CADRE_RES[1] / float(CADRE_RES[0])))


def projette(cam, p):
    """Le point du monde vu dans l'image, en coordonnees fractionnaires
    (x depuis la gauche, y depuis le haut) — le repere de Flutter."""
    from bpy_extras.object_utils import world_to_camera_view
    co = world_to_camera_view(bpy.context.scene, cam, Vector(p))
    return (round(co.x, 5), round(1.0 - co.y, 5))


# ------------------------------------------------------------
# petites primitives de la piece (boites, plaques)
# ------------------------------------------------------------
def maille(nom, verts, faces, mat=None, biseau=0.0, lisse=False, segments=3):
    me = bpy.data.meshes.new(nom)
    me.from_pydata([tuple(v) for v in verts], [], faces)
    me.update()
    ob = bpy.data.objects.new(nom, me)
    bpy.context.scene.collection.objects.link(ob)
    if mat:
        me.materials.append(mat)
    bm = bmesh.new()
    bm.from_mesh(me)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-6)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me)
    bm.free()
    if lisse:
        for p in me.polygons:
            p.use_smooth = True
    if biseau > 0:
        md = ob.modifiers.new("Adoucissement", "BEVEL")
        md.width = biseau
        md.segments = segments
        md.limit_method = "ANGLE"
        md.angle_limit = radians(30)
        md.use_clamp_overlap = True
    return ob


def boite(nom, centre, taille, mat, biseau=0.02):
    cx, cy, cz = centre
    sx, sy, sz = taille
    x0, x1 = cx - sx / 2, cx + sx / 2
    y0, y1 = cy - sy / 2, cy + sy / 2
    z0, z1 = cz - sz / 2, cz + sz / 2
    verts = [(x0, y0, z0), (x1, y0, z0), (x1, y1, z0), (x0, y1, z0),
             (x0, y0, z1), (x1, y0, z1), (x1, y1, z1), (x0, y1, z1)]
    faces = [(0, 1, 2, 3), (4, 5, 6, 7), (0, 1, 5, 4),
             (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]
    return maille(nom, verts, faces, mat, biseau=biseau)


# ------------------------------------------------------------
# materiaux propres a la piece
# ------------------------------------------------------------
def materiau(nom, hexa, rough=0.62, relief=0.009):
    """La matiere clay des murs et des meubles : la meme recette que la
    maison de l'onboarding."""
    return make_mat(nom, hexa, rough=rough, spec=0.20, grain=48.0, relief=relief, sss=0.08)


def teinte(a, b, t):
    """Entre deux teintes 8 bits, en sRGB : la vitre passe du gris-bleu de
    l'ombre au dore du soleil sans changer de materiau."""
    t = min(max(t, 0.0), 1.0)
    return "".join("%02X" % round(int(a[i:i + 2], 16) * (1.0 - t) + int(b[i:i + 2], 16) * t)
                   for i in (0, 2, 4))


def materiau_vitre(chaleur, force):
    """La vitre : une plaque lumineuse, du gris-bleu de l'ombre au dore du
    soleil selon la variante. Elle eclaire un peu la piece, en plus."""
    mat = bpy.data.materials.new("MAT_Vitre")
    mat.use_nodes = True
    b = mat.node_tree.nodes["Principled BSDF"]
    couleur = teinte("C9DCE4", "FFD9A0", chaleur)
    b.inputs["Base Color"].default_value = hexcol(couleur)
    b.inputs["Roughness"].default_value = 0.35
    for nom in ("Emission Color", "Emission"):
        if nom in b.inputs:
            b.inputs[nom].default_value = hexcol(couleur)
            break
    if "Emission Strength" in b.inputs:
        b.inputs["Emission Strength"].default_value = force
    mat.diffuse_color = hexcol(couleur)
    return mat


def materiau_faisceau(nom, intensite):
    """La tache de soleil au sol : une emission chaude melee de transparence
    pure, comme les voiles des guides de multiplication. [intensite] suit la
    variante de lumiere ; 0 la fait disparaitre."""
    mat = bpy.data.materials.new(nom)
    mat.use_nodes = True
    nt = mat.node_tree
    em = nt.nodes.new("ShaderNodeEmission")
    em.inputs["Color"].default_value = hexcol("FFD88F")
    em.inputs["Strength"].default_value = 1.4
    tr = nt.nodes.new("ShaderNodeBsdfTransparent")
    mix = nt.nodes.new("ShaderNodeMixShader")
    mix.inputs["Fac"].default_value = min(max(intensite, 0.0), 1.0)
    nt.links.new(tr.outputs["BSDF"], mix.inputs[1])
    nt.links.new(em.outputs["Emission"], mix.inputs[2])
    nt.links.new(mix.outputs["Shader"], nt.nodes["Material Output"].inputs["Surface"])
    return mat


# ------------------------------------------------------------
# lumieres
# ------------------------------------------------------------
def aire(nom, position, visee, taille, energie, couleur=(1.0, 1.0, 1.0),
         forme="SQUARE", taille_y=None):
    ld = bpy.data.lights.new(nom, type="AREA")
    ld.shape = forme
    ld.size = taille
    if forme == "RECTANGLE" and taille_y is not None:
        ld.size_y = taille_y
    ld.energy = energie
    ld.color = couleur
    ob = bpy.data.objects.new(nom, ld)
    bpy.context.scene.collection.objects.link(ob)
    ob.location = Vector(position)
    ob.rotation_euler = (Vector(visee) - ob.location).to_track_quat("-Z", "Y").to_euler()
    return ob


def monde(force, couleur=(0.85, 0.87, 0.86)):
    w = bpy.data.worlds.new("World")
    bpy.context.scene.world = w
    w.use_nodes = True
    bg = w.node_tree.nodes["Background"]
    bg.inputs[0].default_value = (couleur[0], couleur[1], couleur[2], 1.0)
    bg.inputs[1].default_value = force
    return w


# ------------------------------------------------------------
# le couloir de la plante : la contrainte est a l'ecran, pas dans la piece
# ------------------------------------------------------------
# L'enveloppe de la silhouette la plus large (le monstera) dans son image,
# relative au point d'ancrage, mesuree sur le sprite livre. Deux objets
# eloignes de deux metres dans la piece peuvent parfaitement se superposer
# dans une vue orthographique : c'est ce qui avait mis un lampadaire pile
# sous le pot.
#
# Elle est en fractions du cadre : elle change donc avec le cadre. Pour la
# remesurer apres un changement de CADRE_* ou de silhouette :
#
#     python3 tool/mesure_enveloppe.py
ENVELOPPE_PLANTE = (-0.118, -0.176, 0.112, 0.015)


def releve_gueridon(cam):
    # De combien le gueridon souleve la plante, en fraction d'image. Deduit
    # de la projection plutot que fige : une constante mesuree dans un cadre
    # devient fausse dans le suivant.
    return projette(cam, (0.0, 0.0, 0.605))[1] - projette(cam, (0.0, 0.0, 0.0))[1]


def rects_plante(cam):
    """Pour chaque emplacement, le rectangle d'ecran que la plante peut
    occuper et la distance de cet emplacement a la camera.

    La projection depend du format de l'image : on le fixe au carre, comme
    les couches le seront. Sans cela `world_to_camera_view` rend des y
    compresses par le 16:9 par defaut de Blender — meme piege que dans
    `exporte_slots`.
    """
    sc = bpy.context.scene
    memo = (sc.render.resolution_x, sc.render.resolution_y)
    sc.render.resolution_x, sc.render.resolution_y = resolution(1024)
    bpy.context.view_layer.update()
    ex0, ey0, ex1, ey1 = ENVELOPPE_PLANTE
    releve = releve_gueridon(cam)
    out = []
    for (x, y) in SLOTS.values():
        sx, sy = projette(cam, (x, y, 0.0))
        profondeur = (Vector((x, y, 0.0)) - cam.location).length
        # au sol, et sur le gueridon qui souleve la plante
        for dz in (0.0, releve):
            out.append(((sx + ex0, sy + ey0 + dz, sx + ex1, sy + ey1 + dz), profondeur))
    sc.render.resolution_x, sc.render.resolution_y = memo
    bpy.context.view_layer.update()
    return out


def verifie_couloir(cam, objets, marge=0.5, pas=7):
    """Les objets de [objets] qui se retrouveraient DEVANT la plante.

    La contrainte est a l'ecran : dans une vue orthographique, deux objets
    eloignes de deux metres dans la piece se superposent parfaitement. Un
    lampadaire pose dans le coin oppose peut donc monter pile sous le pot —
    c'est arrive, et rien ne le disait.

    Passer derriere la plante n'est pas une faute : c'est ce qui donne sa
    profondeur a la scene. Seul compte ce qui est plus pres de la camera que
    l'emplacement dont il recoupe la silhouette.

    On regarde les sommets, pas la boite englobante : une plinthe ou un
    tapis sont de longues boites dont un coin frole la camera alors que rien
    de leur matiere ne passe devant la plante. [pas] echantillonne les
    maillages denses.

    [marge] est la distance, en metres, au-dela de laquelle « devant » veut
    dire quelque chose. La console du fond est a deux centimetres pres a la
    profondeur de l'emplacement du milieu : la signaler serait du bruit. Le
    lampadaire fautif, lui, etait deux metres et demi en avant.
    """
    rects = rects_plante(cam)
    sc = bpy.context.scene
    memo = (sc.render.resolution_x, sc.render.resolution_y)
    sc.render.resolution_x, sc.render.resolution_y = resolution(1024)
    bpy.context.view_layer.update()
    fautifs = []
    for ob in objets:
        if ob is None or ob.type != "MESH":
            continue
        M = ob.matrix_world
        sommets = ob.data.vertices
        indices = range(0, len(sommets), pas if len(sommets) > 400 else 1)
        for i in indices:
            p = M @ sommets[i].co
            d = (p - cam.location).length
            fx, fy = projette(cam, p)
            if any(d < prof - marge and r[0] <= fx <= r[2] and r[1] <= fy <= r[3]
                   for r, prof in rects):
                fautifs.append(ob.name)
                break
    sc.render.resolution_x, sc.render.resolution_y = memo
    bpy.context.view_layer.update()
    return sorted(set(fautifs))


def eclairage_plante(centre, Rv, Uv, Cv):
    """Les trois lumieres du studio clay, posees autour de la plante : elle
    garde le meme eclat quelle que soit la variante de la piece — c'est le
    decor qui porte l'information de lumiere."""
    O = Vector(centre)
    aire("LGT_Key", O - 3.4 * Rv + 4.4 * Uv + 3.0 * Cv, O, 11.0, 2600.0, (1.0, 0.985, 0.960))
    aire("LGT_Fill", O + 4.2 * Rv - 1.0 * Uv + 3.0 * Cv, O, 10.0, 520.0, (0.955, 0.975, 1.0))
    aire("LGT_Rim", O - 1.5 * Rv + 2.4 * Uv - 1.6 * Cv, O, 6.0, 900.0)
    monde(0.35)
