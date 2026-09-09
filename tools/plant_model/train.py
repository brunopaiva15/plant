#!/usr/bin/env python3
"""Entraîne le classifieur d'espèces, puis l'exporte en TFLite.

    python3 train.py --dataset ../plant_dataset/dataset --out ../../assets/model

Transfert depuis MobileNetV3-Small pré-entraîné sur ImageNet : la tête est
remplacée, on l'entraîne seule quelques époques (le reste gelé), puis on
dégèle le haut du réseau à faible taux d'apprentissage. C'est la recette qui
donne le plus de précision par heure de calcul quand on a quelques centaines
d'images par classe.

Les répartitions viennent de `splits.csv` : une observation ne peut pas être
à la fois dans l'entraînement et dans le test, sinon la précision mesurée
serait un mensonge.
"""
from __future__ import annotations

import argparse
import csv
import json
import hashlib
import random
import time
from collections import Counter
from pathlib import Path

import numpy as np
import tensorflow as tf

IMAGE_SIZE = 224
AUTOTUNE = tf.data.AUTOTUNE
UNKNOWN = '_unknown'
# Mélange reproductible : deux exécutions partent du même ordre.
SHUFFLE_SEED = 20260905


def read_splits(dataset: Path) -> tuple[dict[str, list[tuple[str, str]]], set[str]]:
    """{split: [(chemin absolu, internal_id)]} tel qu'écrit par build_dataset,
    et l'ensemble des chemins de photos de plantes cultivées (colonne
    `captive`) : la précision sur celles-là est la seule qui décrit ce que
    l'application fera sur les photos de ses utilisateurs."""
    rows: dict[str, list[tuple[str, str]]] = {'train': [], 'val': [], 'test': []}
    captive: set[str] = set()
    with open(dataset / 'splits.csv', newline='', encoding='utf-8') as f:
        for row in csv.DictReader(f):
            path = dataset / row['path']
            if path.exists():
                rows[row['split']].append((str(path), row['internal_plant_id']))
                if row.get('captive') == '1':
                    captive.add(str(path))
    return rows, captive


def usable_classes(rows: dict, min_train: int, min_val: int) -> list[str]:
    """Une classe n'entre dans le modèle que si elle a de quoi apprendre *et*
    de quoi être évaluée. Une classe à 3 images produirait un score illisible."""
    train = Counter(pid for _, pid in rows['train'])
    val = Counter(pid for _, pid in rows['val'])
    return sorted(c for c in train if train[c] >= min_train and val[c] >= min_val)


LOAD_SIZE = 256    # on garde un peu de marge autour de 224 pour le recadrage
SOURCE_SIZE = 448  # taille de stockage du jeu (plant_dataset/images.py, MAX_SIDE)


def set_input_size(px: int) -> None:
    """Change la taille d'entrée du réseau, et le chargement avec.

    `LOAD_SIZE` garde sa marge de recadrage — 256 pour 224, soit un huitième.
    Changer l'un sans l'autre est le piège de cette option : le réseau
    apprendrait sur un cadrage que `model.json` n'annonce pas, l'application
    lui donnerait autre chose que ce qu'il a vu, et l'écart se paierait en
    points sans qu'on sache d'où il vient — c'est exactement ce qui avait
    coûté 4,4 points à la v1 (§ 6.7 de docs/09).

    Au-delà de `SOURCE_SIZE`, on demanderait au jeu plus de pixels qu'il n'en
    a été stocké : l'agrandissement ne créerait pas de détail, il ferait
    seulement croire qu'on en a.
    """
    global IMAGE_SIZE, LOAD_SIZE
    load = round(px * LOAD_SIZE / IMAGE_SIZE)
    if px < 32:
        raise SystemExit(f'--input-size {px} : trop petit')
    if load > SOURCE_SIZE:
        raise SystemExit(f'--input-size {px} demande un chargement à {load} px, '
                         f'au-delà des {SOURCE_SIZE} px auxquels le jeu est stocké')
    IMAGE_SIZE, LOAD_SIZE = px, load


def load_all(usable: list[tuple[str, int]]) -> tuple[np.ndarray, np.ndarray]:
    """Décode une fois pour toutes en mémoire, en 256×256 uint8.

    Décoder un JPEG de 1024 px coûte ~15 ms ; le refaire à chaque époque
    ferait passer l'essentiel du temps d'entraînement dans le décodeur.
    9 000 images tiennent dans 1,8 Go — c'est le bon compromis ici.
    """
    images = np.zeros((len(usable), LOAD_SIZE, LOAD_SIZE, 3), dtype=np.uint8)
    labels = np.zeros(len(usable), dtype=np.int32)
    for i, (path, label) in enumerate(usable):
        raw = tf.io.read_file(path)
        img = tf.io.decode_jpeg(raw, channels=3)
        side = tf.reduce_min(tf.shape(img)[:2])
        img = tf.image.resize_with_crop_or_pad(img, side, side)
        images[i] = tf.image.resize(img, [LOAD_SIZE, LOAD_SIZE]).numpy().astype(np.uint8)
        labels[i] = label
        if (i + 1) % 500 == 0:
            print(f'  {i + 1}/{len(usable)} images chargées', flush=True)
    return images, labels


