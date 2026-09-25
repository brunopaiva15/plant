"""Les images de la vidéo, rangées dans public/ pour Remotion.

    python3 marketing/video/preparer.py

Les téléphones sont habillés par store/compose.py, comme dans le kit
marketing, à partir des captures de store/shots-fr/. Le pot et son clin
d'œil sont ceux de l'ouverture de l'app (assets/splash/).
"""
import json
import os
import shutil
import sys

ICI = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(ICI, '..', '..'))
sys.path.insert(0, os.path.join(ROOT, 'store'))
os.chdir(ROOT)

import compose as C  # noqa: E402
from PIL import Image, ImageDraw  # noqa: E402

C.ensure_fonts()
C.use('iphone')
PUB = os.path.join(ICI, 'public')
os.makedirs(PUB, exist_ok=True)
SHOTS = 'store/shots-fr'

# Les captures du simulateur (store/capture_ios.sh, marquées par un fichier
# .device) sont l'écran entier, 1320 × 2868 : la barre d'état y a déjà sa
# place. Celles du web (store/capture.mjs, 1170 × 2532) n'en ont pas, et
# compose.py la dessine au-dessus.
SIMULATEUR = os.path.exists(os.path.join(SHOTS, '.device'))
dev = C.L['device']
ecran = {'x': dev['bezel'] * dev['px'], 'y': dev['bezel'] * dev['px'] + (0 if SIMULATEUR else dev['status'] * dev['px'])}
geometrie = {}
for nom in ('capture', 'today', 'diagnosis', 'plants', 'garden-calendar'):
    chemin = os.path.join(SHOTS, f'{nom}.png')
    sw, sh = Image.open(chemin).size
    ph = C.phone(chemin, device=SIMULATEUR)
    ph.save(os.path.join(PUB, f'tel-{nom}.png'), optimize=True)
    geometrie[nom] = {'w': ph.width, 'h': ph.height, 'sw': sw, 'sh': sh, **ecran}

