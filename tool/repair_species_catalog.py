#!/usr/bin/env python3
"""Repasse `scrub` sur `assets/species/catalog.tsv` déjà produit.

`build_species_catalog.py` nettoie désormais les libellés que Wikidata rend
avec le balisage de leur source. L'actif livré, lui, a été construit avant :
il porte encore une quarantaine de noms abîmés, et l'encyclopédie les
affiche — « ''Cocus wood'' », « \\Coleus canina\\"" », « Golden&nbsp;torch ».

Remoissonner Wikidata pour si peu coûterait des heures ; ce script répare
l'actif sur place, avec exactement la fonction du générateur, si bien qu'une
régénération future donne le même résultat.

Il est volontairement chirurgical : seules les valeurs que `scrub` modifie
sont rejugées. Une valeur déjà propre n'est pas soumise à un filtre latin
qui ne tournait pas sur le même référentiel de genres — ce serait refaire la
moisson, pas réparer.

Une valeur réparée qui se révèle n'être qu'un binôme latin est retirée :
c'est ce que le générateur en aurait fait, les apostrophes qui l'encadraient
l'ayant seules sauvée du filtre. Une ligne qui perd ainsi ses quatre noms
courants sort du catalogue, comme le veut la règle du générateur.

Usage : python3 tool/repair_species_catalog.py assets/species/catalog.tsv
"""
import sys

from build_species_catalog import is_scientific, scrub

COLS = ('fr', 'en', 'de', 'it')


def repair(path):
    rows = [l.rstrip('\n').split('\t') for l in open(path, encoding='utf-8')]
    # Le référentiel de genres du générateur (GBIF) n'est pas dans le dépôt.
    # Les noms scientifiques de l'actif en sont un substitut suffisant : le
    # binôme déguisé porte presque toujours le genre de sa propre ligne.
    genera = {r[0].split()[0] for r in rows if r[0]}
    fixed = latin = 0
    kept = []
    for r in rows:
        name = r[0]
        for i in range(2, 6):
            value = scrub(r[i])
            if value == r[i]:
                continue
            fixed += 1
            if value and is_scientific(value, name, genera):
                latin += 1
                value = ''
            r[i] = value
        if r[6]:
            alt = []
            for part in r[6].split('~'):
                value = scrub(part)
                if value != part:
                    fixed += 1
                    if is_scientific(value, name, genera):
                        latin += 1
                        continue
                if value:
                    alt.append(value)
            r[6] = '~'.join(alt)
        if any(r[2:6]):
            kept.append(r)
    with open(path, 'w', encoding='utf-8') as f:
        for r in kept:
            f.write('\t'.join(r) + '\n')
    print('%d valeurs réparées, dont %d binômes latins retirés' % (fixed, latin))
    print('%d lignes conservées, %d sans nom courant' % (len(kept), len(rows) - len(kept)))


if __name__ == '__main__':
    repair(sys.argv[1])
