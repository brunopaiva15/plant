#!/usr/bin/env python3
"""L'embedding sépare-t-il les cultivars, ou les a-t-on entraînés à l'effacer ?

    python3 prototypes.py --recolter --especes "Acer palmatum,Hosta,Rosa"
    python3 prototypes.py --mesurer --dossier .cache/cultivars

Le cultivar ne peut pas être une classe : les sources n'en ont pas assez
d'images (§ 12.16). Mais il n'a pas besoin d'en être une. L'architecture
retenue est à deux étages — le classifieur répond l'espèce, puis un
**prototype dans l'espace d'embedding** propose le cultivar, avec dix à
trente photos au lieu de deux cents. Conditionné à l'espèce, le
sous-problème est minuscule : quatre ou huit cultivars, pas cinq mille
classes.

Tout repose sur une hypothèse, et **elle est douteuse pour une raison
précise** : chaque photo de « Thai Constellation » de notre jeu est
étiquetée *Monstera deliciosa*. Le réglage fin — cent couches dégelées —
pousse donc explicitement l'embedding à **faire converger** le cultivar
panaché et la plante ordinaire vers le même point. C'est son travail.
Chercher les cultivars dans cette représentation, c'est les chercher dans
la seule qu'on ait entraînée à les confondre.

D'où cette mesure, avant d'écrire quoi que ce soit d'autre. Elle compare :

- la similarité **entre deux photos d'un même cultivar** ;
- et celle **entre deux cultivars de la même espèce** — la seule
  comparaison qui compte, séparer deux espèces étant déjà résolu.

Si l'écart est nul, l'embedding a bien effacé ce qu'on cherche, et il faut
partir d'un réseau ImageNet gelé ou d'une couche plus précoce (la panachure
est un signal de couleur, que les couches basses gardent mieux) avant
d'aller plus loin.
"""
from __future__ import annotations

import argparse
import sys
from collections import defaultdict
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'plant_dataset'))


def normaliser(v: np.ndarray) -> np.ndarray:
    """Vecteurs de norme 1 : la similarité cosinus devient un produit scalaire."""
    n = np.linalg.norm(v, axis=1, keepdims=True)
    return v / np.maximum(n, 1e-12)


def prototypes(vecteurs: np.ndarray, etiquettes: list[str]) -> dict[str, np.ndarray]:
    """Un vecteur moyen par cultivar — c'est tout ce que la base embarquée
    aurait à porter, et ce qui permet d'ajouter un cultivar sans rien
    réentraîner."""
    v = normaliser(np.asarray(vecteurs, dtype=np.float32))
    par: dict[str, list] = defaultdict(list)
    for i, e in enumerate(etiquettes):
        par[e].append(v[i])
    return {e: normaliser(np.mean(x, axis=0, keepdims=True))[0] for e, x in par.items()}


def separabilite(vecteurs: np.ndarray, etiquettes: list[str]) -> dict:
    """Deux photos d'un même cultivar sont-elles plus proches que deux
    cultivars de la même espèce ?

    Rend aussi la justesse d'un prototype **en laissant une photo de côté** :
    calculer le prototype sur toutes les photos puis classer ces mêmes
    photos donnerait un chiffre flatteur et faux.
    """
    v = normaliser(np.asarray(vecteurs, dtype=np.float32))
    n = len(etiquettes)
    intra, inter = [], []
    for i in range(n):
        for j in range(i + 1, n):
            (intra if etiquettes[i] == etiquettes[j] else inter).append(float(v[i] @ v[j]))

    justes = classables = 0
    for i in range(n):
        restants = [k for k in range(n) if k != i]
        protos = prototypes(v[restants], [etiquettes[k] for k in restants])
        if etiquettes[i] not in protos or len(protos) < 2:
            continue      # sans un autre exemplaire du cultivar, rien à retrouver
        classables += 1
        justes += max(protos, key=lambda e: float(v[i] @ protos[e])) == etiquettes[i]

    cultivars = sorted(set(etiquettes))
    return {
        'photos': n,
        'cultivars': len(cultivars),
        'intra': round(float(np.mean(intra)), 4) if intra else None,
        'inter': round(float(np.mean(inter)), 4) if inter else None,
        'ecart': round(float(np.mean(intra) - np.mean(inter)), 4) if intra and inter else None,
        'justesse_prototype': round(justes / classables, 4) if classables else None,
        'hasard': round(1 / len(cultivars), 4) if cultivars else None,
        'classables': classables,
    }


