"""La taille d'entrée du réseau, et le chargement qui doit la suivre.

`IMAGE_SIZE` et `LOAD_SIZE` étaient des constantes qu'il fallait éditer à la
main avant un entraînement à 320 px. Une édition à la main juste avant une
passe d'une demi-heure est le genre de chose qui se fait de travers et ne se
voit qu'au chiffre final : changer l'entrée sans le chargement recadre
autrement que ce que `model.json` annonce à l'application, et coûte des
points sans qu'on sache d'où ils viennent.
"""
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import train  # noqa: E402


@pytest.fixture(autouse=True)
def restore():
    """Les constantes sont globales : chaque test remet celles d'origine."""
    avant = (train.IMAGE_SIZE, train.LOAD_SIZE)
    yield
    train.IMAGE_SIZE, train.LOAD_SIZE = avant


def test_load_size_follows_the_input():
    train.set_input_size(320)
    assert train.IMAGE_SIZE == 320
    assert train.LOAD_SIZE == 366          # 320 × 256/224, la même marge d'un huitième


def test_the_crop_margin_is_preserved():
    ratio = train.LOAD_SIZE / train.IMAGE_SIZE
    for px in (256, 288, 320, 384):
        train.set_input_size(px)
        assert train.LOAD_SIZE / train.IMAGE_SIZE == pytest.approx(ratio, abs=0.005)
        train.IMAGE_SIZE, train.LOAD_SIZE = 224, 256


def test_beyond_the_stored_size_is_refused():
    """Le jeu est stocké à 448 px : au-delà, on agrandirait sans créer de détail."""
    with pytest.raises(SystemExit, match='448'):
        train.set_input_size(448)


def test_a_size_that_fits_exactly_is_accepted():
    train.set_input_size(392)              # 392 × 256/224 = 448, la limite
    assert train.LOAD_SIZE == train.SOURCE_SIZE


def test_too_small_is_refused():
    with pytest.raises(SystemExit, match='trop petit'):
        train.set_input_size(16)


def test_the_exported_metadata_follows():
    """`model.json` porte la recette de prétraitement que l'application relit."""
    train.set_input_size(320)
    assert (train.IMAGE_SIZE, train.LOAD_SIZE) == (320, 366)
