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

## Composants (`design_system/components/`)
Button · IconButton · PressableScale · ClayBox · ClayLoader · Card · PlantCard · CareCard · ActionChip · BottomSheet · Toast (Undo) · SearchBar · SegmentedControl · EmptyState · Avatar · Badge · Tag · ListRow · TimelineRow · PhotoGrid · QuantityStepper · DatePicker (natif) · PlantPicker · LocationPicker · Skeleton · ErrorState · LargeTitleHeader · SectionHeader

## Design review (par écran)
Est-ce beau ? évident ? Peut-on retirer quelque chose ? L'action principale est-elle visible sans scroller ? Trop de texte ? Moins de taps possible ? Cohérent ? Ressemble-t-il à un template ? → si oui, retravailler.

## Icône de l'application
Le logo est la monstera en papier découpé, dans son pot terracotta, sur
fond blanc.

- Source détourée : `assets/icon/plant.png`. C'est le master : tout le
  reste en dérive.
- `icon.png` / `icon_dark.png` : la plante à 84 % sur blanc. Sans alpha :
  l'App Store la refuse.
- `icon_foreground.png` : plante à 62 %, fond transparent. Le XML adaptatif
  d'Android ajoute un retrait de 16 %, d'où la marge apparemment large.
- `icon_monochrome.png` : la même silhouette en noir, pour les icônes
  thématiques d'Android 13+.

Régénérer après toute modification :
```
dart run flutter_launcher_icons
```
La configuration vit dans `flutter_launcher_icons.yaml`. Les icônes web
« maskable » et le favicon sont retaillés à part : leur zone de sûreté est
plus petite que celle d'iOS.
