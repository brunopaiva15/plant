#!/usr/bin/env python3
"""Le réseau a-t-il appris sur autre chose que ce que l'application lui donne ?

    python3 recettes.py --dataset /data2/dataset-v8 --modele ../../assets/model \
                        --echantillon 800

Les images d'entraînement sont réduites **à la collecte** : le cadre entier
ramené à `MAX_SIDE = 384` px de grand côté, en LANCZOS. `read_and_square`
prend ensuite leur carré central — donc le petit côté, 288 px pour une 4:3
— et l'agrandit à `LOAD_SIZE` (366 à `--input-size 320`).

`tflite_plant_model.dart` fait l'inverse, dans l'autre ordre : il prend le
carré central de la photo **d'abord**, le réduit à `source_size` — que
`model.json` annonce à **448** — puis descend à `LOAD_SIZE`. Le réseau a
donc appris sur des carrés de 288 px étirés à 366, flous par construction,
et reçoit des carrés de 448 px réduits à 366, c'est-à-dire nets.

**Et ça ne se mesure pas sur le jeu de test tel qu'il est stocké.** À 384 px,
le carré vaut 288, la condition `carré > 448` de l'application est fausse,
la moyenne de zone est sautée et les deux chemins coïncident exactement.
L'écart n'existe que sur un **original haute résolution** — c'est pourquoi
cet outil re-télécharge les originaux depuis les URL du manifeste au lieu
de relire le jeu.

Trois recettes, le même modèle, les mêmes images :

| | ordre | taille intermédiaire |
|---|---|---|
| **entraînement** | cadre entier → 384 (LANCZOS), puis carré | ce que le réseau a vu |
| **application** | carré, puis 448 (moyenne de zone) | ce qu'il reçoit aujourd'hui |
| **corrigée** | cadre entier → 384 (moyenne de zone), puis carré | ce qu'on propose |

La recette « entraînement » est la référence : c'est la seule dont on sache
qu'elle correspond à l'apprentissage. Si « application » s'en écarte et que
« corrigée » la rejoint, le défaut est réel et la correction tient — et
elle ne coûte qu'un export, sans réentraîner (§ 12.6, § 12.10).

> **Ce que l'outil ne dit pas.** Une image plus nette que l'entraînement
> n'est pas forcément moins bien reconnue : le signe de l'écart est une
> question ouverte, pas une conclusion. Et l'échantillon est celui du jeu
> de test, donc du domaine du jeu — pas des photos de salon du § 13.3.
"""
from __future__ import annotations

import argparse
import csv
import json
import random
import sys
import time
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))

MAX_SIDE = 384      # plant_dataset/images.py — la taille de stockage du jeu
SOURCE_SIZE = 448   # ce que model.json annonce, et que l'application applique


def _carre(img: Image.Image) -> Image.Image:
    cote = min(img.size)
    g, h = (img.width - cote) // 2, (img.height - cote) // 2
    return img.crop((g, h, g + cote, h + cote))


def _reduire_cadre(img: Image.Image, max_side: int, filtre: int) -> Image.Image:
    """Le cadre entier ramené à `max_side` de grand côté — l'étape de la
    collecte, celle que l'application ne fait pas."""
    if max(img.size) <= max_side:
        return img
    e = max_side / max(img.size)
    return img.resize((max(1, round(img.width * e)), max(1, round(img.height * e))), filtre)


def _recadrer(img: Image.Image, size: int) -> np.ndarray:
    d = (img.width - size) // 2
    return np.asarray(img.crop((d, d, d + size, d + size)).convert('RGB'), dtype=np.uint8)


def recette_entrainement(img: Image.Image, load: int, size: int, max_side: int = MAX_SIDE) -> np.ndarray:
    """Ce que le réseau a vu : la collecte réduit le cadre entier en LANCZOS,
    puis `read_and_square` prend le carré et l'amène à `load`."""
    petit = _carre(_reduire_cadre(img, max_side, Image.LANCZOS))
    return _recadrer(petit.resize((load, load), Image.BILINEAR), size)


def recette_application(img: Image.Image, load: int, size: int, source_size: int = SOURCE_SIZE) -> np.ndarray:
    """Ce que `tflite_plant_model.dart` fait : le carré d'abord, la moyenne
    de zone ensuite, et seulement si le carré dépasse `source_size`."""
    carre = _carre(img)
    if carre.width > source_size > load:
        carre = carre.resize((source_size, source_size), Image.BOX)   # `Interpolation.average`
    return _recadrer(carre.resize((load, load), Image.BILINEAR), size)


def recette_corrigee(img: Image.Image, load: int, size: int, max_side: int = MAX_SIDE) -> np.ndarray:
    """La correction proposée : le même ordre et la même taille que la
    collecte, avec le filtre dont l'application dispose."""
    petit = _carre(_reduire_cadre(img, max_side, Image.BOX))
    return _recadrer(petit.resize((load, load), Image.BILINEAR), size)


RECETTES = {'entraînement': recette_entrainement,
            'application': recette_application,
            'corrigée': recette_corrigee}


