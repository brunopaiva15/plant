#!/usr/bin/env python3
"""Ce qu'un deuxième regard sur la photo rapporterait, quand Iris hésite.

    export INFOMANIAK_AI_API_KEY=… INFOMANIAK_AI_PRODUCT_ID=…
    python3 arbitre.py --modele ../../assets/model --dataset /data2/dataset --limite 300
    python3 arbitre.py --modele ../../assets/model --dataset /data2/dataset --a-blanc

**La mesure passe avant la livraison.** L'application sait demander à un
modèle qui voit les images laquelle des cinq candidates d'Iris correspond à la
photo (`InfomaniakIdentificationArbiter`). Reste à savoir si cet avis vaut
mieux que l'ordre d'Iris — et c'est une question de chiffres, pas d'opinion.

Le raisonnement qui rend la mesure intéressante, sur le modèle livré :

- Iris accepte 62 % des photos de plantes en pot, et il a raison 92 % du temps
  quand il accepte. Il n'y a rien à gagner là.
- Sur les 38 % restantes, sa **première** proposition n'est juste que quatre
  fois sur dix, alors que la bonne espèce est dans ses trois premières deux à
  trois fois sur quatre. Le nom est déjà à l'écran ; ce qui manque, c'est de
  savoir lequel regarder.

Un arbitre parfait sur cinq candidates gagnerait donc une trentaine de points
de top-1 sur ces photos-là. Cette mesure dit ce qu'en gagne un vrai.

Ce que le script rend, par population :

    top-1 Iris        ce que l'application montre en tête aujourd'hui
    top-1 arbitré     la même chose, la candidate désignée passant devant
    avis rendus       part des appels qui ont désigné une candidate
    dont juste        part de ces avis qui désignaient la bonne espèce
    déplacements      avis qui changent la tête de liste — les seuls qui
                      coûtent ou rapportent quelque chose
    coût              francs suisses réellement facturés, jetons comptés

`--a-blanc` n'appelle rien : il sélectionne la population, compte les jetons
d'image et annonce la facture. C'est ce qu'il faut lire avant de lancer la
mesure complète.

`--melanger` bat l'ordre des candidates avant de les soumettre. Un modèle de
langage a un biais de position ; si le mélange change le résultat, c'est
l'ordre d'Iris qui était lu, pas la photo.

La consigne et la question sont **les mêmes** que dans l'application
(`lib/data/services/infomaniak_identification_arbiter.dart`). Les recopier ici
est un choix : mesurer autre chose que ce qui sera livré ne mesure rien. Elles
se modifient donc des deux côtés à la fois.
"""
from __future__ import annotations

import argparse
import base64
import io
import json
import os
import random
import sys
import time
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))

from compare_models import load_model, predict, read_test

# Le seuil et la marge de `FallbackPolicy`, côté application.
SEUIL = 0.70
MARGE = 0.25
PLANCHER = 0.10

# Ce que l'application envoie : cinq noms au plus, le grand côté à 768 px.
TOP_K = 5
COTE = 768

# Tarif des AI Services d'Infomaniak pour Mistral Small 4, en CHF par million
# de jetons (§ 9 de docs/09). À revérifier dans le manager : un tarif recopié
# vieillit en silence, et c'est lui qui donne la facture ci-dessous.
PRIX_ENTREE = 0.20
PRIX_SORTIE = 0.75

CONSIGNE = (
    'You are shown one or two photos of the same plant, and a numbered shortlist of candidate species. '
    'Your only task is to say which numbered candidate the photos show, or 0 when none of them does. '
    'Never name a species that is not on the list, and never add one: the list is closed. '
    'Judge from what the photos actually show — leaf shape, size and margin, venation, fenestration, variegation, succulence, petiole, '
    'stem, habit, spines, flowers, fruit — and not from what is common or likely. '
    'Answer 0 whenever the photos do not let you tell one candidate from another, or when the plant is none of them: '
    '0 is a useful answer, and a wrong name is worse than no name. '
    'Answer with one JSON object only, no markdown, with exactly these keys: '
    '"candidate" (integer: the number of the candidate, or 0), '
    '"plant" (boolean: false only when the photos show no plant at all), '
    '"trait" (string: the single visible feature that decided it, at most ten words, in the language with code "{langue}", '
    'empty when "candidate" is 0).'
)


