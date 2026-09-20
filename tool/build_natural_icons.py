#!/usr/bin/env python3
"""Une illustration d'argile par phenomene naturel.

assets/problems/natural.txt compte trente-deux entrees ; chacune a son dessin,
comme les problemes ont le leur (assets/problems/icons/). Meme studio, memes
materiaux et meme langage que les cinq symboles de familles
(tool/build_category_logos.py), dont ce script emprunte la feuille, les boules,
les tubes et les gouttes : une composition posee dans le plan de la camera,
deux a cinq elements, aucun texte — l'image doit valoir dans les quatre
langues, a cinquante-deux points.

Ce que chaque dessin doit dire n'est pas « voila une fougere » mais « il n'y a
rien a soigner ». D'ou les partis pris : la goutte claire plutot que le bleu de
l'eau, la laine des areoles montree avec ses epines pour qu'on ne la prenne pas
pour une cochenille, les nodosites accrochees a leur racine.

Rend des PNG 1024 RGBA sans ombre au sol : l'ombre est dessinee par
l'application. tool/pack_natural_icons.py les reduit ensuite en WebP 512.

Execution :
  blender -b -noaudio -t 4 -P tool/build_natural_icons.py -- --output build/natural_icons
  blender -b -noaudio -t 4 -P tool/build_natural_icons.py -- --seulement N19 N23
"""
import argparse
import math
import sys
from pathlib import Path

import bpy

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_category_logos as fam
from build_category_logos import Leaf, ball, drop, mesh, tube, world, R, C, U
from clay_scene import grain, make_leaf, purge, rendu_transparent, studio

M = {}


# ------------------------------------------------------------
# la matiere : la palette des familles, et ce que les phenomenes ajoutent
# ------------------------------------------------------------
def palette():
    global M
    fam.palette()
    M = fam.M
    M.update({
        'terre': fam.material('Terreau_4A3A2C', '4A3A2C', .82, .013),
        'terre_claire': fam.material('Terreau_clair_6B5540', '6B5540', .80, .012),
        'ecorce': fam.material('Ecorce_9A7A5C', '9A7A5C', .78, .013),
        'ecorce_claire': fam.material('Ecorce_claire_C6A883', 'C6A883', .74, .011),
        'ecorce_sombre': fam.material('Ecorce_sombre_6E5540', '6E5540', .80, .013),
        'laine': fam.material('Laine_F1ECE0', 'F1ECE0', .86, .016),
        'lichen': fam.material('Lichen_A9BCA2', 'A9BCA2', .84, .015),
        'lichen_clair': fam.material('Lichen_clair_C7D6BE', 'C7D6BE', .82, .014),
        'or': fam.material('Chapeau_E0B84C', 'E0B84C', .58),
        'or_clair': fam.material('Chapeau_clair_EBD183', 'EBD183', .56),
        'rose': fam.material('Nodosite_CE8F86', 'CE8F86', .60),
        'rose_clair': fam.material('Nodosite_claire_E2B2A8', 'E2B2A8', .58),
        'jeune': fam.material('Jeune_feuille_C4705C', 'C4705C', .62),
        'jeune_clair': fam.material('Jeune_feuille_claire_D79A83', 'D79A83', .60),
        'pale': fam.material('Feuille_pale_CBE0BE', 'CBE0BE', .62),
        # La feuille grasse est bleu-vert cendre, et la pruine ne l'eclaircit
        # que d'un cran : une feuille presque blanche ne se lirait plus comme
        # une plante.
        'grasse': fam.material('Feuille_grasse_7FA98B', '7FA98B', .82, .015),
        'pruine': fam.material('Pruine_B9CFBE', 'B9CFBE', .88, .016),
        'fruit': fam.material('Fruit_86A85C', '86A85C', .56),
        'caillou': fam.material('Caillou_A9B49B', 'A9B49B', .74, .012),
        'caillou_clair': fam.material('Caillou_clair_C4CDB6', 'C4CDB6', .72, .011),
        'racine': fam.material('Racine_E4D9C4', 'E4D9C4', .74, .012),
    })


# ------------------------------------------------------------
# les pieces : ce que les scenes assemblent
# ------------------------------------------------------------
def feuille(x=0, z=0, scale=1, lean=30, mat=None, vein=None, stem=None, veins=True):
    """La feuille des symboles de familles, dans la couleur qu'on veut."""
    lame = Leaf(x, z, scale, lean, mat=mat, vein=vein, stem=stem, veins=veins)
    lame.build()
    return lame


def plaque(name, points, mat, depth=0., epaisseur=.22, lisse=2):
    """Une galette d'argile taillee dans un contour ferme du plan.

    De quoi faire un pot, un tronc, un petale ou un chapeau sans modeler :
    le contour donne la silhouette, la subdivision arrondit le reste.
    """
    n = len(points)
    verts = [world(x, depth + s * epaisseur / 2, z) for s in (1, -1) for (x, z) in points]
    faces = [tuple(range(n)), tuple(range(2 * n - 1, n - 1, -1))]
    faces += [(i, (i + 1) % n, n + (i + 1) % n, n + i) for i in range(n)]
    ob = mesh(name, verts, faces, mat)
    sub = ob.modifiers.new('Argile_arrondie', 'SUBSURF')
    sub.levels = lisse
    return ob


