# Les guides de multiplication

Multiplier une plante n'est pas un geste unique. On coupe un pothos sous un
nœud, on partage une touffe de spathiphyllum, on détache un rejet d'aloe, on
laisse sécher un segment de cactus. L'application montre le geste que la
plante demande — jamais un geste par défaut habillé d'un autre texte.

## L'architecture

Un **archétype** (`PropagationGuideKind`) est un geste, pas une famille
botanique. Sept sont livrés :

| Archétype | Geste | Plantes |
|---|---|---|
| `stemNodeVine` | bouture de tige à nœud | monstera, pothos, philodendron |
| `stemSoft` | bouture de tige tendre | basilic, menthe, coleus |
| `leafCutting` | bouture de feuille | sansevieria, ZZ, bégonia |
| `division` | partage d'une touffe | spathiphyllum, graminées |
| `offset` | séparation d'un rejet | pilea, aloe, chlorophytum |
| `keiki` | séparation du rejet d'une orchidée | phalaenopsis, dendrobium |
| `succulentSegment` | bouture de segment | cactus de Noël, crassula |

Trois fichiers portent l'essentiel :

- `lib/domain/cuttings/propagation_guide.dart` — l'énumération, la liste des
  étapes de chaque archétype (`propagationStepIds`), et le cache des textes
  précisés par l'IA ;
- `lib/domain/cuttings/propagation_guide_resolver.dart` — **la seule** règle
  qui choisit le guide, à partir de l'espèce, de la famille et du
  `CareProfile`. Pas de `if` dispersé dans l'interface ;
- `lib/features/cuttings/application/propagation_guides.dart` — les titres,
  les textes locaux, les couleurs, les notes, assemblés sur les identifiants
  du domaine.

Le nombre d'étapes appartient au guide. Rien, dans l'écran, ne suppose qu'il
en faut six : `PropagationGuideStage`, la grappe d'introduction et les points
de progression se calculent sur la liste reçue.

### Méthode et milieu

`Propagation.water` n'est pas une méthode de multiplication : c'est un milieu
d'enracinement, écrit dans la même liste depuis les premières fiches.
`CareProfile.propagationMethods` rend les vraies méthodes,
`CareProfile.rootingMedium` rend le milieu (`water`, `substrate`, `either`,
`none`). Les fiches déjà enregistrées ne bougent pas.

### Plusieurs méthodes

Quand la plante se multiplie de plusieurs façons — une sansevieria se divise
ou se bouture par feuille —, `resolvePropagationOptions` en rend jusqu'à
trois, la conseillée d'abord (l'ordre de `CareProfile.propagation`), et
l'écran de choix paraît avant le guide. Deux méthodes qui montrent le même
geste n'en font qu'une.

## Ajouter un archétype

1. une valeur dans `PropagationGuideKind`, et ses étapes dans
   `propagationStepIds` — les identifiants nomment aussi les fichiers ;
2. le guide dans `propagation_guides.dart` : nom, ligne d'aide, un titre, un
   texte local, une couleur et parfois une note par étape ;
3. les clés dans les quatre ARB, puis `flutter gen-l10n` ;
4. la règle de choix dans `propagation_guide_resolver.dart` ;
5. la description des étapes pour l'IA dans `stepBriefs`
   (`infomaniak_propagation_refiner.dart`) ;
6. un module Blender `tool/cutting/<archétype>.py` et son entrée dans
   `PACKS` (`tool/build_cutting_guide.py`, `tool/build_cutting_assets.py`) ;
7. le dossier d'assets dans `pubspec.yaml`.

Les tests d'`test/assets/propagation_sequences_test.dart` et de
`test/domain/propagation_guide_resolver_test.dart` refusent tout ce qui
manque.

## Les animations

Rendues sous Blender, en argile mate, vue 3/4 orthographique, fond
transparent et sans ombre portée — l'ombre et le flottement sont dessinés par
l'application. Chaque séquence montre **un geste** ; rien n'y tourne pour le
plaisir de tourner.

```
tool/cutting/
    common.py              amortis, primitives, palette, boucle de rendu
    stem_node_vine.py      un module par archétype : sa plante et ses gestes
    stem_soft.py
    leaf_cutting.py
    division.py
    offset.py
    keiki.py
    succulent_segment.py
tool/build_cutting_guide.py    le script lancé sous Blender
tool/build_cutting_assets.py   l'orchestrateur : rendu, emballage, poids
```

Chaque étape est cadrée une fois pour toutes sur l'union de ses images clefs
(`rendre()` dans `common.py`) : sans cela le cadre suivrait le sujet et c'est
le monde qui semblerait bouger.

Une racine ne traverse pas la paroi de son pot ni le fond de son verre.
`Creux` décrit le volume intérieur d'un contenant — le rayon disponible à
chaque hauteur, le fond, une marge pour l'épaisseur des racines — et
`faisceau_racines(dans=…)` y ramène chaque point du tracé. Toute étape qui
montre des racines dans un contenant passe ce `dans` ; sans lui, une racine
sort par le flanc du pot, et cela se voit.

### Régénérer

Blender est cherché dans le `PATH` puis aux endroits usuels ; rien n'est
installé.

```bash
python3 tool/build_cutting_assets.py                  # tout, en qualité livrée
python3 tool/build_cutting_assets.py --preview        # 4 images par étape
python3 tool/build_cutting_assets.py division offset  # deux archétypes
python3 tool/build_cutting_assets.py --etape cut succulent_segment
python3 tool/build_cutting_assets.py --poids          # juste le récapitulatif
```

Le rendu brut va sous `/tmp/multiplication` (`--out` pour ailleurs), hors du
dépôt. Seuls les WebP animés de `assets/cutting/<archétype>/` sont commités.

Sans l'orchestrateur, Blender se lance directement :

```bash
blender -b -noaudio -P tool/build_cutting_guide.py -- complet all --res 768 --samples 24
blender -b -noaudio -P tool/build_cutting_guide.py -- apercu stem_node_vine
python3 tool/pack_growth.py /tmp/multiplication/division/separate assets/cutting/division/separate.webp --fps 14
```

### Le poids

`--poids` affiche le compte, pack par pack et en tout. Une séquence pèse
quelques centaines de kilooctets ; au-delà d'un mégaoctet et demi, le test
d'assets refuse. `ClaySequence` décode image par image, à la taille
d'affichage, et l'écran ne précharge que l'étape courante et la suivante :
les dizaines de séquences ne sont jamais toutes en mémoire.

## L'IA

`InfomaniakPropagationRefiner` ne décide de rien. Il reçoit l'espèce, la
méthode, l'archétype et la liste exacte des étapes ; il rend un texte par
étape, dans le même ordre. Une réponse d'une autre longueur est jetée, et les
textes locaux restent — ils sont déjà justes pour l'archétype. Le cache est
indexé par langue, archétype et espèce : le texte d'une division ne ressort
jamais pour une bouture de feuille de la même plante.

Sans clé, sans réseau, ou avec l'assistance coupée dans les réglages, le
guide marche entier.
