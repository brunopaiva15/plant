"""Les ensembles exposés de la courbe.

Deux points de la courbe ne se comparent que s'ils sont **emboîtés** : une
taille plus grande doit contenir exactement la précédente, plus des espèces
en plus. Sinon l'écart mesuré mélange ce qu'on ajoute et ce qu'on retire.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from courbe import ensembles


TOUTES = ['a', 'b', 'c', 'd', 'e']


def test_the_core_is_always_there_whatever_the_size():
    jeux = ensembles(['a', 'b'], ['e', 'd'], TOUTES, [2, 3, 5])
    for taille, garde in jeux.items():
        assert {'a', 'b'} <= set(garde), taille


def test_sets_are_nested_so_two_points_compare():
    jeux = ensembles(['a'], ['e', 'd', 'c'], TOUTES, [1, 2, 3, 5])
    par_taille = [set(jeux[n]) for n in sorted(jeux)]
    for petit, grand in zip(par_taille, par_taille[1:]):
        assert petit < grand


def test_additions_follow_the_priority_order_not_the_model_order():
    """`candidats_v8.txt` est rangé par ce que les gens cultivent : c'est cet
    ordre-là qui décide de la prochaine espèce ajoutée, pas l'alphabet."""
    jeux = ensembles(['a'], ['e', 'd'], TOUTES, [2, 3])
    assert set(jeux[2]) == {'a', 'e'}
    assert set(jeux[3]) == {'a', 'e', 'd'}


def test_species_absent_from_the_priority_file_still_fill_the_tail():
    """L'ordre ne couvre pas forcément tout : le reste suit, sinon une grande
    taille serait impossible à atteindre."""
    jeux = ensembles(['a'], ['e'], TOUTES, [5])
    assert set(jeux[5]) == set(TOUTES)


def test_a_size_below_the_core_is_raised_to_it():
    """On mesure ce qu'on ajoute, pas ce qu'on ampute : demander moins que le
    cœur rend le cœur, sous son vrai nom."""
    jeux = ensembles(['a', 'b', 'c'], [], TOUTES, [1])
    assert list(jeux) == [3]
    assert set(jeux[3]) == {'a', 'b', 'c'}


def test_a_core_species_the_model_never_learned_is_ignored():
    """Les 13 espèces perdues du § 6.7 bis : il n'y a pas de colonne
    derrière, elles ne peuvent pas faire partie d'un ensemble exposé."""
    jeux = ensembles(['a', 'inconnue'], ['e'], TOUTES, [2])
    assert set(jeux[2]) == {'a', 'e'}


def test_the_priority_order_never_duplicates_the_core():
    jeux = ensembles(['a', 'b'], ['b', 'a', 'e'], TOUTES, [3])
    assert sorted(jeux[3]) == ['a', 'b', 'e']
    assert len(jeux[3]) == len(set(jeux[3]))


# ── le coût de vol ────────────────────────────────────────────────────────

import numpy as np

from courbe import couts_de_vol, ordre_par_vol


def test_a_candidate_steals_only_images_the_core_gets_right():
    """Trois classes : 0 et 1 au cœur, 2 candidate. La candidate vole B, où
    elle dépasse la vérité ; pas A, où elle reste derrière ; et C ne compte
    pas, le cœur s'y trompait déjà."""
    P = np.array([[0.6, 0.1, 0.3],      # A : vérité 0, juste, candidate derrière
                  [0.2, 0.35, 0.45],    # B : vérité 1, juste, candidate devant → vol
                  [0.2, 0.4, 0.4]])     # C : vérité 0, le cœur répond 1 → déjà fausse
    vols, justes = couts_de_vol(P, np.array([0, 1, 0]), np.array([0, 1]), np.array([2]))
    assert list(vols) == [1]
    assert justes == 2


def test_stealing_requires_strictly_more_than_the_truth():
    P = np.array([[0.5, 0.0, 0.5]])
    vols, _ = couts_de_vol(P, np.array([0]), np.array([0, 1]), np.array([2]))
    assert list(vols) == [0]


def test_costs_are_counted_per_candidate():
    P = np.array([[0.4, 0.1, 0.5, 0.0],
                  [0.1, 0.4, 0.5, 0.45]])
    vols, _ = couts_de_vol(P, np.array([0, 1]), np.array([0, 1]), np.array([2, 3]))
    assert list(vols) == [2, 1]


def test_free_candidates_come_first_then_priority_breaks_ties():
    """Deux gratuites et une chère : les gratuites d'abord, dans l'ordre de
    culture — et la chère en dernier même si elle est la plus cultivée."""
    couts = {'chere': 3, 'b': 0, 'c': 0}
    assert ordre_par_vol(couts, ['chere', 'c', 'b']) == ['c', 'b', 'chere']


def test_a_candidate_absent_from_the_priority_file_goes_after_its_peers():
    couts = {'connue': 0, 'inconnue': 0}
    assert ordre_par_vol(couts, ['connue']) == ['connue', 'inconnue']
