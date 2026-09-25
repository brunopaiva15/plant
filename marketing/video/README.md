# Vidéo de sortie

La vidéo verticale (1080 × 1920, 24 s) de la sortie d'Auxine, pour TikTok,
Reels et Shorts, en motion design avec Remotion.

| Fichier | Usage |
|---|---|
| `out/auxine-sortie-fr.mp4` | la vidéo, avec sa musique |
| `out/auxine-sortie-fr-muette.mp4` | la même, sans son (pour poser un son dans l'app) |
| `out/auxine-sortie-fr-couverture.png` | la couverture |

## La musique

« Porch Swing Days (faster) », de Kevin MacLeod (incompetech.com), sous
licence **CC BY 4.0** : l'usage commercial est permis, **à condition de
créditer l'auteur**. À mettre dans la légende de chaque publication :

> Musique : « Porch Swing Days (faster) », Kevin MacLeod (incompetech.com), licence CC BY 4.0 — creativecommons.org/licenses/by/4.0/

`musique.py` télécharge le morceau (`source/`, hors du dépôt), mesure son
tempo (130 BPM) et ses temps forts, et coupe 13 mesures à partir du temps
fort de 29,6 s, qui ouvre une section ; la section suivante tombe sur la
dernière scène. Le montage lit le tempo dans `src/musique.json` : chaque
scène commence sur une mesure (`src/temps.ts`). Pour changer de morceau,
changer `MORCEAU` et `DEBUT_APPROX`, relancer `musique.py`, puis le rendu.

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
