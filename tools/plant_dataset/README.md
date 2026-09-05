# Jeu d'images pour la reconnaissance de plantes

Outil de collecte, en Python, qui construit le jeu d'entraînement du modèle
embarqué dans l'app. Il ne tourne jamais sur le téléphone : c'est un outil
de développement, lancé sur un poste, dont le résultat (`dataset/`) reste
hors de Git.

La vue d'ensemble — pourquoi un modèle local, comment il s'articule avec
Pl@ntNet, le plan d'entraînement — est dans
[`docs/09-plant-recognition.md`](../../docs/09-plant-recognition.md).
Ce fichier ne dit que comment lancer l'outil.

## Installation

```bash
cd tools/plant_dataset
python3 -m pip install -r requirements.txt   # requests, Pillow, numpy, pytest
python3 -m pytest -q                          # 52 tests, sans réseau
```

## Fichiers

| Fichier | Rôle |
|---|---|
| `plants.csv` | La liste de référence : une ligne par plante, avec son nom canonique, son identifiant interne, ses noms courants, sa clé GBIF et son identifiant Wikidata. Versionné. |
| `export_plants.py` | Régénère `plants.csv` depuis le catalogue de l'app (`lib/data/species/species_catalog.dart`) sans perdre les identifiants déjà résolus. |
| `enrich_plants.py` | Remplit `gbif_key` et `wikidata_id` (réseau). |
| `build_dataset.py` | Collecte les images, vérifie, déduplique, répartit, attribue. |
| `plant_dataset/` | Le paquet : `taxonomy` (noms), `licenses`, `manifest`, `images`, `dedup`, `splits`, `fetchers/gbif`. |
| `tests/` | Tests unitaires, avec des réponses GBIF réelles enregistrées dans `tests/fixtures/`. |
| `dataset/` | Sortie. **Ignorée par Git.** |

## Lancer le test de validation (5 plantes, 100 images)

C'est le test à refaire après toute modification du pipeline. Il dure
moins d'une minute et télécharge environ 30 Mo.

```bash
cd tools/plant_dataset
rm -rf dataset
python3 build_dataset.py \
  --plants plants.csv --out dataset \
  --only "Monstera deliciosa,Epipremnum aureum,Ficus elastica,Chlorophytum comosum,Spathiphyllum wallisii" \
  --target-per-species 20 --max-candidates 200
```

Résultat attendu (obtenu le 5 septembre 2026) :

```
100 images gardées sur 100 ; doublons exacts 0, quasi 0 ; 0 en revue ; 100 attributions
licences : {'CC BY 4.0': 30, 'CC0 1.0': 70}
```

Puis vérifier à la main :

- `dataset/stats.json` : décomptes par espèce, licence, source ;
- `dataset/ATTRIBUTIONS.md` : chaque image a un auteur, une licence acceptée et un lien vers l'observation ;
- `dataset/manifest.jsonl` : une ligne par image, avec `checksum`, `phash`, `status`, `reason` ;
- `dataset/splits.csv` : `train` / `val` / `test`, avec la colonne `group` (une observation = un groupe) ;
- ouvrir cinq ou six images au hasard : ce sont bien des plantes, et la bonne espèce.

## Options de `build_dataset.py`

| Option | Défaut | Sens |
|---|---|---|
| `--plants` | `plants.csv` | liste de référence |
| `--out` | `dataset` | dossier de sortie |
| `--target-per-species N` | 200 | images gardées visées par espèce |
| `--only "A,B"` | | ne traiter que ces noms scientifiques |
| `--limit-species N` | | ne traiter que les N premières plantes du CSV |
| `--max-candidates N` | 1500 | occurrences GBIF parcourues au plus, par licence |
| `--allow-sa` | non | accepter aussi CC BY-SA (voir licences ci-dessous) |
| `--skip-fetch` | | ne rien télécharger : dédupliquer, répartir, compter ce qui est déjà là |

L'outil est relançable : ce qui figure déjà dans `manifest.jsonl` n'est pas
retéléchargé, et les identifiants de source (`gbif`, `<clé d'occurrence>#<n>`)
évitent tout doublon d'origine.

