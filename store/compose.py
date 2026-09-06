#!/usr/bin/env python3
"""Compose les visuels App Store (1290 × 2796) à partir des captures réelles.

Chaque visuel : un papier crème teinté, avec son grain, un titre tracé en
Shantell Sans (la police « main » de l'app), un iPhone dessiné (bordure,
Dynamic Island, barre d'état) qui contient la capture, un objet 3D de la
série clay, et parfois un éclat d'interface découpé dans la capture et posé
en avant. Les ombres sont brunes, jamais noires : c'est la lumière de
l'atelier, pas celle d'un studio.

Usage : compose.py <dossier captures> <dossier sortie> [fr|en]
"""
import csv
import json
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

W, H = 1290, 2796
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, '..')
FONTS = os.path.join(HERE, 'fonts/inter/extras/ttf')
HAND = os.path.join(ROOT, 'assets', 'fonts', 'ShantellSans-VF.ttf')
CLAY = os.path.join(ROOT, 'assets', 'onboarding')
INTER_ZIP = 'https://github.com/rsms/inter/releases/download/v4.1/Inter-4.1.zip'


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
    return Image.fromarray(layer, 'RGBA')


def grain(img, strength=0.045, seed=7):
    """Le grain du papier, comme dans l'app : un bruit très fin qui module
    la lumière, sans toucher aux couleurs."""
    rng = np.random.default_rng(seed)
    noise = rng.normal(0, 1, (H, W, 1)).astype(np.float32)
    a = np.asarray(img.convert('RGB')).astype(np.float32)
    a = np.clip(a * (1 + noise * strength), 0, 255).astype(np.uint8)
    return Image.fromarray(a, 'RGB').convert('RGBA')


def background(tint):
    strong, soft = TINTS[tint]
    base = tuple(int(s * 0.5 + c * 0.5) for s, c in zip(soft, CANVAS))
    img = Image.new('RGBA', (W, H), base + (255,))
    img.alpha_composite(radial((W, H), (1180, 380), 980, strong, 0.20))
    img.alpha_composite(radial((W, H), (120, 2500), 900, (255, 252, 246), 0.6))
    img.alpha_composite(radial((W, H), (300, 1500), 700, strong, 0.07))
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


def title_size(titles, width=1110):
    """Une seule taille pour la série : la plus grande où chaque ligne de
    chaque titre tient dans la largeur. Les visuels restent accordés."""
    draw = ImageDraw.Draw(Image.new('RGB', (10, 10)))
    size = 116
    lines = [l for t in titles for l in t.split('\n')]
    while size > 80 and max(draw.textlength(l, font=hand(size)) for l in lines) > width:
        size -= 2
    return size


def draw_text_block(img, title, subtitle, size, x=96, y=200, width=1110):
    """Le titre est coupé à la main (retours à la ligne dans la copie)."""
    draw = ImageDraw.Draw(img)
    lines = title.split('\n')
    t_font = hand(size)
    for line in lines:
        draw.text((x, y), line, font=t_font, fill=INK)
        y += int(size * 1.18)
    y += 22
    s_font = font('Medium', 50)
    for line in wrap(draw, subtitle, s_font, width - 40):
        draw.text((x + 4, y), line, font=s_font, fill=INK2)
        y += 66
    return y


# --- iPhone -------------------------------------------------------------------

