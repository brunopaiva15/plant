#!/usr/bin/env python3
"""Compose les visuels App Store à partir des captures réelles.

Chaque visuel : un papier crème teinté, avec son grain, un titre tracé en
Shantell Sans (la police « main » de l'app), un appareil dessiné (bordure,
barre d'état, île ou œil de caméra) qui montre la capture presque entière,
et un objet 3D de la série clay posé à son pied, devant lui. L'écran est
ce qu'on vend : rien ne le recouvre, à part l'objet sur son coin bas. Les
ombres sont brunes, jamais noires : c'est la lumière de l'atelier, pas celle
d'un studio.

Deux gabarits : l'iPhone 6,7 pouces (1290 × 2796) et l'iPad 13 pouces
(2064 × 2752), les deux séries que demande App Store d'une app universelle.

Les captures viennent du simulateur (store/capture_ios.sh, écran entier,
marqueur `.device` dans le dossier) ou, à défaut, du build web (capture.mjs,
390 × 844 à 3×, sans barre d'état).

Usage : compose.py <dossier captures> <dossier sortie> [fr|en|de|it] [iphone|ipad]
"""
import csv
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, '..')
FONTS = os.path.join(HERE, 'fonts/inter/extras/ttf')
HAND = os.path.join(ROOT, 'assets', 'fonts', 'ShantellSans-VF.ttf')
CLAY = os.path.join(ROOT, 'assets', 'onboarding')
ICON = os.path.join(ROOT, 'assets', 'icon', 'icon_ios_foreground.png')
INTER_ZIP = 'https://github.com/rsms/inter/releases/download/v4.1/Inter-4.1.zip'

# --- les deux gabarits --------------------------------------------------------

# Le projet Xcode déclare les deux familles (TARGETED_DEVICE_FAMILY = « 1,2 »),
# et App Store réclame alors une série par famille : 6,7 pouces pour l'iPhone,
# 13 pouces pour l'iPad. Les deux disent la même chose avec la même grammaire
# — papier teinté, titre à la main, appareil incliné, objet d'argile devant.
# Mais un iPad n'est pas un grand iPhone : presque carré, il laisse moins de
# hauteur au texte, l'appareil y prend moins de largeur, et sa capture est au
# facteur 2 quand celle de l'iPhone est au 3. Chaque gabarit porte donc ses
# mesures ; tout le fichier les lit dans L, réglé par use().
FORMATS = {
    'iphone': {
        'size': (1290, 2796),
        'margin': 96, 'text_top': 200, 'text_width': 1110,
        'title_max': 136, 'title_min': 96, 'title_line': 1.18,
        'sub_size': 54, 'sub_line': 66, 'sub_gap': 22, 'tilt': 1.0,
        # Les formes du fond : le rayon des trois taches, puis la lumière.
        'blobs': (900, 1020, 880), 'radial': ((240, 1250), 880),
        # L'appareil tient en entier dans le cadre, écran complet : sa largeur,
        # le vide entre le sous-titre et lui (où l'objet d'argile dépasse), et
        # la taille de l'objet.
        'phone_width': 850, 'phone_gap': 170, 'phone_clay': 500,
        # Les cotes de l'appareil, en points : la barre d'état, le rayon des
        # coins, le cadre, l'île (ou, sans elle, l'œil de la caméra).
        'device': {'px': 3, 'status': 54, 'radius': 55, 'bezel': 12, 'island': (126, 37), 'camera': 0, 'cellular': True},
        'cover': {
            'title': 296, 'plant': 900, 'plant_dx': 40, 'plant_overlap': 130,
            'card_h': 860, 'card_gap': 86, 'radius': 72, 'pad': 76,
            'name': 88, 'species': 54, 'species_y': 118, 'rows_y': 234,
            'rows': 'liste', 'row_h': 132, 'row_gap': 26, 'row_icon': 88, 'row_x': 126, 'row_label': 54, 'row_value': 58,
            'bar_h': 232, 'bar_bottom': 150, 'footer': 56,
        },
    },
    'ipad': {
        'size': (2064, 2752),
        'margin': 150, 'text_top': 175, 'text_width': 1660,
        'title_max': 165, 'title_min': 128, 'title_line': 1.18,
        'sub_size': 68, 'sub_line': 84, 'sub_gap': 26,
        # L'iPad est presque carré : incliné comme un téléphone, il déborderait
        # par le bas. Le même geste, aux deux tiers.
        'tilt': 0.7,
        'blobs': (1400, 1580, 1360), 'radial': ((390, 1230), 1340),
        'phone_width': 1310, 'phone_gap': 115, 'phone_clay': 620,
        'device': {'px': 2, 'status': 24, 'radius': 26, 'bezel': 20, 'island': None, 'camera': 5, 'cellular': False},
        'cover': {
            'title': 320, 'plant': 950, 'plant_dx': 30, 'plant_overlap': 170,
            'card_h': 980, 'card_gap': 90, 'radius': 90, 'pad': 100,
            'name': 116, 'species': 70, 'species_y': 156, 'rows_y': 420,
            # Trois soins côte à côte : sur une fiche presque carrée, une liste
            # en colonne laisse la moitié droite vide et monte trop haut.
            'rows': 'grille', 'row_h': 340, 'row_gap': 0, 'row_icon': 160, 'row_x': 0, 'row_label': 62, 'row_value': 74,
            'bar_h': 250, 'bar_bottom': 120, 'footer': 72,
        },
    },
}

L = FORMATS['iphone']
W, H = L['size']


def use(fmt):
    """Règle le gabarit courant : la taille de la fiche et toutes ses cotes."""
    global L, W, H
    L = FORMATS[fmt]
    W, H = L['size']


