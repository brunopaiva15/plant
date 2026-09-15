# TODO — Fiabilisation des fiches d’entretien Auxine

Ce document regroupe l’audit des fiches d’entretien d’Auxine et les actions à mener pour améliorer progressivement leur fiabilité botanique, leur traçabilité et leur maintenabilité.

## Constat général

L’encyclopédie affiche actuellement 1 900 espèces, dont 1 444 classes reconnues par Iris et 456 espèces supplémentaires. En revanche, il n’existe pas 1 900 profils d’entretien indépendants.

La résolution actuelle suit cette cascade :

1. espèce exacte ;
2. genre ;
3. famille ;
4. catégorie ;
5. profil générique.

Fichiers principaux :

- `lib/data/species/care_profiles.dart`
- `lib/data/species/catalog_care_guide.dart`
- `lib/domain/care/care_profile.dart`
- `lib/domain/care/care_completion.dart`
- `lib/features/species/presentation/care_guide_screen.dart`
- `lib/features/encyclopedia/presentation/species_page.dart`

Cette architecture donne une excellente couverture, mais elle peut aussi faire apparaître comme très précise une donnée qui vient seulement du genre ou de la famille.

---

# P0 — Fiabilité et sécurité

## [ ] 1. Sortir la toxicité de l’héritage générique

La toxicité ne doit pratiquement jamais être héritée automatiquement au niveau famille.

Problème actuel :

```dart
CareMatch.family
```

peut fournir une valeur :

```dart
toxicity: Toxicity.safe
```

alors que les espèces d’une même famille peuvent avoir des profils toxicologiques très différents.

### Actions

- [ ] Ne plus considérer la toxicité d’un profil de famille comme spécifique à une espèce.
- [ ] Pour les profils familiaux, utiliser `Toxicity.unknown` par défaut sauf cas réellement uniforme et documenté.
- [ ] Vérifier toutes les toxicités définies dans `bySpecies` et `byGenus`.
- [ ] Auditer en priorité les plantes domestiques courantes.
- [ ] Ajouter des tests empêchant une toxicité familiale non vérifiée d’être présentée comme une donnée espèce.
- [ ] Afficher la provenance de la toxicité indépendamment du reste de la fiche.

### Erreurs déjà repérées

#### `Citrus × limon`

Actuellement :

```dart
toxicity: Toxicity.safe
```

À revoir : l’ASPCA classe le citron comme toxique pour chiens et chats en raison notamment des huiles essentielles et psoralènes, même si le fruit lui-même n’a pas le même profil que les autres parties de la plante.

#### `Aloe vera`

Actuellement :

```dart
toxicity: Toxicity.mild
```

À revoir : l’ASPCA classe Aloe vera comme toxique pour chiens et chats.

### Évolution du schéma souhaitée

Le modèle actuel :

```dart
enum Toxicity { safe, mild, toxic, unknown }
```

est trop simple.

À terme, envisager :

```text
toxicity
├── cats
│   ├── status
│   ├── severity
│   └── affectedParts
├── dogs
├── humans
└── source
```

Exemples de parties : feuilles, sève, bulbe, fruit, graines, racines.

---

## [ ] 2. Distinguer les champs héritables des champs non héritables

Tous les champs ne doivent pas suivre la même règle de résolution espèce → genre → famille.

### Héritage raisonnable au niveau genre, avec prudence

- lumière ;
- besoin général en humidité ;
- type global de substrat ;
- type de croissance ;
- certaines méthodes de propagation ;
- certains problèmes fréquents.

### Héritage familial à considérer comme faible confiance

- lumière ;
- humidité ;
- substrat ;
- rusticité ;
- arrosage ;
- difficulté ;
- fertilisation ;
- propagation ;
- problèmes fréquents.

### Champs à ne pas hériter aveuglément

- toxicité ;
- comestibilité ;
- température minimale précise ;
- floraison ;
- dormance ;
- besoins nutritionnels précis ;
- fréquence d’arrosage précise ;
- recette de substrat précise ;
- tolérance exacte à l’eau ;
- instructions de sécurité.

