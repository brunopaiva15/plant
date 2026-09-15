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


Un second tap sur l'onglet courant ramène sa liste en haut, comme sur iOS.
Chaque branche du shell pose son propre `ScrollController` en
`PrimaryScrollController` *dans* sa route (`TabScrollScope`) : il passe
devant celui que la route fournit d'elle-même, la liste de l'onglet s'y
attache sans qu'on le lui dise, et le tap sur la barre d'état — que le
`Scaffold` sert avec ce même contrôleur — continue de marcher. La remontée
suit *réduire les animations* : un saut au lieu d'une glissade.

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
Button · IconButton · PressableScale · ClayBox · ClayLoader · Appear · Card · ActionTile · PlantCard · CareCard · ActionChip · Pill · BottomSheet · Toast (Undo) · SearchBar · SegmentedControl · Slider (natif) · StepDots · EmptyState · Avatar · Badge · Tag · ListRow · TimelineRow · IrisMark · PhotoGrid · PhotoViewer · QuantityStepper · DatePicker (natif) · PlantPicker · PhotoPicker · LocationPicker · Skeleton · ErrorState · LargeTitleHeader · SectionHeader · WhatsNewWindow

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
Cinq volets se pratiquent — arrosage, lumière, humidité, engrais, rempotage —
et chacun a sa carte, teintée de la couleur de son sujet : bleu poussière pour
l'eau, ocre pour la lumière, rose pour l'air, sauge pour l'engrais, terre cuite
pour le rempotage. Une douzaine de lignes dans une seule liste ne se
distinguaient qu'à la lecture ; une carte se retrouve à sa couleur.

L'anatomie est celle des cartes du matin : une tuile d'emoji — crème, comme
sur toute carte teintée —, le nom du volet, le constat dessous, puis ce qui ne
vaut que pour lui : la saison de l'engrais, le substrat avec le rempotage (le
jour où il sert), « Brumiser » sous l'humidité, « Repos hivernal » sous
l'arrosage. L'arrosage porte son chiffre en `title2`, dans le bleu de l'eau :
c'est la question qu'on se pose en premier. La carte « Chez vous » se pose
après l'humidité, puisque c'est l'air de la pièce qu'elle mesure.

Ce qui se lit sans rien faire — température, difficulté, toxicité — reste une
`FloraGroup` à la suite, avant les conseils, ce qu'il faut surveiller, les
problèmes connus et la multiplication ; la provenance de la fiche ferme la
page. `test/features/care_guide_test.dart` tient la séparation.

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
- **Les ajouts courts se rassemblent** sous la ligne « Petites nouveautés » :
  un lot par entrée, le titre disant son sujet, trois points forts au plus —
  la fenêtre n'en montre pas davantage sans se tasser. Un gros morceau, lui,
  garde sa fiche à soi.
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
