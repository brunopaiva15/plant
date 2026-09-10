#!/usr/bin/env python3
"""Ce que le modèle rend à qui photographie une plante d'appartement.

    python3 interieur.py --couverture                    # sans TensorFlow
    python3 interieur.py --dataset ../plant_dataset/dataset \\
        --model ../../assets/model --sample 4000

Le top-1 publié — 0,5961 pour l'Iris 7 — est une moyenne sur 1 457 espèces
dont la plupart sont sauvages, européennes, et que personne ne photographie
dans son salon. L'application, elle, sert d'abord les 167 noms de
`phase1_species.txt` : ce sont les plantes qu'on achète en jardinerie et
qu'on pose sur une étagère.

Deux chiffres répondent, et il faut les deux :

- **la couverture** : combien de ces plantes le modèle sait seulement
  nommer. Une espèce absente du catalogue est un échec certain pour
  l'utilisateur, et elle est *invisible* dans toute mesure de précision —
  on ne se trompe pas sur une classe qui n'existe pas, on ne la propose
  jamais. Cette partie ne demande ni TensorFlow ni le jeu d'images ;
- **la précision sur ce qui est couvert** : le top-1 sur les seules images
  de test de ces espèces, mesuré sur le `.tflite` livré.

Et, pour la précision, deux lectures qui se répondent :

- **catalogue entier** : les 1 457 sorties restent ouvertes. C'est ce que
  vit l'utilisateur aujourd'hui ;
- **catalogue restreint** : les sorties sont masquées aux seules plantes
  d'intérieur. C'est ce que rendrait un modèle qui n'aurait appris qu'elles.

L'écart entre les deux est le **prix de l'étendue** : ce que les 1 306
autres espèces coûtent à celui qui n'en photographiera jamais aucune. C'est
la question que pose le § 12.11 avant de viser 3 000 espèces, et jusqu'ici
personne ne l'avait chiffrée.
"""
from __future__ import annotations

import argparse
import csv
import random
import sys
from collections import Counter
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'plant_dataset'))

#: Le seuil d'acceptation de l'application (`FallbackPolicy`), § 6.7.
SEUIL = 0.70


def _id(nom: str) -> str:
    """Nom scientifique → identifiant interne, sans dépendre du collecteur.

    `plant_dataset.taxonomy.internal_id` fait autorité et sert quand il est
    importable ; cette copie de secours suffit pour les noms d'une liste
    d'espèces, qui sont déjà propres. Les deux doivent rendre la même clé,
    sinon la couverture serait mesurée contre un autre catalogue que celui
    du modèle.
    """
    try:
        from plant_dataset.taxonomy import internal_id
        return internal_id(nom)
    except Exception:
        propre = ' '.join(nom.replace('×', 'x').replace('.', ' ').split())
        return propre.lower().replace(' ', '-')


def alias_depuis(lignes) -> dict[str, str]:
    """identifiant d'un synonyme → identifiant retenu par le catalogue.

    `plants.csv` porte une colonne `synonyms` : c'est elle qui rattache
    *Streptocarpus ionanthus* à `saintpaulia-ionantha`. Sans ça, une espèce
    présente sous son autre nom serait comptée absente — l'erreur exacte que
    le § 6.5 a déjà coûtée à la collecte.
    """
    alias: dict[str, str] = {}
    for r in lignes:
        retenu = r['internal_id']
        alias.setdefault(retenu, retenu)
        for s in (r.get('synonyms') or '').replace(';', ',').split(','):
            if s.strip():
                alias.setdefault(_id(s.strip()), retenu)
        alias.setdefault(_id(r['scientific_name']), retenu)
    return alias


