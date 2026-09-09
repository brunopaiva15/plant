# 11 — Entraîner le modèle sur une VM louée

> Complément de [`10-entrainer-sur-son-poste.md`](10-entrainer-sur-son-poste.md),
> qui décrit la même chaîne sur une machine personnelle (Windows, WSL2,
> RTX 2070 Super). **Les commandes de collecte et d'entraînement sont
> les siennes** ; ce document ne dit que ce qui change quand la machine est
> louée à l'heure, tourne sur Debian nu, et disparaît à la fin.
>
> Machine de référence : Debian 12, NVIDIA L40 (48 Go), disque système de
> 99 Go. Procédure suivie de bout en bout le 9 septembre 2026.

Trois choses changent, et elles changent beaucoup :

1. **La carte n'est plus le goulot.** Sur quatre cœurs, le tuyau de données
   rend 630 images/s quand un 2070 Super en avale 93 : le décodage JPEG est
   sept fois trop rapide pour gêner. Une L40 en avale plusieurs centaines,
   et le rapport s'inverse. C'est le **nombre de vCPU** qui décide de la
   durée d'une époque, pas la carte.
2. **Rien n'est installé, et rien n'est monté.** Un disque attaché chez le
   fournisseur n'est qu'un périphérique bloc ; un pilote NVIDIA absent ne
   s'installe pas d'un paquet. Les deux tiers du temps perdu ici l'ont été
   là.
3. **La machine est facturée pendant qu'elle attend.** La collecte dure
   trois à quatre heures sans toucher au GPU (§ 5).

## 1. Dimensionner

| | Minimum | Confortable | Pourquoi |
|---|---|---|---|
| vCPU | 16 | **32** | le décodage JPEG, ~157 images/s par cœur |
| RAM | 32 Go | **128 Go** | au-delà de ~50 Go, `--ram-budget 50` précharge tout le jeu et supprime le décodage à chaque époque |
| Disque de travail | 100 Go | **150 Go** | voir ci-dessous |
| Disque persistant | 100 Go | | l'archive du jeu, qui doit survivre à la VM |
| OS | **Debian 12 (bookworm)** | | Python 3.11, dans la fenêtre supportée par TensorFlow. Debian 13 livre Python 3.13 : vérifier qu'une roue existe avant de s'y engager |

**Le disque est plus gros que ne le laisse croire `docs/10`.** Les 15 Go
annoncés sont ceux du jeu *fini* ; pendant la collecte en quatre parts, on
porte aussi les images rejetées et les doublons de chaque part. Mesuré ici :
**19 Go à 44 % de la passe principale**, plantes d'intérieur — les plus
coûteuses — déjà passées. Prévoir 100 Go, ce n'est pas cher payé.

Si la VM est **préemptible**, ce n'est pas un problème : `--checkpoint` fait
reprendre l'entraînement au dernier point de sauvegarde, toutes les 200 lots.
C'est le mode nominal, la v6 a été entraînée par tranches de dix minutes.

## 2. Le pilote NVIDIA — là où se perd la matinée

### D'abord, vérifier ce qui est déjà là

```bash
nvidia-smi                    # beaucoup d'images « GPU » l'embarquent déjà
lspci -nn | grep -i nvidia    # la carte est-elle seulement attachée ?
. /etc/os-release && echo "$VERSION_ID"
uname -r
```

Si `lspci` ne rend rien, aucun pilote n'y changera quoi que ce soit : c'est le
type d'instance qui n'a pas de GPU.

### Les en-têtes du noyau, et le piège qui a coûté le plus

```bash
sudo apt update
apt-cache policy "linux-headers-$(uname -r)"      # doit avoir un « Candidat »
sudo apt install -y dkms build-essential "linux-headers-$(uname -r)"
```

> **Lire la sortie de cette commande.** Si un seul paquet de la liste est
> introuvable — et `linux-headers-$(uname -r)` l'est souvent, les noyaux
> « cloud » ayant leur propre nom — **apt abandonne toute la transaction et
> n'installe rien**, pas même `dkms`. Le pilote s'installe ensuite sans
> pouvoir construire son module, `nvidia-smi` existe et répond
> « couldn't communicate with the NVIDIA driver », et l'on cherche du côté de
> Secure Boot pendant vingt minutes. C'est exactement ce qui s'est passé ici.
> Le symptôme qui ne trompe pas : `dkms: command not found`.