def augment(image, label):
    """Recadrage aléatoire, miroir, variation de lumière, de couleur et de
    netteté. Pas de rotation forte : un pot est droit sur une photo."""
    image = tf.image.random_crop(image, [IMAGE_SIZE, IMAGE_SIZE, 3])
    image = tf.image.random_flip_left_right(image)
    image = tf.cast(image, tf.float32)
    image = tf.image.random_brightness(image, 20.0)
    image = tf.image.random_saturation(image, 0.8, 1.25)
    image = resolution_jitter(image)
    return tf.clip_by_value(image, 0.0, 255.0), label


def resolution_jitter(image):
    """Réduit puis réagrandit l'image, à une échelle tirée au hasard.

    Le jeu a été collecté en trois fois, avec des tailles de stockage
    différentes (1024, 640 puis 448 px). La résolution est donc corrélée aux
    lots d'espèces, et un réseau saisit ce genre de raccourci avant
    d'apprendre la botanique : il lui suffirait de reconnaître la netteté
    pour éliminer les deux tiers des classes. Brouiller la netteté à
    l'entraînement lui retire cette possibilité — et rend au passage le
    modèle plus robuste aux photos floues, qui sont le quotidien.
    """
    def blurred():
        scale = tf.random.uniform([], 0.4, 1.0)
        small = tf.maximum(tf.cast(tf.cast(IMAGE_SIZE, tf.float32) * scale, tf.int32), 32)
        down = tf.image.resize(image, [small, small], method='bilinear')
        return tf.image.resize(down, [IMAGE_SIZE, IMAGE_SIZE], method='bilinear')

    return tf.cond(tf.random.uniform([]) < 0.5, blurred, lambda: image)


def center(image, label):
    offset = (LOAD_SIZE - IMAGE_SIZE) // 2
    image = tf.image.crop_to_bounding_box(image, offset, offset, IMAGE_SIZE, IMAGE_SIZE)
    return tf.cast(image, tf.float32), label


def array_dataset(images: np.ndarray, labels: np.ndarray, training: bool):
    """Un jeu de données au-dessus du tableau préchargé, sans le recopier.

    `from_tensor_slices` sur un tableau numpy en fait une constante du
    graphe : la mémoire est doublée. Sur 25 000 images en 256×256, cela
    fait 4,9 Go de tableau plus 4,9 Go de copie, et le système tue le
    processus. Un générateur lit le tableau en place ; il permute lui-même
    l'ordre à chaque époque, ce qui mélange mieux qu'un tampon glissant.
    """
    n = len(labels)

    def generate():
        order = np.random.permutation(n) if training else np.arange(n)
        for i in order:
            yield images[i], labels[i]

    return tf.data.Dataset.from_generator(
        generate,
        output_signature=(
            tf.TensorSpec(shape=(LOAD_SIZE, LOAD_SIZE, 3), dtype=tf.uint8),
            tf.TensorSpec(shape=(), dtype=tf.int32),
        ),
    )


def read_and_square(path, label):
    """Lit un JPEG et le ramène au carré central de LOAD_SIZE, comme le
    préchargement en mémoire. Les deux chemins doivent donner la même image,
    sinon les mesures ne veulent plus rien dire."""
    image = tf.io.decode_jpeg(tf.io.read_file(path), channels=3)
    side = tf.reduce_min(tf.shape(image)[:2])
    image = tf.image.resize_with_crop_or_pad(image, side, side)
    image = tf.image.resize(image, [LOAD_SIZE, LOAD_SIZE])
    return tf.cast(image, tf.uint8), label


