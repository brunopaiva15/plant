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

> **Ce que l’application fait depuis, et qui répond à cette remarque.** Les
> candidates qu’Iris ne tranche pas partent maintenant, avec la photo, à un
> modèle qui voit les images (§ 3.9 de [docs/09](09-plant-recognition.md)) :
> question fermée sur les cinq noms, un numéro en retour, et le caractère
> visible qui a décidé. C’est le regard sur la photo que Jev n’a pas, et c’est
> lui qui produit les informations discriminantes énumérées ci-dessous au lieu
> de les attendre de la personne. Les deux couches ne se remplacent pas :
> l’une dit *quelle candidate*, l’autre *quoi faire du résultat*.

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

Le benchmark a montré qu’il vaut mieux éviter plusieurs décisions produit indépendantes : un premier essai pouvait juger une identification très fiable tout en demandant malgré tout une seconde photo.

La règle de test devient donc une **décision produit unique** :

```text
decision:
Choice [
  show_result,
  ask_another_photo,
  keep_uncertain
]
```

Les autres sorties restent explicatives :

```text
species     → candidat indicatif ou uncertain
confidence  → force des indices
```

`decision` est la seule sortie qui pourrait, après validation du benchmark, piloter le flux d’Auxine. `species` et `confidence` servent à comprendre et mesurer la décision, pas à la contredire.

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

## Validation continue

Jev est maintenant intégré au pipeline produit. Le benchmark reste utile, mais il sert à mesurer et ajuster une intégration réelle plutôt qu'un banc d'essai séparé.

À suivre sur un ensemble de scans dont l'espèce réelle est connue :

- taux de faux résultats présentés comme exploitables ;
- taux de demandes d'une seconde photo ;
- qualité après fusion de deux photos ;
- fréquence de `keep_uncertain` ;
- qualité des recherches en ligne déclenchées après incertitude ;
- latence et coût des appels Jev ;
- comportement hors ligne et en cas de timeout.

Le critère principal reste :

> **Est-ce que Jev réduit les mauvaises décisions produit autour d'une identification incertaine ?**

### Ce que l'appareil compte

`IdentificationMetrics` tient les totaux de la cascade ; les arbitrages Jev
y ont leurs propres compteurs, de la même nature : des nombres, sans espèce,
sans photo, sans horodatage individuel, et qui ne quittent pas l'appareil.

| Compteur | Ce qu'il dit |
|---|---|
| `jevConsulted` | arbitrages réellement partis sur le réseau |
| `jevIncidents` | appels partis sans rien rendre |
| `jevLatencyMsSum` | somme des durées, pour la moyenne |
| `jevShowResult`, `jevAskAnotherPhoto`, `jevKeepUncertain` | répartition des décisions |
| `jevShowResultThenSearched` | résultats montrés que la personne est allée vérifier en ligne |
| `jevKeepUncertainThenPicked` | incertitudes qu'elle a tranchées elle-même |

Les deux derniers sont les seuls qui répondent au critère principal, parce
qu'ils enregistrent un désaccord entre la décision et le geste qui a suivi :

- un fort `jevShowResultDoubtRate` signale des résultats présentés comme
  exploitables sans l'être ;
- un fort `jevKeepUncertainOverrideRate` signale une prudence qui coûte un
  geste pour rien.

Les autres décrivent l'activité, pas sa qualité. Un même écran laissant
retoucher son choix, la suite d'une décision n'est comptée qu'une fois.

Ces totaux se lisent sur l'écran caché **État des services**, sous les
services eux-mêmes.

## Pipeline actuel

Le chemin de production est :

```text
1 photo
  ↓
Iris
  ├─ résultat net ───────────────→ candidats locaux, aucun appel Jev
  └─ résultat ambigu
          ↓
         Jev
          ├─ show_result         → candidats utilisables normalement
          ├─ keep_uncertain      → état « identification incertaine »
          └─ ask_another_photo   → proposer une seconde photo
                                      ↓
                               fusion Iris des 2 photos
                                      ↓
                               Iris net → candidats locaux
                               Iris ambigu
                                      ↓
                                  Jev final
                                  ├─ show_result
                                  └─ keep_uncertain
```

