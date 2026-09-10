"""Deux noms pour une plante font deux classes, et c'est un défaut de
catalogue qu'aucune photo ne peut réparer.

Les images se partagent entre les deux, chacune s'entraîne sur la moitié de
ce qu'elle devrait, et la confusion qui en résulte apparaît dans la matrice
comme une erreur du modèle alors qu'il n'y avait rien à trancher.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from doublons import grouper, images_par_classe  # noqa: E402


def test_deux_noms_sur_un_meme_taxon_font_un_doublon():
    g = grouper({'sansevieria-trifasciata': 11041822, 'dracaena-trifasciata': 11041822,
                 'monstera-deliciosa': 2868536})
    assert g == [['dracaena-trifasciata', 'sansevieria-trifasciata']]


def test_deux_plantes_distinctes_ne_se_regroupent_pas():
    # Populus alba et Salix alba partagent leur épithète et leur famille ;
    # c'est ce qui rend l'heuristique inutilisable et GBIF nécessaire.
    assert grouper({'populus-alba': 3040233, 'salix-alba': 5372513}) == []


def test_les_noms_non_resolus_ne_font_pas_un_gros_doublon():
    # Sans ça, toutes les inconnues tomberaient sur `None` et seraient
    # annoncées comme une seule et même plante.
    assert grouper({'a-un': None, 'b-un': None, 'c-un': 42}) == []


def test_un_taxon_a_trois_noms_rend_un_seul_groupe():
    g = grouper({'a-un': 7, 'b-un': 7, 'c-un': 7})
    assert g == [['a-un', 'b-un', 'c-un']], 'un groupe de trois, pas trois paires'


def test_les_groupes_sortent_dans_un_ordre_stable():
    cles = {'zeta-un': 1, 'alpha-un': 1, 'nu-deux': 2, 'beta-deux': 2}
    assert grouper(cles) == [['alpha-un', 'zeta-un'], ['beta-deux', 'nu-deux']]


def test_sans_jeu_dimages_loutil_reste_utilisable(tmp_path):
    assert images_par_classe(tmp_path) == {}


def test_le_compte_dimages_dit_ce_que_la_scission_separe(tmp_path):
    (tmp_path / 'splits.csv').write_text(
        'internal_plant_id,split\n'
        'sansevieria-trifasciata,train\n'
        'sansevieria-trifasciata,train\n'
        'dracaena-trifasciata,test\n', encoding='utf-8')
    assert images_par_classe(tmp_path) == {'sansevieria-trifasciata': 2, 'dracaena-trifasciata': 1}