def pot(x=0, z=-.62, largeur=1.02, hauteur=.62, terre=True):
    """Un pot de terre cuite vu de face, sa levre et sa terre. Rend la hauteur
    a laquelle les tiges sortent."""
    haut, bas = largeur / 2, largeur / 2 * .74

    def flanc(t):
        """Le galbe du pot, du pied (t=0) a la levre (t=1). Les points
        intermediaires le tiennent : sans eux, la subdivision ramene le tronc
        conique a un bol."""
        return bas + (haut - bas) * t, z + .09 + (hauteur - .09) * t

    droite = [flanc(t) for t in (.22, .52, .80)]
    contour = ([(x - haut, z + hauteur), (x + haut, z + hauteur)]
               + [(x + r, h) for (r, h) in reversed(droite)]
               + [(x + bas * .94, z + .04), (x + bas * .78, z), (x - bas * .78, z), (x - bas * .94, z + .04)]
               + [(x - r, h) for (r, h) in droite])
    plaque('Pot', contour, M['terra'], epaisseur=.42, lisse=1)
    ball('Levre_du_pot', (x, .14, z + hauteur), (haut * 1.10, .25, .085), M['terra_light'])
    if terre:
        ball('Terre_du_pot', (x, .10, z + hauteur - .04), (haut * .86, .20, .055), M['terre'])
    return z + hauteur - .02


def trace(name, points, rayon, mat, depth=.0):
    """Un tube trace dans le plan : les scenes donnent (x, z), la profondeur
    est la meme d'un bout a l'autre."""
    return tube(name, [(x, depth, z) for (x, z) in points], rayon, mat)


def tige(points, rayon, mat=None, name='Tige', depth=.0):
    return trace(name, points, rayon, mat or M['sage_dark'], depth)


def perle(name, x, z, r, mat, depth=.30, aplati=.70):
    return ball(name, (x, depth, z), (r, r * aplati, r), mat)


def grappe(name, centres, r, mat, depth=.34):
    """Un amas de petites boules : de la laine, une moisissure, une mousse."""
    for i, (x, z, k) in enumerate(centres):
        perle(f'{name}_{i}', x, z, r * k, mat, depth=depth, aplati=.62)


# ------------------------------------------------------------
# les trente-deux scenes
# ------------------------------------------------------------
def n01():
    """Nectar extrafloral : le petiole et ses perles, une goutte qui tombe."""
    petiole = [(-.78, -.86), (-.50, -.42), (-.22, .02), (.06, .46), (.30, .86)]
    tige(petiole, [.115, .108, .100, .092, .080], M['sage_dark'], 'Petiole')
    feuille(.42, .64, .52, 22)
    for i, (x, z) in enumerate(((-.58, -.60), (-.34, -.22), (-.10, .18))):
        perle(f'Nectaire_{i}', x + .10, z + .05, .105, M['dew'], depth=.42, aplati=.82)
    drop('Goutte_qui_tombe', -.02, -.52, .155, .46, M['dew'], depth=.46, angle=8)


def n02():
    """Guttation : la rosee au bord du limbe, au petit matin."""
    lame = feuille(-.10, -.06, .96, 30)
    for i, t in enumerate((.42, .58, .74, .88)):
        x, d, z = lame.coords(t, 1.0, 0)
        drop(f'Goutte_de_marge_{i}', x + .04, z - .12, .095, .28, M['dew'], depth=d + .24, angle=6)
    x, d, z = lame.coords(.995, 0, 0)
    drop('Goutte_de_pointe', x + .10, z - .30, .135, .40, M['dew'], depth=d + .26, angle=4)
    perle('Goutte_tombee', x + .22, z - .88, .085, M['dew'], depth=d + .26, aplati=.80)


def n03():
    """Vieillissement des feuilles basses : la vieille s'en va, la jeune reste."""
    tige([(-.06, -.92), (-.02, -.40), (.02, .18), (.06, .74)], [.085, .078, .070, .058])
    feuille(.30, .52, .64, 34)
    feuille(-.42, .14, .58, -38)
    feuille(-.52, -.74, .56, 104, mat=M['ochre'], vein=M['ochre_light'], stem=M['ochre'])


def n04():
    """Panachure naturelle : la creme dessinee dans le limbe, pas posee dessus."""
    lame = feuille(-.08, -.04, 1.0, 30)
    # Des secteurs allonges dans l'axe du limbe : une panachure suit les
    # nervures. En billes rondes, elle passerait pour des oeufs de cochenille.
    for i, (t, f, long, large) in enumerate(((.34, -.44, .30, .13), (.44, .34, .34, .15),
                                             (.58, -.30, .30, .12), (.66, .40, .24, .10),
                                             (.76, -.20, .22, .09))):
        x, d, z = lame.coords(t, f, .020)
        ball(f'Panachure_{i}', (x, d, z), (large, .022, long), M['cream'], angle=30)


