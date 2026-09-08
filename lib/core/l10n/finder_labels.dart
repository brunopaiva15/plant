import '../../domain/species/plant_finder.dart';
import '../../domain/species/species_info.dart';
import '../../l10n/generated/app_localizations.dart';

/// Libellés localisés de « Trouver une plante » : les questions posées, et
/// les raisons données à chaque proposition.
extension FinderLabels on AppLocalizations {
  String finderSpotName(FinderSpot spot) => switch (spot) {
        FinderSpot.brightRoom => finderSpotBright,
        FinderSpot.mediumRoom => finderSpotMedium,
        FinderSpot.darkRoom => finderSpotDark,
        FinderSpot.outdoor => finderSpotOutdoor,
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
