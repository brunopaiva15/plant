# 09 — Reconnaissance de plantes : Iris, le modèle embarqué, repli Pl@ntNet

> État au 9 septembre 2026 : 1 558 plantes au catalogue de collecte, 290 131
> images sous CC0, CC BY ou CC BY-SA, modèle MobileNetV3-Large livré dans
> l'app en TFLite. Ce qu'il pèse, ce qu'il sait et ce qu'il vaut se lisent
> dans **sa fiche au § 0**, recopiée de `assets/model/model.json` : ces
> chiffres-là ne s'écrivent qu'à un seul endroit. La cascade identifie **sur
> l'appareil** et n'appelle Pl@ntNet que sur hésitation ; deux photos de la
> même plante valent quatorze points de top-1, trois en valent vingt-deux.

Le modèle embarqué s'appelle **Iris**, et la version livrée est la première à
porter ses deux domaines dans un seul fichier :
c'est **Iris 9** que l'application nomme à l'écran.
Quand ce document parle de « la v8 » ou
d'« Iris Indoor », il parle des versions précédentes, restées les références
contre lesquelles l'Iris 9 s'est mesurée.

Les numéros plus anciens qu'on croise ici — la v6, l'Iris 7 — **datent une
mesure** : ils disent sur quel modèle un chiffre a été obtenu, et une section
entière peut ainsi décrire une version révolue sans cesser d'être vraie. Un
chiffre qui décrit le modèle d'**aujourd'hui**, lui, ne s'écrit qu'à un
endroit : la fiche.

## 0. Le nom

`Iris` est la marque du modèle, `AppConfig.modelName` dans le code. Le numéro
ne s'écrit **jamais** à la main : le modèle l'annonce dans
`assets/model/model.json`, `TflitePlantModel` le lit au chargement et
`AppConfig.modelDisplayName(version)` le colle au nom. Livrer un modèle
réentraîné suffit donc à faire dire « Iris 9 » à l'écran des réglages, et
l'application ne peut pas afficher un numéro qui ment.

Tant que le modèle n'a rien dit — pas encore chargé, métadonnées absentes —
l'application dit « Iris » tout court plutôt que d'inventer un numéro.

### La fiche du modèle livré

Ce que `model.json` annonce, et rien d'autre. **C'est la seule table de ce
document qui décrit le modèle d'aujourd'hui** : partout ailleurs, un chiffre
appartient à la version qui le porte et ne bouge plus. Recopier une de ces
valeurs dans un autre fichier, c'est se donner rendez-vous avec une
documentation fausse à la livraison suivante — `test/docs/model_facts_test.dart`
relit le fichier et fait échouer la suite si cette table s'en écarte.

<!-- fiche:model.json -->

| clé de `model.json` | valeur | |
|---|---|---|
| `version` | 9 | le numéro affiché, collé à « Iris » |
| `architecture` | MobileNetV3Large | la dorsale |
| `classes` | 1 569 | espèces exposées, une ligne de `labels.txt` chacune |
| `input_size` | 320 | pixels de côté à l'inférence |
| `load_size` | 366 | décodage avant recadrage |
| `source_size` | 448 | côté des images du jeu |
| `preprocessing` | `included_in_graph_uint8_0_255` | la normalisation est dans le graphe |
| `bytes` | 9 005 584 | soit 9,01 Mo de `.tflite` |
| `sha256` | a919ae6a24f7… | empreinte du fichier de poids |
| `metrics.images` | 30 954 | images de test |
| `metrics.top1` | 0,6876 | la bonne espèce en tête |
| `metrics.top3` | 0,8227 | dans les trois premières |
| `metrics.macro_f1` | 0,6702 | moyenne par classe, sans pondérer par le volume |
| `metrics.mean_confidence` | 0,7299 | score moyen du premier candidat |
| `metrics.captive.images` | 4 649 | sous-ensemble des plantes cultivées |
| `metrics.captive.top1` | 0,6728 | ce que voit qui photographie son pot |
| `metrics.captive.top3` | 0,8101 | |

<!-- /fiche -->

**Ces chiffres sont ceux des 1 569 sorties, sans masque.** Le fichier porte
aussi, pour la première fois, un objet `masks` : **336 classes** pour
l'intérieur, **1 424** pour l'extérieur. L'application renormalise sur celles
du lieu, et ce qu'elle rend alors n'est pas dans cette table — c'est mesuré au
§ 14.6. Un ordre de grandeur : sur les photos de plantes cultivées, le masque
intérieur fait passer le top-1 de 0,7230 à **0,7650**.

Le fichier porte en plus `threshold_curve` — pour chaque couple (seuil,
marge), l'autonomie et la justesse qui vont avec. C'est de là que sort le
réglage de `FallbackPolicy` (§ 3.1), et c'est pour cela qu'il se remesure à
chaque version plutôt que de se reprendre d'une version à l'autre.

### Là où l'utilisateur le rencontre

L'onboarding le présente en un écran, entre le jardin et la vie privée : la
marque au centre de la scène, « Iris reconnaît vos plantes hors ligne », le
geste qui va avec — photographiez votre plante — et la cascade en une
proposition, « si Iris ne la reconnaît pas, il la cherche en ligne ». C'est le seul endroit où le
repli se dit avant qu'on en ait besoin ; le taire ici pour l'écrire dans les
réglages, juste avant un écran qui promet que tout reste sur l'appareil,
reviendrait à le cacher.

**Sans numéro.** L'écran dit « Iris », `AppConfig.modelName` et rien de plus.
Le numéro répond d'une question qu'on ne se pose pas encore en découvrant
l'app — *lequel tourne sur mon téléphone ?* —, et il n'a de sens qu'à côté de
ce qu'il a coûté et rapporté, c'est-à-dire dans les réglages. L'onboarding y
gagne aussi de ne rien charger : `version` demande le graphe, et le graphe
n'a rien à faire sur le deuxième écran d'une app qui s'ouvre.

*Réglages > Identification* lui donne une section : la marque (`IrisMark`,
§ *Matière* de [docs/06](06-design-system.md)), le nom, une phrase, le nombre
d'espèces et le fait qu'il réponde hors ligne.

Le compte d'espèces n'est pas écrit dans l'écran : il sort du même
`model.json` que la version. Livrer une v9 change la section sans qu'on touche
à une ligne de présentation.

La carte remplace la ligne d'état tant que le modèle est chargé — la voir,
c'est savoir qu'il l'est. Sinon la ligne d'état reste, avec l'erreur native
brute, qui seule distingue un asset absent d'une bibliothèque non liée.

Une seconde carte porte le conseil des deux photos (§ 6.7) : quatorze points
de top-1 pour zéro calcul, et il n'était écrit nulle part où l'utilisateur
le lise.

## 1. Pourquoi

Aujourd'hui l'identification passe intégralement par l'API Pl@ntNet, avec la
clé de l'utilisateur. C'est bon marché tant que l'usage reste faible, mais
ça dépend d'un réseau, d'un quota (500 requêtes / jour en gratuit) et d'un
tiers. L'objectif :

- **identifier sur l'appareil** les plantes que l'app connaît déjà
  (les 297 espèces du catalogue trié à la main, puis plus) ;
- **consulter Pl@ntNet seulement quand le modèle local hésite**, ou pour
  une plante hors catalogue ;
- rester **commercialement utilisable** : données d'entraînement sous
  licence permissive, attribution livrée, aucune image scrapée ;
- rester **peu coûteux** : entraînement par transfert sur un petit réseau
  mobile, quelques heures de GPU au plus.

## 2. Ce qui existait déjà dans l'app

| Élément | Fichier | Rôle |
|---|---|---|
| `PlantIdentifier` | `lib/domain/identification/plant_identifier.dart` | interface : `identify(List<File>) → candidats` |
| `PlantNetIdentifier` | `lib/data/services/plantnet_identifier.dart` | adaptateur HTTP Pl@ntNet, clé utilisateur |
| `plantIdentifierProvider` | `lib/app/providers.dart` | choisit le service selon la clé |
| Catalogue trié | `lib/data/species/species_catalog.dart` | 297 espèces avec noms en 4 langues, famille, catégorie |
| Catalogue étendu | `assets/species/catalog.tsv` → `SpeciesIndex` | 36 342 espèces, noms courants, chargé à la demande |
| Appelants | création de plante, feuille « Identifier », fiche plante | affichent 5 candidats et laissent choisir |

Les appelants n'ont **pas** changé : ils reçoivent toujours une liste de
`IdentificationCandidate`, désormais avec deux champs de plus (`source`,
`internalId`).

## 3. Architecture

```
photo(s)
   │
   ▼
CascadeIdentifier  (lib/domain/identification/cascade_identifier.dart)
   │  1. cache (même fichier → même réponse)
   │  2. LocalPlantModel.classify()      ── délai max 4 s, erreur absorbée
   │  3. FallbackPolicy.decide()
   │        accepted  → réponse locale, fin, aucun réseau
   │        uncertain / noCandidate ↓
   │  4. repli autorisé ? (réglage utilisateur, clé Pl@ntNet, quota du mois)
   │        oui → PlantNetIdentifier.identify()
   │        non → réponse locale telle quelle (ou vide)
   │  5. normalisation des noms + rattachement au catalogue (internalId)
   │  6. compteurs (IdentificationMetrics) écrits dans les réglages
   ▼
List<IdentificationCandidate>  (scientificName, commonName, score, source, internalId)
```

Fichiers :

| Fichier | Contenu |
|---|---|
| `lib/core/utils/scientific_name.dart` | `normalizeScientificName`, `internalPlantId` — même règle que l'outil Python |
| `lib/domain/identification/identification_policy.dart` | `FallbackPolicy` (seuil, marge, plancher) |
| `lib/domain/identification/local_plant_model.dart` | interface `LocalPlantModel` + `NoLocalModel` |
| `lib/data/services/tflite_plant_model.dart` | le modèle embarqué, exécuté par TensorFlow Lite |
| `lib/domain/identification/cascade_identifier.dart` | la cascade |
| `lib/domain/identification/identification_metrics.dart` | compteurs + magasin |
| `lib/data/services/preferences_metrics_store.dart` | compteurs persistés dans `SharedPreferences` |
| `lib/features/identification/presentation/identification_settings_screen.dart` | interrupteurs « Repli en ligne » et « Envoi des photos identifiées » + ligne de compteurs |

### 3.1 Règle de repli

```dart
const FallbackPolicy(acceptThreshold: 0.70, minMargin: 0.25, floor: 0.10)
```

Réponse locale **acceptée** si, et seulement si :

- le meilleur score ≥ **0,70**, **et**
- l'écart entre le premier et le deuxième score ≥ **0,25**.

Un modèle qui donne 0,71 / 0,29 n'a rien décidé ; on demande à Pl@ntNet.
Sous **0,10**, la liste ne vaut rien (image hors sujet) : `noCandidate`.

**Un seuil ne se transporte pas d'un modèle à l'autre**, et celui-ci a bougé
à chaque version : 0,90 sur la v1 et ses 78 classes, 0,70 sur la v5, 0,60 sur
la v6, **0,70 de nouveau depuis l'Iris 7**. Un réseau qui répartit sa confiance
sur plus d'espèces sort des scores structurellement plus bas ; un réseau mieux
calibré en sort de plus honnêtes. Le recalage se fait avec
`tools/plant_model/multi_photo.py`, sur les photos de plantes cultivées et
dans le calcul exact que fait la cascade — mesure et raisonnement au § 6.7.

Avec l'Iris 7, il a **remonté** pour la première fois : les versions
précédentes dépensaient leur surplus de justesse en autonomie, et à 0,70 elle
rendait l'autonomie qu'avait la v6 à 0,60 — 47 % de réponses seules — avec
85,9 % de justesse au lieu de 82,8 %. L'Iris 8 ne l'a pas fait bouger, et
c'est l'intérêt de la version : au **même** seuil elle est à la fois plus
autonome et plus juste (§ 6.7 bis). Ce que ce couple rend sur le modèle
livré est dans `model.json`, pas ici.

**La marge est aujourd'hui sans effet** : les scores d'un softmax somment à 1,
donc un premier candidat à 0,70 laisse au plus 0,30 au deuxième — la marge vaut
toujours au moins 0,40. Elle ne mordrait qu'avec un seuil sous 0,625 — elle a
failli, avec le 0,60 de la v6 — ou avec un modèle dont les sorties ne somment
pas à 1. Elle est conservée pour cela, pas parce qu'elle travaille.

### 3.2 Inconnu / hors distribution

Un classifieur à N classes répond *toujours* quelque chose, même devant un
chat. Trois garde-fous, du moins cher au plus cher :

1. **la règle de marge** ci-dessus (déjà en place) ;
2. **une classe « autre »** entraînée sur des images de plantes hors
   catalogue *et* de non-plantes (prévue au premier entraînement, images
   CC0 tirées de GBIF pour d'autres familles + photos de scènes d'intérieur) ;
2. plus tard, si nécessaire, **calibration de température** sur le jeu de
   validation, pour que 0,90 veuille dire 90 %.

Dans tous les cas, l'interface continue de présenter **plusieurs candidats
avec leur score** et de laisser l'utilisateur choisir : aucune réponse n'est
appliquée sans un geste de sa part.

### 3.3 Repli Pl@ntNet

**La clé est celle de l'éditeur**, pas celle de l'utilisateur :
l'identification en ligne fait partie de l'application, personne n'a à ouvrir
un compte chez un tiers pour s'en servir.

Elle n'est plus dans le binaire pour autant. Elle l'a été, derrière un
`--dart-define`, et ce mécanisme ne cachait rien : une valeur passée ainsi
devient une constante du code compilé, que `strings` sort d'un paquet démonté
en quelques secondes. Elle vit maintenant dans la fonction Edge `relay`, qui
tient les trois clés de l'éditeur et signe les requêtes ;
`PlantNetIdentifier` ne connaît qu'une adresse et n'envoie que les photos et
la langue. Tout est dans **docs/19-relais-des-cles.md** : ce que le relais
vérifie avant de répondre (App Attest), les quotas qui bornent la facture, et
la marche à suivre pour le déployer.

`RelayConfig` (`lib/core/config/relay_config.dart`) remplace
`IdentificationConfig`, qui a disparu avec `DiagnosisConfig` et `JevConfig`.
L'adresse du relais se déduit de `SUPABASE_URL` : sans backend, le repli est
simplement absent et l'application se contente du modèle embarqué.

**Configuration dans Codemagic**

Les trois clés de services n'y sont plus : elles sont posées sur le projet
Supabase (`supabase secrets set`, docs/19), et le build n'a plus à les
connaître. Ce qui reste à passer :

```yaml
environment:
  groups:
    - flora_secrets
scripts:
  - name: Build iOS
    script: |
      flutter build ipa --release \
        --dart-define=SUPABASE_URL=$SUPABASE_URL \
        --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY \
        --dart-define=SHARE_BASE_URL=$SHARE_BASE_URL
```

| Variable | Sert à | Sans elle |
|---|---|---|
| `SUPABASE_URL`, `SUPABASE_ANON_KEY` | compte, synchronisation, partage (docs/08), et l'adresse du relais (docs/19) | application 100 % locale, sans identification en ligne ni diagnostic |
| `SHARE_BASE_URL` | base des liens de partage : le relais `share-proxy/` (docs/08) | l'URL Supabase, qui sert la page en code source |

`RELAY_DEV_TOKEN` n'entre jamais dans une construction publiée : c'est le
laissez-passer du simulateur et d'Android, et c'est un mot de passe partagé,
pas une preuve (docs/19, § 4).

Le `--dart-define` reste indispensable pour celles-ci : une variable
d'environnement de CI n'entre pas toute seule dans le binaire Flutter.

- Déclenché automatiquement seulement sur `noCandidate`, erreur locale ou absence de modèle. Une liste `uncertain` reste visible pour permettre la seconde photo.
- Coupable par l'utilisateur (réglage « Repli en ligne ») : tout reste alors
  sur l'appareil.
- **Quota mensuel** de 30 appels par appareil (`monthlyRemoteLimit`), remis
  à zéro chaque mois civil : un appel Pl@ntNet se paie, le modèle embarqué
  doit suffire au quotidien et la recherche en ligne reste le recours. Au-delà,
  la réponse locale est rendue, le bouton « Chercher en ligne » disparaît,
  `quotaRefusals` est incrémenté, et l'écran de réglage montre le compte du
  mois.
- Échec réseau après une réponse locale incertaine → la réponse locale est
  rendue, l'erreur comptée. Échec sans rien de local → exception, comme
  aujourd'hui (l'écran affiche « Identification impossible »).
- Cache en mémoire (24 entrées, clé = chemin + taille + date du fichier) :
  rouvrir la feuille sur la même photo ne coûte pas un appel.

### 3.4 Rattachement au catalogue

Tout nom (modèle, Pl@ntNet) passe par `normalizeScientificName` (auteur
retiré, « x » → « × », rangs abrégés). Si le nom canonique est dans le
catalogue trié, ou dans le catalogue étendu quand il est chargé,
`internalId` vaut l'identifiant interne (`monstera-deliciosa`), le même que
dans `tools/plant_dataset/plants.csv` et que les classes du modèle. Sinon
`null` : la plante est inconnue de l'app, mais le nom reste proposé.

### 3.5 Métriques

Sur l'appareil, dans les réglages, sans réseau (`IdentificationMetrics`) :

| Compteur | Sens |
|---|---|
| `total` | identifications demandées (hors cache) |
| `local`, `localAccepted` | passages par le modèle, réponses acceptées sans repli |
| `remote`, `fallbacks` | appels Pl@ntNet ; ceux qui suivent une hésitation locale |
| `cacheHits`, `errors`, `quotaRefusals` | |
| `confidenceSum` | pour la confiance moyenne |
| `remotePeriod`, `remoteInPeriod` | quota du mois |

Dérivés : `localSuccessRate`, `fallbackRate`, `averageConfidence`,
`remoteCallsSaved` (= `localAccepted + cacheHits`, l'économie estimée en
appels distants). Affichés dans l'écran Identification.

Aucune remontée serveur pour l'instant. Si un jour on agrège ces compteurs,
ce sera par un envoi **opt-in**, de totaux seulement — jamais d'image, jamais
de nom d'espèce.

### 3.6 Vie privée

- Avec un modèle local, la photo **ne quitte pas l'appareil** tant que le
  modèle est sûr de lui.
- Elle n'est envoyée à Pl@ntNet que sur hésitation, si l'utilisateur a
  laissé le repli activé, et avec sa propre clé — comme aujourd'hui.
- Les compteurs ne contiennent ni image, ni espèce, ni horodatage
  individuel.
- Les vignettes de la liste (§ 3.7) sortent un **nom d'espèce**, jamais une
  photo : c'est l'application qui demande à quoi ressemble un *Beaucarnea
  recurvata*, pas ce que l'utilisateur a devant lui.

### 3.7 La vignette d'un candidat

« Beaucarnea recurvata » ne dit rien à personne ; la photo, si. Chaque ligne
de la feuille d'identification porte donc une vignette de 44 points de
l'espèce proposée, à côté du nom.

| Source | Quand | Coût |
|---|---|---|
| Pl@ntNet | résultat distant : `include-related-images=true` rend les photos de référence dans **la même requête** | aucun appel ni quota de plus |
| GBIF | tout le reste, et d'abord les réponses du modèle embarqué, qui ne connaît que des noms | deux requêtes par espèce (`species/match` puis `occurrence/search`), sans clé, mémorisées par nom pour la session |

La vignette arrive **après** la liste : les noms s'affichent dès que le
modèle a répondu, les photos se posent ensuite. Sans réseau, la ligne
retrouve son losange de confiance et rien d'autre ne change — le modèle
embarqué reste utilisable hors ligne de bout en bout.

**Licences.** Une vignette n'a pas la place d'écrire son crédit : on la
touche, la fiche espèce s'ouvre, et le crédit y est. Seules les photos en
domaine public ou en attribution simple (CC0, CC BY, CC BY-SA) sont
affichées — `SpeciesImage.isFreelyDisplayable`, la même règle qu'au § 4.1
pour le jeu d'entraînement. Le CC BY-NC que GBIF sert volontiers est écarté
deux fois : au filtre de la requête, puis sur le média lui-même.

### 3.8 Le signe de la provenance

Au-dessus des propositions, une phrase dit d'où elles viennent : « Trouvé sur
votre appareil, sans réseau » ou « Proposé en ligne par Pl@ntNet ». Une
légende grise au-dessus d'une liste se saute, et c'est pourtant la seule
ligne de l'écran qui engage le § 3.6.

Elle porte donc un signe à sa gauche (`IdentificationSourceNote`) : un
**téléphone** quand le modèle embarqué a répondu, un **nuage** quand la photo
est partie chez Pl@ntNet. Il ne remplace pas la phrase, il se lit avant elle ;
pour la synthèse vocale il est décoratif, puisqu'elle lit déjà la phrase.

Trois règles le tiennent honnête :

- **`unknown` n'a pas de signe.** Un dessin qui affirme « appareil » ou
  « réseau » quand on ne sait pas mentirait ; la phrase générique, elle, ne
  promet rien. C'est le cas pendant une relance : la liste à l'écran est la
  précédente, et la provenance de la suivante n'est pas encore connue.
- **Un signe par liste, pas par ligne.** La cascade marque de la même source
  toutes les candidates d'une réponse (`_mark`) ; le répéter à chaque ligne
  ne dirait rien de plus.
- **Il suit le texte.** Sa taille est prise sur `textScaler`, et il s'aligne
  sur la première ligne de la légende — pas sur le bloc, qui passe à deux
  lignes dès qu'on grossit le texte.

Les deux écrans qui proposent des espèces le portent : la feuille « Espèce »
(`identification_sheet.dart`) et l'étape *Nom* du flux de création
(`create_plant_flow.dart`).

## 4. Sources d'images et licences

### 4.1 Règle

| Licence | Décision |
|---|---|
| CC0 1.0, Public Domain Mark | ✅ |
| CC BY (2.0 → 4.0) | ✅ avec attribution livrée |
| CC BY-SA | ✅ depuis le 6 septembre 2026 (`--allow-sa`), avec attribution livrée — décision prise au motif qu'un modèle entraîné n'est pas une adaptation des photos : il n'en reproduit aucune, et elles ne sont jamais redistribuées |
| CC BY-NC, BY-ND, BY-NC-SA, BY-NC-ND | ❌ |
| inconnue, absente, propriétaire, Google Images, scraping | ❌ |

Le filtre est appliqué par requête **et** par média (`plant_dataset/licenses.py`,
`fetchers/gbif.py`), et chaque image gardée porte sa traçabilité dans
`manifest.jsonl`. `ATTRIBUTIONS.md` doit accompagner tout modèle publié.

### 4.2 GBIF (fait)

`api.gbif.org/v1` : `species/match` pour la clé de taxon, `occurrence/search`
avec `mediaType=StillImage`, `basisOfRecord=HUMAN_OBSERVATION`, `license=`.
GBIF agrège iNaturalist (jeu de données `50c9509d-…`), et sur nos 100 images
de test, 100 % venaient de là, hébergées sur `inaturalist-open-data`.
Mesuré sur *Monstera deliciosa* : 125 occurrences CC0, 423 CC BY, 3 535 NC
(refusées).

### 4.3 iNaturalist en direct (fait) — et pourquoi il était indispensable

GBIF ne reçoit d'iNaturalist que les observations de qualité **« research »**,
c'est-à-dire des plantes **sauvages** confirmées par plusieurs personnes. Une
plante d'intérieur en pot est marquée « captive / cultivated », reste
**« casual »**, et n'arrive donc jamais chez GBIF.

C'est exactement le trou constaté à la collecte : *Pilea peperomioides*,
*Calathea orbifolia*, *Zamioculcas zamiifolia* rendaient 0 ou 14 images par
GBIF. Par l'API iNaturalist directe, avec `quality_grade=any` :
Pilea 0 → 56, Zamioculcas 14 → 120, Aspidistra 36 → 120.

`fetchers/inaturalist.py` interroge `api.inaturalist.org/v1`, filtre
`photo_license=cc0,cc-by` côté serveur puis la licence de **chaque photo**
côté client, ignore les photos masquées par la modération, et remplace la
miniature `square` (75 px) par `large` (1024 px).

**Dédoublonnage entre sources** : GBIF relaie les URL iNaturalist telles
quelles, donc la même photo peut arriver deux fois. L'identifiant de photo
extrait de l'URL (`/photos/726492519/`) est stocké dans `extra.photo_id` des
deux côtés et sert de clé — la photo est reconnue **avant** téléchargement.

### 4.4 Wikimedia Commons (fait)

`fetchers/wikimedia.py`, derrière `--wikimedia`. GBIF et iNaturalist
décrivent des observations de terrain ; Commons est une médiathèque, où l'on
photographie son monstera dans son salon. C'est la distribution qui manque au
modèle — le yucca de salon pris pour du maïs vient de là (§ 6.3).

Mesuré sur nos espèces avant d'écrire le connecteur : **97 % des fichiers
portent une licence utilisable**, contre 18 % chez GBIF où les licences non
commerciales écrasent tout. Une catégorie d'espèce contient de l'ordre de la
centaine de fichiers, davantage avec ses sous-catégories : c'est un
complément à GBIF, pas un remplacement.

Trois choix que le connecteur assume :