def resoudre(noms: list[str], labels: set[str], alias: dict[str, str] | None = None) -> dict:
    """Range les noms visés selon que le modèle sait ou non les nommer.

    Trois façons d'être une classe, et il faut les trois, sinon on annonce
    absentes des plantes que le modèle connaît :

    - **directe** : l'identifiant est une étiquette ;
    - **par synonyme** : `plants.csv` rattache l'ancien nom au nouveau ;
    - **par l'hybride** : le catalogue écrit `citrus-x-limon` là où la liste
      écrit « Citrus limon ». Le × est une information taxonomique, pas une
      autre plante ; le laisser tomber ferait passer le citronnier pour une
      espèce manquante.

    Deux noms peuvent désigner la même plante — *Calathea orbifolia* et
    *Goeppertia orbifolia* sont dans la liste toutes les deux. On les compte
    une fois, y compris quand aucune des deux n'est une classe : sans quoi
    la couverture serait mesurée sur un dénominateur gonflé.
    """
    alias = alias or {}
    canon: dict[str, str] = {}          # nom visé → la plante qu'il désigne
    par_nom: dict[str, str] = {}        # nom visé → la classe du modèle
    synonymes: dict[str, str] = {}
    hybrides: dict[str, str] = {}
    for nom in noms:
        i = _id(nom)
        j = alias.get(i, i)
        genre, _, epithete = i.partition('-')
        h = f'{genre}-x-{epithete}' if epithete else ''
        if i in labels:
            par_nom[nom] = i
        elif j in labels:
            par_nom[nom] = synonymes[nom] = j
        elif h in labels:
            par_nom[nom] = hybrides[nom] = h
        canon[nom] = par_nom.get(nom, j)
    compte = Counter(canon.values())
    classes = sorted(set(par_nom.values()))
    distinctes = len(compte)
    return {
        'demandes': len(noms),
        'distinctes': distinctes,
        'classes': classes,
        'couverture': round(len(classes) / distinctes, 4) if distinctes else 0.0,
        'par_nom': par_nom,
        'synonymes': synonymes,
        'hybrides': hybrides,
        'absentes': [n for n in noms if n not in par_nom],
        'doublons': sorted(i for i, n in compte.items() if n > 1),
    }


def prix_de_letendue(entier: dict, restreint: dict) -> dict | None:
    """L'écart entre les deux lectures, en points de top-1.

    Positif : les 1 306 autres espèces coûtent quelque chose à celui qui
    photographie son salon. Nul ou négatif : l'étendue est gratuite, et le
    § 12.11 peut viser 3 000 espèces sans rien reprendre.
    """
    if entier.get('top1') is None or restreint.get('top1') is None:
        return None
    return {
        'top1': round(restreint['top1'] - entier['top1'], 4),
        'top3': round((restreint.get('top3') or 0) - (entier.get('top3') or 0), 4),
        'acceptees': round((restreint.get('accepted_rate') or 0) - (entier.get('accepted_rate') or 0), 4),
    }


def _lire_noms(chemin: Path) -> list[str]:
    return [l.strip() for l in chemin.read_text(encoding='utf-8').splitlines() if l.strip()]


