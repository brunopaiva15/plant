"""Pl@ntNet-300K rangé en corpus de distillation.

Ce qui est testé ici est ce qui abîmerait **silencieusement** la suite : un
identifiant inventé qui se ferait passer pour une espèce du catalogue, une
image du split de test entrée dans l'entraînement, un `splits.csv` qui
annonce des fichiers absents, une reprise qui recommence tout.
"""
import csv

import pytest

from plantnet_corpus import (a_extraire, destination, ecrire, ecrire_splits,
                             identite, rattacher, reduire, restant)


META = {
    'a': {'split': 'train', 'species_id': '1355932', 'license': 'cc-by-sa'},
    'b': {'split': 'test', 'species_id': '1355932', 'license': 'cc-by-sa'},
    'c': {'split': 'train', 'species_id': '9999', 'license': 'cc-by-nc'},
    'd': {'split': 'val', 'species_id': '9999', 'license': 'cc0'},
}


# --------------------------------------------------------------------------
# Le rattachement au catalogue
# --------------------------------------------------------------------------

def test_une_espece_du_catalogue_garde_notre_identifiant():
    r = rattacher({'1355932': 'Lactuca virosa L.'}, {'Lactuca virosa': 'lactuca-virosa'})
    assert identite('1355932', r) == 'lactuca-virosa'


def test_une_espece_inconnue_est_prefixee_pas_inventee():
    """Sans le préfixe, `bioclip.py centroides` bâtirait une référence sous
    un identifiant qui n'existe pas dans le catalogue."""
    assert identite('9999', {}) == 'pn:9999'


def test_le_rattachement_ignore_lauteur_du_binome():
    r = rattacher({'1': 'Salvia × floriferior Hort.'}, {'Salvia × floriferior': 'salvia-x'})
    assert r == {'1': 'salvia-x'}


# --------------------------------------------------------------------------
# Ce qu'on extrait, et ce qu'on refuse
# --------------------------------------------------------------------------

def test_le_split_de_test_est_refuse():
    """Il est le second terrain de mesure : entraîner dessus le rend muet,
    et rien dans les chiffres ne le dirait."""
    with pytest.raises(SystemExit):
        a_extraire(META, ('train', 'test'))


def test_seul_le_split_demande_sort():
    assert [l[3] for l in a_extraire(META, ('train',))] == ['1355932']


def test_une_licence_hors_collecte_est_ecartee():
    """`c` est en cc-by-nc : entraîner dessus laisserait une dette invisible
    dans les poids (§ 4.1)."""
    tires = a_extraire(META, ('train', 'val'))
    assert {l[3] for l in tires} == {'1355932', '9999'}
    assert len(tires) == 2  # `c` est écartée, `d` passe


def test_le_membre_et_la_destination_se_repondent():
    (membre, relatif, split, sid), = a_extraire(META, ('train',))
    assert membre == 'plantnet_300K/images/train/1355932/a.jpg'
    assert relatif == destination(sid, 'a') == 'images/1355932/a.jpg'
    assert split == 'train'


# --------------------------------------------------------------------------
# La reprise
# --------------------------------------------------------------------------

def test_une_image_deja_ecrite_nest_pas_retiree(tmp_path):
    lignes = a_extraire(META, ('train', 'val'))
    ecrire(tmp_path, lignes[0][1], b'x')
    assert restant(lignes, tmp_path) == lignes[1:]


def test_ecrire_ne_laisse_pas_de_fichier_partiel(tmp_path):
    """`restant` lit la présence du fichier : un JPEG tronqué passerait pour
    fait. Le renommage rend l'écriture atomique."""
    ecrire(tmp_path, 'images/1/a.jpg', b'x')
    assert (tmp_path / 'images/1/a.jpg').read_bytes() == b'x'
    assert list(tmp_path.rglob('*.part')) == []


# --------------------------------------------------------------------------
# Le manifeste
# --------------------------------------------------------------------------

def lire_splits(dossier):
    with open(dossier / 'splits.csv', newline='', encoding='utf-8') as f:
        return list(csv.DictReader(f))


def test_splits_ne_liste_que_les_images_presentes(tmp_path):
    """Une ligne sans fichier ferait un jeu plus petit qu'annoncé, et
    `distiller.py` changerait ses pas par époque sans le dire."""
    lignes = a_extraire(META, ('train', 'val'))
    ecrire(tmp_path, lignes[0][1], b'x')
    assert ecrire_splits(lignes, {}, tmp_path) == 1
    lus = lire_splits(tmp_path)
    assert [r['path'] for r in lus] == [lignes[0][1]]


def test_splits_porte_les_colonnes_que_lisent_bioclip_et_distiller(tmp_path):
    lignes = a_extraire(META, ('train',))
    ecrire(tmp_path, lignes[0][1], b'x')
    ecrire_splits(lignes, {'1355932': 'lactuca-virosa'}, tmp_path)
    r, = lire_splits(tmp_path)
    assert r['internal_plant_id'] == 'lactuca-virosa'
    assert r['split'] == 'train' and r['captive'] == '0'


