#!/usr/bin/env python3
"""Compose les visuels App Store (1290 × 2796) à partir des captures réelles.

Chaque visuel : un fond pastel de la charte avec deux souffles de couleur,
un titre en Inter, un iPhone dessiné (bordure, Dynamic Island, barre d'état)
qui contient la capture, un objet 3D de la série clay, et parfois un éclat
d'interface découpé dans la capture et posé en avant, avec son ombre.

Usage : compose.py <dossier captures> <dossier sortie> [fr|en]
"""
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

W, H = 1290, 2796
HERE = os.path.dirname(os.path.abspath(__file__))
FONTS = os.path.join(HERE, 'fonts/inter/extras/ttf')
CLAY = os.path.join(HERE, '..', 'assets', 'onboarding')
INTER_ZIP = 'https://github.com/rsms/inter/releases/download/v4.1/Inter-4.1.zip'


def ensure_fonts():
    """Inter (SIL OFL) n'est pas dans le dépôt : on la télécharge au besoin."""
    if os.path.isdir(FONTS):
        return
    import io
    import urllib.request
    import zipfile
    print('téléchargement d\'Inter…', file=sys.stderr)
    data = urllib.request.urlopen(INTER_ZIP, timeout=120).read()
    zipfile.ZipFile(io.BytesIO(data)).extractall(os.path.join(HERE, 'fonts', 'inter'))

INK = (26, 31, 27)
INK2 = (102, 112, 106)
CANVAS = (243, 246, 241)
TINTS = {
    'sage': ((46, 139, 87), (227, 242, 232)),
    'water': ((62, 127, 196), (227, 238, 250)),
    'sun': ((201, 154, 0), (255, 244, 211)),
    'terracotta': ((200, 117, 42), (251, 238, 221)),
    'rose': ((209, 80, 108), (253, 232, 238)),
}


def font(name, size):
    return ImageFont.truetype(os.path.join(FONTS, f'Inter-{name}.ttf'), size)


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


