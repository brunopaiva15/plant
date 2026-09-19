#!/usr/bin/env python3
"""Le jeu de mesure d'Iris 10, figé une fois pour toutes.

    python3 benchmark.py --dataset ../plant_dataset/dataset \\
        --hors-sujet ~/plant-data/hors-sujet --out benchmark.csv

`docs/14` § 20 met ce jeu en troisième position, avant la première
distillation, et pour une raison qui revient à chaque version : **les chiffres
de deux `model.json` ne se comparent pas** (§ 5 de `docs/10`). Chaque
entraînement a jusqu'ici produit son propre jeu de test, si bien qu'un modèle
qui « gagne trois points » avait peut-être seulement reçu un test plus facile.
Iris Core devant battre Iris Indoor sur son terrain et Iris 9 sur le
généraliste, il lui faut une règle du jeu qui ne bouge plus.

Ce que ce script produit est donc un **manifeste**, pas des images : un CSV
qui dit quelle photo appartient à quelle tranche et quelle est sa vérité. Il
est reproductible à la graine près, et se recalcule à l'identique tant que le
jeu d'images ne change pas.

Cinq tranches, chacune répondant à une question que les autres ne posent pas :

| tranche | ce qu'elle mesure |
|---|---|
| `indoor` | les espèces qu'Iris Indoor expose, sur des photos de plantes cultivées |
| `outdoor` | celles que l'Iris 8 exposait et qu'Indoor a retirées |
| `multi` | les observations à deux photos ou plus — la fusion, § 13 de `docs/14` |
| `ood_plante` | des plantes réelles hors des deux masques : le cas le plus fréquent, et le plus difficile (§ 12.7) |
| `ood_autre` | ce qui n'est pas une plante du tout, s'il y en a |

La tranche `ood_autre` reste vide tant que `--hors-sujet` ne pointe pas sur
des dossiers remplis. C'est volontaire : un jeu qui prétendrait mesurer le
refus sans photo de chat mentirait plus qu'il n'aiderait.
"""
from __future__ import annotations

import argparse
import csv
import random
from collections import defaultdict
from pathlib import Path

EXTENSIONS = {'.jpg', '.jpeg', '.png', '.webp'}


def lire_masque(chemin: Path | None) -> set[str]:
    if chemin is None or not chemin.exists():
        return set()
    return {l.strip() for l in chemin.read_text(encoding='utf-8').splitlines() if l.strip()}


def lire_test(dataset: Path) -> list[dict]:
    """Les images de test, avec leur espèce, leur groupe et leur domaine."""
    lignes = []
    with open(dataset / 'splits.csv', newline='', encoding='utf-8') as f:
        for r in csv.DictReader(f):
            if r['split'] != 'test':
                continue
            chemin = dataset / r['path']
            if not chemin.exists():
                continue
            lignes.append({
                'chemin': str(chemin),
                'verite': r['internal_plant_id'],
                'groupe': r.get('group', ''),
                'captive': '1' if r.get('captive') == '1' else '0',
            })
    return lignes


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--dataset', default='../plant_dataset/dataset')
    ap.add_argument('--indoor', default='../plant_dataset/masque_indoor.txt')
    ap.add_argument('--outdoor', default='../plant_dataset/masque_outdoor.txt')
    ap.add_argument('--hors-sujet', help='dossier de photos hors sujet, rangées par sous-dossier')
    ap.add_argument('--out', default='benchmark.csv')
    ap.add_argument('--par-tranche', type=int, default=2000,
                    help='images au plus par tranche ; 0 = toutes')
    ap.add_argument('--graine', type=int, default=20260919)
    args = ap.parse_args()

    dataset = Path(args.dataset).expanduser()
    indoor = lire_masque(Path(args.indoor).expanduser())
    outdoor = lire_masque(Path(args.outdoor).expanduser())
    if not indoor:
        raise SystemExit(f'masque Indoor introuvable ou vide : {args.indoor}')

    test = lire_test(dataset)
    if not test:
        raise SystemExit(f'aucune image de test dans {dataset}')

    # Les groupes d'abord : une observation à plusieurs photos ne doit pas voir
    # ses photos réparties entre les tranches, sinon la fusion se mesurerait
    # sur des images que les autres tranches ont déjà données.
    par_groupe = defaultdict(list)
    for l in test:
        par_groupe[l['groupe']].append(l)
    multi = [l for g, lot in par_groupe.items() if g and len(lot) >= 2 for l in lot]
    vus_multi = {l['chemin'] for l in multi}

    tranches: dict[str, list[dict]] = {
        'indoor': [l for l in test if l['verite'] in indoor
                   and l['captive'] == '1' and l['chemin'] not in vus_multi],
        'outdoor': [l for l in test if l['verite'] in outdoor and l['verite'] not in indoor
                    and l['chemin'] not in vus_multi],
        'multi': multi,
        'ood_plante': [l for l in test if l['verite'] not in indoor and l['verite'] not in outdoor
                       and l['chemin'] not in vus_multi],
        'ood_autre': [],
    }

    if args.hors_sujet:
        racine = Path(args.hors_sujet).expanduser()
        for p in sorted(racine.rglob('*')):
            if p.suffix.lower() in EXTENSIONS:
                tranches['ood_autre'].append({
                    'chemin': str(p), 'verite': '',
                    'groupe': p.parent.name, 'captive': '0',
                })

    alea = random.Random(args.graine)
    with open(args.out, 'w', newline='', encoding='utf-8') as f:
        w = csv.writer(f)
        w.writerow(['tranche', 'chemin', 'verite', 'groupe', 'captive'])
        for nom, lot in tranches.items():
            garde = lot
            if args.par_tranche and len(lot) > args.par_tranche:
                # Tirer par groupe, pas par image : couper une observation en
                # deux ferait mesurer la fusion sur une photo manquante.
                groupes = sorted({l['groupe'] or l['chemin'] for l in lot})
                alea.shuffle(groupes)
                gardes, n = set(), 0
                for g in groupes:
                    if n >= args.par_tranche:
                        break
                    gardes.add(g)
                    n += sum(1 for l in lot if (l['groupe'] or l['chemin']) == g)
                garde = [l for l in lot if (l['groupe'] or l['chemin']) in gardes]
            especes = len({l['verite'] for l in garde if l['verite']})
            print(f'{nom:12s} {len(garde):6d} images  {especes:5d} espèces')
            for l in garde:
                w.writerow([nom, l['chemin'], l['verite'], l['groupe'], l['captive']])
    print(f'\n{args.out} écrit — graine {args.graine}, à recalculer à l\'identique')
    if not tranches['ood_autre']:
        print('ood_autre vide : passer --hors-sujet sur des dossiers remplis (§ 12.7)')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
