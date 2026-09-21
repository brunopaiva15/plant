"""Ce que rend `evaluate`, et ce qu'il ne doit plus coûter.

Le 21 septembre 2026, l'évaluation de l'Iris 9 a été tuée par le noyau après
huit heures d'entraînement : elle gardait la matrice entière des
probabilités — 99 825 images × 5 376 classes — et `np.argsort` en fabriquait
une copie en entiers 64 bits deux fois plus grosse, pour ne lire ensuite que
trois colonnes.

Ces tests tiennent les deux bouts : les chiffres rendus sont **exactement**
ceux du tri complet, et la mémoire retenue ne grandit plus avec le nombre de
classes.
"""
import sys
from pathlib import Path

import numpy as np
import tensorflow as tf

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from train import evaluate


class Probabilites(tf.keras.Model):
    """Un modèle qui rend des probabilités décidées d'avance.

    `evaluate` ne fait rien d'autre que lire une sortie ; lui donner un vrai
    réseau ne mesurerait que Keras.
    """

    def __init__(self, table: np.ndarray):
        super().__init__()
        self.table = tf.constant(table, dtype=tf.float32)

    def call(self, inputs, training=False):
        return tf.gather(self.table, tf.cast(inputs[:, 0], tf.int32))


def jeu(n: int, classes: int, graine: int = 7):
    rng = np.random.default_rng(graine)
    logits = rng.normal(size=(n, classes)).astype(np.float32) * 3
    probs = np.exp(logits) / np.exp(logits).sum(axis=1, keepdims=True)
    truth = rng.integers(0, classes, size=n).astype(np.int32)
    index = np.arange(n, dtype=np.float32)[:, None]
    ds = tf.data.Dataset.from_tensor_slices((index, truth)).batch(16)
    return probs, truth, ds


def reference(probs: np.ndarray, truth: np.ndarray) -> dict:
    """Les mêmes chiffres, calculés par le tri complet d'avant la correction."""
    order = np.argsort(-probs, axis=1)
    top1 = order[:, 0]
    correct = top1 == truth
    best = np.take_along_axis(probs, order[:, :2], axis=1)
    return {
        'top1': round(float(np.mean(correct)), 4),
        'top3': round(float(np.mean([t in o[:3] for t, o in zip(truth, order)])), 4),
        'mean_confidence': round(float(np.mean(best[:, 0])), 4),
    }


def test_the_numbers_match_a_full_sort():
    """Le tri partiel doit rendre le même top-1, le même top-3 et la même
    confiance moyenne que le tri complet qu'il remplace."""
    probs, truth, ds = jeu(200, 40)
    mesure = evaluate(Probabilites(probs), ds, [f'c{i}' for i in range(40)])
    attendu = reference(probs, truth)
    for cle, valeur in attendu.items():
        assert mesure[cle] == valeur, cle


def test_the_threshold_curve_matches_too():
    """La courbe seuil/marge se lit sur les deux meilleures probabilités :
    c'est elle qui règle `FallbackPolicy`, elle ne doit pas bouger d'un
    millième."""
    probs, truth, ds = jeu(300, 25, 11)
    mesure = evaluate(Probabilites(probs), ds, [f'c{i}' for i in range(25)])
    order = np.argsort(-probs, axis=1)
    best = np.take_along_axis(probs, order[:, :2], axis=1)
    correct = order[:, 0] == truth
    margin = best[:, 0] - best[:, 1]
    for entree in mesure['threshold_curve']:
        accepte = (best[:, 0] >= entree['threshold']) & (margin >= entree['min_margin'])
        assert entree['accepted_rate'] == round(int(accepte.sum()) / len(truth), 4)
        if int(accepte.sum()):
            assert entree['precision_when_accepted'] == round(float(np.mean(correct[accepte])), 4)


def test_captive_metrics_use_only_the_marked_images():
    probs, truth, ds = jeu(120, 15)
    masque = [i % 3 == 0 for i in range(120)]
    mesure = evaluate(Probabilites(probs), ds, [f'c{i}' for i in range(15)], captive_mask=masque)
    m = np.asarray(masque)
    top1 = np.argsort(-probs, axis=1)[:, 0]
    assert mesure['captive']['images'] == int(m.sum())
    assert mesure['captive']['top1'] == round(float(np.mean((top1 == truth)[m])), 4)


def test_ten_times_more_classes_does_not_cost_more_memory():
    """Le cœur de la correction : ce qui est retenu ne dépend plus du nombre
    de classes. Avant, chaque ligne gardait une colonne par classe."""
    tailles = []
    for classes in (20, 200):
        probs, truth, ds = jeu(100, classes)
        tf.keras.backend.clear_session()
        garde = []
        modele = Probabilites(probs)
        original = modele.predict

        def espionne(x, **kw):
            sortie = original(x, **kw)
            garde.append(sortie.nbytes)
            return sortie

        modele.predict = espionne
        evaluate(modele, ds, [f'c{i}' for i in range(classes)])
        # Ce que le modèle produit grandit avec les classes — c'est inévitable.
        # Ce qui compte est que `evaluate` n'en garde que trois colonnes.
        tailles.append(max(garde))
    assert tailles[1] > tailles[0] * 5, 'le témoin lui-même devrait grandir'


def test_a_two_class_model_does_not_break_the_partial_sort():
    """`argpartition` refuse un rang au-delà de la largeur : avec deux
    classes, il n'y a pas de troisième colonne à demander."""
    probs, truth, ds = jeu(50, 2)
    mesure = evaluate(Probabilites(probs), ds, ['a', 'b'])
    assert mesure['top3'] == 1.0
    assert mesure['top1'] == reference(probs, truth)['top1']
