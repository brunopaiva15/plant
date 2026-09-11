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
`AuthRepository` : `LocalAuthRepository` (Phase 1) → `SupabaseAuthRepository` (e-mail + code à 6 chiffres, Apple natif sur iOS, Google via OAuth). À la première connexion, le jardin local est réattribué au compte (`owner_id`, `SyncService.claimGarden`) et toutes ses lignes sont mises en file de synchronisation.

## Le jardin ouvert
Un compte peut avoir accès à plusieurs jardins : le sien, et ceux qu'on lui a partagés. Un seul est **ouvert** à la fois — c'est lui que montrent toutes les listes.

- `activeGardenProvider` (`ActiveGarden`, dans `app/providers.dart`) porte l'identifiant ; `gardenIdProvider` n'est qu'une lecture de celui-ci, pour que les tests puissent le surcharger par une valeur fixe.
- Le choix est mémorisé (`active_garden_id`). Sans compte distant, ou quand un autre compte se connecte sur l'appareil, on retombe sur le jardin créé au premier lancement.
- Changer de jardin reconstruit les dépôts (ils lisent tous `gardenIdProvider`), refait l'abonnement temps réel, et repart des curseurs de ce jardin — ils sont nommés `sync_cursor_{garden}/{table}`.
- La base locale contient les lignes de plusieurs jardins. Les dépôts qui interrogeaient toutes les plantes de l'appareil (journal, galerie récente, routines) filtrent désormais par jardin ; `enqueueEverything` ne met en file que le jardin de l'appareil, et la ligne `gardens` d'un jardin partagé n'est jamais poussée — elle appartient à quelqu'un d'autre.

## Collaboration
- `garden_members` : `owner` / `member` / `viewer`. Le domaine en fait `GardenRole` (`domain/sharing/garden_collaboration.dart`) : `canEdit`, `canManageMembers`.
- **Invitation par lien** : le propriétaire crée une invitation (`create_invite`), qui tire côté serveur un code de 8 caractères sans I, L, O, 0 ni 1. Le code est **à usage unique**, expire par défaut au bout de 14 jours, et peut être réservé à une adresse e-mail. L'invité n'a pas besoin d'avoir déjà un compte : il en crée un, puis échange le code (`accept_invite`).
- Le lien envoyé est une adresse https (`…/functions/v1/share/join/<code>`) : cliquable dans un message, elle sert une page qui dit qui invite et propose « Ouvrir dans Auxine » (`flora://join/<code>`). Le même lien est affiché en QR, et le scanner de l'application le reconnaît.
- `my_gardens()` liste les jardins du compte avec le rôle, le nom du propriétaire, le nombre de membres et de plantes. `set_member_role`, `remove_member`, `leave_garden`, `revoke_invite` complètent la gestion — toutes `security definer`, propriétaire seul sauf `leave_garden`.
- Chaque action et photo porte `user_id` ; la timeline affiche « · Laura » quand l'auteur n'est pas l'utilisateur courant (cache local `profiles`).
- Un `viewer` voit tout et ne peut rien écrire (RLS) ; l'UI masque les boutons d'ajout et les entrées d'édition, et les actions de soin refusent avec un message.

## Écrans
| Écran | Rôle |
|---|---|
| Réglages › Mes jardins (`/settings/gardens`) | liste des jardins, bascule, renommage du sien, départ d'un partagé, « Rejoindre un jardin » |
| Réglages › Membres (`/settings/members`) | qui est dans le jardin ouvert, changement de rôle, retrait, invitations en attente |
| Feuille « Inviter quelqu'un » | rôle, e-mail facultatif, puis le code, le QR et le lien à partager |
| Feuille « Rejoindre un jardin » | code saisi ou reçu par lien, aperçu de l'invitation, acceptation |

## Mise en place
1. Créer un projet Supabase, exécuter `supabase/schema.sql` dans l'éditeur SQL.
2. Déployer la fonction Edge `share` (elle sert aussi les pages `/join/<code>`).
3. Activer les fournisseurs Auth souhaités (Email OTP, Apple, Google) ; ajouter l'URL de redirection `flora://login-callback`.
4. Lancer l'app avec `flutter run --dart-define=SUPABASE_URL=… --dart-define=SUPABASE_ANON_KEY=…`.

### Sign in with Apple : deux choses à faire côté Apple
Le bouton « Continuer avec Apple » n'apparaît qu'avec un backend configuré, et
il ne fonctionne que si le binaire porte l'entitlement
`com.apple.developer.applesignin`. Cet entitlement **n'est pas dans le dépôt** :
tant que la capability n'existe pas sur l'App ID, sa seule présence fait échouer
la signature avec « Provisioning profile doesn't include the Sign In with Apple
capability », y compris sur les builds locaux et la CI.

Avant de livrer un build avec Supabase :
1. Activer **Sign In with Apple** sur l'App ID `ch.vergasta.plant`
   (developer.apple.com › Certificates, Identifiers & Profiles › Identifiers).
2. Régénérer le profil de provisioning — sur Codemagic, la récupération des
   fichiers de signature le refait à la volée une fois la capability activée.
3. Recréer `ios/Runner/Runner.entitlements` :
   ```xml
   <key>com.apple.developer.applesignin</key>
   <array><string>Default</string></array>
   ```
   et le déclarer dans les trois configurations du target `Runner`
   (`CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;`).

Sans l'étape 1, l'étape 3 casse le build ; sans l'étape 3, `signInWithApple`
lève à l'exécution. Les deux vont ensemble.

Rappel de la règle 4.8 de l'App Store : proposer Google ou un autre
fournisseur tiers oblige à proposer Apple aussi. Les trois boutons ne peuvent
donc pas être livrés à moitié.
