"""Répondre au genre quand l'espèce hésite.

Deux choses se tromperaient en silence : une masse de genre mal sommée — le
chiffre serait faux sans que rien ne plante — et un genre qui prendrait la
place d'une espèce que le modèle savait nommer, ce qui serait une perte
déguisée en gain.
"""
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from genre import genres_des, mesurer, repondre, table_genres

LABELS = ['picea-abies', 'picea-glauca', 'picea-pungens', 'monstera-deliciosa']


def sortie(scores: dict[str, float]) -> np.ndarray:
    return np.array([scores.get(c, 0.0) for c in LABELS], dtype=np.float32)


def test_the_genus_of_a_class_comes_from_its_scientific_name_when_known():
    """L'identifiant suffit d'ordinaire, mais pas pour un hybride :
    `citrus-x-limon` donnerait le genre « citrus » par l'identifiant et
    « citrus » par le nom — c'est le nom qui fait foi."""
    assert genres_des(LABELS) == ['picea', 'picea', 'picea', 'monstera']
    assert genres_des(['citrus-x-limon'], {'citrus-x-limon': 'Citrus × limon'}) == ['citrus']


def test_the_mass_of_a_genus_is_the_sum_of_its_species():
    """Le cœur du § 12.15 : cinq Picea à 0,15 pèsent 0,75. Sommer à côté
    rendrait un chiffre faux sans que rien ne plante."""
    distincts, M = table_genres(genres_des(LABELS))
    assert distincts == ['monstera', 'picea']
    masses = sortie({'picea-abies': 0.3, 'picea-glauca': 0.25, 'picea-pungens': 0.2, 'monstera-deliciosa': 0.25}) @ M
    assert np.allclose(masses, [0.25, 0.75])


def test_a_species_that_passes_the_threshold_answers_alone():
    """L'espèce garde la priorité : un nom d'espèce vaut mieux qu'un genre,
    même quand le genre est plus sûr encore."""
    distincts, M = table_genres(genres_des(LABELS))
    probs = sortie({'picea-abies': 0.75, 'picea-glauca': 0.2, 'monstera-deliciosa': 0.05})
    quoi, quel, score = repondre(probs, probs @ M, 0.70)
    assert quoi == 'espece' and LABELS[quel] == 'picea-abies' and score == 0.75


def test_the_genus_answers_only_where_the_species_gave_up():
    distincts, M = table_genres(genres_des(LABELS))
    probs = sortie({'picea-abies': 0.3, 'picea-glauca': 0.25, 'picea-pungens': 0.2, 'monstera-deliciosa': 0.25})
    quoi, quel, score = repondre(probs, probs @ M, 0.70)
    assert quoi == 'genre' and distincts[quel] == 'picea'
    assert score == 0.75


def test_neither_passes_and_nothing_is_answered():
    """Le repli distant garde sa raison d'être : le genre ne sauve pas tout."""
    distincts, M = table_genres(genres_des(LABELS))
    probs = sortie({'monstera-deliciosa': 0.35, 'picea-abies': 0.25, 'picea-glauca': 0.2, 'picea-pungens': 0.2})
    assert repondre(probs, probs @ M, 0.70)[0] == 'rien'


def test_a_lone_species_in_its_genus_gains_nothing():
    """Sa masse *est* son score : elle ne peut pas passer au genre ce qu'elle
    ne passait pas à l'espèce."""
    distincts, M = table_genres(genres_des(LABELS))
    probs = sortie({'monstera-deliciosa': 0.6, 'picea-abies': 0.4})
    assert repondre(probs, probs @ M, 0.70)[0] == 'rien'


def test_the_tally_never_counts_a_genus_answer_as_a_species_one():
    distincts, M = table_genres(genres_des(LABELS))
    P = np.stack([
        sortie({'picea-abies': 0.9, 'picea-glauca': 0.1}),                                  # espèce, juste
        sortie({'picea-abies': 0.3, 'picea-glauca': 0.25, 'picea-pungens': 0.25, 'monstera-deliciosa': 0.2}),  # genre, juste
        sortie({'monstera-deliciosa': 0.4, 'picea-abies': 0.35, 'picea-glauca': 0.25}),     # rien
    ])
    genre_de = np.array([1, 1, 1, 0])
    r = mesurer(P, np.array([0, 2, 3]), M, genre_de, 0.70)
    assert (r['espece_taux'], r['espece_precision']) == (1 / 3, 1.0)
    assert (r['genre_taux'], r['genre_precision']) == (1 / 3, 1.0)
    assert r['autonomie'] == 2 / 3 and r['precision'] == 1.0


def test_a_wrong_genus_answer_counts_against_precision():
    distincts, M = table_genres(genres_des(LABELS))
    probs = sortie({'picea-abies': 0.3, 'picea-glauca': 0.25, 'picea-pungens': 0.25, 'monstera-deliciosa': 0.2})
    r = mesurer(np.stack([probs]), np.array([3]), M, np.array([1, 1, 1, 0]), 0.70)
    assert r['genre_taux'] == 1.0 and r['genre_precision'] == 0.0
