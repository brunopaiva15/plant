"""Le tri des erreurs entre « dans le genre » et « entre genres ».

C'est toute la valeur de la matrice : deux pépéromias confondus ne
demandent rien — l'écran propose cinq candidats et la bonne réponse y est.
Un yucca pris pour du maïs demande des images, et c'est ce genre de paire
qu'il faut voir remonter.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from confusions import croiser, especes_en_difficulte, genre  # noqa: E402


def test_le_genre_sort_de_lidentifiant():
    assert genre('monstera-deliciosa') == 'monstera'
    assert genre('abelia-x-grandiflora') == 'abelia', 'les hybrides gardent leur genre'


def test_plants_csv_a_le_dernier_mot_quand_il_est_la():
    assert genre('goeppertia-orbifolia', {'goeppertia-orbifolia': 'Calathea orbifolia'}) == 'calathea'


def test_une_confusion_dans_le_genre_nest_pas_comptee_comme_defaut():
    stats = croiser([('peperomia-caperata', 'peperomia-obtusifolia')])
    assert stats['dans_genre'] == 1 and stats['hors_genre'] == 0
    assert stats['entre_genres'] == {}


def test_une_confusion_entre_genres_est_retenue_avec_sa_paire():
    stats = croiser([('yucca-gigantea', 'zea-mays')])
    assert stats['hors_genre'] == 1
    assert stats['entre_genres'][('yucca', 'zea')] == 1


def test_les_bonnes_reponses_ne_comptent_pas_comme_erreurs():
    stats = croiser([('monstera-deliciosa', 'monstera-deliciosa')] * 3)
    assert stats['justes'] == 3 and stats['hors_genre'] == 0 and stats['dans_genre'] == 0
    assert stats['par_espece'] == {}


def test_le_sens_de_la_confusion_est_conserve():
    """Yucca pris pour du maïs n'est pas maïs pris pour du yucca : ce sont
    deux défauts différents, et deux collectes différentes."""
    stats = croiser([('yucca-gigantea', 'zea-mays'), ('zea-mays', 'yucca-gigantea')])
    assert stats['entre_genres'][('yucca', 'zea')] == 1
    assert stats['entre_genres'][('zea', 'yucca')] == 1


def test_les_especes_trop_peu_vues_ne_sont_pas_classees():
    """Un taux d'échec sur trois photos ne veut rien dire."""
    paires = [('rara-avis', 'monstera-deliciosa')] * 3
    paires += [('yucca-gigantea', 'zea-mays')] * 6
    noms = [e for e, *_ in especes_en_difficulte(croiser(paires), minimum=5)]
    assert noms == ['yucca-gigantea']


def test_les_especes_sont_classees_par_taux_dechec():
    paires = [('a-un', 'b-deux')] * 5 + [('a-un', 'a-un')] * 5          # 50 % ratées
    paires += [('c-trois', 'd-quatre')] * 9 + [('c-trois', 'c-trois')]  # 90 % ratées
    classement = especes_en_difficulte(croiser(paires))
    assert [e for e, *_ in classement] == ['c-trois', 'a-un']
    espece, ratees, vues, coupable, combien = classement[0]
    assert (ratees, vues, coupable, combien) == (9, 10, 'd-quatre', 9)
