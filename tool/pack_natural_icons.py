#!/usr/bin/env python3
"""Reduit les illustrations des phenomenes naturels en WebP embarquables.

Une illustration par entree de assets/problems/natural.txt, nommee par son
identifiant : c'est lui qui circule dans l'application, pas le titre.
tool/build_natural_icons.py nomme ses rendus `naturel_<Nxx>_<titre>.png` ; on
ne garde que l'identifiant.

Pas de recadrage, comme pour les illustrations des problemes : le cadrage
varie a dessein d'une image a l'autre — une feuille seule occupe moins de
place qu'une plante en pot — et recadrer chacune sur son dessin les ramenerait
toutes a la meme taille apparente.

Ecrit aussi la liste des identifiants illustres dans un fichier Dart, pour que
l'application sache lesquels existent sans interroger le disque. Ceux qui
manquent retombent sur le symbole commun, assets/problems/clay_naturel.webp.

Execution :
  python3 tool/pack_natural_icons.py build/natural_icons/renders
"""
import re
import sys
from pathlib import Path

from PIL import Image

RACINE = Path(__file__).resolve().parent.parent
DEST = RACINE / 'assets' / 'problems' / 'natural'
LISTE = RACINE / 'lib' / 'features' / 'problems' / 'presentation' / 'illustrated_natural.dart'
COTE = 512
NOM = re.compile(r'^naturel_(N\d{2})_')

EN_TETE = '''// Genere par tool/pack_natural_icons.py — ne pas modifier a la main.

/// Les phenomenes naturels qui ont leur propre illustration.
///
/// La liste est ecrite en meme temps que les images : un identifiant present
/// ici a forcement son fichier dans assets/problems/natural/, et l'inverse
/// aussi. Les autres retombent sur le symbole commun, la feuille et sa goutte.
const Set<String> illustratedNaturalCauses = {
'''


def ids_du_dossier(source):
    trouves = {}
    for chemin in sorted(source.glob('*.png')):
        m = NOM.match(chemin.name)
        if not m:
            print(f'  ignore (nom inattendu) : {chemin.name}')
            continue
        trouves[m.group(1)] = chemin
    return trouves


def main():
    sources = [Path(a) for a in sys.argv[1:]]
    if not sources:
        raise SystemExit(__doc__)
    DEST.mkdir(parents=True, exist_ok=True)

    for source in sources:
        for identifiant, chemin in sorted(ids_du_dossier(source).items()):
            image = Image.open(chemin).convert('RGBA').resize((COTE, COTE), Image.LANCZOS)
            cible = DEST / f'{identifiant}.webp'
            image.save(cible, quality=90, method=6, exact=True)
            print(f'{identifiant} — {cible.stat().st_size // 1024} Ko')

    # La liste est relue depuis le dossier et non depuis ce qu'on vient
    # d'ecrire : elle decrit ce qui est embarque.
    embarques = sorted(p.stem for p in DEST.glob('*.webp') if re.fullmatch(r'N\d{2}', p.stem))
    LISTE.write_text(
        EN_TETE + ''.join(f"  '{i}',\n" for i in embarques) + '};\n',
        encoding='utf-8',
    )
    total = sum(p.stat().st_size for p in DEST.glob('*.webp'))
    print(f'\n{len(embarques)} illustrations embarquees, {total // 1024} Ko au total')
    print(f'liste ecrite dans {LISTE.relative_to(RACINE)}')


if __name__ == '__main__':
    main()
