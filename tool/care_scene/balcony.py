# ============================================================
# Le balcon du diorama : une maquette posee, comme la piece et le jardin —
# meme dalle, meme empreinte, du vide transparent tout autour.
#
# Un sol en lames de bois, la facade de l'immeuble au fond avec sa
# porte-fenetre, un garde-corps a gauche, une jardiniere accrochee dessus,
# un tabouret, un arrosoir et un paillasson. Assez pour lire « dehors, mais
# en pot, chez soi » — ce qui est exactement ce que dit la fiche quand elle
# envoie une plante ici : elle passe l'annee dehors sans tenir le gel, donc
# elle vit en pot et rentre l'hiver.
#
# Le garde-corps est a gauche (-x), la ou la piece a sa fenetre et le jardin
# sa haie : le jour vient du meme cote dans les trois scenes, et la table
# des emplacements vaut donc pour le balcon comme pour les deux autres. La
# plante s'approche du vide a mesure qu'elle demande de la lumiere.
#
# Rien n'est pose devant la plante : `common.verifie_couloir` le verifie a
# chaque rendu.
#
# Rien ne s'execute a l'import.
# ============================================================
import bpy
from mathutils import Vector
from math import cos, radians, sin
import os, sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from clay_scene import revolve, tube_along  # noqa: E402  — le chemin doit etre pose avant
from cutting.common import sphere  # noqa: E402  — primitives partagees des guides
from care_scene.common import (  # noqa: E402
    EPAIS_MUR, FENETRE, PIECE_X, PIECE_Y, PIECE_Z, SOLEIL,
    aire, boite, maille, materiau, materiau_faisceau, materiau_vitre, monde,
)

# Les six situations de lumiere. Un balcon est dehors : l'ambiante suit
# celle du jardin, pas celle de la piece.
VARIANTES = {
    "shade":           {"monde": 0.24, "clef": 480.0,  "soleil": 300.0,  "appoint": 130.0, "chaleur": 0.00, "faisceau": 0.00, "vitre": 0.50},
    "low_light":       {"monde": 0.35, "clef": 660.0,  "soleil": 480.0,  "appoint": 170.0, "chaleur": 0.05, "faisceau": 0.00, "vitre": 0.90},
    "indirect":        {"monde": 0.47, "clef": 920.0,  "soleil": 760.0,  "appoint": 230.0, "chaleur": 0.10, "faisceau": 0.00, "vitre": 1.40},
    "bright_indirect": {"monde": 0.57, "clef": 1120.0, "soleil": 900.0,  "appoint": 270.0, "chaleur": 0.30, "faisceau": 0.45, "vitre": 2.00},
    "some_sun":        {"monde": 0.63, "clef": 1240.0, "soleil": 1100.0, "appoint": 300.0, "chaleur": 0.55, "faisceau": 0.70, "vitre": 2.60},
    "full_sun":        {"monde": 0.70, "clef": 1380.0, "soleil": 1300.0, "appoint": 330.0, "chaleur": 0.85, "faisceau": 1.00, "vitre": 3.20},
}

# Le garde-corps, sur le bord gauche : sa ligne, sa hauteur, le pas des
# barreaux.
RAMBARDE_X = -PIECE_X + 0.06
RAMBARDE_H = 1.06
BARREAU_PAS = 0.22


def _materiaux(v):
    # Dehors mais chez soi : un bois de terrasse grisé, une façade plus
    # chaude que les murs du salon, un garde-corps sombre et mat. Rien de
    # saturé ne dispute l'œil à la plante.
    return {
        "lame": materiau("MAT_Lame", "C6B295", rough=0.82, relief=0.024),
        "lame_sombre": materiau("MAT_LameSombre", "B29B7C", rough=0.82, relief=0.024),
        "dalle": materiau("MAT_DalleBalcon", "B7A78E", rough=0.78, relief=0.018),
        "facade": materiau("MAT_Facade", "EFE6D6", rough=0.74, relief=0.016),
        "cadre": materiau("MAT_CadreBalcon", "FBF7EE", rough=0.55, relief=0.006),
        "metal": materiau("MAT_Rambarde", "5C6560", rough=0.44, relief=0.006),
        "bac": materiau("MAT_Bac", "C08464", rough=0.66, relief=0.014),
        "terre": materiau("MAT_TerreBac", "6B5A48", rough=0.84, relief=0.030),
        "feuillage": materiau("MAT_FeuillageBac", "8FA985", rough=0.70, relief=0.022),
        "zinc": materiau("MAT_ZincBalcon", "AFB6B4", rough=0.52, relief=0.008),
        "paillasson": materiau("MAT_Paillasson", "8E7A5E", rough=0.90, relief=0.038),
        "assise": materiau("MAT_Assise", "C4B091", rough=0.78, relief=0.016),
        "vitre": materiau_vitre(v["chaleur"], v["vitre"]),
    }


