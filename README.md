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
| [docs/12-guides-de-multiplication.md](docs/12-guides-de-multiplication.md) | Guides de multiplication : archétypes de gestes, choix du guide, rendus Blender |
| [docs/13-care-environment-scenes.md](docs/13-care-environment-scenes.md) | Scène d'environnement idéal : diorama clay, projection des besoins, pipeline Blender |

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
Schéma et politiques RLS : `supabase/schema.sql`, à rejouer en entier dans l'éditeur SQL. Les liens de partage et d'invitation demandent en plus la fonction Edge `share` (`supabase functions deploy share --no-verify-jwt`, depuis la racine du dépôt) et le relais `share-proxy/` qui la sert sous un domaine à soi (docs/08). Connexion par Apple, sur
iPhone et iPad, et par rien d'autre : pas d'e-mail, et Google attend son tour
(`AppConfig.googleSignInEnabled`) — sur Android le compte reste local. Sign in with Apple demande la capability sur
l'App ID et le bundle dans les *Authorized Client IDs* de Supabase. Détails : docs/08.

## Les capteurs de la maison (facultatif)
Un capteur de température ou d'humidité de la maison peut être branché à
l'onboarding (après la ville) ou dans Profil › Capteurs de la maison. Sa
mesure ajuste les conseils des plantes d'intérieur (air sec, froid, chaleur)
sur l'écran Aujourd'hui et dans les fiches d'entretien, et accompagne les
photos d'un diagnostic. Rien n'est écrit dans la maison, aucune mesure n'est
gardée.

Apple Maison est livré : sur iPhone et iPad, lecture sur l'appareil par
HomeKit (`ios/Runner/HomeClimateChannel.swift`, capability *HomeKit* sur
l'App ID). Google Home est livré aussi (`AppConfig.googleHomeEnabled`) :
lecture des appareils par les Home APIs, sur iPhone et sur Android, dont le
SDK se donne à la construction. Ces API plafonnent à cent comptes tant que
leur console développeur n'accepte pas d'inscription — c'est la limite de
leur beta publique. Sans aucune maison lisible, l'étape et le réglage
n'apparaissent pas. Détails : docs/05.

## Sur l'écran d'accueil d'iOS
Un widget montre les soins du jour (petit et moyen sur l'écran d'accueil,
rond, rectangle et ligne sur l'écran verrouillé) ; l'appui long sur l'icône
propose d'ajouter une plante, de scanner une étiquette ou d'en trouver une ;
l'arrosage, la validation et les gestes sensibles ont leurs motifs Core
Haptics. Tout passe par des canaux natifs, sans plugin (`ios/Runner/*Channel.swift`,
`ios/AuxineWidget/`). L'App Group `group.ch.vergasta.plant` doit exister sur
l'App ID de l'application et sur celui du widget (`ch.vergasta.plant.widget`).
Sur Android, rien de tout cela n'apparaît. Détails : docs/05 et docs/06.

## Encyclopédie
*Profil › Encyclopédie* ouvre ce que l'application embarque, à lire hors de
tout écran de travail : les 200 troubles, ravageurs et maladies de la base
(rangés par famille, cherchables par nom, par numéro ou par hôte, une page
chacun) ; les espèces du catalogue intégré et leur fiche d'entretien, sans
qu'il faille posséder la plante ; et le vocabulaire des fiches — lumière,
humidité, substrat, multiplication, toxicité, difficulté —, un terme, une
définition. Ces listes existaient déjà : elles n'apparaissaient qu'au moment
où elles servaient. Détails : docs/04.

## Conseils de la communauté
Sous la fiche d'entretien — celle d'une plante comme celle d'une espèce de
l'encyclopédie —, ce que d'autres ont observé en gardant la même espèce. Le
catalogue dit ce qu'une plante demande ; il ne dit pas ce qu'on apprend en la
gardant trois ans dans une pièce donnée.

Un conseil est rattaché à l'espèce, par la clé du catalogue : un par personne
et par espèce, qu'on reprend plutôt qu'on empile. Lire ne demande pas de
compte, publier en demande un, et le conseil paraît alors sous le nom du
compte. « Utile » compte les voix, « Signaler » les signalements — au
troisième, le conseil cesse de paraître aux autres, son auteur le voit encore
avec la mention qui le dit.

Au troisième signalement, le conseil cesse de paraître ; il faut ensuite
quelqu'un pour trancher. *Profil › Modération* montre les conseils signalés —
masquer, rétablir, retirer — et n'apparaît qu'aux comptes inscrits dans la
table `moderators`. On en nomme un par une ligne dans l'éditeur SQL du
projet, jamais depuis l'application : un drapeau posé sur le profil se
donnerait à soi-même, puisque chacun écrit sa propre ligne de `profiles`.

```sql
insert into moderators (user_id) values ('<uuid du compte>');
```

Cela demande le backend : sans `SUPABASE_URL`, la section n'existe pas, et
`supabase/schema.sql` est à rejouer en entier pour créer les tables et leurs
fonctions. Détails : docs/04 et docs/08.

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
