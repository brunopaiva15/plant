"""Le basculement float16 → float32 avant l'export.

La précision mixte double le débit sur une carte à cœurs tensor, mais le
convertisseur TFLite ne sait pas convertir un graphe en float16 : il réclame
des « flex ops » que l'application n'embarque pas. On reconstruit donc le
réseau en float32 et on y repose les poids appris.

C'est un transfert de poids entre deux objets distincts : s'il se décalait
d'une couche, le modèle exporté resterait plausible — même taille, mêmes
sorties bien formées — et serait faux. D'où ces tests.
"""
import sys
from pathlib import Path

import numpy as np
import tensorflow as tf

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from train import IMAGE_SIZE, build_model  # noqa: E402


def teardown_function():
    tf.keras.mixed_precision.set_global_policy('float32')


def test_la_tete_reste_en_float32_meme_en_precision_mixte():
    """Un softmax en float16 déborde dès que les logits dépassent ~11, et ce
    sont ces probabilités qui servent de seuil à l'application."""
    tf.keras.mixed_precision.set_global_policy('mixed_float16')
    model = build_model(5, 0.3, 'small')
    assert model.get_layer('species').dtype_policy.name == 'float32'
    assert model.outputs[0].dtype == tf.float32


def test_le_reseau_reconstruit_en_float32_rend_les_memes_sorties():
    """Le cœur du basculement : mêmes poids, mêmes réponses."""
    tf.keras.mixed_precision.set_global_policy('mixed_float16')
    mixte = build_model(5, 0.0, 'small')
    poids = mixte.get_weights()

    tf.keras.mixed_precision.set_global_policy('float32')
    clair = build_model(5, 0.0, 'small')
    clair.set_weights(poids)

    image = tf.random.stateless_uniform([2, IMAGE_SIZE, IMAGE_SIZE, 3], seed=[3, 7], maxval=255)
    ecart = np.abs(mixte(image, training=False).numpy() - clair(image, training=False).numpy()).max()
    # Le calcul intermédiaire diffère (float16 contre float32) ; les
    # probabilités, elles, doivent coïncider à la précision du float16 près.
    assert ecart < 2e-2, f'les deux réseaux ne répondent pas la même chose (écart {ecart})'


def test_les_poids_transferes_sont_bien_les_memes():
    """Un décalage d'une couche passerait le test de sortie sur un réseau
    non entraîné ; ici on compare tenseur par tenseur."""
    tf.keras.mixed_precision.set_global_policy('mixed_float16')
    mixte = build_model(5, 0.0, 'small')
    poids = mixte.get_weights()

    tf.keras.mixed_precision.set_global_policy('float32')
    clair = build_model(5, 0.0, 'small')
    clair.set_weights(poids)

    for avant, apres in zip(poids, clair.get_weights()):
        assert avant.shape == apres.shape
        assert np.array_equal(avant, apres)
    assert all(w.dtype == np.float32 for w in clair.get_weights()), 'les poids exportés doivent être en float32'