def _sol(m):
    # La dalle, puis des lames de terrasse dans le sens de la profondeur.
    # Une teinte sur deux, a peine differente : les lames se lisent sans
    # rayer le sol.
    boite("Dalle", (0.05, -0.075, -0.075), (4.8, 4.15, 0.15), m["dalle"], 0.05)
    largeur = 0.30
    n = int(4.7 / largeur)
    for i in range(n):
        x = 0.05 - 2.35 + largeur * (i + 0.5)
        mat = m["lame"] if i % 2 == 0 else m["lame_sombre"]
        boite("Lame_%02d" % i, (x, -0.075, -0.012),
              (largeur - 0.022, 4.06, 0.05), mat, 0.008)


def _facade(m):
    # Le mur de l'immeuble, au fond : meme place que le mur du fond de la
    # piece, pour que les deux scenes se superposent exactement.
    boite("Facade", (0.0, PIECE_Y + EPAIS_MUR / 2, PIECE_Z / 2),
          (2 * PIECE_X + 2 * EPAIS_MUR, EPAIS_MUR, PIECE_Z), m["facade"], 0.03)
    # Un bandeau de sol le long de la facade : le balcon est rapporte au
    # bati, il ne flotte pas.
    boite("Bandeau", (0.0, PIECE_Y - 0.06, 0.045),
          (2 * PIECE_X, 0.12, 0.09), m["cadre"], 0.008)


def _porte(m):
    # Une porte-fenetre a deux vantaux, sur la facade, du cote droit : elle
    # laisse tout le centre libre pour la plante. Sa vitre suit la variante,
    # comme celle de la piece.
    y = PIECE_Y - 0.03
    x0, lx = 1.05, 1.16
    z0, lz = 0.0, 2.12
    zc = z0 + lz / 2
    boite("Porte_Montant_G", (x0 - lx / 2, y, zc), (0.09, 0.09, lz), m["cadre"], 0.012)
    boite("Porte_Montant_D", (x0 + lx / 2, y, zc), (0.09, 0.09, lz), m["cadre"], 0.012)
    boite("Porte_Linteau", (x0, y, z0 + lz), (lx + 0.18, 0.09, 0.10), m["cadre"], 0.012)
    boite("Porte_Meneau", (x0, y, zc), (0.07, 0.08, lz), m["cadre"], 0.010)
    boite("Porte_Traverse", (x0, y, z0 + lz * 0.42), (lx, 0.07, 0.07), m["cadre"], 0.010)
    boite("Porte_Vitre", (x0, y + 0.035, zc), (lx - 0.06, 0.03, lz - 0.08), m["vitre"], 0.006)


def _fenetre_facade(m):
    # Une petite fenetre a gauche de la porte : la facade est large, et un
    # mur nu de deux metres soixante derriere la plante ne dit rien. Elle
    # reste haute, hors du chemin de la plante.
    y = PIECE_Y - 0.03
    x0, lx, lz, zc = -1.02, 0.78, 0.86, 1.62
    boite("Fen_Cadre_G", (x0 - lx / 2, y, zc), (0.08, 0.09, lz), m["cadre"], 0.010)
    boite("Fen_Cadre_D", (x0 + lx / 2, y, zc), (0.08, 0.09, lz), m["cadre"], 0.010)
    boite("Fen_Cadre_H", (x0, y, zc + lz / 2), (lx + 0.16, 0.09, 0.08), m["cadre"], 0.010)
    boite("Fen_Appui", (x0, y - 0.03, zc - lz / 2), (lx + 0.22, 0.14, 0.07), m["cadre"], 0.012)
    boite("Fen_Meneau", (x0, y, zc), (0.06, 0.08, lz), m["cadre"], 0.008)
    boite("Fen_Vitre", (x0, y + 0.035, zc), (lx - 0.05, 0.03, lz - 0.06), m["vitre"], 0.006)


