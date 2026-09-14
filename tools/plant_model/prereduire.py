#!/usr/bin/env python3
"""Le jeu pré-découpé au carré : ce que ça rend, avant de convertir 794 000 images.

    python3 prereduire.py --dataset /data2/dataset-v8 --input-size 320
    python3 prereduire.py --dataset /data2/dataset-v8 --input-size 320 \
                          --out /ephemeral/dataset-v8-carre --convertir

Le § 13.6 demandait de « stocker le jeu déjà réduit à la taille de
chargement » pour supprimer le décodage JPEG, qui plafonne le tuyau à ~750
images/s. **Le raisonnement était juste et le chiffre à l'envers.**

`read_and_square` fait trois choses à chaque époque : décoder le JPEG,
prendre son **carré central**, le redimensionner à `LOAD_SIZE`. Or le jeu
est stocké à `MAX_SIDE = 384` px de **grand** côté (`plant_dataset/images.py`)
— donc son carré central vaut le **petit** côté, soit 288 px pour une photo
en 4:3, 256 en 3:2, 216 en 16:9. À `--input-size 320`, `LOAD_SIZE` vaut
366 : la plupart des images sont **agrandies**, pas réduites.

Stocker le jeu à 366 px ajouterait donc des pixels à décoder au lieu d'en
retirer. Ce qui paie, c'est l'inverse : **pré-découper au carré sans jamais
agrandir**. Le décodeur ne lit plus que le carré — 288² au lieu de 384×288,
un quart de pixels en moins —, le recadrage disparaît, et le
redimensionnement final reste à sa place. **L'image que le réseau voit ne
change pas** : les mêmes opérations dans le même ordre, l'agrandissement
simplement repoussé à l'endroit où il était déjà.

D'où cet outil en deux temps, et le premier n'écrit rien. Convertir 794 000
images coûte une heure et 50 Go ; savoir ce que ça rend coûte trente
secondes sur un échantillon. C'est la leçon du § 12.7 appliquée ici.

> **Ce que la mesure peut dire, et qui vaut plus que le gain.** Si le carré
> central médian est nettement sous `LOAD_SIZE`, alors l'entraînement à
> 320 px travaille sur des images agrandies — il ne voit pas plus de détail
> qu'à 288, seulement plus de pixels. Le gain du § 12.6 serait alors réel
> mais mal attribué, et le garde-fou de `set_input_size` ne l'a pas vu
> parce qu'il compare `LOAD_SIZE` au **grand** côté quand le tuyau se sert
> du **petit**.
"""
from __future__ import annotations

import argparse
import csv
import random
import shutil
import sys
import time
from collections import Counter
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))

QUALITE = 95   # au-dessus des 92 du jeu source : un aller-retour JPEG ne doit
               # pas être ce qui décide de la mesure suivante


def load_size_pour(px: int) -> int:
    """Le `LOAD_SIZE` que `train.py` emploierait pour cette taille d'entrée."""
    return round(px * 256 / 224)


def lignes(dataset: Path) -> list[tuple[Path, str]]:
    with (dataset / 'splits.csv').open(newline='', encoding='utf-8') as f:
        return [(dataset / r['path'], r['split']) for r in csv.DictReader(f)]


def carre_cible(largeur: int, hauteur: int, load: int) -> int:
    """Le côté auquel stocker le carré central : jamais plus que ce que
    l'image a, jamais plus que ce que le chargement demandera.

    Les deux bornes comptent. Sans la première on agrandirait à l'écriture,
    ce que cet outil existe pour éviter ; sans la seconde on garderait des
    pixels que `read_and_square` jetterait de toute façon.
    """
    return min(min(largeur, hauteur), load)


def convertir_une(src: Path, dst: Path, load: int) -> tuple[int, int]:
    """Écrit le carré central de `src` dans `dst`. Rend (pixels avant, après)."""
    with Image.open(src) as img:
        img = img.convert('RGB')
        w, h = img.size
        cote = min(w, h)
        g, haut = (w - cote) // 2, (h - cote) // 2
        carre = img.crop((g, haut, g + cote, haut + cote))
        cible = carre_cible(w, h, load)
        if cible < cote:
            carre = carre.resize((cible, cible), Image.LANCZOS)
        dst.parent.mkdir(parents=True, exist_ok=True)
        carre.save(dst, 'JPEG', quality=QUALITE, optimize=True)
    return w * h, cible * cible


