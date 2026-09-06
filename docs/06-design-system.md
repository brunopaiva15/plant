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
| `inkTertiary` | #9A8577 | #9C8878 | captions, placeholders |
| `line` | #E6D9C8 | #4A3A2E | séparateurs (rares) |
| `sage` | #2F7F53 | #6DC48D | accent, boutons principaux |
| `sageSoft` | #E4EFE6 | #2C3D31 | fond positif, chip active |
| `terracotta` / `terracottaSoft` | #BD5836 / #F2D9CB | #E59A70 / #4A2E22 | retard, héros du matin |
| `water` / `waterSoft` | #4A82BC / #DCE7F3 | #8FB8E4 / #2B3644 | arrosage |
| `sun` / `sunSoft` | #C4903A / #F3E3C2 | #E7C15C / #45391F | lumière, engrais |
| `rose` / `roseSoft` | #C4566A / #F5DDE0 | #EC8A9B / #4A2C31 | favoris, santé |
| `danger` | #C0392B | #E47064 | destructif |
| `shadow` | #5E2C14 à 14 % | — | ombre portée du clay |

Contrastes texte/fond ≥ 4.5:1 (ink sur canvas ≈ 10:1 ; inkSecondary sur canvas ≈ 5.7:1 ; blanc sur sage ≈ 4.9:1).

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
Dynamic Type : toutes les tailles suivent `MediaQuery.textScaler`.

## Spacing (`spacing.dart`) : 4 · 8 · 12 · 16 · 20 · 24 · 32 · 40 · 48
## Radius (`radius.dart`) : small 10 · medium 16 · large 24 (cartes) · xl 32 (sheets, héros) · full (boutons, chips, tab bar)
## Élévation : c'est le clay qui fait le relief (voir *Matière*). `shadows.dart` ne sert plus qu'aux rares éléments hors design system.
## Motion (`motion.dart`)
- Durées : 150 (micro) · 250 (standard) · 400 (emphase). Courbes : `easeOutCubic`, `Curves.easeInOutCubicEmphasized` pour les sheets.
- `reduced motion` : durées → 0, pas de translation, uniquement fondu.
## Haptics (`core/haptics.dart`)
- `selection` : changement de chip / onglet · `light` : tap bouton · `success` : action enregistrée · `warning` : archivage.

## Composants (`design_system/components/`)
Button · IconButton · PressableScale · ClayBox · ClayLoader · Card · PlantCard · CareCard · ActionChip · BottomSheet · Toast (Undo) · SearchBar · SegmentedControl · EmptyState · Avatar · Badge · Tag · ListRow · TimelineRow · PhotoGrid · QuantityStepper · DatePicker (natif) · PlantPicker · LocationPicker · Skeleton · ErrorState · LargeTitleHeader · SectionHeader

## Design review (par écran)
Est-ce beau ? évident ? Peut-on retirer quelque chose ? L'action principale est-elle visible sans scroller ? Trop de texte ? Moins de taps possible ? Cohérent ? Ressemble-t-il à un template ? → si oui, retravailler.

## Icône de l'application
Le logo est la pousse en pot de l'onboarding, en argile, sur fond blanc.

- Source détourée : `assets/icon/plant.png`, l'objet de
  `assets/onboarding/onboarding_1.png` recadré sur ses bords. C'est le
  master : tout le reste en dérive.
- `icon.png` / `icon_dark.png` : la pousse à 78 % sur blanc. Sans alpha :
  l'App Store la refuse.
- `icon_foreground.png` : pousse à 56 %, fond transparent. Le XML adaptatif
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
