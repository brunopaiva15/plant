import json
from pathlib import Path

from plant_dataset.fetchers.inaturalist import InatClient, InatTaxon, candidates_from_observation, photo_id_of

FIXTURES = Path(__file__).parent / 'fixtures'


def load(name):
    return json.loads((FIXTURES / name).read_text())


class FakeSession:
    def __init__(self, responses):
        self.responses = responses
        self.headers = {}
        self.calls = []

    def get(self, url, params=None, timeout=None):
        self.calls.append((url, params))
        return FakeResponse(self.responses[url.rsplit('/v1', 1)[1]])


class FakeResponse:
    status_code = 200

    def __init__(self, payload):
        self.payload = payload

    def raise_for_status(self):
        pass

    def json(self):
        return self.payload


def client(responses):
    return InatClient(session=FakeSession(responses), pause=0)


def test_match_requires_the_exact_name():
    c = client({'/taxa': load('inat_taxa_pilea.json')})
    t = c.match('Pilea peperomioides')
    assert isinstance(t, InatTaxon)
    assert t.id == 125439 and t.rank == 'species' and t.observations > 0
    assert client({'/taxa': load('inat_taxa_pilea.json')}).match('Pilea cadierei') is None


def test_candidates_from_recorded_observations():
    page = load('inat_observations_pilea.json')
    cands = [c for obs in page['results'] for c in candidates_from_observation(obs)]
    # 4 observations, 7 photos, toutes CC0 ou CC BY.
    assert len(cands) == 7
    assert all(c.source == 'inaturalist' for c in cands)
    assert all(c.author for c in cands), 'chaque photo doit avoir un auteur'
    assert all(c.license_raw in ('cc0', 'cc-by') for c in cands)
    assert all(c.original_url.startswith('https://www.inaturalist.org/observations/') for c in cands)
    # La miniature carrée est remplacée par la version large.
    assert all('/large.' in c.image_url and '/square.' not in c.image_url for c in cands)
    assert all(c.extra['photo_id'] for c in cands)
    first = cands[0]
    assert first.observation_id == '13754959'
    assert first.source_id == '13754959#20276282'


def test_captive_observations_are_kept():
    """C'est tout l'intérêt : GBIF ne reçoit pas les plantes en pot."""
    page = load('inat_observations_pilea.json')
    cands = [c for obs in page['results'] for c in candidates_from_observation(obs)]
    assert any(c.extra['quality_grade'] == 'casual' for c in cands)


def test_photo_licence_filter_and_hidden_photos():
    obs = {'id': 7, 'uri': 'https://www.inaturalist.org/observations/7', 'user': {'login': 'ada'},
           'photos': [{'id': 1, 'license_code': 'cc-by-nc', 'url': 'https://x/photos/1/square.jpg'},
                      {'id': 2, 'license_code': 'cc0', 'url': 'https://x/photos/2/square.jpg', 'hidden': True},
                      {'id': 3, 'license_code': None, 'url': 'https://x/photos/3/square.jpg'},
                      {'id': 4, 'license_code': 'cc-by', 'url': 'https://x/photos/4/square.jpg'}]}
    cands = list(candidates_from_observation(obs))
    assert [c.extra['photo_id'] for c in cands] == ['4']
    assert cands[0].author == 'ada'


def test_share_alike_only_when_asked():
    obs = {'id': 8, 'user': {}, 'photos': [{'id': 9, 'license_code': 'cc-by-sa', 'url': 'https://x/photos/9/square.jpg'}]}
    assert list(candidates_from_observation(obs)) == []
    assert len(list(candidates_from_observation(obs, allow_share_alike=True))) == 1


def test_photo_id_is_the_cross_source_key():
    # GBIF relaie les mêmes URL iNaturalist : le même identifiant de photo
    # des deux côtés, donc pas de doublon entre les deux collecteurs.
    assert photo_id_of('https://inaturalist-open-data.s3.amazonaws.com/photos/726492519/original.jpg') == '726492519'
    assert photo_id_of('https://inaturalist-open-data.s3.amazonaws.com/photos/726492519/large.jpeg') == '726492519'
    assert photo_id_of('https://example.org/image.jpg') is None
    assert photo_id_of('') is None


def test_image_candidates_asks_only_for_allowed_licences():
    page = load('inat_observations_pilea.json')
    c = client({'/observations': page})
    cands = list(c.image_candidates(125439))
    assert len(cands) == 7
    (_, params), = c.session.calls
    assert params['photo_license'] == 'cc0,cc-by'
    assert params['quality_grade'] == 'any', 'les plantes en pot sont « casual »'
    assert params['taxon_id'] == 125439
