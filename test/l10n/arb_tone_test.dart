import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Les textes de l'application suivent docs/06-design-system.md, « Les
/// textes » : sobres, factuels, sans personnifier l'application ni interpeller
/// la personne. Ce test verrouille la part mécanique de ces consignes sur les
/// quatre ARB. Une tournure à bannir de plus s'ajoute dans [banned].
void main() {
  const locales = ['fr', 'en', 'de', 'it'];

  // Tournures interdites, par langue : l'app qui se met en avant (« nos »,
  // « notre »), la politesse de remplissage (« s'il vous plaît »), la
  // réassurance (« pas de panique »), l'à-peu-près (« probablement »).
  final banned = <String, List<RegExp>>{
    'fr': [
      RegExp(r'probablement', caseSensitive: false),
      RegExp(r"s'il vous pla[iî]t", caseSensitive: false),
      RegExp(r'avec plaisir', caseSensitive: false),
      RegExp(r'personne ne vous juge', caseSensitive: false),
      RegExp(r'pas de panique', caseSensitive: false),
      RegExp(r'ne vous inquiétez', caseSensitive: false),
      RegExp(r"c'est le moment", caseSensitive: false),
      RegExp(r'vous attend', caseSensitive: false),
      RegExp(r'\b(notre|nos)\b', caseSensitive: false),
      RegExp(r'\b(bravo|génial|voilà|hop)\b', caseSensitive: false),
    ],
    'en': [
      RegExp(r'\bprobably\b', caseSensitive: false),
      RegExp(r'\bplease\b', caseSensitive: false),
      RegExp(r'with pleasure|\bgladly\b', caseSensitive: false),
      RegExp(r"don'?t worry|no worries", caseSensitive: false),
      RegExp(r'\bawaits?\b', caseSensitive: false),
      RegExp(r'\bour\b', caseSensitive: false),
      RegExp(r'\b(great|awesome|hooray|voilà)\b', caseSensitive: false),
    ],
    'de': [
      RegExp(r'\bbitte\b', caseSensitive: false),
      RegExp(r'\bgerne?\b', caseSensitive: false),
      RegExp(r'keine sorge', caseSensitive: false),
      RegExp(r'\bunser\w*', caseSensitive: false),
      RegExp(r'\b(toll|super|hurra)\b', caseSensitive: false),
    ],
    'it': [
      RegExp(r'probabilmente', caseSensitive: false),
      RegExp(r'per favore', caseSensitive: false),
      RegExp(r'volentieri', caseSensitive: false),
      RegExp(r'tranquill\w*', caseSensitive: false),
      RegExp(r'\bnostr\w*', caseSensitive: false),
      RegExp(r'\b(bravo|ottimo|evviva)\b', caseSensitive: false),
    ],
  };

  Map<String, String> strings(String locale) {
    final json = jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync()) as Map<String, dynamic>;
    return {
      for (final e in json.entries)
        if (!e.key.startsWith('@') && e.value is String) e.key: e.value as String,
    };
  }

  for (final locale in locales) {
    group(locale, () {
      final all = strings(locale);

      test("aucun point d'exclamation", () {
        final fautifs = [for (final e in all.entries) if (e.value.contains('!')) e.key];
        expect(fautifs, isEmpty, reason: 'un texte ne s\'exclame pas : $fautifs');
      });

      test('un titre est un nom, pas une question', () {
        // Les étapes d'un questionnaire (finderStep…) posent une question,
        // c'est leur rôle ; les titres d'écran et d'étape de saisie, non.
        final fautifs = [
          for (final e in all.entries)
            if (e.key.endsWith('Title') && e.value.trim().endsWith('?')) e.key,
        ];
        expect(fautifs, isEmpty, reason: 'titres en forme de question : $fautifs');
      });

      test('aucune tournure bannie', () {
        // Les conseils d'entretien gardent le registre du jardinage (la
        // plante « aime », « pardonne ») : eux seuls y échappent.
        final fautifs = <String>[];
        for (final e in all.entries) {
          if (e.key.startsWith('careTip')) continue;
          for (final re in banned[locale]!) {
            if (re.hasMatch(e.value)) fautifs.add('${e.key} (${re.pattern})');
          }
        }
        expect(fautifs, isEmpty, reason: 'voir docs/06, « Les textes » : $fautifs');
      });
    });
  }
}