- **les non-photographies sont écartées sur le titre** (planches botaniques
  du XIX<sup>e</sup>, scans d'herbier, cartes de répartition). Filtre
  grossier : il laisse passer un dessin non nommé et écarte peut-être une
  photo mal titrée ;
- **pas de notion d'observation** : chaque fichier est son propre groupe de
  répartition. Deux photos de la même plante ne seront donc pas gardées
  ensemble ; la déduplication par empreinte perceptuelle, elle, reste
  pleinement efficace ;
- **une panne réseau n'est jamais avalée.** Le bug trouvé au premier essai
  réel : Commons répondait 429, le connecteur rendait une liste vide, et
  l'espèce était annoncée à zéro image alors qu'elle en avait soixante-dix.
  Une source qui tombe doit se voir — `build_dataset` l'écrit `ÉCHEC`, et
  `failed_species.py` la rattrape.

Dans l'application, la même source illustre la fiche espèce :
`WikimediaSpeciesService` cherche les fichiers par nom scientifique
(`intitle:`, espace « Fichier »), écarte les non-photographies sur le titre et
ne garde que les licences affichables (CC0, CC BY, CC BY-SA), puis les ajoute
aux observations GBIF.

### 4.5 Les autres banques d'images — ce qui a été mesuré, et refusé

Le principe, énoncé par le projet : **la provenance des images est séparée de
l'identité taxonomique.** GBIF reste la référence des noms ; une source
supplémentaire ne fait qu'apporter des photos, rattachées à l'espèce
canonique par `species` et `internal_plant_id`, chacune gardant sa
`source`, son `source_id` et sa `license`. Ajouter une banque ne casse donc
rien — la seule question est de savoir si elle apporte des images
*utilisables* et *du bon domaine visuel*.

Sur ce dernier point, une distinction fait tout le tri : une **planche
d'herbier** est une plante séchée, aplatie, cousue sur un carton beige avec
une étiquette. Le modèle doit reconnaître une plante vivante dans un salon.
Ces images ne sont pas un complément faible, elles sont du bruit.

| Source | Accès | Ce que la mesure a donné | Décision |
|---|---|---|---|
| **Wikimedia Commons** | API MediaWiki, sans clé | 97 % de licences utilisables, plantes cultivées | ✅ fait (§ 4.4) |
| **Kew Data Portal** | `records-ws.data.kew.org` (Biocache / Living Atlases), sans clé | sur *Monstera deliciosa*, *Ficus elastica*, *Rosa canina* : **100 % `PRESERVED_SPECIMEN`** et **100 % de licence `other`** — donc refusées par le filtre avant même la question du domaine | ❌ |
| **Smithsonian Gardens** | `s3://smithsonian-open-access`, unité `ofeo-sg`, sans clé — l'API demande un numéro de téléphone américain, le seau non | 23 678 fiches, toutes « Living botanical specimens », 4 884 avec image **CC0** ; mais 1 035 noms pour 217 genres, à très forte dominante d'orchidées (Phalaenopsis 1 086, Dendrobium 467, Oncidium 321). **Recouvrement avec nos 1 445 classes : 6 espèces, 7 photos.** | ❌ |
| **Smithsonian NMNH (Botany)** | idem | planches d'herbier | ❌ |
| **USDA / USFWS / NPS** | — | planches d'herbier et photos de terrain déjà relayées par GBIF | ❌ |
| **Trefle** | API REST, token gratuit | un relais, pas une source : les photos sont celles de **Pl@ntNet** (`bs.plantnet.org`) et de Kew, la licence n'existe qu'en texte libre dans un champ `copyright` — sur *Monstera deliciosa* : 33 images, 24 CC BY-SA, et le filtre naïf en classe une à tort en NC sur le nom de l'auteur | ❌ |
| **Openverse** | API REST, anonyme 20 req/min et **200 req/jour** (mesuré), au-delà client OAuth | méta-moteur : il **relaye nos propres sources** (Flickr, Wikimedia, iNaturalist vu sur *Pilea peperomioides*) mais par leurs titres — aucune identification vérifiée (« Philodendron bipinnatifidum **and a blazing fire** », noms d'avant renommage) ; `license_type=commercial` laisse passer `by-nd`, il faut `commercial,modification` ; Rawpixel : 3 résultats sur *Monstera*, dont 2 illustrations | ❌ |
| **Pexels** | API REST, clé gratuite | licence **maison, hors CC** — illisible pour `licenses.py`, donc refusée par construction ; aucune identification d'espèce (l'`alt` est du texte de référencement) ; le meilleur domaine visuel des trois — plantes en pot en intérieur — mais sans étiquettes | ❌ |
| **iNaturalist Open Data (S3)** | seau AWS public, CSV mensuels | le **même contenu** que le connecteur API, en vrac : inclut CC BY-NC à refiltrer, sans résolution de synonymes ni `captive`/`place_id` — l'API rend le même service avec la couche d'identité en plus | ❌ (redondant) |
| **Roboflow Universe** | web + API, clé | licences **déclarées par l'uploader**, provenance non vérifiée ; étiquettes vernaculaires (« zz plant », « Chloro**pythum** comosum »), classes maladie mêlées aux espèces ; le plus gros jeu « houseplant » : 2 077 images, 24 classes | ❌ |
| **Kaggle « houseplant »** (Houseplant-30, House Plant Species…) | ZIP par dataset | le § 4.1 à l'état pur : Bing/Google scrapé, tri manuel « by non-expert », licence affichée contredite par le texte (« personal use only due to copyright ») ; le meilleur : 14 790 images, 47 classes. Exception trouvée là-bas : PlantCLEF → § 12.8 | ❌ |
| **OGL-3.0, etalab-2.0, CUSTOM-ML** | — | **zéro image** portant ces licences dans nos sources | sans objet |

Le cas Smithsonian Gardens mérite d'être retenu : 4 884 photos CC0 de
plantes vivantes cultivées, c'est exactement le bon domaine visuel, et
c'est pourtant sept images pour nous. Une source ne vaut pas par sa taille
mais par son recouvrement avec le catalogue — la mesure coûte dix minutes
et évite d'écrire un connecteur pour rien. Elle redeviendrait intéressante
le jour où le catalogue s'ouvrirait aux orchidées d'intérieur.

Le cas **Trefle**, mesuré le 17 septembre 2026, est l'inverse de celui de
Smithsonian : le recouvrement serait bon, et c'est la traçabilité qui
manque. Trefle n'est pas une banque d'images mais un agrégateur — son
registre de sources le dit lui-même : sa seule source de photos est
**Pl@ntNet**, et le reste (POWO, WFO, IPNI, GBIF) est de la taxonomie et
des occurrences que nous avons déjà. Sonde sur *Monstera deliciosa*
(`/api/v1/plants/search` puis `/api/v1/species/{id}`, token gratuit) :
**33 images**, toutes servies depuis `bs.plantnet.org` ou le CDN de Kew,
rangées par organe. La licence n'existe que dans un champ `copyright` en
texte libre — « Taken Feb 11, 2017 by Michael Goddard (cc-by-sa) » — sans
code ni URL. Que ce texte ne se parse pas se vérifie en une ligne : le
filtre naïf y classe « Andrea Branca (cc-by-sa) » en non commercial, sur
le seul nom de l'auteur ; à côté, une image sans aucune mention et un
« Taken Jan 1, 1900 by EOL ». La règle du § 4.1 tranche sans appel :
licence inconnue ou illisible, image refusée — et ici elle est illisible
par construction. Même lue à la main, la récolte annonçait son profil :
24 images CC BY-SA, six NC, trois © Kew, et presque tout en gros plans
fleur/feuille, comme au § 12.8. Les mêmes photos, avec des licences
structurées et un téléchargement en masse, sont dans PlantNet-300K : la
porte reste celle du § 12.8, plafonnée et `habit` d'abord.


### 4.6 PlantNet-300K — étude et décision

Faits vérifiés (Zenodo, enregistrement 5645731, v1.1) :

| | |
|---|---|
| Contenu | 306 146 images, 1 081 espèces, splits train/val/test fournis |
| Licence des données | **CC BY 4.0** |
| Code d'accompagnement | BSD-2 |
| Taille | 31,67 Go |
| Particularités | très forte asymétrie (longue traîne), ambiguïté intra-genre voulue, flore surtout **européenne de terrain** |

**Peut-on l'utiliser commercialement ?** Oui : CC BY 4.0 autorise l'usage
commercial et les dérivés, contre attribution (Pl@ntNet / Garcin et al.,
NeurIPS 2021 Datasets & Benchmarks).

**Décision : ne pas en faire la base du modèle de l'app.** Trois raisons :

1. **Couverture** : ses 1 081 espèces sont celles de la flore sauvage
   d'Europe de l'Ouest. **Mesuré depuis** (§ 12.8) : 108 espèces communes
   avec nos 1 457 classes, 7,4 %. *Monstera*, *Epipremnum* et *Spathiphyllum*
   n'y sont effectivement pas ; seize de nos plantes d'appartement s'y
   trouvent en revanche, et en nombre.
2. **Poids** : 32 Go et 300 000 images pour un modèle qui doit tenir dans
   quelques Mo sur téléphone et n'apprend qu'une liste choisie d'espèces.
3. **Distribution** : les photos de terrain (fleurs, feuilles isolées)
   ressemblent peu à celles que prend un utilisateur de son pot sur le
   rebord de fenêtre.

**Ce qu'on en garde** : (a) un **pré-entraînement** possible — un réseau
d'abord entraîné sur PlantNet-300K, puis affiné sur notre jeu, converge plus
vite et généralise mieux qu'un réseau ImageNet ; à essayer en phase 2 si les
résultats de la phase 1 sont insuffisants ; (b) un **jeu d'évaluation
externe** pour les espèces communes aux deux listes ; (c) son protocole
d'évaluation (macro-average top-k), utile parce que nos classes seront
elles aussi déséquilibrées.

## 5. Jeu de données : structure

```
tools/plant_dataset/
  plants.csv                 liste de référence (versionnée)
  dataset/                   IGNORÉ PAR GIT
    manifest.jsonl           une ligne par image : species, internal_plant_id, source,
                             source_id, observation_id, original_url, image_url, author,
                             license, license_url, downloaded_at, checksum, path,
                             width, height, phash, status, reason, duplicate_of, extra
    splits.csv               path, species, internal_plant_id, split, group
    stats.json               décomptes
    ATTRIBUTIONS.md / attributions.csv
    species.json             réponse GBIF par nom
    Monstera_deliciosa/<sha16>.jpg …
    _rejected/ _duplicates/ _review/
```

Le manifeste est la seule vérité : les dossiers se reconstruisent à partir de
lui. Statuts : `kept`, `duplicate`, `rejected`, `review`.

Nettoyage : lisibilité, orientation EXIF, côté ≥ 320 px, proportions
≤ 1:12, réduction à 1024 px, JPEG ; doublons exacts (SHA-256) et
quasi-doublons (pHash DCT 64 bits, Hamming ≤ 6) au sein d'une espèce ;
le même visuel sous deux espèces → `review`.

Répartition : 80 / 10 / 10 **par groupe** (une observation et ses
quasi-doublons ne se séparent jamais), déterministe par empreinte.

Comment lancer, options, résultat attendu : `tools/plant_dataset/README.md`.

## 6. Entraînement

### 6.1 Collecte phase 1 — résultat réel

Lancée sur les 95 plantes d'intérieur et succulentes du catalogue
(`SpeciesCategory.indoor` + `succulent`), cible 120 images par espèce :

| | |
|---|---|
| Images gardées | **8 825** sur 9 309 téléchargées |
| Espèces avec des images | 87 sur 95 |
| Licences | 5 401 CC BY 4.0, 3 424 CC0 1.0 — **aucune autre** |
| Sources | 6 129 GBIF, 2 696 iNaturalist en direct |
| Doublons | 0 exact, 380 quasi (écartés) |
| Étiquettes douteuses | 0 |
| Répartition | 7 077 train / 863 val / 885 test |
| Disque | 2,8 Go |

Répartition par espèce : 66 au-dessus de 100 images, 10 entre 50 et 99,
6 entre 25 et 49, 5 en dessous de 25. Les plus pauvres — *Echinocactus
grusonii* (1), *Begonia rex* (8), *Cissus rhombifolia* (8) — sont écartées
du modèle par le seuil `--min-train` : une classe à 8 images n'apprend rien
et fausse la mesure. Elles restent identifiables par Pl@ntNet.

Les 8 espèces sans aucune image sont des noms horticoles que ni GBIF ni
iNaturalist ne connaissent sous cette forme (`Dracaena marginata`,
`Saintpaulia ionantha`…). Elles seront rattachées à leur nom accepté lors
d'une prochaine passe.

### 6.2 Résultats du modèle v3 — catalogue complet

| | v1 | **v3** |
|---|---|---|
| Espèces collectées | 87 | **585** |
| Images | 8 825 | **65 999** |
| Classes du modèle | 78 | **542** |
| Taille TFLite | 2,0 Mo | **2,6 Mo** |
| Top-1 (test) | 63,8 % | **44,2 %** |
| Top-3 (test) | 81,3 % | **60,0 %** |
| Macro-F1 | 0,642 | **0,425** |

La baisse était attendue et annoncée : sept fois plus de classes, dont
beaucoup de plantes sauvages proches entre elles (érables, sapins, chênes).
Ce qu'on gagne est la couverture — 542 espèces nommables au lieu de 78.

Courbe seuil / repli mesurée sur 6 284 images de test :

| Seuil | Acceptées | Précision |
|---|---|---|
| 0,80 | 23 % | 89,5 % |
| 0,90 | 16 % | 94,7 % |
| 0,95 | 11 % | 97,4 % |

À 0,90 le modèle ne tranche seul que dans 16 % des cas, contre 30 % au v1.
Le reste part chez Pl@ntNet, comme avant.

**Trois défauts trouvés pendant cet entraînement**, tous corrigés :

1. **Mémoire** — `from_tensor_slices` recopie le tableau numpy dans le
   graphe : 13,9 Go pour un tableau de 4,9, et le processus tué. Remplacé
   par un générateur qui lit le tableau en place.
2. **Mélange** — `splits.csv` est trié par espèce, et le tampon de mélange
   de 4 096 éléments ne couvrait que 38 espèces sur 542. Chaque lot était
   quasi monospécifique : 31 % à l'entraînement contre 9 % en validation.
   Mélange global de la liste avant `tf.data` ; la validation à la première
   époque est passée de 6,2 % à 23,5 %.
3. **Déduplication** — comparaison de toutes les paires, soit un milliard
   pour 45 000 images. Remplacée par un partitionnement en bandes
   (principe des tiroirs) : 13,7 millions de paires en neuf secondes.

**Le prétraitement de service, mesuré sur le `.tflite` exporté** :

| Chaîne appliquée à la photo | Top-1 |
|---|---|
| comme l'entraînement (bilinéaire sans anticrénelage) | **42,2 %** |
| avec anticrénelage (PIL, ImageMagick…) | 38,5 % |

3,7 points séparent les deux : la façon de réduire l'image compte autant
qu'un choix d'architecture. Les images du jeu ont été réduites en deux
temps — moyenne de zone jusqu'à 448 px au stockage, puis bilinéaire jusqu'à
256 à l'entraînement. L'application refait exactement ces deux étapes
(`source_size`, `load_size` dans `model.json`) ; sans quoi une photo de
téléphone de 4 000 px, ramenée d'un coup à 256, arriverait bien plus
crénelée que tout ce que le modèle a vu.

### 6.3 Le yucca de salon : ce que le modèle n'avait jamais vu

Sur une photo idéale d'un yucca en pot — plein jour, fond blanc, spécimen
typique — le modèle v3 a répondu *maïs* à 59 %, sans aucun Yucca dans les
trois premiers. Pl@ntNet : *Yucca gigantea* à 96 %. L'espèce est pourtant
une de ses 542 classes, avec 120 images d'entraînement.

Les 120 images viennent toutes de GBIF, et douze tirées au hasard montrent
douze arbres sauvages — broussailles, ciel, hampes florales. GBIF ne reçoit
que les observations de plantes sauvages, et le collecteur ne demandait
iNaturalist qu'en complément, quand GBIF ne suffisait pas. Pour toutes les
plantes d'intérieur que GBIF pouvait fournir seul, le modèle a donc appris
la forme sauvage et jamais la forme cultivée. C'est un défaut de conception
de la collecte, et il touche précisément les espèces que les utilisateurs
photographient.

Correction, dans `build_dataset.py` :

- `--captive-file` / `--captive-share` : pour les espèces listées, une part
  de la cible (50 % par défaut) est réservée **d'abord** à iNaturalist avec
  le filtre `captive=true` — des plantes en pot, chez des gens. GBIF vient
  ensuite, puis iNaturalist sans filtre s'il manque encore des images.
- `splits.csv` porte une colonne `captive`, et l'entraînement mesure la
  précision **séparément sur ces photos** : c'est le seul chiffre qui décrit
  ce que l'application fera sur les photos de ses utilisateurs. Les seuils
  de `FallbackPolicy` seront recalés dessus, pas sur les plantes sauvages.

### 6.4 Résultats du modèle v4 — plantes cultivées et réseau large

| | v3 | **v4** |
|---|---|---|
| Plantes au catalogue de collecte | 600 | **970** |
| Images | 65 999 | **110 625** (14 715 cultivées) |
| Classes du modèle | 542 | **846** |
| Réseau | MobileNetV3-Small | **MobileNetV3-Large** |
| Taille TFLite | 2,6 Mo | **7,7 Mo** |
| Top-1 (test, 10 582 images) | 44,2 % | **50,2 %** |
| Top-3 (test) | 60,0 % | **65,9 %** |
| Macro-F1 | 0,425 | **0,476** |
| Top-1 sur plantes cultivées (1 384 images) | — | **58,4 %** |
| Top-3 sur plantes cultivées | — | **73,5 %** |
| Entraînement | | 4 + 14 époques, 3 h 40 sur 4 cœurs |

Trois choses ont changé en même temps, et il faut les lire ensemble :

1. **Le catalogue de collecte a été nettoyé.** L'extension à 1 097 espèces
   avait fait entrer 127 animaux par homonymie de genre — « Batis » est un
   arbuste et un gobe-mouches, « Oenanthe » une ombellifère et un traquet.
   GBIF les avait tous rejetés au rang du genre, aucun n'a reçu d'image, et
   les 925 espèces avec images sont toutes vérifiées du règne Plantae. Le
   même défaut touchait le catalogue étendu de l'app (`catalog.tsv`) :
   1 242 animaux, champignons et chromistes écartés après vérification de
   chaque nom auprès de GBIF (voir `tool/README.md`).
2. **Les plantes d'intérieur ont été recollectées en pot** (§ 6.3) : 7 560
   images ajoutées sur les 95 espèces d'intérieur, dont 5 581 photos de
   plantes cultivées. Le chiffre qui compte est la dernière ligne du
   tableau : sur des photos de plantes en pot, chez des gens, la bonne
   espèce est première une fois sur deux et dans les trois premières trois
   fois sur quatre.
3. **Le réseau est passé en Large**, trois fois plus de calcul et cinq
   mégaoctets de plus dans l'app, contre six points de top-1 sur un
   problème pourtant plus dur (846 classes au lieu de 542). Sur l'iPhone,
   l'inférence reste sous la demi-seconde.

Le sur-apprentissage est net à partir de la dixième époque de réglage fin
(entraînement 79 %, validation 51 %) : la prochaine marge est dans les
données et l'augmentation, pas dans les époques.

Courbe seuil / repli mesurée sur le test complet, puis sur les plantes
cultivées seules :

| Seuil | Acceptées (test) | Justesse | Acceptées (cultivées) | Justesse |
|---|---|---|---|---|
| 0,50 | 65 % | 68 % | 72 % | 73 % |
| 0,70 | 47 % | 79 % | 57 % | 83 % |
| 0,80 | 40 % | 84 % | — | — |
| 0,90 | 32 % | 89 % | 41 % | 92 % |

Le seuil d'acceptation reste à 0,70 : sur une plante en pot, le modèle
répond seul une fois sur deux et a raison cinq fois sur six. L'écran
propose de toute façon cinq candidats et la recherche en ligne à un geste.

Le modèle exporté a été rejoué en TFLite avec le prétraitement exact de
l'application (recadrage carré, réduction à 448 puis 256, découpe centrale
224) sur 288 images de test : top-1 52 %, top-3 64 %, et sur les 41 plantes
cultivées de l'échantillon 66 % et 80 %. Ce que le téléphone calcule est
bien ce que l'entraînement a mesuré.

### 6.5 Résultats du modèle v5 — plus de plantes d'appartement, CC BY-SA

| | v4 | **v5** |
|---|---|---|
| Plantes au catalogue de collecte | 970 | **1 032** |
| Images | 110 625 | **130 783** |
| Classes du modèle | 846 | **894** |
| Top-1 (test, 12 661 images) | 50,2 % | **51,9 %** |
| Top-3 (test) | 65,9 % | **67,2 %** |
| Macro-F1 | 0,476 | **0,477** |
| Top-1 sur plantes cultivées (2 795 images) | 58,4 % | **59,7 %** |
| Top-3 sur plantes cultivées | 73,5 % | **73,8 %** |
| Entraînement | 4 + 14 époques, 3 h 40 | 4 + 12 époques, 5 h 15 |

Entre les deux : 62 plantes d'appartement courantes ajoutées au catalogue
(pothos, calathéas, philodendrons, dracaenas, rose du désert, cactus de
salon…), dix espèces recollectées en pot, une passe « cultivé en Europe »,
et l'entrée de CC BY-SA. Le gain global est modeste, un point et demi de
top-1 sur un problème plus large de 48 classes ; ce qui compte davantage,
c'est que ces 48 plantes existent désormais pour le modèle.

Ce que l'on sait des espèces testées par l'éditeur sur ses propres
plantes, mesuré sur les photos cultivées de validation et de test :

| Espèce | Top-1 | Top-3 | Ce qui se passe |
|---|---|---|---|
| Adenium obesum (rose du désert) | 69 % | 88 % | absente de la v4, apprise |
| Pilea peperomioides | 92 % | 100 % | 56 images seulement, forme unique |
| Zamioculcas zamiifolia | 65 % | 81 % | |
| Beaucarnea recurvata | 56 % | 77 % | |
| Yucca gigantea | 52 % | 59 % | photos « cultivées » = arbres de jardin |
| Ficus microcarpa (ficus ginseng) | 27 % | 59 % | l'arbre de rue et le bonsaï dans une classe |

Le ficus ginseng est le cas d'école : la même espèce est un arbre de rue de
vingt mètres à Taïwan et un bonsaï à racines renflées chez un fleuriste
européen, et le modèle doit les mettre dans la même case. Les rejeux des
photos de l'éditeur (recadrées depuis des captures d'écran, donc
approximatifs) donnent : oiseau du paradis reconnu à 88 % ; yucca, ficus
ginseng et rose du désert toujours faux, sous le seuil de 70 % pour les
deux premiers — l'app montre alors ses doutes et propose la recherche en
ligne — mais à 63 % pour un « Ficus benjamina » devant la rose du désert,
juste sous le seuil. Le vrai remède reste des photos de plantes en pot
dans des salons, rares sous licence libre (§ 6.3).

Courbe seuil / repli sur les plantes cultivées : à 0,70 le modèle répond
seul dans 55 % des cas avec 85 % de justesse ; à 0,90, 40 % et 94 %. Le
seuil reste à 0,70.

Trois espèces n'ont reçu aucune image faute de nom reconnu par les
sources : Citrus limon (GBIF sans occurrence sous ce nom, iNaturalist sans
correspondance), Goeppertia orbifolia (connue comme Calathea orbifolia) et
Streptocarpus ionanthus (Saintpaulia ionantha). À résoudre par
`synonyms.txt` avant la v6.

### 6.6 Résultats du modèle v6 — 1 445 espèces, entraîné au goutte-à-goutte

Le catalogue de collecte est passé à 1 558 plantes (les 530 espèces
cultivées les plus observées en Europe s'ajoutant aux 1 030 d'avant), et le
modèle est entraîné.

| | v5 | **v6** |
|---|---|---|
| Plantes au catalogue de collecte | 1 032 | **1 558** |
| Espèces avec au moins une image | 984 | **1 509** |
| Images gardées | 130 783 | **290 518** |
| Classes du modèle | 894 | **1 445** |
| Taille TFLite | 7,8 Mo | **8,8 Mo** |
| Top-1 (test) | 51,9 % | **52,2 %** |
| Top-3 (test) | 67,2 % | **67,6 %** |
| Macro-F1 | 0,477 | **0,503** |
| Entraînement | 4 + 12 époques, 5 h 15 | 40 + 12 époques, 9 h 47 |

Ces deux colonnes **ne se comparent pas** : chaque modèle a été mesuré sur
le jeu de test de sa propre collecte, et celui de la v6 est plus dur — 551
classes de plus, dont beaucoup d'espèces de jardin proches entre elles. Le
seul chiffre lisible entre les deux est le macro-F1, qui monte de 2,6 points
sur un problème 61 % plus large : les classes rares sont mieux traitées.

#### La comparaison qui décide, à armes égales

`tools/plant_model/compare_models.py` fait passer les deux modèles sur **les
mêmes images** — le test de la v6 — en ne gardant que les 889 espèces
qu'ils connaissent tous les deux, et en masquant chez la v6 les classes que
la v5 n'a pas. C'est la seule mesure qui dise ce que l'utilisateur gagne.

| 889 classes communes (5 000 images) | v5 | **v6** |
|---|---|---|
| Top-1 | 48,6 % | **57,3 %** |
| Top-3 | 64,1 % | **72,1 %** |
| Justesse quand le modèle répond seul (0,70) | 77,7 % | **88,9 %** |

| plantes cultivées, classes communes (1 666 images) | v5 | **v6** |
|---|---|---|
| Top-1 | 57,1 % | **60,4 %** |
| Top-3 | 71,8 % | **74,1 %** |
| Justesse quand le modèle répond seul (0,70) | 83,4 % | **89,9 %** |

Et 513 espèces que la v5 ne pouvait pas nommer du tout sont reconnues à
50,3 % en top-1.

Le gain le plus utile n'est pas le top-1 mais les **onze points de justesse
quand le modèle tranche seul** : moins de mauvaises réponses affirmées, et
moins d'appels à Pl@ntNet.

#### Le seuil a été remesuré

Un seuil ne se transporte pas d'un modèle à l'autre. La v6 répartit sa
confiance sur 1 445 candidats au lieu de 894, donc le 0,70 de la v5 la
rendait trop prudente. Mesuré sur les photos de plantes cultivées, dans le
calcul exact que fait la cascade :

| seuil | une photo | deux photos |
|---|---|---|
| 0,70 | 42 % de réponses seules, 86,0 % justes | 34 %, 93,5 % |
| **0,60** | **47 %, 82,8 %** | **38 %, 92,3 %** |
| 0,50 | 55 %, 74,3 % | 44 %, 88,4 % |

`acceptThreshold` passe donc à **0,60**.

#### Deux photos valent dix-neuf points

La mesure la plus rentable de toute cette version n'a demandé aucun
entraînement. `splits.csv` regroupe les photos d'une même observation ;
2 000 observations de trois photos donnent, dans le calcul de la cascade :

| | 1 photo | 2 photos | 3 photos |
|---|---|---|---|
| Top-1, toutes espèces | 47,6 % | 61,5 % | **66,4 %** |
| Top-1, plantes cultivées | 48,5 % | 59,5 % | **67,5 %** |
| Justesse quand le modèle répond seul (0,60) | 82,8 % | 92,3 % | 92,9 % |

Dix-neuf points, contre 8,7 pour dix heures de calcul et 160 000 images de
plus. La fusion se fait par **moyenne géométrique** — elle exige que les
photos soient d'accord, là où la moyenne arithmétique pardonne à une photo
ratée, et elle vaut cinq points de plus qu'elle.

Deux pièges, tous deux tenus par des tests. Une espèce absente de la liste
d'une photo ne vaut pas zéro, sinon le produit s'annule et elle disparaît :
elle vaut la borne connue, sous le plus petit score rendu. Et le résultat
est remis à l'échelle de la masse que les listes couvraient **en moyenne**,
non à 1 : viser 1 fabriquerait de la confiance, deux photos ne rendant qu'un
candidat à 0,30 puis 0,90 en sortiraient à 1,00 au lieu de 0,60. Détails :
`tools/plant_model/multi_photo.py` et `cascade_identifier.dart`.

Le chiffre est un plafond optimiste : les photos d'une observation viennent
de la même séance, sous la même lumière. Les quasi-doublons ayant été
écartés à la collecte, elles restent visuellement distinctes.

#### Ce que l'entraînement a coûté, et ce qu'on en a appris

Neuf heures 47 sur quatre cœurs sans carte graphique, sur une machine
recyclée dès que la session s'endort. Trois passes précédentes avaient été
perdues. Ce qui a changé :

- la collecte est découpée en parts disjointes qui tiennent sur les quatre
  cœurs : 1 558 espèces en 3 h 49 au lieu de près de sept heures ;
- la phase de tête n'est plus qu'une passe avant. Le réseau y est gelé,
  donc ses sorties ne changent pas d'une époque à l'autre : on les calcule
  une fois (`--feature-cache`) et la tête s'entraîne dessus en quelques
  minutes au lieu de quatre fois trente minutes ;
- cet encodage, comme le réglage fin, **reprend où il s'arrête**. C'est ce
  qui a permis d'avancer par tranches de dix minutes entre deux réveils ;
- le décodage JPEG n'est pas le goulot, contrairement à ce que la recette
  supposait : 630 images/s cache froid contre 93 pour le réseau.

Trois hybrides horticoles n'ont aucune image, faute de nom reconnu par
GBIF : Hylotelephium × mottramianum, Salvia × floriferior et
Amelanchier × spicata.

### 6.7 Résultats du modèle v7 — trois drapeaux, une heure

