"""Ce que partagent les modèles qu'on mesure contre Iris dans l'application.

Chacun a son script — `plantnet300k_export.py`, `plantclef2024_export.py` —
qui sait où trouver ses poids et comment construire son réseau. Le reste est
ici, et c'est le contrat de `TflitePlantModel` côté Dart :

- une entrée NHWC en octets 0–255, la normalisation dans le graphe ;
- des probabilités en sortie, une par espèce, dans l'ordre de `labels.txt` ;
- `labels.txt` en identifiants internes (« monstera-deliciosa ») ;
- `model.json` avec la recette de cadrage : carré central, `source_size`,
  `load_size`, `input_size`.

Et la contrainte d'iOS : TensorFlowLiteC 2.12 (voir `ios/Podfile.lock`). Un
modèle qu'il ne sait pas lire tombe à l'exécution, pas à la conversion ; la
vérification qui compte se fait donc avec un interpréteur de cette version
(§ 15 de `docs/09`).
"""
from __future__ import annotations

import hashlib
import json
import sys
import urllib.request
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'plant_dataset'))

from plant_dataset.taxonomy import internal_id, normalize_scientific_name  # noqa: E402

MEAN = (0.485, 0.456, 0.406)
STD = (0.229, 0.224, 0.225)

#: Les précisions de poids proposées. `float16` est celle d'Iris
#: (`export_tflite` de train.py) ; `int8` quantifie les poids **et** le calcul
#: des couches denses (quantification dynamique), ce qui divise le poids par
#: quatre et accélère l'inférence d'un réseau fait de produits matriciels.
PRECISIONS = ('float32', 'float16', 'int8')


def telecharger(url: str, cible: Path) -> Path:
    if cible.exists():
        return cible
    cible.parent.mkdir(parents=True, exist_ok=True)
    print(f'  téléchargement de {cible.name}…', file=sys.stderr, flush=True)
    partiel = cible.with_suffix(cible.suffix + '.part')
    urllib.request.urlretrieve(url, partiel)
    partiel.rename(cible)
    return cible


def etiquettes(noms: list[str]) -> tuple[list[str], list[int], dict[str, str]]:
    """Nos identifiants, et pour chaque sortie du réseau celui qu'elle nomme.

    [noms] est le nom brut de chaque sortie, dans l'ordre du réseau. Ces noms
    portent l'auteur (« Lactuca virosa L. ») ; l'application attend nos
    identifiants (« lactuca-virosa »), qu'elle rattache ensuite au catalogue
    pour trouver le nom courant. Même normalisation que la collecte, sinon
    rien ne se rencontre.

    Les jeux de Pl@ntNet nomment parfois la même plante sous deux ou trois
    citations d'auteur (« Tradescantia zebrina Bosse », « … hort. ex
    Bosse »). Laissées telles quelles, elles s'afficheraient deux fois et se
    partageraient le score. Le graphe les additionne ([Emballage]) ; ici, on
    dit lesquelles vont ensemble.
    """
    labels, rang, especes, vers = [], {}, {}, []
    for i, brut in enumerate(noms):
        nom = normalize_scientific_name(brut)
        ident = internal_id(nom)
        if not ident:
            raise SystemExit(f'sortie {i} : nom illisible « {brut} »')
        if ident not in rang:
            rang[ident] = len(labels)
            labels.append(ident)
            especes[ident] = nom
        vers.append(rang[ident])
    return labels, vers, especes


def emballer(coeur, vers: list[int], n_especes: int, mean=MEAN, std=STD):
    """Le réseau des auteurs dans le graphe que lit l'application.

    Les doublons de [etiquettes] s'additionnent ici, sur les probabilités : la
    première sortie de chaque espèce est prise telle quelle (un `GATHER`), les
    suivantes s'y ajoutent par un produit avec une petite matrice de 0 et de
    1 — une ligne par doublon, pas par sortie. Additionner des probabilités,
    et non des logits, c'est exactement ce que vaut « l'une ou l'autre
    citation ».
    """
    import torch

    premiere, doublons = {}, []
    for sortie, espece in enumerate(vers):
        if espece in premiere:
            doublons.append((sortie, espece))
        else:
            premiere[espece] = sortie
    garde = torch.tensor([premiere[e] for e in range(n_especes)])
    extra = torch.tensor([s for s, _ in doublons], dtype=torch.long)
    ajout = torch.zeros(len(doublons), n_especes)
    for ligne, (_, espece) in enumerate(doublons):
        ajout[ligne, espece] = 1.0

    class Emballage(torch.nn.Module):
        """NHWC 0–255 → probabilités par espèce : le contrat de `TflitePlantModel`."""

        def __init__(self):
            super().__init__()
            self.coeur = coeur
            self.register_buffer('mean', torch.tensor(mean).view(1, 3, 1, 1) * 255.0)
            self.register_buffer('std', torch.tensor(std).view(1, 3, 1, 1) * 255.0)
            self.register_buffer('garde', garde)
            self.register_buffer('extra', extra)
            self.register_buffer('ajout', ajout)

        def forward(self, x):
            x = x.permute(0, 3, 1, 2)
            x = (x - self.mean) / self.std
            p = torch.softmax(self.coeur(x), dim=-1)
            out = p.index_select(1, self.garde)
            if self.extra.numel():
                out = out + p.index_select(1, self.extra) @ self.ajout
            return out

    return Emballage().eval()


