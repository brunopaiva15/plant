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


# --------------------------------------------------------------------------
# Un fichier qui grossit
# --------------------------------------------------------------------------

def test_la_vitesse_se_mesure_entre_deux_releves():
    """Depuis le lancement, un téléchargement repris après coupure a passé
    des minutes à zéro : la moyenne annoncerait des heures de trop."""
    from suivi import avancement
    a = avancement(2 * 1024**3, 4.0, (1024**3, 1000.0), 1100.0)
    assert a['vitesse'] == 1024**3 / 100
    assert a['reste'] == (2 * 1024**3) / (1024**3 / 100)


def test_un_premier_releve_ne_pretend_pas_connaitre_la_vitesse():
    from suivi import avancement
    a = avancement(1024**3, 4.0, None, 1000.0)
    assert a['vitesse'] == 0.0 and a['part'] == 0.25


def test_un_fichier_qui_ne_grossit_plus_ne_divise_pas_par_zero():
    from suivi import avancement
    a = avancement(1024**3, 4.0, (1024**3, 1000.0), 1100.0)
    assert a['vitesse'] == 0.0 and a['reste'] == 0.0


# --------------------------------------------------------------------------
# La passe du teacher
# --------------------------------------------------------------------------

CACHE_EN_COURS = [
    '981276 images, 0 déjà cachées, 243567 à faire (part 0/1)\n',
    '  12800/243567  79.9 img/s  reste 0.8 h\n',
    '  25600/243567  80.4 img/s  reste 0.8 h\n',
]


def test_lavancee_du_cache_se_lit():
    from suivi import etat_cache
    k = etat_cache(CACHE_EN_COURS)
    assert (k['fait'], k['total'], k['vitesse']) == (25600, 243567, 80.4)
    assert not k['finie']


def test_la_fin_ne_se_lit_pas_sur_le_compteur():
    """La dernière ligne de progression s'écrit avant le dernier fragment ;
    c'est la ligne de signature, après la boucle, qui dit que le cache est
    complet et lisible."""
    from suivi import etat_cache
    k = etat_cache(CACHE_EN_COURS + ['\n/home/x/bioclip — signature 5fcd9d9cc6fa\n'])
    assert k['finie'] and k['part'] == 1.0


def test_un_journal_de_cache_absent_ne_rend_rien():
    from suivi import etat_cache
    assert etat_cache([]) is None
    assert etat_cache(['démarrage\n']) is None


def test_la_ligne_du_corpus_ne_se_prend_pas_pour_celle_du_cache():
    """Les deux se ressemblent ; seule celle du corpus porte « sautées »."""
    from suivi import etat_cache, etat_corpus
    ligne = ['  4000/243567  33.0 img/s  5 sautées  reste 120 min\n']
    assert etat_cache(ligne) is None
    assert etat_corpus(ligne)['faites'] == 4000


# --------------------------------------------------------------------------
# Plusieurs passes sur la même page
# --------------------------------------------------------------------------

def test_un_nom_de_passe_suffit():
    """Sortie et journal suivent la même convention pour toutes les passes."""
    from suivi import passes_suivies
    assert passes_suivies(['iris10-mnv4', 'iris10-cosinus'], 'x', 'y') == [
        ('iris10-mnv4', '~/plant-data/iris10-mnv4', '~/plant-data/iris10-mnv4.log'),
        ('iris10-cosinus', '~/plant-data/iris10-cosinus', '~/plant-data/iris10-cosinus.log')]


def test_sans_passe_les_anciennes_commandes_marchent_encore():
    from suivi import passes_suivies
    assert passes_suivies([], '~/plant-data/iris10-complet', '~/plant-data/iris10-complet.log') == [
        ('iris10-complet', '~/plant-data/iris10-complet', '~/plant-data/iris10-complet.log')]


def test_un_corpus_fini_ne_reste_pas_a_999():
    """Le compteur s'arrête au dernier multiple de 500 ; c'est le bilan
    écrit après la boucle qui dit la fin."""
    c = etat_corpus(TIRE + ['\n/x/plantnet-300k — 243567 images, 0 sautées cette passe\n'])
    assert c['finie'] and c['part'] == 1.0
    assert not etat_corpus(TIRE)['finie']