## Licences acceptées

Seules les images sous **CC0 1.0**, **Public Domain Mark** ou **CC BY** (toutes
versions) sont gardées. **CC BY-SA** est refusée par défaut (le partage à
l'identique obligerait à publier le modèle sous la même licence — question
juridique ouverte, tranchée plus tard). **NC**, **ND**, licence inconnue ou
absente, tout contenu propriétaire ou venu d'un moteur d'images : refusés,
sans exception.

Le filtre est appliqué deux fois : dans la requête GBIF (`license=CC0_1_0`
puis `license=CC_BY_4_0`), puis sur **la licence propre de chaque média**,
car une observation CC BY peut porter une photo CC BY-NC (c'est le cas dans
la fixture `tests/fixtures/gbif_occurrence_page.json`, et elle est bien
refusée).

Chaque image gardée est tracée dans le manifeste avec : source, identifiant
d'observation, URL d'origine, URL de l'image, auteur, licence, URL de la
licence, date de téléchargement, empreinte SHA-256. `ATTRIBUTIONS.md` et
`attributions.csv` sont générés à partir de là et doivent être livrés avec
tout modèle entraîné.

## Ce que fait le pipeline, image par image

1. **Nom** — `plants.csv` → GBIF `species/match` (règne Plantae). Seules les
   correspondances `EXACT`, ou `FUZZY` avec confiance ≥ 95, au rang de
   l'espèce ou en dessous, sont acceptées ; le reste est noté dans
   `species.json` et sauté.
2. **Collecte** — `occurrence/search` avec `mediaType=StillImage`,
   `basisOfRecord=HUMAN_OBSERVATION`, par licence, page de 100, cadence
   0,25 s entre requêtes et User-Agent identifiable.
3. **Téléchargement** — 25 Mo au plus ; formats JPEG, PNG, WEBP.
4. **Vérification** — image lisible, orientation EXIF appliquée, côté
   minimal 320 px, proportions ≤ 1:12, pas d'animation ; réduite à 1024 px
   de grand côté et réencodée en JPEG (qualité 92) si nécessaire.
5. **Doublons** — exacts par SHA-256, quasi-doublons par empreinte
   perceptuelle (DCT 64 bits, distance de Hamming ≤ 6) au sein d'une espèce.
   Le même visuel sous deux espèces différentes va en `_review/` : c'est une
   étiquette douteuse, à trancher à la main.
6. **Répartition** — 80 / 10 / 10 par groupe (toutes les photos d'une
   observation, et leurs quasi-doublons, ensemble), déterministe par
   empreinte du groupe : ajouter des images ne déplace pas les anciennes.
   Sur 20 images par espèce la répartition est forcément grossière ; elle
   devient proportionnelle avec quelques centaines d'images.

## Régénérer ou enrichir la liste des plantes

```bash
python3 export_plants.py            # depuis species_catalog.dart, garde les identifiants connus
python3 enrich_plants.py            # GBIF puis Wikidata ; ~2 min pour 297 plantes
```

État actuel : 297 plantes, 295 clés GBIF, 282 identifiants Wikidata.
Les deux noms sans clé sont des taxons horticoles sans existence
nomenclaturale (`Rosa × hybrida`, `Cymbidium hybridum`) : ils devront
être renommés ou traités comme des classes « genre » avant d'entrer dans le
modèle. `Prunus dulcis` et `Allium porrum` ont été résolus par leurs
synonymes acceptés chez GBIF (`Prunus amygdalus`, `Allium ampeloprasum`).

## Étape suivante

Une fois ce test validé, et seulement alors : passer `--target-per-species`
à 100 puis 300 sur toute la liste, et ajouter les connecteurs iNaturalist
(API directe, pour les observations « research grade » non encore
moissonnées par GBIF) et Wikimedia Commons (catégories par espèce). Les deux
s'écrivent comme `fetchers/gbif.py` : une fonction qui rend des
`ImageCandidate`, le reste du pipeline ne change pas.
