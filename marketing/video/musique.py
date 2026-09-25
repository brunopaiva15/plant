"""La musique de la vidéo de sortie : un morceau original, composé ici,
calé sur le montage.

    python3 marketing/video/musique.py        # écrit public/musique.wav

120 BPM : un temps dure 15 images à 30 images/s, une mesure 2 secondes, et
chaque scène de la vidéo commence sur une mesure (voir src/temps.ts). Douze
mesures, fa majeur, la grille I–V–vi–IV (fa, do, ré mineur, si bémol).

    mesures 0–1   les photos arrivent : une note de marimba par temps
    mesure  2     le pot : premier coup de grosse caisse, le rythme entre
    mesures 3–8   les écrans : rythme complet, mélodie en 3–4 et 7–8
    mesure  9     le prix : impact sur le premier temps
    mesures 10–11 la fin : dernière mesure de rythme, accord tenu

Tout est synthétisé (numpy, scipy) : pas d'échantillon, pas de droits. Le
mastering (−14 LUFS intégrés, −1 dB crête) passe par le ffmpeg de Remotion.
"""
import os
import subprocess

import numpy as np
from scipy import signal

ICI = os.path.dirname(os.path.abspath(__file__))
SR = 44100
BPM = 120
TEMPS = 60 / BPM
MESURE = 4 * TEMPS
MESURES = 12
DUREE = MESURES * MESURE + 1.5  # la queue de l'accord final
N = int(DUREE * SR)
rng = np.random.default_rng(7)

GRILLE = [  # accord (voix), basse — une mesure chacun
    ((65, 69, 72), 41),   # fa
    ((64, 67, 72), 36),   # do
    ((65, 69, 74), 38),   # ré mineur
    ((65, 70, 74), 34),   # si bémol
]


def hz(m):
    return 440.0 * 2 ** ((m - 69) / 12)


def t_de(mesure, huitieme=0.0):
    return mesure * MESURE + huitieme * TEMPS / 2


def piste():
    return np.zeros((N, 2))


def poser(p, son, t, gain=1.0, pan=0.0):
    """Ajoute un son mono à la piste stéréo, au temps t, panoramiqué."""
    i = int(t * SR)
    if i >= N:
        return
    son = son[: N - i] * gain
    g, d = np.cos((pan + 1) * np.pi / 4), np.sin((pan + 1) * np.pi / 4)
    p[i:i + len(son), 0] += son * g * np.sqrt(2)
    p[i:i + len(son), 1] += son * d * np.sqrt(2)


def env(n, attaque, chute):
    t = np.arange(n) / SR
    a = np.minimum(1, t / max(attaque, 1e-4))
    return a * np.exp(-t / chute)


def filtre(x, kind, f, ordre=2):
    sos = signal.butter(ordre, f, kind, fs=SR, output='sos')
    return signal.sosfilt(sos, x)


def bruit(n):
    return rng.standard_normal(n)


# --- les instruments -----------------------------------------------------------

def grosse_caisse():
    n = int(0.45 * SR)
    t = np.arange(n) / SR
    f = 48 + 110 * np.exp(-t / 0.035)
    corps = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t / 0.22)
    clic = filtre(bruit(n), 'highpass', 3000) * np.exp(-t / 0.004) * 0.25
    return np.tanh(1.6 * (corps + clic)) * 0.9


def clap():
    n = int(0.35 * SR)
    t = np.arange(n) / SR
    e = np.zeros(n)
    for k, d in enumerate((0.0, 0.011, 0.022)):
        e += (t >= d) * np.exp(-np.maximum(t - d, 0) / (0.007 if k < 2 else 0.12))
    return filtre(bruit(n), 'bandpass', (900, 4200)) * e * 0.55


def charleston(ouvert=False):
    n = int((0.22 if ouvert else 0.06) * SR)
    return filtre(bruit(n), 'highpass', 7500) * env(n, 0.001, 0.08 if ouvert else 0.018) * 0.2


def shaker():
    n = int(0.08 * SR)
    return filtre(bruit(n), 'bandpass', (4500, 9000)) * env(n, 0.012, 0.02) * 0.05


def marimba(m, duree=0.9):
    """Une lame frappée : la fondamentale, et le partiel à quatre fois la
    fréquence qui donne le bois, qui s'éteint plus vite."""
    n = int(duree * SR)
    t = np.arange(n) / SR
    f = hz(m)
    s = np.sin(2 * np.pi * f * t) * np.exp(-t / 0.32)
    s += 0.35 * np.sin(2 * np.pi * 4 * f * t) * np.exp(-t / 0.05)
    s += 0.15 * np.sin(2 * np.pi * 10 * f * t) * np.exp(-t / 0.012)
    return s * np.minimum(1, t / 0.002) * 0.5


