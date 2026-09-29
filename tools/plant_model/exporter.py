#!/usr/bin/env python3
"""L'étape 14 : le student au format du téléphone, et la preuve qu'il n'y a
rien perdu.

    python3 exporter.py convertir --sortie ~/plant-data/iris10-int
    python3 exporter.py verifier  --sortie ~/plant-data/iris10-int

**Le format.** L'application charge déjà Iris 9 par `tflite_flutter` : Iris 10
suit le même chemin, un fichier `.tflite` (LiteRT), converti directement de
PyTorch par `litert-torch`. Pas de détour par ONNX ni par TensorFlow.

**Ce que le fichier contient, et ce qu'il attend.** Le dorsal et son
projecteur, **reparamétrés** (FastViT fond ses branches d'entraînement en
une seule convolution : même sortie, moins de calcul), puis la normalisation
du vecteur. L'entrée est `[1, 320, 320, 3]`, `float32`, valeurs 0-1, le carré
central de la photo réduit en bicubique — exactement `student.preparer`, la
recette de l'entraînement. La sortie est `[1, 1024]`, unitaire.

**Trois formats, départagés au banc :**

| format | poids | ce qu'il risque |
|---|---|---|
| `fp32` | ~46 Mo | rien, c'est l'étalon |
| `fp16` | ~23 Mo | presque rien : poids en demi-précision |
| `int8` | ~12 Mo | la quantification dynamique des poids ; à mesurer |

**`verifier` ne se contente pas d'un cosinus.** Il encode tout le banc avec
chaque fichier, sur le processeur, et l'écrit comme un point de contrôle :
`voisins.py --embeddings <sortie>/export/banc-fp16` le lit alors comme
n'importe quelle époque. Le cosinus avec les vecteurs de l'entraînement dit
si la conversion est fidèle ; le top-1 dit si ça compte.

Demande `torch`, `timm`, `litert-torch` et `ai-edge-quantizer` (voir le
README : un venv à part, sur le processeur, pour ne pas toucher à celui de
l'entraînement).
"""
from __future__ import annotations

import argparse
import csv
import hashlib
import json
from pathlib import Path

import numpy as np

FORMATS = ('fp32', 'fp16', 'int8', 'int8w')


# --------------------------------------------------------------------------
# Lectures pures
# --------------------------------------------------------------------------

def recette(sortie: Path) -> dict:
    """Ce que le point de contrôle dit de lui-même : dorsal, taille d'entrée,
    époque. `etat.json` est écrit à chaque époque par `distiller.py`."""
    etat = json.loads((sortie / 'etat.json').read_text())
    return {'student': etat.get('student', 'fastvit_sa12'),
            'entree': int(etat.get('entree', 224)),
            'epoque': int(etat.get('epoque', 0))}


def reglage_du_format(fmt: str) -> dict | None:
    """Comment `ai_edge_quantizer` tire ce format du fichier `fp32`, ou None
    pour le `fp32` lui-même.

    Le passage par le quantificateur, et non par les options du
    convertisseur, est voulu : `litert-torch` 0.9, le seul installable sous
    Python 3.14, ne passe plus par TensorFlow, et les options `tf.lite` de la
    0.8 n'y existent plus. Le quantificateur, lui, lit un `.tflite` quelle que
    soit la version qui l'a écrit.

    - `fp16` : les poids en demi-précision (`FLOAT_CASTING` sur 16 bits), les
      calculs en float32 ;
    - `int8` : la recette dynamique, poids int8 par canal, activations
      quantifiées à la volée. **Mesuré sur `iris10-int` le 29 septembre :
      inutilisable** — cosinus moyen 0,931, minimal 0,262, −8 points
      d'indoor, −11 d'outdoor ;
    - `int8w` : poids int8 seulement, calculs en float32. Même taille que
      `int8`, sans la quantification des activations qui le ruine.
    """
    if fmt == 'fp32':
        return None
    if fmt == 'fp16':
        return {'poids_seuls': 16, 'algorithme': 'float_casting'}
    if fmt == 'int8':
        return {'recette': 'dynamic_wi8_afp32'}
    if fmt == 'int8w':
        return {'recette': 'weight_only_wi8_afp32'}
    raise ValueError(f'format inconnu : {fmt}')


