# ============================================================
# Les objets des têtes vertes : ce qu'on pose à côté du grand chiffre d'un
# écran. Pour l'instant un arrosoir, en bleu `waterPop`, pour le matin.
#
# Même argile, même studio, même caméra que l'icône et la collection
# (clay_scene.py) : vue 3/4 orthographique, fond transparent, sans ombre
# portée — l'application pose l'objet sur son vert.
#
# Exécution :
#   blender -b -noaudio -P tool/build_objects.py -- <res> <samples> <dossier>
# puis la conversion en WebP (voir tool/README.md).
# ============================================================
import bpy, sys, os
from mathutils import Vector
from math import cos, sin, radians, atan2

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from clay_scene import (  # noqa: E402  — le chemin doit être posé avant
    VUE, grain, make_mat, purge, rendu_transparent, revolve, studio, tube_along,
)

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
RES = int(argv[0]) if len(argv) > 0 else 512
SAMPLES = int(argv[1]) if len(argv) > 1 else 48
DOSSIER = argv[2] if len(argv) > 2 else "/tmp/objets"
os.makedirs(DOSSIER, exist_ok=True)

# Les couleurs vives de la palette (lib/design_system/tokens/colors.dart).
WATER_POP = "5DB7FF"
SUN_POP = "FFE14D"


def arrosoir():
    """Un arrosoir trapu : un corps tourné aux bords arrondis, un bec qui
    monte vers la droite de l'image, sa pomme jaune, une anse en arc."""
    # Le rendu éclaircit : les teintes de départ sont un cran plus soutenues
    # que celles de la palette, pour qu'elles y reviennent à l'image.
    corps_m = make_mat("MAT_Arrosoir", "2C8FEF", 0.50, 0.30, grain=34.0, relief=0.014, sss=0.06)
    bord_m = make_mat("MAT_Bord", "1C6FD0", 0.50, 0.30, grain=34.0, relief=0.014, sss=0.06)
    pomme_m = make_mat("MAT_Pomme", "FFC400", 0.50, 0.30, grain=34.0, relief=0.014, sss=0.06)

    # Le corps : un tonneau bas, arrondi en bas et en haut, ouvert d'un col.
    profil = [
        (0.0, 0.0), (0.40, 0.0), (0.52, 0.03), (0.58, 0.10), (0.61, 0.22),
        (0.62, 0.45), (0.61, 0.66), (0.57, 0.80), (0.48, 0.90), (0.36, 0.95),
        (0.30, 0.97), (0.30, 1.03), (0.34, 1.05), (0.36, 1.08), (0.33, 1.11),
        (0.27, 1.10), (0.25, 1.02), (0.0, 1.00),
    ]
    corps = revolve("Corps", profil, 96, [corps_m], 40.0)

    # Le bec part du bas du corps et monte en s'effilant.
    bec_pts, bec_r = [], []
    P0, P1, P2 = Vector((0.45, 0, 0.28)), Vector((0.95, 0, 0.45)), Vector((1.30, 0, 1.02))
    n = 16
    for i in range(n + 1):
        s = i / n; u = 1 - s
        bec_pts.append(P0 * (u * u) + P1 * (2 * u * s) + P2 * (s * s))
        bec_r.append(0.105 - 0.045 * s)
    bec = tube_along("Bec", bec_pts, bec_r, n1=(0, 1, 0), seg=28, mat=corps_m)

    # La pomme : un disque bombé au bout du bec, tourné dans son axe.
    T = (bec_pts[-1] - bec_pts[-2]).normalized()
    pomme_pts = [bec_pts[-1] - T * 0.02, bec_pts[-1] + T * 0.05, bec_pts[-1] + T * 0.09, bec_pts[-1] + T * 0.11]
    pomme = tube_along("Pomme", pomme_pts, [0.07, 0.15, 0.20, 0.20], n1=(0, 1, 0), seg=40, cap=6, mat=pomme_m)

    # L'anse : un D au dos, qui part de l'épaule et rejoint le flanc.
    anse_pts, anse_r = [], []
    A = [Vector((-0.40, 0, 0.88)), Vector((-0.70, 0, 1.45)), Vector((-1.05, 0, 0.95)), Vector((-0.60, 0, 0.42))]
    for i in range(n + 1):
        s = i / n; u = 1 - s
        anse_pts.append(A[0] * u ** 3 + A[1] * 3 * u * u * s + A[2] * 3 * u * s * s + A[3] * s ** 3)
        anse_r.append(0.08)
    anse = tube_along("Anse", anse_pts, anse_r, n1=(0, 1, 0), seg=28, mat=corps_m)

    # Le col, d'un bleu un cran plus soutenu.
    col = revolve("Col", [(0.36, 1.07), (0.37, 1.09), (0.34, 1.12), (0.27, 1.11)], 96, [bord_m], 40.0)

    objets = [corps, bec, pomme, anse, col]
    # Le bec vers la droite de l'image, un peu tourné vers nous : l'axe x de
    # l'objet pivote entre la droite de la caméra et la caméra elle-même.
    droite = Vector((-VUE.y, VUE.x, 0)).normalized()
    angle = atan2(droite.y, droite.x) - radians(24)
    for ob in objets:
        ob.rotation_euler = (0, 0, angle)
    bpy.context.view_layer.update()
    return objets


OBJETS = {"arrosoir": arrosoir}

for nom, fabrique in OBJETS.items():
    purge()
    objets = fabrique()
    studio(objets, fill=0.86)
    rendu_transparent(RES, SAMPLES)
    # Le rendu « Standard » garde les couleurs vives telles quelles ; AgX,
    # fait pour la photo, les ramenait au pastel.
    bpy.context.scene.view_settings.view_transform = "Standard"
    chemin = os.path.join(DOSSIER, "%s.png" % nom)
    bpy.context.scene.render.filepath = chemin
    bpy.ops.render.render(write_still=True)
    grain(chemin)
    print("OBJET %s -> %s" % (nom, chemin), flush=True)
