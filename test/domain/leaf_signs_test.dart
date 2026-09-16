import 'package:flora/domain/care/care_profile.dart';
import 'package:flora/domain/care/leaf_signs.dart';
import 'package:flutter_test/flutter_test.dart';

/// Les signes sur les feuilles sont lus à travers la fiche de l'espèce : une
/// cause qu'elle ne connaît pas n'est pas proposée, et un signe qui n'a plus
/// de cause disparaît plutôt que de rester vide.
void main() {
  const tropicale = CareProfile(
    wateringSummerDays: 7,
    wateringWinterDays: 14,
    light: LightNeed.brightIndirect,
    humidity: HumidityNeed.high,
    difficulty: CareDifficulty.easy,
    soil: SoilKind.rich,
  );

  const cactus = CareProfile(
    wateringSummerDays: 14,
    wateringWinterDays: 40,
    light: LightNeed.fullSun,
    humidity: HumidityNeed.low,
    difficulty: CareDifficulty.easy,
    soil: SoilKind.cactus,
    dormantInWinter: false,
  );

  List<LeafCause> causes(CareProfile profile, LeafSign sign) =>
      LeafSigns.forProfile(profile).firstWhere((r) => r.sign == sign).causes;

  test('une plante tropicale lit tous les signes', () {
    final signes = LeafSigns.forProfile(tropicale).map((r) => r.sign);
    expect(signes, LeafSign.values);
  });

  test('les causes gardent leur ordre, du plus fréquent au moins', () {
    expect(causes(tropicale, LeafSign.drooping), [
      LeafCause.underwatering,
      LeafCause.overwatering,
      LeafCause.damagedRoots,
    ]);
  });

  group('ce que la fiche écarte', () {
    test("une espèce de plein soleil ne brûle pas au soleil", () {
      expect(causes(tropicale, LeafSign.scorched), contains(LeafCause.tooMuchSun));
      expect(causes(cactus, LeafSign.scorched), isNot(contains(LeafCause.tooMuchSun)));
      // Le signe reste : il lui reste la soif et le calcaire.
      expect(causes(cactus, LeafSign.scorched), isNotEmpty);
    });

    test("une espèce qui aime l'air sec ne brunit pas des pointes pour cela", () {
      expect(causes(tropicale, LeafSign.brownTips), contains(LeafCause.dryAir));
      expect(causes(cactus, LeafSign.brownTips), isNot(contains(LeafCause.dryAir)));
    });

    test("sans repos hivernal, l'hiver n'explique pas un arrêt", () {
      expect(causes(tropicale, LeafSign.stunted), contains(LeafCause.winterRest));
      expect(causes(cactus, LeafSign.stunted), isNot(contains(LeafCause.winterRest)));
    });

    test("une plante sans substrat n'a pas de terreau à épuiser", () {
      const tillandsia = CareProfile(
        wateringSummerDays: 5,
        wateringWinterDays: 10,
        light: LightNeed.brightIndirect,
        humidity: HumidityNeed.high,
        difficulty: CareDifficulty.medium,
        soil: SoilKind.none,
        growthMedium: GrowthMedium.epiphytic,
      );
      expect(causes(tillandsia, LeafSign.yellowing), isNot(contains(LeafCause.poorSoil)));
      expect(causes(tillandsia, LeafSign.stunted), isNot(contains(LeafCause.potBound)));
      expect(causes(tillandsia, LeafSign.stunted), contains(LeafCause.notEnoughLight));
    });
  });

  test('aucun signe ne reste sans cause', () {
    for (final profile in [tropicale, cactus]) {
      for (final reading in LeafSigns.forProfile(profile)) {
        expect(reading.causes, isNotEmpty, reason: reading.sign.name);
      }
    }
  });

  test('chaque signe de la table est nommé, et chaque cause sert', () {
    expect(LeafSigns.table.keys, LeafSign.values);
    final servies = {for (final causes in LeafSigns.table.values) ...causes};
    expect(servies, LeafCause.values.toSet(), reason: 'une cause qu\'aucun signe ne propose ne se lit nulle part');
  });
}