Rien n'a changé du côté des sources : mêmes GBIF et iNaturalist que la v6,
pas de Wikimedia Commons (§ 12.2 l'attend toujours). La collecte a été
refaite de bout en bout — 1 558 plantes au catalogue, 1 507 avec des images,
290 131 images gardées — et elle reproduit celle de la v6 à quelques
centaines d'images près.

Ce qui a changé tient en quatre décisions :

| | |
|---|---|
| Répartition réparée + `--min-val 1` | 1 444 → **1 457 classes** (§ 12.1) |
| `--dropout 0.5` | contre les dix-huit points de sur-apprentissage de la v6 |
| `--unfreeze 100` | cent couches dégelées au lieu de soixante |
| `--input-size 320` | l'entrée du réseau, le jeu étant stocké à 448 px |

#### Une recette à la fois

C'est la règle du § 12, et elle a payé : chaque essai se lit contre le
précédent, sur **le même jeu de test et les mêmes classes**.

| | référence | + dropout 0,5 | + unfreeze 100 | + 320 px |
|---|---|---|---|---|
| top-1 | 0,5162 | 0,5296 | 0,5467 | **0,5960** |
| top-3 | 0,6685 | 0,6805 | 0,6985 | **0,7434** |
| macro-F1 | 0,4981 | 0,5114 | 0,5277 | **0,5796** |
| cultivées top-1 | 0,5335 | 0,5433 | 0,5623 | **0,5981** |
| confiance moyenne | 0,5998 | 0,5430 | 0,5667 | 0,6280 |

Trois choses que ce tableau apprend, et qu'une recette unique aurait cachées :

1. **Le dropout ne gagne pas que de la précision, il recalibre.** La confiance
   moyenne chute de 5,7 points sans que la justesse baisse : le modèle annonce
   moins et se trompe moins. C'est ce qui déplace toute la courbe de seuil.
2. **`--unfreeze 100` n'aurait pas marché seul.** Il rapporte 1,71 point *parce
   que* le dropout tient le sur-apprentissage. Dégeler cent couches sur la
   recette de base aurait probablement empiré les choses.
3. **Le macro-F1 gagne autant que le top-1** (+8,15 contre +7,98 au total). Le
   gain ne se concentre pas sur les espèces fréquentes ; la résolution profite
   surtout aux distinctions fines entre espèces proches, c'est-à-dire aux
   classes rares.

#### La comparaison qui décide

Les `model.json` de deux versions ne se comparent pas — jeux de test
différents. `compare_models.py` fait passer les deux modèles sur **les mêmes
images**, sur les 1 439 classes qu'ils connaissent tous les deux :

| 1 439 classes communes (6 000 images) | Iris 6 | **Iris 7** | |
|---|---|---|---|
| top-1 | 51,67 % | **58,93 %** | +7,26 pt |
| top-3 | 67,93 % | **74,37 %** | +6,44 |
| au seuil 0,70 | 43 % acceptées, 84,5 % justes | **46,8 %, 89,1 %** | +3,8 et +4,6 |

| plantes cultivées (2 000 images) | Iris 6 | **Iris 7** | |
|---|---|---|---|
| top-1 | 53,70 % | **59,45 %** | +5,75 pt |
| top-3 | 68,85 % | **73,30 %** | +4,45 |
| au seuil 0,70 | 49,6 %, 83,8 % | **51,4 %, 87,1 %** | +1,9 et +3,3 |

Plus **18 espèces qu'Iris 6 ne pouvait pas nommer du tout**, reconnues à
44,6 % en top-1 et 62,5 % en top-3.

Le point remarquable n'est pas l'ampleur mais la **direction** : d'ordinaire,
gagner en justesse coûte de l'autonomie — un modèle plus prudent répond moins
souvent. Ici les deux montent ensemble. Au seuil de l'application, Iris 7
répond seule plus souvent *et* se trompe moins.

#### Deux photos valent quatorze points

Dans le calcul exact de la cascade (listes de cinq candidats, plantes
cultivées) :

| | top-1 | top-3 | à 0,70 |
|---|---|---|---|
| 1 photo | 52,24 % | 66,27 % | 47 % de réponses seules, 85,9 % justes |
| **2 photos** | **65,97 %** *(+13,7)* | 80,00 % | 35 %, **94,1 %** |
| **3 photos** | **74,63 %** *(+22,4)* | 87,46 % | 35 %, **96,6 %** |

La v6 donnait +11,0 et +19,0 sur la même mesure. Le geste le plus rentable de
l'application l'est devenu un peu plus — et il ne coûte toujours pas une
milliseconde de calcul.

#### Le seuil remonte, pour la première fois

`acceptThreshold` passe de 0,60 à **0,70**. Les deux versions précédentes
avaient dépensé leur surplus de justesse en autonomie ; Iris 7 permet
l'inverse. **À 0,70 elle rend exactement l'autonomie qu'avait la v6 à 0,60 —
47 % — avec 85,9 % de justesse au lieu de 82,8 %.**

C'est le bon arbitrage parce que la réponse acceptée est la plus coûteuse à
rater : elle s'affiche comme « probable », et c'est celle sur laquelle
l'utilisateur ne se pose pas de question. Une liste seulement plausible est
montrée avec ses cinq candidats, et il tranche lui-même.

#### Ce que ça a coûté

**Une heure de carte graphique**, contre 9 h 47 pour la v6 sur quatre cœurs.
Neuf minutes d'encodage des vecteurs, une minute de tête, dix minutes de
réglage fin par recette — les recettes 1 et 2 réutilisant le cache, seule
celle des 320 px l'a fait réencoder. C'est ce qui a rendu possible de
n'essayer qu'un changement à la fois.

Le seul prix à la livraison est **l'inférence sur le téléphone** :
(320/224)² ≈ 2, donc de l'ordre d'une seconde au lieu d'une demi-seconde. Le
`.tflite` ne bouge pas — 8,8 Mo — parce que MobileNetV3 est entièrement
convolutif et que sa tête part d'une moyenne globale : le nombre de poids ne
dépend pas de la résolution d'entrée. Et le modèle a pu être livré sans
toucher au code : `tflite_plant_model.dart` lit `input_size`, `load_size` et
`source_size` dans `model.json`, avec 224 / 256 / 448 seulement comme
valeurs par défaut.

**Cette seconde-là n'était pas une attente, c'était un gel.** La première
version de ce paragraphe comparait deux latences ; il fallait comparer deux
blocages. `classify()` appelait `interpreter.run()` sur l'isolat principal :
pendant tout le calcul, l'application ne redessinait plus, ne répondait plus
au doigt, et la cascade enchaînant les photos une par une, trois photos
faisaient trois secondes d'écran mort — que l'utilisateur lit comme une
panne, pas comme un calcul. Ça ne renverse pas l'arbitrage des 320 px,
parce que le correctif est indépendant et qu'il ne coûte aucun point :

- **l'inférence est partie dans un isolat.** `tflite_flutter` 0.12.1, déjà
  épinglé, fournit `IsolateInterpreter` : le calcul tourne à côté,
  l'interface reste vivante. Une file d'un seul rang le protège, parce que
  cet isolat, rappelé pendant qu'il travaille, rend la main **sans rien
  exécuter** — l'appelant lirait alors un vecteur de zéros, une réponse
  fausse plutôt qu'une erreur ;
- **l'entrée est passée à plat.** Les listes imbriquées coûtaient 102 400
  listes et 307 200 nombres emballés, recopiés un par un au retour de
  l'isolat de décodage, puis reconvertis élément par élément vers le tenseur
  natif. Un `Float32List` traverse en un bloc ; et donné à TFLite sous sa
  vue en octets — le seul type qu'il recopie tel quel — il devient un memcpy
  d'un mégaoctet au lieu de 307 200 conversions.

Le gel, lui, ne se mesure pas au banc : il se voit sur un téléphone. Ce qui
reste à vérifier sur l'appareil, c'est l'inférence elle-même à 320 px, la
demi-seconde du § 6.4 n'ayant jamais été remesurée depuis.

### 6.7 bis Résultats de l'Iris 8 — collecter large, livrer étroit

La v8 devait élargir le répertoire : 4 220 espèces candidates collectées en
vingt-deux heures, 991 926 images gardées, **5 259 classes entraînées**
(§ 12.11). Elle ne l'a pas élargi d'une espèce, et elle a quand même été la
plus grosse avancée de qualité depuis la v3. Voici pourquoi.

#### La mesure qui a tout décidé

`compare_models.py` fait passer les deux modèles sur les **mêmes** 6 000
images, sur les 1 444 classes qu'ils connaissent tous les deux. Mais il
masque les sorties que l'autre modèle n'a pas — et ce masque retire 13
classes à l'Iris 7 contre **3 815** à l'Iris 8. Le chiffre obtenu répond donc
à « ce réseau-ci, s'il n'avait à choisir que parmi les espèces de l'autre »,
pas à ce que l'utilisateur reçoit. D'où la seconde lecture, sorties
entières :

| 1 444 classes communes, 6 000 mêmes images | Iris 7 | Iris 8 à 5 259 classes |
|---|---|---|
| **sorties masquées** — qualité du réseau | 0,5863 | **0,6543** (+6,8) |
| **sorties entières** — ce que l'application rend | 0,5862 | **0,5528** (−3,3) |
| plantes cultivées, sorties entières | 0,5990 | **0,5300** (−6,9) |

La ligne de l'Iris 7 ne bouge que d'un dix-millième entre les deux lectures :
la comparaison est propre, tout l'écart vient de l'Iris 8.

**Dix points séparent les deux lectures du même réseau sur les mêmes
photos** — onze sur les plantes cultivées. C'est la mesure la plus directe
qu'on ait du prix de l'étendue, et elle confirme au dixième près
l'estimation du § 12.12, obtenue autrement. Les 3 815 espèces nouvelles ne
se contentent pas d'être mal reconnues : **elles volent les réponses des
anciennes.**

#### Retailler plutôt que réentraîner

Le réseau n'avait donc pas besoin d'être réappris, mais d'être **borné**. Et
la borne n'a pas sa place dans l'application : `assets/species/catalog.tsv`
porte 36 342 noms — plus que le modèle — et `CatalogCareGuide` résout
l'entretien espèce → genre → famille → catégorie, si bien que l'application
sait déjà dire quelque chose de presque n'importe quoi. Il n'existe aucun
ensemble « ce que l'app sait afficher » à quoi masquer.

`tools/plant_model/retailler.py` la met donc dans le modèle : on reprend les
poids appris, on ne garde dans la dernière couche que les colonnes voulues,
on réexporte. **Ce n'est pas un réentraînement** — quelques minutes, dont
l'essentiel en réévaluation.

Et ce n'est pas non plus une approximation : le softmax d'une tête tronquée
vaut `exp(zᵢ) / Σ_gardées exp(zⱼ)`, c'est-à-dire exactement un masque suivi
d'une renormalisation. La lecture `compare_models --restreint` **est** la
mesure du fichier produit.

#### Ce qui est livré

1 444 classes, les mêmes que l'Iris 7 moins treize.

| `model.json`, chacun sur son propre test | Iris 7 | **Iris 8** |
|---|---|---|
| classes | 1 457 | 1 444 |
| top-1 | 0,5961 | **0,6627** |
| top-3 | 0,7435 | **0,8047** |
| macro-F1 | 0,5796 | **0,6472** |
| plantes cultivées, top-1 | 0,5979 | **0,6483** |
| seuil 0,70 / marge 0,25 | 47,3 % acceptées, 89,8 % justes | **54,9 %, 91,3 %** |
| taille | 8,79 Mo | 8,77 Mo |

**Plus autonome *et* plus juste au même seuil.** Il n'y a pas d'arbitrage :
`FallbackPolicy` ne bouge pas, huit identifications sur cent cessent
d'appeler Pl@ntNet, et celles que l'application tranche seule sont plus
souvent vraies. À titre de comparaison, le passage de la v6 à la v7 avait
demandé de *monter* le seuil pour obtenir moins que ça.

Le chiffre publié et le chiffre rigoureux bougent ici dans le même sens
(+6,7 et +6,8) — assez rare pour être noté : aucune des deux mesures ne
raconte d'histoire.

#### Combien d'espèces exposer ? La courbe, et ce qu'elle refuse de donner

`retailler.py` fait de l'ensemble exposé un **cadran**. Restait à savoir où
le tourner : le § 6.7 bis ne connaissait que les deux bouts, 1 444 → 0,6543
et 5 259 → 0,5528.

`tools/plant_model/courbe.py` lit toute la courbe en **une seule passe
d'inférence** : masquer un softmax aux classes gardées puis le renormaliser
donne exactement ce que rendrait un modèle retaillé à ces classes, si bien
que chaque taille n'est plus qu'une addition sur les mêmes probabilités.
Le tirage reproduit celui de `compare_models.py` — même graine, même
filtre — donc la ligne du cœur seul doit retomber sur les chiffres publiés.
Elle l'a fait au dix-millième : c'est ce qui permet de lire le reste.

#### Il n'y a pas d'espèces gratuites, et c'est une mesure

Une espèce ne coûte que si elle passe devant la bonne réponse. On a donc
compté, pour chacune des 3 815 candidates, combien d'images du cœur elle
ferait basculer de juste à fausse — son **coût de vol** — puis ajouté par
coût croissant, la priorité de culture ne départageant que les ex æquo.
**La sélection se fait sur la validation et la mesure sur le test** : choisir
et mesurer sur les mêmes images aurait flatté le résultat. C'est cette
séparation qui a tout dit.

| sur 12 000 images de validation | |
|---|---|
| images que le cœur seul reconnaît | 7 849 |
| candidates qui n'en volent **aucune** | **2 202** |
| candidates qui en volent plus de 20 | **0** |

Deux mille deux cents espèces gratuites, donc — sur la validation. Sur le
test, les exposer coûte au cœur **5,9 points de top-1**. « Ne rien voler sur
7 849 images » ne se transporte pas : le vol est réel, simplement trop
diffus pour qu'aucune image de validation ne l'attrape. Aucune candidate ne
dépasse 20 vols sur 7 849 — **il n'y a pas de brebis galeuses à écarter**,
et c'est pour ça qu'il n'y a pas de coude.

#### Le prix d'une espèce exposée

| espèces exposées | cœur, top-1 | autonomie | justesse | espèces ajoutées, top-1 |
|---|---|---|---|---|
| 1 444 | 0,6543 | 54,2 % | 0,9081 | — |
| 1 800 | 0,6418 | 51,9 % | 0,9101 | 0,6761 |
| 2 200 | 0,6290 | 50,1 % | 0,9082 | 0,6413 |
| 2 800 | 0,6138 | 47,9 % | 0,9050 | 0,5982 |
| 3 646 | 0,5952 | 45,6 % | 0,8988 | 0,5802 |
| 4 400 | 0,5753 | 42,6 % | 0,8932 | 0,5502 |
| 5 259 | 0,5528 | 39,7 % | 0,8870 | 0,5230 |

**Le coût est régulier : 0,22 à 0,35 point de top-1 par tranche de cent
espèces**, et il ne s'emballe nulle part. Ordonner par coût de vol plutôt
que par priorité de culture rend 0,4 à 1,2 point selon la taille — **et
jusqu'à 3,5 points sur les plantes en pot**, où l'ordre par culture faisait
entrer les sosies du cœur en premier. Le gain est réel ; il ne crée pas de
coude pour autant.

> **Ce que l'étendue coûte, c'est l'autonomie, pas la justesse.** De 1 444 à
> 5 259 sorties, le top-1 perd 10,2 points et l'autonomie 14,5 — mais la
> justesse des réponses acceptées ne perd que 2,1. Un catalogue plus large
> ne rend pas l'application plus souvent fausse : il la rend plus souvent
> hésitante, donc plus dépendante de Pl@ntNet. C'est un coût en euros et en
> attente, pas en confiance.

#### La question n'était pas « où est le coude » mais « à partir de quand »

Une espèce exposée fait perdre au cœur, et gagner à qui la photographie.
L'échange est rentable dès que la part des photos portant sur les espèces
ajoutées dépasse `perte / (précision sur elles + perte)`. Sur les plantes en
pot — le domaine de l'application :

| espèces exposées | ajoutées | perte du cœur | top-1 sur elles | rentable au-delà de |
|---|---|---|---|---|
| 1 800 | 356 | 1,85 pt | 0,7007 | **2,6 %** des photos |
| 2 200 | 756 | 2,84 pt | 0,5930 | 4,6 % |
| 2 800 | 1 356 | 4,08 pt | 0,5459 | 7,0 % |
| 3 646 | 2 202 | 5,56 pt | 0,5277 | 9,5 % |
| 4 400 | 2 956 | 7,78 pt | 0,5116 | 13,2 % |
| 5 259 | 3 815 | 11,12 pt | 0,4698 | 19,1 % |

Les 356 premières ajoutées — les plus cultivées parmi celles qui ne volent
rien — sont reconnues à **70 % sur les photos en pot, mieux que le cœur
lui-même**. Le seuil de 2,6 % est bas ; il est probablement franchi.

**Mais « probablement » n'est pas une mesure, et le terme manquant arrive.**
La part des photos qui portent sur telle ou telle espèce, personne ne la
connaît — sauf les retours des utilisateurs (§ 13.3, chantier 2), ouverts
depuis. Attendre ne coûte rien : le tableau ci-dessus est prêt, il suffira
d'y reporter un chiffre mesuré au lieu d'un pari.

> **À faire avant d'élargir, quand la décision sera prise.** Le coût de vol
> est mesuré sur *toutes* les images du cœur, pas seulement celles de plantes
> cultivées — d'où les 0,52 point de la première tranche en pot, la plus
> chère de toutes. Mesurer le vol sur les seules photos en pot réordonnerait
> les candidates pour le domaine qui compte.

#### Le coût, et il est réel

**13 espèces que l'Iris 7 nommait et que l'Iris 8 n'a pas apprises**, dont
quatre d'intérieur : *Hoya kerrii*, *Nematanthus gregarius*, *Peperomia
caperata*, *Sinningia speciosa*. La couverture des 167 noms d'appartement
recule de **92 % à 89 %** (151 → 147). Elles restent choisissables à la main
dans le sélecteur d'espèces ; l'appareil photo ne les proposera plus.

Ce ne sont pas des espèces pauvres : elles sont tombées sur le défaut de
découpage du § 12.19, corrigé depuis. La prochaine construction du jeu en
récupère une partie.

#### Ce que la v8 aura vraiment servi

Les vingt-deux heures de collecte n'ont pas élargi le répertoire — elles ont
**affiné la vision**. Le réseau a vu 991 000 images sur 5 259 plantes au lieu
de 290 000 sur 1 457, et sur les espèces qu'il connaissait déjà il est six
points et demi meilleur. On jette ensuite les sorties en trop et on garde
les traits.

On ne peut pas démêler complètement ce qui vient des espèces nouvelles de ce
que les anciennes ont gagné en images au passage. Mais les deux faits sont
mesurés et tiennent ensemble : le jeu a triplé, la représentation partagée a
gagné 6,8 points, et exposer les 5 259 sorties détruit ce gain.

> **Collecter large, livrer étroit.** Le § 13 le pariait par raisonnement ;
> c'est maintenant un chiffre. Une espèce de plus au catalogue coûte à
> toutes les autres, et ce coût ne se voit dans aucun `model.json` — il faut
> deux modèles sur les mêmes images pour le lire.

### 6.8 Résultats du modèle v1

| | |
|---|---|
| Architecture | MobileNetV3-Small, transfert ImageNet |
| Classes retenues | **78** (seuil de 25 images d'entraînement) |
| Fichier | **2,0 Mo** en TFLite float16 |
| Top-1 sur le test | **63,8 %** |
| Top-3 sur le test | **81,3 %** |
| Macro-F1 | 0,642 |
| Entraînement | 16 époques, ~10 min sur 4 cœurs |

Top-3 à 81 % est le chiffre qui compte pour l'usage réel : l'écran propose
cinq candidats et l'utilisateur choisit. La bonne espèce est dans la liste
quatre fois sur cinq.

Deux enseignements de cet entraînement, tous deux corrigés :

1. **Normalisations par lots dégelées** — la validation est tombée de
   48,4 % à 39,8 % dès la première époque de réglage fin, pendant que
   l'entraînement montait. Elles sont désormais figées et le taux
   d'apprentissage divisé par deux.
2. **Prétraitement désaccordé** — l'entraînement redimensionne le carré
   central à 256 puis recadre à 224 ; l'application redimensionnait
   directement à 224. Mesuré sur le `.tflite` exporté, cet écart coûtait
   **4,4 points** de top-1 (55,6 % contre 60,0 % sur le même échantillon).
   La recette est maintenant écrite dans `model.json` (`input_size`,
   `load_size`) et lue par l'application, plutôt que codée des deux côtés.

### 6.9 Recette

> **C'est le plan d'origine, pas la recette livrée**, et il est gardé pour
> ce qu'il montre du chemin parcouru. Quatre points n'ont jamais été suivis
> et un lecteur pressé les prendrait pour l'existant : la tête n'a **pas**
> de classe « autre » — le modèle n'a que des sorties d'espèces, et le § 12.7
> explique pourquoi elle n'a toujours pas été faite ; EfficientNet-Lite0 n'a
> jamais été essayé ; le réglage fin ne dégèle pas « tout le réseau » mais
> ses cent dernières couches (§ 6.7) ; et le déséquilibre est traité par des
> poids de classe dans la perte, non par un échantillonnage pondéré. La
> recette réellement appliquée est celle du § 6.7 et du
> [`README` de `tools/plant_model`](../tools/plant_model/README.md).

| Phase | Espèces | Images / espèce | Objectif |
|---|---|---|---|
| 1 ✅ | 95 plantes d'intérieur et succulentes | 120 | premier `.tflite` livré |
| 2 | 297 (catalogue trié) | 300 → 500 | couverture du catalogue |
| 3 | 1 000 – 1 500 (catalogue étendu, sélection) | 300 | couverture large |

`tools/plant_model/train.py` :

- **Architecture** : MobileNetV3-Large ou EfficientNet-Lite0, pré-entraîné
  ImageNet (puis PlantNet-300K en option), tête remplacée par N + 1 classes
  (la classe « autre »).
- **Entrée** : 224 px (phase 1), 288 ou 320 px si la précision le justifie.
- **Augmentations** : recadrage aléatoire, retournement horizontal,
  légère variation de couleur ; pas de rotation forte (les pots sont
  droits).
- **Déséquilibre** : échantillonnage pondéré par classe, évaluation en
  macro-moyenne.
- **Entraînement** : tête seule 3 époques, puis tout le réseau à faible
  taux d'apprentissage 15 – 30 époques, arrêt sur la validation.
- **Coût** : un GPU grand public ou une instance à l'heure ; phase 2 estimée
  à quelques heures.
- **Évaluation** : top-1, top-3, macro-F1 sur `test`, matrice de confusion
  par genre, puis **courbe précision / taux de repli** en fonction du seuil
  pour fixer `acceptThreshold` et `minMargin`.

## 7. Conversion mobile et intégration

| Cible | Format | Chemin |
|---|---|---|
| Android | TFLite (float16, ou int8 avec calibration sur `val`) | `tflite_flutter` |
| iOS | Core ML (`.mlmodel` / `.mlpackage`) via `coremltools` | canal de plateforme, ou TFLite aussi |
| commun | ONNX conservé comme pivot | |

Livrables du modèle : le fichier de poids, `labels.txt` (une ligne par
classe : `internal_id`), `model.json` (version, date, taille d'entrée,
normalisation, N classes, empreinte SHA-256, seuils recommandés) et
`ATTRIBUTIONS.md`.

> **Ce qui a été fait.** TFLite tourne sur les deux plateformes, par
> `tflite_flutter` : ni Core ML, ni `coremltools`, ni pivot ONNX n'existent
> dans le dépôt, et l'app n'a pas de canal de plateforme pour le modèle. La
> classe s'appelle `TflitePlantModel`, sans `Local`. Et `ATTRIBUTIONS.md`
> est bien produit par la collecte, mais **dans `dataset/`, sur la machine
> d'entraînement** : il n'est pas dans `assets/model/`, donc il n'est pas
> livré avec l'application (voir § 12.13).

Dans l'app : une classe `TfliteLocalPlantModel implements LocalPlantModel`
qui charge le fichier, redimensionne la photo, normalise, exécute et rend
les candidats triés (nom canonique depuis `labels.txt`, `internalId`
rempli). Elle remplace `NoLocalModel` dans `localPlantModelProvider`,
**une ligne**. Le reste — cascade, réglage, compteurs, écran — est déjà là.

Tests à ajouter à ce moment-là : chargement du modèle, une image de
référence par classe (`test/fixtures/`), correspondance `labels.txt` ↔
`plants.csv`.

## 8. Mises à jour du modèle

Une version livrée = un numéro de plus dans `model.json`, donc un nom de plus
à l'écran : après Iris 7 est venu Iris 8, et les suivantes s'appelleront
Iris Indoor et Iris 9 sans qu'on l'écrive nulle part. Le numéro est une
**chaîne** — « Indoor » y tient autant que « 9 », c'est ce qui distingue
l'export 500 intérieur (§ 13.3) de l'entraînement large (§ 13). Rien
d'autre à renommer — ni le code, ni les traductions, qui reçoivent le nom
composé (§ 0).

Deux options, à trancher au moment de la phase 2 :

1. **Avec l'app** (recommandé pour commencer) : le modèle est un asset ;
   nouvelle version = nouvelle version de l'app. Simple, revu par les
   magasins, aucun serveur.
2. **Téléchargé** : un point d'entrée statique (`GET /models/plant/latest.json`
   → `{version, url, sha256, classes, min_app_version}`), fichier signé,
   vérification de l'empreinte, remplacement atomique, retour à la version
   embarquée si le chargement échoue. Le `model.json` du §7 est déjà pensé
   pour ça. Attention aux règles des magasins sur le code téléchargé — un
   modèle de poids n'est pas du code, mais à documenter dans la fiche de
   revue.

## 9. Maladies : un service distant, pas le modèle embarqué

Le diagnostic « Ma plante a un problème » (photos + symptômes + observations
→ pistes classées par vraisemblance, avec des gestes) ne passe pas par le
modèle embarqué, qui ne sait que nommer une espèce. Il envoie les photos aux AI
Services d'Infomaniak, hébergés en Suisse, par leur route compatible OpenAI
(`lib/data/services/infomaniak_diagnoser.dart`) :

- **Modèle** : `Qwen/Qwen3.5-397B-A17B-FP8` par défaut, choisi parce qu'il
  voit les images, qu'il parle bien français et qu'il lit une photo de
  plante malade avec plus de justesse que Mistral Small 4, qui tenait ce
  rôle jusque-là. Il coûte quatre fois plus cher (0,80 / 3,60 CHF par
  million de jetons contre 0,20 / 0,75) : un diagnostic — une à trois
  photos réduites à 1 536 px, la consigne, 300 à 500 jetons de réponse —
  revient à quelques millièmes de franc au lieu d'un seul. Le modèle se
  change par un secret du relais (`INFOMANIAK_AI_MODEL`, docs/19), sans
  toucher au code ni republier : Mistral Small 4 reste donc disponible d'un
  `supabase secrets set`.
- **Taille des photos** : 1 536 px sur le grand côté, et non 1 024. Mille
  vingt-quatre suffisaient à voir une feuille jaune, pas à voir ce qui
  sépare deux pistes : un thrips mesure un millimètre et son dégât est un
  piqueté argenté semé de points noirs, dont il ne restait que quelques
  pixels ternes — lus comme du calcaire, sous un constat qui disait
  « feuilles vertes, sans taches ». L'image double de poids et de jetons ;
  c'est le prix d'un compte rendu qui nomme le ravageur. Le délai d'une
  tentative était passé de 40 à 60 secondes pour absorber le téléversement ;
  il est à 90 pour laisser le modèle réfléchir (ci-dessous).
- **Clé** : celle de l'éditeur, au build, comme Pl@ntNet (§ 3.3). Aucun
  réglage côté utilisateur ; l'écran « Diagnostic » dit seulement si le
  service est là et où partent les photos.
- **Pas de plafond** : décision de l'éditeur, le diagnostic se veut
  toujours disponible. La seule limite de l'application est celle du repli
  en ligne de l'identification (§ 3.3). Une clé extraite du binaire est
  donc à surveiller côté facturation Infomaniak.
- **Réponse** : un JSON demandé par la consigne et par `response_format`
  (`json_object`) ; si le service refuse ce paramètre, la même demande
  repart sans lui et le lecteur extrait le JSON du texte, balises Markdown
  comprises.
- **Quand le service flanche** : « Analyse impossible » était la panne la plus
  visible de l'application, et presque jamais la faute du réseau de la
  personne. Trois causes, trois réponses. Un 5xx, un 429, un 408, une
  coupure ou un délai dépassé repartent d'eux-mêmes : la même demande, trois
  tentatives au plus, une pause qui grandit entre deux. Une réponse coupée
  faute de jetons — le cas le plus fréquent — est refermée à la main par le
  lecteur, qui revient au dernier endroit où le texte se tenait et garde les
  pistes écrites en entier ; celle qui ne se répare pas repart une fois avec
  de quoi finir sa phrase. Un 401, un 400 ou un refus de contenu, eux, ne se
  rejouent pas : ils se corrigent. Ce qui reste se dit à l'écran avec le mot
  juste — service saturé, réponse inexploitable, réseau absent — au lieu
  d'envoyer tout le monde vérifier sa connexion.
- **La réflexion du modèle a sa place** : Qwen 3.5 réfléchit avant de
  répondre, par défaut, et ce monologue invisible compte dans `max_tokens`
  comme la réponse. Devant une photo difficile, il durait parfois plus que
  le budget entier : contenu vide, arrêté faute de place, deux fois de
  suite, et « L'analyse n'a pas abouti » à quelqu'un dont le troisième essai
  passait — la panne intermittente du diagnostic, celle qui se corrige en
  réessayant. On garde la réflexion, c'est elle qui lit le motif avant de
  nommer ; on lui laisse la place : 5 000 jetons à la première demande,
  9 000 à celle qui repart, 3 000 au repli sur les mots et 1 500 au
  rattachement (qui n'avait aucune chance à 300), et une minute et demie
  par tentative au lieu d'une. Le plafond ne coûte rien tant qu'il n'est pas
  atteint, seuls les jetons écrits se facturent. Si une réflexion se
  retrouve dans le contenu, entre balises `<think>`, le lecteur l'écarte
  avant de chercher le JSON — une réflexion jamais close est une réponse
  qui n'a pas commencé, et elle repart.
- **Lire le motif avant de nommer** : la consigne demande d'abord *où* et
  *comment* — quelles feuilles, bord ou centre, sec ou mou, net ou diffus, et
  si cela s'étend — avant toute conclusion. C'est le motif, pas la couleur,
  qui sépare un jaunissement qui commence par les vieilles feuilles de celui
  qui commence par les jeunes. Partent avec les photos ce qu'aucune d'elles
  ne montre : la plante vit dedans ou dehors, le jour de l'analyse et
  l'hémisphère (le signe de la latitude déjà connue, rien de plus). Une
  cochenille de salon en février et une brûlure de balcon en juillet ne se
  confondent pas.
- **Une photo de plus, quand elle changerait quelque chose** : le compte rendu
  porte une clé à part, `view`, où le service nomme la seule vue qui
  l'aiderait — feuille de près, revers, plante entière, base de la tige,
  terre au pied — ou `null`. C'est la seule place où une photo manquante a le
  droit d'exister : les pistes, elles, n'en parlent jamais. L'application en
  fait une proposition (docs/16, « Jev côté diagnostic ») : le compte rendu
  reste entier au-dessus, la photo ajoutée relance l'analyse avec les deux ou
  trois vues ensemble, et trois photos restent le plafond.
- **Poser une question plutôt que deviner** : quand rien ne tranche, le
  compte rendu porte une seconde clé à part, `questions` — une à trois
  questions courtes, dans la langue de la personne, ou une liste vide. La
  consigne les borne : seulement ce qui changerait l'ordre des pistes
  (depuis quand, ce qui a changé autour de la plante, le dernier arrosage ou
  rempotage, ce qui a déjà été tenté), jamais ce que la demande contient
  déjà, jamais une photo — c'est `view` —, et rien du tout sur un compte
  rendu net. Les pistes sont rendues en entier dans tous les cas : une
  question affine une réponse, elle ne la remplace pas. Les réponses
  repartent avec leur question (`answersLine`), pèsent comme une observation,
  et l'analyse se refait en entier — photos comprises — au lieu de se
  recoller à la précédente. Elles sont gardées avec le compte rendu et se
  relisent des mois plus tard, comme les symptômes et les observations.
  L'écran préfère les questions à la photo de plus quand il a les deux
  (docs/16).
- **Tout n'est pas un problème** : la consigne ouvrait les pistes aux seuls
  troubles, ravageurs, maladies et fautes d'entretien, si bien que des gouttes
  de nectar extrafloral n'avaient que des cochenilles pour s'expliquer. Une
  seconde base part donc avec la demande, `assets/problems/natural.txt`
  (docs/04) : trente-deux phénomènes numérotés `N01` à `N32` — nectar
  extrafloral, guttation, vieille feuille du bas qui jaunit, panachure,
  racines aériennes, latex à la coupe, repos hivernal, et les confusions qui
  font traiter une plante saine : sores d'une fougère pris pour des
  cochenilles, laine des aréoles, liégeage d'un cactus pris pour une
  pourriture, nodosités des légumineuses prises pour des galles de nématodes,
  lichens de l'écorce —, réduits comme les problèmes à ce que l'espèce, son
  genre ou sa famille peuvent montrer, soit neuf à quatorze entrées. Le service les rend comme
  n'importe quelle piste, numéro dans `problem` et `"natural": true`, avec leur
  cran de vraisemblance et leurs gestes — celui de ne rien faire en est un. Les
  deux numérotations ne se croisent jamais, et le numéro tranche contre la clé :
  ce que la base range en ravageur n'est pas un phénomène normal. Un compte
  rendu dont aucune piste n'est un problème n'est jamais urgent, ne met pas la
  plante à surveiller, et n'est pas envoyé chercher un numéro à la deuxième
  passe. La base est courte : un phénomène qui n'y est pas reste un phénomène,
  sous le nom que le service lui donne.
- **Toujours au moins une piste** : la consigne interdit d'en faire une de la
  photo — « la feuille sèche n'est pas visible sur l'image » n'est pas un
  diagnostic, et le symptôme a bien été vu sur la plante même quand le
  cadrage l'a manqué. Ce que la personne décrit part donc comme observé, et
  un compte rendu revenu sans aucune piste en redemande une dernière fois,
  sans les photos puisqu'elles n'ont rien donné : l'espèce, les symptômes
  décrits et la liste des problèmes connus suffisent à une piste incertaine,
  qui vaut mieux qu'un compte rendu vide. Ce repli est un bonus, jamais un
  motif d'échec.
- **Une description, pas seulement des photos** : le champ des symptômes
  était facultatif, et une photo seule ne dit ni depuis quand, ni ce qui a
  changé, ni ce qui a déjà été tenté — le modèle n'a alors que des pixels et
  répond ce que des pixels permettent. L'analyse attend donc une photo au
  moins, puis quelques mots ; la barre du bas nomme celui des deux qui
  manque (`diagnosisNeed`). Les quatre observations, elles, restent
  facultatives.
- **Ce que la photo ne montre pas** : quatre questions facultatives sous les
  symptômes — la terre au doigt, les racines hors du pot, la lumière reçue,
  les insectes trouvés (`DiagnosisObservations`). Ce sont elles qui
  départagent l'excès d'eau du manque d'eau, la pourriture du choc de
  rempotage, la brûlure de la carence, et aucune photo ne les donne. Ce qui
  est coché part comme vérifié, avec la consigne de peser chaque piste pour
  et contre — et de ne plus conseiller de vérifier ce qui vient de l'être.
  « Aucun insecte vu » en fait partie : une case vide ne dit rien, cochée
  elle pèse contre les ravageurs. Rien n'est coché d'avance, rien n'est
  obligatoire, et ce qui n'est pas coché ne part pas.

  Un constat pèse autant qu'une photo, et non moins : la consigne plafonnait
  à « possible » tout ce que l'image ne montre pas — la règle des symptômes
  racontés —, si bien qu'une terre détrempée et des racines brunes ne
  menaient jamais à une pourriture probable. Un constat de la main est une
  observation de la plante, pas une impression : il peut rendre une piste
  probable, en écarter une, et le résumé dit quand c'est lui qui tranche.
  « Insectes sur la plante » va plus loin encore : la personne les a vus,
  l'appareil non — un thrips mesure un millimètre —, donc une piste de
  ravageur figure dans les pistes, en tête, et des phénomènes normaux seuls
  ne sont pas une réponse.
- **Nommer le ravageur, pas « un ravageur »** : le compte rendu restait
  général là où un gros plan disait tout. La consigne demande maintenant de
  lire chaque photo à son échelle — un gros plan se lit de près, il ne se
  résume pas par la vue d'ensemble —, de regarder la surface d'une feuille
  avant de la dire saine, et elle nomme les signatures : piqueté argenté ou
  bronzé le long des nervures semé de points noirs de frass pour les thrips,
  fin piqueté pâle et toile ténue pour les acariens, amas cotonneux aux
  aisselles pour les cochenilles farineuses, boucliers bruns et miellat
  poisseux pour les cochenilles à bouclier, moucherons sombres au ras de la
  terre pour les sciarides. Le calcaire d'arrosage en est distingué
  explicitement — dépôt blanc crayeux en auréoles de gouttes séchées, sur le
  dessus, qui s'essuie et laisse le tissu vert dessous —, parce que c'est
  pour lui que des thrips ont été pris.
- **Un geste se range sous la cause qu'il traite** : « Vieillissement des
  feuilles basses » portait « laisser sécher le substrat entre deux
  arrosages ». Le geste traitait l'excès d'eau, c'est-à-dire une autre
  piste, sous une cause qui ne demandait rien. Les gestes d'un phénomène
  normal suivent de ce qu'il est normal — laisser faire, ôter la feuille
  épuisée, essuyer le dépôt —, et jamais un traitement pour un problème
  absent.
- **Ce qui est gardé** : l'analyse enregistrée l'est entière. La note du
  journal en garde le résumé et les trois premières pistes ; le compte rendu
  complet — chaque piste avec son explication et ses gestes, l'urgence, les
  symptômes signalés, les observations cochées, les photos regardées —
  l'accompagne dans `plant_actions.metadata` (docs/04). La ligne du journal
  en montre l'aperçu et le rouvre d'un doigt, des mois plus tard, dans la
  langue du moment.
- **Ce qui n'est pas mesuré** : la justesse de ces modèles sur des maladies
  de plantes. Qwen 3.5 a été retenu sur sa réputation et ses classements
  généraux, pas sur des photos de plantes. La seule façon de départager
  Qwen 3.5, Mistral Small 4 et Kimi est un jeu d'essai de vingt à trente
  photos de plantes à problème connu, envoyées avec la même consigne. Il
  reste à constituer.

## 9 bis. Compléter une fiche d'entretien que le catalogue ne connaît pas

Le catalogue intégré ne renseigne à la main que treize profils d'espèce ;
tout le reste passe par le genre, la famille, la catégorie, ou finit sur des
repères généraux. Cette dernière ligne, la fiche l'affiche honnêtement
(« Repères généraux »), et c'est exactement le trou que l'IA comble
(`lib/data/services/infomaniak_care_completer.dart`) :

- **Quand** : seulement si la fiche n'a que des repères généraux, seulement
  si la plante porte un nom d'espèce, seulement si l'utilisateur laisse le
  réglage actif. Une fiche de l'espèce, du genre ou de la famille est
  renseignée à la main et n'est jamais remplacée.
- **Ce qui part** : le nom scientifique, rien d'autre. Ni photo, ni nom de
  plante, ni donnée de l'utilisateur.
- **Ce qui revient** : des nombres et des mots d'un vocabulaire fermé (les
  valeurs des énumérations de `CareProfile`), à `temperature` 0. Tout ce qui
  n'entre pas dans le vocabulaire est jeté, et les nombres invraisemblables
  aussi (arrosage hors 1–120 jours, rempotage hors 6–120 mois, plage de
  température à l'envers, hiver plus fréquent que l'été). Un champ absent
  vaut mieux qu'un champ inventé, la consigne le dit et le lecteur s'y tient.
  La tolérance à l'eau du robinet en fait partie, et c'est le champ où elle
  sert le plus : le catalogue la suppose tolérante faute de mieux, alors
  qu'une plante de terre acide ou une carnivore ne pardonne pas le calcaire.
- **Ce qui ne revient jamais** : la toxicité. Tout le reste est un avis sur
  le confort d'une plante ; « non toxique pour le chat » est une affirmation
  sur laquelle quelqu'un agit. Elle reste au catalogue, ou inconnue. Ne
  partent pas non plus le type d'engrais, le calcium, la culture hors-sol et
  la floraison : le catalogue les déclare ou les déduit du substrat
  (docs/04), et un substrat corrigé par l'IA recalcule les trois premiers
  sans qu'on ait à les demander. La floraison et le repos à feuillage
  disparu se taisent pour une raison de plus : une date de floraison
  inventée se vérifie six mois trop tard, et un bulbe rangé au froid sur un
  mauvais conseil ne repart pas. Le rapport au pot, lui, revient : trois
  mots d'un vocabulaire fermé (`snug`, `steady`, `roomy`), comme la lumière
  ou le substrat.
- **Une fois** : la réponse est gardée sur l'appareil, par espèce et par
  langue, réponse vide comprise, pour qu'une espèce que l'IA ne connaît pas
  ne soit pas redemandée à chaque ouverture de la fiche. Le cache est borné
  à 120 entrées et ne part ni en sauvegarde ni en synchronisation.
- **La provenance est dite** : la ligne du bas passe de « Repères généraux »
  à « Complétée par l'IA », avec ce qui a été envoyé et ce qui ne l'a pas
  été. Sans cela, l'application perdrait ce qui la distingue d'un moteur de
  texte, savoir d'où viennent ses chiffres.

## 10. Ajouter une espèce

1. L'ajouter au catalogue trié (`species_catalog.dart`) ou, à défaut, à
   `plants.csv` à la main (nom canonique, famille, noms courants).
2. `python3 export_plants.py && python3 enrich_plants.py` — vérifier que
   GBIF répond `EXACT` au rang espèce.
3. `python3 build_dataset.py --only "Nom scientifique" --target-per-species 300`.
4. Contrôler `_review/` et quelques images à la main.
4. Réentraîner, réévaluer, recaler les seuils, livrer avec
   `ATTRIBUTIONS.md`.

## 11. Tests

| Test | Fichier |
|---|---|
| normalisation des noms (Python) | `tools/plant_dataset/tests/test_taxonomy.py` |
| normalisation des noms (Dart, mêmes cas) | `test/core/scientific_name_test.dart` |
| licences | `tools/plant_dataset/tests/test_licenses.py` |
| GBIF : correspondance, filtrage par média, pagination (fixtures réelles) | `tools/plant_dataset/tests/test_gbif.py` |
| images, doublons, orientation, réduction | `tools/plant_dataset/tests/test_images_dedup.py` |
| manifeste, attributions | `tools/plant_dataset/tests/test_manifest.py` |
| répartition | `tools/plant_dataset/tests/test_splits.py` |
| entraînement, export, retaille, courbe des tailles | `tools/plant_model/tests/` |
| règle de repli | `test/domain/identification/identification_policy_test.dart` |
| réponse au genre | `test/domain/identification/genus_answer_test.dart` |
| crans de vraisemblance | `test/domain/identification/identification_confidence_test.dart` |
| proposition de la seconde photo | `test/domain/identification/second_photo_offer_test.dart` |
| cascade : acceptation, repli, réglage, quota, cache, erreurs, fusion multi-photos, métriques | `test/domain/identification/cascade_identifier_test.dart` |
| rattachement au catalogue | `test/domain/identification/catalog_mapping_test.dart` |
| Pl@ntNet : parse | `test/data/plantnet_identifier_test.dart` |
| nom affiché du modèle, et la fiche du § 0 contre `model.json` | `test/core/model_name_test.dart`, `test/docs/model_facts_test.dart` |

```bash
(cd tools/plant_dataset && python3 -m pytest -q)    # sans réseau
(cd tools/plant_model   && python3 -m pytest -q)    # sans carte graphique
flutter test
```

Le nombre de tests ne s'écrit pas ici : il change à chaque commit, et un
compte faux dans un document est plus coûteux qu'un compte absent.

## 12. Ce qu'il reste à faire, dans l'ordre

> **État au 9 septembre 2026.** Les § 12.1, 12.5 et 12.6 ont été livrés dans
> Iris 7 : ils valaient ensemble **+7,26 points de top-1** à armes égales
> contre Iris 6 (§ 6.7). Les § 12.3, 12.4, 12.10, 12.17 et 12.19 ont suivi, et
> l'Iris 8 livré rend **+6,7 points de top-1** sur Iris 7 (§ 6.7 bis) — non
> pas en élargissant le répertoire, mais en entraînant large pour exposer
> étroit. La suite est cadrée au § 13. Le reste attend.

> Les numéros d'espèces et de classes cités dans ce § 12 sont ceux de l'Iris 7,
> sur lequel les mesures ont été faites. Ce que le modèle livré expose
> aujourd'hui est dans la fiche du § 0.

La carte graphique change l'économie de cette liste. Une passe à l'heure au
lieu de dix ([`10-entrainer-sur-son-poste.md`](10-entrainer-sur-son-poste.md))
permet d'essayer **un changement à la fois** au lieu d'une recette par nuit,
et c'est la seule façon de savoir ce qui a agi.

Deux chiffres de la v6 cadrent le reste (§ 6.6) : le sur-apprentissage
limite, pas les époques — 70,5 % à l'entraînement contre 52,2 % en validation
à la douzième époque ; et le gain le plus rentable de toute la version n'a
demandé **aucun entraînement** — deux photos valent 13,9 points de top-1,
contre 8,7 points pour dix heures de calcul et 160 000 images de plus.

L'ordre ci-dessous suit le rapport entre ce que l'utilisateur y gagne et ce
que ça coûte. Les trois premiers points changent ce qu'il voit ; les suivants
font bouger les chiffres.

### 12.1 ✅ Les espèces collectées que le modèle ne nomme pas

Ni collecte, ni entraînement supplémentaire : ces espèces sont déjà dans le
jeu.

| | |
|---|---|
| Plantes au catalogue de collecte | 1 558 |
| Avec au moins une image | 1 509 |
| **Classes dans `labels.txt`** | **1 445** |

Quarante-neuf n'ont aucune image — noms horticoles qu'aucune source ne
reconnaît (§ 6.5, § 6.6). Mais **soixante-quatre en ont et sont pourtant
écartées**, par `--min-train 25` ou `--min-val 3`.

Ce ne sont pas des espèces quelconques. Croisées avec `phase1_species.txt` —
les 167 plantes d'intérieur et succulentes du catalogue trié, celles pour
lesquelles l'application existe — **vingt-deux manquent au modèle** :

> *Phalaenopsis amabilis*, *Howea forsteriana*, *Rhaphidophora tetrasperma*,
> *Hoya kerrii*, *Peperomia caperata*, *Peperomia argyreia*, *Alocasia
> zebrina*, *Alocasia amazonica*, *Anthurium clarinervium*, *Calathea
> orbifolia*, *Goeppertia orbifolia*, *Begonia rex*, *Hippeastrum vittatum*,
> *Sinningia speciosa*, *Cymbidium hybridum*, *Columnea gloriosa*,
> *Nematanthus gregarius*, *Ravenea rivularis*, *Gynura aurantiaca*,
> *Pachyphytum oviferum*, *Streptocarpus ionanthus*, *Citrus limon*.

Le phalaenopsis est l'une des plantes d'appartement les plus répandues, et
l'application la porte à son catalogue trié sans savoir la reconnaître.

**Une partie de ces exclusions est un défaut de répartition, pas un manque de
données.** La répartition 80 / 10 / 10 se fait *par groupe d'observation*
(§ 5) : une espèce dont les photos viennent de peu d'observations peut tomber
à zéro en validation et se faire écarter alors qu'elle a largement de quoi
apprendre. Relevé dans `cache/stats.json` — l'état du jeu au 7 septembre,
avant la dernière passe de reprise, donc à reconfirmer sur le `splits.csv`
final :

| Espèce | train | val | Sort |
|---|---|---|---|
| *Howea forsteriana* (kentia) | 95 | **0** | écartée, absente de `labels.txt` |
| *Sinningia speciosa* (gloxinia) | 50 | **1** | écartée |
| *Hoya kerrii* | 32 | **2** | écartée |
| *Peperomia caperata* | 32 | **2** | écartée |

**Le remède est écrit** : `repair_species_coverage`
(`plant_dataset/splits.py`), actif par défaut. Pour les seules espèces à qui
la répartition n'a laissé aucun groupe en validation, puis aucun en test, il
y déplace leur **plus petit groupe d'entraînement** — le plus petit, parce que
l'entraînement est ce qui coûte le plus à perdre. Une espèce qui n'a qu'un
seul groupe n'est pas touchée : la vider pour la mesurer ne l'avancerait à
rien.

**La réparation est minimale, et c'est la partie qui compte.** Elle ne
redistribue rien : toutes les autres affectations restent exactement ce
qu'elles étaient. Une re-répartition générale ferait passer en test des images
que la v6 a vues à l'entraînement — la v6 y paraîtrait meilleure qu'elle
n'est, et `compare_models.py` sous-estimerait le gain de la v7. C'est aussi
pourquoi le module promet que « relancer la répartition ne déplace pas les
anciennes » (§ 5), et la réparation tient cette promesse.

Elle s'applique à la finalisation, sans réseau :

```bash
python3 build_dataset.py --out dataset --plants plants.csv --skip-fetch
```

`--no-repair-splits` rend la répartition d'avant — **c'est ce qu'il faut pour
reproduire la v6 à l'identique**, puisque son jeu de test a été tiré sans la
réparation. L'ordre est donc : finaliser sans réparation, refaire la v6,
puis refinaliser avec.

La finalisation dit ensuite ce qui reste : « *N* espèce(s) sans validation,
donc absentes du modèle ». Ce qui figure encore dans cette ligne manque de
photos, pas d'un tirage.

#### Ce qu'il faut passer avec, sinon il ne sert à rien

La réparation donne un **groupe** de validation, c'est-à-dire souvent une
seule photo. Or `train.py` compte en **images** : `--min-val 3` par défaut.
Une espèce réparée reste donc écartée si on ne descend pas ce seuil. **Il
faut entraîner avec `--min-val 1`** pour que le correctif produise quoi que
ce soit. Une classe mesurée sur une ou deux images n'a pas de métrique
per-espèce crédible, mais la validation globale qui pilote l'arrêt anticipé
porte sur ~29 000 images : quelques espèces à une photo n'y pèsent rien, et
la classe existe — ce qui était le but.

#### Ce que ça a donné, mesuré

Sur une collecte refaite le 9 septembre 2026 (1 507 espèces avec des
images), le compte des classes entraînables :

| | classes |
|---|---|
| `--min-val 3` (avant, et après réparation) | 1 444 |
| `--min-val 2` | 1 448 |
| **`--min-val 1`** | **1 457** |

**Treize classes récupérées**, pas soixante. Le reste des 63 exclusions —
cinquante espèces — tombe sous `--min-train 25` : elles manquent d'images
d'entraînement, et aucune répartition n'y changera rien. Le défaut de tirage
était donc réel mais minoritaire ; l'estimation initiale venait d'un
instantané de collecte à mi-parcours, où beaucoup d'espèces étaient encore
sous-collectées.

Les treize, en revanche, sont bien celles qu'on visait — cinq plantes
d'appartement : *Hoya kerrii* (32 images d'entraînement), *Peperomia
caperata* (32), *Sinningia speciosa* (49), *Nematanthus gregarius* (42),
*Euphorbia leuconeura* (30). Et le cas d'école, *Hylotelephium telephium* :
**162 images d'entraînement, une seule en validation**.

