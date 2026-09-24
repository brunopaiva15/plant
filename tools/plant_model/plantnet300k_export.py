#!/usr/bin/env python3
"""Pl@ntNet-300K, converti pour tourner dans l'application à côté d'Iris.

    python3 plantnet300k_export.py --out ../../assets/model/plantnet300k

Un banc d'essai, pas un remplaçant : le réglage « Comparer avec
Pl@ntNet-300K » fait passer chaque photo par les deux modèles, et c'est sur
des photos réelles que se décidera s'il vaut mieux qu'Iris (§ 15 de
`docs/09-plant-recognition.md`).

Les poids sont ceux que publient les auteurs du jeu (Garcin et al., NeurIPS
2021), des réseaux PyTorch entraînés sur ses 1 081 espèces. Le script les
télécharge, leur ajoute ce qu'attend `TflitePlantModel` — une entrée NHWC en
octets 0–255, la normalisation ImageNet dans le graphe, un softmax en
sortie — et les exporte en TFLite avec `labels.txt` et `model.json`, les
trois fichiers que lit l'application. Rien d'autre ne change côté Dart.

Par défaut le MobileNetV3-Large : la dorsale d'Iris, entraînée sur d'autres
images. La comparaison mesure alors le jeu et non l'architecture. `--arch`
en prend une autre de la liste publiée (`resnet50`, `efficientnet_b0`…),
au prix du poids.

Dépendances, à part de `requirements.txt` parce qu'elles tirent PyTorch :

    python3 -m pip install litert-torch torchvision pillow
"""
from __future__ import annotations

import argparse
import hashlib
import json
import sys
import urllib.parse
import urllib.request
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'plant_dataset'))

from plant_dataset.taxonomy import internal_id, normalize_scientific_name  # noqa: E402

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
MEAN = (0.485, 0.456, 0.406)
STD = (0.229, 0.224, 0.225)


def telecharger(url: str, cible: Path) -> Path:
    if cible.exists():
        return cible
    cible.parent.mkdir(parents=True, exist_ok=True)
    print(f'  téléchargement de {cible.name}…', file=sys.stderr, flush=True)
    partiel = cible.with_suffix(cible.suffix + '.part')
    urllib.request.urlretrieve(url, partiel)
    partiel.rename(cible)
    return cible


def etiquettes(classes: dict[str, str], noms: dict[str, str]) -> tuple[list[str], list[int], dict[str, str]]:
    """Nos identifiants, et pour chaque sortie du réseau celui qu'elle nomme.

    Leurs noms portent l'auteur (« Lactuca virosa L. ») ; l'application
    attend nos identifiants (« lactuca-virosa »), qu'elle rattache ensuite au
    catalogue pour trouver le nom courant. Même normalisation que la collecte,
    sinon rien ne se rencontre.

    Leurs 1 081 classes ne font que 1 019 espèces : la même plante y figure
    parfois sous deux ou trois citations d'auteur (« Tradescantia zebrina
    Bosse », « … hort. ex Bosse »). Laissées telles quelles, elles
    s'afficheraient deux fois et se partageraient le score. Le graphe les
    additionne (voir [modele]) ; ici, on dit lesquelles vont ensemble.
    """
    ordre = sorted(classes, key=int)
    if [int(i) for i in ordre] != list(range(len(ordre))):
        raise SystemExit(f'{CLASSES} : indices non contigus')
    labels, rang, especes = [], {}, {}
    vers = []
    for i in ordre:
        nom = normalize_scientific_name(noms[classes[i]])
        ident = internal_id(nom)
        if not ident:
            raise SystemExit(f'classe {i} : nom illisible « {noms[classes[i]]} »')
        if ident not in rang:
            rang[ident] = len(labels)
            labels.append(ident)
            especes[ident] = nom
        vers.append(rang[ident])
    return labels, vers, especes