def telecharger(url: str, pause: float, essais: int = 5) -> bytes | None:
    """Comme `prototypes._telecharger` : un 429 se reprend, il ne se perd pas."""
    import requests
    for essai in range(essais):
        try:
            r = requests.get(url, timeout=60,
                             headers={'User-Agent': 'FloraPlantDataset/0.1 (github.com/brunopaiva15/plant)'})
            if r.status_code == 429:
                time.sleep(float(r.headers.get('Retry-After') or min(15 * (essai + 1), 60)))
                continue
            r.raise_for_status()
            time.sleep(pause)
            return r.content
        except requests.RequestException as e:
            if essai == essais - 1:
                code = getattr(getattr(e, 'response', None), 'status_code', '?')
                print(f'    {url} : abandon (HTTP {code})', file=sys.stderr)
                return None
            time.sleep(min(2 ** essai, 30))
    return None


def echantillon_test(dataset: Path, combien: int, graine: int) -> list[tuple[str, str]]:
    """(chemin relatif, étiquette) tirés du seul split de test."""
    with (dataset / 'splits.csv').open(newline='', encoding='utf-8') as f:
        lignes = [(r['path'], r['internal_plant_id']) for r in csv.DictReader(f) if r['split'] == 'test']
    random.seed(graine)
    return random.sample(lignes, min(combien, len(lignes)))


def urls_du_manifeste(dataset: Path) -> dict[str, str]:
    """chemin relatif → URL de l'image d'origine, pleine résolution."""
    urls: dict[str, str] = {}
    chemin = dataset / 'manifest.jsonl'
    if not chemin.exists():
        return urls
    with chemin.open(encoding='utf-8') as f:
        for ligne in f:
            if not ligne.strip():
                continue
            d = json.loads(ligne)
            if d.get('path') and d.get('image_url'):
                urls[d['path']] = d['image_url']
    return urls


def _juger(model, lot: np.ndarray) -> np.ndarray:
    x = lot[None, ...].astype(np.float32)
    if model['in']['dtype'] != np.float32:
        x = x.astype(model['in']['dtype'])
    model['interpreter'].set_tensor(model['in']['index'], x)
    model['interpreter'].invoke()
    return model['interpreter'].get_tensor(model['out']['index'])[0]


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--dataset', required=True)
    ap.add_argument('--modele', default='../../assets/model')
    ap.add_argument('--echantillon', type=int, default=800)
    ap.add_argument('--cache', default='.cache/originaux', help='les originaux téléchargés, gardés entre deux passes')
    ap.add_argument('--pause', type=float, default=0.3)
    ap.add_argument('--seed', type=int, default=20260914)
    args = ap.parse_args(argv)

    dataset, cache = Path(args.dataset), Path(args.cache)
    from compare_models import load_model
    model = load_model(Path(args.modele))
    load, size = model['load_size'], model['input_size']
    index = model['index']
    print(f'modèle v{model["version"]} — {len(model["labels"])} classes, '
          f'entrée {size} px, chargement {load} px\n')

    lignes = echantillon_test(dataset, args.echantillon, args.seed)
    urls = urls_du_manifeste(dataset)
    if not urls:
        print(f'{dataset}/manifest.jsonl introuvable : sans lui, pas d\'originaux.', file=sys.stderr)
        return 1

    cache.mkdir(parents=True, exist_ok=True)
    justes = {nom: 0 for nom in RECETTES}
    top3 = {nom: 0 for nom in RECETTES}
    confiance = {nom: 0.0 for nom in RECETTES}
    desaccords = 0
    faits = sans_url = sans_classe = 0

    for n, (rel, etiquette) in enumerate(lignes, 1):
        if etiquette not in index:
            sans_classe += 1
            continue
        url = urls.get(rel)
        if not url:
            sans_url += 1
            continue
        local = cache / rel.replace('/', '_')
        if not local.exists():
            octets = telecharger(url, args.pause)
            if octets is None:
                continue
            local.write_bytes(octets)
        try:
            with Image.open(local) as brut:
                img = brut.convert('RGB')
                sorties = {nom: _juger(model, f(img, load, size)) for nom, f in RECETTES.items()}
        except Exception as e:
            print(f'    {rel} : {type(e).__name__}: {e}', file=sys.stderr)
            continue
        vrai = index[etiquette]
        faits += 1
        for nom, probs in sorties.items():
            ordre = np.argsort(-probs)
            justes[nom] += int(ordre[0] == vrai)
            top3[nom] += int(vrai in ordre[:3])
            confiance[nom] += float(probs[ordre[0]])
        if np.argmax(sorties['entraînement']) != np.argmax(sorties['application']):
            desaccords += 1
        if n % 100 == 0:
            print(f'  {n}/{len(lignes)}', file=sys.stderr, flush=True)

    if not faits:
        print('aucune image exploitable.', file=sys.stderr)
        return 1
    print(f'{faits} images jugées'
          f'{f", {sans_url} sans URL" if sans_url else ""}'
          f'{f", {sans_classe} hors des classes du modèle" if sans_classe else ""}\n')
    print(f'{"recette":<16} {"top-1":>8} {"top-3":>8} {"confiance":>10}')
    ref = justes['entraînement'] / faits
    for nom in RECETTES:
        t1 = justes[nom] / faits
        ecart = '' if nom == 'entraînement' else f'  ({(t1 - ref) * 100:+.1f} pt)'
        print(f'{nom:<16} {t1:>8.4f} {top3[nom] / faits:>8.4f} {confiance[nom] / faits:>10.4f}{ecart}')
    print(f'\ntop-1 différent entre entraînement et application : '
          f'{desaccords}/{faits} — {desaccords / faits:.1%}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
