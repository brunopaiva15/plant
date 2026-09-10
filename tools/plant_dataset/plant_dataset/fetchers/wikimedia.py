"""Wikimedia Commons : les plantes telles que les gens les cultivent.

GBIF et iNaturalist décrivent des observations de terrain. Commons est une
médiathèque : on y photographie son monstera dans son salon, un pélargonium
sur un balcon, un ficus chez un fleuriste. C'est exactement la distribution
qui manque au modèle — le yucca de salon pris pour du maïs et le ficus
ginseng illisibles viennent de là (§ 6.3 et 6.5 de docs/09).

Deux mesures faites avant d'écrire ce fichier, sur nos propres espèces :

- **97 % des fichiers portent une licence utilisable**, contre 18 % chez
  GBIF, où les licences non commerciales écrasent tout. Sur Commons ce sont
  CC BY-SA 4.0, CC BY 4.0, CC BY-SA 3.0, CC0 et domaine public ;
- une catégorie d'espèce contient de l'ordre de la centaine de fichiers,
  davantage avec ses sous-catégories. C'est un **complément** à GBIF, pas un
  remplacement : la cible du projet est de 200 à 300 images par espèce.

Commons n'a pas de notion d'observation : chaque fichier est indépendant.
L'identifiant de page sert donc d'identifiant de source, et le groupe de
répartition retombe sur le fichier lui-même. Deux photos de la même plante
prises par la même personne ne seront pas reconnues comme un groupe — c'est
une limite acceptée, la déduplication par empreinte perceptuelle rattrape
les quasi-doublons.

La taxonomie ne bouge pas : Commons est une source d'images, GBIF reste la
référence des noms. Chaque image garde sa provenance et sa licence, et se
rattache à l'espèce par `species` et `internal_plant_id`, comme les autres.
"""
from __future__ import annotations

import re
import time
from typing import Iterator

import requests

from ..licenses import is_allowed, parse_license
from . import ImageCandidate

API = 'https://commons.wikimedia.org/w/api.php'
DEFAULT_UA = 'FloraPlantDataset/0.1 (github.com/brunopaiva15/plant; dataset builder)'
RETRIES = 5
PAGE = 100

#: Largeur demandée à Commons. Les originaux montent à plusieurs dizaines de
#: mégaoctets ; le pipeline réduit de toute façon à 448 px. Demander une
#: vignette large épargne la bande passante des deux côtés.
THUMB_WIDTH = 1280

#: Formats acceptés. Commons héberge aussi des SVG, des PDF et des TIFF, que
#: le pipeline ne saurait pas lire.
PHOTO_TYPES = {'image/jpeg', 'image/png', 'image/webp'}

#: Une catégorie d'espèce ne contient pas que des photographies : planches
#: botaniques du XIXe, scans d'herbier, cartes de répartition, schémas
#: anatomiques. Le modèle doit reconnaître une plante vivante ; ces images
#: sont du bruit, et le pipeline ne sait pas les distinguer d'une photo.
#: Filtre grossier sur le titre, assumé comme tel : il laisse passer des
#: dessins non nommés et écarte peut-être une vraie photo mal titrée.
NOT_A_PHOTO = re.compile(
    r'\b(illustration|drawing|dessin|zeichnung|engraving|gravure|lithograph|'
    r'botanical\s+plate|planche|k[öo]hler|flora\s+von|flora\s+of|'
    r'herbarium|herbier|specimen|holotype|isotype|lectotype|type\s+sheet|'
    r'distribution\s+map|carte|diagram|schema|logo|icon|stamp|timbre|'
    r'coat\s+of\s+arms|chromolith)\b', re.I)

_HYBRID = re.compile(r'\s*×\s*')

#: Sous-catégories à visiter d'abord, dans cet ordre. Commons range les
#: photos d'une espèce par contexte, et tous les contextes ne se valent pas
#: pour nous : `Monstera deliciosa (potted)` porte 41 fichiers de plantes en
#: pot, c'est-à-dire **exactement** ce que l'application reçoit et ce qui
#: manque au modèle (§ 12.4 de docs/09 : 73 % des erreurs franchissent la
#: famille, faute d'avoir vu la plante telle qu'on la cultive).
#:
#: Sans cet ordre, les six sous-catégories retenues étaient les six premières
#: rendues par l'API — `(potted)` passait ou ne passait pas au hasard, et
#: `(products)` prenait sa place.
SUBCAT_PRIORITAIRES = ('potted', 'in pots', 'indoor', 'houseplant', 'cultivars',
                       'cultivated', 'in gardens', 'garden')

