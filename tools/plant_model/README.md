# Modèle de reconnaissance d'espèces

Entraîne le classifieur embarqué dans l'app et l'exporte en TensorFlow Lite.
La vue d'ensemble est dans
[`docs/09-plant-recognition.md`](../../docs/09-plant-recognition.md) ; le jeu
d'images est construit par [`../plant_dataset`](../plant_dataset/README.md).

## Installation

```bash
cd tools/plant_model
python3 -m pip install -r requirements.txt   # tensorflow-cpu, numpy, Pillow
```

## Entraîner

```bash
python3 train.py --dataset ../plant_dataset/dataset --out ../../assets/model
```

Sur une machine sans carte graphique, une passe complète dure des heures et
peut être interrompue. La forme reprenable :

```bash
python3 train.py --dataset ../plant_dataset/dataset --out ../../assets/model \
  --backbone large --head-epochs 40 --fine-epochs 12 \
  --feature-cache .cache/features --checkpoint .cache/ckpt --version 6
```

Relancer la même ligne reprend au dernier point de sauvegarde. Avec
`--fine-epochs 0`, l'entraînement est sauté : le modèle est évalué et
exporté depuis le point de sauvegarde tel quel.

**Reprendre n'est pas prolonger** : seuls les poids sont restaurés, Adam
repart de zéro, et ajouter des époques à un réseau déjà convergé lui coûte
des points (§ 13.6 de `docs/09`). Le point de sauvegarde est par ailleurs
réécrit à chaque époque, donc une reprise efface ce dont elle est partie.

Sorties, directement dans les assets de l'app :

| Fichier | Contenu |
|---|---|
| `plants.tflite` | les poids, float16 |
| `labels.txt` | un identifiant interne par ligne, dans l'ordre des sorties |
| `model.json` | version, taille d'entrée, empreinte SHA-256, métriques, courbe seuil / repli |

## Entraîner sur une carte graphique (Windows + RTX, via WSL2)

Une passe complète prend une dizaine d'heures sur quatre cœurs sans carte,
et de l'ordre d'une heure sur une RTX 2070 Super. Tout le reste du travail
sur le modèle en dépend : c'est la première chose à monter.

**TensorFlow n'a plus de support GPU natif sous Windows depuis la 2.10.**
La route qui marche est WSL2, où le pilote Windows est vu par Linux sans
installer de pilote côté WSL :

```bash
# Sous Windows, dans PowerShell
wsl --install -d Ubuntu

# Puis, dans Ubuntu
sudo apt update && sudo apt install -y python3-pip python3-venv
python3 -m venv ~/venv && source ~/venv/bin/activate
pip install -r requirements-gpu.txt         # tensorflow[and-cuda] : CUDA et cuDNN inclus
python3 -c "import tensorflow as tf; print(tf.config.list_physical_devices('GPU'))"
```

La dernière ligne doit afficher une carte. `train.py` le dit aussi au
démarrage : sans carte visible, il l'annonce au lieu de tourner dix fois
plus lentement en silence.

```bash
python3 train.py --dataset ../plant_dataset/dataset --out ../../assets/model \
  --backbone large --batch 64 --mixed-precision \
  --head-epochs 40 --fine-epochs 12 \
  --feature-cache .cache/features --checkpoint .cache/ckpt --version 7
```

| Option | Pourquoi sur GPU |
|---|---|
| `--mixed-precision` | calcul en float16 : les cœurs tensor des RTX 20xx et au-delà doublent à peu près le débit, et la mémoire libérée autorise des lots plus gros. Inutile, voire lent, sur processeur. |
| `--batch 64` | la carte a 8 Go ; un lot plus gros l'occupe mieux. À monter tant que la mémoire suit. |
| `--ram-budget` | sans effet sur le jeu complet : 232 000 images en 256×256 font 45 Go, donc au-delà de toute mémoire vive raisonnable, et le préchargement est tout ou rien. À laisser tel quel. |

L'export TFLite se fait toujours en float32 : le convertisseur ne sait pas
convertir un graphe float16, donc le réseau est reconstruit avant
l'évaluation et l'export. Les chiffres de `model.json` sont ceux du fichier
livré, pas ceux d'un modèle qui lui ressemble.

