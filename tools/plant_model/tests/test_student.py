"""Le prétraitement du student, sans onnxruntime ni modèle.

Ce qui est testé ici est ce qui rendrait le plancher **faux sans le dire** :
un recadrage confondu avec l'autre, une normalisation passée deux fois, un
cache qui laisserait mélanger deux recadrages sous la même clé.
"""
import numpy as np
import pytest
from PIL import Image

from student import ENTREE, lire_banc, preparer, signature_student


def image(tmp_path, largeur, hauteur, couleur=(10, 200, 30)):
    chemin = tmp_path / f'{largeur}x{hauteur}.jpg'
    Image.new('RGB', (largeur, hauteur), couleur).save(chemin, quality=95)
    return str(chemin)


def test_la_sortie_est_nchw_en_224(tmp_path):
    x = preparer(image(tmp_path, 640, 480))
    assert x.shape == (1, 3, ENTREE, ENTREE)


def test_les_valeurs_restent_entre_zero_et_un(tmp_path):
    """La normalisation ImageNet est repliée dans le graphe : l'appliquer ici
    la passerait deux fois, ce qui ne plante pas et rend faux."""
    x = preparer(image(tmp_path, 300, 300, (255, 255, 255)))
    assert x.min() >= 0.0 and x.max() <= 1.0
    assert x.max() == pytest.approx(1.0, abs=0.02)


def test_le_recadrage_carre_et_letirement_ne_donnent_pas_la_meme_image(tmp_path):
    """Sur une image très allongée, les deux chaînes voient autre chose — et
    c'est pourquoi le recadrage est une variable qu'on mesure."""
    from PIL import ImageDraw
    chemin = tmp_path / 'bande.jpg'
    im = Image.new('RGB', (600, 200), (0, 0, 0))
    ImageDraw.Draw(im).rectangle([0, 0, 100, 200], fill=(255, 255, 255))
    im.save(chemin, quality=95)
    carre = preparer(str(chemin), 'carre')
    etire = preparer(str(chemin), 'etire')
    assert not np.allclose(carre, etire)


def test_une_image_carree_est_traitee_pareil_par_les_deux(tmp_path):
    """Le recadrage ne peut différer que sur ce qui n'est pas carré."""
    chemin = image(tmp_path, 300, 300)
    assert np.allclose(preparer(chemin, 'carre'), preparer(chemin, 'etire'), atol=1e-6)


def test_le_recadrage_prend_le_centre(tmp_path):
    """Un bord coloré à gauche d'une image large doit disparaître du carré
    central, sans quoi « carre » ne recadre pas où il dit."""
    from PIL import ImageDraw
    chemin = tmp_path / 'bord.jpg'
    im = Image.new('RGB', (600, 200), (0, 0, 0))
    ImageDraw.Draw(im).rectangle([0, 0, 50, 200], fill=(255, 0, 0))
    im.save(chemin, quality=95)
    assert preparer(str(chemin), 'carre')[0, 0].max() < 0.2


def test_le_recadrage_appartient_a_la_signature():
    """Deux passes au même modèle et au recadrage différent rendent des
    vecteurs qui ne se comparent pas."""
    a = signature_student('flora.onnx', 'carre')
    b = signature_student('flora.onnx', 'etire')
    assert a['empreinte'] != b['empreinte']


def test_deux_modeles_ne_partagent_pas_une_empreinte():
    a = signature_student('flora_fp32.onnx', 'carre')
    b = signature_student('flora_fp16.onnx', 'carre')
    assert a['empreinte'] != b['empreinte']


def test_le_banc_se_lit_sans_doublon(tmp_path):
    """Une observation peut apparaître dans deux tranches ; l'encoder deux
    fois coûterait le double pour le même vecteur."""
    import csv
    chemin = tmp_path / 'banc.csv'
    with open(chemin, 'w', newline='', encoding='utf-8') as f:
        w = csv.writer(f)
        w.writerow(['tranche', 'chemin', 'verite', 'groupe', 'captive'])
        w.writerow(['indoor', '/a.jpg', 'x', 'g', '0'])
        w.writerow(['multi', '/a.jpg', 'x', 'g', '0'])
        w.writerow(['outdoor', '/b.jpg', 'y', 'g', '0'])
    assert lire_banc(chemin) == ['/a.jpg', '/b.jpg']


def test_le_banc_se_restreint_aux_tranches_demandees(tmp_path):
    import csv
    chemin = tmp_path / 'banc.csv'
    with open(chemin, 'w', newline='', encoding='utf-8') as f:
        w = csv.writer(f)
        w.writerow(['tranche', 'chemin', 'verite', 'groupe', 'captive'])
        w.writerow(['indoor', '/a.jpg', 'x', 'g', '0'])
        w.writerow(['multi', '/b.jpg', 'y', 'g', '0'])
    assert lire_banc(chemin, {'indoor'}) == ['/a.jpg']


def test_letalement_voit_un_cone_referme():
    """Le diagnostic : des vecteurs tous semblables rendent un cosinus moyen
    élevé, des vecteurs bien répartis un cosinus proche de zéro."""
    from student import etalement
    alea = np.random.default_rng(0)
    repartis = alea.standard_normal((200, 64)).astype(np.float32)
    # Le bruit se somme sur les 64 dimensions : à 0,02 par axe sa norme vaut
    # 0,16 contre 1 pour le signal, donc le cône reste serré.
    serres = np.zeros((200, 64), dtype=np.float32)
    serres[:, 0] = 1.0
    serres += 0.02 * alea.standard_normal((200, 64)).astype(np.float32)
    assert etalement(repartis) < 0.1
    assert etalement(serres) > 0.8


def test_letalement_ignore_la_diagonale():
    """Un vecteur comparé à lui-même vaut 1 et gonflerait la moyenne."""
    from student import etalement
    v = np.eye(4, dtype=np.float32)
    assert etalement(v) == pytest.approx(0.0, abs=1e-6)
