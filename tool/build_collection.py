# ============================================================
# La petite collection de l'onboarding : cinq plantes en pot, chacune rendue
# seule, que l'application fait ensuite graviter les unes autour des autres.
#
# Meme scene, memes materiaux et meme camera que l'icone : argile mate,
# lumiere de studio, vue 3/4 orthographique. Chaque plante est cadree pour
# elle-meme, sur fond transparent et sans ombre portee — l'ombre et le
# flottement sont dessines par l'application.
#
# Cinq silhouettes differentes, pour que la rangee ne soit pas cinq fois la
# meme plante : un monstera, un caoutchouc a feuilles entieres, une
# sansevieria en lames droites, une petite plante ronde, un semis. Les
# feuilles sortent toutes de `make_leaf` : c'est sa largeur relative, sa
# longueur et son nombre de fentes qui changent la silhouette.
#
# Execution :
#   blender -b -noaudio -P tool/build_collection.py -- <res> <samples> <dossier>
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
RES = int(argv[0]) if len(argv) > 0 else 512
SAMPLES = int(argv[1]) if len(argv) > 1 else 48
DOSSIER = argv[2] if len(argv) > 2 else "/tmp/collection"
os.makedirs(DOSSIER, exist_ok=True)

# Une feuille : (azimut, inclinaison, petiole, limbe, largeur relative,
# fentes, trous, roulis).
PLANTES = [
    {
        "nom": "monstera",
        "pot": ("C87A57", 1.0),
        "feuille": "0E6B34",
        "feuilles": [
            (206.0, 34.0, 0.66, 1.16, 0.435, 4, 2, -8.0),
            (28.0, 30.0, 0.78, 1.08, 0.435, 4, 2, 6.0),
            (96.0, 16.0, 0.92, 0.78, 0.435, 3, 1, -10.0),
        ],
    },
    {
        # Feuilles entieres et larges, comme un caoutchouc : aucune fente.
        "nom": "caoutchouc",
        "pot": ("B87050", 0.92),
        "feuille": "18693C",
        "feuilles": [
            (200.0, 42.0, 0.50, 0.80, 0.60, 0, 0, -12.0),
            (44.0, 38.0, 0.62, 0.86, 0.60, 0, 0, 10.0),
            (300.0, 24.0, 0.74, 0.72, 0.58, 0, 0, -6.0),
            (128.0, 55.0, 0.40, 0.62, 0.56, 0, 0, 14.0),
        ],
    },
    {
        # Lames droites et etroites, comme une sansevieria : presque pas de
        # petiole, les feuilles partent de la terre.
        "nom": "sansevieria",
        "pot": ("CE8462", 0.80),
        "feuille": "2A7A4C",
        "feuilles": [
            (210.0, 9.0, 0.10, 1.42, 0.115, 0, 0, 0.0),
            (330.0, 14.0, 0.10, 1.24, 0.105, 0, 0, 4.0),
            (90.0, 6.0, 0.10, 1.55, 0.100, 0, 0, -3.0),
            (30.0, 17.0, 0.10, 1.10, 0.095, 0, 0, 6.0),
            (150.0, 12.0, 0.10, 1.32, 0.105, 0, 0, -5.0),
        ],
    },
    {
        # Petites feuilles rondes au bout de longues tiges fines.
        "nom": "ronde",
        "pot": ("C0764F", 0.86),
        "feuille": "2E8B57",
        "feuilles": [
            (190.0, 46.0, 0.62, 0.40, 0.92, 0, 0, 0.0),
            (250.0, 33.0, 0.74, 0.36, 0.92, 0, 0, 0.0),
            (20.0, 50.0, 0.58, 0.38, 0.92, 0, 0, 0.0),
            (80.0, 28.0, 0.80, 0.34, 0.92, 0, 0, 0.0),
            (320.0, 58.0, 0.48, 0.32, 0.92, 0, 0, 0.0),
        ],
    },
    {
        # Un semis : deux cotyledons ronds, rien d'autre.
        "nom": "semis",
        "pot": ("D18C68", 0.62),
        "feuille": "359160",
        "feuilles": [
            (215.0, 26.0, 0.46, 0.34, 0.95, 0, 0, 0.0),
            (35.0, 24.0, 0.50, 0.36, 0.95, 0, 0, 0.0),
        ],
    },
]

