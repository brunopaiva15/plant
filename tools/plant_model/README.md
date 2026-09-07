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
