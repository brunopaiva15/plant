"""Le connecteur Wikimedia Commons.

Les réponses sont celles de l'API réelle, réduites : une catégorie d'espèce
et les métadonnées de ses fichiers. Ce qui compte ici n'est pas le nombre de
candidats rendus mais ce qui est **écarté** — un fichier audio, un dessin
botanique, une licence non commerciale — et le fait qu'une panne réseau ne
se déguise jamais en « cette espèce n'a pas d'images ».
"""
import sys
from pathlib import Path

import pytest
import requests

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from plant_dataset.fetchers.wikimedia import (  # noqa: E402
    CommonsClient, category_names, _plain)


def membres(*titres):
    return {'batchcomplete': True,
            'query': {'categorymembers': [{'pageid': 1000 + i, 'ns': 6, 'title': t}
                                          for i, t in enumerate(titres)]}}


def fichier(pageid, titre, mime='image/jpeg', licence='https://creativecommons.org/licenses/by/4.0',
            court='CC BY 4.0', auteur='<a href="//commons.wikimedia.org/wiki/User:X">Amanda Grobe</a>'):
    return {
        'pageid': pageid, 'title': titre,
        'imageinfo': [{
            'mime': mime,
            'url': f'https://upload.wikimedia.org/{titre}',
            'thumburl': f'https://upload.wikimedia.org/thumb/{titre}/1280px.jpg',
            'descriptionurl': f'https://commons.wikimedia.org/wiki/{titre}',
            'extmetadata': {
                'LicenseUrl': {'value': licence} if licence else {},
                'LicenseShortName': {'value': court},
                'Artist': {'value': auteur},
            },
        }],
    }


class FauxCommons(CommonsClient):
    """Un client qui répond depuis un scénario, sans réseau."""

    def __init__(self, categories=None, fichiers=None, erreur=None):
        super().__init__(session=requests.Session(), pause=0)
        self.categories = categories or {}
        self.fichiers = fichiers or {}
        self.erreur = erreur
        self.appels = 0

    def _get(self, **params):
        self.appels += 1
        if self.erreur:
            raise self.erreur
        if params.get('list') == 'categorymembers':
            cat = params['cmtitle'].split(':', 1)[1]
            return self.categories.get((cat, params['cmtype']), membres())
        pages = [self.fichiers[t] for t in params['titles'].split('|') if t in self.fichiers]
        return {'query': {'pages': pages}}


def test_les_variantes_du_signe_hybride_sont_essayees():
    """Commons écrit « Citrus × limon », « Citrus x limon » ou « Citrus
    limon » selon les catégories. Le signe d'hybride avait déjà coûté toutes
    les photos de citronnier à la v5, côté iNaturalist."""
    assert category_names('Citrus × limon') == ['Citrus × limon', 'Citrus x limon', 'Citrus limon']
    assert category_names('Monstera deliciosa') == ['Monstera deliciosa']
    assert category_names('  ') == []


def test_l_auteur_est_un_nom_pas_du_html():
    assert _plain('<a href="/wiki/User:X">Amanda Grobe</a>') == 'Amanda Grobe'
    assert _plain('Forest &amp; Kim Starr') == 'Forest & Kim Starr'
    assert _plain(None) == ''


def test_seules_les_photos_sous_licence_acceptee_sortent():
    c = FauxCommons(
        categories={('Pilea peperomioides', 'file'): membres(
            'File:Pilea in a pot.jpg',            # gardée
            'File:Pilea pronunciation.ogg',       # audio : mauvais type
            'File:Pilea botanical illustration.jpg',  # dessin : écarté sur le titre
            'File:Pilea leaf NC.jpg',             # licence non commerciale
        ), ('Pilea peperomioides', 'subcat'): membres()},
        fichiers={
            'File:Pilea in a pot.jpg': fichier(1, 'File:Pilea in a pot.jpg'),
            'File:Pilea pronunciation.ogg': fichier(2, 'File:Pilea pronunciation.ogg', mime='audio/ogg'),
            'File:Pilea leaf NC.jpg': fichier(4, 'File:Pilea leaf NC.jpg',
                                              licence='https://creativecommons.org/licenses/by-nc/4.0',
                                              court='CC BY-NC 4.0'),
        })
    sortie = list(c.image_candidates('Pilea peperomioides'))
    assert [x.source_id for x in sortie] == ['commons:1']
    seul = sortie[0]
    assert seul.source == 'wikimedia'
    assert seul.author == 'Amanda Grobe'
    assert seul.image_url.startswith('https://upload.wikimedia.org/thumb/')
    assert seul.license_raw == 'https://creativecommons.org/licenses/by/4.0'


