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


# --- Une coupure ne doit plus coûter une heure ----------------------------

def test_la_reprise_saute_ce_qui_est_deja_converti(tmp_path):
    src, out = tmp_path / 'jeu', tmp_path / 'sortie'
    _jeu(src, [(384, 288), (384, 288), (384, 288)])
    rows = lignes(src)
    convertir(rows[:2], src, out, 366)          # une passe interrompue
    avant = {p: p.stat().st_mtime_ns for p in out.rglob('*.jpg')}
    assert len(avant) == 2
    convertir(rows, src, out, 366, reprendre=True)
    apres = {p: p.stat().st_mtime_ns for p in out.rglob('*.jpg')}
    assert len(apres) == 3, 'la troisième est écrite'
    for p, t in avant.items():
        assert apres[p] == t, f'{p.name} ne devait pas être réécrite'


def test_sans_reprise_tout_est_reecrit(tmp_path):
    src, out = tmp_path / 'jeu', tmp_path / 'sortie'
    _jeu(src, [(384, 288), (384, 288)])
    rows = lignes(src)
    convertir(rows, src, out, 366)
    avant = {p: p.stat().st_mtime_ns for p in out.rglob('*.jpg')}
    convertir(rows, src, out, 366)
    apres = {p: p.stat().st_mtime_ns for p in out.rglob('*.jpg')}
    assert any(apres[p] != t for p, t in avant.items()), 'sans --reprendre, on réécrit'


def test_un_fichier_vide_ne_compte_pas_comme_converti(tmp_path):
    # Une coupure au milieu d'une écriture laisse un fichier de taille nulle :
    # le sauter figerait le défaut dans le jeu.
    src, out = tmp_path / 'jeu', tmp_path / 'sortie'
    _jeu(src, [(384, 288)])
    rows = lignes(src)
    vide = out / rows[0][0].relative_to(src)
    vide.parent.mkdir(parents=True, exist_ok=True)
    vide.touch()
    convertir(rows, src, out, 366, reprendre=True)
    assert vide.stat().st_size > 0, 'le fichier vide est refait'


# --- Un jeu converti doit être un jeu complet -----------------------------

from prereduire import copier_metadonnees  # noqa: E402


def test_tous_les_fichiers_de_la_racine_suivent(tmp_path):
    # train.py lit splits.csv **et** manifest.jsonl : sans le second il
    # s'arrête net, et le dossier ressemble à un jeu sans en être un.
    src, out = tmp_path / 'jeu', tmp_path / 'sortie'
    (src / 'Esp').mkdir(parents=True)
    for nom in ('splits.csv', 'manifest.jsonl', 'species.json', 'stats.json'):
        (src / nom).write_text(f'contenu de {nom}', encoding='utf-8')
    out.mkdir()
    faits = copier_metadonnees(src, out)
    assert set(faits) == {'splits.csv', 'manifest.jsonl', 'species.json', 'stats.json'}
    for nom in faits:
        assert (out / nom).read_text(encoding='utf-8') == f'contenu de {nom}'


def test_les_sous_dossiers_ne_sont_pas_recopies(tmp_path):
    src, out = tmp_path / 'jeu', tmp_path / 'sortie'
    (src / 'Esp').mkdir(parents=True)
    (src / 'splits.csv').write_text('x', encoding='utf-8')
    out.mkdir()
    assert copier_metadonnees(src, out) == ['splits.csv']


def test_une_metadonnee_perimee_est_remplacee(tmp_path):
    # Le cas réel : le jeu a été redécoupé après la conversion, donc le
    # splits.csv converti est celui d'avant.
    src, out = tmp_path / 'jeu', tmp_path / 'sortie'
    src.mkdir(); out.mkdir()
    (src / 'splits.csv').write_text('ancien', encoding='utf-8')
    copier_metadonnees(src, out)
    (src / 'splits.csv').write_text('nouveau', encoding='utf-8')
    copier_metadonnees(src, out)
    assert (out / 'splits.csv').read_text(encoding='utf-8') == 'nouveau'