### Actions

- [ ] Ajouter une notion de provenance par champ et non seulement par fiche.
- [ ] Ajouter une notion de confiance par champ.
- [ ] Empêcher certains champs sensibles d’être promus depuis un profil familial.

---

# P1 — Repenser les données d’entretien

## [ ] 3. Séparer le besoin botanique d’arrosage du rappel en jours

Actuellement, une espèce possède par exemple :

```dart
wateringSummerDays: 7,
wateringWinterDays: 14,
```

Puis `wateringDaysFor()` interpole selon le mois et applique un facteur lié à la lumière.

Le problème est qu’un nombre de jours n’est pas une propriété botanique stable de l’espèce.

La fréquence réelle dépend notamment de :

- taille de la plante ;
- volume du pot ;
- matériau du pot ;
- composition du substrat ;
- densité racinaire ;
- température ;
- humidité ;
- ventilation ;
- lumière ;
- saison.

### Direction souhaitée

Ajouter une règle botanique de séchage du substrat, par exemple :

```text
dryDown:
  alwaysMoist
  surfaceDry
  topQuarterDry
  halfDry
  mostlyDry
  fullyDry
```

Les jours deviennent ensuite une estimation initiale du moteur de rappels.

Exemple :

```text
Fiche botanique
→ laisser sécher les 25 % supérieurs

Moteur Auxine
→ estimation initiale : 7 jours

Historique de la plante réelle
→ intervalle observé : environ 9 jours
```

### Actions

- [ ] Ajouter un champ `dryDown` ou équivalent.
- [ ] Conserver temporairement `wateringSummerDays` et `wateringWinterDays` pour compatibilité.
- [ ] Faire évoluer le moteur de rappels vers un apprentissage basé sur l’historique réel de la plante.
- [ ] Utiliser les jours comme estimation, pas comme vérité botanique.
- [ ] Afficher dans la fiche la règle de substrat avant la fréquence estimée.

---

## [ ] 4. Séparer calcium, dureté, alcalinité et sensibilité à l’eau

Le modèle actuel mélange plusieurs notions :

```dart
enum WaterTolerance { tolerant, sensitive, strict }
enum CalciumNeed { avoid, neutral, welcome, needed }
```

et le code rapproche fortement `CalciumNeed.avoid` de la sensibilité au calcaire.

Or :

- calcium nutritif ≠ dureté ;
- dureté ≠ alcalinité ;
- alcalinité ≠ pH ;
- eau dure ≠ forcément mauvaise ;
- une eau très pure peut au contraire nécessiter un apport Ca/Mg.

### Schéma cible possible

```text
water
├── alkalinityTolerance
├── hardnessTolerance
├── sodiumSensitivity
├── fluorideSensitivity
└── preferredWater

nutrition
└── calciumRequirement
```

### Actions

- [ ] Ne plus utiliser `CalciumNeed.avoid` comme proxy de l’eau calcaire.
- [ ] Conserver le calcium dans la partie nutrition.
- [ ] Ajouter au besoin une sensibilité aux bicarbonates/alcalinité.
- [ ] Ajouter une sensibilité au fluor pour les espèces connues pour les pointes brunes.
- [ ] Ajouter une sensibilité au sodium.
- [ ] Revoir `WaterTolerance` pour qu’il ne compacte pas toutes ces notions en un seul enum.
- [ ] Adapter `water_types_sheet.dart` au nouveau modèle.

---

## [ ] 5. Repenser le modèle de substrat

Actuellement :

```dart
enum SoilKind {
  standard,
  draining,
  cactus,
  orchid,
  acidic,
  rich,
  aquatic,
}
```

Le champ mélange plusieurs axes : richesse, drainage, pH et mode de croissance.

### Cas révélateur : Tillandsia

Actuellement :

```dart
soil: SoilKind.aquatic
```

L’interface traduit cela par « Sans substrat », mais Tillandsia est une plante épiphyte/lithophyte, pas aquatique.

### Schéma cible possible

