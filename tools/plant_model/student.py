#!/usr/bin/env python3
"""Ce qu'un student garde de l'espace du teacher — le plancher sous le plafond.

    python3 student.py --banc benchmark.csv --modele ~/plant-data/flora_student.onnx \\
        --cache ~/plant-data/student
    python3 voisins.py --banc benchmark.csv --cache ~/plant-data/bioclip \\
        --embeddings ~/plant-data/student --iris ../../assets/model

La porte C est franchie (§ 19 de `docs/14`), mais avec le **teacher** :
ViT-H/14, 630 M de paramètres, 1,3 Go, 79 img/s sur une RTX 2070 Super. Rien
de cela ne tient sur un téléphone. Ce que mesure ce script, c'est ce qu'un
student de 11,6 M de paramètres en conserve — donc le plancher en face de ce
plafond.

**Et il y a un student public à mesurer avant d'en entraîner un.**
`crazedcodernate/bioclip-2.5-mobile-fastvit` applique exactement la recette
de l'étape 5 : perte cosinus sur des embeddings de teacher cachés, FastViT,
sortie à 1 024 dimensions dans l'espace BioCLIP. Le mesurer coûte une heure ;
entraîner le nôtre coûte des jours. L'ordre va de soi.

## Il écrit un cache, pas un compte rendu

Le format est celui de `bioclip.py` — `signature.json`, fragments `.npy`,
index par chemin. `voisins.py --embeddings` lit alors les vecteurs du student
là où il lirait ceux du teacher, **contre les mêmes références**. Rien
d'autre ne change, donc rien d'autre ne peut expliquer un écart.

Et c'est aussi la vérité du produit : le téléphone n'embarquera jamais
l'encodeur de texte, les références restent pré-calculées hors app (§ 7).
Comparer les vecteurs du student aux références du teacher n'est pas une
commodité de mesure, c'est le montage livré.

## Le prétraitement, qui n'est pas celui du teacher

La carte du modèle est explicite, et elle diffère sur deux points de tout ce
qu'on manipule par ailleurs :

| | ce que ce student attend |
|---|---|
| entrée | `[1, 3, 224, 224]` NCHW, `float32`, **valeurs 0-1** |
| normalisation | **repliée dans le graphe** — ne pas l'appliquer soi-même |
| sortie | `[1, 1024]`, **déjà unitaire** |

Appliquer la normalisation ImageNet par-dessus, comme le demande le ResNet18
de PlantNet, la passerait deux fois. Ça ne planterait pas ; ça rendrait des
vecteurs faux.

## Le recadrage est une variable, donc il se mesure

L'implémentation de référence de la carte fait un `resize((224, 224))`
direct, qui **déforme** l'image. Notre chaîne — et celle du teacher — recadre
au carré central avant de réduire. Les deux sont défendables : la première
est ce que l'auteur a validé, la seconde est ce que le teacher a vu.

`--recadrage` les sépare, et on les mesure plutôt que d'en supposer une.
C'est la règle du § 12 de `docs/09` : une recette à la fois.
"""
from __future__ import annotations

import argparse
import csv
import json
import time
from pathlib import Path

import numpy as np

from bioclip import accorder_signature, empreinte, extrapolation, lire_index, restant

ENTREE = 224
DIM = 1024


# --------------------------------------------------------------------------
# Le prétraitement
# --------------------------------------------------------------------------

def preparer(chemin: str, recadrage: str = 'carre') -> np.ndarray:
    """L'image en `[1, 3, 224, 224]`, valeurs 0-1, sans normalisation.

    `carre` recadre au carré central puis réduit — ce que le teacher a vu, et
    ce que fait `prepare()` pour Iris. `etire` réduit directement à 224×224 en
    déformant, comme l'implémentation de référence de la carte du modèle.
    """
    from PIL import Image
    with Image.open(chemin) as im:
        im = im.convert('RGB')
        if recadrage == 'carre':
            cote = min(im.size)
            g = (im.width - cote) // 2
            h = (im.height - cote) // 2
            im = im.crop((g, h, g + cote, h + cote))
        im = im.resize((ENTREE, ENTREE), Image.BICUBIC)
        x = np.asarray(im, dtype=np.float32) / 255.0
    return x.transpose(2, 0, 1)[None, ...]


def signature_student(modele: str, recadrage: str, dim: int = DIM) -> dict:
    """La clé du cache du student.

    Elle porte le **recadrage** au même titre que le modèle : deux passes au
    même fichier et au recadrage différent rendent des vecteurs qui ne se
    comparent pas, et c'est exactement le genre d'écart qui ne se voit pas à
    l'usage (§ 20 bis de `docs/14`).
    """
    conf = {
        'teacher': f'student:{modele}',
        'dim': int(dim),
        'taille_entree': ENTREE,
        'recadrage': recadrage,
        'normalise': True,
    }
    conf['empreinte'] = empreinte(conf)
    return conf


