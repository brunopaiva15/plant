#!/usr/bin/env python3
"""Relève mécanique des tournures qui brouillent les textes de l'interface.

Lit les quatre ARB et signale, chaîne par chaîne, ce qui relève des défauts
décrits dans `docs/18-clarte-des-textes.md` : la consigne à l'infinitif, le
pronominal impersonnel, le passif descriptif, les nombres en toutes lettres,
l'apostrophe droite, le vouvoiement mêlé au tutoiement (de, it), la phrase
trop longue.

    python3 tool/audit_textes.py             # compte par défaut
    python3 tool/audit_textes.py --liste     # une ligne par chaîne signalée
    python3 tool/audit_textes.py --lot pg    # un préfixe de clé
    python3 tool/audit_textes.py --csv > audit.csv

Le relevé n'est pas un verdict : il désigne les endroits à relire.
"""

from __future__ import annotations

import argparse
import csv
import json
import re
import sys
from collections import Counter
from pathlib import Path

ARB = Path(__file__).resolve().parent.parent / 'lib' / 'l10n'
LOCALES = ('fr', 'en', 'de', 'it')

# Les clés dont le texte est un libellé de bouton ou un titre : l'infinitif y
# est la norme française (« Supprimer »), et la phrase courte aussi.
COURT = re.compile(r'(Title|Label|Button|Action|Cta|Name|Short|Unit|Tab)$')
# Les conseils d'entretien gardent le registre du jardinage (docs/06).
EXEMPT = ('careTip',)

CONSIGNE = re.compile(
    r'^\s*(Tourner|Poser|Toucher|Relever|Renseigner|Choisir|Ajouter|Retirer|Garder|'
    r'Vérifier|Photographier|Saisir|Envoyer|Noter|Couper|Planter|Enterrer|Arracher|'
    r'Tirer|Laisser|Attacher|Guider|Humidifier|Aérer|Écarter|Tenir|Éviter|Lire|Compter)\b')

PRONOMINAL = re.compile(
    r"\b(se|s')\s?(fait|change|choisit|corrige|coupe|détache|déduit|défont|dépose|"
    r"écarte|efface|émiette|enfonce|fixe|glisse|multiplie|partage|place|pose|prend|"
    r"règle|remplit|retire|rouvre|sépare|sort|applique|ajoute|active|allonge|forme)\b")

# Le passif qui escamote celui qui agit : « les feuilles sont retirées » pour
# « retirez les feuilles ». Seuls les gestes que la personne fait comptent.
PASSIF = re.compile(
    r'\b(est|sont|a été|ont été|seront|sera)\s+(retiré|coupé|posé|planté|placé|envoyé|'
    r'choisi|ajouté|supprimé|séché|repiqué|noté|rempli|rangé|daté|analysé|montré|dit|'
    r'mis|gardé|détaché|séparé|enterré|arrosé)(e?s?)\b')

NOMBRES = {
    'fr': re.compile(
        r'\b(deux|trois|quatre|cinq|six|sept|huit|neuf|dix|onze|douze|quinze|vingt|trente|'
        r'cinquante)\b[^.;:]{0,24}\b(centimètres?|millimètres?|mètres?|semaines?|jours?|'
        r'mois|heures?|minutes?|ans?|années?|degrés?|pour cent|%)', re.I),
    'en': re.compile(
        r'\b(two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|fifteen|twenty|thirty|'
        r'fifty)\b[^.;:]{0,24}\b(centimet\w+|millimet\w+|met(re|er)s?|weeks?|days?|months?|'
        r'hours?|minutes?|years?|degrees?|per cent|percent|%)', re.I),
    'de': re.compile(
        r'\b(zwei|drei|vier|fünf|sechs|sieben|acht|neun|zehn|elf|zwölf|fünfzehn|zwanzig|'
        r'dreißig|fünfzig)\b[^.;:]{0,24}\b(Zentimetern?|Millimetern?|Metern?|Wochen?|Tagen?|'
        r'Monaten?|Stunden?|Minuten?|Jahren?|Grad|Prozent|%)', re.I),
    'it': re.compile(
        r'\b(due|tre|quattro|cinque|sei|sette|otto|nove|dieci|undici|dodici|quindici|venti|'
        r'trenta|cinquanta)\b[^.;:]{0,24}\b(centimetri?|millimetri?|metri?|settimane?|giorni?|'
        r'mesi?|ore?|minuti?|anni?|gradi?|per cento|%)', re.I),
}

