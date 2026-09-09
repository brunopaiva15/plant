# D. Data model

Le schéma est conçu pour Postgres (Supabase) et **répliqué localement** dans SQLite (drift). Les IDs sont des UUID v4 générés côté client pour permettre l'offline-first. Toutes les tables ont `created_at`, `updated_at` ; les entités utilisateur ont `deleted_at` (suppression logique).

## Tables Phase 1 (implémentées localement)
```
users            id, email, display_name, locale, created_at
gardens          id, owner_id, name, created_at, updated_at, deleted_at
garden_members   garden_id, user_id, role(owner|member|viewer), created_at        [P3]
locations        id, garden_id, parent_id?, name, icon, photo_id?, light?, orientation?, sort_order, created_at, updated_at, deleted_at
species          id, scientific_name, common_name?, care_defaults(json), source?, created_at
plants           id, garden_id, name, species_id?, species_name?, location_id?, primary_photo_id?,
                 status(active|archived), health(healthy|watch|sick), is_favorite,
                 acquired_at?, source?, price?, pot_size?, notes?, parent_plant_id?,
                 archived_at?, archive_reason?, created_at, updated_at, deleted_at
plant_photos     id, plant_id, user_id?, file_path, thumb_path, width, height, taken_at, created_at, deleted_at
action_types     id, garden_id?, key(watering|fertilizing|…|custom), label?, emoji, is_builtin, sort_order
plant_actions    id, plant_id, user_id?, type_key, occurred_at, notes?, metadata(json), photo_id?, created_at, deleted_at
care_schedules   id, plant_id, type_key, strategy(fixed|seasonal|manual), interval_days, seasonal_rules(json)?,
                 next_due_at?, last_completed_at?, enabled, created_at, updated_at
tags             id, garden_id, name, color?, created_at
plant_tags       plant_id, tag_id
measurements     id, plant_id, action_id?, kind(height|width|leaves|pot), value, unit, measured_at
sync_outbox      id, entity, entity_id, op(upsert|delete), payload(json), created_at, attempts
```

## Tables Phase 2 (schéma v2)
```
inventory_items  id, garden_id, category_key(fertilizer|soil|substrate|pot|tool|treatment|seed|accessory),
                 name, quantity, unit, low_threshold?, location_id?, notes?, photo_path?, thumb_path?,
                 created_at, updated_at, deleted_at
```
Les catégories intégrées de l'inventaire sont un enum localisé ; les groupes personnalisés vivent dans `inventory_groups` (schéma v9).
Les QR codes encodent `flora://plant/<id>` et `flora://item/<id>`, sans table dédiée.

## Phase 3 (schémas v3–v4)
```
locations.is_outdoor           météo (balcon, jardin, serre)
plant_actions.user_id          auteur (compte) ; plant_photos.user_id idem
profiles (cache)               id, display_name, email — membres du jardin
garden_members (cache)         garden_id, user_id, role
```
Le schéma Postgres complet avec RLS, triggers et fonctions (`invite_member`, `garden_members_with_names`) est dans `supabase/schema.sql`.

## Parité HortusFox (schémas v5–v10)
```
tasks             id, garden_id, plant_id?, title, description?, due_at?, all_day,
                  recurrence_value?, recurrence_unit?, done, done_at?, …
plant_attributes  id, garden_id, plant_id, label, datatype(bool|int|double|string|datetime), value?, position
attribute_schemas id, garden_id, label, datatype, position, active   — modèles réutilisables
plant_attachments id, garden_id, plant_id, label, file_path, mime?, size?, user_id?
location_logs     id, garden_id, location_id, user_id?, content      — journal d'un emplacement
inventory_groups  id, garden_id, label, emoji, position              — v9
inventory_tags    item_id, tag_id                                    — v9, réutilise `tags`
event_categories  id, garden_id, label, emoji, color_key?, position  — v10
calendar_entries  id, garden_id, plant_id?, category_id?, title, notes?,
                  start_at, end_at?, all_day, reminder_minutes?      — v10
```
Colonnes ajoutées au passage : `plants.number` et `gardens.plant_counter` (numéros `#42` jamais réattribués, v8),
`locations.notes/photo_path/thumb_path` (v8), `plant_photos.label/remote_url` (v7), `inventory_items.group_id` (v9).

Le calendrier mêle deux sources : les événements stockés dans `calendar_entries` et les échéances de soin
projetées à la volée par `CalendarProjector` à partir des routines et de l'historique.

## Tables prévues (schéma réservé, UI en P4)
```
notifications, devices, plant_links(nfc), plant_relationships
```

## Relations
```
gardens 1─n locations (self-ref parent_id)
gardens 1─n plants n─1 locations
plants  1─n plant_photos, plant_actions, care_schedules, plant_measurements
plants  n─n tags (plant_tags)
plants  self-ref parent_plant_id (boutures)
species 1─n plants
```

## Règles métier
- Une **action** de type `t` marque la routine `t` de la plante comme complétée à `occurred_at` et recalcule `next_due_at` (voir `CareEngine`).
- Archiver une plante désactive ses routines (pas de rappel), sans supprimer l'historique.
- `primary_photo_id` = première photo si nul ; l'utilisateur peut en choisir une autre.
- Les types d'action personnalisés sont des lignes `action_types` avec `is_builtin = false`.

## `plant_actions.metadata`
Champ libre en JSON, à côté de `notes`. Trois usages aujourd'hui :

| Clé | Écrite par | Contenu |
|---|---|---|
| `kind` `value` `unit` `quantity` | mesures et soins chiffrés | ce que la ligne du journal affiche en second |
| `_prev_next_due` `_prev_last_completed` | `DriftActionRepository.log` | l'échéance d'avant, pour l'Undo |
| `diagnosis` | « Ma plante a un problème » | le compte rendu entier de l'analyse |