**Le goulot se déplace.** Mesuré ici sur quatre cœurs, le tuyau de données
rend 630 images/s cache froid quand le réseau en avale 93 : le décodage
JPEG est huit fois trop rapide pour gêner. Sur une carte à 1 000 images/s,
ce rapport s'inverse et c'est le processeur qui fait attendre. Un i7-9700K
(8 cœurs) tient largement ; en dessous, il faut surveiller. **Et le jeu doit
être sur un SSD** : 290 000 fichiers lus dans un ordre différent à chaque
époque sont le pire cas pour un disque à plateaux.

**Mesurer la machine avant d'y déplacer le jeu.** Copier des dizaines de
gigaoctets pour découvrir qu'une carte n'apporte rien, c'est une journée
perdue. `../plant_dataset/echantillon.py` prélève quelques centaines de
mégaoctets — mêmes images, même tuyau, même recette, seul le nombre de
classes change — et cela suffit à comparer deux machines : à 320 px le
dorsal coûte environ 0,45 GFLOP par image contre 0,01 pour la tête, si bien
qu'un débit lu sur 120 classes décrit la machine à quelques pour cent près.
Lancer ensuite `train.py --steps-per-epoch 60 --fine-epochs 2 --ram-budget 0`
sur l'échantillon et lire le `s/step` de la **seconde** époque : la première
paie la compilation du graphe.

**Le jeu d'images n'est pas dans Git** (15 Go). Il se reconstruit avec
[`../plant_dataset`](../plant_dataset/README.md), en parts parallèles :
comptez trois heures sur quatre cœurs, moins sur huit. Recopier d'abord
`tools/plant_dataset/cache/*.json` dans `dataset/`, ce sont des heures de
résolution de noms déjà faites.

## Options

| Option | Défaut | Sens |
|---|---|---|
| `--batch` | 32 | |
| `--backbone` | `small` | `small` (MobileNetV3-Small, v1 à v3) ou `large` (v4 : trois fois plus de calcul, mieux sur les espèces proches) |
| `--input-size` | 224 | côté de l'entrée du réseau ; le chargement suit à la même marge de recadrage. 320 double le calcul sur le téléphone sans changer la taille du `.tflite` — les poids ne dépendent pas de la résolution |
| `--head-epochs` | 4 | époques avec le réseau gelé |
| `--fine-epochs` | 12 | époques de réglage fin, arrêt anticipé sur la validation |
| `--min-train` | 25 | une classe sous ce seuil est écartée du modèle |
| `--min-val` | 3 | une classe sans validation ne peut pas être mesurée |
| `--unfreeze` | 60 | couches dégelées en fin de réseau |
| `--dropout` | 0.3 | |
| `--version` | `1` | version écrite dans `model.json` |
| `--checkpoint DIR` | | poids sauvés toutes les 200 lots et à chaque époque ; relancer avec le même dossier reprend là |
| `--feature-cache DIR` | | active les vecteurs du réseau gelé pour la phase de tête (voir ci-dessous) |
| `--mixed-precision` | non | calcul en float16 ; double le débit sur une carte à cœurs tensor, inutile sur processeur |
| `--steps-per-epoch N` | | lots par époque : des époques courtes, donc des points de sauvegarde fréquents |
| `--ram-budget` | 5 | Go de préchargement au plus ; au-delà, les images sont relues des fichiers |

## Livrer un modèle : retailler, et les masques de lieu

`retailler.py` réexporte un modèle entraîné en ne gardant qu'une partie de ses
classes. Ce n'est pas un réentraînement : les colonnes non gardées de la
dernière couche sont supprimées, et le fichier livré rétrécit d'autant — la
tête fait `960 × classes × 2 octets`.

```bash
python3 retailler.py --poids ~/plant-data/ckpt/fine.weights.h5     --etiquettes ~/plant-data/modele/labels.txt     --garder ../plant_dataset/masque_indoor.txt     --dataset ../plant_dataset/dataset --out ~/plant-data/indoor --version Indoor
```

**Un modèle d'union** garde les classes de plusieurs lieux et dit lesquelles
appartiennent à qui. `--garder` devient inutile : l'union des masques fait la
liste.

```bash
python3 retailler.py --poids … --etiquettes … --dataset … --out … --version 9     --masque indoor=../plant_dataset/masque_indoor.txt     --masque outdoor=../plant_dataset/masque_outdoor.txt
```