```text
growthMedium:
  terrestrial
  epiphytic
  lithophytic
  aquatic
  semiAquatic

substrate:
  organic
  chunky
  mineral
  cactus
  acidic
  orchidBark
  none
```

Éventuellement séparer également :

```text
substrateProperties:
  drainage
  aeration
  moistureRetention
  organicMatter
  preferredPhMin
  preferredPhMax
```

### Actions

- [ ] Ajouter un type de milieu de croissance.
- [ ] Ne plus représenter « sans substrat » par `aquatic`.
- [ ] Revoir Tillandsia et les autres épiphytes.
- [ ] Séparer le pH du type de substrat.
- [ ] Séparer richesse et drainage.

---

## [ ] 6. Ne plus utiliser une recette universelle par `SoilKind`

Exemple actuel pour `rich` :

```text
40 % terreau
40 % compost
20 % perlite
```

Cette recette peut aujourd’hui être appliquée à des Monstera, Calathea, Musa, légumes, etc.

Le terme `rich` peut rester une catégorie générale, mais une recette exacte doit être plus spécifique.

### Actions

- [ ] Ajouter `substrateRecipe` optionnel au niveau espèce ou genre.
- [ ] N’afficher des pourcentages que lorsque la recette est réellement adaptée au taxon.
- [ ] Sinon afficher une description qualitative : « riche, aéré et drainant ».
- [ ] Permettre plusieurs recettes équivalentes si nécessaire.

---

## [ ] 7. Repenser l’humidité

Le modèle actuel combine :

```dart
HumidityNeed.low / average / high
```

et éventuellement une plage en pourcentage.

C’est déjà une bonne base, mais il faut distinguer :

- minimum toléré ;
- plage idéale ;
- humidité réellement nécessaire pour éviter les dommages.

### Schéma cible possible

```text
humidity:
  toleratedMin
  idealMin
  idealMax
```

### Actions

- [ ] Ne pas confondre « préfère 60–80 % » avec « souffre sous 60 % ».
- [ ] Auditer les valeurs élevées héritées par genre/famille.
- [ ] Ne pas afficher une plage trop précise lorsqu’elle vient d’un profil général.

---

## [ ] 8. Repenser la température

Actuellement :

```dart
minTempC
idealTempMinC
idealTempMaxC
```

Bonne base, mais `minTempC` mélange parfois minimum conseillé, seuil de dégâts et survie absolue.

### Schéma cible possible

```text
temperature:
  idealMin
  idealMax
  damageBelow
  survivalMin
```

### Actions

- [ ] Clarifier la sémantique de `minTempC`.
- [ ] Distinguer « éviter sous 15 °C » de « meurt sous 5 °C ».
- [ ] Ne pas donner de minimum très précis au niveau famille si les genres diffèrent fortement.

---

## [ ] 9. Revoir la brumisation

Actuellement :

```dart
mistLeaves: true / false
```

Une simple recommandation de brumisation est discutable : elle augmente très temporairement l’humidité et peut être indésirable pour certaines espèces si le feuillage reste humide.

### Actions

- [ ] Remplacer `mistLeaves` par une stratégie d’humidité plus précise.
- [ ] Distinguer humidificateur, plateau humide, terrarium/serre et brumisation.
- [ ] Ne recommander la brumisation que lorsqu’elle a un intérêt réel pour le taxon ou le mode de culture.

---

# P1 — Provenance et confiance

## [ ] 10. Passer d’une provenance par fiche à une provenance par champ

Actuellement :

```dart
enum CareMatch {
  species,
  genus,
  family,
  category,
  generic,
  assisted,
}
```

La provenance porte sur toute la fiche.

Or une fiche peut très bien avoir :

```text
Lumière        → genre
Arrosage       → espèce
Toxicité       → source vérifiée
Température    → famille
Floraison      → espèce
```

### Actions

- [ ] Introduire une structure du type `CareValue<T>`.

Exemple :

```dart
class CareValue<T> {
  final T value;
  final CareSourceLevel level;
  final String? sourceId;
  final double? confidence;
  final DateTime? reviewedAt;
}
```