Le diagnostic est enregistré comme une note : `notes` en garde le résumé et
les trois premières pistes, lisibles telles quelles à l'export. `metadata.diagnosis`
garde tout le reste — c'est ce qui permet de **rouvrir** l'analyse depuis le
journal des mois plus tard au lieu d'en relire l'aperçu
(`DiagnosisRecord`, `lib/domain/diagnosis/diagnosis_record.dart`) :

```json
{"version": 1, "summary": "…", "urgent": true,
 "symptoms": "ce que l'utilisateur avait décrit",
 "causes": [{"title": "…", "problemId": "002", "likelihood": "likely",
             "explanation": "…", "actions": ["…"]}],
 "photos": [{"file": "…jpg", "thumb": "…_thumb.jpg"}]}
```

Les `problemId` sont conservés plutôt que les seuls noms : à la réouverture,
les pistes sont renommées par la base des problèmes, dans la langue de
l'application du moment. La relecture est tolérante — une analyse gardée avant
un changement de format se lit pour ce qu'il en reste plutôt que de disparaître.

Les fichiers cités par `photos` restent sur l'appareil qui a fait l'analyse :
seules les photos de `plant_photos` partent en synchronisation et en
sauvegarde, et une photo de feuille malade n'a rien à faire dans le suivi de
croissance. Ailleurs, le compte rendu se lit sans elles.

## Sécurité (Supabase, P2)
- RLS : `garden_members` détermine l'accès à tout ce qui porte `garden_id` (via `plants.garden_id` pour les tables filles).
- Storage : bucket privé `plant-photos/{garden_id}/{plant_id}/{photo_id}.jpg`, URLs signées, validation MIME + taille.
- Aucune confiance au client : triggers `updated_at`, contraintes de rôle en base.

## Catalogue d'espèces (hors base locale)
Deux étages, plus la recherche en ligne :

| Étage | Où | Volume | Rôle |
|---|---|---|---|
| Trié à la main | `lib/data/species/species_catalog.dart` | ~300 espèces avec catégorie | Parcours par thème, fiches d'entretien précises |
| Étendu | `assets/species/catalog.tsv` | ~40 000 espèces | Recherche hors ligne, quatre langues |
| En ligne | API GBIF | ~450 000 espèces | Le reste, paginé |

L'actif étendu est un TSV chargé à la demande dans un isolat, jamais au
démarrage : `nom · famille · fr · en · de · it · autres noms`. Les « autres
noms » ne s'affichent pas, ils rendent la recherche tolérante (« Edelweiß »,
« stella alpina »). La recherche compare des chaînes normalisées sans accents
ni casse (`core/utils/search_text.dart`).

Provenance et régénération : `tool/README.md`. Wikidata (CC0) pour les noms,
GBIF (CC BY) pour les familles.

## Base des problèmes (hors base locale)
`assets/problems/catalog.txt` : 200 troubles, ravageurs et maladies couvrant
l'intérieur, les fleurs, les arbustes, le potager et les fruitiers. Un fichier
à séparateurs `|`, écrit à la main, chargé à la demande dans un isolat
(`ProblemCatalogLoader`) et lu par `ProblemCatalog`.

| Champ | Contenu |
|---|---|
| `id` | Trois chiffres, `001` à `200`. C'est lui qui circule. |
| `type` | `ABIOTIQUE` (trouble), `RAVAGEUR`, `MALADIE`, `AFFECTION` |
| `nom_fr` `nom_en` `nom_it` `nom_de` | Le nom affiché, une colonne par langue de l'app |
| `portee` | `GENERAL` (toutes les plantes vasculaires), `LARGE` (beaucoup d'hôtes, exemples), `CIBLE` (hôtes principaux) |
| `taxons_hotes_scientifiques` | Hôtes séparés par `;`, à tous les rangs : espèce, genre, famille, ou `Tracheophyta` |

Elle sert de vocabulaire commun au diagnostic. `candidatesFor` réduit la base
aux pistes qui peuvent concerner une plante — l'universel, plus ce qui vise son
espèce, son genre ou sa famille, plus ce que sa fiche d'entretien signale —,
soit trente à soixante-cinq entrées. Cette liste part avec la demande ; le
service rend un numéro, l'application n'accepte que ceux qu'elle a soumis et
affiche son propre nom. Deux analyses de la même chose se lisent donc pareil,
dans la langue de l'utilisateur.

La fiche de soin s'en sert à froid : `specificTo` garde les entrées qui
nomment l'espèce, son genre ou sa famille, retire les troubles universels et
ce que « À surveiller » dit déjà, et affiche le reste replié au-delà de six
lignes. Sur les 297 espèces du catalogue trié à la main, la médiane est d'une
entrée et la moitié n'en a aucune — la section disparaît alors, plutôt que de
meubler.

Chaque entrée peut avoir sa propre illustration, dans
`assets/problems/icons/<id>.webp`. Elles arrivent par lots et la base en
compte deux cents : celles qui n'en ont pas encore retombent sur le symbole de
leur famille, ce qui est l'état normal de la plupart des entrées et non un cas
d'erreur. `illustrated_problems.dart`, écrit par le même outil que les images,
dit lesquelles existent sans interroger le disque.

Elles ne servent qu'aux cartes de diagnostic, à cinquante-deux points. En
dessous de quarante elles se valent toutes — une plante en pot reste une
plante en pot —, d'où les lignes sans vignette et le regroupement par famille
sur la fiche de soin.

Les lignes `#` en tête du fichier portent ses réserves : les hôtes sont des
exemples, un genre ne rend pas toutes ses espèces sensibles, et la
vérification GBIF porte sur les noms de plantes, pas sur les relations
hôte-problème.
