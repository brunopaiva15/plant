#!/usr/bin/env python3
"""Le teacher d'Iris 10 passé une fois sur le corpus, et ce qu'il en reste.

    python3 bioclip.py mesure --dataset ~/plant-data/dataset-echantillon
    python3 bioclip.py cache  --dataset ~/plant-data/dataset-v8-indoor \\
        --cache ~/plant-data/bioclip
    python3 bioclip.py textes --plants ../plant_dataset/plants.csv \\
        --cache ~/plant-data/bioclip
    python3 bioclip.py centroides --dataset ~/plant-data/dataset-v8-indoor \\
        --cache ~/plant-data/bioclip

C'est l'étape 4 du § 20 de `docs/14`, et elle est ce qui rend les suivantes
abordables : **le teacher tourne une fois sur le corpus**, ensuite aucune
boucle de distillation ne le rappelle. Un ViT-H/14 coûte de l'ordre de cent
fois un MobileNet par image ; le rappeler à chaque époque reviendrait à payer
l'entraînement d'Iris 9 en entier à chaque passe.

Quatre commandes, dans l'ordre où elles se lancent :

| commande | ce qu'elle fait |
|---|---|
| `mesure` | le débit du teacher sur cent images, et ce que le corpus coûtera |
| `cache` | les embeddings du corpus, en fragments `float16`, repris où ils s'arrêtent |
| `textes` | une référence par espèce, depuis sa taxonomie (§ 7 de `docs/14`) |
| `centroides` | une référence par espèce, depuis ses photos cachées |

**La clé du cache porte le prétraitement, pas seulement le chemin.** C'est la
précaution du § 20 bis, et elle vaut d'être dite : un cache faux est pire
qu'un cache absent, parce qu'il ne se voit pas. Le dossier porte donc un
`signature.json` — teacher, dimension, taille d'entrée, normalisation — et
une passe qui n'a pas la même signature refuse d'écrire dedans plutôt que d'y
mélanger deux espaces.

**Et les références se calculent avec le même teacher que les images.** Des
vecteurs d'espèces d'une version et des vecteurs de photos d'une autre ne
vivent pas dans le même espace ; `textes` et `centroides` relisent donc la
signature du cache au lieu de refaire la leur.

Ce qu'on ne fait pas ici : aucune distillation, aucun student, aucune
supervision taxonomique. Ce sont les étapes 5 et au-delà, et les mêler à
celle-ci rendrait la porte A illisible (§ 19 de `docs/14`).

## Sur la machine du projet

Le venv d'entraînement porte `tensorflow[and-cuda]`, qui embarque ses propres
CUDA et cuDNN ; PyTorch embarque les siens. Les deux dans un même venv est la
même erreur que `tensorflow-cpu` à côté de `tensorflow[and-cuda]`, en plus
gros. **Un venv séparé :**

    python3 -m venv ~/venv-torch && source ~/venv-torch/bin/activate
    pip install -r requirements-bioclip.txt

Les 8 Go de VRAM sont la contrainte dure, comme pour l'entraînement à 320 px.
Un ViT-H/14 en `float16` tient ses poids dans 1,3 Go et le reste est de
l'activation, donc proportionnel au lot : `--batch 32` est le défaut, et
c'est une décision, pas un accident. `mesure` affiche ce que la carte a
réellement réservé — c'est le chiffre à lire avant de lancer la nuit.
"""
from __future__ import annotations

import argparse
import csv
import hashlib
import json
import time
from collections import defaultdict
from pathlib import Path

import numpy as np

TEACHER = 'hf-hub:imageomics/bioclip-2.5-vith14'
DIM = 1024
SPLITS = ('train', 'val', 'test')

# Les formulations du § 7. Elles sont listées ici, et non construites au vol,
# parce que la référence d'une espèce ne vaut que si l'on sait quelle phrase
# l'a produite : changer ce dictionnaire change l'espace des références sans
# rien changer au cache des images, et c'est exactement le genre d'écart que
# la signature ne rattraperait pas.
PHRASES = {
    'binome': ['a photo of {genus} {epithet}.'],
    'hierarchie': ['a photo of Plantae {family} {genus} {epithet}.'],
    'commun': ['a photo of {common_en}.'],
    'ensemble': [
        'a photo of {genus} {epithet}.',
        'a photo of Plantae {family} {genus} {epithet}.',
        'a photo of {common_en}.',
    ],
}


