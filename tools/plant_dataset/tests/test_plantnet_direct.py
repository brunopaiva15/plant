"""Le connecteur Pl@ntNet en direct.

Les réponses sont celles de l'API réelle (`api.plantnet.org/v1`, septembre
2026), réduites. Ce qui compte : la licence lue image par image, la plante
entière avant les feuilles, un synonyme résolu vers le nom accepté, les
votes qui écartent une observation à une voix, et une panne réseau qui ne se
déguise jamais en « cette espèce n'a pas d'images ».
"""
import sys
from pathlib import Path

import pytest
import requests

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from plant_dataset.fetchers.plantnet import (  # noqa: E402
    PlantnetClient, candidat, choisir_espece, image_id_of, images_par_organe,
    nom_complet, votes_suffisent)

SA = 'https://creativecommons.org/licenses/by-sa/4.0/'


def image(iid, licence=SA, code='cc-by-sa', obs='1026069666', auteur='KP Laer'):
    return {'id': iid, 'o': f'https://bs.plantnet.org/image/o/{iid}',
            'm': f'https://bs.plantnet.org/image/m/{iid}',
            's': f'https://bs.plantnet.org/image/s/{iid}',
            'author': auteur, 'license': code, 'licenseUrl': licence,
            'observationId': obs}


ESPECE = {'name': 'Goeppertia lietzei', 'author': '(É.Morren) Saka',
          'commonNames': ['Calathea White Fusion'], 'imagesCount': 107}

DETAIL = {'species': 'Goeppertia lietzei', 'images': {
    'leaf': [image('aa01'), image('aa02', obs='2')],
    'bark': [image('aa03', obs='3')],
    'habit': [image('aa04', obs='4')],
}}


def observation(nom='Goeppertia lietzei', voix=3, proba=1.0, revue=False):
    return {'isValid': True, 'isRevised': revue, 'votes': {'determinations': [
        {'species': {'name': nom}, 'count': voix, 'proba': proba}]}}


def test_lidentifiant_se_lit_dans_lurl_quelle_que_soit_la_taille():
    """GBIF relaie les URL de Pl@ntNet : c'est l'URL qui dit d'où vient une
    image d'un manifeste, pas sa source."""
    assert image_id_of('https://bs.plantnet.org/image/o/283BFCC7bf5e8905f7f8') == '283bfcc7bf5e8905f7f8'
    assert image_id_of('https://bs.plantnet.org/image/m/283bfcc7bf5e8905f7f8') == '283bfcc7bf5e8905f7f8'
    assert image_id_of('https://inaturalist-open-data.s3.amazonaws.com/photos/1/o.jpg') is None
    assert image_id_of('') is None


def test_le_nom_complet_porte_lauteur():
    assert nom_complet(ESPECE) == 'Goeppertia lietzei (É.Morren) Saka'


def test_le_nom_exact_passe_devant_le_prefixe():
    """La recherche est un préfixe : « Begonia rex » rend aussi « Begonia
    rex-cultorum », parfois en premier."""
    rendus = [{'name': 'Begonia rex-cultorum'}, {'name': 'Begonia rex'}]
    assert choisir_espece(rendus, 'Begonia rex')['name'] == 'Begonia rex'


def test_un_synonyme_prend_le_nom_accepte():
    assert choisir_espece([ESPECE], 'Calathea lietzei')['name'] == 'Goeppertia lietzei'
    assert choisir_espece([], 'Calathea lietzei') is None


def test_la_plante_entiere_passe_avant_les_feuilles():
    organes = [im['organ'] for im in images_par_organe(DETAIL)]
    assert organes == ['habit', 'leaf', 'leaf', 'bark']


def test_une_licence_sa_ne_passe_que_sur_demande():
    """99,5 % des images sont en CC BY-SA : la règle du projet ne change pas
    pour une source."""
    im = {**image('aa01'), 'organ': 'leaf'}
    assert candidat(im, 'Goeppertia lietzei') is None
    c = candidat(im, 'Goeppertia lietzei', allow_share_alike=True)
    assert c.source == 'plantnet' and c.extra['photo_id'] == 'aa01'
    assert c.observation_id == 'plantnet:1026069666'
    assert c.publisher == 'Pl@ntNet' and c.author == 'KP Laer'


