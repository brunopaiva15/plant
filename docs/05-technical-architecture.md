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
| Version affichée | `package_info_plus` (`AppVersion`, `appVersionProvider`) | la ligne `version:` du `pubspec.yaml` est le seul numéro à changer : Xcode, Gradle et l'écran des réglages la lisent tous là |
| i18n | `flutter_localizations` + ARB (`gen-l10n`) | fr / en / de / it, pluriels, dates locales |
| Backend (P3) | Supabase derrière `RemoteDataSource` | Postgres + Auth + Storage + Realtime, mais remplaçable |
| Espèces | GBIF (`SpeciesService`), photos Wikimedia Commons en complément (`SpeciesImageSource`) | gratuit, sans clé, taxonomie de référence, images d'observations avec attribution ; Commons ajoute la plante cultivée sur la fiche espèce |
| Identification | cascade `CascadeIdentifier` : modèle local (à venir) puis Pl@ntNet (`PlantIdentifier`) | clé de l'utilisateur, repli coupable, voir [09](09-plant-recognition.md) |
| Diagnostic | AI Services d'Infomaniak, route compatible OpenAI (`PlantDiagnoser`) | clé de l'éditeur au build, modèle choisi au build, sans plafond |
| Complément de fiche | AI Services d'Infomaniak (`CareCompleter`) | seulement quand le catalogue n'a que des repères généraux ; nom scientifique seul, réponse gardée sur l'appareil |
| Météo | Open-Meteo (`WeatherService`) : prévisions et jours passés en un appel, archives sur trois ans pour le climat du lieu | gratuit, sans compte |
| Climat de la maison | HomeKit, par un canal natif (`HomeClimateService` → `ios/Runner/HomeClimateChannel.swift`) | iPhone et iPad seulement ; lecture de deux caractéristiques, rien d'écrit, rien ne sort de l'appareil |
| Climat de la maison (Google Home) | Home APIs, par un canal natif (`GoogleHomeClimateService` → `ios/Runner/GoogleHomeChannel.swift`, `android/app/src/googleHome/kotlin/.../GoogleHomeChannel.kt`) | iPhone, iPad et Android ; lecture de deux traits, rien d'écrit. Livré ; les Home APIs plafonnent à cent comptes tant que leur console développeur n'accepte pas d'inscription |
| Widgets, raccourcis, haptiques | WidgetKit, `UIApplicationShortcutItem`, Core Haptics, par trois canaux natifs (`ios/Runner/TodayWidgetChannel.swift`, `QuickActionsChannel.swift`, `HapticsChannel.swift`) | iPhone et iPad seulement ; muets ailleurs, sans plugin |

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

## État du réseau (`core/network/`)
Le jardin, les soins et le journal vivent sur l'appareil et ne demandent rien à
personne. Une poignée de fonctions, elles, n'existent que sur le réseau :
liens de partage, collaboration, diagnostic, recherche GBIF, achat de soutien.
Sans connexion, leurs requêtes ne partaient pas *et ne revenaient pas* — un
écran tournait indéfiniment plutôt que de dire ce qui manquait.

- **Constat.** `ConnectivityController` (`connectivityProvider`) tient un
  `NetworkStatus`, tenu à jour par une sonde de joignabilité
  (`Reachability` → `SocketReachability`). Elle part au lancement — `main` lit
  le provider avant le premier écran —, à chaque retour au premier plan, et
  toutes les huit secondes tant que le réseau manque ; jamais quand
  l'application est en ligne, jamais en arrière-plan. L'application démarre
  « en ligne » : on ne conclut pas avant d'avoir regardé.
- **La sonde ouvre une connexion, elle ne résout pas un nom.** Une résolution
  DNS ne prouve rien sur un téléphone : le résolveur répond de son cache, et
  sur un iPhone les noms courants y sont toujours. En mode avion, l'appareil
  se croyait joignable, la requête partait quand même et l'écran attendait son
  délai d'expiration — le tourniquet sans fin, exactement. Trois destinations
  sont tentées **en même temps**, la première qui répond suffit : le serveur de
  l'application, puis `1.1.1.1` et `8.8.8.8` en TCP sur 443, écrits en chiffres
  pour se passer de DNS. Trois plutôt qu'une parce que se tromper en disant
  « hors ligne » est la pire erreur des deux : elle éteint des fonctions qui
  marchaient.
- **Branchement.** Par défaut `reachabilityProvider` rend une sonde inerte qui
  répond « en ligne » ; c'est `main` qui installe `SocketReachability`, comme il
  installe la base et les préférences. Un test qui ne parle pas du réseau n'a
  donc ni attente ni minuteur, et celui qui joue une coupure passe sa propre
  sonde.
- **Garde.** `ref.online(() => …)` entoure un appel qui a besoin du réseau :
  hors ligne il lève `OfflineException` sans rien tenter ; sinon l'appel part,
  sa réussite confirme la connexion, et son échec ne devient « hors ligne »
  qu'après confirmation par la sonde — un serveur muet n'est pas un réseau
  coupé. Les providers concernés observent `connectivityProvider`, si bien que
  le retour du réseau relance la requête et remplit l'écran tout seul.
- **Pas de reprise invisible.** Riverpod réessaie de lui-même un provider en
  erreur — dix fois, en doublant l'attente — et garde l'état sur
  `AsyncLoading` pendant ce temps : la branche `error:` d'un écran ne
  s'affichait qu'après plusieurs minutes, tourniquet compris. Le conteneur de
  `main` et les providers réseau portent donc `retry: noRetry` ; la reprise est
  celle qu'on voit, le bouton « Réessayer » et le retour du réseau.
- **Délais.** Les clients HTTP bornaient déjà leurs appels ; Postgrest, non.
  Toute requête Supabase — partage, collaboration, synchronisation — est
  bornée par `networkTimeout` (12 s), les transferts de photos par deux
  minutes. C'est le filet, pas la règle : hors ligne la sonde arrête l'appel
  avant qu'il ne parte, et ce délai ne joue que pour un serveur joignable mais
  muet. Une synchronisation qui échoue sur le réseau passe en
  `SyncStatus.offline` plutôt qu'en erreur, et repart dès que la connexion
  revient (`SyncCoordinator` écoute `connectivityProvider`).
- **Ce que voit l'utilisateur.** `OfflineNotice` remplace le contenu d'un écran
  qui n'existe que sur le réseau, avec un bouton qui relit l'état ;
  `OfflineBanner` coiffe un écran qui marche à moitié — la liste des membres se
  lit hors ligne, inviter attend. Chaque fonction dit ce qui lui manque
  (`offlineSharing`, `offlineCollaboration`, `offlineDiagnosis`,
  `offlineIdentification`, `offlineSupport`), et un geste refusé rend
  `offlineActionFailed` plutôt qu'« une erreur est survenue ».

## Auth
`AuthRepository` (domain) ⇒ `LocalAuthRepository` (P1, compte sur appareil, aucune donnée sortante) ⇒ `SupabaseAuthRepository` (P2 : Apple, Google, e-mail). La migration local → compte réattribue `owner_id` du jardin.

## Widgets de l'écran d'accueil (`features/today/application/today_widget.dart`, `ios/AuxineWidget/`)
L'écran du matin, sur l'écran d'accueil et l'écran verrouillé : le chiffre du
jour, les premières plantes qui attendent, « Tout est en ordre » le reste du
temps. Cinq familles : petit et moyen sur l'écran d'accueil ; rond,
rectangle et ligne sur l'écran verrouillé.

- **L'extension ne calcule rien et ne traduit rien.** `todayWidgetSnapshotProvider`
  réduit les soins échus, les tâches libres et le compte des plantes à un
  instantané JSON (`TodayWidgetSnapshot`), libellés compris, dans la langue
  de l'interface — les pluriels de `careCount` sont ceux de l'écran. Il est
  recalculé à chaque changement de la base ; `main.dart` l'écoute et le
  publie par `TodayWidgetService` (`ch.vergasta.plant/widgets`). Au retour
  au premier plan, il est recompté avec la date du jour.
