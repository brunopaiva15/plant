# Sourcer les fiches d'entretien

Pipeline local : sitemap RHS → page HTML en cache → Position, sol, pH,
Pests/Diseases, Propagation, Colour & Scent. L'humidité vient du GBIF
et de Wikipedia, pas de la RHS. L'arrosage sort de la règle de séchage.
L'engrais et le rempotage sortent du temps jusqu'à maturité.
Il ne tourne pas dans l'application.

```bash
cd tools/rhs_care
python -m unittest tests.test_light_map tests.test_soil_map tests.test_issue_map tests.test_prop_map tests.test_bloom_map tests.test_humidity_map tests.test_watering_map tests.test_growth_map tests.test_family_map tests.test_hardiness_map
python extract_light.py
python extract_light.py --retry   # fiches RHS sans Position : autre espèce du groupe
python extract_soil.py            # cache d'abord, Soil Types / Moisture / pH
python extract_soil.py --apply    # reprend soil.json
python extract_issues.py          # Pests / Diseases
python extract_issues.py --apply  # reprend issues.json
python extract_prop.py            # Propagation
python extract_prop.py --apply
python extract_bloom.py           # Colour & Scent, colonne Flower
python extract_bloom.py --apply
python extract_humidity.py        # GBIF + Wikipedia → humidité de l'air
python extract_humidity.py --apply
python extract_watering.py        # dryDown + jours dérivés
python extract_watering.py --apply
python extract_growth.py          # Time to Maturity → engrais / rempotage
python extract_growth.py --apply
python extract_family.py          # familles, via l'espèce représentative
python extract_family.py --apply
python extract_indoor.py          # nouveaux profils espèce : le masque Iris Indoor
python extract_indoor.py --apply  # reprend indoor.json
python extract_indoor.py --dry-run --limit 10   # pour essayer
```

Le HTML et les JSON GBIF/Wikipedia restent hors Git (`cache/`).
`light.json`, `soil.json`, `issues.json`, `prop.json`, `bloom.json`,
`humidity.json`, `watering.json`, `growth.json`, `family.json` et
`indoor.json` sont les journaux, lus par
`--apply` pour reposer le Dart sans refaire le réseau. Ne pas relancer
`extract_light.py` après un `--apply` lumière : il relirait la nouvelle
lumière comme valeur actuelle et ferait disparaître les planchers. Une
espèce n'emprunte pas la page d'une autre (`--retry` bySpecies : soi ou
synonyme seulement). Une famille n'est pas un taxon.

`extract_indoor.py` est le seul à **créer** des fiches : celles des espèces
du masque Iris Indoor (`tools/plant_dataset/masque_indoor.txt`) qui n'ont
encore que le profil de leur genre. La fiche part de cet héritage, sans sa
provenance, puis chaque champ repasse par les mappings déjà testés. Deux
verrous : la page doit être celle de l'espèce (son nom, un de ses cultivars,
son synonyme), et une fiche qui ne dit rien de plus que son genre n'est pas
écrite. Il n'écrit que des clés absentes de `bySpecies` : relancé, il ne
touche pas aux fiches déjà posées.
