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
Les catégories d'inventaire sont un enum localisé (pas de table) ; les QR codes encodent `flora://plant/<id>` sans table dédiée.
Le calendrier n'est pas stocké : il est projeté à la volée (`CalendarProjector`) à partir des routines et de l'historique.

## Tables prévues (schéma réservé, UI en P3–P4)
```
tasks, notes, attachments, notifications, devices, shared_links, plant_links(nfc), plant_relationships
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

## Sécurité (Supabase, P2)
- RLS : `garden_members` détermine l'accès à tout ce qui porte `garden_id` (via `plants.garden_id` pour les tables filles).
- Storage : bucket privé `plant-photos/{garden_id}/{plant_id}/{photo_id}.jpg`, URLs signées, validation MIME + taille.
- Aucune confiance au client : triggers `updated_at`, contraintes de rôle en base.