def background(tint):
    strong, soft = TINTS[tint]
    base = tuple(int(s * 0.55 + c * 0.45) for s, c in zip(soft, CANVAS))
    img = Image.new('RGBA', (W, H), base + (255,))
    img.alpha_composite(radial((W, H), (1180, 380), 980, strong, 0.22))
    img.alpha_composite(radial((W, H), (120, 2500), 900, (255, 255, 255), 0.55))
    img.alpha_composite(radial((W, H), (300, 1500), 700, strong, 0.08))
    return img


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
    chaque titre tient dans la largeur. Les cinq visuels restent accordés."""
    draw = ImageDraw.Draw(Image.new('RGB', (10, 10)))
    size = 118
    lines = [l for t in titles for l in t.split('\n')]
    while size > 84 and max(draw.textlength(l, font=font('Bold', size)) for l in lines) > width:
        size -= 2
    return size


def draw_text_block(img, title, subtitle, size, x=96, y=200, width=1110):
    """Le titre est coupé à la main (retours à la ligne dans la copie)."""
    draw = ImageDraw.Draw(img)
    lines = title.split('\n')
    t_font = font('Bold', size)
    for line in lines:
        draw.text((x, y), line, font=t_font, fill=INK)
        y += int(size * 1.12)
    y += 26
    s_font = font('Medium', 52)
    for line in wrap(draw, subtitle, s_font, width - 40):
        draw.text((x + 4, y), line, font=s_font, fill=INK2)
        y += 68
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
    d.rounded_rectangle((0, 0, body.width - 1, body.height - 1), radius=radius + bezel, fill=(20, 22, 21, 255))
    d.rounded_rectangle((3, 3, body.width - 4, body.height - 4), radius=radius + bezel - 3, outline=(70, 74, 72, 255), width=3)
    body.paste(screen, (bezel, bezel), mask)
    # Dynamic Island
    iw, ih = 3 * 126, 3 * 37
    ix, iy = bezel + (sw - iw) // 2, bezel + 3 * 11
    d.rounded_rectangle((ix, iy, ix + iw, iy + ih), radius=ih // 2, fill=(8, 9, 9, 255))
    return body


def shadow_of(layer, blur=40, offset=(0, 30), alpha=0.28):
    """L'ombre portée d'un calque à transparence."""
    a = layer.split()[-1].point(lambda v: int(v * alpha))
    sh = Image.new('RGBA', layer.size, (0, 0, 0, 0))
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


def place_phone(canvas, shot_path, width=1010, y=1010, angle=0.0, x=None):
    ph = phone(shot_path)
    scale = width / ph.width
    ph = ph.resize((width, int(ph.height * scale)), Image.LANCZOS)
    if angle:
        ph = ph.rotate(angle, resample=Image.BICUBIC, expand=True)
    x = (W - ph.width) // 2 if x is None else x
    paste_with_shadow(canvas, ph, (x, y), blur=60, offset=(0, 50), alpha=0.30)
    return (x, y, ph.width, ph.height, scale)


def place_clay(canvas, index, size, pos):
    obj = Image.open(os.path.join(CLAY, f'onboarding_{index}.png')).convert('RGBA').resize((size, size), Image.LANCZOS)
    paste_with_shadow(canvas, obj, pos, blur=50, offset=(0, 40), alpha=0.22)


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
    paste_with_shadow(canvas, layer, pos, blur=45, offset=(0, 34), alpha=0.26)


# --- les cinq visuels ---------------------------------------------------------

COPY = {
    'fr': [
        ('Toutes vos plantes,\nau même endroit', "Photos, espèce, emplacement — et l'histoire de chacune."),
        ("Chaque matin,\nce qu'il y a à faire", 'Arrosé ? Un geste, et c’est noté.'),
        ("Une fiche d'entretien\npour chaque plante", 'Lumière, arrosage, engrais, rempotage : les bons repères, selon la saison.'),
        ('Lieux, calendrier,\ninventaire', 'Votre jardin s’organise tout seul.'),
        ('Tout reste sur\nvotre téléphone', 'Sans compte obligatoire, sans publicité. Vos données vous appartiennent.'),
    ],
    'en': [
        ('All your plants,\nin one place', 'Photos, species, room — and each one’s story.'),
        ('Each morning,\nwhat needs doing', 'Watered? One tap, and it’s noted.'),
        ('A care guide\nfor every plant', 'Light, watering, feeding, repotting: the right cues, season by season.'),
        ('Rooms, calendar,\ninventory', 'Your garden organises itself.'),
        ('Everything stays\non your phone', 'No account required, no ads. Your data is yours.'),
    ],
}


def build(shots, out, lang):
    os.makedirs(out, exist_ok=True)
    copy = COPY[lang]
    size = title_size([t for t, _ in copy])
    S = lambda name: os.path.join(shots, f'{name}.png')

    # 1 — la collection
    img = background('sage')
    draw_text_block(img, *copy[0], size)
    place_phone(img, S('plants'), y=1040)
    place_clay(img, 1, 560, (760, 640))
    img.convert('RGB').save(os.path.join(out, f'{lang}-1.png'), optimize=True)

    # 2 — aujourd'hui
    img = background('water')
    draw_text_block(img, *copy[1], size)
    place_phone(img, S('today'), y=1060, angle=-3.5)
    place_clay(img, 2, 520, (60, 700))
    # la ligne « Calathea · Arroser », découpée dans la capture
    sticker(img, S('today'), (54, 741, 1110, 1005), 900, (400, 1600), angle=4)
    img.convert('RGB').save(os.path.join(out, f'{lang}-2.png'), optimize=True)

    # 3 — la fiche d'entretien
    img = background('sun')
    draw_text_block(img, *copy[2], size)
    place_phone(img, S('care'), y=1080)
    place_clay(img, 3, 540, (720, 690))
    img.convert('RGB').save(os.path.join(out, f'{lang}-3.png'), optimize=True)

    # 4 — le jardin
    img = background('terracotta')
    draw_text_block(img, *copy[3], size)
    place_phone(img, S('garden-calendar'), y=1060, angle=3.5)
    place_clay(img, 4, 540, (40, 660))
    # deux tuiles du tableau de bord
    sticker(img, S('dashboard'), (54, 210, 1116, 930), 660, (640, 1880), angle=-4)
    img.convert('RGB').save(os.path.join(out, f'{lang}-4.png'), optimize=True)

    # 5 — les données
    img = background('rose')
    draw_text_block(img, *copy[4], size)
    place_phone(img, S('backup'), y=1080)
    place_clay(img, 5, 640, (620, 580))
    img.convert('RGB').save(os.path.join(out, f'{lang}-5.png'), optimize=True)


if __name__ == '__main__':
    ensure_fonts()
    build(sys.argv[1], sys.argv[2], sys.argv[3] if len(sys.argv) > 3 else 'fr')
