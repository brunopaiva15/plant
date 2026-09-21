"""Le rattachement des étiquettes de PlantNet-300K aux nôtres.

Ce qui est testé ici est ce qui rendrait la mesure **fausse sans le dire** :
un ordre de classes décalé d'un cran, une plante dédoublée dont la
probabilité se perd, une espèce hors catalogue à qui on retire sa masse.
L'inférence, elle, ne se teste pas sans TensorFlow.
"""
import numpy as np
import pytest

from plantnet_avis import agreger, binome, couverture, espace, etiquettes_plantnet


# --------------------------------------------------------------------------
# Les noms
# --------------------------------------------------------------------------

def test_lauteur_est_retire():
    assert binome('Lactuca virosa L.') == 'Lactuca virosa'
    assert binome("Pelargonium capitatum (L.) L'Hér.") == 'Pelargonium capitatum'


def test_un_hybride_garde_son_signe():
    """« Salvia × floriferior » tronqué à deux mots donnerait « Salvia × », et
    deux hybrides d'un même genre se confondraient."""
    assert binome('Salvia × floriferior Proctor') == 'Salvia × floriferior'
    assert binome('Amelanchier x spicata (Lam.) K.Koch') == 'Amelanchier x spicata'


def test_un_binome_nu_ne_bouge_pas():
    assert binome('Monstera deliciosa') == 'Monstera deliciosa'


# --------------------------------------------------------------------------
# L'ordre des classes
# --------------------------------------------------------------------------

def test_lordre_est_celui_des_identifiants_tries_comme_des_chaines():
    """`ImageFolder` trie les noms de dossiers, donc des chaînes. Trier en
    numérique décalerait tout : le modèle nommerait une plante pour une
    autre, sans que rien ne le signale."""
    noms = {'1355868': 'Lactuca virosa L.', '999': 'Acacia dealbata Link',
            '1717570': 'Alibertia edulis Rich.'}
    # tri de chaînes : '1355868' < '1717570' < '999'
    assert etiquettes_plantnet(noms) == ['Lactuca virosa', 'Alibertia edulis',
                                         'Acacia dealbata']


def test_le_tri_numerique_donnerait_un_autre_ordre():
    """Le test qui dit pourquoi le précédent existe."""
    noms = {'1355868': 'Lactuca virosa L.', '999': 'Acacia dealbata Link'}
    chaines = etiquettes_plantnet(noms)
    numerique = [binome(noms[k]) for k in sorted(noms, key=int)]
    assert chaines != numerique


# --------------------------------------------------------------------------
# L'espace de sortie
# --------------------------------------------------------------------------

def test_les_noms_connus_prennent_notre_identifiant():
    labels, groupes = espace(['Monstera deliciosa'], {'Monstera deliciosa': 'monstera-deliciosa'})
    assert labels == ['monstera-deliciosa'] and groupes == [0]


def test_une_espece_hors_catalogue_garde_une_classe_a_elle():
    """Lui retirer sa classe rendrait sa masse aux autres et flatterait le
    modèle dans la lecture « sorties entières »."""
    labels, groupes = espace(['Acacia dealbata'], {})
    assert labels == ['pn:Acacia dealbata'] and groupes == [0]


def test_deux_sorties_pour_la_meme_plante_tombent_dans_une_seule_classe():
    """1 081 sorties ne font que 1 022 binômes : plusieurs classes décrivent
    la même plante à l'auteur près."""
    labels, groupes = espace(['Rosa canina', 'Rosa canina', 'Rosa arvensis'],
                             {'Rosa canina': 'rosa-canina'})
    assert labels == ['rosa-canina', 'pn:Rosa arvensis']
    assert groupes == [0, 0, 1]


# --------------------------------------------------------------------------
# L'agrégation
# --------------------------------------------------------------------------

def test_les_logits_deviennent_des_probabilites_qui_somment_a_un():
    p = agreger(np.array([2.0, 1.0, 0.0]), [0, 1, 2], 3)
    assert p.sum() == pytest.approx(1.0, abs=1e-5)
    assert p[0] > p[1] > p[2]


def test_les_doublons_sont_additionnes_pas_maximises():
    """Le § 12.14 à l'envers : deux classes pour une même plante se
    partagent ses images, donc leurs probabilités se recollent."""
    logits = np.array([0.0, 0.0, 10.0])
    ensemble = agreger(logits, [0, 0, 1], 2)
    separees = agreger(logits, [0, 1, 2], 3)
    assert ensemble[0] == pytest.approx(separees[0] + separees[1])
    assert ensemble[0] > separees[0]


def test_un_grand_logit_ne_deborde_pas():
    """Le softmax est décalé de son maximum ; sans ça, exp(1000) déborde et
    rend des NaN silencieux."""
    p = agreger(np.array([1000.0, 999.0]), [0, 1], 2)
    assert np.isfinite(p).all() and p.sum() == pytest.approx(1.0, abs=1e-5)


def test_la_somme_reste_a_un_apres_regroupement():
    p = agreger(np.array([1.0, 2.0, 3.0, 4.0]), [0, 0, 1, 1], 2)
    assert p.sum() == pytest.approx(1.0, abs=1e-5)


# --------------------------------------------------------------------------
# La couverture
# --------------------------------------------------------------------------

def test_la_couverture_compte_ce_que_plantnet_rattrape():
    """Le seul chiffre qui dise ce que le second avis peut ajouter : parmi
    ce qu'Iris ne nomme pas, ce que PlantNet nomme."""
    verites = ['a', 'b', 'c', 'd']
    c = couverture(verites, iris={'a'}, plantnet={'b', 'c'})
    assert c['hors_iris'] == 3
    assert c['rattrapees_par_plantnet'] == 2
    assert c['part_rattrapee'] == pytest.approx(2 / 3, abs=1e-4)
    assert c['perdues_pour_les_deux'] == 1


def test_rien_a_rattraper_quand_iris_sait_tout():
    c = couverture(['a', 'b'], iris={'a', 'b'}, plantnet=set())
    assert c['hors_iris'] == 0 and c['part_rattrapee'] is None


def test_une_espece_que_les_deux_connaissent_nest_pas_un_rattrapage():
    c = couverture(['a'], iris={'a'}, plantnet={'a'})
    assert c['rattrapees_par_plantnet'] == 0