def make_dataset(pairs, classes: list[str], batch: int, training: bool, ram_budget_gb: float = 6.0, preload: bool = True, repeat: bool = False, skip: int = 0):
    """Précharge en mémoire tant que ça tient dans le budget, sinon relit les
    fichiers à chaque époque.

    Le préchargement évite de redécoder les JPEG seize fois, mais 30 000
    images en 256×256 font 5,6 Go : au-delà du budget, mieux vaut une époque
    plus lente qu'un entraînement tué par le système.
    """
    index = {c: i for i, c in enumerate(classes)}
    usable = [(p, index[pid]) for p, pid in pairs if pid in index]
    if not usable:
        raise SystemExit('aucune image utilisable ; le jeu de données est-il construit ?')
    # splits.csv est trié par espèce. Laissé dans cet ordre, un tampon de
    # mélange de quelques milliers d'éléments ne contient qu'une poignée
    # d'espèces à la fois : chaque lot devient presque monospécifique, le
    # modèle marque des points en devinant parmi dix classes, et ne
    # généralise pas — c'est ce qu'on a observé, 31 % à l'entraînement contre
    # 9 % en validation. On mélange donc la liste entière avant tf.data.
    random.Random(SHUFFLE_SEED).shuffle(usable)
    counts = Counter(label for _, label in usable)
    if skip:
        # Reprise d'un encodage interrompu. Le mélange est fait, donc l'ordre
        # est le même qu'à la passe précédente : couper le préfixe déjà
        # calculé revient exactement à reprendre où l'on s'était arrêté.
        usable = usable[skip:]
    estimate = len(usable) * LOAD_SIZE * LOAD_SIZE * 3 / 1e9

    if preload and estimate <= ram_budget_gb:
        images, labels = load_all(usable)
        ds = array_dataset(images, labels, training)
        if training and repeat:
            ds = ds.repeat()
    else:
        if preload:
            print(f'  {len(usable)} images = {estimate:.1f} Go > budget {ram_budget_gb} Go : lecture depuis les fichiers')
        paths = [p for p, _ in usable]
        labels = [l for _, l in usable]
        ds = tf.data.Dataset.from_tensor_slices((paths, labels))
        if training:
            # On mélange les *chemins*, avant de décoder. Mélanger après le
            # décodage obligeait à lire huit mille JPEG avant le premier lot,
            # sept minutes à chaque époque : invisible sur une époque longue,
            # ruineux sur une époque courte. Des chaînes de caractères se
            # mélangent gratuitement, et toute la liste tient dans le tampon.
            ds = ds.shuffle(len(usable), reshuffle_each_iteration=True)
            if repeat:
                ds = ds.repeat()
        ds = ds.map(read_and_square, num_parallel_calls=AUTOTUNE)

    if training:
        ds = ds.map(augment, num_parallel_calls=AUTOTUNE)
    else:
        ds = ds.map(center, num_parallel_calls=AUTOTUNE)
    return ds.batch(batch).prefetch(AUTOTUNE), counts, [p for p, _ in usable]


# Largeur du vecteur rendu par la moyenne globale, par réseau.
FEATURE_DIM = {'small': 576, 'large': 960}

BACKBONES = {
    'small': ('MobileNetV3Small', tf.keras.applications.MobileNetV3Small),
    'large': ('MobileNetV3Large', tf.keras.applications.MobileNetV3Large),
}


def usable_count(pairs, classes: list[str]) -> int:
    """Le nombre d'images que `make_dataset` gardera : celles dont la classe
    est retenue. C'est ce compte, et non celui de `splits.csv`, qui dit
    combien de vecteurs le cache doit contenir."""
    index = set(classes)
    return sum(1 for _, pid in pairs if pid in index)


def frozen_backbone(backbone: str) -> tf.keras.Model:
    """Le réseau pré-entraîné, gelé, suivi de sa moyenne globale : une image
    en 224, un vecteur en sortie. C'est exactement la partie de `build_model`
    qui ne bouge pas pendant la phase de tête."""
    _, factory = BACKBONES[backbone]
    base = factory(input_shape=(IMAGE_SIZE, IMAGE_SIZE, 3), include_top=False, weights='imagenet',
                   include_preprocessing=True, minimalistic=False)
    base.trainable = False
    inputs = tf.keras.Input(shape=(IMAGE_SIZE, IMAGE_SIZE, 3), name='image')
    x = base(inputs, training=False)
    return tf.keras.Model(inputs, tf.keras.layers.GlobalAveragePooling2D()(x))


def encode(pairs, classes: list[str], batch: int, backbone: str, ram_budget_gb: float,
           label: str, x_path: Path | None = None, y_path: Path | None = None,
           mark=None, done: int = 0):
    """Passe les images dans le réseau gelé une fois pour toutes.

    Pendant la phase de tête, le réseau ne bouge pas : réencoder les mêmes
    images à chaque époque, c'est refaire quatre fois le même calcul. Une
    passe avant produit un vecteur par image ; la tête s'entraîne ensuite sur
    ces vecteurs, en secondes au lieu d'une demi-heure par époque.

    Les vecteurs sont écrits au fur et à mesure, pas à la fin. Cette passe
    dure plus d'une heure sur 232 000 images et la machine peut disparaître
    entre-temps : tout garder en mémoire jusqu'au bout, c'est tout perdre. On
    reprend au vecteur près.

    Le prix est le recadrage : les vecteurs sont ceux du carré central, sans
    augmentation. Pour une tête linéaire dont le seul rôle est de partir
    d'ailleurs que du hasard avant le réglage fin, c'est sans conséquence —
    et le réglage fin, lui, garde toutes ses augmentations.
    """
    ds, counts, paths = make_dataset(pairs, classes, batch, training=False,
                                     ram_budget_gb=ram_budget_gb, preload=False, skip=done)
    model = frozen_backbone(backbone)
    total = done + len(paths)
    chunks, labels, at, t0 = [], [], done, time.time()
    x = np.lib.format.open_memmap(x_path, mode='r+' if done else 'w+', dtype=np.float16,
                                  shape=(total, FEATURE_DIM[backbone])) if x_path else None
    y = np.lib.format.open_memmap(y_path, mode='r+' if done else 'w+', dtype=np.int32,
                                  shape=(total,)) if y_path else None
    for images, batch_labels in ds:
        vectors = model(images, training=False).numpy().astype(np.float16)
        n = int(batch_labels.shape[0])
        if x is not None:
            x[at:at + n] = vectors
            y[at:at + n] = batch_labels.numpy()
        else:
            chunks.append(vectors)
            labels.append(batch_labels.numpy())
        at += n
        if (at - done) % (batch * 100) < batch:
            if x is not None:
                x.flush()
                y.flush()
                if mark:
                    mark(at)
            rate = (at - done) / max(1e-6, time.time() - t0)
            print(f'  {label} : {at}/{total} encodées, {rate:.0f} img/s, '
                  f'reste {(total - at) / rate / 60:.0f} min', flush=True)
    if x is not None:
        x.flush()
        y.flush()
        if mark:
            mark(at)
        return x, y, counts
    return np.concatenate(chunks), np.concatenate(labels), counts


