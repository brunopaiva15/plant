"""La couverture avant la précision.

Le top-1 sur les plantes d'appartement ne veut rien dire tant qu'on n'a pas
dit **combien** d'entre elles le modèle sait seulement nommer : une espèce
absente du catalogue ne se trompe pas, elle ne se propose jamais. Compter
absente une plante que le modèle connaît sous un autre nom fausserait donc
les deux chiffres à la fois, et c'est ce que ces tests surveillent.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from interieur import alias_depuis, prix_de_letendue, resoudre  # noqa: E402

LABELS = {'monstera-deliciosa', 'saintpaulia-ionantha', 'citrus-x-limon', 'goeppertia-makoyana'}


def test_un_nom_qui_est_deja_une_classe():
    r = resoudre(['Monstera deliciosa'], LABELS)
    assert r['classes'] == ['monstera-deliciosa']
    assert r['absentes'] == [] and r['couverture'] == 1.0


def test_le_synonyme_rattache_la_plante_au_lieu_de_la_perdre():
    alias = alias_depuis([{'internal_id': 'saintpaulia-ionantha',
                           'scientific_name': 'Saintpaulia ionantha',
                           'synonyms': 'Streptocarpus ionanthus'}])
    r = resoudre(['Streptocarpus ionanthus'], LABELS, alias)
    assert r['classes'] == ['saintpaulia-ionantha']
    assert r['synonymes'] == {'Streptocarpus ionanthus': 'saintpaulia-ionantha'}


def test_le_x_de_lhybride_ne_fait_pas_une_espece_manquante():
    # Le catalogue écrit « Citrus × limon », la liste écrit « Citrus limon ».
    r = resoudre(['Citrus limon'], LABELS)
    assert r['classes'] == ['citrus-x-limon']
    assert r['hybrides'] == {'Citrus limon': 'citrus-x-limon'} and r['absentes'] == []


def test_deux_noms_pour_une_plante_ne_comptent_quune_fois():
    alias = alias_depuis([{'internal_id': 'saintpaulia-ionantha',
                           'scientific_name': 'Saintpaulia ionantha',
                           'synonyms': 'Streptocarpus ionanthus'}])
    r = resoudre(['Saintpaulia ionantha', 'Streptocarpus ionanthus'], LABELS, alias)
    assert r['demandes'] == 2 and r['distinctes'] == 1
    assert r['doublons'] == ['saintpaulia-ionantha'] and r['couverture'] == 1.0


def test_le_doublon_compte_aussi_quand_les_deux_noms_sont_absents():
    # Calathea et Goeppertia orbifolia : la même plante, aucune des deux au
    # catalogue. Les compter deux fois gonflerait le dénominateur et
    # abaisserait la couverture pour rien.
    alias = alias_depuis([{'internal_id': 'calathea-orbifolia',
                           'scientific_name': 'Calathea orbifolia',
                           'synonyms': 'Goeppertia orbifolia'}])
    r = resoudre(['Monstera deliciosa', 'Calathea orbifolia', 'Goeppertia orbifolia'], LABELS, alias)
    assert r['distinctes'] == 2, 'deux plantes, pas trois'
    assert r['couverture'] == 0.5
    assert len(r['absentes']) == 2, 'les deux noms restent dits, ce sont les plantes qu\'on dédoublonne'


def test_une_plante_absente_est_dite_absente_meme_si_son_genre_est_connu():
    # `goeppertia-makoyana` est au catalogue ; orbifolia n'y est pas, et
    # « le genre est là » ne rend pas l'espèce nommable.
    r = resoudre(['Goeppertia orbifolia'], LABELS)
    assert r['classes'] == [] and r['absentes'] == ['Goeppertia orbifolia']


def test_les_synonymes_se_lisent_avec_les_deux_separateurs():
    alias = alias_depuis([{'internal_id': 'a-b', 'scientific_name': 'A b', 'synonyms': 'C d; E f, G h'}])
    assert alias['c-d'] == 'a-b' and alias['e-f'] == 'a-b' and alias['g-h'] == 'a-b'


def test_une_ligne_sans_synonyme_ne_casse_rien():
    alias = alias_depuis([{'internal_id': 'a-b', 'scientific_name': 'A b', 'synonyms': ''},
                          {'internal_id': 'c-d', 'scientific_name': 'C d'}])
    assert alias['a-b'] == 'a-b' and alias['c-d'] == 'c-d'


def test_le_prix_de_letendue_est_positif_quand_restreindre_aide():
    ecart = prix_de_letendue({'top1': 0.60, 'top3': 0.75, 'accepted_rate': 0.47},
                             {'top1': 0.68, 'top3': 0.82, 'accepted_rate': 0.55})
    assert ecart['top1'] == 0.08 and ecart['acceptees'] == 0.08


def test_pas_de_prix_annonce_sans_mesure():
    assert prix_de_letendue({'top1': None}, {'top1': 0.68}) is None
