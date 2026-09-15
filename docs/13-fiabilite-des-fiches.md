# Fiabilité des fiches d'entretien

Plan d'implémentation. Il remplace `TODO.md`, qui posait les bonnes questions
sans les chiffrer ni les ordonner.

## L'état mesuré

L'encyclopédie affiche 1 900 espèces. Elles sont servies par **181 profils** :

| Niveau | Profils écrits | Espèces servies | Part |
|---|---|---|---|
| espèce | 13 | 13 | 0,7 % |
| genre | 95 | 348 | 18,3 % |
| famille | 65 | 1 260 | 66,3 % |
| catégorie | 7 | 134 | 7,1 % |
| générique | 1 | 145 | 7,6 % |

Le profil `Fabaceae` sert à lui seul 278 espèces, `Asteraceae` 107,
`Pinaceae` 85.

La cascade est dans `lib/data/species/catalog_care_guide.dart:17` : espèce,
genre, famille, catégorie, générique. Elle donne une couverture large à peu
de frais, et c'est un bon choix. Le problème n'est pas l'héritage : c'est
qu'une valeur héritée de la famille s'affiche comme une valeur de l'espèce.

Deux conséquences se mesurent.

**L'encyclopédie.** 1 259 espèces affichent une toxicité affirmée héritée de
leur famille, dont 909 en « Sans danger connu ». Parmi elles :
*Abrus precatorius*, *Laburnum anagyroides*, *Oenanthe aquatica* et trois
autres œnanthes, *Heracleum mantegazzianum*, *Robinia pseudoacacia*,
*Wisteria sinensis*, trois *Senecio*, *Cytisus scoparius*, deux *Lupinus*.
Via `Solanaceae → mild` : *Atropa bella-donna*, *Datura stramonium*,
*Hyoscyamus niger*. Les 31 sont des classes Iris : la reconnaissance photo
les identifie, ouvre leur fiche, et affiche « Aucune toxicité connue pour les
animaux ni les enfants ».

**Le chercheur de plantes.** `lib/domain/species/plant_finder.dart:167`
admet sous `safeOnly` toute fiche dont le profil dit `safe`. Sur les 1 037
espèces du catalogue interne, cela fait 563 admises — dont 365 par famille.
L'écran promet « Seulement des espèces non toxiques ».

**Un troisième champ, silencieux.** `minTempC` n'est pas qu'un texte :
`lib/domain/weather/outdoor_alert.dart:86` en tire l'alerte « rentrez vos
plantes », `lib/domain/home/home_climate_advisor.dart:92` le plancher du
logement, et `CareProfile.frostHardy` en dérive `inWater`, `inPon`,
`potGrown`, `benefitsFromGreenhouse`. 1 260 espèces le tiennent de leur
famille.

---

## Lot 0 — Le garde-fou

La règle est **asymétrique**, et c'est tout l'intérêt : au-dessus du genre,
`toxic` et `mild` se transmettent — ils vont dans le sens de la prudence —,
`safe` ne se transmet pas. Faire passer les 1 259 à `unknown` sans
distinction perdrait les 126 `toxic` corrects d'`Araceae`, `Euphorbiaceae`,
`Apocynaceae`, `Ranunculaceae`, `Papaveraceae`, `Liliaceae`, `Buxaceae`,
`Aquifoliaceae`, `Convolvulaceae` : ce serait une régression de sécurité.

1. `lib/data/species/care_profiles.dart` — retirer `toxicity: Toxicity.safe`
   des 32 profils de `byFamily` qui le portent, et des 3 profils de
   `byCategory` (`herb`, `vegetable`, `fruit`). La valeur par défaut du
   constructeur est déjà `Toxicity.unknown` : c'est une suppression de
   lignes, pas une réécriture.
2. `lib/domain/species/plant_finder.dart` — `_admissible` et `_reasons`
   reçoivent `ResolvedCare` au lieu de `CareProfile` ; `safeOnly` exige
   `care.match == species || genus` **et** `toxicity == safe`. Ceinture et
   bretelles : même si un profil de famille redevenait `safe`, le chercheur
   ne le proposerait pas.

