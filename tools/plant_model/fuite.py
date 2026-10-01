#!/usr/bin/env python3
"""Le banc a-t-il des jumeaux dans un corpus d'entraînement ?

    python3 fuite.py --dataset ~/plant-data/plantnet-interieur
    python3 fuite.py --dataset ~/plant-data/dataset-v8-indoor --dataset ~/plant-data/plantnet-interieur

**Pourquoi.** Les corpus ajoutés passent trois gardes contre la fuite
(§ 20 quater et 20 sexies de `docs/14`) : l'identifiant, l'observation,
l'empreinte perceptuelle à 6 bits. L'empreinte rattrape une copie
recompressée ou réduite ; elle laisse passer une photo recadrée, tournée ou
retouchée, publiée par son auteur sur deux sites. Un gain soudain sur le
banc — +12 points dès la première époque — se vérifie avant de se fêter.

**Comment.** Les vecteurs du teacher sont déjà dans le cache, pour le banc
comme pour le corpus. Pour chaque image du banc, on cherche la plus proche
du corpus, au cosinus. Deux photos différentes de la même espèce montent
rarement au-dessus de 0,95 ; une même photo recadrée, presque toujours.

**La lecture qui tranche est la comparaison.** Le corpus v8 est séparé du
banc par observation depuis le début : son niveau de voisinage est celui
d'un corpus propre. Un corpus nouveau qui en compte nettement plus au-dessus
des mêmes seuils a des jumeaux du banc ; les paires listées se regardent.

Rien ne touche au GPU.
"""
from __future__ import annotations

import argparse
import csv
from pathlib import Path

import numpy as np

from voisins import lire_banc, lire_embeddings

SEUILS = (0.90, 0.95, 0.97, 0.99)


def plus_proches(requetes: np.ndarray, corpus: np.ndarray,
                 paquet: int = 50_000) -> tuple[np.ndarray, np.ndarray]:
    """(cosinus maximal, indice dans le corpus) pour chaque requête.

    Par paquets du corpus, pour tenir en mémoire : 266 000 × 1 024 en
    float32 font un gigaoctet.
    """
    q = requetes / np.maximum(np.linalg.norm(requetes, axis=1, keepdims=True), 1e-12)
    meilleur = np.full(len(q), -np.inf, dtype=np.float32)
    ou = np.zeros(len(q), dtype=np.int64)
    for d in range(0, len(corpus), paquet):
        c = corpus[d:d + paquet].astype(np.float32)
        c /= np.maximum(np.linalg.norm(c, axis=1, keepdims=True), 1e-12)
        sim = q @ c.T
        i = sim.argmax(axis=1)
        s = sim[np.arange(len(q)), i]
        mieux = s > meilleur
        meilleur[mieux] = s[mieux]
        ou[mieux] = d + i[mieux]
    return meilleur, ou


def au_dessus(sims: np.ndarray, seuils=SEUILS) -> dict[float, int]:
    return {s: int((sims >= s).sum()) for s in seuils}


def chemins_du_corpus(dataset: Path) -> list[str]:
    with open(dataset / 'splits.csv', newline='', encoding='utf-8') as f:
        return [str(dataset / r['path']) for r in csv.DictReader(f)
                if r.get('split', 'train') == 'train']


def main() -> int:  # pragma: no cover - demande le cache et le banc
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--dataset', action='append', required=True,
                    help='répétable : chaque corpus est lu à part, pour les comparer')
    ap.add_argument('--banc', default='benchmark.csv')
    ap.add_argument('--cache', default='~/plant-data/bioclip')
    ap.add_argument('--tranche', default='indoor')
    ap.add_argument('--paires', type=int, default=15, help='les paires les plus proches à lister')
    args = ap.parse_args()

    cache = Path(args.cache).expanduser()
    lignes = lire_banc(Path(args.banc).expanduser(), args.tranche)
    gardes, banc = lire_embeddings(cache, [c for c, _ in lignes])
    print(f'{args.tranche} : {len(gardes)} images du banc dans le cache\n')
    print(f"  {'corpus':<28} {'images':>8}  " + '  '.join(f'≥ {s:.2f}' for s in SEUILS))
    for d in args.dataset:
        dataset = Path(d).expanduser()
        chemins = chemins_du_corpus(dataset)
        pris, vecteurs = lire_embeddings(cache, chemins)
        if not pris:
            print(f'  {dataset.name:<28} aucun vecteur dans le cache')
            continue
        sims, ou = plus_proches(banc, vecteurs)
        c = au_dessus(sims)
        print(f'  {dataset.name:<28} {len(pris):>8}  '
              + '  '.join(f'{c[s]:>6}' for s in SEUILS))
        ordre = np.argsort(-sims)[:args.paires]
        for k in ordre:
            print(f'      {sims[k]:.4f}  {lignes[gardes[k]][0]}')
            print(f'              {chemins[pris[ou[k]]]}')
        print()
    print('Deux photos différentes montent rarement au-dessus de 0,95. Les paires '
          'listées se regardent : une même photo, recadrée ou retouchée, est une fuite.')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
