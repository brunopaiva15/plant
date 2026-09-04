# Flora

Application mobile premium de gestion de plantes (Flutter, iOS & Android).
Nom de travail : **Flora** — identifiant `ch.vergasta.plant`.

> Comprendre l'état de toutes ses plantes en quelques secondes, enregistrer un soin en un ou deux gestes.

## Documentation
| Fichier | Contenu |
|---|---|
| [docs/00-roadmap.md](docs/00-roadmap.md) | Découpage en phases et état d'avancement |
| [docs/01-product-architecture.md](docs/01-product-architecture.md) | A. Product architecture |
| [docs/02-information-architecture.md](docs/02-information-architecture.md) | B. Navigation et hiérarchie |
| [docs/03-user-flows.md](docs/03-user-flows.md) | C. Flows : créer, arroser, photo, emplacement, rappel |
| [docs/04-data-model.md](docs/04-data-model.md) | D. Modèle de données |
| [docs/05-technical-architecture.md](docs/05-technical-architecture.md) | E. Architecture technique, offline, notifications |
| [docs/06-design-system.md](docs/06-design-system.md) | F. Couleurs, typographie, spacing, composants |
| [docs/07-project-structure.md](docs/07-project-structure.md) | G. Arborescence du projet |

## Démarrer
```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # schéma drift (déjà commité)
flutter gen-l10n                                            # localisations (déjà commitées)
flutter run
```

## Tests
```bash
flutter test            # moteur d'entretien, rappels, repositories (SQLite en mémoire), parcours d'app
flutter analyze
```

## Stack
Flutter 3.47 · Dart 3.13 · Riverpod 3 · go_router · drift (SQLite) · flutter_local_notifications · image_picker · ARB / gen-l10n (fr, en, de, it).

Sur iOS l'app s'appuie sur les composants Cupertino natifs (grands titres, sheets, action sheets, pickers, switches, segmented controls, menus) ; sur Android sur Material 3. L'identité visuelle (tokens, cartes, tab bar flottante) est commune.
