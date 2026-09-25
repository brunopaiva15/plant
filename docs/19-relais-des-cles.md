# Le relais des clés

*Comment trois clés d'API sont sorties du binaire, et ce qui garde la porte
maintenant qu'elles n'y sont plus.*

---

## 1. Le problème

Auxine appelle trois services payants avec des clés qui appartiennent à
l'éditeur, et non à l'utilisateur : Pl@ntNet pour le repli d'identification
(docs/09), les AI Services d'Infomaniak pour le diagnostic, le conseil, le
complément des fiches et les guides de bouturage, OpenRouter pour la couche de
décision Jev (docs/16). C'est un choix de produit, pas un accident :
personne n'a à ouvrir un compte chez un tiers pour identifier une plante.

Ces clés étaient fournies au build par `--dart-define`. **Ce mécanisme ne
cache rien.** Une valeur passée ainsi devient une constante du code compilé,
et se lit sur un paquet démonté :

```
$ strings Payload/Runner.app/Frameworks/App.framework/App | grep -i 'sk-or-'
```

Ce n'est pas un défaut d'Auxine. C'est vrai de toute application qui embarque
une clé, et l'obfuscation n'y change rien : si l'application sait déchiffrer,
celui qui la démonte le sait aussi. La seule parade est que la clé ne soit
jamais sur l'appareil.

Ce que coûtait une extraction, par clé :

| Clé | Ce qu'un tiers en ferait |
|---|---|
| `INFOMANIAK_AI_API_KEY` | jeton du manager, portée AI, facturé au jeton produit |
| `OPENROUTER_API_KEY` | du crédit, et ces clés sont activement cherchées |
| `PLANTNET_API_KEY` | le quota journalier de l'éditeur, épuisable par un tiers |

`SUPABASE_ANON_KEY` n'est pas dans ce tableau, et reste dans le binaire :
elle est publique par conception, c'est la RLS qui protège les données
(docs/08).

## 2. Ce qui remplace

Les clés vivent dans la fonction Edge `relay`
(`supabase/functions/relay/`), à côté de `share`. L'application ne parle
qu'à elle :

```
Auxine ──► /functions/v1/relay/identify ──► my-api.plantnet.org
       ──► /functions/v1/relay/ai       ──► api.infomaniak.com
       ──► /functions/v1/relay/decide   ──► openrouter.ai
```

Côté Dart, le changement est petit, et c'est ce qui permet de le relire :
`RelayConfig` remplace `IdentificationConfig`, `DiagnosisConfig` et
`JevConfig`, qui ont disparu. Les cinq clients — `PlantNetIdentifier`, les
quatre appels aux AI Services, `JevDecisionService` — reçoivent une adresse
et un `http.Client`, et ne connaissent plus aucune clé.

Deux effets de bord qui valent d'être notés :

- **Le modèle se décide côté serveur.** `INFOMANIAK_AI_MODEL` est un secret
  du relais, pas un `--dart-define` : en changer ne demande plus de
  repasser par l'App Store. Le relais écrase le modèle que le corps de la
  requête pourrait porter, et c'est voulu — c'est lui qui décide du prix.
- **Plus de fonction muette par oubli de compilation.** `isConfigured`
  ne veut plus dire « une clé a été passée au build » mais « l'adresse du
  relais est connue », et elle se déduit de `SUPABASE_URL`. C'est
  exactement l'accident raconté dans docs/05 à propos de la sonde de
  fenêtre : un `--dart-define` se passe silencieusement de travers.

## 3. La vraie question : à qui le relais parle-t-il ?

**Un relais sans garde serait pire que la clé volée.** Une clé extraite
demande de démonter un IPA ; une passerelle IA ouverte se trouve en scannant
des URL, et sert le monde entier sur la facture de l'éditeur.

Une contrainte de produit interdit la réponse habituelle : **le compte est
facultatif** (`AppUser.isLocal`). L'identification et le diagnostic
fonctionnent sans être connecté, et doivent continuer. Le relais ne peut donc
pas exiger un JWT d'utilisateur — et n'a de toute façon aucune raison de
savoir qui tient l'appareil.

Deux gardes se superposent, et ils ne font pas le même travail.

### 3.1 App Attest : qui appelle

La Secure Enclave d'un appareil Apple fabrique une paire de clés dont la
partie privée ne sort jamais, et Apple signe une attestation disant que cette
clé est née là, **dans cette application-ci**. Le relais vérifie la chaîne et
sait qu'il parle au vrai Auxine, sur un vrai iPhone. Il ne sait rien d'autre,
et c'est suffisant.

L'échange, dans l'ordre :

```
1. POST /attest/challenge            → un défi tiré au sort, usage unique, 5 min
2. DCAppAttestService.generateKey()    (une fois par appareil)
3. DCAppAttestService.attestKey(défi)
4. POST /attest/register             → le relais vérifie, garde la clé publique,
                                       et rend un jeton de séance (1 h)
   ─── ensuite, et à chaque expiration ───
5. POST /attest/challenge            → un nouveau défi
6. DCAppAttestService.generateAssertion(défi)
7. POST /attest/session              → un nouveau jeton
```

