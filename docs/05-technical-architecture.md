# E. Technical architecture

## Choix
| Couche | Choix | Pourquoi |
|---|---|---|
| UI | **Flutter 3.47 / Dart 3.13** | une base, rendu natif 120 fps, contrôle total du design |
| Navigation | `go_router` + `StatefulShellRoute` | tabs avec état, deep links, transitions Cupertino sur iOS |
| State | `flutter_riverpod` 3 (`Notifier`, `StreamProvider`) | léger, testable, pas de codegen obligatoire |
| Base locale | `drift` (SQLite) | relationnel, réactif (streams), migrations, testable en mémoire |
| Photos | `camera` + `image_picker` + `image` (isolate) | viseur intégré à l'étape photo, pickers natifs en repli, compression + miniatures hors UI thread |
| Notifications | `flutter_local_notifications` + `timezone` | planification locale fiable, actions inline |
| Prefs | `shared_preferences` | réglages simples |
| i18n | `flutter_localizations` + ARB (`gen-l10n`) | fr / en / de / it, pluriels, dates locales |
| Backend (P3) | Supabase derrière `RemoteDataSource` | Postgres + Auth + Storage + Realtime, mais remplaçable |
| Espèces | GBIF (`SpeciesService`) | gratuit, sans clé, taxonomie de référence, images d'observations avec attribution |
| Identification | cascade `CascadeIdentifier` : modèle local (à venir) puis Pl@ntNet (`PlantIdentifier`) | clé de l'utilisateur, repli coupable, voir [09](09-plant-recognition.md) |
| Diagnostic | AI Services d'Infomaniak, route compatible OpenAI (`PlantDiagnoser`) | clé de l'éditeur au build, modèle choisi au build, sans plafond |
| Complément de fiche | AI Services d'Infomaniak (`CareCompleter`) | seulement quand le catalogue n'a que des repères généraux ; nom scientifique seul, réponse gardée sur l'appareil |
| Météo | Open-Meteo (`WeatherService`) | gratuit, sans compte |

## Couches
```
presentation (features/*/presentation)  ── widgets, controllers Riverpod
        │  appelle
domain      (domain/)                    ── modèles immuables, interfaces repository, CareEngine, use-cases
        │  implémenté par
data        (data/)                      ── drift DB, DAOs, repositories, outbox, services plateforme
```
Règle : les widgets ne connaissent ni drift ni la plateforme ; ils consomment des providers exposant des modèles de domaine.

## Offline-first & synchronisation
1. Toute écriture va **d'abord** dans SQLite (UI optimiste, instantanée).
2. Chaque écriture ajoute une ligne `sync_outbox` (entité, op, payload).
3. `SyncService` (P2) draine l'outbox quand la connectivité revient, applique `updated_at` *last-write-wins* par champ, et écoute Realtime pour les autres appareils.
4. Les conflits sur photos sont impossibles (immutables) ; les actions sont *append-only*.

## Auth
`AuthRepository` (domain) ⇒ `LocalAuthRepository` (P1, compte sur appareil, aucune donnée sortante) ⇒ `SupabaseAuthRepository` (P2 : Apple, Google, e-mail). La migration local → compte réattribue `owner_id` du jardin.

## Notifications
- `ReminderPlanner` calcule chaque jour à l'heure préférée un résumé groupé : « Monstera et Pilea ont probablement besoin d'eau aujourd'hui. »
- Replanifié après chaque action / changement de routine / changement de réglages.
- Jours silencieux respectés. Permission demandée **en contexte** (après la première action), jamais au lancement.

## Photos
- Original recompressé (max 2048 px, JPEG q85) + miniature 480 px, dans `ApplicationDocuments/photos/`.
- HEIC converti par le picker natif. Chargement `Image.file` avec `cacheWidth` pour les grilles.
- **Date de prise de vue** : lue dans l'EXIF (`DateTimeOriginal`) pour les photos
  choisies dans la galerie, qui peuvent dater d'il y a deux ans ; à défaut,
  l'heure courante. C'est elle qui range la galerie par mois et ordonne le
  timelapse.
- **Coordonnées GPS effacées** à l'import : l'encodeur JPEG réécrit l'EXIF tel
  quel, et la photo part ensuite dans l'export, la synchronisation et le
  partage par lien.
- **Ménage au lancement** (`PhotoMaintenance`) : les fichiers que plus aucune
  ligne ne réclame — plante supprimée définitivement, photo effacée sur un
  autre appareil — s'en vont. Les fichiers de moins de douze heures sont
  épargnés : pendant une création, la photo existe avant sa ligne.

## Performance
- Listes en `Sliver*` / `GridView.builder` (virtualisées), `RepaintBoundary` sur les cartes.
- Requêtes drift ciblées + streams ; pas de rechargement global.
- Testé conceptuellement pour 10 / 100 / 1 000 plantes : les requêtes *Aujourd'hui* sont indexées sur `care_schedules.next_due_at`.

## Observabilité / analytics (prévus)
`Analytics` et `CrashReporter` interfaces dans `core/observability`, implémentation no-op en P1. Événements : `plant_created`, `watering_logged`, `photo_added`, `location_created`, `reminder_completed`. Jamais de notes, photos ou noms.

## Tests
- `test/domain/care_engine_test.dart` : calculs d'échéances (fixe, saisonnier, manuel, retards).
- `test/data/*_repository_test.dart` : repositories sur base en mémoire (créer plante, arroser, archiver / restaurer, recherche).
- `test/domain/reminder_planner_test.dart` : regroupement et texte des notifications.
