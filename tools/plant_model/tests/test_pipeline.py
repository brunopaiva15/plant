"""Le mélange de la liste d'images, avant qu'elle n'atteigne tf.data.

Le jeu est écrit trié par espèce. Sans mélange global, un tampon de quelques
milliers d'éléments ne couvre qu'une poignée d'espèces, chaque lot devient
presque monospécifique, et le modèle apprend à deviner parmi dix classes.
"""
import random
import sys
from collections import Counter
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from train import SHUFFLE_SEED  # noqa: E402


def species_sorted_pairs(species: int = 500, per_species: int = 100):
    """Comme splits.csv : toutes les images d'une espèce se suivent."""
    return [(f'{s:03d}/{i}.jpg', s) for s in range(species) for i in range(per_species)]


def shuffle_like_training(pairs):
    pairs = list(pairs)
    random.Random(SHUFFLE_SEED).shuffle(pairs)
    return pairs


def distinct_species_in_window(pairs, window: int) -> int:
    return len({label for _, label in pairs[:window]})


def test_unshuffled_order_would_starve_a_shuffle_buffer():
    """Le constat qui a motivé la correction : sans mélange, un tampon de
    4096 éléments ne voit que quelques dizaines d'espèces sur 500."""
    assert distinct_species_in_window(species_sorted_pairs(), 4096) <= 45


def test_shuffling_spreads_species_across_the_buffer():
    pairs = shuffle_like_training(species_sorted_pairs())
    assert distinct_species_in_window(pairs, 4096) > 450


def test_a_batch_is_no_longer_almost_single_species():
    pairs = shuffle_like_training(species_sorted_pairs())
    batch = pairs[:32]
    counts = Counter(label for _, label in batch)
    assert len(counts) >= 28, f'{len(counts)} espèces dans un lot de 32'
    assert counts.most_common(1)[0][1] <= 3


def test_shuffle_keeps_every_image_exactly_once():
    original = species_sorted_pairs(50, 20)
    shuffled = shuffle_like_training(original)
    assert sorted(shuffled) == sorted(original)
    assert len(shuffled) == len(original)


def test_shuffle_is_reproducible():
    a = shuffle_like_training(species_sorted_pairs(50, 20))
    b = shuffle_like_training(species_sorted_pairs(50, 20))
    assert a == b, 'deux exécutions doivent partir du même ordre'
