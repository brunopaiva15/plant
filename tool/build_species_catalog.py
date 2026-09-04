#!/usr/bin/env python3
"""Transforme la moisson Wikidata en l'actif `assets/species/catalog.tsv`.

Entrées :
  harvest.tsv        sortie de tool/harvest_species.py
  genus_family.json  genre → famille, d'après l'ossature taxonomique GBIF

Sortie : une ligne par espèce, colonnes séparées par des tabulations
  nom scientifique · famille · fr · en · de · it · autres noms (recherche)

Seules les espèces ayant au moins un vrai nom vernaculaire sont retenues :
Wikidata répète le nom scientifique en guise de libellé quand aucun nom
courant n'existe, et ces lignes-là n'apportent rien à la recherche.

Usage : python3 tool/build_species_catalog.py harvest.tsv genus_family.json sortie.tsv
"""
import csv
import json
import re
import sys
import unicodedata

LANGS = ('fr', 'de', 'it', 'en')

# Un binôme latin : « Genus species », éventuellement avec un rang infra.
BINOMIAL = re.compile(r'^[A-Z][a-zë\-]+(?:\s+(?:×|x)\s*)?\s+[a-zë\-]+'
                      r'(?:\s+(?:var|subsp|ssp|f|cv|sect|ser)\.?\s*[a-zë\-]+)*$')
# Terminaisons latines les plus fréquentes en botanique : elles trahissent un
# synonyme scientifique déguisé en nom commun (« Pithecolobium turbinatum »).
LATIN_TAIL = re.compile(r'(us|um|is|ii|ae|ata|atum|osa|osum|ensis|folia|folium|flora|florum|'
                        r'oides|ifera|iferum|alis|ale|ana|anum|ica|icum|inus|ina|inum)$')
AUTHORSHIP = re.compile(r'\s+(?:L\.|DC\.|Mill\.|Sm\.|Lam\.|Cass\.|Vahl|Hook\.)$')
LANG_TAG = re.compile(r'@[a-z]{2}(-[a-z]+)?$', re.I)


def fold(s):
    """Sans accents ni casse : « Édelweiß » et « edelweiss » se rejoignent.

    Doit rester d'accord avec `foldSpeciesName` côté Dart, sinon un nom
    écarté ici passerait la recherche là-bas — ou l'inverse. Les ligatures
    comptent : « Lagerstrœmia speciosa » n'est qu'un binôme latin déguisé.
    """
    for ligature, plain in (('ß', 'ss'), ('œ', 'oe'), ('Œ', 'oe'), ('æ', 'ae'), ('Æ', 'ae')):
        s = s.replace(ligature, plain)
    s = unicodedata.normalize('NFKD', s)
    return ''.join(c for c in s if not unicodedata.combining(c)).lower().strip()


def clean(value):
    """Retire l'étiquette de langue que Wikidata colle aux libellés en TSV."""
    return AUTHORSHIP.sub('', LANG_TAG.sub('', value.strip())).strip()


def is_scientific(value, name, genera):
    """Un « nom » qui n'est qu'un binôme latin n'aide personne à chercher."""
    if not value or fold(value) == fold(name):
        return True
    words = value.split()
    head = words[0]
    if len(words) == 1:
        return head in genera or fold(head) == fold(name.split()[0])
    if not BINOMIAL.match(value):
        return False
    # Genre connu de GBIF, ou morphologie latine : dans les deux cas, latin.
    return head in genera or bool(LATIN_TAIL.search(words[-1]))


def dedupe(values):
    seen, out = set(), []
    for v in values:
        key = fold(v)
        if key and key not in seen:
            seen.add(key)
            out.append(v)
    return out


def main(harvest, genus_family, out):
    families = json.load(open(genus_family))
    genera = set(families)
    kept = dropped = 0
    rows = []
    csv.field_size_limit(1 << 22)
    # Wikidata cite les valeurs contenant un séparateur : un découpage naïf
    # sur les tabulations laisserait des guillemets partout.
    for cells in csv.reader(open(harvest, encoding='utf-8'), delimiter='\t', quotechar='"'):
        if len(cells) < 9 or cells[0] == '?name':
            continue
        name = clean(cells[0])
        if len(name.split()) < 2:
            continue  # genres et rangs supérieurs : hors sujet ici
        display, extras = {}, []
        for i, lang in enumerate(LANGS):
            label = clean(cells[1 + i * 2])
            aliases = [clean(v) for v in cells[2 + i * 2].split('~')]
            good = [v for v in dedupe([label] + aliases) if not is_scientific(v, name, genera)]
            # Le libellé Wikidata passe en premier : c'est le nom principal.
            display[lang] = good[0] if good else ''
            extras.extend(good[1:])
        if not any(display.values()):
            dropped += 1
            continue
        kept += 1
        chosen = {fold(v) for v in display.values() if v}
        alt = [v for v in dedupe(extras) if fold(v) not in chosen][:6]
        rows.append([name, families.get(name.split()[0], ''),
                     display['fr'], display['en'], display['de'], display['it'], '~'.join(alt)])
    # Un genre peut être moissonné deux fois (homonymes, reprise après
    # coupure) : on garde la ligne la plus complète.
    best = {}
    for r in rows:
        key = r[0].lower()
        filled = sum(1 for c in r[2:] if c)
        if key not in best or filled > best[key][0]:
            best[key] = (filled, r)
    rows = [r for _, r in best.values()]
    rows.sort(key=lambda r: r[0])
    with open(out, 'w', encoding='utf-8') as f:
        for r in rows:
            f.write('\t'.join(c.replace('\t', ' ') for c in r) + '\n')
    print('%d espèces retenues, %d sans nom vernaculaire' % (kept, dropped))


if __name__ == '__main__':
    main(*sys.argv[1:4])