# Le téléphone persistant de l'acte 2 : le cadre, percé à la place de
# l'écran (l'île redessinée par-dessus), et chaque écran seul, barre d'état
# comprise. Les écrans glissent dans le cadre comme une navigation iOS.
from PIL import ImageChops  # noqa: E402
bx = dev['bezel'] * dev['px']
haut = 0 if SIMULATEUR else dev['status'] * dev['px']
corps = C.phone(os.path.join(SHOTS, 'today.png'), device=SIMULATEUR)
el, eh = corps.width - 2 * bx, corps.height - 2 * bx
rayon = dev['radius'] * dev['px']
trou = Image.new('L', corps.size, 255)
ImageDraw.Draw(trou).rounded_rectangle((bx, bx, bx + el - 1, bx + eh - 1), radius=rayon, fill=0)
cadre = corps.copy()
cadre.putalpha(ImageChops.multiply(cadre.split()[-1], trou))
if dev['island']:
    iw, ih = dev['island'][0] * dev['px'], dev['island'][1] * dev['px']
    ix, iy = bx + (el - iw) // 2, bx + 11 * dev['px']
    ImageDraw.Draw(cadre).rounded_rectangle((ix, iy, ix + iw, iy + ih), radius=ih // 2, fill=(14, 11, 9, 255))
cadre.save(os.path.join(PUB, 'cadre.png'), optimize=True)
for nom in ('capture', 'today', 'diagnosis', 'plants'):
    ecran_ = C.phone(os.path.join(SHOTS, f'{nom}.png'), device=SIMULATEUR).crop((bx, bx, bx + el, bx + eh))
    ecran_.convert('RGB').save(os.path.join(PUB, f'ecran-{nom}.jpg'), quality=93)
geometrie['tel'] = {'w': corps.width, 'h': corps.height, 'ecran': {'x': bx, 'y': bx, 'l': el, 'h': eh, 'rayon': rayon},
                    # Où commence la capture dans l'écran : sous la barre d'état dessinée, pour le web.
                    'haut': haut}

# Ce que la vidéo anime par-dessus les écrans, en pixels de la capture :
# les ronds de validation des deux premières tuiles « À venir »
# d'Aujourd'hui, la photo de l'étape « Aperçu » et le nom qu'Iris y pose.
# Mesurés sur les captures de chaque source.
if SIMULATEUR:
    geometrie['today'].update(coches=[[576, 2471], [1193, 2471]], rayon=48)
    # La carte « Air trop sec » du diagnostic, et les deux premières tuiles
    # de la grille des plantes (la seconde rangée passe sous les onglets).
    geometrie['diagnosis'].update(carte={'x': 70, 'y': 740, 'l': 1180, 'h': 710, 'rayon': 44})
    geometrie['plants'].update(tuiles=[[60, 1256, 580, 800], [680, 1256, 580, 800]], rayonTuile=64)
    geometrie['capture'].update(photo={'x': 60, 'y': 784, 'l': 1200, 'h': 1500, 'rayon': 100}, nom=[400, 1140])
else:
    geometrie['today'].update(coches=[[500, 2004], [1042, 2004]], rayon=48)
    geometrie['capture'].update(photo={'x': 60, 'y': 615, 'l': 1050, 'h': 1311, 'rayon': 90}, nom=[360, 936])

# Le pot de l'ouverture, et l'œil de droite qui se ferme.
for f in ('logo.webp', 'clin_50.webp', 'clin_85.webp', 'clin_100.webp'):
    shutil.copy(os.path.join('assets', 'splash', f), os.path.join(PUB, f))
geometrie['oeil'] = {'x': 497, 'y': 614, 'cote': 176, 'image': 1024}

# Les objets 3D.
for nom in ('monstera', 'ronde', 'sansevieria', 'caoutchouc', 'semis'):
    shutil.copy(os.path.join('assets', 'onboarding', f'collection_{nom}.webp'), os.path.join(PUB, f'{nom}.webp'))
shutil.copy(os.path.join('assets', 'objects', 'arrosoir.webp'), os.path.join(PUB, 'arrosoir.webp'))

# Les photos de plantes de la démo, recadrées en carré.
for f in sorted(os.listdir('store/demo-photos')):
    if not f.endswith('.jpg'):
        continue
    im = Image.open(os.path.join('store/demo-photos', f)).convert('RGB')
    c = min(im.size)
    im = im.crop(((im.width - c) // 2, (im.height - c) // 2, (im.width + c) // 2, (im.height + c) // 2))
    im.resize((720, 720), Image.LANCZOS).save(os.path.join(PUB, f'photo-{f}'), quality=88)

# Les polices : Bricolage Grotesque (celle de l'app) et Inter.
shutil.copy('assets/fonts/BricolageGrotesque-VF.ttf', os.path.join(PUB, 'Bricolage.ttf'))
for g in ('Medium', 'SemiBold'):
    shutil.copy(os.path.join(C.FONTS, f'Inter-{g}.ttf'), os.path.join(PUB, f'Inter-{g}.ttf'))

# Les plans réels : des vidéos Pexels (licence Pexels : usage commercial
# permis, sans crédit), tournées en intérieur. Seulement des mains — aucun
# visage : la licence interdit de laisser croire qu'une personne filmée
# recommande l'app. Chacun est recadré en 9:16 autour du téléphone ou de la
# plante, et coupé au passage utile.
#   (id, fichier sur le CDN, début en s, durée, centre du cadrage en largeur[, nom du passage])
PLANS = [
    ('4507878', 'uhd_4096_2160_25fps', 4.0, 1.8, 0.55),   # vu de dessus, des succulentes au téléphone
    ('7421678', 'hd_1920_1080_25fps', 1.0, 1.8, 0.45),    # des mains autour d'une plante en pot
    # Le début du plan d'arrosage : les mains passent dans les feuilles.
    ('7218427', 'hd_1080_1920_25fps', 5.0, 1.4, 0.5, 'feuilles'),
    # Un arrosage au pied d'une monstera, près d'une fenêtre : l'eau coule
    # entre 19 et 23 s.
    ('7218427', 'hd_1080_1920_25fps', 19.6, 2.2, 0.5),
    # Le cadrage, puis le déclenchement à 7,5 s : il tombe sur le temps où
    # la vidéo passe à l'étape « Aperçu » d'Auxine (src/Scenes.tsx).
    ('6912204', 'hd_1080_1920_24fps', 5.65, 2.2, 0.5),
]
import subprocess  # noqa: E402
import urllib.request  # noqa: E402
FF = os.path.join(ICI, 'node_modules', '@remotion', 'compositor-linux-x64-gnu')
for pid, nom, debut, duree, centre, *alias in PLANS:
    src = os.path.join(ICI, 'source', f'pexels-{pid}.mp4')
    if not os.path.exists(src):
        os.makedirs(os.path.dirname(src), exist_ok=True)
        req = urllib.request.Request(f'https://videos.pexels.com/video-files/{pid}/{pid}-{nom}.mp4', headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req, timeout=600) as r, open(src, 'wb') as f:
            f.write(r.read())
    w, h = (int(v) for v in nom.split('_')[1:3])
    cw = min(w, round(h * 9 / 16 / 2) * 2)
    x = max(0, min(w - cw, round(centre * w - cw / 2)))
    subprocess.run([os.path.join(FF, 'ffmpeg'), '-loglevel', 'error', '-y', '-ss', str(debut), '-t', str(duree), '-i', src,
                    '-vf', f'crop={cw}:{h}:{x}:0,scale=1080:1920', '-an', '-c:v', 'libx264', '-crf', '17',
                    '-pix_fmt', 'yuv420p', '-r', '30', os.path.join(PUB, f'plan-{alias[0] if alias else pid}.mp4')],
                   check=True, env={**os.environ, 'LD_LIBRARY_PATH': FF})

with open(os.path.join(ICI, 'src', 'geometrie.json'), 'w') as f:
    json.dump(geometrie, f, indent=2)
print('public/ :', len(os.listdir(PUB)), 'fichiers')
