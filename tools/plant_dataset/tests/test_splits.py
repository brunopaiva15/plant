import csv
import hashlib

from plant_dataset.manifest import STATUS_KEPT, STATUS_REJECTED, ImageRecord, now_iso
from plant_dataset.splits import RATIOS, assign_groups, group_key, make_splits, split_for, write_splits


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
    assert set(rows[0]) == {'path', 'species', 'internal_plant_id', 'split', 'group'}
    assert sum(sum(v.values()) for v in counts.values()) == 2
    assert 'Ficus elastica' in counts and 'Monstera deliciosa' in counts
