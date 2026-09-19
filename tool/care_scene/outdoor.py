# ============================================================
# Le coin de jardin du diorama : une maquette posee, exactement comme la
# piece — meme dalle, meme empreinte, du vide transparent tout autour. Une
# pelouse sauge, un massif de pleine terre la ou la plante se pose, une
# allee de gravier et ses pas japonais, une palissade de bois au fond
# bordee de touffes fleuries, une haie basse a gauche qui tient lieu de
# coupe-vent, un petit arbre et un arrosoir — le soleil vient de la gauche,
# comme dans la piece, pour que la table des emplacements reste valable
# d'une scene a l'autre.
#
# La dalle est ce qui donne au jardin et au salon le meme statut dans la
# fiche. Sans elle, l'interieur flottait sur du transparent pendant que le
# jardin remplissait le cadre bord a bord : deux langages dans le meme
# emplacement, et le decor changeait de nature d'une espece a l'autre.
#
# Le decor reste en retrait : peu de vegetation, des verts grises, du
# mineral clair, rien de haut derriere la plante. C'est elle, rendue a part,
# qui porte la scene — le decor dit « dehors », pas « jardin botanique ».
# Rien n'est pose sur le couloir des six emplacements ni sur la tache de
# soleil : la plante ne rencontre jamais un massif ni un meuble, a quelque
# cran que ce soit.
#
# Meme camera fixe, memes bornes, meme direction de soleil que la piece
# (care_scene/common.py) : seuls le decor et les lumieres changent. Les six
# variantes vont du coin ombrage au plein soleil ; la plante est la meme
# dans les deux scenes.
#
# Rien ne s'execute a l'import.
# ============================================================
from mathutils import Vector
import os, sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from clay_scene import revolve, tube_along  # noqa: E402  — le chemin doit etre pose avant
from cutting.common import sphere  # noqa: E402  — primitives partagees des guides
from care_scene.common import (  # noqa: E402  — le chemin doit etre pose avant
    FENETRE, PIECE_X, PIECE_Y, SOLEIL,
    aire, boite, maille, materiau, materiau_faisceau, monde,
)

# Les six situations de lumiere, memes noms qu'en interieur. `soleil` est le
# panneau chaud qui passe par-dessus la haie ; `faisceau` la tache au sol.
# L'ambiante est un cran au-dessus de la piece : dehors, le fond clair
# detache la plante au lieu de l'enfoncer.
VARIANTES = {
    "shade":           {"monde": 0.24, "clef": 480.0,  "soleil": 300.0,  "appoint": 130.0, "chaleur": 0.00, "faisceau": 0.00},
    "low_light":       {"monde": 0.35, "clef": 660.0,  "soleil": 480.0,  "appoint": 170.0, "chaleur": 0.05, "faisceau": 0.00},
    "indirect":        {"monde": 0.47, "clef": 920.0,  "soleil": 760.0,  "appoint": 230.0, "chaleur": 0.10, "faisceau": 0.00},
    "bright_indirect": {"monde": 0.57, "clef": 1120.0, "soleil": 900.0,  "appoint": 270.0, "chaleur": 0.30, "faisceau": 0.45},
    "some_sun":        {"monde": 0.63, "clef": 1240.0, "soleil": 1100.0, "appoint": 300.0, "chaleur": 0.55, "faisceau": 0.70},
    "full_sun":        {"monde": 0.70, "clef": 1380.0, "soleil": 1300.0, "appoint": 330.0, "chaleur": 0.85, "faisceau": 1.00},
}

# La palissade : sa ligne au fond, la hauteur des lames, l'espacement.
CLOTURE_Y = PIECE_Y + 0.02
LAME_H = 1.34
LAME_L = 0.14
LAME_PAS = 0.27
LAME_X = 2.28


