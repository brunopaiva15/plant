import 'package:flora/domain/care/care_profile.dart';
import 'package:flora/domain/care/care_suggestions.dart';
import 'package:flora/domain/care/pot.dart';
import 'package:flora/domain/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const profile = CareProfile(wateringSummerDays: 7, wateringWinterDays: 14, light: LightNeed.brightIndirect, humidity: HumidityNeed.average, difficulty: CareDifficulty.easy, soil: SoilKind.standard);

  group('ce que le pot fait à l\'intervalle', () {
    test('un pot inconnu ne change rien à la fiche', () {
      expect(Pot.unknown.intervalFactor, 1);
      for (var month = 1; month <= 12; month++) {
        expect(profile.wateringDaysFor(month, pot: Pot.unknown), profile.wateringDaysFor(month));
      }
    });

    test('le pot de référence, en plastique, ne change rien non plus', () {
      const pot = Pot(diameterCm: Pot.referenceCm, material: PotMaterial.plastic);
      expect(pot.intervalFactor, 1);
    });

    test('un petit pot rapproche les arrosages, un grand les espace', () {
      const small = Pot(diameterCm: 9);
      const large = Pot(diameterCm: 30);
      expect(small.sizeFactor, lessThan(1));
      expect(large.sizeFactor, greaterThan(1));
      expect(profile.wateringDaysFor(7, pot: small), lessThan(profile.wateringDaysFor(7)));
      expect(profile.wateringDaysFor(7, pot: large), greaterThan(profile.wateringDaysFor(7)));
    });

    test('la taille reste bornée : un godet ou un bac ne font pas n\'importe quoi', () {
      expect(const Pot(diameterCm: 2).sizeFactor, 0.7);
      expect(const Pot(diameterCm: 200).sizeFactor, 1.4);
    });

    test('un diamètre nul ou négatif se lit comme absent', () {
      expect(const Pot(diameterCm: 0).sizeFactor, 1);
      expect(const Pot(diameterCm: -4).volumeMl, isNull);
    });

    test('la terre cuite et le tissu sèchent plus vite, la réserve bien moins', () {
      expect(const Pot(material: PotMaterial.terracotta).materialFactor, lessThan(1));
      expect(const Pot(material: PotMaterial.fabric).materialFactor, lessThan(1));
      expect(const Pot(material: PotMaterial.glazed).materialFactor, 1);
      expect(const Pot(material: PotMaterial.selfWatering).materialFactor, greaterThan(1));
    });

    test('taille et matière se cumulent', () {
      const pot = Pot(diameterCm: 9, material: PotMaterial.terracotta);
      expect(pot.intervalFactor, closeTo(pot.sizeFactor * 0.8, 1e-9));
      expect(profile.wateringDaysFor(7, pot: pot), lessThan(profile.wateringDaysFor(7, pot: const Pot(diameterCm: 9))));
    });

    test('l\'intervalle garde ses bornes, pot compris', () {
      const cactus = CareProfile(wateringSummerDays: 100, wateringWinterDays: 120, light: LightNeed.fullSun, humidity: HumidityNeed.low, difficulty: CareDifficulty.easy, soil: SoilKind.cactus);
      const reservoir = Pot(diameterCm: 40, material: PotMaterial.selfWatering);
      expect(cactus.wateringDaysFor(1, pot: reservoir), 120);
      const fern = CareProfile(wateringSummerDays: 1, wateringWinterDays: 1, light: LightNeed.shade, humidity: HumidityNeed.high, difficulty: CareDifficulty.demanding, soil: SoilKind.standard);
      expect(fern.wateringDaysFor(7, pot: const Pot(diameterCm: 5, material: PotMaterial.fabric)), 1);
    });

    test('la routine proposée suit le pot', () {
      const pot = Pot(diameterCm: 9, material: PotMaterial.terracotta);
      final july = DateTime(2026, 7, 15);
      expect(profile.suggestedIntervalDays('watering', now: july, pot: pot), profile.wateringDaysFor(7, pot: pot));
      expect(profile.suggestedIntervalDays('fertilizing', now: july, pot: pot), profile.suggestedIntervalDays('fertilizing', now: july));
    });
  });

  group('l\'eau à verser', () {
    test('sans diamètre, pas de dose', () {
      expect(const Pot(material: PotMaterial.plastic).doseMl(DryDown.halfDry), isNull);
    });

    test('un pot à réserve se remplit par la réserve, pas par le haut', () {
      expect(const Pot(diameterCm: 15, material: PotMaterial.selfWatering).doseMl(DryDown.halfDry), isNull);
    });

    test('le volume d\'un pot de jardinerie : environ 2 L pour 15 cm', () {
      expect(const Pot(diameterCm: 15).volumeMl, closeTo(2025, 1));
    });

    test('une fourchette ordonnée, arrondie au verre doseur', () {
      for (final d in [6.0, 9.0, 12.0, 15.0, 20.0, 30.0]) {
        for (final rule in DryDown.values) {
          final (low, high) = Pot(diameterCm: d).doseMl(rule)!;
          expect(low, greaterThan(0));
          expect(high, greaterThan(low), reason: '$d cm, $rule');
          final step = low < 200 ? 10 : 50;
          expect(low % step, 0, reason: '$d cm, $rule : $low');
        }
      }
    });

    test('un pot de 15 cm séché à moitié : quelques centaines de millilitres', () {
      final (low, high) = const Pot(diameterCm: 15).doseMl(DryDown.halfDry)!;
      expect(low, inInclusiveRange(250, 400));
      expect(high, inInclusiveRange(300, 450));
    });

    test('plus le substrat a séché, plus il faut verser', () {
      const pot = Pot(diameterCm: 15);
      final doses = [for (final rule in DryDown.values) pot.doseMl(rule)!.$1];
      for (var i = 1; i < doses.length; i++) {
        expect(doses[i], greaterThan(doses[i - 1]), reason: '${DryDown.values[i]}');
      }
    });

    test('un grand pot demande plus qu\'un petit', () {
      expect(const Pot(diameterCm: 25).doseMl(DryDown.halfDry)!.$1, greaterThan(const Pot(diameterCm: 12).doseMl(DryDown.halfDry)!.$1));
    });

    test('la terre cuite boit une part de l\'eau par ses parois', () {
      final plastic = const Pot(diameterCm: 20, material: PotMaterial.plastic).doseMl(DryDown.halfDry)!;
      final terracotta = const Pot(diameterCm: 20, material: PotMaterial.terracotta).doseMl(DryDown.halfDry)!;
      expect(terracotta.$2, greaterThanOrEqualTo(plastic.$2));
    });
  });

  group('le pot d\'une plante', () {
    final plant = Plant(
      id: 'p',
      gardenId: 'g',
      name: 'Pilea',
      status: PlantStatus.active,
      health: PlantHealth.healthy,
      isFavorite: false,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      potSize: 6,
      potMaterial: PotMaterial.terracotta,
    );

    test('le diamètre se lit dans l\'unité du profil', () {
      expect(plant.pot().diameterCm, 6);
      expect(plant.pot(metric: false).diameterCm, closeTo(15.24, 1e-9));
      expect(plant.pot().material, PotMaterial.terracotta);
    });

    test('sans diamètre ni matière, le pot est inconnu', () {
      final bare = plant.copyWith(potSize: () => null, potMaterial: () => null);
      expect(bare.pot().isUnknown, isTrue);
    });

    test('une matière inconnue en base se lit comme non renseignée', () {
      expect(PotMaterial.parse('bamboo'), isNull);
      expect(PotMaterial.parse(null), isNull);
      expect(PotMaterial.parse('glazed'), PotMaterial.glazed);
    });
  });
}
