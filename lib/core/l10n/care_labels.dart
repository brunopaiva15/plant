import 'package:intl/intl.dart';

import '../../domain/care/care_guide.dart';
import '../../domain/care/care_profile.dart';
import '../../domain/care/water_quality.dart';
import '../../l10n/generated/app_localizations.dart';

/// Libellés localisés de la fiche d'entretien.
extension CareProfileLabels on AppLocalizations {
  String lightName(LightNeed v) => switch (v) {
        LightNeed.shade => careLightShade,
        LightNeed.lowLight => careLightLow,
        LightNeed.indirect => careLightIndirect,
        LightNeed.brightIndirect => careLightBright,
        LightNeed.someSun => careLightSome,
        LightNeed.fullSun => careLightFull,
      };

  String humidityName(HumidityNeed v) => switch (v) {
        HumidityNeed.low => careHumidityLow,
        HumidityNeed.average => careHumidityAverage,
        HumidityNeed.high => careHumidityHigh,
      };

  String difficultyName(CareDifficulty v) => switch (v) {
        CareDifficulty.easy => careDifficultyEasy,
        CareDifficulty.medium => careDifficultyMedium,
        CareDifficulty.demanding => careDifficultyDemanding,
      };

  String toxicityName(Toxicity v) => switch (v) {
        Toxicity.safe => careToxicSafe,
        Toxicity.mild => careToxicMild,
        Toxicity.toxic => careToxicToxic,
        Toxicity.unknown => careToxicUnknown,
      };

  String soilName(SoilKind v) => switch (v) {
        SoilKind.standard => careSoilStandard,
        SoilKind.draining => careSoilDraining,
        SoilKind.cactus => careSoilCactus,
        SoilKind.orchid => careSoilOrchid,
        SoilKind.acidic => careSoilAcidic,
        SoilKind.rich => careSoilRich,
        SoilKind.aquatic => careSoilAquatic,
      };

  /// Ce que l'espèce demande comme eau, en deux mots.
  String waterToleranceName(WaterTolerance v) => switch (v) {
        WaterTolerance.tolerant => careWaterTolerant,
        WaterTolerance.sensitive => careWaterSensitive,
        WaterTolerance.strict => careWaterStrict,
      };

  /// Pourquoi : ce que le calcaire lui fait, ou ne lui fait pas.
  String waterToleranceNote(WaterTolerance v) => switch (v) {
        WaterTolerance.tolerant => careWaterTolerantNote,
        WaterTolerance.sensitive => careWaterSensitiveNote,
        WaterTolerance.strict => careWaterStrictNote,
      };

  String waterKindName(WaterKind v) => switch (v) {
        WaterKind.tap => careWaterTap,
        WaterKind.rain => careWaterRain,
        WaterKind.filtered => careWaterFiltered,
        WaterKind.osmosis => careWaterOsmosis,
        WaterKind.demineralized => careWaterDemineralized,
        WaterKind.condensate => careWaterCondensate,
        WaterKind.softened => careWaterSoftened,
      };

  /// Ce que cette eau est.
  String waterKindNote(WaterKind v) => switch (v) {
        WaterKind.tap => careWaterTapNote,
        WaterKind.rain => careWaterRainNote,
        WaterKind.filtered => careWaterFilteredNote,
        WaterKind.osmosis => careWaterOsmosisNote,
        WaterKind.demineralized => careWaterDemineralizedNote,
        WaterKind.condensate => careWaterCondensateNote,
        WaterKind.softened => careWaterSoftenedNote,
      };

  /// Ce qu'elle emporte avec elle, et ce qu'il faut en faire.
  String waterKindRisk(WaterKind v) => switch (v) {
        WaterKind.tap => careWaterTapRisk,
        WaterKind.rain => careWaterRainRisk,
        WaterKind.filtered => careWaterFilteredRisk,
        WaterKind.osmosis => careWaterOsmosisRisk,
        WaterKind.demineralized => careWaterDemineralizedRisk,
        WaterKind.condensate => careWaterCondensateRisk,
        WaterKind.softened => careWaterSoftenedRisk,
      };

  String waterVerdictName(WaterVerdict v) => switch (v) {
        WaterVerdict.recommended => careWaterBest,
        WaterVerdict.suitable => careWaterOk,
        WaterVerdict.caution => careWaterCaution,
        WaterVerdict.avoid => careWaterAvoid,
      };