MAT_TIGE = make_mat("MAT_Tige", "227A45", 0.55, 0.26, grain=55.0, relief=0.008, sss=0.12)
MAT_TERRE = make_mat("MAT_Terre", "3B302A", 0.90, 0.06, grain=20.0, relief=0.040, sss=0.0)


def construire(recette):
    """Une plante en pot, seule au monde."""
    couleur_pot, echelle = recette["pot"]
    mat_pot = make_mat("MAT_Pot_" + recette["nom"], couleur_pot, 0.68, 0.18,
                       grain=34.0, relief=0.024, sss=0.10)
    mat_feuille = make_mat("MAT_Feuille_" + recette["nom"], recette["feuille"],
                           0.52, 0.32, grain=60.0, relief=0.008, sss=0.14)
    pot = revolve("Pot", POT_PROFIL, 96, [mat_pot], 34.0)
    terre = revolve("Terre", TERRE_PROFIL, 96, [MAT_TERRE], 40.0)
    # Les petits pots sont plus petits en tout : la terre suit.
    for ob in (pot, terre):
        ob.scale = (echelle, echelle, echelle)
    objets = [pot, terre]

    sol = Z_TERRE * echelle
    for idx, (az, tilt, Lp, L, larg, nfe, ntr, roll) in enumerate(recette["feuilles"]):
        a, t = radians(az), radians(tilt)
        P0 = Vector((0.10 * echelle * cos(a), 0.10 * echelle * sin(a), sol - 0.03))
        dirn = Vector((sin(t) * cos(a), sin(t) * sin(a), cos(t)))
        P2 = P0 + dirn * Lp
        P1 = P0 + Vector((0, 0, Lp * 0.58))
        npt = 14
        pts, radii = [], []
        for i in range(npt + 1):
            s = i / float(npt); u = 1.0 - s
            pts.append(P0 * (u * u) + P1 * (2 * u * s) + P2 * (s * s))
            radii.append(0.052 - 0.020 * s)
        objets.append(tube_along("Tige_%02d" % (idx + 1), pts, radii, mat=MAT_TIGE))

        T = (pts[-1] - pts[-2]).normalized()
        outward = Vector((cos(a), sin(a), 0.0))
        # La face du limbe regarde surtout la camera, avec un appoint vers le
        # haut et vers l'exterieur.
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
                                Xl2, Yl, Zl2, L=L, n_fentes=nfe, mat=mat_feuille,
                                n_trous=ntr, w_ratio=larg))
    return objets


for recette in PLANTES:
    purge()
    bpy.context.scene.name = "Collection_" + recette["nom"]
    # Les materiaux sont recrees a chaque purge : rien ne survit d'une plante
    # a l'autre, chacune est rendue dans une scene neuve.
    MAT_TIGE = make_mat("MAT_Tige", "227A45", 0.55, 0.26, grain=55.0, relief=0.008, sss=0.12)
    MAT_TERRE = make_mat("MAT_Terre", "3B302A", 0.90, 0.06, grain=20.0, relief=0.040, sss=0.0)
    objets = construire(recette)
    # Cadrage large : chaque plante est ensuite posee et deplacee par
    # l'application, et ne doit pas toucher les bords de sa propre image.
    studio(objets, fill=0.86)
    rendu_transparent(RES, SAMPLES)
    chemin = os.path.join(DOSSIER, "collection_%s.png" % recette["nom"])
    bpy.context.scene.render.filepath = chemin
    bpy.ops.render.render(write_still=True)
    grain(chemin)
    print("PLANTE %s -> %s" % (recette["nom"], chemin), flush=True)

print("COLLECTION:", DOSSIER)