def temoin(vecteurs: np.ndarray, etiquettes: list[str], melanges: int = 200,
           graine: int = 20260910) -> dict:
    """Un test de permutation : l'écart observé sort-il de ce que le hasard
    produit sur ces mêmes photos ?

    **Sans ce témoin, l'expérience conclurait à tort.** Dix photos dans un
    espace à 960 dimensions se séparent presque toujours : sur du bruit pur,
    un prototype laissant une photo de côté atteint 0,9 de justesse. Ce
    n'est pas une propriété des cultivars, c'est une propriété des petits
    échantillons en grande dimension.

    Et comparer la valeur observée à la **moyenne** des mélanges ne suffit
    pas : une réalisation dépasse une moyenne une fois sur deux. Ce qu'il
    faut, c'est la part des mélanges qui font aussi bien — une valeur-p. En
    dessous de 0,05, la séparation n'est pas un accident de tirage.
    """
    reel = separabilite(vecteurs, etiquettes)
    rng = np.random.default_rng(graine)
    ecarts, justesses = [], []
    for _ in range(melanges):
        melange = list(etiquettes)
        rng.shuffle(melange)
        r = separabilite(vecteurs, melange)
        if r['ecart'] is not None:
            ecarts.append(r['ecart'])
        if r['justesse_prototype'] is not None:
            justesses.append(r['justesse_prototype'])

    def valeur_p(observe, tirages):
        if observe is None or not tirages:
            return None
        # +1 au numérateur et au dénominateur : la valeur observée est
        # elle-même une permutation, et une valeur-p nulle n'existe pas.
        return round((1 + sum(1 for t in tirages if t >= observe)) / (1 + len(tirages)), 4)

    return {
        'ecart_moyen': round(float(np.mean(ecarts)), 4) if ecarts else None,
        'justesse_moyenne': round(float(np.mean(justesses)), 4) if justesses else None,
        'p_ecart': valeur_p(reel['ecart'], ecarts),
        'p_prototype': valeur_p(reel['justesse_prototype'], justesses),
        'melanges': melanges,
    }


def _recolter(especes: list[str], dossier: Path, par_cultivar: int, pause: float) -> None:
    """Les photos de cultivars que Commons a vraiment, rangées par espèce.

    Commons ne nomme pas les catégories d'après le cultivar mais d'après
    l'espèce : `Acer palmatum (cultivars)`, avec une sous-catégorie par
    cultivar nommé. Chercher `Acer palmatum 'Bloodgood'` rend zéro — c'est
    l'erreur de méthode qui a failli faire conclure trop vite (§ 12.16).
    """
    import requests
    from plant_dataset.fetchers.wikimedia import CommonsClient
    client = CommonsClient(pause=pause)
    for espece in especes:
        racine = f'{espece} (cultivars)'
        sous = [c['title'].split(':', 1)[-1] for c in client._members(racine, 'subcat', 100)]
        print(f'{espece} : {len(sous)} cultivars nommés', flush=True)
        for cat in sous:
            nom = cat.split("'")[1] if "'" in cat else cat.replace(espece, '').strip()
            cible = dossier / espece.replace(' ', '-') / (nom or cat).replace(' ', '-')
            cible.mkdir(parents=True, exist_ok=True)
            gardees = 0
            for cand in client.image_candidates(cat, max_files=par_cultivar, allow_share_alike=True):
                fichier = cible / f'{gardees:03d}.jpg'
                try:
                    r = requests.get(cand.image_url, timeout=60,
                                     headers={'User-Agent': 'FloraPlantDataset/0.1 (github.com/brunopaiva15/plant)'})
                    r.raise_for_status()
                    fichier.write_bytes(r.content)
                    gardees += 1
                except Exception as e:
                    print(f'    {cand.image_url} : ÉCHEC ({type(e).__name__})', file=sys.stderr)
            print(f'   {nom:28s} {gardees} photos', flush=True)


