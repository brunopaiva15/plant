"""Téléchargement et vérification des images.

Une image n'entre dans le jeu que si elle s'ouvre, a une taille utile, est
d'un format prévu, et une fois son orientation EXIF appliquée. On ne juge pas
son fond : une photo prise dans un salon encombré est exactement ce que le
modèle verra sur un téléphone.
"""
from __future__ import annotations

import hashlib
import io
from dataclasses import dataclass
from pathlib import Path

import numpy as np
import requests
from PIL import Image, ImageOps, UnidentifiedImageError

MIN_SIDE = 320             # en dessous, c'est une miniature
# Au-delà, l'image est réduite : les modèles mobiles s'entraînent en 224–384 px,
# et 1024 px laisse de quoi recadrer. Divise le disque par quatre environ.
MAX_SIDE = 1024
MAX_BYTES = 25 * 1024 * 1024
ALLOWED_FORMATS = {'JPEG', 'PNG', 'WEBP'}
JPEG_QUALITY = 92


@dataclass
class Prepared:
    data: bytes           # l'octet stocké (JPEG)
    sha256: str
    phash: str
    width: int
    height: int
    source_format: str


class ImageRejected(Exception):
    """L'image ne convient pas ; le message dit pourquoi."""


def download(url: str, session: requests.Session, timeout: float = 30.0, max_bytes: int = MAX_BYTES) -> bytes:
    with session.get(url, stream=True, timeout=timeout) as r:
        r.raise_for_status()
        length = r.headers.get('content-length')
        if length and int(length) > max_bytes:
            raise ImageRejected(f'fichier trop lourd ({length} octets)')
        buf = io.BytesIO()
        for chunk in r.iter_content(64 * 1024):
            buf.write(chunk)
            if buf.tell() > max_bytes:
                raise ImageRejected('fichier trop lourd')
        return buf.getvalue()


def phash64(img: Image.Image) -> int:
    """Empreinte perceptuelle sur 64 bits : DCT d'une vignette 32 × 32 en
    niveaux de gris, signe des 8 × 8 basses fréquences contre leur médiane.
    Deux photos qui ne diffèrent que par la compression, un recadrage léger
    ou une taille tombent à quelques bits l'une de l'autre."""
    g = np.asarray(img.convert('L').resize((32, 32), Image.LANCZOS), dtype=np.float64)
    n = 32
    k = np.arange(n)
    # Matrice DCT-II orthonormée
    c = np.sqrt(2.0 / n) * np.cos(np.pi * (2 * k[None, :] + 1) * k[:, None] / (2 * n))
    c[0, :] /= np.sqrt(2.0)
    dct = c @ g @ c.T
    low = dct[:8, :8].flatten()
    med = np.median(low[1:])
    bits = 0
    for i, v in enumerate(low):
        if v > med:
            bits |= 1 << (63 - i)
    return bits


def hamming(a: int, b: int) -> int:
    return bin(a ^ b).count('1')


def prepare(data: bytes, min_side: int = MIN_SIDE, max_side: int = MAX_SIDE) -> Prepared:
    """Vérifie l'image et la ramène à un JPEG droit, prêt à stocker."""
    try:
        probe = Image.open(io.BytesIO(data))
        probe.verify()
    except (UnidentifiedImageError, OSError, SyntaxError) as e:
        raise ImageRejected(f'fichier corrompu ou illisible : {e}') from e
    fmt = probe.format or ''
    if fmt not in ALLOWED_FORMATS:
        raise ImageRejected(f'format refusé : {fmt or "inconnu"}')
    img = Image.open(io.BytesIO(data))
    rotated = _needs_rewrite(img)
    try:
        img = ImageOps.exif_transpose(img)
    except Exception:  # EXIF abîmé : on garde l'image telle quelle
        pass
    if getattr(img, 'n_frames', 1) > 1:
        raise ImageRejected('image animée')
    w, h = img.size
    if min(w, h) < min_side:
        raise ImageRejected(f'trop petite ({w}×{h})')
    if max(w, h) > 12 * min(w, h):
        raise ImageRejected(f'proportions aberrantes ({w}×{h})')
    rgb = img.convert('RGB')
    resized = max(w, h) > max_side
    if resized:
        scale = max_side / max(w, h)
        rgb = rgb.resize((max(1, round(w * scale)), max(1, round(h * scale))), Image.LANCZOS)
        w, h = rgb.size
    if fmt == 'JPEG' and img.mode == 'RGB' and not rotated and not resized:
        stored = data
    else:
        out = io.BytesIO()
        rgb.save(out, 'JPEG', quality=JPEG_QUALITY, optimize=True)
        stored = out.getvalue()
    return Prepared(
        data=stored,
        sha256=hashlib.sha256(stored).hexdigest(),
        phash=f'{phash64(rgb):016x}',
        width=w,
        height=h,
        source_format=fmt,
    )


def _needs_rewrite(img: Image.Image) -> bool:
    """Un JPEG dont l'orientation EXIF n'est pas 1 doit être réécrit droit."""
    try:
        return img.getexif().get(0x0112, 1) != 1
    except Exception:
        return False


def store(prepared: Prepared, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(prepared.data)
