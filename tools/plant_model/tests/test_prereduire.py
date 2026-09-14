"""Pré-découper le jeu au carré, sans jamais agrandir.

Le § 13.6 voulait stocker le jeu « déjà réduit à la taille de chargement ».
Le jeu est stocké à 384 px de **grand** côté, et `read_and_square` se sert
du **petit** : à `--input-size 320` le chargement demande 366 px là où une
photo en 4:3 n'en a que 288. Réduire à 366 ajouterait des pixels. Ce qui en
retire, c'est le carré central — et jamais d'agrandissement à l'écriture.
"""
import csv
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from prereduire import carre_cible, convertir, convertir_une, lignes, load_size_pour  # noqa: E402


def test_load_size_suit_la_formule_de_train():
    assert load_size_pour(224) == 256
    assert load_size_pour(320) == 366


def test_le_carre_ne_depasse_jamais_ce_que_limage_a():
    # 384×288 : le carré central vaut 288, pas 366. C'est tout le sujet.
    assert carre_cible(384, 288, 366) == 288


def test_le_carre_ne_depasse_jamais_ce_que_le_chargement_demande():
    # Garder 400 px quand read_and_square en veut 366 serait payer un
    # décodage pour des pixels aussitôt jetés.
    assert carre_cible(500, 400, 366) == 366


def test_une_image_deja_carree_et_petite_ne_bouge_pas():
    assert carre_cible(200, 200, 366) == 200


def _image(path: Path, w: int, h: int) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    Image.new('RGB', (w, h), (120, 160, 90)).save(path, 'JPEG', quality=92)


def test_la_conversion_rend_un_carre_sans_agrandir(tmp_path):
    src, dst = tmp_path / 'a.jpg', tmp_path / 'b.jpg'
    _image(src, 384, 288)
    avant, apres = convertir_une(src, dst, 366)
    with Image.open(dst) as img:
        assert img.size == (288, 288), 'le petit côté décide, et on n\'agrandit pas'
    assert (avant, apres) == (384 * 288, 288 * 288)


def test_la_conversion_reduit_un_grand_carre(tmp_path):
    src, dst = tmp_path / 'a.jpg', tmp_path / 'b.jpg'
    _image(src, 800, 600)
    convertir_une(src, dst, 366)
    with Image.open(dst) as img:
        assert img.size == (366, 366)


def test_le_carre_est_bien_central(tmp_path):
    # Une bande rouge à gauche ne doit pas survivre au recadrage central.
    src, dst = tmp_path / 'a.jpg', tmp_path / 'b.jpg'
    img = Image.new('RGB', (300, 100), (0, 200, 0))
    for x in range(100):
        for y in range(100):
            img.putpixel((x, y), (255, 0, 0))
    src.parent.mkdir(parents=True, exist_ok=True)
    img.save(src, 'JPEG', quality=95)
    convertir_une(src, dst, 366)
    with Image.open(dst) as out:
        r, g, _ = out.convert('RGB').getpixel((50, 50))
    assert g > r, 'le carré central est vert, la bande rouge est hors cadre'


def _jeu(racine: Path, tailles: list[tuple[int, int]]) -> None:
    racine.mkdir(parents=True, exist_ok=True)
    with (racine / 'splits.csv').open('w', newline='', encoding='utf-8') as f:
        w = csv.writer(f)
        w.writerow(['path', 'species', 'internal_plant_id', 'split', 'group', 'captive'])
        for i, (lw, lh) in enumerate(tailles):
            rel = f'Espece_test/{i}.jpg'
            _image(racine / rel, lw, lh)
            w.writerow([rel, 'Espece test', 'espece-test', 'train', i, '0'])


def test_le_jeu_converti_garde_ses_chemins(tmp_path):
    # train.py lit `path` depuis splits.csv : si les chemins bougeaient, il
    # faudrait toucher à train.py, et ce n'est pas le marché.
    src, out = tmp_path / 'jeu', tmp_path / 'sortie'
    _jeu(src, [(384, 288), (384, 384), (300, 400)])
    convertir(lignes(src), src, out, 366)
    assert (out / 'splits.csv').read_text() == (src / 'splits.csv').read_text()
    for i, attendu in enumerate([288, 366, 300]):
        with Image.open(out / f'Espece_test/{i}.jpg') as img:
            assert img.size == (attendu, attendu)


def test_une_image_absente_narrete_pas_la_conversion(tmp_path):
    src, out = tmp_path / 'jeu', tmp_path / 'sortie'
    _jeu(src, [(384, 288), (384, 288)])
    (src / 'Espece_test/0.jpg').unlink()
    convertir(lignes(src), src, out, 366)
    assert (out / 'Espece_test/1.jpg').exists()
