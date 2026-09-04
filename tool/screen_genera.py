#!/usr/bin/env python3
"""Crible les genres avant la moisson.

Un genre dont Wikidata n'a d'article dans aucune de nos langues n'a
pratiquement jamais d'espèce portant un nom courant en français, allemand ou
italien. Les écarter divise la moisson par trois, et la requête ne coûte
qu'une jointure par genre — aucune descente vers les espèces.

Usage : python3 tool/screen_genera.py tous_les_genres.txt genres_notables.txt
"""
import sys
import time
import urllib.parse
import urllib.request

ENDPOINT = 'https://query.wikidata.org/sparql'
UA = 'FloraApp/1.0 (offline species catalogue; github.com/brunopaiva15/plant)'
BATCH = 400


def screen(genera):
    values = ' '.join('"%s"' % g for g in genera)
    query = '''SELECT DISTINCT ?g WHERE {
  VALUES ?g { %s }
  ?genus wdt:P225 ?g ; wdt:P105 wd:Q34740 .
  ?art schema:about ?genus ; schema:isPartOf ?wiki .
  VALUES ?wiki { <https://fr.wikipedia.org/> <https://de.wikipedia.org/> <https://it.wikipedia.org/> }
}''' % values
    url = ENDPOINT + '?' + urllib.parse.urlencode({'query': query})
    req = urllib.request.Request(url, headers={'Accept': 'text/tab-separated-values', 'User-Agent': UA})
    for attempt in range(4):
        try:
            body = urllib.request.urlopen(req, timeout=90).read().decode()
            return [l.strip().strip('"') for l in body.splitlines()[1:] if l.strip()]
        except Exception:
            if attempt == 3:
                # En cas d'échec on garde le lot entier : mieux vaut moissonner
                # pour rien que perdre des espèces en silence.
                return list(genera)
            time.sleep(2 ** attempt)


def main(all_file, out_file):
    genera = [l.strip() for l in open(all_file) if l.strip()]
    keep = []
    for i in range(0, len(genera), BATCH):
        keep.extend(screen(genera[i:i + BATCH]))
        print('%d/%d → %d notables' % (min(i + BATCH, len(genera)), len(genera), len(keep)),
              file=sys.stderr, flush=True)
        time.sleep(0.2)
    with open(out_file, 'w') as f:
        f.write('\n'.join(sorted(set(keep))) + '\n')
    print('%d genres retenus sur %d' % (len(set(keep)), len(genera)))


if __name__ == '__main__':
    main(*sys.argv[1:3])