def n05():
    """Fenestration : les fentes et les trous de la feuille adulte."""
    make_leaf('Feuille_fenetree', world(-.06, 0, -1.02), R, U, C,
              L=2.00, n_fentes=5, n_trous=3, mat=M['sage'], ep=.055, w_ratio=.50)
    tige([(-.06, -1.34), (-.06, -1.10), (-.05, -.96)], .060)


def n06():
    """Racines aeriennes : le noeud en donne, elles cherchent l'air."""
    tige([(-.30, -1.00), (-.22, -.46), (-.14, .10), (-.06, .66), (.00, 1.02)],
         [.120, .112, .104, .094, .082])
    feuille(.46, .72, .50, 24)
    ball('Noeud', (-.16, .10, -.14), (.165, .135, .120), M['sage_light'])
    for i, (depart, fin) in enumerate((((-.26, -.22), (.46, -1.04)), ((-.16, .24), (.66, -.40)))):
        x0, z0 = depart
        x1, z1 = fin
        pts = [(x0, z0), (x0 + (x1 - x0) * .34, z0 - .14), (x0 + (x1 - x0) * .70, z1 + .30), (x1, z1)]
        trace(f'Racine_aerienne_{i}', pts, [.115, .102, .086, .062], M['racine'], depth=.20)
        perle(f'Coiffe_{i}', x1, z1, .072, M['ochre_light'], depth=.26)


def n07():
    """Cataphylle : la gaine seche qui a protege la feuille et se detache."""
    tige([(-.10, -.96), (-.06, -.44), (-.02, .12), (.02, .62)], [.115, .108, .098, .086])
    feuille(.40, .74, .52, 20)
    # La gaine enveloppe la tige, seche, et s'ouvre en pointe : c'est ce
    # cornet-la qu'on prend pour une feuille morte.
    contour = [(-.40, -.74), (.26, -.64), (.34, -.04), (.20, .52), (.02, .92),
               (-.14, .46), (-.30, -.10)]
    plaque('Cataphylle', contour, M['ochre_light'], depth=.46, epaisseur=.26, lisse=1)
    # La fente par laquelle la feuille est sortie, et le bord qui s'ecarte.
    trace('Fente_de_la_gaine', [(-.04, -.58), (.02, .04), (.04, .62), (.02, .88)],
          [.030, .036, .030, .018], M['ochre'], depth=.62)
    trace('Bord_de_la_gaine', [(-.38, -.70), (-.26, -.06), (-.10, .52), (.00, .90)],
          [.046, .052, .042, .024], M['cream'], depth=.58)
    # Celle de l'an dernier, tombee au pied, en papier brun.
    plaque('Cataphylle_tombee', [(-.86, -.92), (-.42, -.78), (-.34, -1.00), (-.78, -1.10)],
           M['ochre'], depth=.36, epaisseur=.10)


def n08():
    """Feuille jeune : pale ou rougie, elle verdira."""
    tige([(-.02, -.98), (.00, -.46), (.02, .06), (.02, .52)], [.085, .078, .070, .058])
    feuille(-.46, -.16, .68, -34)
    feuille(.44, -.10, .64, 36)
    feuille(.06, .74, .46, 8, mat=M['jeune'], vein=M['jeune_clair'], stem=M['jeune_clair'])


def n09():
    """Latex a la coupe : la seve monte a la section, blanche et epaisse."""
    tige([(-.82, -.94), (-.52, -.48), (-.22, .00), (.06, .44)], [.155, .148, .140, .132], M['sage_dark'], 'Tige_coupee')
    ball('Section', (.06, .12, .44), (.145, .115, .105), M['sage_light'])
    drop('Goutte_de_latex', .16, .00, .150, .44, M['cream'], depth=.46, angle=10)
    perle('Perle_de_latex', .34, .58, .070, M['cream'], depth=.40, aplati=.86)
    feuille(-.46, .52, .48, -26)


def n10():
    """Pruine : la cire mate des feuilles grasses, et la trace du doigt."""
    # La cire couvre la feuille entiere : ce n'est pas une tache posee
    # dessus, c'est la couleur de la plante. Ce qui se voit, c'est la ou elle
    # manque.
    trace('Pied', [(.00, -.96), (.00, -.74)], [.10, .13], M['sage_dark'])
    ball('Feuille_du_fond', (-.48, .04, -.24), (.28, .24, .60), M['grasse'], angle=-26)
    ball('Feuille_du_fond_2', (.50, .04, -.28), (.27, .22, .56), M['grasse'], angle=24)
    ball('Feuille_grasse', (.00, .26, .10), (.38, .32, .80), M['grasse'], angle=4)
    # Deux doigts ont passe : dessous, le vert vrai, franc et luisant.
    ball('Trace_de_doigt', (.13, .54, .26), (.115, .06, .42), M['sage'], angle=12)
    ball('Trace_de_doigt_2', (-.12, .54, .04), (.095, .06, .34), M['sage'], angle=-8)


