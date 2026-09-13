#!/usr/bin/env python3
"""Compose les visuels App Store (1290 × 2796) à partir des captures réelles.

Chaque visuel : un papier crème teinté, avec son grain, un titre tracé en
Shantell Sans (la police « main » de l'app), un iPhone dessiné (bordure,
Dynamic Island, barre d'état) qui montre la capture presque entière, et un
objet 3D de la série clay posé au pied du téléphone, devant lui. L'écran est
ce qu'on vend : rien ne le recouvre, à part l'objet sur son coin bas. Les
ombres sont brunes, jamais noires : c'est la lumière de l'atelier, pas celle
d'un studio.

Usage : compose.py <dossier captures> <dossier sortie> [fr|en]
"""
import csv
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

def status_bar(width, height, bg, INK):
    """Une barre d'état iOS : l'heure d'Apple, réseau, wifi, batterie.
    Sans [bg], la barre est transparente, à poser sur une photo."""
    bar = Image.new('RGBA', (width, height), bg + (255,) if bg else (0, 0, 0, 0))
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


def phone(shot, scrim=0.0, sheet=None):
    """La capture (390 × 844 à 3×) habillée en iPhone, au même facteur 3.
    [shot] est un chemin, ou une capture déjà retouchée. Avec [scrim] et
    [sheet], une feuille modale est posée sur l'écran entier, barre d'état
    comprise, comme l'app le fait."""
    shot = (Image.open(shot) if isinstance(shot, str) else shot).convert('RGB')
    sw, sh = shot.size
    top = 3 * 54
    screen = Image.new('RGBA', (sw, sh + top))
    strip = shot.crop((0, 0, sw, top))
    if max(abs(a - b) for a, b in zip(strip.getpixel((sw // 2, 6)), CANVAS)) < 24:
        # Le papier de l'app : la barre d'état est du même papier.
        bar = status_bar(sw, top, strip.getpixel((sw // 2, 6)), INK)
    else:
        # Une photo en tête de page : elle continue sous la barre d'état, en
        # miroir et un peu floue, assombrie vers le haut, et les icônes
        # passent en blanc dessus.
        bar = strip.transpose(Image.FLIP_TOP_BOTTOM).filter(ImageFilter.GaussianBlur(6)).convert('RGBA')
        veil = np.zeros((top, sw, 4), dtype=np.uint8)
        veil[..., 3] = np.linspace(120, 30, top).astype(np.uint8)[:, None]
        bar.alpha_composite(Image.fromarray(veil, 'RGBA'))
        bar.alpha_composite(status_bar(sw, top, None, (255, 255, 255)))
    screen.paste(bar, (0, 0))
    screen.paste(shot, (0, top))
    if scrim:
        # La barrière modale, brune comme les ombres
        screen.alpha_composite(Image.new('RGBA', screen.size, SHADOW + (int(255 * scrim),)))
    if sheet is not None:
        screen.alpha_composite(sheet, (0, screen.height - sheet.height))
    screen = screen.convert('RGB')
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


def place_phone(canvas, shot, y, width=1030, **modal):
    """Le téléphone, droit et centré, assez bas pour que le titre respire et
    assez haut pour que l'écran se lise presque en entier : le bas du
    téléphone sort du cadre, comme sur les fiches d'Apple."""
    ph = phone(shot, **modal)
    scale = width / ph.width
    ph = ph.resize((width, int(ph.height * scale)), Image.LANCZOS)
    x = (W - ph.width) // 2
    paste_with_shadow(canvas, ph, (x, y), blur=60, offset=(14, 50), alpha=0.34)


def place_clay(canvas, name, size, y, phone_width=1030):
    """Un objet de la série clay, derrière le téléphone, qui dépasse en haut
    à droite dans le vide gardé entre le sous-titre et l'écran. Il ne cache
    rien : c'est le téléphone qui le cache à moitié. Il reste dans la largeur
    du téléphone, pour qu'aucun bout n'en ressorte sur le côté."""
    obj = Image.open(os.path.join(CLAY, name)).convert('RGBA').resize((size, size), Image.LANCZOS)
    x = (W + phone_width) // 2 - 36 - size
    paste_with_shadow(canvas, obj, (x, y), blur=50, offset=(10, 40), alpha=0.26)


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
}
# La case « Prendre une photo » de l'étape Photo, dans la capture (3×).
PHOTO_BOX = (60, 541, 1110, 2068)


def common_names(lang):
    with open(os.path.join(ROOT, 'tools', 'plant_dataset', 'plants.csv'), newline='', encoding='utf-8') as f:
        return {r['scientific_name']: r.get(f'common_{lang}', '') for r in csv.DictReader(f)}


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


def identification_shot(shot_path):
    """L'étape Photo de l'ajout, une fois la photo prise : elle remplit la
    case du viseur. La page s'assombrit et la feuille « Espèce » monte
    ensuite, dans le téléphone."""
    shot = Image.open(shot_path).convert('RGB')
    x0, y0, x1, y1 = PHOTO_BOX
    pw, ph = x1 - x0, y1 - y0
    photo = Image.open(IDENT_PHOTO).convert('RGB')
    scale = max(pw / photo.width, ph / photo.height)
    photo = photo.resize((int(photo.width * scale), int(photo.height * scale)), Image.LANCZOS)
    ox, oy = (photo.width - pw) // 2, (photo.height - ph) // 2
    photo = photo.crop((ox, oy, ox + pw, oy + ph))
    pm = Image.new('L', photo.size, 0)
    ImageDraw.Draw(pm).rounded_rectangle((0, 0, pw - 1, ph - 1), radius=3 * 24, fill=255)
    shot.paste(photo, (x0, y0), pm)
    return shot


# --- les sept visuels ---------------------------------------------------------

# Le registre des fiches App Store : un titre court, puis un fragment en
# minuscules, sans point. Pas de phrase.
COPY = {
    'fr': [
        ("Chaque matin,\nce qu'il y a à faire", 'les soins du jour, à cocher'),
        ('Toutes vos plantes,\nau même endroit', 'avec leur photo, leur espèce et leur pièce'),
        ('Chaque plante\na sa page', 'photos, prochains soins, journal'),
        ("Une fiche d'entretien\npour chaque espèce", 'arrosage, lumière, engrais, rempotage'),
        ('Quelle est\ncette plante ?', 'une photo suffit, même sans réseau'),
        ('Lieux, calendrier,\ninventaire', 'pour un appartement ou un jardin entier'),
        ('Tout reste sur\nvotre téléphone', 'sans compte, sans publicité'),
    ],
    'en': [
        ('Each morning,\nwhat needs doing', 'the day’s care, to tick off'),
        ('All your plants,\nin one place', 'with their photo, species and room'),
        ('Every plant\nhas its page', 'photos, upcoming care, journal'),
        ('A care guide\nfor every species', 'watering, light, feeding, repotting'),
        ('What plant\nis this?', 'one photo is enough, even offline'),
        ('Rooms, calendar,\ninventory', 'for a whole flat or garden'),
        ('Everything stays\non your phone', 'no account, no ads'),
    ],
}

SCENES = [
    ('today', 'water', 'onboarding_2.png'),
    ('plants', 'sage', 'collection_monstera.webp'),
    ('plant', 'terracotta', 'collection_ronde.webp'),
    ('care', 'sun', 'onboarding_3.png'),
    ('add-plant', 'earth', 'collection_caoutchouc.webp'),
    ('garden-calendar', 'lavender', 'onboarding_7.png'),
    ('profile', 'rose', 'onboarding_5.png'),
]
# Chaque visuel : la capture, la teinte du papier, l'objet d'argile qui dépasse.


# Le téléphone tient en entier dans le cadre, écran complet : sa largeur, le
# vide entre le sous-titre et lui (où l'objet d'argile dépasse), et la taille
# de l'objet.
PHONE_WIDTH, PHONE_GAP, PHONE_CLAY = 920, 200, 560


def build(shots, out, lang):
    os.makedirs(out, exist_ok=True)
    copy = COPY[lang]
    size = title_size([t for t, _ in copy])
    for i, ((title, subtitle), (name, tint, clay)) in enumerate(zip(copy, SCENES), start=1):
        img = background(tint)
        bottom = draw_text_block(img, title, subtitle, size)
        shot = os.path.join(shots, f'{name}.png')
        modal = {}
        if name == 'add-plant':
            shot = identification_shot(shot)
            modal = {'scrim': 0.36, 'sheet': ident_sheet(lang)}
        place_clay(img, clay, PHONE_CLAY, bottom - 30, PHONE_WIDTH)
        place_phone(img, shot, y=bottom + PHONE_GAP, width=PHONE_WIDTH, **modal)
        img.convert('RGB').save(os.path.join(out, f'{i}.png'), optimize=True)


if __name__ == '__main__':
    ensure_fonts()
    build(sys.argv[1], sys.argv[2], sys.argv[3] if len(sys.argv) > 3 else 'fr')
