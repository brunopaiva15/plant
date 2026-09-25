# Vidéo de sortie

La vidéo verticale (1080 × 1920, 24 s) de la sortie d'Auxine, pour TikTok,
Reels et Shorts, en motion design avec Remotion.

| Fichier | Usage |
|---|---|
| `out/auxine-sortie-fr.mp4` | la vidéo, avec sa musique |
| `out/auxine-sortie-fr-muette.mp4` | la même, sans son (pour poser un son dans l'app) |
| `out/auxine-sortie-fr-couverture.png` | la couverture |

## Le déroulé

Trois actes, décrits temps par temps dans `PARTITION.md` et posés dans
`src/Film.tsx` :

1. **Le geste** (0–3,7 s) — de vrais plans en intérieur, une coupe par temps,
   jusqu'au déclenchement : « Quelle est cette plante ? ».
2. **L'app répond** (3,7–16,6 s) — un seul téléphone, qui ne quitte pas
   l'écran : ses écrans se poussent comme dans iOS (Aperçu, Aujourd'hui,
   Diagnostic, Plantes), la caméra s'approche de ce qui compte, le fond
   prend la couleur de chaque fonction. L'arrosage réel s'intercale avant
   les soins.
3. **L'offre et la marque** (16,6–24 s) — « 0,99 € » sur le changement de
   section du morceau, puis le pot, « Auxine » et « Disponible sur l'App
   Store. », tenus jusqu'à la fin.

## Les plans réels

L'accroche et la scène « Quelle est cette plante ? » montrent de vrais
gestes, filmés en intérieur : des vidéos de [Pexels](https://www.pexels.com)
(licence Pexels : usage commercial permis, sans crédit obligatoire).
`preparer.py` les télécharge (`source/`, hors du dépôt), les recadre en 9:16
et les coupe ; la liste est dans `PLANS`.

| Pexels | Auteur | Ce qu'on y voit |
|---|---|---|
| [4507878](https://www.pexels.com/video/4507878/) | cottonbro studio | des succulentes photographiées au téléphone, vues de dessus |
| [7421678](https://www.pexels.com/video/7421678/) | Antoni Shkraba | des mains autour d'une plante en pot |
| [6912204](https://www.pexels.com/video/6912204/) | Teona Swift | des mains cadrent une plante d'intérieur et déclenchent |
| [7218427](https://www.pexels.com/video/7218427/) | Thirdman | une monstera : les feuilles (accroche), puis l'arrosage (soins) |

Surtout des mains : la licence interdit de laisser croire qu'une personne
filmée recommande l'app. Dans le plan d'arrosage, la personne est de dos
et de profil, sans texte qui lui prête un avis.

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