  /// Le mélange, en proportions : ce qu'on prépare le jour du rempotage.
  String soilMix(SoilKind v) => switch (v) {
        SoilKind.standard => careSoilMixStandard,
        SoilKind.draining => careSoilMixDraining,
        SoilKind.cactus => careSoilMixCactus,
        SoilKind.orchid => careSoilMixOrchid,
        SoilKind.acidic => careSoilMixAcidic,
        SoilKind.rich => careSoilMixRich,
        SoilKind.aquatic => careSoilMixAquatic,
      };

  String soilFreeFitName(SoilFreeFit v) => switch (v) {
        SoilFreeFit.no => careSoilFreeNo,
        SoilFreeFit.cuttings => careSoilFreeCuttings,
        SoilFreeFit.yes => careSoilFreeYes,
      };

  /// « Dans l'eau : bouture seulement · En pon : oui ». `null` quand la
  /// culture hors-sol ne la concerne pas : deux « non » n'apprennent rien.
  String? soilFreeLine(CareProfile p) =>
      p.inWater == SoilFreeFit.no && p.inPon == SoilFreeFit.no ? null : careSoilFree(soilFreeFitName(p.inWater), soilFreeFitName(p.inPon));

  String fertilizerKindName(FertilizerKind v) => switch (v) {
        FertilizerKind.balanced => careFertBalanced,
        FertilizerKind.foliage => careFertFoliage,
        FertilizerKind.flowering => careFertFlowering,
        FertilizerKind.cactus => careFertCactus,
        FertilizerKind.orchid => careFertOrchid,
        FertilizerKind.acidic => careFertAcidic,
        FertilizerKind.citrus => careFertCitrus,
        FertilizerKind.vegetable => careFertVegetable,
      };

  /// Ce qu'il faut faire du calcium. `null` quand il n'y a rien à en dire :
  /// l'eau du robinet en apporte alors assez.
  String? calciumNote(CalciumNeed v) => switch (v) {
        CalciumNeed.avoid => careCalciumAvoid,
        CalciumNeed.welcome => careCalciumWelcome,
        CalciumNeed.needed => careCalciumNeeded,
        CalciumNeed.neutral => null,
      };

  String bloomName(BloomTrigger v) => switch (v) {
        BloomTrigger.coolRest => careBloomCoolRest,
        BloomTrigger.coolNights => careBloomCoolNights,
        BloomTrigger.shortDays => careBloomShortDays,
        BloomTrigger.drySpell => careBloomDrySpell,
        BloomTrigger.potbound => careBloomPotbound,
        BloomTrigger.brightLight => careBloomBrightLight,
      };

  String bloomNote(BloomTrigger v) => switch (v) {
        BloomTrigger.coolRest => careBloomCoolRestNote,
        BloomTrigger.coolNights => careBloomCoolNightsNote,
        BloomTrigger.shortDays => careBloomShortDaysNote,
        BloomTrigger.drySpell => careBloomDrySpellNote,
        BloomTrigger.potbound => careBloomPotboundNote,
        BloomTrigger.brightLight => careBloomBrightLightNote,
      };

  String humidityDetail(HumidityNeed v) => switch (v) {
        HumidityNeed.low => careHumidityLowDetail,
        HumidityNeed.average => careHumidityAverageDetail,
        HumidityNeed.high => careHumidityHighDetail,
      };

  String propagationName(Propagation v) => switch (v) {
        Propagation.stemCutting => carePropCutting,
        Propagation.leafCutting => carePropLeaf,
        Propagation.division => carePropDivision,
        Propagation.offsets => carePropOffsets,
        Propagation.layering => carePropLayering,
        Propagation.seed => carePropSeed,
        Propagation.water => carePropWater,
        Propagation.tuber => carePropTuber,
      };

