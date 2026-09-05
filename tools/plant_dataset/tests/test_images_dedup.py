import io

import numpy as np
import pytest
from PIL import Image

from plant_dataset.dedup import flag_cross_species, mark_duplicates, near_duplicate_groups
from plant_dataset.images import ImageRejected, hamming, phash64, prepare
from plant_dataset.manifest import STATUS_DUPLICATE, STATUS_KEPT, STATUS_REVIEW, ImageRecord, now_iso


def picture(seed: int, size=(640, 480), fmt='JPEG', **save) -> bytes:
    """Une image de test : un dégradé bruité, différent à chaque graine.
    Ce n'est pas une plante, c'est un fichier dont on connaît la vérité."""
    rng = np.random.default_rng(seed)
    y, x = np.mgrid[0:size[1], 0:size[0]]
    base = (np.sin(x / (30 + seed % 17)) * 80 + np.cos(y / (23 + seed % 11)) * 80 + 128)
    noise = rng.normal(0, 12, size=(size[1], size[0]))
    arr = np.clip(np.stack([base + noise, base * 0.7 + noise, base * 0.4 + noise], -1), 0, 255).astype(np.uint8)
    out = io.BytesIO()
    Image.fromarray(arr, 'RGB').save(out, fmt, **save)
    return out.getvalue()


def test_prepare_accepts_a_sound_jpeg():
    p = prepare(picture(1))
    assert p.width == 640 and p.height == 480
    assert len(p.sha256) == 64 and len(p.phash) == 16
    assert p.source_format == 'JPEG'


def test_prepare_rejects_corrupt_small_and_odd_formats():
    with pytest.raises(ImageRejected, match='corrompu'):
        prepare(b'not an image at all')
    with pytest.raises(ImageRejected, match='trop petite'):
        prepare(picture(2, size=(200, 150)))
    with pytest.raises(ImageRejected, match='format'):
        prepare(picture(3, size=(400, 400), fmt='GIF'))
    with pytest.raises(ImageRejected, match='proportions'):
        prepare(picture(4, size=(4000, 320)))


def test_prepare_applies_exif_orientation():
    data = picture(5, size=(640, 400))
    img = Image.open(io.BytesIO(data))
    exif = img.getexif()
    exif[0x0112] = 6  # tourner de 90°
    out = io.BytesIO()
    img.save(out, 'JPEG', exif=exif.tobytes())
    p = prepare(out.getvalue())
    assert (p.width, p.height) == (400, 640)
    assert Image.open(io.BytesIO(p.data)).getexif().get(0x0112, 1) == 1


def test_large_image_is_downscaled_to_max_side():
    p = prepare(picture(12, size=(3000, 2000)))
    assert (p.width, p.height) == (640, 427)
    assert Image.open(io.BytesIO(p.data)).size == (640, 427)
    # Une image déjà sous la limite est stockée telle quelle, octet pour
    # octet : pas de réencodage, donc pas de perte de génération.
    small = picture(13, size=(600, 450))
    assert prepare(small).data == small


def test_png_is_stored_as_jpeg():
    p = prepare(picture(6, fmt='PNG'))
    assert p.source_format == 'PNG'
    assert Image.open(io.BytesIO(p.data)).format == 'JPEG'


def test_phash_close_for_recompressed_far_for_different():
    a = prepare(picture(7))
    a_again = prepare(picture(7, quality=55))
    b = prepare(picture(8))
    assert hamming(int(a.phash, 16), int(a_again.phash, 16)) <= 6
    assert hamming(int(a.phash, 16), int(b.phash, 16)) > 12


def rec(species, checksum, phash, obs, when='2026-01-01T00:00:00Z'):
    return ImageRecord(species=species, internal_plant_id=species.lower().replace(' ', '-'), source='gbif', source_id=f'{obs}#0',
                       original_url='', image_url='', author='x', license='CC BY 4.0', license_url='', downloaded_at=when,
                       checksum=checksum, path=f'{species}/{checksum[:4]}.jpg', observation_id=obs, phash=phash)


def test_mark_duplicates_exact_and_near():
    a = prepare(picture(9)); a2 = prepare(picture(9, quality=50)); b = prepare(picture(10))
    records = [
        rec('Monstera deliciosa', a.sha256, a.phash, '1'),
        rec('Monstera deliciosa', a.sha256, a.phash, '2'),               # exact
        rec('Monstera deliciosa', a2.sha256, a2.phash, '3', when='2026-01-02T00:00:00Z'),  # quasi
        rec('Monstera deliciosa', b.sha256, b.phash, '4'),
    ]
    counts = mark_duplicates(records)
    assert counts == {'exact': 1, 'near': 1}
    assert records[1].status == STATUS_DUPLICATE and records[1].duplicate_of == a.sha256
    assert records[2].status == STATUS_DUPLICATE and records[2].duplicate_of == a.sha256
    assert records[0].status == STATUS_KEPT and records[3].status == STATUS_KEPT


def test_cross_species_near_duplicate_goes_to_review():
    a = prepare(picture(11)); a2 = prepare(picture(11, quality=60))
    records = [rec('Monstera deliciosa', a.sha256, a.phash, '1'), rec('Ficus elastica', a2.sha256, a2.phash, '2')]
    assert not near_duplicate_groups(records)   # pas un doublon *intra* espèce
    assert flag_cross_species(records) == 2
    assert all(r.status == STATUS_REVIEW for r in records)
    assert 'Ficus elastica' in records[0].reason
