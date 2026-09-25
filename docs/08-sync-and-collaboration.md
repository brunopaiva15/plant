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

## Un schéma distant en retard
Le projet Supabase peut avoir une version de retard : `supabase/schema.sql`
n'a pas été rejoué depuis la dernière colonne ajoutée. PostgREST refuse alors
la ligne entière pour ce seul champ (`PGRST204`, « Could not find the
'cutting_month' column of 'plants' »), et comme le cycle s'arrête à la
première erreur, toute la file d'envoi restait à quai — les autres tables
comprises.
- **À l'envoi**, la colonne inconnue est retirée et la ligne repart sans
  elle. Le champ ne monte pas, le reste passe. Ce qui a été retiré est oublié
  à chaque push : le schéma remis à jour se reprend tout seul, sans relancer
  l'application.
- **À la lecture**, le serveur ne renvoie pas ce qu'il n'a pas. Les colonnes
  absentes de la ligne distante gardent leur valeur locale, faute de quoi la
  ligne les viderait — un champ qui ne monte pas est un désagrément, un champ
  effacé est une perte. Une valeur mise à null ailleurs, elle, revient avec sa
  clé : seule l'absence de la clé vaut « garder ce qui est là ».
- **À l'écran**, Compte liste les colonnes en cause sous l'état de la
  synchronisation. Rejouer `supabase/schema.sql` les fait disparaître.

## Les fichiers des photos
La ligne et l'image voyagent séparément, et l'image coûte mille fois plus cher.
- **Téléversement seulement quand l'image change.** Une écriture qui ne touche
  qu'aux métadonnées le dit dans son payload d'outbox (`{"files": false}`) :
  renommer une photo pousse la ligne sans renvoyer l'original.
- **`storage_path` / `thumb_path` appartiennent au serveur.** Les colonnes
  locales du même nom désignent des fichiers de l'appareil : elles ne sont
  jamais poussées. Un push qui ne téléverse rien omet ces colonnes, et
  PostgREST laisse alors au serveur les siennes.
- **Téléchargement hors transaction.** Les fichiers d'un lot descendent avant
  que la transaction SQLite ne s'ouvre, et un échec ne fait échouer ni la
  ligne, ni les tables suivantes.
- **Rattrapage** (`SyncService.repairPhotoFiles`, au plus une fois par dizaine
  de minutes) : les photos dont le fichier manque sur l'appareil sont
  redemandées, au chemin que dit le serveur. Le repérage se fait sur le
  disque : quand rien ne manque, il ne coûte pas un octet de réseau.
- **Suppression** : les objets du bucket partent avec la photo (suppression
  logique) ou avec la plante (suppression définitive, dont le payload de
  l'outbox porte le chemin puisque la ligne, elle, n'existe plus).

## Auth
`AuthRepository` : `LocalAuthRepository` (Phase 1) → `SupabaseAuthRepository` (Apple natif sur iOS, Google natif sur Android ; Google par le navigateur sur iPhone est codé mais pas livré, le bouton attend `AppConfig.googleSignInEnabled`). Pas de connexion par e-mail sur Auxine : un compte, c'est un identifiant Apple sur iPhone, un compte Google sur Android (`signInMethodProvider`, `account/application/sign_in_availability.dart`). Sur Android, tant que le client OAuth n'est pas renseigné (`AppConfig.googleWebClientId`), le compte reste local. La connexion se propose à deux endroits : une étape de l'onboarding, après le prénom, qui dit en deux phrases à quoi sert un compte et se passe d'un « Plus tard » ; et Profil › Se connecter, la ligne juste sous le nom, à tout moment. L'étape de l'onboarding n'est pas dessinée là où la connexion n'existe pas. À la première connexion, le jardin local est réattribué au compte (`owner_id`, `SyncService.claimGarden`) et toutes ses lignes sont mises en file de synchronisation. Dans la foulée, si le compte a déjà des jardins, ils sont proposés (`proposeExistingGardens`, `account/presentation/open_garden_sheet.dart`) : c'est le chemin d'une réinstallation, où l'installation neuve vient de créer un jardin vide et où les plantes, elles, sont restées dans celui d'avant.

### La première connexion
C'est le seul moment où le compte n'existe pas encore, et le seul que le
propriétaire du projet ne repasse jamais : ses comptes sont créés. Deux
choses s'y jouent, qui ne se voient pas ailleurs.

