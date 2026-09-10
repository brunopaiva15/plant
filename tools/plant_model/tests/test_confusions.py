"""Le tri des erreurs entre « dans le genre » et « entre genres ».

C'est toute la valeur de la matrice : deux pépéromias confondus ne
demandent rien — l'écran propose cinq candidats et la bonne réponse y est.
Un yucca pris pour du maïs demande des images, et c'est ce genre de paire
qu'il faut voir remonter.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from confusions import (au_hasard, croiser, especes_en_difficulte, famille,  # noqa: E402
                        genre, jamais_reconnues)


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


# --- La famille, et la référence sans laquelle les parts ne disent rien ----
#
# La première version rangeait les erreurs en deux tas et appelait « vrais
# défauts » tout ce qui sortait du genre. Sur l'Iris 7, ça faisait 87 % — un
# chiffre qui compte comme un défaut la structure du catalogue, puisque 549
# classes sur 1 457 sont seules dans leur genre et ne *peuvent* pas s'y
# tromper.

FAMILLES = {
    'picea-abies': 'Pinaceae', 'abies-alba': 'Pinaceae',
    'parthenocissus-inserta': 'Vitaceae', 'petroselinum-crispum': 'Apiaceae',
}


def test_deux_genres_dune_meme_famille_ne_sont_pas_un_defaut():
    stats = croiser([('picea-abies', 'abies-alba')], None, FAMILLES)
    assert stats['dans_genre'] == 0
    assert stats['meme_famille'] == 1 and stats['hors_famille'] == 0
    assert stats['hors_genre'] == 1, 'le total hors genre reste lisible comme avant'


def test_une_vigne_prise_pour_du_persil_est_un_vrai_defaut():
    stats = croiser([('parthenocissus-inserta', 'petroselinum-crispum')], None, FAMILLES)
    assert stats['hors_famille'] == 1 and stats['meme_famille'] == 0
    assert stats['entre_familles'][('vitaceae', 'apiaceae')] == 1


def test_sans_familles_le_troisieme_tiroir_reste_vide_plutot_que_de_mentir():
    stats = croiser([('picea-abies', 'abies-alba')])
    assert stats['meme_famille'] == 0 and stats['hors_famille'] == 1
    assert stats['entre_familles'] == {}


def test_une_famille_inconnue_ne_se_confond_avec_aucune_autre():
    # Deux espèces sans famille renseignée ne doivent pas être déclarées
    # « même famille » sur la foi de deux valeurs vides.
    stats = croiser([('aaa-un', 'bbb-un')], None, {'ccc-un': 'Rosaceae'})
    assert stats['meme_famille'] == 0 and stats['hors_famille'] == 1


def test_le_hasard_se_calcule_sur_le_catalogue_pas_sur_les_erreurs():
    h = au_hasard(['a-un', 'a-deux', 'b-un'], {'a-un': 'X', 'a-deux': 'X', 'b-un': 'X'})
    assert round(h['genre'], 4) == 0.3333, 'a-un et a-deux se répondent, b-un jamais'
    assert round(h['famille'], 4) == 0.6667
    assert h['seules_dans_leur_genre'] == 1


def test_un_catalogue_dune_seule_classe_na_pas_de_hasard():
    assert au_hasard(['a-un'])['genre'] == 0.0


def test_la_famille_vient_de_plants_csv_et_se_lit_en_minuscules():
    assert famille('picea-abies', FAMILLES) == 'pinaceae'
    assert famille('inconnue-x', FAMILLES).startswith('?'), 'une famille absente reste distincte'


def test_le_troisieme_tiroir_a_sa_reference_comme_les_deux_autres():
    # Sans elle, « 73 % au-delà » se lit comme un désastre alors que le
    # hasard en mettrait 98 % : le modèle y est meilleur, pas pire.
    h = au_hasard(['a-un', 'a-deux', 'b-un'], {'a-un': 'X', 'a-deux': 'X', 'b-un': 'X'})
    assert round(h['genre'] + h['famille'] + h['au_dela'], 6) == 1.0
    assert h['au_dela'] == 0.0, 'ici toutes les classes sont d\'une seule famille'


def test_une_espece_jamais_reconnue_nest_pas_une_espece_confondue():
    # 5 images, 5 erreurs : le modèle ne l'a pas apprise. À distinguer d'une
    # espèce fragile, qui en rate quatre sur cinq.
    perdue = [('a-un', 'b-un')] * 5
    fragile = [('c-un', 'd-un')] * 4 + [('c-un', 'c-un')]
    stats = croiser(perdue + fragile)
    assert jamais_reconnues(stats) == [('a-un', 5)]


def test_une_espece_trop_peu_vue_ne_compte_pas_comme_perdue():
    # Trois images ratées ne disent rien : on ne classe pas une espèce sur
    # trois photos, c'est déjà la règle d'`especes_en_difficulte`.
    assert jamais_reconnues(croiser([('a-un', 'b-un')] * 3)) == []