def encoded(cache: Path | None, name: str, signature: dict, encode_from):
    """Rend les vecteurs, en reprenant l'encodage là où il s'était arrêté.

    Le fichier de signature dit sur quel jeu et quel réseau les vecteurs ont
    été calculés, et combien sont écrits. Une signature qui ne correspond
    plus repart de zéro : mieux vaut une heure de calcul qu'une tête
    entraînée sur les vecteurs d'un autre jeu.
    """
    if cache is None:
        x, y, _ = encode_from(None, None, None, 0)
        return x, y
    cache.mkdir(parents=True, exist_ok=True)
    meta_p, x_p, y_p = cache / f'{name}.json', cache / f'{name}.x.npy', cache / f'{name}.y.npy'
    done, total = 0, signature['images']
    if meta_p.exists() and x_p.exists() and y_p.exists():
        meta = json.loads(meta_p.read_text())
        if {k: v for k, v in meta.items() if k != 'done'} == signature:
            done = int(meta.get('done', 0))
            if done >= total:
                print(f'  {name} : vecteurs relus du cache')
                return np.load(x_p, mmap_mode='r'), np.load(y_p, mmap_mode='r')
            print(f'  {name} : reprise à {done}/{total} vecteurs')
        else:
            print(f'  {name} : cache périmé, réencodage')

    def mark(at):
        meta_p.write_text(json.dumps({**signature, 'done': at}))

    x, y, _ = encode_from(x_p, y_p, mark, done)
    return x, y


def fit_head(x, y, val, n_classes: int, dropout: float, epochs: int, weights: dict, batch: int):
    """La tête seule, sur les vecteurs déjà calculés. Rend ses poids, à
    reposer dans le modèle complet avant le réglage fin."""
    head = tf.keras.Sequential([
        tf.keras.Input(shape=(x.shape[1],)),
        tf.keras.layers.Dropout(dropout),
        tf.keras.layers.Dense(n_classes, activation='softmax', name='species'),
    ])
    head.compile(optimizer=tf.keras.optimizers.Adam(1e-3),
                 loss='sparse_categorical_crossentropy', metrics=['accuracy'])
    head.fit(x.astype(np.float32), y, validation_data=(val[0].astype(np.float32), val[1]),
             epochs=epochs, batch_size=batch * 8, class_weight=weights, verbose=2,
             callbacks=[tf.keras.callbacks.EarlyStopping(monitor='val_accuracy', patience=3,
                                                         restore_best_weights=True)])
    return head.get_layer('species').get_weights()



def use_mixed_precision() -> str:
    """Calcule en float16 là où c'est sûr, accumule en float32.

    Sur une carte à cœurs tensor (RTX 20xx et au-delà), cela double à peu
    près le débit et divise la mémoire par deux, donc autorise des lots plus
    gros. Sur un processeur, cela ne rapporte rien et peut ralentir : c'est
    une option, pas un défaut.

    Les poids restent en float32 ; seuls les calculs intermédiaires passent
    en float16. La tête est déjà forcée en float32 (`build_model`), et
    l'export TFLite repart des poids, pas de la politique de calcul : le
    fichier livré est le même.
    """
    tf.keras.mixed_precision.set_global_policy('mixed_float16')
    return tf.keras.mixed_precision.global_policy().name


