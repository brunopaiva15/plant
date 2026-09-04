// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Flora';

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
  String get genericError => 'Something didn\'t work. Please try again.';

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
  String get allDoneSubtitle => 'Your plants don\'t need anything today.';

  @override
  String get emptyGardenTitle => 'Your garden starts here.';

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
  String get noResultsTitle => 'No results';

  @override
  String get noResultsSubtitle => 'Try another word.';

  @override
  String get emptyPlantsTitle => 'No plants yet';

  @override
  String get emptyPlantsSubtitle => 'Your garden starts here.';

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
  String get stepPhotoTitle => 'A photo?';

  @override
  String get stepPhotoSubtitle => 'It becomes the face of your plant.';

  @override
  String get takePhoto => 'Take a photo';

  @override
  String get choosePhoto => 'Choose a photo';

  @override
  String get withoutPhoto => 'Continue without photo';

  @override
  String get changePhoto => 'Change';

  @override
  String get stepNameTitle => 'What\'s its name?';

  @override
  String get plantNameHint => 'Living room Monstera';

  @override
  String get speciesHint => 'Species (optional)';

  @override
  String get stepLocationTitle => 'Where is it?';

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
  String get notesHint => 'Anything useful…';

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
  String get freeLimitTitle => 'Limit reached';

  @override
  String freeLimitBody(int count) {
    return 'The free plan includes $count plants. Go Premium for an unlimited collection.';
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
  String get cuttings => 'Cuttings';

  @override
  String get createCutting => 'Create a cutting';

  @override
  String cuttingOf(String name) {
    return 'Cutting of $name';
  }

  @override
  String get parentPlant => 'Parent plant';

  @override
  String get schedule => 'Schedule';

  @override
  String get editPlant => 'Edit plant';

  @override
  String get archivePlant => 'Archive plant';

  @override
  String get archiveReasonTitle => 'What happened?';

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
  String get enabled => 'Enabled';

  @override
  String get interval => 'Interval';

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
  String get whatDidYouDo => 'What did you do?';

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
  String get photoError => 'Couldn\'t add the photo. Please try again.';

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
      'By default, Flora follows the system setting.';

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
      'One notification a day, only when a plant needs you.';

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
  String get localAccountHint =>
      'Your plants and photos stay private, on this phone. Accounts and sync will come in a future version.';

  @override
  String get about => 'About';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String get premium => 'Premium';

  @override
  String get premiumBody =>
      'Unlimited plants, identification, diagnosis, collaboration. Coming soon.';

  @override
  String premiumPlantCount(int count, int limit) {
    return '$count / $limit plants';
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
  String get onboardingTitle => 'Your garden, simply.';

  @override
  String get onboardingSubtitle => 'Care for your plants and keep their story.';

  @override
  String get askNameTitle => 'What\'s your name?';

  @override
  String get askNameSubtitle =>
      'To greet you every morning. You can change it later.';

  @override
  String get notificationAskTitle => 'One useful reminder a day';

  @override
  String get notificationAskBody =>
      'A single notification per day, at the time you choose, only when a plant needs it.';

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
    return '$name probably needs water today.';
  }

  @override
  String notifWaterMany(String names) {
    return '$names probably need water today.';
  }

  @override
  String notifOther(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count other tasks are waiting.',
      one: '1 other task is waiting.',
    );
    return '$_temp0';
  }

  @override
  String notifOnlyOther(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tasks are waiting today.',
      one: '1 task is waiting today.',
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
}
