# 09 — Reconnaissance de plantes : Iris, le modèle embarqué, repli Pl@ntNet

> État au 9 septembre 2026 : 1 558 plantes au catalogue de collecte, 290 131
> images sous CC0, CC BY ou CC BY-SA, modèle MobileNetV3-Large à **1 457
> classes**, entrée 320 px, livré dans l'app en TFLite (8,8 Mo). La cascade
> identifie **sur l'appareil** et n'appelle Pl@ntNet que sur hésitation ;
> deux photos de la même plante valent quatorze points de top-1, trois en
> valent vingt-deux.

Le modèle embarqué s'appelle **Iris**, et la version livrée est la septième :
c'est donc **Iris 7** que l'application nomme à l'écran. Le reste de ce
document parle de « la v7 » quand il compare des entraînements entre eux —
ce sont les mêmes poids, vus du côté de la recette plutôt que du produit.

## 0. Le nom

`Iris` est la marque du modèle, `AppConfig.modelName` dans le code. Le numéro
ne s'écrit **jamais** à la main : le modèle l'annonce dans
`assets/model/model.json`, `TflitePlantModel` le lit au chargement et
`AppConfig.modelDisplayName(version)` le colle au nom. Livrer un modèle
réentraîné suffit donc à faire dire « Iris 8 » à l'écran des réglages, et
l'application ne peut pas afficher un numéro qui ment.

Tant que le modèle n'a rien dit — pas encore chargé, métadonnées absentes —
l'application dit « Iris » tout court plutôt que d'inventer un numéro.

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
| Catalogue étendu | `assets/species/catalog.tsv` → `SpeciesIndex` | 36 364 espèces, noms courants, chargé à la demande |
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
| `lib/features/identification/presentation/identification_settings_screen.dart` | interrupteur « Repli en ligne » + ligne de compteurs |

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
la v6, **0,70 de nouveau sur Iris 7**. Un réseau qui répartit sa confiance sur
plus d'espèces sort des scores structurellement plus bas ; un réseau mieux
calibré en sort de plus honnêtes. Le recalage se fait avec
`tools/plant_model/multi_photo.py`, sur les photos de plantes cultivées et
dans le calcul exact que fait la cascade — mesure et raisonnement au § 6.7.

C'est la première fois qu'il **remonte**. Les versions précédentes dépensaient
leur surplus de justesse en autonomie ; Iris 7 permet l'inverse, et à 0,70 elle
rend l'autonomie qu'avait la v6 à 0,60 — 47 % de réponses seules — avec 85,9 %
de justesse au lieu de 82,8 %.

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

**La clé est celle de l'éditeur, fournie au build**, pas celle de
l'utilisateur : l'identification en ligne fait partie de l'application,
personne n'a à ouvrir un compte chez un tiers pour s'en servir.

```bash
flutter build ipa --dart-define=PLANTNET_API_KEY=xxxxxxxx
```

Elle est lue par `IdentificationConfig` (`lib/core/config/identification_config.dart`),
sur le même modèle que `SupabaseConfig`. Sans clé au build, le repli est
simplement absent et l'application se contente du modèle embarqué.

Une clé compilée dans un binaire mobile est extractible par qui démonte le
paquet — c'est vrai de toute application qui en embarque une. Ce qui limite
le risque ici : le modèle local absorbe la majorité des demandes, et le
quota mensuel par appareil borne la casse. Le jour où l'usage le
justifie, la parade est un relais côté serveur qui garde la clé et signe les
requêtes ; `PlantNetIdentifier` n'aurait alors qu'à changer d'URL.

**Configuration dans Codemagic**

1. Codemagic → l'application → **Environment variables**.
2. Nom `PLANTNET_API_KEY`, valeur la clé, groupe par exemple `flora_secrets`,
   **Secure** coché — une variable sécurisée est chiffrée et masquée dans les
   journaux de build.
3. Le groupe doit être attaché au workflow (`groups:` dans `codemagic.yaml`,
   ou la case du groupe dans l'éditeur d'interface).
3. Passer la variable au build :

```yaml
environment:
  groups:
    - flora_secrets          # contient les variables ci-dessous
scripts:
  - name: Build iOS
    script: |
      flutter build ipa --release \
        --dart-define=PLANTNET_API_KEY=$PLANTNET_API_KEY \
        --dart-define=INFOMANIAK_AI_API_KEY=$INFOMANIAK_AI_API_KEY \
        --dart-define=INFOMANIAK_AI_PRODUCT_ID=$INFOMANIAK_AI_PRODUCT_ID \
        --dart-define=INFOMANIAK_AI_MODEL=$INFOMANIAK_AI_MODEL
```

