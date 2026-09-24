# 10 — Entraîner le modèle sur son propre poste

> Procédure suivie de bout en bout, de Windows nu au `.tflite` livré.
> Machine de référence : Windows + RTX 2070 Super (8 Go) + i7-9700K (8 cœurs).
> Compter **une demi-journée** la première fois, dont l'essentiel en attente.
>
> Sur une machine **louée** — Debian nu, carte de centre de calcul, disques à
> monter soi-même — les commandes ci-dessous restent valables, mais
> l'installation et le dimensionnement diffèrent :
> [`11-entrainer-sur-une-vm.md`](11-entrainer-sur-une-vm.md).

Iris 6 — la sixième version du modèle embarqué — a été entraînée sur quatre
cœurs sans carte graphique : neuf heures 47, par tranches de dix minutes, sur
une machine recyclée dès qu'elle s'endormait. Sur une carte grand public, la
même passe coûte de l'ordre d'une heure. C'est ce qui a rendu la v7 puis la v8
possibles : quatre recettes dans un après-midi au lieu d'une par nuit.

La version que l'application livre aujourd'hui est l'**Iris 9** ; son numéro
et ses chiffres ne s'écrivent pas ici, ils sont dans
`assets/model/model.json` et repris une seule fois, au § 0 de
[`09-plant-recognition.md`](09-plant-recognition.md). La procédure ci-dessous
ne dépend d'aucun des deux : elle vaut pour la version suivante.

## Avant de commencer

| | |
|---|---|
| Disque | **110 Go libres**, sur un **SSD**. Le jeu de l'Iris 9 fait 51 Go pour près d'un million de fichiers, relus dans un ordre différent à chaque époque : sur un disque à plateaux, c'est lui qui devient le goulot, et de loin. Et sous WSL, **le disque d'Ubuntu est lui-même un fichier sur `C:`** — l'y copier ne le sort pas de `C:`, ça l'y met une seconde fois. |
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

> **Le second piège, aussi coûteux.** Cloner dans `/mnt/c/...` — le disque
> Windows vu depuis Linux — fait passer chaque lecture de fichier par une
> couche de traduction. Sur 290 000 petits fichiers relus à chaque époque,
> c'est un facteur dix. Le dépôt et le jeu doivent vivre dans le système de
> fichiers de WSL (`~/`), pas sous `/mnt/c`.

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

### Le teacher d'Iris 10 a son propre environnement

`tools/plant_model/bioclip.py` tourne sous PyTorch, et PyTorch embarque ses
CUDA et cuDNN comme `tensorflow[and-cuda]` embarque les siens. Les deux dans
un même venv est l'accident du paragraphe précédent en plus gros : ça
s'installe sans erreur, ça tourne, et c'est la pile lente qui gagne.

```bash
python3 -m venv ~/venv-torch && source ~/venv-torch/bin/activate
pip install -r ~/plant/tools/plant_model/requirements-bioclip.txt
python3 -c "import torch; print(torch.cuda.is_available())"
```

Deux venvs, deux `source`, et on ne lance jamais `train.py` depuis
`~/venv-torch` ni `bioclip.py` depuis `~/venv`.

> **Et la parade du § *tmux* de [`docs/11`](11-entrainer-sur-une-vm.md) est
> devenue un piège.** Elle propose `echo 'source ~/venv/bin/activate' >>
> ~/.bashrc`, parce qu'un shell neuf n'hérite pas du venv activé à côté. Avec
> deux venvs, cette ligne dépose dans celui de TensorFlow un `bioclip.py` qui
> meurt aussitôt sur `No module named 'torch'`. **L'interpréteur en chemin
> absolu est la seule parade qui tienne à deux environnements** :
> `~/venv-torch/bin/python3 bioclip.py …`, `~/venv/bin/python3 train.py …`.

## 2 bis. Ce que la machine rend, mesuré

Avant de déplacer des dizaines de gigaoctets vers une machine, il faut savoir
ce qu'elle vaut. `../plant_dataset/echantillon.py` prélève 120 classes —
quelques centaines de mégaoctets — et deux époques courtes suffisent :

