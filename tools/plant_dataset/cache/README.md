# Ce qui survit au jeu de données

`dataset/` n'est pas versionné : 236 000 images, 6,5 Go. Trois fichiers en
sont extraits ici parce qu'ils coûtent des heures à reconstruire et pèsent
moins d'un mégaoctet.

| Fichier | Ce que c'est |
|---|---|
| `species.json` | le taxon GBIF de chaque nom du catalogue, 1 685 résolus sur 1 688 |
| `species_inat.json` | le taxon iNaturalist, 868 résolus sur 886 demandés |
| `stats.json` | l'état du jeu au 7 septembre 2026 : 1 513 espèces, 235 909 images gardées |

Pour repartir d'ici, les recopier dans `dataset/` avant de lancer
`build_dataset.py` : les noms déjà résolus ne repassent pas par le réseau.
Une entrée `null` n'est jamais mémorisée comme un échec, donc un nom
irrésolu sera réessayé.
