# F. Design system

Identité : **calme, chaleureux, naturel, précis**. Le vert n'est qu'un accent.

## Couleurs (`design_system/tokens/colors.dart`)
Direction (références fournies) : fond très clair teinté menthe, cartes blanches très arrondies, vert franc en accent, pastels bleu / jaune / rose pour les indicateurs, tab bar flottante en pilule.

| Token | Clair | Sombre | Usage |
|---|---|---|---|
| `canvas` | #F3F6F1 | #0F1411 | fond d'écran |
| `surface` | #FFFFFF | #181E1A | cartes, sheets |
| `surfaceMuted` | #EDF1EB | #222925 | chips, champs |
| `ink` | #1A1F1B | #F1F4F0 | texte principal |
| `inkSecondary` | #66706A | #A3ACA5 | texte secondaire |
| `inkTertiary` | #98A19B | #6F7872 | captions, placeholders |
| `line` | #E2E8E0 | #2B332E | séparateurs (rares) |
| `sage` | #2E8B57 | #5FC787 | accent, boutons principaux |
| `sageSoft` | #E3F2E8 | #1F3327 | fond positif, chip active |
| `water` / `waterSoft` | #3E7FC4 / #E3EEFA | #7FB2E5 / #1C2A3A | arrosage |
| `sun` / `sunSoft` | #C99A00 / #FFF4D3 | #E9C043 / #34301A | lumière, engrais |
| `rose` / `roseSoft` | #D1506C / #FDE8EE | #E87A94 / #3A2129 | favoris, santé |
| `terracotta` / `terracottaSoft` | #C8752A / #FBEEDD | #E39A5B / #3A2A1C | retard, attention |
| `danger` | #C0392B | #E06B5E | destructif |

Contrastes texte/fond ≥ 4.5:1 (ink sur canvas ≈ 15:1 ; inkSecondary sur canvas ≈ 5:1 ; blanc sur sage ≈ 4.6:1).

## Typographie (`typography.dart`) — police système (SF sur iOS, Roboto sur Android)
| Style | Taille / poids | Usage |
|---|---|---|
| Display | 34 / 700, -0.6 | grand titre d'onglet |
| Title1 | 28 / 700, -0.4 | nom de plante (fiche) |
| Title2 | 22 / 600, -0.3 | sections |
| Title3 | 17 / 600 | titres de cartes |
| Body | 17 / 400 | texte |
| Callout | 15 / 400 | secondaire |
| Caption | 13 / 500 | métadonnées |
Dynamic Type : toutes les tailles suivent `MediaQuery.textScaler`.

## Spacing (`spacing.dart`) : 4 · 8 · 12 · 16 · 20 · 24 · 32 · 40 · 48
## Radius (`radius.dart`) : small 10 · medium 16 · large 24 (cartes) · xl 32 (sheets, héros) · full (boutons, chips, tab bar)
## Élévation : une seule ombre douce (`0 8 24 rgba(27,26,23,0.06)`), jamais en dark mode (on utilise la teinte de surface).
## Motion (`motion.dart`)
- Durées : 150 (micro) · 250 (standard) · 400 (emphase). Courbes : `easeOutCubic`, `Curves.easeInOutCubicEmphasized` pour les sheets.
- `reduced motion` : durées → 0, pas de translation, uniquement fondu.
## Haptics (`core/haptics.dart`)
- `selection` : changement de chip / onglet · `light` : tap bouton · `success` : action enregistrée · `warning` : archivage.

## Composants (`design_system/components/`)
Button · IconButton · PressableScale · Card · PlantCard · CareCard · ActionChip · BottomSheet · Toast (Undo) · SearchBar · SegmentedControl · EmptyState · Avatar · Badge · Tag · ListRow · TimelineRow · PhotoGrid · QuantityStepper · DatePicker (natif) · PlantPicker · LocationPicker · Skeleton · ErrorState · LargeTitleHeader · SectionHeader

## Design review (par écran)
Est-ce beau ? évident ? Peut-on retirer quelque chose ? L'action principale est-elle visible sans scroller ? Trop de texte ? Moins de taps possible ? Cohérent ? Ressemble-t-il à un template ? → si oui, retravailler.
