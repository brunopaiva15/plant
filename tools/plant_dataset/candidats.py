#!/usr/bin/env python3
"""Les espèces à ajouter au catalogue, classées par ce que les gens cultivent.

    python3 candidats.py --combien 2000 --out candidats-v8.txt

Le § 12.11 dit qu'il faut **sélectionner, pas tirer** : un tirage au hasard
dans le catalogue étendu ne donnerait que 40 % de classes exploitables, et
le § 12.4 ajoute que les espèces les plus faibles du modèle sont déjà des
arbres et des plantes sauvages — 62 des 63 relevées. Grossir cette
population-là coûterait dix points à qui photographie son salon (§ 12.12).

Reste à savoir ce que « cultivée » veut dire pour une base de données.

**Ce n'est pas GBIF qui répond.** Il a le champ qu'il faut —
`degreeOfEstablishment=cultivated` — et personne ne le remplit : 288
occurrences sur les 76 millions de plantes photographiées, soit quatre
millionièmes. Mesuré, pas supposé.

**C'est iNaturalist.** Son drapeau « captive/cultivated » est posé par les
observateurs eux-mêmes et massivement utilisé, et l'API rend directement le
classement : `/observations/species_counts` avec `captive=true` donne 58 000
espèces triées par nombre d'observations. En tête viennent l'hibiscus, le
laurier-rose, l'érable du Japon, le lagerstroemia, l'aloès — c'est-à-dire le
rayon d'une jardinerie, pas une flore de terrain.

Ce classement dit **ce qu'on veut collecter**. Il ne dit pas ce qu'on
*peut* : les images d'iNaturalist ne sont pas toutes sous licence libre.
C'est `disponibilite.py` qui vérifie ensuite, espèce par espèce, qu'il y a
de quoi entraîner une classe.
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from plant_dataset.taxonomy import internal_id, normalize_scientific_name  # noqa: E402

#: Les rangs qui font une classe. Un genre ou une famille n'en fait pas une,
#: et une sous-espèce se confondrait avec l'espèce dans la même image.
RANGS = ('species', 'hybrid')

#: Le plafond d'une page de l'API.
PAGE = 500


def cles(interne: str) -> set[str]:
    """Les écritures sous lesquelles la même plante peut se présenter.

    iNaturalist écrit tantôt « Citrus × limon », tantôt « Citrus limon », et
    les deux donnent des identifiants différents — `citrus-x-limon` et
    `citrus-limon`. Les laisser passer tous les deux, c'est collecter deux
    fois la même plante et créer de toutes pièces le défaut que le § 12.14
    vient de corriger : deux classes pour une espèce, les images partagées,
    une confusion imperdable.
    """
    morceaux = interne.split('-')
    sans_x = '-'.join(p for p in morceaux if p != 'x')
    genre, _, epithete = sans_x.partition('-')
    avec_x = f'{genre}-x-{epithete}' if epithete else sans_x
    return {interne, sans_x, avec_x}


def retenir(resultats: list[dict], connus: set[str], rangs: tuple[str, ...] = RANGS) -> list[tuple[str, int]]:
    """Les candidates réellement nouvelles, dans l'ordre où elles viennent.

    `resultats` est la forme rendue par iNaturalist : `{'count': n, 'taxon':
    {'name': ..., 'rank': ...}}`. `connus` porte les identifiants internes
    déjà au catalogue — c'est la même clé que partout ailleurs.
    """
    vus: set[str] = set()
    out: list[tuple[str, int]] = []
    for r in resultats:
        taxon = r.get('taxon') or {}
        if taxon.get('rank') not in rangs:
            continue
        nom = normalize_scientific_name(taxon.get('name') or '')
        if not nom:
            continue
        variantes = cles(internal_id(nom))
        if variantes & connus or variantes & vus:
            continue
        vus |= variantes
        out.append((nom, int(r.get('count', 0))))
    return out


def deja_au_catalogue(plants: Path, labels: Path | None = None) -> set[str]:
    """Ce qu'on a déjà : le catalogue de collecte, et les classes livrées.

    Les deux, parce qu'ils ne coïncident pas — une espèce peut être au
    catalogue et avoir été écartée du modèle faute d'images (§ 12.1).
    Reproposer celle-là serait juste : c'est une collecte à refaire, pas une
    espèce à découvrir. Mais elle ne doit pas occuper un rang de nouveauté.
    """
    import csv
    connus: set[str] = set()
    if plants.exists():
        connus |= {r['internal_id'] for r in csv.DictReader(plants.open(encoding='utf-8'))}
    if labels and labels.exists():
        connus |= {l.strip() for l in labels.read_text(encoding='utf-8').splitlines() if l.strip()}
    return connus


def _pages(client, combien: int, extra: dict) -> list[dict]:
    """Assez de pages pour `combien` candidates, jamais plus."""
    resultats: list[dict] = []
    page = 1
    while len(resultats) < combien:
        d = client._get('/observations/species_counts', per_page=PAGE, page=page, **extra)
        lot = d.get('results') or []
        if not lot:
            break
        resultats.extend(lot)
        print(f'  page {page} : {len(resultats)} taxons', file=sys.stderr, flush=True)
        page += 1
    return resultats


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--combien', type=int, default=2000, help='candidates nouvelles à rendre')
    ap.add_argument('--plants', default='plants.csv')
    ap.add_argument('--labels', default='../../assets/model/labels.txt')
    ap.add_argument('--place', type=int, help="restreindre à un lieu iNaturalist (place_id), p. ex. l'Europe")
    ap.add_argument('--pause', type=float, default=1.0, help='cadence iNaturalist ; en dessous, 429')
    ap.add_argument('--out', help='un nom par ligne, prêt pour disponibilite.py')
    ap.add_argument('--csv', help='avec le nombre d\'observations cultivées')
    args = ap.parse_args(argv)

    from plant_dataset.fetchers.inaturalist import InatClient   # réseau : pas à l'import du module

    connus = deja_au_catalogue(Path(args.plants), Path(args.labels))
    print(f'{len(connus)} plantes déjà connues du catalogue ou du modèle\n', file=sys.stderr)

    extra = {'iconic_taxa': 'Plantae', 'captive': 'true', 'photos': 'true'}
    if args.place:
        extra['place_id'] = args.place
    # On demande plus large que `--combien` : une bonne part des taxons rendus
    # sont déjà au catalogue, ou d'un rang qui ne fait pas une classe.
    brut = _pages(InatClient(pause=args.pause), args.combien * 2, extra)
    candidates = retenir(brut, connus)[:args.combien]

    print(f'\n{len(brut)} taxons parcourus, {len(candidates)} candidates nouvelles')
    if candidates:
        print(f"observations cultivées : de {candidates[0][1]} pour la première "
              f"à {candidates[-1][1]} pour la dernière\n")
        for nom, n in candidates[:15]:
            print(f'  {n:7d}  {nom}')
        if len(candidates) > 15:
            print(f'  … et {len(candidates) - 15} autres')

    if args.out:
        Path(args.out).write_text('\n'.join(n for n, _ in candidates) + '\n', encoding='utf-8')
        print(f'\n{len(candidates)} noms écrits dans {args.out}')
        print(f'→ vérifier ce qu\'on peut réellement collecter :\n'
              f'   python3 disponibilite.py --species-file {args.out} --csv disponibilite.csv')
    if args.csv:
        import csv as _csv
        with open(args.csv, 'w', newline='', encoding='utf-8') as f:
            w = _csv.writer(f)
            w.writerow(['espece', 'observations_cultivees'])
            w.writerows(candidates)
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
