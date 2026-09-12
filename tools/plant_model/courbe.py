#!/usr/bin/env python3
"""Ce que chaque espèce exposée coûte aux autres.

    python3 courbe.py --modele /data2/model-v8 --dataset /data2/dataset-v8 \\
        --coeur ../../assets/model/labels.txt \\
        --ordre ../plant_dataset/candidats_v8.txt \\
        --tailles 1444,1800,2200,3000,4000,5259

Le § 6.7 bis ne connaît que les deux bouts : l'Iris 8 rend 0,6543 sur les
espèces du cœur quand il n'expose qu'elles, et 0,5528 quand il en expose
5 259. Dix points, mais on ignore la **forme** entre les deux — le coude
peut être à 1 600 comme à 4 000, et c'est lui qui dit combien d'espèces on
peut se permettre.

**Une seule passe d'inférence suffit pour toute la courbe.** Masquer un
softmax aux classes gardées puis le renormaliser donne exactement ce que
rendrait un modèle retaillé à ces classes (`retailler.py`) : `exp(zᵢ) / Σ
gardées`. On calcule donc les 5 259 probabilités une fois par image, et
chaque taille d'ensemble n'est plus qu'une addition. Ce qui coûtait une
heure par point en coûte quelques secondes.

Deux colonnes, et il faut les deux :

- **le coût** — top-1 sur les images des espèces du cœur, les mêmes à
  chaque taille. C'est ce que l'utilisateur actuel perd quand on élargit ;
- **le gain** — top-1 sur les images des espèces ajoutées, que l'ensemble
  précédent ne pouvait pas nommer du tout.

Et deux tables : toutes les photos, puis les seules photos de plantes
**cultivées** (`captive`, § 5). Le § 6.7 bis a mesuré le coût de l'étendue
à 10,2 points en général et **11,1 sur les plantes en pot** — le domaine
réel de l'application. Le coude peut être plus tôt là qu'ailleurs, et c'est
là qu'il faut le lire.

Les ensembles sont **emboîtés** : chaque taille contient la précédente. Sans
ça, deux points de la courbe ne se compareraient pas.

**`--par-vol` : ajouter par coût, pas par priorité.** La première courbe a
montré que le coût de l'étendue n'est pas une fonction de *combien*
d'espèces on ajoute mais de *lesquelles* : une espèce qui ne passe jamais
devant la bonne réponse sur une image du cœur est gratuite, une espèce qui
lui ressemble coûte à chaque photo. Pour chaque candidate, on compte donc
les images du cœur qu'elle ferait basculer de juste à fausse si elle était
exposée — son **coût de vol** — et on ajoute par coût croissant, la priorité
de culture ne départageant que les ex æquo.

La sélection se fait sur le split de **validation** et la mesure sur le
**test** : choisir et mesurer sur les mêmes images flatterait le résultat.
Une taille de plus est ajoutée d'office à la courbe : le cœur plus toutes
les espèces qui ne volent rien en validation.
"""
from __future__ import annotations

import argparse
import random
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'plant_dataset'))


def ensembles(coeur: list[str], ordre: list[str], toutes: list[str],
              tailles: list[int]) -> dict[int, list[str]]:
    """Un ensemble exposé par taille demandée, emboîtés du plus petit au plus
    grand.

    Le cœur d'abord — les espèces déjà servies, qu'on ne retire jamais —
    puis les suivantes dans l'ordre de priorité fourni, puis, si la taille
    l'exige encore, le reste dans l'ordre du modèle. Une taille plus petite
    que le cœur est ramenée au cœur : le but est de mesurer ce qu'on ajoute,
    pas d'amputer ce qui marche.
    """
    connues = set(toutes)
    socle = [c for c in toutes if c in set(coeur) & connues]
    vus = set(socle)
    suite = [c for c in ordre if c in connues and c not in vus]
    vus.update(suite)
    suite += [c for c in toutes if c not in vus]

    sortie = {}
    for n in sorted(set(tailles)):
        garde = max(n - len(socle), 0)
        sortie[max(n, len(socle))] = socle + suite[:garde]
    return sortie


