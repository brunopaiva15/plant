#!/usr/bin/env python3
"""Pl@ntNet-300K, converti pour tourner dans l'application à côté d'Iris.

    python3 plantnet300k_export.py --out ../../assets/model/plantnet300k

Un banc d'essai, pas un remplaçant : le réglage « Comparer avec
Pl@ntNet-300K » fait passer chaque photo par les deux modèles, et c'est sur
des photos réelles que se décidera s'il vaut mieux qu'Iris (§ 15 de
`docs/09-plant-recognition.md`).

Les poids sont ceux que publient les auteurs du jeu (Garcin et al., NeurIPS
2021), des réseaux PyTorch entraînés sur ses 1 081 classes. Le script les
télécharge et les exporte avec `labels.txt` et `model.json` ; le contrat
avec l'application est dans `comparaison.py`.

Par défaut le MobileNetV3-Large : la dorsale d'Iris, entraînée sur d'autres
images. La comparaison mesure alors le jeu et non l'architecture. `--arch`
en prend une autre de la liste publiée (`resnet50`, `efficientnet_b0`…),
au prix du poids.

Dépendances, à part de `requirements.txt` parce qu'elles tirent PyTorch :

    python3 -m pip install litert-torch torchvision pillow
"""
from __future__ import annotations

import argparse
import json
import sys
import urllib.parse
from pathlib import Path

from comparaison import PRECISIONS, convertir, ecrire, emballer, entrees, telecharger, verifier
from comparaison import etiquettes as _etiquettes

#: Poids et métadonnées, aux adresses que donne le dépôt PlantNet-300K.
POIDS = 'https://seafile.plantnet.org/d/01ab6658dad6447c95ae/files/?p=%2F{}_weights_best_acc.tar&dl=1'
METADONNEES = 'https://seafile.plantnet.org/d/bed81bc15e8944969cf6/files/?p=%2F{}&dl=1'
CLASSES = 'class_idx_to_species_id.json'
NOMS = 'plantnet300K_species_id_2_name.json'

#: La recette d'évaluation des auteurs (`get_data` de leur `utils.py`) :
#: `Resize(256)` sur le petit côté, `CenterCrop(224)`, normalisation
#: ImageNet — leurs réseaux partent des poids ImageNet (`--pretrained`).
#: Carré central, 256, recadrage à 224 : c'est exactement ce que fait
#: l'application avec `load_size` et `input_size`.
INPUT_SIZE = 224
LOAD_SIZE = 256
#: La réduction de qualité avant le bilinéaire. torchvision réduit avec
#: anticrénelage ; l'application s'en approche en passant d'abord par une
#: moyenne de zone à cette taille (voir `TflitePlantModel._decode`).
SOURCE_SIZE = 512


def etiquettes(classes: dict[str, str], noms: dict[str, str]) -> tuple[list[str], list[int], dict[str, str]]:
    """Leurs deux fichiers — indice → identifiant d'espèce → nom — ramenés
    à la liste des noms dans l'ordre du réseau."""
    ordre = sorted(classes, key=int)
    if [int(i) for i in ordre] != list(range(len(ordre))):
        raise SystemExit(f'{CLASSES} : indices non contigus')
    return _etiquettes([noms[classes[i]] for i in ordre])


def modele(arch: str, poids: Path, vers: list[int], n_especes: int):
    import torch
    import torchvision.models as tvm

    reseau = getattr(tvm, arch)(num_classes=len(vers))
    etat = torch.load(poids, map_location='cpu', weights_only=False)
    reseau.load_state_dict(etat['model'])
    return emballer(reseau.eval(), vers, n_especes)


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--arch', default='mobilenet_v3_large', help='un des réseaux publiés par les auteurs')
    ap.add_argument('--out', default='../../assets/model/plantnet300k')
    ap.add_argument('--cache', default='.cache/plantnet300k')
    ap.add_argument('--precision', choices=PRECISIONS, default='float16', help='celle d\'Iris par défaut')
    ap.add_argument('--check', nargs='*', type=Path, default=[], help='photos à passer dans les deux graphes')
    args = ap.parse_args(argv)

    cache, out = Path(args.cache), Path(args.out)
    classes = json.loads(telecharger(METADONNEES.format(CLASSES), cache / CLASSES).read_text())
    noms = json.loads(telecharger(METADONNEES.format(NOMS), cache / NOMS).read_text())
    labels, vers, especes = etiquettes(classes, noms)
    poids = telecharger(POIDS.format(urllib.parse.quote(args.arch)), cache / f'{args.arch}_weights_best_acc.tar')

    module = modele(args.arch, poids, vers, len(labels))
    out.mkdir(parents=True, exist_ok=True)
    fichier = out / 'plants.tflite'
    blob = convertir(module, fichier, args.precision, INPUT_SIZE)
    xs = entrees(args.check, INPUT_SIZE, LOAD_SIZE, SOURCE_SIZE)
    controle = verifier(module, fichier, xs, [p.name for p in args.check], labels)
    print(f'  PyTorch contre TFLite : {controle}')

    ecrire(out, blob, labels, especes, {
        'version': '300K',
        'input_size': INPUT_SIZE,
        'load_size': LOAD_SIZE,
        'source_size': SOURCE_SIZE,
        'network_outputs': len(vers),
        'architecture': args.arch,
        'weights': args.precision,
        'source': {
            'dataset': 'Pl@ntNet-300K (Zenodo 5645731)',
            'weights': POIDS.format(args.arch),
            'license': 'dataset CC BY 4.0, code BSD-2; weights: no license stated',
            'citation': 'Garcin et al., Pl@ntNet-300K: a plant image dataset with high label ambiguity '
                        'and a long-tailed distribution, NeurIPS Datasets and Benchmarks 2021',
        },
        'conversion_check': controle,
    })
    print(f'{args.arch} : {len(vers)} sorties, {len(labels)} espèces, {len(blob) / 1e6:.2f} Mo → {out}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
