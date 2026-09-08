# 10 — Entraîner le modèle sur son propre poste

> Procédure suivie de bout en bout, de Windows nu au `.tflite` livré.
> Machine de référence : Windows + RTX 2070 Super (8 Go) + i7-9700K (8 cœurs).
> Compter **une demi-journée** la première fois, dont l'essentiel en attente.

Le modèle v6 a été entraîné sur quatre cœurs sans carte graphique : neuf
heures 47, par tranches de dix minutes, sur une machine recyclée dès qu'elle
s'endormait. Sur une carte grand public, la même passe coûte de l'ordre
d'une heure. C'est ce qui rend la v7 possible : quatre recettes dans un
après-midi au lieu d'une par nuit.

## Avant de commencer

| | |
|---|---|
| Disque | **40 Go libres**, sur un **SSD**. Le jeu fait 15 Go et ses 290 000 fichiers sont relus dans un ordre différent à chaque époque : sur un disque à plateaux, c'est lui qui devient le goulot, et de loin. |
| Carte | NVIDIA avec pilote Windows à jour. Rien à installer côté Linux : WSL2 voit le pilote Windows. |
| Réseau | La collecte télécharge ~15 Go depuis GBIF et iNaturalist. |

## 1. WSL2 et Ubuntu

Dans PowerShell **en administrateur** :

```powershell
wsl --install -d Ubuntu
```

Redémarrer si demandé, puis ouvrir « Ubuntu » dans le menu Démarrer et créer
l'utilisateur Linux.

## 2. TensorFlow qui voit la carte

Dans Ubuntu :

```bash
sudo apt update && sudo apt install -y python3-pip python3-venv git
python3 -m venv ~/venv && source ~/venv/bin/activate
pip install --upgrade pip
```

> **Le piège à ne pas rater.** `requirements.txt` installe `tensorflow-cpu`,
> qui ignore la carte même présente : l'entraînement tourne dix fois plus
> lentement, sans un message. Sur cette machine, c'est **`requirements-gpu.txt`**.

```bash
git clone https://github.com/brunopaiva15/plant.git ~/plant
cd ~/plant/tools/plant_model
pip install -r requirements-gpu.txt
python3 -c "import tensorflow as tf; print(tf.config.list_physical_devices('GPU'))"
```

**Ce que vous devez voir** — une liste non vide :

```
[PhysicalDevice(name='/physical_device:GPU:0', device_type='GPU')]
```

Si la liste est vide : le pilote Windows n'est pas à jour, ou `tensorflow-cpu`
traîne dans l'environnement (`pip uninstall tensorflow-cpu`). Ne pas
continuer avant que cette ligne réponde — `train.py` le redira au démarrage,
mais autant le savoir tout de suite.

## 3. Reconstruire le jeu d'images (~2 h)

Le jeu n'est pas dans Git : 15 Go, 290 518 images. Il se reconstruit à
l'identique depuis les sources, en parts parallèles.

```bash
cd ~/plant/tools/plant_dataset
pip install -r requirements.txt
python3 -m pytest -q            # 84 tests, sans réseau

mkdir -p dataset
cp cache/*.json dataset/        # heures de résolution de noms déjà faites
```

Découper le catalogue en **quatre parts** (huit cœurs) :

```bash
python3 - <<'PY'
from pathlib import Path
noms = [l.strip() for l in Path('all_species.txt').read_text().splitlines() if l.strip()]
interieur = {l.strip() for l in Path('phase1_species.txt').read_text().splitlines() if l.strip()}
# Les plantes d'intérieur coûtent deux fois plus (passes « en pot ») : en
# tête, pour que les parts durent le même temps.
ordre = [n for n in noms if n in interieur] + [n for n in noms if n not in interieur]
for i in range(4):
    Path(f'shard{i}.txt').write_text('\n'.join(ordre[i::4]) + '\n')
PY

for i in 0 1 2 3; do
  mkdir -p shard$i && cp cache/*.json shard$i/
  nohup python3 build_dataset.py --plants plants.csv --out shard$i --only-file shard$i.txt \
    --target-per-species 200 --allow-sa \
    --captive-file phase1_species.txt --captive-share 0.5 \
    --captive-place 97391 --place-share 0.25 \
    --workers 8 --gbif-pause 0.6 --inat-pause 2.0 > shard$i.log 2>&1 &
done
wait
```

Puis la passe « en pot » sur les 167 plantes d'intérieur, qui ajoute par
**dessus** la cible les photos de plantes cultivées — celles qui décrivent
l'usage réel de l'application :

```bash
for i in 0 1 2 3; do
  grep -Fxf phase1_species.txt shard$i.txt > pot$i.txt
  nohup python3 build_dataset.py --plants plants.csv --out shard$i --only-file pot$i.txt \
    --target-per-species 300 --allow-sa \
    --captive-file phase1_species.txt --captive-share 0.5 \
    --captive-place 97391 --place-share 0.25 \
    --workers 8 --gbif-pause 0.6 --inat-pause 2.0 > pot$i.log 2>&1 &
done
wait
```

Enfin la fusion et la finalisation. **La dernière ligne n'est pas
facultative** : déduplication entre espèces, répartition et statistiques
portent sur l'ensemble, et aucune part ne peut les faire seule.