- **Le déclencheur `trg_new_user` s'exécute dans la transaction qui insère la
  ligne `auth.users`.** Ce qu'il laisse échouer emporte la création du compte,
  et GoTrue répond « Database error saving new user » — que l'application
  n'affiche que comme « Connexion impossible ». Le profil qu'il écrit n'en
  vaut pas le prix : `handle_new_user` replie le nom jusqu'à la chaîne vide et
  ignore le reste. Une connexion par Apple n'apporte pas de `display_name`, et
  son jeton d'identité ne porte pas toujours la revendication `email` : le
  `split_part(new.email, '@', 1)` d'avant donnait null à une colonne `not
  null`, et personne ne pouvait ouvrir de compte.
- **Ce qui suit l'échange du jeton n'est plus la connexion.** Apple ne donne
  le prénom qu'à la première autorisation, et l'onboarding n'a pas encore
  écrit celui qu'on tape (`_finish` vient après l'étape du compte) :
  `signInWithApple` écrit donc ce prénom, sur le réseau. La session, elle,
  existe déjà — l'échec de cette écriture est avalé, faute de quoi un appareil
  connecté s'entendrait dire que sa connexion a échoué, et se retrouverait
  connecté au lancement suivant.

Ces deux corrections vivent à des endroits différents : la seconde part avec
le binaire, la première demande de **rejouer `supabase/schema.sql`** dans
l'éditeur SQL du projet. Tant qu'il ne l'est pas, le projet garde l'ancien
déclencheur, et aucune version de l'application n'y changera rien.

## Le jardin ouvert
Un compte peut avoir accès à plusieurs jardins : le sien, et ceux qu'on lui a partagés. Un seul est **ouvert** à la fois — c'est lui que montrent toutes les listes.

- `activeGardenProvider` (`ActiveGarden`, dans `app/providers.dart`) porte l'identifiant ; `gardenIdProvider` n'est qu'une lecture de celui-ci, pour que les tests puissent le surcharger par une valeur fixe.
- Le choix est mémorisé (`active_garden_id`). Sans compte distant, ou quand un autre compte se connecte sur l'appareil, on retombe sur le jardin créé au premier lancement.
- `garden_id` désigne le jardin de l'appareil : celui dont le compte est propriétaire, le seul dont la ligne `gardens` parte d'ici. Il change quand ce jardin est supprimé — l'appareil adopte alors celui qui prend sa place, et s'en crée un neuf s'il ne reste que des jardins partagés.
- Ouvrir un jardin à nous depuis la proposition de connexion emporte le jardin vide que l'installation venait de créer : il est supprimé, et l'appareil adopte celui qu'on ouvre. Sans cela, « Mon jardin » apparaîtrait en double dans Mes jardins, l'un plein, l'autre vide.
- Changer de jardin reconstruit les dépôts (ils lisent tous `gardenIdProvider`), refait l'abonnement temps réel, et repart des curseurs de ce jardin — ils sont nommés `sync_cursor_{garden}/{table}`.
- La base locale contient les lignes de plusieurs jardins. Les dépôts qui interrogeaient toutes les plantes de l'appareil (journal, galerie récente, routines) filtrent désormais par jardin ; `enqueueEverything` ne met en file que le jardin de l'appareil, et la ligne `gardens` d'un jardin partagé n'est jamais poussée — elle appartient à quelqu'un d'autre.

## Collaboration
- `garden_members` : `owner` / `member` / `viewer`. Le domaine en fait `GardenRole` (`domain/sharing/garden_collaboration.dart`) : `canEdit`, `canManageMembers`.
- **Invitation par lien** : le propriétaire crée une invitation (`create_invite`), qui tire côté serveur un code de 8 caractères sans I, L, O, 0 ni 1. Le code est **à usage unique**, expire par défaut au bout de 14 jours, et peut être réservé à une adresse e-mail. L'invité n'a pas besoin d'avoir déjà un compte : la feuille « Rejoindre un jardin » lui propose « Continuer avec Apple » sur place, et accepte l'invitation dans la foulée (`accept_invite`). Là où la connexion n'existe pas (Android, pour l'heure), la feuille le dit d'emblée. Même règle sur Mes jardins et Membres : un bouton « Se connecter » vers l'écran Compte quand la connexion existe, le texte seul sinon (`signInAvailable`, dans `account/application`).
- Le lien envoyé est une adresse https (`…/join/<code>`) : cliquable dans un message, elle sert une page qui dit qui invite et propose « Ouvrir dans Auxine » (`auxine://join/<code>`). Le même lien est affiché en QR, et le scanner de l'application le reconnaît — `PlantLinks.decodeLink` accepte n'importe quel domaine, seuls les deux derniers segments du chemin comptent.
- Dans une messagerie, le lien s'accompagne d'une carte : le titre dit qui invite et dans quel jardin, la phrase dit ce que l'invitation donne, la vignette est celle d'Auxine (docs/06). Le nom du jardin part donc dans les caches de WhatsApp et de Telegram, et s'affiche pour tout un groupe — c'est le prix d'un lien qui se reconnaît. La page reste `noindex` et `no-store` : les moteurs n'en veulent pas, les robots d'aperçu, eux, ne lisent pas cette consigne.
- Sa base est `SHARE_BASE_URL` (`--dart-define`), et elle ne peut pas être l'URL Supabase : la passerelle force `text/plain` sur le HTML servi depuis `*.supabase.co`, sa protection contre les pages d'hameçonnage hébergées sous son nom. La page arrive alors en code source, accents cassés faute de `charset`. D'où le relais de `share-proxy/` — § Mise en place, étape 3.
- **Supprimer un jardin** (`delete_garden`, propriétaire seul) : la ligne part, et tout le reste avec elle par les cascades — plantes, journal, membres, invitations. Les fichiers du bucket, eux, ne connaissent pas les cascades : l'appareil les retire avant l'appel (`SyncService.removeGardenFiles`), tant que les règles du stockage le lui permettent encore. Puis il oublie le jardin à son tour (`FloraDatabase.purgeGarden` : les lignes, et les envois qui les attendaient) et ouvre celui qui prend sa place. Le dernier jardin d'un compte ne se supprime pas — l'application en ouvre toujours un.
- `my_gardens()` liste les jardins du compte avec le rôle, le nom du propriétaire, le nombre de membres et de plantes. `set_member_role`, `remove_member`, `leave_garden`, `revoke_invite` complètent la gestion — toutes `security definer`, propriétaire seul sauf `leave_garden`.
- Renommer son jardin écrit la ligne locale, la met en file et la pousse sans attendre le débounce de trois secondes. La liste venant de `my_gardens()`, un nom encore en file prime sur celui que renvoie le serveur : la réponse distante, antérieure à l'envoi, réécrivait sinon la ligne locale et le renommage repartait à l'envers dans la synchro.
- Chaque action et photo porte `user_id` ; la timeline affiche « · Laura » quand l'auteur n'est pas l'utilisateur courant (cache local `profiles`).
- Un `viewer` voit tout et ne peut rien écrire (RLS) ; l'UI masque les boutons d'ajout et les entrées d'édition, et les actions de soin refusent avec un message.