def describe_devices() -> str:
    """Ce sur quoi l'entraînement va réellement tourner.

    Une carte invisible — pilote absent, TensorFlow sans CUDA, WSL mal
    configuré — se traduit par un entraînement dix fois plus lent et par
    aucun message. Autant le dire au démarrage."""
    gpus = tf.config.list_physical_devices('GPU')
    if not gpus:
        return 'aucune carte graphique visible : entraînement sur processeur'
    for gpu in gpus:
        # Sans cela TensorFlow réserve toute la mémoire de la carte au
        # démarrage, et rien d'autre ne peut plus s'en servir.
        try:
            tf.config.experimental.set_memory_growth(gpu, True)
        except RuntimeError:
            pass
    return f'{len(gpus)} carte(s) graphique(s) : ' + ', '.join(g.name for g in gpus)


def build_model(n_classes: int, dropout: float, backbone: str = 'small') -> tf.keras.Model:
    """Le réseau : un MobileNetV3 pré-entraîné ImageNet, sans sa tête, puis
    la nôtre. `small` (2,5 Mo en float16, ~15 ms sur un téléphone récent)
    a servi jusqu'à la v3 ; `large` (≈ 11 Mo, trois fois plus de calcul)
    voit mieux les détails qui séparent deux espèces proches."""
    name, factory = BACKBONES[backbone]
    base = factory(
        input_shape=(IMAGE_SIZE, IMAGE_SIZE, 3), include_top=False, weights='imagenet',
        include_preprocessing=True, minimalistic=False)
    base.trainable = False
    inputs = tf.keras.Input(shape=(IMAGE_SIZE, IMAGE_SIZE, 3), name='image')
    x = base(inputs, training=False)
    x = tf.keras.layers.GlobalAveragePooling2D()(x)
    x = tf.keras.layers.Dropout(dropout)(x)
    # La dernière couche reste en float32, même en précision mixte : un
    # softmax en float16 déborde dès que les logits dépassent ~11, et les
    # probabilités rendues serviraient ensuite de seuil à l'application.
    outputs = tf.keras.layers.Dense(n_classes, activation='softmax', name='species', dtype='float32')(x)
    model = tf.keras.Model(inputs, outputs)
    model.base = base
    model.architecture = name
    return model


def class_weights(counts: Counter, n_classes: int) -> dict[int, float]:
    """Les classes rares comptent davantage : sans cela, le modèle apprend à
    répondre « Monstera » et a raison une fois sur dix."""
    total = sum(counts.values())
    return {i: total / (n_classes * max(1, counts.get(i, 0))) for i in range(n_classes)}


def evaluate(model, ds, classes: list[str], captive_mask=None) -> dict:
    """Top-1, top-3, macro-F1, et la courbe seuil / taux de repli qui sert à
    régler FallbackPolicy côté application."""
    probs, truth = [], []
    for images, labels in ds:
        probs.append(model.predict(images, verbose=0))
        truth.append(labels.numpy())
    if not probs:
        return {}
    probs = np.concatenate(probs)
    truth = np.concatenate(truth)
    order = np.argsort(-probs, axis=1)
    top1 = order[:, 0]
    correct = top1 == truth
    top3 = np.mean([t in o[:3] for t, o in zip(truth, order)])

    f1s = []
    for c in range(len(classes)):
        tp = int(np.sum((top1 == c) & (truth == c)))
        fp = int(np.sum((top1 == c) & (truth != c)))
        fn = int(np.sum((top1 != c) & (truth == c)))
        if tp + fn == 0:
            continue
        precision = tp / (tp + fp) if tp + fp else 0.0
        recall = tp / (tp + fn)
        f1s.append(2 * precision * recall / (precision + recall) if precision + recall else 0.0)

    best = np.take_along_axis(probs, order[:, :2], axis=1)
    margin = best[:, 0] - best[:, 1]

    # Le chiffre qui compte pour l'application : sur les seules photos de
    # plantes cultivées, en pot, chez des gens. Le reste du jeu est fait de
    # plantes sauvages, que personne ne photographie dans son salon.
    captive_metrics = None
    if captive_mask is not None:
        mask = np.asarray(list(captive_mask), dtype=bool)[:len(truth)]
        if int(mask.sum()) > 0:
            c_top3 = np.mean([t in o[:3] for t, o in zip(truth[mask], order[mask])])
            c_rows = []
            for threshold in (0.5, 0.7, 0.9):
                acc = (best[mask][:, 0] >= threshold)
                n = int(acc.sum())
                c_rows.append({'threshold': threshold, 'accepted_rate': round(n / int(mask.sum()), 4),
                               'precision_when_accepted': round(float(np.mean(correct[mask][acc])), 4) if n else None})
            captive_metrics = {'images': int(mask.sum()), 'top1': round(float(np.mean(correct[mask])), 4),
                               'top3': round(float(c_top3), 4), 'threshold_curve': c_rows}
    curve = []
    for threshold in (0.5, 0.6, 0.7, 0.8, 0.85, 0.9, 0.95):
        for min_margin in (0.0, 0.15, 0.25, 0.4):
            accepted = (best[:, 0] >= threshold) & (margin >= min_margin)
            n = int(np.sum(accepted))
            curve.append({
                'threshold': threshold, 'min_margin': min_margin,
                'accepted_rate': round(n / len(truth), 4),
                'precision_when_accepted': round(float(np.mean(correct[accepted])), 4) if n else None,
            })
    return {
        'images': int(len(truth)), 'top1': round(float(np.mean(correct)), 4), 'top3': round(float(top3), 4),
        'macro_f1': round(float(np.mean(f1s)), 4) if f1s else None,
        'mean_confidence': round(float(np.mean(best[:, 0])), 4),
        'threshold_curve': curve,
        'captive': captive_metrics,
    }