À défaut, le méta-paquet, puis un redémarrage pour tourner sur un noyau qui a
ses en-têtes :

```bash
sudo apt install -y dkms build-essential linux-headers-cloud-amd64 linux-headers-amd64
sudo reboot
```

### Le pilote

```bash
curl -fsSLO https://developer.download.nvidia.com/compute/cuda/repos/debian12/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
sudo apt update
sudo apt install -y cuda-drivers        # le pilote SEUL
sudo reboot
```

**Ne pas installer `cuda-toolkit`** : `tensorflow[and-cuda]` embarque ses
propres CUDA et cuDNN, et deux jeux de bibliothèques qui se marchent dessus
sont la première cause de « carte invisible ».

### Vérifier, dans cet ordre

```bash
dkms status        # nvidia/<version>, <le noyau de `uname -r`>, x86_64: installed
nvidia-smi         # NVIDIA L40, 46068MiB
```

`added` sans `installed` veut dire que la construction a échoué, et son
journal le dit : `sudo cat /var/lib/dkms/*/*/build/make.log | tail -40`.

### Quand `nvidia-smi` échoue encore

| Ce qu'on lit | Cause | Remède |
|---|---|---|
| `dkms: command not found` | l'`apt install` a échoué en bloc | ci-dessus |
| `Module nvidia not found in /lib/modules/<noyau>` | module non construit, ou construit pour un autre noyau | `sudo dkms autoinstall` |
| `Key was rejected by service`, `mokutil --sb-state` = `enabled` | Secure Boot refuse un module non signé | le désactiver dans les options de l'instance |
| `Driver/library version mismatch` | ancien module encore chargé | redémarrer |
| `nouveau` dans `lsmod` | le pilote libre occupe la carte | le mettre en liste noire, `update-initramfs -u`, redémarrer |

## 3. TensorFlow qui voit la carte

```bash
sudo apt install -y git tmux python3-venv python3-pip
python3 -m venv ~/venv-tf && source ~/venv-tf/bin/activate
pip install -U pip
pip install --no-cache-dir "tensorflow[and-cuda]==2.19.*"
python3 -c "import tensorflow as tf; print(tf.config.list_physical_devices('GPU'))"
```

**Ce que vous devez voir** — une liste non vide :

```
[PhysicalDevice(name='/physical_device:GPU:0', device_type='GPU')]
```

**Épingler la version.** `requirements-gpu.txt` demande `>=2.19` ; sur une VM
neuve, pip sert la dernière en date. Ici, une **2.21 embarquant du CUDA 12.9**
face à un pilote **610 / CUDA 13.3** rendait une liste vide et un
« Cannot dlopen some GPU libraries » qui ne nommait aucune bibliothèque. La
2.19, dans un environnement neuf, a réglé le cas. Deux inconnues récentes en
même temps ne se débuguent pas : mieux vaut la paire que le dépôt a vue
tourner.

### Nommer la bibliothèque fautive

Le message qui les nomme est en `VLOG(1)`, pas en `INFO` — d'où son absence
même avec `TF_CPP_MIN_LOG_LEVEL=0` :

```bash
TF_CPP_MIN_LOG_LEVEL=0 TF_CPP_MAX_VLOG_LEVEL=1 \
  python3 -c "import tensorflow as tf; tf.config.list_physical_devices('GPU')" 2>&1 \
  | grep -iE "dso|could not load|libcu|cudnn"
```

Et, plus direct, en chargeant chaque bibliothèque à la main après avoir
importé TensorFlow (l'import met en place les chemins des paquets pip) :

```bash
python3 - <<'PY'
import ctypes, tensorflow
for lib in ['libcuda.so.1', 'libcudart.so.12', 'libcublas.so.12', 'libcublasLt.so.12',
            'libcufft.so.11', 'libcurand.so.10', 'libcusolver.so.11', 'libcusparse.so.12',
            'libcudnn.so.9', 'libnvJitLink.so.12', 'libnccl.so.2']:
    try: ctypes.CDLL(lib); print('OK ', lib)
    except OSError as e: print('KO ', lib, '-', str(e)[:110])
PY
```

**Un cas fréquent sur une VM nue** : `nvidia-smi` marche et CUDA non, parce
que les deux n'utilisent pas le même module. `nvidia-smi` se contente de
`/dev/nvidiactl` ; CUDA exige `nvidia_uvm` et `/dev/nvidia-uvm`, qui ne se
chargent pas toujours seuls.

```bash
lsmod | grep nvidia ; ls -l /dev/nvidia*
sudo modprobe nvidia-uvm
printf 'nvidia\nnvidia-uvm\nnvidia-modeset\n' | sudo tee /etc/modules-load.d/nvidia.conf
```

Deux messages à ignorer, normaux sur une VM : l'avertissement `AVX2 FMA` (la
roue officielle n'est pas compilée pour ce processeur, sans effet quand le GPU
travaille) et `NUMA node read … negative value (-1)`.

