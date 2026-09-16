# La scène d'environnement idéal

Une fiche d'entretien dit tout en cartes : lumière, arrosage, eau,
température, humidité, substrat… Avant ce détail, le héros qui ouvre la
fiche répond en une image à une seule question : **où cette plante
serait-elle bien ?**

La scène est un résumé spatial et climatique, pas une illustration. Sa
géométrie encode l'information :

- la distance à la fenêtre (ou à la haie) = le besoin de lumière ;
- la position par rapport à la tache de soleil = direct ou indirect ;
- la luminosité du décor = l'intensité lumineuse ;
- l'humidificateur et sa vapeur = l'air humide ;
- les lignes de flux = l'air qui bouge, quand la fiche le sait ;
- pièce ou jardin = le milieu de culture ;
- la silhouette = le type de plante.

Le détail reste dans les cartes, juste en dessous : la scène ne remplace
rien, elle prépare la lecture.

## L'architecture

**Blender headless → couches pré-rendues → composition Flutter.** Pas de
moteur 3D embarqué, pas de `.blend` dans l'app, pas de réseau : quelques
dizaines d'images WebP transparentes, superposées par un `Stack`.

```
assets/care_scene/
    indoor/light/    shade … full_sun      la pièce, six lumières
    outdoor/light/   shade … full_sun      le jardin, six lumières
    plants/          monstera, broad_leaf, upright_leaf, vine,
                     fern, rosette, cactus, conifer, orchid
    props/           humidifier
```

Dans l'application, `CareEnvironmentScene` empile : le décor lumineux,
l'humidificateur si l'air est humide, l'ombre, la plante translatée sur son
emplacement, la vapeur et les lignes de flux dessinées en `CustomPainter`,
puis les puces d'information.

L'air qui bouge n'a pas de prop : un courant d'air entre par une ouverture —
la fenêtre dans la pièce, le côté ouvert du jardin dehors —, il ne sort pas
d'une machine. Seules ses lignes de flux sont dessinées.

### La caméra à cadre fixe

Toutes les couches sortent de **la même caméra orthographique, au cadrage
fixe** (`tool/care_scene/common.py`) : position, `ortho_scale` et visée
calculés une fois pour toutes sur les bornes du diorama — jamais sur le
contenu d'une couche. C'est la condition de la composition : deux couches
au contenu différent doivent obtenir exactement le même cadre.

`studio()` de `tool/clay_scene.py`, qui cadre chaque sujet au plus juste,
ne convient donc pas ici. Les objets clay habituels (icône, collection,
guides) gardent leur propre caméra — plus basse (14° contre 32°) — et leurs
images ne se mélangent pas avec celles de la scène.

### La table des emplacements

La plante est rendue seule, au centre du monde ; l'application la translate
jusqu'à l'emplacement qui dit son besoin. Les positions — six
**emplacements** (`CarePlantSlot`), l'ancre de la plante, la place de
l'humidificateur et son haut, l'ouverture d'où souffle l'air — sont
**projetées par le build Blender** et livrées en constante Dart
(`lib/features/species/application/care_environment_slots.dart`, généré,
commité). La géométrie de la scène est la source de vérité : rien n'est
accordé à la main côté application, et le faisceau baké dans le décor
coïncide avec les emplacements au pixel près.

## Le modèle de données

`careEnvironmentSpec()` (`lib/features/species/application/care_environment_spec.dart`)
est une projection pure et déterministe : `CareProfile` + nom scientifique +
famille + catégorie → `CareEnvironmentVisualSpec`. Elle consomme
directement `LightNeed` et `HumidityNeed` — pas d'énumérations miroirs — et
se teste sans widget (`test/features/care_environment_test.dart`).

**Rien n'est inventé.** Une information absente de la fiche n'apparaît pas
dans la scène :

- la température ne se montre que si la plage idéale (ou le seuil de
  dégâts) est connue ;