  String issueName(CommonIssue v) => switch (v) {
        CommonIssue.overwatering => careIssueOverwatering,
        CommonIssue.underwatering => careIssueUnderwatering,
        CommonIssue.rootRot => careIssueRootRot,
        CommonIssue.spiderMites => careIssueSpiderMites,
        CommonIssue.mealybugs => careIssueMealybugs,
        CommonIssue.scale => careIssueScale,
        CommonIssue.aphids => careIssueAphids,
        CommonIssue.fungusGnats => careIssueFungusGnats,
        CommonIssue.whitefly => careIssueWhitefly,
        CommonIssue.slugs => careIssueSlugs,
        CommonIssue.powderyMildew => careIssuePowderyMildew,
        CommonIssue.leafSpot => careIssueLeafSpot,
        CommonIssue.blight => careIssueBlight,
        CommonIssue.sunburn => careIssueSunburn,
        CommonIssue.dryTips => careIssueDryTips,
        CommonIssue.leafDrop => careIssueLeafDrop,
        CommonIssue.etiolation => careIssueEtiolation,
        CommonIssue.chlorosis => careIssueChlorosis,
        CommonIssue.blossomEndRot => careIssueBlossomEndRot,
      };

  /// Ce que le mot veut dire, en une phrase.
  ///
  /// La fiche d'entretien pose le terme sans l'expliquer — « Substrat ·
  /// Écorces pour orchidées » —, ce qui suffit à qui le connaît déjà. Ces
  /// définitions ne se lisent donc pas sur la fiche mais dans le vocabulaire
  /// de l'encyclopédie, où l'on vient exprès.
  String lightNote(LightNeed v) => switch (v) {
        LightNeed.shade => careLightShadeNote,
        LightNeed.lowLight => careLightLowNote,
        LightNeed.indirect => careLightIndirectNote,
        LightNeed.brightIndirect => careLightBrightNote,
        LightNeed.someSun => careLightSomeNote,
        LightNeed.fullSun => careLightFullNote,
      };

  String humidityNote(HumidityNeed v) => switch (v) {
        HumidityNeed.low => careHumidityLowNote,
        HumidityNeed.average => careHumidityAverageNote,
        HumidityNeed.high => careHumidityHighNote,
      };

  String difficultyNote(CareDifficulty v) => switch (v) {
        CareDifficulty.easy => careDifficultyEasyNote,
        CareDifficulty.medium => careDifficultyMediumNote,
        CareDifficulty.demanding => careDifficultyDemandingNote,
      };

  String toxicityNote(Toxicity v) => switch (v) {
        Toxicity.safe => careToxicSafeNote,
        Toxicity.mild => careToxicMildNote,
        Toxicity.toxic => careToxicToxicNote,
        Toxicity.unknown => careToxicUnknownNote,
      };

  String soilNote(SoilKind v) => switch (v) {
        SoilKind.standard => careSoilStandardNote,
        SoilKind.draining => careSoilDrainingNote,
        SoilKind.cactus => careSoilCactusNote,
        SoilKind.orchid => careSoilOrchidNote,
        SoilKind.acidic => careSoilAcidicNote,
        SoilKind.rich => careSoilRichNote,
        SoilKind.aquatic => careSoilAquaticNote,
      };

  String propagationNote(Propagation v) => switch (v) {
        Propagation.stemCutting => carePropCuttingNote,
        Propagation.leafCutting => carePropLeafNote,
        Propagation.division => carePropDivisionNote,
        Propagation.offsets => carePropOffsetsNote,
        Propagation.layering => carePropLayeringNote,
        Propagation.seed => carePropSeedNote,
        Propagation.water => carePropWaterNote,
        Propagation.tuber => carePropTuberNote,
      };