def couts_de_vol(P: np.ndarray, verite: np.ndarray, coeur: np.ndarray,
                 candidats: np.ndarray) -> tuple[np.ndarray, int]:
    """Pour chaque candidate, le nombre d'images du cœur qu'elle ferait
    basculer de juste à fausse si elle était exposée à côté du cœur.

    Seules comptent les images que le cœur seul reconnaît : une image déjà
    fausse ne peut pas le devenir davantage, et une candidate n'est jamais
    la vérité d'une image du cœur. Sur une image juste, le meilleur score du
    cœur *est* celui de la vérité ; la candidate vole si elle le dépasse.

    `P` : une ligne par image, une colonne par classe du modèle. `verite`,
    `coeur`, `candidats` : des indices de colonnes. Rend aussi le nombre
    d'images justes, pour lire les coûts en proportion.
    """
    argmax_coeur = coeur[np.argmax(P[:, coeur], axis=1)]
    juste = argmax_coeur == verite
    seuil = P[np.arange(len(P)), verite][juste]
    return (P[juste][:, candidats] > seuil[:, None]).sum(axis=0), int(juste.sum())


def ordre_par_vol(couts: dict[str, int], priorite: list[str]) -> list[str]:
    """Les candidates par coût croissant ; à coût égal, la priorité de
    culture, puis l'identifiant pour que deux exécutions se ressemblent."""
    rang = {c: i for i, c in enumerate(priorite)}
    return sorted(couts, key=lambda c: (couts[c], rang.get(c, len(rang)), c))


def lire_ordre(chemin: Path | None) -> list[str]:
    """Les identifiants internes, dans l'ordre de priorité du fichier.

    `candidats_v8.txt` porte des noms scientifiques, rangés par ce que les
    gens cultivent (§ 12.11) : c'est l'ordre dans lequel on veut ajouter des
    espèces, pas l'ordre alphabétique du modèle.
    """
    if chemin is None:
        return []
    from plant_dataset.taxonomy import internal_id
    noms = [l.strip() for l in chemin.read_text(encoding='utf-8').splitlines() if l.strip()]
    return [internal_id(n) for n in noms]


