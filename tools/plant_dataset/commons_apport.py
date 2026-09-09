#!/usr/bin/env python3
"""Ce que Wikimedia Commons ajouterait, espèce par espèce, avant de collecter.

    python3 commons_apport.py --limit 30
    python3 commons_apport.py --species-file phase1_species.txt --dataset dataset

Le connecteur existe depuis le 8 septembre (§ 4.4) : 97 % de licences
utilisables contre 18 % chez GBIF, et surtout des plantes photographiées
**chez des gens**. Il n'a jamais servi à une collecte complète, et le § 12.2
demande de mesurer ce qu'il apporte *avant* de le mettre dans la recette.

C'est le même principe qu'au § 4.5, où dix minutes de mesure ont évité
d'écrire un connecteur Smithsonian pour sept photos : **une source ne vaut
pas par sa taille mais par son recouvrement avec le catalogue.**

L'outil ne télécharge aucune image. Il compte, par espèce, les fichiers que
le connecteur retiendrait — photographies, licence acceptée — et les met en
regard de ce que le jeu possède déjà. Une espèce qui a 200 images et à qui
Commons en offre 12 ne justifie pas une passe ; une espèce à 30 images à qui
il en offre 150 la justifie à elle seule.
"""
from __future__ import annotations

import argparse
import csv
import statistics
import sys
from collections import Counter
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))


def resume(offert: dict[str, int], deja: dict[str, int] | None = None,
           seuil_maigre: int = 100) -> dict:
    """Le rapport, à partir des décomptes — sans réseau, donc testable.

    `offert` : espèce → fichiers que Commons retiendrait.
    `deja`   : espèce → images déjà dans le jeu, quand il est là.

    Trois populations valent d'être distinguées, parce qu'elles appellent
    trois décisions différentes : celles que Commons ignore (rien à faire),
    celles qu'il connaît à peine (ne justifient pas la passe à elles seules),
    et celles qu'il pourrait plus que doubler — ce sont elles qu'on cherche.
    """
    deja = deja or {}
    inconnues = sorted(e for e, n in offert.items() if n == 0)
    connues = {e: n for e, n in offert.items() if n > 0}
    valeurs = sorted(connues.values())
    doublees = sorted((e for e, n in connues.items() if deja.get(e) and n >= deja[e]),
                      key=lambda e: -connues[e])
    return {
        'especes': len(offert),
        'inconnues': inconnues,
        'connues': len(connues),
        'total': sum(valeurs),
        'mediane': statistics.median(valeurs) if valeurs else 0,
        'maigres': sorted(e for e, n in connues.items() if n < seuil_maigre),
        'doublees': doublees,
        'offert': offert,
        'deja': deja,
    }


def images_du_jeu(dataset: Path) -> dict[str, int]:
    """Ce que le jeu possède déjà, par nom scientifique."""
    splits = dataset / 'splits.csv'
    if not splits.exists():
        return {}
    compte: Counter = Counter()
    with splits.open(newline='', encoding='utf-8') as f:
        for row in csv.DictReader(f):
            compte[row['species']] += 1
    return dict(compte)


def _afficher(r: dict, detail: int) -> None:
    print(f"\n{r['especes']} espèces interrogées, {r['connues']} connues de Commons")
    if r['inconnues']:
        print(f"  {len(r['inconnues'])} sans catégorie : {', '.join(r['inconnues'][:6])}"
              f"{' …' if len(r['inconnues']) > 6 else ''}")
    if not r['connues']:
        return
    print(f"  {r['total']} photographies utilisables au total, médiane {r['mediane']:.0f} par espèce")
    print(f"  {len(r['maigres'])} espèces sous 100 photos — elles ne justifient pas la passe à elles seules")
    if r['deja']:
        print(f"  **{len(r['doublees'])} espèces que Commons pourrait au moins doubler**")

    print(f"\nles {detail} espèces qui gagneraient le plus :")
    for espece in sorted(r['offert'], key=lambda e: -r['offert'][e])[:detail]:
        combien = r['offert'][espece]
        if not combien:
            continue
        avant = r['deja'].get(espece)
        contexte = f"  (le jeu en a {avant} → ×{(avant + combien) / avant:.1f})" if avant else ''
        print(f'  {espece:34s} {combien:4d} photos{contexte}')


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--species-file', default='phase1_species.txt',
                    help="un nom scientifique par ligne ; par défaut les plantes d'intérieur")
    ap.add_argument('--dataset', default='dataset', help='pour comparer à ce que le jeu a déjà')
    ap.add_argument('--limit', type=int, help='ne mesurer que les N premières, pour un ordre de grandeur')
    ap.add_argument('--max-files', type=int, default=300, help='plafond par espèce, comme à la collecte')
    ap.add_argument('--pause', type=float, default=1.0,
                    help="cadence Commons ; en dessous d'une seconde l'API répond 429")
    ap.add_argument('--no-sa', action='store_true', help='refuser CC BY-SA (accepté depuis le 6 septembre)')
    ap.add_argument('--detail', type=int, default=15)
    ap.add_argument('--csv', help='écrire le décompte par espèce')
    args = ap.parse_args(argv)

    from plant_dataset.fetchers.wikimedia import CommonsClient  # réseau : pas à l'import du module

    especes = [l.strip() for l in Path(args.species_file).read_text(encoding='utf-8').splitlines() if l.strip()]
    if args.limit:
        especes = especes[:args.limit]
    client = CommonsClient(pause=args.pause)

    offert: dict[str, int] = {}
    for i, espece in enumerate(especes, 1):
        try:
            offert[espece] = sum(1 for _ in client.image_candidates(
                espece, max_files=args.max_files, allow_share_alike=not args.no_sa))
        except Exception as e:      # une source qui tombe ne doit jamais être lue comme un zéro
            print(f'  [{i}/{len(especes)}] {espece} : ÉCHEC ({type(e).__name__}: {e})', file=sys.stderr)
            continue
        print(f'  [{i}/{len(especes)}] {espece:34s} {offert[espece]:4d}', flush=True)

    rapport = resume(offert, images_du_jeu(Path(args.dataset)))
    _afficher(rapport, args.detail)
    if args.csv:
        with open(args.csv, 'w', newline='', encoding='utf-8') as f:
            w = csv.writer(f)
            w.writerow(['espece', 'commons', 'deja_dans_le_jeu'])
            for e in sorted(offert, key=lambda x: -offert[x]):
                w.writerow([e, offert[e], rapport['deja'].get(e, '')])
        print(f'\ndécompte écrit dans {args.csv}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