Le jeton, et non une assertion par requête : une signature de l'enclave coûte
un aller-retour, et en demander une à chaque photo ralentirait le diagnostic
sans rien prouver de plus.

Ce que le relais vérifie à l'étape 4, dans l'ordre d'Apple
(`supabase/functions/relay/attest.ts`) :

1. la chaîne `x5c` remonte à l'**Apple App Attestation Root CA**, épinglée
   dans `apple_root.ts` ;
2. le nonce scellé dans l'extension `1.2.840.113635.100.8.2` du certificat
   d'appareil vaut `SHA256(authData ‖ SHA256(défi))` ;
3. le condensé de la clé publique du certificat est l'identifiant annoncé ;
4. le `rpIdHash` est `SHA256(<équipe>.<paquet>)` — l'attestation vient bien
   de cette application ;
5. le compteur est nul, et l'`aaguid` correspond à un environnement accepté.

Les assertions suivantes se vérifient sans Apple : signature ECDSA sur la clé
gardée, et **compteur strictement croissant**. Le défi à usage unique
arrêterait déjà un rejeu ; le compteur est le second verrou, et il est tenu
par la base — `relay_bump_counter` ne met à jour que si le compteur monte,
si bien que deux assertions arrivées ensemble ne passent pas toutes les deux.

Tout cela est éprouvé sans iPhone :
`supabase/functions/relay/attest_test.ts` fabrique une chaîne de la même
forme, enracinée dans une autorité de test, et vérifie surtout les refus —
autre défi, autre application, mauvais environnement, racine d'Apple qui n'a
pas signé cette chaîne-là, assertion rejouée, octet modifié.

```bash
node --experimental-strip-types supabase/functions/relay/attest_test.ts
deno run supabase/functions/relay/attest_test.ts
```

Les deux, et pas seulement Node : c'est le runtime qui a fait défaut. La
chaîne fabriquée ne suffit pas non plus, et `apple_fixtures.ts` ajoute une
vraie attestation d'iPhone, rattachée à la vraie racine d'Apple.

> **Ce que la Web Crypto de Supabase ne sait pas faire.** Elle ne vérifie
> l'ECDSA que pour P-256 avec SHA-256 et P-384 avec SHA-384. Apple signe le
> certificat d'appareil en SHA-256 avec une clé P-384 : chaque première
> attestation levait « Not implemented », le relais répondait 500, et plus
> aucune identification n'atteignait Pl@ntNet. Node et les Deno récents
> acceptent ce mélange, et les tests passaient. Toutes les signatures du relais
> se vérifient donc dans `ecdsa.ts`, sans la Web Crypto, par un chemin unique
> que les tests éprouvent tel qu'il tourne.

### 3.2 Les quotas : combien chacun coûte

App Attest borne le **nombre** d'attaquants possibles. Il ne borne pas ce
qu'un appareil légitime, dont quelqu'un détourne l'application, peut
dépenser. Les quotas s'appliquent donc toujours, et à tout le monde :

| Route | Par appareil et par jour | Par jour, tous appareils |
|---|---|---|
| `identify` | 40 | 4 000 |
| `ai` | 30 | 1 500 |
| `decide` | 60 | 4 000 |

Le second plafond est le vrai filet : il tient encore le jour où quelqu'un
trouve le moyen de se faire passer pour mille appareils. Chacun se relève par
un secret (`RELAY_QUOTA_AI`, `RELAY_QUOTA_AI_DAY`, …) sans redéployer.

Le comptage est atomique (`relay_consume`, verrou consultatif par route) :
sans cela, deux requêtes simultanées liraient le même total avant de
l'écrire, et le plafond se franchirait de quelques appels.

**Et un plafond de dépense chez Infomaniak et chez OpenRouter**, qui ne
dépend d'aucun code de ce dépôt. C'est la dernière ligne.

### 3.3 Le corps des requêtes n'est pas libre

Le relais ne transmet pas n'importe quoi. Sur `ai`, seuls `messages`,
`max_tokens`, `temperature`, `response_format` et `top_p` traversent ;
`max_tokens` est plafonné à 12000 — ce que le diagnostic demande quand une
réponse revient coupée, et pas moins, sans quoi la réflexion du modèle
mange la réponse —, `stream` est forcé à faux, et le modèle
vient des secrets. C'est ce qui sépare un relais qui sert Auxine d'une
passerelle OpenAI gratuite.

## 4. Là où il n'y a pas d'enclave

App Attest n'existe pas sur le simulateur, et pas du tout sur Android. Sans
issue, toute construction de développement serait aveugle.

D'où `RELAY_DEV_TOKEN` : un secret partagé, que le relais échange contre un
jeton de séance. **Ce n'en est pas une preuve** — c'est un mot de passe, et
il a la valeur d'un mot de passe. Deux choses le bornent : tout ce qui entre
par là partage un seul quota d'appareil, et un
`supabase secrets unset RELAY_DEV_TOKEN` le coupe en une commande, sans
republier quoi que ce soit. **Il n'a rien à faire dans une construction
publiée.**