Après deux photos, `ask_another_photo` est retiré du schéma envoyé à Jev. Une garde supplémentaire transforme malgré tout une réponse fournisseur incohérente en `keep_uncertain`.

## Effet produit de `keep_uncertain`

`keep_uncertain` est un vrai état d'interface, pas seulement une information de diagnostic.

Auxine :

- affiche clairement que l'identification reste incertaine ;
- ne présente aucune espèce comme conclusion recommandée ;
- garde un éventuel genre fiable comme réponse plus prudente ;
- met la recherche en ligne en recours principal quand elle est disponible ;
- conserve les candidates Iris sous « suggestions à vérifier » pour une sélection manuelle ;
- permet de poursuivre sans espèce dans le flux de création.

`show_result` conserve le flux normal : les candidates restent utilisables et l'utilisateur garde le dernier mot.

## Garde-fous

- Iris reste le seul classifieur d'espèce ;
- Jev ne reçoit jamais la photo, seulement le Top-5, les scores et le nombre de vues ;
- un résultat déjà accepté par Iris ne déclenche aucun appel Jev ;
- sans clé ou sans réseau, aucun appel n'est tenté : la réponse locale part
  aussitôt, et le retour du réseau rouvre la question ;
- Jev ne sélectionne jamais automatiquement une espèce ;
- le choix utilisateur reste obligatoire ;
- une décision Jev est mise en cache afin qu'un rebuild Flutter ne refasse pas
  le même appel ;
- un incident, lui, n'est pas mémorisé : il ouvre une fenêtre de vingt
  secondes pendant laquelle Auxine s'en tient à la politique locale sans
  rappeler OpenRouter, puis la question se repose ;
- l'appel a un budget unique de trois secondes, porté par la requête ;
- pendant ce délai, l'interface affiche déjà ce qu'Iris seule conclut ;
- en cas d'erreur, timeout ou réponse invalide, Auxine retombe sur la politique locale Iris ;
- aucune troisième photo n'est possible.

## Interface de développement

Les interfaces de debug Jev ont été retirées du produit :

- plus de carte Jev dans le flux d'identification ;
- plus de bouton « Tester Jev » dans Profil ;
- plus de JSON brut affiché dans l'application.

La logique Jev reste couverte par les tests du service de décision, et ses
totaux se lisent sur l'écran caché décrit plus bas.

## Sécurité de la clé

`OPENROUTER_API_KEY` fournie via `--dart-define` est embarquée dans le binaire et ne doit pas être considérée comme un secret pour une distribution publique.

Avant une diffusion large, l'appel OpenRouter doit passer par un backend contrôlé par Auxine avec authentification, quotas, rate limiting et possibilité de révoquer la clé sans republier l'application.


## Pannes Jev et diagnostic caché

Une panne Jev ne doit jamais devenir un message d'erreur produit.

Le comportement est volontairement transparent :

- après une photo ambiguë, erreur, timeout, clé absente, appareil hors ligne ou réponse invalide → la politique Iris locale reprend la main et peut proposer la seconde photo ;
- après deux photos encore ambiguës, le même incident → Auxine garde l'identification incertaine ;
- aucune erreur OpenRouter n'est affichée dans le flux d'identification ;
- aucune troisième photo n'est possible.

Pour diagnostiquer les services sans exposer de panneau technique dans l'interface normale, un écran caché est accessible depuis **Profil** en touchant **5 fois la version** en moins de quatre secondes.

L'écran **État des services** vérifie uniquement la joignabilité HTTPS de :

- Supabase ;
- le service de partage public ;
- OpenRouter / Jev ;
- Pl@ntNet ;
- Infomaniak AI ;
- Open-Meteo prévisions, géocodage et archives ;
- GBIF ;
- Wikimedia Commons.

Les probes utilisent uniquement des requêtes `HEAD` de cinq secondes maximum. Elles n'envoient aucune photo, aucune donnée plante, aucune donnée personnelle et ne déclenchent aucun appel IA payant. Un statut « Joignable » indique que le serveur répond ; il ne valide pas nécessairement les identifiants ou le fonctionnement métier complet de l'API.