def n11():
    """Chute des fleurs fanees : la fleur a fini, la suivante ouvre."""
    tige([(-.16, -.98), (-.08, -.46), (.00, .06), (.06, .50)], [.085, .078, .070, .060])
    for i in range(6):
        a = math.radians(60 * i + 12)
        perle(f'Petale_{i}', .06 + .26 * math.cos(a), .68 + .26 * math.sin(a), .155, M['rose_clair'], depth=.28, aplati=.52)
    perle('Coeur_de_la_fleur', .06, .68, .105, M['or'], depth=.40, aplati=.80)
    for i, (x, z, a) in enumerate(((-.52, -.34, 26), (-.30, -.78, -14))):
        ball(f'Petale_tombe_{i}', (x, .30, z), (.175, .055, .105), M['ochre_light'], angle=a)


def n12():
    """Repos hivernal : la souche dort, le bourgeon attend."""
    sol = pot()
    for i, (x, haut, pente) in enumerate(((-.22, .58, -.26), (.14, .74, .18), (.34, .40, .30))):
        trace(f'Rameau_{i}', [(x, sol - .02), (x + pente * .35, sol + haut * .45), (x + pente, sol + haut)],
             [.075, .062, .046], M['ecorce_sombre'])
        perle(f'Bourgeon_{i}', x + pente, sol + haut + .03, .075, M['sage_dark'], depth=.34, aplati=.86)


def n13():
    """Poils et ecailles : le duvet du limbe, qui n'est pas une moisissure."""
    lame = feuille(-.06, -.04, .94, 28, mat=M['sage_light'], vein=M['sage'], stem=M['sage_dark'])
    for side in (-1, 1):
        for i, t in enumerate((.18, .30, .42, .54, .66, .78, .88)):
            x0, d0, z0 = lame.coords(t, side * .97, .01)
            x1, d1, z1 = lame.coords(t + .02 * side, side * 1.22, .01)
            trace(f'Poil_{side}_{i}', [(x0, z0), ((x0 + x1) / 2, (z0 + z1) / 2), (x1, z1)],
                 [.030, .022, .012], M['cream'])
    for i, (t, f) in enumerate(((.34, -.30), (.52, .26), (.70, -.16))):
        x, d, z = lame.coords(t, f, .016)
        ball(f'Duvet_{i}', (x, d, z), (.085, .020, .070), M['cream'])


def n14():
    """Traces de calcaire : ce que l'eau laisse en s'evaporant."""
    lame = feuille(-.06, -.04, .96, 30)
    for i, (t, f, r) in enumerate(((.34, -.34, .085), (.44, .22, .065), (.58, -.12, .075),
                                   (.66, .38, .055), (.78, -.26, .060), (.86, .10, .045))):
        x, d, z = lame.coords(t, f, .018)
        ball(f'Depot_{i}', (x, d, z), (r, .016, r * .82), M['cream'])
    x, d, z = lame.coords(.52, -.52, .020)
    for i in range(14):
        a = 2 * math.pi * i / 14
        ball(f'Aureole_{i}', (x + .20 * math.cos(a), d, z + .17 * math.sin(a)), (.030, .012, .026), M['cream'])


def n15():
    """Apres la floraison, le bulbe reprend son feuillage : il jaunit pour lui."""
    ball('Bulbe', (-.02, .12, -.78), (.30, .26, .24), M['ochre_light'])
    trace('Collet', [(-.02, -.94), (-.02, -.80)], [.10, .16], M['cream'])
    for i, (x, haut, pente, mat) in enumerate(((-.46, 1.28, -.30, M['ochre']), (-.10, 1.44, -.06, M['sage']),
                                               (.30, 1.20, .26, M['ochre']))):
        trace(f'Feuille_rubanee_{i}', [(-.02, -.66), (x * .5, -.66 + haut * .42), (x, -.66 + haut)],
             [.115, .095, .045], mat)
    trace('Hampe', [(.02, -.62), (.26, -.06), (.44, .40)], [.075, .068, .058], M['sage_dark'])
    for i in range(5):
        a = math.radians(72 * i + 20)
        perle(f'Fleur_fanee_{i}', .46 + .14 * math.cos(a), .52 + .13 * math.sin(a), .105, M['ochre_light'], depth=.30, aplati=.52)


def n16():
    """Chute des feuilles en automne : le rameau se depouille."""
    trace('Rameau', [(-1.00, .52), (-.40, .60), (.24, .56), (.86, .40)],
         [.090, .082, .072, .056], M['ecorce'])
    feuille(-.54, .84, .50, -26, mat=M['ochre'], vein=M['ochre_light'], stem=M['ecorce'])
    feuille(.22, .86, .46, 14, mat=M['terra_light'], vein=M['ochre_light'], stem=M['ecorce'])
    feuille(-.10, -.26, .48, 118, mat=M['ochre'], vein=M['ochre_light'], stem=M['ecorce'])
    feuille(.56, -.84, .44, 62, mat=M['terra'], vein=M['terra_light'], stem=M['ecorce'])


