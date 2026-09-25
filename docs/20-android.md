# Android

*Ce qu'il a fallu pour qu'Auxine se publie sur Google Play, et les réglages
qui restent à faire hors du dépôt.*

---

## 1. Où en est Android

L'application tournait déjà sur Android, locale d'abord : les plantes, les
soins, les rappels, Iris, le scanner QR, la météo. Il manquait trois choses
pour la publier, et quelques finitions.

| | Avant | Maintenant |
|---|---|---|
| Relais des clés (Pl@ntNet, diagnostic, conseils, fiches, bouturage, Jev) | fermé : App Attest n'existe que chez Apple | **Play Integrity** (§ 3) |
| Signature release | clé de debug | `android/key.properties` (§ 2) |
| Compte | local seulement | **Google**, par la feuille du système (§ 4) |
| Permission refusée | une phrase, sans issue | bouton vers la fiche de l'app dans les Paramètres |
| Textes | « Réglages », « identifiant Apple » | « Paramètres », « compte Google » |
| Icône de notification | icône en couleur, rendue en carré blanc | silhouette du pot (`ic_stat_auxine`) |
| Orientation | portrait partout, ignoré par Android 16 sur grand écran | portrait sur téléphone, libre sur tablette et pliable ouvert |

Ce qui n'existe pas sur Android, par choix, et que les écrans ne proposent
donc pas : les widgets, les actions rapides de l'icône, le relevé de la
maison au LiDAR (docs/17), Apple Maison, la chrome native d'iOS et les
motifs haptiques de Core Haptics (le retour haptique du système prend le
relais). Google Home, lui, est bien là — voir docs/05, section « Google
Home ».

Les réglages qui suivent se font une fois, hors du dépôt. Deux valeurs
seulement s'écrivent dans le code, et aucune n'est un secret :

| Constante | Fichier | Valeur |
|---|---|---|
| `RelayConfig.playCloudProjectNumber` | `lib/core/config/relay_config.dart` | numéro du projet Google Cloud lié à l'app dans la console Play |
| `AppConfig.googleWebClientId` | `lib/core/config/app_config.dart` | identifiant du client OAuth *Web* (`….apps.googleusercontent.com`) |

Tant qu'elles valent zéro et vide, une construction Android se comporte
comme avant : relais fermé (sauf `RELAY_DEV_TOKEN`), compte local.

## 2. Signer

Google Play signe lui-même l'application (*Play App Signing*). Ce qu'on lui
envoie est signé avec une **clé d'envoi**, qui se remplace si elle se perd.

```bash
keytool -genkey -v -keystore ~/auxine-upload.jks -keyalg RSA -keysize 2048 \
  -validity 10000 -alias upload
```

Puis `android/key.properties`, que `android/.gitignore` écarte du dépôt :

```properties
storePassword=…
keyPassword=…
keyAlias=upload
# Relatif au dossier android/, ou absolu.
storeFile=/Users/…/auxine-upload.jks
```

Sans ce fichier, `android/app/build.gradle.kts` signe la release avec la clé
de debug : `flutter run --release` marche, et Google Play refuse le paquet.

```bash
flutter build appbundle --release
# build/app/outputs/bundle/release/app-release.aab
```

La console Play affiche ensuite, sous *Intégrité de l'application ›
Signature de l'application*, deux empreintes : celle de la clé d'envoi et
celle de la clé de signature de Google. Les deux servent au § 4, la seconde
au § 3.

## 3. Play Integrity

Le pendant d'App Attest, expliqué dans docs/19 § 4 : l'application demande au
Play Store un jeton qui scelle le défi du relais et son identifiant
d'installation, Google le déchiffre pour le relais, et le relais y lit que
c'est Auxine, distribué par Google Play, sur un Android certifié.

1. **Console Play › Intégrité de l'application › API Play Integrity** : lier
   un projet Google Cloud (en créer un au besoin). L'API s'y active.
2. Copier le **numéro** du projet (pas son identifiant) dans
   `RelayConfig.playCloudProjectNumber`.
3. **Google Cloud › IAM › Comptes de service**, dans ce même projet : créer
   un compte de service, sans rôle, et lui créer une clé JSON. C'est lui qui
   a le droit de déchiffrer les jetons.
4. Côté relais :

   ```bash
   supabase secrets set \
     PLAY_INTEGRITY_SERVICE_ACCOUNT="$(cat ~/Téléchargements/auxine-integrity.json)" \
     PLAY_CERT_SHA256="AB:CD:…"   # facultatif : la clé de signature de Google
   supabase functions deploy relay
   ```

   `PLAY_PACKAGE_NAME` vaut `ch.vergasta.plant` par défaut.
5. Vérifier : `GET …/functions/v1/relay/health` répond `"playIntegrity": true`.

