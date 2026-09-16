import 'package:flora/data/species/care_profiles.dart';
import 'package:flora/domain/care/care_profile.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ce que la fiche déduit toute seule : le mélange se lit sur le substrat, et
/// avec lui l'engrais à privilégier, le rapport au calcium, la culture hors
/// du terreau. Une espèce qui sait mieux le déclare et l'emporte.
void main() {
  CareProfile profile({
    SoilKind soil = SoilKind.standard,
    GrowthMedium growthMedium = GrowthMedium.terrestrial,
    HumidityNeed humidity = HumidityNeed.average,
    int? humidityIdealMin,
    int? humidityIdealMax,
    int? humidityToleratedMin,
    int wateringSummerDays = 7,
    int wateringWinterDays = 14,
    DryDown? dryDown,
    int? fertilizingDays = 30,
    int? repotEveryMonths = 24,
    int? damageBelowC = 12,
    List<Propagation> propagation = const [],
    List<CommonIssue> issues = const [],
    FertilizerKind? fertilizer,
    CalciumNeed? calcium,
    SoilFreeFit? waterCulture,
    SoilFreeFit? ponCulture,
  }) =>
      CareProfile(
        wateringSummerDays: wateringSummerDays,
        wateringWinterDays: wateringWinterDays,
        dryDown: dryDown,
        light: LightNeed.brightIndirect,
        humidity: humidity,
        humidityIdealMin: humidityIdealMin,
        humidityIdealMax: humidityIdealMax,
        humidityToleratedMin: humidityToleratedMin,
        difficulty: CareDifficulty.easy,
        soil: soil,
        growthMedium: growthMedium,
        fertilizingDays: fertilizingDays,
        fertilizer: fertilizer,
        calcium: calcium,
        waterCulture: waterCulture,
        ponCulture: ponCulture,
        repotEveryMonths: repotEveryMonths,
        damageBelowC: damageBelowC,
        propagation: propagation,
        issues: issues,
      );

  group('hors-sol', () {
    test('une plante qui bouture dans l’eau n’y vit pas pour autant', () {
      expect(profile(propagation: [Propagation.water]).inWater, SoilFreeFit.cuttings);
      expect(profile().inWater, SoilFreeFit.no);
    });

    test('celles qui y vivent le déclarent', () {
      expect(profile(waterCulture: SoilFreeFit.yes).inWater, SoilFreeFit.yes);
      // Sans substrat ne veut pas dire dans l'eau : c'est le milieu de vie qui
      // le dit, pas l'absence de terreau. Une tillandsie épiphyte n'y vit pas,
      // un nymphéa aquatique si.
      expect(profile(soil: SoilKind.none).inWater, SoilFreeFit.no);
      expect(profile(soil: SoilKind.none, growthMedium: GrowthMedium.aquatic).inWater, SoilFreeFit.yes);
      expect(profile(growthMedium: GrowthMedium.aquatic, waterCulture: SoilFreeFit.no).inWater, SoilFreeFit.no);
    });

    test('le pon va à ce qui vit en pot, pas à la terre de bruyère', () {
      expect(profile().inPon, SoilFreeFit.yes);
      expect(profile(soil: SoilKind.cactus).inPon, SoilFreeFit.yes);
      expect(profile(soil: SoilKind.acidic).inPon, SoilFreeFit.no);
      // Une culture annuelle ne se rempote pas : elle ne se mène pas en pon.
      expect(profile(repotEveryMonths: null).inPon, SoilFreeFit.no);
    });

    test('ce qui tient le gel vit dehors : ni eau ni pon ni serre', () {
      final hardy = profile(damageBelowC: -10, propagation: [Propagation.water]);
      expect(hardy.inWater, SoilFreeFit.no);
      expect(hardy.inPon, SoilFreeFit.no);
      expect(hardy.benefitsFromGreenhouse, isFalse);
      expect(profile().benefitsFromGreenhouse, isTrue);
    });
  });

  group('engrais et calcium', () {
    test('le substrat dit l’engrais', () {
      expect(profile().fertilizerKind, FertilizerKind.balanced);
      expect(profile(soil: SoilKind.cactus).fertilizerKind, FertilizerKind.cactus);
      expect(profile(soil: SoilKind.orchid).fertilizerKind, FertilizerKind.orchid);
      expect(profile(soil: SoilKind.acidic).fertilizerKind, FertilizerKind.acidic);
    });

    test('une espèce qui sait mieux l’emporte', () {
      expect(profile(fertilizer: FertilizerKind.citrus).fertilizerKind, FertilizerKind.citrus);
      expect(profile(calcium: CalciumNeed.welcome).calciumNeed, CalciumNeed.welcome);
    });

    test('pas d’engrais, pas de type d’engrais', () {
      expect(profile(fertilizingDays: null).fertilizerKind, isNull);
    });

    test('le calcium suit la terre et les fruits', () {
      expect(profile().calciumNeed, CalciumNeed.neutral);
      expect(profile(soil: SoilKind.acidic).calciumNeed, CalciumNeed.avoid);
      expect(profile(soil: SoilKind.cactus).calciumNeed, CalciumNeed.welcome);
      expect(profile(issues: [CommonIssue.blossomEndRot]).calciumNeed, CalciumNeed.needed);
      expect(profile(issues: [CommonIssue.blossomEndRot]).fertilizerKind, FertilizerKind.vegetable);
    });
  });

  group('humidité', () {
    test('la plage idéale et le plancher toléré sont deux choses', () {
      final p = profile(humidity: HumidityNeed.high);
      expect(p.humidityRange, (60, 80), reason: 'ce qu\'elle préfère');
      expect(p.humidityFloor, 45, reason: 'sous quoi elle souffre : l\'idéal moins la marge');
      expect(p.humidityCeiling, 95);
      // « Préfère 65–85 » ne veut pas dire « souffre sous 65 ».
      final stricte = profile(humidity: HumidityNeed.high, humidityIdealMin: 65, humidityIdealMax: 85);
      expect(stricte.humidityRange, (65, 85));
      expect(stricte.humidityFloor, 50);
      // Un minimum toléré explicite l'emporte sur la marge.
      final franche = profile(humidity: HumidityNeed.high, humidityToleratedMin: 35);
      expect(franche.humidityFloor, 35);
    });
  });

  group('séchage', () {
    test('la règle se lit dans l\'intervalle, ou s\'écrit à la main', () {
      expect(profile(wateringSummerDays: 2, wateringWinterDays: 2).dryDownRule, DryDown.alwaysMoist);
      expect(profile(wateringSummerDays: 7, wateringWinterDays: 14).dryDownRule, DryDown.topQuarterDry,
          reason: 'la saison active est l\'été, 7 jours');
      // Une plante active en hiver : c'est l'hiver qui compte, 5 jours.
      expect(profile(wateringSummerDays: 30, wateringWinterDays: 5).dryDownRule, DryDown.topQuarterDry);
      // La règle écrite l'emporte sur la lecture.
      expect(profile(dryDown: DryDown.fullyDry).dryDownRule, DryDown.fullyDry);
    });
  });

  group('catalogue', () {
    final all = <String, CareProfile>{
      ...CareProfiles.bySpecies,
      ...CareProfiles.byGenus,
      ...CareProfiles.byFamily,
      ...CareProfiles.byCategory,
    };

    test('aucune fiche de terre de bruyère ne conseille le calcaire', () {
      final fautifs = [
        for (final e in all.entries)
          if (e.value.soil == SoilKind.acidic && e.value.calciumNeed != CalciumNeed.avoid) e.key,
      ];
      expect(fautifs, isEmpty);
    });

    test('le pon ne se propose qu’à ce qui vit en pot', () {
      final fautifs = [
        for (final e in all.entries)
          if (e.value.inPon != SoilFreeFit.no && !e.value.potGrown) e.key,
      ];
      expect(fautifs, isEmpty);
    });

    test('les fiches connues disent leur engrais et leur floraison', () {
      expect(CareProfiles.bySpecies['Citrus × limon']!.fertilizerKind, FertilizerKind.citrus);
      expect(CareProfiles.bySpecies['Citrus × limon']!.calciumNeed, CalciumNeed.avoid);
      expect(CareProfiles.bySpecies['Solanum lycopersicum']!.calciumNeed, CalciumNeed.needed);
      expect(CareProfiles.byGenus['Epipremnum']!.inWater, SoilFreeFit.yes);
      expect(CareProfiles.byGenus['Tillandsia']!.inWater, SoilFreeFit.no);
      expect(CareProfiles.byGenus['Schlumbergera']!.bloom!.triggers, contains(BloomTrigger.shortDays));
      expect(CareProfiles.byFamily['Orchidaceae']!.bloom!.triggers, contains(BloomTrigger.coolNights));
    });
  });
}