def main() -> int:
    from compare_models import load_model, predict_rows, read_rows, read_test, tally

    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--modele', required=True, help='le modèle large, celui qui a tout appris')
    ap.add_argument('--dataset', required=True)
    ap.add_argument('--coeur', default='../../assets/model/labels.txt',
                    help='les espèces déjà servies, jamais retirées')
    ap.add_argument('--ordre', help='ordre de priorité des ajouts (noms scientifiques)')
    ap.add_argument('--tailles', default='1444,1800,2200,2800,3600,5259')
    ap.add_argument('--sample', type=int, default=6000,
                    help='images de test du cœur ; les autres espèces en reçoivent la moitié')
    ap.add_argument('--seed', type=int, default=20260905)
    ap.add_argument('--seuil', type=float, default=0.70)
    ap.add_argument('--par-vol', action='store_true',
                    help='ordonner les ajouts par coût de vol mesuré en validation, '
                         'la priorité de culture ne départageant que les ex æquo')
    ap.add_argument('--val-sample', type=int, default=12000,
                    help='images du cœur en validation pour mesurer les coûts ; 0 = toutes')
    args = ap.parse_args()

    modele = load_model(Path(args.modele))
    toutes = modele['labels']
    coeur = Path(args.coeur).read_text(encoding='utf-8').split()
    socle = set(coeur) & set(toutes)
    priorite = lire_ordre(Path(args.ordre) if args.ordre else None)
    tailles = [int(x) for x in args.tailles.split(',')]

    if args.par_vol:
        # Un générateur à part : le tirage du test doit rester le premier
        # appel sur `Random(args.seed)`, sinon le garde-fou du § 6.7 bis tombe.
        val = [(p, t) for p, t, _ in read_rows(Path(args.dataset), 'val') if t in socle]
        if args.val_sample and len(val) > args.val_sample:
            val = random.Random(args.seed + 1).sample(val, args.val_sample)
        print(f'coûts de vol : {len(val)} images du cœur en validation…', flush=True)
        pv = predict_rows(val, modele)
        P = np.stack([p for _, p in pv])
        verite = np.array([modele['index'][t] for t, _ in pv])
        idx_coeur = np.array(sorted(modele['index'][c] for c in socle))
        cand_ids = [c for c in toutes if c not in socle]
        vols, justes = couts_de_vol(P, verite, idx_coeur,
                                    np.array([modele['index'][c] for c in cand_ids]))
        couts = dict(zip(cand_ids, (int(v) for v in vols)))
        priorite = ordre_par_vol(couts, priorite)
        paliers = [(0, 'ne volent rien'), (2, 'en volent ≤ 2'), (5, '≤ 5'), (20, '≤ 20')]
        print(f'  {justes} images justes avec le cœur seul ; sur {len(couts)} candidates, '
              + ', '.join(f'{sum(1 for v in couts.values() if v <= n)} {mot}' for n, mot in paliers)
              + f', {sum(1 for v in couts.values() if v > 20)} plus de 20')
        gratuites = sum(1 for v in couts.values() if v == 0)
        tailles.append(len(socle) + gratuites)
        print(f'  → taille ajoutée à la courbe : {len(socle) + gratuites} '
              f'(le cœur plus les {gratuites} gratuites)\n')

    jeux = ensembles(coeur, priorite, toutes, tailles)
    rows = [(p, t, c) for p, t, c in read_test(Path(args.dataset)) if t in modele['index']]

    # Le tirage du cœur reproduit celui de `compare_models.py` — même graine,
    # même filtre, même premier appel — donc **les mêmes images**. La ligne du
    # cœur seul doit alors retomber au millième sur le chiffre du § 6.7 bis :
    # un garde-fou gratuit, et le seul moyen de savoir que le reste de la
    # courbe est lisible.
    rng = random.Random(args.seed)
    au_coeur = [r for r in rows if r[1] in socle]
    ailleurs = [r for r in rows if r[1] not in socle]
    if args.sample:
        if len(au_coeur) > args.sample:
            au_coeur = rng.sample(au_coeur, args.sample)
        if len(ailleurs) > args.sample // 2:
            ailleurs = rng.sample(ailleurs, args.sample // 2)
    rows = au_coeur + ailleurs
    print(f"{len(toutes)} classes apprises, {len(socle)} au cœur\n"
          f"{len(au_coeur)} images du cœur, {len(ailleurs)} des autres espèces\n")

    print('inférence, une fois pour toutes…', flush=True)
    pred = predict_rows([(p, t) for p, t, _ in rows], modele)
    # `predict_rows` ne filtre que les vérités inconnues du modèle, déjà
    # écartées plus haut : les drapeaux restent alignés sur les sorties.
    assert len(pred) == len(rows)
    en_pot = [c for _, _, c in rows]

    def cellule(valeur) -> str:
        return '—' if valeur is None else f'{valeur:.4f}'

    def table(titre: str, sorties: list) -> None:
        pred_coeur = [(t, p) for t, p in sorties if t in socle]
        print(f"\n— {titre} : {len(pred_coeur)} images du cœur, "
              f"{len(sorties) - len(pred_coeur)} des autres espèces")
        print(f"{'exposées':>9}  {'cœur : top1':>12} {'top3':>7} {'autonomie':>10} {'justesse':>9}"
              f"   {'ajoutées : top1':>16} {'images':>7}")
        for n in sorted(jeux):
            garde = set(jeux[n])
            pred_ajoutees = [(t, p) for t, p in sorties if t in garde and t not in socle]
            c = tally(pred_coeur, modele, garde, renormalise=True, seuil=args.seuil)
            a = (tally(pred_ajoutees, modele, garde, renormalise=True, seuil=args.seuil)
                 if pred_ajoutees else {})
            print(f'{n:>9}  {cellule(c["top1"]):>12} {cellule(c["top3"]):>7} '
                  f'{cellule(c["accepted_rate"]):>10} {cellule(c["precision_when_accepted"]):>9}   '
                  f'{cellule(a.get("top1")):>16} {a.get("images", 0):>7}')

    table('toutes les photos', pred)
    table("photos de plantes cultivées — le domaine de l'application",
          [tp for tp, c in zip(pred, en_pot) if c])
    print(f'\ncœur : {len(socle)} espèces, les mêmes à chaque ligne. '
          'La ligne du cœur seul, première table, doit retomber sur le § 6.7 bis.')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
