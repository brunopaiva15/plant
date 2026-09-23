"""Les plantes d'iNaturalist triées pour la distillation.

Ce qui est testé ici est ce qui abîmerait **silencieusement** la suite : une
photo du banc entrée dans l'entraînement, un insecte compté comme une plante,
une photo déjà au corpus comptée comme neuve, un genre pris pour une espèce
du catalogue, un `splits.csv` qui annonce des fichiers absents.
"""
import csv
import io
import json

import numpy as np
import pytest

from inat_corpus import (destination, distances, ecrire_splits, identite,
                         motif_de_rejet, photos_connues, preparer_image,
                         proche_du_banc, taxons_plantes)


TAXA = [
    {'taxon_id': '47126', 'ancestry': '48460', 'rank': 'kingdom', 'name': 'Plantae'},
    {'taxon_id': '48701', 'ancestry': '48460/47126/211194/47125', 'rank': 'genus', 'name': 'Monstera'},
    {'taxon_id': '51798', 'ancestry': '48460/47126/211194/47125/48701', 'rank': 'species',
     'name': 'Monstera deliciosa'},
    {'taxon_id': '4925', 'ancestry': '48460/1/2/355675/3/67561/4917/4921', 'rank': 'species',
     'name': 'Burhinus grallarius'},
    # un champignon : 47170, frère de Plantae sous la racine
    {'taxon_id': '47170', 'ancestry': '48460', 'rank': 'kingdom', 'name': 'Fungi'},
]


# --------------------------------------------------------------------------
# Ce qui est une plante
# --------------------------------------------------------------------------

def test_une_plante_se_lit_dans_lascendance():
    assert taxons_plantes(TAXA) == {47126, 48701, 51798}


def test_un_oiseau_et_un_champignon_ne_sont_pas_des_plantes():
    plantes = taxons_plantes(TAXA)
    assert 4925 not in plantes and 47170 not in plantes


def test_un_identifiant_qui_contient_47126_nest_pas_une_plante_pour_autant():
    """L'ascendance se découpe sur `/` : `147126` n'est pas `47126`."""
    assert taxons_plantes([{'taxon_id': '9', 'ancestry': '48460/147126/5'}]) == set()


# --------------------------------------------------------------------------
# Le tri avant d'ouvrir l'image
# --------------------------------------------------------------------------

PLANTES = {47126, 48701, 51798}


def test_une_photo_sans_taxon_est_ecartee():
    """Rien ne dit qu'elle montre une plante."""
    assert motif_de_rejet('1', None, PLANTES, set()) == 'sans taxon'


def test_un_oiseau_est_ecarte():
    assert motif_de_rejet('1', 4925, PLANTES, set()) == 'pas une plante'


def test_une_photo_deja_au_corpus_est_ecartee():
    """Celles du banc pour la fuite, les autres parce qu'elles y sont déjà."""
    assert motif_de_rejet('726492519', 51798, PLANTES, {'726492519'}) == 'déjà au corpus'


def test_une_plante_neuve_passe():
    assert motif_de_rejet('1', 51798, PLANTES, {'2'}) == ''


def test_le_photo_id_se_compare_en_texte():
    """Parquet peut le rendre en entier, le manifeste le rend en texte."""
    assert motif_de_rejet(726492519, 51798, PLANTES, {'726492519'}) == 'déjà au corpus'


# --------------------------------------------------------------------------
# Les photos déjà chez nous
# --------------------------------------------------------------------------

def test_les_photos_inaturalist_du_manifeste_sont_retrouvees():
    lignes = [
        json.dumps({'source': 'inaturalist',
                    'image_url': 'https://inaturalist-open-data.s3.amazonaws.com/photos/111/medium.jpg'}),
        json.dumps({'source': 'wikimedia', 'image_url': 'https://upload.wikimedia.org/x.jpg'}),
    ]
    assert photos_connues(lignes) == {'111'}


def test_une_photo_inaturalist_relayee_par_gbif_est_retrouvee():
    """GBIF relaie les URL iNaturalist telles quelles : on lit l'URL, pas la
    source."""
    lignes = [json.dumps({'source': 'gbif',
                          'image_url': 'https://inaturalist-open-data.s3.amazonaws.com/photos/222/original.jpeg'})]
    assert photos_connues(lignes) == {'222'}


def test_une_ligne_de_manifeste_abimee_ne_casse_pas_la_lecture():
    assert photos_connues(['pas du json', '']) == set()


# --------------------------------------------------------------------------
# La garde par empreinte
# --------------------------------------------------------------------------

def test_les_distances_se_comptent_en_bits():
    banc = np.array([0b0, 0b1011, (1 << 64) - 1], dtype=np.uint64)
    assert list(distances(0, banc)) == [0, 3, 64]


