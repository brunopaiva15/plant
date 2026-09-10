#!/usr/bin/env python3
"""Sur quoi le modèle se trompe — pas seulement combien.

    python3 confusions.py --dataset ../plant_dataset/dataset \\
        --model ../../assets/model --sample 6000

`train.py` rend le top-1, le top-3, le macro-F1 et la courbe de seuil : on
sait *combien* le modèle se trompe, jamais *sur quoi*. Le § 6.9 promet une
matrice de confusion par genre depuis la v1 ; sans elle, les défauts se
trouvent un par un, à la main, sur des photos réelles — c'est comme ça que
le yucca pris pour du maïs a été découvert (§ 6.3), et il avait eu le temps
de traverser trois versions.

Trois tiroirs, parce que deux mentaient :

- **dans le genre** : deux érables, deux sapins, deux pépéromias. L'écran
  propose cinq candidats, la bonne réponse y est presque toujours ;
- **dans la famille** : *Picea* → *Abies*, deux Pinaceae. Botaniquement
  proches, visuellement proches, et durs pour un humain aussi ;
- **au-delà** : *Parthenocissus* → *Petroselinum*, une vigne vierge prise
  pour du persil. C'est là que sont les vrais défauts, et ces paires-là se
  corrigent par des images.

**Et chaque part se lit contre le hasard, sinon elle ne dit rien.** 38 % des
classes sont seules dans leur genre : leurs erreurs ne *peuvent pas* rester
dans le genre. Une erreur tirée au sort y resterait 0,17 % du temps ; en
annoncer 13 % n'est donc pas « une petite part attendue » mais soixante-dix
fois le hasard. La première version de ce fichier appelait « vrais défauts »
les 87 % restants, ce qui revenait à compter comme un défaut la structure du
catalogue.

Le rapport se lit donc de haut en bas : les trois parts et leur hasard, les
paires responsables ensuite, et enfin les espèces qui échouent le plus
souvent avec ce qu'on leur répond à la place.
"""
from __future__ import annotations

import argparse
import csv
import random
import sys
from collections import Counter, defaultdict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))


def genre(internal_id: str, noms: dict[str, str] | None = None) -> str:
    """Le genre d'une espèce, depuis son identifiant interne.

    Les identifiants sont `genre-épithète` (`monstera-deliciosa`), donc le
    préfixe suffit — et reste juste pour les hybrides, dont l'identifiant
    porte le `x` en deuxième position (`abelia-x-grandiflora`). `plants.csv`
    sert de recours quand il est là, mais l'outil doit tourner sans.
    """
    if noms and internal_id in noms:
        return noms[internal_id].split()[0].lower()
    return internal_id.split('-')[0]


def famille(internal_id: str, familles: dict[str, str] | None = None) -> str:
    """La famille d'une espèce, quand `plants.csv` la donne.

    Elle la donne pour les 1 457 classes de l'Iris 7, mais l'outil doit
    tourner sans : une famille inconnue vaut son propre identifiant, donc
    elle ne se confond avec aucune autre.
    """
    if familles and internal_id in familles:
        return familles[internal_id].strip().lower()
    return f'?{internal_id}'


def au_hasard(classes: list[str], familles: dict[str, str] | None = None,
              noms: dict[str, str] | None = None) -> dict:
    """Où tomberait une erreur tirée au sort — la seule référence qui vaille.

    Sans elle, « 13 % des erreurs restent dans le genre » se lit comme une
    petite part, alors que c'est soixante-dix fois ce que donnerait le
    hasard. Le calcul suppose les classes équiprobables : c'est faux dans le
    détail, mais l'ordre de grandeur suffit à empêcher le contresens.
    """
    n = len(classes)
    if n < 2:
        return {'genre': 0.0, 'famille': 0.0, 'seules_dans_leur_genre': 0}
    par_genre: Counter = Counter(genre(c, noms) for c in classes)
    par_famille: Counter = Counter(famille(c, familles) for c in classes)
    pg = sum(par_genre[genre(c, noms)] - 1 for c in classes) / (n * (n - 1))
    pf = sum(par_famille[famille(c, familles)] - par_genre[genre(c, noms)] for c in classes) / (n * (n - 1))
    return {
        'genre': pg,
        'famille': pf,
        'seules_dans_leur_genre': sum(1 for c in classes if par_genre[genre(c, noms)] == 1),
    }


