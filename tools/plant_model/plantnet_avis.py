#!/usr/bin/env python3
"""Ce que PlantNet-300K rendrait en second avis d'Iris, mesuré.

    python3 plantnet_avis.py --banc benchmark.csv \\
        --iris ../../assets/model --plantnet ~/plant-data/plantnet.tflite

La question posée est celle du § 5 de `docs/14` : embarquer
`litert-community/PlantNet-300K-ResNet18-LiteRT` à côté d'Iris coûterait
**47 Mo** dans une application qui en porte 9,0, et il faut savoir ce que ça
achète avant de le demander à des bêta-testeurs.

Deux chiffres suffisent à trancher, et ce script rend les deux :

1. **la couverture** — combien des espèces qu'Iris ne nomme pas, PlantNet
   les nomme. C'est de l'arithmétique d'étiquettes, sans une seule
   inférence, et c'est la moitié de la réponse ;
2. **la justesse à armes égales** — les deux modèles sur les **mêmes
   images**, restreints aux espèces que les deux connaissent. C'est la
   mesure du § 6.7 : deux `model.json` ne se comparent pas, deux modèles sur
   les mêmes photos si.

## Ce que la mesure doit départager

Iris 9 a ~190 images par espèce ; PlantNet-300K en a **1 040 en médiane**
(§ 12.8 de `docs/09`) sur 1 081 espèces de flore sauvage d'Europe de l'Ouest.
Sur les espèces communes, la profondeur devrait payer. Ailleurs, il ne peut
rien dire — et un modèle qui ne peut pas dire la bonne réponse répond faux
avec assurance (§ 3.2).

**Prédiction écrite avant de mesurer** : il bat Iris sur les 123 espèces
communes et n'apporte rien sur le reste. Si c'est vrai, c'est 47 Mo pour
123 espèces, dont 43 seulement peuvent apparaître dans un salon.

## Les deux chaînes de prétraitement ne sont pas la même

C'est le piège de ce script, et il est silencieux : une image mal préparée
ne fait pas planter un modèle, elle lui fait rendre des réponses fausses
(§ 6.2 de `docs/09`).

| | Iris 9 | PlantNet-300K |
|---|---|---|
| entrée | 320 px, **NHWC** | 224 px, **NCHW** |
| valeurs | `uint8` 0-255, normalisé dans le graphe | `float32`, **ImageNet** à faire ici |
| sortie | probabilités, somme 1 | **logits** — le softmax est à faire ici |

Le carré central puis la réduction sont en revanche les mêmes : `prepare()`
de `compare_models` sert aux deux, à des tailles différentes.

## Les étiquettes, et pourquoi elles ne tombent pas juste

La carte du modèle dit : « class index `i` maps to the `i`-th species when
the PlantNet-300K species-id strings are sorted ». Les noms viennent du
`plantnet300K_species_id_2_name.json` que Pl@ntNet publie à part — le même
fichier que `tools/plant_dataset/plantnet300k.py` télécharge déjà.

Ces noms portent leur auteur (« Lactuca virosa L. »), qu'il faut retirer pour
les rapprocher des nôtres. Et **1 081 sorties ne font que 1 022 binômes** :
plusieurs classes décrivent la même plante à l'auteur près. Leurs
probabilités sont donc **additionnées**, jamais prises au maximum — c'est le
§ 12.14 à l'envers, où deux classes pour une même plante se partageaient les
images.
"""
from __future__ import annotations

import argparse
import csv
import json
import re
import urllib.request
from pathlib import Path

import numpy as np

from compare_models import load_model, prepare, tally

SEAFILE = 'https://seafile.plantnet.org/d/bed81bc15e8944969cf6/files/?p=%2F{}&dl=1'
NOMS = 'plantnet300K_species_id_2_name.json'

# La normalisation d'ImageNet, telle que la carte du modèle l'annonce.
MOYENNE = np.array([0.485, 0.456, 0.406], dtype=np.float32)
ECART = np.array([0.229, 0.224, 0.225], dtype=np.float32)
ENTREE = 224


# --------------------------------------------------------------------------
# Les étiquettes
# --------------------------------------------------------------------------

def binome(nom: str) -> str:
    """« Lactuca virosa L. » → « Lactuca virosa ».

    On garde trois mots quand le second est le signe de l'hybride, sans quoi
    « Salvia × floriferior » deviendrait « Salvia × » et deux hybrides d'un
    même genre se confondraient.
    """
    mots = re.split(r'\s+', nom.strip())
    if len(mots) >= 3 and mots[1] in ('x', '×'):
        return ' '.join(mots[:3])
    return ' '.join(mots[:2])


def etiquettes_plantnet(noms: dict[str, str]) -> list[str]:
    """Les 1 081 binômes, dans l'ordre des sorties du modèle.

    L'ordre est celui de `torchvision.ImageFolder` : les identifiants
    d'espèce triés **comme des chaînes**, pas comme des nombres. Trier en
    numérique donnerait un décalage silencieux — le modèle répondrait une
    plante pour une autre sans que rien ne le signale.
    """
    return [binome(noms[k]) for k in sorted(noms.keys())]


