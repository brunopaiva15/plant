"""L'analyse des erreurs du banc.

Ce qui est testé ici est ce qui ferait tirer la mauvaise conclusion : une
erreur de genre comptée comme une erreur de famille, une image que le
teacher rate aussi comptée comme une perte de distillation, une espèce à
trois images qui passerait devant une espèce à quarante.
"""
import numpy as np

from erreurs import confusions, croiser, niveau, par_espece, rapport, taxonomie, top1

TAXO = taxonomie([
    {'internal_id': 'calathea-orbifolia', 'scientific_name': 'Goeppertia orbifolia',
     'genus': 'Goeppertia', 'family': 'Marantaceae'},
    {'internal_id': 'calathea-lancifolia', 'scientific_name': 'Goeppertia insignis',
     'genus': 'Goeppertia', 'family': 'Marantaceae'},
    {'internal_id': 'maranta-leuconeura', 'scientific_name': 'Maranta leuconeura',
     'genus': 'Maranta', 'family': 'Marantaceae'},
    {'internal_id': 'ficus-benjamina', 'scientific_name': 'Ficus benjamina',
     'genus': 'Ficus', 'family': 'Moraceae'},
])


def test_la_distance_dune_erreur():
    assert niveau('calathea-orbifolia', 'calathea-orbifolia', TAXO) == 'juste'
    assert niveau('calathea-orbifolia', 'calathea-lancifolia', TAXO) == 'même genre'
    assert niveau('calathea-orbifolia', 'maranta-leuconeura', TAXO) == 'même famille'
    assert niveau('calathea-orbifolia', 'ficus-benjamina', TAXO) == 'autre famille'
    assert niveau('calathea-orbifolia', 'pas-au-catalogue', TAXO) == 'inconnu'


def test_un_genre_vide_ne_rapproche_pas_deux_especes():
    taxo = taxonomie([{'internal_id': 'a', 'genus': '', 'family': 'X'},
                      {'internal_id': 'b', 'genus': '', 'family': 'Y'}])
    assert niveau('a', 'b', taxo) == 'autre famille'


def test_le_croisement_separe_la_perte_de_distillation_du_plafond_du_teacher():
    verites = ['a', 'a', 'a', 'a']
    student = ['a', 'b', 'a', 'b']
    teacher = ['a', 'a', 'b', 'b']
    assert croiser(verites, student, teacher) == {
        'juste / juste': 1, 'faux / juste': 1, 'juste / faux': 1, 'faux / faux': 1}


def test_les_especes_se_classent_par_erreurs_pas_par_taux():
    verites = ['a'] * 40 + ['b'] * 3
    preds = ['a'] * 28 + ['x'] * 12 + ['y'] * 3
    assert par_espece(verites, preds) == [('a', 40, 12), ('b', 3, 3)]


def test_une_espece_sans_erreur_nest_pas_listee():
    assert par_espece(['a', 'b'], ['a', 'x']) == [('b', 1, 1)]


def test_les_confusions_les_plus_frequentes_dabord():
    verites = ['a', 'a', 'a', 'b', 'b']
    preds = ['x', 'x', 'y', 'b', 'x']
    assert confusions(verites, preds) == [('a', 'x', 2), ('a', 'y', 1), ('b', 'x', 1)]


def test_le_top1_est_largmax():
    assert top1(['a', 'b', 'c'], [np.array([0.1, 0.7, 0.2]), np.array([0.5, 0.2, 0.3])]) == ['b', 'a']


def test_le_rapport_nomme_les_plantes_et_compte_juste():
    verites = ['calathea-orbifolia'] * 3 + ['ficus-benjamina']
    student = ['maranta-leuconeura', 'calathea-orbifolia', 'calathea-lancifolia',
               'ficus-benjamina']
    teacher = ['calathea-orbifolia', 'calathea-orbifolia', 'calathea-lancifolia',
               'ficus-benjamina']
    iris = ['calathea-orbifolia', 'maranta-leuconeura', 'calathea-orbifolia',
            'ficus-benjamina']
    texte = '\n'.join(rapport('indoor', verites, student, teacher, TAXO, iris))
    assert 'top-1 student 0.5000   teacher 0.7500   Iris 9 0.7500' in texte
    assert 'Goeppertia orbifolia' in texte and 'Maranta leuconeura' in texte
    # deux images qu'Iris 9 réussit seul : une de genre, une de famille, dont
    # une que le teacher réussit
    assert "parmi les 2 qu'Iris 9 réussit seul : même genre 1, même famille 1 ; " \
           "1 que le teacher réussit" in texte
