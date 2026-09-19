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
- l'humidificateur et sa vapeur = l'air humide, seulement si la fiche prescrit
  la machine ;
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
    balcony/light/   shade … full_sun      le balcon, six lumières
    outdoor/light/   shade … full_sun      le jardin, six lumières
    plants/          monstera, broad_leaf, upright_leaf, vine,
                     fern, rosette, cactus, conifer, orchid
    props/           humidifier, pedestal
```

Dans l'application, `CareEnvironmentScene` empile : le décor lumineux, le
guéridon posé sur l'emplacement lumineux quand la plante s'y pose (un prop
rendu seul, comme l'humidificateur), l'humidificateur si la fiche prescrit
la machine, l'ombre, la plante
translatée sur son support, la vapeur et les
lignes de flux dessinées en `CustomPainter`, puis les puces d'information.
Le diorama est une maquette posée dans la fiche : son cadre s'arrondit au
rayon des cartes (`Radii.large`).

L'air qui bouge n'a pas de prop : un courant d'air entre par une ouverture —
la fenêtre dans la pièce, le côté ouvert du jardin dehors —, il ne sort pas
d'une machine. Seules ses lignes de flux sont dessinées.

### La caméra à cadre fixe

Toutes les couches sortent de **la même caméra orthographique, au cadrage
fixe** (`tool/care_scene/common.py`) : position, `ortho_scale` et visée
posés par les constantes `CADRE_*` — jamais calculés sur le contenu d'une
couche. C'est la condition de la composition : deux couches au contenu
différent doivent obtenir exactement le même cadre. Et c'est pour cela que
le cadre est en constantes plutôt que déduit de la géométrie : s'il suivait
le contenu, ajouter un prop le déplacerait, et avec lui la table des
emplacements et toutes les images.

**Le cadre n'est pas carré.** Il l'a été, et il perdait près d'un quart de
sa surface : le contenu des trois décors et des silhouettes tient en 6,34
de large sur 5,64 de haut, et la visée n'était pas centrée dessus — le
diorama flottait dans un carré trop haut, la plante d'autant plus petite.
Le cadre livré fait **1024 × 910** (rapport 1,125) et la caméra monte de
`CADRE_VISEE_U` pour centrer le contenu. L'occupation du cadre est passée
de 88 × 78 % à 94 × 94 %, et la part transparente de 53 % à 39 %.

`CareEnvironmentSlots.aspect` porte ce rapport : côté Flutter, l'`AspectRatio`
du héros suit le pipeline sans rien à changer.

Deux pièges à connaître si on retouche le cadre. `world_to_camera_view` lit
le format de la scène : toute projection doit le poser avant de projeter,
sinon les *y* sortent compressés par le 16:9 par défaut de Blender et la
plante ne tombe plus sur son ombre. Et `rendu_transparent` de `clay_scene`
est partagé avec les autres objets clay, qui se rendent au carré : le format
se repose **après** lui.

`studio()` de `tool/clay_scene.py`, qui cadre chaque sujet au plus juste,
ne convient donc pas ici. Les objets clay habituels (icône, collection,
guides) gardent leur propre caméra — plus basse (14° contre 32°) — et leurs
images ne se mélangent pas avec celles de la scène.

### La table des emplacements

La plante est rendue seule, au centre du monde ; l'application la translate
jusqu'à l'emplacement qui dit son besoin. Les positions — six
**emplacements** (`CarePlantSlot`), l'ancre de la plante, le plateau du
guéridon dans son image, la place de
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
- l'humidificateur ne paraît que si `HumidityNeed.high` **et** que la fiche
  prescrit `HumidityMethod.humidifier`. La brume, le plateau, le terrarium,
  ou un besoin sans méthode, ne posent pas de machine. Le plateau de billes
  est décidé par la projection (`hasHumidityTray`) ; son image n'est pas
  encore livrée, la scène ne l'affiche pas.

### Pièce, balcon ou jardin

Trois décors, pour trois façons de vivre : dedans, dehors mais en pot, ou
dehors en pleine terre. Les deux notions qui départagent existaient déjà
dans la fiche, avec exactement ce sens :

- `CareProfile.frostHardy` (`winterMinC ≤ 0`) — elle tient le gel, **donc
  elle vit dehors en pleine terre** ;
- `CareProfile.outdoorFriendly` — elle passe la belle saison dehors, sans
  pour autant la passer en terre.

Entre les deux, il y a le balcon. La règle est centralisée dans
`environmentFor`, nulle part ailleurs :

| Données | Scène |
|---|---|
| `tree`, `fruit`, `vegetable` | jardin si rustique, **balcon** sinon |
| `herb`, `flower` | jardin si rustique ; **balcon** si `outdoorFriendly` ; pièce sinon |
| `indoor`, `succulent` | pièce |
| pas de catégorie | pièce (repli) |

Ce que le balcon corrige : un citronnier — `fruit`, non rustique — était
planté dans une pelouse, et une aromatique gélive était envoyée dans le
salon alors que sa place est dehors en pot. Sur le catalogue livré, la règle
déplace une soixantaine d'espèces, surtout des fruitiers et des légumes.

Rien n'est inventé : sans `outdoorFriendly`, une plante gélive dont la fiche
ne dit pas qu'elle sort reste dans la pièce.

**Les succulentes restent dedans quoi qu'il arrive.** Le catalogue en compte
deux fois plus de plantes d'appartement que de rustiques, et leur appliquer
la règle déplacerait une trentaine de fiches pour un gain discutable. La
ligne des aromatiques leur irait telle quelle le jour où on le décide.

Un arbre ne finit jamais dans un salon. Les trois décors partagent caméra,
bornes et direction de soleil : la table des emplacements vaut pour l'un
comme pour les autres. Le garde-corps du balcon est du même côté que la
fenêtre de la pièce et la haie du jardin, si bien que la plante s'approche
toujours de la lumière dans le même sens. Ils partagent aussi **la même
dalle** : le jardin et le balcon sont des maquettes posées, exactement comme
la pièce, et le vide autour reste transparent. C'est ce qui leur donne le même statut dans la fiche — un
jardin qui remplirait le cadre bord à bord ferait changer le décor de
nature d'une espèce à l'autre, maquette d'un côté, photo pleine page de
l'autre.

Tous deux restent en retrait — la plante est le sujet. La pièce est
habitée : plinthes, tapis, cadres au mur, console et ses livres,
lampadaire dans l'angle, pouf, une pile de livres posée au sol contre le
fauteuil, un coin salon.

Le décor n'a pas vocation à se remplir : un bac en bois a été retiré du coin
salon parce qu'on ne savait pas ce qu'il faisait là et qu'il pouvait se lire
comme un pot sans plante. Ce qui l'a remplacé — la pile de livres — est
rectangulaire et bas, là où la table basse, le guéridon et le pouf sont
ronds, et il répète le motif des livres de la console : les deux côtés de la
pièce se répondent. Le jardin dit « dehors » sans devenir un
jardin botanique : pelouse sauge, massif de pleine terre là où la plante se
pose, allée de gravier et pas japonais, palissade bordée de touffes
fleuries, haie basse, un petit arbre, un arrosoir. Le balcon dit « dehors,
mais chez soi » : lames de terrasse, façade et sa porte-fenêtre, garde-corps
de métal sombre, jardinière accrochée, tabouret, paillasson, le même
arrosoir que le jardin — c'est la même main qui s'occupe de la plante.

### Rien ne passe devant la plante

La règle est **à l'écran, pas dans la pièce**. La vue est orthographique :
deux objets éloignés de deux mètres s'y superposent parfaitement. Un
lampadaire posé dans le coin opposé montait ainsi pile sous le pot à quatre
emplacements sur six, et la plante avait l'air vissée dessus — une
vérification en coordonnées monde ne voyait rien.

`common.verifie_couloir` la tient maintenant à chaque rendu. Elle projette
les sommets du mobilier — pas sa boîte englobante, qu'une plinthe ou un
tapis rendent énorme — et signale ce qui recoupe la silhouette de la plante
en étant plus proche de la caméra que l'emplacement concerné, d'au moins
un demi-mètre. En deçà, l'objet est à la profondeur de l'emplacement : le
signaler serait du bruit.

Passer **derrière** la plante n'est pas une faute, c'est ce qui donne sa
profondeur à la scène : la console du fond et ses cadres sont partiellement
masqués quand la plante se pose au fond, et c'est très bien ainsi.

### Les six lumières

| `LightNeed` | Emplacement | Décor |
|---|---|---|
| `shade` | `backCorner` | le plus sombre, loin de la fenêtre |
| `lowLight` | `back` | arrière de pièce |
| `indirect` | `middle` | lumière diffuse |
| `brightIndirect` | `besideBeam` | pièce lumineuse, tache de soleil **à côté** de la plante |
| `someSun` | `beamEdge` | au bord de la tache |
| `fullSun` | `sunZone` | dans le soleil |

Les six emplacements tiennent sur **une droite, à pas constant** : du fond
de la pièce jusque dans la tache de soleil, la plante avance d'un cran par
cran de lumière, toujours du même pas et dans le même sens. La distance à
la fenêtre décroît donc strictement, et les trois derniers crans se lisent
sur la tache — à côté, sur son bord, dedans. Six positions choisies une par
une se liraient comme un hasard : d'une fiche à l'autre, la plante
sauterait d'un coin de la pièce à l'autre. `tool/care_scene/common.py` pose
le départ et le pas, le reste en découle ; `test/features/care_environment_test.dart`
vérifie l'ordre et la régularité du pas. Le départ garde une marge de
sécurité avec les murs du fond et de droite (`MARGE_PIECE`) : la silhouette
la plus large ne frôle aucun mur, à quelque cran que ce soit.

L'humidificateur suit la plante d'un décalage d'écran constant, toujours du
même côté — entre elle et la fenêtre : lui aussi doit se retrouver au même
endroit d'une fiche à l'autre.

La plante n'est **rendue qu'une fois**, dans son propre studio : la rendre
six fois, une par lumière, aurait multiplié les images par six. Mais elle ne
garde pas pour autant le même éclat d'une variante à l'autre — sans rien,
elle brillait au fond d'une pièce sombre comme dans la tache de soleil et se
lisait comme une vignette collée. `_lumiereDeLaScene`
(`care_environment_scene.dart`) lui applique un gain par canal et un peu de
saturation, par variante, et la même teinte au guéridon et à
l'humidificateur. Zéro octet livré, et la plante entre dans la lumière de la
pièce. C'est le décor qui porte l'information de lumière ; le filtre ne fait
que l'accorder.

## Les silhouettes

Neuf archétypes, pas 1 900 modèles. Le résolveur (`resolvePlantVisual`)
décide dans l'ordre : l'espèce nommée, le genre, la famille, la catégorie
d'usage, et enfin le repli `broadLeaf` — une feuille large vaut mieux
qu'une mauvaise fougère.

Chaque archétype porte **entre neuf et quatorze organes** — feuilles, lames,
frondes, raquettes. À trois ou quatre, la plante se lisait comme un croquis :
on voyait à travers, et aucun réglage de lumière ou d'ombre ne rattrapait
ça. Les tables de `tool/care_scene/plants.py` sont la seule chose à toucher
pour en ajouter ; le test d'assets vérifie qu'aucune silhouette ne sort du
diorama à quelque emplacement qu'elle se pose, et c'est lui qui borne la
densité.

Deux pièges rencontrés en les densifiant : des organes régulièrement
espacés le long d'une tige font un peigne, il faut les faire alterner de
part et d'autre ; et une irrégularité trop forte entre les étages du
conifère le transforme en glace à l'italienne — la régularité valait
mieux.

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
guéridon, un coin salon et un humidificateur modelés à l'échelle réelle.
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
lisibles.

L'ombre, elle, **fuit la fenêtre** : dans les deux décors le jour vient de
la gauche, et l'ombre bakée du fauteuil part vers la droite. Une ellipse
centrée et symétrique contredisait cette lumière et nimbait l'objet au lieu
de le poser. Chaque contact reçoit donc deux passes — un noyau serré qui
fait le contact, un halo large et clair pour l'ombre portée, tous deux
décalés à l'opposé de la fenêtre. Une seule ellipse très floue ne donnait
ni l'un ni l'autre.

## Régénérer les assets

```bash
# tout, de Blender au WebP livré, avec le récapitulatif des poids
python3 tool/build_care_scene_assets.py
# aperçu rapide + planche contact dans /tmp/care_scene (ne livre rien)
python3 tool/build_care_scene_assets.py --preview
# un groupe, une seule lumière, plante ou prop
python3 tool/build_care_scene_assets.py indoor balcony
python3 tool/build_care_scene_assets.py --only monstera
# juste le poids de ce qui est livré
python3 tool/build_care_scene_assets.py --poids
```

Blender est cherché dans le `PATH` puis aux endroits usuels ; rien n'est
installé. Les PNG intermédiaires restent dans `/tmp/care_scene`, hors Git.
Résolution de livraison : 1024 px (le héros s'affiche à 320–380 logical
px, soit ~1 000 px physiques sur écran @3x).

**Budget de poids : 8 Mo** pour toute la fonctionnalité. Les trois décors,
leurs silhouettes et leurs props pèsent ensemble moins de 0,6 Mo ; le test
d'assets verrouille le total.

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

Ce dernier tient deux invariants **différents**, et c'est voulu. Dans la
pièce, les murs bornent la plante : toute la silhouette doit tomber sur le
décor, sinon elle traverse un mur. Dehors et au balcon, il n'y a que du
transparent au-dessus de la dalle : une plante y dépasse dans le ciel, et
c'est normal. Ce qui doit tenir là, c'est le **pied** — le pot se pose sur
le sol, jamais dans le vide à côté de la dalle. Confondre les deux a failli
faire passer pour une régression le jour où le jardin est devenu une
maquette posée.