def _rambarde(m):
    # Le garde-corps du bord gauche : une lisse haute, une lisse basse, des
    # barreaux verticaux, deux poteaux. Il s'arrete a la facade et laisse le
    # bord avant ouvert — comme la piece n'a pas de quatrieme mur, la
    # maquette se regarde par la.
    y0, y1 = -PIECE_Y, PIECE_Y - 0.06
    ym, ly = (y0 + y1) / 2, y1 - y0
    boite("Lisse_Haute", (RAMBARDE_X, ym, RAMBARDE_H),
          (0.10, ly, 0.07), m["metal"], 0.012)
    boite("Lisse_Basse", (RAMBARDE_X, ym, 0.12),
          (0.08, ly, 0.05), m["metal"], 0.010)
    n = int(ly / BARREAU_PAS)
    for i in range(n + 1):
        y = y0 + 0.06 + i * ((ly - 0.12) / max(n, 1))
        boite("Barreau_%02d" % i, (RAMBARDE_X, y, RAMBARDE_H / 2),
              (0.035, 0.035, RAMBARDE_H), m["metal"], 0.008)
    for j, y in enumerate((y0 + 0.05, y1 - 0.05)):
        boite("Poteau_%d" % j, (RAMBARDE_X, y, RAMBARDE_H / 2 + 0.03),
              (0.075, 0.075, RAMBARDE_H + 0.06), m["metal"], 0.010)
    # Un retour sur le bord avant, cote gauche seulement : il ferme l'angle
    # et dit que le balcon a un vide devant lui, sans jamais venir couper la
    # plante — qui vit bien plus a droite.
    x1r = RAMBARDE_X + 0.92
    xmr = (RAMBARDE_X + x1r) / 2
    boite("Retour_Haut", (xmr, y0, RAMBARDE_H), (x1r - RAMBARDE_X, 0.10, 0.07), m["metal"], 0.012)
    boite("Retour_Bas", (xmr, y0, 0.12), (x1r - RAMBARDE_X, 0.08, 0.05), m["metal"], 0.010)
    nr = int((x1r - RAMBARDE_X) / BARREAU_PAS)
    for i in range(1, nr + 1):
        x = RAMBARDE_X + i * ((x1r - RAMBARDE_X) / (nr + 1))
        boite("Retour_Barreau_%d" % i, (x, y0, RAMBARDE_H / 2),
              (0.035, 0.035, RAMBARDE_H), m["metal"], 0.008)
    boite("Retour_Poteau", (x1r, y0, RAMBARDE_H / 2 + 0.03),
          (0.075, 0.075, RAMBARDE_H + 0.06), m["metal"], 0.010)


def _jardiniere(m):
    # Accrochee a la rambarde, cote balcon : un bac, sa terre, et trois
    # touffes ecrasees. Elle dit « balcon » plus surement que tout le reste,
    # et reste assez basse pour ne jamais monter derriere la plante.
    x = RAMBARDE_X + 0.20
    y, ly = 0.55, 1.15
    boite("Jardiniere", (x, y, 0.80), (0.30, ly, 0.24), m["bac"], 0.02)
    boite("Jardiniere_Terre", (x, y, 0.915), (0.25, ly - 0.06, 0.03), m["terre"], 0.01)
    for i, dy in enumerate((-0.38, 0.0, 0.38)):
        sphere("Touffe_%d" % i, (x + 0.01 * i, y + dy, 0.96), 0.16,
               m["feuillage"], seg=22, echelle=(0.92, 1.0, 0.64))
    # Deux crochets qui la tiennent : sans eux elle flotte contre le vide.
    for j, dy in enumerate((-0.42, 0.42)):
        boite("Crochet_%d" % j, (RAMBARDE_X + 0.10, y + dy, 0.97),
              (0.22, 0.04, 0.05), m["metal"], 0.008)


def _tabouret(m):
    # Un tabouret bas contre la facade, a gauche de la porte : on s'assoit
    # sur un balcon. Il reste au fond, loin du chemin de la plante.
    x, y = -1.30, 1.42
    boite("Tabouret_Assise", (x, y, 0.42), (0.42, 0.38, 0.05), m["assise"], 0.012)
    for i, (dx, dy) in enumerate(((-0.16, -0.14), (0.16, -0.14), (-0.16, 0.14), (0.16, 0.14))):
        boite("Tabouret_Pied_%d" % i, (x + dx, y + dy, 0.20),
              (0.045, 0.045, 0.40), m["metal"], 0.008)


