#!/usr/bin/env python3
"""Relève mécanique des tournures qui brouillent les textes de l'interface.

Lit les quatre ARB et signale, chaîne par chaîne, ce qui relève des défauts
décrits dans `docs/18-clarte-des-textes.md` : la consigne à l'infinitif, le
pronominal impersonnel, le passif descriptif, les nombres en toutes lettres,
l'apostrophe courbe, le registre de trop (le *Sie* allemand, le *voi*
italien) et celui qui demande une relecture, la phrase trop longue.

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
    r"écarte|efface|émiette|enfonce|fixe|glisse|partage|place|pose|prend|"
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
        r'mois|heures?|minutes?|ans?|années?|degrés?|pour cent|%)\b', re.I),
    'en': re.compile(
        r'\b(two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|fifteen|twenty|thirty|'
        r'fifty)\b[^.;:]{0,24}\b(centimet\w+|millimet\w+|met(re|er)s?|weeks?|days?|months?|'
        r'hours?|minutes?|years?|degrees?|per cent|percent|%)\b', re.I),
    'de': re.compile(
        r'\b(zwei|drei|vier|fünf|sechs|sieben|acht|neun|zehn|elf|zwölf|fünfzehn|zwanzig|'
        r'dreißig|fünfzig)\b[^.;:]{0,24}\b(Zentimetern?|Millimetern?|Metern?|Wochen?|Tagen?|'
        r'Monaten?|Stunden?|Minuten?|Jahren?|Grad|Prozent|%)\b', re.I),
    'it': re.compile(
        r'\b(due|tre|quattro|cinque|sei|sette|otto|nove|dieci|undici|dodici|quindici|venti|'
        r'trenta|cinquanta)\b[^.;:]{0,24}\b(centimetri?|millimetri?|metri?|settimane?|giorni?|'
        r'mesi?|ore?|minuti?|anni?|gradi?|per cento|%)\b', re.I),
}

# Le registre est tranché (docs/06, « Les textes ») : « vous » en français,
# *you* en anglais, *du* en allemand, *tu* en italien. Ne reste signalé que le
# registre de trop.
REGISTRE_DE_TROP = {
    'de': re.compile(r'\bIhnen\b|\b\w+en Sie\b'
                     r'|(?<![.:;!?]\s)(?<!^)\b(?:Ihre\w*|Ihr)\b'),
    'it': re.compile(r'\b(voi|vostr\w+|potete|dovete|avete|desiderate|scegliete|toccate|'
                     r'aggiungete|verificate|inserite|attivate|premete|aprite)\b', re.I),
}

# En allemand, « Sie » en tête de phrase est ambigu : le vouvoiement, ou
# simplement « elle » et « ils » (« Sie wächst in Erde », « Sie versorgen den
# Steckling »). Seule la relecture tranche — et une chaîne où l'ambiguïté
# subsiste mérite d'être tournée autrement, le lecteur hésite comme la machine.
SIE_EN_TETE = re.compile(r'(?:^|(?<=[.:;!?]\s))(?:Sie|Ihre\w*|Ihr)\b')

# En italien, l'impératif de politesse se reconnaît à sa terminaison — -ate,
# -ete, -ite en tête de phrase (« Fotografate le foglie », « Inserite il
# codice ») —, mais un participe passé féminin pluriel la partage
# (« Ordinate per verosimiglianza », « Archiviate di recente »). Comme pour le
# « Sie » allemand, la machine désigne, l'œil tranche.
VOI_EN_TETE = re.compile(r'(?:^|(?<=[.:;!?]\s))[A-Z][a-z]*(?:ate|ete|ite)\b')

LONGUEUR = 140          # une aide en ligne tient en deçà
CHAPEAU = 220           # un chapeau d'écran a droit à davantage
PHRASES = 2             # au-delà, l'aide devient un paragraphe

# Le consentement et la confidentialité ont droit à trois phrases et au budget
# d'un chapeau (docs/06, « Les textes », règle 3) : chaque phrase y porte une
# garantie distincte — ce qui part, qui peut le lire, ce qu'il advient si l'on
# refuse. Une clé ne s'ajoute ici que si elle demande un consentement.
REFERENCE = re.compile(r'^care\w*(Risk|Detail)$|^careRestNote$')

CONSENTEMENT = frozenset({
    'irisFeedbackHint',
    'irisFeedbackAskBody',
    'diagnosisSettingsHint',
    'careAssistHint',
    'careAssistedNote',
})


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
    consentement = cle in CONSENTEMENT or REFERENCE.match(cle) is not None
    if len(nu) > CHAPEAU:
        trouves.append('phrase-tres-longue')
    elif len(nu) > LONGUEUR and not consentement:
        trouves.append('phrase-longue')
    if len(re.findall(r'[.!?](?:\s|$)', nu)) > PHRASES and not consentement:
        trouves.append('trop-de-phrases')

    if locale in REGISTRE_DE_TROP and REGISTRE_DE_TROP[locale].search(nu):
        trouves.append('registre-de-trop')
    elif locale == 'de' and SIE_EN_TETE.search(nu):
        trouves.append('registre-a-verifier')
    elif locale == 'it' and VOI_EN_TETE.search(nu):
        trouves.append('registre-a-verifier')

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