def convertir(module, cible: Path, precision: str, taille: int) -> bytes:
    """PyTorch → TFLite, puis la précision de poids demandée."""
    import litert_torch
    import torch

    exemple = (torch.rand(1, taille, taille, 3) * 255.0,)
    litert_torch.convert(module, exemple).export(str(cible))
    if precision == 'float32':
        return cible.read_bytes()

    from ai_edge_quantizer import algorithm_manager, model_modifier, quantizer, recipe, recipe_manager
    from ai_edge_quantizer.qtyping import TFLOperationName

    # Au-delà de 256 Ko de poids, le quantificateur les range **après** le
    # flatbuffer et ne laisse dedans que leur position. Le TensorFlow Lite
    # d'iOS (2.12) ne connaît pas ce format et refuse le modèle : « Input
    # tensor lacks data ». On garde donc la sérialisation d'un seul tenant,
    # que le quantificateur réserve aux petits modèles et qui vaut jusqu'à
    # 2 Go.
    model_modifier.ModelModifier._serialize_model = (
        lambda self, modele, _paquet, serialize_to_path=None: self._serialize_small_model(modele))
    if precision == 'float16':
        # Poids en demi-précision, calcul en flottant, comme Iris.
        recette = recipe_manager.RecipeManager()
        recette.add_weight_only_config(regex='.*', operation_name=TFLOperationName.ALL_SUPPORTED, num_bits=16,
                                       algorithm_key=algorithm_manager.AlgorithmName.FLOAT_CASTING)
        recette = recette.get_quantization_recipe()
    else:
        # La quantification dynamique « à l'ancienne » : poids int8 par
        # canal, activations quantifiées à la volée dans les couches denses.
        # C'est la forme que produisait `TFLiteConverter` avec
        # `Optimize.DEFAULT`, et celle que le runtime 2.12 exécute.
        recette = recipe.dynamic_legacy_wi8_afp32()
    q = quantizer.Quantizer(str(cible))
    q.load_quantization_recipe(recette)
    blob = bytes(q.quantize().quantized_model)
    cible.write_bytes(blob)
    return blob


def entrees(images: list[Path], taille: int, chargement: int, source: int,
            n_aleatoires: int = 4) -> list[np.ndarray]:
    """Les entrées de la vérification : les photos données, recadrées comme
    le fait l'application (`TflitePlantModel._decode`), puis du bruit."""
    from PIL import Image, ImageOps

    out = []
    for chemin in images:
        im = ImageOps.exif_transpose(Image.open(chemin)).convert('RGB')
        cote = min(im.size)
        im = im.crop(((im.width - cote) // 2, (im.height - cote) // 2,
                      (im.width - cote) // 2 + cote, (im.height - cote) // 2 + cote))
        if cote > source > chargement:
            im = im.resize((source, source), Image.BOX)
        im = im.resize((chargement, chargement), Image.BILINEAR)
        marge = (chargement - taille) // 2
        im = im.crop((marge, marge, marge + taille, marge + taille))
        out.append(np.asarray(im, dtype=np.float32)[None])
    rng = np.random.default_rng(0)
    out += [rng.uniform(0, 255, (1, taille, taille, 3)).astype(np.float32) for _ in range(n_aleatoires)]
    return out


def verifier(module, fichier: Path, xs: list[np.ndarray], noms: list[str], labels: list[str]) -> dict:
    """Le TFLite rend-il ce que rend PyTorch ? Écart maximal, accord du
    premier candidat, et les trois premiers de chaque photo nommée."""
    import time

    import torch
    from ai_edge_litert.interpreter import Interpreter

    interp = Interpreter(model_path=str(fichier), num_threads=2)
    interp.allocate_tensors()
    entree, sortie = interp.get_input_details()[0], interp.get_output_details()[0]
    ecart, accords, durees = 0.0, 0, []
    for k, x in enumerate(xs):
        with torch.no_grad():
            ref = module(torch.from_numpy(x)).numpy()[0]
        interp.set_tensor(entree['index'], x)
        debut = time.perf_counter()
        interp.invoke()
        durees.append(time.perf_counter() - debut)
        got = interp.get_tensor(sortie['index'])[0]
        ecart = max(ecart, float(np.abs(ref - got).max()))
        accords += int(ref.argmax() == got.argmax())
        if k < len(noms):
            top = got.argsort()[::-1][:3]
            print(f'  {noms[k]} : ' + ', '.join(f'{labels[i]} {got[i]:.2f}' for i in top))
    return {
        'max_abs_diff': round(ecart, 5),
        'top1_agreement': f'{accords}/{len(xs)}',
        # Sur le poste de conversion, deux fils : un ordre de grandeur, pas
        # la durée sur un téléphone.
        'seconds_per_image_2_threads': round(float(np.median(durees)), 2),
    }


def ecrire(out: Path, blob: bytes, labels: list[str], especes: dict[str, str], meta: dict) -> dict:
    """`labels.txt` et `model.json` à côté du `.tflite` déjà écrit."""
    (out / 'labels.txt').write_text('\n'.join(labels) + '\n', encoding='utf-8')
    meta = {
        **meta,
        'classes': len(labels),
        'preprocessing': 'included_in_graph_uint8_0_255',
        'sha256': hashlib.sha256(blob).hexdigest(),
        'bytes': len(blob),
        'species': especes,
    }
    (out / 'model.json').write_text(json.dumps(meta, ensure_ascii=False, indent=1) + '\n', encoding='utf-8')
    return meta
