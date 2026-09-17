# Sourcer les fiches d'entretien

La rusticité est la seule donnée que les fiches ont confrontée à une source :
la RHS, pour 216 profils sur 310. Les quinze autres champs — lumière,
substrat, eau, humidité, arrosage, engrais, rempotage, floraison,
multiplication, problèmes — sont des estimations d'auteur.

Ce document découpe le travail qui reste. Il se lit avec le `CareProfile` et
`care_profiles.dart` sous les yeux.

Pour savoir **quels profils créer en priorité** avant la première version
publique, voir [`15-care-profile-coverage.md`](15-care-profile-coverage.md).
Cette roadmap sépare la couverture produit de la qualité des données : ici on
définit comment sourcer un champ ; là-bas, quels taxons méritent ce travail en
premier.

## Ce que la RHS donne déjà

La page d'une espèce à la RHS porte, en plus de la rusticité :

- **Position** — plein soleil, mi-ombre, ombre ;
- **Soil Types** — calcaire, argile, limon, sable ;
- **Moisture** — bien drainé, frais, humide ;
- **pH** — acide, neutre, alcalin ;
- **Pests** et **Diseases** — les ennemis nommés de la plante ;
- **Propagation** — semis, bouture, division, rejet, marcottage ;
- **Flowering** — la saison et les mois.

Six champs de la fiche, donc, lisibles d'un seul accès. Le pipeline local
(sitemap + lecture du HTML) les extrait comme il extrait la rusticité.

## Ce qu'aucune source ne donne

- **Les intervalles en jours** : « tous les 7 jours » n'est écrit nulle part.
  C'est une sortie de règle — le substrat, la lumière, le pot, la saison.
- **L'humidité de l'air** : la RHS n'en parle pas. Elle se déduit de l'habitat
  d'origine, ce qui est une inférence, pas une cote.
- **Les conseils** (`tipKeys`) : éditoriaux.

## Phase 0 — La provenance par champ (faite)

`CareProfile.sourcing` remplace `source` : une table `CareField → CareSource`.
La fiche affiche « Vérifié d'après RHS : Température » et se tait sur le
reste. Seul ce qui y est écrit est vérifié.

## Phase 1 — Lumière

Source : la position RHS. Risque élevé : une lumière fausse étiole ou brûle.
426 profils, une espèce représentative pour les 174 familles.

## Phase 2 — Substrat

Sources : Soil Types, Moisture, pH. Risque élevé — c'est le champ qui tue le
plus vite. Deux champs en sortent : `soil` et `water` (les calcifuges se
lisent au pH). Le pH mérite son propre champ, aujourd'hui fondu dans le
substrat.

## Phase 3 — Problèmes fréquents

Sources : Pests et Diseases. Risque faible, gain de crédibilité immédiat :
aujourd'hui `aphids` et `powderyMildew` sont collés à presque tout le monde.

## Phase 4 — Multiplication

Source : Propagation. Risque faible. `rootingMedium` s'en déduit.

## Phase 5 — Floraison

Source : la saison de floraison. Risque faible.

## Phase 6 — Humidité de l'air

Pas de source directe : l'habitat d'origine (forêt humide, sous-bois, maquis,
désert), via le GBIF et la littérature. Marqué `CareSource.habitat` — une
inférence documentée, jamais présentée comme une cote.

## Phase 7 — Arrosage

Sourcer la règle (`dryDown`) sur la stratégie hydrique de la plante, puis
**dériver** les jours de cette règle et de la phase 2. Les jours portent
`CareSource.derived`, explicitement.

## Phase 8 — Engrais et rempotage

Semi-dérivés : la RHS donne le rythme de croissance et la maturité, pas la
fréquence. Règle dérivée, comme la phase 7.

## Phase 9 — Les 174 profils de famille

Toutes les phases ci-dessus butent sur le même mur : une famille n'est pas un
taxon. Chaque champ familial est ancré sur une espèce représentative et porté
comme valeur de famille, jamais comme donnée d'espèce — comme la rusticité.

## Ordre

0 → 1 → 2 → 3 → 4 → 5 (les six champs de la RHS, un lot tous les six, par
paquets de 45 profils) → 6 → 7 → 8 → 9.