def mesurer(rows: list[tuple[Path, str]], load: int, echantillon: int, graine: int) -> None:
    """Ce que le jeu contient vraiment, et ce que la conversion rendrait."""
    random.seed(graine)
    choisis = random.sample(rows, min(echantillon, len(rows)))
    cotes, avant, apres, manquantes = [], 0, 0, 0
    for path, _ in choisis:
        if not path.exists():
            manquantes += 1
            continue
        with Image.open(path) as img:       # l'en-tête suffit pour les tailles
            w, h = img.size
        cotes.append(min(w, h))
        avant += w * h
        apres += carre_cible(w, h, load) ** 2
    if not cotes:
        print('aucune image lisible dans l\'échantillon.', file=sys.stderr)
        return
    cotes.sort()
    n = len(cotes)
    med = cotes[n // 2]
    agrandies = sum(1 for c in cotes if c < load)
    print(f'{n} images lues{f" ({manquantes} absentes)" if manquantes else ""}, '
          f'LOAD_SIZE = {load} px\n')
    print('  carré central (le petit côté, ce que le tuyau utilise)')
    print(f'    médiane {med} px — min {cotes[0]}, max {cotes[-1]}')
    for q, nom in ((0.10, 'p10'), (0.25, 'p25'), (0.75, 'p75'), (0.90, 'p90')):
        print(f'    {nom} {cotes[int(q * (n - 1))]} px')
    print(f'\n  images que le chargement **agrandit** à {load} px : '
          f'{agrandies}/{n} — {agrandies / n:.0%}')
    ecart = 1 - apres / avant
    print(f'  pixels décodés : {avant / n / 1e3:.0f} k/image aujourd\'hui, '
          f'{apres / n / 1e3:.0f} k après conversion — '
          f'{abs(ecart):.0%} {"de moins" if ecart > 0 else "de plus"}')
    if agrandies / n > 0.5:
        print(f'\n  → plus d\'une image sur deux est agrandie : l\'entraînement à cette\n'
              f'    taille ne voit pas plus de détail qu\'à {med} px, seulement plus de\n'
              f'    pixels. Pré-réduire **à {load} px** en ajouterait encore.')


def chronometrer(rows: list[tuple[Path, str]], load: int, combien: int, graine: int) -> None:
    """Le coût réel d'un chargement, avant et après, avec le décodeur de
    `train.py` quand il est là — sinon celui de Pillow, et l'outil le dit."""
    random.seed(graine + 1)
    choisis = [p for p, _ in random.sample(rows, min(combien, len(rows))) if p.exists()]
    if not choisis:
        return
    try:
        import tensorflow as tf
        from train import read_and_square, set_input_size
        set_input_size(int(load * 224 / 256))
        decodeur = 'tensorflow'

        def charger(p):
            read_and_square(str(p), 0)
    except Exception as e:                  # pas de TF : Pillow dit l'ordre de grandeur
        decodeur = f'pillow (tensorflow indisponible : {type(e).__name__})'

        def charger(p):
            with Image.open(p) as im:
                im.convert('RGB').load()

    for p in choisis[:5]:                   # une passe à vide : le cache disque ment
        charger(p)
    t0 = time.perf_counter()
    for p in choisis:
        charger(p)
    dt = time.perf_counter() - t0
    print(f'\n  chargement mesuré ({decodeur}) : {len(choisis) / dt:.0f} images/s '
          f'sur un cœur, {dt / len(choisis) * 1e3:.1f} ms/image')


def convertir(rows: list[tuple[Path, str]], dataset: Path, out: Path, load: int) -> None:
    out.mkdir(parents=True, exist_ok=True)
    shutil.copy2(dataset / 'splits.csv', out / 'splits.csv')
    avant = apres = 0
    faites = ratees = 0
    for n, (src, _) in enumerate(rows, 1):
        if not src.exists():
            continue
        try:
            a, b = convertir_une(src, out / src.relative_to(dataset), load)
        except Exception as e:
            ratees += 1
            print(f'  {src.name} : {type(e).__name__}: {e}', file=sys.stderr)
            continue
        avant, apres, faites = avant + a, apres + b, faites + 1
        if n % 20000 == 0:
            print(f'  {n}/{len(rows)}', file=sys.stderr, flush=True)
    print(f'\n{faites} images écrites dans {out}'
          f'{f", {ratees} en échec" if ratees else ""}.')
    if faites:
        ecart = 1 - apres / avant
        print(f'pixels à décoder : {avant / faites / 1e3:.0f} k → {apres / faites / 1e3:.0f} k '
              f'par image, {abs(ecart):.0%} {"de moins" if ecart > 0 else "de plus"}.')
    print('`splits.csv` est recopié tel quel : les chemins ne bougent pas, '
          f'`train.py --dataset {out}` suffit.')


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--dataset', required=True)
    ap.add_argument('--input-size', type=int, default=320)
    ap.add_argument('--out', help='où écrire le jeu converti ; requis avec --convertir')
    ap.add_argument('--convertir', action='store_true', help='sans quoi rien n\'est écrit')
    ap.add_argument('--echantillon', type=int, default=4000)
    ap.add_argument('--chrono', type=int, default=300, help='images chronométrées ; 0 pour sauter')
    ap.add_argument('--seed', type=int, default=20260914)
    args = ap.parse_args(argv)

    dataset = Path(args.dataset)
    if not (dataset / 'splits.csv').exists():
        print(f'{dataset}/splits.csv introuvable.', file=sys.stderr)
        return 1
    load = load_size_pour(args.input_size)
    rows = lignes(dataset)
    print(f'{len(rows)} lignes dans splits.csv, --input-size {args.input_size}\n')

    mesurer(rows, load, args.echantillon, args.seed)
    if args.chrono:
        chronometrer(rows, load, args.chrono, args.seed)

    if not args.convertir:
        print('\nRien n\'a été écrit. Relancer avec --out <dossier> --convertir.')
        return 0
    if not args.out:
        print('--convertir demande --out.', file=sys.stderr)
        return 1
    convertir(rows, dataset, Path(args.out), load)
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
