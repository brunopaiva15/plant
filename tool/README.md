# Outils de construction du catalogue d'espèces

Le catalogue hors ligne d'Auxine a deux étages :

| Étage | Fichier | Contenu | Rôle |
|---|---|---|---|
| Trié à la main | `lib/data/species/species_catalog.dart` | ~300 espèces, avec catégorie | Parcours par thème, fiches d'entretien |
| Étendu | `assets/species/catalog.tsv` | ~30 000 espèces, sans catégorie | Recherche hors ligne |

Au-delà, la recherche GBIF en ligne couvre les ~450 000 espèces de plantes
restantes. L'étage étendu existe pour qu'un utilisateur hors réseau trouve
« edelweiss », « stella alpina » ou « Gelber Enzian » sans rien télécharger.

## Sources et licences

- **Wikidata** — noms scientifiques et noms vernaculaires en fr/de/it/en.
  Domaine public (CC0), aucune contrainte d'attribution, mais l'écran
  « À propos » les cite tout de même.
- **GBIF Backbone Taxonomy** — correspondance genre → famille. CC BY 4.0.

Aucune des deux ne facture ni ne demande de clé. Les scripts s'annoncent avec
un `User-Agent` identifiable, comme les deux services le demandent.

## Régénérer le catalogue

```bash
# 1. Genres de plantes et leur famille, depuis GBIF (~2 min)
python3 tool/fetch_genera.py /tmp/genus_family.json /tmp/all_genera.txt

# 2. Écarter les genres sans article dans nos langues (~3 min)
python3 tool/screen_genera.py /tmp/all_genera.txt /tmp/notable.txt

# 3. Moissonner les espèces et leurs noms (~45 min à trois processus).
#    Le troisième argument est indispensable : il apparie chaque genre à sa
#    famille GBIF, ce qui écarte les homonymes d'autres règnes.
python3 tool/harvest_species.py /tmp/notable.txt /tmp/harvest.tsv /tmp/genus_family.json

# 4. Filtrer, choisir le nom principal par langue, écrire l'actif
python3 tool/build_species_catalog.py /tmp/harvest.tsv /tmp/genus_family.json \
    assets/species/catalog.tsv
```

L'étape 3 est reprenable : elle note les genres traités dans
`<sortie>.done` et saute ceux-là au relancement. Pour aller plus vite, on
découpe la liste de genres en trois et on lance trois processus vers des
fichiers de sortie distincts, puis on les concatène.

## Les homonymes d'autres règnes

Un nom de genre n'est pas unique entre les règnes : « Batis » est un arbuste
halophile et un gobe-mouches africain, « Oenanthe » une ombellifère et un
traquet, « Glaucidium » une renonculacée et une chevêchette, « Morelia » une
rubiacée et un python. Moissonnée par nom de genre seul, la première version
du catalogue a fait entrer environ 160 oiseaux, poissons et papillons, avec
la famille de la plante homonyme. La moisson exige désormais que le genre
Wikidata remonte à une famille du même nom que celle donnée par GBIF, et le
test de l'actif vérifie qu'aucun de ces noms n'y figure.

## Ce que fait le filtre

