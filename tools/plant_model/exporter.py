#!/usr/bin/env python3
"""L'étape 14 : le student au format du téléphone, et la preuve qu'il n'y a
rien perdu.

    python3 exporter.py convertir --sortie ~/plant-data/iris10-int
    python3 exporter.py verifier  --sortie ~/plant-data/iris10-int
    python3 exporter.py livrer    --sortie ~/plant-data/iris10-final --cache ~/plant-data/bioclip

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

# Ce que l'application reçoit (§ 20 quaterdecies et quindecies de `docs/14`) :
# le fichier `fp16` d'`iris10-final`, lu par les centroïdes v8 et pot, fusionné
# à parts égales avec Iris 9, et qui affirme à 0,85 avec 0,25 d'avance.
FORMAT_LIVRE = 'fp16'
REFERENCES_LIVREES = 'centroide+references-centroides-potseul'
TEMPERATURE = 100.0          # celle de `voisins.classer`
POIDS_IRIS9 = 0.5
PLANCHER = 1e-6              # celui de `seuils.fusion_probas`
SEUIL_FUSION = 0.85
MARGE_FUSION = 0.25


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


def paquet_references(cles: list[str], vecteurs: np.ndarray,
                      labels: list[str]) -> tuple[dict, np.ndarray]:
    """Les références telles que l'application les lit, alignées sur Iris 9.

    C'est `seuils.lire_tranche` mis à plat, pour qu'un téléphone le refasse
    sans numpy :

    - `especes` : les espèces de la fusion, dans l'ordre d'Iris 9, synonymes
      réunis (`canonique`) — celles d'Iris 9 qui ont au moins une référence.
      C'est `aligner` : une espèce sans référence n'entre pas dans la
      fusion, et n'y est pas entrée au banc ;
    - `lignes` : pour chaque ligne de la matrice, l'indice de son espèce.
      Une espèce a plusieurs vues (`#captive`, `#pot`), `classer` garde la
      meilleure ;
    - `iris9` : pour chaque sortie d'Iris 9, l'indice de son espèce, ou −1.
      Deux sorties d'une même plante pointent la même espèce, et leurs
      probabilités s'additionnent (`fusionner_synonymes`).
    """
    from voisins import SYNONYMES, canonique, sans_suffixe
    especes9: list[str] = []
    for lab in labels:
        e = canonique(lab)
        if e not in especes9:
            especes9.append(e)
    vues = {sans_suffixe(c) for c in cles}
    especes = [e for e in especes9 if e in vues]
    rang = {e: i for i, e in enumerate(especes)}
    gardees = [k for k, c in enumerate(cles) if sans_suffixe(c) in rang]
    paquet = {
        'especes': especes,
        'lignes': [rang[sans_suffixe(cles[k])] for k in gardees],
        'iris9': [rang.get(canonique(lab), -1) for lab in labels],
        'synonymes': dict(SYNONYMES),
        'sans_reference': [e for e in especes9 if e not in rang],
    }
    return paquet, np.asarray(vecteurs, dtype=np.float32)[gardees]


def motif_de_controle(entree: int) -> np.ndarray:
    """Une entrée que Dart et Python savent écrire à l'identique, en entiers :
    l'application y compare son vecteur à celui de l'export, et sait alors
    si le fichier qu'elle a chargé calcule ce qu'il doit."""
    i = np.arange(entree * entree * 3, dtype=np.int64)
    return ((i * 7919 % 1000) / 999.0).astype(np.float32).reshape(1, entree, entree, 3)


def meta_livree(r: dict, modele: Path, references: Path, paquet: dict, dim: int,
                nom_references: str, controle: np.ndarray) -> dict:
    """`iris10.json` : tout ce que l'application doit savoir pour lire Iris 10
    et le fusionner avec Iris 9, et les réglages mesurés au banc."""
    octets = modele.read_bytes()
    refs = references.read_bytes()
    return {
        'version': '10',
        'student': r['student'],
        'epoque': r['epoque'],
        'format': FORMAT_LIVRE,
        'input_size': r['entree'],
        'dim': dim,
        'octets': len(octets),
        'sha256': hashlib.sha256(octets).hexdigest(),
        'pretraitement': {'image': 'côté long ramené à 384 (Lanczos)',
                          'recadrage': 'carré central', 'reduction': 'bicubique',
                          'valeurs': '0-1', 'ordre': 'NHWC'},
        'references': {'fichier': references.name, 'jeu': nom_references,
                       'lignes': len(paquet['lignes']), 'dtype': 'float16',
                       'octets': len(refs), 'sha256': hashlib.sha256(refs).hexdigest()},
        'temperature': TEMPERATURE,
        'fusion': {'poids_iris9': POIDS_IRIS9, 'plancher': PLANCHER},
        'accept_threshold': SEUIL_FUSION,
        'min_margin': MARGE_FUSION,
        'controle': {'motif': '(i * 7919 % 1000) / 999',
                     'vecteur': [round(float(x), 6) for x in controle.reshape(-1)[:16]]},
        **{k: paquet[k] for k in ('especes', 'lignes', 'iris9', 'synonymes')},
    }


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
    en_ligne(dest)


def en_ligne(fichier: Path) -> int:  # pragma: no cover - demande ai_edge_litert
    """Remet les poids **dans** le flatbuffer, et rend combien en étaient
    sortis.

    `ai_edge_quantizer` range les poids après la structure du fichier et ne
    garde dans celle-ci que leur position (`Buffer.offset`) — une facilité de
    LiteRT récent. L'application embarque TensorFlow Lite **2.12** (le pod de
    `tflite_flutter`), qui ne sait pas les y chercher : « Input tensor 92
    lacks data », mesuré le 29 septembre 2026. Relus puis réécrits en ligne,
    les mêmes poids se chargent sous 2.12 et rendent le même vecteur
    (cosinus 1,0), pour la même taille.
    """
    from ai_edge_litert.tools import flatbuffer_utils as fu
    octets = bytearray(fichier.read_bytes())
    externes = sum(1 for b in fu.convert_bytearray_to_object(octets).buffers if b.offset)
    if externes:
        fichier.write_bytes(fu.convert_object_to_bytearray(fu.read_model_from_bytearray(octets)))
    return externes


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


def livrer(args) -> int:  # pragma: no cover - demande LiteRT et le cache
    """Le fichier livré, ses références et `iris10.json`, dans les assets."""
    import shutil
    from voisins import charger_references
    sortie = Path(args.sortie).expanduser()
    r = recette(sortie)
    source = sortie / 'export' / f'iris10-{FORMAT_LIVRE}.tflite'
    if not source.exists():
        print(f'{source} absent — lancer `convertir --formats {FORMAT_LIVRE}` d\'abord')
        return 1
    dest = Path(args.dest).expanduser()
    labels = (Path(args.iris).expanduser() / 'labels.txt').read_text(encoding='utf-8').split()
    cles, vecteurs = charger_references(Path(args.cache).expanduser(), args.references)
    paquet, matrice = paquet_references(cles, vecteurs, labels)

    modele = dest / 'iris10.tflite'
    shutil.copyfile(source, modele)
    references = dest / 'iris10-references.bin'
    references.write_bytes(matrice.astype('<f2').tobytes())
    controle = executer(modele, motif_de_controle(r['entree']))
    meta = meta_livree(r, modele, references, paquet, matrice.shape[1], args.references, controle)
    (dest / 'iris10.json').write_text(json.dumps(meta, ensure_ascii=False) + '\n', encoding='utf-8')

    print(f"{r['student']}, époque {r['epoque']}, {FORMAT_LIVRE} : {meta['octets'] / 1e6:.1f} Mo")
    print(f"{len(paquet['especes'])} espèces dans la fusion, {len(paquet['lignes'])} références "
          f"({meta['references']['octets'] / 1e6:.1f} Mo), sur {len(labels)} sorties d'Iris 9")
    manque = paquet['sans_reference']
    if manque:
        print(f'{len(manque)} espèces d\'Iris 9 sans référence, hors de la fusion : '
              + ', '.join(manque[:12]) + (' …' if len(manque) > 12 else ''))
    print(f'→ {modele}\n→ {references}\n→ {dest / "iris10.json"}')
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
    li = sous.add_parser('livrer', help="le fichier fp16, ses références et iris10.json dans les assets")
    li.add_argument('--sortie', required=True)
    li.add_argument('--cache', default='~/plant-data/bioclip')
    li.add_argument('--references', default=REFERENCES_LIVREES)
    li.add_argument('--iris', default='../../assets/model', help='où lire les labels d\'Iris 9')
    li.add_argument('--dest', default='../../assets/model')
    li.set_defaults(fonction=livrer)
    args = ap.parse_args()
    return args.fonction(args)


if __name__ == '__main__':
    raise SystemExit(main())
