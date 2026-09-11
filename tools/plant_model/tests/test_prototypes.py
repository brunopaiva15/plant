"""L'étage cultivar tient ou tombe sur une question : l'embedding
sépare-t-il deux cultivars d'une même espèce ?

Le doute est fondé. Chaque photo de « Thai Constellation » de notre jeu est
étiquetée *Monstera deliciosa* : le réglage fin pousse l'embedding à faire
converger le cultivar panaché et la plante ordinaire. Ces tests vérifient
que la mesure dirait la vérité dans les deux cas — qu'elle voit la
séparation quand elle existe, et le vide quand il n'y a rien.
"""
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from prototypes import normaliser, prototypes, separabilite, temoin  # noqa: E402


def _amas(centre, n, bruit=0.02, graine=0):
    r = np.random.default_rng(graine)
    return np.asarray(centre, dtype=np.float32) + r.normal(0, bruit, (n, len(centre))).astype(np.float32)


def test_des_cultivars_bien_separes_donnent_un_ecart_franc():
    v = np.vstack([_amas([1, 0, 0], 5, graine=1), _amas([0, 1, 0], 5, graine=2)])
    r = separabilite(v, ['Thai'] * 5 + ['Albo'] * 5)
    assert r['ecart'] > 0.9
    assert r['justesse_prototype'] == 1.0


def test_sur_du_bruit_le_test_de_permutation_ne_crie_pas_victoire():
    # Le vrai nul : des étiquettes tirées **indépendamment** des vecteurs.
    # (Découper un échantillon de bruit en deux moitiés contiguës n'est pas
    # un nul : une moitié a toujours une moyenne un peu différente de
    # l'autre, et le test le détecte à juste titre.)
    ps = []
    for graine in range(5):
        r = np.random.default_rng(100 + graine)
        v = _amas([1, 0, 0], 12, bruit=0.3, graine=graine)
        etiquettes = list(r.choice(['Thai', 'Albo'], size=12))
        ps.append(temoin(v, etiquettes, melanges=150)['p_prototype'])
    assert sorted(ps)[len(ps) // 2] > 0.05, f'sans structure, la valeur-p ne doit pas être petite : {ps}'


def test_une_vraie_separation_descend_au_plancher():
    v = np.vstack([_amas([1, 0, 0], 6, graine=1), _amas([0, 1, 0], 6, graine=2)])
    etiquettes = ['Thai'] * 6 + ['Albo'] * 6
    t = temoin(v, etiquettes, melanges=200)
    assert t['p_prototype'] <= 0.01
    assert t['justesse_moyenne'] < 0.8, 'le mélange doit être nettement moins bon'


def test_la_justesse_laisse_vraiment_une_photo_de_cote():
    # Avec un seul exemplaire par cultivar, un prototype calculé sur toutes
    # les photos retrouverait tout ; en laissant celle-ci de côté, il n'a
    # plus rien à quoi la rattacher.
    v = np.vstack([_amas([1, 0, 0], 1, graine=4), _amas([0, 1, 0], 1, graine=5)])
    r = separabilite(v, ['Thai', 'Albo'])
    assert r['classables'] == 0 and r['justesse_prototype'] is None


def test_le_prototype_est_la_moyenne_normalisee():
    p = prototypes(np.asarray([[2.0, 0, 0], [0, 2.0, 0]]), ['a', 'a'])
    assert set(p) == {'a'}
    assert abs(np.linalg.norm(p['a']) - 1.0) < 1e-5
    assert abs(p['a'][0] - p['a'][1]) < 1e-5, 'les deux directions pèsent pareil'


def test_un_cultivar_par_prototype_et_pas_un_de_plus():
    p = prototypes(np.eye(3, dtype=np.float32), ['Thai', 'Albo', 'Thai'])
    assert sorted(p) == ['Albo', 'Thai']


def test_la_normalisation_ne_divise_pas_par_zero():
    assert np.all(np.isfinite(normaliser(np.zeros((2, 4), dtype=np.float32))))
