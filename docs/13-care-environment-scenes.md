# Scènes d’environnement des fiches d’entretien

La fiche d’entretien commence par un petit diorama isométrique qui répond à
une question simple : **où cette plante se place-t-elle bien ?**

Le dessin ne remplace pas la fiche. Il en résume seulement les besoins
spatiaux et climatiques avant les cartes détaillées : lumière, humidité et,
quand elle est connue, température idéale.

## Principe

La scène encode l’information dans sa géométrie :

- la distance à la fenêtre représente le besoin lumineux ;
- la position par rapport à la tache de soleil distingue direct et indirect ;
- la luminosité du décor distingue ombre, faible lumière et pièce lumineuse ;
- une brume très légère accompagne les espèces qui demandent un air humide ;
- le contexte intérieur ou extérieur vient du profil et de quelques genres
  dont le milieu est non ambigu ;
- la silhouette donne une forme végétale crédible sans prétendre être un
  modèle 3D botanique exact de chacune des espèces.

La scène montre le **milieu conseillé**. Les mesures réelles de la maison et
la lumière enregistrée sur un emplacement restent traitées par les composants
Home Climate et par le moteur d’entretien ; elles ne déplacent pas la plante
dans le diorama.

## Architecture

Le rendu n’est pas 3D sur le téléphone :

```text
CareProfile
    ↓
CareEnvironmentVisualResolver
    ↓
CareEnvironmentVisualSpec
    ↓
Flutter Stack
    ├── décor Blender pré-rendu
    ├── brume éventuelle
    ├── silhouette Blender pré-rendue
    └── callouts Flutter localisés
```

Le résolveur vit dans
`lib/features/species/application/care_environment_visual.dart`. Il est pur et
déterministe : aucune requête réseau, aucun hasard, aucune donnée ajoutée à la
fiche.

Le widget est `CareEnvironmentHero`. Les textes restent des widgets Flutter :
rien n’est écrit dans les images Blender, pour garder les quatre langues,
Dynamic Type, VoiceOver et les contrastes de l’application.

## Lumière

Les six valeurs de `LightNeed` ont six décors distincts :

| Valeur | Lecture visuelle |
|---|---|
| `shade` | zone reculée et protégée |
| `lowLight` | arrière de la pièce / zone peu éclairée |
| `indirect` | lumière diffuse, distance moyenne |
| `brightIndirect` | près de la fenêtre, hors de la tache de soleil |
| `someSun` | bord du soleil direct |
| `fullSun` | zone directement ensoleillée |

`brightIndirect` est volontairement explicite : la tache de lumière est
visible au sol mais le slot de la plante reste à côté. Le dessin explique donc
le mot « indirecte » sans inventer une distance en mètres ou une orientation
de fenêtre.

## Silhouettes

Les assets actuels couvrent :

- `monstera`
- `broad_leaf`
- `upright_leaf`
- `vine`
- `fern`
- `rosette`
- `cactus`
- `tree`
- `conifer`

La résolution suit cet ordre : espèce/genre reconnaissable, règle de profil,
puis `broad_leaf` en repli. Ajouter une silhouette demande donc :

1. une valeur dans `CarePlantVisualKind` ;
2. une règle ciblée dans le résolveur ;
3. son rendu dans `tool/build_care_scene.py` ;
4. son nom dans `PLANTS` de l’orchestrateur et du test d’assets.

Ne pas transformer ce fichier en seconde taxonomie. Les overrides sont réservés
aux formes visuelles réellement distinctes.

## Blender

Le rendu réutilise `tool/clay_scene.py` : mêmes matériaux mats, même grain et
mêmes primitives de pot/feuille que les autres illustrations d’Auxine.

Régénération complète :

```bash
python3 tool/build_care_scene_assets.py
```

Aperçu rapide et planche de contact sous `/tmp/care_scene` :

```bash
python3 tool/build_care_scene_assets.py --preview
```

Poids seulement :

```bash
python3 tool/build_care_scene_assets.py --poids
```

Blender est cherché dans le `PATH`, puis dans les emplacements usuels déjà
utilisés par les autres outils du dépôt. Les PNG intermédiaires restent sous
`/tmp`. Seuls les WebP de `assets/care_scene/` sont livrés.

## Budget

Le test `test/assets/care_environment_assets_test.dart` exige :

- toutes les variantes attendues ;
- aucun fichier vide ;
- moins de 8 Mo pour la fonctionnalité entière.

Les décors et silhouettes sont réutilisés par toutes les fiches : on ne rend
jamais une image complète par espèce.

## Accessibilité

La scène est exposée comme une seule image sémantique qui énumère uniquement
les informations réelles du profil. Les couches décoratives sont exclues des
sémantiques.

À partir d’un agrandissement de texte important, les callouts quittent le
diorama et passent sous celui-ci dans un `Wrap`, afin de tenir jusqu’à 350 %
sans rognage.

## Courants d’air

Aucun champ fiable de courant d’air n’existe encore dans `CareProfile`.
La première version ne montre donc **aucun verdict** de ce type. Le décor peut
contenir une porte ou une ouverture pour lire la pièce, mais il ne signifie
pas « courant d’air à éviter ».

Si une donnée botanique dédiée est ajoutée plus tard, elle devra être
optionnelle : `null` signifiera « non renseigné » et ne produira ni callout ni
effet visuel. On ne déduira pas ce besoin d’une catégorie, d’une humidité ou
du fait qu’une plante est tropicale.