def test_une_licence_non_commerciale_est_refusee_meme_avec_sa():
    im = image('aa01', licence='https://creativecommons.org/licenses/by-nc/4.0/', code='cc-by-nc')
    assert candidat(im, 'x', allow_share_alike=True) is None


def test_le_code_suffit_quand_lurl_manque():
    im = image('aa01', licence='', code='cc-by')
    assert candidat(im, 'x') is not None


def test_une_licence_illisible_est_refusee():
    assert candidat(image('aa01', licence='', code='all-rights-reserved'), 'x',
                    allow_share_alike=True) is None


def test_les_votes_confirment_ou_ecartent():
    nom = 'Goeppertia lietzei'
    assert votes_suffisent(observation(voix=3), nom)
    assert not votes_suffisent(observation(voix=1), nom)
    assert not votes_suffisent(observation(voix=3, proba=0.77), nom)
    assert not votes_suffisent(observation(nom='Monstera deliciosa'), nom)


def test_une_observation_revue_passe_sans_compter_les_voix():
    assert votes_suffisent(observation(voix=1, revue=True), 'Goeppertia lietzei')


class Session:
    """Une session qui rend des réponses prévues, chemin par chemin."""

    def __init__(self, reponses, statut=200):
        self.reponses, self.statut, self.headers, self.appels = reponses, statut, {}, []

    def get(self, url, params=None, timeout=None):
        self.appels.append(url)
        for fin, corps in self.reponses.items():
            if url.endswith(fin):
                return Reponse(corps, self.statut)
        raise AssertionError(url)


class Reponse:
    def __init__(self, corps, statut):
        self.corps, self.status_code, self.headers = corps, statut, {}

    def raise_for_status(self):
        if self.status_code >= 400:
            raise requests.HTTPError(str(self.status_code))

    def json(self):
        return self.corps


def test_le_client_rend_les_images_de_lespece(tmp_path):
    s = Session({'/species': [ESPECE],
                 '/species/Goeppertia%20lietzei%20%28%C3%89.Morren%29%20Saka': DETAIL})
    c = PlantnetClient(session=s, pause=0)
    rendues = list(c.image_candidates('Calathea lietzei', allow_share_alike=True))
    assert [r.extra['photo_id'] for r in rendues] == ['aa04', 'aa01', 'aa02', 'aa03']
    assert all(r.extra['plantnet_species'] == 'Goeppertia lietzei' for r in rendues)


def test_le_filtre_de_votes_demande_chaque_observation_une_fois(tmp_path):
    s = Session({'/species': [ESPECE],
                 '/species/Goeppertia%20lietzei%20%28%C3%89.Morren%29%20Saka': DETAIL,
                 '/observations/4': observation(voix=3),
                 '/observations/1026069666': observation(voix=1),
                 '/observations/2': observation(voix=2),
                 '/observations/3': observation(nom='Maranta leuconeura')})
    cache = tmp_path / 'obs.json'
    c = PlantnetClient(session=s, pause=0, cache=cache)
    rendues = list(c.image_candidates('Goeppertia lietzei', allow_share_alike=True, voix_min=2))
    assert [r.extra['photo_id'] for r in rendues] == ['aa04', 'aa02']
    # Une reprise ne redemande rien : le cache est sur disque.
    s2 = Session({'/species': [ESPECE],
                  '/species/Goeppertia%20lietzei%20%28%C3%89.Morren%29%20Saka': DETAIL})
    c2 = PlantnetClient(session=s2, pause=0, cache=cache)
    assert len(list(c2.image_candidates('Goeppertia lietzei', allow_share_alike=True,
                                        voix_min=2))) == 2


def test_une_espece_inconnue_ne_rend_rien():
    c = PlantnetClient(session=Session({'/species': []}), pause=0)
    assert list(c.image_candidates('Philodendron Birkin', allow_share_alike=True)) == []


def test_une_panne_nest_pas_une_espece_vide(monkeypatch):
    """Une panne rendrait sinon « 0 image » pour une plante qui en a mille."""
    monkeypatch.setattr('plant_dataset.fetchers.plantnet.time.sleep', lambda s: None)
    c = PlantnetClient(session=Session({'/species': []}, statut=503), pause=0)
    with pytest.raises(requests.HTTPError):
        list(c.image_candidates('Begonia rex', allow_share_alike=True))
