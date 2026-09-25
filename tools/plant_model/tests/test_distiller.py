"""Les cibles et le mélange, sans PyTorch ni timm.

Ce qui est testé ici est ce qui rendrait l'entraînement **faux sans le
dire** : une image appariée à la cible d'une autre, un lot monospécifique
dont la contrastive apprendrait le contraire de ce qu'on veut, un jeu plus
petit qu'annoncé.
"""
import csv

import numpy as np
import pytest

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


# --------------------------------------------------------------------------
# Plusieurs corpus dans une même passe
# --------------------------------------------------------------------------

def test_deux_jeux_se_concatenent(tmp_path):
    """La distillation ne lit pas d'étiquette : deux corpus s'additionnent
    sans aligner un seul catalogue (§ 20 ter de docs/14)."""
    from distiller import corpus
    d1 = jeu(tmp_path / 'd1', [('img/a.jpg', 'train', 'x')])
    d2 = jeu(tmp_path / 'd2', [('img/b.jpg', 'train', 'pn:9999')])
    c = cache(tmp_path / 'c', [str(d1 / 'img/a.jpg'), str(d2 / 'img/b.jpg')],
              np.eye(2, 1024))
    assert {p[0] for p in corpus([d1, d2], c)} == {str(d1 / 'img/a.jpg'),
                                                   str(d2 / 'img/b.jpg')}


def test_le_meme_jeu_deux_fois_ne_double_pas_lepoque(tmp_path):
    """Deux corpus qui se recouvrent entraîneraient deux fois sur les mêmes
    images, et l'époque durerait plus longtemps pour rien."""
    from distiller import corpus
    d = jeu(tmp_path / 'd', [('img/a.jpg', 'train', 'x')])
    c = cache(tmp_path / 'c', [str(d / 'img/a.jpg')], np.eye(1, 1024))
    assert len(corpus([d, d], c)) == 1


# --------------------------------------------------------------------------
# Une reprise ne renégocie pas la recette
# --------------------------------------------------------------------------

def test_un_poids_contrastif_different_arrete_la_reprise():
    """Un dorsal différent ferait échouer le chargement des poids, donc
    bruyamment. Le poids contrastif passerait sans un mot, et la passe
    finirait sous une recette que personne n'a décidée."""
    from distiller import desaccord_de_reprise
    assert 'contrastive' in desaccord_de_reprise(
        {'student': 'fastvit_sa12', 'contrastive': 0.2}, 'fastvit_sa12', 0.5)


def test_un_dorsal_different_arrete_la_reprise():
    from distiller import desaccord_de_reprise
    assert 'dorsal' in desaccord_de_reprise(
        {'student': 'fastvit_sa12', 'contrastive': 0.2}, 'mobilenetv4_conv_large', 0.2)


def test_la_meme_recette_reprend_sans_rien_dire():
    from distiller import desaccord_de_reprise
    assert desaccord_de_reprise(
        {'student': 'fastvit_sa12', 'contrastive': 0.2}, 'fastvit_sa12', 0.2) == ''


def test_un_etat_ancien_sans_recette_ne_bloque_pas():
    """Les points de contrôle écrits avant que l'état porte la recette se
    reprennent encore : on ne casse pas une passe en cours pour un champ."""
    from distiller import desaccord_de_reprise
    assert desaccord_de_reprise({'epoque': 3}, 'fastvit_sa12', 0.2) == ''


# --------------------------------------------------------------------------
# Le calendrier de taux
# --------------------------------------------------------------------------

def test_le_calendrier_constant_reproduit_les_passes_du_22():
    """Sans quoi une reprise d'`iris10-complet` changerait de recette."""
    from distiller import taux_du_pas
    assert all(taux_du_pas(p, 100, 1e-3) == 1e-3 for p in (0, 50, 99, 100))


def test_le_cosinus_part_de_la_base_et_finit_a_zero():
    from distiller import taux_du_pas
    assert taux_du_pas(0, 100, 1e-3, 'cosinus') == pytest.approx(1e-3)
    assert taux_du_pas(50, 100, 1e-3, 'cosinus') == pytest.approx(5e-4)
    assert taux_du_pas(100, 100, 1e-3, 'cosinus') == pytest.approx(0.0, abs=1e-12)


def test_le_cosinus_ne_remonte_jamais():
    """Un taux qui remonte en fin de passe défait ce que la descente a
    gagné, et c'est précisément la fin de passe qu'on veut soigner."""
    from distiller import taux_du_pas
    taux = [taux_du_pas(p, 1000, 1e-3, 'cosinus') for p in range(1001)]
    assert all(a >= b for a, b in zip(taux, taux[1:]))


def test_un_pas_hors_passe_ne_sort_pas_des_bornes():
    from distiller import taux_du_pas
    assert taux_du_pas(-5, 100, 1e-3, 'cosinus') == pytest.approx(1e-3)
    assert taux_du_pas(150, 100, 1e-3, 'cosinus') == pytest.approx(0.0, abs=1e-12)


def test_un_calendrier_inconnu_ne_passe_pas_en_silence():
    from distiller import taux_du_pas
    with pytest.raises(ValueError):
        taux_du_pas(0, 100, 1e-3, 'lineaire')


def test_un_calendrier_different_arrete_la_reprise():
    from distiller import desaccord_de_reprise
    assert 'calendrier' in desaccord_de_reprise(
        {'student': 'fastvit_sa12', 'contrastive': 0.2}, 'fastvit_sa12', 0.2, 'cosinus')


def test_un_etat_sans_calendrier_a_tourne_a_taux_constant():
    """Les passes du 22 septembre n'écrivaient pas leur calendrier : elles se
    reprennent en constant sans objection, et refusent le cosinus."""
    from distiller import desaccord_de_reprise
    etat = {'student': 'fastvit_sa12', 'contrastive': 0.2}
    assert desaccord_de_reprise(etat, 'fastvit_sa12', 0.2, 'constant') == ''


# --------------------------------------------------------------------------
# La taille d'entrée
# --------------------------------------------------------------------------

def test_une_entree_differente_arrete_la_reprise():
    from distiller import desaccord_de_reprise
    etat = {'student': 'fastvit_sa12', 'contrastive': 0.2, 'calendrier': 'cosinus',
            'entree': 224}
    assert 'entrée' in desaccord_de_reprise(etat, 'fastvit_sa12', 0.2, 'cosinus', 320)


def test_un_etat_sans_entree_a_tourne_a_224():
    """Les passes jusqu'au 25 septembre n'écrivaient pas leur taille : elles se
    reprennent à 224 sans objection, et refusent 320."""
    from distiller import desaccord_de_reprise
    etat = {'student': 'fastvit_sa12', 'contrastive': 0.2, 'calendrier': 'cosinus'}
    assert desaccord_de_reprise(etat, 'fastvit_sa12', 0.2, 'cosinus') == ''
    assert desaccord_de_reprise(etat, 'fastvit_sa12', 0.2, 'cosinus', 224) == ''
    assert 'entrée' in desaccord_de_reprise(etat, 'fastvit_sa12', 0.2, 'cosinus', 320)
