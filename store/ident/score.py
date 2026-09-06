#!/usr/bin/env python3
"""Ce que le modèle livré (assets/model) répond sur des photos.

    python3 store/ident/score.py store/ident/ficus-lyrata.jpg

Sert à recalculer IDENT_RESULTS dans store/compose.py après chaque nouveau
modèle : le visuel « Quelle est cette plante ? » montre de vrais résultats.
Le prétraitement est celui de l'app (tflite_plant_model.dart) : carré
central, 448 puis 256 px, recadrage à 224.
"""
import csv
import os
import sys

import numpy as np
from PIL import Image

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..')


def main(paths):
    import tensorflow as tf
    labels = [l.strip() for l in open(os.path.join(ROOT, 'assets/model/labels.txt')) if l.strip()]
    with open(os.path.join(ROOT, 'tools/plant_dataset/plants.csv'), newline='', encoding='utf-8') as f:
        names = {r['internal_id']: r['scientific_name'] for r in csv.DictReader(f)}
    it = tf.lite.Interpreter(model_path=os.path.join(ROOT, 'assets/model/plants.tflite'))
    it.allocate_tensors()
    inp, out = it.get_input_details()[0], it.get_output_details()[0]
    for p in paths:
        im = Image.open(p).convert('RGB')
        w, h = im.size
        s = min(w, h)
        im = im.crop(((w - s) // 2, (h - s) // 2, (w - s) // 2 + s, (h - s) // 2 + s))
        im = im.resize((448, 448), Image.BOX).resize((256, 256), Image.BILINEAR).crop((16, 16, 240, 240))
        it.set_tensor(inp['index'], np.asarray(im).astype(inp['dtype'])[None])
        it.invoke()
        pr = it.get_tensor(out['index'])[0].astype(float)
        top = [(names.get(labels[i], labels[i]), round(float(pr[i]), 3)) for i in np.argsort(-pr)[:3]]
        print(os.path.basename(p), top)


if __name__ == '__main__':
    main(sys.argv[1:])
