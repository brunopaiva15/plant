"""Le cache d'activations du réseau gelé.

Pendant la phase de tête, le réseau ne bouge pas : ses sorties sont les mêmes
à chaque époque. Les calculer une fois et les relire est ce qui rend la phase
de tête tenable sans carte graphique. Deux choses doivent tenir : le cache se
relit quand rien n'a changé, et il se refait dès que le jeu ou les classes
changent — un cache périmé entraînerait la tête sur d'autres images que
celles annoncées.
"""
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from train import encoded, fit_head  # noqa: E402


def build_once(calls, n=64, dim=16):
    def build():
        calls.append(1)
        rng = np.random.default_rng(len(calls))
        return rng.random((n, dim), dtype=np.float32).astype(np.float16), rng.integers(0, 4, n)
    return build


def test_le_cache_evite_le_second_encodage(tmp_path):
    calls = []
    signature = {'backbone': 'large', 'images': 64}
    x1, y1 = encoded(tmp_path, 'train', signature, build_once(calls))
    x2, y2 = encoded(tmp_path, 'train', signature, build_once(calls))
    assert len(calls) == 1, 'le second appel a réencodé au lieu de relire'
    assert np.array_equal(x1, x2) and np.array_equal(y1, y2)


def test_le_cache_se_refait_quand_le_jeu_change(tmp_path):
    calls = []
    encoded(tmp_path, 'train', {'backbone': 'large', 'images': 64}, build_once(calls))
    encoded(tmp_path, 'train', {'backbone': 'large', 'images': 65}, build_once(calls))
    assert len(calls) == 2, 'un cache périmé a été relu'


def test_sans_dossier_de_cache_on_encode_a_chaque_fois(tmp_path):
    calls = []
    encoded(None, 'train', {}, build_once(calls))
    encoded(None, 'train', {}, build_once(calls))
    assert len(calls) == 2


def test_les_poids_de_tete_ont_la_forme_du_modele_complet():
    """`fit_head` entraîne une tête à part ; ses poids sont reposés tels quels
    dans le modèle complet. Les formes doivent correspondre exactement."""
    rng = np.random.default_rng(0)
    x, y = rng.random((80, 32), dtype=np.float32).astype(np.float16), rng.integers(0, 5, 80)
    xv, yv = rng.random((20, 32), dtype=np.float32).astype(np.float16), rng.integers(0, 5, 20)
    kernel, bias = fit_head(x, y, (xv, yv), 5, 0.3, 1, {i: 1.0 for i in range(5)}, 4)
    assert kernel.shape == (32, 5)
    assert bias.shape == (5,)
