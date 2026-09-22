"""Le tableau de suivi, sur des journaux plutôt que sur des passes.

Ce qui est testé ici est ce qui ferait **mal lire l'avancée** : une vitesse
nulle qui rendrait l'infini, un pas compté comme une image alors qu'un pas en
vaut soixante-quatre, une ligne ancienne prise pour la dernière, une tendance
du cône lue sur un seul point.
"""
from suivi import (barre, derniere, duree, epoques_ecrites, etat_corpus,
                   etat_entrainement, reste, tendance, ENTRAINEMENT)

ENTRAINE = [
    'reprise à l\'époque 0\n',
    '  é0 pas 6600/12468  perte 0.4241  accord 0.6830  cône 0.3069  267 img/s\n',
    '  é0 pas 6800/12468  perte 0.4078  accord 0.6941  cône 0.3015  267 img/s\n',
]
TIRE = [
    '243567 images sous licence sur les splits, 185836 du catalogue\n',
    '  2000/243567  31.4 img/s  3 sautées  reste 128 min\n',
    '  4000/243567  33.0 img/s  5 sautées  reste 120 min\n',
]


# --------------------------------------------------------------------------
# La dernière ligne, pas la première qui correspond
# --------------------------------------------------------------------------

def test_cest_la_derniere_ligne_qui_dit_ou_on_en_est():
    """Un journal de nuit fait des dizaines de milliers de lignes ; lire la
    première correspondante afficherait l'état d'il y a huit heures."""
    assert int(derniere(ENTRAINE, ENTRAINEMENT)[2]) == 6800


def test_un_journal_sans_ligne_de_pas_ne_rend_rien():
    assert etat_entrainement(['démarrage\n']) is None
    assert etat_corpus(['démarrage\n']) is None


# --------------------------------------------------------------------------
# Ce qu'on lit d'une ligne
# --------------------------------------------------------------------------

def test_letat_de_la_distillation_se_lit_entier():
    e = etat_entrainement(ENTRAINE)
    assert (e['epoque'], e['pas'], e['pas_total']) == (0, 6800, 12468)
    assert (e['perte'], e['accord'], e['cone']) == (0.4078, 0.6941, 0.3015)
    assert e['vitesse'] == 267


def test_le_cone_se_lit_meme_sans_accent_circonflexe():
    """Un terminal qui mange l'accent ne doit pas rendre le tableau muet."""
    ligne = ['  é1 pas 10/20  perte 0.1  accord 0.9  cone 0.2  100 img/s\n']
    assert etat_entrainement(ligne)['cone'] == 0.2


def test_letat_du_corpus_se_lit_entier():
    c = etat_corpus(TIRE)
    assert (c['faites'], c['total'], c['sautees']) == (4000, 243567, 5)
    assert c['vitesse'] == 33.0


# --------------------------------------------------------------------------
# Le temps restant
# --------------------------------------------------------------------------

def test_un_pas_vaut_un_lot_dimages_pas_une_image():
    """Compter les pas comme des images annoncerait soixante-quatre fois
    moins de temps qu'il n'en reste."""
    assert reste(0, 100, 64, par_pas=64) == 100.0
    assert reste(0, 100, 64, par_pas=1) == 100 / 64


def test_une_vitesse_nulle_ne_rend_pas_linfini():
    assert reste(0, 100, 0.0) == 0.0
    assert duree(reste(0, 100, 0.0)) == '—'


def test_la_duree_se_lit_dun_coup_doeil():
    assert duree(120) == '2 min'
    assert duree(3600 * 4 + 720) == '4 h 12'
    assert duree(0) == '—'


def test_la_barre_reste_dans_ses_bornes():
    assert len(barre(0.0)) == len(barre(0.5)) == len(barre(1.0)) == 28
    assert barre(0.0).count('█') == 0
    assert barre(1.0).count('·') == 0
    assert barre(2.0).count('█') == 28  # une part aberrante ne déborde pas


# --------------------------------------------------------------------------
# La tendance du cône
# --------------------------------------------------------------------------

def journal(*cones):
    return [{'cone': str(c)} for c in cones]


def test_la_tendance_demande_deux_points():
    """Une valeur seule ne dit pas si le cône se referme, et c'est le sens
    qui est le signal d'alarme du § 19 bis."""
    assert tendance(journal(0.3)) is None
    assert tendance(journal(0.30, 0.31))['ecart'] > 0


def test_la_tendance_ne_lit_que_la_fenetre_demandee():
    t = tendance(journal(0.9, 0.5, 0.31, 0.30), combien=2)
    assert (t['debut'], t['fin'], t['points']) == (0.31, 0.30, 2)


# --------------------------------------------------------------------------
# Les points de contrôle
# --------------------------------------------------------------------------

def test_les_epoques_sortent_dans_lordre_numerique(tmp_path):
    """`sorted()` sur les noms mettrait `banc-e10` avant `banc-e2`."""
    for n in (1, 2, 10):
        (tmp_path / f'banc-e{n}').mkdir()
    (tmp_path / 'banc-exxx').mkdir()
    assert epoques_ecrites(tmp_path) == [1, 2, 10]


def test_aucun_point_de_controle_nest_pas_une_erreur(tmp_path):
    assert epoques_ecrites(tmp_path) == []


# --------------------------------------------------------------------------
# Un journal qui ne dit rien
# --------------------------------------------------------------------------

def test_un_journal_absent_ne_se_confond_pas_avec_un_journal_bloque(tmp_path):
    """Une passe non lancée demande un `tmux`, une passe bloquée demande une
    intervention : les annoncer pareil ferait perdre une nuit."""
    from suivi import silence
    assert 'absent' in silence(tmp_path / 'rien.log')
    journal = tmp_path / 'la.log'
    journal.write_text('démarrage\n')
    assert 'démarrage' in silence(journal, maintenant=journal.stat().st_mtime + 10)
    assert 'muet depuis' in silence(journal, maintenant=journal.stat().st_mtime + 600)