def question(noms: list[str]) -> str:
    """La question soumise : des noms numérotés, et aucun score.

    Donner « 0,44 / 0,39 » ancrerait la réponse sur l'ordre qu'on fait
    arbitrer, et un avis qui recopie l'avis qu'on arbitre ne mesure rien.
    """
    lignes = ['Candidates:']
    lignes += [f'{i + 1}. {nom}' for i, nom in enumerate(noms)]
    lignes.append('Which candidate do the photos show?')
    return '\n'.join(lignes)


def lire_avis(contenu: str, n: int) -> int | None:
    """Le numéro rendu, ou `None` si la réponse est illisible.

    Zéro veut dire « aucune de ces candidates » ; un numéro hors liste vaut
    zéro, exactement comme dans l'application — un modèle qui répond « 7 » sur
    cinq candidates n'a pas répondu à la question posée.
    """
    debut, fin = contenu.find('{'), contenu.rfind('}')
    if debut < 0 or fin <= debut:
        return None
    try:
        data = json.loads(contenu[debut:fin + 1])
    except json.JSONDecodeError:
        return None
    if not isinstance(data, dict):
        return None
    if data.get('plant') is False:
        return 0
    brut = data.get('candidate')
    if isinstance(brut, bool) or brut is None:
        return None
    try:
        numero = int(str(brut).strip())
    except ValueError:
        return None
    return numero if 1 <= numero <= n else 0


def noms_scientifiques(plants: Path) -> dict[str, str]:
    """Identifiant interne → nom scientifique, depuis `plants.csv`.

    Le modèle ne connaît que des identifiants ; l'arbitre, lui, ne peut
    raisonner que sur des noms.
    """
    import csv
    with open(plants, newline='', encoding='utf-8') as f:
        return {r['internal_id']: r['scientific_name'] for r in csv.DictReader(f)}


def hesitant(probs: np.ndarray) -> bool:
    """La photo tombe-t-elle dans la population que l'arbitre verrait ?

    C'est `FallbackPolicy` : une réponse acceptée n'est pas arbitrée, et une
    liste sous le plancher n'offre rien à départager — elle part chez Pl@ntNet.
    """
    ordre = np.sort(probs)[::-1]
    premier = float(ordre[0])
    second = float(ordre[1]) if len(ordre) > 1 else 0.0
    if premier < PLANCHER:
        return False
    return not (premier >= SEUIL and premier - second >= MARGE)


