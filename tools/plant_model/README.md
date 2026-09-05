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

## Ce que fait la recette

1. **Chargement en mémoire** : chaque image est décodée une seule fois, en
   256×256 uint8. Décoder les JPEG à chaque époque ferait passer l'essentiel
   du temps dans le décodeur.
2. **Augmentation** : recadrage aléatoire en 224, miroir horizontal, légère
   variation de lumière et de saturation. Pas de rotation forte : sur une
   photo, un pot est droit.
3. **Transfert** : MobileNetV3-Small pré-entraîné ImageNet, tête remplacée,
   entraînée seule d'abord, puis les 60 dernières couches dégelées à
   faible taux d'apprentissage.
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
