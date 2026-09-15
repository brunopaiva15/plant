"""Le manifeste doit suivre le catalogue, sinon le jeu se contredit.

`fusionner.py` retire une ligne du catalogue ; le manifeste, lui, garde
l'étiquette figée à la collecte. Sans ce rattrapage, le redécoupage
produirait des classes dont aucune ligne ne répond, et les images
resteraient séparées alors que la fusion existait pour les réunir.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from plant_dataset.manifest import ImageRecord, Manifest  # noqa: E402
from plant_dataset.taxonomy import PlantEntry  # noqa: E402
from reetiqueter import correspondance, reetiqueter  # noqa: E402


def entree(nom, synonymes=()):
    e = PlantEntry.from_name(nom, 'Testaceae')
    e.synonyms = list(synonymes)
    return e


def enregistrement(interne, espece, checksum='a'):
    return ImageRecord(species=espece, internal_plant_id=interne, source='gbif',
                       source_id=checksum, original_url='', image_url='', author='',
                       license='CC0 1.0', license_url='', downloaded_at='', checksum=checksum)


# --- Quelles étiquettes sont mortes ---------------------------------------

def test_un_synonyme_qui_nest_pas_une_ligne_est_une_etiquette_morte():
    survivant = entree('Dracaena trifasciata', ['Sansevieria trifasciata'])
    m = correspondance([survivant])
    assert m['sansevieria-trifasciata'] == ('dracaena-trifasciata', 'Dracaena trifasciata')


def test_un_synonyme_qui_est_aussi_une_ligne_nest_pas_mort():
    # Sinon on réétiquetterait une classe vivante vers une autre, ce qui
    # serait une fusion qu'aucun outil n'a décidée.
    a = entree('Aria edulis', ['Sorbus aria'])
    b = entree('Sorbus aria')
    assert correspondance([a, b]) == {}


def test_une_ligne_sans_synonyme_ne_produit_rien():
    assert correspondance([entree('Monstera deliciosa')]) == {}


def test_plusieurs_noms_retires_pointent_la_meme_ligne():
    survivant = entree('Citrus × limon', ['Citrus × bergamia', 'Citrus × limonia'])
    m = correspondance([survivant])
    assert m['citrus-x-bergamia'][0] == 'citrus-x-limon'
    assert m['citrus-x-limonia'][0] == 'citrus-x-limon'


# --- Ce que le réétiquetage fait au manifeste ------------------------------

def test_les_images_changent_detiquette_et_de_nom(tmp_path):
    man = Manifest(tmp_path / 'manifest.jsonl')
    man.records = [enregistrement('sansevieria-trifasciata', 'Sansevieria trifasciata', 'a'),
                   enregistrement('monstera-deliciosa', 'Monstera deliciosa', 'b')]
    faits = reetiqueter(man, {'sansevieria-trifasciata':
                              ('dracaena-trifasciata', 'Dracaena trifasciata')})
    assert sum(faits.values()) == 1
    assert man.records[0].internal_plant_id == 'dracaena-trifasciata'
    assert man.records[0].species == 'Dracaena trifasciata', 'le nom suit l\'identifiant'
    assert man.records[1].internal_plant_id == 'monstera-deliciosa', 'le reste ne bouge pas'


def test_le_chemin_de_limage_ne_bouge_pas(tmp_path):
    # Tout l'intérêt : train.py lit `path` et `internal_plant_id` comme deux
    # colonnes indépendantes, donc réétiqueter ne déplace aucun fichier.
    man = Manifest(tmp_path / 'manifest.jsonl')
    r = enregistrement('sansevieria-trifasciata', 'Sansevieria trifasciata')
    r.path = 'Sansevieria_trifasciata/abc123.jpg'
    man.records = [r]
    reetiqueter(man, {'sansevieria-trifasciata': ('dracaena-trifasciata', 'Dracaena trifasciata')})
    assert man.records[0].path == 'Sansevieria_trifasciata/abc123.jpg'


def test_un_manifeste_deja_daccord_ne_bouge_pas(tmp_path):
    man = Manifest(tmp_path / 'manifest.jsonl')
    man.records = [enregistrement('monstera-deliciosa', 'Monstera deliciosa')]
    assert reetiqueter(man, {'sansevieria-trifasciata': ('dracaena-trifasciata', 'D t')}) == {}


def test_la_reecriture_se_relit(tmp_path):
    chemin = tmp_path / 'manifest.jsonl'
    man = Manifest(chemin)
    man.records = [enregistrement('sansevieria-trifasciata', 'Sansevieria trifasciata')]
    reetiqueter(man, {'sansevieria-trifasciata': ('dracaena-trifasciata', 'Dracaena trifasciata')})
    man.rewrite()
    assert Manifest(chemin).records[0].internal_plant_id == 'dracaena-trifasciata'