def _materiaux(v):
    # La palette se tait : pelouse sauge, massif sable, bois clair, haie
    # grisee. Rien de sature ne dispute l'oeil a la plante.
    return {
        "terre": materiau("MAT_PleineTerre", "6E5B47", rough=0.82, relief=0.032),
        "pelouse": materiau("MAT_Pelouse", "9EB894", rough=0.80, relief=0.024),
        "massif": materiau("MAT_Massif", "8E7B62", rough=0.86, relief=0.034),
        "bordure": materiau("MAT_Bordure", "C3B699", rough=0.76, relief=0.018),
        "bois": materiau("MAT_Palissade", "CBA878", rough=0.64, relief=0.012),
        "bois_fonce": materiau("MAT_PalissadeFonce", "A9855A", rough=0.66, relief=0.014),
        "feuille_haie": materiau("MAT_Haie", "8AA385", rough=0.68, relief=0.022),
        "feuille_lointaine": materiau("MAT_Boisement", "8CA184", rough=0.72, relief=0.020),
        "pierre": materiau("MAT_Pierre", "CFC6B4", rough=0.70, relief=0.018),
        # Le decor du jardin : l'allee, les fleurs de bordure, l'arrosoir,
        # le petit arbre. Des tons sourds : ils disent « jardin », ils ne
        # disputent pas la plante.
        "gravier": materiau("MAT_Gravier", "D3CBBA", rough=0.86, relief=0.034),
        "fleur_a": materiau("MAT_FleurA", "D8C0C6", rough=0.74, relief=0.018),
        "fleur_b": materiau("MAT_FleurB", "E0D2AE", rough=0.74, relief=0.018),
        "fleur_c": materiau("MAT_FleurC", "BFC9D8", rough=0.74, relief=0.018),
        "zinc": materiau("MAT_Zinc", "AFB6B4", rough=0.52, relief=0.008),
        "tronc": materiau("MAT_Tronc", "A88A6A", rough=0.70, relief=0.020),
    }


def _terrain(m):
    # Le jardin est une maquette posee, exactement comme la piece : meme
    # dalle, meme empreinte, et du vide transparent tout autour. C'est ce
    # qui leur donne le meme statut dans la fiche — sans quoi l'un est une
    # maquette et l'autre une photo pleine page, et passer d'une espece a
    # l'autre change de langage.
    boite("Dalle", (0.05, -0.075, -0.075), (4.8, 4.15, 0.15), m["terre"], 0.05)
    boite("Pelouse", (0.05, -0.075, -0.02), (4.76, 4.11, 0.06), m["pelouse"], 0.04)


def _massif(m):
    # La zone ou la plante se pose : un massif sobre — terre claire, bordure
    # simple, a peine sureleve pour que la tache de soleil y tienne. Le pot
    # et son ombre s'en detachent ; la pelouse reste du decor. Les six
    # emplacements et leur humidificateur tiennent dedans, avec marge :
    # jamais un pied a cheval sur la bordure.
    boite("Bordure", (0.22, 0.34, 0.008), (2.62, 1.62, 0.028), m["bordure"], 0.02)
    boite("Massif", (0.22, 0.34, 0.022), (2.46, 1.46, 0.026), m["massif"], 0.02)


def _palissade(m):
    # Des lames de bois debout, une legere variation de hauteur, deux
    # traverses derriere : la palette dit « jardin », pas « interieur ».
    n = int(2 * LAME_X / LAME_PAS) + 1
    xs = [-LAME_X + i * LAME_PAS for i in range(n)]
    for i, x in enumerate(xs):
        haut = LAME_H + 0.05 * ((i * 7) % 3 - 1)
        boite("Lame_%02d" % i, (x, CLOTURE_Y, haut / 2), (LAME_L, 0.045, haut), m["bois"], 0.015)
    # Les traverses s'arretent exactement ou s'arretent les lames : debordantes,
    # elles laissaient un bout de rail flotter au bord de la dalle.
    centre = (xs[0] + xs[-1]) / 2.0
    largeur = (xs[-1] - xs[0]) + LAME_L
    for j, z in enumerate((0.43 * LAME_H, 0.94 * LAME_H)):
        boite("Traverse_%d" % j, (centre, CLOTURE_Y + 0.05, z), (largeur, 0.05, 0.09), m["bois_fonce"], 0.012)
    # Quelques poteaux plus larges, qui depassent les lames d'une tete.
    for k in range(-1, 2):
        x = centre + k * (LAME_PAS * 6)
        boite("Poteau_%d" % (k + 1), (x, CLOTURE_Y + 0.02, (LAME_H + 0.26) / 2),
              (0.11, 0.11, LAME_H + 0.26), m["bois_fonce"], 0.02)


def _lointain(m):
    # Deux volumes lointains derriere la palissade : l'horizon reste dehors
    # sans raconter un boisement. Ils ne depassent la claie que d'un dôme —
    # desatures, ils ferment le fond sans passer derriere la plante.
    # Un petit arbre au fond a gauche, sur la dalle : il donne l'echelle et
    # une hauteur que la palissade seule n'a pas. Il reste hors du massif et
    # ne passe jamais derriere la plante.
    tube_along("Tronc", [(-1.44, 1.58, 0.0), (-1.38, 1.58, 1.26)],
               [0.085, 0.060], mat=m["tronc"], seg=14, cap=3)
    for nom, (x, y, z), r, e in (
        ("A", (-1.38, 1.58, 1.62), 0.44, (1.00, 1.00, 0.86)),
        ("B", (-1.06, 1.48, 1.44), 0.31, (1.04, 1.00, 0.88)),
        ("C", (-1.66, 1.70, 1.40), 0.29, (1.00, 1.06, 0.88)),
        ("D", (-1.30, 1.76, 1.30), 0.26, (1.02, 1.00, 0.90)),
        ("E", (-1.52, 1.40, 1.32), 0.27, (1.00, 1.04, 0.88)),
    ):
        sphere("Houppier_%s" % nom, (x, y, z), r, m["feuille_lointaine"], seg=28, echelle=e)


