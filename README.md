# Auxine

Application mobile premium de gestion de plantes (Flutter, iOS & Android).
Identifiant `ch.vergasta.plant`. Le code garde son nom de travail, « Flora » :
seul `AppConfig.appName` porte le nom vu par l'utilisateur.

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
| [docs/08-sync-and-collaboration.md](docs/08-sync-and-collaboration.md) | Synchronisation, comptes, collaboration (Supabase) |
| [docs/09-plant-recognition.md](docs/09-plant-recognition.md) | Reconnaissance de plantes : Iris, le modèle embarqué, jeu de données, repli Pl@ntNet |
| [docs/10-entrainer-sur-son-poste.md](docs/10-entrainer-sur-son-poste.md) | Entraîner le modèle chez soi, de Windows nu au `.tflite` livré |
| [docs/11-entrainer-sur-une-vm.md](docs/11-entrainer-sur-une-vm.md) | Entraîner sur une VM Debian louée : pilote, disques, ce qui change d'une machine personnelle |

## Démarrer
```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # schéma drift (déjà commité)
flutter gen-l10n                                            # localisations (déjà commitées)
flutter run
```

## Backend (optionnel)
Sans configuration, l'app est 100 % locale. Pour la synchronisation et les comptes :
```bash
flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co --dart-define=SUPABASE_ANON_KEY=...
```
Schéma et politiques RLS : `supabase/schema.sql`. Connexion par Apple, sur
iPhone et iPad, et par rien d'autre : pas d'e-mail, et Google attend son tour
(`AppConfig.googleSignInEnabled`) — sur Android le compte reste local. Sign in with Apple demande la capability sur
l'App ID et le bundle dans les *Authorized Client IDs* de Supabase. Détails : docs/08.

## Gratuite, avec un soutien facultatif
Toutes les fonctions sont ouvertes, sans limite ni publicité. Un achat unique
permet seulement de remercier le développeur — il ne déverrouille rien.

Pour qu'il apparaisse, créer un produit **non consommable** d'identifiant
`ch.vergasta.plant.support` (5 CHF) dans App Store Connect et dans la Google
Play Console. Tant qu'il n'existe pas, l'écran de soutien affiche « l'achat
n'est pas disponible » plutôt qu'un bouton mort ; le reste de l'app est
inchangé. L'identifiant se change dans `AppConfig.supportProductId`.

## Tests
```bash
flutter test            # moteur d'entretien, rappels, repositories (SQLite en mémoire), parcours d'app
flutter analyze
```

## Stack
Flutter 3.47 · Dart 3.13 · Riverpod 3 · go_router · drift (SQLite) · flutter_local_notifications · image_picker · ARB / gen-l10n (fr, en, de, it).

Sur iOS l'app s'appuie sur les composants Cupertino natifs (grands titres, sheets, action sheets, pickers, switches, segmented controls, menus) ; sur Android sur Material 3. L'identité visuelle (tokens, cartes, tab bar flottante) est commune.

Accessibilité : cibles tactiles de 44 pt garanties par `Pressable`, Dynamic Type
de 82 % à 350 % sans rognage, *Texte en gras* et *Augmenter le contraste*
suivis, contrastes AA tenus par un test. Détails et invariants :
[docs/06-design-system.md](docs/06-design-system.md). Sur iPad, l'app tourne et
accepte le multitâche ; le contenu se recentre au-delà de 700 pt de large.
