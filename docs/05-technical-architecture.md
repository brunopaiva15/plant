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

## La fenêtre : téléphone, tablette, pliable (`app/orientation_lock.dart`)

Sur téléphone, l'application se tient en portrait : chaque écran est une
colonne, et le paysage n'apporterait qu'une mise en page étirée. Sur tablette,
elle ne verrouille rien — iPadOS attend qu'une application tourne et cohabite
avec une autre, et le refuser est un motif de rejet. La limite est à 600 points
de côté le plus court ; au-delà de 700 points de large, le contenu rend son
surplus en marges (`readableInset`, `design_system/components/page_scaffold.dart`).

L'iPhone Duo tient les deux rôles dans la même séance : fermé, son écran
extérieur fait environ 466 points de large ; ouvert, l'écran intérieur en fait
environ 669, et rien n'a été relancé entre les deux. (Apple publie les pixels —
1398 × 2034 dehors, 2007 × 2853 dedans pour le magasin — pas les points ; ces
deux nombres s'en déduisent au facteur 3 et restent à confirmer sur
l'appareil. Si l'écran intérieur passait sous la limite des 600, c'est la
limite qu'il faudrait corriger, pas le mécanisme.) Le verrou n'est donc plus une décision de
démarrage mais un état — `OrientationLock` écoute `didChangeMetrics` et le pose
ou le retire à chaque pli —, et aucune taille n'est gardée : `isCompactWindow()`
mesure la vue implicite à chaque appel. Le viseur intégré suit la même règle
(`features/plants/presentation/inline_camera.dart`) : son verrou de capture se
défait quand l'appareil s'ouvre, faute de quoi une photo prise après le pli
sortirait couchée.

Côté iOS, trois points valent d'être connus :

- `UIRequiresFullScreen` ne doit pas revenir dans `Info.plist`. La clé dit au
  système que l'application veut tout l'écran à l'ancienne manière, et la tient
  hors de l'adaptation — fermée comme ouverte.
- L'écran intérieur n'honore pas `UISupportedInterfaceOrientations` : la
  déclaration portrait ne vaut que pour l'écran extérieur. Une page doit savoir
  tourner, pas s'y opposer.
- `TARGETED_DEVICE_FAMILY = "1,2"` était déjà posé pour l'iPad ; c'est cette
  valeur qui ouvre à l'écran intérieur les mises en page larges d'UIKit.

La construction demande le SDK iOS 27.1 (Xcode 27.1, en bêta depuis le
18 septembre 2026, sur un Mac Apple Silicon en macOS 26.6 ou plus récent). En
deçà, iOS applique ses replis de compatibilité : la fenêtre n'atteint pas les
bords de l'écran intérieur et reste tenue en une colonne. La cible de
déploiement, elle, ne bouge pas : iOS 17.

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
- `test/app/orientation_lock_test.dart` : le verrou de portrait posé et retiré
  quand la fenêtre change de taille en cours de séance (pliable).

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
