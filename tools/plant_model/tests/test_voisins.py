"""Le classement par référence la plus proche, sans cache ni teacher.

Ce qui est testé ici est ce qui rendrait la porte C **faussement gagnante** :
une espèce comptée deux fois parce qu'elle a deux références, un répertoire
plus large présenté comme un gain de justesse, une image absente du cache
comptée comme une erreur.
"""
import csv

import numpy as np
import pytest

from voisins import (charger_references, classer, compter, degrader,
                     lire_embeddings, restreindre, sans_suffixe)


def unitaire(*v) -> np.ndarray:
    a = np.array(v, dtype=np.float32)
    return a / np.linalg.norm(a)


# --------------------------------------------------------------------------
# Les références multiples d'une même espèce
# --------------------------------------------------------------------------

def test_le_suffixe_captive_designe_la_meme_espece():
    assert sans_suffixe('monstera-deliciosa#captive') == 'monstera-deliciosa'
    assert sans_suffixe('monstera-deliciosa') == 'monstera-deliciosa'


def test_deux_references_dune_espece_ne_font_quune_classe():
    """Sinon le top-1 compterait une bonne réponse comme fausse : la vérité
    est `monstera-deliciosa`, la tête rendrait `monstera-deliciosa#captive`."""
    refs = np.stack([unitaire(1, 0), unitaire(0.9, 0.1)])
    especes, scores = classer(np.stack([unitaire(1, 0)]), refs,
                              ['monstera-deliciosa', 'monstera-deliciosa#captive'])
    assert especes == ['monstera-deliciosa']
    assert compter(['monstera-deliciosa'], especes, scores, 0.0)['top1'] == 1.0


def test_plusieurs_references_sont_prises_au_mieux_pas_additionnees():
    """Additionner favoriserait mécaniquement l'espèce qui a le plus de vues,
    indépendamment de sa ressemblance avec la photo."""
    photo = np.stack([unitaire(0, 1)])
    refs = np.stack([unitaire(1, 0), unitaire(1, 0), unitaire(0, 1)])
    especes, scores = classer(photo, refs, ['riche', 'riche#captive', 'juste'],
                              temperature=50.0)
    gagnante = especes[int(np.argmax(scores[0]))]
    assert gagnante == 'juste'


# --------------------------------------------------------------------------
# Le classement
# --------------------------------------------------------------------------

def test_la_reference_la_plus_proche_gagne():
    refs = np.stack([unitaire(1, 0), unitaire(0, 1)])
    especes, scores = classer(np.stack([unitaire(0.9, 0.1)]), refs, ['a', 'b'])
    assert especes[int(np.argmax(scores[0]))] == 'a'


def test_les_scores_somment_a_un():
    refs = np.stack([unitaire(1, 0), unitaire(0, 1), unitaire(1, 1)])
    _, scores = classer(np.stack([unitaire(1, 0)]), refs, ['a', 'b', 'c'])
    assert scores[0].sum() == pytest.approx(1.0, abs=1e-5)


def test_une_temperature_haute_pique_la_distribution():
    """La température ne change pas l'ordre, seulement la confiance — c'est
    pourquoi top-1 se compare sans calibration et l'autonomie non."""
    refs = np.stack([unitaire(1, 0), unitaire(0.8, 0.6)])
    photo = np.stack([unitaire(1, 0)])
    _, molle = classer(photo, refs, ['a', 'b'], temperature=1.0)
    _, piquee = classer(photo, refs, ['a', 'b'], temperature=200.0)
    assert piquee[0].max() > molle[0].max()
    assert np.argmax(piquee[0]) == np.argmax(molle[0])


# --------------------------------------------------------------------------
# La restriction, « à armes égales »
# --------------------------------------------------------------------------

def test_restreindre_ne_garde_que_les_especes_demandees():
    cles, vecteurs = ['a', 'b', 'c'], np.eye(3, dtype=np.float32)
    c, v = restreindre(cles, vecteurs, {'a', 'c'})
    assert c == ['a', 'c'] and v.shape == (2, 3)
    assert np.allclose(v[1], vecteurs[2])


def test_sans_restriction_tout_est_garde():
    cles, vecteurs = ['a', 'b'], np.eye(2, dtype=np.float32)
    c, v = restreindre(cles, vecteurs, None)
    assert c == cles and v.shape == (2, 2)


def test_un_repertoire_plus_large_peut_voler_la_reponse():
    """Le § 6.7 bis, dans l'espace des embeddings : une espèce de plus peut
    passer devant la bonne. C'est pourquoi les deux lectures existent."""
    photo = np.stack([unitaire(1, 0.1)])
    cles = ['juste', 'intruse']
    refs = np.stack([unitaire(1, 0), unitaire(1, 0.2)])
    especes, larges = classer(photo, refs, cles)
    c, v = restreindre(cles, refs, {'juste'})
    etroites_especes, etroites = classer(photo, v, c)
    assert especes[int(np.argmax(larges[0]))] == 'intruse'
    assert etroites_especes[int(np.argmax(etroites[0]))] == 'juste'


# --------------------------------------------------------------------------
# Le comptage
# --------------------------------------------------------------------------

def test_le_top3_compte_une_verite_classee_troisieme():
    especes = ['a', 'b', 'c', 'd']
    scores = [np.array([0.4, 0.3, 0.2, 0.1], dtype=np.float32)]
    r = compter(['c'], especes, scores, 0.0)
    assert r['top1'] == 0.0 and r['top3'] == 1.0


