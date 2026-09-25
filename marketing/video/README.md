# Vidéo de sortie

La vidéo verticale (1080 × 1920, 24 s) de la sortie d'Auxine, pour TikTok,
Reels et Shorts, en motion design avec Remotion.

| Fichier | Usage |
|---|---|
| `out/auxine-sortie-fr.mp4` | la vidéo, avec sa musique |
| `out/auxine-sortie-fr-muette.mp4` | la même, sans son (pour poser un son dans l'app) |
| `out/auxine-sortie-fr-couverture.png` | la couverture |

## La musique

Un morceau original, composé par `musique.py` (synthèse, sans échantillon ni
droits) : 120 BPM, fa majeur. Le montage suit sa grille : une mesure par
scène, un geste par temps (`src/temps.ts`). À publier en « son original ».

## Refaire le rendu

```sh
cd marketing/video
npm install
python3 preparer.py      # les téléphones, le pot, les photos → public/
python3 musique.py       # la musique → public/musique.wav
npx remotion render src/index.ts Sortie out/auxine-sortie-fr.mp4 --codec=h264 --crf=16
npx remotion render src/index.ts SortieMuette out/auxine-sortie-fr-muette.mp4 --codec=h264 --crf=16
npx remotion still src/index.ts Sortie out/auxine-sortie-fr-couverture.png --frame=690
npx remotion studio src/index.ts   # pour regarder et régler image par image
```

Les textes à l'écran sont ceux du kit marketing. Le texte reste hors des
zones que TikTok recouvre (`MARGE` dans `src/temps.ts`).

Remotion est gratuit pour une personne seule ou une entreprise de trois
personnes au plus.