def _haie(m):
    # La haie basse, a gauche : trois masses arrondies qui se touchent, d'un
    # seul ton sauge. Elle fait coupe-vent — le soleil la franchit pour
    # toucher le massif — sans densifier le fond.
    # Des masses ecrasees et decalees, jamais trois fois la meme : une boule
    # nette se lit comme un oeuf, pas comme un buisson.
    masses = [
        (-2.04, -1.78, 0.30, 0.19, (1.00, 1.16, 0.68)),
        (-2.14, -1.54, 0.34, 0.22, (1.08, 1.02, 0.74)),
        (-2.00, -1.30, 0.29, 0.18, (0.96, 1.12, 0.70)),
        (-2.12, -1.06, 0.35, 0.23, (1.06, 1.00, 0.76)),
        (-2.02, -0.82, 0.30, 0.19, (1.00, 1.10, 0.70)),
        (-2.15, -0.58, 0.36, 0.24, (1.10, 1.02, 0.76)),
        (-2.01, -0.34, 0.29, 0.18, (0.98, 1.14, 0.68)),
        (-2.13, -0.10, 0.35, 0.23, (1.06, 1.00, 0.74)),
        (-2.03, 0.14, 0.31, 0.20, (1.00, 1.10, 0.72)),
        (-2.14, 0.38, 0.36, 0.24, (1.08, 1.02, 0.76)),
        (-2.02, 0.62, 0.30, 0.19, (0.96, 1.12, 0.70)),
        (-2.12, 0.86, 0.34, 0.22, (1.06, 1.00, 0.74)),
        (-2.04, 1.10, 0.29, 0.18, (1.00, 1.14, 0.68)),
        (-2.13, 1.34, 0.33, 0.21, (1.08, 1.02, 0.76)),
    ]
    for i, (x, y, r, z, e) in enumerate(masses):
        sphere("Haie_%02d" % i, (x, y, z), r, m["feuille_haie"], seg=36, echelle=e)


def _pierres(m):
    # Quelques pierres plates, pour l'echelle, sur le bord droit : l'indice
    # mineral qui ne vole jamais la vedette.
    for i, (x, y, r) in enumerate([(2.02, -1.72, 0.20), (2.24, -1.34, 0.15), (1.86, -2.00, 0.17)]):
        sphere("Pierre_%d" % i, (x, y, 0.03), r, m["pierre"], seg=20, echelle=(1.0, 0.8, 0.28))


def _allee(m):
    # Une allee de gravier en travers de l'avant, entre la pelouse et le
    # bord de la dalle : elle dit « on circule ici », et elle donne au
    # jardin une ligne que la pelouse seule n'a pas.
    boite("Allee", (0.05, -1.48, 0.006), (4.60, 0.62, 0.030), m["gravier"], 0.02)


def _pas_japonais(m):
    # Trois dalles de l'allee vers le massif : le chemin de celui qui vient
    # arroser. Elles restent a gauche des emplacements.
    for i, (x, y) in enumerate([(-0.92, -1.06), (-0.80, -0.72), (-0.70, -0.38)]):
        boite("Pas_%d" % i, (x, y, 0.016), (0.40, 0.30, 0.026), m["pierre"], 0.02)


def _bordure_fleurie(m):
    # Une bordure basse au pied de la palissade : des touffes ecrasees, trois
    # tons sourds, hauteurs inegales. Elle habille le fond sans monter assez
    # haut pour passer derriere la plante.
    touffes = [
        (-1.02, 1.70, 0.13, "fleur_b"), (-0.78, 1.60, 0.10, "fleur_a"),
        (-0.55, 1.71, 0.12, "fleur_c"), (-0.31, 1.61, 0.09, "fleur_b"),
        (-0.06, 1.69, 0.13, "fleur_a"), (0.19, 1.59, 0.10, "fleur_c"),
        (0.44, 1.70, 0.11, "fleur_b"), (0.69, 1.60, 0.13, "fleur_a"),
        (0.94, 1.71, 0.09, "fleur_c"), (1.19, 1.61, 0.12, "fleur_b"),
        (1.44, 1.69, 0.10, "fleur_a"), (1.69, 1.59, 0.13, "fleur_c"),
        (1.94, 1.70, 0.11, "fleur_b"), (2.16, 1.62, 0.09, "fleur_a"),
    ]
    for i, (x, y, r, mat) in enumerate(touffes):
        sphere("Touffe_%02d" % i, (x, y, r * 0.62), r, m[mat], seg=22,
               echelle=(1.0, 0.92, 0.66))