`model.json` porte alors un objet `masks`, et l'application renormalise ses
sorties sur les classes du lieu au moment de l'inférence : `exp(zᵢ) /
Σ_gardées exp(zⱼ)`, c'est-à-dire **exactement ce que rendrait ce modèle
retaillé sur ce masque**. Deux fichiers coûteraient deux fois le même dorsal
pour deux dernières couches — voir le § 14 de `docs/09-plant-recognition.md`.

Un modèle sans objet `masks` se comporte comme avant : aucun masque, le
contexte reste sans effet.

## Ce que fait la recette

1. **Chargement en mémoire** : chaque image est décodée une seule fois, en
   256×256 uint8 — tant que le jeu tient dans `--ram-budget`. Au-delà, les
   images sont relues à chaque époque, et ce n'est pas grave : mesuré sur
   quatre cœurs, le tuyau de données rend 630 images/s cache froid, quand le
   réseau, lui, en avale 70. Le décodeur n'est pas le goulot à cette taille,
   le réseau l'est. Le préchargement ne sert que les petits jeux, où il
   économise quelques minutes.
2. **Augmentation** : recadrage aléatoire en 224, miroir horizontal, légère
   variation de lumière et de saturation. Pas de rotation forte : sur une
   photo, un pot est droit.
3. **Transfert** : MobileNetV3 (Small jusqu'à la v3, Large depuis la v4)
   pré-entraîné ImageNet, tête remplacée,
   entraînée seule d'abord, puis les 60 dernières couches dégelées à
   faible taux d'apprentissage. Avec `--feature-cache`, la phase de
   tête ne repasse pas les images dans le réseau à chaque époque : le
   réseau est gelé, ses sorties ne changent pas, on les calcule une fois
   (un vecteur de 960 nombres par image) et la tête s'entraîne dessus en
   quelques minutes. Sur le jeu de la v6, cela remplace quatre époques de
   trente minutes par une passe de vingt minutes — et la tête peut aller
   jusqu'à convergence, ce qui donne au réglage fin un meilleur départ. Les
   vecteurs sont ceux du carré central, sans augmentation ; le réglage fin,
   lui, garde toutes les siennes.
4. **Déséquilibre** : poids par classe inversement proportionnels au
   nombre d'images. Sans cela le modèle apprend à répondre l'espèce la
   plus fréquente.
5. **Évaluation** sur le jeu de test, jamais vu : top-1, top-3, macro-F1,
   et la **courbe seuil / taux de repli** qui sert à régler `FallbackPolicy`
   côté application.

Les répartitions viennent de `splits.csv` : les photos d'une même
observation sont toutes du même côté, sinon la précision mesurée serait
un mensonge.

## Sur quoi le modèle se trompe

```bash
python3 confusions.py --dataset ../plant_dataset/dataset --model ../../assets/model
```

Sépare les erreurs entre celles qui restent dans le genre — attendues, deux
espèces proches, et l'écran propose cinq candidats — et celles qui en
sortent, qui sont de vrais défauts de collecte. Rend les paires de genres
responsables et les espèces les plus ratées avec ce qu'on leur répond à la
place. Voir le § 12.4 de `docs/09`.

## Ce que rend le modèle sur les plantes d'appartement

```bash
python3 interieur.py --couverture          # sans TensorFlow ni jeu d'images
python3 interieur.py --dataset ../plant_dataset/dataset --model ../../assets/model
```

Le top-1 publié est une moyenne sur toutes les classes exposées — leur nombre
est dans `model.json` —, dont la plupart sont sauvages. L'application sert
d'abord les 167 noms de `phase1_species.txt`.
L'outil rend deux choses qui ne se remplacent pas : la **couverture** —
combien de ces plantes le modèle sait seulement nommer, une classe absente
étant un échec certain et invisible dans toute mesure de précision — puis le
**top-1 sur les images de test de ces espèces**, avec le catalogue entier
puis masqué aux seules plantes d'intérieur. L'écart entre les deux est ce
que l'étendue du catalogue coûte à celui qui photographie son salon. Voir
le § 12.12 de `docs/09`.

## Choisir les seuils de repli

`model.json` contient, pour chaque couple (seuil, marge), le taux de
réponses acceptées et la précision sur ces réponses. On reporte le couple
retenu dans `FallbackPolicy`
(`lib/domain/identification/identification_policy.dart`).

**La règle écrite ici — « précision au-dessus de 97 % » — n'est pas celle
qu'on applique**, et il vaut mieux le dire que laisser croire le contraire.
Elle est atteignable : sur l'Iris 8, le seuil 0,95 rend **98,2 % de
précision**. Mais il n'accepte plus que **32,6 %** des réponses — deux photos
sur trois partiraient chez Pl@ntNet, aux frais du quota mensuel. Le seuil
livré est 0,70 (marge 0,25) : **54,9 % d'autonomie pour 91,3 % de précision**.

Ces quatre chiffres se relisent dans le `threshold_curve` du `model.json`
livré plutôt qu'ici — c'est lui qui fait foi, et il change à chaque version.

C'est donc un arbitrage assumé, sept points de justesse contre vingt-deux
d'autonomie, et non l'application de la règle ci-dessus. La règle réelle,
celle du § 6.7 de `docs/09`, porte sur les versions et non sur les seuils :
**à autonomie égale, prendre la version la plus juste.** C'est elle qui a
fait remonter le seuil à 0,70 pour l'Iris 7 — il y rendait l'autonomie qu'avait
la v6 à 0,60 (47 %) avec 85,9 % de précision au lieu de 82,8 %. L'Iris 8 l'a
gardé tel quel et rend davantage des deux côtés (§ 6.7 bis de `docs/09`).

## Iris 10 : le banc, puis le teacher

Ces deux outils ne servent pas le classifieur : ils préparent Iris Core
(`docs/14-iris-indoor-outdoor.md`, § 20 pour l'ordre, § 20 bis pour le
détail). Aucun ne demande d'architecture nouvelle ; ils demandent du calcul
et une discipline.

### Le jeu de mesure, figé une fois pour toutes

```bash
python3 benchmark.py --dataset ~/plant-data/dataset-v8-indoor --out benchmark.csv
```

Cinq tranches — `indoor`, `outdoor`, `multi`, `ood_plante`, `ood_autre` —,
graine 20260919, échantillonnage **par groupe** pour qu'une observation à
plusieurs photos parte entière dans une tranche. Le manifeste ne se
régénère pas pour arranger un modèle : c'est ce qui a manqué pendant huit
versions, où chaque entraînement produisait son propre test et où « gagner
trois points » pouvait n'être qu'un test plus facile.

### Le teacher, passé une fois sur le corpus

BioCLIP 2.5 définit l'espace d'Iris Core. Il tourne **une fois**, et ses
vecteurs servent ensuite toutes les distillations sans jamais le rappeler.

**Un venv à part.** `tensorflow[and-cuda]` et PyTorch embarquent chacun
leurs CUDA et cuDNN ; les mettre ensemble rejoue en plus gros l'accident de
`tensorflow-cpu` installé à côté de la version GPU.

```bash
python3 -m venv ~/venv-torch && source ~/venv-torch/bin/activate
pip install -r requirements-bioclip.txt
```

**Et l'interpréteur en chemin absolu dès qu'on passe par `tmux`**, qui ouvre
un shell neuf n'héritant d'aucun venv. Le `source` dans `.bashrc` que
conseille `docs/11` ne marche plus à deux environnements : il déposerait
`bioclip.py` dans le venv TensorFlow, où il meurt sur `No module named
'torch'`. Les lignes ci-dessous sont donc écrites en chemin absolu.

Puis, dans l'ordre :

```bash
# 1. ce que la passe coûtera, avant de la lancer
~/venv-torch/bin/python3 bioclip.py mesure --dataset ~/plant-data/dataset-echantillon