# --------------------------------------------------------------------------
# La signature, et ce qu'elle protège
# --------------------------------------------------------------------------

def empreinte(conf: dict) -> str:
    """Douze caractères qui résument le prétraitement.

    Le chemin d'une image ne dit pas comment elle a été réduite avant de
    traverser le teacher. Deux passes au même chemin et à la taille d'entrée
    différente rendraient deux vecteurs incomparables sous la même clé.
    """
    canon = json.dumps(conf, sort_keys=True, ensure_ascii=False, separators=(',', ':'))
    return hashlib.sha256(canon.encode('utf-8')).hexdigest()[:12]


def signature(teacher: str, taille: int, moyenne, ecart, dim: int = DIM) -> dict:
    conf = {
        'teacher': teacher,
        'dim': int(dim),
        'taille_entree': int(taille),
        'moyenne': [round(float(x), 6) for x in moyenne],
        'ecart_type': [round(float(x), 6) for x in ecart],
        # Les vecteurs sont rangés normalisés (voir `encoder`). C'est une
        # propriété du contenu du cache, donc elle appartient à la clé.
        'normalise': True,
    }
    conf['empreinte'] = empreinte(conf)
    return conf


def lire_signature(cache: Path) -> dict | None:
    fichier = cache / 'signature.json'
    if not fichier.exists():
        return None
    return json.loads(fichier.read_text(encoding='utf-8'))


