"""Le cache d'activations du réseau gelé.

Pendant la phase de tête, le réseau ne bouge pas : ses sorties sont les mêmes
à chaque époque. Les calculer une fois et les relire est ce qui rend la phase
de tête tenable sans carte graphique. Deux choses doivent tenir : le cache se
relit quand rien n'a changé, et il se refait dès que le jeu ou les classes
changent — un cache périmé entraînerait la tête sur d'autres images que
celles annoncées.
"""
import json
import sys
from pathlib import Path

import numpy as np
import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from train import encoded, fit_head  # noqa: E402


def encoder(calls, n=64, dim=16, die_after=None):
    """Un encodeur factice : écrit des vecteurs dans le fichier memmap, comme
    le vrai, et peut s'interrompre en chemin pour éprouver la reprise."""
    def run(x_path, y_path, mark, done):
        calls.append(done)
        if x_path is None:
            rng = np.random.default_rng(0)
            return rng.random((n, dim), dtype=np.float32).astype(np.float16), np.arange(n), None
        x = np.lib.format.open_memmap(x_path, mode='r+' if done else 'w+',
                                      dtype=np.float16, shape=(n, dim))
        y = np.lib.format.open_memmap(y_path, mode='r+' if done else 'w+',
                                      dtype=np.int32, shape=(n,))
        stop = n if die_after is None else min(n, done + die_after)
        for i in range(done, stop):
            x[i] = np.float16(i)
            y[i] = i
        x.flush()
        y.flush()
        mark(stop)
        if stop < n:
            raise KeyboardInterrupt('la machine a disparu')
        return x, y, None
    return run


def test_le_cache_evite_le_second_encodage(tmp_path):
    calls = []
    signature = {'backbone': 'large', 'images': 64}
    x1, y1 = encoded(tmp_path, 'train', signature, encoder(calls))
    x2, y2 = encoded(tmp_path, 'train', signature, encoder(calls))
    assert len(calls) == 1, 'le second appel a réencodé au lieu de relire'
    assert np.array_equal(np.asarray(x1), np.asarray(x2))
    assert np.array_equal(np.asarray(y1), np.asarray(y2))


def test_un_encodage_interrompu_reprend_ou_il_s_est_arrete(tmp_path):
    """Le cas qui a coûté une heure : la machine disparaît au milieu de la
    passe. Ce qui est écrit doit rester acquis."""
    signature = {'backbone': 'large', 'images': 64}
    calls = []
    with pytest.raises(KeyboardInterrupt):
        encoded(tmp_path, 'train', signature, encoder(calls, die_after=40))
    assert json.loads((tmp_path / 'train.json').read_text())['done'] == 40

    reprises = []
    x, y = encoded(tmp_path, 'train', signature, encoder(reprises))
    assert reprises == [40], f'la reprise est repartie de {reprises}, pas de 40'
    assert np.array_equal(np.asarray(y), np.arange(64)), 'des vecteurs manquent ou sont mélangés'


def test_le_cache_se_refait_quand_le_jeu_change(tmp_path):
    calls = []
    encoded(tmp_path, 'train', {'backbone': 'large', 'images': 64}, encoder(calls))
    encoded(tmp_path, 'train', {'backbone': 'large', 'images': 65}, encoder(calls, n=65))
    assert calls == [0, 0], 'un cache périmé a été relu, ou repris à tort'


def test_sans_dossier_de_cache_on_encode_a_chaque_fois(tmp_path):
    calls = []
    encoded(None, 'train', {'images': 64}, encoder(calls))
    encoded(None, 'train', {'images': 64}, encoder(calls))
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