def metadonnees(r: dict, fmt: str, fichier: Path, dim: int = 1024) -> dict:
    """`iris10-<format>.json`, livré à côté du fichier : ce que l'application
    doit savoir pour le nourrir, et de quoi reconnaître le fichier."""
    octets = fichier.read_bytes()
    return {
        'modele': 'Iris 10',
        'student': r['student'],
        'epoque': r['epoque'],
        'format': fmt,
        'entree': [1, r['entree'], r['entree'], 3],
        'pretraitement': {'recadrage': 'carre central', 'reduction': 'bicubique',
                          'valeurs': '0-1', 'normalisation': 'aucune', 'ordre': 'NHWC'},
        'sortie': [1, dim],
        'sortie_unitaire': True,
        'octets': len(octets),
        'sha256': hashlib.sha256(octets).hexdigest(),
    }


def cosinus_par_ligne(a: np.ndarray, b: np.ndarray) -> np.ndarray:
    a = a / np.maximum(np.linalg.norm(a, axis=1, keepdims=True), 1e-12)
    b = b / np.maximum(np.linalg.norm(b, axis=1, keepdims=True), 1e-12)
    return (a * b).sum(axis=1)


def ecrire_banc(dossier: Path, sig: dict, chemins: list[str], vecteurs: np.ndarray) -> None:
    """Un cache du banc au format de `distiller.py`, que `voisins.py
    --embeddings` lit tel quel."""
    from bioclip import accorder_signature
    accorder_signature(dossier, sig, forcer=True)
    np.save(dossier / 'emb-0-0000.npy', vecteurs.astype(np.float16))
    with open(dossier / 'index-0.csv', 'w', newline='', encoding='utf-8') as f:
        csv.writer(f).writerows([[c, 'emb-0-0000', i] for i, c in enumerate(chemins)])


# --------------------------------------------------------------------------
# PyTorch et LiteRT
# --------------------------------------------------------------------------

def modele_livrable(sortie: Path, r: dict):  # pragma: no cover - demande torch
    """Le student du point de contrôle, reparamétré, NHWC en entrée et
    vecteur unitaire en sortie."""
    import torch
    import torch.nn as nn
    import torch.nn.functional as F
    from timm.utils.model import reparameterize_model
    from distiller import construire

    modele = construire(r['student'], pretrained=False)
    point = torch.load(sortie / 'poids.pt', map_location='cpu', weights_only=True)
    modele.load_state_dict(point['modele'])
    modele.eval()

    class Livrable(nn.Module):
        def __init__(self, m):
            super().__init__()
            self.m = m

        def forward(self, x):                    # [1, H, W, 3], valeurs 0-1
            return F.normalize(self.m(x.permute(0, 3, 1, 2)), dim=-1)

    return Livrable(reparameterize_model(modele)).eval()


def compresser(fp32: Path, fmt: str, dest: Path) -> None:  # pragma: no cover
    """Le fichier `fp32` compressé en `fmt` par `ai_edge_quantizer`."""
    from ai_edge_quantizer import quantizer, recipe
    from ai_edge_quantizer.algorithm_manager import AlgorithmName
    reglage = reglage_du_format(fmt)
    q = quantizer.Quantizer(str(fp32))
    if 'poids_seuls' in reglage:
        q.add_weight_only_config(regex='.*', operation_name='*',
                                 num_bits=reglage['poids_seuls'],
                                 algorithm_key=AlgorithmName.FLOAT_CASTING)
    else:
        q.load_quantization_recipe(getattr(recipe, reglage['recette'])())
    q.quantize(enable_progress_report=False).export_model(str(dest), overwrite=True)


