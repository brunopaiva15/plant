"""Les cibles et le mélange, sans PyTorch ni timm.

Ce qui est testé ici est ce qui rendrait l'entraînement **faux sans le
dire** : une image appariée à la cible d'une autre, un lot monospécifique
dont la contrastive apprendrait le contraire de ce qu'on veut, un jeu plus
petit qu'annoncé.
"""
import csv

import numpy as np

from distiller import cibles, melanger, paires


def jeu(tmp_path, lignes):
    (tmp_path / 'img').mkdir(parents=True, exist_ok=True)
    with open(tmp_path / 'splits.csv', 'w', newline='', encoding='utf-8') as f:
        w = csv.DictWriter(f, fieldnames=['path', 'split', 'internal_plant_id'])
        w.writeheader()
        for chemin, split, espece in lignes:
            w.writerow({'path': chemin, 'split': split, 'internal_plant_id': espece})
    return tmp_path


def cache(tmp_path, chemins, vecteurs):
    tmp_path.mkdir(parents=True, exist_ok=True)
    np.save(tmp_path / 'emb-0-0000.npy', vecteurs.astype(np.float16))
    with open(tmp_path / 'index-0.csv', 'w', newline='', encoding='utf-8') as f:
        csv.writer(f).writerows([[c, 'emb-0-0000', i] for i, c in enumerate(chemins)])
    return tmp_path


def test_seul_lentrainement_sert_de_cible(tmp_path):
    """Apprendre sur le test rendrait toute mesure ultérieure fausse."""
    d = jeu(tmp_path / 'd', [('img/a.jpg', 'train', 'x'), ('img/b.jpg', 'test', 'y')])
    c = cache(tmp_path / 'c', [str(d / 'img/a.jpg'), str(d / 'img/b.jpg')],
              np.eye(2, 1024))
    assert [p[0] for p in paires(d, c)] == [str(d / 'img/a.jpg')]


def test_une_image_sans_cible_est_ecartee(tmp_path):
    """Elle n'a rien à apprendre ; l'approcher par un voisin fabriquerait une
    supervision inventée."""
    d = jeu(tmp_path / 'd', [('img/a.jpg', 'train', 'x'), ('img/b.jpg', 'train', 'y')])
    c = cache(tmp_path / 'c', [str(d / 'img/a.jpg')], np.eye(1, 1024))
    assert len(paires(d, c)) == 1


def test_chaque_image_recoit_sa_propre_cible(tmp_path):
    """Le défaut le plus coûteux possible : un décalage d'une ligne
    apprendrait au student la cible du voisin, et rien ne le signalerait."""
    d = jeu(tmp_path / 'd', [(f'img/{n}.jpg', 'train', 'x') for n in 'abc'])
    chemins = [str(d / f'img/{n}.jpg') for n in 'abc']
    vecteurs = np.zeros((3, 1024), dtype=np.float32)
    for i in range(3):
        vecteurs[i, i] = 1.0
    c = cache(tmp_path / 'c', chemins, vecteurs)
    lot = paires(d, c)
    rendues = cibles(c, lot)
    for i, (chemin, _, _) in enumerate(lot):
        attendu = chemins.index(chemin)
        assert rendues[i].argmax() == attendu


def test_les_fragments_sont_memorises_entre_les_lots(tmp_path):
    """Un fragment fait 16 Mo ; le relire à chaque lot pour trente-deux
    lignes coûterait plus cher que le réseau."""
    d = jeu(tmp_path / 'd', [(f'img/{n}.jpg', 'train', 'x') for n in 'ab'])
    c = cache(tmp_path / 'c', [str(d / f'img/{n}.jpg') for n in 'ab'], np.eye(2, 1024))
    lot = paires(d, c)
    memo = {}
    cibles(c, lot[:1], memo)
    assert list(memo) == ['emb-0-0000']
    cibles(c, lot[1:], memo)          # ne doit pas recharger
    assert list(memo) == ['emb-0-0000']


def test_le_melange_couvre_tout_sans_doublon():
    ordre = melanger(1000, 20260919)
    assert sorted(ordre.tolist()) == list(range(1000))


def test_le_melange_ne_garde_pas_lordre_des_especes():
    """`splits.csv` est trié par espèce : un lot non mélangé n'aurait que des
    négatifs de la même plante, et la contrastive apprendrait à séparer ce
    qu'il faut rapprocher."""
    ordre = melanger(1000, 20260919)
    assert not np.array_equal(ordre, np.arange(1000))
    assert abs(np.corrcoef(ordre, np.arange(1000))[0, 1]) < 0.15


def test_le_melange_est_reproductible():
    assert np.array_equal(melanger(500, 7), melanger(500, 7))
    assert not np.array_equal(melanger(500, 7), melanger(500, 8))
