# 09 — Reconnaissance de plantes : Iris, le modèle embarqué, repli Pl@ntNet

> État au 8 septembre 2026 : 1 558 plantes au catalogue de collecte, 290 518
> images sous CC0, CC BY ou CC BY-SA, modèle MobileNetV3-Large à **1 445
> classes** livré dans l'app en TFLite (8,8 Mo). La cascade identifie **sur
> l'appareil** et n'appelle Pl@ntNet que sur hésitation ; deux photos de la
> même plante valent dix-neuf points de top-1.

Le modèle embarqué s'appelle **Iris**, et la version livrée est la sixième :
c'est donc **Iris 6** que l'application nomme à l'écran. Le reste de ce
document parle de « la v6 » quand il compare des entraînements entre eux —
ce sont les mêmes poids, vus du côté de la recette plutôt que du produit.

## 0. Le nom

`Iris` est la marque du modèle, `AppConfig.modelName` dans le code. Le numéro
ne s'écrit **jamais** à la main : le modèle l'annonce dans
`assets/model/model.json`, `TflitePlantModel` le lit au chargement et
`AppConfig.modelDisplayName(version)` le colle au nom. Livrer un modèle
réentraîné suffit donc à faire dire « Iris 7 » à l'écran des réglages, et
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
const FallbackPolicy(acceptThreshold: 0.90, minMargin: 0.25, floor: 0.10)
```

Réponse locale **acceptée** si, et seulement si :

- le meilleur score ≥ **0,90**, **et**
- l'écart entre le premier et le deuxième score ≥ **0,25**.

Un modèle qui donne 0,91 / 0,89 n'a rien décidé ; on demande à Pl@ntNet.
Sous **0,10**, la liste ne vaut rien (image hors sujet) : `noCandidate`.

**Recalage sur le modèle v1** (862 images de test, 78 espèces) :

| Seuil | Réponses acceptées | Précision sur ces réponses |
|---|---|---|
| 0,80 | 39 % | 92,6 % |
| **0,90** | **30 %** | **96,9 %** |
| 0,95 | 22 % | 97,9 % |

On garde **0,90**. La précision à 0,95 est meilleure d'un point, mais
l'incertitude de la mesure est du même ordre (±1 point sur 259 réponses
acceptées) alors que l'acceptation chute d'un tiers.

**La marge est aujourd'hui sans effet** : les scores d'un softmax somment
à 1, donc un premier candidat à 0,90 laisse au plus 0,10 au deuxième —
la marge vaut toujours au moins 0,80. Elle ne mordrait qu'avec un seuil
sous 0,625, ou un modèle dont les sorties ne somment pas à 1. Elle est
conservée pour cela, pas parce qu'elle travaille.

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
   d'Europe de l'Ouest ; un test sur les 297 plantes du catalogue Auxine
   (plantes d'intérieur, tropicales, horticoles) reste à faire, mais
   *Monstera*, *Epipremnum*, *Spathiphyllum* n'y ont aucune raison d'être
   bien représentés. GBIF nous donne des images de ces plantes précises.
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

### 6.6 Résultats du modèle v1

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

### 6.7 Recette

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
cd tools/plant_dataset && python3 -m pytest -q      # 95 tests
flutter test                                        # dont 33 pour l'identification
```

## 12. Reste à faire, dans l'ordre

1. Pré-entraînement PlantNet-300K (§ 4.6, option a), jamais essayé. Vérifier
   d'abord s'il existe un poids MobileNet publié — sans quoi c'est une
   seconde passe complète — et le recouvrement d'espèces, qui a beaucoup
   augmenté avec les 530 plantes de jardin de la v6.
2. Régularisation : à la douzième époque, l'entraînement est à 70,5 % et la
   validation à 52,2 %. Dix-huit points d'écart, c'est elle qui limite, pas
   le nombre d'époques.
3. Trois hybrides horticoles sans image, à résoudre par `synonyms.txt`.
4. Photos de plantes en pot dans des intérieurs : c'est ce qui manque encore
   au ficus ginseng, et les licences libres en offrent peu (§ 6.5). Le
   connecteur Wikimedia Commons (§ 4.4) est écrit pour ça mais n'a pas
   encore servi à une collecte complète — reste à mesurer ce qu'il ajoute
   réellement, espèce par espèce, avant de le mettre dans la recette.
