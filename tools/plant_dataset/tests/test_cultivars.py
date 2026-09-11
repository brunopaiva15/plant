"""Le cultivar est un second axe, pas une classe de plus.

Une photo de « Thai Constellation » est une photo de *Monstera deliciosa* :
iNaturalist l'enregistre ainsi et Commons n'en a qu'une. En faire des
classes recréerait le défaut du § 12.14 — deux étiquettes pour une plante,
les images partagées, une confusion imperdable. Le modèle répond l'espèce,
l'application propose les cultivars connus : ce fichier est cette liste.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from cultivars import epithete, grouper  # noqa: E402


def test_lepithete_sort_des_apostrophes_droites():
    assert epithete("Epipremnum aureum 'Neon'", 'Epipremnum aureum') == 'Neon'


def test_wikidata_ecrit_avec_toutes_les_apostrophes_de_lunicode():
    # « Hosta ʽFortunei’ », « Ficus elastica ʽRobusta’ » : la règle horticole
    # n'en connaît qu'une, et deux graphies feraient deux cultivars.
    assert epithete('Ficus elastica ʽRobusta’', 'Ficus elastica') == 'Robusta'
    assert epithete('Hosta ʽGold Standard’', 'Hosta') == 'Gold Standard'


def test_un_taxon_qui_nest_pas_un_cultivar_est_ecarte():
    # Wikidata range sous Q4886 des choses qui n'en sont pas. La règle du
    # code horticole tranche : un nom de cultivar prend une majuscule, une
    # épithète d'espèce ou de variété jamais.
    assert epithete('Hosta decorata', 'Hosta') is None, 'decorata est une espèce'
    assert epithete('Agave americana var. medio-picta alba', 'Agave americana') is None
    assert epithete('Hosta', 'Hosta') is None


def test_un_cultivar_sans_apostrophe_passe_sil_a_sa_majuscule():
    assert epithete('Ficus elastica Robusta', 'Ficus elastica') == 'Robusta'


def test_un_nom_vide_ne_fait_pas_tomber_la_liste():
    assert epithete('', 'Hosta') is None
    assert epithete(None, 'Hosta') is None


def test_les_cultivars_sont_groupes_par_espece_et_dedoublonnes():
    lignes = [('Ficus elastica', "Ficus elastica 'Robusta'"),
              ('Ficus elastica', 'Ficus elastica ʽRobusta’'),
              ('Ficus elastica', "Ficus elastica 'Tineke'"),
              ('Epipremnum aureum', "Epipremnum aureum 'Neon'")]
    assert grouper(lignes) == {
        'Epipremnum aureum': ['Neon'],
        'Ficus elastica': ['Robusta', 'Tineke'],
    }


def test_une_espece_sans_cultivar_nentre_pas_dans_la_liste():
    assert grouper([('Monstera deliciosa', 'Monstera deliciosa')]) == {}