#: Sous-catégories à ne pas visiter du tout : ce ne sont pas des photos de
#: la plante vivante. `NOT_A_PHOTO` les rattrape déjà par le nom de fichier,
#: mais les écarter au niveau de la catégorie évite d'y dépenser des places.
SUBCAT_REFUSEES = ('illustration', 'herbarium', 'specimen', 'products', 'stamps',
                   'coins', 'maps', 'diagram', 'seeds', 'wood', 'timber')


def classer_souscategories(noms: list[str], combien: int) -> list[str]:
    """Les sous-catégories qui valent le détour, les meilleures d'abord.

    Rend au plus `combien` noms : les prioritaires dans l'ordre de
    `SUBCAT_PRIORITAIRES`, puis les autres telles quelles, jamais les
    refusées.
    """
    gardees = [n for n in noms if not any(r in n.lower() for r in SUBCAT_REFUSEES)]

    def rang(nom: str) -> int:
        bas = nom.lower()
        for i, mot in enumerate(SUBCAT_PRIORITAIRES):
            if mot in bas:
                return i
        return len(SUBCAT_PRIORITAIRES)

    return sorted(gardees, key=rang)[:combien]
_TAGS = re.compile(r'<[^>]+>')


def _plain(html: str) -> str:
    """L'auteur arrive en HTML (un lien vers la page utilisateur, le plus
    souvent). L'attribution veut un nom, pas un fragment de page."""
    text = _TAGS.sub(' ', html or '')
    text = (text.replace('&amp;', '&').replace('&lt;', '<').replace('&gt;', '>')
                .replace('&quot;', '"').replace('&#039;', "'").replace('&nbsp;', ' '))
    return ' '.join(text.split())[:200]


def category_names(scientific_name: str) -> list[str]:
    """Les titres de catégorie à essayer pour une espèce, du plus probable au
    moins probable.

    Commons nomme ses catégories d'après le nom scientifique, mais le signe
    d'hybride s'y écrit tantôt « × », tantôt « x », tantôt pas du tout. Le
    citronnier avait déjà coûté une version entière à ce détail côté
    iNaturalist.
    """
    nom = ' '.join((scientific_name or '').split())
    if not nom:
        return []
    variantes = [nom, _HYBRID.sub(' x ', nom), _HYBRID.sub(' ', nom)]
    vus, sortie = set(), []
    for v in variantes:
        v = ' '.join(v.split())
        if v and v.lower() not in vus:
            vus.add(v.lower())
            sortie.append(v)
    return sortie


