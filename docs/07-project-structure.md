# G. Structure du projet

```
lib/
├── main.dart                      bootstrap (DB, prefs, notifications, timezone)
├── app/
│   ├── app.dart                   MaterialApp.router, thèmes, locales
│   ├── router.dart                go_router, shell 4 onglets, routes plein écran
│   └── providers.dart             providers racine (db, repos, services)
├── core/
│   ├── config/app_config.dart     APP_NAME, limites freemium, flags
│   ├── haptics.dart
│   ├── observability/             Analytics / CrashReporter (interfaces + no-op)
│   ├── l10n/                      helpers (relative dates, pluriels)
│   └── utils/                     date helpers, extensions
├── design_system/
│   ├── tokens/                    colors, typography, spacing, radius, motion, shadows
│   ├── theme/                     ThemeData clair / sombre, FloraTheme extension
│   └── components/                composants réutilisables
├── domain/
│   ├── models/                    Plant, Location, PlantAction, CareSchedule, PlantPhoto, ActionType, Tag…
│   ├── repositories/              interfaces
│   ├── care/                      CareEngine, ReminderPlanner, CalendarProjector, Season
│   ├── identification/            PlantIdentifier (interface, candidats)
│   └── auth/                      AuthRepository, AppUser
├── data/
│   ├── db/                        drift: database.dart, tables, daos, migrations
│   ├── repositories/              implémentations drift
│   ├── services/                  PhotoStorage, NotificationService, Preferences, PlantNetIdentifier
│   └── auth/                      LocalAuthRepository
├── features/
│   ├── onboarding/
│   ├── today/
│   ├── plants/                    list, detail, create, edit, timeline, gallery, schedule
│   ├── actions/                   add action sheet, quick actions
│   ├── locations/
│   ├── garden/                    onglet segmenté : emplacements · inventaire · calendrier
│   ├── inventory/
│   ├── calendar/
│   ├── qr/                        liens, étiquettes PDF, sheet QR, scanner
│   ├── identification/            sheet de résultats, réglage de la clé
│   ├── weather/                   ligne météo, conseil pluie, réglage du lieu
│   ├── account/                   compte, membres, rôles
│   ├── export/                    export ZIP
│   ├── archive/
│   └── profile/                   settings, appearance, notifications, action types, about
└── l10n/
    ├── app_fr.arb (template) · app_en.arb · app_de.arb · app_it.arb
test/
├── domain/care_engine_test.dart
├── domain/reminder_planner_test.dart
└── data/plant_repository_test.dart
docs/                              cette documentation
```

## Conventions
- Un fichier = un widget public majeur ; < 300 lignes par fichier.
- Controllers Riverpod suffixés `Controller`, providers `xxxProvider`.
- Aucune chaîne UI hors ARB. Aucune couleur hors tokens.
- Feature = dossier avec `presentation/` (+ `application/` pour controllers si besoin).