def jetons_image(cote: int = COTE) -> int:
    """Ce qu'une image coûte en jetons : une tuile de seize pixels en est un.

    Le côté entre donc au carré dans la facture, et c'est la seule raison de
    réduire les photos avant l'envoi.
    """
    tuiles = -(-cote // 16)
    return tuiles * tuiles


def cout(usage: dict, prix_entree: float = PRIX_ENTREE, prix_sortie: float = PRIX_SORTIE) -> float:
    """La facture d'un appel, en francs, telle que le service l'a comptée."""
    entree = int(usage.get('prompt_tokens', 0) or 0)
    sortie = int(usage.get('completion_tokens', 0) or 0)
    return entree / 1e6 * prix_entree + sortie / 1e6 * prix_sortie


def mesurer(cas: list[dict]) -> dict:
    """Le tableau, à partir des cas mesurés.

    Un cas : `{'vrai': id, 'candidates': [id…], 'avis': int | None}`, où
    `avis` est le numéro rendu (0 = aucune, `None` = pas de réponse).
    """
    total = len(cas)
    if total == 0:
        return {'photos': 0}
    iris_juste = sum(1 for c in cas if c['candidates'] and c['candidates'][0] == c['vrai'])
    rendus = [c for c in cas if c['avis'] is not None]
    designes = [c for c in rendus if c['avis'] and c['avis'] <= len(c['candidates'])]
    designe = {id(c) for c in designes}
    # Ce que l'application montrerait en tête après arbitrage : la candidate
    # désignée quand il y en a une, sinon l'ordre d'Iris, inchangé.
    arbitre_juste = 0
    deplacements = 0
    deplacements_justes = 0
    deplacements_perdus = 0
    for c in cas:
        tete = c['candidates'][0] if c['candidates'] else None
        if id(c) in designe:
            choisi = c['candidates'][c['avis'] - 1]
        else:
            choisi = tete
        if choisi == c['vrai']:
            arbitre_juste += 1
        if choisi != tete:
            deplacements += 1
            if choisi == c['vrai']:
                deplacements_justes += 1
            elif tete == c['vrai']:
                deplacements_perdus += 1
    contient = sum(1 for c in cas if c['vrai'] in c['candidates'])
    return {
        'photos': total,
        'top1_iris': iris_juste / total,
        'top1_arbitre': arbitre_juste / total,
        'top5_iris': contient / total,
        'avis_rendus': len(rendus) / total,
        'designations': len(designes) / total,
        'designations_justes': (sum(1 for c in designes if c['candidates'][c['avis'] - 1] == c['vrai']) / len(designes))
        if designes else 0.0,
        'aucune': sum(1 for c in rendus if not c['avis']) / total,
        'incidents': (total - len(rendus)) / total,
        'deplacements': deplacements / total,
        'gagnes': deplacements_justes,
        'perdus': deplacements_perdus,
    }


def image_encodee(chemin: str, cote: int = COTE) -> str:
    """La photo telle qu'elle part : JPEG, grand côté borné, en base64."""
    from PIL import Image
    with Image.open(chemin) as im:
        im = im.convert('RGB')
        if max(im.size) > cote:
            ratio = cote / max(im.size)
            im = im.resize((round(im.width * ratio), round(im.height * ratio)), Image.LANCZOS)
        tampon = io.BytesIO()
        im.save(tampon, format='JPEG', quality=85)
    return base64.b64encode(tampon.getvalue()).decode('ascii')


def demander(session, url: str, cle: str, modele: str, chemin: str, noms: list[str], langue: str,
             delai: float) -> tuple[int | None, dict]:
    """Un appel, et ce qu'il a coûté. Une panne rend `(None, {})`."""
    encodee = image_encodee(chemin)
    corps = {
        'model': modele,
        'max_tokens': 200,
        'temperature': 0.0,
        'response_format': {'type': 'json_object'},
        'messages': [
            {'role': 'system', 'content': CONSIGNE.format(langue=langue)},
            {
                'role': 'user',
                'content': [
                    {'type': 'image_url', 'image_url': {'url': f'data:image/jpeg;base64,{encodee}'}},
                    {'type': 'text', 'text': question(noms)},
                ],
            },
        ],
    }
    try:
        r = session.post(url, json=corps, headers={'authorization': f'Bearer {cle}'}, timeout=delai)
        if r.status_code == 400:
            corps.pop('response_format')
            r = session.post(url, json=corps, headers={'authorization': f'Bearer {cle}'}, timeout=delai)
        if r.status_code != 200:
            return None, {}
        data = r.json()
        contenu = data['choices'][0]['message']['content']
        if isinstance(contenu, list):
            contenu = ''.join(p.get('text', '') for p in contenu if isinstance(p, dict))
        return lire_avis(contenu, len(noms)), data.get('usage', {}) or {}
    except Exception:
        return None, {}


def rapport(nom: str, m: dict) -> list[str]:
    """Le tableau d'une population, une ligne par chose à savoir."""
    if not m['photos']:
        return [f'{nom} : aucune photo']
    gain = m['top1_arbitre'] - m['top1_iris']
    return [
        f'{nom} — {m["photos"]} photos',
        f'  top-1 Iris        {m["top1_iris"]:.3f}',
        f'  top-1 arbitré     {m["top1_arbitre"]:.3f}  ({gain:+.3f})',
        f'  top-{TOP_K} Iris        {m["top5_iris"]:.3f}  (le plafond d\'un arbitre parfait)',
        f'  avis rendus       {m["designations"]:.2f}, dont juste {m["designations_justes"]:.2f}',
        f'  aucune / incident {m["aucune"]:.2f} / {m["incidents"]:.2f}',
        f'  déplacements      {m["deplacements"]:.2f}  ({m["gagnes"]} gagnées, {m["perdus"]} perdues)',
    ]


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--modele', type=Path, required=True, help='dossier du modèle exporté (model.json, labels.txt, plants.tflite)')
    ap.add_argument('--dataset', type=Path, required=True, help='jeu de données avec splits.csv')
    ap.add_argument('--plants', type=Path, default=Path(__file__).resolve().parents[1] / 'plant_dataset' / 'plants.csv')
    ap.add_argument('--limite', type=int, default=200, help='photos hésitantes à soumettre')
    ap.add_argument('--cultivees', action='store_true', help='ne garder que les plantes en pot')
    ap.add_argument('--langue', default='fr')
    ap.add_argument('--melanger', action='store_true', help='battre l\'ordre des candidates soumises')
    ap.add_argument('--a-blanc', action='store_true', help='sélectionner et chiffrer la facture, sans appeler')
    ap.add_argument('--graine', type=int, default=1234)
    ap.add_argument('--delai', type=float, default=30.0)
    ap.add_argument('--modele-ia', default=os.environ.get('INFOMANIAK_AI_MODEL', 'mistralai/Mistral-Small-4-119B-2603'))
    args = ap.parse_args()

    cle = os.environ.get('INFOMANIAK_AI_API_KEY', '')
    produit = os.environ.get('INFOMANIAK_AI_PRODUCT_ID', '')
    if not args.a_blanc and not (cle and produit):
        print('INFOMANIAK_AI_API_KEY et INFOMANIAK_AI_PRODUCT_ID sont requis (ou --a-blanc).', file=sys.stderr)
        return 2

    modele = load_model(args.modele)
    noms = noms_scientifiques(args.plants)
    rows = read_test(args.dataset)
    if args.cultivees:
        rows = [r for r in rows if r[2]]
    if not rows:
        print('aucune photo de test', file=sys.stderr)
        return 2

    random.seed(args.graine)
    random.shuffle(rows)

    # Sélection : on classe jusqu'à trouver `--limite` photos hésitantes.
    # Inutile de prédire tout le jeu de test pour n'en soumettre que trois
    # cents ; le taux d'hésitation se mesure au passage.
    labels = modele['labels']
    cas: list[dict] = []
    vus = 0
    for chemin, vrai, _ in rows:
        if len(cas) >= args.limite:
            break
        vus += 1
        probs = predict(modele, chemin)
        if not hesitant(probs):
            continue
        rangs = np.argsort(probs)[::-1][:TOP_K]
        candidates = [labels[i] for i in rangs]
        if len(candidates) < 2:
            continue
        ordre = list(range(len(candidates)))
        if args.melanger:
            random.shuffle(ordre)
        cas.append({
            'chemin': chemin,
            'vrai': vrai,
            'candidates': candidates,
            'soumis': [candidates[i] for i in ordre],
            'avis': None,
        })

    part = len(cas) / vus if vus else 0
    print(f'{vus} photos classées, {len(cas)} hésitantes ({part:.1%}) — c\'est la population que l\'arbitre verrait.')

    entree = jetons_image() + 320  # l'image, la consigne et les cinq noms
    facture = len(cas) * (entree / 1e6 * PRIX_ENTREE + 120 / 1e6 * PRIX_SORTIE)
    print(f'{entree} jetons d\'entrée par appel, environ {facture:.2f} CHF pour {len(cas)} appels.')
    if args.a_blanc:
        return 0

    import requests
    session = requests.Session()
    url = f'https://api.infomaniak.com/2/ai/{produit}/openai/v1/chat/completions'
    reel = 0.0
    depart = time.time()
    for i, c in enumerate(cas, 1):
        soumis = [noms.get(k, k) for k in c['soumis']]
        avis, usage = demander(session, url, cle, args.modele_ia, c['chemin'], soumis, args.langue, args.delai)
        reel += cout(usage)
        # L'avis porte sur la liste soumise ; on le ramène au rang d'Iris pour
        # que la mesure compare bien deux ordres de la même liste.
        if avis:
            nom = c['soumis'][avis - 1]
            c['avis'] = c['candidates'].index(nom) + 1
        else:
            c['avis'] = avis
        if i % 25 == 0:
            print(f'  {i}/{len(cas)} — {reel:.3f} CHF', file=sys.stderr)

    print()
    for l in rapport('hésitantes', mesurer(cas)):
        print(l)
    print()
    print(f'facturé {reel:.3f} CHF pour {len(cas)} appels, soit {reel / max(len(cas), 1) * 1000:.2f} CHF les mille.')
    print(f'{time.time() - depart:.0f} s au total, {(time.time() - depart) / max(len(cas), 1):.1f} s par appel — '
          'c\'est ce que la personne attend devant l\'écran.')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