À revoir au passage : `--min-train 25` a été fixé à la v1, sur 78 classes et
8 825 images. Sur 1 500 espèces, il ne protège plus la même chose — et c'est
désormais lui, pas la répartition, qui tient les cinquante espèces
restantes.

### 12.2 Wikimedia Commons, pour de vrai

Le connecteur est écrit et testé (§ 4.4), mesuré à **97 % de licences
utilisables** contre 18 % chez GBIF, et **il n'a jamais servi à une collecte
complète**. C'est le seul levier qui attaque la cause plutôt que le symptôme :
GBIF et iNaturalist décrivent des observations de terrain, Commons est
l'endroit où l'on photographie son monstera dans son salon. C'est exactement
la distribution qui manque au yucca pris pour du maïs (§ 6.3) et au ficus
ginseng à 27 % (§ 6.5).

Ce qui reste à faire est de **mesurer ce qu'il ajoute, espèce par espèce**,
avant de le mettre dans la recette. Une source ne vaut pas par sa taille mais
par son recouvrement avec le catalogue : le cas Smithsonian Gardens (§ 4.5) a
coûté dix minutes de mesure et évité d'écrire un connecteur pour sept photos.

**L'outil de mesure existe** — `tools/plant_dataset/commons_apport.py`. Il ne
télécharge aucune image : il compte, par espèce, les fichiers que le
connecteur retiendrait, et les met en regard de ce que le jeu possède déjà.

```bash
cd tools/plant_dataset
python3 commons_apport.py --limit 30 --csv commons.csv
```

Ce qu'il faut regarder n'est pas le total mais **la troisième ligne du
rapport** : le nombre d'espèces que Commons pourrait *au moins doubler*. Une
espèce qui a 200 images et à qui Commons en offre 12 ne justifie pas une
passe ; une espèce à 30 images à qui il en offre 150 la justifie à elle
seule. Compter une heure pour les 167 plantes d'intérieur — l'API demande
une seconde entre deux requêtes, et le connecteur descend d'un niveau dans
les sous-catégories, là où sont justement les plantes cultivées.

#### Ce qu'un premier échantillon de huit espèces montre déjà

| espèce | Commons | ce que ce document en dit |
|---|---|---|
| *Ficus microcarpa* | **299** *(le plafond)* | « le cas d'école », 27 % de top-1 (§ 6.5) |
| *Monstera deliciosa* | 278 | |
| *Beaucarnea recurvata* | 221 | 56 % de top-1 |
| *Yucca gigantea* | 121 | « photos cultivées = arbres de jardin », 52 % |
| *Zamioculcas zamiifolia* | 102 | 65 % |
| *Hoya kerrii* | 43 | récupérée de justesse par le § 12.1, 32 images |
| *Peperomia caperata* | 14 | idem, 32 images |
| *Rhaphidophora tetrasperma* | 6 | absente d'Iris 6 faute d'images |

La coupure est nette, et elle n'est pas celle qu'on attendait. **Commons est
riche là où la plante est photographiée depuis des décennies, et pauvre là où
elle est une mode récente.** Le ficus ginseng, le monstera, le yucca, le
beaucarnea : cent à trois cents photographies chacun. Le mini-monstera, la
peperomia caperata, le hoya cœur : six, quatorze, quarante-trois.

Or ce sont deux maladies différentes, et Commons n'en soigne qu'une :

- **le mauvais domaine visuel** — beaucoup d'images, mais toutes de plantes
  sauvages ou de terrain. C'est le yucca pris pour du maïs, le ficus de rue
  contre le bonsaï. **Commons soigne exactement ça**, et les espèces
  concernées sont précisément celles où il est riche.
- **la rareté** — trop peu d'images, quelle qu'en soit la provenance. Ce sont
  les treize espèces que le § 12.1 vient de récupérer au bord du seuil.
  **Commons n'y peut rien** : il en a moins qu'elles n'en ont déjà.

Autrement dit, la passe Commons vaut d'être faite, mais il ne faut pas en
attendre qu'elle sauve les espèces les plus fragiles. Pour celles-là, il
faudra autre chose — et le § 12.8 montre que PlantNet-300K, lui, en tient des
centaines pour certaines.

### 12.3 ✅ Une photo d'abord, une seconde seulement si Iris hésite

La création demandait trop tôt plusieurs vues : après la première photo, des
emplacements invitaient déjà à photographier une feuille ou un autre angle,
avant même qu'Iris ait répondu. Le gain multi-photo est réel (§ 6.7), mais le
coût UX l'est aussi : la plupart des plantes n'ont pas besoin d'un mini
shooting pour être ajoutées.

Le parcours est maintenant **progressif** :

1. une seule photo est prise ;
2. Iris démarre immédiatement sur cette photo, pendant qu'elle reste affichée
   dans le grand cadre 4:5 ;
3. les candidats sont toujours montrés ;
4. si la réponse passe le seuil d'acceptation, aucune autre photo n'est
   demandée ;
5. si Iris hésite, les candidats restent visibles et un bouton facultatif
   « Ajouter une photo » propose une seconde vue pour affiner ;
6. après cette seconde photo, la fusion multi-photo est recalculée et il n'y a
   pas de troisième prise dans ce parcours.

La décision reste dans le domaine, via `secondPhotoOffer()` à côté de
`FallbackPolicy` :

| état | quand | interface |
|---|---|---|
| `prominent` | réponse locale non acceptée | candidats + explication + bouton pour une 2e photo |
| `none` | réponse acceptée, 2 photos déjà utilisées, ou réponse distante | aucune demande supplémentaire |

La seconde photo n'est donc plus une vérification systématique d'une réponse
déjà solide. Elle devient un outil de résolution d'incertitude. Le bénéfice
mesuré des deux photos — **+13,7 points de top-1** dans l'expérience du § 6.7 —
est conservé là où il sert le plus.

#### L'analyse reste sur la photo

À la création, l'identification ne démarre plus en arrivant à l'étape du nom.
Dès que la caméra ou la photothèque rend le fichier source, **la photo brute
remplace immédiatement le viseur** et le `ProcessingField` se pose dessus.
La compression 2048 px et la miniature continuent en arrière-plan pour le
stockage ; elles ne remplacent jamais l'image source dans ce cadre. La grille
reste fixe mais sa masse dérive et se replie en faisant respirer les points ;
la petite marque Iris reste en haut à droite. Ce premier passage reste visible
**au moins deux secondes**, même si le modèle répond plus vite, et son entrée
comme sa sortie se font en fondu plutôt que par coupure.

Dès que les candidats sont disponibles, les trois premiers noms apparaissent
**directement sur la photo**, un par un, avec une courte entrée, une position
et une légère rotation stables dérivées du nom scientifique. Le modèle ne
prétend pas rendre ses résultats progressivement — la liste arrive d'un coup ;
c'est l'interface qui la révèle en plusieurs temps. Quand les deux secondes
minimales et le calcul sont terminés, le champ disparaît mais les noms restent
sur l'aperçu jusqu'à « Continuer ». L'étape du nom garde ensuite la liste
complète et les actions de confirmation comme avant.

Le viseur garde seulement quatre coins de cadrage. Le quadrillage a été retiré :
la plante et les repères suffisent, et l'image n'a plus l'apparence d'un
scanner.

#### Les candidats restent la réponse principale

Une faible confiance ne cache jamais les propositions. L'écran écrit d'abord
ce qu'Iris a trouvé, avec les mêmes crans de vraisemblance qu'avant. La seconde
photo vient **après** la liste comme action facultative ; elle affine la
réponse, elle ne la remplace pas.

Dans la feuille « Identifier », le même contrat s'applique : deux photos au
maximum et aucune différence de règle avec la création. Une photo déjà
présente dans la galerie peut servir de seconde vue sans demander une nouvelle
prise.

La photo supplémentaire prise uniquement pour identifier reste temporaire :
elle s'efface en quittant le flux, tandis que la photo principale appartient à
la plante.


### 12.4 ✅ La matrice de confusion par genre

`tools/plant_model/confusions.py`. Le § 6.9 la promettait depuis la v1 ;
`evaluate()` ne rendait que top-1, top-3, macro-F1 et la courbe de seuil —
*combien* le modèle se trompe, jamais *sur quoi*. Le yucca pris pour du maïs
a mis trois versions à être découvert, à la main, sur une photo réelle.

```bash
cd tools/plant_model
python3 confusions.py --dataset ../plant_dataset/dataset --model ../../assets/model
python3 confusions.py --captive        # sur les seules photos de plantes cultivées
```

#### Ce que le premier passage a donné — 6 000 images, Iris 7

|  | part des erreurs | au hasard | |
|---|---|---|---|
| dans le même genre | 12,8 % | 0,17 % | **×73** |
| dans la même famille | 14,2 % | 1,93 % | **×7** |
| au-delà | 73,0 % | 97,89 % | ×0,75 |

*(parts mesurées sur 6 000 images ; les décomptes par famille et la
distribution par espèce plus bas viennent du test entier, 29 000 images.)*

**La lecture prévue ici était fausse, et de deux façons.**

Ce paragraphe annonçait qu'« un modèle dont 80 % des erreurs restent dans le
genre est en bonne santé ». C'est arithmétiquement hors d'atteinte : **549
classes sur 1 457 sont seules dans leur genre** et leurs erreurs ne
*peuvent* pas y rester. Une erreur tirée au sort y resterait 0,17 % du
temps. Les 12,8 % mesurés ne sont donc pas un échec par rapport aux 80 %
espérés, ce sont **soixante-treize fois le hasard** : le modèle sait très
bien reconnaître un genre.

Et le rapport rangeait tout le reste sous « vrais défauts », ce qui mettait
dans le même sac *Picea* → *Abies*, deux Pinaceae que personne ne sépare de
loin, et *Parthenocissus* → *Petroselinum*, une vigne vierge prise pour du
persil. D'où trois tiroirs au lieu de deux, `plants.csv` donnant la famille
des 1 457 classes.

#### Le vrai enseignement : l'échec est par photo, pas par espèce

**1 794 erreurs sur 2 458 franchissent la famille botanique.** Le document
raconte depuis la v1 une histoire de confusions entre espèces proches — le
yucca pris pour du maïs. La mesure dit que c'est le petit quart du problème,
et que ce quart-là est **déjà rattrapé par l'interface** : le top-3 est à
74,4 % contre 59,6 % de top-1, soit près de neuf cents images sur six mille
où la bonne réponse est dans les cinq candidats affichés.

La lecture qui vient alors à l'esprit — « le reste, ce sont des plantes que
le modèle n'a pas apprises » — est **fausse, et c'est la ligne suivante du
rapport qui l'a montrée** :

> **11 espèces sur 575 mesurables n'ont pas une seule bonne réponse (2 %).**

Deux pour cent. La population des espèces jamais reconnues est minuscule.
Les 1 794 erreurs lointaines ne sont donc pas concentrées sur des classes
absentes en tout sauf le nom : elles sont **réparties sur des espèces que le
modèle reconnaît par ailleurs**, une photo sur deux ou sur trois.

Ce qui change le diagnostic, et le remède avec :

- **le modèle connaît presque toutes ses espèces** ; il échoue sur certaines
  *photos* — cadrage, arrière-plan, gros plan contre plante entière,
  lumière ;
- **et quand il échoue, il ne se rabat pas sur une voisine plausible.** Il
  répond une plante sans rapport. Ce n'est pas le comportement d'un modèle
  qui hésite entre deux espèces proches, c'est celui d'un modèle à qui la
  photo ne dit rien.

C'est un problème de **domaine visuel**, pas de couverture d'espèces — le
diagnostic du § 6.3, celui qui avait fait recollecter les plantes d'intérieur
en pot, et celui que la passe Commons du § 12.2 vise. **Ajouter 1 500 espèces
ne le soignerait pas** : ce sont des photos d'un autre genre qu'il faut aux
espèces déjà présentes.

**Et ce 2 % était lui-même une mauvaise mesure.** La passe complète a rendu
**5 espèces sur 1 422**, contre 11 sur 575 dans l'échantillon. Ce n'est pas
une amélioration, c'est le même modèle : une espèce à 15 % de top-1 rate
facilement ses cinq photos, presque jamais ses trente. **Le zéro mesurait le
nombre d'images de test.** Un seuil, lui, ne bouge pas :

| sur les 1 422 espèces vues au moins cinq fois | |
|---|---|
| **sous 25 % de top-1** | **76** (5,3 %) ← la liste de collecte |
| sous 50 % | 402 (28,3 %) |
| pas une seule bonne réponse | 5 (0,4 %) |

Voilà la forme réelle du problème : **soixante-seize espèces à reprendre**,
pas cinq et pas mille quatre cents. Le reste du catalogue tient. Et les
trois quarts des erreurs viennent d'espèces qui, elles, dépassent 50 % —
c'est-à-dire de photos ratées sur des plantes connues, pas de classes
perdues.

#### Les familles franchies, et la seule qui touche l'application

Sur le jeu de test entier, 29 000 images :

| | |
|---|---|
| Pinaceae ↔ Cupressaceae | **98** — sapins, épicéas, cyprès, thuyas |
| Asteraceae ↔ Brassicaceae | 72 |
| Asteraceae → Apiaceae / Ranunculaceae / Lamiaceae / Fabaceae | 120 en tout |
| Rosaceae → Caprifoliaceae / Ranunculaceae / Oleaceae / Fabaceae | 98 en tout |
| **Asparagaceae ↔ Poaceae** | **39** |
| Amaranthaceae → Polygonaceae | 20 |

Les conifères dominent, et c'est sans conséquence : personne n'identifie un
thuya depuis son salon. **La paire qui compte est la deuxième.** Asparagaceae,
ce sont les 41 classes à feuilles en lanières — *Chlorophytum*, *Dracaena*,
*Cordyline*, *Aspidistra*, *Beaucarnea*, *Yucca* —, c'est-à-dire une bonne
part des plantes d'appartement du catalogue. Poaceae, ce sont les graminées.

**C'est le yucca pris pour du maïs du § 6.3, toujours là, et pas résolu.** La
v4 l'avait traité espèce par espèce, en recollectant des photos de yucca en
pot ; la vue par famille dit que le défaut n'était pas le yucca mais **la
forme de feuille**, et qu'il touche tout un rayon de jardinerie — le
classement par genres le confirme, `yucca → dracaena` pèse 10 à lui seul.

> **Une part de ce classement n'est pas une erreur du modèle.**
> `hesperocyparis → cupressus` (11) et son symétrique (10) sont en tête des
> confusions de genre, et pour cause : ce sont **la même plante sous deux
> noms**, tous deux au catalogue. Aucune photo ne pouvait trancher. Voir le
> § 12.14 — cinq autres paires sont dans ce cas.

#### Et ce que les espèces les plus ratées ne contiennent pas

Cèdres, fusains, églantiers, paulownias, mélèzes, frênes, pins : les vingt
espèces les plus ratées sont des plantes de dehors. **Aucune des 151 espèces
d'appartement n'y figure** — ce qui corrobore, par un autre chemin, les huit
points et demi d'écart du § 12.12 entre les plantes d'intérieur et le reste
du catalogue. Le modèle est faible là où l'utilisateur ne regarde pas.

#### En pratique

```bash
python3 confusions.py --dataset ../plant_dataset/dataset --model ../../assets/model --csv paires.csv
python3 confusions.py --pairs paires.csv        # relit, ne recalcule pas
python3 confusions.py --captive                 # les seules photos de plantes cultivées
```

`--csv` écrit les paires, `--pairs` les relit : le rapport se refait en une
seconde sans TensorFlow ni machine d'entraînement. C'est ce qui a permis de
corriger deux fois la lecture ci-dessus sans remobiliser la VM — vingt
minutes d'inférences auraient découragé la première correction, et la
seconde ne serait jamais venue.

Le rapport finit par les espèces les plus ratées avec **ce qu'on leur répond
à la place** — la question qu'on se posait sur le ficus ginseng (§ 6.5)
depuis deux versions. Les fonctions de tri sont testées sans TensorFlow
(`tests/test_confusions.py`).

### 12.5 ✅ La régularisation

C'est le défaut mesuré, et la recette n'a presque rien pour le combattre.
Aujourd'hui : recadrage aléatoire, miroir, luminosité, saturation, gigue de
résolution ; `--dropout 0.3` ; Adam à taux constant ; entropie croisée nue.

| Levier | Aujourd'hui | À essayer |
|---|---|---|
| Dropout | 0,3 | 0,5 |
| Augmentation | cinq transformations douces | effacement aléatoire, mixup |
| Perte | entropie croisée nue | lissage d'étiquettes |
| Taux d'apprentissage | Adam constant | décroissance cosinus |
| Poids retenus | les derniers | moyenne mobile (EMA) |

Aucun ne coûte de collecte, tous coûtent une passe — d'où l'importance de
n'en changer qu'un à la fois.

### 12.6 ✅ L'entrée à 320 px

Le levier classique de la reconnaissance fine, et le jeu est stocké en 448 px :
**pas besoin de recollecter** — `--input-size 320` suffit, et le chargement
suit tout seul à la même marge de recadrage.

**Ce que ça coûte n'est pas la taille du fichier.** MobileNetV3 est
entièrement convolutif et sa tête part d'une moyenne globale : le nombre de
poids ne dépend pas de la résolution d'entrée, et le `.tflite` reste à
8,8 Mo. Ce qui double, c'est le **calcul sur le téléphone** — (320/224)² ≈ 2 —,
donc la demi-seconde d'inférence mesurée au § 6.4 passerait à une seconde.
C'est le seul arbitrage : 320 px ne vaut le coup que s'il rapporte assez de
points pour justifier une attente deux fois plus longue devant l'écran
d'identification.

Ce raisonnement, tenu avant l'entraînement, comparait deux attentes alors
que l'inférence tournait sur l'isolat principal et produisait donc deux
gels. Le § 6.7 dit ce qui a été corrigé après coup ; la décision, elle, ne
change pas.

### 12.7 La classe « autre » — et d'abord savoir si elle manque

Prévue au § 3.2, jamais faite. Le seul garde-fou contre une photo de chat est
le plancher à 0,10, la marge étant inactive au seuil de 0,70.

**Deux choses ont changé, et elles vont en sens contraire.**

D'un côté, la calibration s'est améliorée toute seule. Le dropout à 0,5 a fait
tomber la confiance moyenne de 5,7 points sans que la justesse baisse
(§ 6.7) : le modèle est nettement moins présomptueux qu'à la v6, et c'est
précisément le défaut que la calibration de température devait corriger. Ce
levier-là a perdu de son intérêt.

De l'autre, aucune calibration ne résout le vrai problème. **Un classifieur
dont toutes les sorties sont des plantes n'a aucun moyen de dire « ceci n'est
pas une plante » :** il répartit sa masse entre les espèces qu'il connaît, quoi qu'on
lui montre. Devant un chat, il répond une plante — la seule question est avec
quelle assurance.

#### La mesure à faire avant de construire quoi que ce soit

C'est la leçon du § 4.5 et du § 12.8, appliquée à nous-mêmes : **mesurer avant
d'écrire.** Une trentaine de photos hors sujet — animaux, meubles, visages,
murs, plats — passées dans le modèle livré, et l'on regarde la distribution
des meilleurs scores :

| ce qu'on observe | ce que ça veut dire |
|---|---|
| presque tout sous 0,10 | le plancher fait déjà le travail, la classe « autre » est un chantier pour rien |
| beaucoup entre 0,10 et 0,70 | l'application affiche une liste « plausible » sur une photo de chat : gênant, pas grave — un message suffirait |
| des scores au-dessus de 0,70 | le modèle **affirme** une espèce devant n'importe quoi. Là seulement la classe « autre » se justifie |

Trente photos et dix minutes tranchent entre trois chantiers de tailles très
différentes. Aucun n'a de raison d'être entrepris avant.

#### La moitié plantes, mesurée le 19 septembre 2026

`tools/plant_model/hors_sujet.py` fait cette mesure. Première passe sur la
moitié la plus difficile — **40 plantes hors catalogue**, tirées du jeu de
test parmi les classes qu'Iris Indoor n'expose pas, donc étiquetées :

| bande | Iris Indoor | Iris 8 sur les mêmes photos |
|---|---|---|
| sous le plancher (0,10) | 1 — 2,5 % | 1 — 2,5 % |
| plausible | 28 — 70,0 % | 28 — 70,0 % |
| **affirmé (≥ 0,70)** | **11 — 27,5 %** | 11 — 27,5 % |
| score médian | 0,4430 | 0,4571 |

Les bandes se ressemblent ; ce qu'elles contiennent, non. Sur les dix plus
affirmées, la v8 en avait **quatre justes** — c'étaient des espèces qu'elle
exposait. Iris Indoor n'en a aucune, et **les dix sont acceptées** par
`FallbackPolicy` : affirmées sans réserve, sans appel à Pl@ntNet.

| la plante photographiée | ce qu'Iris Indoor répond | |
|---|---|---|
| *Aloiampelos tenuior* | *Aloe vera* | 0,9983 |
| *Salvia mexicana* | *Sinningia speciosa* | 0,9590 |
| *Agave lophantha* | *Tillandsia ionantha* | 0,9328 |
| *Veronica elliptica* | *Nephrolepis cordifolia*, une fougère | 0,8978 |

Certaines sont des voisines pardonnables — *Echeveria × imbricata* rendue
*Echeveria elegans*, *Stachys arvensis* rendue basilic, deux Lamiacées. Une
dicotylédone à fleurs rendue fougère à 0,90 ne l'est pas.

C'est la troisième ligne du tableau ci-dessus, et elle a une conséquence
que le § 13.3 n'avait pas prévue : **rétrécir le masque ne transforme pas
ces réponses en repli, il les transforme en erreurs confiantes.** La
dégradation douce annoncée n'existe pas pour ces photos-là.

**Ce que cette passe ne dit pas.** n = 40, et rien que des plantes : les
non-plantes — chat, meuble, visage, mur, plat — restent à mesurer, et
c'était la question d'origine du § 3.2. Les images viennent en outre du jeu
de test, donc de photos naturalistes, pas de photos de salon. Et la mesure
donne une proportion **parmi les photos hors catalogue**, pas leur fréquence
chez les utilisateurs : ce dernier terme est exactement ce que le chantier 2
du § 13.3 produit.

#### Si la mesure la réclame