# 2. le corpus — 7,5 h, donc dans un tmux (reprenable : relancer la même
#    ligne continue)
tmux new -s bioclip
~/venv-torch/bin/python3 -u ~/plant/tools/plant_model/bioclip.py cache \
  --dataset ~/plant-data/dataset-v8-indoor \
  --cache ~/plant-data/bioclip \
  2>&1 | tee ~/plant-data/bioclip-cache.log

# 3. les références d'espèces, dans le même espace — quelques minutes
~/venv-torch/bin/python3 bioclip.py textes --cache ~/plant-data/bioclip
~/venv-torch/bin/python3 bioclip.py centroides \
  --dataset ~/plant-data/dataset-v8-indoor --cache ~/plant-data/bioclip
```

Sous WSL, régler la mise en veille de Windows sur « jamais » avant de partir :
une VM suspendue en pleine passe ne rend pas toujours son contexte CUDA au
réveil. Le cache étant incrémental, ça se rattrape — mais autant ne pas avoir
à le rattraper.

`mesure` d'abord, et ce n'est pas une politesse : un ViT-H/14 n'a pas le
débit d'un MobileNet, le chiffre ne se devine pas depuis les 831 img/s de
`train.py`, et une passe qui dépasse la nuit se découpe en parts **avant**
d'être lancée. La commande chronomètre cent images — premier lot jeté, il
paie les noyaux CUDA — extrapole au corpus, et affiche la VRAM réservée :
c'est elle qui décide du `--batch`, comme à l'entraînement en 320 px.

| option | pourquoi |
|---|---|
| `--batch 32` | 8 Go de VRAM face à un ViT-H/14 ; c'est une décision, pas un accident |
| `--fils 6` | fils de décodage ; en série la carte n'était occupée que 53 % du temps |
| `--part i --parts n` | deux machines ou deux nuits ; les parts sont entrelacées, pas contiguës, parce que `splits.csv` est rangé par espèce |
| `--fragment 8192` | vecteurs par fichier `.npy` : 16 Mo, une coupure ne perd jamais plus que ça |
| `--splits train` | pour `centroides` : une référence tirée des images de test rendrait le banc faux |

**La clé du cache porte le prétraitement.** Le dossier reçoit un
`signature.json` — teacher, dimension, taille d'entrée, normalisation — et
une passe d'une autre signature refuse d'écrire dedans. Un cache mélangé ne
se voit pas à l'usage : il rend des vecteurs, simplement ils ne décrivent
pas tous le même espace. C'est le seul défaut de cette étape qui ne se
rattrape pas par une relecture.

Les vecteurs sont rangés **normalisés**, en `float16` : la perte cosinus de
l'étape 5 et le k-plus-proches-voisins de l'étape 6 ne lisent que la
direction. 1 024 dimensions à deux octets font 2 Ko par image, soit 1,6 Gio
pour les 794 000 images d'entraînement et 2,0 Gio pour tout le corpus.

Et les deux commandes de références relisent la signature du cache au lieu
d'en refaire une : des vecteurs d'espèces d'une version du teacher et des
vecteurs de photos d'une autre ne vivent pas dans le même espace.

## Un second avis vaut-il ses mégaoctets ?

```bash
CUDA_VISIBLE_DEVICES= python3 plantnet_avis.py --banc benchmark.csv \
  --iris ../../assets/model --plantnet ~/plant-data/plantnet.tflite
