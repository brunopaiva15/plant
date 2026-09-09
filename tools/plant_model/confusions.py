#!/usr/bin/env python3
"""Sur quoi le modèle se trompe — pas seulement combien.

    python3 confusions.py --dataset ../plant_dataset/dataset \\
        --model ../../assets/model --sample 6000

`train.py` rend le top-1, le top-3, le macro-F1 et la courbe de seuil : on
sait *combien* le modèle se trompe, jamais *sur quoi*. Le § 6.9 promet une
matrice de confusion par genre depuis la v1 ; sans elle, les défauts se
trouvent un par un, à la main, sur des photos réelles — c'est comme ça que
le yucca pris pour du maïs a été découvert (§ 6.3), et il avait eu le temps
de traverser trois versions.

La distinction qui fait tout le tri :

- **une confusion dans le genre** est attendue. Deux érables, deux sapins,
  deux pépéromias se ressemblent, et l'écran propose cinq candidats : la
  bonne réponse y est presque toujours. Ce n'est pas là qu'il faut dépenser
  des images.
- **une confusion entre genres** est un vrai défaut. *Yucca* → *Zea*,
  c'est le modèle qui n'a jamais vu la plante telle qu'on la cultive. Ces
  paires-là se corrigent par des images, et elles disent lesquelles.

Le rapport se lit donc de haut en bas : la part des erreurs qui sortent du
genre d'abord, les paires responsables ensuite, et enfin les espèces qui
échouent le plus souvent avec ce qu'on leur répond à la place.
"""
from __future__ import annotations

import argparse
import csv
import random
import sys
from collections import Counter, defaultdict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))


def genre(internal_id: str, noms: dict[str, str] | None = None) -> str:
    """Le genre d'une espèce, depuis son identifiant interne.

    Les identifiants sont `genre-épithète` (`monstera-deliciosa`), donc le
    préfixe suffit — et reste juste pour les hybrides, dont l'identifiant
    porte le `x` en deuxième position (`abelia-x-grandiflora`). `plants.csv`
    sert de recours quand il est là, mais l'outil doit tourner sans.
    """
    if noms and internal_id in noms:
        return noms[internal_id].split()[0].lower()
    return internal_id.split('-')[0]


def croiser(paires: list[tuple[str, str]], noms: dict[str, str] | None = None) -> dict:
    """Range les erreurs selon qu'elles restent dans le genre ou en sortent.

    `paires` est une liste de (vérité, prédiction) en identifiants internes.
    """
    justes = hors_genre = dans_genre = 0
    entre_genres: Counter = Counter()
    par_espece: dict[str, Counter] = defaultdict(Counter)
    vues: Counter = Counter()
    for verite, predit in paires:
        vues[verite] += 1
        if verite == predit:
            justes += 1
            continue
        par_espece[verite][predit] += 1
        gv, gp = genre(verite, noms), genre(predit, noms)
        if gv == gp:
            dans_genre += 1
        else:
            hors_genre += 1
            entre_genres[(gv, gp)] += 1
    return {
        'images': len(paires),
        'justes': justes,
        'dans_genre': dans_genre,
        'hors_genre': hors_genre,
        'entre_genres': entre_genres,
        'par_espece': par_espece,
        'vues': vues,
    }


def especes_en_difficulte(stats: dict, minimum: int = 5) -> list[tuple[str, int, int, str, int]]:
    """Les espèces les plus ratées, avec ce qu'on leur répond à la place.

    En dessous de `minimum` images de test, un taux d'échec ne veut rien
    dire — on ne classe pas une espèce sur trois photos.
    """
    out = []
    for espece, vues in stats['vues'].items():
        if vues < minimum:
            continue
        erreurs = stats['par_espece'].get(espece)
        if not erreurs:
            continue
        coupable, combien = erreurs.most_common(1)[0]
        out.append((espece, sum(erreurs.values()), vues, coupable, combien))
    out.sort(key=lambda r: (-r[1] / r[2], -r[2]))
    return out


def _rapport(stats: dict, noms: dict[str, str], top: int) -> None:
    n, justes = stats['images'], stats['justes']
    erreurs = n - justes
    print(f'{n} images, {justes} justes ({justes / n:.1%})\n')
    if not erreurs:
        print('aucune erreur : rien à dire.')
        return
    print(f"{erreurs} erreurs, dont :")
    print(f"  {stats['dans_genre']:6d} dans le même genre  ({stats['dans_genre'] / erreurs:.0%})  — attendues")
    print(f"  {stats['hors_genre']:6d} entre genres        ({stats['hors_genre'] / erreurs:.0%})  — les vrais défauts")

    def joli(i):
        return noms.get(i, i)

    print(f'\nles {top} confusions entre genres les plus fréquentes :')
    for (gv, gp), combien in stats['entre_genres'].most_common(top):
        print(f'  {gv:22s} → {gp:22s} {combien:5d}')

    print(f'\nles {top} espèces les plus ratées (au moins 5 images de test) :')
    for espece, ratees, vues, coupable, combien in especes_en_difficulte(stats)[:top]:
        mot = 'même genre' if genre(espece, noms) == genre(coupable, noms) else 'AUTRE GENRE'
        print(f'  {joli(espece):34s} {ratees:3d}/{vues:3d} ratées → {joli(coupable):32s} ×{combien} ({mot})')


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--dataset', default='../plant_dataset/dataset')
    ap.add_argument('--model', default='../../assets/model')
    ap.add_argument('--sample', type=int, default=6000, help='images de test tirées au hasard, 0 = toutes')
    ap.add_argument('--seed', type=int, default=20260905)
    ap.add_argument('--captive', action='store_true', help='ne garder que les photos de plantes cultivées')
    ap.add_argument('--top', type=int, default=20)
    ap.add_argument('--csv', help='écrire toutes les paires (vérité, prédiction) pour creuser ailleurs')
    ap.add_argument('--plants', default='../plant_dataset/plants.csv')
    args = ap.parse_args(argv)

    # Importés ici : ils tirent TensorFlow, dont les fonctions pures de ce
    # fichier n'ont pas besoin pour être testées.
    import numpy as np
    from compare_models import load_model, predict, read_test

    noms = {}
    plants = Path(args.plants)
    if plants.exists():
        noms = {r['internal_id']: r['scientific_name'] for r in csv.DictReader(plants.open(encoding='utf-8'))}

    modele = load_model(Path(args.model))
    lignes = [(p, t) for p, t, cap in read_test(Path(args.dataset)) if not args.captive or cap]
    lignes = [(p, t) for p, t in lignes if t in modele['index']]
    if args.sample and len(lignes) > args.sample:
        lignes = random.Random(args.seed).sample(lignes, args.sample)
    print(f"modèle v{modele['version']} — {len(lignes)} images de test"
          f"{' (plantes cultivées)' if args.captive else ''}\n", flush=True)

    paires = []
    for i, (chemin, verite) in enumerate(lignes, 1):
        paires.append((verite, modele['labels'][int(np.argmax(predict(modele, chemin)))]))
        if i % 500 == 0:
            print(f'  {i}/{len(lignes)}', flush=True)
    print()

    if args.csv:
        with open(args.csv, 'w', newline='', encoding='utf-8') as f:
            w = csv.writer(f)
            w.writerow(['verite', 'prediction'])
            w.writerows(paires)
        print(f'{len(paires)} paires écrites dans {args.csv}\n')

    _rapport(croiser(paires, noms), noms, args.top)
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
