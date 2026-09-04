// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appName => 'Flora';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get save => 'Sichern';

  @override
  String get done => 'Fertig';

  @override
  String get continueLabel => 'Weiter';

  @override
  String get back => 'Zurück';

  @override
  String get delete => 'Löschen';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get add => 'Hinzufügen';

  @override
  String get search => 'Suchen';

  @override
  String get close => 'Schließen';

  @override
  String get undo => 'Rückgängig';

  @override
  String get later => 'Später';

  @override
  String get skip => 'Überspringen';

  @override
  String get next => 'Weiter';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get more => 'Mehr';

  @override
  String get seeAll => 'Alle anzeigen';

  @override
  String get optional => 'optional';

  @override
  String get none => 'Keine';

  @override
  String get genericError =>
      'Etwas hat nicht geklappt. Bitte erneut versuchen.';

  @override
  String get tabToday => 'Heute';

  @override
  String get tabPlants => 'Pflanzen';

  @override
  String get tabGarden => 'Garten';

  @override
  String get tabProfile => 'Profil';

  @override
  String greeting(String name) {
    return 'Hallo $name';
  }

  @override
  String get greetingAnonymous => 'Hallo';

  @override
  String careCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Aufgaben',
      one: '1 Aufgabe',
      zero: 'Nichts zu tun',
    );
    return '$_temp0';
  }

  @override
  String get sectionOverdue => 'Überfällig';

  @override
  String get sectionToday => 'Heute';

  @override
  String get sectionUpcoming => 'Demnächst';

  @override
  String get allDoneTitle => 'Alles in Ordnung';

  @override
  String get allDoneSubtitle => 'Deine Pflanzen brauchen heute nichts.';

  @override
  String get emptyGardenTitle => 'Dein Garten beginnt hier.';

  @override
  String get addFirstPlant => 'Meine erste Pflanze hinzufügen';

  @override
  String get yourGarden => 'Dein Garten';

  @override
  String get recentPhotos => 'Neueste Fotos';

  @override
  String plantCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Pflanzen',
      one: '1 Pflanze',
      zero: 'Keine Pflanzen',
    );
    return '$_temp0';
  }

  @override
  String get kindWatering => 'Gießen';

  @override
  String get kindFertilizing => 'Dünger';

  @override
  String get kindRepotting => 'Umtopfen';

  @override
  String get kindPruning => 'Schnitt';

  @override
  String get kindCleaning => 'Reinigung';

  @override
  String get kindTreatment => 'Behandlung';

  @override
  String get kindMeasurement => 'Messung';

  @override
  String get kindPhoto => 'Foto';

  @override
  String get kindNote => 'Notiz';

  @override
  String get verbWatering => 'Gießen';

  @override
  String get verbFertilizing => 'Düngen';

  @override
  String get verbRepotting => 'Umtopfen';

  @override
  String get verbPruning => 'Schneiden';

  @override
  String get verbCleaning => 'Reinigen';

  @override
  String get verbTreatment => 'Behandeln';

  @override
  String get verbMeasurement => 'Messen';

  @override
  String get verbPhoto => 'Foto';

  @override
  String get verbNote => 'Notiz';

  @override
  String get doneWatering => 'Gegossen';

  @override
  String get doneFertilizing => 'Gedüngt';

  @override
  String get doneRepotting => 'Umgetopft';

  @override
  String get donePruning => 'Geschnitten';

  @override
  String get doneCleaning => 'Gereinigt';

  @override
  String get doneTreatment => 'Behandelt';

  @override
  String get doneMeasurement => 'Gemessen';

  @override
  String get donePhoto => 'Foto hinzugefügt';

  @override
  String get doneNote => 'Notiz hinzugefügt';

  @override
  String get doneCustom => 'Erledigt';

  @override
  String actionDoneToast(String plant, String action) {
    return '$plant · $action';
  }

  @override
  String multiActionDone(int count, String action) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Pflanzen · $action',
      one: '1 Pflanze · $action',
    );
    return '$_temp0';
  }

  @override
  String get dueToday => 'Heute';

  @override
  String get dueTomorrow => 'Morgen';

  @override
  String dueInDays(int count) {
    return 'In $count Tagen';
  }

  @override
  String dueOverdue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage überfällig',
      one: '1 Tag überfällig',
    );
    return '$_temp0';
  }

  @override
  String get dueNone => 'Keine Erinnerung';

  @override
  String careDueLabel(String action, String when) {
    return '$action · $when';
  }

  @override
  String verbToday(String verb) {
    return 'Heute $verb';
  }

  @override
  String get plantsTitle => 'Pflanzen';

  @override
  String get searchPlants => 'Name, Art, Ort…';

  @override
  String get filters => 'Filter';

  @override
  String get sortBy => 'Sortieren nach';

  @override
  String get sortName => 'Name';

  @override
  String get sortNextCare => 'Nächste Pflege';

  @override
  String get sortRecent => 'Zuletzt hinzugefügt';

  @override
  String get filterLocation => 'Ort';

  @override
  String get filterNeedsAttention => 'Pflege nötig';

  @override
  String get filterFavorites => 'Favoriten';

  @override
  String get filterTag => 'Tag';

  @override
  String get clearFilters => 'Filter löschen';

  @override
  String get gridView => 'Raster';

  @override
  String get listView => 'Liste';

  @override
  String get noResultsTitle => 'Keine Ergebnisse';

  @override
  String get noResultsSubtitle => 'Versuch es mit einem anderen Wort.';

  @override
  String get emptyPlantsTitle => 'Noch keine Pflanzen';

  @override
  String get emptyPlantsSubtitle => 'Dein Garten beginnt hier.';

  @override
  String get addPlant => 'Pflanze hinzufügen';

  @override
  String selectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ausgewählt',
      one: '1 ausgewählt',
    );
    return '$_temp0';
  }

  @override
  String get select => 'Auswählen';

  @override
  String get move => 'Verschieben';

  @override
  String get archive => 'Archivieren';

  @override
  String get addTag => 'Tag hinzufügen';

  @override
  String get favorite => 'Favorit';

  @override
  String get unfavorite => 'Aus Favoriten entfernen';

  @override
  String movedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Pflanzen verschoben',
      one: '1 Pflanze verschoben',
    );
    return '$_temp0';
  }

  @override
  String archivedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Pflanzen archiviert',
      one: '1 Pflanze archiviert',
    );
    return '$_temp0';
  }

  @override
  String get newPlant => 'Neue Pflanze';

  @override
  String get stepPhotoTitle => 'Ein Foto?';

  @override
  String get stepPhotoSubtitle => 'Es wird das Gesicht deiner Pflanze.';

  @override
  String get takePhoto => 'Foto aufnehmen';

  @override
  String get choosePhoto => 'Foto auswählen';

  @override
  String get withoutPhoto => 'Ohne Foto fortfahren';

  @override
  String get changePhoto => 'Ändern';

  @override
  String get stepNameTitle => 'Wie heißt sie?';

  @override
  String get plantNameHint => 'Monstera im Wohnzimmer';

  @override
  String get speciesHint => 'Art (optional)';

  @override
  String get stepLocationTitle => 'Wo steht sie?';

  @override
  String get newLocationChip => 'Neu';

  @override
  String get noLocation => 'Kein Ort';

  @override
  String get finish => 'Fertig';

  @override
  String plantAdded(String name) {
    return '$name hinzugefügt';
  }

  @override
  String get moreOptions => 'Weitere Optionen';

  @override
  String get acquiredAt => 'Erworben am';

  @override
  String get source => 'Herkunft';

  @override
  String get sourceHint => 'Gärtnerei, Ableger von Freunden…';

  @override
  String get price => 'Preis';

  @override
  String get potSize => 'Topfdurchmesser';

  @override
  String get notes => 'Notizen';

  @override
  String get notesHint => 'Alles, was nützlich ist…';

  @override
  String get wateringEvery => 'Gießen';

  @override
  String get fertilizingEvery => 'Dünger';

  @override
  String everyDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Alle $count Tage',
      one: 'Jeden Tag',
    );
    return '$_temp0';
  }

  @override
  String get freeLimitTitle => 'Limit erreicht';

  @override
  String freeLimitBody(int count) {
    return 'Die kostenlose Version umfasst $count Pflanzen. Mit Premium ist deine Sammlung unbegrenzt.';
  }

  @override
  String sinceDate(String date) {
    return 'Seit $date';
  }

  @override
  String get nextCare => 'Nächste Pflege';

  @override
  String get addAction => 'Aktion hinzufügen';

  @override
  String get history => 'Verlauf';

  @override
  String get seeFullHistory => 'Gesamter Verlauf';

  @override
  String get growth => 'Wachstum';

  @override
  String get photos => 'Fotos';

  @override
  String get info => 'Details';

  @override
  String get cuttings => 'Ableger';

  @override
  String get createCutting => 'Ableger anlegen';

  @override
  String cuttingOf(String name) {
    return 'Ableger von $name';
  }

  @override
  String get parentPlant => 'Mutterpflanze';

  @override
  String get schedule => 'Pflegeplan';

  @override
  String get editPlant => 'Pflanze bearbeiten';

  @override
  String get archivePlant => 'Pflanze archivieren';

  @override
  String get archiveReasonTitle => 'Was ist passiert?';

  @override
  String get reasonDied => 'Eingegangen';

  @override
  String get reasonGiven => 'Verschenkt';

  @override
  String get reasonSold => 'Verkauft';

  @override
  String get reasonOther => 'Anderes';

  @override
  String plantArchived(String name) {
    return '$name archiviert';
  }

  @override
  String get restore => 'Wiederherstellen';

  @override
  String plantRestored(String name) {
    return '$name wiederhergestellt';
  }

  @override
  String get deleteForever => 'Endgültig löschen';

  @override
  String get deleteForeverConfirm =>
      'Diese Pflanze und ihr gesamter Verlauf werden gelöscht.';

  @override
  String get noHistoryTitle => 'Noch keine Aktionen';

  @override
  String get noHistorySubtitle => 'Jede Pflege erscheint hier.';

  @override
  String get noPhotosTitle => 'Keine Fotos';

  @override
  String get noPhotosSubtitle =>
      'Füge ein Foto hinzu, um das Wachstum zu verfolgen.';

  @override
  String get setAsPrimary => 'Als Hauptfoto';

  @override
  String get deletePhoto => 'Foto löschen';

  @override
  String get health => 'Zustand';

  @override
  String get healthHealthy => 'Gesund';

  @override
  String get healthWatch => 'Beobachten';

  @override
  String get healthSick => 'Krank';

  @override
  String get noSchedule => 'Keine Erinnerungen';

  @override
  String get addRoutine => 'Routine hinzufügen';

  @override
  String get frequency => 'Häufigkeit';

  @override
  String get strategyFixed => 'Fest';

  @override
  String get strategySeasonal => 'Saisonal';

  @override
  String get strategyManual => 'Manuell';

  @override
  String get strategySeasonalHint => 'Im Winter seltener, im Sommer öfter.';

  @override
  String get strategyManualHint => 'Keine automatische Erinnerung.';

  @override
  String get enabled => 'Aktiv';

  @override
  String get interval => 'Intervall';

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage',
      one: '1 Tag',
    );
    return '$_temp0';
  }

  @override
  String lastDone(String date) {
    return 'Zuletzt: $date';
  }

  @override
  String nextDue(String date) {
    return 'Nächste: $date';
  }

  @override
  String get deleteRoutine => 'Routine löschen';

  @override
  String get snooze => 'Später';

  @override
  String snoozed(String name) {
    return '$name · auf morgen verschoben';
  }

  @override
  String get measurements => 'Messungen';

  @override
  String measurementDelta(String delta, String date) {
    return '$delta seit $date';
  }

  @override
  String get whatDidYouDo => 'Was hast du gemacht?';

  @override
  String get when => 'Wann';

  @override
  String get noteHint => 'Notiz hinzufügen…';

  @override
  String get quantity => 'Menge';

  @override
  String get value => 'Wert';

  @override
  String get measureHeight => 'Höhe';

  @override
  String get measureWidth => 'Breite';

  @override
  String get measureLeaves => 'Blätter';

  @override
  String get measurePot => 'Topf';

  @override
  String get record => 'Sichern';

  @override
  String get addNote => 'Notiz hinzufügen';

  @override
  String get addPhoto => 'Foto hinzufügen';

  @override
  String get camera => 'Kamera';

  @override
  String get gallery => 'Fotomediathek';

  @override
  String get photoError =>
      'Foto konnte nicht hinzugefügt werden. Bitte erneut versuchen.';

  @override
  String get newActionType => 'Neuer Aktionstyp';

  @override
  String get actionTypeLabel => 'Name';

  @override
  String get actionTypeLabelHint => 'Besprühen';

  @override
  String get actionTypeEmoji => 'Emoji';

  @override
  String get actionTypes => 'Aktionstypen';

  @override
  String get actionTypesHint =>
      'Erstelle eigene Aktionen neben den integrierten.';

  @override
  String get deleteActionType => 'Diesen Typ löschen';

  @override
  String get builtin => 'Integriert';

  @override
  String get gardenTitle => 'Garten';

  @override
  String get locations => 'Orte';

  @override
  String get newLocationTitle => 'Neuer Ort';

  @override
  String get locationName => 'Name';

  @override
  String get locationNameHint => 'Wohnzimmer';

  @override
  String get locationIcon => 'Symbol';

  @override
  String get parentLocation => 'In';

  @override
  String get noParent => 'Keiner';

  @override
  String get light => 'Licht';

  @override
  String get lightLow => 'Wenig';

  @override
  String get lightMedium => 'Mittel';

  @override
  String get lightHigh => 'Hell';

  @override
  String get orientation => 'Ausrichtung';

  @override
  String get orientationHint => 'Südwest';

  @override
  String get deleteLocation => 'Ort löschen';

  @override
  String get deleteLocationHint => 'Pflanzen werden nicht gelöscht.';

  @override
  String get noLocationsTitle => 'Keine Orte';

  @override
  String get noLocationsSubtitle =>
      'Lege ein Wohnzimmer, einen Balkon, ein Gewächshaus an…';

  @override
  String get editLocation => 'Ort bearbeiten';

  @override
  String get noPlantsHereTitle => 'Keine Pflanzen hier';

  @override
  String get noPlantsHereSubtitle =>
      'Verschiebe Pflanzen hierher oder füge eine hinzu.';

  @override
  String get chooseLocation => 'Ort wählen';

  @override
  String get defaultLivingRoom => 'Wohnzimmer';

  @override
  String get defaultKitchen => 'Küche';

  @override
  String get defaultBedroom => 'Schlafzimmer';

  @override
  String get defaultBalcony => 'Balkon';

  @override
  String get defaultOffice => 'Büro';

  @override
  String get defaultBathroom => 'Bad';

  @override
  String get defaultGarden => 'Garten';

  @override
  String get defaultGreenhouse => 'Gewächshaus';

  @override
  String get profileTitle => 'Profil';

  @override
  String get yourName => 'Dein Vorname';

  @override
  String get yourNameHint => 'Vorname';

  @override
  String get appearance => 'Darstellung';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get reduceMotion => 'Bewegung reduzieren';

  @override
  String get reduceMotionHint =>
      'Standardmäßig folgt Flora der Systemeinstellung.';

  @override
  String get notifications => 'Mitteilungen';

  @override
  String get enableNotifications => 'Tägliche Erinnerung';

  @override
  String get notificationTime => 'Uhrzeit';

  @override
  String get quietDays => 'Ruhige Tage';

  @override
  String get notificationPreview => 'Vorschau';

  @override
  String get notificationHint =>
      'Eine Mitteilung pro Tag, nur wenn eine Pflanze dich braucht.';

  @override
  String get notificationPermissionDenied =>
      'Erlaube Mitteilungen in den Einstellungen deines Telefons.';

  @override
  String get archives => 'Frühere Pflanzen';

  @override
  String get noArchivesTitle => 'Keine früheren Pflanzen';

  @override
  String get noArchivesSubtitle => 'Archivierte Pflanzen erscheinen hier.';

  @override
  String archivedOn(String date) {
    return 'Archiviert am $date';
  }

  @override
  String get units => 'Einheiten';

  @override
  String get metric => 'Metrisch';

  @override
  String get imperial => 'Imperial';

  @override
  String get language => 'Sprache';

  @override
  String get languageSystem => 'System';

  @override
  String get account => 'Konto';

  @override
  String get localAccount => 'Daten auf diesem Gerät';

  @override
  String get localAccountHint =>
      'Deine Pflanzen und Fotos bleiben privat auf diesem Telefon. Konten und Synchronisierung folgen in einer späteren Version.';

  @override
  String get about => 'Über';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String get premium => 'Premium';

  @override
  String get premiumBody =>
      'Unbegrenzt Pflanzen, Bestimmung, Diagnose, Zusammenarbeit. Bald verfügbar.';

  @override
  String premiumPlantCount(int count, int limit) {
    return '$count / $limit Pflanzen';
  }

  @override
  String get tags => 'Tags';

  @override
  String get newTag => 'Neuer Tag';

  @override
  String get tagNameHint => 'Tropisch, Selten, Beobachten…';

  @override
  String get noTags => 'Keine Tags';

  @override
  String get manageTags => 'Tags verwalten';

  @override
  String get onboardingTitle => 'Dein Garten, ganz einfach.';

  @override
  String get onboardingSubtitle =>
      'Pflege deine Pflanzen und bewahre ihre Geschichte.';

  @override
  String get askNameTitle => 'Wie heißt du?';

  @override
  String get askNameSubtitle =>
      'Um dich jeden Morgen zu begrüßen. Du kannst es später ändern.';

  @override
  String get notificationAskTitle => 'Eine nützliche Erinnerung pro Tag';

  @override
  String get notificationAskBody =>
      'Eine einzige Mitteilung pro Tag, zur gewünschten Uhrzeit, nur wenn eine Pflanze sie braucht.';

  @override
  String get enable => 'Aktivieren';

  @override
  String get notNow => 'Jetzt nicht';

  @override
  String get notificationTitle => 'Deine Pflanzen';

  @override
  String get notificationChannel => 'Pflege-Erinnerungen';

  @override
  String notifWaterOne(String name) {
    return '$name braucht heute wahrscheinlich Wasser.';
  }

  @override
  String notifWaterMany(String names) {
    return '$names brauchen heute wahrscheinlich Wasser.';
  }

  @override
  String notifOther(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weitere Aufgaben warten.',
      one: '1 weitere Aufgabe wartet.',
    );
    return '$_temp0';
  }

  @override
  String notifOnlyOther(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Aufgaben warten heute.',
      one: '1 Aufgabe wartet heute.',
    );
    return '$_temp0';
  }

  @override
  String andJoin(String a, String b) {
    return '$a und $b';
  }

  @override
  String get listSeparator => ', ';

  @override
  String get timelineToday => 'Heute';

  @override
  String get timelineYesterday => 'Gestern';

  @override
  String get photoAddedToast => 'Foto hinzugefügt';

  @override
  String get noteAddedToast => 'Notiz hinzugefügt';

  @override
  String get actionAddedToast => 'Aktion gesichert';

  @override
  String locationCreated(String name) {
    return '$name angelegt';
  }

  @override
  String get saved => 'Gesichert';

  @override
  String get gardenLocations => 'Orte';

  @override
  String get gardenInventory => 'Inventar';

  @override
  String get gardenCalendar => 'Kalender';

  @override
  String get inventoryTitle => 'Inventar';

  @override
  String get newItem => 'Neuer Artikel';

  @override
  String get editItem => 'Artikel bearbeiten';

  @override
  String get itemName => 'Name';

  @override
  String get itemNameHint => 'Grünpflanzendünger';

  @override
  String get category => 'Kategorie';

  @override
  String get catFertilizer => 'Dünger';

  @override
  String get catSoil => 'Erden';

  @override
  String get catSubstrate => 'Substrate';

  @override
  String get catPot => 'Töpfe';

  @override
  String get catTool => 'Werkzeuge';

  @override
  String get catTreatment => 'Behandlungen';

  @override
  String get catSeed => 'Samen';

  @override
  String get catAccessory => 'Zubehör';

  @override
  String get unit => 'Einheit';

  @override
  String get unitPieces => 'Stück';

  @override
  String get lowThreshold => 'Schwelle für niedrigen Bestand';

  @override
  String get lowStock => 'Wenig Vorrat';

  @override
  String remaining(String amount) {
    return '$amount übrig';
  }

  @override
  String get noInventoryTitle => 'Leeres Inventar';

  @override
  String get noInventorySubtitle =>
      'Dünger, Erde, Töpfe, Werkzeuge: behalte deine Vorräte im Blick.';

  @override
  String get deleteItem => 'Artikel löschen';

  @override
  String lowStockItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Artikel werden knapp',
      one: '1 Artikel wird knapp',
    );
    return '$_temp0';
  }

  @override
  String get calendarTitle => 'Kalender';

  @override
  String get agenda => 'Agenda';

  @override
  String get month => 'Monat';

  @override
  String get noEventsTitle => 'Nichts geplant';

  @override
  String get noEventsSubtitle => 'Anstehende Pflege erscheint hier.';

  @override
  String get projected => 'geplant';

  @override
  String get today => 'Heute';

  @override
  String get measurementsTitle => 'Messungen';

  @override
  String get addMeasurement => 'Messung hinzufügen';

  @override
  String sinceFirst(String delta, String date) {
    return '$delta seit $date';
  }

  @override
  String get qrCode => 'QR-Code';

  @override
  String get qrHint =>
      'Auf den Topf kleben: Scannen öffnet direkt die Pflanze.';

  @override
  String get scan => 'Scannen';

  @override
  String get scanHint => 'Richte die Kamera auf den QR-Code einer Pflanze.';

  @override
  String get unknownQr => 'Dieser QR-Code gehört nicht zu deinem Garten.';

  @override
  String get shareQr => 'Teilen';

  @override
  String get printLabels => 'PDF-Etiketten';

  @override
  String get labels => 'Etiketten';

  @override
  String get cameraPermission =>
      'Erlaube den Kamerazugriff in den Einstellungen.';

  @override
  String get identify => 'Bestimmen';

  @override
  String get identifying => 'Analyse läuft…';

  @override
  String get identifyTitle => 'Ist es…';

  @override
  String get identifyHint => 'Vorschläge zum Bestätigen, keine Gewissheiten.';

  @override
  String get identifyNone => 'Keine zuverlässige Übereinstimmung.';

  @override
  String get identifyError =>
      'Bestimmung nicht möglich. Prüfe deine Verbindung und versuche es erneut.';

  @override
  String get useThis => 'Verwenden';

  @override
  String get identificationSettings => 'Bestimmung';

  @override
  String get identificationHint =>
      'Artbestimmung anhand eines Fotos über Pl@ntNet. Erstelle einen kostenlosen Schlüssel auf my.plantnet.org und füge ihn hier ein.';

  @override
  String get apiKey => 'API-Schlüssel';

  @override
  String get apiKeyHint => 'Schlüssel einfügen';

  @override
  String get identificationEnabled => 'Bestimmung aktiviert';

  @override
  String get identificationDisabled => 'Nicht konfiguriert';

  @override
  String confidence(int percent) {
    return '$percent %';
  }

  @override
  String get speciesSet => 'Art aktualisiert';

  @override
  String get compare => 'Vergleichen';

  @override
  String get compareHint => 'Ziehen zum Vergleichen.';

  @override
  String get before => 'Vorher';

  @override
  String get after => 'Nachher';

  @override
  String get comparePickFirst => 'Wähle zwei Fotos.';
}