def test_une_copie_a_quelques_bits_du_banc_est_ecartee():
    banc = np.array([0xFFFF0000FFFF0000], dtype=np.uint64)
    assert proche_du_banc(0xFFFF0000FFFF0000 ^ 0b111, banc, seuil=6)
    assert not proche_du_banc(0x0000FFFF0000FFFF, banc, seuil=6)


def test_un_banc_vide_necarte_rien():
    assert not proche_du_banc(0, np.array([], dtype=np.uint64))


def test_une_image_recompressee_et_reduite_reste_proche_delle_meme():
    """C'est tout le rôle de la seconde garde : une copie relayée sous une
    autre URL, recompressée, redimensionnée."""
    from PIL import Image
    alea = np.random.default_rng(0)
    base = (alea.random((64, 64, 3)) * 255).astype('uint8')
    im = Image.fromarray(base).resize((800, 600))
    tampon = io.BytesIO()
    im.save(tampon, format='JPEG', quality=95)
    _, h1 = preparer_image(tampon.getvalue())
    tampon2 = io.BytesIO()
    im.resize((400, 300)).save(tampon2, format='JPEG', quality=60)
    _, h2 = preparer_image(tampon2.getvalue())
    assert proche_du_banc(h1, np.array([h2], dtype=np.uint64))


# --------------------------------------------------------------------------
# La réduction
# --------------------------------------------------------------------------

def png(taille):
    from PIL import Image
    t = io.BytesIO()
    Image.new('RGB', taille, (10, 120, 30)).save(t, format='PNG')
    return t.getvalue()


def test_la_sortie_est_un_jpeg_reduit_a_320():
    from PIL import Image
    jpeg, _ = preparer_image(png((1024, 768)))
    im = Image.open(io.BytesIO(jpeg))
    assert im.format == 'JPEG' and im.size == (320, 240)


def test_une_petite_image_nest_pas_agrandie():
    from PIL import Image
    jpeg, _ = preparer_image(png((200, 150)))
    assert Image.open(io.BytesIO(jpeg)).size == (200, 150)


# --------------------------------------------------------------------------
# L'identité et la destination
# --------------------------------------------------------------------------

CATALOGUE = {'Monstera deliciosa': 'monstera-deliciosa'}


def test_une_espece_du_catalogue_garde_notre_identifiant():
    assert identite('Monstera deliciosa', 'species', 51798, CATALOGUE) == 'monstera-deliciosa'


def test_un_genre_ne_se_rattache_pas_a_une_espece():
    """« Monstera » tout court ne désigne aucune espèce du catalogue."""
    assert identite('Monstera', 'genus', 48701, CATALOGUE) == 'inat:48701'


def test_une_espece_hors_catalogue_est_prefixee():
    assert identite('Ficus lyrata', 'species', 1, CATALOGUE) == 'inat:1'


def test_la_destination_range_par_taxon():
    assert destination(51798, '726492519') == 'images/51798/726492519.jpg'


# --------------------------------------------------------------------------
# Le manifeste
# --------------------------------------------------------------------------

def test_splits_dedoublonne_et_ne_garde_que_les_fichiers_presents(tmp_path):
    """Un fragment repris réécrit ses lignes dans l'index ; une ligne sans
    fichier changerait le nombre de pas par époque sans le dire."""
    from inat_corpus import COLONNES
    (tmp_path / 'images/1').mkdir(parents=True)
    (tmp_path / 'images/1/a.jpg').write_bytes(b'x')
    with open(tmp_path / 'index.csv', 'w', newline='', encoding='utf-8') as f:
        w = csv.DictWriter(f, fieldnames=COLONNES)
        w.writeheader()
        for p in ('images/1/a.jpg', 'images/1/a.jpg', 'images/1/absente.jpg'):
            w.writerow({'path': p, 'internal_plant_id': 'inat:1', 'taxon_id': 1,
                        'species_name': 'x', 'taxonomic_rank': 'species',
                        'photo_id': 'a', 'observation_uuid': 'u'})
    assert ecrire_splits(tmp_path / 'index.csv', tmp_path) == 1
    with open(tmp_path / 'splits.csv', newline='', encoding='utf-8') as f:
        r, = list(csv.DictReader(f))
    assert r['path'] == 'images/1/a.jpg' and r['split'] == 'train'
    assert r['captive'] == ''      # inconnu, pas « sauvage »


# --------------------------------------------------------------------------
# Un fragment Parquet de bout en bout
# --------------------------------------------------------------------------

