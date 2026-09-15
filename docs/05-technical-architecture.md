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
| Espèces | GBIF (`SpeciesService`) | gratuit, sans clé, taxonomie de référence, images d'observations avec attribution |
| Identification | cascade `CascadeIdentifier` : modèle local (à venir) puis Pl@ntNet (`PlantIdentifier`) | clé de l'utilisateur, repli coupable, voir [09](09-plant-recognition.md) |
| Diagnostic | AI Services d'Infomaniak, route compatible OpenAI (`PlantDiagnoser`) | clé de l'éditeur au build, modèle choisi au build, sans plafond |
| Complément de fiche | AI Services d'Infomaniak (`CareCompleter`) | seulement quand le catalogue n'a que des repères généraux ; nom scientifique seul, réponse gardée sur l'appareil |
| Météo | Open-Meteo (`WeatherService`) : prévisions et jours passés en un appel, archives sur trois ans pour le climat du lieu | gratuit, sans compte |
| Climat de la maison | HomeKit, par un canal natif (`HomeClimateService` → `ios/Runner/HomeClimateChannel.swift`) | iPhone et iPad seulement ; lecture de deux caractéristiques, rien d'écrit, rien ne sort de l'appareil |
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

## Apple Maison (`domain/home/`, `features/home_climate/`)
La météo dit ce qu'il fait dehors ; un capteur HomeKit dit ce qu'il fait
dans le salon. L'application en lit deux caractéristiques, la température
et l'humidité relative, et rien d'autre.

- `HomeClimateService` : trois questions — l'accès accordé ou non, la liste
  des accessoires qui mesurent l'une ou l'autre, la mesure de l'un d'eux.
  Implémentation `HomeKitClimateService` sur un `MethodChannel`
  (`ch.vergasta.plant/home_climate`), muette hors iOS ; le natif est dans
  `ios/Runner/HomeClimateChannel.swift` (`HMHomeManager`, délai de dix
  secondes, dernière valeur connue si l'accessoire ne répond pas).
- Le choix se fait dans une feuille (`showHomeSensorPicker`) : la maison
  d'abord, quand HomeKit en a plusieurs, puis les accessoires de cette
  maison pièce par pièce, avec ce que chacun mesure. Un seul capteur dans la
  maison, et il est retenu sans question.
- Deux capteurs, un par grandeur : celui de la température (`home_sensor`)
  et, s'il n'est pas le même, celui de l'humidité (`home_humidity_sensor`).
  Sans second capteur, l'humidité vient du premier, s'il la mesure ; à
  l'onboarding, un capteur sans hygromètre fait demander un hygromètre.
- Le capteur retenu est en préférences (`home_sensor`, `id|nom|pièce|maison`) ; la
  mesure ne l'est jamais, elle se relit toutes les quinze minutes
  (`homeReadingProvider`).
- `HomeClimateAdvisor` compare la mesure aux fiches des plantes d'intérieur
  (celles qui ne sont pas dans un emplacement « extérieur », et seulement
  celles de la pièce si un emplacement porte le nom de la pièce du capteur) :
  air sec sous 45 % pour les espèces à forte humidité, sous 30 % pour les
  autres ; air humide au-delà de 70 % ; froid sous le minimum de l'espèce ;
  chaleur au-delà de sa plage idéale, ou de 30° sans plage.
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
- Réglages : `NSHomeKitUsageDescription` dans `Info.plist`, entitlement
  `com.apple.developer.homekit`, capability *HomeKit* sur l'App ID. Sans
  capteur dans la maison, l'étape d'onboarding se passe d'un geste.
