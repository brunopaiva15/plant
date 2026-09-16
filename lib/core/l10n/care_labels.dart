import 'package:intl/intl.dart';

import '../../domain/care/care_guide.dart';
import '../../domain/care/care_profile.dart';
import '../../domain/care/leaf_signs.dart';
import '../../domain/care/toxicity.dart';
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

  /// La règle d'arrosage, dite en clair : jusqu'où laisser sécher le substrat.
  String dryDownName(DryDown v) => switch (v) {
        DryDown.alwaysMoist => careDryDownAlwaysMoist,
        DryDown.surfaceDry => careDryDownSurfaceDry,
        DryDown.topQuarterDry => careDryDownTopQuarterDry,
        DryDown.halfDry => careDryDownHalfDry,
        DryDown.mostlyDry => careDryDownMostlyDry,
        DryDown.fullyDry => careDryDownFullyDry,
      };

  String toxicityName(Toxicity v) => switch (v) {
        Toxicity.safe => careToxicSafe,
        Toxicity.mild => careToxicMild,
        Toxicity.toxic => careToxicToxic,
        Toxicity.unknown => careToxicUnknown,
      };

  /// Le mot qui tient sur une puce, quand l'espèce a un avis sur son pot.
  /// `null` pour celles qui n'en ont pas : la règle en dessous suffit.
  String? potBadge(PotPreference v) => switch (v) {
        PotPreference.snug => carePotSnug,
        PotPreference.steady => null,
        PotPreference.roomy => carePotRoomy,
      };

  /// Ce qu'une racine sortie par le fond veut dire pour cette espèce. Chez une
  /// plante à réserves, elle ne veut rien dire : c'est la fin du repos qui
  /// commande le rempotage.
  String potNote(CareProfile p) {
    if (p.dormancy != null) return carePotDormantNote;
    return switch (p.pot) {
      PotPreference.snug => carePotSnugNote,
      PotPreference.steady => carePotSteadyNote,
      PotPreference.roomy => carePotRoomyNote,
    };
  }

  String soilName(SoilKind v) => switch (v) {
        SoilKind.standard => careSoilStandard,
        SoilKind.draining => careSoilDraining,
        SoilKind.cactus => careSoilCactus,
        SoilKind.orchid => careSoilOrchid,
        SoilKind.acidic => careSoilAcidic,
        SoilKind.rich => careSoilRich,
        SoilKind.none => careSoilNone,
      };

  /// Où vit la plante : en terre pour la plupart, sur un support ou dans
  /// l'eau pour les autres.
  String growthMediumName(GrowthMedium v) => switch (v) {
        GrowthMedium.terrestrial => careMediumTerrestrial,
        GrowthMedium.epiphytic => careMediumEpiphytic,
        GrowthMedium.lithophytic => careMediumLithophytic,
        GrowthMedium.aquatic => careMediumAquatic,
        GrowthMedium.semiAquatic => careMediumSemiAquatic,
      };

  /// La même chose, en une phrase, pour le vocabulaire.
  String growthMediumNote(GrowthMedium v) => switch (v) {
        GrowthMedium.terrestrial => careMediumTerrestrialNote,
        GrowthMedium.epiphytic => careMediumEpiphyticNote,
        GrowthMedium.lithophytic => careMediumLithophyticNote,
        GrowthMedium.aquatic => careMediumAquaticNote,
        GrowthMedium.semiAquatic => careMediumSemiAquaticNote,
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
        SoilKind.none => careSoilMixNone,
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
        BloomTrigger.chillBulb => careBloomChillBulb,
        BloomTrigger.fertilizer => careBloomFertilizer,
        BloomTrigger.maturity => careBloomMaturity,
        BloomTrigger.deadhead => careBloomDeadhead,
        BloomTrigger.keepSpike => careBloomKeepSpike,
        BloomTrigger.noMove => careBloomNoMove,
        BloomTrigger.evenWater => careBloomEvenWater,
      };

  String bloomNote(BloomTrigger v) => switch (v) {
        BloomTrigger.coolRest => careBloomCoolRestNote,
        BloomTrigger.coolNights => careBloomCoolNightsNote,
        BloomTrigger.shortDays => careBloomShortDaysNote,
        BloomTrigger.drySpell => careBloomDrySpellNote,
        BloomTrigger.potbound => careBloomPotboundNote,
        BloomTrigger.brightLight => careBloomBrightLightNote,
        BloomTrigger.chillBulb => careBloomChillBulbNote,
        BloomTrigger.fertilizer => careBloomFertilizerNote,
        BloomTrigger.maturity => careBloomMaturityNote,
        BloomTrigger.deadhead => careBloomDeadheadNote,
        BloomTrigger.keepSpike => careBloomKeepSpikeNote,
        BloomTrigger.noMove => careBloomNoMoveNote,
        BloomTrigger.evenWater => careBloomEvenWaterNote,
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

  /// Les moyens de tenir l'humidité, quand la fiche en nomme : une phrase par
  /// méthode, dans l'ordre de l'énumération. `null` quand elle se tait.
  String? humidityMethodNote(Set<HumidityMethod> methods) {
    if (methods.isEmpty) return null;
    return [
      for (final method in HumidityMethod.values)
        if (methods.contains(method))
          switch (method) {
            HumidityMethod.mist => careHumidityMethodMist,
            HumidityMethod.humidifier => careHumidityMethodHumidifier,
            HumidityMethod.tray => careHumidityMethodTray,
            HumidityMethod.terrarium => careHumidityMethodTerrarium,
          },
    ].join(' ');
  }

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

  /// D'où vient un fait de toxicité, et à quel niveau il a été trouvé.
  /// `null` quand rien n'est renseigné : il n'y a alors pas de provenance à
  /// montrer, seulement le silence.
  String? toxicityProvenance(ToxicityFact fact) {
    final level = switch (fact.level) {
      ToxicitySource.species => careToxicityFromSpecies,
      ToxicitySource.genus => careToxicityFromGenus(fact.matchedOn ?? ''),
      ToxicitySource.family => careToxicityFromFamily(fact.matchedOn ?? ''),
      ToxicitySource.none => null,
    };
    if (level == null) return null;
    final source = fact.source;
    return source == null ? level : '$level · ${careToxicitySource(source)}';
  }

  String soilNote(SoilKind v) => switch (v) {
        SoilKind.standard => careSoilStandardNote,
        SoilKind.draining => careSoilDrainingNote,
        SoilKind.cactus => careSoilCactusNote,
        SoilKind.orchid => careSoilOrchidNote,
        SoilKind.acidic => careSoilAcidicNote,
        SoilKind.rich => careSoilRichNote,
        SoilKind.none => careSoilNoneNote,
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

  /// Où garder l'organe de réserve pendant son sommeil.
  String restStorage(DormantRest rest) {
    final min = rest.storeMinC;
    final max = rest.storeMaxC;
    if (min == null || max == null) return rest.dark ? careRestStoreDark : careRestStorePlain;
    return rest.dark ? careRestStoreDarkTemp(min, max) : careRestStoreTemp(min, max);
  }

  /// « De mars à mai », dans la langue et le calendrier de l'utilisateur.
  String monthRangeLabel(MonthWindow w, String localeTag) {
    final fmt = DateFormat.MMMM(localeTag);
    return careSeasonRange(fmt.format(DateTime(2026, w.from)), fmt.format(DateTime(2026, w.to)));
  }

  /// Provenance de la fiche, dite honnêtement.
  String careMatchLabel(ResolvedCare care) => switch (care.match) {
        CareMatch.species => careMatchSpecies,
        CareMatch.genus => careMatchGenus(care.matchedOn ?? ''),
        CareMatch.family => careMatchFamily(care.matchedOn ?? ''),
        CareMatch.category || CareMatch.generic => careMatchGeneric,
        CareMatch.assisted => careMatchAssisted,
        CareMatch.edited => careMatchEdited,
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