def _paillasson(m):
    # Devant la porte : plat, il ne peut rien croiser.
    boite("Paillasson", (1.05, 1.36, 0.016), (0.78, 0.46, 0.028), m["paillasson"], 0.012)


def _arrosoir(m):
    # Le meme objet que dans le jardin, pose contre la facade : c'est la
    # main qui s'occupe de la plante, dans les deux scenes.
    x, y = 0.20, 1.50
    corps = revolve("Arrosoir", [(0.0, 0.0), (0.135, 0.0), (0.145, 0.03),
                                 (0.140, 0.23), (0.122, 0.28), (0.108, 0.29),
                                 (0.098, 0.27), (0.0, 0.27)], 36, [m["zinc"]], 30.0)
    corps.location = (x, y, 0.012)
    tube_along("Arrosoir_Bec", [(x + 0.09, y - 0.02, 0.11), (x + 0.33, y - 0.06, 0.28)],
               [0.032, 0.020], mat=m["zinc"], seg=12, cap=3)
    tube_along("Arrosoir_Anse", [(x - 0.08, y, 0.26), (x - 0.01, y, 0.40),
                                 (x + 0.07, y, 0.26)],
               [0.017, 0.017, 0.017], mat=m["zinc"], seg=12, cap=3)


def _faisceau(force):
    if force <= 0.0:
        return
    # La meme tache que dans les deux autres scenes : l'ouverture projetee
    # au sol le long de la direction du soleil. Les emplacements gardent
    # exactement leur sens d'un decor a l'autre.
    coins = []
    for (y, z) in ((FENETRE["y0"], FENETRE["z0"]), (FENETRE["y1"], FENETRE["z0"]),
                   (FENETRE["y1"], FENETRE["z1"]), (FENETRE["y0"], FENETRE["z1"])):
        t = z / -SOLEIL.z
        coins.append(Vector((-PIECE_X + SOLEIL.x * t, y + SOLEIL.y * t, 0.030)))
    maille("Faisceau", coins, [(0, 3, 2, 1)], materiau_faisceau("MAT_Faisceau", 0.26 * force))
    c = sum(coins, Vector()) / 4.0
    coeur = [c + (p - c) * 0.72 + Vector((0.0, 0.0, 0.004)) for p in coins]
    maille("Faisceau_Coeur", coeur, [(0, 3, 2, 1)], materiau_faisceau("MAT_Faisceau_Coeur", 0.44 * force))


def _lumieres(v, Rv, Uv, Cv):
    O = Vector((0.0, 0.0, 0.8))
    aire("LGT_Clef", O + 1.5 * Rv + 4.5 * Uv + 3.5 * Cv, O, 6.5, v["clef"], (1.0, 0.985, 0.960))
    # Le soleil : un panneau chaud au-dessus du garde-corps, qui verse vers
    # le fond du balcon — meme direction que la fenetre de la piece.
    chaud = (1.0, 0.985 - 0.06 * v["chaleur"], 0.96 - 0.16 * v["chaleur"])
    aire("LGT_Soleil", (-3.6, 0.3, 2.6), (0.9, 0.25, 0.0), 2.6, v["soleil"], chaud)
    aire("LGT_Appoint", O + 4.5 * Rv - 1.5 * Uv + 2.0 * Cv, O, 5.0, v["appoint"], (0.955, 0.975, 1.0))
    monde(v["monde"], couleur=(0.84, 0.88, 0.92))


def construire(nom_variante, Rv, Uv, Cv):
    """Le balcon pour une variante de lumiere. La camera est posee par
    l'appelant (common.camera_fixe). Renvoie le mobilier, seul objet que la
    verification du couloir regarde."""
    v = VARIANTES[nom_variante]
    m = _materiaux(v)
    _sol(m)
    _facade(m)
    _porte(m)
    _fenetre_facade(m)
    _rambarde(m)
    avant = set(bpy.context.scene.objects.keys())
    _jardiniere(m)
    _tabouret(m)
    _paillasson(m)
    _arrosoir(m)
    mobilier = [bpy.context.scene.objects[n]
                for n in set(bpy.context.scene.objects.keys()) - avant]
    _faisceau(v["faisceau"])
    _lumieres(v, Rv, Uv, Cv)
    return mobilier
