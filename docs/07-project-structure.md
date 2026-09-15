# G. Structure du projet

```
lib/
├── main.dart                      bootstrap (DB, prefs, notifications, timezone)
├── app/
│   ├── app.dart                   MaterialApp.router, thèmes, locales
│   ├── router.dart                go_router, shell 4 onglets, routes plein écran
│   └── providers.dart             providers racine (db, repos, services)
├── core/
│   ├── config/app_config.dart     APP_NAME, identifiant du soutien, réglages produit
│   ├── haptics.dart
│   ├── observability/             Analytics / CrashReporter (interfaces + no-op)
│   ├── l10n/                      helpers (relative dates, pluriels)
│   ├── network/                   état du réseau (sonde, garde `ref.online`, délais)
│   └── utils/                     date helpers, extensions
├── design_system/
│   ├── tokens/                    colors, typography (Shantell Sans + système), spacing, radius, motion
│   ├── theme/                     ThemeData clair / sombre, FloraTheme extension
│   └── components/                composants réutilisables ; clay.dart = ClayBox / ClayPainter / GrainOverlay
├── domain/
│   ├── models/                    Plant, Location, PlantAction, CareSchedule, PlantPhoto, ActionType, Tag…
│   ├── repositories/              interfaces
│   ├── care/                      CareEngine, ReminderPlanner, CalendarProjector, Season
│   ├── identification/            PlantIdentifier (interface, candidats)
│   ├── diagnosis/                 PlantDiagnoser (interface, causes), DiagnosisObservations (terre, racines, lumière, insectes), DiagnosisRecord (compte rendu gardé)
│   ├── cuttings/                  CuttingStep, CuttingGuideRefinement, CuttingGuideRefiner, CuttingGuideStore
│   ├── location/                  LocationService (lieu de la météo, à l'onboarding)
│   ├── home/                      HomeClimateService (capteurs Apple Maison), HomeClimateAdvisor
│   ├── weather/                   WeatherService, WeatherAdvisor (pluie), WeatherTrend (intervalles), OutdoorAlertAdvisor (gel, chaleur), RegionClimate (zone de rusticité)
│   └── auth/                      AuthRepository, AppUser
├── data/
│   ├── db/                        drift: database.dart, tables, daos, migrations
│   ├── repositories/              implémentations drift
│   ├── services/                  PhotoStorage, NotificationService, Preferences, PlantNetIdentifier, InfomaniakDiagnoser, DeviceLocationService, OpenMeteoService, HomeKitClimateService
│   └── auth/                      LocalAuthRepository
├── features/
│   ├── onboarding/
│   ├── today/
│   ├── plants/                    list, detail, create, edit, timeline, gallery, schedule
│   ├── cuttings/                  guide de bouturage : introduction, séquences d'argile, scène, sheet ; étapes précisées par l'IA
│   ├── actions/                   add action sheet, quick actions
│   ├── locations/
│   ├── network/                   ce qui s'affiche hors ligne (état vide, bandeau)
│   ├── garden/                    onglet segmenté : emplacements · inventaire · calendrier
│   ├── inventory/
│   ├── calendar/
│   ├── qr/                        liens, étiquettes PDF, sheet QR, scanner
│   ├── identification/            sheet de résultats, réglage de la clé
│   ├── weather/                   ligne météo, conseil pluie, avertissements gel et chaleur, climat du lieu, réglages
│   ├── home_climate/              ligne et conseils du climat de la maison, carte « Chez vous », réglage du capteur
│   ├── diagnosis/                 sheet « Ma plante a un problème », compte rendu rouvrable, état du service
│   ├── encyclopedia/              les actifs embarqués à lire à froid : un écran à trois rayons (problèmes, espèces, vocabulaire), une page par problème, une par espèce
│   ├── account/                   compte, membres, rôles
│   ├── export/                    export ZIP
│   ├── archive/
│   ├── whats_new/                 catalogue des nouveautés, règle d'ouverture, fenêtre native
│   └── profile/                   settings, appearance, notifications, action types, about
└── l10n/
    ├── app_fr.arb (template) · app_en.arb · app_de.arb · app_it.arb
test/
├── domain/care_engine_test.dart
├── domain/reminder_planner_test.dart
├── data/plant_repository_test.dart
├── data/infomaniak_cutting_refiner_test.dart   ce qui part à l'IA, ce qu'on garde de la réponse
├── features/cutting_guide_test.dart            le guide : six étapes, trois sorties, texte précisé
├── features/encyclopedia_test.dart             les trois rayons, sur la vraie base des 200 problèmes
├── core/connectivity_test.dart                 état du réseau, garde des appels
├── core/reachability_test.dart                 la sonde, sur de vraies connexions
├── features/shared_links_offline_test.dart     hors ligne, l'écran le dit au lieu de tourner
├── assets/cutting_sequences_test.dart          les six séquences sont là et s'animent
└── l10n/arb_tone_test.dart       ton des textes, sur les quatre ARB
docs/                              cette documentation
```

## Conventions
- Un fichier = un widget public majeur ; < 300 lignes par fichier.
- Controllers Riverpod suffixés `Controller`, providers `xxxProvider`.
- Aucune chaîne UI hors ARB. Aucune couleur hors tokens.
- Les textes suivent docs/06, « Les textes » ; `test/l10n/arb_tone_test.dart` le vérifie.
- Feature = dossier avec `presentation/` (+ `application/` pour controllers si besoin).