- [ ] Afficher l’origine sur chaque volet important.
- [ ] Ne plus laisser une fiche familiale donner l’impression que toutes les valeurs sont spécifiques à l’espèce.

---

## [ ] 11. Ajouter des statuts de vérification

Proposition :

```text
⚪ Héritée
🟡 À vérifier
🔵 Vérifiée par IA
🟢 Vérifiée avec source
🔴 Conflit détecté
```

Important : « vérifiée par IA » ne doit pas être assimilé à « vérifiée avec source ».

### Actions

- [ ] Ajouter un statut au niveau champ ou fiche.
- [ ] Ajouter `reviewedAt`.
- [ ] Ajouter `reviewedBy` si utile.
- [ ] Ajouter une ou plusieurs références source.

---

# P1 — Care Studio

## [ ] 12. Créer un outil interne pour éditer les fiches sans toucher au Dart

Objectif : pouvoir améliorer toi-même progressivement les 1 900 fiches.

### Fonctionnement souhaité

Exemple pour `Anthurium clarinervium` :

```text
Lumière           brightIndirect    Genre: Anthurium
Arrosage été      6 jours           Genre: Anthurium
Humidité          60–80 %           Genre/famille
Substrat          orchid            Genre: Anthurium
Toxicité          toxic             Genre: Anthurium
Température min   15 °C             Genre: Anthurium
```

Chaque ligne doit montrer :

- valeur effective ;
- niveau d’héritage ;
- source ;
- statut de validation ;
- date de dernière révision.

### Bouton clé

```text
Créer une fiche spécifique
```

Il copie les valeurs héritées dans une nouvelle fiche espèce, puis permet de modifier uniquement les différences.

### Modification d’un profil générique

Avant de modifier un genre ou une famille, afficher par exemple :

```text
Cette modification affectera 34 espèces.
```

ou :

```text
Cette modification affectera 127 espèces.
```

### Actions

- [ ] Créer un écran interne/dev `Care Studio`.
- [ ] Recherche par nom scientifique et nom courant.
- [ ] Afficher la chaîne complète d’héritage.
- [ ] Afficher les espèces affectées par un profil genre/famille.
- [ ] Permettre de créer un override espèce.
- [ ] Permettre de modifier les valeurs avec contrôles de validation.
- [ ] Afficher les champs hérités en lecture claire.
- [ ] Afficher les conflits détectés.
- [ ] Ajouter filtre « fiches à vérifier ».
- [ ] Ajouter filtre « héritage famille ».
- [ ] Ajouter filtre « toxicité inconnue ».
- [ ] Ajouter filtre « valeurs générées par IA ».

---

# P1 — Sortir les données du code Dart

## [ ] 13. Migrer progressivement `care_profiles.dart` vers des fichiers de données éditables

Le gigantesque fichier Dart devient difficile à maintenir manuellement.

### Proposition

```text
data/care/
├── species.yaml
├── genera.yaml
├── families.yaml
└── categories.yaml
```

ou un format JSON équivalent.

Exemple :

```yaml
Monstera deliciosa:
  verified: true
  reviewed_at: 2026-09-15

  light:
    value: brightIndirect
    source: RHS

  watering:
    dry_down: topQuarterDry
    reference_summer_days: 7
    reference_winter_days: 14

  humidity:
    ideal_min: 50
    ideal_max: 70

  temperature:
    ideal_min: 18
    ideal_max: 27
    damage_below: 10

  toxicity:
    cats: toxic
    dogs: toxic
    humans: irritating
    source: ASPCA
```

### Architecture possible

```text
YAML/JSON éditable
      ↓
validation
      ↓
générateur
      ↓
Dart typé / asset compact
      ↓
Auxine
```

### Actions

- [ ] Définir le schéma de données.
- [ ] Écrire un validateur.
- [ ] Générer les objets Dart ou charger un asset compilé.
- [ ] Garder les enums Dart pour la sûreté de type.
- [ ] Ajouter des tests de non-régression.

---

# P2 — Utiliser l’IA comme assistant, pas comme autorité

## [ ] 14. Faire évoluer l’usage de `CareCompletion`

