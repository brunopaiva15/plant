"""Choisir les espèces de la v8 par ce que les gens cultivent.

Le § 12.4 a montré que 62 des 63 espèces les plus faibles du modèle sont des
arbres et des plantes sauvages, et le § 12.12 que l'étendue du catalogue
coûte dix points à qui photographie son salon. Tirer 1 500 noms de plus dans
la flore disponible grossirait la mauvaise population : d'où un classement,
et d'où ces tests sur ce qu'il laisse passer.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from candidats import deja_au_catalogue, retenir  # noqa: E402


def taxon(nom, count, rang='species'):
    return {'count': count, 'taxon': {'name': nom, 'rank': rang}}


def test_lordre_diNaturalist_est_conserve():
    # C'est tout l'intérêt : le rang dit combien de gens cultivent la plante.
    r = retenir([taxon('Nerium oleander', 59037), taxon('Acer palmatum', 52626)], set())
    assert r == [('Nerium oleander', 59037), ('Acer palmatum', 52626)]


def test_une_espece_deja_au_catalogue_ne_compte_pas_pour_une_nouveaute():
    r = retenir([taxon('Monstera deliciosa', 999), taxon('Nerium oleander', 10)],
                {'monstera-deliciosa'})
    assert r == [('Nerium oleander', 10)]


def test_un_genre_ou_une_famille_ne_fait_pas_une_classe():
    r = retenir([taxon('Rosa', 9000, 'genus'), taxon('Rosaceae', 8000, 'family'),
                 taxon('Rosa canina', 700)], set())
    assert r == [('Rosa canina', 700)]


def test_les_hybrides_sont_gardes():
    # « Hibiscus × rosa-sinensis » est la plante la plus cultivée du monde ;
    # l'écarter parce que son rang est « hybrid » serait absurde.
    r = retenir([taxon('Hibiscus × rosa-sinensis', 62498, 'hybrid')], set())
    assert r == [('Hibiscus × rosa-sinensis', 62498)]


def test_lhybride_et_sa_forme_sans_signe_sont_la_meme_plante():
    # iNaturalist écrit parfois « Citrus × limon », parfois « Citrus limon ».
    # Sans la clé interne commune, on collecterait deux fois la même.
    r = retenir([taxon('Citrus × limon', 500, 'hybrid'), taxon('Citrus limon', 400)], set())
    assert len(r) == 1


def test_un_doublon_dans_la_page_ne_passe_quune_fois():
    r = retenir([taxon('Nerium oleander', 100), taxon('nerium oleander', 90)], set())
    assert r == [('Nerium oleander', 100)]


def test_un_taxon_sans_nom_ne_fait_pas_tomber_la_liste():
    assert retenir([{'count': 5, 'taxon': {}}, taxon('Aloe vera', 3)], set()) == [('Aloe vera', 3)]


def test_le_deja_connu_reunit_le_catalogue_et_les_classes_livrees(tmp_path):
    # Les deux ne coïncident pas : une espèce peut être au catalogue et avoir
    # été écartée du modèle faute d'images.
    plants = tmp_path / 'plants.csv'
    plants.write_text('internal_id,scientific_name\nmonstera-deliciosa,Monstera deliciosa\n', encoding='utf-8')
    labels = tmp_path / 'labels.txt'
    labels.write_text('ficus-lyrata\n\n', encoding='utf-8')
    assert deja_au_catalogue(plants, labels) == {'monstera-deliciosa', 'ficus-lyrata'}


def test_sans_fichier_le_catalogue_connu_est_vide(tmp_path):
    assert deja_au_catalogue(tmp_path / 'absent.csv', tmp_path / 'absent.txt') == set()


def test_inscrire_rend_les_lignes_qui_manquent_au_catalogue():
    # `build_dataset.py --only-file` ne fait que *filtrer* plants.csv : une
    # candidate absente du catalogue n'est pas collectée, elle est ignorée
    # en silence. C'est la pièce qui manquait entre les deux.
    import sys
    from pathlib import Path as P
    sys.path.insert(0, str(P(__file__).resolve().parents[1]))
    from candidats import inscrire
    from plant_dataset.taxonomy import PlantEntry

    connues = [PlantEntry.from_name('Monstera deliciosa')]
    ajouts = inscrire(connues, [('Monstera deliciosa', 9), ('Ixora coccinea', 28355)])
    assert [e.internal_id for e in ajouts] == ['ixora-coccinea']
    assert ajouts[0].genus == 'Ixora' and ajouts[0].epithet == 'coccinea'


def test_inscrire_ne_double_pas_une_candidate_repetee():
    import sys
    from pathlib import Path as P
    sys.path.insert(0, str(P(__file__).resolve().parents[1]))
    from candidats import inscrire
    ajouts = inscrire([], [('Aloe vera', 5), ('aloe vera', 4)])
    assert len(ajouts) == 1
