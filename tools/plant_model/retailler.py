#!/usr/bin/env python3
"""Réexporte un modèle entraîné en ne gardant qu'une partie de ses classes.

    python3 retailler.py --poids /data2/cache/ckpt/fine.weights.h5 \\
        --etiquettes /data2/model-v8/labels.txt --garder ../../assets/model/labels.txt \\
        --dataset /data2/dataset-v8 --out /data2/model-v8-retaille --version 8

**Ce n'est pas un réentraînement.** On reprend les poids appris, on ne garde
dans la dernière couche que les colonnes des espèces voulues, et on
réexporte. Le calcul est identique à ce que fait une application qui
masquerait les sorties puis renormaliserait la confiance : le softmax d'une
couche tronquée vaut `exp(zᵢ) / Σ_gardées exp(zⱼ)`, et c'est exactement ce
que `compare_models.py --restreint` mesure.

Pourquoi le faire au lieu de masquer côté application : mesuré sur 6 000
mêmes images, l'Iris 8 rend 0,6543 sur les classes de l'Iris 7 et 0,5528
avec ses 5 259 sorties. Les espèces nouvelles ne sont pas seulement mal
reconnues — elles volent les réponses des anciennes. Le modèle n'a pas
besoin d'être réappris, il a besoin d'être borné, et le borner ici évite
d'avoir à figer une liste d'espèces dans le code de l'application.

Le fichier livré rétrécit d'autant : la tête fait 960 × classes × 2 octets.
"""
from __future__ import annotations

import argparse
from pathlib import Path


def garder(toutes: list[str], voulues: list[str]) -> list[str]:
    """Les classes à garder, dans l'ordre du modèle entraîné.

    L'ordre compte : `labels.txt` et les colonnes de la tête doivent se
    correspondre ligne à ligne. Une classe demandée que le modèle n'a jamais
    apprise est ignorée — il n'y a rien à en tirer, et la signaler vaut mieux
    que de livrer une étiquette sans sortie derrière.
    """
    demande = set(voulues)
    return [c for c in toutes if c in demande]


def decouper(poids: list, classes: list[str], gardees: list[str]) -> list:
    """Les poids du modèle retaillé.

    `get_weights()` rend les tableaux à plat dans l'ordre des couches ; la
    tête étant la dernière, son noyau et son biais ferment la liste. Eux
    seuls sont découpés — par colonnes, dans l'ordre de `gardees`, pour que
    la colonne *i* de la tête réponde bien à la ligne *i* de `labels.txt`.
    Tout le reste, c'est-à-dire le dorsal, est recopié sans y toucher.
    """
    index = {c: i for i, c in enumerate(classes)}
    colonnes = [index[c] for c in gardees]
    noyau, biais = poids[-2], poids[-1]
    return poids[:-2] + [noyau[:, colonnes], biais[colonnes]]


def retailler(model, classes: list[str], gardees: list[str], dropout: float, backbone: str):
    """Un modèle identique, à la dernière couche près."""
    import train
    petit = train.build_model(len(gardees), dropout, backbone)
    petit.set_weights(decouper(model.get_weights(), classes, gardees))
    return petit


def main() -> int:
    import train

    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--poids', required=True, help='fine.weights.h5 du modèle entraîné')
    ap.add_argument('--etiquettes', required=True, help='labels.txt du modèle entraîné')
    ap.add_argument('--garder', required=True,
                    help='fichier des classes à garder, une par ligne — '
                         'le labels.txt du modèle livré fait très bien l\'affaire')
    ap.add_argument('--dataset', required=True, help='pour réévaluer et nommer les espèces')
    ap.add_argument('--out', required=True)
    ap.add_argument('--version', default='8')
    ap.add_argument('--backbone', default='large', choices=list(train.BACKBONES))
    ap.add_argument('--dropout', type=float, default=0.5)
    ap.add_argument('--input-size', type=int, default=320)
    ap.add_argument('--batch', type=int, default=64)
    ap.add_argument('--ram-budget', type=float, default=5.0)
    args = ap.parse_args()

    train.set_input_size(args.input_size)
    classes = Path(args.etiquettes).read_text(encoding='utf-8').split()
    voulues = Path(args.garder).read_text(encoding='utf-8').split()
    gardees = garder(classes, voulues)
    perdues = sorted(set(voulues) - set(gardees))
    print(f'{len(classes)} classes apprises, {len(voulues)} demandées, '
          f'{len(gardees)} gardées')
    if perdues:
        print(f'{len(perdues)} demandées que le modèle n\'a pas apprises, ignorées :')
        for c in perdues:
            print(f'   {c}')
    if not gardees:
        raise SystemExit('aucune classe en commun : mauvais fichier ?')

    print('chargement des poids appris…', flush=True)
    model = train.build_model(len(classes), args.dropout, args.backbone)
    model.load_weights(args.poids)
    petit = retailler(model, classes, gardees, args.dropout, args.backbone)

    dataset = Path(args.dataset)
    rows, captive = train.read_splits(dataset)
    test_ds, _, test_paths = train.make_dataset(rows['test'], gardees, args.batch, training=False,
                                                ram_budget_gb=args.ram_budget, preload=False)
    print(f'évaluation sur {len(test_paths)} images de test…', flush=True)
    metrics = train.evaluate(petit, test_ds, gardees,
                             captive_mask=[p in captive for p in test_paths])
    metrics['version'] = args.version

    meta = train.export_tflite(petit, Path(args.out), gardees,
                               train.species_names(dataset), metrics)
    print(f"\n{args.out}/plants.tflite — {meta['bytes'] / 1e6:.1f} Mo, {len(gardees)} classes")
    print(f"  top1 {metrics['top1']}  top3 {metrics['top3']}  macro_f1 {metrics['macro_f1']}")
    for e in meta['threshold_curve']:
        if e['min_margin'] == 0.25 and e['threshold'] in (0.6, 0.7, 0.8):
            print(f"  seuil {e['threshold']} marge 0,25 → {e['accepted_rate']:.1%} acceptées, "
                  f"précision {e['precision_when_accepted']:.4f}")
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