```bash
python3 -u train.py --dataset ~/plant-data/dataset-echantillon --out /tmp/bench \
  --backbone large --batch 128 --mixed-precision \
  --head-epochs 0 --fine-epochs 2 --steps-per-epoch 60 --ram-budget 0
```

On lit le `s/step` de la **seconde** époque : la première paie la compilation
du graphe. Mesuré le 21 septembre 2026, à réglages identiques :

| | par lot de 128 | images/s | |
|---|---|---|---|
| Apple M5 Pro (Metal) | 0,240 s | 533 | |
| **RTX 2070 Super** | **0,076 s** | **1 684** | **3,2×** |

Et la passe réelle qui a suivi, à 320 px et lot 64 : **77 ms par lot, 831
images/s, 953 secondes par époque** de 794 944 images — huit heures pour
trente époques. La prévision tirée du banc annonçait 840 images/s et seize
minutes par époque ; l'écart est de un pour cent.

**Le tuyau n'est pas le plafond ici, mais il n'en est pas loin.** Un i7-9700K
à huit cœurs décode environ 1 260 images/s. À 224 px la carte en demande
1 684 et attend donc un peu le processeur ; à 320 px elle n'en demande plus
que 840, parce qu'elle calcule deux fois plus par image alors que le décodage
coûte la même chose — il dépend de la taille **stockée**, pas de l'entrée du
réseau. Monter à 320 rééquilibre la machine au lieu de l'étrangler.

### Et ce que rend le teacher d'Iris 10, sur la même carte

`bioclip.py mesure`, le 21 septembre 2026, sur l'échantillon :

| | images/s | corpus | |
|---|---|---|---|
| MobileNetV3Large, 320 px, lot 64 | 831 | — | la passe d'entraînement |
| BioCLIP ViT-H/14, décodage en série | 36,6 | 7,5 h | le premier jet |
| **BioCLIP ViT-H/14, `--fils 6`** | **79,9** | **3,4 h** | **2,2×** |

Lot 32, `float16`, **3,74 Gio de VRAM sur les 8** — la moitié de la carte
reste libre.

Dix fois plus lent que l'entraînement, et ce n'est pas un problème : le
teacher tourne **une fois**, là où l'entraînement repasse trente époques.
Trois heures et demie pour BioCLIP contre huit heures pour une passe d'Iris
9 — le cache coûte moins qu'un entraînement, une seule fois, et aucune
distillation ne le rappellera ensuite.

#### La moitié de la passe était du décodage, et ça ne se devinait pas

Le premier jet décodait un lot, l'envoyait à la carte, décodait le suivant.
`nvidia-smi` pendant la passe : **53 %** d'utilisation en moyenne sur huit
échantillons. La carte attendait le processeur à peu près la moitié du
temps.

Deux estimations successives se sont trompées, dans les deux sens, et c'est
l'intérêt de les avoir écrites :

- **23 %**, prévu avant la passe, en partant des 1 260 images/s de décodage
  JPEG mesurés plus haut. Faux : ce chiffre-là mesure un décodage nu, quand
  le teacher décode **et** redimensionne en bicubique vers 224 px, ce qui
  coûte bien davantage ;
- **69 images/s**, prévu depuis les 53 % d'utilisation. Faux aussi, mais par
  défaut : on a obtenu 79,9. L'utilisation vue par `nvidia-smi` est une
  moyenne grossière qui compte mal les creux courts.

> **Un débit ne se déduit pas d'un autre débit.** Les deux estimations
> partaient d'un chiffre mesuré et juste, et toutes deux étaient fausses de
> près du double. Trente secondes de `mesure` ont tranché ce que deux
> raisonnements n'avaient pas su approcher.

### Déplacer le jeu : une archive, jamais un million de fichiers

Copier le jeu dossier par dossier depuis `/mnt/c` vers le disque Linux rend
**4,4 Mo/s** — 86 fichiers par seconde, soit onze millisecondes chacun. C'est
le coût par fichier de la passerelle, et il donne trois heures et quart pour
51 Go. La bonne façon tient en deux commandes et une demi-heure :

