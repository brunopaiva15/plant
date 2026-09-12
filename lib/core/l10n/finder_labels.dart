import '../../domain/species/plant_finder.dart';
import '../../domain/species/species_info.dart';
import '../../l10n/generated/app_localizations.dart';

/// Libellés localisés de « Trouver une plante » : les questions posées, ce
/// que chaque réponse veut dire, et les raisons données à chaque proposition.
extension FinderLabels on AppLocalizations {
  String finderSpotName(FinderSpot spot) => switch (spot) {
        FinderSpot.brightRoom => finderSpotBright,
        FinderSpot.mediumRoom => finderSpotMedium,
        FinderSpot.darkRoom => finderSpotDark,
        FinderSpot.outdoor => finderSpotOutdoor,
      };

  /// Ce que la réponse recouvre, en une ligne sous son libellé : « Coin
  /// sombre » ne dit pas la même chose à tout le monde.
  String finderSpotHint(FinderSpot spot) => switch (spot) {
        FinderSpot.brightRoom => finderSpotBrightHint,
        FinderSpot.mediumRoom => finderSpotMediumHint,
        FinderSpot.darkRoom => finderSpotDarkHint,
        FinderSpot.outdoor => finderSpotOutdoorHint,
      };

  String finderSpotEmoji(FinderSpot spot) => switch (spot) {
        FinderSpot.brightRoom => '☀️',
        FinderSpot.mediumRoom => '🌤️',
        FinderSpot.darkRoom => '🌑',
        FinderSpot.outdoor => '🏡',
      };

  String finderEffortName(FinderEffort effort) => switch (effort) {
        FinderEffort.forgiving => finderEffortForgiving,
        FinderEffort.normal => finderEffortNormal,
        FinderEffort.attentive => finderEffortAttentive,
      };

  String finderEffortHint(FinderEffort effort) => switch (effort) {
        FinderEffort.forgiving => finderEffortForgivingHint,
        FinderEffort.normal => finderEffortNormalHint,
        FinderEffort.attentive => finderEffortAttentiveHint,
      };

  String finderEffortEmoji(FinderEffort effort) => switch (effort) {
        FinderEffort.forgiving => '😅',
        FinderEffort.normal => '🙂',
        FinderEffort.attentive => '🥰',
      };

  String finderReasonName(FinderReason reason) => switch (reason) {
        FinderReason.light => finderReasonLight,
        FinderReason.lowLight => finderReasonLowLight,
        FinderReason.forgiving => finderReasonForgiving,
        FinderReason.easy => finderReasonEasy,
        FinderReason.safe => finderReasonSafe,
        FinderReason.outdoor => finderReasonOutdoor,
      };

  String speciesCategoryName(SpeciesCategory category) => switch (category) {
        SpeciesCategory.indoor => speciesCatIndoor,
        SpeciesCategory.succulent => speciesCatSucculent,
        SpeciesCategory.herb => speciesCatHerb,
        SpeciesCategory.vegetable => speciesCatVegetable,
        SpeciesCategory.fruit => speciesCatFruit,
        SpeciesCategory.flower => speciesCatFlower,
        SpeciesCategory.tree => speciesCatTree,
      };
}