- Le natif dépose le JSON dans les préférences de l'App Group
  `group.ch.vergasta.plant` (clé `today`) et appelle
  `WidgetCenter.reloadAllTimelines()`. L'extension lit la même clé, et
  repasse à minuit. Sans instantané — première installation, galerie des
  widgets —, elle montre un exemple dans la langue de l'appareil, les seuls
  mots qu'elle porte elle-même.
- Toucher le widget ouvre l'accueil (`auxine://today`) ; une ligne du widget
  moyen ouvre la fiche (`auxine://plant/<id>`), par le routage des liens
  `auxine://` qui existe déjà.
- La palette est celle de docs/06, recopiée dans `AuxineWidget.swift` : à
  tenir à jour avec `colors.dart`.
- Cible Xcode `AuxineWidget` (`ch.vergasta.plant.widget`, iOS 16), embarquée
  par Runner ; l'App Group est déclaré dans les deux entitlements. Il doit
  aussi l'être sur les deux App ID du portail développeur, sans quoi la
  signature automatique refuse le profil.

## Raccourcis de l'icône (`app/quick_actions.dart`)
L'appui long sur l'icône propose trois raccourcis : ajouter une plante,
scanner une étiquette, trouver une plante. `QuickActionsHost`, posé autour
de la coquille, les pose dans la langue de l'interface (et les repose si
elle change) et exécute celui qui a été choisi. Le natif
(`QuickActionsChannel`, enregistré comme délégué de scène de Flutter plutôt
qu'en surchargeant `SceneDelegate`) le rend de deux façons : par `perform`
quand l'application tourne, par `launchAction` quand c'est lui qui l'a
lancée — il attend alors que Dart le demande, sans quoi il partirait avant
que personne n'écoute. `pendingQuickActionProvider` le garde jusqu'à ce que
la coquille soit là, après l'onboarding s'il y en a un.

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

## La chrome de navigation, en natif sur iOS (`core/native_shell.dart`)

Sur iOS, la barre d'onglets n'est plus dessinée par Flutter : c'est un
`UITabBarController`. La raison est dans la documentation d'Apple, et elle ne
laisse pas le choix — une `UITabBar` ou une `UINavigationBar` posée seule
**n'est pas prise en compte** pour le placement vertical de l'iPhone Duo ; il
faut un contrôleur qui possède sa barre. Une barre dessinée par une
application, si fidèle soit-elle, reste du contenu aux yeux du système.

Le partage est net :

| qui | quoi |
|---|---|
| UIKit | la barre d'onglets, son placement, son débordement, son allure |
| Dart | la navigation — go_router garde les branches et les pages |

Toucher un onglet ne fait donc rien tout seul : le natif le dit à Dart sur
`ch.vergasta.plant/native_shell`, Dart change de branche, Flutter redessine.
L'inverse vaut aussi, pour qu'un lien profond déplace l'onglet.

La forme, côté natif (`ios/Runner/NativeShell.swift`) :

```
UITabBarController          ← possède la barre, qu'iOS place
├── HostViewController      ← un par onglet, vide
│   └── (la vue de Flutter, quand cet onglet est choisi)
└── …
```

Un contrôleur d'onglets tire ses onglets de ses enfants : il en faut autant
que d'onglets. Mais il n'y a **qu'un moteur Flutter**, donc qu'une vue, et
elle déménage d'un hôte à l'autre au changement d'onglet — contenance UIKit
ordinaire, `addChild` et `didMove`, pas un tour de passe-passe. Quatre moteurs
auraient coûté quatre démarrages et auraient retiré les onglets à go_router.

Les onglets sont déclarés avec des **SF Symbols** et non les icônes Cupertino
d'Auxine : c'est UIKit qui les dessine, et il ne connaît que les siens. Les
libellés viennent des ARB comme partout ailleurs.

Ailleurs que sur iOS, rien ne change : `FloraTabBar` en bas sur un téléphone,
`FloraTabRail` debout sur une fenêtre large (docs/06, « Le menu debout »).

Chaque onglet porte en plus un `UINavigationController`, pour la même raison
que le contrôleur d'onglets : les boutons d'une page sont de vrais
`UIBarButtonItem`, et c'est à ce titre qu'iOS les range dans la bande.

Les pages n'ont pas changé pour autant. Elles donnent toujours des
`FloraIconButton` à `LargeTitlePage` ; `components/native_actions.dart` les
traduit — l'icône par `core/sf_symbols.dart`, le libellé par `semanticLabel`,
l'action par un identifiant que le natif renvoie. Une table plutôt qu'un nom
de symbole déclaré partout : cent vingt sites d'appel n'ont pas eu à bouger.

C'est **tout ou rien** : si une seule icône manque à la table, la page garde
ses boutons en argile, et le point de code manquant s'écrit dans la console en
debug. Une rangée moitié système moitié argile serait pire que l'une ou
l'autre.

**Un bouton peut déplier plutôt qu'agir.** Les trois points d'une fiche de
plante ouvraient une feuille d'actions, qui montait du bas et recouvrait la
photo. Ce n'est pas ce que fait iOS : un bouton de barre qui porte un `UIMenu`
fait sortir son menu **de lui-même**, à sa place dans la barre, en floutant la
page derrière — ce que font Maison, Photos ou Mail. La feuille est faite pour
un choix qui engage ; un menu, pour la liste des gestes d'une page.

La page ne déclare qu'une chose : `FloraIconButton.menu`, la même liste de
`SheetAction` que la feuille recevait. `native_actions.dart` la traduit en
entrées, le natif en `UIAction`, et `separated` ouvre un groupe — iOS sépare
ses groupes d'un trait. Une entrée sans SF Symbol n'entraîne pas le bouton
dans sa chute : c'est une ligne de texte, ce qu'iOS accepte sans broncher ; le
tout ou rien vaut pour la barre, pas pour ce qu'elle déplie.

La liste est dressée **au rendu**, et non à l'ouverture : un menu du système
est déclaré avant d'être touché, et il doit donc déjà dire « Retirer des
favoris » quand le cœur est plein. Le natif renvoie l'entrée choisie —
`R1.3`, la quatrième du menu du deuxième bouton de droite —, pas le bouton
qui la portait.

Là où le natif n'est pas — Android, ou une barre qu'il a refusée —, le bouton
reste en argile et c'est `showAdaptiveActionSheet` qui répond, comme avant :
une feuille reste la bonne réponse de cette plateforme-là. Les deux disent la
même chose ; ce n'est pas la même façon de la dire.

**Une page posée dans une feuille garde la sienne.** C'est le pendant de la
règle : la barre d'UIKit est celle de la coquille, et une feuille de Flutter
passe *par-dessus* la coquille — l'observateur l'efface au moment de la
poussée, et la page qui s'ouvre dedans ne peut pas la reprendre, puisqu'elle
vit dans le navigateur de la feuille. Elle cédait quand même, et se retrouvait
sans rien : ni titre, ni retour, ni croix. « Où la poser », la feuille du
relevé, s'ouvrait sur son contenu nu.

`CupertinoSheetRoute.hasParentSheet` le dit en un mot, et `FloraPage` comme
`LargeTitlePage` s'abstiennent alors de céder. La page à la racine d'une
feuille reçoit en plus **une croix** : elle n'a rien à dépiler — mais la
feuille, si, et sans ce bouton elle ne se refermait qu'au glissement.
`test/design_system/sheet_chrome_test.dart` tient les deux, et la poignée
avec.

Les pages qui prétendent à la barre forment une **pile**, et la dernière
visible l'emporte. Une page poussée par-dessus une autre prend la barre ;
quand elle s'en va, celle qu'elle recouvrait la reprend sans avoir à se
redessiner — rien ne la forcerait à le faire. « Visible » se lit sur deux
choses : la route est-elle celle du dessus, et sa branche d'onglet est-elle
éveillée (`TickerMode`).

**Le titre reste à Flutter.** La barre native n'en porte pas : le grand titre
en argile — le « Bonsoir » arrondi — est la signature d'Auxine, et « fini les
menus » ne dit rien des titres. Deux titres empilés seraient une faute ; c'est
donc le natif qui se tait. À rouvrir si la bande horizontale que la barre
garde en haut se révèle trop chère.

Le bouton de tête d'une page part avec les autres — le tableau de bord
d'« Aujourd'hui » —, à gauche de la barre, là où iOS met la navigation. Pas le
bouton retour : celui-là attend d'être rendu par la pile de navigation
elle-même.

**`isCurrent` ne vaut que dans son navigateur.** C'est le piège de cette
mécanique, et il a coûté trois allers-retours. Une page de la coquille vit
dans le navigateur de son onglet ; une feuille poussée sur le navigateur
racine la couvre sans que sa branche en sache rien, et elle se croyait donc
encore visible. Elle redemandait la barre que l'observateur venait d'effacer,
et la feuille se retrouvait coiffée des boutons de la page d'en dessous.

Une page qui n'est pas posée sur le navigateur racine ne prétend donc à la
barre que si rien ne couvre la coquille. Celles qui y sont posées — une fiche,
une page secondaire — y prétendent à tout étage, puisqu'elles *sont* cet
étage. Et `NativeShell.overlay` est écoutable, pour qu'une page couverte
reprenne la barre quand ce qui la couvrait s'en va : rien ne la forcerait
sinon à se redessiner, et la barre reviendrait vide.

**Et rien ne s'attend entre deux envois.** Le garde-fou qui vide la barre
avant de la masquer *attendait* la première réponse. Cette attente laissait
passer une image : la page qui s'ouvrait demandait la barre et publiait ses
boutons dans l'intervalle, et le masquage arrivait après, effaçant ce qu'elle
venait de poser — une fiche de plante se retrouvait sans aucun bouton. Un
canal de méthode livre dans l'ordre où on lui confie ; il suffit de lui
confier les deux à la suite. `test/core/native_shell_test.dart` tient l'ordre,
et échoue sur la version qui attendait.

**Les deux barres se masquent par leur contrôleur.** `isHidden` et `alpha`
portent sur des vues que `UITabBarController` et `UINavigationController`
possèdent ; ils les remettent comme ils l'entendent à chaque mise en page, et
sur l'iPhone Duo ce sont eux, non leurs barres, qui décident de ce que le
système range dans la bande verticale. La barre d'onglets reparaissait
par-dessus une feuille, trois tentatives de suite ;
`setTabBarHidden(_:animated:)` est l'API faite pour ça, depuis iOS 18 (en deçà
on retombe sur la vue, faute de mieux). La barre du haut, elle, était encore
voilée par son opacité, et l'a appris à son tour : ouvrir une pièce du relevé
donnait une feuille coiffée du titre et du retour de la page d'en dessous,
poignée cachée et titre lu au travers. C'est `setNavigationBarHidden` qui la
retire.