def _arrosoir(m):
    # Un arrosoir de zinc pose sur la pelouse, a droite : l'objet qui dit
    # « quelqu'un s'occupe de ce jardin ». Hors du massif et des
    # emplacements.
    x, y = 2.02, -0.52
    corps = revolve("Arrosoir", [(0.0, 0.0), (0.145, 0.0), (0.155, 0.03),
                                 (0.150, 0.24), (0.130, 0.29), (0.115, 0.30),
                                 (0.105, 0.28), (0.0, 0.28)], 36, [m["zinc"]], 30.0)
    corps.location = (x, y, 0.012)
    tube_along("Arrosoir_Bec", [(x + 0.10, y - 0.02, 0.12), (x + 0.36, y - 0.06, 0.30)],
               [0.035, 0.022], mat=m["zinc"], seg=12, cap=3)
    tube_along("Arrosoir_Anse", [(x - 0.09, y, 0.27), (x - 0.02, y, 0.42),
                                 (x + 0.08, y, 0.27)],
               [0.018, 0.018, 0.018], mat=m["zinc"], seg=12, cap=3)


def _decor(m):
    _allee(m)
    _pas_japonais(m)
    _bordure_fleurie(m)
    _arrosoir(m)


def _faisceau(force):
    if force <= 0.0:
        return
    # La meme tache que dans la piece : l'ouverture-equivalent de la haie,
    # projetee au sol le long de la direction du soleil — les emplacements
    # gardent exactement leur sens d'une scene a l'autre. Elle repose sur le
    # massif comme sur la pelouse : les deux sont quasiment au meme niveau.
    coins = []
    for (y, z) in ((FENETRE["y0"], FENETRE["z0"]), (FENETRE["y1"], FENETRE["z0"]),
                   (FENETRE["y1"], FENETRE["z1"]), (FENETRE["y0"], FENETRE["z1"])):
        t = z / -SOLEIL.z
        coins.append(Vector((-PIECE_X + SOLEIL.x * t, y + SOLEIL.y * t, 0.045)))
    maille("Faisceau", coins, [(0, 3, 2, 1)], materiau_faisceau("MAT_Faisceau", 0.26 * force))
    c = sum(coins, Vector()) / 4.0
    coeur = [c + (p - c) * 0.72 + Vector((0.0, 0.0, 0.004)) for p in coins]
    maille("Faisceau_Coeur", coeur, [(0, 3, 2, 1)], materiau_faisceau("MAT_Faisceau_Coeur", 0.44 * force))


def _lumieres(v, Rv, Uv, Cv):
    O = Vector((0.0, 0.0, 0.8))
    aire("LGT_Clef", O + 1.5 * Rv + 4.5 * Uv + 3.5 * Cv, O, 6.5, v["clef"], (1.0, 0.985, 0.960))
    # Le soleil : un grand panneau chaud au-dessus de la haie, qui verse vers
    # la pelouse a droite.
    chaud = (1.0, 0.985 - 0.06 * v["chaleur"], 0.96 - 0.16 * v["chaleur"])
    aire("LGT_Soleil", (-3.6, 0.3, 2.6), (0.9, 0.25, 0.0), 2.6, v["soleil"], chaud)
    aire("LGT_Appoint", O + 4.5 * Rv - 1.5 * Uv + 2.0 * Cv, O, 5.0, v["appoint"], (0.955, 0.975, 1.0))
    monde(v["monde"], couleur=(0.84, 0.88, 0.92))


def construire(nom_variante, Rv, Uv, Cv):
    """Le coin de jardin pour une variante de lumiere : pelouse, massif,
    palissade, haie basse et deux lointains, plus les lumieres. La camera
    est posee par l'appelant (common.camera_fixe)."""
    v = VARIANTES[nom_variante]
    m = _materiaux(v)
    _terrain(m)
    _massif(m)
    _palissade(m)
    _lointain(m)
    _haie(m)
    _pierres(m)
    _decor(m)
    _faisceau(v["faisceau"])
    _lumieres(v, Rv, Uv, Cv)