def croiser(paires: list[tuple[str, str]], noms: dict[str, str] | None = None,
            familles: dict[str, str] | None = None) -> dict:
    """Range les erreurs selon la distance taxonomique entre les deux espèces.

    `paires` est une liste de (vérité, prédiction) en identifiants internes.

    Sans `familles`, il ne reste que deux tiroirs et `meme_famille` vaut
    zéro : le rapport le dit alors au lieu d'annoncer une part nulle.
    """
    justes = dans_genre = meme_famille = hors_famille = 0
    entre_genres: Counter = Counter()
    entre_familles: Counter = Counter()
    par_espece: dict[str, Counter] = defaultdict(Counter)
    vues: Counter = Counter()
    for verite, predit in paires:
        vues[verite] += 1
        if verite == predit:
            justes += 1
            continue
        par_espece[verite][predit] += 1
        gv, gp = genre(verite, noms), genre(predit, noms)
        if gv == gp:
            dans_genre += 1
            continue
        entre_genres[(gv, gp)] += 1
        fv, fp = famille(verite, familles), famille(predit, familles)
        if familles and fv == fp:
            meme_famille += 1
        else:
            hors_famille += 1
            if familles:
                entre_familles[(fv, fp)] += 1
    return {
        'images': len(paires),
        'justes': justes,
        'dans_genre': dans_genre,
        'meme_famille': meme_famille,
        'hors_famille': hors_famille,
        'hors_genre': meme_famille + hors_famille,
        'entre_genres': entre_genres,
        'entre_familles': entre_familles,
        'par_espece': par_espece,
        'vues': vues,
    }


def especes_en_difficulte(stats: dict, minimum: int = 5) -> list[tuple[str, int, int, str, int]]:
    """Les espèces les plus ratées, avec ce qu'on leur répond à la place.

    En dessous de `minimum` images de test, un taux d'échec ne veut rien
    dire — on ne classe pas une espèce sur trois photos.
    """
    out = []
    for espece, vues in stats['vues'].items():
        if vues < minimum:
            continue
        erreurs = stats['par_espece'].get(espece)
        if not erreurs:
            continue
        coupable, combien = erreurs.most_common(1)[0]
        out.append((espece, sum(erreurs.values()), vues, coupable, combien))
    out.sort(key=lambda r: (-r[1] / r[2], -r[2]))
    return out


