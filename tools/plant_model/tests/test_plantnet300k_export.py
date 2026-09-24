"""Les étiquettes de Pl@ntNet-300K, sans PyTorch.

Le réseau des auteurs a 1 081 sorties pour 1 019 espèces : la même plante y
figure sous plusieurs citations d'auteur. `etiquettes` dit lesquelles vont
ensemble ; si elle se trompait d'un cran, tous les noms de la comparaison
seraient décalés et les scores resteraient plausibles.
"""
import pytest

from plantnet300k_export import etiquettes


def test_les_citations_d_une_meme_espece_se_rejoignent():
    classes = {'0': '10', '1': '11', '2': '12', '3': '13'}
    noms = {
        '10': 'Tradescantia zebrina Bosse',
        '11': 'Lactuca virosa L.',
        '12': 'Tradescantia zebrina hort. ex Bosse',
        '13': "Pelargonium zonale (L.) L'Hér.",
    }
    labels, vers, especes = etiquettes(classes, noms)
    assert labels == ['tradescantia-zebrina', 'lactuca-virosa', 'pelargonium-zonale']
    assert vers == [0, 1, 0, 2]
    assert especes['tradescantia-zebrina'] == 'Tradescantia zebrina'


def test_l_ordre_est_celui_des_indices_et_non_du_fichier():
    noms = {'10': 'Abies alba Mill.', '11': 'Betula pendula Roth', '12': 'Cirsium vulgare (Savi) Ten.'}
    labels, vers, _ = etiquettes({'1': '11', '0': '10', '2': '12'}, noms)
    assert labels == ['abies-alba', 'betula-pendula', 'cirsium-vulgare']
    assert vers == [0, 1, 2]


def test_un_trou_dans_les_indices_est_refuse():
    noms = {'10': 'Abies alba Mill.', '11': 'Betula pendula Roth'}
    with pytest.raises(SystemExit):
        etiquettes({'0': '10', '2': '11'}, noms)