```powershell
# côté Windows : lecture native de C:, une seule grosse écriture
tar -cf E:\dataset.tar -C C:\Temp\plant-data dataset-v8-indoor
```

```bash
# côté Ubuntu : une seule grosse lecture
tar xf /mnt/e/dataset.tar -C ~/plant-data
```

Un disque branché après le démarrage de WSL n'est pas monté tout seul :
`sudo mkdir -p /mnt/e && sudo mount -t drvfs E: /mnt/e`.

**Et le jeu doit vivre dans `~`, jamais dans `/mnt/c`.** Laissé côté Windows,
il serait relu à travers la même passerelle à chaque époque, et la carte
attendrait le disque toute la journée.

### Ce qui peut emporter huit heures de calcul

- **L'évaluation finale tenait neuf gigaoctets.** `np.argsort` sur 99 825
  images × 5 376 classes fabriquait une copie en entiers 64 bits de 4,3 Go
  pour ne lire que trois colonnes ; WSL prenant la moitié de la mémoire de
  Windows, le tueur du noyau a emporté la passe à la dernière étape, sans
  écrire le modèle. Corrigé le 21 septembre — `argpartition` lot par lot, et
  six tests qui comparent au tri complet. La liste des classes est désormais
  écrite dans le dossier de sauvegarde **avant** l'entraînement : `labels.txt`
  n'existait qu'à l'export, et des poids sans leur liste ne servent à rien.
- **Ne jamais `kill -STOP` une passe.** Sur un Mac, geler un processus qui
  tient un contexte Metal l'a laissé vivant, muet et irrécupérable — onze
  minutes après la reprise, puis une seconde fois sans aucune manipulation.
  Deux blocages en une journée, six mégaoctets de mémoire résidente au lieu
  de deux gigaoctets, aucune trace d'erreur. Si la machine doit souffler,
  mieux vaut arrêter franchement et relancer.
- **Relire la ligne de commande avant de lancer.** Une passe entière a tourné
  aux valeurs par défaut — 224 px, dropout 0,3, soixante couches — faute
  d'avoir passé les trois options de la recette. Elle plafonnait douze points
  sous la vraie (§ 13.6 de `docs/09`).
- **Un redémarrage brutal de Windows peut laisser le disque d'Ubuntu en
  lecture seule.** Le 24 septembre, après un redémarrage imprévu, toute
  écriture échouait sur `Read-only file system` ; `dmesg` disait
  `bad block bitmap checksum` puis `Remounting filesystem read-only`, 1,7 s
  après chaque démarrage. `wsl --shutdown` ne répare rien : le disque repart,
  puis rebascule dès qu'on touche la zone abîmée. Ce qui répare, depuis
  Windows, parce qu'on ne vérifie pas un disque depuis le système qui tourne
  dessus :

  ```powershell
  wsl --shutdown
  $disque = Join-Path ((Get-ChildItem HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss | ForEach-Object { Get-ItemProperty $_.PSPath } | Where-Object DistributionName -eq 'Ubuntu').BasePath) 'ext4.vhdx'
  wsl --install -d Debian             # une seule fois : l'outil de réparation
  wsl --mount $disque --vhd --bare    # PowerShell administrateur
  wsl -d Debian                       # puis : lsblk, le disque 1 T sans point de montage
  ```

  Dans Debian, `sudo e2fsck -fn /dev/sdX` d'abord — il ne modifie rien et dit
  si des fichiers sont touchés (passes 1 à 4) ou seulement les tables de
  blocs libres (passe 5, le cas du 24) — puis `sudo e2fsck -fy /dev/sdX`.
  Enfin `wsl --unmount $disque`, `wsl --shutdown`, et vérifier que
  `wsl -l -v` met toujours Ubuntu par défaut. Les passes finies avant la
  coupure étaient intactes : le passage en lecture seule est ce qui les a
  protégées.

## 3. Reconstruire le jeu d'images (~2 h)

Le jeu n'est pas dans Git : 15 Go, 290 518 images. Il se reconstruit à
l'identique depuis les sources, en parts parallèles.

```bash
cd ~/plant/tools/plant_dataset
pip install -r requirements.txt
python3 -m pytest -q            # sans réseau

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
    --workers 8 --gbif-pause 0.8 --inat-pause 4.0 > shard$i.log 2>&1 &
done
wait
```

