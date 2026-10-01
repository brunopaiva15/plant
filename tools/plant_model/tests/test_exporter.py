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


# --------------------------------------------------------------------------
# Ce que l'application reçoit
# --------------------------------------------------------------------------

from exporter import meta_livree, motif_de_controle, paquet_references


def test_les_references_suivent_l_ordre_d_iris9_synonymes_reunis():
    """Les sorties d'Iris 9 pointent leur espèce, deux noms d'une plante la
    même ; une espèce sans référence n'entre pas dans la fusion — c'est
    `aligner`, ce que le banc a mesuré."""
    labels = ['monstera-deliciosa', 'heptapleurum-arboricola', 'schefflera-arboricola',
              'ficus-lyrata', 'pilea-peperomioides']
    cles = ['schefflera-arboricola', 'monstera-deliciosa', 'monstera-deliciosa#pot',
            'pilea-peperomioides#captive', 'hors-iris9']
    vecteurs = np.eye(5, 4, dtype=np.float32)
    paquet, matrice = paquet_references(cles, vecteurs, labels)
    assert paquet['especes'] == ['monstera-deliciosa', 'schefflera-arboricola', 'pilea-peperomioides']
    assert paquet['iris9'] == [0, 1, 1, -1, 2]
    assert paquet['lignes'] == [1, 0, 0, 2]
    assert paquet['sans_reference'] == ['ficus-lyrata']
    assert paquet['synonymes']['heptapleurum-arboricola'] == 'schefflera-arboricola'
    # La ligne hors d'Iris 9 est retirée, les autres gardent leur vecteur.
    assert matrice.shape == (4, 4)
    np.testing.assert_array_equal(matrice[0], vecteurs[0])
    np.testing.assert_array_equal(matrice[3], vecteurs[3])


def test_le_motif_de_controle_s_ecrit_en_entiers():
    m = motif_de_controle(4)
    assert m.shape == (1, 4, 4, 3) and m.dtype == np.float32
    plat = m.reshape(-1)
    assert plat[0] == 0.0
    assert plat[1] == pytest.approx(7919 % 1000 / 999)
    assert plat[47] == pytest.approx(47 * 7919 % 1000 / 999)


def test_iris10_json_porte_les_reglages_mesures(tmp_path):
    modele = tmp_path / 'iris10.tflite'
    modele.write_bytes(b'modele')
    refs = tmp_path / 'iris10-references.bin'
    refs.write_bytes(np.zeros((3, 4), dtype='<f2').tobytes())
    paquet = {'especes': ['a', 'b'], 'lignes': [0, 0, 1], 'iris9': [0, 1, -1],
              'synonymes': {}, 'sans_reference': ['c']}
    controle = np.arange(20, dtype=np.float32)[None] / 20
    m = meta_livree({'student': 'fastvit_sa12', 'entree': 320, 'epoque': 10}, modele, refs,
                    paquet, 4, 'centroide', controle)
    assert m['version'] == '10'
    assert m['input_size'] == 320 and m['dim'] == 4
    assert m['accept_threshold'] == 0.85 and m['min_margin'] == 0.25
    assert m['fusion'] == {'poids_iris9': 0.5, 'plancher': 1e-6}
    assert m['temperature'] == 100.0
    assert m['references']['lignes'] == 3 and m['references']['octets'] == 24
    assert len(m['controle']['vecteur']) == 16
    assert 'sans_reference' not in m
    json.dumps(m)
