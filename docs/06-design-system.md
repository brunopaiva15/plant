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

`FloraCard`, `FloraButton`, `EmojiTile`, `QuickActionChip`, `FloraTabBar`,
`SelectionBar` et le toast reposent tous sur `ClayBox` : un composant ne
dessine jamais sa propre ombre.

### Chargement : la motte (`clay_loader.dart`)
Pas de roue qui tourne. `ClayLoader` est une motte d'argile animée image par
image, comme dans *Art Attack* : elle tombe, s'écrase au sol en projetant
six gouttes, rebondit en tremblant de moins en moins, respire en se
remodelant, se ramasse et repart. Un cycle dure 1,6 s. La silhouette ondule
en permanence (trois harmoniques lentes), l'ombre au sol rétrécit quand elle
saute. Elle est peinte avec `paintClay`, la même recette que les cartes.

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
se déclare `header: true`, ce qui rend le rotor « Titres » utilisable.

## Haptics (`core/haptics.dart`)
- `selection` : changement de chip / onglet · `light` : tap bouton · `success` : action enregistrée · `warning` : archivage.

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
Button · IconButton · PressableScale · ClayBox · ClayLoader · Card · ActionTile · PlantCard · CareCard · ActionChip · BottomSheet · Toast (Undo) · SearchBar · SegmentedControl · Slider (natif) · StepDots · EmptyState · Avatar · Badge · Tag · ListRow · TimelineRow · IrisMark · PhotoGrid · PhotoViewer · QuantityStepper · DatePicker (natif) · PlantPicker · PhotoPicker · LocationPicker · Skeleton · ErrorState · LargeTitleHeader · SectionHeader · WhatsNewWindow

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
- Quand elle s'ouvre : voir docs/03, *Après une mise à jour*.

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