def n17():
    """Mue des plantes-cailloux : les nouvelles feuilles sortent des anciennes."""
    for i, (x, z, r) in enumerate(((-.46, -.22, .52), (.48, -.34, .44))):
        for side in (-1, 1):
            mat = M['caillou'] if side < 0 else M['caillou_clair']
            ball(f'Corps_{i}_{side}', (x + side * r * .46, .16, z), (r * .52, r * .46, r * .86), mat)
        # La fente d'ou sort la nouvelle paire, et la paire elle-meme.
        ball(f'Fente_{i}', (x, .30, z + r * .30), (.020, .040, r * .52), M['ecorce_sombre'])
        for side in (-1, 1):
            ball(f'Feuille_neuve_{i}_{side}', (x + side * .07, .34, z + r * .74),
                 (.10, .09, r * .34), M['sage'], angle=side * 12)
    # La vieille peau, papier seche, ecartee au pied.
    plaque('Ancienne_peau', [(-1.00, -.74), (-.70, -.52), (-.64, -.90), (-.92, -1.02)],
           M['cream'], depth=.34, epaisseur=.09)


def n18():
    """Cotyledons : les deux premieres feuilles se retirent, le semis continue."""
    tige([(.00, -.96), (.00, -.40), (.02, .16), (.02, .62)], [.070, .064, .058, .048])
    for side in (-1, 1):
        ball(f'Cotyledon_{side}', (side * .34, .24, -.30), (.24, .14, .17), M['ochre_light'], angle=side * 14)
    feuille(-.32, .56, .44, -30)
    feuille(.36, .58, .44, 30)


def n19():
    """Sores des fougeres : les points bruns sont des spores, pas des cochenilles."""
    rachis = [(-.86, -.86), (-.52, -.40), (-.18, .10), (.16, .58), (.44, .96)]
    tige(rachis, [.070, .064, .058, .050, .038], M['sage_dark'], 'Rachis')
    for i, t in enumerate((.10, .30, .50, .70, .88)):
        bx = -.86 + (.44 + .86) * t
        bz = -.86 + (.96 + .86) * t
        for side in (-1, 1):
            taille = .40 - .05 * i
            lame = feuille(bx + side * taille * .58, bz + taille * .30, taille, side * 62)
            for j, (u, f) in enumerate(((.42, -.34), (.56, .30), (.72, -.22))):
                x, d, z = lame.coords(u, f, .018)
                ball(f'Sore_{i}_{side}_{j}', (x, d, z), (.055, .022, .050), M['terra_deep'])


def n20():
    """Moisissure blanche du terreau : elle mange le terreau, pas la plante."""
    sol = pot()
    grappe('Moisissure', [(-.34, sol + .04, 1.0), (-.18, sol + .10, .82), (-.02, sol + .03, .96),
                          (.14, sol + .09, .74), (.30, sol + .02, .88), (-.24, sol - .03, .68),
                          (.06, sol - .04, .72), (.22, sol - .05, .60)], .130, M['laine'], depth=.36)
    tige([(.16, sol - .02), (.22, sol + .40), (.26, sol + .74)], [.070, .062, .050])
    feuille(.50, sol + .92, .44, 26)


def n21():
    """Champignon du terreau : un saprophyte, qui vit du terreau."""
    sol = pot()
    trace('Pied', [(-.20, sol - .02), (-.18, sol + .26), (-.16, sol + .46)], [.085, .076, .070], M['or_clair'])
    ball('Chapeau', (-.16, .26, sol + .58), (.30, .23, .22), M['or'])
    ball('Petit_chapeau', (.20, .20, sol + .22), (.17, .13, .13), M['or'])
    trace('Petit_pied', [(.20, sol - .01), (.20, sol + .14)], [.050, .044], M['or_clair'])
    tige([(.34, sol - .02), (.42, sol + .42), (.48, sol + .78)], [.070, .062, .050])
    feuille(.72, sol + .94, .42, 26)


def n22():
    """Liegeage : la base se lignifie, seche et dure — ce n'est pas la pourriture."""
    contour = [(-.40, -1.00), (.40, -1.00), (.44, -.10), (.42, .56), (.26, .96),
               (-.26, .96), (-.42, .56), (-.44, -.10)]
    plaque('Cactus', contour, M['sage'], epaisseur=.56)
    # Les cotes d'abord : c'est a elles qu'on reconnait un cactus.
    for i, x in enumerate((-.26, .00, .26)):
        trace(f'Cote_{i}', [(x * 1.06, -.86), (x, .10), (x * .74, .90)], [.040, .036, .026],
              M['sage_light'], depth=.32)
        for j, z in enumerate((-.52, -.16, .22, .58)):
            perle(f'Areole_{i}_{j}', x * (1 - .16 * j / 3), z, .034, M['laine'], depth=.36, aplati=.80)
    # Le liege monte du pied, sec et dur : ni mou, ni sombre, ni humide.
    liege = [(-.42, -1.02), (.42, -1.02), (.46, -.52), (.22, -.34), (-.16, -.42), (-.46, -.32)]
    plaque('Liege', liege, M['ecorce'], depth=.34, epaisseur=.34, lisse=1)
    trace('Bord_du_liege', [(-.44, -.34), (-.14, -.44), (.22, -.36), (.46, -.54)],
          [.030, .034, .034, .028], M['ecorce_sombre'], depth=.50)


