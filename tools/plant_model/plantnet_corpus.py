#!/usr/bin/env python3
"""Le jeu de Pl@ntNet-300K comme corpus de distillation, sans ses étiquettes.

**Pourquoi ce script existe.** Un student distillé apprend à reproduire le
vecteur du teacher, pas à nommer une espèce. Ses images n'ont donc **pas
besoin d'étiquettes** : n'importe quelle photo de plante est utilisable telle
quelle, sans aligner 1 081 classes sur nos 1 569, sans décider quoi faire des
espèces inconnues, sans hériter du bruit d'annotation. Ce qui aurait été un
chantier de catalogue pour Iris 9 est ici une copie de fichiers.

**Et pourquoi ce corpus-là.** Le § 5 de `docs/14` a mesuré que ce qui sépare
Iris 9 de PlantNet-300K n'est pas le cadrage — sur les seules plantes
entières l'écart se resserre de 7,75 à 4,8 points mais ne s'inverse pas —
c'est la **provenance des images**. Notre corpus vient de GBIF et
d'iNaturalist, le leur de photos d'utilisateurs en extérieur. Ces
243 000 images sont exactement le monde où notre corpus est le plus mince.

Ce que ça ne fait pas : rendre Iris 10 plus savant que BioCLIP. Le plafond
reste le teacher. Ça rend la **copie plus fidèle là où elle n'a jamais été
testée**.

**Le split `test` de Pl@ntNet est refusé, et ce n'est pas négociable.** Il
sert déjà de second terrain de mesure (§ 5 de `docs/14`, la mesure
symétrique), et c'est le seul dont on dispose qui ne vienne pas de notre
propre monde. L'entraîner dessus le détruirait sans rien signaler.

**Ce script ne touche pas au GPU.** Il peut donc tourner pendant une
distillation. L'encodage par le teacher, lui, le demande : c'est
`bioclip.py cache`, et il attend son tour.

    python3 plantnet_corpus.py --sortie ~/plant-data/plantnet-300k
    python3 plantnet_corpus.py --sortie ~/plant-data/plantnet-300k \\
        --archive ~/plant-data/plantnet_300K.zip

Sans `--archive` local, l'archive est lue **à distance** par plages : rien
n'est téléchargé en entier, mais chaque image coûte une requête. Avec le zip
sur disque, c'est une lecture locale — plus rapide, contre 29,5 Gio.

La sortie est un jeu au format de `tools/plant_dataset` : `images/` et un
`splits.csv`, que `bioclip.py cache` et `distiller.py` lisent sans une ligne
de changement.
"""
import argparse
import csv
import io
import json
import threading
import time
from pathlib import Path

from plantnet_avis import (ARCHIVE, LICENCES, METADONNEES, NOMS, binome,
                           lecteur, membre, noms_du_catalogue, telecharger)

# Pl@ntNet mesure jusqu'à 800 px de côté. Le teacher comme le student entrent
# à 224 ; garder 320 laisse de quoi recadrer et augmenter, et divise le disque
# par quatre. Le § « Pièges » de `docs/10` : le disque d'Ubuntu est un fichier
# sur C:, donc trente gigaoctets de plus ne sont pas neutres.
TAILLE = 320


# --------------------------------------------------------------------------
# Ce qu'on extrait
# --------------------------------------------------------------------------

def rattacher(noms: dict[str, str], catalogue: dict[str, str]) -> dict[str, str]:
    """{species_id de Pl@ntNet: notre identifiant}, sur tout le catalogue.

    Plus large que `especes_communes` de `plantnet_avis.py`, qui se limite
    aux classes qu'Iris expose : ici on ne mesure pas, on range. Une espèce
    du catalogue non exposée par Iris 9 est justement ce qu'Iris 10 peut
    apprendre à retrouver.
    """
    return {sid: catalogue[binome(n)] for sid, n in noms.items()
            if binome(n) in catalogue}


