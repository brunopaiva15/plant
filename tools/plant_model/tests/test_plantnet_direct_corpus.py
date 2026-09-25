"""Les plantes en pot de Pl@ntNet triées pour la distillation.

Ce qui est testé ici est ce qui abîmerait **silencieusement** la suite : une
photo du banc — ou sa sœur de la même observation — entrée dans
l'entraînement, une image déjà au corpus comptée comme neuve, une licence
non commerciale qui passe, une espèce rangée sous une clé inventée qui se
ferait passer pour une des nôtres, une attribution qui manque.
"""
import csv
import json
from pathlib import Path

from plantnet_direct_corpus import (attribution, destination, ecrire_attributions,
                                    especes_a_collecter, identite, ids_des_corpus,
                                    ids_des_manifestes, motif_de_rejet,
                                    observations_interdites)

SA = 'https://creativecommons.org/licenses/by-sa/4.0/'


def image(iid, obs='1', licence=SA, code='cc-by-sa'):
    return {'id': iid, 'o': f'https://bs.plantnet.org/image/o/{iid}', 'author': 'KP Laer',
            'license': code, 'licenseUrl': licence, 'observationId': obs}


def ligne(**champs):
    base = {'espece_plantnet': '', 'noms_du_depot': '', 'photos_libres': '0', 'verdict': ''}
    return {**base, **champs}


# --------------------------------------------------------------------------
# Les espèces
# --------------------------------------------------------------------------

def test_toutes_les_especes_avec_des_photos_par_defaut():
    """Le student ne lit aucun nom : « à écarter » est une étiquette fausse,
    pas une mauvaise photo."""
    lignes = [ligne(espece_plantnet='Begonia rex', photos_libres='4491', verdict='propre'),
              ligne(espece_plantnet='Anthurium scherzerianum', photos_libres='5049',
                    verdict='à écarter'),
              ligne(espece_plantnet='Philodendron Birkin', photos_libres='0',
                    verdict='absente de Pl@ntNet'),
              ligne(espece_plantnet='Dracaena angolensis', noms_du_depot='Sansevieria cylindrica',
                    photos_libres='900', verdict='déjà dans le modèle')]
    assert especes_a_collecter(lignes) == [
        ('Begonia rex', ''), ('Anthurium scherzerianum', ''),
        ('Dracaena angolensis', 'Sansevieria cylindrica')]


def test_les_verdicts_se_restreignent():
    lignes = [ligne(espece_plantnet='Begonia rex', photos_libres='4491', verdict='propre'),
              ligne(espece_plantnet='Anthurium scherzerianum', photos_libres='5049',
                    verdict='à écarter')]
    assert especes_a_collecter(lignes, {'propre'}) == [('Begonia rex', '')]


def test_une_espece_en_double_nest_collectee_quune_fois():
    lignes = [ligne(espece_plantnet='Begonia rex', photos_libres='10'),
              ligne(espece_plantnet='Begonia  rex', photos_libres='10')]
    assert len(especes_a_collecter(lignes)) == 1


def test_le_nom_du_depot_rattache_au_catalogue():
    """Pl@ntNet dit *Dracaena angolensis*, nous `sansevieria-cylindrica`."""
    catalogue = {'Sansevieria cylindrica': 'sansevieria-cylindrica'}
    assert identite('Dracaena angolensis', 'Sansevieria cylindrica', catalogue) == \
        'sansevieria-cylindrica'


def test_une_espece_hors_catalogue_garde_une_cle_a_elle():
    cle = identite('Goeppertia lietzei', '', {'Monstera deliciosa': 'monstera-deliciosa'})
    assert cle == 'pnd:Goeppertia_lietzei'


def test_le_chemin_ne_porte_que_des_caracteres_surs():
    assert destination('Alocasia × amazonica', 'ab12') == 'images/Alocasia___amazonica/ab12.jpg'
    assert destination('Begonia rex Putz.', 'ab12') == 'images/Begonia_rex/ab12.jpg'


# --------------------------------------------------------------------------
# Les gardes contre la fuite
# --------------------------------------------------------------------------

def manifeste(*records):
    return [json.dumps(r) for r in records]