# Le tutoiement et le vouvoiement, dans les langues où les deux se lisent.
REGISTRE = {
    'de': (re.compile(r'\b(du|dich|dir|dein\w*)\b'),
           re.compile(r'\b(Sie|Ihnen|Ihre\w*|Ihr)\b')),
    'it': (re.compile(r'\b(tuo|tua|tuoi|tue|puoi|devi|hai|scegli|tocca|aggiungi|correggi|'
                      r'verifica|inserisci|attiva|premi|apri)\b', re.I),
           re.compile(r'\b(vostr\w+|potete|dovete|avete|desiderate|scegliete|toccate|'
                      r'aggiungete|verificate|inserite|attivate|premete|aprite)\b', re.I)),
}

LONGUEUR = 140          # une bulle d'aide tient en deçà
PHRASES = 2             # au-delà, l'aide devient un paragraphe


def chaines(locale: str) -> dict[str, str]:
    brut = json.loads((ARB / f'app_{locale}.arb').read_text(encoding='utf-8'))
    return {k: v for k, v in brut.items() if not k.startswith('@') and isinstance(v, str)}


def sans_icu(texte: str) -> str:
    """Le texte débarrassé des accolades ICU, pour ne pas compter leur syntaxe."""
    return re.sub(r'\{[^{}]*\}', '…', texte)


def defauts(locale: str, cle: str, texte: str) -> list[str]:
    if cle.startswith(EXEMPT):
        return []
    nu = sans_icu(texte)
    trouves: list[str] = []

    # L'apostrophe droite est la convention des ARB (283 chaînes contre 27) :
    # c'est la courbe qui détonne.
    if '\u2019' in nu:
        trouves.append('apostrophe-courbe')
    if NOMBRES[locale].search(nu):
        trouves.append('nombre-en-lettres')
    if len(nu) > LONGUEUR:
        trouves.append('phrase-longue')
    if len(re.findall(r'[.!?](?:\s|$)', nu)) > PHRASES:
        trouves.append('trop-de-phrases')

    if locale in REGISTRE:
        tu, vous = REGISTRE[locale]
        if tu.search(nu):
            trouves.append('registre-tutoiement')
        if vous.search(nu):
            trouves.append('registre-vouvoiement')

    if locale == 'fr' and not COURT.search(cle):
        # Un bouton s'intitule « Ajouter une plante » : l'infinitif n'y est
        # pas un défaut. C'est dans la phrase explicative qu'il détonne.
        if CONSIGNE.search(nu) and len(nu) >= 38:
            trouves.append('consigne-a-l-infinitif')
        if PRONOMINAL.search(nu):
            trouves.append('pronominal-impersonnel')
        if PASSIF.search(nu):
            trouves.append('passif-descriptif')
    return trouves


def releve(lot: str | None) -> list[tuple[str, str, str, list[str]]]:
    lignes = []
    for locale in LOCALES:
        for cle, texte in chaines(locale).items():
            if lot and not cle.startswith(lot):
                continue
            d = defauts(locale, cle, texte)
            if d:
                lignes.append((locale, cle, texte, d))
    return lignes


def main() -> int:
    parse = argparse.ArgumentParser(description=__doc__)
    parse.add_argument('--liste', action='store_true', help='une ligne par chaîne')
    parse.add_argument('--csv', action='store_true', help='sortie CSV')
    parse.add_argument('--lot', help='ne garder que les clés de ce préfixe')
    args = parse.parse_args()

    lignes = releve(args.lot)

    if args.csv:
        sortie = csv.writer(sys.stdout)
        sortie.writerow(['langue', 'cle', 'defauts', 'texte'])
        for locale, cle, texte, d in lignes:
            sortie.writerow([locale, cle, ' '.join(d), texte])
        return 0

    if args.liste:
        for locale, cle, texte, d in lignes:
            print(f'{locale}\t{cle}\t{",".join(d)}\t{texte}')
        print()

    par_defaut = Counter(d for _, _, _, ds in lignes for d in ds)
    par_langue = Counter(locale for locale, _, _, _ in lignes)
    cles = {cle for _, cle, _, _ in lignes}

    print(f'{len(cles)} clés signalées, {len(lignes)} chaînes sur les quatre langues')
    print()
    for nom, n in par_defaut.most_common():
        print(f'{n:5d}  {nom}')
    print()
    for locale in LOCALES:
        print(f'{par_langue[locale]:5d}  {locale}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