## Conseils de la communauté
Le partage d'un jardin met plusieurs personnes autour des mêmes plantes ;
celui-ci met tout le monde autour de la même **espèce**. Un conseil est
attaché à la clé du catalogue (`hoya-kerrii`), pas au nom tel qu'il est
écrit : deux personnes qui saisissent « Hoya kerrii » et « hoya kerrii »
lisent la même page. Le schéma est dans docs/04 ; ce qui suit est ce qui
change par rapport au reste de la synchronisation.

- **Rien ne descend dans SQLite.** Tout le reste de l'application est local
  d'abord ; ceci ne l'est pas, et ne peut pas l'être : ce n'est pas l'état du
  jardin, c'est ce que d'autres écrivent, et la liste se relit à chaque
  ouverture de la fiche. Hors ligne, la section le dit et propose de
  réessayer — le reste de la fiche d'entretien, lui, se lit sans réseau.
- **Lire sans compte, écrire avec.** `species_tips_for` est ouverte à la clé
  anonyme, les quatre autres fonctions à `authenticated`. Sans compte, la
  section se lit et la ligne « Publier un conseil demande un compte. » prend
  la place du bouton — avec « Se connecter » là où la connexion existe, le
  texte seul ailleurs (`signInAvailable`, comme Mes jardins et Membres).
- **Une personne, un conseil par espèce.** Publier une seconde fois remplace
  le premier : on revient sur ce qu'on a écrit plutôt que d'empiler. Sa carte
  est teintée, s'ouvre en modification, et porte la suppression.
