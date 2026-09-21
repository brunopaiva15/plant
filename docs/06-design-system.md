# F. Design system

Identité : **argile, terre cuite, fait main**. L'app ressemble à l'atelier
d'un potier : fond de papier crème, cartes qui semblent modelées, grands titres
tracés à la main. Le vert reste l'accent du soin, la terre cuite celui de
l'urgence.

Ce qu'on garde du design précédent : la grille, les cartes très arrondies, la
tab bar en pilule, les pastels par type de soin. Ce qui change : la matière.

## Matière : le clay (`design_system/components/clay.dart`)
Chaque surface est un `ClayBox`, peint par `ClayPainter` :
- une **ombre portée teintée** (brun terre en clair, noir en sombre), décalée
  en bas à droite ;
- un **reflet intérieur** blanc en haut à gauche et une **ombre intérieure** en
  bas à droite : c'est ce qui donne le relief modelé.
Tout est proportionné au plus petit côté (`unit`), donc une tuile de 56 px et
un héros de 300 px ont le même rendu.

- `ClayShape.rounded(r)` (cartes), `.pill()` (boutons, tab bar, barre de
  sélection, toast), `.blob(variant)` : quatre jeux de coins elliptiques,
  choisis par index pour que deux tuiles voisines ne soient jamais identiques
  (tuiles d'emoji, actions rapides).
- `ClayDepth.light` (cartes) · `deep` (boutons principaux, héros, éléments
  flottants).
- `GrainOverlay` : `assets/textures/grain.png` répété par-dessus l'app à 7 %
  (10 % en sombre). C'est le grain du papier ; il est ignoré par le pointeur.

Une `FloraChip` accepte une pièce dessinée devant son libellé (`leading`) plutôt
qu'un emoji : c'est ce qui porte les illustrations d'argile des problèmes de
santé, dans la feuille d'édition d'une plante (voir docs/04).

`FloraChoice` en assemble plusieurs sous un libellé : un choix facultatif dont
une seule puce est allumée, qu'un second toucher éteint. Même geste pour la
lumière d'une plante, son cycle de vie, la forme et l'origine d'un engrais.

`FloraCard`, `FloraButton`, `EmojiTile`, `QuickActionChip`, `FloraTabBar`,
`FloraAvatar`, la pastille d'`EmptyState`, `SelectionBar` et le toast reposent
tous sur `ClayBox` : un composant ne dessine jamais sa propre ombre.

La pastille d'un état vide et celle d'un avatar sont des `blob` : leur forme
est tirée de l'emoji ou du nom, donc stable d'un écran à l'autre et différente
d'une personne à l'autre. Une pièce modelée, pas un rond.

### Chargement : la motte (`clay_loader.dart`)
Pas de roue qui tourne. `ClayLoader` est une motte d'argile animée image par
image, comme dans *Art Attack* : elle tombe, s'écrase au sol en projetant
des gouttes, rebondit en tremblant de moins en moins, respire en se
remodelant, se ramasse et repart. Un cycle dure 1,6 s. La silhouette ondule
en permanence (trois harmoniques lentes), l'ombre au sol rétrécit quand elle
saute. Elle est peinte avec `paintClay`, la même recette que les cartes.

Les éclaboussures existent en cinq jeux de cinq à sept gouttes, réglées une
à une (angle, portée, taille, poids, retard) : dans un jeu, aucune goutte
n'est le miroir d'une autre, et la motte change de jeu à chaque cycle, si
bien que la boucle ne se voit pas. Chaque motte démarre sur un jeu au
hasard. Les gouttes retombent et se posent au sol, elles ne le traversent
pas.

`AdaptiveProgress` (toutes les attentes de l'app) et l'état `loading` de
`FloraButton` l'utilisent ; `size` est le diamètre au repos (36 par défaut,
14 dans un bouton). Avec *reduced motion*, la motte reste posée.

### Traitement d'une image : le champ (`processing_field.dart`)
Une attente n'a pas toujours la même échelle. Quand Iris traite la première
photo, une petite motte sous le titre ferait croire à une attente générique :
`ProcessingField` garde donc la photo à l'écran et pose dessus une grille de
points blanc cassé / crème. Leurs centres restent strictement fixes ; c'est une
masse souple qui dérive et se replie sous la grille, faisant varier rayon et
opacité de chaque point. Les périodes de dérive, souffle et plis ne se divisent
pas entre elles, sur le principe de ProcessingField (haplollc), réécrit en
Flutter.

Le champ entre et sort par un court fondu accompagné d'un changement d'échelle
presque imperceptible, plutôt que de surgir ou disparaître d'une image. La
marque d'Iris respire à part, petite et posée en haut à droite afin de ne pas
masquer le sujet. Ce composant est réservé aux traitements qui portent
réellement sur une surface ou une image ; les petites attentes continuent
d'utiliser `AdaptiveProgress`. Avec *reduced motion*, le champ garde une image
fixe et ses contrôleurs s'arrêtent complètement.

### La marque d'Iris (`iris_mark.dart`)
Le logo du modèle embarqué, dans *Réglages > Identification* et au centre de
son écran d'onboarding : une feuille peinte par `paintClay`, sa nervation, et
en son centre un iris clair à cœur de terre cuite. Iris, c'est l'œil, le
diaphragme et la fleur.

Sans trois écarts, une vésique symétrique ne serait qu'un œil : la feuille
penche, sa base est plus ronde que sa pointe, et ses nervures partent toutes
vers celle-ci, comme une nervation pennée.

**Ses couleurs sont les siennes.** La première version prenait `sage`,
`onAccent` et `terracotta` de la palette du moment ; en sombre la feuille
pâlissait, l'iris passait au presque-noir et le cœur au saumon — le même
dessin, pas le même logo. `IrisMark.blade`, `.iris` et `.heart` sont donc des
constantes, et `paintClay` est appelé en `dark: false` : le relief lui-même ne
bascule pas. Le peintre n'a plus aucun champ, si bien que le même exemplaire
`const` sert les quatre palettes — l'identité est vérifiée, pas promise.

`blade` (#369361) n'est pas `sage` mais un vert un peu plus clair, la seule
bande de clarté où une couleur figée passe 3:1 sur les quatre fonds qu'elle
rencontre : canvas clair, canvas sombre, pastel des réglages des deux côtés
(3,34 · 4,49 · 3,23 · 3,03). Le seuil reste celui d'un dessin, même en
contraste élevé : la marque est décorative, le nom du modèle est écrit à côté
d'elle. Décorative par défaut, donc ; `semanticLabel` ne se donne que si elle
est seule.

Sur la scène de l'onboarding (`iris_float.dart`) elle prend la place d'un objet
d'argile, à la même respiration. Sans l'ombre au sol de `ClayFloat` : elle porte
déjà la sienne, et deux ombres la feraient flotter deux fois. Et c'est le seul
écran où le halo de la scène s'efface (`OnboardingStage.mark`) : il est de la
couleur de l'écran, la feuille est verte, et en sombre les deux se rejoignaient
à 1,2:1. Entre une marque qui change de couleur pour se sauver et un halo qui
se retire le temps d'un écran, c'est le halo qui cède ; les lueurs du fond
reculent au tiers pour la même raison.

## Couleurs (`design_system/tokens/colors.dart`)
| Token | Clair | Sombre | Usage |
|---|---|---|---|
| `canvas` | #F6EFE4 | #221A15 | papier crème / terre sombre |
| `surface` | #FBF6EE | #2E2219 | cartes, sheets |
| `surfaceMuted` | #EFE4D4 | #3A2C22 | chips, champs |
| `surfaceElevated` | #FFFBF5 | #443428 | éléments flottants |
| `ink` | #4A3528 | #F6EFE4 | texte principal : un brun franc, jamais noir |
| `inkSecondary` | #6F5A4E | #C2AE9C | texte secondaire |
| `inkTertiary` | #746256 | #A69485 | captions, placeholders |
| `line` | #E6D9C8 | #4A3A2E | séparateurs (rares) |
| `sage` | #2C774E | #6DC48D | accent, boutons principaux |
| `sageSoft` | #E4EFE6 | #2C3D31 | fond positif, chip active |
| `terracotta` / `terracottaSoft` | #9C482C / #F2D9CB | #E59A70 / #4A2E22 | retard, héros du matin |
| `water` / `waterSoft` | #39689A / #DCE7F3 | #8FB8E4 / #2B3644 | arrosage |
| `sun` / `sunSoft` | #966E2C / #F3E3C2 | #E7C15C / #45391F | lumière, engrais |
| `rose` / `roseSoft` | #C64A61 / #F5DDE0 | #EC8A9B / #4A2C31 | favoris, santé |
| `danger` | #C0392B | #E47064 | destructif |
| `shadow` | #5E2C14 à 14 % | — | ombre portée du clay |

### Le contrat de contraste
Un accent sert tantôt de texte sur un pastel (la pastille « 💧 Dans 2 j »),
tantôt de fond sous du texte (le bouton « Arroser »). Les deux sens sont tenus,
et `test/design_system/colors_contrast_test.dart` les vérifie à chaque
exécution :

- les trois encres : **≥ 4.5:1** sur `canvas`, `surface` et `surfaceMuted` —
  `inkTertiary` porte les libellés des champs, ce n'est pas un gris décoratif ;
- `sage`, `terracotta`, `water`, `danger` : **≥ 4.5:1** sur ces fonds et sur
  leur pastel, parce qu'ils portent du texte de 13 pt ;
- `sun` et `rose` ne servent que d'icônes : **≥ 3:1** ;
- `ink` sur `sageSoft` : la carte du modèle est une carte de couleur, donc ce
  qu'on y écrit ne repose plus sur les fonds neutres. Tout y est en pleine
  encre, et le libellé de ses chiffres en `sage` ;
- **`onAccent`** — ce qu'on pose sur un accent employé comme fond — **≥ 4.5:1**
  sur chacun d'eux. Une seule valeur par thème suffit : les accents sont tous
  sombres en clair, tous clairs en sombre. Ne jamais écrire `Colors.white` en
  dur là-dessus : sur l'ocre du thème sombre, cela donnait 1,7:1.

C'est cette dernière règle qui fixe la clarté des accents, et qui a assombri
la terre cuite, le bleu et l'ocre par rapport aux premières maquettes.

### Les commandes posées sur une image (`OnMedia`)
La galerie dans un coin du viseur, la croix d'une vue de plus : sous elles il
n'y a pas un fond du thème mais un cadrage. Elles sont donc hors du contrat,
comme la marque d'Iris — pastille blanche (`OnMedia.tile`, #FFFFFF à 85 %) et
encre figée (`OnMedia.ink`, #4A3528) dans les quatre palettes. Prendre `ink`
de la palette du moment, comme la première version, faisait tourner l'icône au
crème en thème sombre : elle s'effaçait dans sa pastille, à 1,2:1. L'encre
figée tient 8:1 sur la pastille au pire du fondu.

### Contraste élevé
`FloraColors.lightHighContrast` / `darkHighContrast`, servies par
`highContrastTheme` de `MaterialApp` quand *Augmenter le contraste* est actif.
Mêmes teintes, seule la clarté bouge : le texte vise AAA (7:1), les icônes
4.5:1, et les séparateurs deviennent enfin visibles — c'est la première chose
qu'attend qui active ce réglage.

## Typographie (`typography.dart`)
Deux voix : la **main** pour ce qui est grand (Shantell Sans, police variable
sous licence OFL, `assets/fonts/`), le **système** pour tout ce qui se lit
(SF sur iOS, Roboto sur Android). La graisse de Shantell se règle par
`FontVariation('wght', …)`, pas par `fontWeight`.

| Style | Police | Taille / poids | Usage |
|---|---|---|---|
| Display | Shantell | 34 / 700 | grand titre d'onglet, chiffre du héros |
| Title1 | Shantell | 28 / 700 | nom de plante (fiche) |
| Title2 | Shantell | 22 / 600 | sections |
| Title3 | système | 17 / 600 | titres de cartes |
| Body | système | 17 / 400 | texte |
| Callout | système | 15 / 400 | secondaire |
| Caption | système | 13 / 500 | métadonnées |
Dynamic Type : toutes les tailles suivent `MediaQuery.textScaler`, et la mise
en page suit le texte — hauteurs planchers plutôt que fixes, libellés qui
plient sur deux lignes plutôt que de se faire couper. La barre d'onglets
grandit avec eux et plafonne le grossissement de ses libellés à 1,6× (iOS fait
de même). `test/design_system/dynamic_type_test.dart` promène les composants de
82 % à 350 %.

*Texte en gras* : `context.text` rend une variante épaissie. Le détour est
nécessaire — Flutter épaissit tout seul les styles à `fontWeight`, mais la
fonte variable des titres n'écoute que `FontVariation`.

## Spacing (`spacing.dart`) : 4 · 8 · 12 · 16 · 20 · 24 · 32 · 40 · 48
## Radius (`radius.dart`) : small 10 · medium 16 · large 24 (cartes) · xl 32 (sheets, héros) · full (boutons, chips, tab bar)
## Élévation : c'est le clay qui fait le relief (voir *Matière*). `shadows.dart` ne sert plus qu'aux rares éléments hors design system.
## Motion (`motion.dart`)
- Durées : 150 (micro) · 250 (standard) · 400 (emphase). Courbes : `easeOutCubic`, `Curves.easeInOutCubicEmphasized` pour les sheets.
- `reduced motion` : durées → 0, pas de translation, uniquement fondu.

### Les ressorts
Ce qui bouge **sous le doigt** ou se déplace d'un point à un autre suit une
physique, pas une durée fixe. Une courbe met toujours le même temps d'où
qu'elle parte ; un ressort reprend la vitesse en cours — c'est la différence
entre une pièce qui répond et une pièce qui rejoue une animation. Le rapport
d'amortissement, `damping / (2·√(mass · stiffness))`, décide du dépassement.

| Ressort | Amortissement | Usage |
|---|---|---|
| `Springs.press` | 1,00 | l'aller sous le doigt : franc, sans tremblement |
| `Springs.release` | 0,44 | le retour : dépasse d'un cheveu, comme une pâte qui se détend |
| `Springs.glide` | 0,81 | ce qui se déplace : la bulle de la barre d'onglets |

`AnimationController.springTo` les mène, sur un contrôleur **sans bornes** :
le dépassement sort de l'intervalle 0–1, et c'est voulu. Avec *réduire les
animations*, il saute à la valeur — un ressort qu'on raccourcit n'est plus un
ressort.

Le réglage se lit dans `didChangeDependencies`, jamais dans le rappel du
geste : une pièce qui disparaît sous le doigt annule son appui *pendant*
qu'elle se démonte, et un élément désactivé ne peut plus remonter à son
`MediaQuery`.

### L'appui (`Pressable`)
Deux choses le distinguent d'un simple rétrécissement.

- **La pièce s'aplatit plus qu'elle ne s'éloigne** : l'axe vertical cède
  environ quatre fois plus que l'horizontal (0,968 contre 0,992 pour une
  carte), comme une pâte qu'on écrase. Un rétrécissement égal dans les deux
  axes, c'est du papier qui s'en va. L'écrasement reste sous le
  rétrécissement lui-même : une carte pleine largeur ne déborde jamais de ses
  marges sous le doigt.
- **Le relief rentre avec elle** : `Pressable` diffuse sa pression aux
  `ClayBox` qui sont dessous (`PressDepth`), et `paintClay` rapproche la pièce
  de son ombre portée, pâlit son reflet et creuse son ombre intérieure. C'est
  le même dessin sous le doigt, pas une autre pièce. Seul le peintre repasse ;
  le contenu de la carte ne se reconstruit pas.

### Une pièce qui s'en va (`features/today/`)
Un soin enregistré repousse l'échéance à la seconde même. L'échéance décide de
la section **et du rang** : la pièce changeait donc de place avant d'avoir rien
montré. Une carte passait de « En retard » à « À venir » ; une tuile de la
grille filait en fin de liste pendant qu'une autre prenait sa case. Dans les
deux cas, de l'écran, cela ressemblait à une disparition instantanée.

Tant que la tâche séjourne dans `completedTasksProvider`, c'est donc **la
version d'avant qui prime** sur celle de la base, et l'écran se range sur
l'échéance qu'il affiche. Le tri est *stable* : beaucoup de soins tombent le
même jour, et un ordre qui se rejoue à chaque image serait pire que le saut
qu'on répare.

La pièce tient alors sa place une seconde en « Arrosée », le temps qu'on
puisse annuler, puis s'en va — une carte vers la droite en s'effaçant, une
tuile en se rétractant sur place, sans pousser ses voisines. La carte referme
**en même temps la place qu'elle occupait** ; sans cela elle s'en allait bien
en douceur mais les suivantes sautaient d'un cran à l'instant où la liste se
reconstruisait sans elle.

### Une liste qui se pose (`Appear`)
Une pièce monte de huit points en s'éclaircissant, une seule fois, avec trente
millisecondes de retard par rang — plafonné à huit rangs, sans quoi une longue
liste se déroulerait encore alors que le doigt défile déjà. Le retard vit dans
la courbe et non dans un minuteur : un `Timer` en attente survivrait au widget.
Avec une clé stable, une carte déjà posée ne rejoue rien quand la liste se
réordonne. L'écran Aujourd'hui s'en sert pour ses soins du jour.

`test/design_system/spring_motion_test.dart` verrouille les trois : les deux
axes qui ne cèdent pas pareil, le retour qui passe au-dessus de la taille au
repos, la bulle qui glisse, et le fait que rien de tout cela ne joue avec
*réduire les animations*.
## Cibles tactiles
44 × 44 points minimum, la règle des HIG. `Pressable` s'en charge pour tout le
monde via `MinTapTarget` : le dessin garde sa taille — un rond de 32 reste un
rond de 32 —, seule la surface qui écoute le doigt s'élargit autour, et
uniquement quand le parent n'impose pas déjà une taille suffisante (une carte
pleine largeur se pose exactement comme avant).
`test/design_system/tap_target_test.dart` le vérifie avec
`iOSTapTargetGuideline`.

## VoiceOver
`FloraListRow` fusionne ses nœuds (`MergeSemantics`) : une ligne s'annonce
« Monstera, arrosée il y a trois jours » d'un seul tenant, au lieu d'un bouton
sans nom suivi de deux fragments. Le libellé se compose des textes de la ligne
plutôt que d'être recopié — sinon la synthèse vocale bégaie. `SectionHeader`
se déclare `header: true`, ce qui rend le rotor « Titres » utilisable. Un
onglet de `FloraTabBar` exclut la sémantique de son contenu : son libellé est
déjà celui de l'onglet, et le texte dessiné en ajoutait un second — « Jardin,
Jardin ». Ce qu'il annonce suit l'onglet choisi, pas la bulle, qui met le
temps d'un ressort à y arriver.

## Haptics (`core/haptics.dart`)
- `selection` : changement de chip / onglet · `light` : tap bouton · `drop` : arrosage enregistré · `success` : toute autre action enregistrée · `warning` : archivage, suppression.

Sur iPhone, les trois retours qui racontent quelque chose sont des motifs
Core Haptics (`ios/Runner/HapticsChannel.swift`), là où `HapticFeedback`
n'offre qu'un coup : la **goutte** — deux impulsions légères, puis celle qui
touche la terre et s'y étale —, le **roulement** d'une action faite, qui monte
et se pose, et le **coup sourd** d'un geste sensible, suivi de son écho. La
sélection et le tap restent ceux du système, qui sont déjà les bons. Partout
ailleurs, et dès que le moteur manque (iPad, simulateur, *Vibrations* coupé),
le repli est le retour d'avant ; le natif n'est sollicité qu'une fois pour le
savoir. `test/core/haptics_test.dart` vérifie l'aiguillage.

## La barre d'onglets et le retour au sommet (`app/tab_scroll.dart`)
Un second tap sur l'onglet courant remonte sa liste ; ce n'est qu'une fois en
haut qu'il revient à la racine de la branche. Les deux dans le même geste se
gênaient : revenir à la racine reconstruit la page, et la remontée n'avait pas
le temps de se jouer.

L'attache de la liste au contrôleur de son onglet est **dite explicitement**
par `LargeTitlePage` (`primary: true` quand la page n'a pas de contrôleur à
elle), et non laissée à l'heuristique de plateforme de
`PrimaryScrollController` : une page qui ne s'attache pas ne remonte pas, et
rien ne le signale. Le test couvre les deux plateformes pour cette raison.


La bulle active est **une seule pièce qui se déplace** (`Springs.glide`), et
non un fond qui s'allume sous chaque onglet à son tour : c'est ce qui relie le
départ et l'arrivée. Les libellés virent au passage — leur couleur suit la
part de l'onglet que la bulle recouvre — au lieu de basculer à l'arrivée, et
l'icône qui l'accueille se pose au ressort.

### Le grand titre là où la barre est celle d'UIKit
Deux barres se superposaient : celle du système portait les boutons, et celle
de Flutter dessinait le titre une rangée plus bas. Le titre replié descendait
donc d'une hauteur de barre, ce qu'aucune application native ne fait.

Là où UIKit tient la barre, Flutter n'en dessine plus : le **grand titre
devient du contenu**, en tête des slivers, avec sa police arrondie intacte.
C'est le système qui porte le **titre replié**, sur la même ligne que les
boutons — « Auxine » à côté du tableau de bord et de l'ajout.

Le passage de l'un à l'autre se lit sur la position de défilement, au même
seuil que le titre replié de la barre de Flutter — cinquante-deux points —,
ce qui garde les deux chemins d'accord.

Une première version guettait la sortie d'un sliver posé après le titre. Elle
basculait **une hauteur de barre trop tard** : un sliver ne sait pas qu'il
approche du bord, seulement qu'il l'a franchi, et le titre avait donc
entièrement disparu avant que le système n'affiche le sien. iOS, lui, bascule
dès que le grand titre glisse *sous* la barre.

Ailleurs — Android, et iOS avant que la chrome ne soit passée au natif — la
`CupertinoSliverNavigationBar` et son repli restent ce qu'ils étaient.

### La bande du système, et qui la retire
Sur un pliable, la bande de la caméra et de l'heure occupe un bord entier —
quatre-vingt-quatre points sur l'iPhone Duo — et change de côté avec la
rotation. La règle est simple à dire et facile à rater : **elle est retirée
une fois, et une seule.**

| gabarit | qui la retire |
|---|---|
| `LargeTitlePage` | la page, dans ses `SliverPadding` |
| `FloraPage` | le `SafeArea` de son corps — ne rien ajouter par-dessus |
| la fiche d'une plante | un `SliverPadding` qui couvre tout, **photo comprise** |
| une feuille | `_MargesLaterales`, parce que la feuille d'iOS les efface — et c'est sa **surface** qui s'écarte, pas seulement son contenu |

La deuxième ligne a coûté un aller-retour : ajouter la marge à `FloraPage`
donnait 188 points au lieu de 104, le `SafeArea` l'ayant déjà retirée. Le test
de `wide_layout_test.dart` fixe donc la **cote exacte** et non un maximum —
un test qui n'accepte qu'un plafond laisse passer le double comptage.

`systemSideInsets` existe pour les pages qui n'ont ni l'un ni l'autre : elle
dit à quoi sert la valeur, là où un `MediaQuery.paddingOf` recopié ne dit rien.

**La photo ne fait pas exception**, contrairement à ce qu'on avait d'abord
laissé. Une région réservée n'est pas une marge de confort : le système y pose
l'heure et le wifi, et une image qui passe dessous les rend illisibles. La
hauteur de l'en-tête se calcule donc sur la largeur qui reste, sans quoi les
proportions de l'image se faussent de ce que la bande a pris.

### Ce qui vit dans la barre, et ce qui vit dessous
La barre garde toute la largeur — c'est ce que fait iOS —, et seul le contenu
se tient dans les marges. D'où une règle facile à oublier : **ce qui est posé
dans la barre doit prendre ses marges lui-même.** Le champ de recherche est le
cas d'espèce ; posé dans le `bottom` de la barre, il ignorait les marges des
contenus et passait sous la bande verticale de l'iPhone Duo. Il prend
désormais `max(Space.md, marge)` de chaque côté : sa marge ordinaire sur un
téléphone, celle du système là où il y en a une.

`test/design_system/wide_layout_test.dart` le tient sur les deux plateformes.
Le premier test écrit ne prouvait rien : sous `flutter test`, la plateforme
par défaut est Android, et c'est la barre d'iOS qui laissait passer le champ.

### Les feuilles portent leur poignée (`components/sheets.dart`)

Deux feuilles chez Auxine, et le même trait en haut des deux. `showFloraSheet`
monte à hauteur de contenu et pose sa `SheetHandle` dans sa colonne ;
`showFloraFlow` et `showFloraScrollableFlow` donnent toute la hauteur à une
page, et la poignée se pose donc **par-dessus** — c'est la marge sûre qui lui
fait sa place, si bien que la page s'en écarte d'elle-même, comme elle
s'écarte de l'heure et du wifi, sans rien savoir d'elle.

Une feuille d'iOS se referme d'un glissement vers le bas, et c'est la poignée
qui le dit. Sans elle, une feuille dont le contenu n'offre rien pour sortir
n'a l'air de rien — ni page, ni fenêtre. `showCupertinoSheet` sait la dessiner
lui-même (`showDragHandle`), mais ne transmet pas le drapeau à sa route quand
on lui demande la navigation imbriquée, et nos flows la demandent tous : le
drapeau restait sans effet.

### Le menu debout (`FloraTabRail`)
Quand la fenêtre est large sans être celle d'une tablette — l'écran intérieur
d'un iPhone Duo ouvert —, le menu passe à droite, en colonne : une pilule de
64 points de large, centrée dans la hauteur, contre le bord. Une barre posée
en bas y traverserait tout l'écran pour quatre onglets, et la main qui tient
l'appareil ouvert est sur le côté, pas en bas.

C'est la même pièce : la même bulle, le même ressort, la même argile,
seulement couchée (`_TabStrip` prend un `Axis`). Deux choses changent.

Les **libellés tombent** : quatre mots debout doubleraient la largeur de la
colonne. L'icône reste, et `Semantics` dit toujours le libellé à VoiceOver —
c'est ce que le rail perd pour l'œil qu'il garde pour l'oreille. En retour, la
colonne ne bouge plus avec Dynamic Type, là où la barre du bas s'agrandit et
passe à deux lignes.

La colonne se pose **dans** la bande que le système réserve à droite — 84
points mesurés —, pas à côté d'elle. C'est là que le pliable met les commandes
d'une application, sous l'heure et le wifi ; s'en écarter laissait une colonne
vide large comme un pouce. Ce n'est pas contredire la marge : elle vaut pour
le **contenu**, qui s'arrête bien avant, puisqu'il ne prend que ce que la
colonne lui laisse. Le menu, lui, est du châssis, comme la barre d'outils
debout d'iOS. Ce qui l'empêche de heurter l'heure, c'est sa position : centrée
dans la hauteur, quand les éléments du système se tiennent en haut de la bande
dans toutes les poses mesurées. Ce qui flotte par-dessus l'application évite
la colonne à son tour — le toast se range à sa gauche et redescend, puisque
plus rien n'occupe le bas (`FloraTabRail.reserved`).

La bascule est dans `FloraTabRail.fitsIn`, et tient en trois conditions.

| | Pourquoi |
|---|---|
| côté le plus court < 700 | pas une tablette : le plus petit iPad en fait 744, et l'iPad garde sa barre du bas |
| largeur ≥ 460 | assez large pour céder les 80 points de la colonne ; l'écran extérieur du Duo en fait 466, il lui reste 386 |
| largeur / hauteur > 0,6 | pas une colonne de téléphone — c'est la **forme** qui tranche, pas la taille |

La troisième est celle qui compte. Un iPhone en portrait est étroit et long
(402 × 874, soit 0,46) et une barre en bas y est chez elle ; les fenêtres du
Duo sont trapues — 0,69 fermé, 0,70 ouvert, 1,4 couché. Toutes les poses du
Duo passent donc debout, écran extérieur compris. Les tranches de multitâche
(445 × 626, 320 × 626) restent en bas, et l'iPad en Split View aux deux tiers
— 678 × 1133, soit 0,60 — aussi, ce que la règle précédente ratait.

La bande fait 84 points mesurés et change de côté selon la rotation. La
colonne reste au bord droit dans les deux cas ; c'est le contenu et la pilule
du bas qui s'écartent, bord par bord — rien n'est supposé symétrique. Voir
docs/05, section « La fenêtre ».

#### Les boutons de la page descendent avec
Debout, la colonne ne porte pas que les onglets : les boutons du haut de page
la rejoignent, sous la pilule, le dernier de la liste — le « + », le plus
souvent — au plus près du pouce. Deux choses restent en haut : le titre, et le
bouton de retour, qui est un geste de navigation et non une commande de la
page.

C'est un relais, parce que les deux bouts ne se voient pas : la coquille
dessine la colonne, chaque page connaît ses boutons. Une page se déclare par
`RailActions`, le relais garde les déclarations en pile, et c'est la dernière
**visible** qui gagne — la visibilité se lit au `TickerMode` que go_router
coupe sur les branches hors écran, sans quoi un onglet resté monté derrière
garderait la main. La colonne se redessine après l'image, jamais pendant : la
coquille est construite avant les pages, et la prévenir en cours de route
reviendrait à rebâtir un ancêtre déjà bâti.

D'où `LargeTitlePage.actions`, une **liste** et non une `Row` toute faite :
une rangée ne se range pas debout. Les pages qui n'ont qu'un bouton gardent
`trailing`, qui marche pareil.

**L'ordre est celui d'iOS : les boutons en haut, les onglets en bas.** Apple
le dit dans « Raise the bar with iPhone Duo » — « reserve the top for primary
navigation controls, like back or close, followed by prominent actions » —, et
la barre d'onglets, elle, « moves to the bottom of the vertical bar ». C'est la
rotation à quatre-vingt-dix degrés de ce qu'un iPhone montre déjà : la
navigation en haut, les onglets en bas.

Rien n'est centré, et rien ne bouge. Les boutons sont calés sous le dégagement
du haut, la pilule contre le bas, et c'est le vide entre les deux groupes qui
absorbe la différence — le même vide que le système met entre ses placements du
haut et ceux du bas. Centrer, même la pilule seule, la faisait bouger dès que
la fenêtre changeait de hauteur ; centrer le groupe entier la faisait remonter
d'un cran à chaque bouton de plus, jusqu'à passer sous l'heure.

Les 172 points qui dégagent le haut sont une mesure plus une marge : sur l'écran extérieur du Duo,
la pile caméra + heure + wifi descend à 140 points, là où
`MediaQuery.padding.top` n'en annonce que 82. iOS ne dit donc pas où s'arrête
sa propre colonne, et la nôtre commence sous la mesure. Si une pose annonçait
davantage, c'est l'annonce qui l'emporterait. Les 32 points d'air ne sont pas
décoratifs : douze collaient la pilule au wifi, et deux pièces d'argile de 64
points de large demandent plus d'écart qu'un glyphe de vingt.

Le dégagement cède avant les cibles : dans une fenêtre trop courte — un Duo
fermé et couché, 466 points de haut pour quatre onglets et quatre boutons —
le groupe du haut remonte de ce qu'il faut, et les onglets gardent leurs
44 points.

**Horizontalement, les deux colonnes partagent un axe.** iOS pose sa pile à
47,7 points du bord droit, mesuré au pixel dans les trois poses du Duo — 466,
669 et 951 points de large. La pilule en fait 64, donc 16 de blanc mettent
son axe à 48. Douze la décalaient de quatre points : c'est tout l'écart entre
une colonne qui prolonge celle du système et une colonne posée à côté.

**Ces deux cotes sont désormais des replis.** Un canal natif demande à UIKit
où sont réellement la bande du système, la caméra et le pli, et le menu s'y
range quand la réponse est plausible — voir docs/05, « Ce que le système
réserve ». Sur l'écran extérieur du Duo, iOS annonce une bande haute de 170
points et une caméra à 47,8 du bord droit : le menu commence à 178 au lieu de
172, et son axe ne bouge pas d'un dixième. Ouvert et couché, la bande ne fait
plus que 120 et la colonne remonte d'autant — il y a moins de système
au-dessus d'elle. Aucune constante ne savait faire ça. Les 140 et les 47,7 points restent
écrits dans le code, et servent partout où le canal se tait : ailleurs que sur iOS, sur un binaire construit avec un SDK
plus ancien, ou quand la réponse est invraisemblable. Le menu se pose alors où
il se posait avant, ce qui est déjà juste : l'annonce affine, elle ne porte
rien.

Ce que le canal ne rattrape pas : iOS regroupe et fait déborder tout seul les
commandes d'une barre d'outils debout, mais seulement pour les barres de
`UINavigationController` et `UITabBarController`. Une barre montée à la main
n'y a pas droit, régions réservées ou non. C'est le prix d'un menu dessiné par
l'application, et il se paie en gardant la colonne courte.

La colonne mesure cette place avant de se donner une hauteur — elle ne peut
pas mesurer ses enfants d'abord. Un bouton compte pour 44 points et non 40 :
c'est `Pressable` qui décide, en garantissant la cible des HIG
(`kMinTapTarget`). Les quatre points d'écart passaient inaperçus jusqu'à ce
que quatre boutons débordent de onze.


Un second tap sur l'onglet courant ramène sa liste en haut, comme sur iOS.
Chaque branche du shell pose son propre `ScrollController` en
`PrimaryScrollController` *dans* sa route (`TabScrollScope`) : il passe
devant celui que la route fournit d'elle-même, la liste de l'onglet s'y
attache sans qu'on le lui dise, et le tap sur la barre d'état — que le
`Scaffold` sert avec ce même contrôleur — continue de marcher. La remontée
suit *réduire les animations* : un saut au lieu d'une glissade.

### Une page que la barre du bas referme (`ScrollFade`)
Une barre posée sous la page la referme : le dernier élément visible s'arrête
net sur elle, au pixel près, et rien ne distingue une page qui se termine là
d'une page qui continue. `FloraPage` efface donc le bas de sa zone défilante
tant qu'il reste du contenu dessous — une couche teintée du `canvas`, réglée
sur ce qui reste à défiler, qui s'efface elle-même une fois le bas atteint.
C'est une couche colorée et non un masque d'opacité (`HeaderFade`) : la page
porte la même couleur des deux côtés de la barre, le voile n'a donc rien à
trahir, et il évite un `saveLayer` par-dessus un viseur de caméra. Les pages
sans barre du bas s'en passent : leur contenu touche déjà le bord de l'écran.

## Les textes (`lib/l10n/*.arb`)
Le ton est celui d'un outil, pas d'un assistant : sobre, factuel, court.
- Une phrase dit une chose, à l'indicatif. Un titre est un nom, pas une
  question : « Nom », « Emplacement », « Aperçu », et non « Comment
  s'appelle-t-elle ? ». Seuls les questionnaires (le chercheur de plantes)
  posent des questions, c'est leur rôle.
- L'application ne parle pas d'elle-même et ne se prête pas d'intentions :
  pas de « nos propositions », « Auxine regarde la pluie », « il sait dire
  qu'il hésite ». On décrit ce qui se passe : « Propositions », « l'arrosage
  est reporté les jours de pluie », « Doute signalé ».
- On n'interpelle pas la personne : pas de « personne ne vous juge »,
  « s'il vous plaît », « avec plaisir », « pas de panique », pas de point
  d'exclamation. Pas de réassurance ni de justification qui ne change rien à
  ce qu'elle va faire.
- Notifications et erreurs sont des constats : « Monstera : arrosage prévu
  aujourd'hui », « Code invalide, expiré ou déjà utilisé. », et non « a
  probablement besoin d'eau », « ce code ne vaut plus rien ».
- Les conseils d'entretien (`careTip…`) gardent le registre du jardinage :
  « elle pardonne les oublis » y est admis, nulle part ailleurs.
- Les trois autres langues suivent le français, dans le même ton.

`test/l10n/arb_tone_test.dart` verrouille la part mécanique : pas de point
d'exclamation, pas de titre en forme de question, et une liste de tournures
interdites par langue. Une tournure à bannir de plus s'ajoute là.

## Composants (`design_system/components/`)
Button · IconButton · PressableScale · ClayBox · ClayLoader · Appear · Card · ActionTile · PlantCard · CareCard · PaperSheet · ActionChip · Pill · BottomSheet · Toast (Undo) · SearchBar · SegmentedControl · Slider (natif) · StepDots · EmptyState · Avatar · Badge · Tag · ListRow · TimelineRow · IrisMark · PhotoGrid · PhotoViewer · QuantityStepper · DatePicker (natif) · PlantPicker · PhotoPicker · LocationPicker · Skeleton · ErrorState · LargeTitleHeader · SectionHeader · ScrollFade · WhatsNewWindow

## L'écran du matin (`features/today/`)
Le grand titre salue : « Bonjour Paul » jusqu'à dix-huit heures, « Bonsoir
Paul » ensuite, à l'heure de l'appareil, et sans le nom tant qu'on n'en a pas.
Replié dans la barre, ce salut ne dit plus où l'on est : c'est **Auxine** qui
y reste (`collapsedTitle` de `LargeTitlePage`). Le petit titre arrive dans le
fondu du gabarit natif, celui-là même qui emporte le grand, et monte de
quelques pixels au passage — une montée tirée du défilement, pas une
animation qui se rejoue. Les autres onglets n'en ont pas besoin : leur titre
est déjà un nom.

Sous le grand titre, le jour et ce qu'il fait : la date, puis une rangée de
`FloraPill` — le temps dehors, l'air de la maison — qui mènent aux
prévisions et au capteur. Une pilule fait la hauteur de la cible tactile et
pas plus : c'est sa surface qui écoute, aucun vide autour. Les emplacements
de « Votre jardin » sont les mêmes pilules, avec leur compte en retrait.

Ce qui demande un regard tient dans une `TodayNotice`, toujours la même :
une tuile d'emoji, un titre qui est un nom (« Pluie aujourd'hui », « 25° ·
41 % · Salon », « Rappel quotidien »), une phrase qui est un constat,
parfois un ou deux boutons, une croix quand la carte se ferme pour la
journée. Celle de l'air de la maison ne paraît qu'une fois par jour : les
plantes qu'elle signale le restent tant que la pièce ne change pas, et la
mesure demeure sur la pilule. La teinte dit le sujet — bleu poussière pour
la pluie, ocre pour l'air de la maison, sauge pour les rappels — et la
carte de repos, « Tout est en ordre », reste crème. Sur une carte teintée,
la tuile reste `surface`. `TodayNoticeSlot` pose la marge commune et fond
la carte quand elle disparaît, sans laisser de vide. La carte du jour, en
terre cuite, reste à part : c'est le chiffre du matin, pas un avis.