**La chrome n'existe pas avant la coquille.** Au premier lancement,
l'introduction s'ouvre sans elle : sans verrou, le contrôleur d'onglets
montrait son onglet de départ — un rond sans nom — par-dessus, et une barre
vide avec. Les deux barres restent donc effacées tant que la coquille n'a pas
déclaré ses onglets.

Le verrou tient des deux côtés, et il a fallu les deux. Côté Dart, la coquille
dit ses onglets **avant** de rendre la barre : un canal livre dans l'ordre, et
la barre ne reparaît donc que remplie. Côté natif, les deux barres partent
cachées — le rond sans nom se voyait pendant toute l'introduction, parce que
Dart, lui, n'avait encore rien dit du tout. L'état demandé est gardé, parce que
`rebatir` refait les contrôleurs de navigation : neufs, ils arrivent avec leur
barre visible, et Dart ne redit pas une chrome qui n'a pas changé.

**Une page et une surcouche ne se valent pas.** Un menu d'action, une alerte,
une feuille à hauteur de contenu ne prennent pas la place de la page : elles
se posent dessus le temps d'un choix. Les effacer pour de bon rendrait leur
place au contenu, la marge sûre changerait, et la page glisserait sous le menu
qui vient de s'ouvrir — ce qu'elle faisait. Ces routes-là ne font donc que
**voiler** la chrome. L'observateur les compte à part (`PageRoute` ou non).

Voiler, c'est retirer la barre **et lui garder sa place** : elle part par son
contrôleur, seule façon qu'elle s'en aille pour de bon, et
`additionalSafeAreaInsets` tient la marge qu'elle occupait le temps de la
surcouche. Cette place se mesure pendant que la chrome est encore là — une
fois partie, elle ne dit plus ce qu'elle prenait —, comme la différence entre
ce que la vue de Flutter reçoit et ce que la fenêtre réserve d'elle-même, et
dans les quatre sens : une barre rangée dans la bande verticale ne prend pas
la sienne en haut. Une chrome déjà effacée mesure zéro, et une surcouche posée
sur une page plein écran n'a donc rien à compenser.

**Et la chrome s'efface quand une page la couvre.** UIKit ne sait rien de la
navigation de Flutter : une fiche de plante, un scanner de QR code, une
feuille d'ajout sont des routes que go_router pose par-dessus la coquille, et
les barres natives restaient là — sur la page ouverte, avec les boutons de
celle d'en dessous. `app/native_chrome_observer.dart` observe le navigateur
racine : il tient la liste des pages vivantes, et tout ce qui se trouve
au-dessus de la plus basse efface les deux barres. Les pages des branches
d'onglets ne passent pas par là, elles ont leur propre navigateur, et c'est
bien la coquille qu'on regarde alors.

**Une liste, et non un compteur.** Le compteur ignorait la page du bas — elle
n'a rien en dessous, donc c'est la coquille — et se trompait à la fin de
l'introduction : `context.go` pose la coquille **par-dessus** l'introduction,
puis retire celle-ci d'en dessous. Le premier mouvement comptait une page de
trop, le second ne la retirait pas faute de route en dessous, et l'application
restait sans aucune barre jusqu'au lancement suivant — c'est le redémarrage qui
la rendait, puisque la coquille y est la première page. Une liste dit ce qui
reste debout quel que soit l'ordre des deux mouvements, et
`test/app/native_chrome_observer_test.dart` rejoue la séquence.

Le **bouton retour** part avec le reste : c'était déjà un `FloraIconButton` à
chevron, il se décrit comme les autres et va à gauche. Le geste de balayage
reste celui de Flutter, qui possède la pile de routes.

L'**ajout** est marqué proéminent, et iOS le garde visible quand la bande
déborde au lieu de le replier dans le menu — `pinnedTrailingGroup`, qui
n'existe pas avant iOS 26 ; sans lui l'action reste un bouton ordinaire.
C'est l'ajout et pas un autre parce qu'il est l'action principale d'Auxine
partout où elle est offerte.

Trois gabarits cèdent désormais leur barre :

| gabarit | ce qui part |
|---|---|
| `LargeTitlePage` | le bouton de tête, le retour, les actions. Le grand titre reste à Flutter |
| `FloraPage` | le retour, l'action, **et le titre** — il était centré et petit, c'est exactement ce qu'`UINavigationItem.title` dessine |
| la fiche plante | le retour, le cœur, le menu. Ils flottaient sur la photo ; ce sont des commandes, et iOS les range comme telles |

Ce qui reste : les pages qui dessinent leur propre chrome sans passer par ces
gabarits — un scanner, une feuille —, et qui gardent leurs boutons. Elles
n'ont pas de barre, donc rien à céder ; la chrome native s'efface pour elles.

Et les marges sûres : elles viennent de la propagation d'UIKit, que les
contraintes de `heberger` ont remise d'aplomb. Y ajouter un canal qui les
calculerait à part créerait une seconde source de vérité capable de
contredire la première — à ne faire que si un relevé montre qu'elle se
trompe.

## La fenêtre : téléphone, tablette, pliable (`app/window.dart`)