def test_un_fragment_ne_garde_que_les_plantes_neuves_et_loin_du_banc(tmp_path):
    pa = pytest.importorskip('pyarrow')
    pq = pytest.importorskip('pyarrow.parquet')
    from inat_corpus import COLONNES, traiter_fragment
    from PIL import Image

    def jpeg(graine):
        a = (np.random.default_rng(graine).random((48, 48, 3)) * 255).astype('uint8')
        t = io.BytesIO()
        Image.fromarray(a).resize((640, 480)).save(t, format='JPEG')
        return t.getvalue()

    du_banc = jpeg(1)
    _, h_banc = preparer_image(du_banc)
    lignes = [
        # gardée
        {'photo_id': '10', 'observation_uuid': 'a', 'taxon_id': 51798,
         'species_name': 'Monstera deliciosa', 'taxonomic_rank': 'species', 'image': jpeg(2)},
        # oiseau
        {'photo_id': '11', 'observation_uuid': 'b', 'taxon_id': 4925,
         'species_name': 'Burhinus grallarius', 'taxonomic_rank': 'species', 'image': jpeg(3)},
        # déjà au corpus
        {'photo_id': '12', 'observation_uuid': 'c', 'taxon_id': 51798,
         'species_name': 'Monstera deliciosa', 'taxonomic_rank': 'species', 'image': jpeg(4)},
        # la photo du banc, sous un autre photo_id
        {'photo_id': '13', 'observation_uuid': 'd', 'taxon_id': 48701,
         'species_name': 'Monstera', 'taxonomic_rank': 'genus', 'image': du_banc},
        # sans taxon
        {'photo_id': '14', 'observation_uuid': 'e', 'taxon_id': None,
         'species_name': None, 'taxonomic_rank': None, 'image': jpeg(5)},
        # illisible
        {'photo_id': '15', 'observation_uuid': 'f', 'taxon_id': 51798,
         'species_name': 'Monstera deliciosa', 'taxonomic_rank': 'species', 'image': b'pas une image'},
    ]
    fichier = tmp_path / 'fragment.parquet'
    pq.write_table(pa.Table.from_pylist(lignes), fichier)
    sortie = tmp_path / 'sortie'
    sortie.mkdir()
    with open(sortie / 'index.csv', 'w', newline='', encoding='utf-8') as index_f:
        csv.DictWriter(index_f, fieldnames=COLONNES).writeheader()
        c = traiter_fragment(fichier, sortie, PLANTES, {'12'},
                             np.array([h_banc], dtype=np.uint64), CATALOGUE,
                             320, 6, 2, index_f)
    assert c['lignes'] == 6
    assert (c['gardée'], c['pas une plante'], c['déjà au corpus'],
            c['proche du banc'], c['sans taxon'], c['illisible']) == (1, 1, 1, 1, 1, 1)
    assert ecrire_splits(sortie / 'index.csv', sortie) == 1
    with open(sortie / 'splits.csv', newline='', encoding='utf-8') as f:
        r, = list(csv.DictReader(f))
    assert r['path'] == 'images/51798/10.jpg'
    assert r['internal_plant_id'] == 'monstera-deliciosa'


# --------------------------------------------------------------------------
# Les photos sœurs des observations du banc
# --------------------------------------------------------------------------

def test_les_observations_du_banc_se_retrouvent_par_leur_chemin(tmp_path):
    """Le manifeste donne le chemin relatif, le banc l'absolu."""
    from inat_corpus import observations_du_banc
    lignes = [
        json.dumps({'source': 'inaturalist', 'observation_id': '555', 'path': 'img/a.jpg'}),
        json.dumps({'source': 'inaturalist', 'observation_id': '666', 'path': 'img/b.jpg'}),
    ]
    assert observations_du_banc(lignes, tmp_path, {str(tmp_path / 'img/a.jpg')}) == {'555'}


def test_une_occurrence_gbif_publiee_par_inaturalist_donne_son_observation(tmp_path):
    """Sa clé GBIF ne dit rien à iNaturalist ; son URL d'origine, si."""
    from inat_corpus import observations_du_banc
    lignes = [json.dumps({'source': 'gbif', 'observation_id': '4012345678', 'path': 'img/c.jpg',
                          'original_url': 'https://www.inaturalist.org/observations/777'})]
    assert observations_du_banc(lignes, tmp_path, {str(tmp_path / 'img/c.jpg')}) == {'777'}


def test_une_image_gbif_hors_inaturalist_ne_donne_rien(tmp_path):
    from inat_corpus import observations_du_banc
    lignes = [json.dumps({'source': 'gbif', 'observation_id': '4012345678', 'path': 'img/d.jpg',
                          'original_url': 'https://www.gbif.org/occurrence/4012345678'})]
    assert observations_du_banc(lignes, tmp_path, {str(tmp_path / 'img/d.jpg')}) == set()


def test_toutes_les_photos_dune_observation_sont_ses_soeurs():
    from inat_corpus import soeurs
    obs = [{'id': 555, 'uuid': 'u-555', 'photos': [{'id': 1}, {'id': 2}]},
           {'id': 666, 'uuid': 'u-666', 'photos': []}]
    assert soeurs(obs) == ({'1', '2'}, {'u-555', 'u-666'})


def test_une_photo_soeur_du_banc_est_ecartee_par_son_observation():
    """Autre photo_id, autre cadrage : seule l'observation la trahit."""
    assert motif_de_rejet('999', 51798, PLANTES, set(), 'u-555', {'u-555'}) == 'observation du banc'
