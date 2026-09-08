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
pip install 'tensorflow[and-cuda]'          # embarque CUDA et cuDNN
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
| `--ram-budget` | avec 32 Go de mémoire vive, précharger une partie du jeu évite de relire les JPEG à chaque époque. |

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

## Choisir les seuils de repli

`model.json` contient, pour chaque couple (seuil, marge), le taux de
réponses acceptées et la précision sur ces réponses. On retient le couple
dont la précision dépasse 97 % avec le taux d'acceptation le plus élevé,
et on le reporte dans `FallbackPolicy`
(`lib/domain/identification/identification_policy.dart`).