def _rapport(stats: dict, noms: dict, familles: dict, hasard: dict, top: int) -> None:
    n, justes = stats['images'], stats['justes']
    erreurs = n - justes
    print(f'{n} images, {justes} justes ({justes / n:.1%})\n')
    if not erreurs:
        print('aucune erreur : rien à dire.')
        return

    def part(combien, reference=None):
        ligne = f"  {combien:6d}  ({combien / erreurs:5.1%})"
        if reference is not None:
            ligne += f"   au hasard : {reference:5.2%}"
            if reference > 0:
                ligne += f"  → ×{combien / erreurs / reference:.0f}"
        # Largeur fixe : les trois parts doivent se lire en colonne, y
        # compris celle qui n'a pas de référence à afficher.
        return ligne.ljust(48)

    print(f'{erreurs} erreurs, rangées par distance taxonomique :')
    print(f"{part(stats['dans_genre'], hasard.get('genre'))}   dans le même genre")
    if familles:
        print(f"{part(stats['meme_famille'], hasard.get('famille'))}   dans la même famille")
        print(f"{part(stats['hors_famille'])}   au-delà  ← les vrais défauts")
    else:
        print(f"{part(stats['hors_genre'])}   hors du genre (sans `plants.csv`, la famille n'est pas connue)")
    seules = hasard.get('seules_dans_leur_genre')
    if seules:
        print(f"\n{seules} classes sont seules dans leur genre : leurs erreurs ne *peuvent pas*")
        print("y rester. C'est pourquoi la colonne « au hasard » est là — sans elle, la")
        print('première ligne se lirait comme une petite part au lieu de son contraire.')

    def joli(i):
        return noms.get(i, i)

    print(f'\nles {top} confusions de genre les plus fréquentes :')
    for (gv, gp), combien in stats['entre_genres'].most_common(top):
        print(f'  {gv:22s} → {gp:22s} {combien:5d}')

    if stats['entre_familles']:
        print(f'\nles {top} confusions de famille les plus fréquentes — celles qui coûtent des images :')
        for (fv, fp), combien in stats['entre_familles'].most_common(top):
            print(f'  {fv:22s} → {fp:22s} {combien:5d}')

    print(f'\nles {top} espèces les plus ratées (au moins 5 images de test) :')
    for espece, ratees, vues, coupable, combien in especes_en_difficulte(stats)[:top]:
        if genre(espece, noms) == genre(coupable, noms):
            mot = 'même genre'
        elif familles and famille(espece, familles) == famille(coupable, familles):
            mot = 'même famille'
        else:
            mot = 'AU-DELÀ'
        print(f'  {joli(espece):34s} {ratees:3d}/{vues:3d} ratées → {joli(coupable):32s} ×{combien} ({mot})')


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--dataset', default='../plant_dataset/dataset')
    ap.add_argument('--model', default='../../assets/model')
    ap.add_argument('--sample', type=int, default=6000, help='images de test tirées au hasard, 0 = toutes')
    ap.add_argument('--seed', type=int, default=20260905)
    ap.add_argument('--captive', action='store_true', help='ne garder que les photos de plantes cultivées')
    ap.add_argument('--top', type=int, default=20)
    ap.add_argument('--csv', help='écrire toutes les paires (vérité, prédiction) pour creuser ailleurs')
    ap.add_argument('--pairs', help='relire un CSV de paires déjà écrit au lieu de refaire les inférences')
    ap.add_argument('--plants', default='../plant_dataset/plants.csv')
    args = ap.parse_args(argv)

    noms, familles = {}, {}
    plants = Path(args.plants)
    if plants.exists():
        for r in csv.DictReader(plants.open(encoding='utf-8')):
            noms[r['internal_id']] = r['scientific_name']
            if r.get('family', '').strip():
                familles[r['internal_id']] = r['family']

    classes = [l.strip() for l in (Path(args.model) / 'labels.txt').read_text(encoding='utf-8').splitlines() if l.strip()]

    if args.pairs:
        # Les paires suffisent au rapport : relire un fichier déjà écrit coûte
        # une seconde là où refaire 6 000 inférences coûte vingt minutes.
        # C'est ce qui a permis de corriger la lecture de ce rapport sans
        # remobiliser la machine d'entraînement.
        with open(args.pairs, newline='', encoding='utf-8') as f:
            paires = [(r['verite'], r['prediction']) for r in csv.DictReader(f)]
        print(f'{len(paires)} paires relues de {args.pairs}\n', flush=True)
        _rapport(croiser(paires, noms, familles), noms, familles,
                 au_hasard(classes, familles, noms), args.top)
        return 0

    # Importés ici : ils tirent TensorFlow, dont les fonctions pures de ce
    # fichier n'ont pas besoin pour être testées.
    import numpy as np
    from compare_models import load_model, predict, read_test

    modele = load_model(Path(args.model))
    lignes = [(p, t) for p, t, cap in read_test(Path(args.dataset)) if not args.captive or cap]
    lignes = [(p, t) for p, t in lignes if t in modele['index']]
    if args.sample and len(lignes) > args.sample:
        lignes = random.Random(args.seed).sample(lignes, args.sample)
    print(f"modèle v{modele['version']} — {len(lignes)} images de test"
          f"{' (plantes cultivées)' if args.captive else ''}\n", flush=True)

    paires = []
    for i, (chemin, verite) in enumerate(lignes, 1):
        paires.append((verite, modele['labels'][int(np.argmax(predict(modele, chemin)))]))
        if i % 500 == 0:
            print(f'  {i}/{len(lignes)}', flush=True)
    print()

    if args.csv:
        with open(args.csv, 'w', newline='', encoding='utf-8') as f:
            w = csv.writer(f)
            w.writerow(['verite', 'prediction'])
            w.writerows(paires)
        print(f'{len(paires)} paires écrites dans {args.csv}\n')

    _rapport(croiser(paires, noms, familles), noms, familles,
             au_hasard(classes, familles, noms), args.top)
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
