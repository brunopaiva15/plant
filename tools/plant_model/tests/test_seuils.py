"""Le seuil d'affirmation d'Iris 10 et de la fusion.

Ce qui est testé ici est ce qui ferait livrer un seuil trop hardi sans le
dire : une fusion qui ne serait pas une distribution (0,70 n'y voudrait rien
dire), une marge oubliée, une affirmation hors répertoire non comptée, un
seuil recommandé qui battrait Iris 9 sur un front en le perdant sur l'autre.
"""
import numpy as np

from seuils import a_tort, affirmees, courbe, fusion_probas, recommander, tete


def test_la_fusion_est_une_distribution():
    rng = np.random.default_rng(0)
    p9 = rng.dirichlet(np.ones(5), size=4)
    p10 = rng.dirichlet(np.ones(5), size=4)
    f = fusion_probas(p9, p10)
    assert np.allclose(f.sum(axis=1), 1.0)
    # deux avis d'accord renforcent l'espèce commune
    d = fusion_probas(np.array([[0.6, 0.4]]), np.array([[0.6, 0.4]]))
    assert np.allclose(d, [[0.6, 0.4]])


def test_la_tete_rend_le_premier_et_son_avance():
    i, s1, marge = tete(np.array([[0.1, 0.7, 0.2], [0.5, 0.45, 0.05]]))
    assert list(i) == [1, 0]
    assert np.allclose(s1, [0.7, 0.5]) and np.allclose(marge, [0.5, 0.05])


def test_affirmer_demande_le_seuil_et_la_marge():
    s1 = np.array([0.80, 0.80, 0.60])
    marge = np.array([0.40, 0.10, 0.40])
    assert list(affirmees(s1, marge, 0.70)) == [True, False, False]


def test_la_courbe_compte_autonomie_et_justesse():
    justes = np.array([True, False, True, True])
    s1 = np.array([0.9, 0.9, 0.5, 0.8])
    marge = np.array([0.5, 0.5, 0.5, 0.5])
    c = {x['seuil']: x for x in courbe(justes, s1, marge, [0.7, 0.95])}
    assert c[0.7]['autonomie'] == 0.75 and np.isclose(c[0.7]['justesse'], 2 / 3)
    assert c[0.95]['autonomie'] == 0.0 and c[0.95]['justesse'] is None


def test_toute_affirmation_hors_repertoire_est_a_tort():
    assert a_tort(np.array([0.9, 0.4, 0.8, 0.95]), np.array([0.5, 0.5, 0.1, 0.6]), 0.7) == 0.5


def _lecteur(justes, s1, marge, ood_s1, ood_marge):
    return {'justes': np.array(justes), 's1': np.array(s1), 'marge': np.array(marge),
            'ood_s1': np.array(ood_s1), 'ood_marge': np.array(ood_marge)}


def test_le_seuil_recommande_egale_la_reference_sur_les_deux_fronts():
    # Iris 9 à 0,70 : 2 affirmées sur 4, justes à 100 %, 1 hors répertoire sur 2 affirmée.
    ref = _lecteur([True, True, False, False], [0.9, 0.8, 0.6, 0.5], [0.5] * 4,
                   [0.75, 0.3], [0.5, 0.5])
    # La fusion : juste à 100 % dès 0,50 (3 affirmées), mais affirme les deux
    # plantes hors répertoire sous 0,85 — il faut monter jusque-là.
    cand = _lecteur([True, True, True, False], [0.95, 0.9, 0.55, 0.4], [0.5] * 4,
                    [0.8, 0.8], [0.5, 0.5])
    assert recommander(cand, ref, seuils=(0.5, 0.6, 0.7, 0.85, 0.9)) == 0.85


def test_aucun_seuil_si_la_justesse_ne_suit_pas():
    ref = _lecteur([True, True], [0.9, 0.9], [0.5, 0.5], [0.1], [0.5])
    cand = _lecteur([False, False], [0.9, 0.9], [0.5, 0.5], [0.1], [0.5])
    assert recommander(cand, ref, seuils=(0.5, 0.7, 0.9)) is None