def modele(arch: str, poids: Path, vers: list[int], n_especes: int):
    """Le réseau des auteurs, tête comprise, dans le graphe que lit l'app.

    [vers] donne, pour chaque sortie du réseau, l'espèce qu'elle nomme : les
    probabilités des doublons s'additionnent dans le graphe, par un produit
    avec une matrice de 0 et de 1. Additionner des probabilités, et non des
    logits, c'est exactement ce que vaut « l'une ou l'autre citation ».
    """
    import torch
    import torchvision.models as tvm

    fusion = torch.zeros(len(vers), n_especes)
    fusion[torch.arange(len(vers)), torch.tensor(vers)] = 1.0
    reseau = getattr(tvm, arch)(num_classes=len(vers))
    etat = torch.load(poids, map_location='cpu', weights_only=False)
    reseau.load_state_dict(etat['model'])
    reseau.eval()

    class Emballage(torch.nn.Module):
        """NHWC 0–255 → probabilités : le contrat de `TflitePlantModel`."""

        def __init__(self, coeur):
            super().__init__()
            self.coeur = coeur
            self.register_buffer('mean', torch.tensor(MEAN).view(1, 3, 1, 1) * 255.0)
            self.register_buffer('std', torch.tensor(STD).view(1, 3, 1, 1) * 255.0)
            self.register_buffer('fusion', fusion)

        def forward(self, x):
            x = x.permute(0, 3, 1, 2)
            x = (x - self.mean) / self.std
            return torch.softmax(self.coeur(x), dim=-1) @ self.fusion

    return Emballage(reseau).eval()


def convertir(module, cible: Path, demi: bool) -> bytes:
    import litert_torch
    import torch

    exemple = (torch.rand(1, INPUT_SIZE, INPUT_SIZE, 3) * 255.0,)
    litert_torch.convert(module, exemple).export(str(cible))
    if not demi:
        return cible.read_bytes()
    # Poids en demi-précision, calcul en flottant : comme Iris
    # (`export_tflite` de train.py), deux fois plus léger pour un écart que
    # la vérification qui suit chiffre sur les mêmes entrées.
    from ai_edge_quantizer import algorithm_manager, model_modifier, quantizer, recipe_manager
    from ai_edge_quantizer.qtyping import TFLOperationName

    # Au-delà de 256 Ko de poids, le quantificateur les range **après** le
    # flatbuffer et ne laisse dedans que leur position. Le TensorFlow Lite
    # d'iOS (TensorFlowLiteC 2.12, voir ios/Podfile.lock) ne connaît pas ce
    # format et refuse le modèle : « Input tensor lacks data ». On garde donc
    # la sérialisation d'un seul tenant, que le quantificateur réserve aux
    # petits modèles et qui vaut jusqu'à 2 Go.
    model_modifier.ModelModifier._serialize_model = (
        lambda self, modele, _paquet, serialize_to_path=None: self._serialize_small_model(modele))
    recette = recipe_manager.RecipeManager()
    recette.add_weight_only_config(regex='.*', operation_name=TFLOperationName.ALL_SUPPORTED, num_bits=16,
                                   algorithm_key=algorithm_manager.AlgorithmName.FLOAT_CASTING)
    q = quantizer.Quantizer(str(cible))
    q.load_quantization_recipe(recette.get_quantization_recipe())
    blob = bytes(q.quantize().quantized_model)
    cible.write_bytes(blob)
    return blob