Sur téléphone, l'application se tient en portrait : chaque écran est une
colonne, et le paysage n'apporterait qu'une mise en page étirée. Sur tablette,
rien n'est verrouillé — iPadOS attend qu'une application tourne et cohabite
avec une autre, et le refuser est un motif de rejet. **Ces deux règles sont
déclarées, pas demandées** : `ios/Runner/Info.plist` porte le portrait sur
iPhone et les quatre orientations sur iPad, le manifeste Android porte le
portrait partout. Aucun code ne fait de demande à l'exécution, et la section
« Ce qu'il ne faut pas refaire », plus bas, dit pourquoi.

Ce que le code décide, c'est où se poser dans la fenêtre qu'on lui donne. La
limite est à 600 points de côté le plus court ; au-delà de 700 points de
large, le contenu rend son surplus en marges (`readableInset`,
`design_system/components/page_scaffold.dart`).

L'iPhone Duo tient les deux rôles dans la même séance : fermé il est un
téléphone, ouvert une tablette, et rien n'a été relancé entre les deux. Aucune
taille n'est donc gardée : `isCompactWindow()` mesure la vue implicite à
chaque appel, et le viseur intégré suit la même règle
(`features/plants/presentation/inline_camera.dart`) — son verrou de capture,
qui passe par le plugin caméra et non par UIKit, se défait quand l'appareil
s'ouvre, faute de quoi une photo prise après le pli sortirait couchée.

### Les cotes, mesurées

Relevées dans Xcode 27.1 sur le simulateur, DPR 3 partout. Elles viennent du
harnais Duo de *disquebleu* (`docs/duo-harness.md` de ce dépôt-là), pas d'un
calcul, et d'un binaire **construit avec le SDK 27.1** — celui qui dessine
bord-à-bord.

| Pose | `MediaQuery.size` | `physicalSize` | Marges sûres (G/H/D/B) |
|---|---:|---:|---|
| fermé, portrait | 466 × 678 pt | 1398 × 2034 px | 0 / 82 / 0 / 34 |
| fermé, couché | 678 × 466 pt | 2034 × 1398 px | 0 / 0 / 84 / 34 |
| ouvert, portrait | 669 × 951 pt | 2007 × 2853 px | 0 / 82 / 0 / 34 |
| ouvert, couché | 951 × 669 pt | 2853 × 2007 px | 0 / 0 / 84 / 34 |
| multitâche, moitié | 445 × 626 pt | | |
| multitâche, tiers | 320 × 626 pt | | |

La bande de la caméra n'est pas toujours du même côté : selon le sens de
rotation, les mêmes 84 points se retrouvent à gauche. **Rien n'est
symétrique**, et chaque bord se lit pour lui-même — c'est aussi ce que
recommande Apple. La pilule du bas comme le rail de droite ajoutent donc les
marges du système aux leurs, bord par bord.

Construite avec le SDK 27.0, la même application tourne en **mode de
compatibilité** : bande noire, fenêtre tenue à l'écart de la zone
heure/caméra, et 80 points perdus sur un axe — 386 × 678 fermé, 669 × 871
ouvert. Les deux se ressemblent assez pour qu'on prenne l'un pour l'autre,
d'où le `[auxine:sdk]` qu'écrit `ios/Runner/SceneDelegate.swift` en debug : il
donne le SDK inscrit dans le bundle et prévient si c'est le mauvais. Changer
de simulateur ne suffit pas, c'est le Xcode sélectionné à la construction qui
décide. Les deux limites de l'application — 600 points pour le menu, 700 pour
le côté le plus court — tiennent dans les deux modes.

Deux constats de ces relevés valent plus que les nombres :

- `MediaQuery.displayFeatures` est **vide** dans les quatre poses, pli partiel
  compris. Flutter ne l'alimente que sur Android, et le pli partiel ne produit
  même pas de nouveau relevé : la scène garde la même surface. Rien, côté
  Dart, ne dit où passe la charnière.
- `SystemChrome.setPreferredOrientations` est **refusé** par UIKit, qui répond
  `UISceneErrorDomain Code=101`. Voir juste en dessous.

Côté iOS, trois points valent d'être connus :

- `UIRequiresFullScreen` ne doit pas revenir dans `Info.plist`. La clé dit au
  système que l'application veut tout l'écran à l'ancienne manière, et la tient
  hors de l'adaptation — fermée comme ouverte.
- Les orientations ne se décident plus depuis le code : la déclaration de
  `Info.plist` vaut, la demande programmatique est refusée (voir plus bas).
  Une page doit savoir tourner, pas s'y opposer.
- `TARGETED_DEVICE_FAMILY = "1,2"` était déjà posé pour l'iPad ; c'est cette
  valeur qui ouvre à l'écran intérieur les mises en page larges d'UIKit.

La construction demande le SDK iOS 27.1 (Xcode 27.1, en bêta depuis le
18 septembre 2026, sur un Mac Apple Silicon en macOS 26.6 ou plus récent). En
deçà, iOS applique ses replis de compatibilité : la fenêtre n'atteint pas les
bords de l'écran intérieur et reste tenue en une colonne. La cible de
déploiement, elle, ne bouge pas : iOS 17.

Ce que l'ouverture change à l'écran : le menu passe debout sur le bord droit
(`FloraTabRail`, `app/shell.dart`), le contenu prenant ce qui reste — une
pilule posée en bas traverserait tout l'écran pour quatre onglets — et les
boutons du haut de page rejoignent la colonne (`RailActions`). La bascule
tient en deux nombres, dans `FloraTabRail.fitsIn`, et l'iPad n'est pas
concerné : il garde sa barre du bas. Le détail du rail est dans docs/06,
section « Le menu debout ».

### Ce qu'il ne faut pas refaire

L'application a demandé le portrait à `SystemChrome.setPreferredOrientations`
dès que la fenêtre était compacte. Elle ne le fait plus, et ne doit pas
recommencer.

