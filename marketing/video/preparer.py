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
from PIL import Image  # noqa: E402

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

# Ce que la vidéo anime par-dessus les écrans, en pixels de la capture :
# les ronds de validation des deux premières tuiles « À venir »
# d'Aujourd'hui, la photo de l'étape « Aperçu » et le nom qu'Iris y pose.
# Mesurés sur les captures de chaque source.
if SIMULATEUR:
    geometrie['today'].update(coches=[[576, 2471], [1193, 2471]], rayon=48)
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

with open(os.path.join(ICI, 'src', 'geometrie.json'), 'w') as f:
    json.dump(geometrie, f, indent=2)
print('public/ :', len(os.listdir(PUB)), 'fichiers')
