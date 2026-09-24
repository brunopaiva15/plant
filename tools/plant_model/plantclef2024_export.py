#!/usr/bin/env python3
"""PlantCLEF 2024 (DINOv2, ViT-B/14), converti pour tourner dans
l'application à côté d'Iris.

    python3 plantclef2024_export.py --out ../../assets/model/plantclef2024

Le même banc d'essai que Pl@ntNet-300K (§ 15 de
`docs/09-plant-recognition.md`), avec le modèle que Pl@ntNet a publié pour
le challenge PlantCLEF 2024 : un ViT-B/14 à registres, pré-entraîné par
DINOv2, puis affiné en entier sur 1,4 million d'images de la flore
d'Europe du Sud-Ouest — **7 806 espèces**. 75,9 % de top-1 annoncé par ses
auteurs sur leur jeu de test, une plante par image.

Zenodo 10848263, sous CC BY 4.0 : une archive de 2,3 Go qui porte deux
modèles. On prend `…_onlyclassifier_then_all`, le mieux classé des deux, et
ses poids EMA, comme le fait `basic_usage_pretrained_model.py` des auteurs.

C'est un autre gabarit qu'Iris : 86 millions de paramètres dans la dorsale,
une entrée de 518 px. D'où `--precision int8` par défaut — poids en int8,
couches denses calculées en int8 —, qui ramène le fichier vers 90 Mo et
accélère un réseau fait de produits matriciels.

Dépendances, à part de `requirements.txt` parce qu'elles tirent PyTorch :

    python3 -m pip install litert-torch timm pillow
"""
from __future__ import annotations

import argparse
import csv
import io
import sys
import tarfile
from pathlib import Path

from comparaison import PRECISIONS, convertir, ecrire, emballer, entrees, etiquettes, telecharger, verifier

ARCHIVE = ('https://zenodo.org/api/records/10848263/files/'
           'PlantNet_PlantCLEF2024_pretrained_models_on_the_flora_of_south-western_europe.tar/content')
MODELE = 'vit_base_patch14_reg4_dinov2_lvd142m_pc24_onlyclassifier_then_all'
TIMM = 'vit_base_patch14_reg4_dinov2.lvd142m'

#: La recette d'évaluation de timm pour ce réseau
#: (`resolve_model_data_config`) : `Resize(518)` bicubique avec
#: anticrénelage, `CenterCrop(518)`, normalisation ImageNet. Pas de marge de
#: recadrage : `load_size` vaut `input_size`.
INPUT_SIZE = 518
LOAD_SIZE = 518
#: À peine plus que `load_size` : c'est la moyenne de zone de l'application
#: qui fait toute la réduction, comme l'anticrénelage de timm, et le
#: bilinéaire qui suit ne retire plus que deux pixels. Égale à `load_size`,
#: l'application sauterait la moyenne et réduirait une photo de 4 000 px par
#: un bilinéaire seul — le crénelage que le réseau n'a jamais vu.
SOURCE_SIZE = 520


def extraire(archive: Path, cache: Path) -> tuple[Path, Path, Path]:
    """Les trois fichiers utiles de l'archive : poids, ordre des sorties,
    noms d'espèces. L'archive se lit une fois, les fichiers restent."""
    voulus = {
        f'pretrained_models/{MODELE}/model_best.pth.tar': cache / f'{MODELE}.pth.tar',
        'pretrained_models/class_mapping.txt': cache / 'class_mapping.txt',
        'pretrained_models/species_id_to_name.txt': cache / 'species_id_to_name.txt',
    }
    if not all(c.exists() for c in voulus.values()):
        with tarfile.open(archive) as tar:
            for membre in tar:
                cible = voulus.get(membre.name)
                if cible is None or cible.exists():
                    continue
                print(f'  extraction de {cible.name}…', file=sys.stderr, flush=True)
                with tar.extractfile(membre) as src:
                    cible.write_bytes(src.read())
    manque = [n for n, c in voulus.items() if not c.exists()]
    if manque:
        raise SystemExit(f'absent de l\'archive : {manque}')
    return tuple(voulus.values())


def noms_des_sorties(classes: Path, especes: Path) -> list[str]:
    """Sortie i → identifiant d'espèce (`class_mapping.txt`) → nom
    (`species_id_to_name.txt`, un CSV à point-virgule)."""
    ordre = [l.strip() for l in classes.read_text().splitlines() if l.strip()]
    lecteur = csv.DictReader(io.StringIO(especes.read_text(encoding='utf-8')), delimiter=';')
    nom = {r['species_id']: r['species'] for r in lecteur}
    absents = [s for s in ordre if s not in nom]
    if absents:
        raise SystemExit(f'{len(absents)} espèces sans nom, dont {absents[:3]}')
    return [nom[s] for s in ordre]


def modele(poids: Path, vers: list[int], n_especes: int):
    import timm

    reseau = timm.create_model(TIMM, pretrained=False, num_classes=len(vers), checkpoint_path=str(poids))
    # L'attention fusionnée (`scaled_dot_product_attention`) se convertit en
    # un op composite que le TensorFlow Lite d'iOS ne connaît pas. Écrite en
    # clair — deux produits matriciels et un softmax —, elle donne des ops
    # que la 2.12 exécute, pour le même résultat.
    for bloc in reseau.blocks:
        bloc.attn.fused_attn = False
    return emballer(reseau.eval(), vers, n_especes)


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--out', default='../../assets/model/plantclef2024')
    ap.add_argument('--cache', default='.cache/plantclef2024')
    ap.add_argument('--archive', type=Path, help='l\'archive Zenodo déjà téléchargée (2,3 Go)')
    ap.add_argument('--precision', choices=PRECISIONS, default='int8')
    ap.add_argument('--check', nargs='*', type=Path, default=[], help='photos à passer dans les deux graphes')
    args = ap.parse_args(argv)

    cache, out = Path(args.cache), Path(args.out)
    cache.mkdir(parents=True, exist_ok=True)
    archive = args.archive or telecharger(ARCHIVE, cache / 'pc24_pretrained_models.tar')
    poids, classes, especes = extraire(archive, cache)
    labels, vers, noms = etiquettes(noms_des_sorties(classes, especes))

    module = modele(poids, vers, len(labels))
    out.mkdir(parents=True, exist_ok=True)
    fichier = out / 'plants.tflite'
    blob = convertir(module, fichier, args.precision, INPUT_SIZE)
    xs = entrees(args.check, INPUT_SIZE, LOAD_SIZE, SOURCE_SIZE)
    controle = verifier(module, fichier, xs, [p.name for p in args.check], labels)
    print(f'  PyTorch contre TFLite : {controle}')

    ecrire(out, blob, labels, noms, {
        'version': '2024',
        'input_size': INPUT_SIZE,
        'load_size': LOAD_SIZE,
        'source_size': SOURCE_SIZE,
        'network_outputs': len(vers),
        'architecture': f'{TIMM} ({MODELE})',
        'weights': args.precision,
        'source': {
            'dataset': 'PlantCLEF 2024 single-plant training data (Pl@ntNet, flora of south-western Europe)',
            'weights': 'https://zenodo.org/records/10848263',
            'license': 'CC BY 4.0',
            'citation': 'Goëau, Lombardo, Affouard, Espitalier, Bonnet, Joly: PlantCLEF 2024 pretrained models on '
                        'the flora of the south western Europe, Zenodo 10848263',
        },
        'conversion_check': controle,
    })
    print(f'{MODELE} : {len(vers)} sorties, {len(labels)} espèces, {len(blob) / 1e6:.2f} Mo → {out}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
