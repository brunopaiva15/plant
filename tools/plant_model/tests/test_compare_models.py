"""Le comptage de `compare_models`, sans TensorFlow.

L'inférence est séparée du comptage (`predict_rows` / `tally`), et c'est le
comptage qui porte la subtilité : masquer ou non les classes que l'autre
modèle ignore ne répond pas à la même question, et l'un des deux chiffres
flatte le modèle le plus large.
"""
import numpy as np
import pytest

from compare_models import tally


def modele(labels: list[str], version: str = '8') -> dict:
    return {'labels': labels, 'index': {c: i for i, c in enumerate(labels)}, 'version': version}


def sortie(model: dict, scores: dict[str, float]) -> np.ndarray:
    p = np.zeros(len(model['labels']), dtype=np.float32)
    for c, v in scores.items():
        p[model['index'][c]] = v
    return p


def test_masking_does_not_change_the_ranking_of_what_remains():
    """La docstring l'affirme, et tout le reste en dépend : masquer ne
    réordonne pas les classes qui restent, il ne fait qu'en retirer."""
    m = modele(['monstera', 'ficus', 'inconnue'])
    pred = [('monstera', sortie(m, {'monstera': 0.5, 'ficus': 0.3, 'inconnue': 0.2}))]
    assert tally(pred, m, {'monstera', 'ficus'})['top1'] == 1.0
    assert tally(pred, m, None)['top1'] == 1.0


def test_a_new_class_can_steal_the_answer_when_nothing_is_masked():
    """Le cœur du problème : une espèce que l'ancien modèle ignorait peut
    prendre la première place. Le masque la retire, l'utilisateur non."""
    m = modele(['monstera', 'ficus', 'nouvelle'])
    pred = [('monstera', sortie(m, {'monstera': 0.35, 'ficus': 0.05, 'nouvelle': 0.6}))]
    assert tally(pred, m, {'monstera', 'ficus'})['top1'] == 1.0
    assert tally(pred, m, None)['top1'] == 0.0


def test_top3_counts_a_truth_ranked_third():
    m = modele(['a', 'b', 'c', 'd'])
    pred = [('d', sortie(m, {'a': 0.4, 'b': 0.3, 'd': 0.2, 'c': 0.1}))]
    r = tally(pred, m, None)
    assert r['top1'] == 0.0 and r['top3'] == 1.0


def test_acceptance_uses_the_app_threshold_of_070():
    m = modele(['a', 'b'])
    juste = [('a', sortie(m, {'a': 0.71, 'b': 0.29}))]
    limite = [('a', sortie(m, {'a': 0.69, 'b': 0.31}))]
    assert tally(juste, m, None)['accepted_rate'] == 1.0
    assert tally(limite, m, None)['accepted_rate'] == 0.0
    assert tally(limite, m, None)['precision_when_accepted'] is None


def test_precision_when_accepted_counts_only_accepted_answers():
    m = modele(['a', 'b'])
    pred = [('a', sortie(m, {'a': 0.9, 'b': 0.1})),      # acceptée, juste
            ('b', sortie(m, {'a': 0.8, 'b': 0.2})),      # acceptée, fausse
            ('a', sortie(m, {'a': 0.6, 'b': 0.4}))]      # sous le seuil, ignorée
    r = tally(pred, m, None)
    assert r['accepted_rate'] == round(2 / 3, 4)
    assert r['precision_when_accepted'] == 0.5


def test_renormalising_raises_autonomy_without_touching_top1():
    """Sans renormaliser, la masse partie aux classes masquées ne revient à
    personne et l'autonomie mesurée est artificiellement basse."""
    m = modele(['a', 'b', 'masquee'])
    pred = [('a', sortie(m, {'a': 0.5, 'b': 0.1, 'masquee': 0.4}))]
    brut = tally(pred, m, {'a', 'b'})
    renorme = tally(pred, m, {'a', 'b'}, renormalise=True)
    assert brut['top1'] == renorme['top1'] == 1.0
    assert brut['accepted_rate'] == 0.0        # 0,5 reste sous 0,70
    assert renorme['accepted_rate'] == 1.0     # 0,5 / 0,6 = 0,83


def test_images_of_unknown_species_are_not_counted():
    """`predict_rows` les écarte ; `tally` ne voit que ce qu'on lui donne."""
    m = modele(['a', 'b'])
    assert tally([], m, None)['images'] == 0
    assert tally([], m, None)['top1'] is None


@pytest.mark.parametrize('restrict', [None, {'a', 'b'}])
def test_tally_does_not_modify_the_probabilities_it_is_given(restrict):
    """Deux lectures se font sur la même passe d'inférence : la première ne
    doit pas abîmer les tableaux que la seconde va relire."""
    m = modele(['a', 'b', 'c'])
    probs = sortie(m, {'a': 0.5, 'b': 0.2, 'c': 0.3})
    avant = probs.copy()
    tally([('a', probs)], m, restrict, renormalise=True)
    assert np.array_equal(probs, avant)


def test_the_threshold_is_a_parameter_not_a_constant():
    """Choisir le seuil de `FallbackPolicy` demande de le balayer : une réponse
    à 0,62 est refusée à 0,70 et acceptée à 0,60, et c'est tout l'objet du
    réglage."""
    m = modele(['a', 'b'])
    pred = [('a', sortie(m, {'a': 0.62, 'b': 0.38}))]
    assert tally(pred, m, None, seuil=0.70)['accepted_rate'] == 0.0
    assert tally(pred, m, None, seuil=0.60)['accepted_rate'] == 1.0
    # Le seuil ne touche pas au classement.
    assert tally(pred, m, None, seuil=0.90)['top1'] == 1.0


def test_restricting_and_renormalising_is_what_a_narrowed_app_would_render():
    """La configuration visée : masquer aux espèces du catalogue, rendre la
    masse retirée, puis appliquer le seuil. Sans renormaliser, la même réponse
    paraît moins sûre qu'elle ne l'est."""
    m = modele(['fiche', 'autre-fiche', 'hors-catalogue'])
    pred = [('fiche', sortie(m, {'fiche': 0.45, 'autre-fiche': 0.15, 'hors-catalogue': 0.4}))]
    catalogue = {'fiche', 'autre-fiche'}
    assert tally(pred, m, catalogue, seuil=0.70)['accepted_rate'] == 0.0
    renorme = tally(pred, m, catalogue, renormalise=True, seuil=0.70)
    assert renorme['accepted_rate'] == 1.0          # 0,45 / 0,60 = 0,75
    assert renorme['precision_when_accepted'] == 1.0
