# Visuels du magasin

Sept visuels par langue, au format iPhone 6,7 pouces (1290 × 2796), sans le
nom de l'application. Chacun montre une capture réelle de l'app dans un
iPhone dessiné, entier et droit, l'écran complet : c'est l'écran qu'on vend,
rien ne le recouvre. Au-dessus, un titre tracé en Shantell Sans (la police
« main » de l'app) ; entre le titre et le téléphone, un objet 3D de la série
clay de l'onboarding dépasse de derrière l'écran. Le fond est le papier
crème de l'app, avec son grain ; les ombres sont brunes, jamais noires.

| # | Écran | Objet | Teinte |
|---|---|---|---|
| 1 | Aujourd'hui | trois rangées cochées | eau |
| 2 | Plantes (la collection) | monstera en pot | sauge |
| 3 | Fiche d'une plante (Basilic), photo en tête | plante ronde en pot | terre cuite |
| 4 | Fiche d'entretien | anneau et goutte | soleil |
| 5 | Ajout d'une plante, étape Photo, avec la feuille « Espèce » ouverte | caoutchouc en pot | terre |
| 6 | Jardin, calendrier | la maison | lavande |
| 7 | Profil (« Vos données restent sur ce téléphone. ») | carte, cadenas, nuage | rose |

Le cinquième montre l'identification sur l'appareil. La feuille « Espèce »
est redessinée par `compose.py` dans le téléphone, sur la page assombrie,
comme l'app la présente ; ce qu'elle affiche est vrai : la photo est une
observation iNaturalist en CC0 (`ident/ficus-lyrata.jpg`, observation
359128431, photo 655212161), absente du jeu d'entraînement, et les trois
propositions avec leur cran de confiance sont la réponse du modèle livré,
obtenue par `ident/score.py`, lue avec les seuils de l'app.
Après chaque nouveau modèle : relancer `score.py`, reporter ses résultats
dans `IDENT_RESULTS`, régénérer.

Sur la page d'une plante, la photo continue sous la barre d'état dessinée
(en miroir, floue, assombrie), et les icônes passent en blanc.

Le jeu de démo (`?demo`) est réglé pour ces visuels : un seul soin en
retard, d'un jour, le reste dû aujourd'hui. L'invite aux rappels est marquée
déjà vue par `capture.mjs` avant le chargement.

`fr/` et `en/` contiennent les fichiers prêts à déposer dans App Store Connect ;
les textes de la fiche (titre, sous-titre, mots-clés) sont dans [listing.md](listing.md).

## Régénérer

```bash
flutter build web --profile --no-web-resources-cdn
python3 store/serve.py 8081 build/web &

# Les photos de démo (CC0, voir demo-photos/SOURCES.md) à côté du build
cp -r store/demo-photos build/web/

# Captures réelles (390 × 844 à 3×), données de démo, iOS
node store/capture.mjs store/shots-fr fr-FR
node store/capture.mjs store/shots-en en-US

# Composition
pip install pillow numpy
python3 store/compose.py store/shots-fr store/fr fr
python3 store/compose.py store/shots-en store/en en
```

`capture.mjs` demande Playwright (`npm i playwright`) ; la variable `CHROMIUM`
peut pointer un binaire précis. Les emojis de l'app sont fournis par Flutter
web depuis Google Fonts : quand le navigateur ne peut pas y aller directement,
le script relaie ces requêtes par `curl`, qui suit le proxy de la machine.

`compose.py` télécharge la police Inter (SIL OFL) dans `store/fonts/` au
premier lancement ; Shantell Sans vient de `assets/fonts/`. Les captures et les polices ne sont pas versionnées.

Les textes des visuels sont dans `compose.py` (`COPY`), coupés à la main pour
que chaque titre tienne sur deux lignes ; la taille est commune aux sept.
L'ordre des écrans, les teintes et les objets sont dans `SCENES`.
