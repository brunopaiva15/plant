"""Deux noms pour une plante font deux classes, et c'est un défaut de
catalogue qu'aucune photo ne peut réparer.

Les images se partagent entre les deux, chacune s'entraîne sur la moitié de
ce qu'elle devrait, et la confusion qui en résulte apparaît dans la matrice
comme une erreur du modèle alors qu'il n'y avait rien à trancher.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from doublons import grouper, images_par_classe  # noqa: E402


def test_deux_noms_sur_un_meme_taxon_font_un_doublon():
    g = grouper({'sansevieria-trifasciata': 11041822, 'dracaena-trifasciata': 11041822,
                 'monstera-deliciosa': 2868536})
    assert g == [['dracaena-trifasciata', 'sansevieria-trifasciata']]


def test_deux_plantes_distinctes_ne_se_regroupent_pas():
    # Populus alba et Salix alba partagent leur épithète et leur famille ;
    # c'est ce qui rend l'heuristique inutilisable et GBIF nécessaire.
    assert grouper({'populus-alba': 3040233, 'salix-alba': 5372513}) == []


def test_les_noms_non_resolus_ne_font_pas_un_gros_doublon():
    # Sans ça, toutes les inconnues tomberaient sur `None` et seraient
    # annoncées comme une seule et même plante.
    assert grouper({'a-un': None, 'b-un': None, 'c-un': 42}) == []


def test_un_taxon_a_trois_noms_rend_un_seul_groupe():
    g = grouper({'a-un': 7, 'b-un': 7, 'c-un': 7})
    assert g == [['a-un', 'b-un', 'c-un']], 'un groupe de trois, pas trois paires'


def test_les_groupes_sortent_dans_un_ordre_stable():
    cles = {'zeta-un': 1, 'alpha-un': 1, 'nu-deux': 2, 'beta-deux': 2}
    assert grouper(cles) == [['alpha-un', 'zeta-un'], ['beta-deux', 'nu-deux']]


def test_sans_jeu_dimages_loutil_reste_utilisable(tmp_path):
    assert images_par_classe(tmp_path) == {}


def test_le_compte_dimages_dit_ce_que_la_scission_separe(tmp_path):
    (tmp_path / 'splits.csv').write_text(
        'internal_plant_id,split\n'
        'sansevieria-trifasciata,train\n'
        'sansevieria-trifasciata,train\n'
        'dracaena-trifasciata,test\n', encoding='utf-8')
    assert images_par_classe(tmp_path) == {'sansevieria-trifasciata': 2, 'dracaena-trifasciata': 1}


# --- La garde de rang : un nom inconnu rend son genre, pas rien -------------
#
# GBIF ne répond jamais « je ne sais pas » : faute d'espèce, il remonte d'un
# cran. *Harpephyllum afrum* tombe sur la clé 6, qui est *Plantae*. Sans
# garde, toutes les inconnues du catalogue tomberaient sur la même clé et
# l'outil annoncerait une plante de 5 000 noms.

from doublons import CACHE_VERSION, cle_acceptee, ecrire_cache, lire_cache  # noqa: E402
from plant_dataset.fetchers.gbif import TaxonMatch  # noqa: E402


class _ClientFictif:
    """Rend une correspondance par nom demandé ; un nom absent de la table
    ne résout pas, ce qui est le cas du repli par synonyme."""

    def __init__(self, m, table=None):
        self._m, self._table = m, table
        self.demandes = []

    def match(self, nom):
        self.demandes.append(nom)
        return self._table.get(nom) if self._table is not None else self._m


def _match(**kw):
    base = dict(key=1, canonical_name='', scientific_name='', rank='SPECIES', status='ACCEPTED',
                match_type='EXACT', confidence=99, family='', genus='', accepted_key=None)
    return TaxonMatch(**(base | kw))


def test_un_nom_resolu_a_lespece_rend_sa_cle():
    assert cle_acceptee(_ClientFictif(_match(key=2868536)), 'Monstera deliciosa') == 2868536


def test_un_synonyme_rend_la_cle_du_nom_accepte():
    # Sinon le synonyme se rangerait à part de son nom accepté, c'est-à-dire
    # exactement le doublon qu'on cherche.
    assert cle_acceptee(_ClientFictif(_match(key=5363644, accepted_key=2987867)), 'Aronia mitschurinii') == 2987867


def test_le_regne_nest_pas_une_plante():
    m = _match(key=6, rank='KINGDOM', match_type='HIGHERRANK', confidence=95)
    assert cle_acceptee(_ClientFictif(m), 'Harpephyllum afrum') is None


def test_le_genre_dun_hybride_horticole_nest_pas_une_plante():
    # Rosa × hybrida, Protea × hybrida, Cymbidium hybridum : sans ça, tous
    # les Rosa non résolus du catalogue deviendraient un seul doublon.
    m = _match(key=8395064, rank='GENUS', match_type='HIGHERRANK', confidence=99)
    assert cle_acceptee(_ClientFictif(m), 'Rosa × hybrida') is None


def test_un_nom_inconnu_de_gbif_ne_groupe_avec_personne():
    assert cle_acceptee(_ClientFictif(None), 'Plante imaginaire') is None


def test_une_correspondance_floue_mais_sure_est_retenue():
    # Clematis armandi → Clematis armandii, 98 de confiance : la ligne du
    # catalogue est bien cette plante, et deux lignes qui y tombent sont
    # bien un doublon.
    m = _match(key=6375061, match_type='FUZZY', confidence=98)
    assert cle_acceptee(_ClientFictif(m), 'Clematis armandi') == 6375061


def test_une_correspondance_floue_incertaine_est_ecartee():
    m = _match(key=42, match_type='FUZZY', confidence=80)
    assert cle_acceptee(_ClientFictif(m), 'Nom approximatif') is None


# --- Le cache ne survit pas à une correction de l'outil ---------------------

def test_le_cache_se_relit(tmp_path):
    c = tmp_path / 'doublons.json'
    ecrire_cache(c, {'monstera-deliciosa': 2868536, 'inconnue': None})
    assert lire_cache(c) == {'monstera-deliciosa': 2868536, 'inconnue': None}


def test_un_cache_dune_autre_version_se_jette(tmp_path):
    # Les clés résolues avant la garde de rang sont des genres et des
    # règnes : les relire rendrait la réponse fausse en silence.
    c = tmp_path / 'doublons.json'
    c.write_text('{"harpephyllum-afrum": 6, "erythrina-afra": 2945830}', encoding='utf-8')
    assert lire_cache(c) == {}


def test_un_cache_absent_ne_fait_pas_echouer(tmp_path):
    assert lire_cache(tmp_path / 'rien.json') == {}


def test_la_version_du_cache_est_ecrite(tmp_path):
    import json
    c = tmp_path / 'doublons.json'
    ecrire_cache(c, {'a': 1})
    assert json.loads(c.read_text())['version'] == CACHE_VERSION


# --- Le repli par synonyme, sans quoi six vrais doublons manquaient -------

def test_le_synonyme_resout_quand_le_nom_echoue():
    # Allium porrum ne résout pas — GBIF rend le genre — mais Allium
    # ampeloprasum, son synonyme au catalogue, porte la clé du poireau.
    c = _ClientFictif(None, {'Allium ampeloprasum': _match(key=2856037)})
    assert cle_acceptee(c, 'Allium porrum', ['Allium ampeloprasum']) == 2856037


def test_le_nom_prime_sur_ses_synonymes():
    c = _ClientFictif(None, {'Sorbus aria': _match(key=111), 'Aria edulis': _match(key=222)})
    assert cle_acceptee(c, 'Sorbus aria', ['Aria edulis']) == 111
    assert c.demandes == ['Sorbus aria'], 'un nom qui résout n\'interroge pas ses synonymes'


def test_un_genre_rendu_pour_le_synonyme_ne_compte_pas_davantage():
    # La garde de rang vaut pour le repli : sinon le synonyme rouvrirait la
    # porte que le nom vient de fermer.
    genre = _match(key=3020559, rank='GENUS', match_type='HIGHERRANK')
    c = _ClientFictif(None, {'Prunus dulcis': genre, 'Prunus amygdalus': genre})
    assert cle_acceptee(c, 'Prunus dulcis', ['Prunus amygdalus']) is None


def test_sans_synonyme_le_comportement_ne_change_pas():
    c = _ClientFictif(None, {})
    assert cle_acceptee(c, 'Harpephyllum afrum', []) is None


def test_tous_les_synonymes_sont_essayes_dans_lordre():
    c = _ClientFictif(None, {'Troisieme nom': _match(key=7)})
    assert cle_acceptee(c, 'Premier nom', ['Deuxieme nom', 'Troisieme nom']) == 7
    assert c.demandes == ['Premier nom', 'Deuxieme nom', 'Troisieme nom']
