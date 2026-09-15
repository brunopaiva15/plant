"""Le verdict du § 12.7 : trois cas, trois chantiers de tailles différentes.

Un classifieur dont toutes les sorties sont des plantes répond une plante
devant un chat ; la seule question est avec quelle assurance. Ces tests
fixent la lecture, pour qu'un résultat limite ne se lise pas au jugé.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from hors_sujet import CATEGORIES, verdict  # noqa: E402


def _verdict(scores, capsys, plancher=0.10, seuil=0.70):
    verdict(scores, plancher, seuil)
    return capsys.readouterr().out


def test_tout_sous_le_plancher_ferme_le_chantier(capsys):
    sortie = _verdict([0.02, 0.05, 0.01, 0.09, 0.03], capsys)
    assert 'chantier pour rien' in sortie


def test_une_majorite_entre_plancher_et_seuil_appelle_un_message(capsys):
    sortie = _verdict([0.3, 0.45, 0.5, 0.2, 0.05], capsys)
    assert 'un message suffirait' in sortie
    assert 'AFFIRME' not in sortie


def test_une_seule_affirmation_suffit_a_justifier_la_classe(capsys):
    # Le troisième cas l'emporte sur les autres : une espèce affirmée devant
    # un mur est le défaut que la classe « autre » existe pour corriger, et
    # il ne se compense pas par une majorité de scores bas.
    sortie = _verdict([0.02, 0.03, 0.01, 0.04, 0.85], capsys)
    assert 'AFFIRME une espèce sur 1 image' in sortie


def test_le_seuil_est_inclusif(capsys):
    assert 'AFFIRME' in _verdict([0.70, 0.01, 0.01], capsys)


def test_le_plancher_est_inclusif(capsys):
    # 0,10 pile n'est pas « sous le plancher » : la cascade le laisse passer.
    sortie = _verdict([0.10, 0.10, 0.10], capsys)
    assert 'un message suffirait' in sortie


def test_les_seuils_se_reglent(capsys):
    # Le même échantillon, lu avec le seuil d'une autre version de la
    # cascade, ne doit pas rendre le même verdict.
    assert 'chantier pour rien' in _verdict([0.3, 0.2, 0.25], capsys, plancher=0.5, seuil=0.9)


def test_les_categories_ne_sont_pas_des_plantes():
    """Une catégorie qui en contiendrait invaliderait toute la mesure."""
    suspects = ('plant', 'flower', 'tree', 'garden', 'leaf', 'flora', 'botan')
    for c in CATEGORIES:
        assert not any(m in c.lower() for m in suspects), c
    assert len(CATEGORIES) >= 6, 'assez variées pour ne pas mesurer un seul sujet'