- **Modération** : « Utile » compte les voix (une par personne, jamais sur son
  propre conseil), « Signaler » les signalements ; au troisième, le conseil
  cesse de paraître aux autres. Le seuil est écrit une fois côté serveur
  (`species_tip_reports_to_hide()`) et une fois côté client
  (`speciesTipReportsToHide`, qui sert au texte qui l'annonce).
- **Qui tranche ensuite** : *Profil › Modération* (`/settings/moderation`),
  visible des seuls comptes inscrits dans `moderators`. La liste des conseils
  signalés, et pour chacun : masquer, rétablir — ce qui efface ses
  signalements — ou retirer. Nommer un modérateur se fait dans l'éditeur SQL
  (docs/04) ; rien dans l'application ne peut s'accorder ce droit, et c'est
  pour cela que le drapeau n'est pas une colonne de `profiles`.
- **Où ça se voit** : au bas de `CareGuideBody`, donc sur la fiche
  d'entretien d'une plante, sur la page d'espèce de l'encyclopédie et dans
  l'aperçu du dénicheur — partout où la fiche se lit, sans qu'il faille
  posséder la plante.

## Écrans
| Écran | Rôle |
|---|---|
| Réglages › Mes jardins (`/settings/gardens`) | liste des jardins, bascule, renommage du sien, suppression du sien (jamais le dernier), départ d'un partagé, « Rejoindre un jardin » |
| Feuille « Vos jardins » | au retour d'une connexion, les jardins que le compte connaît déjà : en ouvrir un, ou rester sur celui de l'appareil |
| Réglages › Membres (`/settings/members`) | qui est dans le jardin ouvert, changement de rôle, retrait, invitations en attente |
| Feuille « Inviter quelqu'un » | rôle, e-mail facultatif, puis le code, le QR et le lien à partager |
| Feuille « Rejoindre un jardin » | code saisi ou reçu par lien, aperçu de l'invitation, acceptation |
| Feuille « Votre conseil » | écrire, remplacer ou retirer son conseil sur une espèce ; le compte des signes, et ce que la publication rend public |
| Réglages › Modération (`/settings/moderation`) | les conseils signalés ; masquer, rétablir, retirer — l'entrée ne paraît qu'aux modérateurs |

## Mise en place
1. Créer un projet Supabase, exécuter `supabase/schema.sql` dans l'éditeur SQL. Le fichier se rejoue tel quel à chaque mise à jour du schéma — le rejouer en entier est la façon de migrer. Symptôme d'un schéma en retard : « Colonnes inconnues du serveur » sur l'écran Compte, sous l'état de la synchronisation, qui les nomme en « table.colonne ». Le reste passe quand même — la colonne en trop est retirée de la ligne, et reprend sa place d'elle-même une fois le fichier rejoué —, mais ces champs-là ne quittent pas l'appareil. Les autres refus du serveur arrêtent la synchronisation et s'affichent au mot près sous « Erreur de synchronisation » (« new row violates row-level security » : une règle refuse ; « Bucket not found » : le stockage `plant-photos` n'existe pas).
2. Déployer la fonction Edge `share` (elle sert aussi les pages `/join/<code>`). Tant qu'elle ne l'est pas, un lien envoyé répond `{"code":"NOT_FOUND","message":"Requested function was not found"}`. Depuis un poste avec la CLI Supabase :
   ```bash
   cd <racine du dépôt>                             # le dossier qui contient supabase/
   supabase login
   supabase link --project-ref <ref du projet>      # la partie avant .supabase.co dans l'URL
   supabase functions deploy share --no-verify-jwt
   ```
   Les commandes se lancent depuis la racine du dépôt : la CLI cherche `supabase/functions/share/index.ts` sous le dossier courant, et retient le projet lié au même endroit (`supabase/.temp/`). Ailleurs, elle part avec une source vide et le déploiement échoue en `400 Entrypoint path does not exist` — un `WARNING: Docker is not running` peut apparaître au passage, il n'y est pour rien.

   `--no-verify-jwt` est indispensable (et déjà inscrit dans `supabase/config.toml`) : la page s'ouvre depuis un navigateur, sans clé. `SUPABASE_URL` et `SUPABASE_ANON_KEY` sont fournis à la fonction par Supabase, rien à configurer. À refaire à chaque changement du dossier `supabase/functions/share/` — la page y est habillée du design system de l'app, fonte et grain compris (docs/06).

   Pour vérifier, `curl -i https://<ref>.supabase.co/functions/v1/share/join/ABCD1234` : la page HTML « Lien indisponible » signale une fonction déployée qui répond (le code n'existe pas), le JSON `NOT_FOUND` une fonction toujours absente.
3. Déployer le relais public `share-proxy/` : la fonction sert la page, ce Worker Cloudflare la sert sous un domaine qui n'est pas `*.supabase.co` et lui rend son `content-type` (et sa politique de sécurité, que la passerelle remplace sinon par un `sandbox` qui empêcherait « Ouvrir dans Auxine » d'ouvrir l'application). La page reste dans `index.ts` : le Worker ne fait que relayer.
   ```bash
   cd share-proxy
   npx wrangler login
   npx wrangler deploy
   ```
   La fonction relayée est `SHARE_UPSTREAM`, dans `wrangler.toml` — à changer là, pas en argument : un `--var CLE:valeur` se fait couper en deux par PowerShell, qui prend la valeur pour une commande.
   Wrangler annonce l'adresse obtenue, en `https://auxine-share.<compte>.workers.dev` — c'est elle qui devient `SHARE_BASE_URL` à l'étape 5. Un domaine à soi se branche ensuite sur le même Worker (Cloudflare › Workers › Custom Domains) sans rien réécrire, et ouvre la voie aux Universal Links / App Links, qui feraient ouvrir l'application sans passer par la page.

   `curl -i https://auxine-share.<compte>.workers.dev/join/ABCD1234` doit répondre `content-type: text/html; charset=utf-8`. Tant qu'il répond `text/plain`, c'est l'adresse Supabase qui est interrogée, pas le relais.
4. Activer le fournisseur Auth **Apple** (voir ci-dessous) — et lui seul : pas d'e-mail, et Google n'est pas livré ; le jour où il l'est, l'activer aussi et ajouter l'URL de redirection `auxine://login-callback`.
5. Lancer l'app avec `flutter run --dart-define=SUPABASE_URL=… --dart-define=SUPABASE_ANON_KEY=… --dart-define=SHARE_BASE_URL=https://auxine-share.<compte>.workers.dev`. Sur la CI (Codemagic), ces `--dart-define` vont dans les arguments de build : sans les deux premiers, l'app tombe sur `LocalAuthRepository` et l'écran Compte ne propose aucune connexion ; sans le troisième, les liens partagés repartent vers Supabase et s'affichent en code source. Les liens déjà envoyés gardent l'ancienne adresse — ils sont écrits au moment du partage.

### Sign in with Apple
Le bouton « Continuer avec Apple » n'apparaît qu'avec un backend configuré, sur
iPhone et iPad. La connexion est native (feuille système, pas de navigateur) :
l'app reçoit un jeton d'identité signé par Apple et l'échange contre une session
Supabase (`signInWithIdToken`, nonce à l'appui). Le prénom donné par Apple à la
première connexion devient le nom affiché s'il n'y en avait pas encore.

Le binaire porte l'entitlement `com.apple.developer.applesignin`
(`ios/Runner/Runner.entitlements`, déclaré dans les trois configurations du
target `Runner` par `CODE_SIGN_ENTITLEMENTS`). Cet entitlement **exige que la
capability existe sur l'App ID** : sans elle, la signature échoue avec
« Provisioning profile doesn't include the Sign In with Apple capability », y
compris sur les builds locaux et la CI. C'est ce qui était arrivé une première
fois (commit c13bbcd), et la raison pour laquelle l'entitlement avait été retiré.

À faire une fois, avant le prochain build :
1. **Apple** : activer *Sign In with Apple* sur l'App ID `ch.vergasta.plant`
   (developer.apple.com › Certificates, Identifiers & Profiles › Identifiers),
   puis régénérer le profil de provisioning — sur Codemagic, la récupération des
   fichiers de signature le refait à la volée une fois la capability activée.
2. **Supabase** : Authentication › Providers › Apple, activer, et mettre
   `ch.vergasta.plant` dans *Authorized Client IDs*. C'est tout ce que demande
   le flux natif ; le *Secret Key* (JWT signé avec la clé `.p8`) ne sert qu'au
   flux OAuth web, que l'app n'utilise pas.
3. **Codemagic** : passer `SUPABASE_URL` et `SUPABASE_ANON_KEY` en
   `--dart-define` (§ Mise en place, étape 5).

Sans l'étape 1, le build ne se signe pas ; sans la 2, Supabase refuse le jeton
(« Unacceptable audience ») ; sans la 3, le bouton n'est pas dessiné.

Sur Android, Google suit le même chemin qu'Apple : la feuille du système
(Credential Manager, `android/.../GoogleSignInChannel.kt`) rend un jeton
d'identité, échangé par `signInWithIdToken` avec un nonce. La mise en place —
clients OAuth Web et Android, fournisseur Google côté Supabase — est dans
docs/20, § 4.

Sur iPhone, Google par le navigateur (`signInWithOAuth` et sa redirection
`auxine://login-callback`) reste codé, mais le bouton attend
`AppConfig.googleSignInEnabled`. La règle 4.8 de l'App Store n'exige Apple
qu'en présence d'un autre fournisseur tiers ; Apple seul est permis.
