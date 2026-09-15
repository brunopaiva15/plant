import 'package:intl/intl.dart';

import '../../domain/care/care_guide.dart';
import '../../domain/care/care_profile.dart';
import '../../domain/care/leaf_signs.dart';
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
        CommonIssue.thrips => careIssueThrips,
        CommonIssue.mealybugs => careIssueMealybugs,
        CommonIssue.scale => careIssueScale,
        CommonIssue.aphids => careIssueAphids,
        CommonIssue.fungusGnats => careIssueFungusGnats,
        CommonIssue.whitefly => careIssueWhitefly,
        CommonIssue.trueBugs => careIssueTrueBugs,
        CommonIssue.slugs => careIssueSlugs,
        CommonIssue.powderyMildew => careIssuePowderyMildew,
        CommonIssue.greyMould => careIssueGreyMould,
        CommonIssue.leafSpot => careIssueLeafSpot,
        CommonIssue.blight => careIssueBlight,
        CommonIssue.sunburn => careIssueSunburn,
        CommonIssue.dryTips => careIssueDryTips,
        CommonIssue.leafDrop => careIssueLeafDrop,
        CommonIssue.etiolation => careIssueEtiolation,
        CommonIssue.chlorosis => careIssueChlorosis,
        CommonIssue.blossomEndRot => careIssueBlossomEndRot,
      };

  /// Le support demandé par l'espèce.
  String supportName(PlantSupport v) => switch (v) {
        PlantSupport.mossPole => careSupportMossPole,
        PlantSupport.stake => careSupportStake,
        PlantSupport.trellis => careSupportTrellis,
      };

  /// Ce que ce support demande, et quand : un tuteur moussu s'humidifie à
  /// chaque arrosage, une tige s'attache à mesure qu'elle monte.
  String supportCare(PlantSupport v) => switch (v) {
        PlantSupport.mossPole => careSupportMossPoleCare,
        PlantSupport.stake => careSupportStakeCare,
        PlantSupport.trellis => careSupportTrellisCare,
      };

  /// Ce qu'on voit sur la feuille, dit comme on le voit.
  String leafSignName(LeafSign v) => switch (v) {
        LeafSign.paling => leafSignPaling,
        LeafSign.yellowing => leafSignYellowing,
        LeafSign.scorched => leafSignScorched,
        LeafSign.spots => leafSignSpots,
        LeafSign.brownTips => leafSignBrownTips,
        LeafSign.stunted => leafSignStunted,
        LeafSign.drooping => leafSignDrooping,
        LeafSign.falling => leafSignFalling,
        LeafSign.sticky => leafSignSticky,
      };

  /// Ce qui peut l'expliquer.
  String leafCauseName(LeafCause v) => switch (v) {
        LeafCause.tooMuchSun => leafCauseTooMuchSun,
        LeafCause.notEnoughLight => leafCauseNotEnoughLight,
        LeafCause.overwatering => leafCauseOverwatering,
        LeafCause.underwatering => leafCauseUnderwatering,
        LeafCause.dryAir => leafCauseDryAir,
        LeafCause.coldDraught => leafCauseColdDraught,
        LeafCause.hardWater => leafCauseHardWater,
        LeafCause.poorSoil => leafCausePoorSoil,
        LeafCause.potBound => leafCausePotBound,
        LeafCause.damagedRoots => leafCauseDamagedRoots,
        LeafCause.leafPests => leafCauseLeafPests,
        LeafCause.honeydewPests => leafCauseHoneydewPests,
        LeafCause.sootyMould => leafCauseSootyMould,
        LeafCause.leafFungus => leafCauseLeafFungus,
        LeafCause.wetLeaves => leafCauseWetLeaves,
        LeafCause.recentMove => leafCauseRecentMove,
        LeafCause.oldLeaves => leafCauseOldLeaves,
        LeafCause.winterRest => leafCauseWinterRest,
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
        'filteredWater' => careTipFilteredWater,
        'rainwaterOnly' => careTipRainwaterOnly,
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
