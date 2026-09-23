"""Le kit marketing d'Auxine : profils, bannières, publications et stories,
aux formats courants des réseaux.

    python3 marketing/kit.py                  # tout, dans marketing/fr/
    python3 marketing/kit.py store/shots-fr   # avec un autre jeu de captures

Les captures viennent de `store/shots-fr/` : celles du web
(`store/capture.mjs`) ici, celles du simulateur sur un Mac
(`store/capture_ios.sh`) — le script les reconnaît à leur taille. Les
couleurs, les polices, l'appareil et les objets 3D sont ceux des visuels du
magasin (`store/compose.py`), dont ce script reprend les outils.
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, '..')
sys.path.insert(0, os.path.join(ROOT, 'store'))
os.chdir(ROOT)

import compose as C  # noqa: E402
from PIL import Image, ImageDraw, ImageFilter  # noqa: E402

C.ensure_fonts()
C.use('iphone')

SHOTS = sys.argv[1] if len(sys.argv) > 1 else 'store/shots-fr'
OUT = os.path.join(HERE, 'fr')
POT = 'assets/icon/rendu/lancement.png'
OBJ = 'assets/onboarding/collection_{}.webp'

# --- les thèmes ---------------------------------------------------------------
# Un thème : le titre (coupé à la main), la phrase dessous, la couleur du
# fond, la capture et l'objet qui s'y pose. Un objet ne se pose jamais sur
# sa propre couleur.
THEMES = {
    'marque': dict(title='Le carnet\nde vos plantes.', sub='Soins, identification, diagnostic et journal photo.',
                   tint='sage', shot='today', obj=POT),
    'prix': dict(big=True, title='0,99 €', lead='Un seul achat.\nSans abonnement.', sub=None, tint='sun', shot='plants',
                 obj=OBJ.format('monstera'),
                 pills=['Toutes les fonctions', 'Sans publicité', 'Sans achat intégré', 'Plantes illimitées']),
    'iris': dict(title='Quelle est\ncette plante ?', sub='Une photo suffit, même sans réseau.', tint='lavender',
                 shot='capture', obj=OBJ.format('ronde')),
    'soins': dict(title='Chaque matin,\nles soins du jour.', sub='Arrosage, engrais, rempotage : à cocher en un geste.',
                  tint='water', shot='today', obj=OBJ.format('sansevieria')),
    'diagnostic': dict(title='Un diagnostic\nsur photo.', sub='Plus de 200 troubles, ravageurs et maladies.',
                       tint='night', shot='diagnosis', obj=OBJ.format('monstera')),
    'fiche': dict(title='Une fiche\npar espèce.', sub='Arrosage selon la saison, lumière, engrais, rempotage.',
                  tint='sage', shot='care', obj=OBJ.format('ronde')),
    'collection': dict(title='Toutes vos plantes,\nau même endroit.', sub='Avec leur photo, leur espèce et leur pièce.',
                       tint='rose', shot='plants', obj=OBJ.format('sansevieria')),
    'calendrier': dict(title='Le jardin\nen calendrier.', sub='Soins à venir, tâches, lieux et inventaire.',
                       tint='terracotta', shot='garden-calendar', obj=OBJ.format('caoutchouc')),
    'hors-ligne': dict(title='Vos plantes\nrestent chez vous.', sub='Sans compte, vos données restent sur votre appareil.',
                       tint='night', shot=None, obj=POT),
}


# La sortie : l'annonce, l'attente, le compte à rebours, le merci, et un
# modèle pour chaque mise à jour. Pas de date : elle se met dans le texte
# qui accompagne l'image.
SORTIE = {
    'bientot': dict(title='Bientôt\nsur l’App Store.', sub='Auxine, le carnet de vos plantes.', tint='night', shot=None, obj=POT),
    'j-3': dict(big=True, title='J-3', lead='Auxine arrive\nsur l’App Store.', sub=None, tint='water', shot=None, obj=POT),
    'j-2': dict(big=True, title='J-2', lead='Auxine arrive\nsur l’App Store.', sub=None, tint='lavender', shot=None, obj=POT),
    'j-1': dict(big=True, title='J-1', lead='Auxine arrive\nsur l’App Store.', sub=None, tint='rose', shot=None, obj=POT),
    'disponible': dict(title='Auxine est\ndisponible.', sub='Sur l’App Store, pour iPhone et iPad.', tint='sage', shot=None, obj=POT,
                       pills=['0,99 €', 'Un seul achat', 'Sans abonnement']),
    'disponible-ecran': dict(title='Auxine est\ndisponible.', sub='Sur l’App Store, pour iPhone et iPad.', tint='sun', shot='today',
                             obj=OBJ.format('monstera'), pills=['0,99 €', 'Un seul achat', 'Sans abonnement']),
    'merci': dict(big=True, title='Merci.', lead='Pour votre accueil\net vos retours.', sub=None, tint='sun', shot=None, obj=POT),
    'nouveautes': dict(title='Nouveau\ndans Auxine.', sub='La mise à jour est sur l’App Store.', tint='terracotta', shot='today',
                       obj=OBJ.format('caoutchouc')),
}


# Le prix en francs suisses : sur l'App Store suisse, le palier de 0,99 €
# vaut 1 CHF. Chaque image qui dit le prix a sa version « -chf ».
def en_chf(t):
    t = dict(t)
    for k in ('title', 'lead', 'sub'):
        if t.get(k):
            t[k] = t[k].replace('0,99 €', '1 CHF')
    if t.get('pills'):
        t['pills'] = [p.replace('0,99 €', '1 CHF') for p in t['pills']]
    return t


THEMES['prix-chf'] = en_chf(THEMES['prix'])
for k in ('disponible', 'disponible-ecran'):
    SORTIE[f'{k}-chf'] = en_chf(SORTIE[k])
THEMES.update(SORTIE)


# --- les outils ------------------------------------------------------------------

def fond(size, tint):
    """L'aplat du thème et les deux disques pâles des têtes vertes."""
    w, h = size
    base, ink, ink2 = C.TINTS[tint]
    img = Image.new('RGBA', size, base + (255,))
    discs = Image.new('RGBA', size, (255, 255, 255, 0))
    d = ImageDraw.Draw(discs)
    m = max(w, h)
    for cx, cy, r, a in ((w * 1.02, -h * 0.04, m * 0.42, 24), (w * 0.94, h * 0.10, m * 0.24, 18)):
        d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(255, 255, 255, a))
    img.alpha_composite(discs)
    return img, ink, ink2