```

`CUDA_VISIBLE_DEVICES=` parce que tout se calcule ici sur processeur, mais
que `prepare()` passe par des ops TensorFlow : voyant une carte, TensorFlow
les y place et réserve la mémoire qu'il trouve. Lancée à côté d'un
`bioclip.py cache`, la mesure ferait tomber la passe plutôt que l'inverse.

Embarquer `litert-community/PlantNet-300K-ResNet18-LiteRT` à côté d'Iris
coûterait **47 Mo** dans une application qui en porte 9,0. Ce script dit ce
que ça achèterait, avant de le demander à qui que ce soit.

Il rend deux chiffres qui ne se remplacent pas :

- **la couverture**, sans une seule inférence — parmi les espèces qu'Iris ne
  nomme pas, celles que PlantNet nomme. C'est la seule chose qu'un second
  avis puisse *ajouter* ;
- **la justesse à armes égales** — les deux modèles sur les **mêmes images**
  du banc, restreints aux espèces que les deux connaissent, en deux lectures
  (sorties masquées et sorties entières) comme au § 6.7 bis de `docs/09`.

Ce qu'on sait déjà sans inférer : **123 espèces communes** sur les 1 569
d'Iris 9, **43 sur les 363** du masque intérieur, et **899 espèces** que
PlantNet nomme et pas Iris. Sur les neuf espèces qu'Iris a ratées dans les
retours d'utilisateurs, PlantNet en connaît **une**.

**Les deux chaînes de prétraitement ne sont pas la même**, et c'est le piège
de ce script : une image mal préparée ne fait pas planter un modèle, elle lui
fait rendre des réponses fausses (§ 6.2).

| | Iris 9 | PlantNet-300K |
|---|---|---|
| entrée | 320 px, NHWC | 224 px, **NCHW** |
| valeurs | `uint8` 0-255, normalisation dans le graphe | `float32`, normalisation **ImageNet** ici |
| sortie | probabilités | **logits** — softmax ici |

Le carré central puis la réduction restent communs : `prepare()` sert aux
deux, à des tailles différentes.

Les étiquettes viennent du `plantnet300K_species_id_2_name.json` que
`plantnet300k.py` télécharge déjà, et l'ordre des classes est celui des
identifiants d'espèce **triés comme des chaînes** (`ImageFolder`). Trier en
numérique décalerait tout sans rien signaler. Enfin, 1 081 sorties ne font
que **1 022 binômes** : les probabilités des doublons sont additionnées, pas
maximisées.

La chaîne a été vérifiée de bout en bout sur l'image de la carte du modèle —
*Calendula officinalis* à 0,95, avec *Calendula stellata* en quatrième. Un
décalage d'étiquettes aurait rendu une espèce au hasard, pas une grappe de
genre.

## La porte C : l'espace contre le softmax

```bash
python3 voisins.py --banc benchmark.csv --cache ~/plant-data/bioclip \
  --iris ../../assets/model
