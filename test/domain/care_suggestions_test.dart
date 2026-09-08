import 'package:flora/domain/care/care_profile.dart';
import 'package:flora/domain/care/care_suggestions.dart';
import 'package:flora/domain/models/care_kind.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const base = CareProfile(
    wateringSummerDays: 7,
    wateringWinterDays: 14,
    light: LightNeed.brightIndirect,
    humidity: HumidityNeed.average,
    difficulty: CareDifficulty.easy,
    soil: SoilKind.standard,
    fertilizingDays: 21,
    repotEveryMonths: 24,
  );
  final july = DateTime(2026, 7, 15);

  int? suggest(CareProfile p, CareKind kind, {LightNeed? light}) =>
      p.suggestedIntervalDays(kind.key, now: july, actualLight: light);

  group('intervalles repris de la fiche', () {
    test('arrosage : celui du mois en cours', () {
      expect(suggest(base, CareKind.watering), base.wateringDaysFor(7));
    });

    test('arrosage : la lumière de l\'emplacement compte', () {
      expect(suggest(base, CareKind.watering, light: LightNeed.lowLight), greaterThan(suggest(base, CareKind.watering)!));
    });

    test('engrais : la fréquence de la fiche', () {
      expect(suggest(base, CareKind.fertilizing), 21);
    });

    test('rempotage : les mois de la fiche, en jours', () {
      expect(suggest(base, CareKind.repotting), 720);
    });
  });

  group('sans indication de la fiche', () {
    test('pas d\'engrais conseillé', () {
      const p = CareProfile(
        wateringSummerDays: 7,
        wateringWinterDays: 14,
        light: LightNeed.fullSun,
        humidity: HumidityNeed.low,
        difficulty: CareDifficulty.easy,
        soil: SoilKind.cactus,
      );
      expect(suggest(p, CareKind.fertilizing), isNull);
      expect(suggest(p, CareKind.repotting), isNull);
    });

    test('type non planifiable ou personnalisé', () {
      expect(suggest(base, CareKind.photo), isNull);
      expect(base.suggestedIntervalDays('custom:taille-haie', now: july), isNull);
    });
  });

  group('déduits de ce que dit la fiche', () {
    const misted = CareProfile(
      wateringSummerDays: 7,
      wateringWinterDays: 14,
      light: LightNeed.brightIndirect,
      humidity: HumidityNeed.high,
      difficulty: CareDifficulty.easy,
      soil: SoilKind.standard,
      mistLeaves: true,
      issues: [CommonIssue.spiderMites],
    );

    test('nettoyage plus fréquent pour un feuillage à brumiser', () {
      expect(suggest(base, CareKind.cleaning), 30);
      expect(suggest(misted, CareKind.cleaning), 21);
    });

    test('traitement plus fréquent pour une espèce à ravageurs', () {
      expect(suggest(base, CareKind.treatment), 90);
      expect(suggest(misted, CareKind.treatment), 60);
    });

    test('taille : intervalle générique', () {
      expect(suggest(base, CareKind.pruning), 90);
    });
  });
}