Toutes les variables de build de l'application, à mettre dans le même
groupe :

| Variable | Sert à | Sans elle |
|---|---|---|
| `PLANTNET_API_KEY` | repli Pl@ntNet de l'identification | modèle embarqué seul |
| `INFOMANIAK_AI_API_KEY` | diagnostic « Ma plante a un problème » (jeton d'API Infomaniak, portée AI Services) | diagnostic absent |
| `INFOMANIAK_AI_PRODUCT_ID` | identifiant du produit AI Services, dans l'URL du manager | diagnostic absent |
| `INFOMANIAK_AI_MODEL` | modèle du diagnostic ; facultatif, `mistralai/Mistral-Small-4-119B-2603` par défaut | le défaut |
| `SUPABASE_URL`, `SUPABASE_ANON_KEY` | compte, synchronisation, partage (docs/08) | application 100 % locale |
| `SHARE_BASE_URL` | base des liens de partage ; facultatif | l'URL Supabase |

Le `--dart-define` est indispensable : une variable d'environnement de CI
n'entre pas toute seule dans le binaire Flutter.

- Déclenché seulement sur `uncertain` / `noCandidate`, ou sans modèle local.
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
| **OGL-3.0, etalab-2.0, CUSTOM-ML** | — | **zéro image** portant ces licences dans nos sources | sans objet |

Le cas Smithsonian Gardens mérite d'être retenu : 4 884 photos CC0 de
plantes vivantes cultivées, c'est exactement le bon domaine visuel, et
c'est pourtant sept images pour nous. Une source ne vaut pas par sa taille
mais par son recouvrement avec le catalogue — la mesure coûte dix minutes
et évite d'écrire un connecteur pour rien. Elle redeviendrait intéressante
le jour où le catalogue s'ouvrirait aux orchidées d'intérieur.


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
> de classe « autre » — le modèle a 1 457 sorties, pas 1 458, et le § 12.7
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
à l'écran : après Iris 6 vient Iris 7. Rien d'autre à renommer — ni le code,
ni les traductions, qui reçoivent le nom composé (§ 0).

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

Le diagnostic « Ma plante a un problème » (photos + symptômes → pistes
classées par vraisemblance, avec des gestes) ne passe pas par le modèle
embarqué, qui ne sait que nommer une espèce. Il envoie les photos aux AI
Services d'Infomaniak, hébergés en Suisse, par leur route compatible OpenAI
(`lib/data/services/infomaniak_diagnoser.dart`) :

- **Modèle** : `mistralai/Mistral-Small-4-119B-2603` par défaut, choisi
  parce qu'il voit les images, qu'il est stable, qu'il parle bien français
  et qu'il est le moins cher de sa taille en sortie (0,20 / 0,75 CHF par
  million de jetons). Un diagnostic — une à trois photos réduites à
  1 024 px, la consigne, 300 à 500 jetons de réponse — coûte de l'ordre
  d'un millième de franc. Le modèle se change au build
  (`INFOMANIAK_AI_MODEL`), sans toucher au code.
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
  comprises. Une photo sans plante lisible rend un résumé et aucune cause.
- **Ce qui est gardé** : l'analyse enregistrée l'est entière. La note du
  journal en garde le résumé et les trois premières pistes ; le compte rendu
  complet — chaque piste avec son explication et ses gestes, l'urgence, les
  symptômes signalés, les photos regardées — l'accompagne dans
  `plant_actions.metadata` (docs/04). La ligne du journal en montre l'aperçu
  et le rouvre d'un doigt, des mois plus tard, dans la langue du moment.
- **Ce qui n'est pas mesuré** : la justesse de ces modèles sur des maladies
  de plantes. La seule façon de choisir entre Mistral Small 4, Qwen 3.5 et
  Kimi est un jeu d'essai de vingt à trente photos de plantes à problème
  connu, envoyées avec la même consigne. Il reste à constituer.

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
- **Ce qui ne revient jamais** : la toxicité. Tout le reste est un avis sur
  le confort d'une plante ; « non toxique pour le chat » est une affirmation
  sur laquelle quelqu'un agit. Elle reste au catalogue, ou inconnue.
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
| règle de repli | `test/domain/identification/identification_policy_test.dart` |
| cascade : acceptation, repli, réglage, quota, cache, erreurs, fusion multi-photos, métriques | `test/domain/identification/cascade_identifier_test.dart` |
| rattachement au catalogue | `test/domain/identification/catalog_mapping_test.dart` |
| Pl@ntNet : parse | `test/data/plantnet_identifier_test.dart` |

```bash
cd tools/plant_dataset && python3 -m pytest -q      # 124 tests
flutter test                                        # dont 33 pour l'identification
```