def entrees(images: list[Path], n_aleatoires: int = 4) -> list[np.ndarray]:
    """Les entrées de la vérification : les photos données, recadrées comme
    le fait l'application, puis du bruit pour couvrir le reste."""
    from PIL import Image, ImageOps

    out = []
    for chemin in images:
        im = ImageOps.exif_transpose(Image.open(chemin)).convert('RGB')
        cote = min(im.size)
        im = im.crop(((im.width - cote) // 2, (im.height - cote) // 2,
                      (im.width - cote) // 2 + cote, (im.height - cote) // 2 + cote))
        if cote > SOURCE_SIZE:
            im = im.resize((SOURCE_SIZE, SOURCE_SIZE), Image.BOX)
        im = im.resize((LOAD_SIZE, LOAD_SIZE), Image.BILINEAR)
        marge = (LOAD_SIZE - INPUT_SIZE) // 2
        im = im.crop((marge, marge, marge + INPUT_SIZE, marge + INPUT_SIZE))
        out.append(np.asarray(im, dtype=np.float32)[None])
    rng = np.random.default_rng(0)
    out += [rng.uniform(0, 255, (1, INPUT_SIZE, INPUT_SIZE, 3)).astype(np.float32) for _ in range(n_aleatoires)]
    return out


def verifier(module, fichier: Path, images: list[Path], labels: list[str]) -> dict:
    """Le TFLite rend-il ce que rend PyTorch ? Écart maximal, accord du
    premier candidat, et le premier candidat de chaque photo donnée."""
    import torch
    from ai_edge_litert.interpreter import Interpreter

    interp = Interpreter(model_path=str(fichier))
    interp.allocate_tensors()
    entree, sortie = interp.get_input_details()[0], interp.get_output_details()[0]
    ecart, accords, lignes = 0.0, 0, []
    xs = entrees(images)
    for k, x in enumerate(xs):
        with torch.no_grad():
            ref = module(torch.from_numpy(x)).numpy()[0]
        interp.set_tensor(entree['index'], x)
        interp.invoke()
        got = interp.get_tensor(sortie['index'])[0]
        ecart = max(ecart, float(np.abs(ref - got).max()))
        accords += int(ref.argmax() == got.argmax())
        if k < len(images):
            top = got.argsort()[::-1][:3]
            lignes.append(f'  {images[k].name} : ' + ', '.join(f'{labels[i]} {got[i]:.2f}' for i in top))
    for ligne in lignes:
        print(ligne)
    return {'max_abs_diff': round(ecart, 5), 'top1_agreement': f'{accords}/{len(xs)}'}


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--arch', default='mobilenet_v3_large', help='un des réseaux publiés par les auteurs')
    ap.add_argument('--out', default='../../assets/model/plantnet300k')
    ap.add_argument('--cache', default='.cache/plantnet300k')
    ap.add_argument('--float', action='store_true', help='garder les poids en flottant 32 bits (deux fois plus lourd)')
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
    blob = convertir(module, fichier, demi=not args.float)
    controle = verifier(module, fichier, args.check, labels)
    print(f'  PyTorch contre TFLite : {controle}')

    (out / 'labels.txt').write_text('\n'.join(labels) + '\n', encoding='utf-8')
    meta = {
        'version': '300K',
        'input_size': INPUT_SIZE,
        'load_size': LOAD_SIZE,
        'source_size': SOURCE_SIZE,
        'classes': len(labels),
        'network_outputs': len(vers),
        'architecture': args.arch,
        'preprocessing': 'included_in_graph_uint8_0_255',
        'weights': 'float32' if args.float else 'float16',
        'sha256': hashlib.sha256(blob).hexdigest(),
        'bytes': len(blob),
        'source': {
            'dataset': 'Pl@ntNet-300K (Zenodo 5645731)',
            'weights': POIDS.format(args.arch),
            'citation': 'Garcin et al., Pl@ntNet-300K: a plant image dataset with high label ambiguity '
                        'and a long-tailed distribution, NeurIPS Datasets and Benchmarks 2021',
        },
        'conversion_check': controle,
        'species': especes,
    }
    (out / 'model.json').write_text(json.dumps(meta, ensure_ascii=False, indent=1) + '\n', encoding='utf-8')
    print(f'{args.arch} : {len(vers)} sorties, {len(labels)} espèces, {len(blob) / 1e6:.2f} Mo → {out}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