Wikidata répète le nom scientifique en guise de libellé quand aucun nom
courant n'existe, et range parfois des synonymes latins parmi les alias.
`build_species_catalog.py` écarte donc toute valeur qui est un binôme latin,
reconnue par son genre (présent dans l'ossature GBIF) ou par sa morphologie
(terminaisons `-us`, `-folia`, `-ensis`…). Une espèce sans aucun nom courant
dans les quatre langues n'entre pas dans le catalogue : elle n'aiderait
personne à chercher, et la recherche GBIF la couvre déjà.

Le test `test/data/species_catalog_asset_test.dart` vérifie l'actif produit :
volume, absence de doublons, absence de faux noms vernaculaires, et présence
de quelques espèces témoins.

# La plante qui pousse (écran de bienvenue)

`build_monstera.py` construit l'icône de l'application : la scène, les
matériaux « pâte à modeler », la caméra orthographique et l'éclairage studio.
`grow_monstera.py` reprend tout cela et rend la même plante à quarante âges,
de la terre nue à l'adulte ; `pack_growth.py` en fait l'image animée que joue
le premier écran de l'onboarding. Seule la plante change d'une image à
l'autre — la dernière est exactement l'icône.

Ce qui bouge entre deux images vient de la vraie plante : les feuilles sortent
l'une après l'autre, la plus vieille d'abord ; chacune émerge en fuseau
presque vertical, étroite et entière ; elle s'allonge, s'écarte, s'élargit,
puis se découpe — fentes d'abord, fenestrations ensuite. Une jeune feuille de
Monstera n'a ni fente ni trou, ils viennent avec l'âge.

Le fond est transparent et sans ombre portée : l'ombre au sol et le
flottement sont dessinés par l'application, qui les accorde à son thème.

```bash
# ~15 min sur quatre cœurs (Cycles, CPU)
blender -b -noaudio -P tool/grow_monstera.py -- 40 1024 40 /tmp/pousse
python3 tool/pack_growth.py /tmp/pousse assets/onboarding/pousse.webp --fps 14
```

La caméra est cadrée une fois pour toutes sur la plante adulte : sans cela,
le cadrage automatique suivrait la plante qui grandit et elle semblerait
immobile pendant que le monde rétrécit autour d'elle.

# La collection qui gravite (« Toutes vos plantes, ici »)

`build_collection.py` rend cinq plantes, chacune seule dans son image : un
monstera, un caoutchouc à feuilles entières, une sansevieria en lames droites,
une petite plante ronde, un semis. Les cinq sortent des mêmes primitives que
l'icône — c'est la largeur relative du limbe, sa longueur et son nombre de
fentes qui changent la silhouette. L'application les pose ensuite côte à côte
et les fait dériver, chacune sur son ellipse et à son rythme.

```bash
# ~2 min sur quatre cœurs
blender -b -noaudio -P tool/build_collection.py -- 640 48 /tmp/collection
# puis, en WebP (30 Ko par plante au lieu de 370 Ko en PNG) :
python3 -c "from PIL import Image; import glob, os
for f in glob.glob('/tmp/collection/*.png'):
    Image.open(f).convert('RGBA').save('assets/onboarding/' + os.path.basename(f)[:-4] + '.webp', quality=92, method=6)"
```

# Les guides de multiplication (sept archétypes)

`build_cutting_guide.py` rend les séquences des guides qui s'ouvrent avant la
création d'une plante fille. Un guide par **geste**, pas par famille
botanique : bouture de tige à nœud (`stem_node_vine`), de tige tendre
(`stem_soft`), de feuille (`leaf_cutting`), division d'une touffe
(`division`), séparation d'un rejet (`offset`), séparation du rejet d'une
orchidée (`keiki`), bouture de segment (`succulent_segment`). Même argile,
même studio, même caméra que l'icône ; l'ombre et le flottement sont dessinés
par l'application.

Chaque archétype a son module sous `tool/cutting/`, et sa plante. Le pothos
de la liane a ses feuilles en cœur et ses nœuds renflés ; la touffe de la
division a des feuilles lancéolées sur de longs pétioles et une motte ; la
rosette du rejet a des feuilles charnues ; le phalaenopsis du keiki a des
feuilles larges, une hampe arquée et des fleurs, et son rejet naît en l'air
sur un nœud de la hampe ; le sansevieria de la feuille a des lames en glaive,
taillées en V pour que le bas se reconnaisse ; le cactus a des raquettes
articulées et une plaie qui pâlit en séchant. Tout ce qui se répète — amortis,
limbes, rubans charnus, anneaux, ciseaux, pot, verre, motte, racines, palette,
boucle de rendu — est dans `tool/cutting/common.py`.

Le verre et l'eau sont des « voiles » : une surface claire mêlée de
transparence pure, sans réfraction — un vrai verre en transmission grouille
de bruit à ces réglages et assombrit les racines.

Chaque étape est cadrée une fois pour toutes sur l'union de ses images
clefs ; sans cela le cadre suivrait le sujet et c'est le monde qui semblerait
bouger. Et une racine ne traverse pas la paroi de son pot : `Creux` décrit le
volume intérieur d'un contenant, `faisceau_racines(dans=…)` y ramène le tracé.

```bash
# tout, de Blender au WebP livré, avec le récapitulatif des poids (~1 h 45)
python3 tool/build_cutting_assets.py
# aperçu : quatre images par étape
python3 tool/build_cutting_assets.py --preview
# un ou deux archétypes, une seule étape
python3 tool/build_cutting_assets.py division offset
python3 tool/build_cutting_assets.py --etape cut succulent_segment
# juste le poids de ce qui est livré
python3 tool/build_cutting_assets.py --poids
```

Sans l'orchestrateur, Blender se lance directement :

```bash
blender -b -noaudio -P tool/build_cutting_guide.py -- complet all --res 768 --samples 24
blender -b -noaudio -P tool/build_cutting_guide.py -- apercu stem_node_vine
python3 tool/pack_growth.py /tmp/multiplication/division/separate assets/cutting/division/separate.webp --fps 14
```

`test/assets/propagation_sequences_test.dart` vérifie que chaque étape de
chaque archétype est embarquée, carrée, animée, transparente et pas trop
lourde. L'architecture des guides côté application : `docs/12`.

# La scène d'environnement idéal (fiches d'entretien)

`build_care_scene.py` rend le diorama qui ouvre une fiche d'entretien : une
petite pièce clay dont la géométrie encode les besoins de la plante — la
distance à la fenêtre dit le besoin de lumière, la tache de soleil au sol
dit direct ou indirect. Six variantes de lumière (`shade` à `full_sun`),
même pièce, seuls la lumière, la vitre et le faisceau changent. Les espèces
de plein air (arbres, fruitiers, légumes, et les aromatiques ou fleurs
rustiques) ont leur propre décor : un coin de jardin avec pelouse, palissade
de bois, haie et boisement — même caméra, même direction de soleil, la table
des emplacements vaut d'une scène à l'autre. Les plantes sont rendues seules : `monstera`,
`broad_leaf` (le repli), `upright_leaf`, `vine`, `fern`, `rosette`,
`cactus`, `conifer`, `orchid` — neuf archétypes que le résolveur attache par
espèce, genre, famille et catégorie. L'application les pose sur l'emplacement
qui correspond au `LightNeed` de la fiche. Un prop dit le climat sans un
mot : l'humidificateur (air humide), posé à côté de la plante. L'air à
abriter n'a pas de prop — il entre par une ouverture, la fenêtre dedans ou
le côté ouvert du jardin dehors. La vapeur et les lignes de flux ne sont pas
rendues : l'application les dessine (reduced motion, et le flux doit passer à
distance de la plante, qui bouge).

