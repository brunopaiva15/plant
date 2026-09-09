import csv
import hashlib

from plant_dataset.manifest import STATUS_KEPT, STATUS_REJECTED, ImageRecord, now_iso
from plant_dataset.splits import (RATIOS, assign_groups, group_key, make_splits,
                                  repair_species_coverage, split_for, write_splits)


def rec(i, species='Monstera deliciosa', obs=None, phash=None, status=STATUS_KEPT):
    return ImageRecord(species=species, internal_plant_id='x', source='gbif', source_id=f'{i}#0', original_url='', image_url='',
                       author='a', license='CC BY 4.0', license_url='', downloaded_at=now_iso(), checksum=f'{i:064x}',
                       path=f'{species}/{i}.jpg', observation_id=obs or str(i), phash=phash or hashlib.sha256(str(i).encode()).hexdigest()[:16], status=status)


def test_split_is_deterministic_and_roughly_proportional():
    counts = {'train': 0, 'val': 0, 'test': 0}
    for i in range(5000):
        counts[split_for(f'gbif:{i}')] += 1
    assert split_for('gbif:1') == split_for('gbif:1')
    for name, ratio in RATIOS.items():
        assert abs(counts[name] / 5000 - ratio) < 0.03, counts


def test_same_observation_stays_together():
    records = [rec(1, obs='obs'), rec(2, obs='obs'), rec(3)]
    groups = assign_groups(records)
    assert groups[records[0].checksum] == groups[records[1].checksum]
    assert groups[records[0].checksum] != groups[records[2].checksum]
    assert group_key(records[0]) == 'gbif:obs'
    splits = make_splits(records)
    assert splits[records[0].checksum] == splits[records[1].checksum]


def test_near_duplicates_across_observations_merge_groups():
    records = [rec(1, phash='0' * 16), rec(2, phash='0' * 15 + '1'), rec(3, phash='f' * 16)]
    groups = assign_groups(records)
    assert groups[records[0].checksum] == groups[records[1].checksum]
    assert groups[records[2].checksum] != groups[records[0].checksum]


def test_rejected_records_have_no_split(tmp_path):
    records = [rec(1), rec(2, status=STATUS_REJECTED), rec(3, species='Ficus elastica')]
    counts = write_splits(records, tmp_path / 'splits.csv')
    rows = list(csv.DictReader(open(tmp_path / 'splits.csv')))
    assert [r['path'] for r in rows] == ['Ficus elastica/3.jpg', 'Monstera deliciosa/1.jpg']
    assert set(rows[0]) == {'path', 'species', 'internal_plant_id', 'split', 'group', 'captive'}
    assert sum(sum(v.values()) for v in counts.values()) == 2
    assert 'Ficus elastica' in counts and 'Monstera deliciosa' in counts


def test_captive_column_marks_cultivated_photos(tmp_path):
    potted = rec(7, species='Yucca gigantea')
    potted.extra = {'captive': True}
    wild = rec(8, species='Yucca gigantea')
    write_splits([potted, wild], tmp_path / 'splits.csv')
    rows = {r['path']: r['captive'] for r in csv.DictReader(open(tmp_path / 'splits.csv'))}
    assert rows[potted.path] == '1'
    assert rows[wild.path] == '0'


def test_repair_gives_val_then_test_to_a_species_that_had_neither():
    records = [rec(1, obs='a'), rec(2, obs='a'), rec(3, obs='b'), rec(4, obs='c')]
    groups = assign_groups(records)
    splits = {ck: 'train' for ck in groups}
    assert repair_species_coverage(records, splits, groups) == {'Monstera deliciosa': ['val', 'test']}
    assert {splits[r.checksum] for r in records} == {'train', 'val', 'test'}
    # Le groupe déplacé reste entier : les deux photos de « a » vont ensemble.
    assert splits[records[0].checksum] == splits[records[1].checksum]


def test_repair_moves_the_smallest_group_first():
    records = [rec(1, obs='gros'), rec(2, obs='gros'), rec(3, obs='gros'),
               rec(4, obs='petit'), rec(5, obs='moyen'), rec(6, obs='moyen')]
    groups = assign_groups(records)
    splits = {ck: 'train' for ck in groups}
    repair_species_coverage(records, splits, groups)
    assert splits[records[3].checksum] == 'val'      # « petit », une image
    assert splits[records[4].checksum] == 'test'     # « moyen », deux
    assert splits[records[0].checksum] == 'train'    # « gros » reste à l'entraînement


def test_repair_leaves_alone_a_species_that_already_has_both():
    records = [rec(i, obs=f'o{i}') for i in range(1, 6)]
    splits = dict(zip((r.checksum for r in records), ['train', 'train', 'val', 'test', 'train']))
    groups = assign_groups(records)
    avant = dict(splits)
    assert repair_species_coverage(records, splits, groups) == {}
    assert splits == avant


def test_repair_never_empties_the_training_set():
    """Une espèce dont toutes les photos viennent d'une seule observation n'a
    rien à donner : la vider pour la mesurer ne l'avancerait à rien."""
    records = [rec(1, obs='seule'), rec(2, obs='seule')]
    groups = assign_groups(records)
    splits = {ck: 'train' for ck in groups}
    assert repair_species_coverage(records, splits, groups) == {}
    assert set(splits.values()) == {'train'}


def test_repair_only_moves_what_was_in_train():
    """La réparation est additive : ce qui était déjà en validation ou en test
    ne bouge pas, sinon la comparaison avec le modèle précédent mentirait."""
    records = [rec(i, species='Hoya kerrii', obs=f'o{i}') for i in range(1, 12)]
    brut = make_splits(records, repair=False)
    repare = make_splits(records, repair=True)
    for ck, cote in brut.items():
        if cote != 'train':
            assert repare[ck] == cote
    assert {'train', 'val'} <= set(repare.values())


def test_repair_is_deterministic():
    records = [rec(i, obs=f'o{i}') for i in range(1, 9)]
    groups = assign_groups(records)
    a, b = {ck: 'train' for ck in groups}, {ck: 'train' for ck in groups}
    repair_species_coverage(records, a, groups)
    repair_species_coverage(records, b, groups)
    assert a == b


def test_write_splits_repairs_by_default(tmp_path):
    records = [rec(i, species='Howea forsteriana', obs='une-seule-sortie') for i in range(1, 4)]
    records += [rec(i, species='Howea forsteriana', obs=f'o{i}') for i in range(4, 9)]
    counts = write_splits(records, tmp_path / 'splits.csv')
    assert counts['Howea forsteriana'].get('val', 0) >= 1
