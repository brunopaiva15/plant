# Outils de construction du catalogue d'espèces

Le catalogue hors ligne d'Auxin a deux étages :

| Étage | Fichier | Contenu | Rôle |
|---|---|---|---|
| Trié à la main | `lib/data/species/species_catalog.dart` | ~300 espèces, avec catégorie | Parcours par thème, fiches d'entretien |
| Étendu | `assets/species/catalog.tsv` | ~30 000 espèces, sans catégorie | Recherche hors ligne |

Au-delà, la recherche GBIF en ligne couvre les ~450 000 espèces de plantes
restantes. L'étage étendu existe pour qu'un utilisateur hors réseau trouve
« edelweiss », « stella alpina » ou « Gelber Enzian » sans rien télécharger.

## Sources et licences

- **Wikidata** — noms scientifiques et noms vernaculaires en fr/de/it/en.
  Domaine public (CC0), aucune contrainte d'attribution, mais l'écran
  « À propos » les cite tout de même.
- **GBIF Backbone Taxonomy** — correspondance genre → famille. CC BY 4.0.

Aucune des deux ne facture ni ne demande de clé. Les scripts s'annoncent avec
un `User-Agent` identifiable, comme les deux services le demandent.

## Régénérer le catalogue

```bash
# 1. Genres de plantes et leur famille, depuis GBIF (~2 min)
python3 tool/fetch_genera.py /tmp/genus_family.json /tmp/all_genera.txt

# 2. Écarter les genres sans article dans nos langues (~3 min)
python3 tool/screen_genera.py /tmp/all_genera.txt /tmp/notable.txt

# 3. Moissonner les espèces et leurs noms (~45 min à trois processus).
#    Le troisième argument est indispensable : il apparie chaque genre à sa
#    famille GBIF, ce qui écarte les homonymes d'autres règnes.
python3 tool/harvest_species.py /tmp/notable.txt /tmp/harvest.tsv /tmp/genus_family.json

# 4. Filtrer, choisir le nom principal par langue, écrire l'actif
python3 tool/build_species_catalog.py /tmp/harvest.tsv /tmp/genus_family.json \
    assets/species/catalog.tsv
```

L'étape 3 est reprenable : elle note les genres traités dans
`<sortie>.done` et saute ceux-là au relancement. Pour aller plus vite, on
découpe la liste de genres en trois et on lance trois processus vers des
fichiers de sortie distincts, puis on les concatène.

## Les homonymes d'autres règnes

Un nom de genre n'est pas unique entre les règnes : « Batis » est un arbuste
halophile et un gobe-mouches africain, « Oenanthe » une ombellifère et un
traquet, « Glaucidium » une renonculacée et une chevêchette, « Morelia » une
rubiacée et un python. Moissonnée par nom de genre seul, la première version
du catalogue a fait entrer environ 160 oiseaux, poissons et papillons, avec
la famille de la plante homonyme. La moisson exige désormais que le genre
Wikidata remonte à une famille du même nom que celle donnée par GBIF, et le
test de l'actif vérifie qu'aucun de ces noms n'y figure.

## Ce que fait le filtre

Wikidata répète le nom scientifique en guise de libellé quand aucun nom
courant n'existe, et range parfois des synonymes latins parmi les alias.
`build_species_catalog.py` écarte donc toute valeur qui est un binôme latin,
reconnue par son genre (présent dans l'ossature GBIF) ou par sa morphologie
(terminaisons `-us`, `-folia`, `-ensis`…). Une espèce sans aucun nom courant
dans les quatre langues n'entre pas dans le catalogue : elle n'aiderait
personne à chercher, et la recherche GBIF la couvre déjà.

Le test `test/data/species_catalog_asset_test.dart` vérifie l'actif produit :
volume, absence de doublons, absence de faux noms vernaculaires, et présence
de quelques espèces témoins.

# La plante qui pousse (écran de bienvenue)

`build_monstera.py` construit l'icône de l'application : la scène, les
matériaux « pâte à modeler », la caméra orthographique et l'éclairage studio.
`grow_monstera.py` reprend tout cela et rend la même plante à quarante âges,
de la terre nue à l'adulte ; `pack_growth.py` en fait l'image animée que joue
le premier écran de l'onboarding. Seule la plante change d'une image à
l'autre — la dernière est exactement l'icône.

Ce qui bouge entre deux images vient de la vraie plante : les feuilles sortent
l'une après l'autre, la plus vieille d'abord ; chacune émerge en fuseau
presque vertical, étroite et entière ; elle s'allonge, s'écarte, s'élargit,
puis se découpe — fentes d'abord, fenestrations ensuite. Une jeune feuille de
Monstera n'a ni fente ni trou, ils viennent avec l'âge.

Le fond est transparent et sans ombre portée : l'ombre au sol et le
flottement sont dessinés par l'application, qui les accorde à son thème.

```bash
# ~15 min sur quatre cœurs (Cycles, CPU)
blender -b -noaudio -P tool/grow_monstera.py -- 40 1024 40 /tmp/pousse
python3 tool/pack_growth.py /tmp/pousse assets/onboarding/pousse.webp --fps 14
```

La caméra est cadrée une fois pour toutes sur la plante adulte : sans cela,
le cadrage automatique suivrait la plante qui grandit et elle semblerait
immobile pendant que le monde rétrécit autour d'elle.
