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

Le cinquième montre l'identification sur l'appareil : sur le simulateur,
c'est la feuille « Espèce » de l'app, le modèle ayant regardé la photo du
Ficus lyrata de la démo. Sur le web, où le modèle ne tourne pas,
`compose.py` la redessine dans le téléphone, sur la page assombrie, avec
des résultats vrais : la photo est une observation iNaturalist en CC0
(`ident/ficus-lyrata.jpg`, observation 359128431, photo 655212161), absente
du jeu d'entraînement, et les trois propositions avec leur cran de
confiance sont la réponse du modèle livré, obtenue par `ident/score.py`,
lue avec les seuils de l'app. Après chaque nouveau modèle : relancer
`score.py`, reporter ses résultats dans `IDENT_RESULTS`, régénérer.

Sur la page d'une plante, la photo continue sous la barre d'état dessinée
(en miroir, floue, assombrie), et les icônes passent en blanc.

Le septième montre le compte rendu d'un diagnostic tel que l'app le rend :
le jeu de démo en garde un au journal de la Calathea (air trop sec, tétranyques,
excès d'eau — des numéros de `assets/problems/catalog.txt`), et la capture
le rouvre depuis la fiche. Le service de diagnostic lui-même n'est pas
configuré sur le build web ; le rapport, lui, est le vrai.

Le jeu de démo (`?demo` sur le web, `--dart-define=DEMO=true` ailleurs) est
réglé pour ces visuels : un seul soin en retard, d'un jour, le reste dû
aujourd'hui ; ses textes libres suivent la langue de l'app. Avant le
chargement, le test d'intégration comme `capture.mjs` écrivent les
préférences d'un téléphone déjà réglé : onboarding passé, un prénom pour
« Bonjour », une ville pour la météo (Open-Meteo ; sur le web, relayée par
`curl` comme les polices), un capteur Apple Maison transmis par Raccourcis
avec une mesure du moment, et l'invite aux rappels déjà vue. Sur le web, là
où la molette n'entraîne presque rien, la page se fait défiler par un
glissement tactile synthétique.

`fr/` et `en/` contiennent les fichiers prêts à déposer dans App Store Connect ;
les textes de la fiche (titre, sous-titre, mots-clés) sont dans [listing.md](listing.md).

## Régénérer

### Sur le simulateur iPhone (les vraies captures)

Depuis un Mac avec Xcode et Flutter ; le script prend le plus grand iPhone
que Xcode propose (17 Pro Max, sinon 16 ou 15 Pro Max), `DEVICE` en impose
un autre :

```bash
pip install pillow numpy
store/capture_ios.sh                      # fr puis en, captures et composition
LANGS=fr store/capture_ios.sh             # une seule langue
DEVICE="iPhone 17 Pro" store/capture_ios.sh
```

Le script démarre le simulateur, sert les photos de démo, désinstalle l'app,
puis lance `integration_test/store_screenshots_test.dart` par `flutter drive`
avec `--dart-define=DEMO=true` : le jeu de démo se charge au premier
lancement, le test règle les préférences d'un téléphone déjà en usage
(prénom, ville pour la météo, capteur Apple Maison transmis par Raccourcis)
et parcourt les écrans en prenant les captures, que
`test_driver/integration_test.dart` écrit dans `store/shots-<langue>/`.
L'identification par Iris et le diagnostic rouvert depuis le journal sont
ceux de l'app. Une scène qui échoue est signalée dans la sortie de
`flutter drive`, les autres se prennent quand même ; il suffit alors de
relancer `compose.py` après correction.

Les captures d'appareil sont l'écran entier, avec la place de la barre
d'état en haut (marqueur `.device` dans le dossier) : `compose.py` y
dessine la sienne, l'heure d'Apple.

### Sur le web (à défaut)

Le build web imite iOS (`?demo&ios`) sans être l'app : les composants
Cupertino y sont dessinés par Flutter, pas par le système, et le modèle
d'identification n'y tourne pas. Ce chemin reste utile pour vérifier une
composition sans Mac.

```bash
flutter build web --profile --no-web-resources-cdn
python3 store/serve.py 8081 build/web &

# Les photos de démo (CC0, voir demo-photos/SOURCES.md) à côté du build
cp -r store/demo-photos build/web/

# Captures (390 × 844 à 3×), données de démo, iOS imité
node store/capture.mjs store/shots-fr fr-FR
node store/capture.mjs store/shots-en en-US

# Composition
pip install pillow numpy
python3 store/compose.py store/shots-fr store/fr fr
python3 store/compose.py store/shots-en store/en en
```

Sans capture `identify.png`, `compose.py` redessine la feuille « Espèce »
sur l'étape Photo de l'ajout, avec les résultats mesurés par `ident/score.py`.

`capture.mjs` demande Playwright (`npm i playwright`) ; la variable `CHROMIUM`
peut pointer un binaire précis. Les emojis de l'app sont fournis par Flutter
web depuis Google Fonts : quand le navigateur ne peut pas y aller directement,
le script relaie ces requêtes par `curl`, qui suit le proxy de la machine.

`compose.py` télécharge la police Inter (SIL OFL) dans `store/fonts/` au
premier lancement ; Shantell Sans vient de `assets/fonts/`. Les captures et les polices ne sont pas versionnées.

Les textes des visuels sont dans `compose.py` (`COPY`), coupés à la main pour
que chaque titre tienne sur deux lignes ; la taille est commune aux sept.
L'ordre des écrans, les teintes et les objets sont dans `SCENES`.
