"""Les retours des utilisateurs, avant qu'ils n'entrent au jeu.

Ce qui peut se tromper en silence : une étiquette faible prise pour solide,
une espèce hors catalogue devenue une classe, deux photos d'une même
identification séparées au découpage.
"""
import sys
from dataclasses import dataclass
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from auxine import REVIEW_DIR, SOURCE, chemin_objet, enregistrement, fiable, resoudre
from plant_dataset.manifest import STATUS_KEPT, STATUS_REVIEW
from plant_dataset.taxonomy import PlantEntry


@dataclass
class Prep:
    sha256: str = 'a' * 64
    phash: str = 'b' * 16
    width: int = 640
    height: int = 480


def plante(nom='Hoya kerrii', ident='hoya-kerrii') -> PlantEntry:
    return PlantEntry(internal_id=ident, scientific_name=nom, genus=nom.split()[0], epithet=nom.split()[-1], family='')


def retour(kind='corrigee', remote=None, nom='Hoya kerrii', ident='hoya-kerrii', photos=2) -> dict:
    return {'id': 'f1', 'storage_path': 'u1/f1', 'photos': photos, 'species_id': ident, 'species_name': nom,
            'kind': kind, 'chosen_source': 'remote', 'local_top5': [], 'remote_top1': remote,
            'model_version': '8'}


def test_a_confirmation_is_solid_on_its_own():
    """L'humain et Iris sont d'accord : deux avis, rien à valider."""
    assert fiable(retour('confirmee'))


def test_a_correction_is_solid_only_with_plantnet_agreeing_and_sure():
    assert fiable(retour(remote={'name': 'Hoya kerrii', 'score': 0.82}))
    assert not fiable(retour(remote={'name': 'Hoya kerrii', 'score': 0.31}))
    assert not fiable(retour(remote={'name': 'Hoya carnosa', 'score': 0.95}))
    assert not fiable(retour(remote=None))


def test_a_weak_label_goes_to_review_not_to_training():
    r = enregistrement(retour(remote=None), 0, Prep(), plante())
    assert r.status == STATUS_REVIEW
    assert r.path.startswith(f'{REVIEW_DIR}/Hoya_kerrii/')   # le slug du jeu, comme build_dataset
    assert r.extra['fiable'] is False


def test_a_solid_label_is_kept_like_any_other_source():
    r = enregistrement(retour('confirmee'), 1, Prep(), plante())
    assert r.status == STATUS_KEPT
    assert r.path == 'Hoya_kerrii/' + 'a' * 16 + '.jpg'
    assert r.source == SOURCE
    assert r.source_id == 'f1#1'
    assert r.license == 'consent'


def test_photos_of_one_identification_share_an_observation_group():
    """Le découpage regroupe par observation : les deux photos vont du même
    côté, sinon le test verrait ce que l'entraînement a vu."""
    a = enregistrement(retour('confirmee'), 0, Prep(), plante())
    b = enregistrement(retour('confirmee'), 1, Prep(sha256='c' * 64), plante())
    assert a.observation_id == b.observation_id == 'f1'


def test_every_user_photo_is_a_cultivated_one():
    assert enregistrement(retour('confirmee'), 0, Prep(), plante()).extra['captive'] is True


def test_a_species_outside_the_catalogue_never_becomes_a_class():
    """Elle est rendue à part : une candidate au catalogue, pas une classe."""
    rows = [retour('confirmee'), retour('confirmee', nom='Hoya linearis', ident='hoya-linearis')]
    connues, inconnues = resoudre(rows, [plante()])
    assert [p.internal_id for _, p in connues] == ['hoya-kerrii']
    assert [r['species_id'] for r in inconnues] == ['hoya-linearis']


def test_object_paths_follow_the_bucket_layout():
    assert chemin_objet(retour(), 2) == 'u1/f1/2.jpg'
