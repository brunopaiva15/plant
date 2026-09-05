import io

import numpy as np
import pytest
from PIL import Image

from plant_dataset.dedup import flag_cross_species, mark_duplicates, near_duplicate_groups
from plant_dataset.images import ImageRejected, hamming, phash64, prepare
from plant_dataset.manifest import STATUS_DUPLICATE, STATUS_KEPT, STATUS_REVIEW, ImageRecord, now_iso


def picture(seed: int, size=(440, 360), fmt='JPEG', **save) -> bytes:
    """Une image de test : un champ aléatoire lisse, propre à chaque graine.

    Ce n'est pas une plante, c'est un fichier dont on connaît la vérité. Le
    champ est tiré en basse résolution puis agrandi : deux graines donnent
    des images franchement différentes — ce que des sinusoïdes de fréquences
    voisines ne garantissaient pas — tandis qu'une même graine réencodée
    reste la même image.
    """
    rng = np.random.default_rng(seed)
    coarse = rng.uniform(0, 255, size=(6, 7, 3))
    img = Image.fromarray(coarse.astype(np.uint8), 'RGB').resize(size, Image.BICUBIC)
    arr = np.clip(np.asarray(img, dtype=np.float64) + rng.normal(0, 6, size=(size[1], size[0], 3)), 0, 255)
    out = io.BytesIO()
    Image.fromarray(arr.astype(np.uint8), 'RGB').save(out, fmt, **save)
    return out.getvalue()


def test_prepare_accepts_a_sound_jpeg():
    # Sous MAX_SIDE : l'image traverse le préparateur sans être touchée.
    p = prepare(picture(1))
    assert p.width == 440 and p.height == 360
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
    data = picture(5, size=(440, 360))
    img = Image.open(io.BytesIO(data))
    exif = img.getexif()
    exif[0x0112] = 6  # tourner de 90°
    out = io.BytesIO()
    img.save(out, 'JPEG', exif=exif.tobytes())
    p = prepare(out.getvalue())
    assert (p.width, p.height) == (360, 440)
    assert Image.open(io.BytesIO(p.data)).getexif().get(0x0112, 1) == 1


def test_large_image_is_downscaled_to_max_side():
    p = prepare(picture(12, size=(3000, 2000)))
    assert (p.width, p.height) == (448, 299)
    assert Image.open(io.BytesIO(p.data)).size == (448, 299)
    # Une image déjà sous la limite est stockée telle quelle, octet pour
    # octet : pas de réencodage, donc pas de perte de génération.
    small = picture(13, size=(440, 360))
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


def test_band_bucketing_finds_exactly_the_same_pairs_as_brute_force():
    """L'optimisation ne doit rien perdre : sur des empreintes tirées au
    hasard, les paires proches trouvées par bandes sont exactement celles
    qu'une comparaison exhaustive aurait trouvées."""
    from plant_dataset.dedup import candidate_pairs
    from plant_dataset.images import hamming

    rng = np.random.default_rng(1234)
    values = [int(rng.integers(0, 2 ** 63)) for _ in range(400)]
    # Quelques voisins délibérés, à 1 à 6 bits du premier.
    for bits in range(1, 7):
        flip = 0
        for b in rng.choice(64, size=bits, replace=False):
            flip |= 1 << int(b)
        values.append(values[0] ^ flip)
    # Et un voisin à 7 bits, qui ne doit surtout pas être compté.
    flip = 0
    for b in rng.choice(64, size=7, replace=False):
        flip |= 1 << int(b)
    values.append(values[1] ^ flip)

    items = [(None, v) for v in values]
    threshold = 6
    brute = {(i, j) for i in range(len(values)) for j in range(i + 1, len(values))
             if hamming(values[i], values[j]) <= threshold}
    fast = {tuple(sorted(p)) for p in candidate_pairs(items, threshold)
            if hamming(values[p[0]], values[p[1]]) <= threshold}
    assert fast == brute
    assert len(brute) >= 6, 'les voisins fabriqués doivent bien être trouvés'


def test_band_bucketing_examines_far_fewer_pairs():
    """L'économie doit croître avec la taille : c'est à grande échelle que le
    coût quadratique faisait tomber la collecte, pas sur quelques centaines
    d'images."""
    from plant_dataset.dedup import candidate_pairs

    rng = np.random.default_rng(7)

    def ratio(n: int) -> float:
        items = [(None, int(rng.integers(0, 2 ** 63))) for _ in range(n)]
        return sum(1 for _ in candidate_pairs(items, 6)) / (n * (n - 1) / 2)

    small, large = ratio(1000), ratio(8000)
    assert large < small, 'la proportion de paires examinées doit baisser quand le jeu grandit'
    assert large < 0.05, f'{large:.1%} des paires encore examinées à 8 000 images'
