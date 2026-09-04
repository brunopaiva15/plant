# Synchronisation & collaboration (Phase 3)

## Principes
- **Local d'abord** : chaque écriture va dans SQLite et marque la ligne « à synchroniser » (`sync_outbox`). L'UI est instantanée.
- **Backend abstrait** : `RemoteDataSource` (domaine) est implémenté par `SupabaseRemoteDataSource`. Rien d'autre ne connaît Supabase.
- **Sans compte, rien ne change** : si `SUPABASE_URL` / `SUPABASE_ANON_KEY` ne sont pas fournis (`--dart-define`), l'app reste 100 % locale.
- **Le serveur fait foi** : `updated_at` est posé par un trigger ; RLS sur toutes les tables via `garden_members` (`supabase/schema.sql`).

## Cycle
```
écriture locale ─→ sync_outbox(entity, id)
                       │
   SyncService.push ───┘  lit la ligne locale, la pousse (upsert / delete), téléverse les photos
   SyncService.pull       delta par table (updated_at > curseur), applique en last-write-wins
   Realtime               changement distant sur le jardin → pull (débounce 1 s)
   Déclencheurs           démarrage, retour au premier plan, après chaque écriture (débounce 3 s)
```

## Résolution de conflits
| Table | Stratégie |
|---|---|
| plants, locations, care_schedules, inventory_items, gardens | last-write-wins sur `updated_at` (champ à champ non nécessaire : les écritures sont atomiques par ligne) |
| plant_actions, plant_photos, measurements, tags, plant_tags | append-only : `insert or ignore`, suppression logique par `deleted_at` |
| photos (fichiers) | immuables, nommées par UUID : jamais de conflit |

## Auth
`AuthRepository` : `LocalAuthRepository` (Phase 1) → `SupabaseAuthRepository` (e-mail + code à 6 chiffres, Apple natif sur iOS, Google via OAuth). À la première connexion, le jardin local est réattribué au compte (`owner_id`) et toutes les lignes sont mises en file de synchronisation.

## Collaboration
- `garden_members` : owner / member / viewer. Invitation par e-mail via la fonction `invite_member(garden_id, email, role)` (security definer).
- Chaque action et photo porte `user_id` ; la timeline affiche « · Laura » quand l'auteur n'est pas l'utilisateur courant (cache local `profiles`).
- Un `viewer` voit tout et ne peut rien écrire (RLS) ; l'UI masque les actions d'écriture pour ce rôle.

## Mise en place
1. Créer un projet Supabase, exécuter `supabase/schema.sql` dans l'éditeur SQL.
2. Activer les fournisseurs Auth souhaités (Email OTP, Apple, Google) ; ajouter l'URL de redirection `flora://login-callback`.
3. Lancer l'app avec `flutter run --dart-define=SUPABASE_URL=… --dart-define=SUPABASE_ANON_KEY=…`.
