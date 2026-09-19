# Couverture des profils d'entretien — priorité V1

Ce document répond à une question différente de [`14-sourcer-les-fiches.md`](14-sourcer-les-fiches.md) : **quels profils faut-il créer en premier ?**

`14-sourcer-les-fiches.md` décrit comment rendre un champ fiable et traçable. Ici, le but est de décider où investir ce travail pour qu'une première version publique d'Auxine soit forte sur les plantes que les utilisateurs possèdent réellement.

## État actuel

La mesure de référence est `test/data/care_coverage_snapshot.json` :

- **33 343 fiches espèce** dans l'encyclopédie ;
- **671 profils d'entretien réellement utilisés** ;
- **280 profils espèce** ;
- **215 profils genre** ;
- **176 profils famille** ;
- résolution actuelle des 33 343 fiches : **278 espèce**, **6 983 genre**, **26 081 famille**, **1 générique**.

La fiche générique est *Callianthe picta*, une classe du modèle sans famille
au catalogue étendu : ni son genre ni sa famille ne répondent pour elle.

Le lot des 242 fiches espèce d'Iris Indoor a été écrit par
`tools/rhs_care/extract_indoor.py` ; la méthode est décrite en phase 10 de
[`14-sourcer-les-fiches.md`](14-sourcer-les-fiches.md).

La cascade reste :

`espèce exacte → genre → famille → catégorie → fallback`

Le nombre de fiches au niveau famille n'est **pas** un KPI à réduire à tout prix. Les plus grosses familles du catalogue étendu — Asteraceae, Orchidaceae, Fabaceae, Poaceae, Cyperaceae — contiennent des milliers d'espèces dont beaucoup ont peu de valeur produit pour Auxine. Créer des profils uniquement pour faire baisser le pourcentage familial ferait travailler sur les mauvais taxons.

## Objectif de la V1 publique

La priorité est d'augmenter la **précision sur les plantes courantes**, pas de maximiser artificiellement le nombre brut de profils.

Cible recommandée :

| Étape | Profils espèce | Profils totaux | But |
|---|---:|---:|---|
| Point de départ | 38 | 429 | couverture taxonomique large |
| Cible P0 + P1 | 113 | 504 | cible recommandée pour la V1 publique |
| Cible P0 à P3 | 158 | 549 | socle populaire + collection + comestible/balcon |
| Aujourd'hui, lot Indoor écrit | 280 | 671 | les espèces qu'Iris Indoor expose |

Le lot Indoor couvre 32 des 40 espèces P0, 22 des 35 P1 et 13 des 25 P2. Les
manquantes ne sont pas des oublis : leur genre répond déjà exactement comme
elles, parce qu'il a été ancré sur leur propre page RHS — *Maranta
leuconeura*, *Strelitzia reginae*, *Chlorophytum comosum*, *Coffea arabica*,
*Dypsis lutescens*, *Ceropegia woodii* sont dans ce cas. Écrire leur fiche
espèce ne ferait qu'une copie de plus à tenir à jour. P3 (aromatiques,
potager, balcon) reste presque entier : il sort du masque intérieur.

Un objectif de **700 profils** reste à portée, mais il ne doit pas être atteint en ajoutant des genres obscurs seulement parce qu'ils couvrent beaucoup d'espèces. Après P0–P3, les ajouts doivent être guidés par l'usage réel, les recherches dans l'app et les erreurs constatées du fallback genre/famille.

## Méthode de priorisation

Les candidats viennent d'abord de `tools/plant_dataset/cible_interieur_500.tsv`, qui contient déjà une sélection très large de plantes d'intérieur et de collection. Cette liste est croisée avec :

1. les profils déjà présents dans `CareProfiles.bySpecies`, `byGenus` et `byFamily` ;
2. les espèces réellement exposées ou collectées par Iris ;
3. le risque qu'un profil de genre soit trompeur pour l'espèce ;
4. des signaux de popularité commerciale européens et suisses ;
5. les usages d'Auxine : plante d'intérieur, balcon, aromatique, potager, collection.

Les signaux commerciaux servent à **prioriser**, pas à définir les besoins botaniques. La RHS indique en 2026 une hausse de 15 % des ventes de plantes d'intérieur dans son retail et cite Monstera puis Dracaena en tête. Feey classe explicitement ses meilleures ventes et cite `Monstera deliciosa` parmi les plantes d'intérieur les plus populaires. PLNTS décrit Philodendron comme l'un de ses groupes les plus populaires et expose notamment `P. melanochrysum`, `P. gloriosum`, `P. scandens` et `P. micans` dans ses sélections courantes.

### Règle de décision

Un profil espèce est prioritaire quand plusieurs de ces critères sont vrais :

