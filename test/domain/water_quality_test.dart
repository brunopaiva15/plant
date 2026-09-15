import 'package:flora/core/l10n/care_labels.dart';
import 'package:flora/domain/care/care_profile.dart';
import 'package:flora/domain/care/water_quality.dart';
import 'package:flora/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ce que vaut chaque eau pour une plante : deux choses se croisent, et elles
/// ne se confondent pas. Les sels dissous dépendent de la plante, la propreté
/// de l'eau ne dépend d'aucune.
void main() {
  group('le verdict croise l\'eau et la plante', () {
    test('l\'eau de pluie convient à toutes', () {
      for (final t in WaterTolerance.values) {
        expect(waterVerdictFor(WaterKind.rain, t), WaterVerdict.recommended, reason: '$t');
      }
    });

    test('le robinet suit la tolérance de la plante', () {
      expect(waterVerdictFor(WaterKind.tap, WaterTolerance.tolerant), WaterVerdict.recommended);
      expect(waterVerdictFor(WaterKind.tap, WaterTolerance.sensitive), WaterVerdict.caution);
      expect(waterVerdictFor(WaterKind.tap, WaterTolerance.strict), WaterVerdict.avoid);
    });

    test('une plante qui craint le calcaire ne se voit proposer ni robinet ni carafe', () {
      expect(waterVerdictFor(WaterKind.tap, WaterTolerance.strict), WaterVerdict.avoid);
      expect(waterVerdictFor(WaterKind.filtered, WaterTolerance.strict), WaterVerdict.caution);
      // Une plante sensible, elle, s'accommode d'une carafe.
      expect(waterVerdictFor(WaterKind.filtered, WaterTolerance.sensitive), WaterVerdict.suitable);
    });

    test('osmosée et déminéralisée valent pareil : même absence de minéraux', () {
      for (final t in WaterTolerance.values) {
        expect(waterVerdictFor(WaterKind.osmosis, t), waterVerdictFor(WaterKind.demineralized, t), reason: '$t');
      }
      // Sans minéraux, elles ne servent à rien à une plante que le calcaire
      // ne gêne pas ; elles sont la réponse pour les autres.
      expect(waterVerdictFor(WaterKind.osmosis, WaterTolerance.tolerant), WaterVerdict.suitable);
      expect(waterVerdictFor(WaterKind.osmosis, WaterTolerance.sensitive), WaterVerdict.recommended);
      expect(waterVerdictFor(WaterKind.osmosis, WaterTolerance.strict), WaterVerdict.recommended);
    });

    test('la réserve du condensat ne dépend pas de la plante', () {
      for (final t in WaterTolerance.values) {
        expect(waterVerdictFor(WaterKind.condensate, t), WaterVerdict.caution, reason: '$t');
      }
    });

    test('l\'eau adoucie n\'est bonne pour aucune : la résine met du sodium', () {
      for (final t in WaterTolerance.values) {
        expect(waterVerdictFor(WaterKind.softened, t), WaterVerdict.avoid, reason: '$t');
      }
    });

    test('chaque eau est jugée, quelle que soit la plante', () {
      for (final k in WaterKind.values) {
        for (final t in WaterTolerance.values) {
          expect(() => waterVerdictFor(k, t), returnsNormally, reason: '$k · $t');
        }
      }
    });
  });

  group('les quatre langues nomment chaque eau', () {
    for (final locale in AppLocalizations.supportedLocales) {
      test(locale.languageCode, () async {
        final l10n = await AppLocalizations.delegate.load(locale);
        for (final k in WaterKind.values) {
          expect(l10n.waterKindName(k), isNotEmpty, reason: '$k');
          expect(l10n.waterKindNote(k), isNotEmpty, reason: '$k');
          expect(l10n.waterKindRisk(k), isNotEmpty, reason: '$k');
        }
        for (final v in WaterVerdict.values) {
          expect(l10n.waterVerdictName(v), isNotEmpty, reason: '$v');
        }
        for (final t in WaterTolerance.values) {
          expect(l10n.waterToleranceName(t), isNotEmpty, reason: '$t');
          expect(l10n.waterToleranceNote(t), isNotEmpty, reason: '$t');
        }
        // Deux eaux ne portent pas le même nom : la liste se lit.
        final noms = {for (final k in WaterKind.values) l10n.waterKindName(k)};
        expect(noms, hasLength(WaterKind.values.length));
        // Ni deux verdicts : la couleur ne porte jamais l'information seule.
        final verdicts = {for (final v in WaterVerdict.values) l10n.waterVerdictName(v)};
        expect(verdicts, hasLength(WaterVerdict.values.length));
      });
    }
  });
}
