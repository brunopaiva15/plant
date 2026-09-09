"""Le tri des espèces candidates avant d'engager une collecte.

Agrandir le catalogue coûte du top-1 quand les espèces ajoutées n'ont pas
d'images : elles entrent au catalogue, sortent du modèle par `--min-train`,
et il ne reste que le coût. Ce tri distingue les quatre sorts possibles,
parce qu'ils appellent quatre décisions différentes.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from disponibilite import SEUIL, verdict  # noqa: E402


def test_les_quatre_populations_sont_separees():
    r = verdict({'Solide sp': 400, 'Maigre sp': 10, 'Vide sp': 0, 'Inconnue sp': -1}, seuil=25)
    assert r['solides'] == ['Solide sp']
    assert r['maigres'] == ['Maigre sp']
    assert r['vides'] == ['Vide sp']
    assert r['absentes'] == ['Inconnue sp']


def test_un_nom_non_resolu_nest_pas_une_espece_sans_photo():
    """-1 veut dire « GBIF ne connaît pas ce nom » : c'est `synonyms.txt` qui
    répond, pas une collecte. Zéro veut dire « connue, jamais photographiée »,
    et là c'est la collecte qui passerait pour rien."""
    r = verdict({'Citrus limon': -1, 'Rara avis': 0})
    assert r['absentes'] == ['Citrus limon'] and r['vides'] == ['Rara avis']
    assert r['maigres'] == [] and r['solides'] == []


def test_le_seuil_est_celui_de_l_entrainement():
    """Une espèce exactement au seuil est gardée : `--min-train` compare avec
    un supérieur ou égal."""
    r = verdict({'Juste sp': SEUIL, 'Juste dessous sp': SEUIL - 1})
    assert r['solides'] == ['Juste sp']
    assert r['maigres'] == ['Juste dessous sp']


def test_seules_les_solides_comptent_dans_la_mediane():
    """Sinon une traîne d'espèces vides ferait passer la médiane à zéro et
    condamnerait un catalogue par ailleurs sain."""
    r = verdict({'A a': 100, 'B b': 300, 'C c': 0, 'D d': 0, 'E e': -1})
    assert r['mediane'] == 200
    assert r['demandees'] == 5


def test_les_maigres_sortent_les_plus_proches_du_seuil_en_premier():
    """C'est là qu'une passe de collecte supplémentaire peut faire basculer."""
    r = verdict({'Loin sp': 2, 'Proche sp': 24, 'Milieu sp': 12}, seuil=25)
    assert r['maigres'] == ['Proche sp', 'Milieu sp', 'Loin sp']


def test_un_catalogue_vide_ne_casse_pas():
    r = verdict({})
    assert r['demandees'] == 0 and r['mediane'] == 0 and r['solides'] == []