Sur l'iPhone Duo, la demande est refusée : UIKit répond `UISceneErrorDomain
Code=101`, et Dart n'en sait rien — l'engine passe un gestionnaire d'erreur
vide, si bien que l'appel paraît réussir. L'écran extérieur tourne donc quoi
qu'on demande, et 678 × 466 est un état à tenir, pas à empêcher.

Ailleurs, la demande ne faisait que répéter ce qui était déjà déclaré dans
`Info.plist` et dans le manifeste. Sur iPad, Flutter note d'ailleurs qu'elle
n'est honorée que si le multitâche est coupé — ce qu'on ne fait pas, et qu'on
ne fera pas. Il restait donc un mécanisme qui ne décidait rien et qui, sur
pliable, laissait une erreur UIKit dans la console à chaque lancement.

C'est aussi la conclusion du harnais Duo de *disquebleu*, dans les mêmes
termes : « ne pas réintroduire de verrouillage programmatique de
l'orientation ; utiliser la taille de scène et les insets réellement reçus par
Flutter ».

Pour relever les cotes d'une pose qu'on n'a pas sous la main,
`app/window_probe.dart` écrit la fenêtre dans la console à chaque changement —
taille, marges sûres, écran, nombre de vues, pli. En debug, sans rien
demander ; jamais ailleurs. Un relevé qui répète le précédent n'est pas
réécrit, si bien qu'un clavier qui monte ne dit rien et qu'un pli dit tout.

Elle a d'abord été muette sur l'appareil, pour deux raisons qu'il vaut mieux
connaître : elle était derrière un `--dart-define`, qui se passe
silencieusement de travers, et son premier relevé partait de `main()`, avant
que l'application ait ouvert sa fenêtre — donc dans le journal de l'appareil
avant que `flutter run` ne s'y branche. Le drapeau a disparu et le premier
relevé attend la première image. Même chemin que le `_logDuoMetrics` de
*disquebleu*, qui écrit depuis un `build()` pour la même raison.

### Ce que le système réserve (`core/window_regions.dart`)
Les marges sûres ne disent pas tout. Sur un pliable, trois cotes manquent, et
chacune décidait jusqu'ici d'une constante relevée au pixel sur une capture :

- **jusqu'où descend la pile du système** — caméra, heure, wifi empilés contre
  le bord. `padding.top` annonce 82 points là où la pile descend à 140 ;
- **sur quel axe** cette pile est posée, pour que le menu debout s'y aligne ;
- **où passe le pli**, que `MediaQuery.displayFeatures` ne donne pas : le champ
  est alimenté sur Android seulement.

`ios/Runner/WindowRegionsChannel.swift` les demande à UIKit —
`reservedRegions(kind: .occlusion)` pour la caméra, `.division` pour le pli,
`statusBarManager.statusBarFrame` pour la pile — et les rend dans le repère de
la vue Flutter, en points. `WindowRegionsService` les lit au lancement et à
chaque `didChangeMetrics`, c'est-à-dire à chaque pli et à chaque rotation.

Le relevé du 20 septembre 2026, sur le simulateur de l'écran extérieur, dit
comment les trois se lisent — et il vaut mieux que ce qu'on espérait.

`statusBarFrame` est mort sur cet appareil : il rend **466 × 2 points en haut
à gauche** pendant que l'heure et le wifi sont debout contre le bord droit. Le
cadre n'a pas suivi la barre dans sa rotation.

Mais les occlusions en donnent deux, pas une :

| région annoncée | ce qu'elle vaut |
|---|---|
| `382, 0 · 84 × 170` | la **bande du système**, large comme la marge sûre de ce côté. Son bas, 170, borne la pile |
| `399,7 ; 29,3 · 37 × 37` | la **caméra**, qui flotte dedans. Son milieu tombe à 47,8 points du bord droit |

D'où les deux règles de `parse`, qui se répondent. Le bas de la pile ne vient
que d'une région qui **part du bord haut** — la bande. L'axe ne vient que d'une
région qui **flotte** — la caméra. Chacune est écartée du rôle de l'autre, et
pour de bonnes raisons : une caméra est le haut de la pile, jamais son bas, et
prise seule elle poserait le menu au-dessus de l'heure ; le milieu de la bande
n'est pas celui des glyphes, 42 points du bord contre 47,8 dans la même pose.

La seconde règle compte plus qu'il n'y paraît, parce qu'iOS n'annonce pas la
caméra dans toutes les poses :

| pose | régions annoncées | ce qu'on en retient |
|---|---|---|
| fermé, 466 × 678 | bande `382, 0 · 84 × 170`, caméra `399,7 ; 29,3 · 37 × 37` | pile 170, axe 47,8 |
| ouvert couché, 951 × 669 | bande `867, 0 · 84 × 120` | pile 120, **pas d'axe** |

Se rabattre sur la bande dans le second cas ferait sauter le menu de six points
d'un pli à l'autre. Sans région flottante on ne dit donc rien, et la mesure —
48 — tient : la colonne ne bouge pas d'un dixième entre les deux poses.

Le bas de la pile, lui, varie vraiment d'une pose à l'autre : 170 fermé, 120
ouvert couché. C'est le vrai gain du canal, celui qu'aucune constante ne
pouvait rendre. L'axe, la mesure l'avait déjà juste.

**Le pli, en revanche, n'est pas venu.** `divisions` est vide dans toutes les
poses du simulateur — fermé, semi-ouvert, ouvert —, et le passage de l'une à
l'autre n'y change rien. Une requête par défaut ne rend que les régions
**actives**, et rien ne dit qu'une charnière sans rupture visible en soit une.
Le champ `fold` reste donc en place, et vide : il coûte une ligne, et c'est la
seule voie qu'aura une mise en page qui veut éviter la charnière, puisque
`MediaQuery.displayFeatures` ne sera jamais rempli sur iOS. À revérifier sur
l'appareil.

C'est aussi pourquoi l'air sous une région annoncée n'est pas celui d'une
mesure — huit points sous ce que le système se réserve, trente-deux sous des
glyphes vus sur une capture.

Deux garde-fous, parce que la réponse vient de l'extérieur. Le premier est un
`#if compiler(>=6.4)` autour des *reserved regions* : le symbole n'existe pas
avant le SDK 27.1, et `#available` seul ne le cacherait pas au compilateur —
sans ce test, le projet ne se construirait plus sur un Xcode plus ancien.
`compiler`, et surtout pas `swift` : `#if swift(>=x)` interroge la version du
**langage**, qui ne prend que des valeurs comme 4.2, 5 ou 6, si bien que
`swift(>=6.4)` est faux partout. Écrit ainsi au départ, le bloc n'a jamais été
compilé et les régions revenaient vides sur un appareil où elles existent. Le
second est dans `WindowRegionsService.parse` : une pile qui prendrait plus du
tiers de la fenêtre, ou un axe au milieu de l'écran, sont écartés. Le cadre de
la barre d'état est le seul des trois dont on ne sache pas encore ce qu'il vaut
quand elle passe debout, et une valeur écartée n'est pas une panne : l'appelant
garde sa mesure.

La sonde écrit deux lignes plutôt qu'une : les régions retenues, et **la
réponse du natif**, à clés triées — la carte que rend le canal change d'ordre
d'un appel à l'autre, et la sonde croyait à quatre fenêtres différentes là où
il n'y en avait qu'une. Le natif y joint de quoi lire un tableau vide : la
version de Swift qui l'a compilé, celle du système, et si les régions ont été
demandées ou si le `#if` les a sautées. « Aucune région annoncée » a trop de causes
pour se lire seul — pas d'iOS, un binaire construit sans le canal, un SDK
antérieur à 27.1, une vue pas encore posée, ou une cote écartée par `parse`.
La seconde ligne les distingue.

Deux `ValueNotifier`, et leur ordre compte : les régions sont publiées
**avant** la réponse. Un notifieur prévient ses auditeurs sur-le-champ, si bien
que la sonde, qui écoute la réponse pour écrire son relevé, lisait des régions
encore vides — et comme une seule réponse suffit à l'appareil, elle ne
repassait jamais. Le relevé affichait « aucune région annoncée » sous une
réponse qui en contenait deux. `test/core/window_regions_test.dart` tient
l'ordre par un auditeur, et la sonde écoute désormais les deux notifieurs,
ce qui rend l'ordre indifférent.

`test/core/window_regions_codec_test.dart` fait passer la réponse mesurée par
le codec standard avant de la lire : le canal rend des `Map<Object?, Object?>`
jusque dans les rectangles imbriqués, là où les autres tests donnent des
littéraux typés. Il ne dispense pas de regarder la réponse : le canal a un
jour cessé d'envoyer les cotes de la vue, sans lesquelles `parse` ne retient
rien, et le test les fournissait de sa main. La sonde marque donc « rien
retenu » quand une réponse pleine ne donne aucune région — c'est la seule
façon de distinguer un natif qui se tait d'un natif qu'on écarte.

La première demande part de `main()`, avant la première image : la scène n'est
pas encore active, la fenêtre pas encore clé, la barre d'état vaut zéro. Le
service redemande donc une fois la fenêtre posée, et c'est cette réponse-là
qui compte. La sonde écoute la réponse pour la même raison : elle arrive après
son premier relevé.

C'est bien l'ordre des choses — la mesure d'abord, l'annonce en raffinement.
Hors d'iOS le canal n'existe pas, sur un binaire construit avec un SDK plus
ancien il répond sans régions, et le menu debout se pose exactement où il se
posait avant. Une proposition est ouverte chez Flutter pour alimenter
`displayFeatures` depuis ces mêmes régions (flutter/flutter#192515) ; si elle
atterrit, la moitié « pli » du canal devient inutile.

Ce que le canal ne donne pas, et qu'il faut savoir : le regroupement et le
débordement automatiques qu'iOS fait dans une barre d'outils debout. Ils
viennent de `UINavigationController` et `UITabBarController`, pas des régions
— une barre montée à la main ne les obtient pas, et le menu s'en passe (voir
docs/06, « Le menu debout »).

Ce qui reste à faire quand l'appareil sera là (23 octobre 2026) : les visuels
du magasin pour l'écran intérieur (`store/README.md`) et, si la place le
justifie, une famille de widget plus grande que `systemMedium`.

