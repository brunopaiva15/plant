import 'package:flora/data/species/care_profiles.dart';
import 'package:flora/domain/care/care_profile.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ce que la fiche déduit toute seule : le mélange se lit sur le substrat, et
/// avec lui l'engrais à privilégier, le rapport au calcium, la culture hors
/// du terreau. Une espèce qui sait mieux le déclare et l'emporte.
void main() {
  CareProfile profile({
    SoilKind soil = SoilKind.standard,
    int? fertilizingDays = 30,
    int? repotEveryMonths = 24,
    int? minTempC = 12,
    List<Propagation> propagation = const [],
    List<CommonIssue> issues = const [],
    FertilizerKind? fertilizer,
    CalciumNeed? calcium,
    SoilFreeFit? waterCulture,
    SoilFreeFit? ponCulture,
  }) =>
      CareProfile(
        wateringSummerDays: 7,
        wateringWinterDays: 14,
        light: LightNeed.brightIndirect,
        humidity: HumidityNeed.average,
        difficulty: CareDifficulty.easy,
        soil: soil,
        fertilizingDays: fertilizingDays,
        fertilizer: fertilizer,
        calcium: calcium,
        waterCulture: waterCulture,
        ponCulture: ponCulture,
        repotEveryMonths: repotEveryMonths,
        minTempC: minTempC,
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
      // Sans substrat ne veut pas dire dans l'eau : la plante aérienne le dit.
      expect(profile(soil: SoilKind.aquatic).inWater, SoilFreeFit.yes);
      expect(profile(soil: SoilKind.aquatic, waterCulture: SoilFreeFit.no).inWater, SoilFreeFit.no);
    });

    test('le pon va à ce qui vit en pot, pas à la terre de bruyère', () {
      expect(profile().inPon, SoilFreeFit.yes);
      expect(profile(soil: SoilKind.cactus).inPon, SoilFreeFit.yes);
      expect(profile(soil: SoilKind.acidic).inPon, SoilFreeFit.no);
      // Une culture annuelle ne se rempote pas : elle ne se mène pas en pon.
      expect(profile(repotEveryMonths: null).inPon, SoilFreeFit.no);
    });

    test('ce qui tient le gel vit dehors : ni eau ni pon ni serre', () {
      final hardy = profile(minTempC: -10, propagation: [Propagation.water]);
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
      expect(CareProfiles.byGenus['Schlumbergera']!.bloom, BloomTrigger.shortDays);
      expect(CareProfiles.byFamily['Orchidaceae']!.bloom, BloomTrigger.coolNights);
    });
  });
}
