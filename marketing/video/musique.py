"""La musique de la vidéo de sortie : un vrai morceau, sous licence libre,
coupé sur ses temps.

    python3 marketing/video/musique.py

« Porch Swing Days (faster) », de Kevin MacLeod (incompetech.com), sous
licence Creative Commons Attribution 4.0 : l'usage commercial est permis, à
condition de créditer l'auteur — voir CREDIT, à reprendre dans la légende de
la publication.

Le script télécharge le morceau (source/, hors du dépôt), mesure son tempo et
ses temps forts, et coupe 13 mesures à partir d'un temps fort choisi : le
montage (src/temps.ts) lit le tempo dans src/musique.json et pose chaque
scène sur une mesure. Le passage choisi commence au début d'une section du
morceau, et la section suivante tombe sur la dernière scène.
"""
import json
import os
import subprocess
import urllib.parse
import urllib.request
import warnings

import librosa
import numpy as np

warnings.filterwarnings('ignore')
ICI = os.path.dirname(os.path.abspath(__file__))

MORCEAU = {
    'titre': 'Porch Swing Days (faster)',
    'auteur': 'Kevin MacLeod',
    'fichier': 'Porch Swing Days - faster.mp3',
    'source': 'https://incompetech.com',
    'licence': 'CC BY 4.0',
    'licence_url': 'https://creativecommons.org/licenses/by/4.0/',
}
CREDIT = ('Musique : « Porch Swing Days (faster) », Kevin MacLeod (incompetech.com), '
          'licence CC BY 4.0 — creativecommons.org/licenses/by/4.0/')

# Le passage : le temps fort le plus proche de cette seconde, et 13 mesures.
DEBUT_APPROX = 29.6
MESURES = 13
FONDU = 1.6

source = os.path.join(ICI, 'source', MORCEAU['fichier'])
if not os.path.exists(source):
    os.makedirs(os.path.dirname(source), exist_ok=True)
    url = 'https://incompetech.com/music/royalty-free/mp3-royaltyfree/' + urllib.parse.quote(MORCEAU['fichier'])
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    with urllib.request.urlopen(req, timeout=120) as r, open(source, 'wb') as f:
        f.write(r.read())

# Le tempo : une droite passée par tous les temps détectés, plus précise que
# l'estimation de librosa, qui s'arrondit à sa grille.
y, sr = librosa.load(source, sr=22050)
_, cadres = librosa.beat.beat_track(y=y, sr=sr, start_bpm=130, tightness=400)
temps = librosa.frames_to_time(cadres, sr=sr)
n = np.arange(len(temps))
periode, origine = np.polyfit(n, temps, 1)
bpm = 60 / periode

# Le temps fort : celui des quatre temps où les graves attaquent le plus.
S = np.abs(librosa.stft(y))
graves = librosa.onset.onset_strength(S=librosa.amplitude_to_db(S[librosa.fft_frequencies(sr=sr) < 200]), sr=sr)
phase = int(np.argmax([graves[cadres[p::4]].mean() for p in range(4)]))
forts = origine + periode * np.arange(phase, len(temps), 4)
debut = float(forts[np.argmin(np.abs(forts - DEBUT_APPROX))])
duree = MESURES * 4 * periode

# Le passage, en stéréo, avec un fondu de sortie ; ffmpeg ne fait que le
# mastering (−14 LUFS intégrés, −1 dB crête), son build n'ayant pas de fondus.
from scipy.io import wavfile  # noqa: E402
SR = 44100
passage, _ = librosa.load(source, sr=SR, mono=False, offset=debut, duration=duree)
passage = np.atleast_2d(passage).T
f = int(FONDU * SR)
passage[-f:] *= np.linspace(1, 0, f)[:, None] ** 2
passage[:int(0.01 * SR)] *= np.linspace(0, 1, int(0.01 * SR))[:, None]
brut = os.path.join(ICI, 'public', 'musique-brute.wav')
os.makedirs(os.path.dirname(brut), exist_ok=True)
wavfile.write(brut, SR, (passage * 32767).astype(np.int16))
ffmpeg = os.path.join(ICI, 'node_modules', '@remotion', 'compositor-linux-x64-gnu', 'ffmpeg')
sortie = os.path.join(ICI, 'public', 'musique.wav')
subprocess.run([ffmpeg, '-y', '-loglevel', 'error', '-i', brut, '-af', 'loudnorm=I=-14:TP=-1:LRA=9', '-ar', str(SR), sortie],
               check=True, env={**os.environ, 'LD_LIBRARY_PATH': os.path.dirname(ffmpeg)})
os.remove(brut)

with open(os.path.join(ICI, 'src', 'musique.json'), 'w') as f:
    json.dump({**MORCEAU, 'bpm': round(bpm, 3), 'debut': round(debut, 3), 'duree': round(duree, 3), 'credit': CREDIT},
              f, ensure_ascii=False, indent=2)
print(f'{MORCEAU["titre"]} : {bpm:.2f} BPM, de {debut:.2f} s à {debut + duree:.2f} s → {sortie}')
print(CREDIT)
