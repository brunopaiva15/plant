"""Les sources d'images. Chaque collecteur rend des `ImageCandidate` : une
image, sa page d'origine, son auteur et sa licence telle que la source la
déclare. C'est le filtre de licence, en aval, qui décide."""
from __future__ import annotations

from dataclasses import dataclass


@dataclass
class ImageCandidate:
    source: str
    source_id: str
    observation_id: str
    original_url: str
    image_url: str
    author: str
    license_raw: str        # tel que la source le donne (URL ou code)
    publisher: str = ''
    dataset_key: str = ''
    extra: dict | None = None