Ce que le relais exige d'un verdict (`supabase/functions/relay/integrity.ts`) :
le paquet `ch.vergasta.plant`, le condensé du défi et de l'installation, un
jeton de moins de cinq minutes, `PLAY_RECOGNIZED` et
`MEETS_DEVICE_INTEGRITY`. Un APK installé à la main, ou lancé par
`flutter run`, n'est pas `PLAY_RECOGNIZED` : il passe par le laissez-passer
`RELAY_DEV_TOKEN` s'il en porte un, et sinon le relais lui reste fermé. Pour
éprouver le vrai chemin, passer par une piste de test interne de la console
Play.

Deux limites à connaître. Google accorde par défaut 10 000 verdicts par jour ;
l'application en demande un par heure et par appareil actif, pas un par
requête. Et Play Integrity ne rend aucune identité d'appareil : le quota par
appareil compte l'identifiant d'installation, qu'une réinstallation
renouvelle. Le plafond du jour, tous appareils confondus, reste celui qui
borne la facture (docs/19 § 3).

## 4. Connexion Google

La feuille du système (Credential Manager,
`android/app/src/main/kotlin/…/GoogleSignInChannel.kt`), comme Sign in with
Apple sur iPhone : pas de navigateur, un jeton d'identité signé par Google,
échangé contre une session Supabase avec un nonce.

1. **Google Cloud › API et services › Identifiants**, dans le projet de son
   choix (celui du § 3 convient) :
   - un client OAuth de type **Web** : son identifiant va dans
     `AppConfig.googleWebClientId`, et le couple identifiant et secret dans
     Supabase (étape 2) ;
   - un client OAuth de type **Android** par empreinte SHA-1 : le paquet
     `ch.vergasta.plant`, avec l'empreinte de la clé de signature de Google
     (§ 2), celle de la clé d'envoi, et celle de la clé de debug pour
     `flutter run` (`keytool -list -v -keystore ~/.android/debug.keystore
     -storepass android`). Ces clients n'ont rien à copier nulle part : leur
     existence suffit à Google.
2. **Supabase › Authentication › Providers › Google** : activer, coller
   l'identifiant et le secret du client Web. Laisser la vérification du nonce
   active : l'application en envoie un.
3. L'écran de consentement OAuth du projet : nom « Auxine », logo, lien vers
   `AppConfig.privacyUrl`.

Sur iPhone, rien ne change : Apple seul, et Google par le navigateur
reste derrière `AppConfig.googleSignInEnabled`.

## 5. La fiche Google Play

Les textes de `store/listing.md` valent pour Google Play, à trois
différences près : Play demande une **description courte** de 80 caractères,
n'a pas de champ de mots-clés, et la description longue ne compte pas plus
de 4 000 caractères. Il demande aussi :

- **des captures de téléphone** (au moins deux, format 16:9 ou 9:16) et une
  **image de présentation** de 1024 × 500. Les captures d'iPhone ne
  conviennent pas : la barre d'état et les contrôles ne sont pas les mêmes.
  `store/capture.mjs` peut servir de base, avec une fenêtre de 412 × 915.
- **le formulaire « Sécurité des données »**. Il reprend ce que déclare
  `ios/Runner/PrivacyInfo.xcprivacy` : adresse e-mail et nom (compte),
  photos et contenus (plantes synchronisées, identification), position
  approximative (la ville de la météo, non gardée). Rien n'est partagé avec
  des tiers à des fins publicitaires, rien n'est suivi. Les photos envoyées
  pour identification transitent par le relais vers Pl@ntNet.
- **la classification du contenu** et **le public cible** : tout public, pas
  destiné aux enfants.

## 6. Ce qui a été vérifié, et comment

- `flutter build apk --release` et `flutter build appbundle --release`
  compilent, canaux Kotlin compris. Il a fallu une ligne dans
  `android/gradle.properties` : `tflite_flutter` compile son Java en cible 11
  et laisse Kotlin sur celle du JDK, ce que Gradle refusait (« Inconsistent
  JVM Target Compatibility »). La construction Android était cassée avant
  même ce chantier.
- Les bibliothèques natives sont alignées sur 16 Ko, comme Google Play
  l'exige des applications qui ciblent Android 15 et plus :

  ```bash
  unzip -o build/app/outputs/flutter-apk/app-release.apk 'lib/*' -d /tmp/apk
  for so in /tmp/apk/lib/arm64-v8a/*.so; do
    llvm-objdump -p "$so" | awk '/LOAD/ {print $NF}' | sort -u
  done   # 2**14 ou 2**16 : jamais moins
  /opt/android-sdk/build-tools/36.0.0/zipalign -c -P 16 -v 4 \
    build/app/outputs/flutter-apk/app-release.apk | tail -1
  ```

  Vérifié sur la 1.0.1 : `libtensorflowlite_jni.so` et les autres à
  `2**14`, `libflutter.so` et `libapp.so` à `2**16`, et `zipalign` passe.

- `supabase/functions/relay/integrity_test.ts` éprouve chaque refus du
  verdict ; `test/core/relay_client_test.dart` la poignée de main côté
  application. Les deux calculent le même condensé sur le même vecteur.

Ce qui ne s'éprouve que sur un vrai téléphone, par une piste de test
interne : le verdict de Google lui-même, et la feuille de connexion.
