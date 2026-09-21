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

  // Une aide en ligne tient en 140 signes ; ce qui est seul sur sa page — le
  // texte d'un écran d'accueil, un chapeau, un bloc de référence de la fiche
  // d'entretien — a droit à 220. Le consentement s'y ajoute : chacune de ses
  // trois phrases porte une garantie distincte (docs/06, « Les textes »,
  // règle 3). `tool/audit_textes.py` porte les mêmes listes ; ce test fait foi.
  const court = 140;
  const long = 220;
  final chapeau = RegExp(
    r'^care\w*(Risk|Detail)$|^careRestNote$|^onb\w*Body$|^roomScan(Hint|BeforeText)$',
  );
  const consentement = {
    'irisFeedbackHint',
    'irisFeedbackAskBody',
    'diagnosisSettingsHint',
    'careAssistHint',
    'careAssistedNote',
  };

  // Le registre est tranché : « vous » en français, *you* en anglais, *du* en
  // allemand, *tu* en italien. Ne sont verrouillées que les marques sûres. En
  // allemand, un « Sie » ou un « Ihre » en tête de phrase désigne aussi bien
  // la plante (« Sie wächst in Erde ») que la personne, et en italien une
  // terminaison en -ate est autant un participe (« Modificate ») qu'un
  // impératif de politesse : la machine ne tranche pas, le relevé les signale
  // à l'œil, et ce test n'en fait pas un échec.
  final registreDeTrop = <String, RegExp>{
    'de': RegExp(r'\bIhnen\b|\b\w+en Sie\b|(?<!^)(?<![.:;!?] )\b(?:Ihre\w*|Ihr|Sie)\b'),
    // Seuls les verbes au participe irrégulier sont sûrs : le participe
    // d'« aprire » est « aperto », donc « Aprite » ne peut être qu'un
    // impératif. « Inviate », « verificate », « attivate » sont aussi des
    // participes féminins pluriels — « {remote} inviate online » veut dire
    // « envoyées » —, et restent au relevé, à l'œil, plutôt qu'ici.
    'it': RegExp(
      r'\b(voi|vostr\w+|potete|dovete|avete|siete|sapete|fate|scegliete|aggiungete|premete|aprite)\b',
      caseSensitive: false,
    ),
  };

  /// Le texte débarrassé des accolades ICU, qui s'imbriquent : on pèle de
  /// l'intérieur jusqu'à ce que plus rien ne bouge.
  String sansIcu(String texte) {
    final accolade = RegExp(r'\{[^{}]*\}');
    while (true) {
      final reduit = texte.replaceAll(accolade, '…');
      if (reduit == texte) return texte;
      texte = reduit;
    }
  }

  Map<String, String> strings(String locale) {
    final json = jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync()) as Map<String, dynamic>;
    return {
      for (final e in json.entries)
        if (!e.key.startsWith('@') && e.value is String) e.key: e.value as String,
    };
  }

  /// Les marqueurs déclarés par le modèle français, clé par clé :
  /// `@plantCount.placeholders` donne `{count}`. Les 195 clés à marqueur en
  /// ont toutes un.
  Map<String, Set<String>> marqueursDuModele() {
    final json = jsonDecode(File('lib/l10n/app_fr.arb').readAsStringSync()) as Map<String, dynamic>;
    final declares = <String, Set<String>>{};
    for (final e in json.entries) {
      if (!e.key.startsWith('@') || e.value is! Map) continue;
      final ph = (e.value as Map)['placeholders'];
      if (ph is Map) declares[e.key.substring(1)] = ph.keys.cast<String>().toSet();
    }
    return declares;
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

      test('aucun marqueur ICU perdu', () {
        // Une réécriture qui laisse tomber « {count} » ne casse qu'à
        // l'exécution. Le modèle français déclare les marqueurs ; chaque
        // langue doit les porter tous, sous la forme `{nom}` ou `{nom, …}`.
        final fautifs = <String>[];
        marqueursDuModele().forEach((cle, attendus) {
          final texte = all[cle];
          if (texte == null) return;
          for (final nom in attendus) {
            if (!RegExp(r'\{\s*' + nom + r'\s*[,}]').hasMatch(texte)) {
              fautifs.add('$cle ($nom)');
            }
          }
        });
        expect(fautifs, isEmpty, reason: 'marqueur ICU absent : $fautifs');
      });

      test("l'apostrophe est droite", () {
        // Les ARB en portent 418 droites contre zéro courbe : c'est la courbe
        // qui détonnerait, et un copier-coller l'introduit sans qu'on la voie.
        final fautifs = [for (final e in all.entries) if (e.value.contains('’')) e.key];
        expect(fautifs, isEmpty, reason: 'apostrophe courbe : $fautifs');
      });

      test('une aide tient en une ou deux phrases', () {
        final fautifs = <String>[];
        for (final e in all.entries) {
          final texte = sansIcu(e.value);
          final limite = chapeau.hasMatch(e.key) || consentement.contains(e.key) ? long : court;
          if (texte.length > limite) {
            fautifs.add('${e.key} (${texte.length} > $limite)');
          }
          final phrases = RegExp(r'[.!?](?:\s|$)').allMatches(texte).length;
          if (phrases > 2 && !consentement.contains(e.key)) {
            fautifs.add('${e.key} ($phrases phrases)');
          }
        }
        expect(fautifs, isEmpty, reason: 'voir docs/06, « Les textes », règle 3 : $fautifs');
      });

      test('un seul registre par langue', () {
        final deTrop = registreDeTrop[locale];
        if (deTrop == null) return;
        final fautifs = <String>[];
        for (final e in all.entries) {
          final m = deTrop.firstMatch(sansIcu(e.value));
          if (m != null) fautifs.add('${e.key} (${m.group(0)})');
        }
        expect(fautifs, isEmpty, reason: 'le registre est du (de) et tu (it) : $fautifs');
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
