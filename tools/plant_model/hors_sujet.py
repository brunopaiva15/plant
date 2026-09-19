#!/usr/bin/env python3
"""Ce que le modèle répond quand on ne lui montre pas une plante.

    python3 hors_sujet.py ~/photos-hors-sujet --model ../../assets/model

Un classifieur dont toutes les sorties sont des plantes n'a aucun moyen de
dire « ceci n'est pas une plante » : il répartit sa masse entre les espèces
qu'il connaît, quoi qu'on lui montre. Devant un chat, il répond une plante —
la seule question est avec quelle assurance (§ 12.7 de `docs/09`).

Le seul garde-fou aujourd'hui est le plancher à 0,10 (`floor` dans
`identification_policy.dart`), la marge étant inactive au seuil de 0,70.
Cette mesure dit s'il suffit, et elle tranche entre trois chantiers de
tailles très différentes :

| ce qu'on observe          | ce que ça veut dire                             |
|---------------------------|-------------------------------------------------|
| presque tout sous 0,10    | le plancher travaille, la classe « autre » est   |
|                           | un chantier pour rien                            |
| beaucoup entre 0,10-0,70  | une liste « plausible » sur une photo de chat :  |
|                           | gênant, pas grave — un message suffirait         |
| des scores au-dessus      | le modèle **affirme** une espèce devant          |
| de 0,70                   | n'importe quoi. Là seulement elle se justifie    |

Trente photos suffisent : animaux, meubles, visages, murs, plats. Y mêler
des **plantes hors catalogue** vaut la peine — c'est le cas le plus fréquent
en vrai, et le plus difficile. Depuis Iris Indoor il l'est devenu bien
davantage : le modèle expose 336 espèces là où l'Iris 8 en exposait 1 444,
et les 1 252 qui sortent du masque ne disparaissent pas du monde.

`--parmi` range les photos par sous-dossier, s'il y en a : une photo de chat
et un ficus hors catalogue ne racontent pas la même histoire, et les mélanger
dans une seule moyenne les efface tous les deux.
"""
from __future__ import annotations

import argparse
from collections import defaultdict
from pathlib import Path

import numpy as np

from compare_models import load_model, predict
from identify import species_names

EXTENSIONS = {'.jpg', '.jpeg', '.png', '.webp'}
PLANCHER, SEUIL = 0.10, 0.70


def photos(racine: Path) -> list[Path]:
    if racine.is_file():
        return [racine]
    return sorted(p for p in racine.rglob('*') if p.suffix.lower() in EXTENSIONS)


def bande(score: float) -> str:
    if score < PLANCHER:
        return 'sous le plancher'
    if score < SEUIL:
        return 'plausible'
    return 'AFFIRMÉ'


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('dossier', help='un dossier de photos hors sujet, ou une photo')
    ap.add_argument('--model', default='../../assets/model')
    ap.add_argument('--parmi', action='store_true',
                    help='détailler par sous-dossier plutôt qu\'en un seul tas')
    ap.add_argument('--detail', type=int, default=10,
                    help='combien de photos lister, les plus affirmées d\'abord')
    args = ap.parse_args()

    dossier = Path(args.dossier).expanduser()
    fichiers = photos(dossier)
    if not fichiers:
        raise SystemExit(f'aucune image dans {dossier}')

    model = load_model(Path(args.model))
    noms = species_names(Path(args.model))
    print(f'{len(fichiers)} photos dans {model["name"]} '
          f'(version {model["version"]}, {len(model["labels"])} classes)\n')

    lignes = []
    for f in fichiers:
        probs = predict(model, str(f))
        ordre = np.argsort(-probs)[:2]
        top, second = float(probs[ordre[0]]), float(probs[ordre[1]])
        etiquette = model['labels'][ordre[0]]
        lignes.append({
            'photo': f,
            'groupe': f.parent.name if f.parent != dossier else '(racine)',
            'score': top,
            'marge': top - second,
            'espece': noms.get(etiquette, etiquette),
        })

    def tableau(titre: str, lot: list[dict]) -> None:
        compte = defaultdict(int)
        for l in lot:
            compte[bande(l['score'])] += 1
        scores = sorted(l['score'] for l in lot)
        median = scores[len(scores) // 2]
        print(f'— {titre} ({len(lot)} photos)')
        for nom in ('sous le plancher', 'plausible', 'AFFIRMÉ'):
            n = compte[nom]
            print(f'   {nom:18s} {n:3d}  {n / len(lot):5.1%}')
        print(f'   score médian       {median:.4f}   maximum {max(scores):.4f}\n')

    if args.parmi:
        groupes = defaultdict(list)
        for l in lignes:
            groupes[l['groupe']].append(l)
        for nom in sorted(groupes):
            tableau(nom, groupes[nom])
    tableau('toutes', lignes)

    # Les plus affirmées d'abord : ce sont elles qui décident, pas la moyenne.
    pires = sorted(lignes, key=lambda l: -l['score'])[:args.detail]
    print(f'les {len(pires)} plus affirmées')
    for l in pires:
        accepte = 'acceptée' if l['score'] >= SEUIL and l['marge'] >= 0.25 else ''
        print(f'   {l["score"]:.4f}  marge {l["marge"]:.4f}  {l["espece"]:34s} '
              f'{l["photo"].name}  {accepte}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