Une classe de plus, entraînée sur des négatifs de deux natures : des
non-plantes (scènes d'intérieur, animaux, objets — CC0 abondant) et des
**plantes hors catalogue**, qui sont le cas le plus fréquent en vrai et le
plus difficile. Le coût réel n'est pas la collecte mais l'équilibre : une
classe « autre » trop nourrie devient la réponse par défaut et fait chuter le
rappel partout ailleurs. Elle se mesurerait comme le reste, à armes égales
contre le modèle sans elle (§ 12.10).

### 12.8 PlantNet-300K — mesuré, et ce n'est pas ce qu'on croyait

La mesure que ce document réclamait depuis deux versions est faite :
`tools/plant_dataset/plantnet300k.py`, sur les 66 Mo de métadonnées que
Pl@ntNet publie à part — sans télécharger une seule des 306 000 images.

```bash
cd tools/plant_dataset && python3 plantnet300k.py
```

**Le recouvrement d'espèces est faible.** 108 de nos 1 457 classes, soit
7,4 %, et 68 genres sur nos 814. Leur jeu est profond mais étroit : 1 019
espèces pour seulement 303 genres, la flore sauvage d'Europe de l'Ouest
échantillonnée en profondeur. Le nôtre est large : 1 457 espèces sur 814
genres.

**Mais le volume sur ces 108 espèces est énorme, et les licences sont
parfaites.**

| | |
|---|---|
| Images sur les espèces communes | **181 824** utilisables sur 181 915 — **100 %** |
| Licence | CC BY-SA presque partout, acceptée depuis le 6 septembre (§ 4.1) |
| Par espèce | médiane **1 040**, contre ~190 dans notre jeu |
| Espèces qui gagneraient plus de 100 images | 97 sur 108 |

Et parmi elles, **seize plantes d'appartement de notre catalogue trié**, avec
de quoi les noyer d'images : *Pelargonium zonale* 3 317, *Anthurium
andraeanum* 2 801, *Tradescantia pallida* 2 521, *Tradescantia zebrina*
2 470, *Zamioculcas zamiifolia* 2 164, *Schefflera arboricola* 1 972,
*Fittonia albivenis* 1 358, *Nephrolepis exaltata* 687, *Sedum morganianum*
630, *Peperomia caperata* 334…

**Le piège est dans le cadrage.** La répartition par organe :

| organe | images | |
|---|---|---|
| `flower` | 105 904 | 58 % |
| `leaf` | 64 161 | 35 % |
| `fruit` | 8 283 | 5 % |
| **`habit`** (la plante entière) | **2 001** | **1,1 %** |

Quatre-vingt-treize pour cent de gros plans. Sur *Zamioculcas zamiifolia*,
2 164 images et **28** montrant la plante entière. Verser ce jeu tel quel,
c'est refaire l'erreur du § 6.3 en plus gros : le modèle apprendrait
magnifiquement à reconnaître une feuille de zamioculcas cadrée serrée, et pas
la plante posée sur un meuble.

Deuxième piège, arithmétique : ces 108 espèces passeraient de ~190 images à
plus de mille. Elles pèseraient cinq fois le reste du catalogue, et le
déséquilibre que `class_weight` corrige aujourd'hui deviendrait structurel.

#### Ce qu'il faut donc en faire

Ni pré-entraîner, ni verser en vrac : **une ingestion plafonnée, et le
plafond est tout le travail.** Au plus 200 à 300 images par espèce, en
prenant d'abord les `habit`, puis les `leaf` — dans cet ordre, parce que
c'est celui de l'utilité décroissante pour nos utilisateurs. Sur les 108
espèces, cela ferait de l'ordre de 25 000 images bien cadrées et sous
licence propre, sans déformer la répartition.

Le pré-entraînement, lui, reste ce que le § 4.6 en disait : les poids publiés
sont des **ResNet18 PyTorch**, rien de réutilisable pour un MobileNetV3
TensorFlow. Une passe complète de plus sur 306 000 images, pour un bénéfice
que personne n'a mesuré. À garder pour le jour où le reste sera épuisé.

#### Addendum (17 septembre 2026) : le même corpus, dix fois plus grand et mieux outillé

**PlantCLEF** (éditions 2024 et 2025, LifeCLEF / Kaggle) distribue le jeu
d'entraînement de Pl@ntNet : **1 408 033 images, 7 806 espèces**, 800 px
de côté, splits fournis, complété d'images GBIF à étiquettes de confiance
pour les espèces pauvres. Le CSV de métadonnées est public
(`lab.plantnet.org`) et donne **par image** la licence, l'organe, l'auteur
et `gbif_species_id` — tout ce qui manquait au 300K.

Mesuré sur dix tranches du CSV (2 125 lignes, 16 espèces) :

| | |
|---|---|
| licences | **99,6 % cc-by-sa**, reste cc-by-nc que le filtre du § 4.1 écarte — applicable **par image** |
| `habit` (plante entière) | **25 %**, contre 1,1 % dans le 300K — et l'organe est une **colonne**, le plafonné « `habit` d'abord » devient un `ORDER BY` |
| recouvrement avec `plants.csv` | 7 espèces sur 16 — c'est bien de la **flore sauvage**, pas une source pour le domaine salon |
| bruit résiduel | même chez les experts : *Pseudopodospermum hispanicum* y figure en double pour une coquille d'auteur (« N.Kilia » / « N.Kilian ») ; les clés `gbif_species_id` ne recoupent pas nos `gbif_key` (format ou version de référentiel) — le rattachement se fera **par nom** |

La sauvagine n'est pas le défaut qu'on croit : c'est exactement le principe
« entraîner large » du § 13.2 — ces espèces ne seraient jamais exposées,
et la v8 a mesuré que la largeur paie dans les représentations. Mais ce
corpus ne comblera **jamais** le domaine salon : des *Knautia* dans une
prairie n'apprennent rien d'un monstera sur un meuble. C'est donc un
**chantier de volume, pas de domaine** — après les chantiers 2 et 4 du
§ 13.3, pas avant.

Conditions : inscription gratuite au challenge ; chaque image garde sa
licence. Des poids ViT/DinoV2 affinés sur ce jeu sont publiés sur Zenodo
— aussi inutilisables pour MobileNetV3 que ceux du 300K. La décision du
§ 12.8 tient telle quelle, avec un réservoir dix fois plus profond :
plafonné, `habit` d'abord.

### 12.9 Les hybrides sans image

Trois hybrides horticoles n'ont aucune image faute de nom reconnu par GBIF :
*Hylotelephium × mottramianum*, *Salvia × floriferior*, *Amelanchier ×
spicata*. À résoudre par `synonyms.txt`, comme les trois de la v5 (§ 6.5).

### 12.10 ✅ Comment on sait qu'une version vaut mieux

**Pas au top-1 de `model.json`.** Deux versions n'y sont pas mesurées sur le
même jeu de test, et le § 6.6 le montre : la v6 y « gagne » 0,3 point sur un
test plus dur, alors qu'à armes égales elle en gagne 8,7. La méthode ci-dessous
a servi à valider Iris 7 (§ 6.7) ; elle vaut pour la suivante.

Ce qui décide :

1. `compare_models.py` entre Iris 6 et la v7, sur les classes communes et les
   mêmes images ;
2. le même calcul restreint aux **plantes cultivées**, la seule population qui
   ressemble aux photos des utilisateurs ;
3. la **justesse quand le modèle répond seul** — 77,7 % → 88,9 % de la v5 à la
   v6. C'est le chiffre que l'utilisateur ressent : moins de mauvaises réponses
   affirmées, et moins d'appels à Pl@ntNet ;
4. et, à la livraison, `multi_photo.py` pour remesurer `acceptThreshold` : un
   seuil ne se transporte pas d'un modèle à l'autre (§ 3.1, § 6.6).

### 12.11 Cadrage de la v8 : viser 3 000 espèces

L'objectif est de passer de 1 457 à **3 000 classes**. Ce qui suit est ce
qu'il faut savoir avant de s'y engager.

#### Ce que ça coûte

| | Iris 7 | à 3 000 |
|---|---|---|
| Modèle livré | 8,8 Mo | **≈ 11,8 Mo** — la dorsale ne bouge pas, la tête est un `Dense(960 → N)` |
| Collecte | ~6 h | **~12 h**, bornée par les API : une machine plus grosse n'y change rien |
| Jeu | 15 Go, 290 k images | ~30 Go, ~580 k images — compter 90 Go pendant la collecte en parts |
| Une recette d'entraînement | 25 min | **~2 h** |

#### Le risque, et il a un précédent

**Ajouter des classes a toujours coûté du top-1 ici** : 78 classes en
rendaient 63,8 %, 542 en rendaient 44,2 % (§ 6.2). Ce n'est pas une fatalité
— la v6 a ajouté 551 espèces sans perdre — mais elle n'y est arrivée que
parce que la collecte s'améliorait en même temps.

Or les espèces à ajouter sont **moins photographiées** que les 1 457
actuelles : c'est mécanique, on descend la courbe de popularité.

#### Ce que la mesure dit déjà

`tools/plant_dataset/disponibilite.py`, sur vingt espèces tirées au hasard du
catalogue étendu et absentes du catalogue de collecte :

| | |
|---|---|
| au-dessus des 25 images de `--min-train` | **8** |
| entre 1 et 24 — collectées pour rien, écartées du modèle | 5 |
| connues de GBIF, jamais photographiées | 7 |

**Quarante pour cent.** Un tirage au hasard de 1 543 noms dans les 34 793
candidates ne donnerait pas 3 000 classes mais environ **2 100**, et 900
espèces collectées pour rien — douze heures de réseau et du disque pour des
classes que `train.py` écarterait.

**Et le § 12.12 a depuis chiffré ce que l'étendue coûte déjà** : sur les
plantes d'appartement, restreindre les sorties de 1 457 à 151 classes rend
**dix points de top-1**. Ce n'est pas un argument contre les 3 000 — il faut
bien nommer ce que les gens photographient —, mais c'est la mesure qui
manquait au critère de réussite ci-dessous : la première condition n'est pas
une formalité, c'est celle qui décide.

#### Ce que les 76 espèces faibles disent du cap

Les 63 plus mal classées (§ 12.4) ont été relevées nommément. Leur
composition dit où le modèle est faible, et ce n'est pas là où on
l'attendait :

| | |
|---|---|
| **plantes d'appartement** | **1 sur 63** — *Dracaena reflexa* |
| échouent contre une espèce du **même genre** | 28 (44 %) |
| dans la même famille | 11 (17 %) |
| au-delà de la famille | 24 (38 %) |

Les soixante-deux autres sont des **arbres, des conifères, des céréales et
des plantes sauvages** : paulownia, lagerstroemia, cryptomeria, seigle,
orties de bord de route. Or c'est exactement la population que 1 543 espèces
de plus viendraient grossir — on ne descend pas la courbe de popularité de
GBIF sans tomber sur davantage de flore européenne sauvage.

Et 44 % de ces échecs sont **rattrapés par l'écran** : le candidat proposé
est du même genre, l'application en montre cinq, la bonne réponse y est. La
population réellement coûteuse, ce sont les 24 qui sortent de la famille.

#### Ce que ça change au cap des 3 000, sans l'abandonner

Trois mesures pointent dans le même sens :

1. le modèle rend **67,3 %** sur les plantes d'appartement et 58,9 % sur le
   reste (§ 12.12) ;
2. restreindre les sorties à l'intérieur rend **dix points** ;
3. **une seule** des 63 espèces les plus faibles est une plante
   d'appartement.

Le catalogue est déjà large là où l'utilisateur ne regarde pas, et faible au
même endroit. **Viser 3 000 par un tirage dans la flore disponible
ajouterait des espèces dans la bande la plus faible, en faisant payer dix
points à celui qui photographie son salon.** Ce n'est pas une raison de
renoncer au chiffre — c'en est une de choisir ce qu'on y met : des plantes
**cultivées**, celles des jardineries, des balcons et des jardins, plutôt
que ce dont GBIF a le plus. La v6 l'avait fait sans le nommer (§ 12.11,
« sélectionner, ne pas tirer ») ; la mesure dit maintenant pourquoi c'était
la bonne intuition.

Et deux corrections gratuites avant toute collecte : les **six doublons**
du § 12.14 — *Cupressus macrocarpa* rate 20 de ses 26 images, dont **8 en
répondant son propre autre nom** —, et les **14 plantes d'appartement
absentes** du § 12.12.

Trois réserves sur ce chiffre, dans les deux sens : l'échantillon est de
vingt, donc l'incertitude est d'une vingtaine de points ; c'est une **borne
basse**, GBIF ne filtrant que CC0 et CC BY à la requête et iNaturalist en
direct n'étant pas interrogé (§ 4.3) ; mais un tirage **au hasard** est le
pire cas.

#### La conclusion : sélectionner, ne pas tirer

C'est déjà ce que la v6 avait fait sans le nommer — ses 530 ajouts étaient
« les espèces cultivées les plus observées en Europe ». La liste des
candidates doit se **générer par nombre d'observations**, pas se tirer du
catalogue étendu. `disponibilite.py` devient alors une vérification, pas une
recherche.

#### ✅ Fait, et le résultat renverse la prudence ci-dessus

`tools/plant_dataset/candidats.py`. **Ce n'est pas GBIF qui sait dire
« cultivée »** : il a le champ (`degreeOfEstablishment=cultivated`) et
personne ne le remplit — **288 occurrences sur 76 millions**, quatre
millionièmes. Mesuré, pas supposé.

C'est **iNaturalist** : son drapeau « captive/cultivated » est posé par les
observateurs et massivement utilisé, et l'API rend le classement tout fait.
58 543 espèces de plantes cultivées, triées par observations. En tête :
hibiscus, laurier-rose, érable du Japon, lagerstroemia, croton, romarin,
aloès. Le rayon d'une jardinerie, pas une flore de terrain.

Après retrait des 1 457 déjà connues : **7 658 candidates nouvelles**.

| rang de la candidate | observations cultivées |
|---|---|
| 500ᵉ | 1 489 (*Eucalyptus robusta*) |
| 1 543ᵉ — de quoi viser 3 000 | 481 (*Correa alba*) |
| 3 000ᵉ | 203 |
| 3 543ᵉ — de quoi viser 5 000 | 160 (*Trichocereus atacamensis*) |
| 5 000ᵉ | 94 |

#### Le gap entre 3 000 et 5 000 : il n'y en a pas

C'est la question qui décide, et elle se mesure : sur 35 candidates tirées
au sort dans chaque bande, combien atteignent les 25 images de
`--min-train` chez GBIF ?

| | au-dessus de 25 images | maigres | jamais photographiées |
|---|---|---|---|
| **rangs 1 – 1 543** (viser 3 000) | **30/35 — 86 %** | 5 | 0 |
| **rangs 1 544 – 3 543** (les 2 000 de plus) | **29/35 — 83 %** | 6 | 0 |

Trois points d'écart, dans le bruit d'un échantillon de 35. **La deuxième
bande vaut la première.** Et les deux valent le double du tirage au hasard
mesuré plus haut, qui rendait 40 % : c'est la sélection qui produit
l'écart, pas la profondeur.

Le chiffre est en outre une **borne basse** : GBIF ne filtre que CC0 et CC BY
à la requête, le partage à l'identique ne se voit qu'au média, et
iNaturalist en direct — qui apporte précisément les plantes cultivées
(§ 4.3) — n'est pas interrogé du tout.

Ce qu'on peut donc attendre :

| | candidates à collecter | classes réelles attendues |
|---|---|---|
| viser 3 000 | 1 543 | ≈ **2 780** |
| viser 5 000 | 3 543 | ≈ **4 430** |
| atteindre 5 000 | ≈ 4 220 | ≈ 5 000 |

#### ✅ Ce que la collecte a réellement rendu

4 220 candidates collectées en vingt-deux heures, quatre parts, plus une
reprise GBIF pour les espèces tombées sur le quota journalier d'iNaturalist.
Fusionnées au jeu de l'Iris 7 :

