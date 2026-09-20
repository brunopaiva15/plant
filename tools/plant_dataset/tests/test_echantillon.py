"""L'échantillon qui sert à mesurer une machine.

Ce qu'il ne doit jamais faire : produire un jeu dont `train.py` écarterait
des classes. Un échantillon annoncé à 120 classes et qui en enseigne 80
mesurerait autre chose que ce qu'on croit, et l'erreur serait invisible —
le débit resterait plausible.
"""
import csv
import json
import sys
from collections import Counter
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from echantillon import choisir, lire, main

MIN_TRAIN, MIN_VAL = 25, 3


def jeu(tmp_path: Path, especes: int = 5, gros: int = 3) -> Path:
    """Un jeu factice : `gros` espèces bien nourries, le reste maigres."""
    src = tmp_path / 'source'
    lignes = []
    for n in range(especes):
        cid = f'espece-{n}'
        quotas = {'train': 80 if n < gros else 10, 'val': 6, 'test': 6}
        for split, q in quotas.items():
            for i in range(q):
                rel = f'images/{cid}/{split}-{i}.jpg'
                p = src / rel
                p.parent.mkdir(parents=True, exist_ok=True)
                p.write_bytes(b'\xff\xd8' + bytes(400))
                lignes.append([rel, f'Genus specie{n}', cid, split, f'g{n}-{i}', '1' if i % 2 else '0'])
    # Une ligne qui annonce une image absente du disque : splits.csv en porte,
    # et `train.py` les ignore déjà (`read_splits` teste `path.exists()`).
    lignes.append([f'images/espece-0/fantome.jpg', 'Genus specie0', 'espece-0', 'train', 'gX', '0'])
    with open(src / 'splits.csv', 'w', newline='', encoding='utf-8') as f:
        w = csv.writer(f)
        w.writerow(['path', 'species', 'internal_plant_id', 'split', 'group', 'captive'])
        w.writerows(lignes)
    return src


def construire(tmp_path: Path, **kw) -> Path:
    src = jeu(tmp_path, **{k: v for k, v in kw.items() if k in ('especes', 'gros')})
    out = tmp_path / 'echantillon'
    sys.argv = ['echantillon.py', '--dataset', str(src), '--out', str(out),
                '--classes', str(kw.get('classes', 4)), '--train', str(kw.get('train', 60)),
                '--val', '5', '--test', '5']
    assert main() == 0
    return out


def lues(out: Path) -> dict[str, list[tuple[str, str]]]:
    """Ce que `read_splits` de `train.py` verrait, à la lettre."""
    rows = {'train': [], 'val': [], 'test': []}
    with open(out / 'splits.csv', newline='', encoding='utf-8') as f:
        for r in csv.DictReader(f):
            if (out / r['path']).exists():
                rows[r['split']].append((r['path'], r['internal_plant_id']))
    return rows


def test_every_kept_class_survives_the_thresholds_of_train_py(tmp_path):
    rows = lues(construire(tmp_path))
    train, val = Counter(p for _, p in rows['train']), Counter(p for _, p in rows['val'])
    utilisables = [c for c in train if train[c] >= MIN_TRAIN and val[c] >= MIN_VAL]
    assert utilisables, 'aucune classe utilisable'
    assert len(utilisables) == len(train), 'une classe copiée serait écartée par train.py'


def test_a_class_too_thin_is_left_out_rather_than_copied_short(tmp_path):
    """Copier une classe à dix images pour la voir écartée ensuite, c'est du
    disque dépensé pour rien."""
    rows = lues(construire(tmp_path, especes=5, gros=3, classes=5))
    classes = {p for _, p in rows['train']}
    assert classes == {'espece-0', 'espece-1', 'espece-2'}


def test_a_line_without_its_file_is_skipped(tmp_path):
    out = construire(tmp_path)
    assert not (out / 'images/espece-0/fantome.jpg').exists()
    with open(out / 'splits.csv', newline='', encoding='utf-8') as f:
        assert all(r['path'] != 'images/espece-0/fantome.jpg' for r in csv.DictReader(f))


def test_the_manifest_names_every_kept_class(tmp_path):
    """`train.py` y lit les noms d'espèces à l'export ; un identifiant absent
    ressortirait tel quel dans `model.json`."""
    out = construire(tmp_path)
    noms = {json.loads(l)['internal_plant_id'] for l in open(out / 'manifest.jsonl', encoding='utf-8')}
    assert noms == {p for _, p in lues(out)['train']}


def test_quotas_cap_each_split(tmp_path):
    rows = lues(construire(tmp_path, train=30))
    train = Counter(p for _, p in rows['train'])
    assert set(train.values()) == {30}
    assert set(Counter(p for _, p in rows['val']).values()) == {5}


def test_the_choice_is_deterministic(tmp_path):
    """Deux machines doivent prélever le même échantillon, sinon elles ne
    mesurent pas la même chose."""
    src = jeu(tmp_path)
    par_classe = lire(src)
    assert choisir(par_classe, 2, 60, 5, 5) == choisir(par_classe, 2, 60, 5, 5)


def test_impossible_thresholds_say_so(tmp_path):
    src = jeu(tmp_path)
    sys.argv = ['echantillon.py', '--dataset', str(src), '--out', str(tmp_path / 'x'),
                '--train', '5000']
    with pytest.raises(SystemExit):
        main()
