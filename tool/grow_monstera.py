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
import bpy, sys, os
from mathutils import Vector
from math import cos, sin, radians

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from clay_scene import (  # noqa: E402  — le chemin doit etre pose avant
    POT_PROFIL, TERRE_PROFIL, VUE, Z_TERRE,
    grain, make_leaf, make_mat, purge, rendu_transparent, revolve, studio, tube_along,
)

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
IMAGES = int(argv[0]) if len(argv) > 0 else 40
RES = int(argv[1]) if len(argv) > 1 else 1024
SAMPLES = int(argv[2]) if len(argv) > 2 else 40
DOSSIER = argv[3] if len(argv) > 3 else "/tmp/pousse"
os.makedirs(DOSSIER, exist_ok=True)

purge()
sc = bpy.context.scene
sc.name = "Pousse_Monstera"

MAT_FEUILLE = make_mat("MAT_Feuille", "0E6B34", 0.52, 0.32, grain=60.0, relief=0.008, sss=0.14)
MAT_TIGE = make_mat("MAT_Tige", "227A45", 0.55, 0.26, grain=55.0, relief=0.008, sss=0.12)
MAT_POT = make_mat("MAT_Pot_Terracotta", "C87A57", 0.68, 0.18, grain=34.0, relief=0.024, sss=0.10)
MAT_TERRE = make_mat("MAT_Terre", "3B302A", 0.90, 0.06, grain=20.0, relief=0.040, sss=0.0)

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


# La camera est cadree une fois pour toutes sur la plante adulte : cadrer
# chaque image ferait grandir le cadre avec la plante, qui semblerait alors
# immobile pendant que le monde retrecit autour d'elle.
adulte = plante(1.0)
studio(adulte, fill=0.80)
rendu_transparent(RES, SAMPLES)

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