def espace(etiquettes: list[str], vers_id: dict[str, str]) -> tuple[list[str], list[int]]:
    """L'espace de sortie du modèle, exprimé dans nos identifiants.

    Rend `(labels, groupes)` : `labels` est la liste des classes distinctes,
    `groupes[i]` dit dans laquelle tombe la sortie `i`. Une espèce que notre
    catalogue ignore garde une clé à elle, préfixée `pn:` — elle doit rester
    dans l'espace, sinon la lecture « sorties entières » lui retirerait sa
    masse et flatterait le modèle.
    """
    labels: list[str] = []
    rang: dict[str, int] = {}
    groupes: list[int] = []
    for nom in etiquettes:
        cle = vers_id.get(nom) or f'pn:{nom}'
        if cle not in rang:
            rang[cle] = len(labels)
            labels.append(cle)
        groupes.append(rang[cle])
    return labels, groupes


def agreger(logits: np.ndarray, groupes: list[int], combien: int) -> np.ndarray:
    """Les logits en probabilités, puis sommées par classe distincte.

    Le softmax d'abord, la somme ensuite : deux sorties qui décrivent la même
    plante se partagent sa probabilité, et c'est leur somme qui la rend. Les
    prendre au maximum sous-estimerait toute espèce que le jeu a dédoublée.
    """
    x = np.asarray(logits, dtype=np.float64)
    x = np.exp(x - x.max())
    p = x / x.sum()
    sortie = np.zeros(combien, dtype=np.float32)
    for i, g in enumerate(groupes):
        sortie[g] += p[i]
    return sortie


def couverture(verites: list[str], iris: set[str], plantnet: set[str]) -> dict:
    """Qui sait nommer quoi, sur ces images-là.

    Le chiffre qui décide : parmi ce qu'Iris **ne peut pas** nommer, la part
    que PlantNet nomme. C'est la seule chose que le second avis puisse
    ajouter — le reste, Iris le sait déjà.
    """
    total = len(verites)
    ni_lun_ni_lautre = sum(1 for v in verites if v not in iris and v not in plantnet)
    hors_iris = [v for v in verites if v not in iris]
    rattrapees = sum(1 for v in hors_iris if v in plantnet)
    return {
        'images': total,
        'connues_iris': sum(1 for v in verites if v in iris),
        'connues_plantnet': sum(1 for v in verites if v in plantnet),
        'hors_iris': len(hors_iris),
        'rattrapees_par_plantnet': rattrapees,
        'part_rattrapee': round(rattrapees / len(hors_iris), 4) if hors_iris else None,
        'perdues_pour_les_deux': ni_lun_ni_lautre,
    }


# --------------------------------------------------------------------------
# Le modèle PlantNet
# --------------------------------------------------------------------------

def telecharger(nom: str, cache: Path) -> Path:
    """Le fichier de noms, mis en cache — même source que `plantnet300k.py`."""
    cache.mkdir(parents=True, exist_ok=True)
    chemin = cache / nom
    if not chemin.exists():
        print(f'téléchargement de {nom}…')
        urllib.request.urlretrieve(SEAFILE.format(nom), chemin)
    return chemin


def charger_plantnet(tflite: Path, noms: dict[str, str],
                     vers_id: dict[str, str]):  # pragma: no cover - demande TensorFlow
    import tensorflow as tf
    interpreter = tf.lite.Interpreter(model_path=str(tflite))
    interpreter.allocate_tensors()
    entree = interpreter.get_input_details()[0]
    sortie = interpreter.get_output_details()[0]
    if tuple(entree['shape'][1:]) != (3, ENTREE, ENTREE):
        raise SystemExit(
            f"entrée inattendue {entree['shape']} : ce script prépare du NCHW "
            f"3×{ENTREE}×{ENTREE}. Si le modèle a changé de format, la chaîne de "
            'prétraitement est à refaire — elle ne planterait pas, elle rendrait faux.')
    labels, groupes = espace(etiquettes_plantnet(noms), vers_id)
    return {
        'name': 'plantnet-300k',
        'version': 'ResNet18',
        'labels': labels,
        'index': {c: i for i, c in enumerate(labels)},
        'groupes': groupes,
        'interpreter': interpreter,
        'in': entree,
        'out': sortie,
    }


def predire_plantnet(model, chemin: str) -> np.ndarray:  # pragma: no cover - TensorFlow
    """Le carré central en 224, normalisé ImageNet, en NCHW."""
    x = prepare(chemin, ENTREE, ENTREE)[0] / 255.0          # (224, 224, 3), 0-1
    x = (x - MOYENNE) / ECART
    x = np.transpose(x, (2, 0, 1))[None, ...].astype(np.float32)
    model['interpreter'].set_tensor(model['in']['index'], x)
    model['interpreter'].invoke()
    logits = model['interpreter'].get_tensor(model['out']['index'])[0]
    return agreger(logits, model['groupes'], len(model['labels']))