## Performance
- Listes en `Sliver*` / `GridView.builder` (virtualisées), `RepaintBoundary` sur les cartes.
- Requêtes drift ciblées + streams ; pas de rechargement global.
- Testé conceptuellement pour 10 / 100 / 1 000 plantes : les requêtes *Aujourd'hui* sont indexées sur `care_schedules.next_due_at`.

## Observabilité / analytics (prévus)
`Analytics` et `CrashReporter` interfaces dans `core/observability`, implémentation no-op en P1. Événements : `plant_created`, `watering_logged`, `photo_added`, `location_created`, `reminder_completed`. Jamais de notes, photos ou noms.

## Tests
- `test/domain/care_engine_test.dart` : calculs d'échéances (fixe, saisonnier, météo, manuel, retards).
- `test/domain/weather_test.dart`, `weather_trend_test.dart`, `outdoor_alert_test.dart`,
  `region_climate_test.dart` : lecture d'Open-Meteo, conseil de la pluie,
  correction météo d'un intervalle, gel et chaleur, zone de rusticité.
- `test/data/*_repository_test.dart` : repositories sur base en mémoire (créer plante, arroser, archiver / restaurer, recherche).
- `test/domain/reminder_planner_test.dart` : regroupement et texte des notifications.
- `test/app/window_test.dart` : la fenêtre courante, mesurée à chaque appel et
  non au démarrage — la réponse change au pli.
- `test/app/window_probe_test.dart` : la sonde de fenêtre écrit sans qu'on lui
  demande rien, attend la première image, et ne se répète pas.
- `test/design_system/tab_rail_test.dart` : où le menu se met debout, ce qu'il
  fait une fois debout (bord, bande réservée, cibles, bulle), et ce qu'il
  change quand le système annonce sa géométrie.
- `test/core/window_regions_test.dart` : la lecture des régions réservées, et
  surtout ses refus — une cote invraisemblable disparaît au lieu de déplacer
  le menu.

## La météo (`domain/weather/`, `features/weather/`)
Un seul appel sert tout : `weatherWindowProvider` demande trois jours passés,
aujourd'hui et quatre jours à venir, et se rafraîchit toutes les heures. La
ligne du jour, les prévisions, la pluie déjà tombée, la tendance des routines
et les avertissements en sortent — pas cinq requêtes pour cinq écrans.

Il vit dans `app/providers.dart`, à côté de l'hémisphère, et non dans la
fonctionnalité météo : les dépôts en dépendent. Une routine en stratégie
météo recalcule son échéance au moment où elle est complétée, sans rien
savoir de l'écran qui l'a demandée — d'où un `WeatherTrend? Function()`
passé aux dépôts, lu et non observé, exactement comme `southernHemisphere`.

Quatre pièces pures, toutes testées sans réseau :

- `WeatherAdvisor` : la pluie tombée (≥ 5 mm sur la fenêtre passée) vaut un
  arrosage, la pluie annoncée le reporte. La première l'emporte sur la
  seconde.
- `WeatherTrend` : la moyenne des maximums et le cumul de pluie de la
  fenêtre, réduits à un multiplicateur d'intervalle borné à 0,6–1,6. La
  météo corrige la fiche de l'espèce, elle ne la remplace pas.
- `OutdoorAlertAdvisor` : gel (≤ 2 °C sous abri) et chaleur (≥ 32 °C) des
  trois prochains jours, croisés avec le minimum supporté et la plage idéale
  de chaque fiche. Une alerte par sorte, celle du jour le plus dur.
- `RegionClimate` : la nuit la plus froide et le jour le plus chaud d'une
  année ordinaire, tirés de trois ans d'archives et gardés dans les
  préférences six mois. De là, la zone de rusticité, qui classe les
  propositions de plantes pour l'extérieur. Ce qui part à l'IA, ce sont deux
  températures et une zone — jamais la ville, jamais les coordonnées.

## La maison (`domain/home/`, `features/home_climate/`)
La météo dit ce qu'il fait dehors ; un capteur de la maison dit ce qu'il
fait dans le salon. L'application en lit deux grandeurs, la température et
l'humidité relative, et rien d'autre. Deux maisons les donnent : Apple
Maison, par HomeKit, et Google Home, par les Home APIs.

- `HomeClimateService` : trois questions — l'accès accordé ou non, la liste
  des accessoires qui mesurent l'une ou l'autre, la mesure de l'un d'eux.
  Une implémentation par plateforme, toutes deux sur un `MethodChannel` et
  sur le même dictionnaire (`ChannelHomeClimateService` : `id`, `name`,
  `room`, `home`, `temperature`, `humidity`, `at`, `error`).
  `HomeKitClimateService` (`ch.vergasta.plant/home_climate`) est muette hors
  iOS ; le natif est dans `ios/Runner/HomeClimateChannel.swift`
  (`HMHomeManager`, délai de dix secondes, dernière valeur connue si
  l'accessoire ne répond pas). `GoogleHomeClimateService`
  (`ch.vergasta.plant/google_home_climate`) vaut pour iOS et Android — voir
  « Google Home » plus bas.
- `MultiHomeClimateService` les rassemble : l'écran ne voit qu'un service et
  une liste. Chaque capteur porte sa maison (`HomeSensor.source`), un
  identifiant n'étant unique que chez elle, et c'est cette marque qui
  renvoie une lecture à la bonne — d'où `read(HomeSensor)` plutôt que
  `read(String)`, et `HomeSensor.key` (`google:N1`) pour reconnaître un
  capteur d'un écran à l'autre. Une maison muette ici — Apple Maison sur
  Android, Google Home sans son SDK — est écartée à la construction, et
  n'apparaît ni à l'onboarding ni dans les réglages. Une maison refermée
  par son drapeau y garde pourtant sa ligne, si `AppConfig.googleHomeSoon`
  le veut : son nom, l'étiquette « Bientôt » (`FloraTag`) et rien à toucher
  — voir « Google Home » plus bas.
- Le choix se fait dans une feuille (`showHomeSensorPicker`) : la plateforme
  d'abord quand l'appareil lit les deux, puis la maison quand la plateforme
  en a plusieurs, puis les accessoires de cette maison pièce par pièce, avec
  ce que chacun mesure. Un seul capteur dans la maison, et il est retenu
  sans question.
- Une demande d'accès à la fois : à l'onboarding, `showHomeSourcePicker`
  fait dire laquelle brancher avant que le système ne demande quoi que ce
  soit — deux fenêtres coup sur coup, et personne ne sait laquelle il vient
  de refuser. Dans les réglages, chaque maison a son bouton ; celle qui a
  déjà donné ses capteurs n'en a plus.
- Deux capteurs, un par grandeur : celui de la température (`home_sensor`)
  et, s'il n'est pas le même, celui de l'humidité (`home_humidity_sensor`).
  Sans second capteur, l'humidité vient du premier, s'il la mesure ; à
  l'onboarding, un capteur sans hygromètre fait demander un hygromètre.
- Le capteur retenu est en préférences (`home_sensor`,
  `id|nom|pièce|maison|température|humidité|plateforme`) ; la plateforme
  vient en dernier, et une préférence écrite avant Google Home se relit
  sans elle — c'était Apple Maison. La mesure, elle, n'est jamais gardée :
  elle se relit toutes les quinze minutes (`homeReadingProvider`).
- Google Home tient une session sur un compte Google, et ce qui s'ouvre doit
  pouvoir se fermer : la déconnexion (`HomeClimateService.canDisconnect`,
  `disconnect`) emporte ensemble la session côté natif, les capteurs de
  cette maison en préférences et sa liste à l'écran. Ce que le compte a
  accordé ne part pas avec — le SDK est explicite, `disconnect` ne révoque
  pas le jeton —, alors l'écran le dit avant de déconnecter et mène au compte
  après (`AppConfig.googleAccountUrl`, la page des applications connectées),
  par une ligne qui reste. Apple Maison n'a rien de tel : son accès est une
  permission du système, qui se retire dans les Réglages.
- `HomeClimateAdvisor` compare la mesure aux fiches des plantes d'intérieur
  (celles qui ne sont pas dans un emplacement « extérieur », et seulement
  celles de la pièce si un emplacement porte le nom de la pièce du capteur) :
  air sec quinze points sous le minimum de la plage d'hygrométrie de la fiche
  (`HomeClimateAdvisor.tolerance`), soit 45 % pour une espèce qui en demande
  60 et 35 % pour une qui se contente de 50 ; air humide au-delà de 70 % dans
  la pièce, et pour les espèces dont la mesure dépasse de quinze points le haut
  de leur plage ; froid sous le minimum de l'espèce ; chaleur au-delà de sa
  plage idéale, ou de 30° sans plage. La marge existe parce qu'une plante n'est
  pas en peine au premier point manquant — d'où « Rien qui gêne cette espèce »
  sur la carte, et non « dans la plage », que la fiche d'entretien imprime en
  toutes lettres juste au-dessus.
- La carte des conseils ne paraît qu'une fois par jour
  (`HomeTipsNoticeController`) : un salon à 25° l'est encore ce soir, et les
  plantes signalées le sont toujours — la redonner à chaque passage sur
  l'écran du matin serait du bruit. Le jour de l'apparition est gardé en
  préférences (`home_tips_shown_at`), donc relancer l'application ne la
  ramène pas ; l'état du provider, lui, dit seulement si elle est à l'écran,
  le temps qu'on la lise, et la croix l'enlève tout de suite. La mesure
  reste lisible sur la pilule de la maison, et l'écart à l'espèce sur la
  carte « Chez vous » de chaque fiche.
- Les HomePod sont invisibles pour HomeKit vu d'une app tierce (Apple les
  réserve à Maison) : leurs capteurs ne se lisent pas, et l'application ne
  cherche pas à les contourner.
