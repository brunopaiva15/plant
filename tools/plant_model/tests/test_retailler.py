"""Retailler un modèle entraîné sans le réapprendre.

Deux choses peuvent se tromper en silence et livrer un modèle qui répond à
côté : l'ordre des classes gardées, et le découpage des colonnes de la tête.
Une colonne décalée d'un rang donnerait un modèle qui marche — il rendrait
simplement le mauvais nom, sans jamais planter.
"""
import sys
from pathlib import Path

import numpy as np
import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from retailler import decouper, garder, lire_masques


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


def test_a_mask_is_read_as_name_equals_file(tmp_path):
    fichier = tmp_path / 'indoor.txt'
    fichier.write_text('monstera-deliciosa\nficus-lyrata\n', encoding='utf-8')
    assert lire_masques([f'indoor={fichier}']) == {
        'indoor': ['monstera-deliciosa', 'ficus-lyrata'],
    }


def test_a_mask_without_a_name_is_refused(tmp_path):
    """« --masque fichier.txt » ne dit pas de quel lieu il parle, et un masque
    sans lieu n'a rien à écrire dans `model.json`."""
    with pytest.raises(SystemExit):
        lire_masques([str(tmp_path / 'indoor.txt')])


def test_two_masks_keep_their_own_lists(tmp_path):
    (tmp_path / 'a.txt').write_text('a\nb\n', encoding='utf-8')
    (tmp_path / 'b.txt').write_text('b\nc\n', encoding='utf-8')
    masques = lire_masques([f'indoor={tmp_path / "a.txt"}', f'outdoor={tmp_path / "b.txt"}'])
    # Une espèce peut appartenir aux deux : ce sont des contextes, pas deux
    # taxonomies exclusives (`docs/14` § 8).
    assert masques == {'indoor': ['a', 'b'], 'outdoor': ['b', 'c']}


def test_the_union_of_two_masks_is_what_a_union_model_exposes(tmp_path):
    """Sans `--garder`, c'est l'union des masques qui fait la liste : la dire
    deux fois inviterait les deux listes à diverger."""
    (tmp_path / 'a.txt').write_text('a\nb\n', encoding='utf-8')
    (tmp_path / 'b.txt').write_text('b\nc\n', encoding='utf-8')
    masques = lire_masques([f'indoor={tmp_path / "a.txt"}', f'outdoor={tmp_path / "b.txt"}'])
    union = sorted({c for ids in masques.values() for c in ids})
    assert garder(['a', 'b', 'c', 'd'], union) == ['a', 'b', 'c']