# --------------------------------------------------------------------------
# Ce qui tourne, et rien de ce qui a fini
# --------------------------------------------------------------------------

def test_seuls_les_journaux_qui_bougent_sont_suivis(tmp_path):
    """Un sujet en cours est un journal qui bouge : aucune liste à tenir."""
    import os
    from suivi import journaux_actifs
    for nom, age in (('iris10-mnv4-cos.log', 30), ('inat.log', 200), ('iris10-complet.log', 90000)):
        f = tmp_path / nom
        f.write_text('x\n')
        os.utime(f, (1_000_000 - age, 1_000_000 - age))
    actifs = [j.name for j in journaux_actifs(tmp_path, maintenant=1_000_000, fenetre=900)]
    assert actifs == ['inat.log', 'iris10-mnv4-cos.log']


def test_la_nature_se_lit_dans_les_lignes_pas_dans_le_nom():
    """Le nom est celui qu'on a donné à `tee`, le format des lignes non."""
    from suivi import nature
    assert nature(ENTRAINE) == 'distillation'
    assert nature(CACHE_EN_COURS) == 'cache'
    assert nature(TIRE) == 'corpus'
    assert nature(['  fragment 3/595  data/train-0002-of-unknown.parquet  gardées 1180/2500  '
                   '— cumul : 3570 gardées, 3810 hors plantes, 12 déjà au corpus, '
                   '1 écartées pour le banc  reste 412 min\n']) == 'inat'
    assert nature(['empreintes du banc…\n']) == 'autre'


def test_lavancee_inaturalist_se_lit():
    from suivi import etat_inat
    i = etat_inat(['  fragment 3/595  data/train-0002-of-unknown.parquet  gardées 1180/2500  '
                   '— cumul : 3570 gardées, 3810 hors plantes, 12 déjà au corpus, '
                   '1 écartées pour le banc  reste 412 min\n'])
    assert (i['fragment'], i['fragments'], i['gardees'], i['banc'], i['reste_min']) == (3, 595, 3570, 1, 412)


def test_une_passe_qui_demarre_montre_sa_derniere_ligne():
    from suivi import derniere_ligne
    assert derniere_ligne(['a\n', '  empreintes du banc : 3000/5127\n', '\n']) == \
        'empreintes du banc : 3000/5127'


# --------------------------------------------------------------------------
# Les résultats des points de contrôle
# --------------------------------------------------------------------------

SORTIE_VOISINS = """références : hf-hub:imageomics/bioclip-2.5-vith14, signature 5fcd9d9cc6fa
vecteurs   : student:fastvit_sa12-e10, signature 3ccf119d613f

— indoor — 1127 images
  texte      à armes égales     top-1 0.6957  top-3 0.8527  (1114/1127 nommables)
  texte      répertoire entier  top-1 0.6318  top-3 0.7977  (1127/1127 nommables)
  centroide  à armes égales     top-1 0.7081  top-3 0.8483  (1114/1127 nommables)

— outdoor — 2000 images
  texte      à armes égales     top-1 0.742  top-3 0.885  (2000/2000 nommables)

— ood_plante — 2000 images
  texte      à armes égales     top-1 0.0  top-3 0.0  (0/2000 nommables)
  texte      répertoire entier  top-1 0.5745  top-3 0.7695  (2000/2000 nommables)
"""


def test_la_sortie_de_voisins_se_relit():
    from suivi import lire_voisins
    r = lire_voisins(SORTIE_VOISINS)
    assert r['indoor'][('texte', 'à armes égales')] == 0.6957
    assert r['indoor'][('centroide', 'à armes égales')] == 0.7081
    assert r['ood_plante'][('texte', 'répertoire entier')] == 0.5745


def test_le_resume_prend_les_trois_lectures_comparees():
    """Armes égales là où Iris 9 existe, répertoire entier hors répertoire —
    le zéro d'`ood_plante` à armes égales ne dit rien."""
    from suivi import lire_voisins, resume
    assert resume(lire_voisins(SORTIE_VOISINS)) == (0.6957, 0.742, 0.5745)


