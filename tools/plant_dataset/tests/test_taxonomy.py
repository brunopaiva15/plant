from plant_dataset.taxonomy import (PlantEntry, epithet_of, genus_of, internal_id, load_plants, match_to_catalog,
                                    normalize_scientific_name, save_plants, species_slug)


def test_strips_authorship():
    assert normalize_scientific_name('Monstera deliciosa Liebm.') == 'Monstera deliciosa'
    assert normalize_scientific_name('Citrus × limon (L.) Osbeck') == 'Citrus × limon'
    assert normalize_scientific_name('Ficus benjamina var. nuda (Miq.) Barrett') == 'Ficus benjamina var. nuda'


def test_hybrid_sign_and_case():
    assert normalize_scientific_name('citrus x aurantium L.') == 'Citrus × aurantium'
    assert normalize_scientific_name('MONSTERA DELICIOSA') == 'Monstera deliciosa'
    assert normalize_scientific_name('  Ficus   elastica ') == 'Ficus elastica'


def test_cultivar_keeps_its_capitals():
    assert normalize_scientific_name("Rosa 'Peace'") == "Rosa 'Peace'"


def test_genus_only_and_empty():
    assert normalize_scientific_name('Monstera') == 'Monstera'
    assert normalize_scientific_name('') == ''
    assert normalize_scientific_name('Citrus ×') == 'Citrus'


def test_slug_and_id():
    assert species_slug('Citrus × limon') == 'Citrus_x_limon'
    assert species_slug('Ficus benjamina var. nuda') == 'Ficus_benjamina_var_nuda'
    assert internal_id('Monstera deliciosa') == 'monstera-deliciosa'
    assert genus_of('Citrus × limon') == 'Citrus'
    assert epithet_of('Citrus × limon') == 'limon'
    assert epithet_of('Monstera') == ''


def test_csv_roundtrip(tmp_path):
    a = PlantEntry.from_name('Monstera deliciosa Liebm.', 'Araceae', fr='Monstera', en='Swiss cheese plant')
    a.synonyms = ['Philodendron pertusum']
    a.gbif_key = 2868241
    b = PlantEntry.from_name('Epipremnum aureum', 'Araceae', fr='Pothos')
    path = tmp_path / 'plants.csv'
    save_plants(path, [a, b])
    back = load_plants(path)
    assert [e.scientific_name for e in back] == ['Monstera deliciosa', 'Epipremnum aureum']
    assert back[0].internal_id == 'monstera-deliciosa'
    assert back[0].common_names == {'fr': 'Monstera', 'en': 'Swiss cheese plant'}
    assert back[0].synonyms == ['Philodendron pertusum']
    assert back[0].gbif_key == 2868241
    assert back[1].gbif_key is None


def test_match_to_catalog_by_name_and_synonym():
    entries = [PlantEntry.from_name('Monstera deliciosa', 'Araceae'), PlantEntry.from_name('Dracaena trifasciata', 'Asparagaceae')]
    entries[1].synonyms = ['Sansevieria trifasciata Prain']
    assert match_to_catalog('Monstera deliciosa Liebm.', entries) is entries[0]
    assert match_to_catalog('Sansevieria trifasciata', entries) is entries[1]
    assert match_to_catalog('Plantus imaginarius', entries) is None
    assert match_to_catalog('', entries) is None
