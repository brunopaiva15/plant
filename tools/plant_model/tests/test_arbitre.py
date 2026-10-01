"""Les règles qui combinent Iris 9 et Iris 10.

Ce qui est testé ici est ce qui flatterait un résultat sans le dire : un
paramètre choisi sur les images qu'il note, deux classes d'une même plante
qui se partagent un score, un masque qui écarterait la moitié d'une plante.
"""
import numpy as np

from arbitre import (aligner, croisee, fusion, fusionner_synonymes, justesse, masquer,
                     moities, oracle, regle_seuil)
from voisins import canonique


def test_deux_classes_dune_meme_plante_sadditionnent():
    labels = ['schefflera-arboricola', 'ficus-benjamina', 'heptapleurum-arboricola']
    especes, p = fusionner_synonymes(np.array([[0.30, 0.40, 0.25]]), labels)
    assert especes == ['schefflera-arboricola', 'ficus-benjamina']
    assert np.allclose(p, [[0.55, 0.40]])
    assert canonique('heptapleurum-arboricola') == 'schefflera-arboricola'


def test_le_masque_garde_une_plante_par_nimporte_lequel_de_ses_noms():
    especes = ['schefflera-arboricola', 'ficus-benjamina', 'monstera-deliciosa']
    p = masquer(np.array([[0.5, 0.3, 0.2]]), especes, {'heptapleurum-arboricola', 'ficus-benjamina'})
    assert np.allclose(p, [[0.625, 0.375, 0.0]])


def test_sans_masque_rien_ne_change():
    p = np.array([[0.5, 0.5]])
    assert masquer(p, ['a', 'b'], None) is p


def test_la_regle_de_seuil():
    assert regle_seuil(np.array([0.9, 0.2]), ['a', 'b'], ['x', 'y'], 0.5) == ['a', 'y']


def test_la_fusion_departage_deux_avis():
    especes = ['a', 'b']
    p9 = np.array([[0.9, 0.1]])
    p10 = np.array([[0.3, 0.7]])
    assert fusion(especes, p9, p10, 0.75) == ['a']
    assert fusion(especes, p9, p10, 0.25) == ['b']


def test_une_probabilite_nulle_ne_met_pas_de_veto():
    """Iris 9 masqué rend 0 hors du lieu : sans plancher, le logarithme
    ferait -inf partout et l'argmax tomberait au hasard."""
    assert fusion(['a', 'b'], np.array([[0.0, 0.0]]), np.array([[0.99, 0.01]]), 0.5) == ['a']


def test_aligner_garde_les_especes_communes_dans_lordre():
    communes, a, b = aligner(['a', 'b', 'c'], np.array([[1, 2, 3]]), ['c', 'a'], np.array([[9, 8]]))
    assert communes == ['a', 'c'] and a.tolist() == [[1, 3]] and b.tolist() == [[8, 9]]


def test_les_moities_sont_fixes_et_se_partagent_le_banc():
    a, b = moities(101)
    a2, _ = moities(101)
    assert (a == a2).all() and len(set(a) | set(b)) == 101 and not set(a) & set(b)


def test_le_parametre_est_note_sur_les_images_quil_na_pas_choisies():
    """Un paramètre qui ne réussit que sur les images qui l'ont choisi ne
    doit pas être récompensé : la validation croisée le lit sur l'autre
    moitié."""
    verites = ['v'] * 100
    a, b = moities(100)
    triche = ['v' if i in set(a) else 'x' for i in range(100)]    # juste sur A seulement
    honnete = ['v' if i % 2 == 0 else 'x' for i in range(100)]    # juste une fois sur deux partout
    t1, choisis = croisee(verites, {'triche': triche, 'honnete': honnete})
    assert t1 < 0.6
    assert justesse(verites, triche, a) == 1.0


def test_larbitre_parfait():
    assert oracle(['a', 'b', 'c'], ['a', 'x', 'x'], ['x', 'b', 'x']) == 2 / 3