def identite(species_id: str, rattachements: dict[str, str]) -> str:
    """Notre identifiant, ou `pn:<id>` pour une espèce hors catalogue.

    Le préfixe est celui de `plantnet_avis.py`, et il porte la même promesse :
    une clé `pn:` ne se confond jamais avec une des nôtres. La distillation
    ignore cette colonne — elle ne lit que le chemin — mais `bioclip.py
    centroides` ne l'ignorerait pas, et un identifiant inventé s'y glisserait
    comme une espèce du catalogue.
    """
    return rattachements.get(species_id, f'pn:{species_id}')


def destination(species_id: str, cle: str) -> str:
    """Le chemin relatif de l'image dans le jeu produit."""
    return f'images/{species_id}/{cle}.jpg'


def a_extraire(metadonnees: dict[str, dict], splits: tuple[str, ...],
               licences: set[str] = LICENCES) -> list[tuple[str, str, str, str]]:
    """(membre, destination, split, species_id) pour les images à tirer.

    Le filtre de licence est celui de la collecte (§ 4.1) : entraîner sur des
    images qu'on ne pourrait pas redistribuer laisserait une dette invisible
    dans les poids, qu'aucune mesure ne révélerait.
    """
    if 'test' in splits:
        raise SystemExit(
            "le split `test` de Pl@ntNet est notre second terrain de mesure : "
            "l'entraîner dessus le rendrait muet. Voir l'en-tête de ce script.")
    sortie = []
    for cle, ligne in metadonnees.items():
        if ligne.get('split') not in splits or ligne.get('license') not in licences:
            continue
        sid = ligne.get('species_id')
        sortie.append((membre(cle, ligne), destination(sid, cle),
                       ligne['split'], sid))
    return sortie


def restant(lignes: list[tuple[str, str, str, str]],
            sortie: Path) -> list[tuple[str, str, str, str]]:
    """Celles dont le fichier n'est pas déjà écrit.

    Deux cent quarante mille lectures par plage ne tiennent pas d'un bloc :
    la passe sera relancée, et la relancer depuis zéro coûterait tout.
    """
    return [l for l in lignes if not (sortie / l[1]).exists()]


# --------------------------------------------------------------------------
# La réduction
# --------------------------------------------------------------------------

def reduire(octets: bytes, taille: int = TAILLE) -> bytes:
    """L'image en JPEG, côté long ramené à `taille`, jamais agrandie.

    Agrandir une petite image ne lui ajoute rien et ferait croire à une
    résolution qu'elle n'a pas — le teacher l'encoderait exactement pareil,
    pour quatre fois le disque.
    """
    from PIL import Image
    im = Image.open(io.BytesIO(octets))
    im = im.convert('RGB')
    if max(im.size) > taille:
        im.thumbnail((taille, taille), Image.BICUBIC)
    tampon = io.BytesIO()
    im.save(tampon, format='JPEG', quality=90)
    return tampon.getvalue()


def ecrire(sortie: Path, relatif: str, octets: bytes) -> None:
    """Écrit l'image, par un fichier temporaire renommé.

    Une écriture interrompue laisserait un JPEG tronqué que `restant` verrait
    comme fait : le renommage est atomique, donc un fichier présent est un
    fichier entier.
    """
    chemin = sortie / relatif
    chemin.parent.mkdir(parents=True, exist_ok=True)
    partiel = chemin.with_suffix('.part')
    partiel.write_bytes(octets)
    partiel.rename(chemin)


# --------------------------------------------------------------------------
# Le manifeste
# --------------------------------------------------------------------------

def ecrire_splits(lignes: list[tuple[str, str, str, str]],
                  rattachements: dict[str, str], sortie: Path) -> int:
    """`splits.csv` au format de `tools/plant_dataset`, sur les seules images
    réellement écrites.

    Une ligne sans fichier ferait un jeu plus petit qu'annoncé, et
    `distiller.py` changerait son nombre de pas par époque sans le dire.
    """
    ecrites = [l for l in lignes if (sortie / l[1]).exists()]
    with open(sortie / 'splits.csv', 'w', newline='', encoding='utf-8') as f:
        w = csv.writer(f)
        w.writerow(['internal_plant_id', 'path', 'split', 'captive'])
        for _, relatif, split, sid in ecrites:
            # `captive` reste à 0 : Pl@ntNet est du terrain, et c'est
            # précisément ce que notre corpus a de plus mince.
            w.writerow([identite(sid, rattachements), relatif, split, '0'])
    return len(ecrites)


