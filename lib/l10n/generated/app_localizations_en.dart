// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Auxine';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get done => 'Done';

  @override
  String get continueLabel => 'Continue';

  @override
  String get back => 'Back';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get add => 'Add';

  @override
  String get search => 'Search';

  @override
  String get close => 'Close';

  @override
  String get undo => 'Undo';

  @override
  String get later => 'Later';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get skip => 'Skip';

  @override
  String get next => 'Next';

  @override
  String get retry => 'Retry';

  @override
  String get more => 'More';

  @override
  String get seeAll => 'See all';

  @override
  String get optional => 'optional';

  @override
  String get none => 'None';

  @override
  String get soon => 'Soon';

  @override
  String get genericError => 'An error occurred. Try again.';

  @override
  String get offlineTitle => 'Offline';

  @override
  String get offlineHint =>
      'This needs a connection. Data already on your device stays readable.';

  @override
  String get offlineActionFailed =>
      'Offline. Try again once the network is back.';

  @override
  String get offlineSharing =>
      'Creating, revoking and listing links needs a connection.';

  @override
  String get offlineCollaboration =>
      'Inviting, joining a garden and changing a role needs a connection.';

  @override
  String get offlineDiagnosis => 'The analysis needs a connection.';

  @override
  String get offlineIdentification =>
      'Online search needs a connection; on-device recognition does not.';

  @override
  String get tabToday => 'Today';

  @override
  String get tabPlants => 'Plants';

  @override
  String get tabGarden => 'Garden';

  @override
  String get tabProfile => 'Profile';

  @override
  String greeting(String name) {
    return 'Hello $name';
  }

  @override
  String get greetingAnonymous => 'Hello';

  @override
  String greetingEvening(String name) {
    return 'Good evening $name';
  }

  @override
  String get greetingEveningAnonymous => 'Good evening';

  @override
  String todayHeroCare(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'tasks today',
      one: 'task today',
    );
    return '$_temp0';
  }

  @override
  String statDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'days',
      one: 'day',
    );
    return '$_temp0';
  }

  @override
  String todayHeroWeek(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'tasks this week',
      one: 'task this week',
      zero: 'tasks this week',
    );
    return '$_temp0';
  }

  @override
  String careCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tasks',
      one: '1 task',
      zero: 'Nothing to do',
    );
    return '$_temp0';
  }

  @override
  String get sectionOverdue => 'Overdue';

  @override
  String get sectionToday => 'Today';

  @override
  String get sectionUpcoming => 'Coming up';

  @override
  String get allDoneTitle => 'All good';

  @override
  String get allDoneSubtitle => 'No care due today.';

  @override
  String get emptyGardenTitle => 'No plants';

  @override
  String get addFirstPlant => 'Add my first plant';

  @override
  String get yourGarden => 'Your garden';

  @override
  String get recentPhotos => 'Recent photos';

  @override
  String plantCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count plants',
      one: '1 plant',
      zero: 'No plants',
    );
    return '$_temp0';
  }

  @override
  String get kindWatering => 'Watering';

  @override
  String get kindFertilizing => 'Fertilizer';

  @override
  String get kindRepotting => 'Repotting';

  @override
  String get kindPruning => 'Pruning';

  @override
  String get kindCleaning => 'Cleaning';

  @override
  String get kindTreatment => 'Treatment';

  @override
  String get kindMeasurement => 'Measurement';

  @override
  String get kindPhoto => 'Photo';

  @override
  String get kindNote => 'Note';

  @override
  String get verbWatering => 'Water';

  @override
  String get verbFertilizing => 'Fertilize';

  @override
  String get verbRepotting => 'Repot';

  @override
  String get verbPruning => 'Prune';

  @override
  String get verbCleaning => 'Clean';

  @override
  String get verbTreatment => 'Treat';

  @override
  String get verbMeasurement => 'Measure';

  @override
  String get verbPhoto => 'Photo';

  @override
  String get verbNote => 'Note';

  @override
  String get doneWatering => 'Watered';

  @override
  String get doneFertilizing => 'Fertilized';

  @override
  String get doneRepotting => 'Repotted';

  @override
  String get donePruning => 'Pruned';

  @override
  String get doneCleaning => 'Cleaned';

  @override
  String get doneTreatment => 'Treated';

  @override
  String get doneMeasurement => 'Measured';

  @override
  String get donePhoto => 'Photo added';

  @override
  String get doneNote => 'Note added';

  @override
  String get doneCustom => 'Done';

  @override
  String actionDoneToast(String plant, String action) {
    return '$plant · $action';
  }

  @override
  String multiActionDone(int count, String action) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count plants · $action',
      one: '1 plant · $action',
    );
    return '$_temp0';
  }

  @override
  String get dueToday => 'Today';

  @override
  String get dueTomorrow => 'Tomorrow';

  @override
  String dueInDays(int count) {
    return 'In $count days';
  }

  @override
  String dueOverdue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days overdue',
      one: '1 day overdue',
    );
    return '$_temp0';
  }

  @override
  String get dueNone => 'No reminder';

  @override
  String careDueLabel(String action, String when) {
    return '$action · $when';
  }

  @override
  String verbToday(String verb) {
    return '$verb today';
  }

  @override
  String get plantsTitle => 'Plants';

  @override
  String get searchPlants => 'Name, species, location…';

  @override
  String get filters => 'Filters';

  @override
  String get sortBy => 'Sort by';

  @override
  String get sortName => 'Name';

  @override
  String get sortNextCare => 'Next care';

  @override
  String get sortRecent => 'Recently added';

  @override
  String get sortEdited => 'Recently edited';

  @override
  String get sortLastWatered => 'Last watered';

  @override
  String get sortLastFertilized => 'Last fertilised';

  @override
  String get sortLastRepotted => 'Last repotted';

  @override
  String get sortAcquired => 'Acquired';

  @override
  String get filterLocation => 'Location';

  @override
  String get filterNeedsAttention => 'Needs care';

  @override
  String get filterFavorites => 'Favorites';

  @override
  String get filterTag => 'Tag';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get gridView => 'Grid';

  @override
  String get listView => 'List';

  @override
  String get showAsGrid => 'Show as grid';

  @override
  String get showAsList => 'Show as list';

  @override
  String get noResultsTitle => 'No results';

  @override
  String get noResultsSubtitle => 'Try another word.';

  @override
  String get emptyPlantsTitle => 'No plants yet';

  @override
  String get emptyPlantsSubtitle => 'Add your first plant.';

  @override
  String get addPlant => 'Add a plant';

  @override
  String selectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selected',
      one: '1 selected',
    );
    return '$_temp0';
  }

  @override
  String get select => 'Select';

  @override
  String get move => 'Move';

  @override
  String get archive => 'Archive';

  @override
  String get addTag => 'Add tag';

  @override
  String get favorite => 'Favorite';

  @override
  String get unfavorite => 'Remove from favorites';

  @override
  String movedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count plants moved',
      one: '1 plant moved',
    );
    return '$_temp0';
  }

  @override
  String archivedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count plants archived',
      one: '1 plant archived',
    );
    return '$_temp0';
  }

  @override
  String get newPlant => 'New plant';

  @override
  String get stepPhotoTitle => 'Photo';

  @override
  String get stepPhotoSubtitle => 'Frame the whole plant, in daylight.';

  @override
  String get stepPhotoSubtitleCutting =>
      'Frame the whole cutting, in daylight.';

  @override
  String get takePhoto => 'Take a photo';

  @override
  String get choosePhoto => 'Choose a photo';

  @override
  String get withoutPhoto => 'Continue without photo';

  @override
  String get changePhoto => 'Change';

  @override
  String get stepNameTitle => 'Name';

  @override
  String get plantNameHint => 'Plant name';

  @override
  String get speciesHint => 'Species (optional)';

  @override
  String get stepLocationTitle => 'Location';

  @override
  String get newLocationChip => 'New';

  @override
  String get noLocation => 'No location';

  @override
  String get finish => 'Finish';

  @override
  String plantAdded(String name) {
    return '$name added';
  }

  @override
  String get moreOptions => 'More options';

  @override
  String get acquiredAt => 'Acquired on';

  @override
  String get source => 'Source';

  @override
  String get sourceHint => 'Nursery, cutting from a friend…';

  @override
  String get price => 'Price';

  @override
  String get potSize => 'Pot diameter';

  @override
  String get notes => 'Notes';

  @override
  String get notesHint => 'Light, repotting, remarks…';

  @override
  String get wateringEvery => 'Watering';

  @override
  String get fertilizingEvery => 'Fertilizer';

  @override
  String everyDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Every $count days',
      one: 'Every day',
    );
    return '$_temp0';
  }

  @override
  String sinceDate(String date) {
    return 'Since $date';
  }

  @override
  String get nextCare => 'Next care';

  @override
  String get addAction => 'Add an action';

  @override
  String get history => 'History';

  @override
  String get seeFullHistory => 'Full history';

  @override
  String get growth => 'Growth';

  @override
  String get photos => 'Photos';

  @override
  String get info => 'Details';

  @override
  String get offspring => 'Offspring';

  @override
  String get editSchedule => 'Edit the schedule';

  @override
  String cuttingOf(String name) {
    return 'Cutting of $name';
  }

  @override
  String get propagate => 'Create a cutting';

  @override
  String get pgPickTitle => 'Propagate this plant';

  @override
  String get pgPickBody =>
      'This plant propagates in more than one way. Pick one: the steps follow from it.';

  @override
  String get pgRecommended => 'Recommended';

  @override
  String pgIntroTitle(String name, String species) {
    return '$name of $species';
  }

  @override
  String pgIntroBody(int count) {
    return '$count steps, each one shown as an image and explained in one sentence, adapted to the species when it is known.';
  }

  @override
  String get pgStartCutting => 'Create the cutting';

  @override
  String get pgStartPlant => 'Create the plant';

  @override
  String get pgNoteSpot => 'Look for';

  @override
  String get pgNoteAvoid => 'Avoid';

  @override
  String get pgNoteUsual => 'Usually';

  @override
  String get pgNoteMedium => 'Rooting';

  @override
  String get pgMediumWater => 'In water';

  @override
  String get pgMediumSubstrate => 'In a light substrate';

  @override
  String get pgMediumEither => 'Water or a light substrate';

  @override
  String get pgVineName => 'Stem cutting';

  @override
  String get pgVineHint => 'A node, a clean cut, water';

  @override
  String get pgVineNodeTitle => 'The node';

  @override
  String get pgVineNodeBody =>
      'Find the swelling where a leaf starts, often with an aerial root beside it. Keep at least one on the cutting.';

  @override
  String get pgVineNodeNote => 'Node and aerial root';

  @override
  String get pgVineCutTitle => 'The cut';

  @override
  String get pgVineCutBody =>
      'With a clean blade, cut cleanly 1 cm below the node: the node stays on the cutting.';

  @override
  String get pgVineCutNote => 'Cutting above the node';

  @override
  String get pgVineClearTitle => 'The bare node';

  @override
  String get pgVineClearBody =>
      'Remove the leaves that would sit under water. Keep 2 or 3 on top: they feed the cutting.';

  @override
  String get pgVineWaterTitle => 'The water';

  @override
  String get pgVineWaterBody =>
      'Put the node under the water, the leaves above it. Set the glass in bright light, out of direct sun.';

  @override
  String get pgVineRootsTitle => 'The roots';

  @override
  String get pgVineRootsBody =>
      'The roots come out of the node, not the bottom of the stem. Change the water every week.';

  @override
  String get pgVineRootsNote => 'First roots in 2 to 6 weeks';

  @override
  String get pgVinePotTitle => 'The pot';

  @override
  String get pgVinePotBody =>
      'When the roots are a few centimetres long, pot the cutting in light potting mix, the node just under the surface.';

  @override
  String get pgSoftName => 'Soft stem cutting';

  @override
  String get pgSoftHint => 'A young shoot, fast roots';

  @override
  String get pgSoftStemTitle => 'The shoot';

  @override
  String get pgSoftStemBody =>
      'Pick a young, firm shoot without flowers, about 10 cm: old wood roots badly.';

  @override
  String get pgSoftCutTitle => 'The cut';

  @override
  String get pgSoftCutBody =>
      'With a clean blade, cut just below a pair of leaves: the roots will start there.';

  @override
  String get pgSoftStripTitle => 'The lower leaves';

  @override
  String get pgSoftStripBody =>
      'Remove the lowest pair to bare 3 to 4 cm of stem.';

  @override
  String get pgSoftStripNote => 'Leaving a leaf under water';

  @override
  String get pgSoftRootTitle => 'Rooting';

  @override
  String get pgSoftRootBody =>
      'Stand the bare stem in the water and keep the leaves dry, in bright light and out of direct sun.';

  @override
  String get pgSoftRootsTitle => 'The roots';

  @override
  String get pgSoftRootsBody =>
      'The roots are fine and many, and come from the whole submerged part.';

  @override
  String get pgSoftRootsNote => 'First roots in 1 to 3 weeks';

  @override
  String get pgSoftPotTitle => 'Potting on';

  @override
  String get pgSoftPotBody =>
      'Pot it early, at 2 to 3 cm of root: a soft stem does not keep well.';

  @override
  String get pgLeafName => 'Leaf cutting';

  @override
  String get pgLeafHint => 'Slower, one leaf is enough';

  @override
  String get pgLeafChooseTitle => 'The leaf';

  @override
  String get pgLeafChooseBody =>
      'Pick a mature, firm leaf with no marks: young leaves have no reserves.';

  @override
  String get pgLeafCutTitle => 'The cut';

  @override
  String get pgLeafCutBody =>
      'With a clean blade, cut the leaf at its base, level with the substrate.';

  @override
  String get pgLeafSplitTitle => 'The segments';

  @override
  String get pgLeafSplitBody =>
      'Cut the leaf into pieces of 5 to 8 cm. Cut a V at the bottom of each to mark the end that goes down.';

  @override
  String get pgLeafSplitNote => 'The V marks the bottom';

  @override
  String get pgLeafCallusTitle => 'Drying';

  @override
  String get pgLeafCallusBody =>
      'Let the cuts dry in the air, in the shade, before planting them.';

  @override
  String get pgLeafCallusNote => '1 to 2 days of drying';

  @override
  String get pgLeafPlantTitle => 'The substrate';

  @override
  String get pgLeafPlantBody =>
      'Push the V 2 cm into a free-draining substrate.';

  @override
  String get pgLeafPlantNote => 'Planting a segment upside down';

  @override
  String get pgLeafGrowthTitle => 'New growth';

  @override
  String get pgLeafGrowthBody =>
      'The roots come first; the young shoot rises from the substrate beside the segment.';

  @override
  String get pgLeafGrowthNote => 'New shoot in 2 to 4 months';

  @override
  String get pgDivisionName => 'Division';

  @override
  String get pgDivisionHint => 'Quick and reliable, for clump-forming plants';

  @override
  String get pgDivPlantTitle => 'The clump';

  @override
  String get pgDivPlantBody =>
      'Take the plant out of the pot whole. A substrate watered the day before holds together better.';

  @override
  String get pgDivUnpotTitle => 'Out of the pot';

  @override
  String get pgDivUnpotBody =>
      'Slide the pot off the root ball to free the plant.';

  @override
  String get pgDivRootsTitle => 'The root ball';

  @override
  String get pgDivRootsBody =>
      'Crumble the soil away until you can see the roots and the base of the shoots.';

  @override
  String get pgDivClustersTitle => 'The two groups';

  @override
  String get pgDivClustersBody =>
      'Each group keeps its own shoots and its own roots.';

  @override
  String get pgDivClustersNote => 'Leaves and roots on each side';

  @override
  String get pgDivSplitTitle => 'The split';

  @override
  String get pgDivSplitBody =>
      'Pull the groups apart by hand. Use the blade only if the crowns hold.';

  @override
  String get pgDivSplitNote => 'Cutting a stem above the soil';

  @override
  String get pgDivRepotTitle => 'Repotting';

  @override
  String get pgDivRepotBody =>
      'Pot each division in its own pot, at the depth it had before, then water it once.';

  @override
  String get pgOffsetName => 'Offset';

  @override
  String get pgOffsetHint => 'The offset leaves with its own roots';

  @override
  String get pgOffSpotTitle => 'The offset';

  @override
  String get pgOffSpotBody =>
      'An offset a third the size of the mother plant, with leaves of its own, is ready to leave.';

  @override
  String get pgOffSpotNote => 'An offset already formed';

  @override
  String get pgOffClearTitle => 'Clearing';

  @override
  String get pgOffClearBody =>
      'Clear the substrate around the base until the link to the mother plant shows.';

  @override
  String get pgOffDetachTitle => 'The split';

  @override
  String get pgOffDetachBody =>
      'Pull the offset away with its roots. Use the blade only if the link is woody.';

  @override
  String get pgOffDetachNote => 'Pulling the offset off without roots';

  @override
  String get pgOffRootsTitle => 'The roots';

  @override
  String get pgOffRootsBody =>
      'A few clean roots are enough. Without them the offset dries before it takes.';

  @override
  String get pgOffPotTitle => 'The pot';

  @override
  String get pgOffPotBody =>
      'Pot it in a small pot with the substrate the species wants, then water lightly.';

  @override
  String get pgOffSettleTitle => 'Settling in';

  @override
  String get pgOffSettleBody =>
      'A new leaf at the centre means the offset has taken.';

  @override
  String get pgOffSettleNote => 'Takes in 3 to 6 weeks';

  @override
  String get pgKeikiName => 'Separate a keiki';

  @override
  String get pgKeikiHint => 'The orchid\'s offshoot leaves with its roots';

  @override
  String get pgKeikiSpotTitle => 'The keiki';

  @override
  String get pgKeikiSpotBody =>
      'A young plant grows on a node of the flower spike: 2 leaves and aerial roots make it recognisable.';

  @override
  String get pgKeikiSpotNote => 'An offshoot already formed';

  @override
  String get pgKeikiWaitTitle => 'The roots';

  @override
  String get pgKeikiWaitBody =>
      'The roots lengthen along the spike. At 3 to 5 roots a few centimetres long, the keiki can live on its own.';

  @override
  String get pgKeikiWaitNote => 'Roots ready in 2 to 3 months';

  @override
  String get pgKeikiDetachTitle => 'The split';

  @override
  String get pgKeikiDetachBody =>
      'Cut the spike on either side of the keiki, 1 or 2 cm away. Do not pull: you would bruise the base.';

  @override
  String get pgKeikiDetachNote => 'Pulling the keiki off';

  @override
  String get pgKeikiRootsTitle => 'The keiki\'s roots';

  @override
  String get pgKeikiRootsBody =>
      'Keep the keiki\'s aerial roots: they are the ones that take in the pot.';

  @override
  String get pgKeikiPotTitle => 'The pot';

  @override
  String get pgKeikiPotBody =>
      'Pot it in a small pot of bark, the base of the keiki level with the substrate, not buried.';

  @override
  String get pgKeikiSettleTitle => 'Settling in';

  @override
  String get pgKeikiSettleBody =>
      'A new leaf at the centre means the keiki has taken.';

  @override
  String get pgKeikiSettleNote => 'Takes in 1 to 2 months';

  @override
  String get pgSegmentName => 'Segment cutting';

  @override
  String get pgSegmentHint => 'A segment detached, dried, planted';

  @override
  String get pgSegChooseTitle => 'The segment';

  @override
  String get pgSegChooseBody =>
      'Pick a firm terminal segment with no wrinkles, 2 or 3 joints long.';

  @override
  String get pgSegDetachTitle => 'Detaching';

  @override
  String get pgSegDetachBody =>
      'Twist the segment off at the joint. Use a clean blade if it holds.';

  @override
  String get pgSegDetachNote => 'Pulling and tearing the joint';

  @override
  String get pgSegWoundTitle => 'The wound';

  @override
  String get pgSegWoundBody =>
      'The cut is pale and damp: planted straight away, it would rot.';

  @override
  String get pgSegCallusTitle => 'The callus';

  @override
  String get pgSegCallusBody =>
      'Let the wound dry in the air, in the shade, until it forms a matt callus.';

  @override
  String get pgSegCallusNote => '3 to 7 days of drying';

  @override
  String get pgSegPlantTitle => 'The substrate';

  @override
  String get pgSegPlantBody =>
      'Set the callused end barely 1 cm into a very free-draining substrate.';

  @override
  String get pgSegPlantNote => 'Burying the segment';

  @override
  String get pgSegRootsTitle => 'New growth';

  @override
  String get pgSegRootsBody =>
      'The roots come first, then a new joint. Wait until the roots hold before watering.';

  @override
  String get parentPlant => 'Parent plant';

  @override
  String get schedule => 'Schedule';

  @override
  String get editPlant => 'Edit plant';

  @override
  String get archivePlant => 'Archive plant';

  @override
  String get archiveReasonTitle => 'Reason';

  @override
  String get reasonDied => 'Died';

  @override
  String get reasonGiven => 'Given away';

  @override
  String get reasonSold => 'Sold';

  @override
  String get reasonOther => 'Other';

  @override
  String plantArchived(String name) {
    return '$name archived';
  }

  @override
  String get restore => 'Restore';

  @override
  String plantRestored(String name) {
    return '$name restored';
  }

  @override
  String get deleteForever => 'Delete permanently';

  @override
  String get deleteForeverConfirm =>
      'This plant and its whole history will be deleted.';

  @override
  String get noHistoryTitle => 'No actions yet';

  @override
  String get noHistorySubtitle => 'Every care will show up here.';

  @override
  String get noPhotosTitle => 'No photos';

  @override
  String get noPhotosSubtitle => 'Add a photo to follow its growth.';

  @override
  String get setAsPrimary => 'Set as main photo';

  @override
  String get deletePhoto => 'Delete photo';

  @override
  String get health => 'Health';

  @override
  String get healthHealthy => 'Thriving';

  @override
  String get healthWatch => 'Keep an eye';

  @override
  String get healthSick => 'Sick';

  @override
  String get healthIssue => 'Problem';

  @override
  String get issueOverwatering => 'Overwatering';

  @override
  String get issueUnderwatering => 'Underwatering';

  @override
  String get issuePests => 'Pests';

  @override
  String get issueDisease => 'Disease';

  @override
  String get issueRootRot => 'Root rot';

  @override
  String get issueTransplantShock => 'Transplant shock';

  @override
  String get issueDeficiency => 'Nutrient deficiency';

  @override
  String get issueSunburn => 'Sunburn';

  @override
  String get issueFrost => 'Frost damage';

  @override
  String get needsSection => 'Needs';

  @override
  String get detailsSection => 'Details';

  @override
  String get lifespan => 'Life cycle';

  @override
  String get lifespanAnnual => 'Annual';

  @override
  String get lifespanBiennial => 'Biennial';

  @override
  String get lifespanPerennial => 'Perennial';

  @override
  String get hardiness => 'Hardiness';

  @override
  String get hardinessHardy => 'Hardy';

  @override
  String get hardinessTender => 'Tender';

  @override
  String get cuttingMonth => 'Cutting month';

  @override
  String get noSchedule => 'No reminders';

  @override
  String get addRoutine => 'Add a routine';

  @override
  String get frequency => 'Frequency';

  @override
  String get strategyFixed => 'Fixed';

  @override
  String get strategySeasonal => 'Seasonal';

  @override
  String get strategyManual => 'Manual';

  @override
  String get strategySeasonalHint => 'Less often in winter, more in summer.';

  @override
  String get strategyManualHint => 'No automatic reminder.';

  @override
  String get strategyFixedHint => 'The same interval all year.';

  @override
  String get enabled => 'Enabled';

  @override
  String get interval => 'Interval';

  @override
  String get intervalSuggested => 'Suggested interval';

  @override
  String intervalSuggestedDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Suggested interval: $count days',
      one: 'Suggested interval: 1 day',
    );
    return '$_temp0';
  }

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String lastDone(String date) {
    return 'Last: $date';
  }

  @override
  String nextDue(String date) {
    return 'Next: $date';
  }

  @override
  String get deleteRoutine => 'Delete routine';

  @override
  String get snooze => 'Later';

  @override
  String snoozed(String name) {
    return '$name · postponed to tomorrow';
  }

  @override
  String get measurements => 'Measurements';

  @override
  String measurementDelta(String delta, String date) {
    return '$delta since $date';
  }

  @override
  String get whatDidYouDo => 'Action';

  @override
  String get when => 'When';

  @override
  String get noteHint => 'Add a note…';

  @override
  String get quantity => 'Quantity';

  @override
  String get value => 'Value';

  @override
  String get measureHeight => 'Height';

  @override
  String get measureWidth => 'Width';

  @override
  String get measureLeaves => 'Leaves';

  @override
  String get measurePot => 'Pot';

  @override
  String get record => 'Save';

  @override
  String get addNote => 'Add a note';

  @override
  String get addPhoto => 'Add a photo';

  @override
  String get camera => 'Camera';

  @override
  String get gallery => 'Photo library';

  @override
  String get photoError => 'Couldn\'t add the photo. Try again.';

  @override
  String get newActionType => 'New action type';

  @override
  String get actionTypeLabel => 'Name';

  @override
  String get actionTypeLabelHint => 'Misting';

  @override
  String get actionTypeEmoji => 'Emoji';

  @override
  String get actionTypes => 'Action types';

  @override
  String get actionTypesHint =>
      'Create your own actions alongside the built-in ones.';

  @override
  String get deleteActionType => 'Delete this type';

  @override
  String get builtin => 'Built-in';

  @override
  String get gardenTitle => 'Garden';

  @override
  String get locations => 'Locations';

  @override
  String get newLocationTitle => 'New location';

  @override
  String get locationName => 'Name';

  @override
  String get locationNameHint => 'Living room';

  @override
  String get locationIcon => 'Icon';

  @override
  String get parentLocation => 'Inside';

  @override
  String get noParent => 'None';

  @override
  String get light => 'Light';

  @override
  String get lightLow => 'Low';

  @override
  String get lightMedium => 'Medium';

  @override
  String get lightHigh => 'Bright';

  @override
  String get orientation => 'Orientation';

  @override
  String get orientationHint => 'South-west';

  @override
  String get deleteLocation => 'Delete location';

  @override
  String get deleteLocationHint => 'Plants won\'t be deleted.';

  @override
  String get noLocationsTitle => 'No locations';

  @override
  String get noLocationsSubtitle =>
      'Create a living room, a balcony, a greenhouse…';

  @override
  String get editLocation => 'Edit location';

  @override
  String get noPlantsHereTitle => 'No plants here';

  @override
  String get noPlantsHereSubtitle => 'Move plants here or add one.';

  @override
  String get chooseLocation => 'Choose a location';

  @override
  String get defaultLivingRoom => 'Living room';

  @override
  String get defaultKitchen => 'Kitchen';

  @override
  String get defaultBedroom => 'Bedroom';

  @override
  String get defaultBalcony => 'Balcony';

  @override
  String get defaultOffice => 'Office';

  @override
  String get defaultBathroom => 'Bathroom';

  @override
  String get defaultGarden => 'Garden';

  @override
  String get defaultGreenhouse => 'Greenhouse';

  @override
  String get profileTitle => 'Profile';

  @override
  String get yourName => 'Your first name';

  @override
  String get yourNameHint => 'First name';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get reduceMotion => 'Reduce motion';

  @override
  String get reduceMotionHint =>
      'By default, the app follows the system setting.';

  @override
  String get notifications => 'Notifications';

  @override
  String get enableNotifications => 'Daily reminder';

  @override
  String get notificationTime => 'Time';

  @override
  String get quietDays => 'Quiet days';

  @override
  String get notificationPreview => 'Preview';

  @override
  String get notificationHint =>
      'One notification a day, only when care is due.';

  @override
  String get notificationPermissionDenied =>
      'Allow notifications in your phone\'s Settings.';

  @override
  String get archives => 'Past plants';

  @override
  String get noArchivesTitle => 'No past plants';

  @override
  String get noArchivesSubtitle => 'Archived plants will show up here.';

  @override
  String archivedOn(String date) {
    return 'Archived on $date';
  }

  @override
  String get units => 'Units';

  @override
  String get metric => 'Metric';

  @override
  String get imperial => 'Imperial';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get account => 'Account';

  @override
  String get localAccount => 'Data on this device';

  @override
  String get localAccountHint => 'Your data stays on this phone.';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String get tags => 'Tags';

  @override
  String get newTag => 'New tag';

  @override
  String get tagNameHint => 'Tropical, Rare, Watch…';

  @override
  String get noTags => 'No tags';

  @override
  String get manageTags => 'Manage tags';

  @override
  String get onboardingTitle => 'All your plants, here';

  @override
  String get onboardingSubtitle => 'Add them with or without a photo.';

  @override
  String get onbPlaceTitle => 'Your city';

  @override
  String get onbPlaceBody =>
      'For the weather and outdoor watering. A city is enough: your exact position is not stored.';

  @override
  String get useMyLocation => 'Use my location';

  @override
  String get locating => 'Finding your town…';

  @override
  String get locationFailed =>
      'Location unavailable. You can pick a town in Profile › Weather.';

  @override
  String get locationUnavailable => 'Location unavailable.';

  @override
  String get onbHomeTitle => 'Your home';

  @override
  String get onbHomeBody =>
      'Apple Home and Google Home sensors give the temperature and humidity of your rooms. Indoor advice and diagnoses take them into account, and the reading stays in the app.';

  @override
  String get homeClimate => 'Home sensors';

  @override
  String get homeClimateHint =>
      'A home sensor adjusts the advice for your indoor plants and fills out diagnoses. The reading stays in the app.';

  @override
  String get homeClimateApple => 'Apple Home';

  @override
  String get homeClimateGoogle => 'Google Home';

  @override
  String get homeClimateConnect => 'Connect a home';

  @override
  String get homeClimateConnectApple => 'Connect Apple Home';

  @override
  String get homeClimateConnectGoogle => 'Connect Google Home';

  @override
  String get homeClimateSearching => 'Looking for sensors…';

  @override
  String get homeClimateSensor => 'Sensor';

  @override
  String get homeClimateSensors => 'Sensors found';

  @override
  String get homeClimateChoose => 'Choose a sensor';

  @override
  String get homeClimateChange => 'Change sensor';

  @override
  String get homeClimateHome => 'Home';

  @override
  String get homeClimateSource => 'Platform';

  @override
  String get homeClimateNoRoom => 'No room';

  @override
  String get homeClimateTemperatureSensor => 'Temperature sensor';

  @override
  String get homeClimateHumiditySensor => 'Humidity sensor';

  @override
  String get homeClimateSameSensor => 'Same sensor';

  @override
  String get homeClimateHumidityMissing =>
      'This sensor is not sending humidity. Pick another one in the Humidity row.';

  @override
  String get homeClimateNone => 'No sensor';

  @override
  String get homeClimateRemove => 'Remove sensor';

  @override
  String get homeClimateReading => 'Reading';

  @override
  String get homeClimateUnavailable => 'Sensor not reachable for now.';

  @override
  String homeClimateUpdatedAgo(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes min ago',
      one: '1 min ago',
      zero: 'Just now',
    );
    return '$_temp0';
  }

  @override
  String homeClimateNoSensorsIn(String home) {
    return 'No temperature or humidity sensor in $home.';
  }

  @override
  String get homeClimateDeniedApple =>
      'Access to Apple Home denied. You can grant it again in Settings › Privacy › Home.';

  @override
  String get homeClimateDeniedGoogle =>
      'Access to Google Home denied. You can grant it again in the Google Home app, under permissions.';

  @override
  String homeClimateFailedIn(String home) {
    return '$home is unavailable. You can connect a sensor in Profile › Home sensors.';
  }

  @override
  String get homeClimateAppleNote =>
      'Apple Home reads accessories on the device.';

  @override
  String get homeClimateGoogleNote =>
      'Google Home reads devices through your Google account.';

  @override
  String get homeClimateDisconnect => 'Disconnect';

  @override
  String get homeClimateDisconnectGoogle => 'Disconnect Google Home';

  @override
  String get homeClimateDisconnectGoogleHint =>
      'The Google Home sensors are forgotten on this device. The access stays in your Google account: withdraw it from there.';

  @override
  String get homeClimateDisconnectedGoogle => 'Google Home disconnected.';

  @override
  String get homeClimateGoogleAccess => 'Google Account permissions';

  @override
  String get homeClimateAtHome => 'At home';

  @override
  String get homeClimateFits => 'Nothing that bothers this species.';

  @override
  String get homeClimateTooDry => 'Air too dry for this species.';

  @override
  String get homeClimateTooHumid => 'Air too humid for this species.';

  @override
  String get homeClimateTooCold => 'Too cold for this species.';

  @override
  String get homeClimateTooHot => 'Too warm for this species.';

  @override
  String homeTipDryAir(String names) {
    return 'Dry air: mist or group $names.';
  }

  @override
  String get homeTipHumidAir => 'Humid air: air the room.';

  @override
  String homeTipHumidAirPlants(String names) {
    return 'Humid air: air the room, and let $names dry out between waterings.';
  }

  @override
  String homeTipCold(String names) {
    return 'Too cold for $names.';
  }

  @override
  String homeTipHot(String names) {
    return 'Heat: $names dry out faster, check the soil.';
  }

  @override
  String diagnosisWithHome(String reading) {
    return 'Home reading attached: $reading.';
  }

  @override
  String placeChosen(String place) {
    return 'Weather set to $place.';
  }

  @override
  String get askNameTitle => 'Your first name';

  @override
  String get askNameSubtitle => 'Can be changed later in the profile.';

  @override
  String get onbAccountTitle => 'Backup and sharing';

  @override
  String get onbAccountBody =>
      'An account backs up your data and lets you share a garden. Sign in with your Apple ID.';

  @override
  String get notificationAskTitle => 'Daily reminder';

  @override
  String get notificationAskBody =>
      'One notification a day, at the time you choose, only when care is due.';

  @override
  String get enable => 'Enable';

  @override
  String get notNow => 'Not now';

  @override
  String get notificationTitle => 'Your plants';

  @override
  String get notificationChannel => 'Care reminders';

  @override
  String notifWaterOne(String name) {
    return '$name: watering due today.';
  }

  @override
  String notifWaterMany(String names) {
    return '$names: watering due today.';
  }

  @override
  String notifOther(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count other cares due.',
      one: '1 other care due.',
    );
    return '$_temp0';
  }

  @override
  String notifOnlyOther(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cares due today.',
      one: '1 care due today.',
    );
    return '$_temp0';
  }

  @override
  String andJoin(String a, String b) {
    return '$a and $b';
  }

  @override
  String get listSeparator => ', ';

  @override
  String get timelineToday => 'Today';

  @override
  String get timelineYesterday => 'Yesterday';

  @override
  String get photoAddedToast => 'Photo added';

  @override
  String get noteAddedToast => 'Note added';

  @override
  String get actionAddedToast => 'Action saved';

  @override
  String locationCreated(String name) {
    return '$name created';
  }

  @override
  String get saved => 'Saved';

  @override
  String get gardenLocations => 'Places';

  @override
  String get gardenInventory => 'Inventory';

  @override
  String get gardenCalendar => 'Calendar';

  @override
  String get inventoryTitle => 'Inventory';

  @override
  String get newItem => 'New item';

  @override
  String get editItem => 'Edit item';

  @override
  String get itemName => 'Name';

  @override
  String get itemNameHint => 'Green plant fertilizer';

  @override
  String get category => 'Category';

  @override
  String get catFertilizer => 'Fertilizers';

  @override
  String get catSoil => 'Soils';

  @override
  String get catSubstrate => 'Substrates';

  @override
  String get catPot => 'Pots';

  @override
  String get catTool => 'Tools';

  @override
  String get catTreatment => 'Treatments';

  @override
  String get catSeed => 'Seeds';

  @override
  String get catAccessory => 'Accessories';

  @override
  String get fertForm => 'Form';

  @override
  String get fertFormLiquid => 'Liquid';

  @override
  String get fertFormGranules => 'Granules';

  @override
  String get fertFormSticks => 'Sticks';

  @override
  String get fertFormSolublePowder => 'Soluble powder';

  @override
  String get fertFormFoliar => 'Foliar';

  @override
  String get fertFormOther => 'Other';

  @override
  String get fertOrigin => 'Origin';

  @override
  String get fertOriginMineral => 'Mineral';

  @override
  String get fertOriginOrganic => 'Organic';

  @override
  String get fertOriginOrganomineral => 'Organo-mineral';

  @override
  String get fertNpk => 'NPK';

  @override
  String get fertNpkPercent => 'NPK (%)';

  @override
  String get unit => 'Unit';

  @override
  String get unitPieces => 'pieces';

  @override
  String get lowThreshold => 'Low stock threshold';

  @override
  String get lowStock => 'Low stock';

  @override
  String remaining(String amount) {
    return '$amount left';
  }

  @override
  String get noInventoryTitle => 'Empty inventory';

  @override
  String get noInventorySubtitle => 'Fertilisers, soils, pots, tools…';

  @override
  String get deleteItem => 'Delete item';

  @override
  String lowStockItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items running low',
      one: '1 item running low',
    );
    return '$_temp0';
  }

  @override
  String get calendarTitle => 'Calendar';

  @override
  String get agenda => 'Agenda';

  @override
  String get month => 'Month';

  @override
  String get noEventsTitle => 'Nothing planned';

  @override
  String get noEventsSubtitle => 'Upcoming care will show up here.';

  @override
  String get projected => 'planned';

  @override
  String get today => 'Today';

  @override
  String get measurementsTitle => 'Measurements';

  @override
  String get addMeasurement => 'Add a measurement';

  @override
  String sinceFirst(String delta, String date) {
    return '$delta since $date';
  }

  @override
  String get qrCode => 'QR code';

  @override
  String get qrHint => 'When scanned, this code opens the plant\'s page.';

  @override
  String get scan => 'Scan';

  @override
  String get quickActionScan => 'Scan a label';

  @override
  String get scanHint => 'Point at a plant\'s QR code.';

  @override
  String get unknownQr => 'Unknown QR code.';

  @override
  String get shareQr => 'Share';

  @override
  String get printLabels => 'PDF labels';

  @override
  String get labels => 'Labels';

  @override
  String get cameraPermission => 'Allow camera access in Settings.';

  @override
  String get identify => 'Identify';

  @override
  String get identifying => 'Analyzing…';

  @override
  String get identifyTitle => 'Species';

  @override
  String get identifyHint => 'Species suggestions, to confirm';

  @override
  String get searchOnline => 'Search online';

  @override
  String get identifyAnotherPhoto => 'Add a photo';

  @override
  String get identifyAnotherPhotoHint =>
      'Add a leaf, a flower or the whole plant to narrow it down.';

  @override
  String get identificationUncertainTitle => 'Uncertain identification';

  @override
  String get identificationUncertainBody =>
      'No species stands out clearly enough. Search online, or pick the species yourself if you recognise the plant.';

  @override
  String get identificationSuggestionsToCheck => 'Suggestions to check';

  @override
  String get identifyConfirmWithPhoto => 'Confirm with a photo';

  @override
  String get searchingOnline => 'Searching online…';

  @override
  String get suggestionsLocal =>
      'Iris results on your device · photo not uploaded';

  @override
  String get suggestionsRemote => 'Suggested online by Pl@ntNet';

  @override
  String identifyOnDevice(String name) {
    return 'Recognised by $name on the device. Choose the species';
  }

  @override
  String get identifyViaPlantNet =>
      'Recognised online by Pl@ntNet. Choose the species';

  @override
  String get identifyPhotoSource =>
      'Photos from Pl@ntNet and GBIF. Tap one to open the species page.';

  @override
  String get identifyNone => 'No reliable match.';

  @override
  String get identifyError =>
      'Couldn\'t identify. Check your connection and try again.';

  @override
  String get useThis => 'Use';

  @override
  String get identificationSettings => 'Identification';

  @override
  String identificationHint(String name) {
    return '$name recognises species directly on your device, without a network. When in doubt, the photo can be sent to Pl@ntNet.';
  }

  @override
  String get identificationEnabled => 'Identification enabled';

  @override
  String get identificationDisabled => 'Not configured';

  @override
  String get identificationFallback => 'Online fallback';

  @override
  String identificationFallbackHint(String name) {
    return 'When $name hesitates, the app sends the photo to Pl@ntNet. Off, everything stays on your device.';
  }

  @override
  String get irisFeedback => 'Sending identified photos';

  @override
  String irisFeedbackHint(String name) {
    return 'By naming a plant, you send its photos and the chosen name to train the next versions of $name. Only you can read them, and deleting your account erases them. Off, nothing leaves your device.';
  }

  @override
  String plantNet300kComparison(String name) {
    return 'Compare with $name';
  }

  @override
  String plantNet300kComparisonHint(String name, String iris) {
    return 'The app also runs your photos through $name, on your device, and shows its suggestions below those from $iris.';
  }

  @override
  String plantNet300kSection(String name) {
    return 'Suggestions from $name';
  }

  @override
  String plantNet300kNone(String name) {
    return '$name recognises no plant in these photos.';
  }

  @override
  String get irisFeedbackNeedsAccount => 'An account is needed to send photos.';

  @override
  String get irisFeedbackAskTitle => 'Sending identified photos';

  @override
  String irisFeedbackAskBody(String name) {
    return 'Your identification photos and the chosen name can train the next versions of $name. Only you will be able to read them, and deleting your account will erase them. You can change this choice in the settings.';
  }

  @override
  String get genusUncertainSpecies => 'Species uncertain';

  @override
  String modelMissing(String name) {
    return '$name unavailable on this device';
  }

  @override
  String get modelLoading => 'Loading the model…';

  @override
  String identificationStats(int local, int accepted, int remote) {
    return '$local analysed on your device, $accepted without sending; $remote sent online';
  }

  @override
  String onlineSearchesMonth(int used, int limit) {
    return '$used of $limit online searches this month.';
  }

  @override
  String get irisSection => 'The on-device model';

  @override
  String get irisTagline =>
      'Recognises species on your phone, without a network or an account.';

  @override
  String get irisSpeciesLabel => 'species';

  @override
  String get irisOfflineValue => 'offline';

  @override
  String get irisOfflineLabel => 'even on a plane';

  @override
  String confidence(int percent) {
    return '$percent%';
  }

  @override
  String get speciesSet => 'Species updated';

  @override
  String get compare => 'Compare';

  @override
  String get compareHint => 'Drag to compare.';

  @override
  String get before => 'Before';

  @override
  String get after => 'After';

  @override
  String get comparePickFirst => 'Pick two photos.';

  @override
  String get outdoor => 'Outdoor';

  @override
  String get outdoorHint =>
      'Balcony, garden or greenhouse: the weather is taken into account.';

  @override
  String get weather => 'Weather';

  @override
  String get weatherHint =>
      'For your outdoor plants: rain that has fallen counts as watering, forecast rain postpones it, frost and heat are flagged (Open-Meteo).';

  @override
  String get weatherPlace => 'Place';

  @override
  String get weatherSearchHint => 'City…';

  @override
  String get weatherNone => 'No place';

  @override
  String get weatherRemove => 'Remove place';

  @override
  String get weatherNoResults => 'No place found.';

  @override
  String get weatherRainTitle => 'Rain today';

  @override
  String weatherRainSkip(String names) {
    return 'Watering of $names can wait.';
  }

  @override
  String get postpone => 'Postpone';

  @override
  String postponedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count waterings postponed to tomorrow',
      one: '1 watering postponed to tomorrow',
    );
    return '$_temp0';
  }

  @override
  String get condClear => 'Clear sky';

  @override
  String get condPartlyCloudy => 'Partly cloudy';

  @override
  String get condCloudy => 'Cloudy';

  @override
  String get condFog => 'Fog';

  @override
  String get condDrizzle => 'Drizzle';

  @override
  String get condRain => 'Rain';

  @override
  String get condSnow => 'Snow';

  @override
  String get condThunderstorm => 'Thunderstorm';

  @override
  String rainChance(int percent) {
    return '$percent% rain';
  }

  @override
  String get dataSection => 'Data';

  @override
  String get exportData => 'Export my data';

  @override
  String get exportHint =>
      'A ZIP file containing your plants, history, inventory, settings and photos.';

  @override
  String get exporting => 'Preparing export…';

  @override
  String get exportError => 'Export failed. Try again.';

  @override
  String get play => 'Play';

  @override
  String get timelapseHint => 'Tap to pause.';

  @override
  String notifLowStockOne(String name) {
    return '$name: low stock.';
  }

  @override
  String notifLowStockMany(int count) {
    return '$count items low on stock.';
  }

  @override
  String get accountTitle => 'Account';

  @override
  String get signIn => 'Sign in';

  @override
  String get signInWithAppleId => 'With your Apple ID';

  @override
  String get signInHint =>
      'An account backs up your data, syncs it across devices and lets you share a garden.';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutConfirm => 'Your data stays on this phone.';

  @override
  String get signedInAs => 'Signed in';

  @override
  String get syncNow => 'Sync now';

  @override
  String syncIdle(String time) {
    return 'Up to date · $time';
  }

  @override
  String get syncNever => 'Not synced yet';

  @override
  String syncPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pending changes',
      one: '1 pending change',
    );
    return '$_temp0';
  }

  @override
  String get syncOffline => 'Offline · will resume automatically';

  @override
  String get syncError => 'Sync error';

  @override
  String syncUnknownColumns(String columns) {
    return 'Columns unknown to the server: $columns';
  }

  @override
  String get syncSyncing => 'Syncing…';

  @override
  String get authError => 'Couldn\'t sign in. Try again in a moment.';

  @override
  String get appleUnavailable =>
      'Apple sign-in is available on iPhone and iPad.';

  @override
  String get synchronization => 'Sync';

  @override
  String get membersTitle => 'Members';

  @override
  String get shareGarden => 'Share the garden';

  @override
  String get inviteMember => 'Invite';

  @override
  String get inviteHint =>
      'The person must already have an Auxine account with this address.';

  @override
  String get roleOwner => 'Owner';

  @override
  String get roleMember => 'Member';

  @override
  String get roleViewer => 'View only';

  @override
  String get invited => 'Invitation sent';

  @override
  String get inviteError => 'This address has no account yet.';

  @override
  String get removeMember => 'Remove from garden';

  @override
  String get readOnlyHint => 'You\'re viewing this garden in read-only mode.';

  @override
  String byUser(String name) {
    return 'by $name';
  }

  @override
  String get you => 'you';

  @override
  String get diagnosisTitle => 'Diagnosis';

  @override
  String get diagnosisHint =>
      'Photograph the leaves, the stem and the soil, close up then whole. The results are indicative only.';

  @override
  String get diagnosisMoreBelow => 'Below: symptoms and observations';

  @override
  String get diagnosisSymptomsHint => 'What you noticed…';

  @override
  String get diagnosisNeedsPhoto => 'One photo at least.';

  @override
  String get diagnosisNeedsSymptoms => 'What you noticed, even in a few words.';

  @override
  String get diagnosisChecks => 'Observations';

  @override
  String get diagnosisChecksHint =>
      'Optional: add what the photo cannot show to sharpen the analysis.';

  @override
  String get diagnosisSoil => 'Soil';

  @override
  String get diagnosisSoilDry => 'Dry';

  @override
  String get diagnosisSoilMoist => 'Damp';

  @override
  String get diagnosisSoilSoggy => 'Soaked';

  @override
  String get diagnosisRoots => 'Roots';

  @override
  String get diagnosisRootsFirm => 'Firm and pale';

  @override
  String get diagnosisRootsSoft => 'Brown or soft';

  @override
  String get diagnosisRootsCrowded => 'Cramped';

  @override
  String get diagnosisLightDirect => 'Direct sun';

  @override
  String get diagnosisLightBright => 'Bright, no direct sun';

  @override
  String get diagnosisLightDim => 'Low';

  @override
  String get diagnosisBugs => 'Insects';

  @override
  String get diagnosisBugsNone => 'None seen';

  @override
  String get diagnosisBugsOnPlant => 'On the plant';

  @override
  String get diagnosisBugsInSoil => 'In the soil';

  @override
  String get diagnosisSymptoms => 'Symptoms';

  @override
  String get diagnosisAround => 'Around the plant';

  @override
  String get diagnosisPhotosFull => 'Three photos at most.';

  @override
  String get diagnosisRemovePhoto => 'Remove this photo';

  @override
  String get diagnosisFinding => 'Finding';

  @override
  String get diagnosisNothingWrong => 'Nothing wrong';

  @override
  String get diagnosisNatural => 'Normal phenomenon';

  @override
  String get analyze => 'Analyze';

  @override
  String get analyzing => 'Analyzing…';

  @override
  String get diagnosisError =>
      'Couldn\'t analyze. Check your connection and try again.';

  @override
  String get diagnosisRefused => 'This photo could not be analysed.';

  @override
  String get diagnosisUnauthorized =>
      'Diagnosis is unavailable right now. Try again later.';

  @override
  String get diagnosisBusy =>
      'The analysis service is not answering. Try again in a moment.';

  @override
  String get diagnosisUnreadable =>
      'The analysis did not go through. Try again.';

  @override
  String get diagnosisUncertain =>
      'The photos are not enough to conclude. Check the leads below.';

  @override
  String get diagnosisAnotherPhotoHint =>
      'One more photo would sharpen the analysis.';

  @override
  String get diagnosisQuestionsHint => 'What is missing to decide.';

  @override
  String get diagnosisAnswerHint => 'Answer…';

  @override
  String get diagnosisAnswerAgain => 'Run the analysis again';

  @override
  String get diagnosisAnswersNoted => 'Answers given';

  @override
  String diagnosisAnotherPhotoView(String view) {
    return 'To photograph: $view.';
  }

  @override
  String get diagnosisAnotherPhoto => 'Add a photo';

  @override
  String get diagnosisViewLeafCloseup => 'a leaf up close';

  @override
  String get diagnosisViewLeafUnderside => 'the underside of a leaf';

  @override
  String get diagnosisViewWholePlant => 'the whole plant';

  @override
  String get diagnosisViewStemBase => 'the base of the stem';

  @override
  String get diagnosisViewSoilRoots => 'the soil at the base';

  @override
  String get possibleCauses => 'Possible causes';

  @override
  String get causesHint => 'Ranked by likelihood, to confirm.';

  @override
  String get likelihoodLikely => 'Likely';

  @override
  String get likelihoodPossible => 'Possible';

  @override
  String get likelihoodUnlikely => 'Less likely';

  @override
  String get urgentHint => 'Needs quick attention';

  @override
  String get saveToJournal => 'Save to journal';

  @override
  String get markWatch => 'Mark as “keep an eye”';

  @override
  String get diagnosisSettings => 'Diagnosis';

  @override
  String get diagnosisSettingsHint =>
      'Your photos are analysed by a model hosted in Switzerland (Infomaniak AI Services). They leave only when you start an analysis, and are not kept.';

  @override
  String get diagnosisEnabled => 'Diagnosis enabled';

  @override
  String get diagnosisUnavailable => 'Diagnosis unavailable';

  @override
  String get addPhotos => 'Add photos';

  @override
  String photosCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos',
      one: '1 photo',
    );
    return '$_temp0';
  }

  @override
  String get diagnosisSaved => 'Diagnosis added to the journal';

  @override
  String get diagnosisEntry => 'Diagnosis';

  @override
  String get diagnosisOpen => 'See the full diagnosis';

  @override
  String get diagnosisSymptomsNoted => 'Reported symptoms';

  @override
  String diagnosisMoreCauses(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more leads',
      one: '1 more lead',
    );
    return '$_temp0';
  }

  @override
  String get speciesInfo => 'Species';

  @override
  String get speciesSource =>
      'Source: GBIF — Global Biodiversity Information Facility';

  @override
  String get speciesCommonNames => 'Common names';

  @override
  String get speciesFamily => 'Family';

  @override
  String get speciesOrder => 'Order';

  @override
  String get speciesGenus => 'Genus';

  @override
  String get speciesStatus => 'Status';

  @override
  String get speciesOpenGbif => 'View on GBIF';

  @override
  String get speciesNotFound => 'Species not found in GBIF.';

  @override
  String get speciesLoading => 'Searching GBIF…';

  @override
  String get speciesPhotos => 'Observations';

  @override
  String speciesPhotoCredit(String author, String license) {
    return '$author · $license';
  }

  @override
  String get speciesSuggestions => 'Suggestions';

  @override
  String get speciesUseName => 'Use this name';

  @override
  String get speciesStatusAccepted => 'Accepted name';

  @override
  String get speciesStatusSynonym => 'Synonym';

  @override
  String get speciesPickerTitle => 'Choose a species';

  @override
  String get speciesSearchHint => 'Common name, Latin name, family…';

  @override
  String get speciesInGarden => 'In your garden';

  @override
  String get speciesCommonList => 'Common species';

  @override
  String get speciesGbifResults => 'All species (GBIF)';

  @override
  String speciesGbifCount(int count) {
    return '$count matching species';
  }

  @override
  String speciesUseText(String name) {
    return 'Use “$name”';
  }

  @override
  String get speciesNoResults => 'No species found';

  @override
  String get speciesOffline =>
      'The full list needs a connection. Common species stay available.';

  @override
  String get speciesBrowse => 'Full list';

  @override
  String get speciesCatAll => 'All';

  @override
  String get speciesCatIndoor => 'Houseplants';

  @override
  String get speciesCatSucculent => 'Succulents';

  @override
  String get speciesCatHerb => 'Herbs';

  @override
  String get speciesCatVegetable => 'Vegetables';

  @override
  String get speciesCatFruit => 'Fruit';

  @override
  String get speciesCatFlower => 'Flowers';

  @override
  String get speciesCatTree => 'Trees and shrubs';

  @override
  String get gardenTasks => 'Tasks';

  @override
  String get tasks => 'Tasks';

  @override
  String get newTask => 'New task';

  @override
  String get editTask => 'Edit task';

  @override
  String get taskTitleHint => 'Title';

  @override
  String get taskDescriptionHint => 'Details (optional)';

  @override
  String get taskPlant => 'Plant';

  @override
  String get taskNoPlant => 'No plant';

  @override
  String get taskDue => 'Due';

  @override
  String get taskNoDue => 'No date';

  @override
  String get taskTime => 'Time';

  @override
  String get taskAllDay => 'All day';

  @override
  String get taskRecurrence => 'Repeat';

  @override
  String get taskRecurrenceNone => 'None';

  @override
  String get taskEvery => 'Every';

  @override
  String recurrenceLabel(String unit, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Every $count hours',
      one: 'Every hour',
    );
    String _temp1 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Every $count days',
      one: 'Every day',
    );
    String _temp2 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Every $count weeks',
      one: 'Every week',
    );
    String _temp3 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Every $count months',
      one: 'Every month',
    );
    String _temp4 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Every $count years',
      one: 'Every year',
    );
    String _temp5 = intl.Intl.selectLogic(unit, {
      'hours': '$_temp0',
      'days': '$_temp1',
      'weeks': '$_temp2',
      'months': '$_temp3',
      'years': '$_temp4',
      'other': '—',
    });
    return '$_temp5';
  }

  @override
  String get unitHours => 'hours';

  @override
  String get unitDays => 'days';

  @override
  String get unitWeeks => 'weeks';

  @override
  String get unitMonths => 'months';

  @override
  String get unitYears => 'years';

  @override
  String get taskFilterOpen => 'Open';

  @override
  String get taskFilterOverdue => 'Overdue';

  @override
  String get taskFilterDone => 'Done';

  @override
  String get taskSectionOverdue => 'Overdue';

  @override
  String get taskSectionToday => 'Today';

  @override
  String get taskSectionUpcoming => 'Upcoming';

  @override
  String get taskSectionNoDate => 'No date';

  @override
  String get noTasksTitle => 'No tasks';

  @override
  String get noTasksSubtitle =>
      'Sowing, cleaning the greenhouse, ordering soil…';

  @override
  String get noDoneTasks => 'Nothing done yet';

  @override
  String taskDoneToast(String title) {
    return '$title · Done';
  }

  @override
  String taskNextToast(String title, String date) {
    return '$title · Next $date';
  }

  @override
  String get taskDeleted => 'Task deleted';

  @override
  String get deleteTask => 'Delete task';

  @override
  String get reopenTask => 'Reopen';

  @override
  String taskDoneOn(String date) {
    return 'Done $date';
  }

  @override
  String taskOverdueSince(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days overdue',
      one: '1 day overdue',
    );
    return '$_temp0';
  }

  @override
  String taskDueIn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'In $count days',
      one: 'Tomorrow',
    );
    return '$_temp0';
  }

  @override
  String get tasksTodayTitle => 'Tasks';

  @override
  String get choosePlant => 'Choose a plant';

  @override
  String notifTasksOne(String title) {
    return 'Task: $title.';
  }

  @override
  String notifTasksMany(int count, String titles) {
    return '$count tasks to do: $titles.';
  }

  @override
  String notifTaskDue(String title) {
    return 'To do: $title';
  }

  @override
  String get careGuide => 'Care guide';

  @override
  String get careGuideSubtitle =>
      'When to water, how much light, what to watch for.';

  @override
  String get careHowTo => 'How to care for it';

  @override
  String get careWatering => 'Watering';

  @override
  String get careLight => 'Light';

  @override
  String get careHumidity => 'Humidity';

  @override
  String get careTemperature => 'Temperature';

  @override
  String get careSoil => 'Soil';

  @override
  String get careFertilizing => 'Fertilizer';

  @override
  String get careRepotting => 'Repotting';

  @override
  String get careToxicity => 'Toxicity';

  @override
  String get careDifficulty => 'Difficulty';

  @override
  String get carePropagation => 'Propagation';

  @override
  String get careSupport => 'Support';

  @override
  String get careSupportMossPole => 'Moss pole';

  @override
  String get careSupportStake => 'Stake';

  @override
  String get careSupportTrellis => 'Trellis';

  @override
  String get careSupportMossPoleCare =>
      'Dampen the pole at every watering: the aerial roots take hold in it.';

  @override
  String get careSupportStakeCare => 'Tie the stem loosely as it climbs.';

  @override
  String get careSupportTrellisCare => 'Guide the stems as they grow.';

  @override
  String get careIssues => 'Watch out for';

  @override
  String get careKnownProblems => 'Known problems on this plant';

  @override
  String get careKnownProblemsNote =>
      'Reported on this species or related ones.';

  @override
  String get careLeafSigns => 'Leaf signs';

  @override
  String get careLeafSignsNote =>
      'What a leaf shows, and what usually explains it.';

  @override
  String get leafSignPaling => 'Leaves turning pale';

  @override
  String get leafSignYellowing => 'Yellow leaves';

  @override
  String get leafSignScorched => 'Scorched leaves';

  @override
  String get leafSignSpots => 'Spots in the middle of the leaf';

  @override
  String get leafSignBrownTips => 'Brown tips and edges';

  @override
  String get leafSignStunted => 'Leaves that stop growing';

  @override
  String get leafSignDrooping => 'Limp leaves';

  @override
  String get leafSignFalling => 'Leaves dropping';

  @override
  String get leafSignSticky => 'Sticky leaves';

  @override
  String get leafCauseTooMuchSun => 'Too much direct sun';

  @override
  String get leafCauseNotEnoughLight => 'Not enough light';

  @override
  String get leafCauseOverwatering => 'Watering too often';

  @override
  String get leafCauseUnderwatering => 'Soil left dry for too long';

  @override
  String get leafCauseDryAir => 'Air too dry';

  @override
  String get leafCauseColdDraught => 'Cold or a draught';

  @override
  String get leafCauseHardWater => 'Hard water, or fertilizer too strong';

  @override
  String get leafCausePoorSoil => 'Exhausted potting mix';

  @override
  String get leafCausePotBound => 'Roots cramped in the pot';

  @override
  String get leafCauseDamagedRoots => 'Roots damaged by standing water';

  @override
  String get leafCauseLeafPests => 'Feeding marks from spider mites or thrips';

  @override
  String get leafCauseHoneydewPests =>
      'Mealybugs or aphids, on the plant or above it';

  @override
  String get leafCauseSootyMould =>
      'Sooty mould, the black that grows on honeydew';

  @override
  String get leafCauseLeafFungus => 'A fungus or a bacterium on the leaf';

  @override
  String get leafCauseWetLeaves => 'Water left on the foliage';

  @override
  String get leafCauseRecentMove => 'A recent move or repotting';

  @override
  String get leafCauseOldLeaves => 'Lower leaves ageing';

  @override
  String get leafCauseWinterRest => 'Winter rest';

  @override
  String get problemKindDisorder => 'Disorder';

  @override
  String get problemKindPest => 'Pest';

  @override
  String get problemKindDisease => 'Disease';

  @override
  String get problemKindCondition => 'Condition';

  @override
  String get problemKindDisorders => 'Disorders';

  @override
  String get problemKindPests => 'Pests';

  @override
  String get problemKindDiseases => 'Diseases';

  @override
  String get problemKindConditions => 'Conditions';

  @override
  String get careTips => 'Tips';

  @override
  String careEveryDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Every $count days',
      one: 'Every day',
    );
    return '$_temp0';
  }

  @override
  String careWateringNow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Every $count days right now',
      one: 'Every day right now',
    );
    return '$_temp0';
  }

  @override
  String careWateringSeasons(int summer, int winter) {
    return '$summer days in season · $winter days in winter';
  }

  @override
  String get careDryDownAlwaysMoist => 'Keep the soil moist';

  @override
  String get careDryDownSurfaceDry => 'Let the surface dry';

  @override
  String get careDryDownTopQuarterDry => 'Let the top quarter dry';

  @override
  String get careDryDownHalfDry => 'Let it dry halfway';

  @override
  String get careDryDownMostlyDry => 'Let it dry almost through';

  @override
  String get careDryDownFullyDry => 'Let it dry out completely';

  @override
  String careFertilizeSeason(String from, String to) {
    return 'from $from to $to';
  }

  @override
  String get careNoFertilizer => 'No fertilizer needed';

  @override
  String careRepotMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Every $count months',
      one: 'Every month',
    );
    return '$_temp0';
  }

  @override
  String careRepotYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Every $count years',
      one: 'Every year',
    );
    return '$_temp0';
  }

  @override
  String get careRepotNone => 'No repotting (grown as an annual)';

  @override
  String get carePotSnug => 'Better snug';

  @override
  String get carePotRoomy => 'A wide pot';

  @override
  String get carePotSnugNote =>
      'A root through the drainage hole is not enough: repot once the root ball is a solid mass, or once water no longer soaks in.';

  @override
  String get carePotSteadyNote =>
      'Repot once roots come through the drainage hole and circle the bottom of the pot.';

  @override
  String get carePotRoomyNote =>
      'Repot as soon as the roots reach the side of the pot: cramped, it stops growing.';

  @override
  String get carePotDormantNote =>
      'Repot when growth restarts, at the end of the rest, not because a root is coming out.';

  @override
  String careTempIdeal(int min, int max) {
    return '$min to $max °C';
  }

  @override
  String careTempMin(int min) {
    return 'Avoid below $min °C';
  }

  @override
  String get careEnvTitle => 'Ideal spot';

  @override
  String careEnvHumidity(int min, int max) {
    return '$min–$max %';
  }

  @override
  String careEnvTempRange(int min, int max) {
    return '$min–$max °C';
  }

  @override
  String careEnvTempMin(int min) {
    return '≥ $min °C';
  }

  @override
  String careEnvSemanticTemp(int min, int max) {
    return 'temperature from $min to $max degrees';
  }

  @override
  String careEnvSemanticTempMin(int min) {
    return 'temperature above $min degrees';
  }

  @override
  String get careAirflow => 'Draughts';

  @override
  String get careAirflowSheltered => 'Sheltered from draughts';

  @override
  String get careAirflowNormal => 'Ordinary air';

  @override
  String get careAirflowVentilated => 'Well-ventilated air';

  @override
  String get careLightShade => 'Shade';

  @override
  String get careLightLow => 'Low light';

  @override
  String get careLightIndirect => 'Indirect light';

  @override
  String get careLightBright => 'Bright indirect light';

  @override
  String get careLightSome => 'A few hours of sun';

  @override
  String get careLightFull => 'Full sun';

  @override
  String careLightFloor(String value) {
    return 'Holds down to $value';
  }

  @override
  String careLightLamp(int min, int max, int hours) {
    return 'Under a lamp · full-spectrum LED, $min to $max µmol/m²/s, $hours h a day';
  }

  @override
  String careLightLampDli(int min, int max) {
    return 'That is $min to $max mol/m²/day reaching the leaves.';
  }

  @override
  String get careHumidityLow => 'Dry air is fine';

  @override
  String get careHumidityAverage => 'Average humidity';

  @override
  String get careHumidityHigh => 'Humid air';

  @override
  String careHumidityRange(int min, int max) {
    return '$min to $max % air humidity';
  }

  @override
  String get careHumidityLowDetail =>
      'It copes well with the dry air of a home. Humidity kept higher than that harms it.';

  @override
  String get careHumidityAverageDetail =>
      'The ordinary air of a home suits it. Away from a radiator in winter, leaf tips stay green.';

  @override
  String get careHumidityHighDetail =>
      'The dry air of a heated home harms it: the air has to be kept humid.';

  @override
  String get careHumidityMethodMist => 'Mist the leaves.';

  @override
  String get careHumidityMethodHumidifier => 'An air humidifier.';

  @override
  String get careHumidityMethodTray =>
      'A tray of damp clay pebbles, or plants grouped together.';

  @override
  String get careHumidityMethodTerrarium =>
      'Under glass: terrarium, cloche or jar.';

  @override
  String get careDifficultyEasy => 'Easy';

  @override
  String get careDifficultyMedium => 'Moderate';

  @override
  String get careDifficultyDemanding => 'Demanding';

  @override
  String get careToxicSafe => 'No known hazard';

  @override
  String get careToxicMild => 'Mildly irritating';

  @override
  String get careToxicToxic => 'Toxic if eaten';

  @override
  String get careToxicUnknown => 'Toxicity unknown';

  @override
  String get careToxicPets => 'Keep away from pets and children.';

  @override
  String get careToxicityFromSpecies => 'Verified for this species';

  @override
  String careToxicityFromGenus(String name) {
    return 'Genus $name · not verified for this species';
  }

  @override
  String careToxicityFromFamily(String name) {
    return 'Family $name · not verified for this species';
  }

  @override
  String careToxicitySource(String name) {
    return 'Source: $name';
  }

  @override
  String get careSoilStandard => 'All-purpose potting mix';

  @override
  String get careSoilDraining => 'Free-draining mix';

  @override
  String get careSoilCactus => 'Cactus and succulent mix';

  @override
  String get careSoilOrchid => 'Orchid bark';

  @override
  String get careSoilAcidic => 'Ericaceous (acidic) soil';

  @override
  String get careSoilRich => 'Rich compost-based mix';

  @override
  String get careSoilNone => 'No soil at all';

  @override
  String get careGrowthMedium => 'Growing medium';

  @override
  String get careMediumTerrestrial => 'Terrestrial';

  @override
  String get careMediumEpiphytic => 'Epiphytic';

  @override
  String get careMediumLithophytic => 'Lithophytic';

  @override
  String get careMediumAquatic => 'Aquatic';

  @override
  String get careMediumSemiAquatic => 'Semi-aquatic';

  @override
  String get careMediumTerrestrialNote => 'It grows in soil.';

  @override
  String get careMediumEpiphyticNote =>
      'It grows on a support, without soil: bark, moss, or nothing.';

  @override
  String get careMediumLithophyticNote =>
      'It grows on stone, its roots in the cracks.';

  @override
  String get careMediumAquaticNote => 'Its roots live in water.';

  @override
  String get careMediumSemiAquaticNote =>
      'It lives in waterlogged ground, at the water\'s edge.';

  @override
  String get careWater => 'Water';

  @override
  String get careWaterTolerant => 'Tap water';

  @override
  String get careWaterSensitive => 'Low-lime water';

  @override
  String get careWaterStrict => 'Lime-free water';

  @override
  String get careWaterTolerantNote => 'Lime has no effect.';

  @override
  String get careWaterSensitiveNote => 'Lime browns its leaf tips.';

  @override
  String get careWaterFluorideSensitive =>
      'Tap-water fluoride browns its leaf tips: rainwater or osmosis.';

  @override
  String get careWaterStrictNote => 'Lime harms it, even in small amounts.';

  @override
  String get careWaterTypes => 'Water types';

  @override
  String get careWaterTypesNote =>
      'Tap water hardness changes from one town to the next; the supplier\'s annual analysis gives it.';

  @override
  String get careWaterBest => 'Recommended';

  @override
  String get careWaterOk => 'Suitable';

  @override
  String get careWaterCaution => 'With caution';

  @override
  String get careWaterAvoid => 'To avoid';

  @override
  String get careWaterTap => 'Tap water';

  @override
  String get careWaterTapNote =>
      'Mains water as it comes. Its hardness depends on the town.';

  @override
  String get careWaterTapRisk =>
      'Lime builds up in the potting mix and raises its pH. Letting the water stand drives off the chlorine, not the lime.';

  @override
  String get careWaterRain => 'Rainwater';

  @override
  String get careWaterRainNote => 'Soft, lime-free, slightly acidic.';

  @override
  String get careWaterRainRisk =>
      'Collected off a roof, it carries dust and droppings; an uncovered barrel turns green. Let the first minutes of rain run off, and keep the barrel covered.';

  @override
  String get careWaterFiltered => 'Filtered water';

  @override
  String get careWaterFilteredNote =>
      'A filter jug removes the chlorine and part of the lime.';

  @override
  String get careWaterFilteredRisk =>
      'How much it holds back depends on the cartridge, and a spent cartridge holds back nothing. The lime is never removed entirely.';

  @override
  String get careWaterOsmosis => 'Reverse osmosis water';

  @override
  String get careWaterOsmosisNote => 'Almost free of minerals, like rainwater.';

  @override
  String get careWaterOsmosisRisk =>
      'It brings no nutrients at all: fertilizer becomes the only source. For an ordinary plant, a third of tap water balances it out.';

  @override
  String get careWaterDemineralized => 'Demineralized water';

  @override
  String get careWaterDemineralizedNote =>
      'Sold for irons, it matches osmosis water as long as it is pure.';

  @override
  String get careWaterDemineralizedRisk =>
      'Some bottles hold an anti-scale additive or a fragrance: read the label. Like osmosis water, it brings no nutrients.';

  @override
  String get careWaterCondensate => 'Air conditioner water';

  @override
  String get careWaterCondensateNote =>
      'The condensate from an air conditioner or a dehumidifier, distilled by the machine.';

  @override
  String get careWaterCondensateRisk =>
      'It has run over a heat exchanger and through a tray where dust and bacteria build up, and may carry traces of metals. Keep it for ornamental plants, from a clean appliance, never on anything edible.';

  @override
  String get careWaterSoftened => 'Softened water';

  @override
  String get careWaterSoftenedNote =>
      'A resin softener swaps the lime for sodium.';

  @override
  String get careWaterSoftenedRisk =>
      'Sodium builds up in the potting mix, damages the roots and closes up the structure of the soil. The untreated tap, upstream of the softener, stays the right one.';

  @override
  String get careSoilMixStandard =>
      'Lightened with 20 % perlite, so water runs through.';

  @override
  String get careSoilMixDraining =>
      '50 % potting mix, 25 % perlite, 25 % coarse sand or lava rock.';

  @override
  String get careSoilMixCactus =>
      '30 % potting mix, 70 % lava rock, pumice or coarse sand.';

  @override
  String get careSoilMixOrchid =>
      'Medium pine bark, 10 % perlite, a little sphagnum; never potting soil.';

  @override
  String get careSoilMixAcidic =>
      'Lightened with 25 % pine bark, no lime, no compost.';

  @override
  String get careSoilMixRich => '40 % potting mix, 40 % compost, 20 % perlite.';

  @override
  String get careSoilMixNone =>
      'No growing medium: the roots live in air or in water.';

  @override
  String careSoilFree(String water, String pon) {
    return 'In water: $water · In pon: $pon';
  }

  @override
  String get careSoilFreeYes => 'yes';

  @override
  String get careSoilFreeNo => 'no';

  @override
  String get careSoilFreeCuttings => 'cuttings only';

  @override
  String get careFertBalanced =>
      'Balanced houseplant fertilizer, at half strength.';

  @override
  String get careFertFoliage =>
      'High-nitrogen fertilizer, the one for foliage.';

  @override
  String get careFertFlowering =>
      'High-potash fertilizer, the one for flowers.';

  @override
  String get careFertCactus => 'Cactus fertilizer, low in nitrogen.';

  @override
  String get careFertOrchid => 'Orchid fertilizer, well diluted.';

  @override
  String get careFertAcidic => 'Ericaceous fertilizer, lime-free.';

  @override
  String get careFertCitrus =>
      'Citrus fertilizer, high in nitrogen and trace elements.';

  @override
  String get careFertVegetable => 'Tomato fertilizer, high in potash.';

  @override
  String get careCalciumAvoid =>
      'Calcium: none at all, and rainwater; lime turns its leaves yellow.';

  @override
  String get careCalciumWelcome =>
      'Calcium: hard water is safe; crushed eggshells at repotting add some.';

  @override
  String get careCalciumNeeded =>
      'Calcium: a steady supply keeps blossom end rot away.';

  @override
  String get careGreenhouse => 'Under glass';

  @override
  String get careGreenhouseWarmHumid => 'Warmth and humid air';

  @override
  String get careGreenhouseWarmLight => 'Warmth and light';

  @override
  String get careGreenhouseWarmDry => 'Warmth, light and dry air';

  @override
  String get careGreenhouseGrowth =>
      'Held all year, these conditions speed up growth: watering and feeding come round just as fast.';

  @override
  String get careGreenhouseHold =>
      'Hold the humidity range by day, let it fall at night, and keep the air moving.';

  @override
  String get careGreenhouseAir =>
      'Air it every day: still air rots plants from dry habitats.';

  @override
  String get careGreenhouseEarly =>
      'In a cold frame or a small greenhouse, sowings start 4 to 6 weeks earlier.';

  @override
  String get careBloom => 'Flowering';

  @override
  String careSeasonRange(String from, String to) {
    return 'From $from to $to';
  }

  @override
  String get careBloomOutdoors => 'Rarely indoors';

  @override
  String get careBloomChillBulb => 'A chilled bulb';

  @override
  String get careBloomChillBulbNote =>
      'Allow 10 to 15 weeks between 5 and 9 °C in the dark before bringing the pot back to warmth and light.';

  @override
  String get careBloomFertilizer => 'A bloom fertilizer';

  @override
  String get careBloomFertilizerNote =>
      'As soon as buds form, switch to a bloom fertilizer, richer in potash than the one for foliage.';

  @override
  String get careBloomMaturity => 'Some age';

  @override
  String get careBloomMaturityNote =>
      'It only flowers from 3 or 4 years old: before that age, no condition will change anything.';

  @override
  String get careBloomDeadhead => 'Spent flowers cut';

  @override
  String get careBloomDeadheadNote =>
      'Cut the faded flowers as they go: with no seeds to form, the plant flowers again.';

  @override
  String get careBloomKeepSpike => 'A kept spike';

  @override
  String get careBloomKeepSpikeNote =>
      'While the spike stays green, leave it in place: it can flower again from a node lower down.';

  @override
  String get careBloomNoMove => 'A fixed spot';

  @override
  String get careBloomNoMoveNote =>
      'Once the buds are formed, stop moving it and stop turning it: the change makes them drop.';

  @override
  String get careBloomEvenWater => 'Even watering';

  @override
  String get careBloomEvenWaterNote =>
      'While the buds are forming, water regularly: a single dry spell is enough to make them drop.';

  @override
  String get careRest => 'Rest';

  @override
  String careRestStoreDarkTemp(int min, int max) {
    return 'Dry and dark, between $min and $max °C';
  }

  @override
  String careRestStoreTemp(int min, int max) {
    return 'Dry, between $min and $max °C';
  }

  @override
  String get careRestStoreDark => 'Dry and dark';

  @override
  String get careRestStorePlain => 'Dry';

  @override
  String get careRestNote =>
      'Let the leaves yellow and dry without cutting them, then stop watering. Bring the pot back to the light and water again at the end of this period.';

  @override
  String get careBloomCoolRest => 'A cool winter';

  @override
  String get careBloomCoolRestNote =>
      'To prepare for flowering, keep it at 10–12 °C for about 2 months and reduce watering sharply.';

  @override
  String get careBloomCoolNights => 'Cool nights';

  @override
  String get careBloomCoolNightsNote =>
      'In autumn, about 3 weeks with nights around 15 °C can encourage the flower spike to form.';

  @override
  String get careBloomShortDays => 'Short days';

  @override
  String get careBloomShortDaysNote =>
      'For about 6 weeks, nights of at least 12 hours of darkness trigger bud formation.';

  @override
  String get careBloomDrySpell => 'A dry spell';

  @override
  String get careBloomDrySpellNote =>
      'Reduce watering sharply for a few weeks, then resume gradually. This change can trigger flowering.';

  @override
  String get careBloomPotbound => 'A tight pot';

  @override
  String get careBloomPotboundNote =>
      'It often flowers better when its roots fill the pot. Avoid repotting too early.';

  @override
  String get careBloomBrightLight => 'More light';

  @override
  String get careBloomBrightLightNote =>
      'Flowering takes more light than growth: a very bright place, without harsh sun.';

  @override
  String get carePropCutting => 'Stem cutting';

  @override
  String get carePropLeaf => 'Leaf cutting';

  @override
  String get carePropDivision => 'Division';

  @override
  String get carePropOffsets => 'Offsets';

  @override
  String get carePropLayering => 'Layering';

  @override
  String get carePropSeed => 'Seed';

  @override
  String get carePropWater => 'Rooting in water';

  @override
  String get carePropTuber => 'Splitting tubers';

  @override
  String get careMatchSpecies => 'Species guide';

  @override
  String careMatchGenus(String name) {
    return '$name genus guide';
  }

  @override
  String careMatchFamily(String name) {
    return '$name family guide';
  }

  @override
  String get careMatchGeneric => 'General guidance';

  @override
  String get careMatchNote =>
      'These figures come from the botanical group, not the exact species. Set the species to refine them.';

  @override
  String get careDisclaimer =>
      'Indicative values, to be adapted to the light, the pot and the room air.';

  @override
  String get careApplyToSchedule => 'Apply to schedule';

  @override
  String get careScheduleApplied => 'Schedule updated';

  @override
  String careSuggestedIntervals(int water, int fertilize) {
    return 'Water every $water days, feed every $fertilize days';
  }

  @override
  String get careBadgeMist => 'Mist';

  @override
  String get careBadgeDormant => 'Winter rest';

  @override
  String get careBadgeOutdoor => 'Happy outdoors';

  @override
  String get careIssueOverwatering => 'Overwatering (soft, yellow leaves)';

  @override
  String get careIssueUnderwatering => 'Underwatering (drooping leaves)';

  @override
  String get careIssueRootRot => 'Root rot';

  @override
  String get careIssueSpiderMites => 'Spider mites (fine webbing)';

  @override
  String get careIssueThrips => 'Thrips (silvery leaves)';

  @override
  String get careIssueMealybugs => 'Mealybugs';

  @override
  String get careIssueScale => 'Scale insects';

  @override
  String get careIssueAphids => 'Aphids';

  @override
  String get careIssueFungusGnats => 'Fungus gnats';

  @override
  String get careIssueWhitefly => 'Whitefly';

  @override
  String get careIssueTrueBugs => 'True bugs';

  @override
  String get careIssueSlugs => 'Slugs and snails';

  @override
  String get careIssuePowderyMildew => 'Powdery mildew';

  @override
  String get careIssueGreyMould => 'Grey mould (Botrytis)';

  @override
  String get careIssueLeafSpot => 'Leaf spot';

  @override
  String get careIssueBlight => 'Blight';

  @override
  String get careIssueSunburn => 'Sunburn';

  @override
  String get careIssueDryTips => 'Dry brown leaf tips';

  @override
  String get careIssueLeafDrop => 'Leaf drop';

  @override
  String get careIssueEtiolation => 'Stretching from too little light';

  @override
  String get careIssueChlorosis => 'Chlorosis (pale leaves, green veins)';

  @override
  String get careIssueBlossomEndRot => 'Blossom end rot';

  @override
  String get careTipFingerTest =>
      'Push a finger in and water when the top 2 cm are dry.';

  @override
  String get careTipDrySoilFirst =>
      'Let the soil dry out completely between waterings.';

  @override
  String get careTipNeverDryOut => 'Never let the soil dry out completely.';

  @override
  String get careTipEvenWatering =>
      'Water evenly, as irregular watering splits the fruit.';

  @override
  String get careTipWaterAtBase => 'Water at the base, keeping the leaves dry.';

  @override
  String get careTipNoWaterOnLeaves =>
      'Keep water off the leaves, as droplets leave marks.';

  @override
  String get careTipBottomWatering =>
      'Water from below by standing the pot in water for 20 minutes.';

  @override
  String get careTipThirstyPlant =>
      'High water need: check the soil daily in summer.';

  @override
  String get careTipDroopSignal => 'Drooping leaves signal a lack of water.';

  @override
  String get careTipWinterDry => 'Keep it nearly dry through winter.';

  @override
  String get careTipWinterRest => 'Growth stops in winter: much less water.';

  @override
  String get careTipSummerDormant =>
      'Dormant in summer: very little water then.';

  @override
  String get careTipNoWaterWhileSplitting =>
      'Do not water while the leaves are renewing.';

  @override
  String get careTipOrchidSoak =>
      'Soak the pot for 10 minutes, then drain fully.';

  @override
  String get careTipSoakMount => 'Soak the whole plant, then let it air-dry.';

  @override
  String get careTipDryUpsideDown =>
      'After soaking, dry it upside down, as water in the centre rots it.';

  @override
  String get careTipWaterInTheCup =>
      'Fill the central cup and refresh the water weekly.';

  @override
  String get careTipNoSoil =>
      'It lives without soil, just resting on a holder.';

  @override
  String get careTipGreenRoots =>
      'Green roots mean hydrated. Silvery roots mean water it.';

  @override
  String get careTipHumidityTray =>
      'Stand the pot on a tray of damp clay pebbles.';

  @override
  String get careTipNoDirectSun =>
      'Keep it out of direct sun, which scorches the leaves.';

  @override
  String get careTipToleratesLowLight =>
      'It copes with a dim room but grows faster near a window.';

  @override
  String get careTipToleratesNeglect =>
      'Neglect does no harm: when in doubt, do not water.';

  @override
  String get careTipBrightForColor =>
      'The brighter the light, the stronger the colours.';

  @override
  String get careTipRotatePot =>
      'A quarter turn of the pot each week keeps the stem straight.';

  @override
  String get careTipHatesMoving =>
      'Keep one fixed spot: each move drops leaves.';

  @override
  String get careTipWipeLeaves => 'Wipe the leaves: dust blocks the light.';

  @override
  String get careTipTrimToBushOut =>
      'Trimming leggy stems makes the plant branch.';

  @override
  String get careTipMonsteraSupport =>
      'On a moss pole, the leaves get bigger and more split.';

  @override
  String get careTipShallowPot => 'A wide, shallow pot.';

  @override
  String get careTipLikesBeingPotbound =>
      'Flowering is better when snug: repot rarely.';

  @override
  String get careTipTrunkStoresWater =>
      'The swollen base stores water, so too little beats too much.';

  @override
  String get careTipPupsToShare => 'Pups detach to propagate or give away.';

  @override
  String get careTipKeepFlowerSpike =>
      'Do not cut a green flower spike, as it can rebloom on it.';

  @override
  String get careTipDarkForRebloom =>
      'To rebloom: six weeks of long, cool nights.';

  @override
  String get careTipNotADesertCactus =>
      'A forest cactus, not a desert one: shade and humid air.';

  @override
  String get careTipDeadheadFlowers =>
      'Removing spent flowers extends the bloom.';

  @override
  String get careTipPinchFlowers =>
      'Pinch off flower buds to keep the leaves tender.';

  @override
  String get careTipHarvestTop =>
      'Harvest from the top, above a pair of leaves.';

  @override
  String get careTipHarvestOutside =>
      'Pick the outer leaves and the centre keeps growing.';

  @override
  String get careTipStakeAndPrune => 'Stake it and pinch out the side shoots.';

  @override
  String get careTipPrunesInSpring =>
      'Prune in spring, never into old dry wood.';

  @override
  String get careTipPrunesAfterFlowering =>
      'Prune right after flowering to keep it compact.';

  @override
  String get careTipWinterPruning =>
      'Prune in winter, frost-free, while it sleeps.';

  @override
  String get careTipPruneAfterHarvest => 'Prune after harvest, not in spring.';

  @override
  String get careTipCutSpentCanes => 'Cut spent fruiting canes to the ground.';

  @override
  String get careTipTrimTwiceAYear =>
      'Two trims a year is enough, in June and late August.';

  @override
  String get careTipContainItsRoots =>
      'The rhizomes spread everywhere: in a pot, or behind a root barrier.';

  @override
  String get careTipMulchIt =>
      'Mulch the base for less watering and fewer weeds.';

  @override
  String get careTipAcidSoil => 'Acidic soil, not all-purpose compost.';

  @override
  String get careTipFeedsOnInsects =>
      'It feeds on insects: no fertilizer, and a poor soil.';

  @override
  String get careTipBlueNeedsAcid =>
      'Blue flowers need acidic soil; in lime they turn pink.';

  @override
  String get careTipCitrusFertilizer =>
      'Use a dedicated citrus feed all through the growing season.';

  @override
  String get careTipNoFertilizer =>
      'No feeding: rich soil weakens scent and shape.';

  @override
  String get careTipNoNitrogen =>
      'No nitrogen feed: the plant fixes its own nitrogen.';

  @override
  String get careTipLetFoliageDieBack =>
      'Let the foliage yellow in place, as it refuels the bulb.';

  @override
  String get careTipDiesBackInWinter =>
      'The foliage disappears in winter and returns in spring.';

  @override
  String get careTipSummerOutdoors =>
      'Move it outside for summer, in shade for the first days.';

  @override
  String get careTipWinterIndoors => 'Bring it in before the first frost.';

  @override
  String get careTipWinterShelter => 'Overwinter it in a cool, bright room.';

  @override
  String get careTipWinterCool => 'A cool (10–14 °C), bright winter.';

  @override
  String get careTipCoolerIsBetter =>
      'Better cool: keep it away from radiators.';

  @override
  String get careTipHardyOutdoors =>
      'Hardy enough to overwinter outdoors unprotected.';

  @override
  String get careTipShelterFromWind =>
      'Shelter it from wind, as the foliage tears easily.';

  @override
  String get careTipAirFlow =>
      'Air around the plant: still air favours disease.';

  @override
  String get careTipSpiderMiteWatch =>
      'Check under the leaves, where spider mites settle.';

  @override
  String get careTipSlugWatch =>
      'Protect the young shoots from slugs in spring.';

  @override
  String get careTipBoxMothWatch =>
      'Watch for box moth, whose caterpillars leave silk in the foliage.';

  @override
  String get careTipSapIrritant =>
      'Its sap irritates skin and eyes, so wear gloves to prune.';

  @override
  String get careTipVeryToxic =>
      'Every part is highly toxic, including the smoke if burned.';

  @override
  String get careTipSharpSpines => 'Sharp spines: away from walkways.';

  @override
  String get careTipSplitsAreNormal =>
      'Leaves split with age, which is normal and not a disease.';

  @override
  String get careTipDryToBloom => 'A little drought stress triggers flowering.';

  @override
  String get customFields => 'Custom fields';

  @override
  String get addCustomField => 'Add a field';

  @override
  String get editCustomField => 'Edit field';

  @override
  String get deleteCustomField => 'Delete field';

  @override
  String get fieldLabel => 'Field name';

  @override
  String get fieldLabelHint => 'Source, price, aspect…';

  @override
  String get fieldType => 'Type';

  @override
  String get fieldValue => 'Value';

  @override
  String get fieldTypeBool => 'Yes / no';

  @override
  String get fieldTypeInt => 'Whole number';

  @override
  String get fieldTypeDouble => 'Decimal number';

  @override
  String get fieldTypeText => 'Text';

  @override
  String get fieldTypeDate => 'Date';

  @override
  String get fieldEmpty => 'Not set';

  @override
  String get noCustomFields => 'No custom fields';

  @override
  String get fieldTemplates => 'Field templates';

  @override
  String get fieldTemplatesHint => 'Fields reusable across several plants.';

  @override
  String get newFieldTemplate => 'New template';

  @override
  String get noFieldTemplates => 'No templates';

  @override
  String get fieldTemplateInactive => 'Hidden';

  @override
  String get fieldFromTemplate => 'From a template';

  @override
  String get bulkSetField => 'Set a field';

  @override
  String bulkFieldApplied(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Field set on $count plants',
      one: 'Field set on 1 plant',
    );
    return '$_temp0';
  }

  @override
  String get confirmDeleteField => 'Delete this field and its value?';

  @override
  String get confirmDeleteTemplate =>
      'Delete this template? Fields already filled in are kept.';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get attachments => 'Documents';

  @override
  String get addAttachment => 'Add a document';

  @override
  String get noAttachments => 'No documents';

  @override
  String get noAttachmentsHint => 'Receipt, grower\'s sheet, soil analysis…';

  @override
  String get attachmentLabel => 'Document name';

  @override
  String get renameAttachment => 'Rename';

  @override
  String get deleteAttachment => 'Delete document';

  @override
  String get confirmDeleteAttachment =>
      'Delete this document? The file will be removed from your device.';

  @override
  String get openAttachment => 'Open';

  @override
  String get attachmentOpenFailed => 'No app can open this file.';

  @override
  String get photoLabel => 'Photo title';

  @override
  String get photoLabelHint => 'Before repotting, new leaf…';

  @override
  String get setAsMainPhoto => 'Set as main photo';

  @override
  String get mainPhotoSet => 'Main photo updated';

  @override
  String get addPhotoByUrl => 'From a web address';

  @override
  String get photoUrlHint => 'https://…';

  @override
  String get photoUrlInvalid => 'The address must start with https://';

  @override
  String get photoRemote => 'Remote photo';

  @override
  String get confirmDeletePhoto => 'Delete this photo?';

  @override
  String get shareByLink => 'Share with a link';

  @override
  String get sharedLinks => 'Shared links';

  @override
  String get sharedLinksHint => 'A public web page you can revoke at any time.';

  @override
  String get noSharedLinks => 'No shared links';

  @override
  String get shareTitle => 'Page title';

  @override
  String get shareDescription => 'Description (optional)';

  @override
  String get shareKeywords => 'Keywords (optional)';

  @override
  String get shareUnlisted => 'Unlisted';

  @override
  String get shareUnlistedHint =>
      'The page asks search engines not to index it, but anyone with the link can see it.';

  @override
  String get shareExpiry => 'Expires on';

  @override
  String get shareNoExpiry => 'No expiry';

  @override
  String get shareCreate => 'Create link';

  @override
  String get shareCopy => 'Copy link';

  @override
  String get shareCopied => 'Link copied';

  @override
  String get shareRevoke => 'Revoke';

  @override
  String get shareRevoked => 'Revoked';

  @override
  String get shareExpired => 'Expired';

  @override
  String get shareActive => 'Active';

  @override
  String get confirmRevokeLink =>
      'Revoke this link? The page will stop working.';

  @override
  String get shareNeedsAccount => 'Sharing by link needs an account.';

  @override
  String get shareFailed => 'The link could not be created. Try again.';

  @override
  String get sharePhoto => 'Share this photo';

  @override
  String get sharePlant => 'Share this plant';

  @override
  String get notesMarkdownHint =>
      'Formatting: **bold**, *italic*, - lists, [links](https://…)';

  @override
  String get preview => 'Preview';

  @override
  String get locationNotes => 'Location notes';

  @override
  String get locationLog => 'Log';

  @override
  String get addLogEntry => 'Add an entry';

  @override
  String get editLogEntry => 'Edit entry';

  @override
  String get logEntryHint => 'Blind replaced, greenhouse cleaned…';

  @override
  String get noLogEntries => 'Empty log';

  @override
  String get confirmDeleteLogEntry => 'Delete this entry?';

  @override
  String get locationPhoto => 'Location photo';

  @override
  String get removeLocationPhoto => 'Remove photo';

  @override
  String get careAllPlants => 'Care for all plants';

  @override
  String get waterAllHere => 'Water everything here';

  @override
  String get fertilizeAllHere => 'Feed everything here';

  @override
  String get repotAllHere => 'Repot everything here';

  @override
  String get searchByNumberHint => 'Type #42 to find plant no. 42.';

  @override
  String get inventoryGroups => 'Groups';

  @override
  String get manageGroups => 'Manage groups';

  @override
  String get newGroup => 'New group';

  @override
  String get editGroup => 'Edit group';

  @override
  String get groupName => 'Group name';

  @override
  String get groupNameHint => 'Fertilizer, tools, pots…';

  @override
  String get deleteGroup => 'Delete group';

  @override
  String get deleteGroupHint =>
      'Items are not deleted: they move to the group you pick.';

  @override
  String get moveItemsTo => 'Move items to';

  @override
  String get noGroup => 'No group';

  @override
  String get noGroups => 'No custom groups';

  @override
  String get itemGroup => 'Group';

  @override
  String get itemTags => 'Tags';

  @override
  String get itemQr => 'Item QR code';

  @override
  String get exportSelection => 'Export selection';

  @override
  String get exportCsv => 'Export as CSV';

  @override
  String get selectItems => 'Select';

  @override
  String itemsSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get filterByTag => 'Filter by tag';

  @override
  String get itemNotFound => 'Item not found';

  @override
  String get noGroupsYet => 'No groups.';

  @override
  String get deleteGroupExplain =>
      'Items are not deleted: they lose their group.';

  @override
  String get newEvent => 'New event';

  @override
  String get editEvent => 'Edit event';

  @override
  String get deleteEvent => 'Delete event';

  @override
  String get eventTitleHint => 'Plant fair';

  @override
  String get eventNotesHint => 'Notes (optional)';

  @override
  String get eventStart => 'Starts';

  @override
  String get eventEnd => 'Ends';

  @override
  String get eventNoEnd => 'Same day';

  @override
  String get eventAllDay => 'All day';

  @override
  String get eventCategory => 'Category';

  @override
  String get eventNoCategory => 'None';

  @override
  String get eventReminder => 'Reminder';

  @override
  String get eventNoReminder => 'None';

  @override
  String get eventReminderAtStart => 'At start';

  @override
  String eventReminderMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes before',
      one: '1 minute before',
    );
    return '$_temp0';
  }

  @override
  String eventReminderHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours before',
      one: '1 hour before',
    );
    return '$_temp0';
  }

  @override
  String eventReminderDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days before',
      one: '1 day before',
    );
    return '$_temp0';
  }

  @override
  String get manageEventCategories => 'Event categories';

  @override
  String get newEventCategory => 'New category';

  @override
  String get editEventCategory => 'Edit category';

  @override
  String get deleteEventCategory => 'Delete category';

  @override
  String get deleteEventCategoryExplain =>
      'Events are not deleted: they lose their category.';

  @override
  String get noEventCategoriesYet => 'No categories.';

  @override
  String get categoryNameHint => 'Category name';

  @override
  String get eventPlant => 'Linked plant';

  @override
  String get eventNoPlant => 'None';

  @override
  String get eventsOfDay => 'Events';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get statsSection => 'Numbers';

  @override
  String get statPlants => 'Plants';

  @override
  String get statSpecies => 'Species';

  @override
  String get statLocations => 'Locations';

  @override
  String get statFavorites => 'Favourites';

  @override
  String get statArchived => 'Archived';

  @override
  String get statNeedingCare => 'Need care';

  @override
  String get statOpenTasks => 'Open tasks';

  @override
  String get statLowStock => 'Low stock';

  @override
  String get statActionsThisMonth => 'Care this month';

  @override
  String get statWateringsThisMonth => 'Waterings this month';

  @override
  String get statOldest => 'Oldest';

  @override
  String get warningsSection => 'Needs attention';

  @override
  String get warningSick => 'Sick';

  @override
  String get warningWatch => 'Watch';

  @override
  String warningOverdue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days late',
      one: '1 day late',
    );
    return '$_temp0';
  }

  @override
  String get noWarnings => 'Nothing to report.';

  @override
  String get recentPlantsSection => 'Recent plants';

  @override
  String get recentAdded => 'Added';

  @override
  String get recentUpdated => 'Updated';

  @override
  String get activityLogTitle => 'Activity log';

  @override
  String get activityEmpty => 'No activity.';

  @override
  String get activityPlantAdded => 'Added to the garden';

  @override
  String get activityPlantArchived => 'Archived';

  @override
  String get activityLocationNote => 'Location note';

  @override
  String get activityTaskDone => 'Task completed';

  @override
  String get searchArchives => 'Search archives';

  @override
  String get archiveSortArchivedDesc => 'Recently archived';

  @override
  String get archiveSortArchivedAsc => 'Oldest archived';

  @override
  String get archiveSortName => 'Name';

  @override
  String get archiveSortLongestKept => 'Kept the longest';

  @override
  String get allYears => 'All';

  @override
  String keptForDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Kept $count days',
      one: 'Kept 1 day',
    );
    return '$_temp0';
  }

  @override
  String keptForYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Kept $count years',
      one: 'Kept 1 year',
    );
    return '$_temp0';
  }

  @override
  String get noArchiveMatch => 'No plant matches.';

  @override
  String get weatherForecastTitle => 'Forecast';

  @override
  String get weatherPrecipitation => 'Precipitation';

  @override
  String get weatherRainChance => 'Chance of rain';

  @override
  String get weatherWind => 'Wind';

  @override
  String get weatherHumidity => 'Humidity';

  @override
  String get weatherNoPlace => 'Pick a place to see the forecast.';

  @override
  String get weatherToday => 'Today';

  @override
  String get weatherFailed => 'Forecast unavailable right now.';

  @override
  String get backupTitle => 'Backup';

  @override
  String get backupExplain => 'A .zip file containing your data and photos.';

  @override
  String get backupWhatToExport => 'What to back up';

  @override
  String get backupWhatToImport => 'What to restore';

  @override
  String get sectionGarden => 'Garden and locations';

  @override
  String get sectionPlants => 'Plants';

  @override
  String get sectionPhotos => 'Photos';

  @override
  String get sectionCare => 'Care and routines';

  @override
  String get sectionInventory => 'Inventory';

  @override
  String get sectionTasks => 'Tasks';

  @override
  String get sectionCalendar => 'Calendar';

  @override
  String get importBackup => 'Restore a backup';

  @override
  String get chooseBackupFile => 'Choose a file';

  @override
  String get importing => 'Restoring…';

  @override
  String importDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items restored',
      one: '1 item restored',
    );
    return '$_temp0';
  }

  @override
  String importSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rows skipped',
      one: '1 row skipped',
    );
    return '$_temp0';
  }

  @override
  String get importConfirm =>
      'Data in the file replaces entries with the same id. Nothing is deleted.';

  @override
  String get importErrorNotAZip => 'This file is not an Auxine backup.';

  @override
  String get importErrorWrongApp => 'This backup comes from another app.';

  @override
  String get importErrorTooRecent =>
      'This backup comes from a newer version of Auxine.';

  @override
  String get importErrorGeneric => 'Restore failed.';

  @override
  String backupFrom(String date) {
    return 'Backup from $date';
  }

  @override
  String backupContains(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get onbTodayTitle => 'Today\'s care';

  @override
  String get onbTodayBody => 'One tap to log each care.';

  @override
  String get onbCareTitle => 'Less watering in winter';

  @override
  String get onbCareBody => 'Intervals adjust with the season.';

  @override
  String get onbGardenTitle => 'Rooms, photos, calendar';

  @override
  String get onbGardenBody =>
      'The app dates every watering and repotting, and files them with the plant.';

  @override
  String onbIrisTitle(String name) {
    return '$name names your plants offline';
  }

  @override
  String get onbIrisBody =>
      'If Iris does not know the plant, the search continues online.';

  @override
  String get onbPrivacyTitle => 'Everything stays on your phone';

  @override
  String get onbPrivacyBody => 'No account required, no ads.';

  @override
  String get onbStart => 'Get started';

  @override
  String get replayOnboarding => 'Replay the intro';

  @override
  String onbStepOf(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get weatherPickPlace => 'Choose a place';

  @override
  String get speciesMoreOffline => 'More species';

  @override
  String get aboutSources => 'Data sources';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get aboutSourceWikidata =>
      'Species names in four languages, public domain';

  @override
  String get aboutSourceGbif =>
      'Taxonomy, families and photographed occurrences';

  @override
  String get aboutSourceOpenMeteo => 'Weather and forecast, no account or key';

  @override
  String get aboutSourceRhs => 'Hardiness, soils and growing advice';

  @override
  String get aboutSourceAspca => 'Plant toxicity for domestic animals';

  @override
  String aboutSpeciesCount(String count) {
    return '$count species searchable offline';
  }

  @override
  String get emptyGardenSubtitle => 'Add your first plant.';

  @override
  String get finderTitle => 'Find a plant';

  @override
  String get finderEntryHint => 'Help choosing';

  @override
  String get finderStepSpot => 'Location';

  @override
  String get finderStepSpotHint => 'Light is the main criterion.';

  @override
  String get finderSpotBright => 'Bright room';

  @override
  String get finderSpotMedium => 'Medium light';

  @override
  String get finderSpotDark => 'Dark corner';

  @override
  String get finderSpotOutdoor => 'Outdoors, balcony or garden';

  @override
  String get finderStepEffort => 'How much care?';

  @override
  String get finderStepEffortHint => 'How often you can water.';

  @override
  String get finderEffortForgiving => 'Occasional watering';

  @override
  String get finderEffortNormal => 'Regular watering';

  @override
  String get finderEffortAttentive => 'Frequent care';

  @override
  String get finderStepSafety => 'Pets or children?';

  @override
  String get finderStepSafetyHint =>
      'Many houseplants are toxic if a pet or a child chews them.';

  @override
  String get finderSafetyYes => 'Yes, non-toxic only';

  @override
  String get finderSafetyNo => 'No constraint';

  @override
  String get finderNote => 'Details';

  @override
  String get finderNoteHint =>
      'A windowless bathroom, a cat that chews everything…';

  @override
  String get finderResults => 'Suggestions';

  @override
  String get finderEmptyTitle => 'No results';

  @override
  String get finderEmptySubtitle =>
      'No species in the catalogue ticks every criterion. Change an answer or widen the plant types.';

  @override
  String get finderRestart => 'Start over';

  @override
  String get finderAdd => 'Add to my garden';

  @override
  String get finderAskAi => 'Ask the AI';

  @override
  String get finderAiSection => 'AI suggestions';

  @override
  String get finderAiHint =>
      'Outside the catalogue, worth checking before buying.';

  @override
  String get finderAiError => 'No suggestion from the AI.';

  @override
  String get finderReasonLight => 'Suitable light';

  @override
  String get finderReasonLowLight => 'Tolerates shade';

  @override
  String get finderReasonForgiving => 'Tolerates missed waterings';

  @override
  String get finderReasonEasy => 'Easy';

  @override
  String get finderReasonSafe => 'Non-toxic';

  @override
  String get finderReasonOutdoor => 'Happy outdoors';

  @override
  String get finderAnyAnswer => 'No preference';

  @override
  String finderQuestionOf(int n, int total) {
    return 'Question $n of $total';
  }

  @override
  String get finderSpotBrightHint => 'Near a window, plenty of daylight';

  @override
  String get finderSpotMediumHint => 'A few steps from a window';

  @override
  String get finderSpotDarkHint => 'Far from windows, little daylight';

  @override
  String get finderSpotOutdoorHint => 'Balcony, terrace or garden';

  @override
  String get finderEffortForgivingHint =>
      'A plant that tolerates missed waterings';

  @override
  String get finderEffortNormalHint => 'About one watering a week';

  @override
  String get finderEffortAttentiveHint => 'Misting, repotting, regular checks';

  @override
  String get finderSafetyYesHint => 'Only non-toxic species';

  @override
  String get finderSafetyNoHint => 'Every species, toxic ones included';

  @override
  String get finderTopPick => 'First pick';

  @override
  String get finderAlternatives => 'Other suggestions';

  @override
  String get finderChangeAnswer => 'Change this answer';

  @override
  String get finderChipSpotAny => 'Spot: no preference';

  @override
  String get finderChipEffortAny => 'Care: no preference';

  @override
  String get finderChipSafe => 'Non-toxic';

  @override
  String finderFactWater(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Water every $count d',
      one: 'Water daily',
    );
    return '$_temp0';
  }

  @override
  String get finderAiTitle => 'Go further';

  @override
  String get finderAiBody =>
      'Search beyond the catalogue, from your answers and whatever you add here.';

  @override
  String get finderPhotoSource => 'Photos: GBIF observations, freely licensed.';

  @override
  String get onbWelcomeTitle => 'Welcome to Auxine';

  @override
  String get onbWelcomeBody => 'The care log for your plants.';

  @override
  String get careMatchAssisted => 'Completed by AI';

  @override
  String get careAssistedNote =>
      'Species missing from the catalogue: these guides come from the AI, which received only the scientific name. Toxicity is not covered.';

  @override
  String get careMatchEdited => 'Edited profile';

  @override
  String get careEditedNote =>
      'Profile corrected by hand; the rest comes from the catalogue.';

  @override
  String careVerifiedFields(String source, String fields) {
    return 'Verified from $source: $fields';
  }

  @override
  String get careSourceHabitat => 'native habitat';

  @override
  String get careSourceDerived => 'cultivation rule';

  @override
  String get careStudio => 'Care Studio';

  @override
  String get careStudioHint =>
      'Fix a care sheet. Your edit applies on this device only.';

  @override
  String get careStudioSearch => 'Search for a species';

  @override
  String get careStudioPrompt => 'Search for a species to fix its profile.';

  @override
  String get careStudioEmpty => 'No species matches.';

  @override
  String get careStudioWateringSummer => 'Watering, growing season';

  @override
  String get careStudioWateringWinter => 'Watering, winter';

  @override
  String get careStudioDamageBelow => 'Keep above';

  @override
  String get careStudioSave => 'Save';

  @override
  String get careStudioSaved => 'Edit saved';

  @override
  String get careStudioReset => 'Revert to catalogue';

  @override
  String get careAssistSetting => 'Complete care sheets with AI';

  @override
  String get careAssistHint =>
      'For a species missing from the catalogue, the app sends the scientific name to the AI to fill out the sheet. Nothing else leaves your device. The answer is kept.';

  @override
  String get gardensTitle => 'My gardens';

  @override
  String get gardensHint =>
      'The open garden is the one shown everywhere in the app. Switch between them here.';

  @override
  String get gardenMine => 'My garden';

  @override
  String get gardenUnnamed => 'Shared garden';

  @override
  String gardenSharedBy(String name) {
    return 'Shared by $name';
  }

  @override
  String gardenOpened(String name) {
    return 'Garden: $name';
  }

  @override
  String get someone => 'someone';

  @override
  String memberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
    );
    return '$_temp0';
  }

  @override
  String get renameGarden => 'Rename the garden';

  @override
  String get renameGardenHint => 'Name visible to invited people.';

  @override
  String get gardenNameHint => 'The garden at home';

  @override
  String get joinGarden => 'Join a garden';

  @override
  String get joinGardenHint =>
      'Enter the code you were given, or open your invitation link.';

  @override
  String get inviteCodeHint => 'Invitation code';

  @override
  String get joinLook => 'See the invitation';

  @override
  String get joinConfirm => 'Join';

  @override
  String get joinInvalid =>
      'This code is no longer valid. It has been used, has expired, or never existed.';

  @override
  String get joinWrongEmail =>
      'This invitation is reserved for another email address.';

  @override
  String get joinNeedsAccount => 'You need an account to join a garden.';

  @override
  String get joinSignInHint => 'Sign in with your Apple ID.';

  @override
  String joinInvitedBy(String name, String garden) {
    return '$name invites you to “$garden”';
  }

  @override
  String joinGardenName(String garden) {
    return 'Invitation to “$garden”';
  }

  @override
  String get joinAsMember => 'Add, edit and delete plants.';

  @override
  String get joinAsViewer => 'View only, no changes.';

  @override
  String get joinAlreadyMember => 'You are already part of this garden.';

  @override
  String joined(String name) {
    return 'Joined “$name”';
  }

  @override
  String get leaveGarden => 'Leave this garden';

  @override
  String leaveGardenConfirm(String name) {
    return 'You will no longer have access to “$name”.';
  }

  @override
  String leftGarden(String name) {
    return 'You left “$name”';
  }

  @override
  String get deleteGarden => 'Delete the garden';

  @override
  String deleteGardenConfirm(String name) {
    return '“$name”, its plants and its history will be deleted, for you and for the people you invited.';
  }

  @override
  String gardenDeleted(String name) {
    return 'Garden “$name” deleted';
  }

  @override
  String get deleteGardenLast => 'An account keeps at least one garden.';

  @override
  String get openGardenTitle => 'Your gardens';

  @override
  String get openGardenHint =>
      'This account gives access to these gardens. Open the one holding your plants.';

  @override
  String get collaborationNeedsAccount => 'Sharing a garden needs an account';

  @override
  String get inviteSomeone => 'Invite someone';

  @override
  String get inviteReady => 'Invitation ready';

  @override
  String get inviteRoleHint =>
      'Member: adds, edits and deletes plants. Viewer: view only.';

  @override
  String get inviteEmailOptional => 'Email address (optional)';

  @override
  String get inviteEmailHint =>
      'If set, only this address can accept the invitation.';

  @override
  String get inviteCreate => 'Create the invitation';

  @override
  String get inviteShareHint =>
      'Send this link or code. The person does not need the app to receive it.';

  @override
  String get inviteShare => 'Share the link';

  @override
  String inviteMessage(String link) {
    return 'Invitation to join my garden on Auxine: $link';
  }

  @override
  String get inviteOnceHint => 'An invitation works only once.';

  @override
  String inviteExpires(String date) {
    return 'Expires on $date';
  }

  @override
  String get inviteFailed => 'The invitation could not be created.';

  @override
  String get invitesTitle => 'Pending invitations';

  @override
  String get inviteRevoke => 'Revoke';

  @override
  String get inviteRevokeConfirm => 'The code will no longer work.';

  @override
  String get inviteRevoked => 'Invitation revoked';

  @override
  String get membersHint =>
      'Members see your plants and can take care of them.';

  @override
  String get membersGuestHint => 'Garden shared by another user.';

  @override
  String get memberRoleHint =>
      'Member: adds, edits and deletes plants. Viewer: view only.';

  @override
  String makeRole(String role) {
    return 'Change to “$role”';
  }

  @override
  String roleChanged(String name, String role) {
    return '$name is now “$role”';
  }

  @override
  String removeMemberConfirm(String name) {
    return '$name will lose access to this garden.';
  }

  @override
  String get photoFirstTitle => 'First photo';

  @override
  String get photoNextTitle => 'New photo';

  @override
  String get photoFirstHint => 'It will be the main photo.';

  @override
  String get photoFrameHint =>
      'Keep the same framing each time to follow its growth.';

  @override
  String get photoGhostToggle => 'Overlay the last photo';

  @override
  String get photoGhostHint =>
      'Line the plant up with the photo shown in transparency.';

  @override
  String get photoTitleStepTitle => 'Title';

  @override
  String get photoTitleStepSubtitle => 'Optional.';

  @override
  String get photoTagNewLeaf => 'New leaf';

  @override
  String get photoTagFlowering => 'Flowering';

  @override
  String get photoTagBeforeRepotting => 'Before repotting';

  @override
  String get photoTagAfterRepotting => 'After repotting';

  @override
  String get photoTagCutting => 'Cutting';

  @override
  String get photoTagAfterPruning => 'After pruning';

  @override
  String get mainPhotoHint => 'Shown on the plant page and in the list.';

  @override
  String get retake => 'Retake';

  @override
  String get growthEmptySubtitle => 'Add photos regularly to track growth.';

  @override
  String growthSummary(int count, String since) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos · since $since',
      one: '1 photo · since $since',
    );
    return '$_temp0';
  }

  @override
  String growthNudge(String date) {
    return 'Last photo on $date.';
  }

  @override
  String get timelapse => 'Timelapse';

  @override
  String get beforeAfter => 'Before / after';

  @override
  String photoCounter(int index, int total) {
    return '$index / $total';
  }

  @override
  String get photoTitleShort => 'Title';

  @override
  String get mainPhotoShort => 'Main';

  @override
  String get share => 'Share';

  @override
  String get addTitle => 'Add a title';

  @override
  String get swap => 'Swap';

  @override
  String get pause => 'Pause';

  @override
  String get stepPhotoDoneTitle => 'Preview';

  @override
  String stepPhotoDoneSubtitle(String name) {
    return 'A leaf close up helps $name recognise the species.';
  }

  @override
  String get stepPhotoDonePlain => 'You can add more from its page.';

  @override
  String get viewPlant => 'The plant';

  @override
  String get viewLeafClose => 'A leaf close up';

  @override
  String get viewAnother => 'Another view';

  @override
  String viewForModel(String name) {
    return 'Used by $name to recognise the species, not kept.';
  }

  @override
  String get strategyWeather => 'Weather';

  @override
  String get strategyWeatherHint =>
      'The seasonal interval shortens in dry heat and stretches in rain and cold.';

  @override
  String strategyWeatherNow(String interval) {
    return 'With this week\'s weather: $interval';
  }

  @override
  String get strategyWeatherNoPlace =>
      'Without a weather place, the interval stays the seasonal one.';

  @override
  String get weatherWhenTonight => 'tonight';

  @override
  String get weatherWhenToday => 'today';

  @override
  String get weatherWhenTomorrow => 'tomorrow';

  @override
  String weatherWhenInDays(int count) {
    return 'in $count days';
  }

  @override
  String weatherFrostTitle(String when, String temp) {
    return 'Frost $when · $temp';
  }

  @override
  String weatherHeatTitle(String when, String temp) {
    return 'Heat $when · $temp';
  }

  @override
  String weatherFrostBody(String names) {
    return 'Bring in or cover $names.';
  }

  @override
  String weatherHeatBody(String names) {
    return 'Move $names into shade, and water early.';
  }

  @override
  String weatherAlertMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'and $count more',
      one: 'and 1 more',
    );
    return '$_temp0';
  }

  @override
  String weatherAlertFamily(String name) {
    return 'the $name family';
  }

  @override
  String notifFrost(String when, String names) {
    return 'Frost $when · bring in or cover $names.';
  }

  @override
  String notifHeat(String when, String names) {
    return 'Heat $when · move $names into shade.';
  }

  @override
  String weatherRainFallenTitle(String mm) {
    return 'Rain · $mm mm';
  }

  @override
  String weatherRainWatered(String names) {
    return 'Watering logged for $names.';
  }

  @override
  String weatherRainWaterable(String names) {
    return 'The rain covers the watering for $names.';
  }

  @override
  String get weatherRainMarkWatered => 'Log as watered';

  @override
  String weatherRainWateredToast(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count waterings logged',
      one: '1 watering logged',
    );
    return '$_temp0';
  }

  @override
  String weatherRainNote(String mm) {
    return 'Watered by rain ($mm mm).';
  }

  @override
  String get weatherRainCounts => 'Rain counts as watering';

  @override
  String get weatherRainCountsHint =>
      'Above 5 mm over 3 days, watering at your outdoor locations is logged as done. A pot under foliage gets less rain.';

  @override
  String get weatherClimate => 'Climate';

  @override
  String get weatherClimateHint =>
      'Plants suggested for outdoors take account of the winters and summers where you are.';

  @override
  String weatherClimateZone(String zone) {
    return 'Zone $zone';
  }

  @override
  String weatherClimateRange(String low, String high) {
    return 'Winters at $low, summers at $high';
  }

  @override
  String get weatherClimateNone => 'Unknown';

  @override
  String get finderReasonHardy => 'Winters outdoors here';

  @override
  String get finderReasonSheltered => 'Winters outdoors, sheltered';

  @override
  String finderRegion(String zone, String low) {
    return 'Zone $zone · winters at $low';
  }

  @override
  String get encyclopediaTitle => 'Encyclopedia';

  @override
  String get encyclopediaHint =>
      'The problems recorded, the species in the catalogue and the vocabulary of the care sheets.';

  @override
  String get encyclopediaProblems => 'Problems';

  @override
  String get encyclopediaSpecies => 'Species';

  @override
  String get encyclopediaGlossary => 'Vocabulary';

  @override
  String get encyclopediaSearchProblems => 'Name, pest, disease…';

  @override
  String get encyclopediaSearchGlossary => 'Light, soil, cutting…';

  @override
  String encyclopediaProblemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count problems',
      one: '1 problem',
      zero: 'No problem',
    );
    return '$_temp0';
  }

  @override
  String encyclopediaNaturalCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count normal phenomena',
      one: '1 normal phenomenon',
      zero: 'No normal phenomenon',
    );
    return '$_temp0';
  }

  @override
  String encyclopediaSpeciesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count species',
      one: '1 species',
      zero: 'No species',
    );
    return '$_temp0';
  }

  @override
  String get encyclopediaNoTerm => 'No term found';

  @override
  String problemNumber(String id) {
    return 'Entry $id';
  }

  @override
  String get problemScope => 'Range';

  @override
  String get problemScopeGeneral => 'All plants';

  @override
  String get problemScopeWide => 'Many hosts';

  @override
  String get problemScopeTarget => 'Specific hosts';

  @override
  String get problemScopeGeneralNote =>
      'Possible on vascular plants, depending on conditions and growth stage.';

  @override
  String get problemScopeWideNote =>
      'Many hosts; the taxa listed are examples.';

  @override
  String get problemScopeTargetNote =>
      'Main hosts within a target group; the list is not exhaustive.';

  @override
  String get problemOtherNames => 'Other names';

  @override
  String get problemOtherNamesNote =>
      'Common and scientific names for the same thing.';

  @override
  String get problemHosts => 'Hosts';

  @override
  String get problemHostsAll => 'All vascular plants';

  @override
  String get problemHostsNote =>
      'A genus or a family does not make all of its species susceptible.';

  @override
  String get problemInGarden => 'In the garden';

  @override
  String get problemKindsTitle => 'Problem families';

  @override
  String get problemKindDisorderNote =>
      'Neither pest nor disease: water, light, cold, soil, a deficiency.';

  @override
  String get problemKindPestNote =>
      'A living thing feeding on the plant: insect, mite, slug, nematode.';

  @override
  String get problemKindDiseaseNote =>
      'A fungus, a bacterium, a virus or a phytoplasma living in the plant.';

  @override
  String get problemKindConditionNote =>
      'Neither one: sooty mould grows on honeydew without attacking the plant.';

  @override
  String get naturalCauses => 'Normal phenomena';

  @override
  String get naturalCauseNote =>
      'What the plant does normally and gets taken for a problem: there is nothing to treat.';

  @override
  String get careLightShadeNote =>
      'Away from windows, with no direct beam at any time of day.';

  @override
  String get careLightLowNote =>
      'A light room, but far from the window, or facing north.';

  @override
  String get careLightIndirectNote =>
      'A few steps from a window, or behind a sheer curtain.';

  @override
  String get careLightBrightNote =>
      'Close to a window, out of the sun\'s beam.';

  @override
  String get careLightSomeNote => 'Morning or late-day sun, not midday sun.';

  @override
  String get careLightFullNote =>
      '6 hours of direct sun or more, through the middle of the day.';

  @override
  String get careHumidityLowNote => 'The air of a heated home is enough.';

  @override
  String get careHumidityAverageNote =>
      'Around 50%, away from a radiator in winter.';

  @override
  String get careHumidityHighNote =>
      'Above 60%: bathroom, kitchen, or a tray of damp clay pebbles.';

  @override
  String get careDifficultyEasyNote =>
      'Puts up with missed waterings and changes in light.';

  @override
  String get careDifficultyMediumNote =>
      'Needs a steady watering rhythm and a settled spot.';

  @override
  String get careDifficultyDemandingNote =>
      'Light, humidity and watering all have to be watched closely.';

  @override
  String get careToxicSafeNote => 'No known toxicity for pets or children.';

  @override
  String get careToxicMildNote => 'The sap irritates skin and mouth.';

  @override
  String get careToxicToxicNote =>
      'Swallowing a leaf or a fruit causes illness.';

  @override
  String get careToxicUnknownNote =>
      'Nothing is recorded for this species; keep it out of reach as a precaution.';

  @override
  String get careSoilStandardNote =>
      'Standard houseplant compost, with nothing added.';

  @override
  String get careSoilDrainingNote =>
      'Potting mix lightened with perlite, sand or pumice.';

  @override
  String get careSoilCactusNote =>
      'Largely mineral: water runs through without sitting.';

  @override
  String get careSoilOrchidNote => 'Coarse bark: the roots live in the air.';

  @override
  String get careSoilAcidicNote =>
      'An acid pH, for plants that lime turns yellow.';

  @override
  String get careSoilRichNote => 'Compost-enriched mix, for hungry plants.';

  @override
  String get careSoilNoneNote =>
      'The roots sit in water, or on a support with no soil.';

  @override
  String get carePropCuttingNote =>
      'A stem cut below a node, set in damp compost.';

  @override
  String get carePropLeafNote =>
      'A whole leaf, or a piece of one, laid on the compost.';

  @override
  String get carePropDivisionNote =>
      'A clump split in two at repotting, roots included.';

  @override
  String get carePropOffsetsNote =>
      'The young shoots born at the base, detached once rooted.';

  @override
  String get carePropLayeringNote =>
      'A stem rooted while still attached to the mother plant.';

  @override
  String get carePropSeedNote =>
      'Sown seed, slower than a cutting and often less true to type.';

  @override
  String get carePropWaterNote =>
      'The cutting sits in a glass of water until roots appear.';

  @override
  String get carePropTuberNote => 'A tuber cut into pieces, each with an eye.';

  @override
  String get communityTipsTitle => 'Community tips';

  @override
  String get communityTipsHint =>
      'What other people noticed while growing this species, outside the catalogue.';

  @override
  String get communityTipsEmpty => 'No tips on this species.';

  @override
  String get offlineCommunityTips =>
      'Reading and publishing tips needs a connection.';

  @override
  String get communityTipWrite => 'Write a tip';

  @override
  String get communityTipYours => 'Your tip';

  @override
  String get communityTipPlaceholder =>
      'What worked on this plant, in a few sentences.';

  @override
  String get communityTipPublicNote =>
      'Your tip will be visible to everyone, under your name, on this species page.';

  @override
  String communityTipLength(int used, int max) {
    return '$used / $max';
  }

  @override
  String get communityTipPublish => 'Publish';

  @override
  String get communityTipPublished => 'Tip published.';

  @override
  String get communityTipNeedsAccount => 'Publishing a tip needs an account.';

  @override
  String get communityTipAnonymous => 'Anonymous';

  @override
  String get communityTipHelpful => 'Helpful';

  @override
  String get communityTipReport => 'Report';

  @override
  String get communityTipReported => 'Tip reported.';

  @override
  String communityTipReportNote(int count) {
    return 'A tip reported by $count people stops appearing.';
  }

  @override
  String get communityTipHidden => 'Reported: other people no longer see it.';

  @override
  String get confirmDeleteTip => 'Delete this tip?';

  @override
  String get confirmReportTip => 'Report this tip?';

  @override
  String get moderationTitle => 'Moderation';

  @override
  String get moderationHint => 'Reported tips, most reported first.';

  @override
  String get moderationEmpty => 'No reported tips.';

  @override
  String moderationReports(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reports',
      one: '1 report',
    );
    return '$_temp0';
  }

  @override
  String get moderationHide => 'Hide';

  @override
  String get moderationRestore => 'Restore';

  @override
  String get confirmRestoreTip => 'Restore this tip? Its reports are cleared.';

  @override
  String get roomScan => 'Home scan';

  @override
  String get roomScanHint =>
      'Scan a room with the camera and LiDAR: the app finds the walls, windows and doors, then works out how much light each spot gets, so you know where to put your plants. Everything stays on your device.';

  @override
  String get roomScanStart => 'Scan a room';

  @override
  String get roomScanRooms => 'Scanned rooms';

  @override
  String get roomScanEmptyTitle => 'No room scanned';

  @override
  String get roomScanEmptySubtitle => 'Allow 1 to 2 minutes per room.';

  @override
  String get roomScanNoLidar =>
      'This device has no LiDAR. Scanning needs an iPhone Pro or an iPad Pro.';

  @override
  String get roomScanBeforeTitle => 'Before the scan';

  @override
  String get roomScanBeforeText =>
      'The camera opens the iOS scanner. Walk slowly along the walls until the room is fully drawn, then tap Done.';

  @override
  String get roomScanFailed => 'The scan did not complete.';

  @override
  String get roomScanDefaultName => 'Room';

  @override
  String roomScanArea(String area) {
    return '$area m²';
  }

  @override
  String roomScanWindowsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count windows',
      one: 'one window',
      zero: 'no window',
    );
    return '$_temp0';
  }

  @override
  String get roomScanName => 'Room name';

  @override
  String get roomScanLinkedLocation => 'Location';

  @override
  String get roomScanWindows => 'Windows';

  @override
  String roomScanWindowN(int n) {
    return 'Window $n';
  }

  @override
  String get roomScanWindowUnknown => 'Unknown orientation';

  @override
  String get roomScanWindowFromCompass => 'From the compass';

  @override
  String get roomScanWindowConfirmed => 'Confirmed';

  @override
  String get roomScanOrientationHelp =>
      'The compass is off by 10 to 15°. Correct each window\'s orientation here.';

  @override
  String get roomScanDelete => 'Delete the scan';

  @override
  String get roomScanDeleteConfirm =>
      'The scan and its markers will be deleted from your device.';

  @override
  String roomScanCapturedOn(String date) {
    return 'Scanned on $date';
  }

  @override
  String get roomSectionBathroom => 'Bathroom';

  @override
  String get roomSectionBedroom => 'Bedroom';

  @override
  String get roomSectionDiningRoom => 'Dining room';

  @override
  String get roomSectionKitchen => 'Kitchen';

  @override
  String get roomSectionLaundryRoom => 'Laundry room';

  @override
  String get roomSectionLivingRoom => 'Living room';

  @override
  String get directionNorth => 'north';

  @override
  String get directionNorthEast => 'north-east';

  @override
  String get directionEast => 'east';

  @override
  String get directionSouthEast => 'south-east';

  @override
  String get directionSouth => 'south';

  @override
  String get directionSouthWest => 'south-west';

  @override
  String get directionWest => 'west';

  @override
  String get directionNorthWest => 'north-west';

  @override
  String get placementTitle => 'Where to put it';

  @override
  String get placementHint =>
      'Spots are ranked by comparing the light they receive with the light the care sheet asks for.';

  @override
  String placementRoomsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rooms scanned',
      one: 'one room scanned',
    );
    return '$_temp0';
  }

  @override
  String get placementVerdictGood => 'Suitable room.';

  @override
  String get placementVerdictAcceptable =>
      'Acceptable room, with no ideal spot.';

  @override
  String get placementVerdictUnsuitable => 'Unsuitable room.';

  @override
  String get placementShortfallTooDark => 'Too dark for the light required.';

  @override
  String get placementShortfallTooBright => 'Too much direct sun.';

  @override
  String get placementShortfallDrafty => 'Every spot is near a door: draughts.';

  @override
  String get placementShortfallTooDry =>
      'Wet room, humid air: the care sheet calls for dry air.';

  @override
  String get placementGeneric =>
      'Without a species, the light required is unknown: the care sheet stays generic.';

  @override
  String placementDistanceM(String m) {
    return '$m m';
  }

  @override
  String placementDistanceCm(int cm) {
    return '$cm cm';
  }

  @override
  String placementNearWindow(String distance, String direction) {
    return '$distance from the $direction window';
  }

  @override
  String placementNearWindowUnknown(String distance) {
    return '$distance from the window';
  }

  @override
  String get placementOnTable => 'on the table';

  @override
  String get placementOnStorage => 'on the cabinet';

  @override
  String placementOnSill(String direction) {
    return 'on the $direction window sill';
  }

  @override
  String get placementOnSillUnknown => 'on the window sill';

  @override
  String get placementDeepInRoom => 'at the back, away from the windows';

  @override
  String get placementDraftyNote => 'Near a door: draught.';

  @override
  String get placementHumidRoomNote => 'Wet room: more humid air.';

  @override
  String placementPlanSemantics(int count) {
    return 'Room plan seen from above, $count spots kept.';
  }

  @override
  String get roomScanHeaters => 'Radiators';

  @override
  String get roomScanHeatersHelp =>
      'The scan does not detect radiators. Place them on the plan: the air counts as dry and hot within 80 cm.';

  @override
  String get roomScanAddHeater => 'Place a radiator';

  @override
  String get roomScanTapForHeater => 'Tap the plan where the radiator is.';

  @override
  String roomScanHeatersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count radiators',
      one: 'one radiator',
      zero: 'no radiator',
    );
    return '$_temp0';
  }

  @override
  String get roomScanRemoveHeater => 'Remove this radiator';

  @override
  String get roomScanFillLocation => 'Fill in the location';

  @override
  String roomScanFillLocationDetail(String orientation, String light) {
    return 'From the scan: orientation $orientation, light $light. Fields you have already filled in do not change.';
  }

  @override
  String get roomScanLocationFilled => 'Location filled in';

  @override
  String get roomScanWhoFitsHere => 'The garden in this room';

  @override
  String get roomScanWhoFitsHint =>
      'Each plant is rated by comparing the room\'s light with what its care sheet asks for.';

  @override
  String get roomScanNoPlantsToRank => 'No plant with a known species.';

  @override
  String get placementShortfallHeater =>
      'Every spot is near a radiator: the air is dry and hot.';

  @override
  String get placementHeaterNote => 'Near a radiator: dry, hot air.';

  @override
  String get placementAtHome => 'Room sensor';

  @override
  String get roomScanStartStructure => 'Scan the whole home';

  @override
  String get roomScanStructureHint =>
      'Scan your rooms one after another: tap “Next room” after each one, “Done” at the end. The app assembles them into a single plan.';

  @override
  String get roomScanNextRoom => 'Next room';

  @override
  String roomScanRoomNumber(int n) {
    return 'Room $n';
  }

  @override
  String get roomScanPlantsOnPlan => 'Plants on the plan';

  @override
  String get roomScanPlantsHelp =>
      'Place your plants on the plan: each one gets a rating, and the list flags a clearly better spot.';

  @override
  String get roomScanAddPlant => 'Place a plant';

  @override
  String roomScanTapForPlant(String plant) {
    return 'Tap the plan where $plant is.';
  }

  @override
  String roomScanRemovePlant(String plant) {
    return 'Remove $plant from the plan';
  }

  @override
  String get roomScanNoPlantToPlace => 'No plant to place.';

  @override
  String roomScanPlantWellPlaced(String light) {
    return 'Suitable spot · $light';
  }

  @override
  String roomScanPlantBetterAt(String light, String place) {
    return 'Here $light · better $place';
  }

  @override
  String get placementAllRooms => 'All rooms';

  @override
  String get placementChoose => 'Place here';

  @override
  String placementChosen(String place) {
    return 'Placed $place';
  }

  @override
  String placementCurrent(String place, String light) {
    return 'Current spot: $place · $light';
  }

  @override
  String get sectionRooms => 'Home scans';

  @override
  String get roomScanCurtain => 'Curtain';

  @override
  String get roomScanCurtainNone => 'No curtain';

  @override
  String get roomScanCurtainSheer => 'Sheer curtain';

  @override
  String get roomScanCurtainDrawn => 'Curtain often drawn';

  @override
  String get roomScanCurtainHelp =>
      'The scan does not detect curtains. A sheer curtain halves the light and removes direct sun; a curtain that is often drawn divides it by 3.';

  @override
  String get roomScanPlace => 'Place';

  @override
  String get roomScanAddWindow => 'Add a window';

  @override
  String get roomScanAddWindowHelp =>
      'The scan misses a window behind a drawn curtain, or takes it for a gap. Add it here, at its size.';

  @override
  String get roomScanTapForWindow =>
      'Tap the plan next to the wall that holds the window.';

  @override
  String get roomScanWindowSmall => 'Small window · 0.6 m';

  @override
  String get roomScanWindowStandard => 'Window · 1.2 m';

  @override
  String get roomScanWindowWide => 'Patio door · 2.2 m';

  @override
  String get roomScanWindowByHand => 'Added by hand';

  @override
  String get roomScanRemoveWindow => 'Remove this window';

  @override
  String roomScanRoomsShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rooms',
      one: '1 room',
      zero: 'None',
    );
    return '$_temp0';
  }

  @override
  String get roomScanThisRoom => 'Scan this room';

  @override
  String get roomScanThisRoomHint =>
      'The plan shows the light at each spot, to choose where to put a plant.';

  @override
  String get roomScanRoomPlan => 'Room plan';

  @override
  String roomScanPlantsOnPlanCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count plants on the plan',
      one: 'one plant on the plan',
      zero: 'no plant on the plan',
    );
    return '$_temp0';
  }
}
