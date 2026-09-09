"""Le rapport qui décide si Commons vaut une passe de collecte.

Le § 4.5 a montré ce que coûte de ne pas mesurer : Smithsonian Gardens
offrait 4 884 photos CC0 de plantes cultivées, exactement le bon domaine
visuel, et sept d'entre elles concernaient nos espèces. Une source ne vaut
pas par sa taille mais par son recouvrement.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from commons_apport import resume  # noqa: E402


def test_une_espece_sans_categorie_est_signalee_a_part():
    """Zéro n'est pas « peu » : c'est « Commons ne connaît pas cette plante »."""
    r = resume({'Monstera deliciosa': 40, 'Rara avis': 0})
    assert r['inconnues'] == ['Rara avis']
    assert r['connues'] == 1


def test_les_maigres_sont_comptees_comme_telles():
    r = resume({'A a': 12, 'B b': 250}, seuil_maigre=100)
    assert r['maigres'] == ['A a']
    assert r['total'] == 262


def test_une_espece_que_commons_pourrait_doubler_ressort():
    """C'est la population qu'on cherche : peu d'images chez nous, beaucoup
    chez eux."""
    r = resume({'Hoya kerrii': 150, 'Monstera deliciosa': 20},
               deja={'Hoya kerrii': 40, 'Monstera deliciosa': 400})
    assert r['doublees'] == ['Hoya kerrii']


def test_sans_le_jeu_aucune_espece_nest_dite_doublee():
    """Faute de savoir ce qu'on a déjà, on ne prétend pas savoir ce qu'on gagne."""
    r = resume({'Hoya kerrii': 150})
    assert r['doublees'] == []


def test_la_mediane_ignore_les_especes_inconnues():
    """Sinon une poignée d'absences ferait passer la médiane à zéro et
    condamnerait une source par ailleurs riche."""
    r = resume({'A a': 100, 'B b': 200, 'C c': 0, 'D d': 0})
    assert r['mediane'] == 150
    assert r['especes'] == 4 and r['connues'] == 2


def test_un_rapport_vide_ne_casse_pas():
    r = resume({})
    assert r['mediane'] == 0 and r['total'] == 0 and r['connues'] == 0
