#!/usr/bin/env python3
"""Moissonne Wikidata (CC0) : espèces de plantes et noms vernaculaires
en fr/de/it/en.

Pour chaque genre de l'ossature taxonomique GBIF, on descend d'un cran vers
ses espèces et on relève, par langue, le libellé principal d'un côté, les
alias et les « noms communs du taxon » de l'autre. La distinction compte :
le libellé est le nom que Wikidata tient pour principal (« gombo »),
l'alias un synonyme secondaire (« Okra »).

Wikidata coupe les requêtes à 60 s. Plutôt que de deviner une taille de lot
sûre, on divise le lot en deux à chaque expiration.

Usage : python3 tool/harvest_species.py genres.txt sortie.tsv
"""
import os
import sys
import time
import urllib.parse
import urllib.request

ENDPOINT = 'https://query.wikidata.org/sparql'
UA = 'FloraApp/1.0 (offline species catalogue; github.com/brunopaiva15/plant)'
LANGS = ('fr', 'de', 'it', 'en')
BATCH = 40


def build_query(genera):
    values = ' '.join('"%s"' % g for g in genera)
    blocks, columns = [], []
    for i, lang in enumerate(LANGS):
        label, alt = '?l_%s' % lang, '?a_%s' % lang
        # Le libellé français est exigé : sans une langue obligatoire, la
        # requête ramènerait les 400 000 espèces sans le moindre nom.
        pattern = '?t rdfs:label %s FILTER(lang(%s) = "%s")' % (label, label, lang)
        blocks.append(pattern if i == 0 else 'OPTIONAL { %s }' % pattern)
        blocks.append('OPTIONAL { { ?t skos:altLabel %s } UNION { ?t wdt:P1843 %s } '
                      'FILTER(lang(%s) = "%s") }' % (alt, alt, alt, lang))
        columns.append('(SAMPLE(%s) AS ?%s)' % (label, lang))
        columns.append('(GROUP_CONCAT(DISTINCT %s; separator="~") AS ?%s_alt)' % (alt, lang))
    return '''SELECT ?name %s WHERE {
  VALUES ?g { %s }
  ?genus wdt:P225 ?g ; wdt:P105 wd:Q34740 .
  ?t wdt:P171 ?genus ; wdt:P105 wd:Q7432 ; wdt:P225 ?name .
  %s
} GROUP BY ?name''' % (' '.join(columns), values, '\n  '.join(blocks))


def run(genera, depth=0):
    url = ENDPOINT + '?' + urllib.parse.urlencode({'query': build_query(genera)})
    req = urllib.request.Request(
        url, headers={'Accept': 'text/tab-separated-values', 'User-Agent': UA})
    try:
        return urllib.request.urlopen(req, timeout=75).read().decode()
    except Exception as e:
        if len(genera) == 1 or depth > 6:
            print('  abandon : %s (%s)' % (genera[:2], type(e).__name__), file=sys.stderr, flush=True)
            return None
        mid = len(genera) // 2
        time.sleep(1)
        halves = [run(genera[:mid], depth + 1), run(genera[mid:], depth + 1)]
        return '\n'.join(h for h in halves if h)


def main(genus_file, out_file):
    genera = [l.strip() for l in open(genus_file) if l.strip()]
    done_file = out_file + '.done'
    done = set(open(done_file).read().split()) if os.path.exists(done_file) else set()
    todo = [g for g in genera if g not in done]
    print('%d genres à traiter (%d déjà faits)' % (len(todo), len(done)), file=sys.stderr, flush=True)
    with open(out_file, 'a', encoding='utf-8') as out, open(done_file, 'a') as marks:
        for i in range(0, len(todo), BATCH):
            chunk = todo[i:i + BATCH]
            body = run(chunk)
            if body:
                for line in body.splitlines():
                    if line.strip() and not line.startswith('?name'):
                        out.write(line + '\n')
                out.flush()
            marks.write('\n'.join(chunk) + '\n')
            marks.flush()
            print('%d/%d' % (i + len(chunk), len(todo)), file=sys.stderr, flush=True)
            time.sleep(0.4)


if __name__ == '__main__':
    main(*sys.argv[1:3])