def ensure_fonts():
    """Inter (SIL OFL) n'est pas dans le dépôt : on la télécharge au besoin.
    Shantell Sans, elle, est celle de l'app (assets/fonts)."""
    if os.path.isdir(FONTS):
        return
    import io
    import urllib.request
    import zipfile
    print('téléchargement d\'Inter…', file=sys.stderr)
    data = urllib.request.urlopen(INTER_ZIP, timeout=120).read()
    zipfile.ZipFile(io.BytesIO(data)).extractall(os.path.join(HERE, 'fonts', 'inter'))


# La palette de l'app (design_system/tokens/colors.dart), en clair.
CANVAS = (246, 239, 228)
SURFACE = (251, 246, 238)
SURFACE_MUTED = (239, 228, 212)
INK = (74, 53, 40)
INK2 = (111, 90, 78)
INK3 = (154, 133, 119)
SHADOW = (94, 44, 20)
SAGE = (47, 127, 83)
TINTS = {
    'sage': ((47, 127, 83), (228, 239, 230)),
    'water': ((74, 130, 188), (220, 231, 243)),
    'sun': ((196, 144, 58), (243, 227, 194)),
    'terracotta': ((189, 88, 54), (242, 217, 203)),
    'rose': ((196, 86, 106), (245, 221, 224)),
    'earth': ((122, 76, 48), (236, 222, 208)),
    'lavender': ((110, 96, 168), (226, 222, 240)),
}


def font(name, size):
    return ImageFont.truetype(os.path.join(FONTS, f'Inter-{name}.ttf'), size)


def hand(size, weight=700):
    """Shantell Sans est une police variable : la graisse se règle par axe."""
    f = ImageFont.truetype(HAND, size)
    f.set_variation_by_axes([weight, 0, 0, 0])
    return f


# --- fond -------------------------------------------------------------------

def radial(size, center, radius, color, alpha):
    """Une tache de couleur sans bord, à poser en fondu."""
    w, h = size
    y, x = np.mgrid[0:h, 0:w]
    d = np.sqrt((x - center[0]) ** 2 + (y - center[1]) ** 2) / radius
    a = np.clip(1 - d, 0, 1) ** 1.6 * alpha
    layer = np.zeros((h, w, 4), dtype=np.uint8)
    layer[..., :3] = color
    layer[..., 3] = (a * 255).astype(np.uint8)
    return Image.fromarray(layer)


def blob(center, radius, color, alpha, seed=0, wobble=0.2):
    """Une forme organique, comme celles peintes derrière les fiches : un
    cercle dont le rayon ondule sur trois harmoniques, adouci au bord. Chaque
    fiche tire les siennes d'une graine différente : la famille est la même,
    aucune ne se répète."""
    rng = np.random.default_rng(seed)
    phases = rng.uniform(0, 2 * np.pi, 3)
    amps = rng.uniform(0.5, 1.0, 3) * wobble
    pts = []
    for i in range(320):
        a = 2 * np.pi * i / 320
        r = radius * (1 + sum(amps[k] * np.sin((k + 2) * a + phases[k]) for k in range(3)))
        pts.append((center[0] + r * np.cos(a), center[1] + r * np.sin(a)))
    mask = Image.new('L', (W, H), 0)
    ImageDraw.Draw(mask).polygon(pts, fill=int(255 * alpha))
    mask = mask.filter(ImageFilter.GaussianBlur(radius * 0.05))
    layer = Image.new('RGBA', (W, H), color + (0,))
    layer.putalpha(mask)
    return layer


def grain(img, strength=0.045, seed=7):
    """Le grain du papier, comme dans l'app : un bruit très fin qui module
    la lumière, sans toucher aux couleurs."""
    rng = np.random.default_rng(seed)
    noise = rng.normal(0, 1, (H, W, 1)).astype(np.float32)
    a = np.asarray(img.convert('RGB')).astype(np.float32)
    a = np.clip(a * (1 + noise * strength), 0, 255).astype(np.uint8)
    return Image.fromarray(a).convert('RGBA')


def background(tint, seed=0):
    """Le papier de l'app, teinté, avec deux ou trois formes organiques qui
    sortent du cadre. C'est ce qui fait qu'une fiche ne se lit pas comme un
    aplat, et le même système sur les huit fait tenir la série."""
    strong, soft = TINTS[tint]
    # Le pastel plein de la teinte, pas sa version laiteuse : a cote d'une
    # fiche du magasin, un fond trop clair passe pour un blanc rate.
    base = tuple(int(a * 0.74 + b * 0.26) for a, b in zip(soft, strong))
    r1, r2, r3 = L['blobs']
    light, light_r = L['radial']
    img = Image.new('RGBA', (W, H), base + (255,))
    img.alpha_composite(blob((W * 1.02, H * 0.06), r1, strong, 0.34, seed=seed))
    img.alpha_composite(blob((-W * 0.06, H * 0.66), r2, strong, 0.26, seed=seed + 11))
    img.alpha_composite(blob((W * 0.62, H * 1.06), r3, strong, 0.22, seed=seed + 23))
    img.alpha_composite(radial((W, H), light, light_r, (255, 253, 248), 0.40))
    return grain(img)


# --- texte --------------------------------------------------------------------

def wrap(draw, text, fnt, max_width):
    words, lines, line = text.split(), [], ''
    for w in words:
        trial = (line + ' ' + w).strip()
        if draw.textlength(trial, font=fnt) <= max_width or not line:
            line = trial
        else:
            lines.append(line)
            line = w
    if line:
        lines.append(line)
    return lines


def title_size(titles, width=None):
    """Une seule taille pour la série : la plus grande où chaque ligne de
    chaque titre tient dans la largeur. Les visuels restent accordés."""
    width = L['text_width'] if width is None else width
    draw = ImageDraw.Draw(Image.new('RGB', (10, 10)))
    size = L['title_max']
    lines = [l for t in titles for l in t.split('\n')]
    while size > L['title_min'] and max(draw.textlength(l, font=hand(size, 800)) for l in lines) > width:
        size -= 2
    return size