def n23():
    """Laine des areoles : la touffe porte les epines — une cochenille, non."""
    contour = [(-.52, -.92), (.52, -.92), (.58, -.10), (.44, .62), (.00, .94),
               (-.44, .62), (-.58, -.10)]
    plaque('Cactus', contour, M['sage'], epaisseur=.60)
    for i, x in enumerate((-.30, .02, .34)):
        trace(f'Cote_{i}', [(x * 1.10, -.82), (x, .00), (x * .80, .78)], [.034, .030, .024],
              M['sage_light'], depth=.30)
    for i, (x, z) in enumerate(((-.32, .44), (.02, .58), (.34, .38), (-.34, -.06), (.02, .08),
                                (.36, -.12), (-.30, -.54), (.04, -.44), (.34, -.62))):
        # L'epine d'abord, la laine par-dessus : c'est elle qui tient la
        # touffe, et c'est elle qui separe une areole d'une cochenille.
        for j, a in enumerate((28, 90, 152, 214, 326)):
            ar = math.radians(a)
            trace(f'Epine_{i}_{j}', [(x, z), (x + .21 * math.cos(ar), z + .21 * math.sin(ar))],
                  [.020, .006], M['ochre'], depth=.42)
        perle(f'Areole_{i}', x, z, .072, M['laine'], depth=.46, aplati=.80)


def n24():
    """Nyctinastie : la feuille se replie la nuit, et rouvre au matin."""
    # A gauche le jour : la feuille est a plat. A droite la nuit : les deux
    # moities se sont relevees l'une contre l'autre, en V.
    feuille(-.66, -.14, .78, 78)
    trace('Petiole_du_jour', [(-1.00, -.86), (-.86, -.56), (-.74, -.34)], [.070, .062, .054], M['sage_dark'])
    for side in (-1, 1):
        lame = Leaf(.66 + side * .13, -.04, .62, side * 22, mat=M['sage'],
                    vein=M['sage_light'], stem=M['sage_dark'], veins=False)
        lame.build()
    trace('Petiole_de_la_nuit', [(.58, -.92), (.64, -.62), (.68, -.40)], [.070, .062, .054], M['sage_dark'])
    perle('Pulvinus', .68, -.34, .075, M['sage_light'], depth=.34, aplati=.86)


def n25():
    """Lichens et mousses : poses sur l'ecorce, ils ne prennent rien a l'arbre."""
    trace('Branche', [(-1.04, -.52), (-.40, -.24), (.28, .02), (.96, .40)],
         [.180, .190, .175, .150], M['ecorce'])
    for i, (x, z, r, mat) in enumerate(((-.62, -.10, .21, M['lichen']), (-.20, .10, .17, M['lichen_clair']),
                                        (.24, .22, .23, M['lichen']), (.62, .40, .16, M['lichen_clair']),
                                        (-.84, -.34, .14, M['lichen_clair']))):
        for j, a in enumerate((0, 72, 144, 216, 288)):
            ar = math.radians(a)
            ball(f'Lichen_{i}_{j}', (x + r * .52 * math.cos(ar), .26, z + r * .40 * math.sin(ar)),
                 (r * .62, .045, r * .50), mat)
    trace('Rameau', [(.30, .04), (.52, .46), (.66, .80)], [.070, .060, .048], M['ecorce_sombre'])
    feuille(.90, .96, .40, 22)


def n26():
    """Racines adventives : la tige en prepare, elles n'attendent que la terre."""
    trace('Tige', [(-.28, -1.00), (-.14, -.40), (.00, .22), (.12, .82)],
         [.175, .168, .158, .140], M['sage'])
    for i, (t, side) in enumerate(((.18, 1), (.34, -1), (.50, 1), (.62, -1), (.78, 1))):
        x = -.28 + .40 * t
        z = -1.00 + 1.82 * t
        perle(f'Racine_naissante_{i}', x + side * .14, z, .075, M['cream'], depth=.40, aplati=.80)
        trace(f'Poil_racinaire_{i}', [(x + side * .16, z), (x + side * .30, z - .10)],
             [.026, .010], M['cream'])
    feuille(.36, .96, .44, 26)