```bash
python3 merge_shards.py --out dataset shard0 shard1 shard2 shard3
python3 build_dataset.py --out dataset --plants plants.csv --skip-fetch
```

**Ce que vous devez voir**, à quelques centaines d'images près (les sources
bougent d'un jour à l'autre) :

```
290 000 ± images gardées ; 1 500 ± espèces
```

Une coupure réseau saute une espèce et l'écrit `ÉCHEC` dans le journal ;
`grep ÉCHEC shard*.log` les liste, et les relancer avec
`--only "Nom scientifique"` les rattrape en quelques secondes.

## 4. Refaire la v6 à l'identique (~1 h 30)

**Ne pas sauter cette étape.** C'est le seul entraînement dont la réponse est
connue d'avance : s'il retombe sur ses pieds, toute la chaîne est validée et
les essais suivants sont interprétables. Sinon, mieux vaut le savoir
maintenant qu'après trois recettes.

```bash
cd ~/plant/tools/plant_model
python3 train.py --dataset ../plant_dataset/dataset --out .cache/v6_gpu \
  --backbone large --batch 64 --mixed-precision \
  --head-epochs 40 --fine-epochs 12 \
  --feature-cache .cache/features --checkpoint .cache/ckpt --version 6-gpu
```

**Ce que vous devez voir** — au démarrage la carte, puis, à la fin :

```
1 carte(s) graphique(s) : /physical_device:GPU:0
précision mixte : mixed_float16
...
précision mixte : réseau reconstruit en float32 pour l'évaluation et l'export
 "top1": 0.52 ±0.01,  "top3": 0.67 ±0.01,  "macro_f1": 0.50 ±0.01
```

Un écart de plus d'un point ou deux sur le top-1 veut dire que quelque chose
diffère — pas la peine d'enchaîner, il faut comprendre quoi.

L'entraînement est **reprenable** : relancer la même ligne repart du dernier
point de sauvegarde (toutes les 200 lots). `--fine-epochs 0` évalue et
exporte depuis un point de sauvegarde sans rien réentraîner.

## 5. Comparer, toujours à armes égales

Les chiffres de deux `model.json` **ne se comparent pas** : ils viennent de
jeux de test différents. Un modèle qui « gagne trois points » a peut-être
seulement reçu un test plus facile. Ce qui se compare, ce sont deux modèles
sur les mêmes images :

```bash
python3 compare_models.py --dataset ../plant_dataset/dataset \
  --a ../../assets/model --b .cache/v6_gpu --sample 5000
```

Et pour rejouer une photo réelle dans plusieurs modèles, avec la décision que
prendrait l'application :

```bash
python3 identify.py ma_plante.jpg --model ../../assets/model --model .cache/v6_gpu
```

## 6. Enchaîner les recettes de la v7

Le défaut mesuré de la v6 est le **sur-apprentissage** : à la douzième
époque, 70,5 % à l'entraînement contre 52,2 % en validation. Dix-huit points
d'écart, c'est la régularisation qui limite, pas le nombre d'époques.

Une recette à la fois, sinon on ne saura pas ce qui a agi.

| # | Essai | Coût | Ce qu'on attend |
|---|---|---|---|
| 1 | `--dropout 0.5`, augmentations plus fortes | 1 h | resserrer l'écart de dix-huit points |
| 2 | `--unfreeze 100` ou `--fine-lr 2e-5` | 1 h | trouver le bon dosage de réglage fin |
| 3 | Entrée à 320 px — **demande une petite modification** : `IMAGE_SIZE` et `LOAD_SIZE` sont des constantes de `train.py`, pas des options | 2 h | le levier classique de la reconnaissance fine |
| 4 | Pré-entraînement PlantNet-300K | ½ journée | voir ci-dessous |

**PlantNet-300K, ce qu'il faut savoir avant de s'y engager.** Les poids
publiés sont des **ResNet18 PyTorch** : rien de réutilisable pour un
MobileNetV3 TensorFlow, donc ce serait une passe complète de plus, sur
306 000 images et 32 Go à télécharger. Avant cela, une mesure à dix
secondes : le recouvrement entre leurs 1 081 espèces
(`plantnet300K_species_id_2_name.json`, livré avec le jeu) et nos 1 445
classes (`assets/model/labels.txt`). S'il est fort, le geste utile n'est pas
de pré-entraîner mais d'**ajouter leurs images aux nôtres** pour les espèces
communes — même bénéfice, aucune passe supplémentaire.

## 7. Livrer

```bash
cp .cache/v7_out/{plants.tflite,labels.txt,model.json} ../../assets/model/
cd ~/plant && flutter analyze && flutter test
```

Et **remesurer le seuil** : `acceptThreshold` vaut 0,60 pour la v6 et ne se
transporte pas d'un modèle à l'autre — un réseau plus large répartit sa
confiance sur plus de candidats. Le tableau se produit avec :

```bash
python3 multi_photo.py --dataset ../plant_dataset/dataset --model .cache/v7_out
```

Le détail du raisonnement est dans `identification_policy.dart` et au § 6.6
de [`09-plant-recognition.md`](09-plant-recognition.md).
