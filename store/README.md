# Visuels du magasin

Huit visuels dans les quatre langues de l'app (fr, en, de, it), en deux
séries : iPhone 6,7 pouces (1290 × 2796) et iPad 13 pouces (2064 × 2752).
Le projet Xcode déclare les deux familles (`TARGETED_DEVICE_FAMILY = "1,2"`)
et App Store en réclame alors une série chacune. Le
premier ne montre pas un écran, mais il en suit la mise en page : la marge
de page de l'app, un grand titre en haut à gauche, puis des cartes en
colonne. Sur le vert de la marque, le nom en Bricolage blanc et la
revendication ; le pot de l'icône, entier, se pose sur une carte crème qui
porte ce que l'app dit d'une plante ; une carte orange vif dit ce que l'app
n'impose pas — ni compte, ni publicité. Le mot « gratuit » n'y figure plus : l'app ne le sera pas.
L'espèce montrée est la monstera, celle que tout le monde reconnaît ; son
arrosage et sa lumière sont ceux de son profil de soin
(`data/species/care_profiles.dart`), son nom courant celui du catalogue
livré. Rien de plus — une
fiche chargée ne se lit pas dans une grille de vignettes.

Les sept autres montrent une capture réelle de l'app dans un appareil
dessiné, légèrement incliné, l'écran complet : c'est l'écran qu'on vend,
rien ne le recouvre. Au-dessus, un titre en Bricolage Grotesque très gras
(la police des titres de l'app) et une ligne qui le précise.

La série tient par deux règles communes. Le fond est un aplat d'une couleur
de l'app — le vert de la marque, l'orange, le jaune, le bleu, le rose, un
lilas, le brun de nuit —, avec les deux grands disques pâles de ses têtes
vertes en haut à droite ; le titre est blanc sur le vert et le brun, à
l'encre sur les couleurs vives, comme dans l'app. Et un objet 3D se pose
devant l'appareil, sur un coin bas, entier et à sa taille native — jamais
derrière, jamais coupé, jamais sur sa propre couleur. Le titre, lui, reste seul : un second objet
posé en marge faisait deux fois le même geste sur la même fiche.

Le nom de l'application, sur la première fiche, a sa taille à lui
(`cover.title` du gabarit) : ce n'est pas un titre de fiche, il se lit de
loin dans la grille du magasin. Cette fiche se cale par le bas — la barre de
terre cuite d'abord, la carte de verre au-dessus, la plante posée sur elle.

Les deux gabarits sont dans `FORMATS` ; `use()` règle celui du moment et tout
le fichier lit ses cotes dans `L`. Un iPad n'est pas un grand iPhone : presque
carré, il laisse moins de hauteur au texte, l'appareil y prend moins de
largeur, il s'incline aux deux tiers pour ne pas déborder par le bas, sa
capture est au facteur 2 quand celle de l'iPhone est au 3, et son cadre n'a
ni île ni antenne — un œil de caméra au milieu du bord haut, l'heure, le
wifi, la batterie. Sur sa fiche d'ouverture, les trois soins passent côte à
côte : en colonne, ils laisseraient la moitié droite vide.

Le troisième, juste après l'écran du matin, montre l'identification là où
elle commence : l'étape « Aperçu » de la création, la photo prise, les trois
premiers noms qu'Iris pose dessus —
nom courant en gras, nom scientifique dessous, la première proposition
cernée de sauge. Le modèle tourne vraiment, sur la photo du Ficus lyrata de
la démo. Le simulateur n'a pas de caméra : c'est « Choisir une photo » qui
sert de prise de vue, et le magasin de photos de la démo
(`lib/core/demo/demo_photo_storage.dart`) rend ce Ficus au lieu d'ouvrir
une photothèque vide. Rien d'autre n'est simulé — l'écran, le modèle et les
noms sont ceux de l'app.

Sans Mac, le même écran se prend par un banc de test
(`test/store/identification_capture_test.dart`) : l'écran de l'app, la
photo CC0 du Ficus de `ident/`, et la réponse que le modèle livré donne sur
elle (`ident/score.py`), les noms courants du catalogue dans chaque langue.

```bash
STORE_CAPTURE=1 flutter test test/store/identification_capture_test.dart
```

Il écrit `store/shots-<langue>/capture.png` ; hors de cette variable, il ne
fait rien, et la suite de tests le saute. Après un nouveau modèle, ses
scores se reportent là aussi.

S'il manque, `compose.py` montre l'autre façon d'identifier, la feuille
« Espèce »
redessinée sur la fiche du Ficus assombrie — celle-là même qu'elle recouvre
dans l'app —, avec des résultats vrais : la photo est une observation
iNaturalist en CC0 (`ident/ficus-lyrata.jpg`, observation 359128431, photo
655212161), absente du jeu d'entraînement, et les trois propositions avec
leur cran de confiance sont la réponse du modèle livré, obtenue par
`ident/score.py`, lue avec les seuils de l'app. Après chaque nouveau
modèle : relancer `score.py`, reporter ses résultats dans `IDENT_RESULTS`,
régénérer.

Sur la page d'une plante, la photo continue sous la barre d'état dessinée
(en miroir, floue, assombrie), et les icônes passent en blanc.

Le huitième montre le compte rendu d'un diagnostic tel que l'app le rend :
le jeu de démo en garde un au journal de la Calathea (air trop sec, tétranyques,
excès d'eau — des numéros de `assets/problems/catalog.txt`), et la capture
le rouvre depuis la fiche. Le service de diagnostic lui-même n'est pas
configuré sur le build web ; le rapport, lui, est le vrai.

Hors du web, les photos de la démo sont téléchargées et rangées comme de
vraies photos de plante : une photo laissée à son adresse s'affiche, mais
n'a pas de fichier, et Iris n'aurait rien à lire — la feuille « Espèce »
répondrait « Aucune correspondance fiable ». Le test s'en assure et fait
échouer la scène plutôt que de livrer un visuel vide.

Le jeu de démo (`?demo` sur le web, `--dart-define=DEMO=true` ailleurs) est
réglé pour ces visuels : rien de dû aujourd'hui, tous les soins à venir à
des échéances variées, pour l'écran du matin en grille ; ses textes libres
suivent la langue de l'app, dans les quatre langues. Avant le
chargement, le test d'intégration comme `capture.mjs` écrivent les
préférences d'un téléphone déjà réglé : onboarding passé, un prénom pour
« Bonjour », une ville pour la météo (Open-Meteo ; sur le web, relayée par
`curl` comme les polices), l'invite aux rappels déjà vue et la question des
photos d'entraînement d'Iris déjà posée. Apple Maison ne se lit que par
HomeKit, sur un iPhone : ni le web ni le simulateur n'en montrent. Sur le web, là
où la molette n'entraîne presque rien, la page se fait défiler par un
glissement tactile synthétique.

`fr/`, `en/`, `de/` et `it/` contiennent les visuels iPhone prêts à déposer
dans App Store Connect, `ipad-fr/`, `ipad-en/`, `ipad-de/` et `ipad-it/` ceux
de l'iPad ;
les textes de la fiche (titre, sous-titre, mots-clés) sont dans [listing.md](listing.md).

## Régénérer

### Sur le simulateur (les vraies captures)

Depuis un Mac avec Xcode et Flutter ; le script prend le plus grand appareil
de la famille que Xcode propose (iPhone 17 Pro Max, sinon 16 ou 15 Pro Max ;
iPad Pro 13 pouces, sinon 12,9), `DEVICE` en impose un autre. Les deux séries
demandent les deux passages :

```bash
pip install pillow numpy
store/capture_ios.sh                      # iPhone, les quatre langues, captures et composition
FORMAT=ipad store/capture_ios.sh          # iPad, la même série
LANGS="fr en" store/capture_ios.sh        # deux langues
DEVICE="iPhone 17 Pro" store/capture_ios.sh
```

Le script démarre le simulateur, sert les photos de démo, désinstalle l'app,
puis lance `integration_test/store_screenshots_test.dart` par `flutter drive`
avec `--dart-define=DEMO=true` : le jeu de démo se charge au premier
lancement, le test règle les préférences d'un téléphone déjà en usage
(prénom, ville pour la météo) et parcourt les écrans en prenant les
captures, que
`test_driver/integration_test.dart` écrit dans `store/shots-<langue>/`
(`store/shots-ipad-<langue>/` pour l'iPad).
Les noms posés sur la photo par Iris et le diagnostic rouvert depuis le
journal sont ceux de l'app. Une scène qui échoue est signalée dans la sortie de
`flutter drive` (avec ce qu'on lisait à l'écran, et une capture
`<scène>-echec.png`), les autres se prennent quand même ; le visuel de la
scène manquée reste tel quel. Pour rejouer quelques scènes seulement :
`STORE_SCENES=capture,diagnosis LANGS=fr store/capture_ios.sh`. Ce sont les
noms des scènes du test, pas ceux des captures : la scène « garden » en
prend quatre.

Les captures d'appareil sont l'écran entier, avec la place de la barre
d'état en haut (marqueur `.device` dans le dossier) : `compose.py` y
dessine la sienne, l'heure d'Apple.

### Sur le web (à défaut)

Le build web imite iOS (`?demo&ios`) sans être l'app : les composants
Cupertino y sont dessinés par Flutter, pas par le système, et le modèle
d'identification n'y tourne pas. Ce chemin reste utile pour vérifier une
composition sans Mac.

Ce repli ne vaut que pour l'iPhone : la feuille « Espèce » redessinée est
taillée pour une capture de téléphone, et l'iPad n'a pas d'autre source que
son simulateur.

```bash
flutter build web --profile --no-web-resources-cdn
python3 store/serve.py 8081 build/web &

# Les photos de démo (CC0, voir demo-photos/SOURCES.md) à côté du build
cp -r store/demo-photos build/web/

# Captures (390 × 844 à 3×), données de démo, iOS imité
node store/capture.mjs store/shots-fr fr-FR
node store/capture.mjs store/shots-en en-US
node store/capture.mjs store/shots-de de-DE
node store/capture.mjs store/shots-it it-IT

# Composition
pip install pillow numpy
python3 store/compose.py store/shots-fr store/fr fr
python3 store/compose.py store/shots-en store/en en
python3 store/compose.py store/shots-de store/de de
python3 store/compose.py store/shots-it store/it it
```

Sans capture `capture.png` — l'étape photo demande une photo, que le web ne
sait pas fournir —, `compose.py` redessine la feuille « Espèce » sur
`plant-ficus.png`, avec les résultats mesurés par `ident/score.py`. Le
troisième visuel montre alors la feuille plutôt que l'étape photo : les deux
disent la même chose de l'app, l'une après l'autre dans le parcours.

Le viseur lui-même n'est capturé nulle part : ni le web ni le simulateur
n'ont de caméra, et la capture ne montrerait qu'un cadre vide.

`capture.mjs` demande Playwright (`npm i playwright`) ; la variable `CHROMIUM`
peut pointer un binaire précis. Les emojis de l'app sont fournis par Flutter
web depuis Google Fonts : quand le navigateur ne peut pas y aller directement,
le script relaie ces requêtes par `curl`, qui suit le proxy de la machine.

`compose.py` télécharge la police Inter (SIL OFL) dans `store/fonts/` au
premier lancement ; Bricolage Grotesque vient de `assets/fonts/`. Les captures et les polices ne sont pas versionnées.

L'iPhone Duo a sa propre taille de visuel — 2007 × 2853 pour l'écran
intérieur —, mais App Store Connect n'en accepte pas encore le dépôt : la
série iPhone 6,7 pouces vaut pour lui aussi en attendant. Quand la case
s'ouvrira, ce sera un troisième gabarit dans `FORMATS` et un troisième passage
de `capture_ios.sh`, avec un cadre d'appareil ouvert à dessiner.

Les objets d'argile ne sont jamais agrandis au-delà de leur taille native
(`crisp()`) : ces images font 640 ou 1024 pixels, et les étirer plus loin
les fait fondre.

Les textes des visuels sont dans `compose.py` (`COPY`), coupés à la main pour
que chaque titre tienne sur deux lignes ; la taille est commune aux sept
captures et calculée par gabarit. L'ordre des écrans, les teintes et les objets sont dans `SCENES` ;
les textes de la fiche d'ouverture dans `COVER` ; le verre dépoli est
`glass()`, l'argile `clay_shape()`.