def n27():
    """Nodosites : les bacteries donnent l'azote, ce ne sont pas des galles."""
    # La motte sortie du pot : le collet en haut, la racine qui descend.
    trace('Tige_aerienne', [(-.14, 1.12), (-.12, .96)], [.085, .095], M['sage_dark'])
    trace('Racine_principale', [(-.12, .92), (-.06, .30), (.00, -.32), (.04, -1.00)],
          [.130, .115, .095, .060], M['racine'])
    for i, (z0, x1, z1) in enumerate(((.44, -.66, -.06), (-.20, .62, -.62), (.06, .58, .28))):
        x0 = -.10 + .14 * (1 - (z0 + 1) / 2)
        trace(f'Radicelle_{i}', [(x0, z0), ((x0 + x1) / 2, (z0 + z1) / 2 - .12), (x1, z1)],
              [.075, .058, .034], M['racine'])
    # Les nodosites tiennent a la racine, la ou les bacteries se sont
    # installees : une galle, elle, fait corps avec elle et la deforme.
    for i, (x, z, r) in enumerate(((-.30, .26, .135), (-.58, -.02, .110), (.26, -.44, .130),
                                   (.52, -.58, .100), (.30, .18, .115), (.02, -.72, .095),
                                   (-.08, .62, .090))):
        perle(f'Nodosite_{i}', x, z, r, M['rose'], depth=.40, aplati=.88)
        perle(f'Attache_{i}', x * .82, z + .02, r * .52, M['rose_clair'], depth=.30, aplati=.70)


def n28():
    """Chute physiologique : l'arbre garde ce qu'il peut nourrir."""
    trace('Rameau', [(-1.00, .58), (-.36, .66), (.30, .60), (.92, .44)],
         [.090, .082, .072, .058], M['ecorce'])
    feuille(-.72, .92, .40, -30)
    feuille(.66, .88, .38, 24)
    for i, (x, z, r) in enumerate(((-.42, .32, .175), (.08, .30, .160))):
        perle(f'Fruit_{i}', x, z, r, M['fruit'], depth=.34, aplati=.94)
        trace(f'Pedoncule_{i}', [(x, z + r * .90), (x - .02, z + r * 1.45)], [.028, .024], M['sage_dark'])
    perle('Fruit_tombe', .48, -.48, .140, M['fruit'], depth=.34, aplati=.94)
    perle('Fruit_au_sol', -.16, -.92, .120, M['fruit'], depth=.30, aplati=.88)


def n29():
    """Ecorce qui se desquame : l'arbre change de peau, celle du dessous est neuve."""
    # Le tronc de trois quarts, dans l'ecorce neuve : chaude et claire, c'est
    # elle qui apparait sous celle qui s'en va.
    # Les coins doubles gardent les bouts francs : une section de tronc, pas
    # une gelule. La subdivision arrondit ce qu'on lui laisse d'espace.
    contour = [(-.84, -1.16), (-.20, -1.16), (-.18, -1.10), (-.14, -.55), (-.13, .00), (-.14, .55),
               (-.18, 1.10), (-.20, 1.16), (-.84, 1.16), (-.88, 1.10),
               (-.90, .55), (-.91, .00), (-.90, -.55), (-.88, -1.10)]
    plaque('Tronc', contour, M['ochre'], epaisseur=.58, lisse=1)
    # La laniere part du tronc, se souleve et finit enroulee : c'est le
    # rouleau qui dit qu'elle se detache, mieux qu'une ecaille posee a plat.
    def enroulement(cx, cz, r0, r1, tours, depart):
        pas = 26
        return [(cx + (r0 + (r1 - r0) * k / pas) * math.cos(depart + tours * 2 * math.pi * k / pas),
                 cz + (r0 + (r1 - r0) * k / pas) * math.sin(depart + tours * 2 * math.pi * k / pas))
                for k in range(pas + 1)]

    laniere = [(-.20, .62), (.02, .56), (.20, .40)] + enroulement(.34, .10, .34, .07, 1.35, math.radians(96))
    trace('Laniere', laniere, [.145] * 3 + [.135 - .075 * k / 26 for k in range(27)],
          M['ecorce_sombre'], depth=.34)
    # Celle de l'an dernier, tombee au pied, deja toute roulee.
    tombee = enroulement(.28, -.86, .26, .06, 1.25, math.radians(-40))
    trace('Laniere_tombee', tombee, [.105 - .055 * k / 26 for k in range(27)],
          M['ecorce'], depth=.30)


def n30():
    """Lenticelles : les pores de l'ecorce, en tirets alignes."""
    # Une branche de l'annee, en biais et en ecorce sombre : les lenticelles
    # sont des tirets clairs en travers, la ou les racines adventives (N26)
    # sont des bosses sur une tige verte. Les deux dessins ne doivent pas se
    # ressembler.
    axe = [(-1.02, -.66), (-.34, -.26), (.34, .20), (.96, .68)]
    trace('Branche', axe, [.235, .225, .210, .180], M['ecorce_sombre'], depth=0)
    direction = math.atan2(.68 + .66, .96 + 1.02)
    nx, nz = -math.sin(direction), math.cos(direction)
    for i, (t, decalage, longueur) in enumerate(((.12, .30, .085), (.24, -.34, .080), (.36, .26, .090),
                                                 (.47, -.28, .082), (.58, .30, .078), (.68, -.24, .072),
                                                 (.79, .22, .066), (.88, -.20, .058))):
        x = -1.02 + 1.98 * t + nx * decalage * .18
        z = -.66 + 1.34 * t + nz * decalage * .18
        trace(f'Lenticelle_{i}', [(x - nx * longueur, z - nz * longueur),
                                  (x + nx * longueur, z + nz * longueur)],
              [.030, .030], M['cream'], depth=.30)
    # Un bourgeon au bout : c'est une branche vivante, pas un baton.
    perle('Bourgeon', 1.02, .78, .105, M['sage_dark'], depth=.24, aplati=.88)
    feuille(.74, 1.02, .38, -34)


