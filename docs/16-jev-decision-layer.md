# Jev comme couche de décision autour d’Iris

> Statut : piste d’architecture à expérimenter, pas une dépendance décidée.
> Note créée le 18 septembre 2026.

## Idée

Jev pourrait s’appliquer à Auxine non pas comme modèle de reconnaissance végétale, mais comme **couche de décision après Iris**.

L’objectif serait de garder Iris comme source principale de compréhension visuelle, puis d’utiliser Jev seulement lorsque plusieurs signaux doivent être combinés pour décider quoi faire dans l’application.

```text
Photo
  ↓
Iris
  ↓
Top-k espèces + scores + informations extraites
  ↓
Contexte Auxine
  ├─ intérieur / extérieur
  ├─ pays ou région
  ├─ saison
  ├─ taille approximative
  ├─ observations morphologiques
  └─ historique éventuel de la plante
  ↓
Jev
  ├─ résultat suffisamment fiable ?
  ├─ faut-il demander une autre photo ?
  ├─ quelle photo demander ?
  ├─ faut-il lancer un diagnostic ?
  └─ quel candidat est le plus cohérent ?
  ↓
Décision de l’application
```

## Cas d’usage principal : les scans ambigus

Exemple de sortie Iris :

```text
Monstera adansonii          44 %
Monstera deliciosa          39 %
Rhaphidophora tetrasperma   12 %
Epipremnum pinnatum          5 %
```

Le problème n’est pas seulement que le top-1 vaut 44 %. L’écart entre les deux premiers est faible et plusieurs informations disponibles dans Auxine peuvent aider à décider si le résultat doit être accepté.

On pourrait transmettre à Jev un état structuré du type :

```json
{
  "iris_candidates": [
    ["Monstera adansonii", 0.44],
    ["Monstera deliciosa", 0.39],
    ["Rhaphidophora tetrasperma", 0.12],
    ["Epipremnum pinnatum", 0.05]
  ],
  "environment": "indoor",
  "leaf_length_cm": 28,
  "fenestrations": true,
  "mature_plant": true
}
```

Puis demander plusieurs décisions structurées :

```text
species:
Choice [
  Monstera adansonii,
  Monstera deliciosa,
  Rhaphidophora tetrasperma,
  Epipremnum pinnatum
]

identification_reliable:
Yes / No

need_another_photo:
Yes / No

best_next_photo:
Choice [
  leaf_closeup,
  whole_plant,
  stem,
  underside,
  none
]
```

Auxine pourrait alors, par exemple, demander une photo de la plante entière plutôt que d’afficher immédiatement une identification trop incertaine.

## Jev ne doit pas remplacer Iris

Jev ne dispose pas de davantage d’information visuelle qu’Iris si on lui transmet seulement :

```text
A : 44 %
B : 39 %
```

Dans ce cas, il risque surtout de reformuler l’incertitude existante.

Il devient intéressant lorsqu’on lui fournit **des informations supplémentaires réellement discriminantes**, par exemple :

- taille ou forme des feuilles ;
- fenestrations ;
- port de la plante ;
- longueur des entre-nœuds ;
- environnement intérieur / extérieur ;
- région ou saison ;
- observations utilisateur ;
- historique d’identifications du même spécimen.

Le schéma à privilégier serait donc :

```text
catalogue complet
      ↓
     Iris
      ↓
top 5 / top 10
      ↓
règles botaniques Auxine
      ↓
Jev si le cas reste ambigu
```

Jev ne doit pas avoir pour rôle de choisir directement parmi l’ensemble du catalogue Auxine.

## Conserver les règles déterministes

Les règles botaniques certaines doivent rester du code classique.

Exemple : si une contrainte connue permet d’écarter un candidat de manière fiable, il vaut mieux appliquer cette règle explicitement plutôt que demander à un modèle de la redécouvrir.

Architecture envisagée :

```text
Iris
  ↓
connaissances structurées Auxine
  ↓
re-ranking / règles déterministes
  ↓
Jev uniquement pour la décision résiduelle
```

Cela permet de garder le comportement :

- reproductible ;
- testable ;
- rapide ;
- explicable ;
- utilisable hors ligne autant que possible.

## Jev comme « contrôleur Iris »

Le cas d’usage potentiellement le plus intéressant est de remplacer une partie des seuils rigides par une décision prenant en compte plusieurs signaux.

Aujourd’hui une logique peut ressembler à :