def export_tflite(model, out: Path, classes: list[str], names: dict, metrics: dict, quantize_ds=None) -> dict:
    out.mkdir(parents=True, exist_ok=True)
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.target_spec.supported_types = [tf.float16]
    blob = converter.convert()
    model_path = out / 'plants.tflite'
    model_path.write_bytes(blob)
    (out / 'labels.txt').write_text('\n'.join(classes) + '\n', encoding='utf-8')
    meta = {
        'version': metrics.get('version', '1'),
        'input_size': IMAGE_SIZE,
        # La recette de prétraitement, pour que l'application applique
        # exactement la même : redimensionner le carré central à `load_size`
        # puis recadrer au centre à `input_size`. Redimensionner directement
        # à 224 change le cadrage et coûte plusieurs points de précision.
        'load_size': LOAD_SIZE,
        # Taille à laquelle les images du jeu ont été réduites au stockage.
        # L'application refait la même réduction en deux temps sur les photos
        # de l'appareil, sans quoi elle nourrirait le modèle d'images plus
        # crénelées que tout ce qu'il a vu.
        'source_size': SOURCE_SIZE,
        'classes': len(classes),
        'architecture': getattr(model, 'architecture', 'MobileNetV3Small'),
        'preprocessing': 'included_in_graph_uint8_0_255',
        'sha256': hashlib.sha256(blob).hexdigest(),
        'bytes': len(blob),
        'metrics': {k: v for k, v in metrics.items() if k != 'threshold_curve'},
        'threshold_curve': metrics.get('threshold_curve', []),
        'species': {c: names.get(c, c) for c in classes},
    }
    (out / 'model.json').write_text(json.dumps(meta, ensure_ascii=False, indent=1), encoding='utf-8')
    return meta