## 12. Ce qu'il reste à faire, dans l'ordre

> **État au 9 septembre 2026.** Les § 12.1, 12.5 et 12.6 sont faits et livrés
> dans Iris 7 : ils valent ensemble **+7,26 points de top-1** à armes égales
> contre Iris 6 (§ 6.7). Le reste attend.

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

### 12.3 La deuxième photo, là où elle n'est pas encore proposée

Le bouton « ajouter une photo » n'apparaît que si la politique hésite
(`_ambiguous`, dans `identification_sheet.dart` et `create_plant_flow.dart`).
Une réponse **acceptée** ne le propose donc jamais — or une réponse acceptée
seule à 0,60 est juste **82,8 %** du temps (§ 6.6). Un sixième des réponses
affirmées sont fausses et ne se voient jamais offrir le geste qui les
corrigerait : à deux photos, la justesse passe à 92,3 %.

Élargir le déclencheur ne demande aucun réentraînement. Reste à trancher ce
qu'on ne veut pas casser : proposer une photo de plus après une bonne réponse
ajoute un geste à un parcours qui marchait. La piste raisonnable est de la
proposer sous les candidats, sans l'imposer, plutôt qu'en travers du chemin.

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

#### Le vrai enseignement : c'est de l'ignorance, pas de la confusion

**1 794 erreurs sur 2 458 franchissent la famille botanique.** Le document
raconte depuis la v1 une histoire de confusions entre espèces proches — le
yucca pris pour du maïs. La mesure dit que c'est le petit quart du problème,
et que ce quart-là est **déjà rattrapé par l'interface** : le top-3 est à
74,4 % contre 59,6 % de top-1, soit près de neuf cents images sur six mille
où la bonne réponse est dans les cinq candidats affichés.

Le reste n'est pas une confusion qu'on arbitre, c'est une plante que le
modèle n'a pas apprise. Le rapport le dit maintenant en une ligne : combien
d'espèces n'ont **pas une seule** bonne réponse sur leurs images de test.
Celles-là ne demandent pas un meilleur départage, elles demandent des
images.

#### Les familles franchies, et la seule qui touche l'application

| | |
|---|---|
| Pinaceae ↔ Cupressaceae | **26** — sapins, épicéas, cyprès, thuyas |
| **Asparagaceae ↔ Poaceae** | **14** |
| Amaranthaceae → Polygonaceae | 10 |
| Rosaceae → Ranunculaceae / Fagaceae / Caprifoliaceae / Fabaceae | 25 en tout |
| Asteraceae → Fabaceae / Apiaceae / Brassicaceae / Ranunculaceae | 26 en tout |

Les conifères dominent, et c'est sans conséquence : personne n'identifie un
thuya depuis son salon. **La paire qui compte est la deuxième.** Asparagaceae,
ce sont les 41 classes à feuilles en lanières — *Chlorophytum*, *Dracaena*,
*Cordyline*, *Aspidistra*, *Beaucarnea*, *Yucca* —, c'est-à-dire une bonne
part des plantes d'appartement du catalogue. Poaceae, ce sont les graminées.

**C'est le yucca pris pour du maïs du § 6.3, toujours là, et pas résolu.** La
v4 l'avait traité espèce par espèce, en recollectant des photos de yucca en
pot ; la vue par famille dit que le défaut n'était pas le yucca mais **la
forme de feuille**, et qu'il touche tout un rayon de jardinerie. Quatorze
erreurs sur six mille images est un petit nombre — mais mesuré sur un jeu de
test aux trois quarts sauvage, pas sur les photos que l'application reçoit.

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

De l'autre, aucune calibration ne résout le vrai problème. **Un classifieur à
1 457 sorties de plantes n'a aucun moyen de dire « ceci n'est pas une
plante » :** il répartit sa masse entre les espèces qu'il connaît, quoi qu'on
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

Trois réserves sur ce chiffre, dans les deux sens : l'échantillon est de
vingt, donc l'incertitude est d'une vingtaine de points ; c'est une **borne
basse**, GBIF ne filtrant que CC0 et CC BY à la requête et iNaturalist en
direct n'étant pas interrogé (§ 4.3) ; mais un tirage **au hasard** est le
pire cas.

#### La conclusion : sélectionner, ne pas tirer

C'est déjà ce que la v6 avait fait sans le nommer — ses 530 ajouts étaient
« les espèces cultivées les plus observées en Europe ». La liste des
candidates doit se **générer depuis GBIF par nombre d'observations**, pas se
tirer du catalogue étendu. `disponibilite.py` devient alors une
vérification, pas une recherche.

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