Actuellement, l’IA ne complète que les fiches :

```dart
CareMatch.generic
CareMatch.category
```

Les profils de genre et de famille ne sont donc jamais contrôlés par l’IA.

Cela signifie que remplacer simplement Mistral par Qwen ne corrigera pas le principal problème des 1 900 fiches.

### Nouvelle utilisation souhaitée

Utiliser plusieurs modèles comme outil d’audit dans Care Studio.

Exemple :

```text
Humidité Monstera

Auxine    55–75 %
Qwen      60–80 %
Kimi      60–80 %
Mistral   70–80 %

⚠️ Désaccord détecté
```

Puis vérifier la donnée dans une source horticole fiable.

### Actions

- [ ] Garder l’IA hors des champs sensibles non vérifiés : toxicité, sécurité, comestibilité, dormance critique.
- [ ] Ajouter un outil de comparaison Auxine / Qwen / Kimi / Mistral.
- [ ] Détecter automatiquement les désaccords importants.
- [ ] Permettre d’accepter/rejeter une proposition champ par champ.
- [ ] Ne jamais marquer automatiquement une donnée comme « vérifiée avec source » à partir d’un LLM.

---

# P2 — Audit automatisé des 1 900 fiches

## [ ] 15. Générer un rapport de couverture réelle

Pour chaque espèce de l’encyclopédie, produire :

```text
scientific_name
family
care_match
matched_on
number_of_species_using_same_profile
toxicity_source
review_status
```

### Statistiques à calculer

- [ ] nombre de fiches espèce exactes ;
- [ ] nombre de fiches héritées du genre ;
- [ ] nombre de fiches héritées de la famille ;
- [ ] nombre de fiches catégorie ;
- [ ] nombre de fiches génériques ;
- [ ] nombre de fiches avec toxicité spécifique ;
- [ ] nombre de fiches avec température spécifique ;
- [ ] nombre de profils utilisés par plus de 10/50/100 espèces.

### Priorisation

Commencer par :

1. fiches basées sur une famille ;
2. plantes d’intérieur populaires ;
3. plantes toxiques ;
4. plantes carnivores ;
5. orchidées ;
6. plantes à dormance/bulbes ;
7. plantes avec exigences d’eau particulières ;
8. espèces dont les modèles IA sont fortement en désaccord.

---

# P2 — Tests de vérité botanique

## [ ] 16. Compléter les tests structurels par des tests de référence

Les tests actuels vérifient correctement :

- résolution espèce/genre/famille ;
- cohérence été/hiver ;
- humidité valide ;
- traductions ;
- dormance ;
- floraison ;
- cohérence interne eau/calcium ;
- couverture des 1 900 espèces.

Mais ils ne peuvent pas détecter qu’une valeur botaniquement fausse est syntaxiquement valide.

### Ajouter une petite suite de références incontestables

Exemples :

```text
Monstera deliciosa
Calathea / Goeppertia orbifolia
Aloe vera
Citrus × limon
Phalaenopsis amabilis
Dionaea muscipula
Tillandsia ionantha
Dracaena trifasciata
Spathiphyllum wallisii
Lavandula angustifolia
```

Pour chacune, vérifier quelques faits très stables provenant de sources reconnues.

### Actions

- [ ] Créer `test/data/care_reference_test.dart`.
- [ ] Ne tester que les données réellement bien documentées.
- [ ] Documenter dans le test la source utilisée.
- [ ] Éviter de tester des fréquences horticoles arbitraires au jour près.

---

# P2 — Affichage et UX

## [ ] 17. Afficher honnêtement la précision de chaque donnée

Au lieu d’un simple texte final du type « fiche du genre », envisager des badges discrets sur les valeurs importantes.

Exemples :

```text
Humidité
60–80 %
Basé sur le genre Anthurium
```

ou :

```text
Toxicité
Non vérifiée pour cette espèce
```

### Actions

- [ ] Ne pas surcharger l’interface principale.
- [ ] Mettre la provenance détaillée derrière une interaction secondaire.
- [ ] Mettre davantage en évidence les données de sécurité incertaines.
- [ ] Distinguer clairement valeur spécifique et estimation générale.