- plante très vendue, très connue ou très susceptible d'être ajoutée dans Auxine ;
- besoins sensiblement différents du profil générique de son genre ;
- erreur de soin potentiellement dommageable : eau, lumière, température, dormance, substrat ;
- plante fréquemment cultivée en pot ou en intérieur ;
- espèce déjà reconnaissable par Iris ou très présente dans le catalogue ;
- données suffisamment sourçables pour ne pas créer une fausse précision.

Si deux espèces d'un même genre ont réellement les mêmes besoins dans les champs qu'Auxine affiche, un bon profil de genre reste préférable à deux copies presque identiques.

## P0 — avant la sortie publique

**40 nouveaux profils espèce.** Ce sont les classiques pour lesquels un utilisateur s'attend le plus à une fiche précise.

- `Monstera adansonii`
- `Epipremnum aureum`
- `Scindapsus pictus`
- `Philodendron hederaceum`
- `Philodendron erubescens`
- `Anthurium andraeanum`
- `Alocasia zebrina`
- `Syngonium podophyllum`
- `Aglaonema commutatum`
- `Dieffenbachia seguine`
- `Goeppertia orbifolia`
- `Goeppertia roseopicta`
- `Goeppertia zebrina`
- `Maranta leuconeura`
- `Dracaena marginata`
- `Dracaena fragrans`
- `Chlorophytum comosum`
- `Beaucarnea recurvata`
- `Aspidistra elatior`
- `Yucca gigantea` — alias horticole courant : `Yucca elephantipes`
- `Ficus elastica`
- `Ficus benjamina`
- `Ficus microcarpa`
- `Peperomia obtusifolia`
- `Peperomia argyreia`
- `Peperomia caperata`
- `Begonia maculata`
- `Nephrolepis exaltata`
- `Asplenium nidus`
- `Dypsis lutescens`
- `Howea forsteriana`
- `Chamaedorea elegans`
- `Crassula ovata`
- `Ceropegia woodii`
- `Hoya carnosa`
- `Tradescantia zebrina`
- `Curio rowleyanus`
- `Strelitzia reginae`
- `Strelitzia nicolai`
- `Coffea arabica`

## P1 — immédiatement après P0

**35 profils espèce.** Plantes encore très courantes, familles horticoles importantes et espèces dont les besoins divergent suffisamment pour justifier le niveau espèce.

- `Epipremnum pinnatum`
- `Thaumatophyllum bipinnatifidum` — ancien nom très courant : `Philodendron bipinnatifidum`
- `Philodendron gloriosum`
- `Philodendron verrucosum`
- `Philodendron melanochrysum`
- `Anthurium crystallinum`
- `Anthurium clarinervium`
- `Alocasia macrorrhizos`
- `Alocasia reginula`
- `Alocasia cuprea`
- `Caladium bicolor`
- `Rhaphidophora tetrasperma`
- `Goeppertia makoyana`
- `Goeppertia rufibarba`
- `Stromanthe sanguinea`
- `Ctenanthe burle-marxii`
- `Dracaena reflexa`
- `Dracaena sanderiana`
- `Cordyline fruticosa`
- `Ficus pumila`
- `Begonia rex`
- `Platycerium bifurcatum`
- `Phlebodium aureum`
- `Adiantum raddianum`
- `Rhapis excelsa`
- `Echeveria elegans`
- `Sedum morganianum`
- `Kalanchoe blossfeldiana`
- `Schlumbergera truncata`
- `Opuntia microdasys`
- `Echinocactus grusonii`
- `Gymnocalycium mihanovichii`
- `Codiaeum variegatum`
- `Fittonia albivenis`
- `Oxalis triangularis`

## P2 — collection et besoins particuliers

**25 profils espèce.** Espèces de collection, plantes à forte valeur perçue ou taxons pour lesquels un profil de genre masque facilement un besoin particulier.

- `Monstera dubia`
- `Monstera siltepecana`
- `Philodendron hastatum`
- `Philodendron billietiae`
- `Philodendron squamiferum`
- `Anthurium veitchii`
- `Anthurium warocqueanum`
- `Alocasia baginda`
- `Alocasia lauterbachiana`
- `Aglaonema pictum`
- `Peperomia prostrata`
- `Hoya kerrii`
- `Hoya linearis`
- `Tillandsia ionantha`
- `Guzmania lingulata`
- `Aechmea fasciata`
- `Vriesea splendens`
- `Dendrobium nobile`
- `Ludisia discolor`
- `Vanilla planifolia`
- `Dionaea muscipula`
- `Drosera capensis`
- `Musa acuminata`
- `Gardenia jasminoides`
- `Cyclamen persicum`

## P3 — aromatiques, potager, balcon et petits fruits

**20 profils espèce.** Cette vague élargit Auxine au-delà de la plante d'intérieur sans diluer P0/P1.