## 4. Les disques

```bash
lsblk -f          # la vue qui décide : FSTYPE et MOUNTPOINT par périphérique
findmnt /data     # rien ? alors /data est un dossier, pas un disque
```

Deux pièges de vocabulaire :

- **Un volume monté sur `/ephemeral` est du stockage local rapide, effacé
  quand la VM est arrêtée.** C'est le meilleur endroit où mettre le jeu
  pendant l'entraînement — 290 000 petits fichiers relus dans un ordre
  différent à chaque époque sont le pire cas pour un disque réseau — et le
  pire endroit où mettre l'archive.
- **Un disque attaché n'est pas un disque monté.** Il apparaît dans `lsblk`
  sans système de fichiers ni point de montage, et il faut le formater.

```bash
lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT     # relire, puis remplacer vdX
sudo mkfs.ext4 -L auxine-backup /dev/vdX
sudo mkdir -p /backup && sudo mount /dev/vdX /backup && sudo chown "$USER" /backup
sudo blkid /dev/vdX                      # puis, dans /etc/fstab, par UUID :
# UUID=…  /backup  ext4  defaults,nofail  0  2
```

⚠️ `mkfs` sur le mauvais périphérique détruit ce qu'il contient. L'identifier
par sa taille **et** l'absence de système de fichiers **et** l'absence de
point de montage, jamais par son seul nom.

Le `nofail` n'est pas cosmétique : sans lui, une VM qui redémarre sans son
volume reste bloquée au boot, et il n'y a pas de console pour la débloquer.

Une fois le jeu construit et archivé, on peut le déplacer sur le disque
local :

```bash
tar -C /data/plant/tools/plant_dataset -cf /backup/dataset-v7.tar dataset
mv /data/plant/tools/plant_dataset/dataset /ephemeral/dataset
ln -s /ephemeral/dataset /data/plant/tools/plant_dataset/dataset
```

Le lien symbolique évite de changer tous les `--dataset ../plant_dataset/dataset`.
Et **pas de `zstd`** : le jeu n'est que du JPEG, déjà compressé ; on paierait
du processeur pour deux ou trois pour cent, et une archive locale de 45 Go
demande 45 Go de plus sur le même disque.

## 5. La collecte : la VM n'y peut rien

Les commandes sont celles du § 3 de [`docs/10`](10-entrainer-sur-son-poste.md),
sans changement. Deux remarques propres à la VM :

- **Une plus grosse machine n'accélère pas la collecte.** Elle est bornée par
  les limites de débit des sources — iNaturalist demande de rester sous
  60 requêtes par minute — et `--inat-pause` est l'attente d'*une* part :
  quatre parts à 4 s font déjà le maximum autorisé. Passer à huit parts
  obligerait à `--inat-pause 8.0`, pour le même débit total.
- **Le GPU ne fait rien pendant ces trois ou quatre heures.** Si la
  facturation le justifie, collecter sur une petite VM de la même région et
  copier `dataset/` (15 Go, quelques minutes sur le réseau interne) revient
  moins cher. Dans tous les cas, **archiver le jeu** : la version suivante
  n'aura pas à refaire la collecte.

### tmux, et le venv qu'il ne transmet pas

Une session SSH coupée pendant quatre heures de collecte, c'est quatre heures
perdues : travailler dans `tmux` (`tmux new -s v7`, `Ctrl-b d` pour détacher,
`tmux attach -t v7` pour revenir).

> **Le piège.** `tmux` ouvre un shell neuf, qui **n'hérite pas du venv
> activé** dans la session précédente. Les quatre parts lancées ici sont
> mortes en une seconde, sur un `ModuleNotFoundError: No module named
> 'requests'`, avec `nohup` qui avale le message dans les journaux. Deux
> parades : `echo 'source ~/venv/bin/activate' >> ~/.bashrc`, ou l'interpréteur
> en chemin absolu (`~/venv/bin/python3 build_dataset.py …`), qui ne peut pas
> se tromper.