> **Les pauses se divisent par le nombre de parts.** `--inat-pause` est
> l'attente d'**une** part entre deux requêtes ; quatre parts en parallèle
> font quatre fois plus de trafic. iNaturalist demande de rester sous
> 60 requêtes par minute : c'est 4 s de pause à quatre parts, 3 s à trois,
> 1 s tout seul. En dessous, la source répond 429, les six essais s'épuisent
> et l'espèce part en `ÉCHEC` — sans casse, mais il faut la reprendre. Une
> collecte saine finit à quelques échecs sur 1 558 ; à plusieurs dizaines
> par part, c'est le débit qu'il faut relâcher, pas la reprise qu'il faut
> répéter.

### Rattraper les espèces tombées

Une source qui tombe fait sauter **une** espèce, pas la collecte : elle
part en `ÉCHEC` dans le journal et la suivante démarre. Il faut donc
repasser derrière, avant la fusion :

```bash
python3 failed_species.py --why --against shard0.txt --against shard1.txt \
    --against shard2.txt --against shard3.txt shard0.log shard1.log shard2.log shard3.log
```

`--against` compare le journal à la liste qu'on avait confiée à la part et
ramasse aussi les espèces qui n'ont **aucune** ligne : une part tuée en
route s'arrête sans rien écrire, et « 389/390 » ne se distingue autrement
de « 390/390 » qu'à l'œil. Deux vérifications valent la peine avant :

```bash
pgrep -af '[b]uild_dataset.py'                    # doit être vide
grep -c 'images gardées sur' shard*.log           # 1 par part : elle est allée au bout
```

Le décompte par motif dit quoi faire :

| Motif | Ce que c'est | Quoi faire |
|---|---|---|
| `HTTPError` | 429 ou 5xx après six essais — le débit, presque toujours | reprendre en séquentiel ; ça passe |
| `ConnectionError`, `Timeout` | réseau coupé, source lente | reprendre à l'identique |
| `JSONDecodeError` | réponse tronquée, source sous charge | reprendre à l'identique |
| `jamais traitée` | la part s'est arrêtée avant | reprendre ; vérifier d'abord qu'elle n'a pas été tuée par manque de disque |
| autre chose | un bogue, pas une panne | ne pas boucler dessus : la ligne complète du journal vaut plus qu'une seconde tentative |

Les espèces marquées `nom non résolu chez GBIF, à revoir` ne sont **pas**
des échecs et ne se reprennent pas : le nom est ambigu ou absent du
référentiel, et c'est `synonyms.txt` qui répond
(`grep -c 'à revoir' shard*.log` pour les compter). Il y en a une poignée,
et le jeu s'en passe.

La reprise réécrit chaque espèce dans **sa** part d'origine — une espèce
éclatée entre deux dossiers serait comptée deux fois à la fusion :

```bash
python3 failed_species.py --write retry --against shard0.txt --against shard1.txt \
    --against shard2.txt --against shard3.txt shard0.log shard1.log shard2.log shard3.log

for i in 0 1 2 3; do
  [ -s retry$i.txt ] && python3 build_dataset.py --plants plants.csv --out shard$i \
    --only-file retry$i.txt --target-per-species 200 --allow-sa \
    --captive-file phase1_species.txt --captive-share 0.5 \
    --captive-place 97391 --place-share 0.25 \
    --workers 8 --gbif-pause 1.0 --inat-pause 1.5 > retry$i.log 2>&1
done
python3 failed_species.py --why retry*.log     # doit être proche de zéro
```

> **La reprise écrit dans son propre journal, et ce n'est pas un détail.**
> `failed_species.py` retient toute espèce ayant une ligne `ÉCHEC`, sans
> savoir qu'une passe ultérieure l'a rattrapée. Ajoutée à la suite du journal
> de la passe principale (`>>`), la reprise laisserait donc le décompte
> inchangé — 342 échecs avant, 342 après, alors que la quasi-totalité a été
> reprise. Un journal par passe, et le chiffre veut de nouveau dire quelque
> chose.

