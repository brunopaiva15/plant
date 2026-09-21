"""Le cache du teacher, sans PyTorch ni carte graphique.

Ce qui est testé ici est ce qui peut rendre un cache **faux sans le dire** :
une signature qui laisse mélanger deux prétraitements, un index qui oublie
une part, un centroïde calculé sur les images de mesure. L'inférence, elle,
ne se teste pas hors machine — elle est isolée dans `encoder`.
"""
import csv

import numpy as np
import pytest

from bioclip import (accorder_signature, accumuler, centroides, conf_du_transforme,
                     empreinte, extrapolation, lire_index, moyenne_unitaire, phrases,
                     restant, signature, tranche)


# --------------------------------------------------------------------------
# La signature
# --------------------------------------------------------------------------

def test_deux_tailles_dentree_ne_donnent_pas_la_meme_empreinte():
    """Le piège du § 20 bis : la clé porte le prétraitement, pas le chemin.
    Deux passes à des tailles différentes doivent être discernables."""
    a = signature('bioclip', 224, [0.5] * 3, [0.3] * 3)
    b = signature('bioclip', 336, [0.5] * 3, [0.3] * 3)
    assert a['empreinte'] != b['empreinte']


def test_la_normalisation_compte_dans_lempreinte():
    a = signature('bioclip', 224, [0.481, 0.457, 0.408], [0.268, 0.261, 0.275])
    b = signature('bioclip', 224, [0.5, 0.5, 0.5], [0.5, 0.5, 0.5])
    assert a['empreinte'] != b['empreinte']


def test_la_meme_configuration_rend_la_meme_empreinte():
    """Sans quoi une reprise refuserait son propre cache."""
    conf = ('bioclip', 224, [0.481, 0.457, 0.408], [0.268, 0.261, 0.275])
    assert signature(*conf)['empreinte'] == signature(*conf)['empreinte']


def test_lordre_des_cles_ne_change_pas_lempreinte():
    assert empreinte({'a': 1, 'b': 2}) == empreinte({'b': 2, 'a': 1})


def test_un_cache_neuf_recoit_sa_signature(tmp_path):
    sig = signature('bioclip', 224, [0.5] * 3, [0.3] * 3)
    accorder_signature(tmp_path / 'cache', sig)
    assert (tmp_path / 'cache' / 'signature.json').exists()


def test_un_cache_dune_autre_signature_est_refuse(tmp_path):
    """Le cœur du test : un cache mélangé ne se voit pas à l'usage, donc il
    faut qu'il ne puisse pas se fabriquer."""
    accorder_signature(tmp_path, signature('bioclip', 224, [0.5] * 3, [0.3] * 3))
    with pytest.raises(SystemExit):
        accorder_signature(tmp_path, signature('bioclip', 336, [0.5] * 3, [0.3] * 3))


def test_forcer_passe_outre(tmp_path):
    accorder_signature(tmp_path, signature('bioclip', 224, [0.5] * 3, [0.3] * 3))
    accorder_signature(tmp_path, signature('bioclip', 336, [0.5] * 3, [0.3] * 3),
                       forcer=True)


def test_la_taille_et_la_normalisation_se_lisent_dans_la_transformation():
    """On ne recopie pas les constantes du teacher, on les lui demande."""
    class Recadrage:
        size = (224, 224)
    Recadrage.__name__ = 'CenterCrop'

    class Normalisation:
        mean = [0.481, 0.457, 0.408]
        std = [0.268, 0.261, 0.275]
    Normalisation.__name__ = 'Normalize'

    class Chaine:
        transforms = [Recadrage(), Normalisation()]

    taille, moyenne, ecart = conf_du_transforme(Chaine())
    assert taille == 224
    assert moyenne == [0.481, 0.457, 0.408]
    assert ecart == [0.268, 0.261, 0.275]


# --------------------------------------------------------------------------
# L'index et les parts
# --------------------------------------------------------------------------

def index_ecrit(dossier, part, lignes):
    with open(dossier / f'index-{part}.csv', 'w', newline='', encoding='utf-8') as f:
        csv.writer(f).writerows(lignes)


def test_lindex_reunit_toutes_les_parts(tmp_path):
    """Deux nuits, deux parts, un seul cache : oublier une part ferait
    recalculer des vecteurs déjà payés."""
    index_ecrit(tmp_path, 0, [['/a.jpg', 'emb-0-0000', 0]])
    index_ecrit(tmp_path, 1, [['/b.jpg', 'emb-1-0000', 0]])
    index = lire_index(tmp_path)
    assert index == {'/a.jpg': ('emb-0-0000', 0), '/b.jpg': ('emb-1-0000', 0)}


def test_un_cache_vide_ne_rend_rien(tmp_path):
    assert lire_index(tmp_path) == {}


def test_la_reprise_ne_refait_que_ce_qui_manque():
    corpus = [('/a.jpg', 'x', '0'), ('/b.jpg', 'y', '0'), ('/c.jpg', 'z', '1')]
    assert restant(corpus, {'/a.jpg': ('emb-0-0000', 0)}) == corpus[1:]


def test_les_parts_sont_disjointes_et_couvrent_tout():
    items = list(range(10))
    parts = [tranche(items, i, 3) for i in range(3)]
    assert sorted(x for p in parts for x in p) == items
    assert all(set(a).isdisjoint(b) for i, a in enumerate(parts) for b in parts[i + 1:])


