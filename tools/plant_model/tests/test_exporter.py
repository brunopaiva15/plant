"""L'export au format du téléphone, sans torch ni LiteRT.

Ce qui est testé ici est ce qui ferait livrer un fichier faux sans le dire :
un format sans réglage, une recette
d'entrée qui ne dit pas ce que le modèle attend, un banc encodé que
`voisins.py` ne saurait pas relire.
"""
import json
import numpy as np
import pytest

from exporter import cosinus_par_ligne, ecrire_banc, metadonnees, recette, reglage_du_format

def test_la_recette_vient_du_point_de_controle(tmp_path):
    (tmp_path / 'etat.json').write_text(json.dumps(
        {'epoque': 10, 'student': 'fastvit_sa12', 'entree': 320, 'calendrier': 'cosinus'}))
    assert recette(tmp_path) == {'student': 'fastvit_sa12', 'entree': 320, 'epoque': 10}


def test_un_etat_ancien_a_tourne_a_224(tmp_path):
    (tmp_path / 'etat.json').write_text(json.dumps({'epoque': 10, 'student': 'fastvit_sa12'}))
    assert recette(tmp_path)['entree'] == 224


def test_chaque_format_a_son_reglage():
    """Le fp32 est le fichier du convertisseur ; les deux autres en sont
    tirés par le quantificateur, qui lit un .tflite de n'importe quelle
    version de litert-torch."""
    assert reglage_du_format('fp32') is None
    assert reglage_du_format('fp16') == {'poids_seuls': 16, 'algorithme': 'float_casting'}
    assert reglage_du_format('int8') == {'recette': 'dynamic_wi8_afp32'}
    assert reglage_du_format('int8w') == {'recette': 'weight_only_wi8_afp32'}
    with pytest.raises(ValueError):
        reglage_du_format('fp8')


def test_les_metadonnees_disent_ce_que_le_modele_attend(tmp_path):
    f = tmp_path / 'iris10-fp16.tflite'
    f.write_bytes(b'modele')
    m = metadonnees({'student': 'fastvit_sa12', 'entree': 320, 'epoque': 10}, 'fp16', f)
    assert m['entree'] == [1, 320, 320, 3] and m['sortie'] == [1, 1024]
    assert m['pretraitement']['ordre'] == 'NHWC' and m['pretraitement']['valeurs'] == '0-1'
    assert m['octets'] == 6 and len(m['sha256']) == 64


def test_le_cosinus_par_ligne():
    a = np.array([[1.0, 0.0], [0.0, 2.0]])
    b = np.array([[2.0, 0.0], [1.0, 0.0]])
    assert np.allclose(cosinus_par_ligne(a, b), [1.0, 0.0])


def test_le_banc_encode_se_relit_comme_une_epoque(tmp_path):
    from student import signature_student
    from voisins import lire_embeddings
    chemins = ['/banc/a.jpg', '/banc/b.jpg']
    v = np.eye(2, 1024, dtype=np.float32)
    ecrire_banc(tmp_path / 'banc-fp16', signature_student('x-tflite-fp16', 'carre', entree=320),
                chemins, v)
    gardes, lus = lire_embeddings(tmp_path / 'banc-fp16', chemins)
    assert gardes == [0, 1] and np.allclose(lus, v)