  /// Conseil libre, par clé. Retourne `null` si la clé est inconnue, pour que
  /// l'UI n'affiche jamais un identifiant technique.
  String? careTip(String key) => switch (key) {
        'fingerTest' => careTipFingerTest,
        'drySoilFirst' => careTipDrySoilFirst,
        'neverDryOut' => careTipNeverDryOut,
        'evenWatering' => careTipEvenWatering,
        'waterAtBase' => careTipWaterAtBase,
        'noWaterOnLeaves' => careTipNoWaterOnLeaves,
        'bottomWatering' => careTipBottomWatering,
        'thirstyPlant' => careTipThirstyPlant,
        'droopSignal' => careTipDroopSignal,
        'winterDry' => careTipWinterDry,
        'winterRest' => careTipWinterRest,
        'summerDormant' => careTipSummerDormant,
        'noWaterWhileSplitting' => careTipNoWaterWhileSplitting,
        'orchidSoak' => careTipOrchidSoak,
        'soakMount' => careTipSoakMount,
        'dryUpsideDown' => careTipDryUpsideDown,
        'waterInTheCup' => careTipWaterInTheCup,
        'noSoil' => careTipNoSoil,
        'greenRoots' => careTipGreenRoots,
        'humidityTray' => careTipHumidityTray,
        'noDirectSun' => careTipNoDirectSun,
        'toleratesLowLight' => careTipToleratesLowLight,
        'toleratesNeglect' => careTipToleratesNeglect,
        'brightForColor' => careTipBrightForColor,
        'rotatePot' => careTipRotatePot,
        'hatesMoving' => careTipHatesMoving,
        'wipeLeaves' => careTipWipeLeaves,
        'trimToBushOut' => careTipTrimToBushOut,
        'monsteraSupport' => careTipMonsteraSupport,
        'shallowPot' => careTipShallowPot,
        'likesBeingPotbound' => careTipLikesBeingPotbound,
        'trunkStoresWater' => careTipTrunkStoresWater,
        'pupsToShare' => careTipPupsToShare,
        'keepFlowerSpike' => careTipKeepFlowerSpike,
        'darkForRebloom' => careTipDarkForRebloom,
        'notADesertCactus' => careTipNotADesertCactus,
        'deadheadFlowers' => careTipDeadheadFlowers,
        'pinchFlowers' => careTipPinchFlowers,
        'harvestTop' => careTipHarvestTop,
        'harvestOutside' => careTipHarvestOutside,
        'stakeAndPrune' => careTipStakeAndPrune,
        'prunesInSpring' => careTipPrunesInSpring,
        'prunesAfterFlowering' => careTipPrunesAfterFlowering,
        'winterPruning' => careTipWinterPruning,
        'pruneAfterHarvest' => careTipPruneAfterHarvest,
        'cutSpentCanes' => careTipCutSpentCanes,
        'trimTwiceAYear' => careTipTrimTwiceAYear,
        'containItsRoots' => careTipContainItsRoots,
        'mulchIt' => careTipMulchIt,
        'acidSoil' => careTipAcidSoil,
        'feedsOnInsects' => careTipFeedsOnInsects,
        'blueNeedsAcid' => careTipBlueNeedsAcid,
        'citrusFertilizer' => careTipCitrusFertilizer,
        'noFertilizer' => careTipNoFertilizer,
        'noNitrogen' => careTipNoNitrogen,
        'letFoliageDieBack' => careTipLetFoliageDieBack,
        'diesBackInWinter' => careTipDiesBackInWinter,
        'summerOutdoors' => careTipSummerOutdoors,
        'winterIndoors' => careTipWinterIndoors,
        'winterShelter' => careTipWinterShelter,
        'winterCool' => careTipWinterCool,
        'coolerIsBetter' => careTipCoolerIsBetter,
        'hardyOutdoors' => careTipHardyOutdoors,
        'shelterFromWind' => careTipShelterFromWind,
        'airFlow' => careTipAirFlow,
        'spiderMiteWatch' => careTipSpiderMiteWatch,
        'slugWatch' => careTipSlugWatch,
        'boxMothWatch' => careTipBoxMothWatch,
        'sapIrritant' => careTipSapIrritant,
        'veryToxic' => careTipVeryToxic,
        'sharpSpines' => careTipSharpSpines,
        'splitsAreNormal' => careTipSplitsAreNormal,
        'dryToBloom' => careTipDryToBloom,
        _ => null,
      };

  /// Provenance de la fiche, dite honnêtement.
  String careMatchLabel(ResolvedCare care) => switch (care.match) {
        CareMatch.species => careMatchSpecies,
        CareMatch.genus => careMatchGenus(care.matchedOn ?? ''),
        CareMatch.family => careMatchFamily(care.matchedOn ?? ''),
        CareMatch.category || CareMatch.generic => careMatchGeneric,
        CareMatch.assisted => careMatchAssisted,
      };

  /// « de mars à septembre », dans la langue et le calendrier de l'utilisateur.
  String fertilizeWindowLabel(MonthWindow w, String localeTag) {
    final fmt = DateFormat.MMMM(localeTag);
    return careFertilizeSeason(fmt.format(DateTime(2026, w.from)), fmt.format(DateTime(2026, w.to)));
  }

  /// « Tous les 18 mois » ou « Tous les 2 ans », selon ce qui se lit le mieux.
  String repotLabel(int? months) {
    if (months == null) return careRepotNone;
    if (months >= 12 && months % 12 == 0) return careRepotYears(months ~/ 12);
    return careRepotMonths(months);
  }
}
