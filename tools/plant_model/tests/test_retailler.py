"""Retailler un modèle entraîné sans le réapprendre.

Deux choses peuvent se tromper en silence et livrer un modèle qui répond à
côté : l'ordre des classes gardées, et le découpage des colonnes de la tête.
Une colonne décalée d'un rang donnerait un modèle qui marche — il rendrait
simplement le mauvais nom, sans jamais planter.
"""
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from retailler import decouper, garder


def test_kept_classes_follow_the_trained_order_not_the_requested_one():
    """`labels.txt` et les colonnes de la tête se lisent ligne à ligne : les
    gardées doivent donc suivre l'ordre du modèle, pas celui du fichier."""
    assert garder(['abies', 'betula', 'cedrus'], ['cedrus', 'abies']) == ['abies', 'cedrus']


def test_a_requested_class_the_model_never_learned_is_dropped():
    """Les 13 espèces que l'Iris 7 nomme et que l'Iris 8 n'a pas apprises :
    il n'y a pas de colonne derrière, garder l'étiquette livrerait un nom
    sans sortie."""
    assert garder(['abies', 'betula'], ['abies', 'hoya-kerrii']) == ['abies']


def test_asking_for_everything_changes_nothing():
    toutes = ['a', 'b', 'c']
    assert garder(toutes, toutes) == toutes


def test_the_head_is_cut_by_columns_in_the_kept_order():
    noyau = np.array([[1.0, 2.0, 3.0],
                      [4.0, 5.0, 6.0]])          # 2 traits × 3 classes
    biais = np.array([10.0, 20.0, 30.0])
    poids = [np.zeros((2, 2)), noyau, biais]      # un tableau de dorsal devant
    sortie = decouper(poids, ['a', 'b', 'c'], ['a', 'c'])
    assert np.array_equal(sortie[-2], np.array([[1.0, 3.0], [4.0, 6.0]]))
    assert np.array_equal(sortie[-1], np.array([10.0, 30.0]))


def test_everything_before_the_head_is_copied_untouched():
    """Le dorsal n'est pas concerné : c'est la même vision, moins de noms."""
    dorsal = [np.arange(6).reshape(2, 3), np.array([7.0, 8.0])]
    poids = dorsal + [np.ones((2, 4)), np.zeros(4)]
    sortie = decouper(poids, list('abcd'), ['b', 'd'])
    assert len(sortie) == len(poids)
    for avant, apres in zip(dorsal, sortie[:-2]):
        assert avant is apres


def test_cutting_preserves_the_ratio_between_two_kept_logits():
    """Le softmax d'une tête tronquée vaut exp(zi) / somme des gardées : le
    classement entre deux espèces conservées ne bouge donc jamais, et c'est
    ce qui rend la retaille équivalente à un masque renormalisé."""
    noyau = np.array([[2.0, 9.0, 1.0]])
    biais = np.array([0.5, 0.0, 0.25])
    traits = np.array([[3.0]])
    complet = traits @ noyau + biais
    coupe = decouper([noyau, biais], ['a', 'b', 'c'], ['a', 'c'])
    petit = traits @ coupe[-2] + coupe[-1]
    assert np.allclose(petit, complet[:, [0, 2]])