- l'air qui bouge n'apparaît que si `CareProfile.airflow` est renseigné —
  `null` signifie « non renseigné » et ne devient jamais « éviter les
  courants d'air ». Le champ est optionnel, propagé par `CareOverride`
  (Care Studio peut le retoucher) et ignoré par la complétion IA, qui ne se
  prononce pas ;
- l'humidificateur ne paraît que pour `HumidityNeed.high`.

### Pièce ou jardin

La règle est centralisée dans `environmentFor`, nulle part ailleurs :

| Données | Scène |
|---|---|
| `tree`, `fruit`, `vegetable` | jardin |
| `indoor`, `succulent` | pièce |
| `herb`, `flower` | jardin si rustique (`frostHardy`), pièce sinon |
| pas de catégorie | pièce (repli) |

Un arbre ne finit jamais dans un salon. Les deux décors partagent caméra,
bornes et direction de soleil : la table des emplacements vaut pour l'un
comme pour l'autre.

### Les six lumières

| `LightNeed` | Emplacement | Décor |
|---|---|---|
| `shade` | `backCorner` | le plus sombre, loin de la fenêtre |
| `lowLight` | `back` | arrière de pièce |
| `indirect` | `middle` | lumière diffuse |
| `brightIndirect` | `nearWindowOutsideBeam` | pièce lumineuse, tache de soleil **à côté** de la plante |
| `someSun` | `nearWindowEdgeOfBeam` | au bord de la tache |
| `fullSun` | `sunZone` | dans le soleil |

La plante garde le même éclat d'une variante à l'autre : c'est le décor —
luminosité, fenêtre, faisceau — qui porte l'information, pas un
ré-éclairage de la plante (ce qui aurait multiplié les rendus par six).

## Les silhouettes

Neuf archétypes, pas 1 900 modèles. Le résolveur (`resolvePlantVisual`)
décide dans l'ordre : l'espèce nommée, le genre, la famille, la catégorie
d'usage, et enfin le repli `broadLeaf` — une feuille large vaut mieux
qu'une mauvaise fougère.

| Archétype | Exemples |
|---|---|
| `monstera` | Monstera (genre entier) |
| `uprightLeaf` | dracaena, sansevieria, palmiers (famille, en attendant leur silhouette) |
| `vine` | epipremnum, scindapsus, misère, lierre, cissus, chaîne des cœurs, philodendron grimpant |
| `fern` | nephrolepis, asplenium, adiantum, platycerium |
| `rosette` | succulentes non cactées (catégorie) |
| `cactus` | Cactaceae |
| `conifer` | Pinaceae |
| `orchid` | phalaenopsis, dendrobium, cymbidium, oncidium |
| `broadLeaf` | tout le reste |

Un genre ne se range dans la table que si la forme tient pour tout le
genre : le philodendron est mixte (le grimpant retombe, le selloum pousse
comme un arbre), sa règle reste donc à l'espèce. Les orchidées terrestres du
catalogue étendu (ophrys, céphalanthère) gardent elles aussi la feuille
large : la silhouette en pot ne leur va pas.

### L'échelle

Les recettes de silhouette viennent de la collection de l'onboarding, où la
plante est rendue seule : sa taille absolue n'y veut rien dire. Dans le
diorama, elle partage le cadre avec une pièce de 4,2 m sur 3,6 m, un
guéridon et un humidificateur modelés à l'échelle réelle.
`plants.ECHELLE_PIECE` réduit donc tout l'assemblage autour de l'ancre
avant le rendu : le monstera fait 1,5 m, pot compris, et tient dans la
pièce aux six emplacements. À l'échelle des recettes, il faisait 3,3 m de
large dans un pot de 1,3 m — ses feuilles traversaient les murs et
sortaient du diorama, à côté d'un humidificateur haut de 47 cm.

### Ajouter une silhouette

1. la construire dans `tool/care_scene/plants.py` (une entrée `PLANTES`,
   un constructeur) — les primitives sont dans `tool/clay_scene.py` et
   `tool/cutting/common.py` ; la bâtir à la taille des recettes,
   `ECHELLE_PIECE` la met à l'échelle de la pièce au rendu ;