```

La plus fondamentale des cinq portes du § 19 de `docs/14` : **nommer par la
référence la plus proche vaut-il mieux qu'une couche de sortie apprise ?**
Tant que ce n'est pas mesuré, la distillation des étapes 5 et 6 est un pari.

Elle ne coûte presque rien, et c'est tout l'intérêt. Les images du banc sont
des images de test, donc `bioclip.py cache` les a déjà encodées : le teacher
n'a rien à recalculer, et classer une photo devient un produit scalaire.
Quelques secondes de numpy, sans carte graphique.

Deux lectures, comme au § 6.7 bis :

- **à armes égales** — références restreintes aux classes qu'Iris expose.
  « L'espace fait-il aussi bien que la tête apprise ? », et il part avec un
  handicap : il n'a jamais vu nos étiquettes ;
- **répertoire entier** — une référence par espèce du catalogue, ~5 800 au
  lieu de 1 569. C'est ce que la tranche `ood_plante` interroge, là où Iris
  est à zéro par construction.

Le compte rendu affiche toujours combien d'images sont **nommables** par le
jeu de références utilisé : un top-1 sans son dénominateur ne dit pas si le
modèle s'est trompé ou n'avait aucune chance.

**Aucun seuil n'est cité.** Un cosinus n'est pas une probabilité, et le 0,70
d'Iris a été réglé sur ses sorties (§ 3.1). Top-1 et top-3 se comparent sans
calibration ; l'autonomie est rendue sous `--temperature`, comme une courbe à
lire, jamais comme un chiffre à publier.

Trois pièges tenus par des tests : deux références d'une même espèce ne font
qu'une classe (sinon `monstera-deliciosa#captive` compterait une bonne
réponse comme fausse), elles sont prises **au mieux** et non additionnées
— additionner favoriserait l'espèce qui a le plus de vues —, et une image
absente du cache est écartée avec son compte, jamais comptée fausse.

### Le terrain adverse

```bash
python3 plantnet_avis.py --terrain plantnet --combien 2000 \
  --iris ../../assets/model --plantnet ~/plant-data/plantnet.tflite
```

Mesurer sur notre banc penche en notre faveur : il est bâti sur notre corpus
GBIF/iNaturalist, donc ses photos ressemblent à celles qui ont entraîné Iris.
La mesure symétrique fait jouer les deux modèles sur le **jeu de test de
PlantNet-300K**, où c'est lui qui est à domicile — 18 396 images des 123
espèces communes, dont **93 % de gros plans** de fleur ou de feuille, ce
qu'Iris n'a jamais appris.

Rien à télécharger : l'archive Zenodo fait 29,5 Gio, mais un zip se lit par
plages et le chemin d'une image se déduit de ses métadonnées
(`plantnet_300K/images/{split}/{species_id}/{clé}.jpg`). Seules les images
tirées sont cherchées. Passer `--archive` sur un zip local si on l'a
téléchargé : c'est alors instantané.

**Le split de test de PlantNet, jamais son entraînement** — le faire jouer
sur des images qu'il a apprises ne dirait rien. Et le filtre de licence est
celui de la collecte (§ 4.1) : il ne change presque rien ici, mais une mesure
qui s'autoriserait des images inutilisables mentirait sur ce qui est
reproductible.

Les lectures sont **résistantes** : deux mille requêtes par plage d'affilée,
il y en a toujours une qui casse. La lecture est retentée, l'archive rouverte
en dernier recours, et une image qui résiste est **sautée avec son compte** —
un top-1 calculé sur moins d'images qu'annoncé serait un mensonge tranquille.