def _lire(dossier: Path) -> list[tuple[Path, str, str]]:
    """(chemin, espèce, cultivar) pour tout ce qui a été récolté."""
    out = []
    for espece in sorted(p for p in dossier.iterdir() if p.is_dir()):
        for cultivar in sorted(p for p in espece.iterdir() if p.is_dir()):
            for image in sorted(cultivar.glob('*.jpg')):
                out.append((image, espece.name, cultivar.name))
    return out


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--recolter', action='store_true', help='télécharger les photos de cultivars de Commons')
    ap.add_argument('--mesurer', action='store_true', help='embarquer et mesurer la séparabilité')
    ap.add_argument('--especes', default='Acer palmatum,Hosta,Rosa,Camellia japonica,Hydrangea macrophylla',
                    help='les genres riches en cultivars, où Commons a de quoi mesurer')
    ap.add_argument('--dossier', default='.cache/cultivars')
    ap.add_argument('--par-cultivar', type=int, default=40)
    ap.add_argument('--pause', type=float, default=1.0)
    ap.add_argument('--backbone', default='large')
    ap.add_argument('--poids', help='poids fine-tunés à comparer au réseau ImageNet gelé')
    ap.add_argument('--melanges', type=int, default=200,
                    help='permutations du témoin ; sans lui, dix photos en 960 dimensions\n'
                         'se séparent toujours')
    ap.add_argument('--minimum', type=int, default=3, help='photos minimales pour qu\'un cultivar compte')
    args = ap.parse_args(argv)

    dossier = Path(args.dossier)
    if args.recolter:
        _recolter([e.strip() for e in args.especes.split(',') if e.strip()],
                  dossier, args.par_cultivar, args.pause)
    if not args.mesurer:
        return 0

    lignes = _lire(dossier)
    if not lignes:
        print(f'{dossier} est vide : lancer d\'abord --recolter', file=sys.stderr)
        return 1

    # Importés ici : les fonctions pures ci-dessus se testent sans TensorFlow.
    import tensorflow as tf
    from train import IMAGE_SIZE, frozen_backbone

    modele = frozen_backbone(args.backbone)
    if args.poids:
        modele.load_weights(args.poids, skip_mismatch=True, by_name=True)
        print(f'poids chargés depuis {args.poids}')

    vecteurs = []
    for chemin, _, _ in lignes:
        img = tf.io.decode_jpeg(tf.io.read_file(str(chemin)), channels=3)
        cote = tf.reduce_min(tf.shape(img)[:2])
        img = tf.image.resize_with_crop_or_pad(img, cote, cote)
        img = tf.image.resize(img, [IMAGE_SIZE, IMAGE_SIZE])
        vecteurs.append(modele(tf.cast(img, tf.float32)[None, ...], training=False).numpy()[0])
    vecteurs = np.stack(vecteurs)

    print(f'\n{len(lignes)} photos embarquées en {vecteurs.shape[1]} dimensions\n')
    for espece in sorted({e for _, e, _ in lignes}):
        idx = [i for i, (_, e, _) in enumerate(lignes) if e == espece]
        etiquettes = [lignes[i][2] for i in idx]
        assez = {c for c in set(etiquettes) if etiquettes.count(c) >= args.minimum}
        idx = [i for i in idx if lignes[i][2] in assez]
        if len({lignes[i][2] for i in idx}) < 2:
            print(f'{espece} : moins de deux cultivars avec {args.minimum} photos — non mesurable')
            continue
        etiq = [lignes[i][2] for i in idx]
        r = separabilite(vecteurs[idx], etiq)
        t = temoin(vecteurs[idx], etiq, args.melanges)
        print(f"{espece} — {r['photos']} photos, {r['cultivars']} cultivars")
        print(f"   même cultivar        : {r['intra']}")
        print(f"   cultivars différents : {r['inter']}")
        print(f"   écart : {r['ecart']}   (mélangé : {t['ecart_moyen']}, p = {t['p_ecart']})")
        print(f"   prototype : {r['justesse_prototype']}   (mélangé : {t['justesse_moyenne']}, "
              f"p = {t['p_prototype']}, hasard {r['hasard']})")
        significatif = (t['p_prototype'] is not None and t['p_prototype'] < 0.05)
        verdict = ("le cultivar est dans l'embedding" if significatif
                   else "RIEN À VOIR : le hasard fait aussi bien sur ces mêmes photos")
        print(f'   → {verdict}\n')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