def draw_text_block(img, title, subtitle, size, x=None, y=None, width=None):
    """Le titre est coupé à la main (retours à la ligne dans la copie)."""
    x = L['margin'] if x is None else x
    y = L['text_top'] if y is None else y
    width = L['text_width'] if width is None else width
    draw = ImageDraw.Draw(img)
    lines = title.split('\n')
    t_font = hand(size, 800)
    for line in lines:
        draw.text((x, y), line, font=t_font, fill=INK)
        y += int(size * L['title_line'])
    y += L['sub_gap']
    s_font = font('Medium', L['sub_size'])
    for line in wrap(draw, subtitle, s_font, width - 40):
        draw.text((x + 4, y), line, font=s_font, fill=INK2)
        y += L['sub_line']
    return y


# --- l'appareil ---------------------------------------------------------------

def status_bar(width, height, bg, ink, u=1.0, cellular=True):
    """Une barre d'état iOS : l'heure d'Apple, réseau, wifi, batterie.
    Sans [bg], la barre est transparente, à poser sur une photo.

    Les cotes sont celles d'une capture d'iPhone au facteur 3 ; [u] les ramène
    au facteur de la capture (2/3 pour un iPad, qui capture au facteur 2). Un
    iPad wifi n'a pas d'antenne : [cellular] efface les quatre barres."""
    def s(v):
        return int(round(v * u))

    bar = Image.new('RGBA', (width, height), bg + (255,) if bg else (0, 0, 0, 0))
    d = ImageDraw.Draw(bar)
    d.text((s(100), height // 2 - s(4)), '9:41', font=font('SemiBold', s(50)), fill=ink, anchor='lm')
    # Signal : quatre barres qui montent
    x0 = width - s(300)
    if cellular:
        for i in range(4):
            h = s(18 + i * 10)
            d.rounded_rectangle((x0 + s(i * 20), height // 2 + s(20) - h, x0 + s(i * 20) + s(12), height // 2 + s(20)), radius=s(3), fill=ink)
    # Wifi : trois arcs
    cx, cy = width - s(190), height // 2 + s(20)
    for r, wdt in ((44, 9), (28, 9), (10, 10)):
        d.arc((cx - s(r), cy - s(r), cx + s(r), cy + s(r)), start=225, end=315, fill=ink, width=s(wdt))
    # Batterie
    bx = width - s(130)
    d.rounded_rectangle((bx, height // 2 - s(18), bx + s(78), height // 2 + s(18)), radius=s(10), outline=ink, width=s(4))
    d.rounded_rectangle((bx + s(6), height // 2 - s(12), bx + s(60), height // 2 + s(12)), radius=s(6), fill=ink)
    d.rounded_rectangle((bx + s(80), height // 2 - s(7), bx + s(86), height // 2 + s(7)), radius=s(3), fill=ink)
    return bar


def phone(shot, scrim=0.0, sheet=None, device=False):
    """La capture habillée en appareil, aux cotes du gabarit courant.
    [shot] est un chemin, ou une capture déjà retouchée. Une capture du web
    (390 × 844) n'a pas de barre d'état : on la dessine au-dessus. Une
    capture d'appareil ([device]) est l'écran entier : la place de la barre
    d'état y est déjà réservée en haut, on dessine dedans. Avec [scrim] et
    [sheet], une feuille modale est posée sur l'écran entier, barre d'état
    comprise, comme l'app le fait."""
    dev = L['device']
    px, u = dev['px'], dev['px'] / 3
    shot = (Image.open(shot) if isinstance(shot, str) else shot).convert('RGB')
    sw, sh = shot.size
    top = dev['status'] * px
    if device:
        screen = shot.convert('RGBA')
    else:
        screen = Image.new('RGBA', (sw, sh + top))
        screen.paste(shot, (0, top))
    strip = shot.crop((0, 0, sw, top))
    if max(abs(a - b) for a, b in zip(strip.getpixel((sw // 2, 6)), CANVAS)) < 24:
        # Le papier de l'app : la barre d'état est du même papier.
        bar = status_bar(sw, top, strip.getpixel((sw // 2, 6)), INK, u, dev['cellular'])
    else:
        # Une photo en tête de page : elle continue sous la barre d'état
        # (en miroir et un peu floue quand la capture s'arrête au bord),
        # assombrie vers le haut, et les icônes passent en blanc dessus.
        bar = strip.convert('RGBA') if device else strip.transpose(Image.FLIP_TOP_BOTTOM).filter(ImageFilter.GaussianBlur(6)).convert('RGBA')
        veil = np.zeros((top, sw, 4), dtype=np.uint8)
        veil[..., 3] = np.linspace(120, 30, top).astype(np.uint8)[:, None]
        bar.alpha_composite(Image.fromarray(veil))
        bar.alpha_composite(status_bar(sw, top, None, (255, 255, 255), u, dev['cellular']))
    screen.paste(bar, (0, 0))
    sh = screen.height - top
    if scrim:
        # La barrière modale, brune comme les ombres
        screen.alpha_composite(Image.new('RGBA', screen.size, SHADOW + (int(255 * scrim),)))
    if sheet is not None:
        screen.alpha_composite(sheet, (0, screen.height - sheet.height))
    screen = screen.convert('RGB')
    # Coins de l'écran
    radius = dev['radius'] * px
    mask = Image.new('L', screen.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, sw - 1, sh + top - 1), radius=radius, fill=255)
    bezel = dev['bezel'] * px
    edge = max(1, int(round(3 * u)))
    body = Image.new('RGBA', (sw + 2 * bezel, sh + top + 2 * bezel), (0, 0, 0, 0))
    d = ImageDraw.Draw(body)
    d.rounded_rectangle((0, 0, body.width - 1, body.height - 1), radius=radius + bezel, fill=(46, 36, 30, 255))
    d.rounded_rectangle((edge, edge, body.width - 1 - edge, body.height - 1 - edge), radius=radius + bezel - edge, outline=(92, 76, 66, 255), width=edge)
    body.paste(screen, (bezel, bezel), mask)
    if dev['island']:
        # Dynamic Island
        iw, ih = dev['island'][0] * px, dev['island'][1] * px
        ix, iy = bezel + (sw - iw) // 2, bezel + 11 * px
        d.rounded_rectangle((ix, iy, ix + iw, iy + ih), radius=ih // 2, fill=(14, 11, 9, 255))
    elif dev['camera']:
        # L'iPad n'a pas d'île : un œil de caméra au milieu du cadre du haut.
        r = dev['camera'] * px
        cx, cy = bezel + sw // 2, bezel // 2
        d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(20, 16, 13, 255))
    return body


# --- argile -------------------------------------------------------------------

def paste_with_shadow(canvas, layer, pos, blur=40, offset=(0, 30), alpha=0.28):
    """Pose un calque avec son ombre portée, brune comme dans l'app. L'ombre
    est floutée dans un calque plus grand que l'élément : floutée à sa
    taille exacte, elle serait coupée net sur ses bords et laisserait un
    rectangle translucide derrière lui."""
    pad = blur * 3
    a = Image.new('L', (layer.width + 2 * pad, layer.height + 2 * pad), 0)
    a.paste(layer.split()[-1].point(lambda v: int(v * alpha)), (pad + offset[0], pad + offset[1]))
    sh = Image.new('RGBA', a.size, SHADOW + (0,))
    sh.putalpha(a.filter(ImageFilter.GaussianBlur(blur)))
    canvas.alpha_composite(sh, (pos[0] - pad, pos[1] - pad))
    canvas.alpha_composite(layer, pos)


def clay_shape(mask, color=SURFACE):
    """Une pièce d'argile à la forme donnée : l'aplat, un reflet en haut à
    gauche, une ombre en bas à droite, rognés à la forme. Le calque rendu est
    transparent hors de la pièce ; l'ombre portée se pose à part."""
    w, h = mask.size
    layer = Image.new('RGBA', (w, h), color + (255,))

    def rim(dx, dy, blur):
        shifted = Image.new('L', (w, h), 0)
        shifted.paste(mask, (dx, dy))
        m = Image.fromarray(np.clip(np.asarray(mask).astype(int) - np.asarray(shifted).astype(int), 0, 255).astype(np.uint8))
        return m.filter(ImageFilter.GaussianBlur(blur))

    unit = max(1.0, min(w, h) / 160)
    light = Image.new('RGBA', (w, h), (255, 255, 255, 0))
    light.putalpha(rim(int(4 * unit), int(4 * unit), 6 * unit).point(lambda v: int(v * 0.85)))
    layer.alpha_composite(light)
    shade = Image.new('RGBA', (w, h), tuple(int(c * 0.7) for c in color) + (0,))
    shade.putalpha(rim(-int(5 * unit), -int(6 * unit), 8 * unit).point(lambda v: int(v * 0.16)))
    layer.alpha_composite(shade)
    layer.putalpha(mask)
    return layer


def clay_card(size, radius, color=SURFACE):
    """Une carte d'argile comme celles de l'app."""
    mask = Image.new('L', size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, size[0] - 1, size[1] - 1), radius=radius, fill=255)
    return clay_shape(mask, color)


def clay_arch(width, height, color=SURFACE):
    """Une arche : un plein cintre posé sur des montants droits. Elle sort du
    cadre par le bas, et rien dans la fiche ne se retrouve dans une boîte
    dans une boîte."""
    mask = Image.new('L', (width, height), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, width - 1, height + width), radius=width // 2, fill=255)
    return clay_shape(mask, color)


def place_phone(canvas, shot, y, width=None, angle=0.0, **modal):
    """L'appareil, legerement incline : droit, huit fiches d'affilee font
    une planche de catalogue ; penche, la serie respire. Rend sa boite pour
    que l'objet d'argile sache ou se poser."""
    width = L['phone_width'] if width is None else width
    angle *= L['tilt']
    ph = phone(shot, **modal)
    scale = width / ph.width
    ph = ph.resize((width, int(ph.height * scale)), Image.LANCZOS)
    if angle:
        ph = ph.rotate(angle, resample=Image.BICUBIC, expand=True)
    x = (W - ph.width) // 2
    paste_with_shadow(canvas, ph, (x, y), blur=60, offset=(14, 50), alpha=0.34)
    return (x, y, ph.width, ph.height)


def place_object(canvas, name, size, corner, box):
    """L'objet d'argile, pose devant le telephone et jamais derriere : il
    mord sur un coin bas de l'ecran, entier, a sa taille native."""
    obj = crisp(os.path.join('assets', 'onboarding', name), box=size)
    x, y, w, h = box
    px = x - obj.width // 3 if corner == 'left' else x + w - obj.width * 2 // 3
    # Entier dans le cadre : un objet coupe par le bord n'est plus un objet.
    py = min(y + h - obj.height - 40, H - obj.height - 70)
    paste_with_shadow(canvas, obj, (max(20, min(px, W - obj.width - 20)), py), blur=50, offset=(12, 36), alpha=0.26)


# --- la feuille « Espèce » ---------------------------------------------------

# Une photo CC0 (iNaturalist, observation 359128431, photo 655212161) qui
# n'est pas dans le jeu d'entraînement, et ce que le modèle livré en dit.
# Ce sont ses vrais résultats, pas une maquette : les recalculer avec
#   python3 store/ident/score.py store/ident/ficus-lyrata.jpg
# après chaque nouveau modèle.
IDENT_PHOTO = os.path.join(HERE, 'ident', 'ficus-lyrata.jpg')
IDENT_RESULTS = [('Ficus lyrata', 0.804), ('Epipremnum aureum', 0.063), ('Euphorbia lactea', 0.039)]
# Les seuils du modèle embarqué (domain/identification/identification_policy.dart).
LIKELY, POSSIBLE = 0.70, 0.25
# Les textes de la feuille, ceux des ARB.
IDENT_COPY = {
    'fr': {'title': 'Espèce', 'hint': 'Reconnu par Iris sur l’appareil. Choisissez l’espèce.', 'use': 'Utiliser',
           'online': 'Chercher en ligne', 'likely': 'Probable', 'possible': 'Possible', 'unlikely': 'Peu probable'},
    'en': {'title': 'Species', 'hint': 'Recognised by Iris on the device. Choose the species.', 'use': 'Use',
           'online': 'Search online', 'likely': 'Likely', 'possible': 'Possible', 'unlikely': 'Less likely'},
    'de': {'title': 'Art', 'hint': 'Von Iris auf dem Gerät erkannt. Wählen Sie die Art.', 'use': 'Verwenden',
           'online': 'Online suchen', 'likely': 'Wahrscheinlich', 'possible': 'Möglich', 'unlikely': 'Wenig wahrscheinlich'},
    'it': {'title': 'Specie', 'hint': 'Riconosciuta da Iris sul dispositivo. Scegliete la specie.', 'use': 'Usa',
           'online': 'Cerca online', 'likely': 'Probabile', 'possible': 'Possibile', 'unlikely': 'Poco probabile'},
}

def common_names(lang):
    with open(os.path.join(ROOT, 'tools', 'plant_dataset', 'plants.csv'), newline='', encoding='utf-8') as f:
        return {r['scientific_name']: r.get(f'common_{lang}', '') for r in csv.DictReader(f)}


def fit(d, text, name, size, max_width):
    """La plus grande taille où [text] tient dans [max_width]. « Tous les 8
    jours » et « Alle 8 Tage » n'ont pas la même longueur, et la fiche est la
    même dans les quatre langues."""
    while size > 20 and d.textlength(text, font=font(name, size)) > max_width:
        size -= 2
    return font(name, size)


def ellipsize(d, text, fnt, max_width):
    """Comme un Text à une ligne : coupé avec des points de suspension."""
    if d.textlength(text, font=fnt) <= max_width:
        return text
    while text and d.textlength(text + '…', font=fnt) > max_width:
        text = text[:-1].rstrip()
    return text + '…'


def diamond(d, center, size, level):
    """Le cran de confiance de l'app : trois losanges, du plein au vide."""
    x, y = center
    pts = [(x, y - size), (x + size, y), (x, y + size), (x - size, y)]
    if level == 'likely':
        d.polygon(pts, fill=SAGE)
    elif level == 'possible':
        d.polygon(pts, outline=SAGE, width=6)
        inner = [(x, y - size // 2), (x + size // 2, y), (x, y + size // 2), (x - size // 2, y)]
        d.polygon(inner, fill=SAGE)
    else:
        d.polygon(pts, outline=INK3, width=6)


def ident_sheet(lang, width=1170):
    """La feuille « Espèce » telle que l'app la présente après une photo :
    l'en-tête, la phrase d'origine, un groupe d'argile avec une ligne par
    espèce (le cran, le nom courant, le nom scientifique et le mot de
    confiance, le bouton « Utiliser »), puis le bouton fantôme de la
    recherche en ligne. Tout à 3×, comme la capture qu'elle recouvre."""
    t, names = IDENT_COPY[lang], common_names(lang)
    pad, row_h = 48, 204
    y = 0
    height = 40 + 150 + 56 + 40 + row_h * len(IDENT_RESULTS) + 48 + 120 + 110
    sheet = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    mask = Image.new('L', (width, height), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, width - 1, height + 200), radius=3 * 28, fill=255)
    sheet.paste(Image.new('RGBA', (width, height), SURFACE + (255,)), (0, 0), mask)
    d = ImageDraw.Draw(sheet)
    # La poignée, puis le titre centré
    d.rounded_rectangle((width // 2 - 54, 24, width // 2 + 54, 40), radius=8, fill=(214, 200, 184))
    y = 40 + 12
    d.text((width // 2, y + 66), t['title'], font=font('SemiBold', 54), fill=INK, anchor='mm')
    y += 150
    d.text((pad, y), t['hint'], font=font('Regular', 39), fill=INK2)
    y += 56 + 40
    # Le groupe d'argile, une ligne par espèce
    group = clay_card((width - 2 * pad, row_h * len(IDENT_RESULTS)), 3 * 20, color=(255, 252, 246))
    sheet.alpha_composite(group, (pad, y))
    d = ImageDraw.Draw(sheet)
    for i, (name, score) in enumerate(IDENT_RESULTS):
        cy = y + i * row_h + row_h // 2
        level = 'likely' if score >= LIKELY else 'possible' if score >= POSSIBLE else 'unlikely'
        diamond(d, (pad + 48 + 60, cy), 27, level)
        common = names.get(name, '')
        x = pad + 48 + 132 + 24
        title, sub = (common, f'{name} · {t[level]}') if common else (name, t[level])
        bw, bh = 96 + 33 * len(t['use']), 108
        bx = width - pad - 48 - bw
        d.text((x, cy - 28), title, font=font('SemiBold', 51), fill=INK, anchor='lm')
        d.text((x, cy + 34), ellipsize(d, sub, font('Regular', 39), bx - 24 - x), font=font('Regular', 39), fill=INK2, anchor='lm')
        pill = clay_card((bw, bh), bh // 2, color=(228, 239, 230))
        sheet.alpha_composite(pill, (bx, cy - bh // 2))
        d = ImageDraw.Draw(sheet)
        d.text((bx + bw // 2, cy), t['use'], font=font('SemiBold', 45), fill=SAGE, anchor='mm')
        if i < len(IDENT_RESULTS) - 1:
            d.line((x, y + (i + 1) * row_h, width - pad - 48, y + (i + 1) * row_h), fill=(232, 220, 204), width=3)
    y += row_h * len(IDENT_RESULTS) + 48
    d.text((width // 2, y + 60), t['online'], font=font('SemiBold', 51), fill=SAGE, anchor='mm')
    return sheet


# Sans capture de la feuille « Espèce » — le modèle ne tourne pas sur le
# web —, elle est redessinée sur la fiche du Ficus, celle-là même qu'elle
# recouvre dans l'app.


# --- la fiche de présentation -------------------------------------------------

# La première fiche ne montre pas un écran : elle plante le décor, fort, sur
# un aplat sauge. Les concurrents du magasin font tous la même chose — un
# aplat saturé, un titre énorme, une vraie photo, des pastilles d'interface
# posées dessus. Ici les pastilles sont celles de l'app, à sa palette.
# La fiche d'ouverture suit la mise en page de l'app : la marge de page, un
# grand titre en haut à gauche, puis des cartes en colonne. Elle y ajoute une
# bande sauge, la plante de l'icône posée sur son bord, et une carte de verre
# dépoli qui mord sur la bande. Rien de plus : une fiche chargée ne se lit
# pas dans une grille de vignettes.
COVER = {
    'fr': {
        'title': 'Auxine',
        'subtitle': 'le carnet de vos plantes',
        'name': 'Monstera deliciosa',
        'species': 'Faux philodendron',
        'rows': [
            ('assets/onboarding/onboarding_3.png', 'Arrosage', 'Tous les 8 jours'),
            ('assets/problems/clay_abiotique.webp', 'Lumière', 'Vive indirecte'),
            ('assets/onboarding/onboarding_2.png', 'Dernier soin', 'Il y a 2 jours'),
        ],
        'footer': 'Gratuite, sans compte, sans publicité',
    },
    'en': {
        'title': 'Auxine',
        'subtitle': 'the journal of your plants',
        'name': 'Monstera deliciosa',
        'species': 'Swiss cheese plant',
        'rows': [
            ('assets/onboarding/onboarding_3.png', 'Watering', 'Every 8 days'),
            ('assets/problems/clay_abiotique.webp', 'Light', 'Bright indirect'),
            ('assets/onboarding/onboarding_2.png', 'Last care', '2 days ago'),
        ],
        'footer': 'Free, no account, no ads',
    },
    'de': {
        'title': 'Auxine',
        'subtitle': 'das Tagebuch Ihrer Pflanzen',
        'name': 'Monstera deliciosa',
        'species': 'Fensterblatt',
        'rows': [
            ('assets/onboarding/onboarding_3.png', 'Gießen', 'Alle 8 Tage'),
            ('assets/problems/clay_abiotique.webp', 'Licht', 'Hell, indirekt'),
            ('assets/onboarding/onboarding_2.png', 'Letzte Pflege', 'Vor 2 Tagen'),
        ],
        'footer': 'Kostenlos, ohne Konto, ohne Werbung',
    },
    'it': {
        'title': 'Auxine',
        'subtitle': 'il diario delle vostre piante',
        'name': 'Monstera deliciosa',
        'species': 'Monstera',
        'rows': [
            ('assets/onboarding/onboarding_3.png', 'Annaffiatura', 'Ogni 8 giorni'),
            ('assets/problems/clay_abiotique.webp', 'Luce', 'Viva indiretta'),
            ('assets/onboarding/onboarding_2.png', 'Ultima cura', '2 giorni fa'),
        ],
        'footer': 'Gratuita, senza account, senza pubblicità',
    },
}

SAGE_SOLID = (44, 119, 78)
CREAM = (250, 245, 236)
TERRACOTTA = (156, 72, 44)


def rounded_mask(size, radius):
    mask = Image.new('L', size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, size[0] - 1, size[1] - 1), radius=radius, fill=255)
    return mask


def glass(img, box, radius=72, blur=70, alpha=0.46):
    """Une plaque de verre dépoli posée sur la fiche.

    Le verre n'a rien à montrer s'il n'y a rien dessous : on reprend ce que
    la fiche porte déjà à cet endroit, on le floute, on l'éclaircit d'un
    souffle, et on pose un voile blanc dessus. Un liseré clair sur le
    pourtour et une lumière qui glisse du haut font le reste — c'est ce
    liseré qui donne son épaisseur à la plaque."""
    x, y, w, h = box
    region = img.crop((x, y, x + w, y + h)).convert('RGB').filter(ImageFilter.GaussianBlur(blur))
    region = ImageEnhance.Brightness(region).enhance(1.05)
    pane = region.convert('RGBA')
    pane.alpha_composite(Image.new('RGBA', (w, h), (255, 253, 250, int(255 * alpha))))
    # La lumière du haut, qui s'éteint vers le bas.
    grad = np.zeros((h, w, 4), dtype=np.uint8)
    grad[..., :3] = 255
    grad[..., 3] = np.clip(np.linspace(86, 0, h) ** 1.2, 0, 255).astype(np.uint8)[:, None]
    pane.alpha_composite(Image.fromarray(grad))
    d = ImageDraw.Draw(pane)
    d.rounded_rectangle((1, 1, w - 2, h - 2), radius=radius, outline=(255, 255, 255, 150), width=3)
    d.rounded_rectangle((4, 4, w - 5, h - 5), radius=radius - 3, outline=(255, 255, 255, 60), width=2)
    pane.putalpha(Image.fromarray(np.minimum(np.asarray(pane.split()[-1]), np.asarray(rounded_mask((w, h), radius)))))
    # L'ombre portée, brune et très douce : la plaque flotte, elle ne colle pas.
    pad = 90
    sh = Image.new('L', (w + 2 * pad, h + 2 * pad), 0)
    sh.paste(rounded_mask((w, h), radius).point(lambda v: int(v * 0.22)), (pad, pad + 26))
    shadow = Image.new('RGBA', sh.size, SHADOW + (0,))
    shadow.putalpha(sh.filter(ImageFilter.GaussianBlur(46)))
    img.alpha_composite(shadow, (x - pad, y - pad))
    img.alpha_composite(pane, (x, y))


def crisp(path, height=None, width=None, box=None):
    """Un objet d'argile à sa taille, jamais au-delà : ces images font 640 ou
    1024 pixels, et les étirer plus loin les fait fondre — c'est ce qui
    donnait à la fiche son air bon marché."""
    im = Image.open(os.path.join(ROOT, path)).convert('RGBA')
    im = im.crop(im.getbbox())
    if box:
        # Tenir dans un carré : les objets n'ont pas tous la même allure, et
        # caler sur la hauteur ferait déborder les larges sur le libellé.
        scale = box / max(im.width, im.height)
        width, height = int(im.width * scale), int(im.height * scale)
    elif height:
        width = int(im.width * height / im.height)
    else:
        height = int(im.height * width / im.width)
    return im.resize((width, height), Image.LANCZOS)


def cover(lang, size):
    """La fiche d'ouverture entre dans le même gabarit que les sept autres :
    même fond, même titre au même endroit, même sous-titre. À la place de
    l'appareil, la plante de l'icône, la carte de ce que l'app dit d'une
    plante en verre dépoli, et la carte pleine de terre cuite."""
    t, c, m = COVER[lang], L['cover'], L['margin']
    img = background('sage', seed=1)
    # Le nom de l'app n'est pas un titre de fiche : il se lit de loin, dans la
    # grille du magasin, et il porte la serie. Il a donc sa taille a lui.
    draw_text_block(img, t['title'], t['subtitle'], c['title'])

    # La fiche se cale par le bas : la barre d'abord, la carte au-dessus, la
    # plante posee sur elle. Sans quoi le bas de la fiche reste vide.
    bar_h = c['bar_h']
    by = H - c['bar_bottom'] - bar_h
    gw, gh = W - 2 * m, c['card_h']
    gx, gy = m, by - c['card_gap'] - gh

    # Sur l'iPhone la plante est au milieu, au-dessus de la carte ; sur l'iPad,
    # ou le titre ne prend que la moitie de la largeur, elle passe a sa droite.
    plant = crisp('assets/icon/icon_ios_foreground.png', width=c['plant'])
    paste_with_shadow(img, plant, ((W - plant.width) // 2 + c['plant_dx'], gy + c['plant_overlap'] - plant.height), blur=64, offset=(16, 46), alpha=0.28)

    glass(img, (gx, gy, gw, gh), radius=c['radius'], blur=56, alpha=0.58)
    d = ImageDraw.Draw(img)
    pad = c['pad']
    d.text((gx + pad, gy + pad - 6), t['name'], font=font('Bold', c['name']), fill=INK)
    d.text((gx + pad, gy + pad + c['species_y']), t['species'], font=font('MediumItalic', c['species']), fill=SAGE)
    yy = gy + pad + c['rows_y']
    icon_box, row_h = c['row_icon'], c['row_h']
    if c['rows'] == 'grille':
        cw = (gw - 2 * pad) // len(t['rows'])
        for i, (icon, label, value) in enumerate(t['rows']):
            cx = gx + pad + cw * i + cw // 2
            if i:
                d.line((cx - cw // 2, yy + 20, cx - cw // 2, yy + row_h - 40), fill=(255, 255, 255, 160), width=3)
            obj = crisp(icon, box=icon_box)
            img.alpha_composite(obj, (cx - obj.width // 2, yy + (icon_box - obj.height) // 2))
            d = ImageDraw.Draw(img)
            d.text((cx, yy + icon_box + 56), label, font=font('Medium', c['row_label']), fill=INK2, anchor='mm')
            d.text((cx, yy + icon_box + 146), value, font=fit(d, value, 'Bold', c['row_value'], cw - 60), fill=INK, anchor='mm')
    else:
        for i, (icon, label, value) in enumerate(t['rows']):
            if i:
                d.line((gx + pad + c['row_x'], yy, gx + gw - pad, yy), fill=(255, 255, 255, 160), width=3)
            yy += c['row_gap']
            obj = crisp(icon, box=icon_box)
            img.alpha_composite(obj, (gx + pad + (icon_box - obj.width) // 2, yy + (icon_box + 10 - obj.height) // 2))
            d = ImageDraw.Draw(img)
            d.text((gx + pad + c['row_x'], yy + row_h // 2 - 17), label, font=font('Medium', c['row_label']), fill=INK2, anchor='lm')
            d.text((gx + gw - pad, yy + row_h // 2 - 17), value, font=font('Bold', c['row_value']), fill=INK, anchor='rm')
            yy += row_h

    # La carte pleine de terre cuite : dans l'app, c'est celle qui compte.
    paste_with_shadow(img, clay_card((gw, bar_h), c['radius'], color=TERRACOTTA), (m, by), blur=52, offset=(12, 36), alpha=0.28)
    ImageDraw.Draw(img).text((W // 2, by + bar_h // 2), t['footer'], font=font('Bold', c['footer']), fill=CREAM, anchor='mm')
    return img


# --- les visuels --------------------------------------------------------------

# Le registre des fiches App Store : un titre court, puis un fragment en
# minuscules, sans point. Pas de phrase.
COPY = {
    'fr': [
        ("Chaque matin,\nl'état des plantes", 'les soins qui viennent, à cocher'),
        ('Toutes vos plantes,\nau même endroit', 'avec leur photo, leur espèce et leur pièce'),
        ('Chaque plante\na sa page', 'photos, prochains soins, journal'),
        ("Une fiche d'entretien\npour chaque espèce", 'arrosage, lumière, engrais, rempotage'),
        ('Quelle est\ncette plante ?', 'une photo suffit, même sans réseau'),
        ('Lieux, calendrier,\ninventaire', 'pour un appartement ou un jardin entier'),
        ('Un diagnostic\nsur photo', 'plus de 200 troubles, ravageurs, maladies'),
    ],
    'en': [
        ('Each morning,\nwhere things stand', 'upcoming care, to tick off'),
        ('All your plants,\nin one place', 'with their photo, species and room'),
        ('Every plant\nhas its page', 'photos, upcoming care, journal'),
        ('A care guide\nfor every species', 'watering, light, feeding, repotting'),
        ('What plant\nis this?', 'one photo is enough, even offline'),
        ('Rooms, calendar,\ninventory', 'for a whole flat or garden'),
        ('A diagnosis\nfrom a photo', '200+ disorders, pests and diseases'),
    ],
    'de': [
        ('Jeden Morgen,\nder Stand der Dinge', 'die anstehende Pflege, zum Abhaken'),
        ('Alle Pflanzen,\nan einem Ort', 'mit Foto, Art und Zimmer'),
        ('Jede Pflanze\nhat ihre Seite', 'Fotos, nächste Pflege, Tagebuch'),
        ('Ein Pflegeblatt\nfür jede Art', 'Gießen, Licht, Dünger, Umtopfen'),
        ('Welche Pflanze\nist das?', 'ein Foto genügt, auch ohne Netz'),
        ('Orte, Kalender,\nBestand', 'für eine Wohnung oder einen ganzen Garten'),
        ('Eine Diagnose\nnach Foto', 'über 200 Störungen, Schädlinge, Krankheiten'),
    ],
    'it': [
        ('Ogni mattina,\nlo stato delle piante', 'le cure in arrivo, da spuntare'),
        ('Tutte le piante,\nnello stesso posto', 'con foto, specie e stanza'),
        ('Ogni pianta\nha la sua pagina', 'foto, prossime cure, diario'),
        ('Una scheda di cura\nper ogni specie', 'annaffiatura, luce, concime, rinvaso'),
        ('Che pianta\nè questa?', 'basta una foto, anche senza rete'),
        ('Luoghi, calendario,\ninventario', 'per un appartamento o un giardino intero'),
        ('Una diagnosi\nda una foto', 'oltre 200 disturbi, parassiti, malattie'),
    ],
}

SCENES = [
    ('today', 'water', 'onboarding_2.png', -3.5, 'right'),
    ('plants', 'sage', 'collection_monstera.webp', 3.0, 'left'),
    ('plant', 'terracotta', 'collection_ronde.webp', -3.0, 'right'),
    ('care', 'sun', 'onboarding_3.png', 3.5, 'left'),
    ('capture', 'earth', 'collection_caoutchouc.webp', -3.0, 'right'),
    ('garden-calendar', 'lavender', 'onboarding_7.png', 3.0, 'left'),
    ('diagnosis', 'rose', 'collection_sansevieria.webp', -3.5, 'right'),
]
# Chaque visuel : la capture, la teinte du papier, l'objet d'argile qui dépasse.


def build(shots, out, lang, fmt='iphone'):
    use(fmt)
    os.makedirs(out, exist_ok=True)
    # Des captures d'appareil (store/capture_ios.sh) ou du web (capture.mjs).
    device = os.path.exists(os.path.join(shots, '.device'))
    copy = COPY[lang]
    size = title_size([COVER[lang]['title']] + [t for t, _ in copy])
    cover(lang, size).convert('RGB').save(os.path.join(out, '1.png'), optimize=True)
    for i, ((title, subtitle), (name, tint, clay, angle, corner)) in enumerate(zip(copy, SCENES), start=2):
        img = background(tint, seed=i * 7)
        bottom = draw_text_block(img, title, subtitle, size)
        shot = os.path.join(shots, f'{name}.png')
        modal = {'device': device}
        if name == 'capture' and not os.path.exists(shot) and fmt == 'iphone':
            # Ni caméra ni modèle sur le web : l'étape photo ne s'y prend pas.
            # Le repli montre l'autre façon d'identifier — la feuille
            # « Espèce » redessinée sur la fiche du Ficus, avec les vrais
            # résultats. Il est taillé pour une capture de téléphone ; sur
            # iPad, mieux vaut pas de visuel qu'une feuille aux mauvaises
            # proportions.
            shot = os.path.join(shots, 'plant-ficus.png')
            modal.update(scrim=0.36, sheet=ident_sheet(lang))
        if isinstance(shot, str) and not os.path.exists(shot):
            # Une capture manquée ne bloque pas les autres : le visuel
            # précédent reste en place, et on le dit.
            print(f'{i}.png : pas de capture « {name} » dans {shots}, visuel laissé tel quel', file=sys.stderr)
            continue
        box = place_phone(img, shot, y=bottom + L['phone_gap'], angle=angle, **modal)
        place_object(img, clay, L['phone_clay'], corner, box)
        img.convert('RGB').save(os.path.join(out, f'{i}.png'), optimize=True)


if __name__ == '__main__':
    ensure_fonts()
    build(sys.argv[1], sys.argv[2], sys.argv[3] if len(sys.argv) > 3 else 'fr',
          sys.argv[4] if len(sys.argv) > 4 else 'iphone')
