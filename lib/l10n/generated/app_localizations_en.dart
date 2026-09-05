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
  String get onboardingSubtitle =>
      'Add them one by one, with a photo if you like.';

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
  String get noInventorySubtitle =>
      'Fertilizers, soils, pots, tools: keep an eye on your supplies.';

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
  String get qrHint =>
      'Stick it on the pot: scanning opens the plant directly.';

  @override
  String get scan => 'Scan';

  @override
  String get scanHint => 'Point at a plant\'s QR code.';

  @override
  String get unknownQr => 'This QR code doesn\'t belong to your garden.';

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
  String get identifyTitle => 'Is it…';

  @override
  String get identifyHint => 'Suggestions to confirm, never certainties.';

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
  String get identificationHint =>
      'Species recognition from a photo, powered by Pl@ntNet. Create a free key on my.plantnet.org and paste it here.';

  @override
  String get apiKey => 'API key';

  @override
  String get apiKeyHint => 'Paste your key';

  @override
  String get identificationEnabled => 'Identification enabled';

  @override
  String get identificationDisabled => 'Not configured';

  @override
  String get identificationFallback => 'Online fallback';

  @override
  String get identificationFallbackHint =>
      'When the built-in model is unsure, the photo is sent to Pl@ntNet. Turned off, everything stays on the device.';

  @override
  String identificationStats(int local, int remote, int saved) {
    return '$local local identifications, $remote online, $saved calls saved';
  }

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
  String get outdoorHint => 'Balcony, garden, greenhouse: weather matters.';

  @override
  String get weather => 'Weather';

  @override
  String get weatherHint =>
      'For your outdoor plants, Flora checks today\'s rain and spares you a useless watering. Open-Meteo data, no account or key.';

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
  String weatherRainSkip(String names) {
    return 'Rain expected: no need to water $names today.';
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
      'A ZIP file with your plants, history, inventory, settings and photos. Your data is yours.';

  @override
  String get exporting => 'Preparing export…';

  @override
  String get exportError => 'Export failed. Please try again.';

  @override
  String get play => 'Play';

  @override
  String get timelapseHint => 'Tap to pause.';

  @override
  String notifLowStockOne(String name) {
    return 'You\'re almost out of $name.';
  }

  @override
  String notifLowStockMany(int count) {
    return '$count items are almost out.';
  }

  @override
  String get accountTitle => 'Account';

  @override
  String get signIn => 'Sign in';

  @override
  String get signInHint =>
      'An account backs up your plants, syncs them across your devices and lets you share a garden. Without one, everything stays on this phone.';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueWithEmail => 'Continue with email';

  @override
  String get emailHint => 'you@example.com';

  @override
  String get sendCode => 'Send me a code';

  @override
  String codeSent(String email) {
    return 'Code sent to $email.';
  }

  @override
  String get codeHint => '6-digit code';

  @override
  String get verifyCode => 'Verify';

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
  String get syncSyncing => 'Syncing…';

  @override
  String get authError => 'Couldn\'t sign in. Check the address and try again.';

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
      'The person must already have a Flora account with this address.';

  @override
  String get roleOwner => 'Owner';

  @override
  String get roleMember => 'Member';

  @override
  String get roleViewer => 'View only';

  @override
  String get invited => 'Invitation sent';

  @override
  String get inviteError =>
      'Couldn\'t invite: this address has no account yet.';

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
  String get diagnosisTitle => 'My plant has a problem';

  @override
  String get diagnosisHint =>
      'Photograph the leaves, stem or soil from a few angles. Results are leads, never certainties.';

  @override
  String get diagnosisSymptomsHint => 'What you noticed (optional)…';

  @override
  String get analyze => 'Analyze';

  @override
  String get analyzing => 'Analyzing…';

  @override
  String get diagnosisError =>
      'Couldn\'t analyze. Check your connection and try again.';

  @override
  String get diagnosisRefused => 'This photo couldn\'t be analyzed.';

  @override
  String get diagnosisUnauthorized =>
      'API key rejected. Check it in Profile › Diagnosis.';

  @override
  String get possibleCauses => 'Possible causes';

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
      'Photo analysis by Anthropic\'s Claude API, with your own key (console.anthropic.com). Photos are only sent when you start an analysis.';

  @override
  String get diagnosisEnabled => 'Diagnosis enabled';

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
  String get taskTitleHint => 'What needs doing?';

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
      'Sowing, greenhouse cleaning, ordering soil: keep it all here.';

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
    return 'Time for: $title';
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
  String get careIssues => 'Watch out for';

  @override
  String get careTips => 'Good habits';

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
  String get careRepotNone => 'No repotting: grown as an annual';

  @override
  String careTempIdeal(int min, int max) {
    return '$min to $max °C';
  }

  @override
  String careTempMin(int min) {
    return 'Handles down to $min °C';
  }

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
  String get careHumidityLow => 'Dry air is fine';

  @override
  String get careHumidityAverage => 'Average humidity';

  @override
  String get careHumidityHigh => 'Likes humid air';

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
  String get careSoilAquatic => 'No soil at all';

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
      'Guidance, not rules: your light, your pot and your air matter just as much.';

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
  String get careIssueOverwatering => 'Overwatering: soft, yellow leaves';

  @override
  String get careIssueUnderwatering => 'Underwatering: drooping leaves';

  @override
  String get careIssueRootRot => 'Root rot';

  @override
  String get careIssueSpiderMites => 'Spider mites (fine webbing)';

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
  String get careIssueSlugs => 'Slugs and snails';

  @override
  String get careIssuePowderyMildew => 'Powdery mildew';

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
  String get careIssueChlorosis => 'Chlorosis: pale leaves, green veins';

  @override
  String get careIssueBlossomEndRot => 'Blossom end rot';

  @override
  String get careTipFingerTest =>
      'Push a finger in: water when the top 2 cm are dry.';

  @override
  String get careTipDrySoilFirst =>
      'Let the soil dry out completely between waterings.';

  @override
  String get careTipNeverDryOut => 'Never let the soil dry out completely.';

  @override
  String get careTipEvenWatering =>
      'Water evenly: irregular watering splits the fruit.';

  @override
  String get careTipWaterAtBase => 'Water at the base, keeping the leaves dry.';

  @override
  String get careTipNoWaterOnLeaves =>
      'Keep water off the leaves: droplets leave marks.';

  @override
  String get careTipBottomWatering =>
      'Water from below: stand the pot in water for 20 minutes.';

  @override
  String get careTipFilteredWater =>
      'Use rain or filtered water: hard water browns the tips.';

  @override
  String get careTipRainwaterOnly =>
      'Water with rainwater: this plant hates lime.';

  @override
  String get careTipThirstyPlant => 'A thirsty one: check daily in summer.';

  @override
  String get careTipDroopSignal => 'It droops when thirsty: that is your cue.';

  @override
  String get careTipWinterDry => 'Keep it nearly dry through winter.';

  @override
  String get careTipWinterRest =>
      'Cut watering right back in winter: it rests.';

  @override
  String get careTipSummerDormant =>
      'It rests in summer: water very little then.';

  @override
  String get careTipNoWaterWhileSplitting =>
      'Do not water while it is splitting into new leaves.';

  @override
  String get careTipOrchidSoak =>
      'Soak the pot for 10 minutes, then drain fully.';

  @override
  String get careTipSoakMount => 'Soak the whole plant, then let it air-dry.';

  @override
  String get careTipDryUpsideDown =>
      'After soaking, dry it upside down: water in the centre rots it.';

  @override
  String get careTipWaterInTheCup =>
      'Fill the central cup and refresh the water weekly.';

  @override
  String get careTipNoSoil =>
      'It lives without soil: just rest it on a holder.';

  @override
  String get careTipGreenRoots =>
      'Green roots mean hydrated. Silvery roots mean water it.';

  @override
  String get careTipHumidityTray =>
      'Stand the pot on a tray of damp clay pebbles.';

  @override
  String get careTipNoDirectSun =>
      'Keep it out of direct sun: it scorches the leaves.';

  @override
  String get careTipToleratesLowLight =>
      'It copes with a dim room but grows faster near a window.';

  @override
  String get careTipToleratesNeglect =>
      'It forgives neglect: when in doubt, do not water.';

  @override
  String get careTipBrightForColor =>
      'The brighter the light, the stronger the colours.';

  @override
  String get careTipRotatePot =>
      'Turn the pot a quarter each week so it grows straight.';

  @override
  String get careTipHatesMoving =>
      'It hates being moved: find one spot and leave it there.';

  @override
  String get careTipWipeLeaves =>
      'Wipe the leaves: they breathe and catch light better.';

  @override
  String get careTipTrimToBushOut => 'Trim leggy stems and it will branch out.';

  @override
  String get careTipMonsteraSupport =>
      'Give it a moss pole: leaves get bigger and more split.';

  @override
  String get careTipShallowPot => 'A wide, shallow pot suits it better.';

  @override
  String get careTipLikesBeingPotbound =>
      'It flowers better when snug: repot rarely.';

  @override
  String get careTipTrunkStoresWater =>
      'The swollen base stores water: too little beats too much.';

  @override
  String get careTipPupsToShare =>
      'It makes pups: detach them to propagate or give away.';

  @override
  String get careTipKeepFlowerSpike =>
      'Do not cut a green flower spike: it can rebloom on it.';

  @override
  String get careTipDarkForRebloom =>
      'To rebloom, give it six weeks of long, cool nights.';

  @override
  String get careTipNotADesertCactus =>
      'Not a desert cactus: it likes shade and moisture.';

  @override
  String get careTipDeadheadFlowers =>
      'Remove spent flowers and it keeps blooming.';

  @override
  String get careTipPinchFlowers =>
      'Pinch off flower buds: the leaves stay tender.';

  @override
  String get careTipHarvestTop =>
      'Harvest from the top, above a pair of leaves.';

  @override
  String get careTipHarvestOutside =>
      'Pick the outer leaves: the centre keeps growing.';

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
      'Two trims a year is enough: June and late August.';

  @override
  String get careTipContainItsRoots =>
      'Grow it in a pot or add a root barrier: it spreads fast.';

  @override
  String get careTipMulchIt => 'Mulch the base: less watering, fewer weeds.';

  @override
  String get careTipAcidSoil =>
      'It needs acidic soil: skip all-purpose compost.';

  @override
  String get careTipBlueNeedsAcid =>
      'Blue flowers need acidic soil; in lime they turn pink.';

  @override
  String get careTipCitrusFertilizer =>
      'Use a dedicated citrus feed all through the growing season.';

  @override
  String get careTipNoFertilizer =>
      'No feeding: rich soil costs it scent and shape.';

  @override
  String get careTipNoNitrogen => 'Skip nitrogen feed: it makes its own.';

  @override
  String get careTipLetFoliageDieBack =>
      'Let the foliage yellow in place: it refuels the bulb.';

  @override
  String get careTipDiesBackInWinter =>
      'It vanishes in winter and returns in spring: that is normal.';

  @override
  String get careTipSummerOutdoors =>
      'Move it outside for summer, in shade for the first days.';

  @override
  String get careTipWinterIndoors => 'Bring it in before the first frost.';

  @override
  String get careTipWinterShelter => 'Overwinter it in a cool, bright room.';

  @override
  String get careTipWinterCool =>
      'A cool, bright winter (10–14 °C) does it good.';

  @override
  String get careTipCoolerIsBetter =>
      'It prefers cool: keep it away from radiators.';

  @override
  String get careTipHardyOutdoors =>
      'Hardy: it overwinters outdoors unprotected.';

  @override
  String get careTipShelterFromWind =>
      'Shelter it from wind: the foliage tears easily.';

  @override
  String get careTipAirFlow => 'Give it airflow: stagnant air invites disease.';

  @override
  String get careTipSpiderMiteWatch =>
      'Check under the leaves: spider mites love it.';

  @override
  String get careTipSlugWatch =>
      'Protect the young shoots from slugs in spring.';

  @override
  String get careTipBoxMothWatch =>
      'Watch for box moth: caterpillars and silk in the foliage.';

  @override
  String get careTipSapIrritant =>
      'Its sap irritates skin and eyes: wear gloves to prune.';

  @override
  String get careTipVeryToxic =>
      'Every part is highly toxic, including the smoke if burned.';

  @override
  String get careTipSharpSpines =>
      'Its spines are dangerous: keep it away from walkways.';

  @override
  String get careTipSplitsAreNormal =>
      'Leaves split with age: that is normal, not a disease.';

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
  String get fieldTemplatesHint =>
      'Create the fields you reuse across plants: they will be one tap away.';

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
      'Delete this document? The file will be removed from the device.';

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
  String get photoUrlInvalid => 'Invalid address: it must start with https://';

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
      'The page asks search engines not to index it. Anyone with the link can still see it.';

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
  String plantNumber(int number) {
    return 'No. $number';
  }

  @override
  String get searchByNumberHint => 'Tip: type #42 to find plant no. 42.';

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
  String get noGroupsYet =>
      'No groups yet. Create one to organise your items your way.';

  @override
  String get deleteGroupExplain =>
      'Items are not deleted: they simply go back to no group.';

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
      'Events are not deleted: they simply lose their category.';

  @override
  String get noEventCategoriesYet =>
      'No categories yet. Create one to colour your events.';

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
  String get statOldest => 'Longest with you';

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
  String get noWarnings => 'All is well in the garden.';

  @override
  String get recentPlantsSection => 'Recent plants';

  @override
  String get recentAdded => 'Added';

  @override
  String get recentUpdated => 'Updated';

  @override
  String get activityLogTitle => 'Activity log';

  @override
  String get activityEmpty =>
      'Nothing yet. The log fills up with your first care action.';

  @override
  String get activityPlantAdded => 'Added to the garden';

  @override
  String get activityPlantArchived => 'Archived';

  @override
  String get activityLocationNote => 'Location note';

  @override
  String get activityTaskDone => 'Task completed';

  @override
  String get archiveNameTitle => 'Archive name';

  @override
  String get archiveNameHint => 'Memorial, The past…';

  @override
  String get archiveNameExplain => 'Leave empty to keep the default name.';

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
  String get backupExplain =>
      'A .zip file with your data and photos. An open format: your data stays yours.';

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
  String get importErrorNotAZip => 'This file is not a Flora backup.';

  @override
  String get importErrorWrongApp => 'This backup comes from another app.';

  @override
  String get importErrorTooRecent =>
      'This backup comes from a newer version of Flora.';

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
  String get apiTitle => 'External API';

  @override
  String get apiExplain =>
      'Your data is reachable through your Supabase project\'s REST API, with your own key. Nothing is exposed without an account.';

  @override
  String get apiNotConnected => 'Connect an account to enable the API.';

  @override
  String get apiEndpoints => 'Endpoints';

  @override
  String get apiCopyBase => 'Copy base URL';

  @override
  String get apiCopied => 'URL copied';

  @override
  String get apiTokenHint =>
      'Authenticate with your Supabase session token (Authorization: Bearer header).';

  @override
  String get apiCopyToken => 'Copy access token';

  @override
  String get apiTokenCopied => 'Token copied';

  @override
  String get apiTokenWarning =>
      'Valid for a few hours. Revoked by signing out.';

  @override
  String get apiReadWrite => 'Read and write';

  @override
  String get apiOnlyYourGarden =>
      'Every request only sees gardens you belong to.';

  @override
  String get apiExample => 'Example';

  @override
  String get onbTodayTitle => 'Each morning, what needs doing';

  @override
  String get onbTodayBody => 'Watered? One tap, and it\'s noted.';

  @override
  String get onbCareTitle => 'Less watering in winter';

  @override
  String get onbCareBody =>
      'Intervals adjust on their own as the days get shorter.';

  @override
  String get onbGardenTitle => 'Rooms, photos, calendar';

  @override
  String get onbGardenBody => 'Each plant\'s history keeps itself.';

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
  String get aboutSourceWikidata =>
      'Species names in four languages, public domain';

  @override
  String get aboutSourceGbif =>
      'Taxonomy, families and photographed occurrences';

  @override
  String get aboutSourceOpenMeteo => 'Weather and forecast, no account or key';

  @override
  String aboutSpeciesCount(String count) {
    return '$count species searchable offline';
  }

  @override
  String get supportTitle => 'Flora is free';

  @override
  String get supportBody =>
      'Every feature is free. If the app is useful to you, you can give its developer a hand — once, no subscription.';

  @override
  String get supportNothingLocked => 'Nothing is reserved for those who give.';

  @override
  String supportGive(String price) {
    return 'Support · $price';
  }

  @override
  String get supportRestore => 'Restore my support';

  @override
  String get supportThanksTitle => 'Thank you';

  @override
  String get supportThanksBody =>
      'Your support is recorded. The app does not change: it was already complete.';

  @override
  String get supportUnavailable =>
      'The purchase is not available on this device.';

  @override
  String get supportFailed => 'The purchase did not go through.';

  @override
  String get supportNothingToRestore => 'No support to restore.';

  @override
  String get supportSettings => 'Support the developer';

  @override
  String get supportFreeForever => 'Free, no limits';

  @override
  String get supportAlready => 'Thank you for your support';

  @override
  String get supportNoThanks => 'Continue without';

  @override
  String get aboutTagline => 'Care for your plants and keep their story.';

  @override
  String get emptyGardenSubtitle =>
      'Add your first plant, with a photo if you like.';
}