def predire_iris(model, chemin: str) -> np.ndarray:  # pragma: no cover - TensorFlow
    from compare_models import predict
    return predict(model, chemin)


# --------------------------------------------------------------------------
# Le banc
# --------------------------------------------------------------------------

def lire_banc(chemin: Path, tranches: set[str]) -> list[tuple[str, str]]:
    """(chemin, vérité) pour les tranches demandées du manifeste figé."""
    lignes = []
    with open(chemin, newline='', encoding='utf-8') as f:
        for r in csv.DictReader(f):
            if r['tranche'] in tranches and r['verite']:
                lignes.append((r['chemin'], r['verite']))
    return lignes


def noms_du_catalogue(plants: Path) -> dict[str, str]:
    """{nom scientifique: identifiant interne}, pour rattacher par le nom.

    Les clés GBIF ne recoupent pas celles de Pl@ntNet (§ 12.8), donc le
    rattachement se fait par le binôme, comme pour PlantCLEF.
    """
    with open(plants, newline='', encoding='utf-8') as f:
        return {binome(r['scientific_name']): r['internal_id'] for r in csv.DictReader(f)}


def courbe(predictions, model, restrict, seuils) -> list[dict]:
    """Le couple (autonomie, justesse) à plusieurs seuils.

    Le 0,70 d'Iris ne se transporte pas : il a été réglé sur ses sorties à
    lui (§ 3.1). Un modèle inconnu se lit sur sa courbe, pas au seuil du
    voisin.
    """
    return [dict(seuil=s, **tally(predictions, model, restrict, seuil=s)) for s in seuils]


def main() -> int:  # pragma: no cover - demande TensorFlow et le jeu d'images
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--banc', default='benchmark.csv')
    ap.add_argument('--iris', default='../../assets/model')
    ap.add_argument('--plantnet', default='~/plant-data/plantnet.tflite')
    ap.add_argument('--plants', default='../plant_dataset/plants.csv')
    ap.add_argument('--cache', default='.cache/plantnet')
    ap.add_argument('--tranches', default='outdoor',
                    help='tranches du banc à mesurer, séparées par des virgules')
    ap.add_argument('--couverture-sur', default='ood_plante',
                    help='tranche où compter ce que PlantNet rattrape')
    ap.add_argument('--combien', type=int, default=0, help='limiter les images ; 0 = toutes')
    args = ap.parse_args()

    banc = Path(args.banc).expanduser()
    vers_id = noms_du_catalogue(Path(args.plants).expanduser())
    noms = json.loads(telecharger(NOMS, Path(args.cache).expanduser()).read_text())

    iris = load_model(Path(args.iris).expanduser())
    plantnet = charger_plantnet(Path(args.plantnet).expanduser(), noms, vers_id)

    connues_iris = set(iris['index'])
    connues_pn = {c for c in plantnet['index'] if not c.startswith('pn:')}
    communes = connues_iris & connues_pn
    print(f"Iris {iris['version']} : {len(connues_iris)} classes")
    print(f'PlantNet-300K : {len(plantnet["labels"])} classes distinctes, '
          f'{len(connues_pn)} rattachées au catalogue')
    print(f'communes : {len(communes)}\n')

    # 1. La couverture, sans une seule inférence.
    verites = [v for _, v in lire_banc(banc, {args.couverture_sur})]
    if verites:
        c = couverture(verites, connues_iris, connues_pn)
        print(f'— couverture sur « {args.couverture_sur} » ({c["images"]} images) —')
        print(f'  hors du catalogue d\'Iris : {c["hors_iris"]}')
        print(f'  dont PlantNet en nomme   : {c["rattrapees_par_plantnet"]} '
              f'({c["part_rattrapee"]})')
        print(f'  perdues pour les deux    : {c["perdues_pour_les_deux"]}\n')

    # 2. La justesse, à armes égales, sur les mêmes images.
    tranches = {t.strip() for t in args.tranches.split(',') if t.strip()}
    lignes = [(p, v) for p, v in lire_banc(banc, tranches) if v in communes]
    if args.combien:
        lignes = lignes[:args.combien]
    if not lignes:
        print(f'aucune image de {tranches} sur une espèce commune — rien à comparer')
        return 0

    print(f'— justesse sur « {args.tranches} », {len(lignes)} images des '
          f'{len(communes)} espèces communes —')
    for modele, predire in ((iris, predire_iris), (plantnet, predire_plantnet)):
        predictions = [(v, predire(modele, p)) for p, v in lignes]
        masque = tally(predictions, modele, communes)
        entier = tally(predictions, modele, None)
        print(f"\n  {modele['name']} ({modele['version']})")
        print(f"    sorties masquées : top-1 {masque['top1']}  top-3 {masque['top3']}")
        print(f"    sorties entières : top-1 {entier['top1']}  top-3 {entier['top3']}")
        for l in courbe(predictions, modele, communes, (0.5, 0.7, 0.9)):
            print(f"    seuil {l['seuil']} : {l['accepted_rate']} acceptées, "
                  f"{l['precision_when_accepted']} justes")
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
