"""La recette d'entraînement, écrite à côté des chiffres qu'elle explique.

La v9 est sortie 2,5 points sous la v8 sur son propre jeu de test. Les deux
`model.json` ne se comparent pas — c'est le § 12.10 — mais on ne pouvait même
pas dire *ce qui* avait changé entre les deux runs : ni le lot, ni les
époques, ni le jeu n'étaient notés nulle part. Un `model.json` sans sa
recette est un résultat sans son protocole.
"""
import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import train  # noqa: E402


def args(**kw) -> argparse.Namespace:
    base = dict(dataset='/data2/dataset-v8-carre', backbone='large', batch=64,
                head_epochs=4, fine_epochs=12, fine_lr=5e-5, dropout=0.5,
                unfreeze=100, input_size=320, min_train=25, min_val=3,
                mixed_precision=True)
    return argparse.Namespace(**{**base, **kw})


def test_la_recette_note_le_lot_et_les_epoques():
    r = train.recette(args())
    assert r['batch'] == 64
    assert r['head_epochs'] == 4 and r['fine_epochs'] == 12


def test_deux_lots_differents_donnent_deux_recettes_differentes():
    """Le cas qui a manqué : v8 à 128, v9 à 64, et rien ne le disait."""
    assert train.recette(args(batch=128)) != train.recette(args(batch=64))


def test_la_recette_note_le_jeu():
    """Un carré pré-découpé et un jeu plein cadre ne sont pas le même jeu."""
    a = train.recette(args(dataset='/data2/dataset-v8'))
    b = train.recette(args(dataset='/data2/dataset-v8-carre'))
    assert a['dataset'] != b['dataset']


def test_la_recette_est_serialisable():
    import json
    json.loads(json.dumps(train.recette(args())))


def test_l_empreinte_distingue_deux_decoupages(tmp_path):
    """Le cas qui a coûté l'intersection : le redécoupage a écrasé le
    `splits.csv` de la v8, et rien ne disait que ce n'était plus le même."""
    a, b = tmp_path / 'a', tmp_path / 'b'
    a.mkdir(); b.mkdir()
    (a / 'splits.csv').write_text('path,species,split\nx.jpg,rosa-canina,test\n')
    (b / 'splits.csv').write_text('path,species,split\nx.jpg,rosa-canina,train\n')
    assert train.empreinte_decoupage(a) != train.empreinte_decoupage(b)


def test_l_empreinte_est_stable(tmp_path):
    (tmp_path / 'splits.csv').write_text('path,species,split\nx.jpg,rosa-canina,test\n')
    assert train.empreinte_decoupage(tmp_path) == train.empreinte_decoupage(tmp_path)


def test_l_empreinte_absente_ne_leve_pas(tmp_path):
    """Un jeu sans `splits.csv` n'existe pas en pratique, mais l'export ne
    doit pas mourir après treize heures de GPU pour un fichier manquant."""
    assert train.empreinte_decoupage(tmp_path) is None


def test_la_precision_mixte_est_un_booleen():
    """`args.mixed_precision` vient de `store_true` ; on ne veut pas d'un
    `None` qui se relirait comme « non » sans qu'on sache si c'est mesuré."""
    r = train.recette(args(mixed_precision=False))
    assert r['mixed_precision'] is False