def test_les_images_plantnet_se_lisent_dans_lurl_quelle_que_soit_la_source(tmp_path):
    """GBIF relaie Pl@ntNet : une image « gbif » peut en venir."""
    racine = tmp_path / 'dataset'
    lignes = manifeste(
        {'source': 'gbif', 'path': 'Begonia_rex/a.jpg',
         'image_url': 'https://bs.plantnet.org/image/o/aaaa1111aaaa1111'},
        {'source': 'gbif', 'path': 'Begonia_rex/b.jpg',
         'image_url': 'https://bs.plantnet.org/image/o/bbbb2222bbbb2222'},
        {'source': 'inaturalist', 'path': 'Begonia_rex/c.jpg',
         'image_url': 'https://inaturalist-open-data.s3.amazonaws.com/photos/1/o.jpg'},
        {'source': 'plantnet', 'path': 'Begonia_rex/d.jpg', 'image_url': '',
         'extra': {'photo_id': 'DDDD4444DDDD4444'}})
    banc = {str(racine / 'Begonia_rex/b.jpg')}
    connues, du_banc = ids_des_manifestes(lignes, racine, banc)
    assert connues == {'aaaa1111aaaa1111', 'bbbb2222bbbb2222', 'dddd4444dddd4444'}
    assert du_banc == {'bbbb2222bbbb2222'}


def test_une_ligne_illisible_du_manifeste_est_sautee(tmp_path):
    connues, du_banc = ids_des_manifestes(['{pas du json', ''], tmp_path, set())
    assert connues == set() and du_banc == set()


def test_les_images_de_plantnet300k_sont_deja_au_corpus():
    lignes = [{'path': 'images/1355868/5f0c1a2b3c4d5e6f7a8b.jpg'},
              {'path': 'images/pn/nom-de-fichier.jpg'}]
    assert ids_des_corpus(lignes) == {'5f0c1a2b3c4d5e6f7a8b'}


def test_les_photos_soeurs_dune_image_du_banc_partent_avec_elle():
    """Deux prises de la même plante le même jour sont une fuite, même sous
    un autre identifiant et un autre cadrage."""
    images = [image('bb01', obs='7'), image('bb02', obs='7'), image('cc01', obs='8')]
    interdites = observations_interdites(images, du_banc={'bb01'})
    assert interdites == {'7'}
    assert motif_de_rejet(images[1], set(), interdites) == 'observation du banc'
    assert motif_de_rejet(images[2], set(), interdites) == ''


def test_une_image_deja_au_corpus_nest_pas_neuve():
    assert motif_de_rejet(image('AA01'), {'aa01'}, set()) == 'déjà au corpus'


def test_une_licence_non_commerciale_est_refusee():
    nc = image('aa01', licence='https://creativecommons.org/licenses/by-nc-sa/4.0/',
               code='cc-by-nc-sa')
    assert motif_de_rejet(nc, set(), set()) == 'licence'
    assert motif_de_rejet(image('aa02', licence='', code='all-rights-reserved'),
                          set(), set()) == 'licence'


def test_cc_by_sa_passe():
    assert motif_de_rejet(image('aa01'), set(), set()) == ''


# --------------------------------------------------------------------------
# L'attribution
# --------------------------------------------------------------------------

def test_lattribution_est_celle_que_demande_plantnet():
    assert attribution({'author': 'KP Laer', 'license': 'CC BY-SA 4.0'}) == \
        'Photo : KP Laer / Pl@ntNet, CC BY-SA 4.0'


def test_les_attributions_ne_listent_que_les_images_presentes(tmp_path):
    (tmp_path / 'images/X').mkdir(parents=True)
    (tmp_path / 'images/X/a.jpg').write_bytes(b'jpeg')
    index = tmp_path / 'index.csv'
    with open(index, 'w', newline='', encoding='utf-8') as f:
        w = csv.DictWriter(f, fieldnames=['path', 'author', 'license', 'url'])
        w.writeheader()
        w.writerow({'path': 'images/X/a.jpg', 'author': 'A', 'license': 'CC BY-SA 4.0', 'url': 'u'})
        w.writerow({'path': 'images/X/a.jpg', 'author': 'A', 'license': 'CC BY-SA 4.0', 'url': 'u'})
        w.writerow({'path': 'images/X/absente.jpg', 'author': 'B', 'license': 'CC BY-SA 4.0',
                    'url': 'v'})
    assert ecrire_attributions(index, tmp_path) == 1
    lignes = list(csv.DictReader(open(tmp_path / 'attributions.csv', encoding='utf-8')))
    assert lignes[0]['attribution'] == 'Photo : A / Pl@ntNet, CC BY-SA 4.0'
