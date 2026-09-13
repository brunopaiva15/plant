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
| 7 | Diagnostic gardé au journal de la Calathea, rouvert en entier | sansevieria en pot | rose |

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

Le septième montre le compte rendu d'un diagnostic tel que l'app le rend :
le jeu de démo en garde un au journal de la Calathea (air trop sec, tétranyques,
excès d'eau — des numéros de `assets/problems/catalog.txt`), et la capture
le rouvre depuis la fiche. Le service de diagnostic lui-même n'est pas
configuré sur le build web ; le rapport, lui, est le vrai.

Le jeu de démo (`?demo`) est réglé pour ces visuels : un seul soin en
retard, d'un jour, le reste dû aujourd'hui ; ses textes libres suivent la
langue du navigateur. Avant le chargement, `capture.mjs` écrit les
préférences d'un téléphone déjà réglé : onboarding passé, un prénom pour
« Bonjour », une ville pour la météo (Open-Meteo, relayée par `curl` comme
les polices), un capteur Apple Maison transmis par Raccourcis avec une
mesure du moment, et l'invite aux rappels déjà vue. Là où la molette
n'entraîne presque rien, la page se fait défiler par un glissement tactile
synthétique.

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
