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
from collections import Counter
from pathlib import Path

import numpy as np
import tensorflow as tf

IMAGE_SIZE = 224
AUTOTUNE = tf.data.AUTOTUNE
UNKNOWN = '_unknown'


def read_splits(dataset: Path) -> dict[str, list[tuple[str, str]]]:
    """{split: [(chemin absolu, internal_id)]}, tel qu'écrit par build_dataset."""
    rows: dict[str, list[tuple[str, str]]] = {'train': [], 'val': [], 'test': []}
    with open(dataset / 'splits.csv', newline='', encoding='utf-8') as f:
        for row in csv.DictReader(f):
            path = dataset / row['path']
            if path.exists():
                rows[row['split']].append((str(path), row['internal_plant_id']))
    return rows


def usable_classes(rows: dict, min_train: int, min_val: int) -> list[str]:
    """Une classe n'entre dans le modèle que si elle a de quoi apprendre *et*
    de quoi être évaluée. Une classe à 3 images produirait un score illisible."""
    train = Counter(pid for _, pid in rows['train'])
    val = Counter(pid for _, pid in rows['val'])
    return sorted(c for c in train if train[c] >= min_train and val[c] >= min_val)


LOAD_SIZE = 256  # on garde un peu de marge autour de 224 pour le recadrage


def load_all(pairs, classes: list[str]) -> tuple[np.ndarray, np.ndarray]:
    """Décode une fois pour toutes en mémoire, en 256×256 uint8.

    Décoder un JPEG de 1024 px coûte ~15 ms ; le refaire à chaque époque
    ferait passer l'essentiel du temps d'entraînement dans le décodeur.
    9 000 images tiennent dans 1,8 Go — c'est le bon compromis ici.
    """
    index = {c: i for i, c in enumerate(classes)}
    usable = [(p, index[pid]) for p, pid in pairs if pid in index]
    if not usable:
        raise SystemExit('aucune image utilisable ; le jeu de données est-il construit ?')
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


def read_and_square(path, label):
    """Lit un JPEG et le ramène au carré central de LOAD_SIZE, comme le
    préchargement en mémoire. Les deux chemins doivent donner la même image,
    sinon les mesures ne veulent plus rien dire."""
    image = tf.io.decode_jpeg(tf.io.read_file(path), channels=3)
    side = tf.reduce_min(tf.shape(image)[:2])
    image = tf.image.resize_with_crop_or_pad(image, side, side)
    image = tf.image.resize(image, [LOAD_SIZE, LOAD_SIZE])
    return tf.cast(image, tf.uint8), label


def make_dataset(pairs, classes: list[str], batch: int, training: bool, ram_budget_gb: float = 6.0):
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
    counts = Counter(label for _, label in usable)
    estimate = len(usable) * LOAD_SIZE * LOAD_SIZE * 3 / 1e9

    if estimate <= ram_budget_gb:
        images, labels = load_all(pairs, classes)
        ds = tf.data.Dataset.from_tensor_slices((images, labels))
    else:
        print(f'  {len(usable)} images = {estimate:.1f} Go > budget {ram_budget_gb} Go : lecture depuis les fichiers')
        paths = [p for p, _ in usable]
        labels = [l for _, l in usable]
        ds = tf.data.Dataset.from_tensor_slices((paths, labels)).map(read_and_square, num_parallel_calls=AUTOTUNE)

    if training:
        ds = ds.shuffle(min(len(usable), 4096), reshuffle_each_iteration=True).map(augment, num_parallel_calls=AUTOTUNE)
    else:
        ds = ds.map(center, num_parallel_calls=AUTOTUNE)
    return ds.batch(batch).prefetch(AUTOTUNE), counts


def build_model(n_classes: int, dropout: float) -> tf.keras.Model:
    base = tf.keras.applications.MobileNetV3Small(
        input_shape=(IMAGE_SIZE, IMAGE_SIZE, 3), include_top=False, weights='imagenet',
        include_preprocessing=True, minimalistic=False)
    base.trainable = False
    inputs = tf.keras.Input(shape=(IMAGE_SIZE, IMAGE_SIZE, 3), name='image')
    x = base(inputs, training=False)
    x = tf.keras.layers.GlobalAveragePooling2D()(x)
    x = tf.keras.layers.Dropout(dropout)(x)
    outputs = tf.keras.layers.Dense(n_classes, activation='softmax', name='species')(x)
    model = tf.keras.Model(inputs, outputs)
    model.base = base
    return model


def class_weights(counts: Counter, n_classes: int) -> dict[int, float]:
    """Les classes rares comptent davantage : sans cela, le modèle apprend à
    répondre « Monstera » et a raison une fois sur dix."""
    total = sum(counts.values())
    return {i: total / (n_classes * max(1, counts.get(i, 0))) for i in range(n_classes)}


def evaluate(model, ds, classes: list[str]) -> dict:
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
        'classes': len(classes),
        'architecture': 'MobileNetV3Small',
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
    ap.add_argument('--ram-budget', type=float, default=6.0, help='Go de préchargement au plus ; au-delà, lecture depuis les fichiers')
    args = ap.parse_args()

    dataset = Path(args.dataset)
    rows = read_splits(dataset)
    classes = usable_classes(rows, args.min_train, args.min_val)
    if len(classes) < 2:
        raise SystemExit(f'{len(classes)} classe(s) exploitable(s) : collecte insuffisante')
    names = species_names(dataset)
    print(f'{len(classes)} classes, {len(rows["train"])} train / {len(rows["val"])} val / {len(rows["test"])} test')

    train_ds, counts = make_dataset(rows['train'], classes, args.batch, training=True, ram_budget_gb=args.ram_budget)
    val_ds, _ = make_dataset(rows['val'], classes, args.batch, training=False, ram_budget_gb=args.ram_budget)
    test_ds, _ = make_dataset(rows['test'], classes, args.batch, training=False, ram_budget_gb=args.ram_budget)

    model = build_model(len(classes), args.dropout)
    weights = class_weights(counts, len(classes))

    model.compile(optimizer=tf.keras.optimizers.Adam(1e-3),
                  loss='sparse_categorical_crossentropy', metrics=['accuracy'])
    model.fit(train_ds, validation_data=val_ds, epochs=args.head_epochs, class_weight=weights, verbose=2)

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
    model.fit(train_ds, validation_data=val_ds, epochs=args.fine_epochs, class_weight=weights, verbose=2,
              callbacks=[tf.keras.callbacks.EarlyStopping(monitor='val_accuracy', patience=4, restore_best_weights=True)])

    metrics = evaluate(model, test_ds, classes)
    metrics['version'] = args.version
    print(json.dumps({k: v for k, v in metrics.items() if k != 'threshold_curve'}, indent=1))

    meta = export_tflite(model, Path(args.out), classes, names, metrics)
    print(f'modèle écrit : {args.out}/plants.tflite — {meta["bytes"] / 1e6:.1f} Mo, {meta["classes"]} classes')
    for row in metrics.get('threshold_curve', []):
        if row['min_margin'] == 0.25 and row['threshold'] in (0.8, 0.9):
            print(f'  seuil {row["threshold"]} marge 0.25 → {row["accepted_rate"]:.0%} acceptées, '
                  f'précision {row["precision_when_accepted"]}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