def convertir(args) -> int:  # pragma: no cover - demande torch et litert-torch
    import torch
    import litert_torch
    sortie = Path(args.sortie).expanduser()
    r = recette(sortie)
    dest = sortie / 'export'
    dest.mkdir(exist_ok=True)
    modele = modele_livrable(sortie, r)
    exemple = torch.rand(1, r['entree'], r['entree'], 3)
    with torch.no_grad():
        attendu = modele(exemple).numpy()
    print(f"{r['student']}, époque {r['epoque']}, entrée {r['entree']} px")
    fp32 = dest / 'iris10-fp32.tflite'
    litert_torch.convert(modele, (exemple,)).export(str(fp32))
    for fmt in args.formats.split(','):
        fichier = dest / f'iris10-{fmt}.tflite'
        if fmt != 'fp32':
            compresser(fp32, fmt, fichier)
        rendu = executer(fichier, exemple.numpy())
        meta = metadonnees(r, fmt, fichier)
        (dest / f'iris10-{fmt}.json').write_text(json.dumps(meta, indent=2, ensure_ascii=False) + '\n')
        print(f'  {fmt:<5} {meta["octets"] / 1e6:6.1f} Mo   cosinus sur une image au hasard '
              f'{float(cosinus_par_ligne(attendu, rendu)[0]):.6f}   {fichier}')
    return 0


def interprete(fichier: Path):  # pragma: no cover - demande LiteRT
    from ai_edge_litert.interpreter import Interpreter
    it = Interpreter(model_path=str(fichier))
    it.allocate_tensors()
    return it, it.get_input_details()[0], it.get_output_details()[0]


def executer(fichier: Path, x: np.ndarray, it=None) -> np.ndarray:  # pragma: no cover
    it, entree, sortie = it or interprete(fichier)
    it.set_tensor(entree['index'], x.astype(np.float32))
    it.invoke()
    return it.get_tensor(sortie['index']).copy()


def verifier(args) -> int:  # pragma: no cover - demande LiteRT et le banc
    from student import lire_banc, preparer, signature_student
    from voisins import lire_embeddings
    sortie = Path(args.sortie).expanduser()
    r = recette(sortie)
    chemins = lire_banc(Path(args.banc).expanduser())
    if args.images:
        chemins = chemins[:args.images]
    dest = sortie / 'export'
    reference = sortie / f"banc-e{r['epoque']}"
    gardes, attendus = lire_embeddings(reference, chemins)
    print(f'{len(chemins)} images du banc ; référence {reference}\n')
    for fmt in args.formats.split(','):
        fichier = dest / f'iris10-{fmt}.tflite'
        if not fichier.exists():
            print(f'  {fmt}: {fichier} absent — lancer `convertir` d\'abord')
            continue
        it = interprete(fichier)
        vecteurs = np.empty((len(chemins), 1024), dtype=np.float32)
        for k, c in enumerate(chemins):
            x = preparer(c, entree=r['entree'])[0].transpose(1, 2, 0)[None]
            vecteurs[k] = executer(fichier, x, it)[0]
            if (k + 1) % 1000 == 0:
                print(f'    {fmt} : {k + 1}/{len(chemins)}', flush=True)
        banc = dest / f'banc-{fmt}'
        sig = signature_student(f"{r['student']}-e{r['epoque']}-tflite-{fmt}", 'carre',
                                entree=r['entree'])
        ecrire_banc(banc, sig, chemins, vecteurs)
        cos = cosinus_par_ligne(attendus, vecteurs[gardes]) if gardes else np.array([np.nan])
        print(f'  {fmt:<5} cosinus avec l\'entraînement : moyen {cos.mean():.5f}, '
              f'minimal {cos.min():.5f}   → voisins.py --embeddings {banc}')
    return 0


def main() -> int:  # pragma: no cover
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    sous = ap.add_subparsers(dest='commande', required=True)
    c = sous.add_parser('convertir', help='le point de contrôle en .tflite, dans <sortie>/export')
    c.add_argument('--sortie', required=True, help='le dossier de la passe, ex. ~/plant-data/iris10-int')
    c.add_argument('--formats', default=','.join(FORMATS))
    c.set_defaults(fonction=convertir)
    v = sous.add_parser('verifier', help='encoder le banc avec chaque fichier et le comparer')
    v.add_argument('--sortie', required=True)
    v.add_argument('--formats', default=','.join(FORMATS))
    v.add_argument('--banc', default='benchmark.csv')
    v.add_argument('--images', type=int, default=0, help="n'en encoder que N — un essai")
    v.set_defaults(fonction=verifier)
    args = ap.parse_args()
    return args.fonction(args)


if __name__ == '__main__':
    raise SystemExit(main())