def poser(img, layer, pos, blur=40, offset=(10, 30), alpha=0.26):
    """Pose un calque et son ombre, même quand il déborde du cadre."""
    x, y = int(pos[0]), int(pos[1])
    if alpha:
        a = Image.new('L', img.size, 0)
        a.paste(layer.split()[-1].point(lambda v: int(v * alpha)), (x + offset[0], y + offset[1]))
        ombre = Image.new('RGBA', img.size, (0, 0, 0, 0))
        ombre.putalpha(a.filter(ImageFilter.GaussianBlur(blur)))
        img.alpha_composite(ombre)
    plein = Image.new('RGBA', img.size, (0, 0, 0, 0))
    plein.paste(layer, (x, y), layer)
    img.alpha_composite(plein)


def texte(img, x, y, width, title, sub, size, ink, ink2, align='left', lead=None):
    """Le titre en Bricolage, la phrase en Inter. Un titre géant (le prix)
    prend dessous une seconde ligne en Bricolage, [lead]. Rend le bas du bloc."""
    d = ImageDraw.Draw(img)
    # Un mot ne se coupe pas : trop large pour la place, le titre rapetisse.
    while max(d.textlength(m, font=C.display(size)) for m in title.split()) > width:
        size -= 4
    blocs = [(title, C.display(size), 1.06)]
    if lead:
        blocs.append((lead, C.display(int(size * 0.3), 750), 1.1))
    for texte_, f, interligne in blocs:
        for line in texte_.split('\n'):
            for l in C.wrap(d, line, f, width):
                tx = x + (width - d.textlength(l, font=f)) / 2 if align == 'center' else x
                d.text((tx, y), l, font=f, fill=ink)
                y += int(f.size * interligne)
        y += int(f.size * 0.1)
    if sub:
        y += int(size * 0.12)
        s = C.font('Medium', min(46, max(26, int(size * 0.36))))
        for l in C.wrap(d, sub, s, width):
            tx = x + (width - d.textlength(l, font=s)) / 2 if align == 'center' else x
            d.text((tx, y), l, font=s, fill=ink2)
            y += int(s.size * 1.3)
    return y