```text
si confiance > 90 %
    afficher le résultat
sinon si confiance > 60 %
    afficher "identification probable"
sinon
    demander une autre photo
```

Cette logique ignore par exemple :

- la marge entre top-1 et top-2 ;
- la qualité de la photo ;
- la partie de la plante visible ;
- la cohérence avec une photo précédente ;
- le fait que les deux meilleurs candidats appartiennent ou non au même genre ;
- les informations déjà connues dans le Jardin.

Jev pourrait alors produire plusieurs décisions :

```text
identification_reliable = faible
need_another_photo       = forte
best_next_photo          = whole_plant
```

L’intérêt n’est donc pas seulement de choisir une espèce, mais de choisir **la prochaine action d’Auxine**.

## Offline

Iris doit continuer à fonctionner localement.

Jev ne devrait jamais devenir nécessaire pour obtenir une identification de base.

```text
                    ┌─ en ligne ─→ Jev ─→ décision avancée
Iris → état local ──┤
                    └─ hors ligne → règles Auxine
```

Une intégration éventuelle doit donc être conçue comme un enrichissement facultatif.

## Stratégie d’appel

Jev ne serait idéalement pas appelé pour tous les scans.

Exemple :

1. Iris produit son top-k.
2. Les règles Auxine vérifient si le résultat est suffisamment net.
3. Si le cas est clair, Auxine continue localement.
4. Si le cas est ambigu et qu’une connexion est disponible, Jev reçoit l’état structuré.
5. Jev aide à choisir entre résultat, seconde photo ou analyse complémentaire.

Cela pourrait limiter l’usage de Jev à une minorité des scans.

## Benchmark à faire avant toute intégration

Tester sur un ensemble de scans dont l’espèce réelle est connue, en particulier les cas où Iris hésite.

Comparer :

| Variante | Description |
|---|---|
| A | Top-1 Iris |
| B | Iris + règles botaniques |
| C | Iris + Jev |
| D | Iris + règles botaniques + Jev |

Mesures :

- top-1 accuracy ;
- top-3 accuracy ;
- taux de faux résultats affichés comme certains ;
- taux de demandes d’une seconde photo ;
- accuracy après seconde photo ;
- latence ;
- coût par scan ;
- taux de disponibilité hors ligne / en ligne.

Le critère principal ne doit pas être seulement « Jev change-t-il le top-1 ? », mais surtout :

> **Est-ce que Jev réduit les mauvaises décisions produit autour d’une identification incertaine ?**

## Décision actuelle

Ne pas intégrer Jev dans le cœur d’Iris pour le moment.

À conserver comme piste pour une future couche de décision, probablement autour d’Iris 10 Core ou d’une génération ultérieure, après benchmark sur les scans ambigus.

La direction à tester est :

```text
Iris → règles Auxine → Jev si nécessaire → action de l’application
```

et non :

```text
Photo → Jev → espèce
```

## Points à revalider avant implémentation

Jev est encore une technologie récente. Avant de coder une intégration, revalider notamment :

- API et disponibilité ;
- formats de décisions typées ;
- limites de cardinalité des choix ;
- latence réelle depuis les régions utilisées par Auxine ;
- coût ;
- politique de confidentialité ;
- possibilité éventuelle d’exécution locale à l’avenir.

Référence initiale : https://typesafe.ai/blog/introducing-system-one-models-and-jev


## Banc d’essai dans l’application

Un test manuel est disponible uniquement en build Flutter debug :

```text
Profil
  ↓
DEBUG
  ↓
Tester Jev
```

La clé OpenRouter est lue depuis le build :

```bash
flutter run --dart-define=OPENROUTER_API_KEY=…
```

Le bouton envoie à `https://openrouter.ai/api/alpha/decisions` un état de test représentant un scan Iris ambigu :

```text
Monstera adansonii        45 %
Monstera deliciosa        41 %
Rhaphidophora tetrasperma 14 %
```

avec quelques observations supplémentaires. Il pose en une seule requête :

- une question `noul` sur la fiabilité de l’identification ;
- une question `choice` sur l’espèce la plus cohérente ;
- une question `choice` sur la prochaine action d’Auxine ;
- une question `score` sur la force globale des indices.

La sheet affiche ensuite le JSON brut d’OpenRouter, probabilités comprises. Ce banc d’essai ne touche pas au flux d’identification réel et n’existe pas en release.

Implémentation :

- `lib/core/config/jev_config.dart`
- `lib/data/services/jev_decision_service.dart`
- `lib/features/profile/presentation/jev_debug_sheet.dart`
