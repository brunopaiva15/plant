"""Le contrôle des jumeaux du banc."""
import numpy as np

from fuite import au_dessus, plus_proches


def test_le_plus_proche_est_trouve_a_travers_les_paquets():
    rng = np.random.default_rng(0)
    corpus = rng.normal(size=(1000, 16)).astype(np.float32)
    requetes = corpus[[3, 777]] * 2.0          # la même direction, une autre norme
    sims, ou = plus_proches(requetes, corpus, paquet=100)
    assert list(ou) == [3, 777]
    assert np.allclose(sims, 1.0, atol=1e-5)


def test_une_photo_differente_reste_sous_les_seuils():
    rng = np.random.default_rng(1)
    corpus = rng.normal(size=(500, 64)).astype(np.float32)
    sims, _ = plus_proches(rng.normal(size=(20, 64)).astype(np.float32), corpus)
    assert au_dessus(sims)[0.90] == 0


def test_les_seuils_se_comptent():
    assert au_dessus(np.array([0.5, 0.92, 0.96, 0.995])) == {0.90: 3, 0.95: 2, 0.97: 1, 0.99: 1}