- Le diagnostic joint la mesure à la question, pour une plante qui n'est pas
  dehors, et le dit sous le champ des symptômes. Ce que le capteur ne donne
  pas — l'humidité d'un thermostat seul, tout sans capteur ou pour une plante
  dehors — se demande là aussi, deux champs facultatifs dans le groupe
  « Observations », dans l'unité de la personne (`ReportedClimate`, converti
  en Celsius, hors plage ignoré). Le modèle sait ce qui est mesuré et ce qui
  est donné.
- Réglages d'Apple Maison : `NSHomeKitUsageDescription` dans `Info.plist`,
  entitlement `com.apple.developer.homekit`, capability *HomeKit* sur l'App
  ID. Sans capteur dans la maison, l'étape d'onboarding se passe d'un geste.

### Google Home
Les mêmes deux nombres, lus sur les Home APIs, sur iPhone comme sur Android.
Livré, `AppConfig.googleHomeEnabled` à vrai : le Kotlin compile contre le
SDK réel, et le Swift lit de vrais capteurs sur un iPhone, avec le client
OAuth d'un projet déclaré.

Ce que le drapeau ne règle pas : les Home APIs plafonnent à **cent comptes**
tant que le projet n'est pas enregistré dans la console développeur Google
Home, et cette console n'accepte pas encore d'inscription. C'est le plafond
de leur beta publique, et il tombera avec la disponibilité générale. Au cent
unième compte, la demande d'accès est refusée, et l'écran dit alors ce que
dit un refus (`homeClimateDeniedGoogle` renvoie aux autorisations de
l'application Google Home) : ce ne sera pas la vraie raison, mais rien dans
l'API ne distingue les deux. Les deux signaux à suivre sont les notes de
version du SDK et la mention « The Google Home Developer Console is not yet
available for registration » sur la page OAuth iOS de Google. Publier le
client OAuth en production, au passage, retire l'avertissement
« application non vérifiée » — aucun scope n'est demandé, la vérification
n'a rien à examiner — mais ne touche pas au plafond.

Côté Android, il n'y a pas de session à fermer : les Home APIs n'y exposent
que l'autorisation du compte, sans méthode pour la rendre. La déconnexion y
vaut donc l'oubli des capteurs, et le canal n'a qu'un refus à oublier pour
que la question puisse se reposer ; le retrait, lui, se fait dans le compte,
comme sur iPhone.

Refermer la maison ne demande qu'une ligne : `googleHomeEnabled` à faux, et
`AppConfig.googleHomeSoon` laisse à sa place, dans les réglages, la ligne
« Google Home · Bientôt » — une étiquette sans rien à toucher.

Le SDK, lui, est nécessaire à la construction iOS drapeau haut ou bas : le
paquet local est référencé par `ios/Runner.xcodeproj`
(`tool/ios/google_home_sdk.sh`, appelé par le *Post-clone script* de
Codemagic), et la cible de déploiement est à iOS 17. Côté Android, il n'y a
pas de référence dans le projet : un build sans `-PgoogleHomeRepo` compile
le jeu de sources muet, et le bouton « Connecter Google Home » répondra
« aucun capteur » — sur cette plateforme, le drapeau et l'option de build se
lèvent ensemble.

À la différence de HomeKit, les Home APIs ne sont pas dans le système. Leur
SDK ne se prend ni sur Maven Central, ni sur le dépôt Google, ni sur un
registre SwiftPM : il se télécharge depuis la console Google Home, pour un
projet déclaré, et se compile dans l'application. Tant qu'il n'y est pas, le
canal natif n'existe pas, et une maison qu'on ne peut pas lire ne se propose
pas. Le drapeau est donc la dernière ligne à changer, pas la première.

Pour la livrer :

1. Déclarer un projet développeur dans la [console Google Home](https://console.home.google.com),
   avec le client OAuth de l'application — l'empreinte SHA-1 de la clé de
   signature côté Android, l'identifiant d'équipe et le bundle côté iOS.
2. Télécharger le SDK depuis la console. Les deux archives sont aussi dans
   des seaux publics, ce qui permet de vérifier une version sans se
   connecter : `home_sdk_android` et `home_sdk_ios` du projet
   `home-api-public-beta`.
   - Android (`home.android.sdk_1_10_1.zip`) : l'archive **est déjà un dépôt
     Maven** (`com/google/android/gms/play-services-home/17.1.0/…`). La
     dézipper et donner le chemin suffit :
     `flutter build apk -PgoogleHomeRepo=<chemin>`.
     `android/build.gradle.kts` ajoute alors ce dossier aux dépôts, et
     `app/build.gradle.kts` ajoute les deux artefacts en 17.1.0 plus le jeu
     de sources `src/googleHome/kotlin` à la place de
     `src/noGoogleHome/kotlin`. Les deux jeux donnent `GoogleHomeChannel` et
     `HostActivity` : l'un parle aux Home APIs et fait de `MainActivity` un
     `FlutterFragmentActivity` (la demande d'autorisation veut un
     `ActivityResultCaller`), l'autre ne fait rien et laisse l'activité de
     Flutter telle quelle. `kotlinx-coroutines` vient en dépendance
     transitive du SDK, rien à déclarer. minSdk 24.
   - iOS : `tool/ios/google_home_sdk.sh` fait le travail — il télécharge
     l'archive, la décompresse dans `vendor/GoogleHomeSDK` et répare les
     trois défauts qu'elle porte. Puis, dans Xcode,
     `File › Add Package Dependencies › Add Local › vendor/GoogleHomeSDK`,
     avec **Runner** dans la colonne *Add to Target* des deux produits :
     laissée à *None*, la référence s'écrit sans lier quoi que ce soit, et
     `canImport` reste faux — un build vert qui ne prouve rien.

     Ce que le script répare : l'archive porte des attributs
     `com.apple.quarantine` que `tar` restaure et qui font refuser le dossier
     à Xcode, et ses fichiers sont en lecture seule, jusqu'à interdire de
     retirer ces attributs.

     Ce qu'il ne répare pas, et qui se règle ailleurs :
     `GoogleHomeTypes.framework` n'a pas d'`Info.plist`, étant une
     bibliothèque statique dans un dossier `.framework` — elle est liée à la
     compilation, pas faite pour être copiée. Xcode l'embarque quand même,
     sans distinguer statique de dynamique, et l'outillage Flutter, qui
     inspecte le `.app` construit, échoue sur le fichier manquant. Fabriquer
     cet `Info.plist` est pire : le framework passe alors pour signable, et
     la signature échoue sur une archive `ar` (`signature-collection
     failed`). La cible Runner porte donc une dernière phase de build,
     « Retirer GoogleHomeTypes du bundle », qui supprime cette copie avant
     la signature. C'est la bonne réponse, pas un contournement : cette
     copie ne sert à rien.

     Le dossier du paquet doit rester à la racine, pas sous `ios/` : Xcode
     refuse un paquet local voisin du `.xcodeproj`, où vit déjà le paquet
     généré de Flutter, avec un « Cannot select this directory ».
     `ios/Runner/GoogleHomeChannel.swift` est derrière
     `#if canImport(GoogleHomeSDK)` : sans eux, il se compile en un canal qui
     ne s'enregistre pas. Capabilities *App Attest* et *App Groups* sur l'App
     ID — App Groups y est déjà, celui du widget (`group.ch.vergasta.plant`)
     sert aussi à Google Home, il n'y a donc qu'App Attest à ajouter, d'un
     clic dans l'onglet *Signing & Capabilities* de la cible Runner. Le SDK
     ne se déploie pas sur le simulateur. Il demande **iOS 17**,
     d'où la cible de déploiement du projet, montée de 15 (et 16 pour le
     widget) à 17 : l'application abandonne les iPhone 8, 8 Plus et X, dont
     iOS 16 est la dernière version. C'était le prix d'entrée des Home APIs
     sur iPhone.
3. Renseigner `GoogleHomeClientID`, `GoogleHomeTeamID` et
   `GoogleHomeAppGroup` dans `ios/Runner/Info.plist` (les clés sont en
   commentaire à côté de `NSHomeKitUsageDescription`, avec le groupe déjà
   rempli) ; sans elles, le canal répond « pas de maison ici » plutôt que
   d'ouvrir une session à moitié configurée.
4. Passer `AppConfig.googleHomeEnabled` à vrai, et en dernier : sans le
   SDK, le bouton « Connecter Google Home » répondra toujours « aucun
   capteur » ; sans l'enregistrement de la console développeur, il lâchera
   au cent unième compte.

Ce que le canal lit : les appareils, les pièces et les maisons à plat, puis
recollés par identifiant (`HomeDevice.roomID`, `structureID`). Trois types
portent l'air d'une pièce, et pas de la même façon — c'est la surprise de
l'API : le capteur de température a `temperatureMeasurementTrait`,
l'hygromètre a `relativeHumidityMeasurementTrait`, mais le thermostat n'a
aucun trait de mesure : sa température de pièce est `localTemperature`, sur
`thermostatTrait`. Un type de plus s'ajoute dans `measures`. Les trois
valeurs sont des entiers Matter en centièmes (`Int16` pour un degré,
`UInt16` pour un pour cent), donc divisés par cent, sans deviner. Une valeur
absente du cache se redemande une fois par `forceRead`, que les trois traits
savent faire.

Ce qui n'est pas la même promesse qu'Apple Maison : HomeKit lit les
accessoires sur l'appareil, les Home APIs passent par le compte Google de
la personne. L'écran le dit, maison par maison (`homeClimateAppleNote`,
`homeClimateGoogleNote`), et le texte commun ne promet plus qu'une chose,
vraie des deux : la mesure ne quitte pas l'application.