# --------------------------------------------------------------------------
# La réduction
# --------------------------------------------------------------------------

def image(taille):
    import io
    from PIL import Image
    t = io.BytesIO()
    Image.new('RGB', taille, (10, 120, 30)).save(t, format='PNG')
    return t.getvalue()


def test_le_cote_long_descend_a_la_taille():
    import io
    from PIL import Image
    im = Image.open(io.BytesIO(reduire(image((800, 600)), 320)))
    assert max(im.size) == 320 and im.size == (320, 240)


def test_une_petite_image_nest_pas_agrandie():
    """L'agrandir ne lui ajoute rien : le teacher l'encoderait pareil, pour
    quatre fois le disque."""
    import io
    from PIL import Image
    im = Image.open(io.BytesIO(reduire(image((150, 100)), 320)))
    assert im.size == (150, 100)


def test_la_sortie_est_un_jpeg_rgb():
    import io
    from PIL import Image
    im = Image.open(io.BytesIO(reduire(image((400, 400)), 320)))
    assert im.format == 'JPEG' and im.mode == 'RGB'


# --------------------------------------------------------------------------
# Un lecteur par fil
# --------------------------------------------------------------------------

def test_chaque_fil_ouvre_sa_propre_archive():
    """`zipfile` et `RemoteZip` partagent un objet fichier et s'y déplacent :
    huit fils sur la même archive se volent leur position et rendent les
    octets d'une autre image, sans lever d'erreur."""
    import threading
    from concurrent.futures import ThreadPoolExecutor

    from plantnet_corpus import par_fil

    ouvertures = []
    verrou = threading.Lock()

    def ouvrir():
        with verrou:
            ouvertures.append(threading.current_thread().name)
        return lambda chemin: threading.current_thread().name.encode()

    lire = par_fil(ouvrir)
    with ThreadPoolExecutor(max_workers=4) as pool:
        rendus = set(pool.map(lambda _: lire('x'), range(200)))
    assert len(ouvertures) == len(set(ouvertures)) == len(rendus)


def test_un_fil_nouvre_larchive_quune_fois():
    """À distance, l'ouverture relit trente mégaoctets de répertoire
    central : la payer à chaque image coûterait plus que les images."""
    from plantnet_corpus import par_fil
    compte = []
    lire = par_fil(lambda: (compte.append(1), lambda c: b'x')[1])
    for _ in range(5):
        assert lire('a') == b'x'
    assert len(compte) == 1


# --------------------------------------------------------------------------
# Deux passes sur le même dossier
# --------------------------------------------------------------------------

def test_une_passe_vivante_bloque_la_suivante(tmp_path):
    """`tmux new` refuse une session existante, et les lignes suivantes
    partent alors dans le terminal : deux extractions tirent les mêmes
    images et divisent le débit par deux sans rien signaler."""
    from plantnet_corpus import verrou_vivant
    v = tmp_path / '.passe-en-cours'
    v.touch()
    assert verrou_vivant(v, maintenant=v.stat().st_mtime + 10)


def test_une_passe_tuee_ne_bloque_pas_le_dossier(tmp_path):
    """Le verrou est un battement de cœur : sans quoi un Ctrl-C laisserait
    le dossier inutilisable jusqu'à ce qu'on pense à le nettoyer."""
    from plantnet_corpus import verrou_vivant
    v = tmp_path / '.passe-en-cours'
    v.touch()
    assert not verrou_vivant(v, maintenant=v.stat().st_mtime + 300)


def test_un_dossier_neuf_nest_pas_verrouille(tmp_path):
    from plantnet_corpus import verrou_vivant
    assert not verrou_vivant(tmp_path / '.passe-en-cours')


# --------------------------------------------------------------------------
# Quand l'archive ne s'ouvre pas
# --------------------------------------------------------------------------

def test_un_429_dit_quoi_faire_pas_ou_ca_a_cassé():
    """Une trace de dix cadres ne dit pas quoi faire. Ici il n'y a qu'une
    chose à faire, et elle tient en deux commandes."""
    from plantnet_corpus import diagnostic
    m = diagnostic(RuntimeError('429 Client Error: TOO MANY REQUESTS for url: …'),
                   '/data/plantnet_300K.zip', '/data/plantnet-300k')
    assert 'curl' in m and '--archive /data/plantnet_300K.zip' in m


def test_une_autre_erreur_nest_pas_deguisee_en_429():
    from plantnet_corpus import diagnostic
    m = diagnostic(FileNotFoundError('pas là'), '/z.zip', '/s')
    assert 'curl' not in m and 'FileNotFoundError' in m