def test_une_lecture_absente_reste_absente():
    from suivi import resume
    assert resume({}) == (None, None, None)


def test_un_banc_encore_ecrit_nest_pas_evalue(tmp_path):
    """`index-0.csv` s'écrit en dernier ; sans lui, on lirait un banc à moitié
    encodé."""
    from suivi import etat_evaluation
    assert etat_evaluation(tmp_path) == 'incomplet'
    (tmp_path / 'index-0.csv').write_text('')
    assert etat_evaluation(tmp_path) == 'à faire'


def test_les_etats_dune_evaluation(tmp_path):
    import os
    from suivi import etat_evaluation
    (tmp_path / 'index-0.csv').write_text('')
    partiel = tmp_path / 'voisins.txt.part'
    partiel.write_text('')
    os.utime(partiel, (1000, 1000))
    assert etat_evaluation(tmp_path, maintenant=1100) == 'en cours'
    # une évaluation tuée sans avoir fini ne bloque pas pour toujours
    assert etat_evaluation(tmp_path, maintenant=1000 + 3600) == 'à faire'
    (tmp_path / 'voisins.echec').write_text('')
    assert etat_evaluation(tmp_path, maintenant=1100) == 'échec'
    (tmp_path / 'voisins.txt').write_text('')
    assert etat_evaluation(tmp_path) == 'faite'


def test_une_seule_evaluation_a_la_fois(tmp_path):
    """Chacune tient un cœur une minute ; toutes ensemble voleraient le
    processeur au décodage des images de la distillation."""
    from suivi import prochaine_evaluation
    a, b = tmp_path / 'banc-e2', tmp_path / 'banc-e1'
    for d in (a, b):
        d.mkdir()
        (d / 'index-0.csv').write_text('')
    assert prochaine_evaluation([a, b]) == a
    (a / 'voisins.txt.part').write_text('')
    assert prochaine_evaluation([a, b]) is None
    (a / 'voisins.txt.part').rename(a / 'voisins.txt')
    assert prochaine_evaluation([a, b]) == b


def test_lecart_se_dit_en_points():
    from suivi import points
    assert points(0.7050, 0.6957) == ' (+0.9)'
    assert points(0.6531, 0.6957) == ' (−4.3)'
    assert points(0.7, None) == ''


# --------------------------------------------------------------------------
# Une passe arrêtée sur une erreur
# --------------------------------------------------------------------------

TRACE = ['Traceback (most recent call last):\n', '  File "x.py", line 1\n',
         'requests.exceptions.HTTPError: 429 Client Error: Too Many Requests\n']


def test_une_passe_arretee_sur_une_erreur_la_donne():
    from suivi import erreur_finale
    assert erreur_finale(ENTRAINE + TRACE) == \
        'requests.exceptions.HTTPError: 429 Client Error: Too Many Requests'


def test_une_erreur_suivie_dune_relance_reussie_nest_plus_un_arret():
    """`tee -a` garde l'ancienne trace dans le journal de la relance."""
    from suivi import erreur_finale
    assert erreur_finale(TRACE + ENTRAINE) == ''


def test_une_passe_finie_sans_trace_nest_pas_arretee():
    from suivi import erreur_finale
    assert erreur_finale(ENTRAINE) == ''


def test_une_passe_arretee_reste_visible_une_journee(tmp_path):
    """Muette comme une passe finie ; seule la trace la distingue."""
    import os
    from suivi import journaux_arretes
    for nom, age, contenu in (('inat.log', 3600, ENTRAINE + TRACE),
                              ('iris10-cosinus.log', 3600, ENTRAINE),
                              ('vieux.log', 3 * 86400, TRACE),
                              ('actif.log', 60, TRACE)):
        f = tmp_path / nom
        f.write_text(''.join(contenu), encoding='utf-8')
        os.utime(f, (1_000_000 - age, 1_000_000 - age))
    arretes = journaux_arretes(tmp_path, maintenant=1_000_000)
    assert [j.name for j, _ in arretes] == ['inat.log']