2. la rendre : `python3 tool/build_care_scene_assets.py --only <nom>` ;
3. une valeur dans `PlantVisualKind` et son chemin dans
   `CareEnvironmentVisualSpec.plantAsset` ;
4. la règle du résolveur (espèce, genre ou famille) et ses tests ;
   `test/assets/care_scene_assets_test.dart` exige l'image pour chaque
   valeur de l'énumération.

### Ajouter un état

Une variante de lumière : une entrée dans `room.VARIANTES` et
`outdoor.VARIANTES`, le rendu des deux groupes, et le mapping côté
projection. Un prop : un modèle dans `tool/care_scene/props.py`, sa place
dans l'export de `build_care_scene.py` si elle dépend de l'emplacement, la
couche dans `CareEnvironmentScene`, le dossier dans le pubspec.

## Les effets dessinés

La vapeur et les lignes de flux ne sont **pas** des images : ce sont des
`CustomPainter` dans `CareEnvironmentScene`. Trois raisons : le reduced
motion peut les figer proprement, le contraste les restyle avec le thème,
et le flux à abriter doit passer **à distance de la plante**, qui bouge —
une couche bakée ne le pourrait pas.

Les effets respirent trois cycles à l'ouverture puis se reposent : rien ne
bouge en permanence dans la fiche. En reduced motion, ils sont statiques et
lisibles. L'ombre de la plante est une ellipse douce dessinée sous son
emplacement : elle ne flotte jamais.

## Régénérer les assets

```bash
# tout, de Blender au WebP livré, avec le récapitulatif des poids
python3 tool/build_care_scene_assets.py
# aperçu rapide + planche contact dans /tmp/care_scene (ne livre rien)
python3 tool/build_care_scene_assets.py --preview
# un groupe, une seule lumière, plante ou prop
python3 tool/build_care_scene_assets.py indoor
python3 tool/build_care_scene_assets.py --only monstera
# juste le poids de ce qui est livré
python3 tool/build_care_scene_assets.py --poids
```

Blender est cherché dans le `PATH` puis aux endroits usuels ; rien n'est
installé. Les PNG intermédiaires restent dans `/tmp/care_scene`, hors Git.
Résolution de livraison : 1024 px (le héros s'affiche à 320–380 logical
px, soit ~1 000 px physiques sur écran @3x).

**Budget de poids : 8 Mo** pour toute la fonctionnalité. La vague 1 pèse
~0,4 Mo ; le test d'assets verrouille le total.

## Idéal et réel

La scène montre **l'environnement recommandé par la fiche**, jamais l'état
réel de la pièce. La comparaison avec les conditions mesurées reste à
`HomeClimateFitCard`, juste en dessous. Ne pas substituer la lumière de
l'emplacement à `profile.light` pour décider où la plante apparaît.

## Accessibilité et thèmes

- La description sémantique du héros est une phrase unique, limitée à ce
  qui est réellement montré ; les images sont exclues de la sémantique.
- Les puces sont superposées au diorama à taille normale, repliées sous la
  scène à forte échelle de texte (testé à 200 % et 350 %).
- Les informations indispensables ne reposent jamais sur la couleur seule :
  l'air à abriter est aussi écrit sur sa puce.
- Le diorama a ses propres murs et sols sur fond transparent : il garde son
  identité en thème sombre, les effets dessinés suivent les tokens.

## Les tests

- `test/features/care_environment_test.dart` — la projection : six
  lumières, humidité, température, air, règle pièce/jardin, silhouettes,
  table des emplacements ;
- `test/features/care_guide_test.dart` — le héros : présence, puces
  honnêtes, sémantique, Dynamic Type, reduced motion, `paper: false`,
  props et effets selon la fiche ;
- `test/assets/care_scene_assets_test.dart` — les fichiers : chaque
  lumière, silhouette et prop existe, en-tête RIFF/WEBP, chemins du
  résolveur, poids sous le budget, déclarations du pubspec.
