"""La fusion de collectes menées en parallèle.

Une part ne voit que ses espèces. La fusion doit rendre un jeu identique à
celui d'une collecte d'un seul tenant : tous les manifestes bout à bout, tous
les dossiers d'images, et les résolutions de noms des deux côtés — sans
laisser derrière elle les fichiers que la finalisation refera (`splits.csv`,
`stats.json`, les attributions).
"""
import json
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from merge_shards import merge, merge_caches  # noqa: E402


def make_shard(root: Path, species: dict[str, list[str]], caches: dict | None = None) -> Path:
    root.mkdir(parents=True)
    with open(root / 'manifest.jsonl', 'w', encoding='utf-8') as f:
        for name, files in species.items():
            for checksum in files:
                f.write(json.dumps({'species': name, 'checksum': checksum,
                                    'path': f'{name}/{checksum}.jpg'}) + '\n')
    for name, files in species.items():
        (root / name).mkdir()
        for checksum in files:
            (root / name / f'{checksum}.jpg').write_bytes(b'jpeg')
    # Ce que la finalisation de la part a écrit, et qui sera refait.
    (root / 'splits.csv').write_text('path,species\n')
    (root / 'stats.json').write_text('{}')
    (root / 'ATTRIBUTIONS.md').write_text('#\n')
    for name, content in (caches or {}).items():
        (root / name).write_text(json.dumps(content))
    return root


def test_la_fusion_rassemble_manifestes_et_images(tmp_path):
    a = make_shard(tmp_path / 'a', {'Monstera_deliciosa': ['aa', 'bb']})
    b = make_shard(tmp_path / 'b', {'Aloe_vera': ['cc']})
    out = tmp_path / 'dataset'

    counts = merge([a, b], out)

    assert counts['lignes'] == 3
    lines = [json.loads(l) for l in (out / 'manifest.jsonl').read_text().splitlines()]
    assert {r['checksum'] for r in lines} == {'aa', 'bb', 'cc'}
    assert sorted(p.name for p in out.rglob('*.jpg')) == ['aa.jpg', 'bb.jpg', 'cc.jpg']


def test_la_fusion_ne_recopie_pas_ce_qui_sera_refait(tmp_path):
    a = make_shard(tmp_path / 'a', {'Monstera_deliciosa': ['aa']})
    out = tmp_path / 'dataset'

    merge([a], out)

    for name in ('splits.csv', 'stats.json', 'ATTRIBUTIONS.md'):
        assert not (out / name).exists(), f'{name} vient d\'une part, il doit être refait sur l\'ensemble'


def test_les_dossiers_de_statut_se_rejoignent(tmp_path):
    """`_rejected` existe dans chaque part : le second ne doit pas écraser le
    premier, ni faire échouer la fusion."""
    a = make_shard(tmp_path / 'a', {'Monstera_deliciosa': ['aa'], '_rejected': ['x']})
    b = make_shard(tmp_path / 'b', {'Aloe_vera': ['cc'], '_rejected': ['y']})
    out = tmp_path / 'dataset'

    merge([a, b], out)

    assert sorted(p.name for p in (out / '_rejected').iterdir()) == ['x.jpg', 'y.jpg']


def test_les_resolutions_de_noms_des_deux_parts_sont_gardees(tmp_path):
    a = make_shard(tmp_path / 'a', {'Monstera_deliciosa': ['aa']},
                   {'species.json': {'Monstera deliciosa': {'key': 1}}})
    b = make_shard(tmp_path / 'b', {'Aloe_vera': ['cc']},
                   {'species.json': {'Aloe vera': {'key': 2}}, 'species_inat.json': {'Aloe vera': {'id': 9}}})
    out = tmp_path / 'dataset'
    out.mkdir()

    sizes = merge_caches([a, b], out)

    assert sizes['species.json'] == 2
    assert json.loads((out / 'species.json').read_text())['Aloe vera']['key'] == 2
    assert json.loads((out / 'species_inat.json').read_text())['Aloe vera']['id'] == 9


def test_une_part_sans_manifeste_arrete_la_fusion(tmp_path):
    """Une part interrompue avant d'écrire quoi que ce soit produirait un jeu
    silencieusement incomplet. Mieux vaut s'arrêter."""
    a = make_shard(tmp_path / 'a', {'Monstera_deliciosa': ['aa']})
    vide = tmp_path / 'vide'
    vide.mkdir()

    with pytest.raises(SystemExit):
        merge([a, vide], tmp_path / 'dataset')