## La fiche d'entretien (`features/species/presentation/care_guide_screen.dart`)
La page suit le chemin réel d'entretien, en sections titrées : **ce qu'elle
demande** (lumière, arrosage, eau, température, humidité, puis « Chez vous »),
**ce qu'on lui fait** (substrat, engrais, rempotage, puis le repos et le tuteur
pour celles qui en ont un), **les conditions particulières** (serre, floraison)
et enfin **les détails** (difficulté, toxicité). Sept volets se pratiquent —
arrosage, eau, lumière, humidité, engrais, substrat, rempotage — et chacun a sa
carte, teintée de la couleur de son sujet : bleu poussière pour l'arrosage et
pour l'eau, ocre pour la lumière, rose pour l'air, sauge pour l'engrais, terre
cuite pour la terre (le substrat et le rempotage la partagent, c'est la même).
Une douzaine de lignes dans une seule liste ne se distinguaient qu'à la
lecture ; une carte se retrouve à sa couleur.

**La fiche est une feuille posée sur le fond** (`PaperSheet`,
`design_system/components/paper.dart`) : un cran plus claire que le canvas,
une ombre droite — la lumière vient du dessus, pas d'un coin —, un filet, et
un coin corné en bas à droite qui emporte l'ombre du coin avec lui. Les
cartes d'argile restent des pièces posées sur la feuille : deux matières, et
c'est leur écart qui dit que la fiche est un objet. Les titres de sections
passent à la main (`SectionHeader`, Shantell 22), comme écrits sur la
feuille, et la provenance se tamponne au pied : le libellé de
`careMatchLabel` — « Fiche de l'espèce », « Repères généraux », « Complétée
par l'IA » — dans un cadre d'encre posé de travers. L'aperçu du dénicheur
garde la surface de sa sheet (`CareGuideBody(paper: false)`) : une feuille
sur une feuille ne se lit pas.

L'anatomie est celle des cartes du matin : une tuile d'emoji — crème, comme
sur toute carte teintée —, le nom du volet, le constat dessous, puis une ligne
par précision qui ne vaut que pour lui. Ces précisions sont le fond de la
fiche :

- **Humidité** : le taux de l'espèce, puis par quoi l'obtenir. « Air
  humide » seul ne se compare à rien, et ne suffit pas à régler une serre :
  entre deux plantes du même mot, l'une tient à 50 % et l'autre en veut 85.
  Le pourcentage vient de la fiche quand elle le précise, de la catégorie
  sinon, et se compare à la mesure de la pièce, juste au-dessous — laquelle
  dit « Rien qui gêne cette espèce », et non « dans la plage », parce qu'elle
  tolère quinze points sous le minimum.
- **Engrais** : lequel avant combien de fois — plantes vertes équilibré,
  azoté, potasse, cactées, orchidées, terre de bruyère, agrumes, tomates —,
  puis la saison, puis ce que le calcium lui fait quand il lui fait quelque
  chose (rien à dire vaut mieux qu'une ligne pour dire « rien »).
- **Substrat** : le mélange en proportions, et ce qu'elle accepte hors du pot
  — la culture dans l'eau, la culture en pon. Deux « déconseillée » font
  disparaître la ligne.

L'arrosage porte son chiffre en `title2`, dans le bleu de l'eau : c'est le
chiffre qu'on retient. Il vient après la lumière, qui commande justement son
intervalle. La carte « Chez vous » ferme les besoins, puisque c'est l'air de
la pièce qu'elle mesure.

Sous ces précisions vient ce qu'il faut en faire, une phrase par idée
(`notes`), en `caption` : la règle du rempotage, la dose de la lampe, les
conditions d'une floraison. La lumière annonce la lampe qui la remplace — LED
à spectre complet, intensité reçue et durée, puis la dose du jour —, parce que
c'est le seul volet de la fiche qui s'achète quand la fenêtre manque. Le
rempotage dit ce qu'une racine sortie par le fond signifie pour cette
espèce-là : signal pour celle qui veut de l'espace, état normal pour celle qui
fleurit à l'étroit, et chez une plante à réserves rien du tout, puisque c'est
la fin du repos qui commande.

**Repos** est la carte des plantes à réserves dont le feuillage disparaît —
crocus, caladium, cyclamen : la période, la température et l'obscurité du
rangement, puis ce qu'on fait du feuillage qui jaunit. Elle suit le rempotage
et reste crème, seule de la fiche : c'est la seule carte qui décrit une
absence — plus de feuilles, plus d'eau, plus de lumière —, et le crème le dit
sans un mot.

**Tuteur** ferme ce qu'on fait au pot, même registre et même crème : il ne
paraît que pour les espèces qui en demandent un.

Ce qui se lit sans rien faire — difficulté, toxicité — reste une `FloraGroup`
en fin de page. Avant elle viennent les deux projets, pour qui en a un :
**Sous serre** (ocre) dit les conditions à tenir pour pousser plus vite, et
**Floraison** (rose) la saison, puis ce qui décide la plante à fleurir : les
conditions nommées d'un trait (« Des nuits fraîches · Une hampe gardée »), et
chacune expliquée dessous, dans le même ordre. Trois au plus, sans quoi la
carte ne se lit plus. Ils se pratiquent, donc ils gardent la carte des
volets ; ils ne se pratiquent pas tous les jours, d'où leur place à part. Une
plante qui passe l'hiver dehors n'a pas l'usage d'une serre et n'en voit pas
la carte — c'est là que se règle la plage d'humidité, puisqu'une
serre se tient au chiffre ; la floraison ne paraît que lorsque la fiche sait
ce qui la déclenche, et dit « Rarement en intérieur » quand elle ne se joue
pas dans une pièce. Les conseils, ce qu'il faut surveiller, les problèmes
connus et la multiplication ferment la page, puis la provenance de la fiche. `test/features/care_guide_test.dart` tient la
séparation, `test/domain/care_profile_test.dart` ce qui se déduit.

**« À surveiller »** range la liste de l'espèce dans l'ordre de la base des
problèmes — les troubles, puis les ravageurs, puis les maladies —, parce que
c'est l'ordre dans lequel on vérifie. Elle ne se replie pas, à la différence de
« Problèmes connus » juste en dessous : celle-ci est écrite à la main, espèce
par espèce, et la plus longue tient en dix lignes. Un feuillage tropical en
appartement en compte neuf — l'eau, les quatre suceurs de sève qu'un intérieur
chauffé garde actifs toute l'année, les moucherons du terreau, les taches — et
les cacher derrière un bouton reviendrait à répondre « araignées rouges » à qui
ouvre la fiche d'un pothos.

**« Signes sur les feuilles »** est l'autre entrée de la fiche. On y arrive
avec la plante sous les yeux — elle s'éclaircit, elle brûle, elle se tache au
milieu, elle ne grandit plus — et pas avec un nom de champignon. Chaque signe
s'ouvre sur ce qui l'explique le plus souvent, un seul à la fois, pour que la
liste garde sa hauteur de liste. Les causes sont filtrées par la fiche
(`LeafSigns.forProfile`) : une espèce de plein soleil ne brûle pas au soleil,
une espèce qui aime l'air sec ne brunit pas des pointes pour cela, et ces
causes-là ne sont pas proposées. Rien ne part sur le réseau, à la différence du
diagnostic par photo, qui répond à la même question autrement.

## Les photos (`features/plants/presentation/photo_*.dart`, `growth_section.dart`)
Un seul chemin pour en ajouter une, `showPhotoCaptureFlow` : le viseur dans
la page, comme à la création, avec la dernière photo posée dessus en
transparence (`CaptureFrame.ghostOpacity`, 38 %) pour retrouver le même
cadrage ; puis la photo, sa date, un titre que des puces remplissent, et la
photo principale quand la question se pose. Les feuilles d'action système
« Appareil photo | Galerie » n'existent plus pour les photos de plante.

La visionneuse est une route transparente sur le noir : toucher cache ou
montre ce qui entoure la photo, tirer vers le bas la referme (le noir
s'éclaircit à mesure, le héros repart vers sa vignette), toucher deux fois
agrandit autour du doigt. Ses gestes sont nommés — Titre, Principale,
Partager, Supprimer — sur une même rangée ; elle s'abonne aux photos de la
plante, si bien qu'une suppression la met à jour sans la refermer. Sur le
noir, la palette du thème ne s'applique pas : blancs et un rouge clair
figé pour le geste destructif.

Deux vignettes de la même photo peuvent se trouver sur la fiche — la bande
Croissance et le journal — : chacune a son nom de héros (`growth-` et
`photo-`), et la visionneuse reçoit celui de la vignette d'où elle part.

## La page du diagnostic (`features/diagnosis/presentation/diagnosis_screen.dart`)
« Ma plante a un problème » était une feuille tirée du bas de la fiche : un
viseur n'y tenait pas, et le compte rendu — cinq pistes, leurs explications,
leurs gestes — défilait dans une demi-hauteur d'écran. C'est une page,
poussée depuis la fiche (`/plants/:id/diagnosis`), et elle suit les trois
temps du geste sans jamais changer d'écran.

**Montrer.** Le viseur occupe le haut de la page, en 4:5, avec ses commandes
posées dessus : le déclencheur au centre en bas (`Shutter`, partagé avec la
création d'une plante), la galerie à sa gauche à douze points, et le cadre
qui déclenche aussi quand on le touche. Sans caméra (refus, appareil sans
viseur, test), le cadre garde son invite, ouvre l'appareil du système, et
les deux boutons écrits — « Prendre une photo », « Choisir une photo » —
prennent le relais sous lui, exactement comme à la création d'une plante.
Une fois la première photo prise, une bande montre ce qui partira à
l'analyse et les places qui restent ; elle ne sert qu'à montrer, la croix
d'une vignette mise à part.

**Ce qu'on a remarqué se demande, il ne se propose plus.** Le champ des
symptômes était facultatif, et c'est ce qui rendait les comptes rendus
généraux : une photo seule ne dit ni depuis quand, ni ce qui a changé, ni ce
qu'on a déjà fait à la plante. « Analyser » attend donc une photo, puis une
description — dans cet ordre, une chose à la fois. Le bouton éteint ne reste
pas muet : la barre du bas nomme ce qui manque au-dessus de lui, et quand
c'est la description, elle le dit avec la pastille qui y mène et y pose le
curseur. Les observations, elles, restent facultatives : on ne fait pas
sortir une motte de son pot pour avoir le droit de demander.

Puis ce qu'on décrit, et ce qu'on est allé vérifier de sa main : une carte par
sujet, tuile d'emoji et teinte comprises, comme les volets de la fiche
d'entretien — la terre en terre cuite, les racines en sauge, la lumière en
ocre, les insectes en rose, l'air autour de la plante en bleu. Rien n'est
coché d'avance, et ce qui n'est pas coché ne part pas. Ce qui est coché part
comme un constat et non comme une impression : la consigne le pèse comme une
photo — une terre détrempée et des racines brunes peuvent mener à une piste
*probable* que l'image ne montre pas —, et le compte rendu dit dans son
constat quand c'est ce qui tranche.

**Ce qui attend dessous se dit.** Le viseur prend le haut de l'écran et la
barre du bas referme la page : les symptômes et les observations — ce qui
affine le plus l'analyse — tiennent entièrement sous la ligne de flottaison,
et rien dans le dessin ne le laissait deviner. Une pastille posée sous la
consigne de prise de vue les nomme, « Plus bas : symptômes et observations »,
et y mène d'un toucher — la section se pose sous la barre du titre, non
derrière elle. Le fondu du bas de page (`ScrollFade`) dit le reste : la page
ne s'arrête plus net sur la barre.

**Chercher.** La photo passe au centre dans son propre halo, les quatre
familles de problèmes tournant autour (`AnalysisWait`) ; le formulaire
s'efface, la barre du bas avec lui.

**Répondre.** Le compte rendu prend la page : les pistes d'abord — c'est ce
qu'on est venu lire —, puis le constat sur une carte crème, puis ce qui avait
été signalé et coché. Le constat et les symptômes ont longtemps ouvert le
compte rendu ; un paragraphe et sa propre phrase prenaient l'écran, et on
descendait sous eux pour apprendre ce que la plante a. Ils suivent, pour qui
veut comprendre sur quoi les pistes reposent. Quand il y a urgence, une carte
terre cuite précède tout — « À traiter rapidement », seule couleur qui change
—, et ne dit rien de plus : les pistes disent quoi, juste dessous. Chaque
piste porte la tuile de sa famille (l'illustration d'argile de la base sur sa
teinte), son cran de vraisemblance, son explication, et ses gestes sous un
filet ; celles que la base connaît mènent à leur fiche de l'encyclopédie.
Quand l'analyse ne tranche pas, c'est dit sous le titre des pistes, à la place
de « Classées par vraisemblance, à confirmer », et non dans le constat.

**Une piste peut n'être un problème pour personne.** Des gouttes claires et
collantes sous un philodendron sont du nectar extrafloral aussi souvent que du
miellat de cochenilles, et la moitié de ce qu'on photographie par inquiétude
n'a rien d'anormal. Ces pistes-là viennent dans la même liste, au même rang de
vraisemblance, et se lisent autrement : sur la sauge, leur propre dessin
d'argile — les sores d'une fougère, la laine des aréoles, le liégeage d'un
cactus — au lieu de celui d'une famille, dont elles ne relèvent pas ; et une
seconde pastille, « Phénomène normal », à côté du cran. Un phénomène hors base
porte le symbole commun, la feuille et sa goutte claire. Elles ne mènent nulle part : l'encyclopédie
parle de ce qui se soigne. Quand aucune piste n'est un problème, la première
carte le dit par sa pastille, et le constat le redit en titre : « Rien
d'anormal », sur la feuille, plutôt que « Constat » sur le stéthoscope. Un
compte rendu pareil n'est jamais urgent. Quand rien ne
tranche, ce qui manque se propose après les pistes, jamais à leur place
(docs/16) : d'abord les une à trois questions que le service a posées — une
carte ocre, un champ par question, « Reprendre l'analyse » dessous —, et la
photo de plus quand il n'en a posé aucune. Une seule des deux, et jamais sur
un compte rendu net. Répondre refait l'analyse entière ; les réponses
rejoignent ensuite les symptômes et les observations dans le compte rendu
gardé. Le même corps sert à la réouverture depuis le journal, à ceci près
que l'incertitude, elle, ne se relit pas : c'est une décision du moment, pas
une ligne du compte rendu.

**La barre du bas ne porte qu'un geste à la fois** : analyser, puis
enregistrer dans le journal. `test/features/diagnosis_screen_test.dart` tient
le formulaire.

## La fenêtre des nouveautés (`features/whats_new/`)
Ce que l'application montre après une mise à jour : un bandeau teinté qui
s'éteint dans le fond de la page, la marque posée au centre sur une médaille
d'argile qui respire, un titre en Shantell, trois points forts, et un bouton
qui reste sous les yeux pendant que la page défile.

- **Présentation native, dessin commun.** `showFloraScrollableFlow` : la sheet
  empilée d'iOS d'un côté, le dialogue plein écran de Material 3 de l'autre.
- **Le contenu défile parce qu'il emprunte le `ScrollController` de la sheet.**
  La sheet d'iOS arme un `VerticalDragGestureRecognizer` par-dessus tout son
  contenu ; sans ce contrôleur, elle remporte chaque geste vertical et la page
  reste figée pendant que la sheet descend. Avec lui, la liste défile tant
  qu'elle n'est pas en haut, et referme la sheet une fois en haut. Un flow à
  plusieurs pages défilantes ne peut pas s'en servir — d'où `showFloraFlow`,
  qui reste à côté.
- **La médaille est `surface`, pas la teinte** du bandeau : la marque d'Iris a
  ses couleurs figées, garanties lisibles sur les quatre fonds de carte et
  sur rien d'autre.
- **L'accent ne porte que des icônes** — pastilles des points forts, lueur du
  bandeau. Titres et corps restent à l'encre : c'est ce qui autorise l'ocre et
  le rose, qui ne tiennent que 3:1.
- **Contenu = données.** Une version est une entrée de `releaseNotes()` et ses
  clés dans les quatre `.arb`. Aucune image à livrer.
- Quand elle s'ouvre : voir docs/03, *Après une mise à jour*.

## La page du soutien (`features/support/`)
« Auxine est gratuite » demande sans rien vendre, et elle n'est pas une page :
c'est **un objet qu'on tend**. Une seule pièce d'argile porte tout — le titre,
ce qui est ouvert, le montant, le bouton — et la plante n'y est pas rangée :
elle est **posée dessus**, débordant du coin haut droit, comme on laisse une
plante sur un coin de table. C'est ce débordement qui sépare un objet d'une
carte à image.

- **La pièce** est en argile crue — `surfaceMuted`, un cran sous le papier —,
  relief franc, rayon `xl`. Elle a été en terre cuite pâle, et c'était une
  erreur de sens autant que de goût : dans cette application la terre cuite
  est la couleur du retard et de l'urgence, et un grand aplat rouge derrière
  une demande se lit comme un avertissement. `surfaceMuted` ne dit rien que
  la matière, laisse ressortir le vert du bouton et la terre cuite du
  montant, et rentre dans le contrat de contraste — les trois encres y
  tiennent 4,5:1, ce que le pastel de terre cuite ne faisait pas.
- **La plante** est celle de l'icône, avec sa pousse et sa respiration. Le
  `Stack` ne rogne pas (`Clip.none`) : ce qui dépasse pousse la pièce vers le
  bas, ce qui y entre creuse sa marge haute, pour que le titre ne lui passe
  pas dessous.
- **Le texte** est rangé à gauche dans la pièce, comme celui des écrans de
  l'onboarding — un titre d'affiche, pas une légende. Sous le titre, deux
  phrases reprises mot pour mot de `store/listing.md` : ce que l'auteur écrit
  déjà de l'application, plutôt qu'une reformulation. Une première version
  tenait en une seule phrase, un deux-points et quatre compléments — la
  cadence d'une machine, et un deux-points qui n'annonçait pas une valeur
  mais une énumération. Les deux-points de l'application servent ailleurs à
  nommer un champ (« Dernier : {date} ») ; celui-là ne nommait rien.
- **La porte**, en pleine encre, entre ce qu'on a reçu et ce qu'on demande :
  « Si vous souhaitez néanmoins aider le développeur, un achat unique
  suffit. » Tout le travail est dans « néanmoins » — le paragraphe au-dessus
  vient de dire que rien n'est dû, celui-ci ouvre quand même une possibilité
  sans rien exiger. Elle nomme aussi la seule chose qui puisse motiver le
  geste : l'argent va à une personne, pas à une société. Rien n'y est
  supposé du lecteur ni promis en échange — c'est un constat, comme le reste
  des textes, et il disparaît une fois le soutien versé.
- **Le montant est dans le bouton** (« Soutenir · CHF 5.00 »), et nulle part
  ailleurs. Écrit en grand et à la main au-dessus, il tenait la moitié du bas
  de la pièce et le bouton n'en était plus que la conclusion ; dans le
  bouton, ce qu'on lit est ce qu'on va faire et ce que cela coûte, d'un seul
  tenant. Dessous, centré et en encre tertiaire, ce que le bouton ne dit
  pas — « Une seule fois ». Centré parce qu'il appartient au bouton, pas au
  paragraphe rangé à gauche au-dessus.
- **Rien d'autre ne se lit après le bouton.** Une mention y a
  traîné — « le soutien ne déverrouille rien » —, et c'était un avertissement
  juste avant le geste : la phrase du haut dit déjà que tout est ouvert, donc
  qu'il n'y a rien à déverrouiller.
- **Sur le papier, sous la pièce**, ne reste que ce qui ne lui appartient
  pas : retrouver un soutien déjà versé n'est pas l'accepter.
- **Une fois versé**, un sceau d'argile se pose au ressort contre le pot, et
  c'est la phrase du haut qui revient au bas de la pièce en plus petit : elle
  se ferme sur ce qu'elle est venue dire plutôt que sur un blanc.

**Deux versions ont échoué avant celle-ci**, et pour la même raison. La
première empilait une pastille en capitales, une grille de quatre tuiles à
icônes et une carte de prix : la page d'accueil de n'importe quel service. La
seconde a tout dégraissé — illustration, titre, phrase, trait, bouton — et
restait le squelette de tous les écrans du monde, simplement plus propre. Ce
n'était pas la densité qui clochait, c'était la structure. La revue de design
ci-dessous demande « ressemble-t-il à un template ? » ; la question se repose
à chaque ajout, et enlever n'y répond pas à soi seul.

**Ce que l'App Store demande** (règles 3.1.1 et 3.2.2(iv)) :

- l'achat est un **non consommable**, donc restaurable : « Restaurer mon
  soutien » est offert **partout où l'achat l'est**, onboarding compris.
  C'est là qu'il sert le plus — quelqu'un qui change de téléphone repasse par
  l'onboarding avant de voir les réglages ;
- le prix vient du magasin, déjà mis en forme dans la monnaie de la personne
  (`SupportOffer.price`), et se lit en entier avant le bouton ;
- rien ne laisse croire à une contrepartie, et ce sont les phrases du haut
  qui s'en chargent — tout est déjà accessible, il n'y a rien à vendre. Le
  mot *don* est
  évité — un pourboire au développeur passe par l'achat intégré (3.1.1), une
  collecte pour une cause est interdite dans l'app (3.2.2(iv)), et les deux ne
  doivent pas se confondre ;
- là où le magasin n'existe pas, une phrase remplace le bouton.

**Dans l'onboarding**, `SupportPitch` se rend en version courte (`compact`) :
seule la scène rapetisse, la page y partageant sa hauteur avec les points de
progression. « Non merci » n'appartient pas à la proposition mais à
l'étape, qui le dessine elle-même avec le bouton discret de l'onboarding,
celui de « Plus tard » : sous « Restaurer mon soutien », qui est vert, deux
fantômes de la même couleur ne disaient plus lequel était la sortie.

Les pièces se posent l'une après l'autre (`Appear`).
`test/features/support_screen_test.dart` tient l'ordre — ce qui est ouvert
avant le montant —, le montant qui ne paraît que là où le magasin le propose,
et la page qui ne redemande rien une fois le soutien versé.

## Design review (par écran)
Est-ce beau ? évident ? Peut-on retirer quelque chose ? L'action principale est-elle visible sans scroller ? Trop de texte ? Moins de taps possible ? Cohérent ? Ressemble-t-il à un template ? → si oui, retravailler.

## Icône de l'application
Le logo est la monstera en papier découpé, dans son pot terracotta, sur
fond blanc.

- Source détourée : `assets/icon/plant.png`. C'est le master : tout le
  reste en dérive.
- `icon.png` / `icon_dark.png` : la plante à 92 % sur blanc. Sans alpha :
  l'App Store la refuse.
- `icon_ios_foreground.png` : la même plante à 92 %, fond transparent. iOS
  pose lui-même le fond du mode nuit et la teinte du mode teinté.
- `icon_foreground.png` : plante à 62 %, fond transparent. Le XML adaptatif
  d'Android ajoute un retrait de 16 %, d'où la marge apparemment large.
- `icon_monochrome.png` : la même silhouette en noir, pour les icônes
  thématiques d'Android 13+.

La plante occupe 92 % de la largeur, comme sur les icônes système : c'est
elle qui doit se lire sur la grille, pas le blanc autour. Les pointes de
feuilles s'arrêtent à 4 % des bords, loin du rayon d'angle du squircle
d'iOS — 22 % du côté, qui n'entame que les coins. Seules les icônes web
« maskable » descendent à 72 % : leur zone de sûreté est un disque de 80 %
du côté, et tout ce qui déborde peut être rogné.

Régénérer après toute modification :
```
python3 tool/build_app_icon.py
```
Le script compose les cinq sources depuis le master, puis toutes les
déclinaisons d'iOS, d'Android et du web, sans chaîne Flutter installée.
`dart run flutter_launcher_icons` fait le même travail depuis
`flutter_launcher_icons.yaml`, à deux réserves près : il rééchantillonne
autrement, et il retaille les « maskable » comme les autres.

## La page web de partage (`supabase/functions/share/`)
Un lien d'invitation ou de plante ouvre une page dans un navigateur, souvent
avant que l'application soit installée : c'est le premier Auxine que voit la
personne invitée. Elle porte donc la même identité — papier crème grainé,
pièces d'argile, titres à la main.

- `page.ts` tient la feuille de style et la coquille ; `index.ts` route et
  interroge. La page se rend donc sans Supabase, ce qui permet de la
  photographier avant de la déployer.
- Les valeurs sont recopiées des tokens Dart. Les changer d'un côté sans
  l'autre ferait deux Auxine.
- `assets.ts` emporte les trois pièces qui ne se recréent pas en CSS :
  Shantell Sans réduite à l'axe 600–700 et au latin étendu, la tuile de grain
  de 128 px, et la vignette des messageries. Servies sous `/asset/`, gardées
  un an par le navigateur ; la page elle-même pèse cinq kilo-octets. Le
  fichier est produit, pas écrit :
  ```bash
  node tool/build_share_preview.mjs     # la vignette, 1200 × 630
  python3 tool/build_share_assets.py    # les trois dans assets.ts
  ```
- **La vignette** (`preview.jpg`) est ce que WhatsApp, Telegram ou Messages
  montrent sous le lien. La monstera du master de l'icône sur le papier
  grainé, « Auxine » tracé à la main : elle est composée en HTML puis
  photographiée par Chromium, seule façon d'avoir la vraie fonte et le vrai
  grain sans les redessiner. En JPEG — le grain est du bruit, il pèse trois
  fois moins là qu'en PNG. Rien n'y nomme le jardin ni la personne : c'est
  `og:title` qui porte le particulier, la vignette ne vieillit qu'avec la
  marque. Une plante partagée garde sa photo ; sans photo, elle retombe sur
  la vignette plutôt que sur un lien nu.
- **Le relief ne se recopie pas chiffre pour chiffre.** Un flou CSS vaut deux
  fois le sigma de Flutter, et surtout les deux ombres intérieures n'y sont
  pas la même figure : `paintClay` floute une bande large de quelques points,
  CSS floute un bord. À opacité égale la bande perd presque tout à la
  convolution, le bord en garde la moitié — un reflet à 0,75 recopié tel quel
  délave la carte. Les opacités du reflet et du creux sont donc celles qui
  rendent le même pic ; l'ombre portée, même figure des deux côtés, garde
  les siennes.