def pastilles(img, x, y, labels, size, fill, ink, vertical=True, max_x=None):
    d = ImageDraw.Draw(img)
    f = C.font('SemiBold', size)
    h = int(size * 2.1)
    x0 = x
    for label in labels:
        w = d.textlength(label, font=f) + size * 1.9
        if not vertical and max_x and x + w > max_x:
            x, y = x0, y + h + int(size * 0.5)
        d.rounded_rectangle((x, y, x + w, y + h), radius=h // 2, fill=fill)
        d.text((x + size * 0.95, y + h / 2), label, font=f, fill=ink, anchor='lm')
        if vertical:
            y += h + int(size * 0.65)
        else:
            x += w + int(size * 0.5)
    return y + (0 if vertical else h)


def telephone(img, shot, width, x, y, angle=0.0):
    """L'appareil, habillé par compose.py. Une capture du web (390 points de
    large, sans barre d'état) en reçoit une ; celle du simulateur l'a déjà."""
    path = os.path.join(SHOTS, f'{shot}.png')
    device = Image.open(path).size[1] / Image.open(path).size[0] > 2.3
    ph = C.phone(path, device=device)
    ph = ph.resize((width, round(ph.height * width / ph.width)), Image.LANCZOS)
    if angle:
        ph = ph.rotate(angle, resample=Image.BICUBIC, expand=True)
    poser(img, ph, (x, y), blur=max(20, width // 12), offset=(width // 50, width // 14), alpha=0.32)
    return ph.size


def objet(img, path, box, x, y):
    o = C.crisp(path, box=box)
    poser(img, o, (x, y - o.height), blur=max(12, box // 10), offset=(box // 40, box // 14), alpha=0.24)
    return o.size


def objet_sous(img, path, top, bottom, box, align, width, margin=40):
    """L'objet entre le bas du texte ([top]) et [bottom], aussi grand que
    [box] le permet : il ne remonte jamais sur une ligne."""
    o = C.crisp(path, box=int(max(160, min(box, bottom - top))))
    x = (width - o.width) / 2 if align == 'center' else width - o.width - margin
    poser(img, o, (x, bottom - o.height), blur=max(12, o.height // 10), offset=(o.width // 40, o.height // 14), alpha=0.26)


def marque(img, cx, cy, height, ink, ink2, tagline=True):
    """Le pot de l'icône, « Auxine » à côté, et la phrase dessous : le groupe
    centré sur (cx, cy)."""
    d = ImageDraw.Draw(img)
    pot = C.crisp(POT, box=int(height))
    title = C.display(int(height * 0.52))
    sub = C.font('Medium', int(height * 0.12))
    phrase = tagline if isinstance(tagline, str) else 'Le carnet de vos plantes.'
    tw = d.textlength('Auxine', font=title)
    if tagline:
        tw = max(tw, d.textlength(phrase, font=sub))
    gap = height * 0.15
    x0 = cx - (pot.width + gap + tw) / 2
    base = cy + height / 2
    poser(img, pot, (x0, base - pot.getbbox()[3]), blur=int(height * 0.05), offset=(0, int(height * 0.05)), alpha=0.3)
    tx = x0 + pot.width + gap
    d = ImageDraw.Draw(img)
    d.text((tx, cy + height * (0.14 if tagline else 0.2)), 'Auxine', font=title, fill=ink, anchor='ls')
    if tagline:
        d.text((tx + height * 0.02, cy + height * 0.36), phrase, font=sub, fill=ink2, anchor='ls')


def enregistrer(img, name, transparent=False):
    path = os.path.join(OUT, name)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    if transparent:
        img.save(path + '.png', optimize=True)
    else:
        img.convert('RGB').save(path + '.jpg', quality=92, optimize=True, progressive=True)
    print(name)


def encre_pastille(tint):
    """Les pastilles : l'encre sur les fonds clairs, le blanc sur le vert et
    la nuit."""
    return ((255, 255, 255), C.INK) if tint in ('sage', 'night') else (C.INK, C.CANVAS)


# --- les formats ---------------------------------------------------------------

def carre(key, dossier=''):
    """Publication carrée, 1080 × 1080 (Instagram, X, Facebook, LinkedIn)."""
    t = THEMES[key]
    img, ink, ink2 = fond((1080, 1080), t['tint'])
    big = t.get('big')
    if t['shot'] is None:
        y = texte(img, 80, 96, 920, t['title'], t['sub'], 300 if big else 96, ink, ink2, lead=t.get('lead'))
        if t.get('pills'):
            fill, pen = encre_pastille(t['tint'])
            pastilles(img, 80, y + 40, t['pills'], 30, fill, pen)
            objet_sous(img, t['obj'], y + 30, 1080 - 60, 520, 'right', 1080)
        elif big:
            objet_sous(img, t['obj'], y + 30, 1080 - 60, 560, 'right', 1080)
        else:
            objet(img, t['obj'], 560, 1080 - 600, 1080 - 70)
    else:
        y = texte(img, 72, 76, 936, t['title'], t['sub'], 200 if big else 84, ink, ink2, lead=t.get('lead'))
        telephone(img, t['shot'], 470, 1080 - 470 - 30, max(y + 30, 400), -4)
        if t.get('pills'):
            fill, pen = encre_pastille(t['tint'])
            pastilles(img, 72, y + 40, t['pills'], 27, fill, pen)
        else:
            objet(img, t['obj'], 330, 60, 1080 - 50)
    enregistrer(img, f'{dossier}post-carre-{key}')


def portrait(key, dossier=''):
    """Publication 4:5, 1080 × 1350 : la plus grande place dans un fil."""
    t = THEMES[key]
    img, ink, ink2 = fond((1080, 1350), t['tint'])
    big = t.get('big')
    y = texte(img, 72, 84, 936, t['title'], t['sub'], (330 if t['shot'] is None else 250) if big else 96, ink, ink2, lead=t.get('lead'))
    if t['shot'] is None:
        if t.get('pills'):
            fill, pen = encre_pastille(t['tint'])
            pastilles(img, 72, y + 40, t['pills'], 32, fill, pen)
        objet_sous(img, t['obj'], y + 40, 1350 - 70, 640, 'right', 1080)
        enregistrer(img, f'{dossier}post-portrait-{key}')
        return
    top = max(y + 50, 560)
    telephone(img, t['shot'], 560, 1080 - 560 + 20, top, -5)
    if t.get('pills'):
        fill, pen = encre_pastille(t['tint'])
        pastilles(img, 72, min(top + 50, y + 40), t['pills'], 30, fill, pen)
        objet(img, t['obj'], 300, 50, 1350 - 40)
    else:
        objet(img, t['obj'], 360, 50, 1350 - 50)
    enregistrer(img, f'{dossier}post-portrait-{key}')


def story(key, dossier=''):
    """Story et Reels, 1080 × 1920. Le haut (250 px) et le bas (340 px)
    passent sous l'interface : le texte s'en garde."""
    t = THEMES[key]
    img, ink, ink2 = fond((1080, 1920), t['tint'])
    if key == 'marque':
        marque(img, 540, 760, 360, ink, ink2, tagline=False)
        texte(img, 90, 1040, 900, 'Le carnet\nde vos plantes.', 'Soins, identification, diagnostic et journal photo.',
              110, ink, ink2, align='center')
        enregistrer(img, f'story-{key}')
        return
    big = t.get('big')
    y = texte(img, 80, 260, 920, t['title'], t['sub'], (400 if t['shot'] is None else 280) if big else 118, ink, ink2, lead=t.get('lead'))
    if t.get('pills'):
        fill, pen = encre_pastille(t['tint'])
        y = pastilles(img, 80, y + 40, t['pills'], 34, fill, pen, vertical=False, max_x=1000)
    if t['shot'] is None:
        objet_sous(img, t['obj'], y + 80, 1920 - 320, 780, 'center', 1080)
    else:
        telephone(img, t['shot'], 720, 1080 - 720 + 20, max(y + 70, 820), -4)
        objet(img, t['obj'], 300, 0, 1920 - 150)
    enregistrer(img, f'{dossier}story-{key}')


def paysage(key, dossier=''):
    """Publication 16:9, 1600 × 900 (X, LinkedIn, présentation)."""
    t = THEMES[key]
    img, ink, ink2 = fond((1600, 900), t['tint'])
    if key == 'marque':
        marque(img, 800, 430, 300, ink, ink2)
        enregistrer(img, f'post-paysage-{key}')
        return
    big = t.get('big')
    y = texte(img, 96, 150, 800, t['title'], t['sub'], 220 if big else 100, ink, ink2, lead=t.get('lead'))
    if t['shot'] is None:
        if t.get('pills'):
            fill, pen = encre_pastille(t['tint'])
            pastilles(img, 96, y + 40, t['pills'], 30, fill, pen, vertical=False, max_x=940)
        objet_sous(img, t['obj'], 90, 900 - 70, 640, 'right', 1600, margin=110)
        enregistrer(img, f'{dossier}post-paysage-{key}')
        return
    telephone(img, t['shot'], 540, 1600 - 540 - 60, 120, -5)
    if t.get('pills'):
        fill, pen = encre_pastille(t['tint'])
        pastilles(img, 96, y + 40, t['pills'][:3], 28, fill, pen, vertical=False, max_x=940)
    else:
        objet(img, t['obj'], 330, 760, 900 - 40)
    enregistrer(img, f'{dossier}post-paysage-{key}')


def profils():
    """Symbole, logos, avatar et bannières."""
    os.makedirs(OUT, exist_ok=True)
    pot = C.crisp(POT, box=1024)
    sym = Image.new('RGBA', (1024, 1024), (0, 0, 0, 0))
    sym.alpha_composite(pot, ((1024 - pot.width) // 2, (1024 - pot.height) // 2))
    enregistrer(sym, 'symbole-1024', transparent=True)

    for nom, ink in (('logo-encre', C.INK), ('logo-blanc', C.WHITE)):
        # Sans ombre sous le pot : un logo se pose sur n'importe quel fond.
        logo = Image.new('RGBA', (2200, 800), (0, 0, 0, 0))
        p = C.crisp(POT, box=600)
        d = ImageDraw.Draw(logo)
        f = C.display(312)
        tw = d.textlength('Auxine', font=f)
        x0 = (2200 - (p.width + 90 + tw)) / 2
        logo.alpha_composite(p, (int(x0), 100))
        d.text((x0 + p.width + 90, 520), 'Auxine', font=f, fill=ink + (255,), anchor='ls')
        enregistrer(logo.crop(logo.getbbox()), nom, transparent=True)

    # L'avatar : rogné en rond par les réseaux, le pot tient dans le cercle.
    img, _, _ = fond((1000, 1000), 'sage')
    p = C.crisp(POT, box=640)
    poser(img, p, ((1000 - p.width) / 2, (1000 - p.height) / 2 + 20), blur=26, offset=(0, 26), alpha=0.3)
    enregistrer(img, 'avatar-1000', transparent=False)

    # X : 1500 × 500. Sur mobile, les côtés sont rognés, l'heure et les
    # boutons se posent dessus : le groupe tient au centre, sous l'île.
    img, ink, ink2 = fond((1500, 500), 'sage')
    marque(img, 675, 330, 250, ink, ink2)
    enregistrer(img, 'banniere-x-1500x500')

    # LinkedIn : 1584 × 396, la photo de profil mord en bas à gauche.
    img, ink, ink2 = fond((1584, 396), 'sage')
    marque(img, 900, 200, 230, ink, ink2)
    enregistrer(img, 'banniere-linkedin-1584x396')

    # Facebook : 1640 × 624, rognée sur les côtés en mobile.
    img, ink, ink2 = fond((1640, 624), 'sage')
    marque(img, 820, 300, 300, ink, ink2)
    enregistrer(img, 'couverture-facebook-1640x624')

    # YouTube : 2560 × 1440, seul le centre (1546 × 423) se voit partout.
    img, ink, ink2 = fond((2560, 1440), 'sage')
    marque(img, 1280, 720, 380, ink, ink2)
    enregistrer(img, 'couverture-youtube-2560x1440')

    # L'aperçu d'un lien (Open Graph) : 1200 × 630.
    img, ink, ink2 = fond((1200, 630), 'sage')
    d = ImageDraw.Draw(img)
    p = C.crisp(POT, box=86)
    img.alpha_composite(p, (70, 58))
    d.text((70 + p.width + 18, 58 + 62), 'Auxine', font=C.display(52), fill=ink, anchor='ls')
    texte(img, 70, 200, 640, 'Le carnet\nde vos plantes.', 'Soins, identification, diagnostic et journal photo.', 78, ink, ink2)
    telephone(img, 'today', 420, 1200 - 420 - 40, 80, -5)
    enregistrer(img, 'apercu-lien-1200x630')

    # La miniature d'une vidéo : 1280 × 720.
    img, ink, ink2 = fond((1280, 720), 'sun')
    texte(img, 80, 90, 640, 'Découvrez\nAuxine.', 'Le carnet de vos plantes.', 150, ink, ink2)
    telephone(img, 'plants', 470, 1280 - 470 - 60, 90, -6)
    # Sous la phrase, jamais dessus : le pot se pose entre le texte et l'appareil.
    objet(img, POT, 190, 560, 720 - 36)
    enregistrer(img, 'miniature-video-1280x720')


def sortie():
    """La série de la sortie, dans fr/sortie/."""
    d = 'sortie/'
    for k in SORTIE:
        carre(k, d)
        story(k, d)
    for k in ('bientot', 'disponible', 'disponible-ecran', 'disponible-chf', 'disponible-ecran-chf', 'merci'):
        portrait(k, d)
    for k in ('disponible', 'disponible-ecran', 'disponible-chf', 'disponible-ecran-chf'):
        paysage(k, d)
    for nom, taille, cy, h in (('banniere-x-1500x500', (1500, 500), 330, 250),
                               ('banniere-linkedin-1584x396', (1584, 396), 200, 230)):
        img, ink, ink2 = fond(taille, 'sage')
        marque(img, 675 if taille[0] == 1500 else 900, cy, h, ink, ink2, tagline='Disponible sur l’App Store.')
        enregistrer(img, f'{d}{nom}')


if __name__ == '__main__':
    sortie()
    profils()
    for k in ('prix', 'prix-chf', 'iris', 'soins', 'diagnostic', 'fiche', 'hors-ligne'):
        carre(k)
    for k in ('prix', 'prix-chf', 'iris', 'soins', 'collection', 'calendrier'):
        portrait(k)
    for k in ('marque', 'prix', 'prix-chf', 'iris', 'soins', 'diagnostic'):
        story(k)
    for k in ('marque', 'iris', 'prix', 'prix-chf'):
        paysage(k)
    n = sum(len(f) for _, _, f in os.walk(OUT))
    print(n, 'fichiers dans', os.path.relpath(OUT))