def _couverture(r: dict, lisibles: dict[str, str], detail: int) -> None:
    print(f"{r['demandes']} noms visés, {r['distinctes']} plantes distinctes, "
          f"{len(r['classes'])} que le modèle sait nommer — **{r['couverture']:.0%} de couverture**\n")
    for nom, i in r['synonymes'].items():
        print(f'  {nom} est au catalogue sous {i}')
    for nom, i in r['hybrides'].items():
        print(f'  {nom} est au catalogue sous {i} — le × que la liste ne met pas')
    if r['doublons']:
        noms = ', '.join(lisibles.get(i, i) for i in r['doublons'])
        print(f"  {len(r['doublons'])} plantes nommées deux fois dans la liste : {noms}")
    if r['absentes']:
        print(f"\n**{len(r['absentes'])} noms d'intérieur que le modèle ne peut pas rendre.**")
        print("Pour ceux-là aucune précision ne se mesure : la classe n'existe pas, elle")
        print('ne sera jamais proposée, et la réponse est fausse à coup sûr.')
        for nom in r['absentes'][:detail]:
            print(f'  {nom}')
        if len(r['absentes']) > detail:
            print(f"  … et {len(r['absentes']) - detail} autres")


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--model', default='../../assets/model', help='le modèle livré, celui qui tourne dans l\'app')
    ap.add_argument('--species-file', default='../plant_dataset/phase1_species.txt')
    ap.add_argument('--plants', default='../plant_dataset/plants.csv', help='pour les synonymes')
    ap.add_argument('--dataset', default='../plant_dataset/dataset')
    ap.add_argument('--couverture', action='store_true',
                    help='ne mesurer que la couverture : ni TensorFlow ni images')
    ap.add_argument('--sample', type=int, default=4000, help='images de test tirées au hasard, 0 = toutes')
    ap.add_argument('--seed', type=int, default=20260909)
    ap.add_argument('--detail', type=int, default=20)
    args = ap.parse_args(argv)

    modele_dir = Path(args.model)
    labels = {l.strip() for l in (modele_dir / 'labels.txt').read_text(encoding='utf-8').splitlines() if l.strip()}
    noms = _lire_noms(Path(args.species_file))
    plants = Path(args.plants)
    lignes = list(csv.DictReader(plants.open(encoding='utf-8'))) if plants.exists() else []
    lisibles = {r['internal_id']: r['scientific_name'] for r in lignes}
    r = resoudre(noms, labels, alias_depuis(lignes))
    print(f"modèle : {len(labels)} classes\n")
    _couverture(r, lisibles, args.detail)
    if args.couverture:
        return 0

    # Importé ici : la couverture ci-dessus doit pouvoir se lire sur
    # n'importe quelle machine, y compris sans TensorFlow ni jeu d'images.
    try:
        from compare_models import load_model, read_test, score
    except ImportError as e:
        print(f"\nla suite demande TensorFlow ({e}) : `pip install -r requirements.txt`,"
              "\nou `--couverture` pour s'en tenir à ce qui précède.", file=sys.stderr)
        return 1
    dataset = Path(args.dataset)
    if not (dataset / 'splits.csv').exists():
        print(f'\n{dataset}/splits.csv est introuvable : la suite demande le jeu d\'images.', file=sys.stderr)
        return 1

    interieur = set(r['classes'])
    modele = load_model(modele_dir)
    toutes = read_test(dataset)
    dedans = [(p, t) for p, t, _ in toutes if t in interieur]
    cultivees = [(p, t) for p, t, cap in toutes if t in interieur and cap]
    rng = random.Random(args.seed)

    def tirer(items, n):
        return rng.sample(items, n) if n and len(items) > n else items

    especes_vues = len({t for _, t in dedans})
    print(f"\n{len(dedans)} images de test sur ces plantes, {especes_vues} espèces représentées")
    if not dedans:
        print("aucune : le jeu de test ne contient aucune de ces espèces.")
        return 0

    lot = tirer(dedans, args.sample)
    print(f'\n— plantes d\'appartement ({len(lot)} images)')
    entier = score(lot, modele, None)
    # Renormalisé : un modèle qui n'aurait appris que ces classes répartirait
    # entre elles la masse que celui-ci donne aux 1 306 autres. Le top-1 ne
    # bouge pas — masquer préserve l'ordre —, seules les colonnes de seuil
    # sont concernées, et sans ça on lirait une autonomie en baisse alors
    # qu'elle monterait.
    restreint = score(lot, modele, interieur, renormalise=True)
    for titre, res in (('catalogue entier   ', entier), ('catalogue restreint', restreint)):
        print(f"   {titre} : top1 {res['top1']}  top3 {res['top3']}  "
              f"seuil {SEUIL} → {res['accepted_rate']} acceptées, précision {res['precision_when_accepted']}")
    ecart = prix_de_letendue(entier, restreint)
    if ecart:
        print(f"   → le prix de l'étendue : {ecart['top1']:+.4f} de top-1, {ecart['acceptees']:+.4f} d'autonomie")

    if cultivees:
        lot = tirer(cultivees, max(1, args.sample // 2))
        res = score(lot, modele, None)
        print(f"\n— les mêmes, photographiées en pot ({len(lot)} images) — au plus près de l'application")
        print(f"   top1 {res['top1']}  top3 {res['top3']}  "
              f"seuil {SEUIL} → {res['accepted_rate']} acceptées, précision {res['precision_when_accepted']}")

    reste = tirer([(p, t) for p, t, _ in toutes if t not in interieur], args.sample)
    if reste:
        res = score(reste, modele, None)
        print(f'\n— pour comparaison, tout le reste du catalogue ({len(reste)} images)')
        print(f"   top1 {res['top1']}  top3 {res['top3']}")
        print("   (mesuré sur le `.tflite` livré, pas sur le réseau Keras : c'est ce que\n"
              "    l'utilisateur exécute, et `model.json` ne l'avait jamais vérifié)")
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