def status_bar(width, height, bg):
    """Une barre d'état iOS : l'heure d'Apple, réseau, wifi, batterie."""
    bar = Image.new('RGBA', (width, height), bg + (255,))
    d = ImageDraw.Draw(bar)
    d.text((100, height // 2 - 4), '9:41', font=font('SemiBold', 50), fill=INK, anchor='lm')
    # Signal : quatre barres qui montent
    x0 = width - 300
    for i in range(4):
        h = 18 + i * 10
        d.rounded_rectangle((x0 + i * 20, height // 2 + 20 - h, x0 + i * 20 + 12, height // 2 + 20), radius=3, fill=INK)
    # Wifi : trois arcs
    cx, cy = width - 190, height // 2 + 20
    for r, wdt in ((44, 9), (28, 9), (10, 10)):
        d.arc((cx - r, cy - r, cx + r, cy + r), start=225, end=315, fill=INK, width=wdt)
    # Batterie
    bx = width - 130
    d.rounded_rectangle((bx, height // 2 - 18, bx + 78, height // 2 + 18), radius=10, outline=INK, width=4)
    d.rounded_rectangle((bx + 6, height // 2 - 12, bx + 60, height // 2 + 12), radius=6, fill=INK)
    d.rounded_rectangle((bx + 80, height // 2 - 7, bx + 86, height // 2 + 7), radius=3, fill=INK)
    return bar


def phone(shot_path):
    """La capture (390 × 844 à 3×) habillée en iPhone, au même facteur 3."""
    shot = Image.open(shot_path).convert('RGB')
    sw, sh = shot.size
    top = 3 * 54
    bg = shot.getpixel((sw // 2, 6))
    screen = Image.new('RGB', (sw, sh + top), bg)
    screen.paste(status_bar(sw, top, bg), (0, 0))
    screen.paste(shot, (0, top))
    # Coins de l'écran
    radius = 3 * 55
    mask = Image.new('L', screen.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, sw - 1, sh + top - 1), radius=radius, fill=255)
    bezel = 3 * 12
    body = Image.new('RGBA', (sw + 2 * bezel, sh + top + 2 * bezel), (0, 0, 0, 0))
    d = ImageDraw.Draw(body)
    d.rounded_rectangle((0, 0, body.width - 1, body.height - 1), radius=radius + bezel, fill=(46, 36, 30, 255))
    d.rounded_rectangle((3, 3, body.width - 4, body.height - 4), radius=radius + bezel - 3, outline=(92, 76, 66, 255), width=3)
    body.paste(screen, (bezel, bezel), mask)
    # Dynamic Island
    iw, ih = 3 * 126, 3 * 37
    ix, iy = bezel + (sw - iw) // 2, bezel + 3 * 11
    d.rounded_rectangle((ix, iy, ix + iw, iy + ih), radius=ih // 2, fill=(14, 11, 9, 255))
    return body


# --- argile -------------------------------------------------------------------

def shadow_of(layer, blur=40, offset=(0, 30), alpha=0.28):
    """L'ombre portée d'un calque à transparence : brune, comme dans l'app."""
    a = layer.split()[-1].point(lambda v: int(v * alpha))
    sh = Image.new('RGBA', layer.size, SHADOW + (0,))
    sh.putalpha(a)
    sh = sh.filter(ImageFilter.GaussianBlur(blur))
    return sh, offset


def paste_with_shadow(canvas, layer, pos, blur=40, offset=(0, 30), alpha=0.28):
    sh, off = shadow_of(layer, blur, offset, alpha)
    pad = blur * 3
    big = Image.new('RGBA', (layer.width + 2 * pad, layer.height + 2 * pad), (0, 0, 0, 0))
    big.alpha_composite(sh, (pad + off[0], pad + off[1]))
    canvas.alpha_composite(big, (pos[0] - pad, pos[1] - pad))
    canvas.alpha_composite(layer, pos)


def clay_card(size, radius, color=SURFACE):
    """Une carte d'argile comme celles de l'app : l'aplat, un reflet en haut
    à gauche, une ombre en bas à droite, rognés à la forme. Le calque rendu
    est transparent hors de la carte ; l'ombre portée se pose à part."""
    w, h = size
    mask = Image.new('L', (w, h), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, w - 1, h - 1), radius=radius, fill=255)
    layer = Image.new('RGBA', (w, h), color + (255,))

    def rim(dx, dy, blur):
        shifted = Image.new('L', (w, h), 0)
        shifted.paste(mask, (dx, dy))
        m = Image.fromarray(np.clip(np.asarray(mask).astype(int) - np.asarray(shifted).astype(int), 0, 255).astype(np.uint8), 'L')
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


def place_phone(canvas, shot_path, width=1010, y=1010, angle=0.0, x=None):
    ph = phone(shot_path)
    scale = width / ph.width
    ph = ph.resize((width, int(ph.height * scale)), Image.LANCZOS)
    if angle:
        ph = ph.rotate(angle, resample=Image.BICUBIC, expand=True)
    x = (W - ph.width) // 2 if x is None else x
    paste_with_shadow(canvas, ph, (x, y), blur=60, offset=(14, 50), alpha=0.34)
    return (x, y, ph.width, ph.height, scale)


def place_clay(canvas, index, size, pos):
    obj = Image.open(os.path.join(CLAY, f'onboarding_{index}.png')).convert('RGBA').resize((size, size), Image.LANCZOS)
    paste_with_shadow(canvas, obj, pos, blur=50, offset=(10, 40), alpha=0.24)


def sticker(canvas, shot_path, box, width, pos, radius=54, angle=0.0):
    """Un morceau d'interface découpé dans la capture et posé en avant."""
    shot = Image.open(shot_path).convert('RGB')
    crop = shot.crop(box)
    scale = width / crop.width
    crop = crop.resize((width, int(crop.height * scale)), Image.LANCZOS)
    mask = Image.new('L', crop.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, crop.width - 1, crop.height - 1), radius=radius, fill=255)
    layer = Image.new('RGBA', crop.size, (0, 0, 0, 0))
    layer.paste(crop, (0, 0), mask)
    if angle:
        layer = layer.rotate(angle, resample=Image.BICUBIC, expand=True)
    paste_with_shadow(canvas, layer, pos, blur=45, offset=(10, 34), alpha=0.30)


# --- la carte d'identification ----------------------------------------------------

# Une photo CC0 (iNaturalist, observation 359128431, photo 655212161) qui
# n'est pas dans le jeu d'entraînement, et ce que le modèle livré en dit.
# Ce sont ses vrais résultats, pas une maquette : les recalculer avec
#   python3 store/ident/score.py store/ident/ficus-lyrata.jpg
# après chaque nouveau modèle.
IDENT_PHOTO = os.path.join(HERE, 'ident', 'ficus-lyrata.jpg')
IDENT_RESULTS = [('Ficus lyrata', 0.804), ('Epipremnum aureum', 0.063), ('Euphorbia lactea', 0.039)]


def model_classes():
    with open(os.path.join(ROOT, 'assets', 'model', 'model.json')) as f:
        return json.load(f)['classes']


def common_names(lang):
    with open(os.path.join(ROOT, 'tools', 'plant_dataset', 'plants.csv'), newline='', encoding='utf-8') as f:
        return {r['scientific_name']: r.get(f'common_{lang}', '') for r in csv.DictReader(f)}


def ring(d, center, r, value, width=6):
    """L'anneau de score des propositions : la part pleine en sauge."""
    x, y = center
    d.arc((x - r, y - r, x + r, y + r), 0, 360, fill=SURFACE_MUTED, width=width)
    if value > 0:
        d.arc((x - r, y - r, x + r, y + r), -90, -90 + int(360 * value), fill=SAGE if value >= 0.5 else INK3, width=width)


def ident_card(lang, width=930):
    """La feuille « Est-ce bien… » de l'app, redessinée à plat avec ses
    vraies propositions : la photo, puis une ligne par espèce avec son
    score, son nom, et le bouton « Utiliser »."""
    names = common_names(lang)
    title = {'fr': 'Est-ce bien…', 'en': 'Is it…'}[lang]
    hint = {'fr': 'Reconnu sur votre appareil.', 'en': 'Recognised on your device.'}[lang]
    use = {'fr': 'Utiliser', 'en': 'Use'}[lang]
    pad, row_h = 44, 132
    photo_h = 520
    height = pad + 84 + photo_h + 36 + 52 + 20 + row_h * len(IDENT_RESULTS) + pad
    card = clay_card((width, height), 48)
    d = ImageDraw.Draw(card)
    d.text((pad, pad + 6), title, font=hand(56, 600), fill=INK)
    # La photo, contenue et arrondie
    photo = Image.open(IDENT_PHOTO).convert('RGB')
    pw = width - 2 * pad
    scale = max(pw / photo.width, photo_h / photo.height)
    photo = photo.resize((int(photo.width * scale), int(photo.height * scale)), Image.LANCZOS)
    photo = photo.crop(((photo.width - pw) // 2, (photo.height - photo_h) // 2, (photo.width - pw) // 2 + pw, (photo.height - photo_h) // 2 + photo_h))
    pm = Image.new('L', photo.size, 0)
    ImageDraw.Draw(pm).rounded_rectangle((0, 0, pw - 1, photo_h - 1), radius=36, fill=255)
    y = pad + 84
    card.paste(photo, (pad, y), pm)
    y += photo_h + 36
    d.text((pad, y), hint, font=font('Medium', 34), fill=INK2)
    y += 52 + 20
    # Les propositions, dans un groupe d'argile plus clair
    group = clay_card((width - 2 * pad, row_h * len(IDENT_RESULTS)), 36, color=(255, 252, 246))
    card.alpha_composite(group, (pad, y))
    d = ImageDraw.Draw(card)
    for i, (name, score) in enumerate(IDENT_RESULTS):
        cy = y + i * row_h + row_h // 2
        ring(d, (pad + 60, cy), 30, score)
        d.text((pad + 60, cy), str(round(score * 100)), font=font('Bold', 22), fill=INK, anchor='mm')
        common = names.get(name, '')
        d.text((pad + 120, cy - (26 if common else 0)), name, font=font('SemiBold', 38), fill=INK, anchor='lm')
        if common:
            d.text((pad + 120, cy + 26), common, font=font('Medium', 30), fill=INK2, anchor='lm')
        # Le bouton tonal « Utiliser »
        bw, bh = 176, 68
        bx = width - pad - 28 - bw
        pill = clay_card((bw, bh), bh // 2, color=(228, 239, 230))
        card.alpha_composite(pill, (bx, cy - bh // 2))
        d = ImageDraw.Draw(card)
        d.text((bx + bw // 2, cy), use, font=font('SemiBold', 30), fill=SAGE, anchor='mm')
        if i < len(IDENT_RESULTS) - 1:
            d.line((pad + 120, y + (i + 1) * row_h, width - pad - 28, y + (i + 1) * row_h), fill=(230, 217, 200), width=2)
    return card


# --- les six visuels ---------------------------------------------------------

COPY = {
    'fr': [
        ('Toutes vos plantes,\nau même endroit', "Photos, espèce, emplacement, et l'histoire de chacune."),
        ("Chaque matin,\nce qu'il y a à faire", 'Arrosé ? Un geste, et c’est noté.'),
        ("Une fiche d'entretien\npour chaque plante", 'Lumière, arrosage, engrais, rempotage : les bons repères, selon la saison.'),
        ('Lieux, calendrier,\ninventaire', 'Votre jardin s’organise tout seul.'),
        ('Tout reste sur\nvotre téléphone', 'Sans compte obligatoire, sans publicité. Vos données vous appartiennent.'),
        ('Quelle est\ncette plante ?', 'Une photo, et l’app propose l’espèce parmi {n}. Ça se passe sur votre téléphone : rien n’est envoyé.'),
    ],
    'en': [
        ('All your plants,\nin one place', 'Photos, species, room, and each one’s story.'),
        ('Each morning,\nwhat needs doing', 'Watered? One tap, and it’s noted.'),
        ('A care guide\nfor every plant', 'Light, watering, feeding, repotting: the right cues, season by season.'),
        ('Rooms, calendar,\ninventory', 'Your garden organises itself.'),
        ('Everything stays\non your phone', 'No account required, no ads. Your data is yours.'),
        ('What plant\nis this?', 'One photo, and the app suggests the species out of {n}. It happens on your phone: nothing is sent.'),
    ],
}


# La ligne « Calathea · Arroser » dans la capture d'Aujourd'hui, par langue.
TODAY_ROW = {'fr': (54, 1636, 1116, 1916), 'en': (54, 1574, 1116, 1856)}


def build(shots, out, lang):
    os.makedirs(out, exist_ok=True)
    n = model_classes()
    copy = [(t, s.replace('{n}', f'{n:,}'.replace(',', ' '))) for t, s in COPY[lang]]
    size = title_size([t for t, _ in copy])
    S = lambda name: os.path.join(shots, f'{name}.png')

    # 1 — la collection
    img = background('sage')
    draw_text_block(img, *copy[0], size)
    place_phone(img, S('plants'), y=1040)
    place_clay(img, 1, 560, (760, 640))
    img.convert('RGB').save(os.path.join(out, '1.png'), optimize=True)

    # 2 — aujourd'hui
    img = background('water')
    draw_text_block(img, *copy[1], size)
    place_phone(img, S('today'), y=1060, angle=-3.5)
    place_clay(img, 2, 520, (60, 700))
    # la ligne « Calathea · Arroser », découpée dans la capture
    # La ligne monte en anglais : la carte de rappel y tient sur une ligne de moins.
    sticker(img, S('today'), TODAY_ROW[lang], 900, (330, 2060), angle=4)
    img.convert('RGB').save(os.path.join(out, '2.png'), optimize=True)

    # 3 — la fiche d'entretien
    img = background('sun')
    draw_text_block(img, *copy[2], size)
    place_phone(img, S('care'), y=1080)
    place_clay(img, 3, 540, (720, 690))
    img.convert('RGB').save(os.path.join(out, '3.png'), optimize=True)

    # 4 — le jardin
    img = background('terracotta')
    draw_text_block(img, *copy[3], size)
    place_phone(img, S('garden-calendar'), y=1060, angle=3.5)
    place_clay(img, 4, 540, (40, 660))
    # quatre tuiles du tableau de bord
    sticker(img, S('dashboard'), (54, 215, 1116, 905), 660, (640, 1880), angle=-4)
    img.convert('RGB').save(os.path.join(out, '4.png'), optimize=True)

    # 5 — les données
    img = background('rose')
    draw_text_block(img, *copy[4], size)
    place_phone(img, S('backup'), y=1080)
    place_clay(img, 5, 640, (620, 580))
    img.convert('RGB').save(os.path.join(out, '5.png'), optimize=True)

    # 6 — l'identification, sur l'appareil
    img = background('earth')
    draw_text_block(img, *copy[5], size)
    place_phone(img, S('plant'), y=1120, angle=-3)
    card = ident_card(lang).rotate(3, resample=Image.BICUBIC, expand=True)
    paste_with_shadow(img, card, (150, 1560), blur=55, offset=(12, 44), alpha=0.32)
    img.convert('RGB').save(os.path.join(out, '6.png'), optimize=True)


if __name__ == '__main__':
    ensure_fonts()
    build(sys.argv[1], sys.argv[2], sys.argv[3] if len(sys.argv) > 3 else 'fr')
