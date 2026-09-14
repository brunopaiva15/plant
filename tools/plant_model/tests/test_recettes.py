"""Trois recettes de prétraitement, et ce qui les sépare vraiment.

Le réseau apprend sur des carrés de 288 px étirés à 366 ; l'application lui
donne des carrés de 448 px réduits à 366. Ces tests fixent l'ordre des
opérations de chaque recette, parce que c'est l'ordre — pas le filtre — qui
fait l'écart.
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from recettes import (_carre, _reduire_cadre, echantillon_test, recette_application,  # noqa: E402
                      recette_corrigee, recette_entrainement, urls_du_manifeste)


def _photo(w, h):
    """Un dégradé, pour que réduire ne soit pas une opération neutre."""
    a = np.zeros((h, w, 3), dtype=np.uint8)
    a[:, :, 0] = np.linspace(0, 255, w, dtype=np.uint8)[None, :]
    a[:, :, 1] = np.linspace(0, 255, h, dtype=np.uint8)[:, None]
    return Image.fromarray(a)


def test_le_carre_prend_le_petit_cote():
    assert _carre(_photo(400, 300)).size == (300, 300)
    assert _carre(_photo(300, 400)).size == (300, 300)


def test_reduire_le_cadre_vise_le_grand_cote():
    assert _reduire_cadre(_photo(4000, 3000), 384, Image.BOX).size == (384, 288)


def test_une_image_deja_petite_nest_pas_agrandie():
    assert _reduire_cadre(_photo(300, 200), 384, Image.BOX).size == (300, 200)


def test_les_trois_recettes_rendent_la_meme_forme():
    img = _photo(4032, 3024)
    for f in (recette_entrainement, recette_application, recette_corrigee):
        assert f(img, 366, 320).shape == (320, 320, 3)


def test_lapplication_et_lentrainement_different_sur_un_original():
    # Tout le sujet : l'ordre des opérations, pas le filtre.
    img = _photo(4032, 3024)
    a = recette_entrainement(img, 366, 320)
    b = recette_application(img, 366, 320)
    assert not np.array_equal(a, b), 'si elles coïncidaient, il n\'y aurait rien à mesurer'


def test_la_correction_se_rapproche_de_lentrainement():
    # Même ordre et même taille intermédiaire que la collecte : il ne reste
    # que le filtre pour les séparer.
    img = _photo(4032, 3024)
    a = recette_entrainement(img, 366, 320).astype(float)
    b = recette_application(img, 366, 320).astype(float)
    c = recette_corrigee(img, 366, 320).astype(float)
    assert np.abs(c - a).mean() < np.abs(b - a).mean()


def test_sur_une_image_du_jeu_les_recettes_coincident():
    """384 px de grand côté : le carré vaut 288, la condition `> 448` de
    l'application est fausse, la moyenne de zone est sautée. C'est pourquoi
    la mesure doit repartir des originaux et non du jeu stocké."""
    img = _photo(384, 288)
    a = recette_entrainement(img, 366, 320)
    b = recette_application(img, 366, 320)
    assert np.array_equal(a, b)


def test_lechantillon_ne_prend_que_le_test(tmp_path):
    (tmp_path / 'splits.csv').write_text(
        'path,species,internal_plant_id,split,group,captive\n'
        'a/0.jpg,A,a-un,train,0,0\n'
        'a/1.jpg,A,a-un,test,1,0\n'
        'a/2.jpg,A,a-un,val,2,0\n'
        'a/3.jpg,A,a-un,test,3,0\n', encoding='utf-8')
    tire = echantillon_test(tmp_path, 10, 1)
    assert sorted(p for p, _ in tire) == ['a/1.jpg', 'a/3.jpg']


def test_les_urls_viennent_du_manifeste(tmp_path):
    (tmp_path / 'manifest.jsonl').write_text(
        '{"path": "a/0.jpg", "image_url": "http://x/0.jpg"}\n'
        '\n'
        '{"path": "a/1.jpg", "image_url": ""}\n'
        '{"path": "a/2.jpg", "image_url": "http://x/2.jpg"}\n', encoding='utf-8')
    assert urls_du_manifeste(tmp_path) == {'a/0.jpg': 'http://x/0.jpg', 'a/2.jpg': 'http://x/2.jpg'}


def test_sans_manifeste_loutil_ne_devine_pas(tmp_path):
    assert urls_du_manifeste(tmp_path) == {}