def cloche(m, duree=1.1):
    """La mélodie : une cloche en synthèse FM, rapport 3,5, dont l'index
    retombe vite — l'attaque brille, la tenue est douce."""
    n = int(duree * SR)
    t = np.arange(n) / SR
    f = hz(m)
    index = 2.2 * np.exp(-t / 0.12) + 0.3
    s = np.sin(2 * np.pi * f * t + index * np.sin(2 * np.pi * 3.5 * f * t))
    return s * env(n, 0.003, 0.45) * 0.32


def nappe(accord, duree):
    """Le tapis des accords : des dents de scie désaccordées, filtrées bas."""
    n = int(duree * SR)
    t = np.arange(n) / SR
    s = np.zeros(n)
    for m in accord:
        for d in (-0.08, 0.08):
            s += signal.sawtooth(2 * np.pi * hz(m - 12) * (1 + d / 100 * 12) * t)
    s = filtre(s, 'lowpass', 1400)
    a = np.minimum(1, t / 0.08) * np.minimum(1, (duree - t) / 0.15)
    return s * a * 0.035


def basse(m, duree):
    n = int(duree * SR)
    t = np.arange(n) / SR
    f = hz(m)
    s = np.sin(2 * np.pi * f * t) + 0.5 * filtre(signal.sawtooth(2 * np.pi * f * t), 'lowpass', 700)
    return np.tanh(1.4 * s) * env(n, 0.004, duree * 0.7) * 0.42


def montee(duree):
    """La montée avant un impact : du bruit dont le filtre s'ouvre."""
    n = int(duree * SR)
    t = np.arange(n) / SR
    x = bruit(n)
    out = np.zeros(n)
    blocs = 24
    for b in range(blocs):
        s, e = b * n // blocs, (b + 1) * n // blocs
        f = 500 + 7000 * (b / blocs) ** 2
        out[s:e] = filtre(x, 'bandpass', (f, min(f * 1.8, 18000)))[s:e]
    return out * (t / duree) ** 2 * 0.3


def impact():
    n = int(1.6 * SR)
    t = np.arange(n) / SR
    boum = np.sin(2 * np.pi * (42 + 60 * np.exp(-t / 0.05)) * t) * np.exp(-t / 0.5) * 0.7
    souffle = filtre(bruit(n), 'highpass', 2500) * np.exp(-t / 0.5) * 0.09
    return boum + souffle


def pop():
    """Le « pop » d'une photo qui se pose."""
    n = int(0.09 * SR)
    t = np.arange(n) / SR
    f = 700 * np.exp(-t / 0.03) + 300
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t / 0.025) * 0.35


# --- l'arrangement -------------------------------------------------------------

MELODIE = {  # par accord : (huitième, note)
    0: [(0, 72), (1, 77), (3, 81), (5, 79), (6, 77)],
    1: [(0, 76), (2, 79), (3, 84), (6, 79)],
    2: [(0, 77), (2, 81), (3, 84), (5, 81), (6, 77)],
    3: [(0, 74), (2, 77), (3, 82), (5, 81), (6, 79)],
}

batterie, basses, accords, melodie, effets, reverb_envoi = (piste() for _ in range(6))
kicks = []