Effet : 909 fiches passent à « Toxicité non renseignée », le chercheur
descend de 563 à 157 espèces admissibles. Aucune chaîne ARB nouvelle —
`careToxicUnknown` et `careToxicUnknownNote` existent et disent déjà « à
tenir hors de portée par précaution ».

Tests — `test/data/care_toxicity_test.dart`, nouveau :
- aucun profil de `byFamily` ni de `byCategory` ne déclare `Toxicity.safe` ;
- une liste de référence d'espèces dangereuses ne résout jamais vers `safe`
  ni `mild`.

Tests — `test/domain/plant_finder_test.dart` :
- sous `safeOnly`, toute proposition vient d'une fiche espèce ou genre ;
- le chercheur rend au moins une proposition pour chaque combinaison
  plausible de critères. Le resserrement ne doit pas vider l'écran ; si un
  trou apparaît, la réponse est d'écrire les fiches genre qui manquent, pas
  de rouvrir l'héritage.

Une demi-journée.

---

## Lot 1 — Sortir la toxicité de `CareProfile`

`Toxicity` est un champ de `CareProfile`. Pour affirmer qu'*Atropa
bella-donna* est mortelle, il faut aussi lui inventer un intervalle
d'arrosage, une lumière, une difficulté et un substrat. C'est pour cela que
les espèces dangereuses n'ont pas de fiche : le coût d'entrée est une fiche
d'entretien complète. Le champ le plus sensible est le plus cher à
renseigner, et c'est l'inverse de ce qu'il faut.

- `lib/domain/care/toxicity.dart`, nouveau :

  ```dart
  enum ToxicitySource { species, genus, family, none }

  class ToxicityFact {
    final Toxicity status;
    final ToxicitySource level;
    final String? matchedOn;
    final String? source;   // « ASPCA », « CAPAE-Ouest »…
  }
  ```

- `lib/data/species/toxicity_catalog.dart`, nouveau : `bySpecies`,
  `byGenus`, `byFamily`, indépendants des profils d'entretien. La règle
  asymétrique du lot 0 passe de la donnée au code — une entrée famille ne
  peut rendre que `toxic`, `mild` ou `unknown`, jamais `safe`.
- On y écrit alors les genres qu'on ne pouvait pas écrire, sans avoir à leur
  inventer un entretien : Abrus, Aconitum, Atropa, Colchicum, Conium,
  Datura, Digitalis, Heracleum, Hyoscyamus, Laburnum, Ligustrum, Lobelia,
  Nerium, Oenanthe, Ricinus, Robinia, Senecio, Jacobaea, Spartium, Cytisus,
  Lupinus, Taxus, Wisteria. Et les corrections repérées : Citrus (le genre
  autant que `Citrus × limon`), Aloe, Vitis, Malus, Dahlia.
- `CareProfile.toxicity` est retiré. Cinq lecteurs à reprendre :
  `care_guide_screen.dart:351-355`, `plant_finder.dart:167` et `:259`,
  `care_labels.dart:33` et `:316`, `glossary_section.dart:40`,
  `care_completion.dart:116`.

L'affichage porte alors sa provenance sur la ligne elle-même, indépendamment
du pied de fiche :

```
🐾  Toxicité          Toxique si ingérée
    Famille des Araceae · non vérifié pour cette espèce
```

C'est le §10 du TODO — provenance par champ — réduit au seul champ qui le
justifie aujourd'hui. `CareValue<T>` généralisé à toute la fiche peut
attendre ; la toxicité, non.

Prévoir 3 à 4 clés ARB nouvelles dans les quatre langues, `flutter
gen-l10n`, les fichiers générés commités, et `test/l10n/arb_tone_test.dart`
vert.

Deux à trois jours.

---

## Lot 2 — Le rapport de couverture, en test

Les chiffres de ce document ont dû être recalculés à la main. Sans mesure
commitée, chaque décision sur l'héritage se discute à l'aveugle et une
régression ne se voit pas.

- `test/data/care_coverage_test.dart` parcourt les 1 900 fiches, résout
  chacune, et compare à un instantané commité : répartition par niveau,
  profils partagés par plus de 10 / 50 / 100 espèces, toxicité par niveau.
