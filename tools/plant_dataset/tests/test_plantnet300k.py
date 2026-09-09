"""La mesure qui décide si PlantNet-300K vaut un connecteur.

Le § 4.6 avait écarté ce jeu sur une intuition — flore européenne sauvage
contre plantes d'appartement. Une intuition ne se vérifie pas toute seule :
ces tests tiennent la mécanique de la mesure, pour que le chiffre du § 12.8
se refasse et se conteste.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from plantnet300k import ENTIERE, compter, correspondance  # noqa: E402


def test_les_noms_se_rencontrent_malgre_les_auteurs():
    """« Lactuca virosa L. » et « lactuca-virosa » sont la même plante."""
    corr = correspondance({'1': 'Lactuca virosa L.', '2': 'Cirsium vulgare (Savi) Ten.'},
                          {'lactuca-virosa', 'cirsium-vulgare', 'monstera-deliciosa'})
    assert corr == {'1': 'lactuca-virosa', '2': 'cirsium-vulgare'}


def test_une_espece_que_nous_ne_connaissons_pas_est_ignoree():
    assert correspondance({'9': 'Quercus robur L.'}, {'monstera-deliciosa'}) == {}


def test_deux_identifiants_peuvent_tomber_sur_une_seule_espece():
    """Synonymes et sous-espèces : leurs images se rejoindraient chez nous."""
    corr = correspondance({'1': 'Lactuca virosa L.', '2': 'Lactuca virosa'}, {'lactuca-virosa'})
    assert set(corr) == {'1', '2'} and set(corr.values()) == {'lactuca-virosa'}


def _img(sid, licence='cc-by-sa', organe='flower'):
    return {'species_id': sid, 'license': licence, 'organ': organe}


def test_les_licences_refusees_sont_comptees_mais_pas_retenues():
    """Savoir qu'un jeu est utilisable à 100 % ou à 18 % change la décision."""
    stats = compter({'a': _img('1'), 'b': _img('1', 'cc-by-nc'), 'c': _img('1', 'cc0')},
                    {'1': 'lactuca-virosa'})
    assert stats['images'] == 2, 'seules cc-by-sa et cc0 sont gardées'
    assert stats['images_toutes_licences'] == 3
    assert stats['par_licence']['cc-by-nc'] == 1


def test_les_images_hors_recouvrement_ne_comptent_pas():
    stats = compter({'a': _img('1'), 'b': _img('inconnue')}, {'1': 'lactuca-virosa'})
    assert stats['images'] == 1 and stats['especes'] == 1


def test_la_plante_entiere_est_comptee_a_part():
    """C'est le seul cadrage qui ressemble à ce que photographie un
    utilisateur : le § 6.3 a déjà coûté cher pour l'avoir ignoré."""
    stats = compter({'a': _img('1', organe=ENTIERE), 'b': _img('1', organe='leaf'),
                     'c': _img('1', organe='flower')}, {'1': 'lactuca-virosa'})
    assert stats['entieres']['lactuca-virosa'] == 1
    assert stats['par_organe'] == {ENTIERE: 1, 'leaf': 1, 'flower': 1}
    assert stats['images'] == 3


def test_un_jeu_sans_recouvrement_ne_rend_rien():
    stats = compter({'a': _img('1')}, {})
    assert stats['images'] == 0 and stats['especes'] == 0
