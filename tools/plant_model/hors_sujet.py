#!/usr/bin/env python3
"""Ce que le modèle répond devant ce qui n'est pas une plante.

    python3 hors_sujet.py --modele ../../assets/model

Un classifieur dont **toutes** les sorties sont des plantes n'a aucun moyen
de dire « ceci n'est pas une plante » : il répartit sa masse entre les
espèces qu'il connaît, quoi qu'on lui montre. Devant un chat, il répond une
plante — la seule question est avec quelle assurance (§ 12.7).

Le § 3.2 prévoit une classe « autre » depuis la v1 et elle n'a jamais été
faite. Avant de la construire, le § 12.7 demande **une mesure** : une
trentaine de photos hors sujet dans le modèle livré, et l'on regarde la
distribution des meilleurs scores.

| ce qu'on observe | ce que ça veut dire |
|---|---|
| presque tout sous le plancher | le plancher fait déjà le travail, la classe « autre » est un chantier pour rien |
| beaucoup entre le plancher et le seuil | l'application affiche une liste « plausible » sur une photo de chat : gênant, pas grave — un message suffirait |
| des scores au-dessus du seuil | le modèle **affirme** une espèce devant n'importe quoi. Là seulement la classe « autre » se justifie |

Trente photos et dix minutes tranchent entre trois chantiers de tailles
très différentes.

**Les images viennent de Commons**, de catégories qui ne contiennent
manifestement pas de plantes. Des photos prises au téléphone chez soi
seraient plus fidèles au domaine de l'application — mais pour la question
posée ici, « le modèle affirme-t-il une espèce devant un mur », des images
bien cadrées et bien éclairées sont un test **plus sévère** : elles
donnent au réseau toutes ses chances d'être confiant. Un résultat rassurant
sur celles-ci l'est donc a fortiori sur une photo de salon.
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'plant_dataset'))

#: Catégories Commons sans plantes. Variées à dessein : un animal, du
#: mobilier, une surface nue, de la nourriture, un visage, un objet
#: technique — ce que l'appareil d'un utilisateur voit entre deux plantes.
CATEGORIES = ('Cats', 'Chairs', 'Brick walls', 'Pizza', 'Portrait photographs',
              'Bicycles', 'Coffee cups', 'Laptops', 'Staircases', 'Sneakers')


def recolter(dossier: Path, par_categorie: int, pause: float) -> int:
    from plant_dataset.fetchers.wikimedia import CommonsClient
    import requests
    client = CommonsClient(pause=pause)
    dossier.mkdir(parents=True, exist_ok=True)
    n = 0
    for cat in CATEGORIES:
        titres = [m.get('title', '') for m in client._members(cat, 'file', par_categorie)]
        for page in client._files_info([t for t in titres if t]):
            info = (page.get('imageinfo') or [{}])[0]
            url = info.get('thumburl')
            if not url:      # sans vignette on ne demande pas l'original (§ 12.6)
                continue
            try:
                r = requests.get(url, timeout=60, headers={'User-Agent': client.session.headers['User-Agent']})
                r.raise_for_status()
            except Exception:
                continue
            (dossier / f'{n:03d}.jpg').write_bytes(r.content)
            n += 1
    return n


def lire(modele, dossier: Path) -> list[tuple[str, float, float]]:
    """(nom, meilleure confiance, écart avec le second) pour chaque image."""
    from compare_models import predict
    out = []
    for image in sorted(dossier.glob('*.jpg')):
        probs = predict(modele, str(image))
        ordre = np.argsort(-probs)
        out.append((image.name, float(probs[ordre[0]]), float(probs[ordre[0]] - probs[ordre[1]])))
    return out


def verdict(scores: list[float], plancher: float, seuil: float) -> None:
    n = len(scores)
    sous = sum(1 for s in scores if s < plancher)
    entre = sum(1 for s in scores if plancher <= s < seuil)
    au_dessus = sum(1 for s in scores if s >= seuil)
    tri = sorted(scores)
    print(f'\n{n} images hors sujet\n')
    print(f'  confiance médiane {tri[n // 2]:.3f} — min {tri[0]:.3f}, max {tri[-1]:.3f}\n')
    print(f'  sous le plancher ({plancher})      : {sous:>3}  {sous / n:>5.0%}')
    print(f'  entre plancher et seuil ({seuil}) : {entre:>3}  {entre / n:>5.0%}')
    print(f'  au-dessus du seuil               : {au_dessus:>3}  {au_dessus / n:>5.0%}')
    print()
    if au_dessus:
        print(f'  → le modèle AFFIRME une espèce sur {au_dessus} image(s) sans plante.')
        print('    La classe « autre » se justifie (§ 12.7, troisième cas).')
    elif entre > n / 2:
        print('  → pas d\'affirmation, mais une liste « plausible » sur la majorité.')
        print('    Gênant, pas grave : un message suffirait (§ 12.7, deuxième cas).')
    else:
        print('  → le plancher fait déjà le travail.')
        print('    La classe « autre » est un chantier pour rien (§ 12.7, premier cas).')


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--modele', default='../../assets/model')
    ap.add_argument('--dossier', default='.cache/hors-sujet')
    ap.add_argument('--par-categorie', type=int, default=4)
    ap.add_argument('--pause', type=float, default=1.0)
    ap.add_argument('--plancher', type=float, default=0.10, help='le garde-fou actuel de la cascade')
    ap.add_argument('--seuil', type=float, default=0.70, help='au-delà, l\'application répond seule')
    ap.add_argument('--garder', action='store_true', help='ne pas re-télécharger si le dossier existe')
    args = ap.parse_args(argv)

    dossier = Path(args.dossier)
    if not (args.garder and any(dossier.glob('*.jpg'))):
        n = recolter(dossier, args.par_categorie, args.pause)
        print(f'{n} images récoltées dans {dossier}', file=sys.stderr)
    if not any(dossier.glob('*.jpg')):
        print(f'{dossier} est vide : rien à mesurer.', file=sys.stderr)
        return 1

    from compare_models import load_model
    modele = load_model(Path(args.modele))
    print(f'modèle v{modele["version"]} — {len(modele["labels"])} classes')
    lignes = lire(modele, dossier)
    for nom, conf, marge in sorted(lignes, key=lambda x: -x[1])[:10]:
        print(f'  {nom:<10} confiance {conf:.3f}   écart {marge:.3f}')
    if len(lignes) > 10:
        print(f'  … {len(lignes) - 10} autres')
    verdict([c for _, c, _ in lignes], args.plancher, args.seuil)
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