def test_le_partage_a_l_identique_suit_le_drapeau():
    scenario = dict(
        categories={('Sedum', 'file'): membres('File:Sedum SA.jpg'), ('Sedum', 'subcat'): membres()},
        fichiers={'File:Sedum SA.jpg': fichier(9, 'File:Sedum SA.jpg',
                                               licence='https://creativecommons.org/licenses/by-sa/4.0',
                                               court='CC BY-SA 4.0')})
    assert list(FauxCommons(**scenario).image_candidates('Sedum')) == []
    avec = list(FauxCommons(**scenario).image_candidates('Sedum', allow_share_alike=True))
    assert len(avec) == 1


def test_les_sous_categories_sont_parcourues():
    """« Monstera deliciosa (cultivars) », « ... in Brazil » : c'est souvent
    là que sont les photos de plantes cultivées."""
    c = FauxCommons(
        categories={
            ('Monstera deliciosa', 'file'): membres('File:A.jpg'),
            ('Monstera deliciosa', 'subcat'): membres('Category:Monstera deliciosa (cultivars)'),
            ('Monstera deliciosa (cultivars)', 'file'): membres('File:B.jpg'),
        },
        fichiers={'File:A.jpg': fichier(1, 'File:A.jpg'), 'File:B.jpg': fichier(2, 'File:B.jpg')})
    assert sorted(x.source_id for x in c.image_candidates('Monstera deliciosa')) == ['commons:1', 'commons:2']


def test_une_panne_reseau_ne_se_deguise_pas_en_espece_sans_images():
    """Le bug trouvé au premier essai réel : Commons a répondu 429, le
    connecteur avalait l'erreur, et l'espèce était annoncée à zéro image
    alors qu'elle en avait soixante-dix. Une source qui tombe doit se voir —
    `build_dataset` l'écrit `ÉCHEC` et la reprise la rattrape."""
    c = FauxCommons(erreur=requests.ConnectionError('coupure'))
    with pytest.raises(requests.RequestException):
        list(c.image_candidates('Pilea peperomioides'))


def test_une_espece_sans_categorie_rend_simplement_rien():
    """À distinguer du cas précédent : là, Commons répond, il n'y a
    simplement pas de catégorie. Ce n'est pas une erreur."""
    c = FauxCommons(categories={})
    assert list(c.image_candidates('Cymbidium hybridum')) == []


# --- L'ordre des sous-catégories décide du domaine visuel des photos -------
#
# Commons range les photos d'une espèce par contexte : `(potted)` porte les
# plantes en pot, `(products)` des pots de confiture, `- botanical
# illustrations` des gravures du XIXe. Prendre les six premières rendues par
# l'API revenait à tirer au sort — or le § 12.4 dit que 73 % des erreurs du
# modèle viennent de n'avoir jamais vu la plante telle qu'on la cultive.

from plant_dataset.fetchers.wikimedia import classer_souscategories  # noqa: E402


def test_les_plantes_en_pot_passent_devant():
    noms = ['Monstera deliciosa (flowers)', 'Monstera deliciosa (potted)',
            'Monstera deliciosa (fruit)']
    assert classer_souscategories(noms, 3)[0] == 'Monstera deliciosa (potted)'


def test_les_planches_et_herbiers_ne_sont_jamais_visites():
    noms = ['Ficus elastica - botanical illustrations', 'Ficus elastica (herbarium specimens)',
            'Ficus elastica (potted)']
    assert classer_souscategories(noms, 6) == ['Ficus elastica (potted)']


def test_les_produits_derives_non_plus():
    # « Monstera deliciosa (products) » : des confitures, pas des plantes.
    assert classer_souscategories(['Monstera deliciosa (products)'], 6) == []


def test_lordre_des_priorites_est_respecte():
    noms = ['X (garden)', 'X (cultivars)', 'X (in pots)']
    assert classer_souscategories(noms, 3) == ['X (in pots)', 'X (cultivars)', 'X (garden)']


def test_les_categories_neutres_suivent_sans_etre_ecartees():
    noms = ['X (leaves)', 'X (potted)']
    assert classer_souscategories(noms, 2) == ['X (potted)', 'X (leaves)']


def test_le_plafond_est_respecte():
    noms = [f'X (potted {i})' for i in range(10)]
    assert len(classer_souscategories(noms, 4)) == 4