# --------------------------------------------------------------------------
# Le banc
# --------------------------------------------------------------------------

def lire_banc(chemin: Path, tranches: set[str] | None = None) -> list[str]:
    """Les chemins d'images du manifeste, sans doublon, dans l'ordre du fichier."""
    vus, sortie = set(), []
    with open(chemin, newline='', encoding='utf-8') as f:
        for r in csv.DictReader(f):
            if tranches and r['tranche'] not in tranches:
                continue
            if r['chemin'] not in vus:
                vus.add(r['chemin'])
                sortie.append(r['chemin'])
    return sortie


def charger(modele: Path):  # pragma: no cover - demande onnxruntime
    try:
        import onnxruntime as ort
    except ImportError as e:
        raise SystemExit(f'{e}. pip install onnxruntime') from e
    session = ort.InferenceSession(str(modele), providers=['CPUExecutionProvider'])
    entree = session.get_inputs()[0]
    if tuple(entree.shape[1:]) != (3, ENTREE, ENTREE):
        raise SystemExit(
            f'entrée inattendue {entree.shape} : ce script prépare du NCHW '
            f'3×{ENTREE}×{ENTREE}. Un format changé ne planterait pas, il rendrait faux.')
    return session, entree.name, session.get_outputs()[0].name


def encoder(session, nom_entree: str, nom_sortie: str, chemins: list[str],
            recadrage: str) -> np.ndarray:  # pragma: no cover - demande onnxruntime
    """Les vecteurs de ces images, unitaires, dans l'ordre reçu.

    La sortie du modèle est annoncée **déjà unitaire**. On renormalise quand
    même : ça ne coûte rien, et si l'annonce était fausse le cache serait
    silencieusement incomparable à celui du teacher.
    """
    sortie = np.empty((len(chemins), DIM), dtype=np.float16)
    for i, chemin in enumerate(chemins):
        v = session.run([nom_sortie], {nom_entree: preparer(chemin, recadrage)})[0][0]
        n = np.linalg.norm(v)
        sortie[i] = (v / n if n else v).astype(np.float16)
    return sortie


def main() -> int:  # pragma: no cover - demande onnxruntime et les images
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--banc', default='benchmark.csv')
    ap.add_argument('--modele', default='~/plant-data/flora_student_fp32.onnx')
    ap.add_argument('--cache', default='~/plant-data/student')
    ap.add_argument('--tranches', default='indoor,outdoor,ood_plante')
    ap.add_argument('--recadrage', choices=['carre', 'etire'], default='carre',
                    help="« carre » recadre au carré central comme le teacher ; "
                         '« etire » déforme, comme la carte du modèle le montre')
    ap.add_argument('--fragment', type=int, default=4096)
    ap.add_argument('--combien', type=int, default=0, help='limiter ; 0 = toutes')
    ap.add_argument('--forcer', action='store_true')
    args = ap.parse_args()

    cache = Path(args.cache).expanduser()
    modele = Path(args.modele).expanduser()
    sig = signature_student(modele.name, args.recadrage)
    accorder_signature(cache, sig, args.forcer)

    tranches = {t.strip() for t in args.tranches.split(',') if t.strip()}
    chemins = lire_banc(Path(args.banc).expanduser(), tranches)
    if args.combien:
        chemins = chemins[:args.combien]
    afaire = [c for c in restant([(c, '', '') for c in chemins], lire_index(cache))]
    afaire = [c for c, _, _ in afaire]
    print(f'{len(chemins)} images du banc, {len(chemins) - len(afaire)} déjà cachées, '
          f'{len(afaire)} à faire — recadrage {args.recadrage}, signature {sig["empreinte"]}')
    if not afaire:
        return 0

    session, nom_entree, nom_sortie = charger(modele)
    index = open(cache / 'index-0.csv', 'a', newline='', encoding='utf-8')
    numero = len(list(cache.glob('emb-0-*.npy')))
    debut = time.perf_counter()
    try:
        for d in range(0, len(afaire), args.fragment):
            lot = afaire[d:d + args.fragment]
            vecteurs = encoder(session, nom_entree, nom_sortie, lot, args.recadrage)
            nom = f'emb-0-{numero:04d}'
            np.save(cache / f'{nom}.npy', vecteurs)
            w = csv.writer(index)
            for i, c in enumerate(lot):
                w.writerow([c, nom, i])
            index.flush()
            numero += 1
            fait = d + len(lot)
            e = extrapolation(fait, time.perf_counter() - debut, len(afaire))
            print(f'  {fait}/{len(afaire)}  {e["images_par_seconde"]:.1f} img/s', flush=True)
    finally:
        index.close()
    print(f'\n{cache} — à lire avec `voisins.py --embeddings {cache}`')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