## Le relevé de la maison (`domain/room/`, `features/room_scan/`)

Livré, sur iPhone et iPad à LiDAR (`AppConfig.roomScanEnabled`, qu'on
peut refermer sans rien effacer). Le dessein, le modèle de lumière et les
paliers sont dans [docs/17](17-releve-de-la-maison.md) ; ici, ce qui tient
au code.

- **Le canal** `ios/Runner/RoomScanChannel.swift`
  (`ch.vergasta.plant/room_scan`), sur le patron de `HomeClimateChannel` :
  `support` rend ce que l'appareil sait faire (`lidar`, `sections`,
  `structure`), `scan` présente `RoomCaptureView` par-dessus la fenêtre
  Flutter, avec le coaching du système, et au « Terminer » encode le
  `CapturedRoom` en JSON à l'endroit demandé ; `scanStructure` (iOS 17)
  enchaîne les pièces dans le même repère — « Pièce suivante » arrête la
  session sans mettre ARKit en pause et la relance une fois la pièce
  rendue —, les assemble par `StructureBuilder` et écrit un fichier par
  pièce dans le dossier demandé (`paths`). Annuler rend `nil` ; un relevé
  qui échoue rend `error` sans `paths`. Aucun entitlement : RoomPlan et
  ARKit sont des frameworks système, liés à l'import.
- **Le nord.** RoomPlan ne le donne pas. `NorthEstimator` lit la boussole
  (`CLLocationManager`, cap vrai si la position est autorisée, magnétique
  sinon) et le lacet de la caméra ARKit au même instant, et garde la moyenne
  circulaire de leur écart ; moins de cinq mesures, ou des mesures qui se
  contredisent, et il ne rend rien. Le cap d'une direction se lit comme
  `atan2(x, −z)` des deux côtés du canal (`ScannedRoom.headingOf`). Le
  résultat vaut dix à quinze degrés : l'écran des fenêtres le montre et
  demande de le confirmer, et l'orientation confirmée prime.
- **Côté Dart**, `RoomScanService` (`data/services/room_scan_service.dart`) :
  `ChannelRoomScanService` avale `PlatformException` et
  `MissingPluginException` en réponse vide, `UnavailableRoomScanService`
  partout ailleurs. `RoomScanStore` tient les fichiers dans
  `Documents/rooms/`. Le lecteur `RoomPlanParser` (`domain/room/`) ne lit
  que ce que le modèle consomme et tolère ce qu'il ne connaît pas ; le
  format du JSON est celui du `Codable` de RoomPlan, et la fixture
  `test/domain/fixtures/roomplan_diorama.json` en fixe une forme — à
  confirmer sur un appareil, palier 0 de docs/17.
- **Le modèle** est pur : `RoomLightModel.lightAt` rend un `LightNeed` en
  chaque point, `RoomFitAdvisor.survey` lit la pièce une fois — lumière
  selon la latitude du lieu de la météo, air qui bouge, radiateurs posés —
  et `placeIn` classe les places d'une fiche sur ce relevé ; c'est ce qui
  permet de juger tout le jardin sur la même grille (« Le jardin dans
  cette pièce »). Les seuils sont calibrés sur la pièce du diorama : les six
  emplacements de docs/13 rendent leurs six crans, ce que
  `test/domain/room_light_model_test.dart` verrouille — sans latitude, à
  45° de soleil ; le test dit aussi ce que Paris et les tropiques changent.
- **Le gating** tient en trois niveaux, comme la maison : le drapeau et la
  plateforme dans `isSupported`, le LiDAR demandé une fois au canal
  (`roomScanAvailableProvider`), et les écrans qui n'existent pas sans lui —
  la ligne de Profil, la section « Plan de la pièce » de la fiche
  emplacement, l'entrée « Où la poser » sous le diorama ; la carte de la
  fiche plante, elle, n'existe que s'il y a un relevé autour de la plante
  (`plantRoomPlaceProvider`), ce qui suppose déjà le LiDAR.
- **Le relevé et l'emplacement.** Un relevé se lie à un emplacement dès le
  relevé : celui d'où l'on part (fiche emplacement, `scan(locationId:)`),
  sinon celui qui porte le nom de la pièce reconnue, s'il est seul et pas
  encore décrit (`RoomScanController._locationNamed`). Lié, il propose
  de renseigner l'orientation de l'emplacement (celle de la plus grande
  fenêtre) et sa lumière (la plus fréquente au sol, ramenée aux trois
  crans de `locations.light` par `lightCodeFor`), sans toucher à ce qui
  est déjà rempli (`roomFillSuggestionProvider`, la même ligne sur la
  fiche emplacement et sur la feuille du relevé). Et si le capteur de la maison porte le nom de la pièce ou de son
  emplacement, « Où la poser » montre sa mesure sous les places, avec le
  même verdict que la carte « Chez vous ».

