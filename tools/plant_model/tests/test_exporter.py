"""L'export au format du téléphone, sans torch ni LiteRT.

Ce qui est testé ici est ce qui ferait livrer un fichier faux sans le dire :
une option de format ignorée (le float16 qui sort en int8), une recette
d'entrée qui ne dit pas ce que le modèle attend, un banc encodé que
`voisins.py` ne saurait pas relire.
"""
import json
from types import SimpleNamespace

import numpy as np
import pytest

from exporter import cosinus_par_ligne, ecrire_banc, metadonnees, options_du_format, recette

TF = SimpleNamespace(lite=SimpleNamespace(Optimize=SimpleNamespace(DEFAULT='defaut')),
                     float16='f16')


def test_la_recette_vient_du_point_de_controle(tmp_path):
    (tmp_path / 'etat.json').write_text(json.dumps(
        {'epoque': 10, 'student': 'fastvit_sa12', 'entree': 320, 'calendrier': 'cosinus'}))
    assert recette(tmp_path) == {'student': 'fastvit_sa12', 'entree': 320, 'epoque': 10}


def test_un_etat_ancien_a_tourne_a_224(tmp_path):
    (tmp_path / 'etat.json').write_text(json.dumps({'epoque': 10, 'student': 'fastvit_sa12'}))
    assert recette(tmp_path)['entree'] == 224


def test_le_float16_passe_par_un_dictionnaire_imbrique():
    """À plat, `target_spec.supported_types` est ignoré sans erreur et le
    fichier sort quantifié en int8 : 12 Mo au lieu de 23."""
    o = options_du_format('fp16', TF)
    assert o == {'optimizations': ['defaut'], 'target_spec': {'supported_types': ['f16']}}
    assert 'target_spec.supported_types' not in o


def test_fp32_sans_option_et_int8_sans_type():
    assert options_du_format('fp32', TF) == {}
    assert options_du_format('int8', TF) == {'optimizations': ['defaut']}
    with pytest.raises(ValueError):
        options_du_format('fp8', TF)


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