---

# P3 — Champs à faire évoluer à terme

## [ ] Lumière

- conserver le système actuel ;
- envisager DLI/PPFD spécifiques à certaines espèces ;
- ne pas donner une précision excessive au niveau famille.

## [ ] Arrosage

- priorité au niveau de séchage du substrat ;
- jours = estimation dynamique ;
- apprentissage à partir des arrosages réels.

## [ ] Humidité

- minimum toléré ;
- idéal minimum ;
- idéal maximum.

## [ ] Température

- plage idéale ;
- seuil de dégâts ;
- minimum de survie.

## [ ] Eau

- alcalinité ;
- dureté ;
- sodium ;
- fluor ;
- préférence eau de pluie/filtrée/osmosée si réellement nécessaire.

## [ ] Nutrition

- type d’engrais ;
- fréquence ;
- dose/concentration ;
- période ;
- calcium séparé de la qualité de l’eau.

## [ ] Substrat

- milieu de croissance ;
- aération ;
- rétention d’eau ;
- matière organique ;
- pH ;
- recette optionnelle.

## [ ] Toxicité

- chat ;
- chien ;
- humain ;
- partie toxique ;
- sévérité ;
- voie d’exposition si utile.

## [ ] Rempotage

- conserver comme estimation ;
- éventuellement préférer critères racinaires à une fréquence fixe.

## [ ] Difficulté

- envisager une valeur dérivée plutôt qu’une donnée botanique brute.

## [ ] Floraison

- conserver uniquement lorsque curatée ou sourcée ;
- ne pas générer automatiquement.

## [ ] Dormance

- conserver uniquement lorsque curatée ou sourcée ;
- donnée critique à ne pas inventer.

## [ ] Problèmes fréquents

- conserver ;
- éviter les longues listes copiées à toute une famille ;
- prioriser les problèmes réellement fréquents pour le taxon.

---

# Ordre recommandé d’implémentation

## Phase 1 — Sécuriser

- [ ] corriger les toxicités déjà identifiées ;
- [ ] empêcher l’héritage familial de la toxicité ;
- [ ] identifier les autres champs sensibles hérités ;
- [ ] générer un rapport des 1 900 fiches et de leur niveau réel de résolution.

## Phase 2 — Rendre les données éditables

- [ ] définir un schéma YAML/JSON ;
- [ ] migrer progressivement `care_profiles.dart` ;
- [ ] ajouter sources, statuts et dates de révision ;
- [ ] créer les premières validations automatiques.

## Phase 3 — Care Studio

- [ ] visualiser la chaîne d’héritage ;
- [ ] modifier une valeur ;
- [ ] créer un override espèce ;
- [ ] afficher les espèces impactées ;
- [ ] filtrer les fiches à vérifier.

## Phase 4 — Refonte scientifique du modèle

- [ ] arrosage basé sur le séchage ;
- [ ] eau et calcium séparés ;
- [ ] substrat multi-axes ;
- [ ] humidité idéal/tolérance ;
- [ ] température idéal/dégâts/survie ;
- [ ] toxicité détaillée.

## Phase 5 — Audit assisté par IA

- [ ] comparer Auxine/Qwen/Kimi/Mistral ;
- [ ] détecter les divergences ;
- [ ] valider manuellement avec sources ;
- [ ] progresser espèce par espèce.

---

# Principe directeur

L’objectif n’est pas de supprimer l’héritage : il est extrêmement utile pour couvrir 1 900 espèces sans écrire 1 900 fiches complètes dès le premier jour.

L’objectif est de rendre explicite la différence entre :

```text
JE SAIS
    donnée spécifique et vérifiée

J’HÉRITE
    bonne approximation du genre

J’ESTIME
    repère général provenant de la famille/catégorie

JE NE SAIS PAS
    information non suffisamment fiable
```

Puis de permettre, via Care Studio, de transformer progressivement les fiches héritées en vraies fiches spécifiques et sourcées, sans devoir maintenir plusieurs milliers de lignes Dart à la main.