- Le test échoue quand l'instantané ne correspond plus. Le diff devient la
  revue : « ce commit fait passer 40 espèces de genre à famille » se lit.
- Cliquet : la part famille ne doit pas augmenter.

Point de départ mesuré : espèce 13, genre 348, famille 1 260, catégorie 134,
générique 145. Profils servant plus de 100 espèces : 3.

Une journée.

---

## Lot 3 — Tests de vérité botanique

`test/data/care_reference_test.dart` : une trentaine d'espèces dont les
faits sont incontestables, la source citée en commentaire. Uniquement ce qui
est stable — toxicité, épiphyte ou non, acidophile ou non, rusticité
grossière. Aucune fréquence d'arrosage au jour près.

Les tests actuels vérifient la structure (résolution, cohérence été/hiver,
plages valides, traductions) ; par construction ils ne peuvent pas attraper
une valeur botaniquement fausse mais syntaxiquement valide.

Une journée.

---

## Lot 4 — `minTempC` et les alertes gel

Scinder en `idealMin`, `idealMax`, `damageBelow`, `survivalMin`. Le point
délicat n'est pas le découpage : c'est de décider ce que `frostHardy` lit —
`survivalMin` — et de le documenter, parce que ce choix change le
comportement de quatre fonctions sans rapport entre elles.

Un seuil hérité de la famille ne déclenche pas d'alerte nominative :
l'alerte dit la famille, ou ne nomme pas de température.

Un à deux jours, tests de `outdoor_alert` compris.

---

## Lot 5 — Le reste

Indépendants les uns des autres, dans cet ordre de valeur.

| | Sujet | Pourquoi ce rang |
|---|---|---|
| 5a | Substrat : séparer `growthMedium` de `substrate` | `Tillandsia` en `SoilKind.aquatic` s'affiche « Sans substrat » alors que la plante est épiphyte. Le changement d'enum ne casse pas le cache `care_completions` : `enumOf` rend `null` sur un nom inconnu, le champ se perd, rien ne plante |
| 5b | Eau : alcalinité, dureté, sodium, fluor ; calcium en nutrition | `care_guide_copy.dart:164-182` fait déjà dire à `CalciumNeed.avoid` une phrase sur l'eau calcaire — la confusion est dans le texte, pas seulement dans l'enum |
| 5c | Brumisation | 108 espèces l'héritent, dont 30 d'une famille : `Arecaceae` la recommande à tous les palmiers |
| 5d | Humidité : toléré / idéal | Petit et mécanique |
| 5e | `dryDown` : besoin de séchage plutôt que nombre de jours | Gros, et touche le moteur de rappels |
| 5f | Données en YAML, puis Care Studio | Dans cet ordre : Care Studio ne peut pas éditer du Dart source |

## Deux choses à ne pas faire

**Le statut « vérifiée par IA ».** Deux statuts suffisent : *héritée, à
vérifier* et *vérifiée avec source*. `care_completion.dart:12-20` pose déjà
le bon principe — la toxicité, la floraison et le repos sont hors du champ
de l'IA parce que ce sont des affirmations sur lesquelles quelqu'un agit.
Une pastille de validation à côté d'une réponse de modèle défait ce
principe. La comparaison multi-modèles est un signal de désaccord, pas un
niveau de confiance.

**Resserrer l'héritage sans regarder le nombre de fiches.**
`iris_detailed_catalog.dart:105` admet une espèce dans l'encyclopédie si et
seulement si elle décroche un profil espèce, genre **ou famille**. Les 456
fiches hors Iris existent parce qu'un profil de famille existe. Décider que
la famille n'est plus un profil acceptable, c'est décider que
l'encyclopédie ne fait plus 1 900 fiches. C'est une question produit, à
trancher explicitement et non par effet de bord.

## Ce que le TODO ne dit pas

Toute chaîne visible passe par les quatre ARB, puis `flutter gen-l10n`, puis
les fichiers générés commités, et `test/l10n/arb_tone_test.dart` doit
passer. C'est la première contrainte du dépôt et, en volume, la moitié de
chaque lot qui touche à l'affichage.