**Et vérifier que ça tourne vraiment**, plutôt que d'attendre quatre heures
pour rien :

```bash
sleep 30
pgrep -af '[b]uild_dataset.py' | wc -l     # 4
tail -3 shard0.log                          # des espèces qui défilent
```

### Suivre l'avancement

```bash
cat > ~/avancement.sh <<'EOF'
#!/bin/bash
cd /data/plant/tools/plant_dataset 2>/dev/null || exit 1
tot_n=0; tot_N=0
printf '%-8s %14s %8s %10s\n' PART AVANCEMENT ÉCHECS ÉTAT
for f in shard*.log; do
  [ -e "$f" ] || continue
  pos=$(grep -oE '^\[[0-9]+/[0-9]+\]' "$f" | tail -1 | tr -d '[]')
  n=${pos%%/*}; N=${pos##*/}
  [ -n "$n" ] && { tot_n=$((tot_n + n)); tot_N=$((tot_N + N)); }
  if grep -q 'images gardées sur' "$f"; then etat='TERMINÉ'
  elif pgrep -f "${f%.log}" >/dev/null;   then etat='en cours'
  else                                          etat='ARRÊTÉ'; fi
  printf '%-8s %14s %8s %10s\n' "${f%.log}" "${pos:-—}" "$(grep -c 'ÉCHEC' "$f")" "$etat"
done
echo
sec=$(pgrep -f '[b]uild_dataset.py' | head -1 | xargs -r ps -o etimes= -p 2>/dev/null | tr -d ' ')
[ "$tot_n" -gt 0 ] && [ -n "$sec" ] && printf 'total %d/%d espèces — reste ~%d min (estimation)\n' \
  "$tot_n" "$tot_N" "$(( sec * (tot_N - tot_n) / tot_n / 60 ))"
df -h /data | awk 'NR==2 {printf "disque : %s utilisés, %s libres (%s)\n", $3, $4, $5}'
EOF
chmod +x ~/avancement.sh && watch -n 15 ~/avancement.sh
```

Trois colonnes, dans l'ordre d'importance : un `ARRÊTÉ` avant `TERMINÉ` est
une part tuée en route ; quelques `ÉCHEC` par part sont normaux, plusieurs
dizaines veulent dire qu'il faut relâcher le débit ; et le disque monte plus
vite qu'on ne croit (§ 1).

## 6. L'entraînement

La recette est celle des § 4 à 7 de [`docs/10`](10-entrainer-sur-son-poste.md).
Ce qui change sur une carte de cette taille :

- **`--ram-budget 50`** si la VM a la mémoire : 232 000 images en 256×256 font
  45,6 Go, et le jeu se décode alors **une seule fois** au lieu d'être relu à
  chaque époque. C'est le levier qui débloque le tuyau de données. En dessous
  de 64 Go de RAM, laisser le défaut : le cache de pages du système gardera de
  toute façon les JPEG après la première époque.
- **Garder `--batch 64`.** Un lot plus gros change le taux d'apprentissage
  effectif, donc la recette : on ne pourrait plus comparer. Si la carte
  s'ennuie (`nvidia-smi dmon -s um`, colonne `sm` sous 60 %), c'est le
  processeur qui fait attendre, pas le lot qui est trop petit.
- **Refaire la v6 à l'identique reste obligatoire** (§ 4 de `docs/10`) : c'est
  le seul entraînement dont la réponse est connue d'avance, et il valide toute
  la chaîne. Le faire **avant** d'activer la réparation de répartition
  (§ 12.1 de [`09-plant-recognition.md`](09-plant-recognition.md)), qui change
  le jeu de test : finaliser avec `--no-repair-splits`, refaire la v6,
  refinaliser sans le drapeau, puis enchaîner les recettes de la v7.

## 7. Avant de détruire la VM

```bash
ls -lh /backup/dataset-v7.tar                                   # le jeu
tar czf /backup/v7-modeles.tar.gz -C ~/plant/tools/plant_model .cache/v7_*
cp ~/plant/tools/plant_dataset/dataset/ATTRIBUTIONS.md /backup/
```

`ATTRIBUTIONS.md` n'est pas facultatif : c'est la contrepartie des licences
CC BY et CC BY-SA, et il doit accompagner tout modèle publié (§ 4.1 de
`09-plant-recognition.md`).

Et vérifier que `/backup` est bien un volume persistant, pas `/ephemeral`.