def test_lautonomie_suit_le_seuil():
    especes = ['a', 'b']
    juste = [np.array([0.8, 0.2], dtype=np.float32)]
    assert compter(['a'], especes, juste, 0.7)['accepted_rate'] == 1.0
    assert compter(['a'], especes, juste, 0.9)['accepted_rate'] == 0.0
    assert compter(['a'], especes, juste, 0.9)['precision_when_accepted'] is None


# --------------------------------------------------------------------------
# La lecture du cache
# --------------------------------------------------------------------------

def cache_ecrit(dossier, chemins, vecteurs):
    np.save(dossier / 'emb-0-0000.npy', vecteurs.astype(np.float16))
    with open(dossier / 'index-0.csv', 'w', newline='', encoding='utf-8') as f:
        csv.writer(f).writerows([[c, 'emb-0-0000', i] for i, c in enumerate(chemins)])


def test_les_embeddings_sortent_du_cache_dans_lordre_demande(tmp_path):
    cache_ecrit(tmp_path, ['/a.jpg', '/b.jpg'], np.array([[1.0, 0.0], [0.0, 1.0]]))
    gardes, emb = lire_embeddings(tmp_path, ['/b.jpg', '/a.jpg'])
    assert gardes == [0, 1]
    assert np.allclose(emb[0], [0.0, 1.0]) and np.allclose(emb[1], [1.0, 0.0])


def test_une_image_absente_du_cache_est_ecartee_pas_comptee_fausse(tmp_path):
    """Un chiffre calculé sur la moitié des images sans le dire serait pire
    qu'une erreur."""
    cache_ecrit(tmp_path, ['/a.jpg'], np.array([[1.0, 0.0]]))
    gardes, emb = lire_embeddings(tmp_path, ['/a.jpg', '/absente.jpg'])
    assert gardes == [0] and emb.shape[0] == 1


def test_un_cache_vide_ne_rend_rien(tmp_path):
    gardes, emb = lire_embeddings(tmp_path, ['/a.jpg'])
    assert gardes == [] and emb.shape[0] == 0


def test_des_references_depareillees_sarretent(tmp_path):
    np.save(tmp_path / 'references-textes.npy', np.eye(3, dtype=np.float16))
    with open(tmp_path / 'references-textes.csv', 'w', newline='', encoding='utf-8') as f:
        w = csv.writer(f)
        w.writerow(['internal_id'])
        w.writerow(['a'])
    with pytest.raises(SystemExit):
        charger_references(tmp_path, 'texte')


# --------------------------------------------------------------------------
# La courbe « quel cosinus viser »
# --------------------------------------------------------------------------

def test_le_cosinus_obtenu_est_exactement_la_cible():
    """« Environ 0,85 » ne servirait à rien : c'est la précision qui fait
    l'intérêt de la courbe."""
    v = np.random.default_rng(0).standard_normal((50, 32)).astype(np.float32)
    v /= np.linalg.norm(v, axis=1, keepdims=True)
    for cible in (0.95, 0.85, 0.75, 0.5):
        cos = (v * degrader(v, cible)).sum(axis=1)
        assert np.allclose(cos, cible, atol=1e-5)


def test_les_vecteurs_degrades_restent_unitaires():
    v = np.random.default_rng(1).standard_normal((20, 16)).astype(np.float32)
    v /= np.linalg.norm(v, axis=1, keepdims=True)
    d = degrader(v, 0.8)
    assert np.allclose(np.linalg.norm(d, axis=1), 1.0, atol=1e-5)


def test_un_cosinus_de_un_ne_change_rien():
    v = np.random.default_rng(2).standard_normal((10, 8)).astype(np.float32)
    v /= np.linalg.norm(v, axis=1, keepdims=True)
    assert np.allclose(degrader(v, 1.0), v, atol=1e-5)


def test_la_degradation_est_reproductible():
    """Même graine, même bruit : deux lectures de la courbe se comparent."""
    v = np.random.default_rng(3).standard_normal((10, 8)).astype(np.float32)
    v /= np.linalg.norm(v, axis=1, keepdims=True)
    assert np.allclose(degrader(v, 0.9), degrader(v, 0.9))


def test_recaler_deplace_le_cone_sans_le_deformer():
    """Le student revient au centre du teacher, et son étalement interne ne
    change pas : on déplace, on ne redistribue pas."""
    from voisins import recaler
    from student import etalement
    alea = np.random.default_rng(0)
    v = alea.standard_normal((200, 64)).astype(np.float32) * 0.1
    v[:, 0] += 1.0
    v /= np.linalg.norm(v, axis=1, keepdims=True)
    cible = np.zeros(64, dtype=np.float32)
    cible[1] = 1.0
    deplace = recaler(v, cible)
    assert np.allclose(np.linalg.norm(deplace, axis=1), 1.0, atol=1e-5)
    # la direction dominante a changé d'axe
    assert abs(deplace.mean(axis=0)[1]) > abs(deplace.mean(axis=0)[0])


def test_recaler_rend_des_vecteurs_unitaires():
    from voisins import recaler
    v = np.random.default_rng(1).standard_normal((30, 16)).astype(np.float32)
    cible = np.zeros(16, dtype=np.float32)
    cible[0] = 1.0
    assert np.allclose(np.linalg.norm(recaler(v, cible), axis=1), 1.0, atol=1e-5)