| | |
|---|---|
| espèces du catalogue ayant des images | **5 646 / 5 778 — 97,7 %** |
| qui passent `--min-train 25` | **5 371 / 5 646 — 95,1 %** |
| qui passent **aussi** `--min-val 3` | **5 259 / 5 646 — 93,1 %** |
| images gardées | 991 926 sur 1 014 678 (4 596 doublons exacts) |
| par classe | 185 (199 pour l'Iris 7) |
| **classes de l'Iris 8** | **5 259**, soit 3,6× l'Iris 7 |

Les 112 espèces qui tombent entre les deux seuils ne manquaient pas
d'images — c'est la réparation du découpage qui leur en donnait trop peu à
valider. Diagnostic et correctif au § 12.19 ; il prend effet à la prochaine
construction du jeu, pas sur l'Iris 8.

> **Ces 5 259 classes n'ont pas été livrées.** Mesuré sur les mêmes images,
> le modèle à 5 259 sorties rend *moins* bien que l'Iris 7 sur les espèces
> que l'utilisateur avait déjà. L'Iris 8 livré est le même réseau retaillé à
> **1 444 classes**, et il gagne 6,6 points de top-1. La collecte a servi —
> comme matière d'entraînement, pas comme répertoire. Tout est au § 6.7 bis,
> et c'est la leçon la plus chère de cette version.

**L'échantillon de 35 espèces annonçait 84 % ; la réalité est à 95 %.** Ce
n'est pas une erreur de l'échantillon, c'est sa limite, écrite dans sa
propre documentation : `disponibilite.py` n'interroge que GBIF en CC0 et
CC BY, alors que la collecte a aussi eu iNaturalist, le partage à
l'identique et Commons. Il annonçait une **borne basse** et c'en était une.

La conséquence pratique dépasse ce chiffre : **la disponibilité n'était pas
le facteur limitant, et ne l'était probablement pas non plus à 3 000.** Le
gap qu'on cherchait entre les deux cibles n'existait ni dans l'échantillon
ni dans les faits.

#### Ce que 5 000 coûte vraiment

Pas la disponibilité, donc. Trois autres choses :

| | 1 457 | 3 000 | 5 000 |
|---|---|---|---|
| `.tflite` livré | 8,8 Mo | ≈ 11,8 Mo | **≈ 15,6 Mo** |
| collecte | ~6 h | ~12 h | **~15 h**, bornée par les API |
| jeu d'images | 15 Go | ~30 Go | **~50 Go** (et le triple en cours de collecte) |
| une recette d'entraînement | 25 min | ~2 h | **~3 h** |

La tête est un `Dense(960 → N)` : c'est le seul poste qui grossit avec le
nombre de classes, à raison de deux octets par classe et par canal.

**Et le vrai prix reste celui du § 12.12** : dix points de top-1 pris à
celui qui photographie son salon, pour les espèces qu'il ne photographiera
jamais. Passer de 1 457 à 5 000 ne peut qu'aggraver ce chiffre.

#### La pièce qui manquait entre la sélection et la collecte

`build_dataset.py --only-file` ne **filtre** que les plantes déjà présentes
dans `plants.csv` : une candidate absente du catalogue n'est pas collectée,
**elle est ignorée en silence**. Le défaut ne se voit qu'après la collecte,
dans un décompte plus court que prévu — quinze heures pour rien.

D'où `candidats.py --inscrire`, qui ajoute les candidates retenues au
catalogue avant de collecter. Les lignes créées ne portent que ce que le nom
donne — identifiant interne, genre, épithète ; la famille, la clé GBIF et
l'identifiant Wikidata viennent ensuite d'`enrich_plants.py`.

La chaîne complète, dans l'ordre :

```bash
python3 candidats.py --combien 4220 --out candidats_v8.txt --inscrire
python3 enrich_plants.py --gbif --wikidata
# puis la collecte en parts, § 3 de docs/10
```

#### La décision se déplace, elle ne se prend pas maintenant

**Collecter ne force pas à entraîner.** Les images de 4 000 candidates
servent aussi bien un modèle à 3 000 classes qu'un modèle à 5 000 : c'est
`--min-train` et la liste des classes qui tranchent, à l'entraînement, en
vingt-cinq minutes de plus.

Donc : **collecter large** — la collecte est le travail long, irréversible
et borné par les API —, puis **entraîner les deux et mesurer** avec
`compare_models.py` (§ 12.10). Le critère de réussite ci-dessous ne change
pas ; il devient simplement décidable au lieu d'être pronostiqué.

#### Le critère de réussite, à fixer maintenant

Deux conditions, mesurées avec `compare_models.py` (§ 12.10) :

1. **Les 1 457 espèces actuelles ne régressent pas.** Quelqu'un qui
   photographie son monstera ne doit rien perdre à ce qu'on ait ajouté des
   orchidées rares.
2. **Les nouvelles dépassent 45 % de top-1.** En dessous, elles encombrent
   plus qu'elles ne servent — et le repli Pl@ntNet existe précisément pour la
   plante inhabituelle.

#### L'ordre du travail

La couverture seule ne rend pas l'application meilleure sur les plantes que
les gens possèdent ; le domaine visuel, si. Les deux dans la même version,
mais mesurés séparément :

1. les **quatorze plantes d'appartement absentes** du catalogue (§ 12.12) —
   déjà mesurées, quatorze noms à collecter, et ce sont celles que les gens
   possèdent ;
2. `confusions.py` sur Iris 7 — dix minutes, aucune collecte, et il dira
   **lesquelles** des espèces actuelles réclament des images (§ 12.4) ;
3. la liste des candidates, générée par observations et vérifiée par
   `disponibilite.py` ;
4. la collecte, avec Commons pour le domaine (§ 12.2) et PlantNet-300K
   plafonné pour le volume (§ 12.8) ;
5. les recettes, une à la fois, comme pour la v7.

### 12.12 Ce que le modèle rend sur les plantes d'appartement

*Mesuré sur l'Iris 7 ; ce que le modèle livré annonce depuis est dans la
fiche du § 0. Ce que la section établit — l'écart entre les plantes
d'appartement et le reste, et le prix de l'étendue — ne dépend pas de la
version.*

Le top-1 publié — **0,5961** — est une moyenne sur 1 457 espèces dont la
plupart sont sauvages, européennes, et que personne ne photographie dans son
salon. L'application, elle, sert d'abord les 167 noms de
`phase1_species.txt` : les plantes qu'on achète en jardinerie et qu'on pose
sur une étagère. Ce chiffre-là n'a jamais été mesuré.

`tools/plant_model/interieur.py` le mesure, et il commence par une question
qui vient avant la précision.

#### La couverture d'abord — mesurée, et elle surprend

**Une espèce absente du catalogue ne se trompe pas : elle ne se propose
jamais.** Elle est un échec certain pour l'utilisateur, et elle est
*invisible* dans toute mesure de top-1 — on ne compte pas les erreurs d'une
classe qui n'existe pas. Il faut donc la compter à part, et cette partie ne
demande ni carte graphique, ni jeu d'images, ni TensorFlow :

```bash
cd tools/plant_model && python3 interieur.py --couverture
```

| | |
|---|---|
| noms dans `phase1_species.txt` | 167 |
| plantes distinctes | **165** — *Calathea* et *Goeppertia orbifolia* sont la même, *Saintpaulia ionantha* et *Streptocarpus ionanthus* aussi |
| que l'Iris 7 sait nommer | **151** |
| **couverture** | **92 %** |

Deux de ces 151 ne se trouvent qu'en résolvant les noms, et c'est pour cela
que l'outil le fait : *Streptocarpus ionanthus* est au catalogue sous
`saintpaulia-ionantha` (colonne `synonyms` de `plants.csv`), et *Citrus
limon* sous `citrus-x-limon` — le × que la liste ne met pas. Les compter
absentes aurait été une erreur de lecture, pas une lacune du modèle.

#### Les quatorze plantes que l'application ne peut pas nommer

| | |
|---|---|
| *Phalaenopsis amabilis* | l'orchidée la plus vendue d'Europe |
| *Rhaphidophora tetrasperma* | le « mini-monstera », la plante à la mode |
| *Alocasia zebrina*, *Alocasia amazonica* | deux Alocasia sur trois du commerce |
| *Begonia rex* | trois *Begonia* au catalogue, pas celui-là |
| *Peperomia argyreia* | le pépéromia melon d'eau |
| *Calathea* (*Goeppertia*) *orbifolia* | le genre est là — `goeppertia-makoyana` — l'espèce non |
| *Anthurium clarinervium* | `anthurium-andraeanum` est là, pas lui |
| *Cymbidium hybridum*, *Hippeastrum vittatum*, *Gynura aurantiaca*, *Columnea gloriosa*, *Ravenea rivularis*, *Pachyphytum oviferum* | genre entièrement absent |

Ce ne sont pas des espèces rares : ce sont des plantes de supermarché. Six
d'entre elles ont un genre déjà au catalogue — les deux *Alocasia*, le
*Begonia*, l'*Anthurium*, le *Peperomia*, le *Calathea* —, ce qui veut dire
que le modèle répondra **une cousine avec assurance** plutôt que rien : le
cas le plus coûteux du § 6.7, celui de la réponse acceptée qui est fausse.

#### La précision, mesurée sur le `.tflite` livré

3 606 images de test portent sur ces 151 espèces. Deux lectures, la seconde
avec les sorties masquées aux seules plantes d'intérieur — ce que rendrait
un modèle qui n'aurait appris qu'elles :

| sur les 3 606 images | top-1 | top-3 | à 0,70 |
|---|---|---|---|
| **catalogue entier** (1 457 sorties) | 0,6733 | 0,8028 | 57,4 % acceptées, 90,6 % justes |
| **catalogue restreint** (151 sorties) | **0,7754** | 0,8899 | 54,6 % acceptées, 95,1 % justes |
| les mêmes, **photographiées en pot** (1 963 images) | 0,6796 | 0,8105 | 59,6 % acceptées, 89,9 % justes |
| pour comparaison, **tout le reste du catalogue** (4 000 images) | 0,5888 | 0,7403 | |

Trois choses en sortent, et elles ne disent pas la même chose.

**1. Le titre sous-vend le modèle sur son terrain.** 67,3 % sur les plantes
d'appartement contre 58,9 % sur le reste : **huit points et demi d'écart**
en faveur des photos que l'application reçoit vraiment. Le 0,5961 publié est
une moyenne sur une population que l'utilisateur ne photographie pas.

**2. Le `.tflite` livré vaut ce que `model.json` annonce.** 59,0 % sur 6 000
images tirées au hasard contre 59,61 % annoncés sur 28 983 : l'écart tient
dans le bruit d'échantillonnage (± 1,2 point à 6 000 tirages). L'export
float16 ne coûte rien de mesurable — c'était pris sur parole jusqu'ici.

**3. Le prix de l'étendue est de dix points.** Restreindre les sorties aux
151 plantes d'intérieur fait passer le top-1 de 67,3 % à **77,5 %**, et la
précision des réponses acceptées de 90,6 % à **95,1 %**. Les 1 306 espèces
que l'utilisateur ne photographiera jamais lui coûtent donc **dix points de
top-1**, tous les jours.

> **Confirmé depuis, par un autre chemin.** Le § 6.7 bis fait passer un même
> réseau de 5 259 sorties à 1 444 sur les mêmes 6 000 images : 0,5528 contre
> 0,6543, soit **10,2 points**, et 11,1 sur les plantes cultivées. Deux
> mesures indépendantes, deux jeux de classes différents, le même ordre de
> grandeur. Ce n'est donc pas une particularité des plantes d'intérieur :
> c'est ce que coûte une sortie de plus, quelle qu'elle soit.

> Le top-1 est exact : masquer préserve l'ordre entre les classes qui
> restent, renormaliser n'y change rien. Les colonnes de seuil, elles, sont
> mesurées **après** renormalisation (`score(..., renormalise=True)`), sans
> quoi la masse partie aux classes masquées ne reviendrait à personne et
> l'autonomie serait artificiellement basse. Un modèle réellement entraîné
> sur 151 classes ferait vraisemblablement mieux encore : il aurait la même
> capacité pour neuf fois moins d'espèces.

#### Ce que ça change dans l'ordre du travail

Quatorze classes manquantes sur les plantes que les gens possèdent, contre
1 543 espèces à ajouter pour atteindre 3 000. Le second chantier coûte douze
heures de collecte et deux heures d'entraînement par recette ; le premier
coûte une collecte de quatorze noms. **Ils ne se valent pas, et le petit
passe devant** — il ne demande même pas d'attendre la v8, `--min-train`
mis à part.

#### Et une piste qui ne demande aucun entraînement

Ces dix points ne s'obtiennent pas qu'en rétrécissant le modèle : ils
s'obtiennent en rétrécissant **la liste des candidats au moment de
répondre**. C'est un masque sur les sorties, quelques lignes dans la
cascade, aucune collecte et aucune passe d'entraînement — et l'application
sait souvent de quoi il s'agit, puisqu'elle sert d'abord à suivre des
plantes en pot.

Ce n'est pas gratuit pour autant : masquer, c'est **rendre impossible** la
bonne réponse pour qui photographie un érable dans la rue. Le § 3.2 avait
prévu la classe « autre » pour ce genre de garde-fou et elle n'existe
toujours pas (§ 12.7). À creuser avec les mêmes 3 606 images avant d'écrire
quoi que ce soit — mais dix points pour zéro heure de calcul, c'est le
meilleur rapport de toute cette liste.

### 12.13 Les attributions ne sortent pas de la machine d'entraînement

La collecte fait ce qu'il faut : `write_attributions` écrit, pour chacune
des 290 131 images gardées, son auteur, sa licence et le lien vers
l'observation (`dataset/ATTRIBUTIONS.md` et `dataset/attributions.csv`).
Son commentaire dit « c'est ce qu'on livrera avec le modèle », et le
[`README` du collecteur](../tools/plant_dataset/README.md) écrit qu'ils
« doivent être livrés avec le modèle ». Le § 7 les compte parmi les
livrables.

**Ils ne le sont pas.** `assets/model/` contient `plants.tflite`,
`labels.txt` et `model.json`, rien d'autre — et `pubspec.yaml` embarquant le
dossier entier, il suffirait d'y déposer le fichier pour qu'il parte dans
l'app. Deux choses à trancher, et elles sont indépendantes.

#### 1. La sauvegarde, qui n'attend pas

`dataset/` est dans `.gitignore` et vit sur une machine louée à l'heure.
**Ce fichier est la seule trace de la provenance de 290 131 images** : d'où
elles viennent, sous quelle licence, de qui. Le jeu se recollecte — les
images sont toujours chez GBIF et iNaturalist —, mais pas à l'identique :
une observation retirée, une licence changée, et la trace de ce que le
modèle *livré* a réellement vu est perdue. `attributions.csv` compressé pèse
quelques dizaines de mégaoctets ; il devrait sortir de la VM avant qu'elle
ne soit rendue.

#### 2. Ce qu'on livre dans l'app, qui demande une décision

Le fichier entier fait de l'ordre de **40 Mo** — une ligne de 130 octets par
image, contre 8,8 Mo pour le modèle. Le livrer tel quel quadruplerait le
poids de l'application pour un texte que personne ne lira. Trois voies :

- **une forme condensée** dans `assets/model/` : une ligne par auteur
  distinct plutôt que par image, avec les licences et les sources. Il faut
  d'abord compter les auteurs distincts — le chiffre n'existe pas ;
- **le fichier entier publié à côté** (dépôt ou site), l'app y renvoyant
  depuis un écran de crédits qu'elle n'a pas encore ;
- **écrire noir sur blanc qu'on ne le livre pas**, et pourquoi. C'est
  défendable — la question de savoir si des poids sont une adaptation des
  images n'est pas tranchée —, mais alors il faut corriger les trois
  endroits qui promettent le contraire, plutôt que de les laisser dire une
  chose que le dépôt ne fait pas.

Ce qui n'est pas défendable, c'est l'état actuel : trois documents et un
commentaire de code annoncent une livraison qui n'a pas lieu.

### 12.14 Six plantes comptées deux fois

`tools/plant_dataset/doublons.py`. Trouvé en cherchant pourquoi
`hesperocyparis → cupressus` était en tête des confusions de genre du
§ 12.4 : ce n'était pas une erreur du modèle. **Les deux noms sont la même
plante, et tous deux sont des classes.**

Les 1 457 noms du catalogue ont été résolus vers leur taxon accepté chez
GBIF — aucun non résolu — et six couples tombent sur la même clé :

| | | |
|---|---|---|
| `dracaena-trifasciata` | `sansevieria-trifasciata` | **la sansevière**, genre changé en 2017 |
| `coleus-scutellarioides` | `plectranthus-scutellarioides` | **le coléus** |
| `echinocactus-grusonii` | `kroenleinia-grusonii` | **le coussin de belle-mère** |
| `cupressus-macrocarpa` | `hesperocyparis-macrocarpa` | le cyprès de Lambert |
| `citrus-myrtifolia` | `citrus-x-aurantium` | le chinotto, une forme de bigaradier |
| `citrus-x-bergamia` | `citrus-x-limon` | la bergamote, rattachée au citron par GBIF |

Les quatre premiers ne prêtent pas à discussion. **Les deux derniers sont le
jugement de GBIF sur le marais taxonomique des agrumes**, et méritent d'être
confirmés avant fusion — mais ils expliquent au passage pourquoi *Citrus ×
limon* rate 23 de ses 26 images de test en répondant six fois *Citrus ×
aurantium* (§ 12.4).

#### Ce que ça coûte, trois fois

- **les images se partagent.** Une plante photographiée sous deux noms
  nourrit deux classes à demi. Pour la sansevière — l'une des plantes
  d'appartement les plus vendues — c'est exactement le contraire de ce que
  le § 12.12 demande ;
- **la confusion est imperdable.** Aucune photo ne peut trancher, puisqu'il
  n'y a rien à trancher. Elle compte pourtant dans la matrice comme un
  défaut, et elle a occupé la tête du classement ;
- **le décompte de classes est faux d'autant.** 1 457 annoncées, 1 451
  plantes.

#### Pourquoi il fallait GBIF et pas une heuristique

Le premier réflexe — deux identifiants qui partagent leur épithète dans une
même famille — rend **34 groupes pour 4 vrais doublons** sur ce catalogue.
*Populus alba* et *Salix alba* ne sont pas la même plante ; `officinalis`,
`vulgaris` et `japonica` sont des passe-partout. Et l'heuristique **rate**
les deux couples d'agrumes, dont l'épithète diffère. GBIF est déjà l'arbitre
de la collecte et de `synonyms.txt` (§ 6.5) ; il n'y avait pas de raison
d'en prendre un autre.

**Sa limite, écrite dans l'outil.** La dorsale GBIF retarde sur certains
transferts récents : *Schefflera arboricola* et *Heptapleurum arboricola* y
sont deux taxons acceptés, donc l'outil ne les signale pas, alors que la
littérature récente les tient pour une seule plante — et ce sont deux
classes du modèle. **L'outil rend les doublons certains, pas tous les
doublons.**

#### ✅ Ce que ça changeait pour l'utilisateur, et qui est corrigé

Le défaut n'attendait pas la v8 : **il était déjà dans l'app livrée.** Les
deux noms sont dans `catalog.tsv`, et `catalogLookup` (`providers.dart`)
résolvait chacun pour son compte. Selon la photo, la même sansevière
donnait :

| | fiche trouvée | nom affiché en français | identifiant interne |
|---|---|---|---|
| classe `dracaena-trifasciata` | celle soignée à la main | **Langue de belle-mère** | `dracaena-trifasciata` |
| classe `sansevieria-trifasciata` | le catalogue étendu | *Mother-in-law's tongue* | `sansevieria-trifasciata` |

Deux fiches dans la recherche, deux noms, **deux identifiants internes donc
deux profils de soin** — pour une seule plante, au hasard de la photo.

`acceptedSpeciesName()` (`core/utils/scientific_name.dart`) rattache les
cinq couples avant la résolution, à l'entonnoir unique qu'est
`catalogLookup`. Le nom reçu reste affichable — *Sansevieria trifasciata*
est un nom juste — mais l'identité, elle, est unique.

**Et le sens de la flèche n'est pas celui qu'on croit**, ce qui a failli me
coûter la correction. GBIF dit *quels* noms sont la même plante ; il ne dit
pas lequel garder. Suivre le nom accepté de GBIF aurait donné :

- *Coleus scutellarioides*, que **ni** la fiche soignée **ni** le catalogue
  étendu ne portent — la plante ne serait plus reconnue du tout ;
- *Kroenleinia grusonii*, qui n'est que dans le catalogue étendu, là où
  *Echinocactus grusonii* a sa fiche soignée à la main et son nom français.

Ce qui décide, c'est **ce que l'app possède** : fiche soignée d'abord,
catalogue étendu ensuite. Les cinq flèches pointent maintenant vers un nom
dont les quatre langues existent, vérifié une par une.

*Citrus × bergamia* est volontairement laissée de côté : GBIF la rattache au
citron, la bergamote n'est pas un citron pour qui la cultive, et aucun des
deux catalogues ne la porte — il n'y a pas de contradiction à lever.

#### Ce qui reste, pour la v8

Les cinq couples sont inscrits dans la colonne `synonyms` de `plants.csv`,
donc lisibles par la collecte. **Retirer les lignes en double du catalogue
de collecte est la décision suivante** : elle change le jeu d'étiquettes du
modèle, donc elle se prend en ouvrant la v8, pas en passant. Les images se
rejoindront alors, et six classes fantômes quitteront le décompte.

#### Et le catalogue de la v8 en a ramené quarante de plus

Le catalogue est passé à 5 778 lignes (§ 12.11), et le défaut a suivi.
Simple comptage des clés GBIF déjà résolues dans `plants.csv` — aucun appel
réseau :

| | |
|---|---|
| clés GBIF portées par plus d'une ligne | **46** |
| lignes en trop | **51** |
| groupes dont deux membres sont des classes de l'Iris 8 livré | 6 — les mêmes qu'ici |

L'Iris 8 livré n'est donc pas plus atteint qu'avant, et
`acceptedSpeciesName()` continue de le couvrir. Mais le modèle **à 5 259
classes**, lui, portait les 46 : *Calathea* et *Goeppertia orbifolia*,
*Dypsis* et *Chrysalidocarpus lutescens*, cinq agrumes sur une seule clé.
Autant de plantes dont les images se partageaient entre deux classes qui se
disputaient ensuite la réponse — une part, petite mais réelle, des dix
points du § 6.7 bis.

**Et 46 est une borne basse.** *Saintpaulia ionantha* et *Streptocarpus
ionanthus* sont deux lignes du catalogue pour une seule plante, et leurs
clés GBIF diffèrent : le comptage par clé ne les voit pas. C'est
`doublons.py`, qui demande à GBIF le taxon *accepté* de chaque nom, qui
donne le vrai chiffre — à lancer sur les 5 778 lignes avant la prochaine
collecte, pas après.

### 12.15 Répondre au niveau du genre, plutôt qu'une tête hiérarchique

La question posée : le modèle doit-il apprendre Famille → Genre → Espèce ?
**Non à l'entraînement, oui à la réponse**, et la matrice du § 12.4 dit
pourquoi.

#### Ce que la mesure interdit d'espérer

Une tête hiérarchique — trois sorties, trois pertes additionnées — sert
quand les erreurs se serrent contre l'arbre taxonomique. Les nôtres ne s'y
serrent pas : **73 % franchissent la famille**. Et le modèle a déjà appris
la taxonomie sans qu'on la lui donne : 12,8 % d'erreurs dans le genre, soit
**73 fois le hasard**. Ce qui manque n'est pas la structure, c'est la photo
— l'échec est par photo et non par espèce (§ 12.4), et aucune supervision
taxonomique ne fait parler une image qui ne dit rien.

S'y ajoute que les quasi-erreurs sont **déjà rattrapées par l'écran** :
top-3 à 74,4 % contre 59,6 % de top-1, cinq candidats affichés.

#### Ce que la même mesure rend gratuit

Sommer le softmax **par genre**. Quand cinq candidats sont cinq *Picea* à
0,15, le genre pèse 0,75 : « un épicéa, espèce incertaine » est une réponse
**vraie et utile**, là où cinq noms n'en sont pas une et où l'appel à
Pl@ntNet coûte du quota.

Le plancher se lit déjà dans les chiffres du § 12.4 :

| | top-1 |
|---|---|
| espèce | 59,0 % |
| **genre** | **≥ 64,3 %** |
| famille | ≥ 70,1 % |

Ce sont des planchers : ils ne comptent que les cas où la *première*
réponse tombait dans le bon genre, pas ceux où la masse du genre était
juste mais répartie.

Et à 5 000 classes, plus d'espèces par genre : ce que ça rapporte augmente
avec le catalogue, contrairement au top-1.

#### Le chiffre, mesuré

`genre.py` garde les distributions et somme par genre ; le plancher devient
un chiffre. Sur les 6 000 images de test d'Iris 8, **62 % portent sur une
espèce dont le genre en compte plusieurs** — les seules où le genre ajoute
quelque chose.

| top-1 | |
|---|---|
| espèce | 0,6543 |
| **genre** | **0,7130** |

Six points au-dessus de l'espèce, et le plancher du § 12.4 était bien un
plancher.

Ce que ça donne dans la cascade, masses sommées sur les **cinq** candidates
affichées et non sur les 1 444 classes — la configuration réelle de
l'application, au seuil 0,70 :

| | le genre répond | et il a raison |
|---|---|---|
| toutes les photos | 5,5 % | 89,9 % |
| photos en pot | 6,6 % | 88,7 % |

**Une réponse sur dix-huit**, juste neuf fois sur dix. C'est peu, et c'est
attendu : l'espèce garde la priorité, le genre ne parle que là où elle
renonçait. Le taux monte avec le seuil — à 0,80, 6,3 % des photos et 93,4 %
de justesse — parce qu'un seuil plus haut fait renoncer l'espèce plus
souvent et laisse au genre les cas qu'il traite bien.

> **Ce que la rareté implique pour le test.** Une fonctionnalité qui répond
> une fois sur dix-huit ne se vérifie pas en scannant trois plantes : il
> faudrait onze scans pour une chance sur deux. Elle se vérifie par la
> mesure ci-dessus et par ses tests unitaires, pas à l'œil. Le signe visible,
> pour qui veut la provoquer : la première ligne doit annoncer « Possible »
> et non « Probable » — au-dessus de 0,70 l'espèce ne renonce pas, et
> `genusAnswer()` rend `null` sans regarder plus loin.

### 12.16 Les cultivars : un second axe, pas des classes

*Monstera deliciosa* « Thai Constellation » est une *Monstera deliciosa*
panachée. Les gens en possèdent, et ils veulent le nom. La tentation est
d'en faire des classes ; **trois mesures l'interdisent.**

| | |
|---|---|
| iNaturalist | sur les 2 000 taxons cultivés les plus observés : 1 935 espèces, 65 hybrides, **zéro cultivar**. Une photo de « Thai Constellation » y est enregistrée *Monstera deliciosa* |
| Commons | la hiérarchie existe — `Monstera deliciosa (cultivars)` — et porte **1 fichier**. `Epipremnum aureum` « Marble Queen » : **3**. « N'Joy » : **6** |
| le seuil | 25 images pour qu'une classe entre dans le modèle, 200 visées |

> **Une mesure ratée, et ce qu'elle apprend.** La première version de ce
> paragraphe annonçait zéro photo partout. C'était faux : le connecteur
> cherchait `Category:Monstera deliciosa 'Thai Constellation'` quand Commons
> nomme `Category:Monstera deliciosa (cultivars)`. **Les zéros venaient de
> la requête, pas des données.** Refaite correctement, la conclusion tient —
> pour une autre raison, qui recoupe le § 12.2 : Commons est riche pour les
> plantes installées de longue date, pauvre pour les modes récentes, et
> « Thai Constellation » est une mode récente.

S'ajoute le risque propre : des centaines de classes visuellement quasi
identiques recréeraient à grande échelle le défaut du § 12.14 — les images
d'une plante partagées entre deux étiquettes, une confusion qu'aucune photo
ne peut trancher — et aggraveraient les dix points du § 12.12.

#### Ce qu'on fait à la place

**Le modèle répond l'espèce, l'application propose les cultivars.**
`tools/plant_dataset/cultivars.py` construit la liste depuis Wikidata, où un
cultivar est une instance de `Q4886` rattachée à son taxon parent. Sur les
360 premières espèces du catalogue : **622 cultivars sur 115 espèces, un
tiers du catalogue en a au moins un** — *Acer palmatum* « Bloodgood »,
*Ficus elastica* « Robusta », *Epipremnum aureum* « Neon ».

Un garde-fou non négociable : `Q4886` porte aussi des taxons qui n'en sont
pas. La règle du code horticole tranche — **un nom de cultivar prend une
majuscule** —, ce qui écarte *Hosta decorata* (une espèce) et « Agave
americana var. medio-picta alba » (une variété).

Si un jour un modèle doit les distinguer, **la source sera l'application
elle-même** : demander « quel cultivar ? » après avoir dit l'espèce
accumule le jeu étiqueté qui n'existe nulle part. Ça commence par poser la
question, pas par entraîner.

### 12.17 ✅ Commons range les plantes en pot, et on ne le lui demandait pas

Trouvé en cherchant les cultivars : `Category:Monstera deliciosa (potted)`
porte **41 fichiers**. Commons **catégorise le contexte** — `(potted)`,
`(flowers)`, `(leaves)`, `(products)`, `- botanical illustrations`.

Or le § 12.4 dit que 73 % des erreurs viennent de n'avoir jamais vu la
plante telle qu'on la cultive, et le § 6.3 a déjà payé une fois ce défaut —
le yucca pris pour du maïs, corrigé en recollectant des photos en pot.

Le connecteur descendait bien d'un niveau, mais prenait **les six premières
sous-catégories rendues par l'API** : `(potted)` passait ou non au hasard,
et `(products)` — des confitures — pouvait prendre sa place.
`classer_souscategories()` les ordonne maintenant : les plantes en pot et
les cultivars d'abord, les planches botaniques et les herbiers jamais.

Quelques lignes, aucune collecte de plus, et ça vise le défaut le plus cher
du modèle. À faire **avant** la collecte de la v8, sinon on ramène 4 220
espèces sans en profiter.

### 12.18 L'étage cultivar : prototypes plutôt que classes

Le § 12.16 concluait que le cultivar ne pouvait pas être une classe et le
renvoyait à une question posée à l'utilisateur. **Il y a mieux, et ça ne
coûte pas ce que j'avais chiffré.**

```
photo → backbone → embedding
                      ↓
              classifieur d'espèces          ← 50-100+ observations, classes
                      ↓
             « Monstera deliciosa »
                      ↓
         prototypes du genre/espèce          ← 5-30 observations, suggestion
                      ↓
        Thai / Albo / Aurea / Mint
```

**Pourquoi c'est bon marché, contrairement à ce que je disais.** Les dix
points du § 12.12 viennent de l'étendue du *softmax* : chaque classe de plus
est un candidat de plus à écarter pour toutes les photos. Un étage
conditionné à l'espèce n'élargit rien — il ne sépare que les quatre ou huit
cultivars d'une seule plante, une fois l'espèce connue. Le sous-problème est
minuscule, et ajouter un cultivar ne demande **aucun réentraînement** : un
prototype de plus dans la base.

L'infrastructure existe déjà : `--feature-cache` met en cache les
activations du réseau gelé, **960 nombres par image** (`FEATURE_DIM`).

#### Trois réserves, dont une qui peut tout arrêter

**1. Le réglage fin apprend à effacer ce qu'on cherche.** Chaque photo de
« Thai Constellation » de notre jeu est étiquetée *Monstera deliciosa*. Les
cent couches dégelées poussent donc l'embedding à **faire converger** le
cultivar panaché et la plante ordinaire. Chercher les cultivars dans cette
représentation, c'est les chercher dans la seule qu'on ait entraînée à les
confondre. Parades, du moins cher au plus cher : partir du backbone
**ImageNet gelé** ; prendre une couche **plus précoce**, la panachure étant
un signal de couleur que les couches basses gardent mieux ; ou ajouter une
perte contrastive au réglage fin.

**2. La donnée manque là où l'app en a besoin.** Le seuil relâché à 10-30
photos est le bon raisonnement, mais Commons donne **1** fichier pour
`Monstera deliciosa (cultivars)`, **3** pour « Marble Queen », **6** pour
« N'Joy ». Là où il y a de quoi, c'est *Acer palmatum*, *Hosta*, *Rosa* —
les classiques de jardin, photographiés depuis vingt ans. L'architecture
marcherait donc **d'abord sur les érables, pas sur la Monstera panachée**,
soit l'inverse de ce que l'application sert. C'est le § 12.2 encore.

**3. La base de prototypes n'est pas gratuite sur le téléphone.**

| | 960 dimensions | projetées en 128 |
|---|---|---|
| 5 000 prototypes, float16 | 9,6 Mo | **1,3 Mo** |
| 7 500 prototypes | 14,4 Mo | 1,9 Mo |

Neuf mégaoctets, c'est plus que le modèle entier. **La projection fait
partie du dessin, pas de l'optimisation.**

#### L'expérience qui tranche, et son piège

`tools/plant_model/prototypes.py`. Elle compare la similarité entre deux
photos d'un même cultivar et celle entre deux cultivars **de la même
espèce** — séparer deux espèces étant déjà résolu.

> **Le piège, mesuré en écrivant l'outil.** Dix photos dans un espace à 960
> dimensions se séparent presque toujours : sur du bruit pur, un prototype
> laissant une photo de côté atteint **0,9 de justesse**. Ce n'est pas une
> propriété des cultivars, c'est une propriété des petits échantillons en
> grande dimension. Sans témoin, l'expérience aurait conclu que l'embedding
> sépare les cultivars — quel que soit l'embedding.
>
> D'où un **test de permutation** : on mélange les étiquettes deux cents
> fois et on regarde la part des mélanges qui font aussi bien. Comparer à
> leur *moyenne* ne suffirait pas — une réalisation dépasse une moyenne une
> fois sur deux.

```bash
python3 prototypes.py --recolter --especes "Acer palmatum,Hosta,Rosa"
python3 prototypes.py --mesurer                    # ImageNet gelé
python3 prototypes.py --mesurer --poids .cache/ckpt/fine.weights.h5   # notre réseau
```

Les deux lectures répondent à la réserve n° 1 : si le réseau gelé sépare et
que le nôtre non, c'est le réglage fin qui a effacé le signal, et l'étage
cultivar doit partir d'ailleurs.

### 12.19 ✅ 112 espèces écartées pour une image de validation

Le compte des classes d'Iris 8 ne tombait pas juste : la finalisation
annonçait 5 371 classes, `train.py` en a déclaré **5 259**. L'entonnoir, lu
sur `splits.csv` :

| | classes | perdues |
|---|---|---|
| espèces dans `splits.csv` | 5 628 | |
| `train ≥ 25` | 5 371 | −257, trop peu d'images |
| `train ≥ 25` **et** `val ≥ 3` | **5 259** | −112, pas de quoi valider |

Ces 112 ne sont pas des classes fragiles : **47 images d'entraînement en
médiane, jusqu'à 193** — *Sinapis alba*, *Hylotelephium telephium*. 6 356
images d'entraînement partent avec elles. Et aucune n'avait une validation
vide : toutes en avaient **une ou deux**.

**C'est la réparation elle-même qui les a mises là.**
`repair_species_coverage` donnait bien un groupe de validation aux espèces
qui n'en avaient aucun — d'où les zéros absents — mais elle prenait **le plus
petit groupe d'entraînement**. L'intention était bonne (perdre le moins
possible d'entraînement) ; l'effet ne l'était pas : le plus petit groupe fait
souvent une ou deux photos, et `train.py` en exige trois.

**Les deux moitiés du système ne visaient pas la même cible.** La réparation
visait « au moins un groupe », `train.py` exige « au moins `--min-val`
images ». Une espèce réparée avec un groupe de deux photos était réparée sur
le papier et écartée en pratique. Et la réparation ne se déclenchait que si
la validation était *absente* : une espèce à qui le hachage avait
naturellement donné deux photos n'était jamais touchée.

Corrigé dans `plant_dataset/splits.py`, qui nomme désormais les deux seuils
(`MIN_TRAIN`, `MIN_VAL`) et les vise :

- on répare aussi une validation **présente mais sous le seuil** ;
- on choisit le plan qui **sort le moins d'images de l'entraînement** — le
  plus petit groupe qui comble à lui seul, ou les plus petits accumulés,
  selon lequel coûte le moins ;
- un plan qui ferait passer l'entraînement sous `--min-train` est **abandonné
  entier** : la classe serait écartée quand même, et on aurait perdu les
  images pour rien.

**Le correctif ne peut pas fausser une comparaison entre versions** : une
espèce qui satisfait déjà les deux seuils n'est jamais touchée, donc seules
des classes absentes du modèle précédent changent de découpage. C'est la
propriété que vérifie
`test_repair_leaves_alone_a_species_that_already_meets_the_thresholds`.

Trouvé pendant l'entraînement de la v8, donc **trop tard pour elle** :
changer la liste des classes invalide l'empreinte du cache de traits et
relancerait l'encodage. Ça prend effet à la prochaine construction du jeu.

## 13. Cadrage de l'Iris 9 : entraîner large, exposer étroit

> **Écrit avant l'Iris 8, révisé par elle.** La première version de ce
> cadrage disait « nourrir, pas grossir » et attendait un chiffre : ce que
> la largeur coûte réellement à 5 000 classes. Le chiffre est tombé —
> **10,2 points** (§ 6.7 bis) — et il a changé le titre. Grossir n'est pas
> le problème ; grossir *à la sortie* l'est. Les deux ne se décidaient pas
> séparément jusqu'ici, et c'est le vrai acquis de la v8.

### 13.1 Les sept faits, et ce qu'ils imposent

Chacun a coûté une version ou une nuit. Ensemble ils ne laissent pas
beaucoup de choix.

| ce qui est mesuré | où | ce que ça impose |
|---|---|---|
| **73 %** des erreurs franchissent la **famille** botanique | § 12.4 | ce ne sont pas des confusions entre voisines : la photo est hors du domaine appris |
| **5 espèces sur 1 422** jamais reconnues, **76** sous 25 % | § 12.4 | l'échec est **par photo**, pas par espèce — les classes sont apprises |
| **67,3 %** sur les plantes d'appartement contre 58,9 % ailleurs | § 12.12 | le seul endroit où le modèle est bon est celui où on lui avait donné des photos en pot (§ 6.3) |
| tripler le jeu rend **+6,8 points** sur les espèces déjà connues | § 6.7 bis | la collecte large **paie**, dans l'entraînement |
| exposer 5 259 sorties au lieu de 1 444 coûte **−10,2 points** | § 6.7 bis | la même largeur **coûte**, dans les sorties |
| sommer le softmax par genre : **+5,3 points au moins**, sans entraînement | § 12.15 | une réponse plus vague et vraie vaut mieux que cinq noms faux |
| **46 clés GBIF** portées par plusieurs lignes du catalogue | § 12.14 | des classes qui se disputent les mêmes images, sans qu'aucune photo puisse trancher |

Les deux lignes du milieu sont la découverte de la v8, et elles se
contredisent en apparence. C'est la clé de tout le reste.

### 13.2 Le principe : entraîner large, exposer étroit

**L'ensemble d'entraînement et l'ensemble exposé sont deux décisions
différentes.** On les avait confondues pendant huit versions, parce que
`train.py` fait des classes de tout ce qu'il trouve et que personne n'avait
essayé autrement.

La v8 les a séparées par accident, puis `retailler.py` l'a fait exprès :

- **large à l'entraînement** — 991 000 images sur 5 259 plantes ont produit
  une représentation nettement meilleure que 290 000 sur 1 457. Une espèce
  de plus, même si personne ne la photographiera jamais, apprend au réseau à
  mieux voir les autres ;
- **étroit à la sortie** — chaque classe exposée dispute les réponses de
  toutes les autres. Dix points entre 1 444 et 5 259 sorties, sur les mêmes
  poids et les mêmes photos.

#### Ce que ça change dans la conduite du projet

**Le nombre de classes cesse d'être un pari.** Il se choisissait avant la
collecte, donc vingt-deux heures et un entraînement avant d'en voir l'effet
— c'est ce qui a fait perdre une journée à débattre de « 3 000 ou 5 000 »
(§ 12.11) alors que la question ne se posait pas là. Désormais :

1. on collecte tout ce qu'on peut ;
2. on entraîne **une fois**, sur tout ;
3. on **mesure** la courbe des tailles de sortie ;
4. on exporte l'ensemble qu'on veut, en quelques minutes, autant de fois
   qu'on veut.

La décision la plus risquée n'est plus attachée à l'étape la plus chère.
C'est le vrai gain de la v8, et il vaut plus que ses six points.

> **Et un même réseau peut rendre plusieurs modèles.** Rien n'oblige à
> n'exporter qu'une tête. Un ensemble « ce qu'on cultive » et un ensemble
> « tout » sont deux fichiers tirés des mêmes poids — le § 12.12 attendait
> ce masque contextuel depuis la v7 ; il est maintenant à portée, sous
> réserve de la porte du § 13.6.

### 13.3 Les chantiers, par rapport mesuré

**1. ✅ Choisir l'ensemble exposé — mesuré, et la réponse n'est pas un
nombre.** La courbe est lue (§ 6.7 bis) : il n'y a **pas de coude**, le coût
est régulier à 0,22-0,35 point de top-1 par tranche de cent espèces, et il
n'existe **pas d'espèces gratuites** — 2 202 candidates ne volent rien sur
12 000 images de validation et coûtent quand même 5,9 points sur le test.
Le vol est trop diffus pour qu'on puisse l'éviter en écartant quelques
coupables.

Ce que la courbe donne à la place vaut mieux qu'un coude : un **seuil de
rentabilité** par taille d'ensemble. Exposer 356 espèces de plus paie dès
que 2,6 % des photos portent sur elles ; 2 202 de plus, dès 9,5 %. Le terme
manquant — la part des photos par espèce — est exactement ce que le chantier
2 produit. **Les deux chantiers se tiennent par là**, et la décision attend
un chiffre mesuré plutôt qu'un pari.

#### Iris Indoor — décision posée le 17 septembre 2026 : 500 espèces exposées, pas plus, toutes d'intérieur

Le nom d'abord, pour éviter la confusion : cette version-ci est **Iris
Indoor** — codée « 9.1 » pendant le cadrage, nommée par `docs/14`, qui en
fait la première spécialiste Indoor et la baseline que Iris 10 devra
battre. L'Iris 9 du présent § 13 reste l'entraînement large prévu, et les
deux ne se ressemblent pas. Le numéro est une chaîne libre dans
`model.json` : « Indoor » y tient autant que « 9 », rien à renommer (§ 8).

Le nombre n'attend plus la courbe : c'est une borne produit, assumée. La
liste candidate est déposée, résolue nom par nom (GBIF `species/match`),
dans `tools/plant_dataset/cible_interieur_500.tsv` :

| verdict | nombre | ce que ça engage |
|---|---|---|
| déjà exposées par Iris 8 | **155** | rien |
| dans `plants.csv`, entraînées v8, non exposées | **127** | exportables sans réentraînement, si présentes dans les 5 259 classes apprises — à vérifier à l'export |
| absentes, espèces acceptées | **161** | la collecte nouvelle — d'abord `disponibilite.py`, pas avant |
| absentes, synonymes | **43** | à collecter sous le nom accepté (*Rosmarinus officinalis* → *Salvia rosmarinus*…) |
| pas des espèces (cultivars, grex) | **14** | jamais une classe (§ 13.5) : *Philodendron birkin*, *Alocasia stingray*, *Cambria hybrida*… |

Deux conséquences d'arithmétique, pas d'opinion :

1. **La liste plafonne à 486 classes.** Pour tenir « exactement 500 », il
   faut au moins **14 espèces de substitution**, et davantage après le
   passage de `disponibilite.py` — la liste des remplaçantes se dressera à
   ce moment-là, sur le même rayon.
2. **Retirer des sorties paie.** À courbe constante, passer de 1 444 à
   500 exposées rend **2 à 3 points de top-1** mécaniquement (0,22-0,35
   point par tranche de cent). Les ~950 espèces qui sortent du masque
   basculent sur le repli Pl@ntNet et la réponse de genre : coût produit
   connu, pas accident.

   > **Cette dernière phrase est fausse pour un quart d'entre elles**, et la
   > mesure du § 12.7 le dit : sur 40 photos de plantes hors catalogue,
   > Iris Indoor en **affirme 27,5 %** au-dessus du seuil et avec la marge.
   > La cascade ne bascule pas, elle répond — et elle répond faux. Ce qui
   > était écrit comme une dégradation douce est, pour ces photos-là, une
   > erreur confiante. Le coût était sous-estimé, pas la direction.

Ce qui reste mesuré plutôt que parié : **lesquelles** des candidates
tiennent leurs images (`disponibilite.py`), puis la part des photos des
utilisateurs par espèce (chantier 2) pour trancher les limites de liste.
Le compte, lui, est arrêté.

#### La disponibilité a tranché : ~341, pas 500

La mesure est tombée le jour même (17 septembre 2026), sur les 204
candidates (`disponibilite_indoor.csv` pour la borne basse GBIF,
`disponibilite_indoor_inat.csv` pour la borne haute iNaturalist `captive`
compris, licences libres) :

| | espèces ≥ 25 images |
|---|---|
| solides GBIF | 42 |
| solides iNaturalist | 36 |
| **union collectable** | **55 / 204** |

Les 149 autres sont des espèces de collectionneurs que presque personne ne
photographie sous licence libre — le rayon « plantes d'intérieur connues »
était déjà épuisé par la liste elle-même, et `candidats_v8` ne recèle plus
rien de non collecté (4 108 lignes sur 4 220 sont entrées à la v8). Les
substituts maison (`phase1_species.txt`, par clé GBIF) n'ajoutent que
**4** espèces : *Ravenea rivularis*, *Phalaenopsis amabilis*,
*Streptocarpus ionanthus*, *Hippeastrum vittatum*.

L'arithmétique finale, arbitrée le jour même : **155 + 127 + 55 + 4 =
~341 espèces**, sous réserve que les 127 collectées soient bien dans les
5 259 classes apprises de la v8 (à vérifier à l'export). La borne
« pas plus de 500 » est respectée ; le reste des places se remplira par le
chantier 2, qui produit exactement ce qui manque. Décision : **livrer avec
le réel**, pas attendre le chiffre.

#### Collecte faite : 35 espèces, 5 741 images

Le même jour, dans l'ordre du § 13.6 (doublons d'abord) :

1. **Contrôle des clés GBIF** sur les 59 (55 + 4) : 18 « nouvelles »
   étaient déjà couvertes sous un nom accepté (*Dracaena angolensis* =
   `sansevieria-cylindrica`, *Citrus limon* = `citrus-x-limon`…) ; 2
   sous-taxons écartés (*Philodendron hederaceum var. hederaceum*, *Ficus
   natalensis subsp. leprieurii* — des classes qui disputeraient les images
   d'une espèce déjà collectée, le défaut du § 12.14). Restent **37**, puis
   **35** après arbitrage de deux lignes au nom commercial seul au
   catalogue applicatif.
2. **Catalogue** : rien à ajouter côté application — les deux
   *Rhaphidophora* étaient déjà curatées dans le palier `expansion_500`
   (le test « aucun palier ne rejoue une espèce déjà curatée » veille) ;
   côté collecte, **35 lignes** ajoutées à `plants.csv` (5 778 → 5 813),
   enrichies (`enrich_plants.py`, clé GBIF pour chacune). Les 14
   non-espèces de la liste sont restées ce qu'elles doivent être : des
   fiches du catalogue applicatif, jamais des classes.
   `doublons.py` signale au passage 6 paires préexistantes dans l'exposé
   actuel (*Citrus × bergamia* = *Citrus × limon*, *Dracaena trifasciata*
   = *Sansevieria trifasciata*…) : le masque en résout 5 de lui-même en ne
   gardant qu'un membre, la sixième (*Cupressus* = *Hesperocyparis
   macrocarpa*) sort du champ intérieur sans décision.
3. **Collecte** (`cible_indoor_collecte.txt`, `--target-per-species 300
   --allow-sa --captive-share 0.5 --captive-place 97391`) : **5 741 images
   gardées sur 5 819**, 0 en revue, licences 3 874 CC BY / 1 289 CC0 /
   578 CC BY-SA, attributions complètes. Test de validation passé avant
   (99/100) ; images contrôlées à la main après. 34 espèces à 27 images et
   plus — *Philodendron squamiferum* ferme la marche à 27.

   > **Ce contrôle comparait le mauvais nombre**, et il a coûté la plupart
   > des vingt-sept classes perdues au retaillage.
   > `--min-train 25` compte les images d'**entraînement**, pas les
   > images collectées : le découpage en prélève une part pour la validation
   > et le test. Les 27 de *Philodendron squamiferum* ont donné 22 en
   > entraînement, et la classe a sauté. Le seuil de collecte utile est donc
   > d'environ **32 images**, et plutôt 40 puisque le découpage ne sépare
   > jamais un groupe d'observation et ne tombe pas sur la proportion
   > voulue. Mesuré au retaillage, plus bas.
4. **Le masque est figé** : `masque_indoor.txt`, **335 classes** — 155 déjà
   exposées, 143 collectées sous un nom ou un autre (synonymes compris),
   4 substituts, 35 nouvelles, dédupliquées par `internal_id`. C'est le
   `--garder` de `retailler.py` à l'export ; les 143 ne valent que si la
   v8 les a apprises — sinon l'entraînement large les leur donne.

#### Entraînée, retaillée deux fois : 336 classes

L'entraînement large a tourné sur `dataset-v8-indoor` — le jeu de la v8 plus
les 35 espèces ci-dessus, 5 632 lignes — et en a appris **5 376** classes,
les 256 autres tombant sous `--min-train` ou `--min-val`. Le fichier de
16,3 Mo qu'il exporte n'est pas livrable, et le § 13.2 dit pourquoi : à
5 376 sorties, il n'accepte que 25 % des photos au seuil 0,8. C'est la
moitié « entraîner large », pas un modèle.

`retailler.py --garder masque_indoor.txt` a fait la seconde moitié en
quelques minutes. Il a fallu s'y reprendre à deux fois, et la deuxième passe
est la plus instructive des deux.

| | premier retaillage | **livré** |
|---|---|---|
| classes demandées | 335 | 363 |
| classes gardées | 308 | **336** |
| taille | 6,6 Mo | **6,64 Mo** |
| top-1 sur son test | 0,7537 | 0,7461 |

Ces chiffres-là sont ceux de leur propre test, à 308 puis 336 réponses
possibles : ils ne se comparent ni entre eux ni à aucun autre `model.json`
(§ 5 de `docs/10`). Les mesures qui comptent sont plus bas.

#### Les 27 classes manquantes : le seuil de collecte, pas le découpage

Vingt-sept classes du masque n'ont pas de colonne dans la tête entraînée.
**Aucune n'atteint 25 images d'entraînement**, et plusieurs manquent
entièrement au jeu — `goeppertia-orbifolia`, `goeppertia-rufibarba`,
`vriesea-splendens`, `alocasia-amazonica`, `citrus-medica`,
`citrus-x-aurantifolia`, `citrus-x-aurantium`. Les deux *Goeppertia* sentent
le synonyme non résolu (*Calathea* → *Goeppertia*) et *Alocasia × amazonica*
est un hybride, donc jamais une classe (§ 13.5) : à vérifier avant toute
reprise de collecte.

`--min-val 3` n'a jamais eu l'occasion de mordre. Le découpage corrigé du
§ 12.19 n'y est pour rien : **c'est le seuil de collecte qui a été lu sur le
mauvais nombre**, comme dit plus haut.

Le peloton s'arrête juste sous la barre, et c'est ce qui rend la perte
évitable :

| | images d'entraînement |
|---|---|
| `peperomia-argyreia` | **24** |
| `haworthia-truncata`, `philodendron-squamiferum` | 22 |
| `ravenea-rivularis` | 21 |
| `gynura-aurantiaca` | 20 |
| `alocasia-reginula` | 19 |
| `brassia-verrucosa` | 18 |

Sept espèces d'intérieur très courantes à une poignée d'images près, dont
une à **une seule**. La liste complète se regénère du journal de retaillage :

```bash
awk '/demandées que le modèle/{f=1;next} /chargement des poids/{f=0} f' \
  iris-indoor-retaille.log | tr -d ' ' | grep .
```

**Aucune ne se rattrape par un retaillage** : une classe que la tête n'a pas
apprise n'a pas de colonne à garder. C'est collecte puis passe complète, ou
rien.

#### Le masque perdait 28 plantes d'appartement, et personne ne le vérifiait

Le premier retaillage a produit un modèle mesurable, et `interieur.py` l'a
recalé net : **44 des 167 plantes de `phase1_species.txt` hors d'atteinte**.
Treize seulement s'expliquaient par l'entraînement — treize des vingt-sept
ci-dessus. Les **31 autres n'étaient pas dans `masque_indoor.txt` du tout**,
et **28 d'entre elles étaient exposées par l'Iris 8**.

Livrer ainsi aurait retiré à l'utilisateur des plantes que l'application
nommait la veille, et pas des espèces sauvages : presque tout le rayon
cactées et succulentes (*Agave americana*, *Opuntia ficus-indica*,
*Mammillaria hahniana*, *Cereus repandus*, *Astrophytum myriostigma*,
*Ferocactus latispinus*, *Epiphyllum oxypetalum*, *Selenicereus undatus*,
*Hatiora salicornioides*, *Aloe arborescens*, deux *Gasteria*, *Crassula
perforata*, *Portulacaria afra*), plus *Zantedeschia aethiopica*, *Medinilla
magnifica*, *Stephanotis floribunda*, *Livistona chinensis*, *Cyperus
alternifolius*, *Cissus rhombifolia*, trois *Ficus*, *Colocasia esculenta*
et *Areca catechu*.

La cause est une frontière qu'on n'a pas franchie exprès : le masque a été
bâti depuis `cible_interieur_500.tsv`, et son arithmétique — 155 + 143 + 4 +
35 — n'a jamais demandé **« est-ce que ça couvre les 167 ? »**. Les deux
listes ne parlent d'ailleurs pas la même langue : `phase1_species.txt` porte
des noms scientifiques, `masque_indoor.txt` des `internal_id`, si bien qu'un
rapprochement naïf ne trouve aucune intersection et rassure à tort.

Le *Calathea orbifolia* en est le symptôme le plus net : `calathea-orbifolia`
et `goeppertia-orbifolia` portent **la même clé GBIF 7476815** — deux lignes
du catalogue pour une plante, le défaut du § 12.14. Le masque avait retenu le
nom neuf, celui qui n'a pas d'images.

Les 28 étant toutes apprises par l'entraînement large, elles se sont
récupérées par un second retaillage de quelques minutes, sans rien
réentraîner. Trois restent dehors faute d'avoir été apprises —
`calathea-orbifolia`, `cymbidium-hybridum`, `columnea-gloriosa` —, et
l'Iris 8 ne les exposait pas davantage.

Il reste donc **16 noms d'intérieur hors d'atteinte** au lieu de 44 : les
trois ci-dessus et treize des vingt-sept. Plus aucune perte d'écriture, rien
que la dette de collecte — **contre `phase1_species.txt`**, et c'est la
réserve qui compte : voir plus bas.

#### Trois plantes du salon, et le troisième trou du même masque

Le soir de la livraison, trois plantes photographiées dans l'application :
un **frangipanier**, une **Alocasia 'Jacklyn'**, un **avocatier**. Aucune
reconnue par Iris Indoor, toutes trois nommées par Pl@ntNet.

La cascade a fait ce qu'il fallait — elle n'a affirmé aucune plante
d'appartement fausse, elle est passée au repli. Ce n'est donc pas le défaut
du § 12.7, c'est de la **couverture** : le modèle n'a aucune sortie pour
elles.

| | au catalogue de collecte | dans le masque |
|---|---|---|
| *Plumeria obtusa* | oui | non — seule *P. rubra* est exposée |
| *Persea americana* | oui | non |
| *Alocasia scalprum* | **non** | non — jamais collectée |

Le balayage qui suit donne l'ampleur : **55 fiches que l'application curate
en `indoor` ou `succulent` sont collectables et hors du masque** — *Calathea
orbifolia*, *Araucaria heterophylla*, *Agave attenuata*, sept *Asplenium* et
*Dryopteris*, une douzaine d'*Echeveria* et de *Kalanchoe*. Cent
quatre-vingt-quinze autres ne sont même pas dans `plants.csv`.

**Mais aucune des trois plantes du salon n'est dans ces 55**, et c'est la
vraie leçon. *Persea americana* est curatée `SpeciesCategory.fruit` :
l'avocatier qu'on fait pousser d'un noyau sur un rebord de fenêtre est rangé
au rayon fruitier. *Plumeria obtusa* n'est pas curatée du tout.

**Les catégories éditoriales de l'application ne décrivent pas ce que les
gens gardent chez eux.** Le masque a été bâti sur une liste
(`cible_interieur_500.tsv`), rapiécé avec `phase1_species.txt`, puis mesuré
contre les catégories du catalogue : trois sources, trois trous, et chacune
répond à une question légèrement différente de celle qui compte.

Ce qu'il faut en tirer pour le masque suivant : **une règle, pas une liste.**
Tout ce que la tête a appris et dont l'application a une fiche, moins ce qui
est franchement sauvage, puis deux ou trois tailles mesurées sur la courbe du
§ 6.7 bis — elle chiffre le prix à 0,22-0,35 point de top-1 par tranche de
cent espèces exposées. Passer de 336 à ~600 coûterait moins d'un point et
rendrait ces 55, plus l'avocatier et le frangipanier.

Et une action qui ne dépend d'aucun modèle : **`alocasia-scalprum` manque à
`plants.csv`**, donc n'a jamais été collectée, donc ne sera apprise par
aucun entraînement. Aucun masque ne la rendra tant que la ligne n'existe pas.

> **n = 3**, et des photos de salon plutôt qu'un jeu de test. Ça nomme une
> catégorie de défaut, ça n'en donne pas la fréquence — exactement comme les
> quatre scans du § 13.3. Le terme manquant reste le chantier 2.

#### Le verdict : le réseau perd, le produit gagne

`compare_models.py`, 2 000 images de plantes cultivées, sur les seules
classes que les deux modèles connaissent :

| à armes égales, sorties masquées | Iris 8 | Iris Indoor |
|---|---|---|
| top-1 | **0,7850** | 0,7710 |
| top-3 | **0,8985** | 0,8855 |
| seuil 0,70 | 61,1 % acceptées, 0,9517 | 60,1 %, 0,9542 |

| sorties entières, ce que l'application rend | Iris 8 | Iris Indoor |
|---|---|---|
| top-1 | 0,7175 | **0,7350** (+1,8) |
| top-3 | 0,8460 | **0,8650** (+1,9) |
| seuil 0,70 | 63,1 % acceptées, 0,9208 | 61,6 %, **0,9302** |

Plus 144 espèces qu'Iris 8 ne sait pas nommer, rendues à 0,7315 de top-1 —
pour elles la v8 est à zéro par construction.

**Le réseau est 1,4 point en dessous de la v8, et le produit est quand même
meilleur de 1,8.** Les deux ne se contredisent pas : le gain ne vient pas
d'un meilleur apprentissage mais du masque, exactement ce qu'annonce le
§ 13.2. Ce léger recul du réseau n'est pas expliqué — 117 classes apprises de
plus que la v8, ou la variation d'une passe à l'autre — et il ne se mesurera
qu'en le reproduisant.

Le masque élargi se paie, et le prix est connu : le premier retaillage à 308
rendait +2,5 points là où celui-ci en rend +1,8, et l'autonomie recule d'un
point et demi au lieu d'être plate. Sept dixièmes de point et quelques
appels à Pl@ntNet de plus, contre 28 plantes rendues à l'utilisateur : c'est
le bon côté de l'échange, et c'est un arbitrage, pas un progrès gratuit.

Sur le terrain qui compte, `interieur.py` sur 3 653 images de plantes
d'appartement — dont 1 995 photographiées en pot, au plus près de l'usage :

| | catalogue entier | sorties masquées à l'intérieur |
|---|---|---|
| top-1 | 0,7394 | 0,7963 |
| seuil 0,70 | 61,7 % acceptées, 0,9299 | 69,5 %, 0,9531 |

Le **prix de l'étendue** reste de 5,7 points de top-1 et 7,9 d'autonomie,
même à 336 sorties : la courbe du § 6.7 bis n'est pas épuisée, elle est
seulement devenue un arbitrage de couverture plutôt qu'un gain gratuit.

Deux chiffres à ne pas confondre, parce qu'ils se ressemblent :
**l'autonomie ne gagne pas dix points, elle en perd un et demi.** Le
54,9 % → 63,2 % qu'on lit en rapprochant les deux `model.json` est un
artefact de deux jeux de test différents ; à armes égales, c'est 63,1 % →
61,6 %. Ce que la livraison gagne, c'est un point de justesse, deux de top-1
et 144 espèces.

`acceptThreshold` **reste donc à 0,70**. La courbe propre d'Iris Indoor offre
0,60 à 69,6 % pour 0,9107, mais cette justesse-là passe sous les 0,9208
d'aujourd'hui mesurés à armes égales : ce serait payer de la justesse pour de
l'autonomie, l'inverse de ce que la v8 avait obtenu.

#### Ce que livrer retire

Iris Indoor expose 336 classes dont 144 inconnues de la v8 : **192 communes**.
Livrer retire donc **1 252 espèces** de ce que l'application savait nommer.
Elles ne basculent pas toutes sur la réponse de genre et le repli Pl@ntNet :
pour un quart d'entre elles, le modèle affirme à leur place une plante
d'intérieur qu'il connaît, au-dessus du seuil et avec la marge (§ 12.7).

C'est la décision du § 13.3, mais la coupe est plus large que les ~950
anticipées : le masque est tombé à 336 au lieu des 500 visés. Pour une
application de plantes d'appartement c'est l'arbitrage voulu ; il se relit le
jour où le chantier 2 donne la part réelle des photos par espèce.

**2. Les photos des utilisateurs.** La seule source qui règle **les deux**
problèmes à la fois — le domaine visuel *et* les cultivars. Chaque
identification confirmée est une photo étiquetée, dans le bon domaine, de la
plante que quelqu'un possède vraiment. Aucun jeu public n'a ça : iNaturalist
ne modélise pas les cultivars (§ 12.16), Commons en a deux photos par
cultivar en médiane sur son genre le mieux fourni.

C'est aussi **le seul chantier dont le délai se compte en mois**, d'où sa
place : il faut le commencer avant d'en avoir besoin. Il demande du
consentement explicite, une tuyauterie, et du soin sur la vie privée — une
photo de salon n'est pas une observation naturaliste. Il commence par
**poser la question dans l'application**, pas par entraîner.

> **Le robinet est ouvert.** Enregistrer une plante après l'avoir identifiée
> étiquette ses photos sans rien demander de plus — c'est le geste de la
> personne qui écarte Iris, cherche en ligne et choisit elle-même, et il
> vaut plus qu'une correction : selon d'où vient le nom retenu, la même
> photo est *confirmée*, *reclassée* ou *corrigée*, et les confirmations
> sont les photos du bon domaine qu'aucune source publique ne donne.
> Consentement demandé **une fois**, juste après le premier enregistrement
> d'une plante identifiée — le moment où la question se comprend — et
> éteint tant que la réponse n'est pas oui ; l'interrupteur des réglages
> (« Envoi des photos identifiées ») reste là pour changer d'avis, et il
> dit ce qui part, où, et ce que « désactivé » vaut. Sans compte distant,
> rien ne peut partir : l'interrupteur est alors inerte et l'écran le dit,
> plutôt que de laisser croire à un envoi. Table
> `iris_feedback` et seau `iris-feedback`, lisibles par l'auteur seul,
> retirés avec le compte ; la cascade garde ce qu'Iris croyait (`lastLocal`)
> même quand elle a basculé d'elle-même sur Pl@ntNet. Côté entraînement,
> `tools/plant_dataset/auxine.py` tire la table, met en `review` ce que ni
> Iris ni Pl@ntNet ne confirment, et liste les espèces hors catalogue comme
> candidates.

> **Mis en service le 14 septembre 2026**, vérifié de bout en bout sur
> téléphone : la feuille de consentement s'ouvre une fois, le premier
> enregistrement n'écrit rien — c'est lui qui pose la question, et il passe
> par l'enregistreur muet —, les trois `kind` arrivent corrects, les photos
> partent à 640 px pour ~67 Ko, et retenir un genre n'écrit rien, comme
> prévu.
>
> **Les quatre premiers scans terrain, et ce qu'ils ne prouvent pas.**
> *Epipremnum pinnatum* rendu *Dieffenbachia seguine* à 0,859 — donc
> `accepted`, affirmé sans réserve, et les deux espèces sont au catalogue.
> *Ficus elastica* rendu plante ZZ, *Peperomia obtusifolia*, *Ficus
> benjamina* : absent du top-3 alors que le modèle expose neuf *Ficus*, et
> les trois candidates partagent une feuille épaisse et luisante — le
> regroupement se fait sur la texture, pas sur le port. Un pin sans aucune
> proposition locale, la cascade passée à Pl@ntNet. **n = 4 : ça nomme une
> catégorie, ça n'en donne pas la fréquence.** Mais l'écart avec les 0,6543
> de top-1 du jeu de test est précisément l'écart de domaine que ce chantier
> existe pour combler, et il se mesurera quand les lignes s'accumuleront.
>
> **Ce que ces cas apprennent sur le reste de l'architecture** : l'erreur
> confiante est invisible à tout mécanisme fondé sur la confiance. Ni le
> seuil, ni la marge, ni le genre, ni le repli ne voient un faux à 0,859 —
> seule la correction humaine le révèle. C'est l'argument le plus fort pour
> ce chantier, et il ne se lit dans aucune métrique agrégée.

**3. ✅ Répondre au niveau du genre.** Aucun entraînement : sommer le
softmax par genre porte le top-1 de **5,9 points** sur le modèle livré —
0,6543 à l'espèce, 0,7130 au genre (§ 12.15) —, et « un épicéa, espèce
incertaine » est une réponse vraie là où cinq noms n'en sont pas une. Dans
la cascade, où l'espèce garde la priorité et où les masses ne se somment
que sur les cinq candidates affichées, le genre répond sur **5,5 %** des
photos et a raison **neuf fois sur dix**. Le gain grandit avec le
catalogue, contrairement au top-1.

**4. Nourrir les 76 espèces faibles — le domaine avant le volume.**
`(potted)` de Commons, branché à la v8 (§ 12.17), et `captive=true`
d'iNaturalist qu'on n'utilise qu'à 50 % de la cible. Pour des plantes que
les gens possèdent, cette proportion devrait être inversée. C'est le
chantier qui attaque directement les 73 % d'erreurs hors famille.

**5. Les doublons, avant la collecte et pas après.** 46 clés GBIF en double
au minimum dans les 5 778 lignes, et c'est une borne basse (§ 12.14).
`doublons.py` donne le vrai chiffre en une passe. Deux classes pour une
plante, ce sont des images partagées et une confusion imperdable : du
travail de collecte dépensé à fabriquer une erreur.

**6. Le découpage — déjà fait.** Le § 12.19 rendra ~112 espèces que la v8
avait écartées pour une image de validation manquante. Rien à décider, ça
prend effet à la prochaine construction du jeu.

### 13.4 La branche cultivars, et la porte qui la commande

Le § 12.18 tient à une hypothèse non vérifiée : **l'embedding sépare-t-il
deux cultivars d'une même espèce, ou l'a-t-on entraîné à les confondre ?**
Chaque photo de « Thai Constellation » de notre jeu est étiquetée *Monstera
deliciosa* — les cent couches dégelées ont appris à les rapprocher.

`prototypes.py` tranche en deux heures, avec les quelques *Hosta* qui ont 5
à 14 photos sur Commons. Et le résultat oriente deux routes très
différentes :

- **signal présent** → c'est un problème de **récolte**, et les sources
  existent (Commons par les légendes plutôt que par les catégories, NC State
  et ses blocs image-légende-auteur-licence, Flickr par cultivar nommé) ;
- **signal absent** → c'est une décision d'**entraînement** de l'Iris 9 —
  une perte contrastive pendant le réglage fin — et aucune récolte n'a de
  sens avant.

**Ne pas construire le moissonneur avant d'avoir passé cette porte.** Deux
heures peuvent en économiser cinquante.

### 13.5 Le catalogue de l'application et celui de la collecte ne sont pas le même fichier

C'est la frontière la plus facile à franchir par mégarde, et la plus chère.

**`plants.csv` est le catalogue de *collecte*.** `build_dataset.py` collecte
ce qu'il contient ; `train.py` en fait des classes. Une ligne y est donc une
**classe du modèle**, pas une fiche d'application.

**Une fiche de cultivar n'a donc rien à y faire.** Écrire `Epipremnum aureum
'Marble Queen'` dans `plants.csv` la ferait collecter comme une espèce, puis
entrer au modèle comme une classe de plus — c'est-à-dire exactement ce que
le § 12.16 interdit, et une répétition à grande échelle du défaut du
§ 12.14 : deux étiquettes pour une plante, les images partagées, une
confusion qu'aucune photo ne peut trancher.

| | vit dans | devient |
|---|---|---|
| espèce | `plants.csv` | une classe du modèle |
| cultivar | catalogue de l'app + `cultivars.csv` | une fiche, jamais une classe |
| photo validée | table `plant_images` | une illustration, ou un prototype (§ 12.18) |

Le rattachement se fait par l'identifiant de l'espèce parente : si GBIF ne
connaît qu'*Epipremnum aureum*, c'est à elle que pointent 'Marble Queen' et
'N'Joy', qui restent deux fiches distinctes côté application.

#### Un identifiant qu'on possède déjà sans le savoir

Un plan de rattachement aux référentiels veut `gbif_taxon_key` **et**
`inaturalist_taxon_id`, qui sont deux registres différents. `plants.csv`
porte `gbif_key`, `wikidata_id` et `plantnet_id` — pas iNaturalist.

Mais **la valeur existe déjà** : `resolve_inat()` résout le taxon espèce par
espèce pendant la collecte et le mémorise dans `dataset/species_inat.json`,
indexé par nom scientifique, avec l'identifiant, le rang et le nombre
d'observations. C'est une colonne à recopier, pas des milliers de requêtes à
refaire.

#### Valider à la main : pour quoi, et jusqu'où

Un écran de validation — la fiche à gauche, les photos candidates à droite,
trois réponses possibles (espèce confirmée, cultivar confirmé, insuffisant)
— est la bonne réponse au défaut des sources sans identification : Unsplash,
Openverse, Pexels donnent des photos, pas des identifications, et un humain
en ajoute une. Ces trois-là sont mesurés et rangés au § 4.5 ; Pexels en est
le tuyau désigné le jour où l'écran existe — le meilleur domaine visuel du
lot, des intérieurs stylisés qui ressemblent aux photos des utilisateurs.

**Mais il ne passe pas à l'échelle de l'entraînement.** Une photo de
référence par fiche, ce sont ~5 000 décisions : faisable, et c'est l'usage
« illustration ». La profondeur d'un modèle en demande des centaines par
espèce, et les prototypes de cultivars dix à trente chacun — des dizaines de
milliers de décisions.

**Sauf braqué ailleurs.** L'écran est la partie coûteuse à construire ; une
fois qu'il existe, le pointer sur les **photos des utilisateurs** (§ 13.3,
chantier 2) change sa nature : l'identification est déjà donnée par celui
qui a ajouté la plante, et on n'échantillonne plus qu'un contrôle qualité.
Même outil, même table, mais une source qui fournit du volume dans le bon
domaine visuel — et qui règle les cultivars par la même occasion.

#### Licence et conditions d'API ne sont pas le même texte

Pour Unsplash en particulier, et la remarque vaut ailleurs : la **licence**
accorde le téléchargement, la copie et la modification — donc
l'entraînement, la seule restriction réelle étant de ne pas revendre sans
modification substantielle ni reconstituer un service concurrent. Les
**conditions de l'API**, elles, imposent de servir les images depuis les URL
d'Unsplash, d'attribuer, et d'appeler leur point de suivi à la sélection.

Deux documents, deux usages : trouver les photos *via l'API* lie pour
l'affichage, sans interdire d'entraîner sous la licence. À trancher
explicitement avant d'écrire le connecteur, plutôt qu'après.

### 13.6 La recette, et ce qu'elle change de la v8

Rien de spectaculaire : la v8 a montré que la recette d'entraînement n'est
plus le facteur limitant. Quatre corrections, toutes tirées d'une mesure.

**1. Pré-réduire le jeu à la taille d'entrée.** C'est le seul changement qui
achète du temps, et donc des essais. À `--input-size 320`, `LOAD_SIZE` monte
à 366 px et précharger les 794 000 images d'entraînement demanderait 315 Go
— hors de portée. Le jeu est donc **relu et redécodé à chaque époque**, et
le tuyau plafonne autour de **750 images/s**, mesuré pendant l'encodage de
la v8. Dix-huit minutes d'époque dont l'essentiel est du JPEG.

Stocker le jeu **déjà réduit** à la taille de chargement supprime ce
décodage. Sur une L40 dont la carte attend le processeur (`docs/11` § 1), le
gain est direct : plus d'époques par euro, donc plus de recettes essayées.

**2. Lancer `doublons.py` avant la collecte**, pas après (§ 13.3, chantier
5). Une ligne en double, c'est de la collecte dépensée à fabriquer une
confusion imperdable.

**3. Le découpage corrigé** (§ 12.19) est déjà dans `splits.py` : il vise
maintenant `--min-val` images, pas « au moins un groupe ».

**4. Trancher la question du lot, une fois pour toutes.** On ne sait
toujours pas si `--batch 128` a aidé la v8 : le run a changé deux choses à
la fois. Deux entraînements courts sur un sous-ensemble le diraient pour
quelques euros — et si le tuyau reste le plafond (point 1), la réponse est
probablement « rien », ce qui vaut la peine d'être su plutôt que supposé.

Le reste ne bouge pas : `--backbone large`, `--dropout 0.5`, `--unfreeze
100`, `--input-size 320`, précision mixte, cache de traits et points de
sauvegarde. Une recette à la fois, comme au § 12.

#### Le masque rapporte, la recette coûte — mesuré le 19 septembre 2026

Jusqu'ici les deux se confondaient. Iris Indoor rendait +1,8 point de top-1
sur ce que l'application livre, et son réseau paraissait « 1,4 point sous la
v8 » — mais mesuré à **masques différents**, ce qui ne veut rien dire.

`masque_outdoor.txt` a permis de les séparer : il reprend l'ensemble exposé
par l'Iris 8 tel quel, coupé dans la tête large d'aujourd'hui. Même masque des
deux côtés, seule la recette diffère.

| 6 000 images, classes communes | Iris 8 | tête du 19 septembre |
|---|---|---|
| top-1, sorties masquées | **0,6672** | 0,6365 (−3,1) |
| top-3 | **0,8063** | 0,7825 |
| autonomie au seuil 0,70 | **55,0 %** | 48,2 % (−6,8) |
| justesse quand elle accepte | 0,9176 | **0,9284** (+1,1) |
| top-1, plantes cultivées | **0,6525** | 0,6410 (−1,2) |

Trois points, quand le § 4 de `docs/10` fixe le seuil d'alerte à « un point
ou deux ». L'écart se resserre à 1,2 sur les plantes cultivées : la perte est
concentrée sur les espèces sauvages.

**Mais ce n'est pas la recette qui est moins bonne : l'entraînement n'était
pas fini.** Le journal le dit sans ambiguïté — à la douzième et dernière
époque de réglage fin, `val_loss` descendait encore (2,5245 → 2,5084) et
`val_accuracy` montait encore (0,4885 → 0,4950). `state.json` porte
`fine_epochs_done: 12`, les douze demandées : **aucun arrêt anticipé**. Ce
n'est pas la validation qui a dit stop, c'est `--fine-epochs 12`.

Un second écart accompagne le premier : 24 842 pas de 32 images font
`--batch 32`, le défaut, là où la v8 tournait à 128. C'est précisément la
variable que le point 4 ci-dessus demande de trancher « une fois pour
toutes », et elle a été changée sans qu'on le décide.

Le diagnostic est donc **un entraînement tronqué**, pas une recette dégradée.

#### Mais la reprise ne le répare pas : elle coûte 2,3 points

Huit époques de plus ont été lancées depuis le point de sauvegarde, sept
heures de calcul. Résultat :

| | val_accuracy | val_loss |
|---|---|---|
| époque 12, avant la reprise | **0,4950** | **2,5084** |
| époque 15 | 0,4612 | — |
| époque 20, fin de la reprise | 0,4723 | 2,7272 |

La reprise **repart 3,4 points plus bas**, remonte de ~0,003 par époque, et
finit encore **2,3 points sous son point de départ** — avec une perte de
validation nettement pire, 2,73 contre 2,51. Elle ne s'est pas contentée de
plonger : elle s'est installée dans un moins bon creux.

La cause est à `train.py:705` : `model.compile(optimizer=Adam(args.fine_lr))`
construit un optimiseur **neuf**. Les poids sont restaurés, les moments
accumulés d'Adam ne le sont pas, et un réseau convergé n'aime pas qu'on lui
remette un optimiseur à zéro.

Deux effets de bord vont avec, et ils comptent :

- `_Checkpoint.on_epoch_end` réécrit `fine.weights.h5` à chaque époque. **Les
  poids d'avant la reprise sont perdus** — on ne peut plus couper un nouveau
  masque dans la tête qui a produit l'Indoor livré. Seuls les `.tflite`
  déjà exportés subsistent ;
- l'arrêt anticipé est reconstruit lui aussi, donc son `restore_best_weights`
  restaure le meilleur **de la reprise**, pas celui d'avant.

La reprise reste bonne pour ce qu'elle a été écrite — une machine qui
s'endort, un run tué, reprendre là où on en était. Elle ne l'est pas pour
**prolonger** un entraînement qui a convergé : mieux vaut relancer une passe
entière avec le bon nombre d'époques que d'en ajouter après coup.

Et la question de départ reste donc ouverte : on ne saura pas par cette voie
si douze époques suffisaient. Il faudra une passe complète, `--batch 128`,
et assez d'époques pour que la validation décroche d'elle-même.

Le compte d'Iris Indoor tombe alors juste, et c'est la première fois :

```text
+3 environ  ce que rapporte le masque étroit
−1 environ  ce que coûte la recette
= +1,8      mesuré sur ce que l'application rend
```

Le gain était réel, mais net d'une perte qu'on n'avait pas isolée.

**Deux conséquences.** D'abord, ne pas couper Outdoor dans cette tête tant
qu'elle n'a pas fini : il serait trois points sous l'Iris 8 sur son propre
terrain, et l'Iris 8 *est* déjà un spécialiste extérieur. Ensuite, ne pas
lancer Iris 9 sur ce constat-là : la recette n'a pas été jugée, elle a été
interrompue.

#### Ce que la donnée n'explique pas, et comment on l'a su

Avant d'arriver au journal, deux hypothèses sont tombées, et leur chute vaut
d'être notée — elles auraient coûté une collecte chacune.

**Les classes maigres.** On a cru que le découpage corrigé du § 12.19 avait
fait entrer des classes mal nourries qui abîmaient le dorsal. Reconstruits
depuis les deux `splits.csv` aux seuils `--min-train 25` / `--min-val 3`, les
deux jeux enseignent **5 343 et 5 376 classes** : trente-trois entrées,
aucune sortie, médiane de 119 images d'entraînement contre 156 pour le jeu.
Une seule sous quarante. Trente-trois classes nourries ne coûtent pas trois
points.

**Le vol en sortie.** Il n'a même pas lieu d'être : les classes
supplémentaires ne sont pas dans les sorties du modèle retaillé, leurs
colonnes ont été supprimées. Elles ne peuvent voler personne à l'inférence.

Ce que `confusions.py` disait, en revanche, pointait déjà ailleurs. Les
erreurs, sur 6 000 images :

| | Iris 8 | tête du 19 | écart |
|---|---|---|---|
| dans le même genre | 325 | 313 | −12 |
| dans la même famille | 313 | 323 | +10 |
| **au-delà** | **1 378** | **1 545** | **+167** |

**Toute la régression est « au-delà »** — les confusions hors famille, celles
que le § 6.9 appelle les vrais défauts. Le fine-grained est intact à douze
erreurs près. Un réseau qui n'a pas fini d'apprendre perd d'abord le
grossier, pas le fin : c'est cohérent avec un entraînement tronqué, et ça ne
l'est pas avec une recette mal réglée.

Et le point 4 ci-dessus s'appliquait bien à nous, mais sur un autre point que
celui qu'on cherchait : **le lot a changé sans décision**, 32 au lieu de 128.
On reproduit exactement ce qu'on reprochait à la v8 — un run, deux variables.

#### Six doublons dans l'exposé, et ils ne datent pas d'aujourd'hui

`doublons.py` trouve **six clés GBIF en double** parmi les 1 444 classes que
l'Iris 8 expose : *Cupressus macrocarpa* = *Hesperocyparis macrocarpa*,
*Dracaena trifasciata* = *Sansevieria trifasciata*, *Echinocactus grusonii* =
*Kroenleinia grusonii*, *Coleus scutellarioides* = *Plectranthus
scutellarioides*, *Citrus × bergamia* = *Citrus × limon*, *Citrus myrtifolia*
= *Citrus × aurantium*.

Douze classes pour six plantes. Chaque photo peut être étiquetée des deux
façons et la moitié compte comme fausse : `confusions.py` voit six
*Cupressus* rendus *Hesperocyparis*, et le modèle n'a pas tort. C'est le
défaut du § 12.14, dans l'ensemble livré.

Trois se tranchent seules — la table des noms acceptés résout vers un membre
qui seul a une fiche. Les trois autres sont des décisions éditoriales : deux
paires de *Citrus* portent la même clé **et** deux fiches curatées, et
*Coleus* résout vers un *Plectranthus* qui n'a pas de fiche.

**Ces doublons sont dans le masque, donc dans les deux modèles à l'identique** :
ils ne sont pour rien dans les trois points d'écart. C'est un gain gratuit
— six classes de moins, un retaillage de cinq minutes — pas une explication.

#### La passe complète, enfin — 21 septembre 2026

Trente époques de réglage fin, sans une interruption, à la recette du § 13.6 :
`--input-size 320`, `--dropout 0.5`, `--unfreeze 100`. Huit heures sur une
RTX 2070 Super, 12 421 lots de 64 par époque, 953 secondes chacune.

**Le lot est à 64, et c'est une décision.** À 320 px, un seul tenseur
intermédiaire fait 98 Mo et les 8 Go de la carte ne suivent pas à 128 :
l'encodage du cache de traits est tombé sur un manque de mémoire avant même
la première époque. Le point 4 ci-dessus demandait de trancher la question du
lot « une fois pour toutes » ; elle est tranchée par la carte, elle est
écrite, et c'est tout ce qu'on demandait — contrairement au 32 de la v8, qui
était passé sans que personne le décide.

**Et la validation montait encore à la trentième époque.** L'arrêt anticipé
surveille `val_accuracy` avec une patience de quatre ; il n'a jamais parlé.
La question laissée ouverte plus haut — douze époques suffisaient-elles ? —
reçoit donc une réponse, et elle va plus loin que prévu :

| | val_accuracy | val_loss |
|---|---|---|
| tête du 19 septembre, époque 12 (320 px, lot 32) | 0,4950 | 2,5084 |
| passe du Mac, époque 20 (224 px, lot 128) | 0,4305 | 3,1630 |
| **passe complète, époque 27** (320 px, lot 64) | **0,5473** | **2,2515** |

Douze étaient très loin du compte, et trente ne sont **toujours pas** le
plafond. La recette n'était pas en cause : elle n'avait jamais eu le temps
de s'exprimer.

La ligne du milieu mérite un mot, parce qu'elle a coûté deux jours. Une
première passe a tourné sur le Mac aux valeurs **par défaut** — 224 px,
dropout 0,3, soixante couches dégelées — faute d'avoir passé les trois
options. Elle plafonnait douze points sous la vraie recette. Une passe qui
n'applique pas la recette ne mesure pas la recette ; la ligne de commande
fait partie de l'expérience, et elle doit être relue avant de lancer huit
heures de calcul.

#### Ce que rend l'Iris 9, mesuré contre le modèle livré

`compare_models.py`, 6 000 images du jeu de test, Iris Indoor en référence.
**336 classes communes, 1 233 connues du seul Iris 9, aucune perdue** — rien
de ce que l'application sait nommer aujourd'hui ne disparaît.

Sur les photos de plantes cultivées, c'est-à-dire ce que l'application voit
vraiment :

| | top-1 | autonomie à 0,70 | justesse |
|---|---|---|---|
| Iris Indoor (livré) | 0,7310 | 62,7 % | 0,9234 |
| **Iris 9, masque intérieur** | **0,7650** | **65,7 %** | **0,9284** |
| Iris 9, sans masque | 0,7230 | 67,5 % | 0,9030 |

**Trois points et demi avec le masque, huit dixièmes de perte sans lui.** Les
deux lignes du bas sont les deux comportements possibles de l'application,
et l'écart entre elles — 4,2 points — est le prix exact de la largeur. C'est
ce que le § 14 achète.

Sur l'ensemble des classes communes, l'écart est plus marqué : 0,7842 avec
masque contre 0,7253 sans, soit 5,9 points pour 1 233 espèces exposées de
plus. La courbe des tailles de sortie (§ 6.7 bis) prévoyait 0,22 à 0,35 point
par centaine ; **sur les plantes cultivées le compte tombe à 0,34, pile dans
la fourchette**, et à 0,48 sur le jeu entier. La courbe tient là où elle
compte, et sous-estime ailleurs — une plante en pot est le plus souvent une
espèce d'intérieur, les classes ajoutées lui volent donc moins de réponses.

Enfin la couverture gagnée : **949 espèces qu'Iris Indoor ne sait pas nommer,
reconnues à 0,6785 en top-1** et 0,8305 en top-3, sur 2 000 images. Ce ne
sont pas des espèces mieux reconnues, ce sont des espèces qui passaient
jusqu'ici de l'écran à Pl@ntNet ou à rien.

### 13.7 Les trois portes, et ce qu'on ne fera pas

**Aucun de ces chantiers ne commence avant sa porte.** C'est ce qui a
manqué à la v8 : on a collecté 4 220 espèces avant de savoir ce qu'une
espèce de plus coûte.

| porte | ce qu'elle décide | état |
|---|---|---|
| la **courbe des tailles de sortie** | combien d'espèces exposer, donc lesquelles nourrir | **franchie** — lue au § 6.7 bis, c'est elle qui a décidé des 336 exposées |
| la classe **« autre »** (§ 3.2) | si un masque contextuel est tenable, ou s'il rend impossible la bonne réponse | **à moitié** — plantes hors catalogue mesurées le 19 septembre (§ 12.7), 27,5 % affirmées à tort ; les non-plantes restent à faire |
| `prototypes.py` (§ 12.18) | si l'embedding sépare deux cultivars, donc si la branche cultivars existe | **ouverte** — deux heures, et elle commande toute la branche |

**Ce qu'on ne fera pas, et pourquoi :**

- **pas de tête hiérarchique** famille → genre → espèce : sommer le softmax
  par genre donne le même service sans rien réentraîner (§ 12.15) ;
- **pas de cultivars comme classes** : ils n'ont pas de source d'images, et
  les mettre au catalogue de collecte répéterait le défaut du § 12.14 à
  grande échelle (§ 12.16, § 13.5) ;
- **pas d'espèces de plus pour le nombre.** C'est le renversement de la v8 :
  élargir le catalogue exposé se paie, et se paie en points. On continuera
  d'en collecter — pour l'entraînement, pas pour l'affichage ;
- **pas de connecteur Trefle** : ce qu'il sert, ce sont les photos de
  Pl@ntNet vues par un relais, la licence en texte libre dans un champ
  `copyright` — non filtrable, mesuré et refusé au § 4.5. Le même corpus
  existe avec des licences structurées dans PlantNet-300K (§ 12.8).

### 13.8 Ce qu'il faut retenir

Trois des six chantiers ne demandent **aucun entraînement**, et deux ne
demandent aucune collecte. L'Iris 9 n'est pas un modèle plus gros : c'est un
modèle mieux nourri, mieux borné, et pour l'essentiel une application qui
sait quoi faire de ce qu'il rend.

Et une phrase, s'il ne fallait en garder qu'une, parce qu'elle a coûté
vingt-deux heures de collecte et une nuit de mesures :

> **La largeur se paie dans les sorties, pas dans l'entraînement.**
> Collecter tout ce qu'on trouve, n'exposer que ce qu'on sert.


## 14. Livrer Indoor et Outdoor ensemble

Iris Indoor est livré, Iris Outdoor est cadré, et la question qui vient n'est
plus « comment les entraîner » mais **comment les embarquer tous les deux**.
Cette section fixe ce qui est décidé avant la mesure, et ce que la mesure
doit trancher. Elle prolonge le § 8 de `docs/14`, qui pose Indoor et Outdoor
comme deux vues du même cerveau ; ici, le cerveau est encore un softmax.

### 14.1 Deux masques d'une même tête, ou deux entraînements

C'est le point qui commande tout le reste, et il tient en une ligne :

> **Deux masques coupés dans la même tête ont des scores comparables. Deux
> entraînements différents n'en ont pas.**

Retailler, c'est supprimer des colonnes de la dernière couche, puis
renormaliser : `exp(zᵢ) / Σ_gardées exp(zⱼ)`. Les logits `zᵢ` ne bougent pas.
Deux masques taillés dans la même tête rendent donc des probabilités qui
vivent sur la même échelle, et un 0,74 de l'un se compare honnêtement à un
0,71 de l'autre. C'est ce qui rend un arbitrage possible.

Deux entraînements distincts ne donnent pas cette garantie. Leurs
calibrations diffèrent, et le § 13.6 en a payé la démonstration : la tête du
19 septembre et l'Iris 8 n'étaient même pas comparables classe pour classe
sans repasser par un jeu d'images commun.

**Conséquence.** L'Indoor livré vient de la tête du 19 septembre — dont les
poids sont perdus (§ 13.6) — et l'Outdoor viendra de la passe complète de
l'Iris 9. Les deux ne peuvent pas travailler ensemble : ils ne sont pas
calibrés l'un pour l'autre. Il n'y a donc pas de version intermédiaire à
bricoler. **Indoor et Outdoor sortent tous les deux de la tête de l'Iris 9,
ou ils ne cohabitent pas.**

### 14.2 Un fichier, pas deux

Embarquer deux modèles, c'est payer deux fois le même réseau pour deux
dernières couches. Le dorsal MobileNetV3Large pèse environ 5,99 Mo et ne
dépend pas du nombre de sorties ; la tête coûte `960 × classes × 2 octets`.

| | classes demandées | poids livré |
|---|---|---|
| Indoor seul | 363 | ~6,65 Mo |
| Outdoor seul | 1 444 | ~8,63 Mo |
| **les deux fichiers** | | **~15,28 Mo** |
| **un modèle d'union** | **1 612** | **~8,94 Mo** |

L'union des deux masques fait 1 612 entrées : 195 espèces communes, 168
propres à Indoor, le reste à Outdoor. Avec le masque Indoor élargi
(`masque_indoor_large.txt`, 421 entrées), l'union monte à 1 635 et le poids à
~8,98 Mo — vingt-trois espèces de plus pour quarante kilo-octets.

Un seul fichier coûte donc **2,3 Mo de plus qu'Indoor seul, et 6,3 Mo de
moins que deux fichiers**. Il évite aussi ce qui ne se lit pas dans un
tableau : un second interpréteur, un second isolat, une seconde seconde
d'inférence par photo — et la cascade en enchaîne jusqu'à trois (§ 12.3).

#### Le masque dans l'app rend exactement ce que `retailler.py` rend

Le graphe applique son softmax sur les 1 612 sorties, donc l'app lit
`exp(zᵢ) / Σ_toutes exp(zⱼ)`. Garder les classes du contexte et diviser par
leur somme donne `exp(zᵢ) / Σ_gardées exp(zⱼ)` : **la même formule que le
retaillage, au même résultat près de l'arrondi**. Le masque appliqué dans
`tflite_plant_model.dart` n'est pas une approximation du modèle retaillé,
c'en est l'égal.

C'est ce qui rend la décision facile : les ~3 points que rapporte le masque
étroit (§ 13.6) s'obtiennent **sans second fichier**. Ils ne tiennent pas au
poids livré, ils tiennent à la renormalisation.

Et un masque qui vit dans l'app se change sans rien retélécharger. Une plante
déplacée du salon au balcon change de contexte à la lecture suivante ; deux
fichiers auraient demandé de recharger l'autre modèle.

### 14.3 Le contexte donne un a priori, jamais une interdiction

La règle vient du § 8 de `docs/14`, et elle contredit le masque dur si on
l'applique sans précaution : couper une classe, c'est rendre la bonne réponse
**impossible**, pas seulement improbable. Un monstera sur un balcon en été
n'est pas un cas rare.

La sortie s'écrit donc en deux temps, sur une seule inférence :

1. `p_contexte` — les probabilités renormalisées sur le masque du lieu. C'est
   ce qui est proposé, et c'est là que les trois points sont gagnés ;
2. `p_global` — les probabilités sur les 1 612, gardées sans coût, puisque le
   réseau les a calculées de toute façon.

Et la règle d'arbitrage à mesurer :

- si `p_contexte` accepte au sens du § 3.1 — seuil 0,70, marge 0,25 —
  l'application affirme, et n'ouvre pas `p_global` ;
- sinon, si le premier de `p_global` dépasse nettement le premier de
  `p_contexte`, ce candidat hors contexte est proposé comme **plausible**,
  avec son lieu d'origine pour ce qu'il vaut ;
- contexte inconnu — une photo identifiée hors d'une plante enregistrée —
  `p_global` seul, aucun masque.

Cette règle remplace le palliatif posé le 19 septembre, où Iris propose au
lieu d'affirmer dès que le lieu est extérieur
(`identification_policy.dart`, `localMayAffirm`). Le palliatif était juste
tant que le modèle embarqué était un spécialiste intérieur seul face à
l'extérieur ; il n'a plus de raison d'être une fois l'Outdoor livré, et
`outdoor_policy_test.dart` devra être réécrit en conséquence, pas supprimé —
il porte le cas mesuré, une *Veronica elliptica* rendue *Nephrolepis
cordifolia* à 0,8978.

Le lieu est déjà résolu côté app : `plant_detail_screen.dart` lit
`locationsProvider` et sait si la plante est dehors. C'est le même signal qui
choisira le masque ; rien de nouveau n'est à collecter auprès de
l'utilisateur.

### 14.4 Ce qu'il faut mesurer avant de livrer

Aucune de ces lignes ne demande une collecte ; toutes demandent la tête
complète de l'Iris 9.

| mesure | comment | ce qu'elle décide |
|---|---|---|
| Indoor 363 vs Indoor élargi 421 | deux retaillages, `compare_models.py` sur le même jeu | quel masque intérieur on livre — **pas encore fait**, l'Iris 9 livre le masque de 363 |
| Outdoor 1 424 sur son terrain | retaillage sur le seul masque extérieur | ✅ **fait** le 21 septembre : 0,6898 top-1, 60,9 % acceptées à 0,9073 (§ 14.6). La comparaison directe avec l'Iris 8 demande encore son fichier sur la même machine |
| union 1 612 + masque appliqué | `compare_models.py` sur le jeu Indoor | ✅ **fait** le 21 septembre : 1 569 classes gardées, et le masque rend bien ce qu'annonçait le § 14.2 |
| hors-sujet sur l'union masquée | `hors_sujet.py` | le masque restreint 1 612 sorties à ~363 : le taux d'affirmation à tort des plantes hors catalogue remonte-t-il au-dessus des 27,5 % du § 12.7 |
| fiches manquantes sur 1 612 | le compteur du § 12.1 | combien de classes exposées ne mènent à rien — le défaut du § 12.14, à l'échelle de l'union |
| masquer ou non quand le lieu n'est pas renseigné | `interieur.py`, une fois avec le masque intérieur, une fois sans | ce que l'application fait pour qui n'a jamais rangé ses plantes — aujourd'hui elle ne masque pas |
| la marge du candidat d'ailleurs | `hors_sujet.py` sur des plantes d'un lieu et de l'autre | `FallbackPolicy.contextMargin`, posée à 0,15 sans mesure |

Deux d'entre elles sont des portes, au sens du § 13.7 :

- **l'Outdoor n'est pas prêt tant qu'il n'a pas son propre jeu de test.** Le
  § 8 de `docs/14` le dit, et le seul chiffre disponible aujourd'hui — 0,6365
  contre 0,6672 — a été lu sur une tête tronquée, donc ne juge rien ;
- **une classe exposée sans fiche est une impasse.** Elle se nomme à l'écran
  et ne mène à aucun conseil. À 336 sorties, six cas (§ 13.3). À 1 612, le
  compte est à faire avant, pas après.

### 14.5 Ce qui est déjà dans le code

Tout ce qui ne dépendait pas du modèle a été écrit d'abord, et s'est tu
jusqu'à ce qu'un masque soit livré — trois jours, jusqu'à l'Iris 9. Un modèle
sans objet `masks` laisse ce code sans effet, et l'application se comporte
alors exactement comme avant cette section. Ce qu'il rend une fois les
masques livrés est au § 14.6.

| où | quoi |
|---|---|
| `lib/domain/identification/identification_context.dart` | le lieu — `indoor`, `outdoor`, `unknown` |
| `lib/domain/identification/context_mask.dart` | la lecture des masques et la renormalisation, en fonctions pures : ce ne sont que des divisions, elles se mesurent sans interpréteur natif |
| `tflite_plant_model.dart` | une seule inférence, le masque appliqué à sa sortie |
| `cascade_identifier.dart` | le lieu porté jusqu'au modèle, présent dans les clés de cache, et la fusion multi-photo faite **par échelle** |
| `identification_policy.dart` | le verdict rendu sur les classes du lieu, et `challenger` — le candidat d'ailleurs qui reprend la parole |
| `identification_sheet.dart` | le candidat d'ailleurs affiché en dernier, après la réponse du lieu |
| `retailler.py --masque nom=fichier` | l'export d'un modèle d'union, `--garder` devenant l'union des masques |

Deux choix méritent d'être dits, parce qu'ils se lisent mal dans un diff :

- **la réserve du dehors se lève toute seule.** Aujourd'hui Iris propose au
  lieu d'affirmer à un emplacement extérieur (§ 13.3). Ce n'est pas une règle
  sur l'extérieur, c'est une règle sur un modèle qui n'expose que de
  l'intérieur : la feuille d'identification demande au modèle quels lieux il
  couvre, et la réserve tombe le jour où un masque extérieur est livré. Aucune
  constante à changer, rien à se rappeler ;
- **un lieu non renseigné ne masque rien.** Deviner « intérieur » ferait
  gagner le masque à tout le monde et le ferait perdre à qui a mis sa plante
  dehors sans le dire. C'est la ligne à mesurer du § 14.4 : le masque n'est un
  gain que lorsqu'il est juste.

Ce qui reste, et qui demandait le modèle : les valeurs. `contextMargin` est
posée à 0,15 sans mesure, et la masse minimale sous laquelle renormaliser
ment n'est bornée que numériquement. Le modèle est là depuis le 21 septembre ;
ces deux-là attendent toujours (§ 14.6).

### 14.6 Ce que le masque rend, mesuré — 21 septembre 2026

L'Iris 9 est le premier modèle à porter l'objet `masks` : 336 classes pour
l'intérieur, 1 424 pour l'extérieur, 1 569 exposées en tout. Les deux
lectures de `compare_models.py` sont **exactement** les deux comportements
possibles de l'application, puisque les classes communes à l'Iris Indoor et
à l'Iris 9 sont précisément celles du masque intérieur.

Sur les photos de plantes cultivées :

| | top-1 | autonomie à 0,70 | justesse |
|---|---|---|---|
| Iris Indoor (livré jusqu'ici) | 0,7310 | 62,7 % | 0,9234 |
| **Iris 9, masque du lieu appliqué** | **0,7650** | **65,7 %** | **0,9284** |
| Iris 9, sans masque | 0,7230 | 67,5 % | 0,9030 |

**Le masque transforme une perte de 0,8 point en un gain de 3,4.** C'est la
mesure de ce que vaut le § 14 : le même fichier, la même inférence, et
quatre points d'écart selon qu'on renormalise ou non sur le lieu. Sans lui,
livrer un modèle plus large aurait coûté à l'utilisateur ce qu'il rapporte
en couverture.

**Et la réserve du dehors s'est levée toute seule**, comme le § 14.5 l'avait
prévu : le modèle déclare un masque extérieur, `TflitePlantModel.contexts`
n'est plus vide, et la feuille d'identification cesse de retenir Iris à un
emplacement extérieur. Aucune constante n'a été touchée.

#### L'Outdoor a enfin son propre terrain

Le § 8 de `docs/14` l'exigeait avant de le considérer prêt : *Outdoor doit
recevoir son propre jeu de test.* La même tête retaillée sur le seul masque
extérieur, évaluée sur le jeu de test, le lui donne.

| | classes | top-1 | top-3 | autonomie à 0,70 | justesse |
|---|---|---|---|---|---|
| **masque extérieur** | 1 424 | **0,6898** | 0,8246 | 60,9 % | 0,9073 |
| union, sans masque | 1 569 | 0,6876 | 0,8227 | 60,8 % | 0,9051 |
| Iris 8, même masque (§ 13.6) | 1 444 | 0,6672 | 0,8063 | 55,0 % | 0,9176 |

Deux points au-dessus de l'Iris 8, qui était le généraliste extérieur que
l'application livrait avant Indoor — sur un tirage d'images différent, donc
un indice fort plutôt qu'une mesure. La version décisive demanderait un
`compare_models.py` entre les deux, et donc le fichier de l'Iris 8 sur la
même machine.

**Et les deux masques ne valent pas la même chose.** Le masque extérieur
garde 1 424 sorties sur 1 569 — il n'en retire que 145 — et ne rapporte que
deux dixièmes de point, courbes de seuil quasi superposées. Le masque
intérieur garde 336 sorties sur 1 569 et rapporte 4,2 points.

> **La valeur d'un masque est dans ce qu'il enlève, pas dans ce qu'il garde.**

C'est « la largeur se paie dans les sorties » vue par l'autre bout. Dehors,
l'Iris 9 est le généraliste qu'il est, et le masque n'y change presque rien ;
dedans, le masque en fait un spécialiste. Cela ne rend pas le masque
extérieur inutile — il empêche un géranium de salon d'être proposé devant un
massif —, mais il ne faut pas lui attribuer un gain qu'il ne produit pas.

Deux choses restent à mesurer :

- **`FallbackPolicy.contextMargin`**, posée à 0,15 sans mesure — c'est elle
  qui décide quand un candidat hors du lieu reprend la parole ;
- **ce qu'on fait quand le lieu n'est pas renseigné.** Aujourd'hui on ne
  masque rien, et cette ligne du § 14.4 attend toujours son `interieur.py`.

### 14.7 Ce qu'on ne fera pas

- **pas deux fichiers `.tflite`.** Six mégaoctets et une seconde d'inférence
  pour une renormalisation qui se calcule en quelques lignes ;
- **pas de téléchargement séparé du modèle Outdoor.** Le § 8 prévoit une
  mise à jour de modèle, pas deux catalogues à tenir à jour séparément ;
- **pas de masque dur sans issue.** Une classe hors contexte est déclassée,
  jamais supprimée : le § 3.2 décrit exactement cette panne — un modèle qui
  ne peut pas dire la bonne réponse répond faux avec assurance ;
- **pas d'arbitrage entre deux entraînements.** Tant que les deux masques ne
  viennent pas de la même tête, comparer leurs scores n'a pas de sens
  (§ 14.1).

## 15. Pl@ntNet-300K et PlantCLEF 2024 à côté d'Iris : le banc d'essai de la 1.0.1

La question du § 4.6 et du § 12.8 — que valent les modèles de Pl@ntNet pour
nous ? — y était tranchée sur les métadonnées : recouvrement d'espèces,
licences, cadrage. Il restait à voir ce que rendent **les modèles** sur les
photos qu'on prend d'une plante chez soi. La 1.0.1 en livre deux dans
l'application, chacun derrière un réglage, pour les mesurer là.

### 15.1 Ce qui tourne

| | Pl@ntNet-300K | PlantCLEF 2024 |
|---|---|---|
| réseau publié | MobileNetV3-Large, la dorsale d'Iris | ViT-B/14 à registres, pré-entraîné par DINOv2, affiné en entier (`…_onlyclassifier_then_all`, poids EMA) |
| jeu | Pl@ntNet-300K, 306 000 images | 1,4 million d'images Pl@ntNet, flore d'Europe du Sud-Ouest |
| espèces | 1 019 (1 081 sorties, voir plus bas) | 7 806 |
| top-1 annoncé par les auteurs | — | 75,9 % (une plante par image) |
| entrée | 224 px (`Resize(256)`, `CenterCrop(224)`) | 518 px (`Resize(518)` bicubique, sans recadrage) |
| poids | float16, 11,6 Mo | int8 dynamique, 97,4 Mo |
| licence | jeu CC BY 4.0, poids sans licence déclarée | CC BY 4.0 (Zenodo 10848263) |
| script | `plantnet300k_export.py` | `plantclef2024_export.py` |

Ce qu'Iris met en face se lit dans sa fiche, au § 0, et nulle part ailleurs.

Les deux scripts partagent `tools/plant_model/comparaison.py`, qui ajoute au
réseau ce qu'attend `TflitePlantModel` — entrée NHWC en octets 0–255,
normalisation ImageNet dans le graphe, softmax en sortie — et vérifie que le
`.tflite` rend ce que rend PyTorch. Côté Dart, rien de neuf : chaque modèle
est un `TflitePlantModel` de plus, sur ses propres assets
(`assets/model/<key>/`, `ComparisonModel`).

**1 081 sorties, 1 019 espèces.** Pl@ntNet-300K nomme parfois la même plante
sous deux ou trois citations d'auteur (« *Tradescantia zebrina* Bosse », « …
hort. ex Bosse »). Telles quelles, elles s'affichaient deux fois et se
partageaient le score. Le graphe additionne leurs probabilités ; `labels.txt`
n'a plus que des espèces distinctes. PlantCLEF 2024 n'a pas ce défaut.

**Le TensorFlow Lite d'iOS est en 2.12** (`ios/Podfile.lock`), celui
d'Android est LiteRT 1.4 (`tflite_flutter` 0.12.1). Trois conséquences, que
les scripts prennent en charge :

- le quantificateur range les poids d'un modèle de plus de 256 Ko hors du
  flatbuffer, ce que la 2.12 refuse (« Input tensor lacks data ») ; les
  scripts forcent la sérialisation d'un seul tenant ;
- l'attention fusionnée de timm se convertit en un op composite inconnu de
  la 2.12 ; `plantclef2024_export.py` l'écrit en clair (`BATCH_MATMUL`,
  `SOFTMAX`) ;
- **l'int8 dynamique n'est pas accéléré en 2.12.** Mesuré sur le poste de
  conversion, deux fils, une photo à 518 px :

| PlantCLEF 2024 | LiteRT récent | TFLite 2.12 | mémoire en plus (2.12) |
|---|---|---|---|
| float32, 370 Mo | 1,6 s | 4,4 s | ~1 000 Mo |
| int8 poids seuls, 97 Mo | — | 4,3 s | ~1 000 Mo |
| **int8 dynamique, 97 Mo** (livré) | **0,8 s** | **10,1 s** | **~390 Mo** |

  L'int8 « poids seuls » est aussi rapide que le flottant en 2.12, mais les
  poids s'y redéplient en float32 au chargement : un gigaoctet de plus, à
  côté d'Iris et de Pl@ntNet-300K, c'est l'application tuée par iOS sur un
  téléphone de 4 Go. L'int8 dynamique garde ses poids en int8 et coûte
  quatre fois moins de mémoire ; sur iPhone il se paie en secondes. Android
  embarque un LiteRT récent, où il était le plus rapide des trois sur le
  poste de conversion — à confirmer sur un téléphone. D'où son délai de 60 s
  par photo (`ComparisonModel.timeout`).

Les deux modèles livrés ont été chargés et exécutés par un interpréteur 2.12
avant d'être commités. L'int8 dynamique s'écarte du float32 d'au plus 0,09
en probabilité, sans changer le premier candidat d'aucune des photos de
contrôle, à un ex-æquo près (*Anthurium*, deux espèces à 0,02).

### 15.2 Ce que voit l'utilisateur

*Réglages > Identification > Modèles à comparer* : un interrupteur par
modèle, tous éteints par défaut. Pour chacun d'allumé :

- chaque identification passe par Iris, **puis** par les modèles allumés, un
  à la fois, dans l'ordre de `ComparisonModel`. Jamais en même temps : deux
  inférences simultanées se partageraient le processeur, Iris dépasserait le
  délai de la cascade et partirait en ligne — la comparaison fausserait ce
  qu'elle mesure ;
- la feuille d'identification montre ses cinq premières propositions sous
  celles d'Iris, dans une section « Propositions de … ». Elles se
  choisissent comme les autres ;
- toutes les listes affichent le **score brut** à côté du cran de
  confiance. Tout éteint, rien ne change : un pourcentage se lit comme une
  certitude qu'il n'est pas ;
- un modèle qui ne se charge pas le dit, erreur native comprise, au lieu de
  « ne reconnaître aucune plante ».

Rien de ce que rendent ces modèles n'entre dans la décision : ni seuil, ni
repli, ni compteur. Chacun passe par une `CascadeIdentifier` sans repli
(même fusion des photos, même rattachement au catalogue) dont les compteurs
restent en mémoire, pour ne pas fausser ceux d'Iris dans les réglages.

### 15.3 Premier coup d'œil, et ce qu'il ne dit pas

Neuf photos iNaturalist, une par espèce, et la photo de test que les auteurs
de PlantCLEF joignent à leurs poids, passées dans les trois `.tflite` :

| photo | Iris | Pl@ntNet-300K | PlantCLEF 2024 |
|---|---|---|---|
| *Anthurium andraeanum* | ✅ 1,00 | ✅ 1,00 | *Datura metel* 0,02 ✗ |
| *Cirsium vulgare* | *Carduus nutans* 0,92 | ✅ 1,00 | ✅ 0,07 |
| *Fittonia albivenis* | ✅ 0,92 | ✅ 1,00 | *Salix reticulata* 0,01 ✗ |
| *Lactuca virosa* | *Chrysanthemum × morifolium* 0,30 | *Lactuca serriola* 1,00 | *Lactuca quercina* 0,47 (✅ 2ᵉ, 0,16) |
| *Monstera deliciosa* | ✅ 1,00 | *Alocasia macrorrhizos* 0,99 ✗ | *Polypodium macaronesicum* 0,05 ✗ |
| *Pelargonium zonale* | ✅ 0,99 | *Pelargonium inquinans* 0,56 | *Pelargonium graveolens* 0,05 (✅ 3ᵉ) |
| *Schefflera arboricola* | ✅ 0,85 | ✅ 0,99 | *Pyracantha angustifolia* 0,03 ✗ |
| *Tradescantia zebrina* | ✅ 0,53 | ✅ 1,00 | *Tradescantia fluminensis* 0,05 ✗ |
| *Zamioculcas zamiifolia* | ✅ 0,78 | *Erucastrum incanum* 0,68 | *Cyrtomium falcatum* 0,11 ✗ |
| *Orchis simia* (photo des auteurs) | — | — | ✅ 0,43 |

✗ : l'espèce n'est pas parmi celles du modèle — il ne pouvait pas la nommer.

Dix photos ne mesurent rien, et celles-ci moins encore : Iris s'entraîne
sur iNaturalist et a pu voir ces images-là. Elles disent en revanche trois
choses à vérifier sur les vraies photos :

- **aucun des deux ne peut nommer ce qu'il ne connaît pas.** Pas de
  *Monstera* dans Pl@ntNet-300K, et six des neuf plantes d'intérieur
  absentes des 7 806 espèces de PlantCLEF 2024 : c'est une flore sauvage,
  pas un catalogue de salon. C'est la panne du § 3.2 ;
- **Pl@ntNet-300K est sûr de lui jusque dans l'erreur** — 1,00 sur une
  espèce voisine, 0,99 sur un *Alocasia* pour un *Monstera* ;
- **PlantCLEF 2024 répartit sa confiance** : 0,07 pour un *Cirsium vulgare*
  juste, 0,43 pour la photo de test de ses propres auteurs. Entraîné avec
  mixup et cutmix sur 7 806 classes, il ne sort presque jamais de score
  franc. C'est honnête, mais aucun seuil d'Iris ne s'y transpose : le
  0,70 de `FallbackPolicy` le ferait partir en ligne à chaque photo.

S'il fallait remplacer Iris par l'un d'eux, la courbe du § 6.7 serait à
refaire, et la question des espèces d'intérieur absentes resterait entière.
Cela se jugera sur les plantes qu'on photographie vraiment, dans la maison :
c'est ce que ces réglages permettent de relever.