- `Salvia rosmarinus`
- `Mentha spicata`
- `Thymus vulgaris`
- `Salvia officinalis`
- `Origanum vulgare`
- `Petroselinum crispum`
- `Coriandrum sativum`
- `Allium schoenoprasum`
- `Anethum graveolens`
- `Capsicum annuum`
- `Solanum melongena`
- `Cucumis sativus`
- `Cucurbita pepo`
- `Fragaria × ananassa`
- `Rubus idaeus`
- `Vaccinium corymbosum`
- `Ribes nigrum`
- `Vitis vinifera`
- `Laurus nobilis`
- `Pelargonium zonale`

## Taxonomie et alias

Le profil doit vivre sous le **nom canonique accepté**, jamais sous un nom de commerce ou un synonyme uniquement parce que c'est le nom que l'utilisateur connaît.

Le catalogue et la recherche peuvent garder les alias. Exemples à traiter explicitement :

- `Yucca elephantipes` → `Yucca gigantea` ;
- `Philodendron bipinnatifidum` → `Thaumatophyllum bipinnatifidum` ;
- les cultivars comme Philodendron 'Birkin', 'Pink Princess', Monstera 'Thai Constellation' ou les hybrides horticoles restent des alias/cultivars et ne doivent pas devenir arbitrairement des espèces botaniques.

Avant d'ajouter une clé à `CareProfiles.bySpecies`, la résoudre contre la taxonomie du catalogue/GBIF et vérifier que la fiche d'encyclopédie emploie la même clé canonique.

Le lot Indoor a donc été écrit sous les noms que l'app résout déjà —
`plants.csv`, `catalog.tsv` et les classes du modèle portent tous
`Philodendron bipinnatifidum`, pas `Thaumatophyllum bipinnatifidum` :
déplacer la clé aurait rendu la fiche inatteignable pour la plante
identifiée. Un cas reste à réconcilier : le catalogue connaît la même
broméliacée sous `Vriesea splendens` (le modèle) et `Lutheria splendens` (le
nom accepté). La fiche vit sous le premier ; `CatalogCareGuide` n'applique
pas `acceptedSpeciesName`, donc le second retombe sur sa famille.

## Définition de « terminé » pour un nouveau profil

Un profil P0–P3 n'est pas terminé parce qu'un bloc `CareProfile(...)` compile. Il doit :

1. être attaché au nom canonique utilisé par le catalogue ;
2. améliorer réellement le profil hérité du genre — pas le recopier à l'identique ;
3. porter `sourcing` **champ par champ** selon `14-sourcer-les-fiches.md` ;
4. conserver les champs non vérifiés comme estimés ou dérivés, jamais comme sourcés ;
5. passer les tests de cohérence de `care_profile_test.dart` et `care_guide_test.dart` ;
6. mettre à jour `test/data/care_coverage_snapshot.json` et relire le diff ;
7. ajouter un test de référence quand le profil tranche un genre hétérogène ou une règle dangereuse.

## Ce qu'il ne faut pas faire

- Ne pas créer 30 000 blocs indépendants à la main.
- Ne pas transformer chaque espèce du catalogue étendu en profil spécifique uniquement pour afficher « espèce » dans la provenance.
- Ne pas dupliquer un profil de genre quand aucune donnée fiable ne justifie une différence.
- Ne pas utiliser la popularité commerciale comme source botanique.
- Ne pas faire passer une valeur héritée ou dérivée pour une mesure propre à l'espèce.

À terme, Auxine peut produire des dizaines de milliers de **profils résolus uniques** par composition :

`famille → ajustements genre → ajustements espèce → données sourcées par champ`

Cela donne une fiche finale propre à chaque taxon sans maintenir 30 000 copies complètes de `CareProfile`.

## Sources de priorisation

### Interne

- `lib/data/species/care_profiles.dart` — profils réellement définis ;
- `test/data/care_coverage_snapshot.json` — mesure de couverture ;
- `tools/plant_dataset/cible_interieur_500.tsv` — univers prioritaire intérieur/collection ;
- `assets/model/model.json` — espèces exposées par Iris.

### Externe — signaux de popularité, pas sources de soin

- RHS, prévisions 2026 : https://www.rhs.org.uk/press/releases/2026-to-see-rise-of-tabletop-veg-and-%E2%80%98in-and-out%E2%80%99
- Feey, best-sellers : https://feey.ch/collections/bestseller
- PLNTS, Philodendron : https://plnts.com/en/shop/all-plnts/plantfamily%3Aphilodendron

Ces pages sont datées/volatiles. Elles servent à établir la priorité produit au moment de la préparation de la V1 ; elles ne doivent jamais alimenter directement les champs d'entretien.