Contrairement aux autres objets clay, toutes les couches partagent une
**caméra à cadre fixe** (`tool/care_scene/common.py`), calculée sur les
bornes de la pièce et non sur le contenu de chaque couche : `studio()` ne
convient pas ici, il recadrerait chaque couche sur son contenu et la
composition Flutter se décalerait. La table des emplacements de plante est
projetée par cette caméra et livrée en constante Dart
(`lib/features/species/application/care_environment_slots.dart`) — la
géométrie de la scène fait foi, rien n'est accordé à la main côté
application. La structure côté application : `docs/13` (à venir).

```bash
# tout, de Blender au WebP livré, avec le récapitulatif des poids (~15 min)
python3 tool/build_care_scene_assets.py
# aperçu rapide + planche contact dans /tmp/care_scene
python3 tool/build_care_scene_assets.py --preview
# un groupe, une seule lumière ou plante
python3 tool/build_care_scene_assets.py indoor
python3 tool/build_care_scene_assets.py --only monstera
# juste le poids de ce qui est livré
python3 tool/build_care_scene_assets.py --poids
```

Sans l'orchestrateur, Blender se lance directement :

```bash
blender -b -noaudio -P tool/build_care_scene.py -- complet all --res 1024 --samples 56
blender -b -noaudio -P tool/build_care_scene.py -- apercu indoor bright_indirect
```

# La maison (« Votre intérieur »)

`build_home.py` rend la maison d'argile de l'étape de la maison de
l'onboarding, dans le même studio et les mêmes matériaux que les autres
objets : murs crème, toit de terre cuite, porte sauge, fenêtres rondes
couleur d'eau, cheminée. Sans ombre au sol, comme les autres : l'application
la dessine.

```bash
# ~2 min sur quatre cœurs ; --resolution 512 --samples 16 pour un aperçu
blender -b -noaudio -t 4 -P tool/build_home.py -- --output assets/onboarding/onboarding_7.png
```

# Les quatre familles de problèmes

`build_category_logos.py` rend les symboles des quatre valeurs du champ `type`
de `assets/problems/catalog.txt` : une feuille au soleil avec sa goutte pour
les troubles abiotiques, un charançon pour les ravageurs, une feuille à
lésions pour les maladies, un dépôt sombre pour les affections. Aucun texte,
donc valables dans les quatre langues.

```bash
# ~3 min sur quatre cœurs
blender -b -noaudio -t 4 -P tool/build_category_logos.py -- --output build/category_logos
# puis recadrage commun et réduction en WebP 512 (~25 Ko par symbole)
python3 tool/pack_category_logos.py build/category_logos/renders
```

Le cadrage des rendus réserve de la place au mouvement, dont l'application n'a
pas besoin : `pack_category_logos.py` recadre sur le contenu avant de réduire.
Le recadrage est commun aux quatre, sans quoi le charançon grandirait et la
feuille rétrécirait, et la famille perdrait son unité d'échelle.

# Une illustration par problème

Les lots livrés contiennent des PNG 1 024 px nommés
`probleme_<id>_<titre>.png`. `pack_problem_icons.py` n'en garde que
l'identifiant, réduit à 512 px et écrit la liste des identifiants illustrés
dans `lib/features/problems/presentation/illustrated_problems.dart`.

```bash
python3 tool/pack_problem_icons.py <dossier de PNG> [<autre lot> …]
```

La liste est relue depuis `assets/problems/icons/` et non depuis ce qui vient
d'être écrit : elle décrit ce qui est embarqué, lots précédents compris. Un
test compare les deux, si bien qu'une image ajoutée ou retirée à la main se
voit tout de suite.

Pas de recadrage ici, contrairement aux symboles de familles : le cadrage
varie à dessein d'une illustration à l'autre, une feuille seule occupant moins
de place qu'une plante en pot, et les recadrer une par une les ramènerait
toutes à la même taille apparente.

`clay_scene.py` tient ce que ces scripts ont en commun : les primitives de
géométrie, les matériaux mats, le studio d'éclairage et le grain. Rien ne s'y
exécute à l'import.