class CommonsClient:
    def __init__(self, session: requests.Session | None = None, user_agent: str = DEFAULT_UA,
                 pause: float = 1.0, timeout: float = 60.0):
        self.session = session or requests.Session()
        self.session.headers['User-Agent'] = user_agent
        self.pause = pause
        self.timeout = timeout

    def _get(self, **params) -> dict:
        params.update(action='query', format='json', formatversion='2')
        for attempt in range(RETRIES):
            try:
                r = self.session.get(API, params=params, timeout=self.timeout)
                if r.status_code == 429:
                    # Commons ne dit pas toujours combien de temps attendre ;
                    # à défaut, on recule franchement plutôt que d'insister.
                    time.sleep(float(r.headers.get('Retry-After') or min(15 * (attempt + 1), 60)))
                    raise requests.HTTPError('429', response=r)
                if r.status_code >= 500:
                    raise requests.HTTPError(str(r.status_code), response=r)
                r.raise_for_status()
                data = r.json()
                time.sleep(self.pause)
                return data
            except (requests.ConnectionError, requests.Timeout, requests.HTTPError,
                    requests.exceptions.JSONDecodeError):
                if attempt == RETRIES - 1:
                    raise
                time.sleep(min(2 ** attempt, 30))
        raise RuntimeError('unreachable')

    def _members(self, category: str, kind: str, limit: int) -> list[dict]:
        """Les membres d'une catégorie, fichiers (`file`) ou sous-catégories
        (`subcat`), sur une seule page — inutile d'en pagionner mille pour un
        complément."""
        data = self._get(list='categorymembers', cmtitle=f'Category:{category}',
                         cmtype=kind, cmlimit=str(min(limit, 500)))
        return (data.get('query') or {}).get('categorymembers', []) or []

    def _files_info(self, titles: list[str]) -> list[dict]:
        """Métadonnées de plusieurs fichiers d'un coup : URL de vignette,
        licence, auteur, type."""
        out = []
        for i in range(0, len(titles), 50):   # l'API en accepte 50 par appel
            data = self._get(titles='|'.join(titles[i:i + 50]), prop='imageinfo',
                             iiprop='url|extmetadata|mime', iiurlwidth=str(THUMB_WIDTH))
            out.extend((data.get('query') or {}).get('pages', []) or [])
        return out

    def category_for(self, scientific_name: str) -> str | None:
        """La première catégorie qui existe et contient des fichiers.

        Les erreurs réseau ne sont **pas** avalées : une limitation de débit
        rendrait la catégorie introuvable, donc l'espèce vide, et le journal
        annoncerait tranquillement « 0 image » pour une plante qui en a cent.
        `build_dataset` attrape déjà les exceptions espèce par espèce et les
        écrit `ÉCHEC` — c'est là que ça se voit, et c'est rattrapable.
        """
        for nom in category_names(scientific_name):
            if self._members(nom, 'file', 1):
                return nom
        return None

    def image_candidates(self, scientific_name: str, max_files: int = 300,
                         allow_share_alike: bool = False, subcategories: int = 6) -> Iterator[ImageCandidate]:
        """Les photographies d'une espèce, licence acceptable seulement.

        On descend d'un niveau dans les sous-catégories : Commons y range
        « Monstera deliciosa in <lieu> », « ... flowers », « ... leaves », et
        c'est souvent là que sont les photos de plantes cultivées.
        """
        racine = self.category_for(scientific_name)
        if racine is None:
            return
        categories = [racine]
        if subcategories:
            # On demande large et on trie : les plantes en pot d'abord, les
            # planches botaniques jamais. Prendre les six premières rendues
            # par l'API revenait à tirer au sort le contexte des photos.
            toutes = [c['title'].split(':', 1)[-1] for c in self._members(racine, 'subcat', 50)]
            categories += classer_souscategories(toutes, subcategories)

        titres, vus = [], set()
        for cat in categories:
            if len(titres) >= max_files:
                break
            membres = self._members(cat, 'file', max_files - len(titres))
            for m in membres:
                titre = m.get('title', '')
                if titre and titre not in vus and not NOT_A_PHOTO.search(titre):
                    vus.add(titre)
                    titres.append(titre)

        for page in self._files_info(titres):
            info = (page.get('imageinfo') or [{}])[0]
            if info.get('mime') not in PHOTO_TYPES:
                continue
            meta = info.get('extmetadata') or {}
            # L'URL de licence est plus sûre que le libellé : « CC BY 3.0 us »
            # ou « CC-BY 4.0 Int » se lisent mal, l'URL jamais.
            brute = ((meta.get('LicenseUrl') or {}).get('value')
                     or (meta.get('LicenseShortName') or {}).get('value') or '')
            if not is_allowed(parse_license(brute), allow_share_alike=allow_share_alike):
                continue
            url = info.get('thumburl') or info.get('url')
            if not url:
                continue
            yield ImageCandidate(
                source='wikimedia',
                source_id=f'commons:{page.get("pageid")}',
                # Commons n'a pas d'observation : le fichier est son propre
                # groupe. Deux photos de la même plante ne seront donc pas
                # gardées ensemble à la répartition ; la déduplication par
                # empreinte reste, elle, pleinement efficace.
                observation_id=f'commons:{page.get("pageid")}',
                original_url=info.get('descriptionurl') or f'https://commons.wikimedia.org/wiki/{page.get("title", "")}',
                image_url=url,
                author=_plain((meta.get('Artist') or {}).get('value', '')),
                license_raw=brute,
                publisher='Wikimedia Commons',
                extra={'title': page.get('title', ''), 'category': racine},
            )
