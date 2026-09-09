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
python3 -m pytest -q                          # 105 tests, sans réseau
```

## Fichiers

| Fichier | Rôle |
|---|---|
| `plants.csv` | La liste de référence : une ligne par plante, avec son nom canonique, son identifiant interne, ses noms courants, sa clé GBIF et son identifiant Wikidata. Versionné. |
| `export_plants.py` | Régénère `plants.csv` depuis le catalogue de l'app (`lib/data/species/species_catalog.dart`) sans perdre les identifiants déjà résolus. |
| `enrich_plants.py` | Remplit `gbif_key` et `wikidata_id` (réseau). |
| `build_dataset.py` | Collecte les images, vérifie, déduplique, répartit, attribue. |
| `merge_shards.py` | Recolle des collectes menées en parallèle sur des parts disjointes du catalogue. |
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
| `--captive-file F` | | espèces (une par ligne) pour lesquelles réserver une part de plantes cultivées (iNaturalist `captive=true`) |
| `--captive-share` | 0,5 | part de la cible réservée aux plantes cultivées |
| `--captive-place ID` | | lieu iNaturalist (97391 = Europe) : les plantes cultivées de cette région sont collectées **en premier**, en plus de la cible |
| `--place-share` | 0,25 | part de la cible ajoutée en plantes cultivées de la région |
| `--skip-fetch` | | ne rien télécharger : dédupliquer, répartir, compter ce qui est déjà là |
| `--repair-splits` / `--no-repair-splits` | oui | donner un groupe de validation, puis de test, aux espèces qui n'en ont aucun ; `--no-repair-splits` rend la répartition d'avant, pour reproduire un modèle antérieur |
| `--workers N` | 6 | téléchargements en parallèle |
| `--gbif-pause` / `--inat-pause` | 0,25 / 1 | cadence des requêtes, en secondes ; à augmenter quand plusieurs collectes tournent |
| `--wikimedia` | non | compléter par Wikimedia Commons (voir ci-dessous) |
| `--commons-pause` | 1 | cadence Commons ; en dessous d'une seconde l'API répond 429 |

L'outil est relançable : ce qui figure déjà dans `manifest.jsonl` n'est pas
retéléchargé, et les identifiants de source (`gbif`, `<clé d'occurrence>#<n>`)
évitent tout doublon d'origine.

## Collecter le catalogue entier, en parallèle

Une collecte d'un seul tenant occupe un cœur et laisse le réseau attendre :
1 558 espèces prennent près de sept heures. Découpée en parts disjointes,
elle tient sur les quatre cœurs de la machine et descend sous les trois
heures. Les parts ne se chevauchent pas, donc la fusion est un déplacement
de dossiers.

```bash
python3 - <<'PY'
from pathlib import Path
noms = [l.strip() for l in Path('all_species.txt').read_text().splitlines() if l.strip()]
interieur = {l.strip() for l in Path('phase1_species.txt').read_text().splitlines() if l.strip()}
# Les plantes d'intérieur coûtent deux fois plus (passes « en pot ») : on les
# met en tête pour que les trois parts durent le même temps.
ordre = [n for n in noms if n in interieur] + [n for n in noms if n not in interieur]
for i in range(3):
    Path(f'shard{i}.txt').write_text('\n'.join(ordre[i::3]) + '\n')
PY

for i in 0 1 2; do
  mkdir -p shard$i && cp cache/species.json cache/species_inat.json shard$i/
  nohup python3 build_dataset.py --plants plants.csv --out shard$i --only-file shard$i.txt \
    --target-per-species 200 --allow-sa \
    --captive-file phase1_species.txt --captive-share 0.5 \
    --captive-place 97391 --place-share 0.25 \
    --workers 8 --gbif-pause 0.6 --inat-pause 2.0 > shard$i.log 2>&1 &
done
wait

python3 merge_shards.py --out dataset shard0 shard1 shard2
python3 build_dataset.py --out dataset --plants plants.csv --skip-fetch
```

La dernière ligne n'est pas facultative : déduplication entre espèces,
répartition et statistiques portent sur l'ensemble, et aucune part ne peut
les faire seule.

C'est la recette qui produit le jeu de la v6 (§ 6.6 de
[`docs/09`](../../docs/09-plant-recognition.md)). Une seconde passe sur
`phase1_species.txt` à `--target-per-species 300` ajoute ensuite les photos
de plantes en pot par-dessus la cible : ce sont celles qui décrivent l'usage
réel de l'application.

## Wikimedia Commons, en complément

GBIF et iNaturalist décrivent des observations de terrain. Commons est une
médiathèque : on y photographie son monstera dans son salon, un ficus chez
un fleuriste. C'est la distribution qui manque au modèle — le yucca pris
pour du maïs et le ficus ginseng illisibles viennent de là (§ 6.3 et 6.5 de
[`docs/09`](../../docs/09-plant-recognition.md)).

Deux chiffres mesurés avant d'écrire le connecteur, sur nos propres
espèces : **97 % des fichiers portent une licence utilisable**, contre 18 %
chez GBIF où les licences non commerciales écrasent tout ; et une catégorie
d'espèce contient de l'ordre de la centaine de fichiers. C'est un
complément, pas un remplacement.

```bash
python3 build_dataset.py --plants plants.csv --out dataset \
  --target-per-species 200 --allow-sa --wikimedia
```

Commons passe en dernier, après GBIF et iNaturalist, et seulement si la
cible n'est pas atteinte. Il n'a pas de notion d'observation : chaque
fichier est son propre groupe de répartition.

Deux filtres lui sont propres. Les fichiers qui ne sont pas des photos —
planches botaniques, scans d'herbier, cartes, schémas — sont écartés sur
leur titre ; c'est grossier et assumé comme tel. Et la licence est lue sur
l'URL plutôt que sur le libellé : « CC BY 3.0 us » ou « CC-BY 4.0 Int » se
lisent mal, l'URL jamais.

**L'API limite le débit.** En dessous d'une seconde entre requêtes elle
répond 429. Le connecteur attend et réessaie, puis **laisse l'erreur
remonter** : une source qui tombe doit s'écrire `ÉCHEC` dans le journal, pas
se déguiser en « cette espèce n'a pas d'images ».

## Licences acceptées

Les images sous **CC0 1.0**, **Public Domain Mark** ou **CC BY** (toutes
versions) sont gardées. **CC BY-SA** l'est aussi avec `--allow-sa`, et c'est
ainsi que le jeu est collecté depuis le 6 septembre 2026 : la décision a été
prise au motif qu'un modèle entraîné n'est pas une adaptation des photos, il
n'en reproduit aucune, et que les photos ne sont jamais redistribuées.
Chacune reste attribuée avec sa licence dans `ATTRIBUTIONS.md`. **NC**,
**ND**, licence inconnue ou absente, tout contenu propriétaire ou venu d'un
moteur d'images : refusés, sans exception.

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
