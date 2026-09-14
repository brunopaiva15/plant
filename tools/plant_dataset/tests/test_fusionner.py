"""Fusionner deux lignes qui sont une seule plante, sans rien perdre.

La collecte va chercher les images **par la clé GBIF** : deux lignes qui
partagent une clé téléchargent les mêmes photos dans deux classes. Le choix
n'est donc pas « fusionner ou non » mais « quel nom survit », et la réponse
est celle du § 12.14 : ce que l'application sait résoudre.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from fusionner import absorber, choisir, fusionner, groupes_de, rang_app, sans_hybride  # noqa: E402
from plant_dataset.taxonomy import PlantEntry  # noqa: E402


def e(nom, **kw):
    p = PlantEntry.from_name(nom, kw.pop('family', 'Testaceae'))
    for k, v in kw.items():
        setattr(p, k, v)
    return p


# --- Le signe d'hybride ne fait pas deux plantes ---------------------------

def test_le_signe_dhybride_ne_change_pas_la_cle_de_comparaison():
    # GBIF écrit « Citrus aurantiifolia », le catalogue « Citrus ×
    # aurantiifolia ». Sans ça, le nom accepté passerait pour un inconnu.
    assert sans_hybride('Citrus × aurantiifolia') == sans_hybride('Citrus aurantiifolia')


def test_deux_epithetes_differentes_restent_differentes():
    assert sans_hybride('Citrus × aurantifolia') != sans_hybride('Citrus × aurantiifolia')


# --- Quel nom survit ------------------------------------------------------

def test_la_fiche_soignee_lemporte_sur_le_catalogue_etendu():
    g = [e('Dracaena trifasciata'), e('Sansevieria trifasciata')]
    gagnant, regle = choisir(g, {'Dracaena trifasciata'}, {'Sansevieria trifasciata'})
    assert (gagnant.scientific_name, regle) == ('Dracaena trifasciata', 'app')


def test_le_catalogue_etendu_lemporte_sur_un_nom_que_lapp_ignore():
    # Citrus medica est une classe du modèle livré mais n'est dans aucun des
    # deux catalogues : l'app ne saurait pas l'afficher.
    g = [e('Citrus hassaku'), e('Citrus medica')]
    gagnant, regle = choisir(g, set(), {'Citrus hassaku'})
    assert (gagnant.scientific_name, regle) == ('Citrus hassaku', 'app')


def test_a_egalite_le_nom_accepte_par_gbif_tranche():
    g = [e('Sorbus torminalis'), e('Torminalis glaberrima')]
    etendu = {'Sorbus torminalis', 'Torminalis glaberrima'}
    gagnant, regle = choisir(g, set(), etendu, canonique='Torminalis glaberrima')
    assert (gagnant.scientific_name, regle) == ('Torminalis glaberrima', 'gbif')


def test_le_nom_accepte_tranche_malgre_le_signe_dhybride():
    g = [e('Citrus × aurantifolia'), e('Citrus × aurantiifolia')]
    gagnant, regle = choisir(g, set(), set(), canonique='Citrus aurantiifolia')
    assert (gagnant.scientific_name, regle) == ('Citrus × aurantiifolia', 'gbif')


def test_un_nom_accepte_absent_du_catalogue_laisse_lalphabet_decider():
    # Grindelia camporum et G. stricta sont deux synonymes de G. hirsutula,
    # que le catalogue n'a pas. Le nom retenu n'est qu'une étiquette : la
    # collecte ira chercher la clé.
    g = [e('Grindelia camporum'), e('Grindelia stricta')]
    gagnant, regle = choisir(g, set(), set(), canonique='Grindelia hirsutula')
    assert (gagnant.scientific_name, regle) == ('Grindelia camporum', 'alphabétique')


def test_rang_app():
    assert rang_app('A', {'A'}, set()) == 0
    assert rang_app('B', set(), {'B'}) == 1
    assert rang_app('C', set(), set()) == 2


# --- Une fusion ne perd rien ----------------------------------------------

def test_le_nom_retire_devient_un_synonyme():
    # build_dataset.py essaie le nom puis les synonymes : sans ça, la
    # collecte perdrait la seule orthographe que GBIF résout.
    gagnant = absorber(e('Sorbus aria'), [e('Aria edulis')])
    assert 'Aria edulis' in gagnant.synonyms


def test_les_synonymes_du_retire_suivent():
    perdant = e('Aria edulis', synonyms=['Pyrus aria'])
    assert 'Pyrus aria' in absorber(e('Sorbus aria'), [perdant]).synonyms


def test_un_nom_commun_manquant_est_reprise_du_retire():
    gagnant = e('Allium porrum', common_names={'fr': 'Poireau'})
    perdant = e('Allium ampeloprasum', common_names={'fr': 'Poireau sauvage', 'de': 'Sommerlauch'})
    fusionne = absorber(gagnant, [perdant])
    assert fusionne.common_names['fr'] == 'Poireau', 'le nom du survivant ne se fait pas écraser'
    assert fusionne.common_names['de'] == 'Sommerlauch', 'le trou se remplit'


def test_les_identifiants_manquants_se_completent():
    gagnant = e('A un', wikidata_id='', plantnet_id='pn-1')
    perdant = e('B un', wikidata_id='Q42', plantnet_id='pn-2')
    f = absorber(gagnant, [perdant])
    assert (f.wikidata_id, f.plantnet_id) == ('Q42', 'pn-1')


def test_un_synonyme_deja_connu_ne_se_repete_pas():
    gagnant = e('A un', synonyms=['B un'])
    assert absorber(gagnant, [e('B un')]).synonyms == ['B un']


# --- Les groupes et le catalogue final ------------------------------------

def test_seules_les_cles_partagees_font_un_groupe():
    entrees = [e('A un'), e('B un'), e('C un')]
    cles = {'a-un': 7, 'b-un': 7, 'c-un': 9}
    g = groupes_de(cles, entrees)
    assert [[x.scientific_name for x in grp] for grp in g] == [['A un', 'B un']]


def test_une_cle_nulle_ne_groupe_personne():
    entrees = [e('A un'), e('B un')]
    assert groupes_de({'a-un': None, 'b-un': None}, entrees) == []


def test_la_fusion_retire_les_perdants_et_garde_le_reste():
    entrees = [e('Dracaena trifasciata'), e('Sansevieria trifasciata'), e('Monstera deliciosa')]
    groupes = groupes_de({'dracaena-trifasciata': 1, 'sansevieria-trifasciata': 1,
                          'monstera-deliciosa': 2}, entrees)
    restant, rapport = fusionner(entrees, groupes, {'Dracaena trifasciata'},
                                 {'Sansevieria trifasciata'}, {})
    assert [x.scientific_name for x in restant] == ['Dracaena trifasciata', 'Monstera deliciosa']
    assert len(rapport) == 1 and rapport[0][0] == 'app'
    assert 'Sansevieria trifasciata' in restant[0].synonyms
