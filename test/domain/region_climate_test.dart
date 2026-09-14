import 'package:flora/domain/weather/region_climate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  RegionClimate at(double winterLow, {double summerHigh = 30, int years = 3}) =>
      RegionClimate(winterLowC: winterLow, summerHighC: summerHigh, years: years);

  group('la zone de rusticité', () {
    test('suit la graduation des cartes USDA', () {
      // 8a va de 10 à 15 °F, soit −12,2 à −9,4 °C ; 8b de 15 à 20 °F.
      expect(at(-11).hardinessLabel, '8a');
      expect(at(-8).hardinessLabel, '8b');
      expect(at(-6).hardinessLabel, '9a');
      expect(at(0).hardinessLabel, '10a');
    });

    test('ne sort jamais de 1a–13b', () {
      expect(at(-60).hardinessLabel, '1a');
      expect(at(40).hardinessLabel, '13b');
    });

    test('sépare la moitié basse de la moitié haute', () {
      expect(at(-11).isUpperHalf, isFalse);
      expect(at(-8).isUpperHalf, isTrue);
      expect(at(-11).hardinessZone, 8);
      expect(at(-8).hardinessZone, 8);
    });
  });

  group('ce qu\'une espèce risque à l\'hiver', () {
    test('rustique quand son minimum descend plus bas que celui du lieu', () {
      expect(at(-8).hardinessOf(-15), RegionHardiness.hardy);
      expect(at(-8).hardinessOf(-8), RegionHardiness.hardy);
    });

    test('protégée dans les six degrés au-dessus : un voile suffit', () {
      expect(at(-8).hardinessOf(-3), RegionHardiness.sheltered);
      expect(at(-8).hardinessOf(-2), RegionHardiness.sheltered);
    });

    test('à rentrer au-delà', () {
      expect(at(-8).hardinessOf(0), RegionHardiness.indoors);
      expect(at(-8).hardinessOf(12), RegionHardiness.indoors);
    });

    test('sans minimum connu, on ne tranche pas', () {
      expect(at(-8).hardinessOf(null), RegionHardiness.unknown);
    });
  });

  test('un été de huit degrés au-dessus de la plage idéale fait souffrir', () {
    expect(at(-5, summerHigh: 38).suffersInSummer(27), isTrue);
    expect(at(-5, summerHigh: 33).suffersInSummer(27), isFalse);
    expect(at(-5, summerHigh: 38).suffersInSummer(null), isFalse);
  });

  test('le descriptif pour l\'IA ne porte ni ville ni coordonnées', () {
    final text = at(-6, summerHigh: 31).describe();
    expect(text, contains('-6 °C'));
    expect(text, contains('31 °C'));
    expect(text, contains('9a'));
  });

  group('la moyenne des extrêmes annuels', () {
    test('moyenne chaque année de la série', () {
      final climate = RegionClimate.fromYearlyExtremes({
        2023: (low: -10, high: 34),
        2024: (low: -6, high: 30),
        2025: (low: -8, high: 32),
      });
      expect(climate!.winterLowC, -8);
      expect(climate.summerHighC, 32);
      expect(climate.years, 3);
      expect(climate.isReliable, isTrue);
    });

    test('une seule année ne fait pas un climat', () {
      final climate = RegionClimate.fromYearlyExtremes({2025: (low: -8, high: 32)});
      expect(climate!.isReliable, isFalse);
    });

    test('sans année, rien', () {
      expect(RegionClimate.fromYearlyExtremes(const {}), isNull);
    });
  });
}