def par_fil(ouvrir):
    """Un lecteur par fil d'exécution, ouvert à la première lecture.

    **`zipfile` et `RemoteZip` ne sont pas réentrants.** Les deux partagent un
    seul objet fichier et se déplacent dedans ; huit fils sur la même archive
    ne lèvent pas d'erreur, ils se volent leur position et rendent des octets
    d'une autre image. Le désastre serait silencieux : des JPEG valides, au
    mauvais endroit, encodés sans broncher par le teacher.

    L'ouverture est paresseuse parce qu'elle coûte : à distance, chaque fil
    relit le répertoire central de l'archive, trente mégaoctets.
    """
    local = threading.local()

    def lire(chemin):
        if not hasattr(local, 'lire'):
            local.lire = ouvrir()
        return local.lire(chemin)

    return lire


def main() -> int:  # pragma: no cover - réseau et disque
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--sortie', default='~/plant-data/plantnet-300k')
    ap.add_argument('--archive', default=ARCHIVE,
                    help="le zip Zenodo, local s'il existe, distant sinon")
    ap.add_argument('--cache', default='~/plant-data/plantnet',
                    help='où sont mis les deux fichiers de métadonnées')
    ap.add_argument('--plants', default='../plant_dataset/plants.csv')
    ap.add_argument('--splits', default='train',
                    help="splits de Pl@ntNet à tirer ; `test` est refusé")
    ap.add_argument('--taille', type=int, default=TAILLE)
    ap.add_argument('--fils', type=int, default=8,
                    help='lectures en parallèle ; au-delà de 16 Zenodo ferme')
    args = ap.parse_args()

    sortie = Path(args.sortie).expanduser()
    sortie.mkdir(parents=True, exist_ok=True)
    cache = Path(args.cache).expanduser()

    meta = json.loads(telecharger(METADONNEES, cache).read_text())
    noms = json.loads(telecharger(NOMS, cache).read_text())
    rattachements = rattacher(noms, noms_du_catalogue(Path(args.plants).expanduser()))

    splits = tuple(s.strip() for s in args.splits.split(',') if s.strip())
    tout = a_extraire(meta, splits)
    afaire = restant(tout, sortie)
    connues = sum(1 for _, _, _, sid in tout if sid in rattachements)
    print(f'{len(tout)} images sous licence sur les splits {splits}, '
          f'{connues} d\'espèces du catalogue, {len(afaire)} à tirer')
    if not afaire:
        print('tout est déjà là')

    source = (args.archive if str(args.archive).startswith('http')
              else str(Path(args.archive).expanduser()))
    lire = par_fil(lambda: lecteur(source)[0])
    debut, faites, sautees = time.perf_counter(), 0, 0

    def tirer(ligne):
        octets = lire(ligne[0])
        if octets is None:
            return ligne, False
        try:
            ecrire(sortie, ligne[1], reduire(octets, args.taille))
        except Exception:
            return ligne, False
        return ligne, True

    from concurrent.futures import ThreadPoolExecutor
    with ThreadPoolExecutor(max_workers=args.fils) as pool:
        for _, bonne in pool.map(tirer, afaire):
            faites += 1
            sautees += 0 if bonne else 1
            if faites % 2000 == 0:
                vitesse = faites / (time.perf_counter() - debut)
                reste = (len(afaire) - faites) / max(vitesse, 1e-6) / 60
                print(f'  {faites}/{len(afaire)}  {vitesse:.1f} img/s  '
                      f'{sautees} sautées  reste {reste:.0f} min', flush=True)

    ecrites = ecrire_splits(tout, rattachements, sortie)
    print(f'\n{sortie} — {ecrites} images, {sautees} sautées cette passe')
    print('relancer la même commande reprend les manquantes ; puis, GPU libre :')
    print(f'  python3 bioclip.py cache --dataset {args.sortie} '
          f'--cache ~/plant-data/bioclip --batch 64')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