def test_les_parts_sont_entrelacees_pas_contigues():
    """`splits.csv` est rangé par espèce : des parts contiguës donneraient à
    l'une les classes riches et à l'autre les pauvres, et les deux machines
    ne finiraient pas en même temps."""
    assert tranche(list(range(6)), 0, 2) == [0, 2, 4]


def test_une_seule_part_rend_tout():
    assert tranche([1, 2, 3], 0, 1) == [1, 2, 3]


def test_une_part_hors_bornes_sarrete():
    with pytest.raises(SystemExit):
        tranche([1, 2, 3], 3, 3)


# --------------------------------------------------------------------------
# L'extrapolation
# --------------------------------------------------------------------------

def test_le_debit_sextrapole_au_corpus():
    e = extrapolation(100, 2.0, 900_000)
    assert e['images_par_seconde'] == 50.0
    assert e['heures'] == pytest.approx(5.0)


def test_le_disque_est_deux_octets_par_dimension():
    """1 024 dimensions en float16 = 2 Ko par image, le calcul du § 20 bis."""
    e = extrapolation(100, 1.0, 991_926)
    assert e['octets'] == 991_926 * 2048
    assert e['gio'] == pytest.approx(1.89, abs=0.02)


# --------------------------------------------------------------------------
# Les références textuelles
# --------------------------------------------------------------------------

def espece(**kw):
    base = {'internal_id': 'monstera-deliciosa', 'scientific_name': 'Monstera deliciosa',
            'genus': 'Monstera', 'epithet': 'deliciosa', 'family': 'Araceae',
            'common_en': 'Swiss cheese plant'}
    base.update(kw)
    return base


def test_lensemble_rend_les_trois_formulations():
    p = phrases(espece(), 'ensemble')
    assert p == ['a photo of Monstera deliciosa.',
                 'a photo of Plantae Araceae Monstera deliciosa.',
                 'a photo of Swiss cheese plant.']


def test_une_formulation_incomplete_est_sautee_pas_trouee():
    """Sans nom commun anglais, on ne veut pas « a photo of . » dans l'espace
    des références : c'est une direction qui ne décrit aucune plante."""
    p = phrases(espece(common_en=''), 'ensemble')
    assert len(p) == 2
    assert all('photo of .' not in x for x in p)


def test_une_espece_sans_genre_ne_rend_aucune_formulation():
    assert phrases(espece(genus='', common_en=''), 'binome') == []


def test_le_binome_seul_est_une_option():
    assert phrases(espece(), 'binome') == ['a photo of Monstera deliciosa.']


# --------------------------------------------------------------------------
# Les centroïdes
# --------------------------------------------------------------------------

def test_la_moyenne_est_unitaire():
    v = moyenne_unitaire(np.array([[3.0, 0.0], [0.0, 4.0]]))
    assert np.linalg.norm(v) == pytest.approx(1.0)


def test_chaque_vecteur_pese_pareil_quelle_que_soit_sa_norme():
    """Une formulation que le teacher encode avec une grande norme ne doit
    pas décider de la référence pour cette raison-là."""
    egaux = moyenne_unitaire(np.array([[1.0, 0.0], [0.0, 1.0]]))
    dont_un_geant = moyenne_unitaire(np.array([[100.0, 0.0], [0.0, 1.0]]))
    assert np.allclose(egaux, dont_un_geant)


def test_un_vecteur_nul_ne_fait_pas_diviser_par_zero():
    v = moyenne_unitaire(np.array([[0.0, 0.0], [1.0, 0.0]]))
    assert np.allclose(v, [1.0, 0.0])


def test_les_sommes_par_fragment_donnent_le_meme_centroide_quen_une_fois():
    """C'est ce qui autorise à ne jamais charger les deux gigaoctets."""
    vecteurs = np.array([[1.0, 0.0], [0.6, 0.8], [0.0, 1.0]])
    en_deux, c2 = {}, {}
    accumuler(en_deux, c2, ['a', 'a'], vecteurs[:2])
    accumuler(en_deux, c2, ['a'], vecteurs[2:])
    en_un, c1 = {}, {}
    accumuler(en_un, c1, ['a', 'a', 'a'], vecteurs)
    assert np.allclose(en_deux['a'], en_un['a']) and c2['a'] == c1['a'] == 3


def test_une_espece_trop_peu_photographiee_est_ecartee():
    sommes, comptes = {}, {}
    accumuler(sommes, comptes, ['riche'] * 6 + ['pauvre'] * 2,
              np.tile([1.0, 0.0], (8, 1)))
    cles, vecteurs, nombres = centroides(sommes, comptes, min_images=5)
    assert cles == ['riche'] and nombres == [6] and vecteurs.shape[0] == 1


def test_les_centroides_sortent_en_float16_normalise():
    sommes, comptes = {}, {}
    accumuler(sommes, comptes, ['a'] * 5, np.tile([3.0, 4.0], (5, 1)))
    _, vecteurs, _ = centroides(sommes, comptes, min_images=5)
    assert vecteurs.dtype == np.float16
    assert np.linalg.norm(vecteurs.astype(np.float32)[0]) == pytest.approx(1.0, abs=1e-3)


def test_aucune_espece_assez_riche_rend_un_tableau_vide():
    sommes, comptes = {}, {}
    accumuler(sommes, comptes, ['a'], np.array([[1.0, 0.0]]))
    cles, vecteurs, nombres = centroides(sommes, comptes, min_images=5)
    assert cles == [] and nombres == [] and vecteurs.shape[0] == 0