def n31():
    """Rougissement au soleil : la plante grasse fabrique son ecran."""
    for i in range(7):
        a = math.radians(360 / 7 * i - 90)
        x, z = .52 * math.cos(a), .46 * math.sin(a)
        incline = math.degrees(a) + 90
        ball(f'Feuille_rosette_{i}', (x, .14 + .02 * i, z), (.21, .15, .42), M['sage_light'], angle=incline)
        # La pointe est la fin de la feuille, pas une bille posee a cote.
        ball(f'Pointe_rougie_{i}', (x * 1.46, .16 + .02 * i, z * 1.46), (.155, .115, .175),
             M['jeune'], angle=incline)
    ball('Coeur_de_la_rosette', (0, .34, 0), (.20, .15, .20), M['sage'])


def n32():
    """Un changement de place : la plante se refait un feuillage."""
    sol = pot()
    tige([(.00, sol - .04), (.04, sol + .42), (.08, sol + .88), (.10, sol + 1.18)],
         [.085, .076, .066, .052])
    feuille(-.40, sol + .74, .50, -32)
    feuille(.42, sol + 1.04, .48, 30)
    feuille(-.62, sol - .34, .44, 96, mat=M['ochre'], vein=M['ochre_light'], stem=M['ochre'])
    feuille(.66, sol - .12, .42, 56, mat=M['ochre_light'], vein=M['cream'], stem=M['ochre'])


ICONES = {
    'N01': (n01, 'nectar_extrafloral'),
    'N02': (n02, 'guttation'),
    'N03': (n03, 'vieillissement_des_feuilles_basses'),
    'N04': (n04, 'panachure_naturelle'),
    'N05': (n05, 'fenestration'),
    'N06': (n06, 'racines_aeriennes'),
    'N07': (n07, 'cataphylles'),
    'N08': (n08, 'feuilles_jeunes'),
    'N09': (n09, 'latex_a_la_coupe'),
    'N10': (n10, 'pruine_cireuse'),
    'N11': (n11, 'chute_des_fleurs_fanees'),
    'N12': (n12, 'repos_hivernal'),
    'N13': (n13, 'poils_et_ecailles'),
    'N14': (n14, 'traces_de_calcaire'),
    'N15': (n15, 'feuillage_apres_floraison'),
    'N16': (n16, 'chute_des_feuilles_en_automne'),
    'N17': (n17, 'mue_des_plantes_cailloux'),
    'N18': (n18, 'cotyledons'),
    'N19': (n19, 'sores_des_fougeres'),
    'N20': (n20, 'moisissure_du_terreau'),
    'N21': (n21, 'champignon_du_terreau'),
    'N22': (n22, 'liegeage'),
    'N23': (n23, 'laine_des_areoles'),
    'N24': (n24, 'feuilles_repliees_la_nuit'),
    'N25': (n25, 'lichens_et_mousses'),
    'N26': (n26, 'racines_adventives'),
    'N27': (n27, 'nodosites'),
    'N28': (n28, 'chute_des_jeunes_fruits'),
    'N29': (n29, 'ecorce_qui_se_desquame'),
    'N30': (n30, 'lenticelles'),
    'N31': (n31, 'rougissement_au_soleil'),
    'N32': (n32, 'chute_apres_un_changement_de_place'),
}


def build(identifiant, output, res, samples):
    scene, slug = ICONES[identifiant]
    purge()
    palette()
    scene()
    objets = [o for o in bpy.context.scene.objects if o.type == 'MESH']
    # Chaque dessin a son propre cadrage, comme les illustrations des
    # problemes : une feuille seule occupe moins de place qu'une plante en pot,
    # et les ramener toutes a la meme taille apparente les ecraserait.
    studio(objets, fill=.86)
    rendu_transparent(res, samples)
    sc = bpy.context.scene
    sc.render.resolution_percentage = 100
    sc.render.threads_mode = 'FIXED'
    sc.render.threads = 4
    sc['source_repo'] = 'https://github.com/brunopaiva15/plant'
    sc['phenomene'] = identifiant
    png = output / 'renders' / f'naturel_{identifiant}_{slug}.png'
    sc.render.filepath = str(png)
    bpy.ops.render.render(write_still=True)
    grain(str(png), amplitude=.010, graine=7)
    print('DELIVERED', identifiant, str(png), flush=True)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--output', type=Path,
                        default=Path(__file__).resolve().parent.parent / 'build' / 'natural_icons')
    parser.add_argument('--resolution', type=int, default=1024)
    parser.add_argument('--samples', type=int, default=48)
    parser.add_argument('--seulement', nargs='*', default=None)
    args = parser.parse_args(sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else [])
    (args.output / 'renders').mkdir(parents=True, exist_ok=True)
    for identifiant in (args.seulement or ICONES):
        build(identifiant, args.output, args.resolution, args.samples)


if __name__ == '__main__':
    main()
