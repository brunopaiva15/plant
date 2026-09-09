"""La reprise après échecs de collecte.

Les journaux ci-dessous sont ceux d'une vraie collecte en quatre parts, où
216 espèces sur 1 558 sont tombées sur des limitations de débit. Ce qui
compte : retrouver les noms exactement, ne pas confondre un `:` du message
d'erreur avec celui qui suit le nom, et rendre le motif — parce que « 429 »
et « une image illisible » n'appellent pas la même réponse.
"""
import pytest
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from failed_species import failures, main  # noqa: E402

JOURNAL = """[1/390] Monstera deliciosa: 42 gardées (gbif 30, inat 12)
[2/390] Ficus elastica: ÉCHEC (HTTPError: 429 Client Error: Too Many Requests for url: https://api.inaturalist.org/v1/observations), espèce sautée
[3/390] Citrus × limon: ÉCHEC (ConnectionError: ('Connection aborted.', RemoteDisconnected)), espèce sautée
[4/390] Pilea peperomioides: 200 gardées (gbif 140, inat 60)
"""


def test_le_nom_s_arrete_avant_le_motif():
    """Le message d'erreur contient lui-même « : » — c'est `ÉCHEC` qui
    borne le nom, pas le premier deux-points venu."""
    assert failures(JOURNAL) == [('Ficus elastica', 'HTTPError'),
                                 ('Citrus × limon', 'ConnectionError')]


def test_une_espece_tombee_deux_fois_ne_se_reprend_qu_une():
    deux = JOURNAL + '[9/390] Ficus elastica: ÉCHEC (Timeout: lecture), espèce sautée\n'
    assert [n for n, _ in failures(deux)] == ['Ficus elastica', 'Citrus × limon']


def test_les_listes_de_reprise_suivent_l_ordre_des_journaux(tmp_path, monkeypatch, capsys):
    """Une espèce doit revenir dans **sa** part : éclatée entre deux
    dossiers, elle se retrouverait comptée deux fois à la fusion."""
    (tmp_path / 'shard0.log').write_text(JOURNAL, encoding='utf-8')
    (tmp_path / 'shard1.log').write_text(
        '[7/390] Sedum morganianum: ÉCHEC (HTTPError: 429), espèce sautée\n', encoding='utf-8')
    monkeypatch.chdir(tmp_path)
    assert main(['--write', 'retry', 'shard0.log', 'shard1.log']) == 0
    assert (tmp_path / 'retry0.txt').read_text(encoding='utf-8').splitlines() == [
        'Ficus elastica', 'Citrus × limon']
    assert (tmp_path / 'retry1.txt').read_text(encoding='utf-8').splitlines() == ['Sedum morganianum']
    assert '2  HTTPError' in capsys.readouterr().err


def test_un_journal_sans_echec_donne_une_liste_vide(tmp_path, monkeypatch):
    (tmp_path / 'ok.log').write_text('[1/2] Monstera deliciosa: 42 gardées\n', encoding='utf-8')
    monkeypatch.chdir(tmp_path)
    assert main(['--write', 'retry', 'ok.log']) == 0
    assert (tmp_path / 'retry0.txt').read_text(encoding='utf-8') == ''


def test_une_espece_jamais_traitee_est_reprise_aussi(tmp_path, monkeypatch, capsys):
    """Le cas « 389/390 » : la part a été tuée avant sa dernière espèce, qui
    n'a donc aucune ligne — pas même un ÉCHEC. Rien ne la distingue d'une
    espèce inexistante, sauf la liste qu'on avait confiée à la part."""
    (tmp_path / 'shard0.log').write_text(JOURNAL, encoding='utf-8')
    (tmp_path / 'shard0.txt').write_text(
        'Monstera deliciosa\nFicus elastica\nCitrus × limon\nPilea peperomioides\nSedum morganianum\n',
        encoding='utf-8')
    monkeypatch.chdir(tmp_path)
    assert main(['--write', 'retry', '--against', 'shard0.txt', 'shard0.log']) == 0
    assert (tmp_path / 'retry0.txt').read_text(encoding='utf-8').splitlines() == [
        'Ficus elastica', 'Citrus × limon', 'Sedum morganianum']
    assert 'jamais traitée' in capsys.readouterr().err


def test_un_nom_non_resolu_n_est_pas_a_reprendre(tmp_path, monkeypatch):
    """« nom non résolu chez GBIF » n'est pas une panne : relancer n'y
    changera rien, c'est `synonyms.txt` qui répond. L'espèce a une ligne,
    donc `--against` ne la ramasse pas non plus."""
    (tmp_path / 'shard0.log').write_text(
        '[1/2] Sorbus aria: nom non résolu chez GBIF (FAMILY), à revoir\n'
        '[2/2] Monstera deliciosa: 42 gardées\n', encoding='utf-8')
    (tmp_path / 'shard0.txt').write_text('Sorbus aria\nMonstera deliciosa\n', encoding='utf-8')
    monkeypatch.chdir(tmp_path)
    assert main(['--write', 'retry', '--against', 'shard0.txt', 'shard0.log']) == 0
    assert (tmp_path / 'retry0.txt').read_text(encoding='utf-8') == ''


def test_autant_de_listes_que_de_journaux(tmp_path, monkeypatch):
    (tmp_path / 'a.log').write_text(JOURNAL, encoding='utf-8')
    (tmp_path / 'b.log').write_text(JOURNAL, encoding='utf-8')
    (tmp_path / 'a.txt').write_text('Ficus elastica\n', encoding='utf-8')
    monkeypatch.chdir(tmp_path)
    with pytest.raises(SystemExit):
        main(['--against', 'a.txt', 'a.log', 'b.log'])