def accorder_signature(cache: Path, sig: dict, forcer: bool = False) -> None:
    """Refuse d'écrire dans un cache qui décrit autre chose."""
    ancienne = lire_signature(cache)
    if ancienne is None:
        cache.mkdir(parents=True, exist_ok=True)
        (cache / 'signature.json').write_text(
            json.dumps(sig, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
        return
    if ancienne.get('empreinte') == sig.get('empreinte') or forcer:
        return
    raise SystemExit(
        f"{cache} contient des vecteurs d'une autre signature :\n"
        f"  déjà là  {ancienne.get('empreinte')}  {ancienne.get('teacher')} "
        f"à {ancienne.get('taille_entree')} px\n"
        f"  demandé  {sig.get('empreinte')}  {sig.get('teacher')} "
        f"à {sig.get('taille_entree')} px\n"
        "Un cache mélangé ne se voit pas à l'usage. Choisir un autre dossier, "
        "ou --forcer si l'on sait ce qu'on fait.")


# --------------------------------------------------------------------------
# Le corpus, l'index, les fragments
# --------------------------------------------------------------------------

def lire_corpus(dataset: Path, splits: tuple[str, ...]) -> list[tuple[str, str, str]]:
    """(chemin, espèce, `captive`) pour les images qui existent vraiment."""
    if not (dataset / 'splits.csv').exists():
        raise SystemExit(f'{dataset}/splits.csv introuvable — --dataset pointe-t-il '
                         'sur un jeu construit par tools/plant_dataset ?')
    lignes = []
    with open(dataset / 'splits.csv', newline='', encoding='utf-8') as f:
        for r in csv.DictReader(f):
            if r['split'] not in splits:
                continue
            chemin = dataset / r['path']
            if chemin.exists():
                lignes.append((str(chemin), r['internal_plant_id'],
                               '1' if r.get('captive') == '1' else '0'))
    return lignes


def lire_index(cache: Path) -> dict[str, tuple[str, int]]:
    """{chemin: (fragment, ligne)} — la réunion de tous les index de parts."""
    index: dict[str, tuple[str, int]] = {}
    for fichier in sorted(cache.glob('index-*.csv')):
        with open(fichier, newline='', encoding='utf-8') as f:
            for r in csv.reader(f):
                if len(r) == 3:
                    index[r[0]] = (r[1], int(r[2]))
    return index


def restant(corpus: list[tuple[str, str, str]], deja: dict) -> list[tuple[str, str, str]]:
    """Ce que la passe doit encore calculer. Le cache est incrémental par
    construction : une nuit coupée se rattrape en relançant la même ligne."""
    return [l for l in corpus if l[0] not in deja]


def tranche(items: list, part: int, parts: int) -> list:
    """Une part disjointe du travail, pour deux machines ou deux nuits.

    Le découpage est entrelacé plutôt que contigu : les images de `splits.csv`
    sont rangées par espèce, et des parts contiguës donneraient à l'une les
    classes riches et à l'autre les pauvres — deux parts de durées très
    différentes, alors qu'on les veut égales.
    """
    if parts <= 1:
        return items
    if not 0 <= part < parts:
        raise SystemExit(f'--part {part}/{parts} : la part doit être entre 0 et {parts - 1}')
    return items[part::parts]


def extrapolation(vus: int, secondes: float, total: int, dim: int = DIM) -> dict:
    """Ce que le corpus coûtera, depuis ce que cent images ont coûté.

    Le § 20 bis le demande explicitement : le débit d'un ViT-H/14 ne se
    devine pas depuis celui d'un MobileNet, et une passe qui dépasserait la
    nuit se découpe en parts avant d'être lancée, pas après.
    """
    debit = vus / secondes if secondes > 0 else float('inf')
    return {
        'images_par_seconde': debit,
        'secondes': total / debit if debit else float('inf'),
        'heures': total / debit / 3600 if debit else float('inf'),
        'octets': total * dim * 2,
        'gio': total * dim * 2 / 2 ** 30,
    }


# --------------------------------------------------------------------------
# Le teacher
# --------------------------------------------------------------------------

def charger_teacher(nom: str, appareil: str | None = None, demi: bool = True):
    """Le modèle, sa transformation d'images et son tokeniseur.

    L'import est tardif pour que le reste du fichier — l'index, les parts, les
    phrases, les centroïdes — reste lisible et testable sans PyTorch, qui
    n'est pas dans le venv d'entraînement et ne doit pas y être.
    """
    try:
        import torch
        import open_clip
    except ImportError as e:  # pragma: no cover - dépend de l'environnement
        raise SystemExit(
            f'{e}. Un venv séparé du venv TensorFlow :\n'
            '  python3 -m venv ~/venv-torch && source ~/venv-torch/bin/activate\n'
            '  pip install -r requirements-bioclip.txt') from e

    if appareil is None:
        appareil = 'cuda' if torch.cuda.is_available() else 'cpu'
    if appareil == 'cpu':
        print('carte graphique absente : le teacher tournera sur le processeur, '
              'ce qui se compte en jours et non en heures')
        demi = False

    modele, _, transforme = open_clip.create_model_and_transforms(nom)
    modele = modele.to(appareil).eval()
    if demi:
        modele = modele.half()
    return modele, transforme, open_clip.get_tokenizer(nom), appareil, demi


def conf_du_transforme(transforme) -> tuple[int, list, list]:
    """La taille d'entrée et la normalisation, lues dans la transformation du
    teacher plutôt que recopiées.

    On ne réutilise **pas** la chaîne de réduction d'Iris (§ 6.2 de `docs/09`,
    `source_size` / `load_size`). Ici c'est le teacher qui définit l'espace :
    lui donner autre chose que son propre prétraitement, c'est mesurer un
    autre modèle que celui dont on veut la géométrie.
    """
    taille, moyenne, ecart = 224, [0.0, 0.0, 0.0], [1.0, 1.0, 1.0]
    for t in getattr(transforme, 'transforms', []):
        nom = type(t).__name__
        if nom == 'Normalize':
            moyenne, ecart = list(t.mean), list(t.std)
        elif nom == 'CenterCrop':
            s = t.size
            taille = int(s[0] if isinstance(s, (tuple, list)) else s)
    return taille, moyenne, ecart


def encoder(modele, transforme, chemins: list[str], appareil: str, demi: bool,
            batch: int):  # pragma: no cover - demande PyTorch et des images
    """Les vecteurs de ces images, unitaires, dans l'ordre reçu.

    **Rangés normalisés.** La perte cosinus de l'étape 5 et le k-plus-proches-
    voisins de l'étape 6 ne lisent que la direction ; garder la norme ne
    servirait à rien et coûterait la moitié de la précision utile du
    `float16`, dont les exposants sont bien mieux employés sur des
    composantes toutes de l'ordre du trentième.
    """
    import torch
    from PIL import Image

    sortie = np.empty((len(chemins), DIM), dtype=np.float16)
    ecrit = 0
    for debut in range(0, len(chemins), batch):
        lot = chemins[debut:debut + batch]
        images = []
        for c in lot:
            with Image.open(c) as im:
                images.append(transforme(im.convert('RGB')))
        x = torch.stack(images).to(appareil)
        if demi:
            x = x.half()
        with torch.no_grad():
            v = modele.encode_image(x)
            v = v / v.norm(dim=-1, keepdim=True)
        sortie[ecrit:ecrit + len(lot)] = v.float().cpu().numpy().astype(np.float16)
        ecrit += len(lot)
    return sortie


# --------------------------------------------------------------------------
# Les références d'espèces
# --------------------------------------------------------------------------

def phrases(espece: dict, modele: str = 'ensemble') -> list[str]:
    """Les formulations à encoder pour cette espèce, celles qui sont remplies.

    La hiérarchie est partielle — `plants.csv` porte la famille, le genre et
    l'épithète, pas l'ordre ni la classe. BioCLIP accepte une hiérarchie
    tronquée ; il faut seulement savoir que ce n'est pas la formulation
    canonique complète, et que le jour où le catalogue portera l'ordre, ces
    références changeront d'espace et se recalculeront en entier.
    """
    sortie = []
    for gabarit in PHRASES[modele]:
        cles = [c.split('}')[0] for c in gabarit.split('{')[1:]]
        if all(str(espece.get(c) or '').strip() for c in cles):
            sortie.append(gabarit.format(**{c: str(espece[c]).strip() for c in cles}))
    return sortie


def moyenne_unitaire(vecteurs: np.ndarray) -> np.ndarray:
    """La direction moyenne d'un paquet de vecteurs.

    Chacun est ramené à la longueur 1 avant la moyenne : sans cela une
    formulation que le teacher encode avec une norme plus grande pèserait
    davantage dans la référence, pour une raison qui n'a rien à voir avec
    l'espèce décrite.
    """
    v = np.asarray(vecteurs, dtype=np.float32)
    if v.ndim == 1:
        v = v[None, :]
    normes = np.linalg.norm(v, axis=1, keepdims=True)
    normes[normes == 0] = 1.0
    moyenne = (v / normes).mean(axis=0)
    n = np.linalg.norm(moyenne)
    return moyenne / n if n else moyenne


def accumuler(sommes: dict, comptes: dict, etiquettes: list[str],
              vecteurs: np.ndarray) -> None:
    """Ajoute un fragment aux sommes par espèce, sans tout charger.

    Le corpus entier fait deux gigaoctets de vecteurs ; les additionner
    fragment par fragment évite de les tenir tous, et donne exactement le
    même centroïde qu'une somme en une fois.
    """
    v = np.asarray(vecteurs, dtype=np.float32)
    for i, e in enumerate(etiquettes):
        if e not in sommes:
            sommes[e] = np.zeros(v.shape[1], dtype=np.float64)
            comptes[e] = 0
        sommes[e] += v[i]
        comptes[e] += 1


def centroides(sommes: dict, comptes: dict, min_images: int = 5
               ) -> tuple[list[str], np.ndarray, list[int]]:
    """Une référence par espèce assez photographiée, normalisée.

    Sous `min_images`, le centroïde décrit une poignée de photos plus qu'une
    espèce : il est écarté plutôt que livré avec une fausse autorité. La
    référence textuelle, elle, existe pour toutes.
    """
    gardees = sorted(e for e in sommes if comptes[e] >= min_images)
    if not gardees:
        return [], np.zeros((0, DIM), dtype=np.float16), []
    vecteurs = np.stack([moyenne_unitaire(sommes[e] / comptes[e]) for e in gardees])
    return gardees, vecteurs.astype(np.float16), [comptes[e] for e in gardees]


def ecrire_references(cache: Path, nom: str, cles: list[str], vecteurs: np.ndarray,
                      colonnes: dict[str, list], meta: dict) -> None:
    np.save(cache / f'{nom}.npy', vecteurs)
    with open(cache / f'{nom}.csv', 'w', newline='', encoding='utf-8') as f:
        w = csv.writer(f)
        entetes = ['internal_id'] + list(colonnes)
        w.writerow(entetes)
        for i, c in enumerate(cles):
            w.writerow([c] + [colonnes[k][i] for k in colonnes])
    (cache / f'{nom}.json').write_text(
        json.dumps(meta, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
    print(f'{cache / nom}.npy — {len(cles)} références de {vecteurs.shape[1] if len(cles) else 0} '
          f'dimensions')


# --------------------------------------------------------------------------
# Les commandes
# --------------------------------------------------------------------------

def cmd_mesure(args) -> int:  # pragma: no cover - demande PyTorch
    dataset = Path(args.dataset).expanduser()
    corpus = lire_corpus(dataset, SPLITS)
    if not corpus:
        raise SystemExit(f'aucune image dans {dataset}')
    combien = min(args.combien, len(corpus))
    chemins = [c for c, _, _ in corpus[:combien]]

    modele, transforme, _, appareil, demi = charger_teacher(args.teacher, args.appareil)
    taille, moyenne, ecart = conf_du_transforme(transforme)
    sig = signature(args.teacher, taille, moyenne, ecart)
    print(f'{args.teacher}\n  {appareil}, {"float16" if demi else "float32"}, '
          f'entrée {taille} px, signature {sig["empreinte"]}')

    # Un premier lot ne compte pas : il paie les noyaux CUDA, l'allocateur et
    # le premier accès au disque. Le chronomètre part après.
    encoder(modele, transforme, chemins[:args.batch], appareil, demi, args.batch)
    debut = time.perf_counter()
    encoder(modele, transforme, chemins, appareil, demi, args.batch)
    secondes = time.perf_counter() - debut

    e = extrapolation(combien, secondes, args.corpus)
    print(f'\n{combien} images en {secondes:.1f} s — {e["images_par_seconde"]:.1f} img/s')
    print(f'{args.corpus} images : {e["heures"]:.1f} h, {e["gio"]:.2f} Gio de vecteurs')
    try:
        import torch
        if appareil == 'cuda':
            vram = torch.cuda.max_memory_allocated() / 2 ** 30
            print(f'VRAM réservée au lot de {args.batch} : {vram:.2f} Gio sur 8')
    except ImportError:
        pass
    if e['heures'] > 10:
        parts = int(e['heures'] // 8) + 1
        print(f'\nPlus d\'une nuit : découper en {parts} parts, --part 0/{parts} à '
              f'--part {parts - 1}/{parts}, ou relancer la même ligne — le cache reprend.')
    return 0


def cmd_cache(args) -> int:  # pragma: no cover - demande PyTorch
    dataset = Path(args.dataset).expanduser()
    cache = Path(args.cache).expanduser()
    splits = tuple(s.strip() for s in args.splits.split(',') if s.strip())

    corpus = lire_corpus(dataset, splits)
    if not corpus:
        raise SystemExit(f'aucune image de {splits} dans {dataset}')

    modele, transforme, _, appareil, demi = charger_teacher(args.teacher, args.appareil)
    taille, moyenne, ecart = conf_du_transforme(transforme)
    sig = signature(args.teacher, taille, moyenne, ecart)
    accorder_signature(cache, sig, args.forcer)

    deja = lire_index(cache)
    afaire = tranche(restant(corpus, deja), args.part, args.parts)
    print(f'{len(corpus)} images, {len(deja)} déjà cachées, {len(afaire)} à faire '
          f'(part {args.part}/{args.parts})')
    if not afaire:
        return 0

    index = open(cache / f'index-{args.part}.csv', 'a', newline='', encoding='utf-8')
    numero = len(list(cache.glob(f'emb-{args.part}-*.npy')))
    debut = time.perf_counter()
    try:
        for d in range(0, len(afaire), args.fragment):
            lot = afaire[d:d + args.fragment]
            vecteurs = encoder(modele, transforme, [c for c, _, _ in lot],
                               appareil, demi, args.batch)
            nom = f'emb-{args.part}-{numero:04d}'
            # Le tableau d'abord, l'index ensuite : l'index est la vérité du
            # cache, et une coupure entre les deux ne perd qu'un fragment à
            # recalculer, jamais un vecteur qu'on croirait présent.
            np.save(cache / f'{nom}.npy', vecteurs)
            w = csv.writer(index)
            for i, (c, _, _) in enumerate(lot):
                w.writerow([c, nom, i])
            index.flush()
            numero += 1
            fait = d + len(lot)
            ecoule = time.perf_counter() - debut
            reste = (len(afaire) - fait) / (fait / ecoule) / 3600 if fait else 0
            print(f'  {fait}/{len(afaire)}  {fait / ecoule:.1f} img/s  '
                  f'reste {reste:.1f} h', flush=True)
    finally:
        index.close()
    print(f'\n{cache} — signature {sig["empreinte"]}')
    return 0


def cmd_textes(args) -> int:  # pragma: no cover - demande PyTorch
    cache = Path(args.cache).expanduser()
    sig = lire_signature(cache)
    if sig is None:
        raise SystemExit(f"{cache} n'a pas de signature : lancer `cache` d'abord, "
                         'pour que les références et les images soient du même teacher')

    with open(Path(args.plants).expanduser(), newline='', encoding='utf-8') as f:
        especes = list(csv.DictReader(f))
    if args.etiquettes:
        garde = {l.strip() for l in Path(args.etiquettes).expanduser()
                 .read_text(encoding='utf-8').splitlines() if l.strip()}
        especes = [e for e in especes if e['internal_id'] in garde]

    modele, transforme, tokeniseur, appareil, demi = charger_teacher(
        sig['teacher'], args.appareil)
    import torch

    cles, vecteurs, comptes, textes = [], [], [], []
    for e in especes:
        formulations = phrases(e, args.modele_de_phrase)
        if not formulations:
            continue
        with torch.no_grad():
            jetons = tokeniseur(formulations).to(appareil)
            v = modele.encode_text(jetons).float().cpu().numpy()
        cles.append(e['internal_id'])
        vecteurs.append(moyenne_unitaire(v))
        comptes.append(len(formulations))
        textes.append(' | '.join(formulations))

    tableau = (np.stack(vecteurs).astype(np.float16) if cles
               else np.zeros((0, DIM), dtype=np.float16))
    ecrire_references(cache, 'references-textes', cles, tableau,
                      {'phrases': comptes, 'formulations': textes},
                      {'teacher': sig['teacher'], 'signature': sig['empreinte'],
                       'modele_de_phrase': args.modele_de_phrase,
                       'gabarits': PHRASES[args.modele_de_phrase]})
    sans = len(especes) - len(cles)
    if sans:
        print(f'{sans} espèces sans formulation complète — taxonomie incomplète '
              'dans plants.csv')
    return 0


def cmd_centroides(args) -> int:
    dataset = Path(args.dataset).expanduser()
    cache = Path(args.cache).expanduser()
    sig = lire_signature(cache)
    if sig is None:
        raise SystemExit(f"{cache} n'a pas de signature : lancer `cache` d'abord")

    splits = tuple(s.strip() for s in args.splits.split(',') if s.strip())
    verite = {c: (e, cap) for c, e, cap in lire_corpus(dataset, splits)}
    index = lire_index(cache)
    if not index:
        raise SystemExit(f'{cache} ne contient aucun vecteur')

    # Regrouper par fragment : chacun s'ouvre une fois, et les deux
    # gigaoctets du corpus ne se retrouvent jamais tous en mémoire.
    par_fragment: dict[str, list[tuple[int, str]]] = defaultdict(list)
    for chemin, (fragment, ligne) in index.items():
        if chemin in verite:
            par_fragment[fragment].append((ligne, chemin))

    sommes: dict[str, np.ndarray] = {}
    comptes: dict[str, int] = {}
    lus = 0
    for fragment in sorted(par_fragment):
        tableau = np.load(cache / f'{fragment}.npy')
        lignes = par_fragment[fragment]
        etiquettes = []
        choisies = []
        for ligne, chemin in lignes:
            espece, captive = verite[chemin]
            etiquettes.append(espece)
            choisies.append(ligne)
            if args.captive_a_part and captive == '1':
                etiquettes.append(f'{espece}#captive')
                choisies.append(ligne)
        accumuler(sommes, comptes, etiquettes, tableau[choisies])
        lus += len(lignes)
    print(f'{lus} vecteurs lus dans {len(par_fragment)} fragments')

    cles, tableau, nombres = centroides(sommes, comptes, args.min_images)
    ecarte = len(sommes) - len(cles)
    ecrire_references(cache, 'references-centroides', cles, tableau,
                      {'images': nombres},
                      {'teacher': sig['teacher'], 'signature': sig['empreinte'],
                       'splits': list(splits), 'min_images': args.min_images,
                       'captive_a_part': bool(args.captive_a_part)})
    if ecarte:
        print(f'{ecarte} espèces sous {args.min_images} images — écartées plutôt que '
              'livrées sur une poignée de photos')
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--teacher', default=TEACHER)
    ap.add_argument('--appareil', choices=['cuda', 'cpu'],
                    help='par défaut la carte si elle est là')
    sous = ap.add_subparsers(dest='commande', required=True)

    m = sous.add_parser('mesure', help='le débit du teacher, avant de lancer le corpus')
    m.add_argument('--dataset', default='~/plant-data/dataset-echantillon')
    m.add_argument('--combien', type=int, default=100)
    m.add_argument('--corpus', type=int, default=991926,
                   help='taille du corpus à extrapoler')
    m.add_argument('--batch', type=int, default=32)
    m.set_defaults(fonction=cmd_mesure)

    c = sous.add_parser('cache', help='les embeddings du corpus, repris où ils s\'arrêtent')
    c.add_argument('--dataset', default='~/plant-data/dataset-v8-indoor')
    c.add_argument('--cache', default='~/plant-data/bioclip')
    c.add_argument('--splits', default=','.join(SPLITS))
    c.add_argument('--batch', type=int, default=32, help='8 Go de VRAM : 32 passe')
    c.add_argument('--fragment', type=int, default=8192, help='vecteurs par fichier .npy')
    c.add_argument('--part', type=int, default=0)
    c.add_argument('--parts', type=int, default=1)
    c.add_argument('--forcer', action='store_true',
                   help='écrire malgré une signature différente')
    c.set_defaults(fonction=cmd_cache)

    t = sous.add_parser('textes', help='une référence par espèce, depuis sa taxonomie')
    t.add_argument('--plants', default='../plant_dataset/plants.csv')
    t.add_argument('--cache', default='~/plant-data/bioclip')
    t.add_argument('--etiquettes', help='labels.txt, pour ne garder que ces espèces')
    t.add_argument('--modele-de-phrase', choices=sorted(PHRASES), default='ensemble')
    t.set_defaults(fonction=cmd_textes)

    p = sous.add_parser('centroides', help='une référence par espèce, depuis ses photos')
    p.add_argument('--dataset', default='~/plant-data/dataset-v8-indoor')
    p.add_argument('--cache', default='~/plant-data/bioclip')
    p.add_argument('--splits', default='train',
                   help='jamais le test : une référence tirée des images de mesure '
                        'rendrait le banc faux')
    p.add_argument('--min-images', type=int, default=5)
    p.add_argument('--captive-a-part', action='store_true',
                   help='un second centroïde par espèce sur les seules photos en pot')
    p.set_defaults(fonction=cmd_centroides)

    args = ap.parse_args()
    return args.fonction(args)


if __name__ == '__main__':
    raise SystemExit(main())