def species_names(dataset: Path) -> dict:
    """internal_id → nom scientifique, lu dans le manifeste."""
    names = {}
    with open(dataset / 'manifest.jsonl', encoding='utf-8') as f:
        for line in f:
            r = json.loads(line)
            names.setdefault(r['internal_plant_id'], r['species'])
    return names


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--dataset', default='../plant_dataset/dataset')
    ap.add_argument('--out', default='../../assets/model')
    ap.add_argument('--batch', type=int, default=32)
    ap.add_argument('--head-epochs', type=int, default=4)
    ap.add_argument('--fine-epochs', type=int, default=12)
    ap.add_argument('--dropout', type=float, default=0.3)
    ap.add_argument('--min-train', type=int, default=25, help='images d\'entraînement minimales par classe')
    ap.add_argument('--min-val', type=int, default=3)
    ap.add_argument('--unfreeze', type=int, default=60, help='couches dégelées en fin de réseau')
    ap.add_argument('--fine-lr', type=float, default=5e-5, help='taux d\'apprentissage du réglage fin')
    ap.add_argument('--version', default='1')
    ap.add_argument('--backbone', choices=sorted(BACKBONES), default='small', help='MobileNetV3 small (v1 à v3) ou large')
    ap.add_argument('--input-size', type=int, default=IMAGE_SIZE,
                    help="côté de l'entrée du réseau, en pixels ; le chargement suit à la même "
                         'marge de recadrage. 320 est le levier classique de la reconnaissance fine, '
                         "au prix d'une inférence deux fois plus lourde sur le téléphone")
    ap.add_argument('--ram-budget', type=float, default=5.0, help='Go de préchargement au plus ; au-delà, lecture depuis les fichiers')
    ap.add_argument('--steps-per-epoch', type=int, help='lots par époque ; une époque courte = des points de sauvegarde fréquents')
    ap.add_argument('--val-max', type=int, default=6000, help='images de validation pendant l\'entraînement ; l\'évaluation finale reste complète')
    ap.add_argument('--checkpoint', help='dossier où les poids sont sauvés après chaque époque, et d\'où l\'entraînement reprend')
    ap.add_argument('--feature-cache', help='dossier où garder les activations du réseau gelé ; la phase de tête devient une passe avant au lieu de N époques')
    ap.add_argument('--mixed-precision', action='store_true', help='calcul en float16 : double le débit sur une carte à cœurs tensor, inutile sur processeur')
    args = ap.parse_args()
    # Avant toute lecture du jeu ou construction du réseau : tout le reste du
    # fichier lit ces constantes au moment de s'en servir.
    if args.input_size != IMAGE_SIZE:
        set_input_size(args.input_size)

    print(describe_devices(), flush=True)
    if args.mixed_precision:
        print(f'précision mixte : {use_mixed_precision()}', flush=True)

    dataset = Path(args.dataset)
    rows, captive = read_splits(dataset)
    classes = usable_classes(rows, args.min_train, args.min_val)
    if len(classes) < 2:
        raise SystemExit(f'{len(classes)} classe(s) exploitable(s) : collecte insuffisante')
    names = species_names(dataset)
    print(f'{len(classes)} classes, {len(rows["train"])} train / {len(rows["val"])} val / {len(rows["test"])} test')

    train_ds, counts, _ = make_dataset(rows['train'], classes, args.batch, training=True, ram_budget_gb=args.ram_budget,
                                       repeat=bool(args.steps_per_epoch))
    # La validation d'époque se fait sur un échantillon : elle sert à suivre
    # la courbe et à décider de l'arrêt, pas à mesurer le modèle. La mesure,
    # c'est le jeu de test à la fin, entier. Les deux se lisent depuis les
    # fichiers : précharger 47 000 JPEG coûtait dix minutes au démarrage, et
    # cette machine redémarre souvent.
    val_rows = rows['val']
    if args.val_max and len(val_rows) > args.val_max:
        val_rows = random.Random(SHUFFLE_SEED).sample(val_rows, args.val_max)
    val_ds, _, _ = make_dataset(val_rows, classes, args.batch, training=False, ram_budget_gb=args.ram_budget, preload=False)

    model = build_model(len(classes), args.dropout, args.backbone)
    weights = class_weights(counts, len(classes))

    # Points de sauvegarde : dix heures d'entraînement sur une machine qui
    # peut redémarrer sans prévenir. Les poids sont écrits après la tête,
    # puis après chaque époque du réglage fin, avec le compte des époques
    # faites ; au relancement avec le même dossier, on reprend là.
    # Points de sauvegarde. Cette machine peut disparaître à tout moment et
    # une époque coûte une demi-heure : les poids sont donc écrits aussi en
    # cours d'époque, et pas seulement à la fin. Seule la fin fait avancer le
    # compteur d'époques ; reprendre au milieu d'une époque revient à la
    # refaire depuis des poids un peu plus avancés, ce qui ne coûte rien.
    ckpt = Path(args.checkpoint) if args.checkpoint else None
    head_w = ckpt / 'head.weights.h5' if ckpt else None
    fine_w = ckpt / 'fine.weights.h5' if ckpt else None
    state_p = ckpt / 'state.json' if ckpt else None
    state = json.loads(state_p.read_text()) if state_p and state_p.exists() else {}
    head_done = state.get('head_epochs_done', 0)
    fine_done = state.get('fine_epochs_done', 0)
    if ckpt:
        ckpt.mkdir(parents=True, exist_ok=True)

    def _save_state(**kw):
        state.update(kw)
        state_p.write_text(json.dumps(state))

    class _Checkpoint(tf.keras.callbacks.Callback):
        def __init__(self, path, key, every=200):
            super().__init__()
            self.path, self.key, self.every = path, key, every
            self.t0 = time.time()

        def on_train_batch_end(self, batch, logs=None):
            if batch and batch % self.every == 0:
                self.model.save_weights(self.path)
                # Un battement de cœur : sur une machine qui redémarre, c'est
                # la seule façon de savoir si l'entraînement avance vraiment.
                print(f'  lot {batch} sauvé, {time.time() - self.t0:.0f} s', flush=True)

        def on_epoch_end(self, epoch, logs=None):
            self.model.save_weights(self.path)
            _save_state(**{self.key: epoch + 1, 'val_accuracy': float((logs or {}).get('val_accuracy', 0))})

    in_fine = bool(fine_w and fine_w.exists())
    model.compile(optimizer=tf.keras.optimizers.Adam(1e-3),
                  loss='sparse_categorical_crossentropy', metrics=['accuracy'])
    if in_fine:
        print(f'reprise : réglage fin, {fine_done} époque(s) terminée(s)')
    elif head_w and head_w.exists():
        model.load_weights(head_w)
        print(f'reprise : tête, {head_done} époque(s) terminée(s)')
    if not in_fine and head_done < args.head_epochs:
        if args.feature_cache:
            # Le réseau est gelé : les vecteurs qu'il produit ne changent pas
            # d'une époque à l'autre. On les calcule une fois, puis la tête
            # s'entraîne dessus en quelques minutes au lieu d'une demi-heure
            # par époque — et peut aller jusqu'à convergence, ce qui donne au
            # réglage fin un bien meilleur point de départ que quatre époques.
            cache = Path(args.feature_cache)
            signature = {'backbone': args.backbone, 'input': IMAGE_SIZE, 'classes': len(classes),
                         'fingerprint': hashlib.sha256('\n'.join(classes).encode()).hexdigest()[:16]}
            def encoder(pairs, label):
                def run(x_p, y_p, mark, done):
                    return encode(pairs, classes, args.batch, args.backbone, args.ram_budget,
                                  label, x_p, y_p, mark, done)
                return run

            x, y = encoded(cache, 'train', {**signature, 'images': usable_count(rows['train'], classes)},
                           encoder(rows['train'], 'entraînement'))
            xv, yv = encoded(cache, 'val', {**signature, 'images': usable_count(val_rows, classes)},
                             encoder(val_rows, 'validation'))
            print(f'tête sur vecteurs : {x.shape[0]} × {x.shape[1]}, validation {xv.shape[0]}')
            model.get_layer('species').set_weights(
                fit_head(x, y, (xv, yv), len(classes), args.dropout, args.head_epochs, weights, args.batch))
            del x, y, xv, yv
            if ckpt:
                model.save_weights(head_w)
                _save_state(head_epochs_done=args.head_epochs)
        else:
            model.fit(train_ds, validation_data=val_ds, initial_epoch=head_done, epochs=args.head_epochs,
                      steps_per_epoch=args.steps_per_epoch, class_weight=weights, verbose=2,
                      callbacks=[_Checkpoint(head_w, 'head_epochs_done')] if ckpt else [])

    model.base.trainable = True
    for layer in model.base.layers[:-args.unfreeze]:
        layer.trainable = False
    # Les couches de normalisation par lots restent figées : dégelées, elles
    # recalculent leurs moyennes sur des lots de 32 images et détruisent en
    # une époque ce que le pré-entraînement ImageNet avait établi. C'est la
    # cause classique d'une validation qui chute au début du réglage fin.
    frozen_bn = 0
    for layer in model.base.layers:
        if isinstance(layer, tf.keras.layers.BatchNormalization):
            layer.trainable = False
            frozen_bn += 1
    print(f'réglage fin : {args.unfreeze} couches dégelées, {frozen_bn} normalisations figées')
    model.compile(optimizer=tf.keras.optimizers.Adam(args.fine_lr),
                  loss='sparse_categorical_crossentropy', metrics=['accuracy'])
    if in_fine:
        model.load_weights(fine_w)
    callbacks = [tf.keras.callbacks.EarlyStopping(monitor='val_accuracy', patience=4, restore_best_weights=True)]
    if ckpt:
        callbacks.append(_Checkpoint(fine_w, 'fine_epochs_done'))
    if fine_done < args.fine_epochs:
        model.fit(train_ds, validation_data=val_ds, initial_epoch=fine_done, epochs=args.fine_epochs,
                  steps_per_epoch=args.steps_per_epoch, class_weight=weights, verbose=2, callbacks=callbacks)

    if args.mixed_precision:
        # Le convertisseur TFLite ne sait pas convertir un graphe en float16 :
        # il réclame des « flex ops », que l'application n'embarque pas. Les
        # poids, eux, sont restés en float32 — la précision mixte ne change
        # que les calculs intermédiaires. On reconstruit donc le réseau en
        # float32 et on y repose les poids appris.
        #
        # Le basculement se fait *avant* l'évaluation, pas seulement avant
        # l'export : ainsi les chiffres publiés dans `model.json` sont ceux
        # du fichier livré, et non ceux d'un modèle qui lui ressemble.
        tf.keras.mixed_precision.set_global_policy('float32')
        weights = model.get_weights()
        model = build_model(len(classes), args.dropout, args.backbone)
        model.set_weights(weights)
        print('précision mixte : réseau reconstruit en float32 pour l\'évaluation et l\'export', flush=True)

    test_ds, _, test_paths = make_dataset(rows['test'], classes, args.batch, training=False,
                                          ram_budget_gb=args.ram_budget, preload=False)
    metrics = evaluate(model, test_ds, classes, captive_mask=[p in captive for p in test_paths])
    metrics['version'] = args.version
    print(json.dumps({k: v for k, v in metrics.items() if k != 'threshold_curve'}, indent=1))
    if metrics.get('captive'):
        c = metrics['captive']
        print(f"plantes cultivées ({c['images']} images de test) : top1 {c['top1']}, top3 {c['top3']}")

    meta = export_tflite(model, Path(args.out), classes, names, metrics)
    print(f'modèle écrit : {args.out}/plants.tflite — {meta["bytes"] / 1e6:.1f} Mo, {meta["classes"]} classes')
    for row in metrics.get('threshold_curve', []):
        if row['min_margin'] == 0.25 and row['threshold'] in (0.8, 0.9):
            print(f'  seuil {row["threshold"]} marge 0.25 → {row["accepted_rate"]:.0%} acceptées, '
                  f'précision {row["precision_when_accepted"]}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