Android attend Play Integrity, qui est le pendant du mécanisme d'Apple et
reste à écrire. En attendant, une construction Android sans
`RELAY_DEV_TOKEN` voit les fonctions du relais simplement absentes — le
reste de l'application marche, elle est locale d'abord.

## 5. Mise en place

**1. Le schéma.** Rejouer `supabase/schema.sql` en entier dans l'éditeur SQL
du projet. Il ajoute `relay_devices`, `relay_challenges`, `relay_usage` et
leurs fonctions. Aucune de ces tables n'est lisible par `anon` ni par
`authenticated` : seule la fonction Edge y touche, avec la clé de service.

**2. Les secrets.** Depuis la racine du dépôt :

```bash
supabase secrets set \
  RELAY_SESSION_SECRET="$(openssl rand -base64 48)" \
  APPLE_APP_ID=ABCDE12345.ch.vergasta.plant \
  APP_ATTEST_ENVIRONMENTS=production \
  PLANTNET_API_KEY=… \
  INFOMANIAK_AI_API_KEY=… \
  INFOMANIAK_AI_PRODUCT_ID=… \
  INFOMANIAK_AI_MODEL=Qwen/Qwen3.5-397B-A17B-FP8 \
  OPENROUTER_API_KEY=…
```

L'identifiant d'équipe se lit dans l'onglet *Membership* du compte
développeur Apple. `APP_ATTEST_ENVIRONMENTS` vaut `production` pour une
application de l'App Store ; en développement, `development,production`.
Accepter `development` en production reviendrait à laisser entrer n'importe
quel appareil de développement enregistré.

**3. La fonction.**

```bash
supabase functions deploy relay
```

`verify_jwt` est à faux dans `supabase/config.toml` : les appelants sont des
appareils, pas des comptes, et la plateforme répondrait 401 avant que la
fonction ait pu regarder l'attestation.

**4. Vérifier.**

```bash
curl -s https://<projet>.supabase.co/functions/v1/relay/health
{"ok":true,"routes":{"identify":true,"ai":true,"decide":true},"missing":[]}
```

`missing` nomme les secrets absents. C'est aussi ce que sonde
Profil › État des services, qui ne vise plus les trois tiers — ils ne sont
plus joignables depuis l'appareil.

> **La requête qui éprouvera les limites.** Le diagnostic est de loin la plus
> lourde : jusqu'à trois photos réduites à 1 536 px, encodées en base64 dans
> le corps JSON, et le modèle réfléchit avant d'écrire. Le relais la borne à
> 12 Mo et 120 s (`RELAY_BODY_AI`, `RELAY_TIMEOUT_AI`), mais la plateforme a
> ses propres plafonds de taille et de durée, qui dépendent du plan. C'est ce
> qu'il faut éprouver en premier sur un vrai appareil : un 413, ou une
> coupure au bout de n secondes, vient de là et non du code. Si le plafond
> gêne, la route `ai` peut déménager derrière le Worker Cloudflare qui sert
> déjà `share` (`share-proxy/`), plus à l'aise sur les gros corps — les deux
> autres routes n'ont aucune raison de bouger, elles sont légères.

**5. Rien à passer au build.** L'adresse du relais se déduit de
`SUPABASE_URL`, déjà fournie. Les `--dart-define` des trois clés sont à
retirer de Codemagic (docs/09, § 3.3).

**6. Avant de publier : révoquer les anciennes clés.** Elles ont traversé des
shells, des scripts et des journaux de build, et rien ne les protégeait. En
faire de nouvelles, et ne les donner qu'au relais.

## 6. Ce qui reste à faire

- **Play Integrity** pour Android, à la place du laissez-passer partagé.
- **Le reçu d'Apple** est gardé (`relay_devices.receipt`) mais pas exploité :
  il ouvre le service de risque d'Apple, qui dit combien d'attestations un
  appareil a demandées. C'est ce qui repérerait une ferme d'appareils.
- **La purge** (`relay_purge`) n'est appelée par personne : à brancher sur un
  cron Supabase, sans quoi `relay_usage` grossit indéfiniment.
- **Le plafond de dépense** chez Infomaniak et OpenRouter, qui ne s'écrit pas
  ici mais sans lequel rien de ce qui précède ne borne vraiment la facture.

## 7. Ce qu'il ne faut pas refaire

- **Remettre une clé de tiers dans un `--dart-define`.** Ce n'est pas un
  secret, ça n'en a jamais été un.
- **Croire qu'obfusquer suffit.** L'application doit pouvoir s'en servir,
  donc elle doit pouvoir la lire, donc n'importe qui le peut.
- **Ouvrir le relais sans quota**, en se disant qu'App Attest garde la
  porte. Il dit qui frappe, pas combien de fois.
- **Rejouer une assertion.** Le défi est à usage unique et le compteur ne
  redescend pas ; les deux sont vérifiés, et les deux ont leur test.
- **Laisser `RELAY_DEV_TOKEN` posé sur le projet de production.** Il y
  annulerait tout le reste.