C'est séquentiel — une part après l'autre — et c'est voulu : deux cents
espèces seules ne pèsent rien, quelques minutes suffisent, et on ne
reproduit pas la cause. Ce qui reste après deux passes est probablement une
espèce qu'aucune source ne connaît ; le jeu s'en passe.

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
    --workers 8 --gbif-pause 0.8 --inat-pause 4.0 > pot$i.log 2>&1 &
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

> **Reprendre n'est pas prolonger.** Seuls les poids sont restaurés : Adam
> repart de moments nuls. Sur un réseau interrompu en route, c'est sans
> conséquence ; sur un réseau qui a convergé, ça coûte cher. Mesuré le
> 19 septembre 2026 — huit époques ajoutées après coup ont rendu un modèle
> **2,3 points de validation sous son point de départ**, et `fine.weights.h5`
> étant réécrit à chaque époque, les poids d'avant étaient perdus. Pour
> allonger un entraînement, relancer une passe entière avec le bon nombre
> d'époques.

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

## 6. Enchaîner les recettes, une à la fois

> Les quatre essais ci-dessous sont ceux de la v7, gardés parce qu'ils
> montrent comment on s'y prend. Les trois premiers ont été faits et livrés :
> ils valent ensemble +7,26 points de top-1 (§ 6.7 de
> [`09-plant-recognition.md`](09-plant-recognition.md)). Le quatrième a été
> mesuré et écarté (§ 12.8). Ce que la v8 a changé ensuite ne tient pas à une
> recette mais à la séparation entre ce qu'on entraîne et ce qu'on expose
> (§ 13).

Le défaut mesuré de la v6 était le **sur-apprentissage** : à la douzième
époque, 70,5 % à l'entraînement contre 52,2 % en validation. Dix-huit points
d'écart, c'est la régularisation qui limite, pas le nombre d'époques.

Une recette à la fois, sinon on ne saura pas ce qui a agi.

| # | Essai | Coût | Ce qu'on attend |
|---|---|---|---|
| 1 | `--dropout 0.5`, augmentations plus fortes | 1 h | resserrer l'écart de dix-huit points |
| 2 | `--unfreeze 100` ou `--fine-lr 2e-5` | 1 h | trouver le bon dosage de réglage fin |
| 3 | Entrée à 320 px : `--input-size 320` | 2 h | le levier classique de la reconnaissance fine, au prix d'une inférence deux fois plus lourde sur le téléphone |
| 4 | Pré-entraînement PlantNet-300K | ½ journée | voir ci-dessous |

**PlantNet-300K, ce qu'il faut savoir avant de s'y engager.** Les poids
publiés sont des **ResNet18 PyTorch** : rien de réutilisable pour un
MobileNetV3 TensorFlow, donc ce serait une passe complète de plus, sur
306 000 images et 32 Go à télécharger. Avant cela, une mesure à dix
secondes : le recouvrement entre leurs 1 081 espèces
(`plantnet300K_species_id_2_name.json`, livré avec le jeu) et nos classes —
une ligne par espèce dans `assets/model/labels.txt`, comptées par
`model.json`. S'il est fort, le geste utile n'est pas de pré-entraîner mais
d'**ajouter leurs images aux nôtres** pour les espèces communes — même
bénéfice, aucune passe supplémentaire.

## 7. Livrer

```bash
cp .cache/v7_out/{plants.tflite,labels.txt,model.json} ../../assets/model/
cd ~/plant && flutter analyze && flutter test
```

Et **remesurer le seuil** : `acceptThreshold` vaut 0,70 depuis l'Iris 7, et
il ne se transporte pas d'un modèle à l'autre — un réseau plus large répartit
sa confiance sur plus de candidats. Le couple retenu se relit dans le
`threshold_curve` du `model.json` produit ; le tableau se produit avec :

```bash
python3 multi_photo.py --dataset ../plant_dataset/dataset --model .cache/v7_out
```

Le détail du raisonnement est dans `identification_policy.dart`, et dans
[`09-plant-recognition.md`](09-plant-recognition.md) : la règle de décision
au § 3.1, la mesure du seuil au § 6.7.