for b in range(MESURES):
    accord, racine = GRILLE[b % 4]
    debut = t_de(b)

    if b <= 1:
        # Les photos : une note par temps, qui monte dans l'accord, et un pop.
        notes = [accord[0], accord[1], accord[2], accord[0] + 12]
        for k in range(4):
            poser(accords, marimba(notes[k] + 12 * (b == 1)), t_de(b, 2 * k), 0.9, pan=(-0.3, 0.3)[k % 2])
            poser(effets, pop(), t_de(b, 2 * k), 0.8)
        if b == 1:
            poser(effets, montee(2 * TEMPS), t_de(1, 4), 0.9)
        continue

    fin = b == MESURES - 1
    if b in (2, 9) or fin:
        poser(effets, impact(), debut, 1.0)

    if fin:
        # L'accord final, tenu, et la note haute qui le signe.
        poser(accords, nappe(accord, 3.2), debut, 1.4)
        for m in accord:
            poser(accords, marimba(m + 12, 2.5), debut, 0.7)
        poser(melodie, cloche(84, 2.8), debut, 1.0)
        poser(batterie, grosse_caisse(), debut, 1.0)
        kicks.append(debut)
        break

    # Le rythme : grosse caisse à chaque temps, clap sur 2 et 4, charleston
    # sur les contretemps, shaker en doubles croches.
    for k in range(4):
        poser(batterie, grosse_caisse(), t_de(b, 2 * k))
        kicks.append(t_de(b, 2 * k))
        poser(batterie, charleston(ouvert=(k == 3)), t_de(b, 2 * k + 1), 1.0, pan=0.25)
    for k in (1, 3):
        poser(batterie, clap(), t_de(b, 2 * k), 1.0)
        poser(reverb_envoi, clap(), t_de(b, 2 * k), 0.5)
    for k in range(16):
        poser(batterie, shaker(), t_de(b, k / 2), 0.9 if k % 2 else 0.5, pan=-0.35)

    # Le roulement qui annonce le prix, à la fin de la mesure 8.
    if b == 8:
        for k in range(8):
            poser(batterie, clap(), t_de(8, 4 + k / 2), 0.35 + 0.08 * k)
        poser(effets, montee(2 * TEMPS), t_de(8, 4), 1.0)

    # La basse : la fondamentale sur le temps, l'octave sur les contretemps.
    for k in range(8):
        m = racine + (12 if k % 2 else 0)
        poser(basses, basse(m, TEMPS / 2 * 0.9), t_de(b, k), 1.0 if k % 2 == 0 else 0.8)

    # Les accords : un tapis, et des coups de marimba syncopés (1, 2 et demi, 4).
    poser(accords, nappe(accord, MESURE), debut, 1.0)
    for h in (0, 3, 6):
        for m in accord:
            poser(accords, marimba(m, 0.5), t_de(b, h), 0.45, pan=0.15)
            poser(reverb_envoi, marimba(m, 0.5), t_de(b, h), 0.15)

    # La mélodie, sur deux passages.
    if b in (3, 4, 7, 8, 10):
        for h, m in MELODIE[b % 4]:
            poser(melodie, cloche(m), t_de(b, h), 1.0, pan=-0.1)
            poser(reverb_envoi, cloche(m), t_de(b, h), 0.5)

# --- le mixage -----------------------------------------------------------------

# La grosse caisse creuse la basse et les accords (compression latérale).
t = np.arange(N) / SR
pompe = np.ones(N)
for k in kicks:
    i = int(k * SR)
    j = min(N, i + int(0.3 * SR))
    pompe[i:j] = np.minimum(pompe[i:j], 1 - 0.65 * np.exp(-(t[i:j] - k) / 0.09))
basses *= pompe[:, None]
accords *= (0.4 + 0.6 * pompe)[:, None]

# La réverbération : une réponse de bruit qui s'éteint en 1,6 s, une par côté.
n_ir = int(1.6 * SR)
ir_t = np.arange(n_ir) / SR
reverb = piste()
for c in range(2):
    ir = filtre(bruit(n_ir), 'lowpass', 6000) * np.exp(-ir_t / 0.45)
    ir[: int(0.012 * SR)] = 0
    reverb[:, c] = signal.fftconvolve(reverb_envoi[:, c] + 0.3 * melodie[:, c], ir)[:N] * 0.018

mix = batterie * 0.9 + basses * 0.85 + accords * 0.8 + melodie * 0.75 + effets * 0.8 + reverb
for c in range(2):
    mix[:, c] = filtre(mix[:, c], 'highpass', 30)
mix = np.tanh(mix * 1.1) / np.tanh(1.1)
# Un fondu très court en fin de queue.
f = int(0.8 * SR)
mix[-f:] *= np.linspace(1, 0, f)[:, None]
mix /= np.max(np.abs(mix)) * 1.05

brut = os.path.join(ICI, 'public', 'musique-brute.wav')
os.makedirs(os.path.dirname(brut), exist_ok=True)
from scipy.io import wavfile  # noqa: E402
wavfile.write(brut, SR, (mix * 32767).astype(np.int16))

ffmpeg = os.path.join(ICI, 'node_modules', '@remotion', 'compositor-linux-x64-gnu', 'ffmpeg')
sortie = os.path.join(ICI, 'public', 'musique.wav')
subprocess.run([ffmpeg, '-y', '-loglevel', 'error', '-i', brut,
                '-af', 'loudnorm=I=-14:TP=-1:LRA=9', '-ar', str(SR), sortie], check=True,
               env={**os.environ, 'LD_LIBRARY_PATH': os.path.dirname(ffmpeg)})
os.remove(brut)
print(f'{sortie} : {DUREE:.1f} s, {BPM} BPM, {MESURES} mesures')
