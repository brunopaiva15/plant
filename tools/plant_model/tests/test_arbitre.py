"""Le deuxième regard sur la photo, mesuré avant d'être livré.

Trois choses se tromperaient en silence, et donneraient un chiffre faux sans
que rien ne plante : une population mal sélectionnée — on mesurerait alors sur
des photos qu'Iris tranche déjà seul —, un numéro hors liste pris pour une
réponse, et un gain compté là où l'arbitre n'a fait que confirmer l'ordre
d'Iris.
"""
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from arbitre import cout, hesitant, jetons_image, lire_avis, mesurer, question


def sortie(*scores: float) -> np.ndarray:
    return np.array(scores, dtype=np.float32)


def test_an_accepted_answer_is_not_part_of_the_population():
    """0,80 contre 0,10 : Iris a tranché, et il a raison neuf fois sur dix
    quand il tranche. Mesurer là-dessus diluerait le résultat."""
    assert not hesitant(sortie(0.80, 0.10, 0.05))


def test_a_close_call_is():
    assert hesitant(sortie(0.44, 0.39, 0.12))
    assert hesitant(sortie(0.18, 0.15, 0.10))


def test_a_list_below_the_floor_is_not():
    """Sous 0,10, la liste ne vaut rien : c'est la réponse d'un modèle à qui
    l'on montre un chat, et elle part chez Pl@ntNet, pas chez l'arbitre."""
    assert not hesitant(sortie(0.05, 0.04, 0.03))


def test_the_question_numbers_the_names_and_hides_the_scores():
    """Donner les scores ancrerait la réponse sur l'ordre qu'on fait arbitrer."""
    q = question(['Monstera deliciosa', 'Monstera adansonii'])
    assert '1. Monstera deliciosa' in q
    assert '2. Monstera adansonii' in q
    assert '0.44' not in q


def test_a_number_outside_the_list_counts_as_none():
    """Un modèle qui répond « 7 » sur trois candidates n'a pas répondu à la
    question posée. Le compter comme une désignation inventerait un nom."""
    assert lire_avis('{"candidate": 2, "plant": true, "trait": "x"}', 3) == 2
    assert lire_avis('{"candidate": 7}', 3) == 0
    assert lire_avis('{"candidate": 0}', 3) == 0
    assert lire_avis('{"candidate": "2"}', 3) == 2


def test_not_a_plant_comes_before_the_number():
    assert lire_avis('{"candidate": 1, "plant": false}', 3) == 0


def test_an_unreadable_answer_is_not_an_answer():
    """Un incident et un « aucune » ne se confondent pas : le premier dit que
    l'appel a échoué, le second que la liste d'Iris est à côté."""
    assert lire_avis('je ne sais pas', 3) is None
    assert lire_avis('{"trait": "fenestrations"}', 3) is None
    assert lire_avis('```json\n{"candidate": 3}\n```', 3) == 3


def test_an_image_costs_the_square_of_its_side():
    """C'est la seule raison de réduire les photos : 768 px coûtent un peu
    plus de la moitié de 1 024 px, pas un peu moins."""
    assert jetons_image(768) == 48 * 48
    assert jetons_image(1024) == 64 * 64
    assert jetons_image(512) / jetons_image(1024) == 0.25


def test_the_bill_counts_input_and_output_apart():
    # 2 304 jetons d'entrée et 120 de sortie, aux tarifs de Mistral Small 4.
    assert cout({'prompt_tokens': 2304, 'completion_tokens': 120}) == (
        2304 / 1e6 * 0.20 + 120 / 1e6 * 0.75
    )


def cas(vrai, candidates, avis):
    return {'vrai': vrai, 'candidates': candidates, 'avis': avis}


def test_a_confirmed_lead_is_not_a_gain():
    """L'arbitre qui désigne la candidate déjà en tête ne change rien à
    l'écran : le compter comme un déplacement gonflerait le résultat."""
    m = mesurer([cas('a', ['a', 'b', 'c'], 1)])
    assert m['top1_iris'] == 1.0
    assert m['top1_arbitre'] == 1.0
    assert m['deplacements'] == 0.0


def test_a_moved_lead_that_is_right_is_a_gain():
    m = mesurer([cas('b', ['a', 'b', 'c'], 2)])
    assert m['top1_iris'] == 0.0
    assert m['top1_arbitre'] == 1.0
    assert m['deplacements'] == 1.0
    assert (m['gagnes'], m['perdus']) == (1, 0)


def test_a_moved_lead_that_is_wrong_is_a_loss():
    """Le cas qui coûte : Iris avait raison, l'arbitre l'a contredit."""
    m = mesurer([cas('a', ['a', 'b', 'c'], 2)])
    assert m['top1_iris'] == 1.0
    assert m['top1_arbitre'] == 0.0
    assert (m['gagnes'], m['perdus']) == (0, 1)


def test_no_answer_leaves_iris_untouched():
    """Un incident ne doit ni gagner ni perdre : la liste d'Iris est rendue
    telle quelle, comme dans l'application."""
    m = mesurer([cas('a', ['a', 'b'], None), cas('b', ['a', 'b'], None)])
    assert m['top1_iris'] == m['top1_arbitre'] == 0.5
    assert m['incidents'] == 1.0
    assert m['deplacements'] == 0.0


def test_the_ceiling_is_what_the_list_contains():
    """Un arbitre parfait ne peut pas faire mieux que le top-5 d'Iris : c'est
    le plafond à comparer au gain réel."""
    m = mesurer([cas('z', ['a', 'b'], 0), cas('b', ['a', 'b'], 2)])
    assert m['top5_iris'] == 0.5
    assert m['top1_arbitre'] == 0.5
    assert m['aucune'] == 0.5
