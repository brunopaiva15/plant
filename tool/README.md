# Outils de construction du catalogue d'espèces

Le catalogue hors ligne de Flora a deux étages :

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

# 3. Moissonner les espèces et leurs noms (~45 min à trois processus)
python3 tool/harvest_species.py /tmp/notable.txt /tmp/harvest.tsv

# 4. Filtrer, choisir le nom principal par langue, écrire l'actif
python3 tool/build_species_catalog.py /tmp/harvest.tsv /tmp/genus_family.json \
    assets/species/catalog.tsv
```

L'étape 3 est reprenable : elle note les genres traités dans
`<sortie>.done` et saute ceux-là au relancement. Pour aller plus vite, on
découpe la liste de genres en trois et on lance trois processus vers des
fichiers de sortie distincts, puis on les concatène.

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
