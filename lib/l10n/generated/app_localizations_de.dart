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
  String get onboardingTitle => 'Alle deine Pflanzen, hier';

  @override
  String get onboardingSubtitle =>
      'Füge sie eine nach der anderen hinzu, mit Foto, wenn du magst.';

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
  String get identifyOnDevice =>
      'Auf deinem Gerät erkannt. Wähle die passende Art.';

  @override
  String get identifyViaPlantNet =>
      'Online von Pl@ntNet erkannt. Wähle die passende Art.';

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
      'Die Arterkennung läuft zuerst auf deinem Gerät, ohne Netz. Wenn das Modell unsicher ist, kann das Foto zur Klärung an Pl@ntNet gehen.';

  @override
  String get apiKey => 'API-Schlüssel';

  @override
  String get apiKeyHint => 'Schlüssel einfügen';

  @override
  String get identificationEnabled => 'Bestimmung aktiviert';

  @override
  String get identificationDisabled => 'Nicht konfiguriert';

  @override
  String get identificationFallback => 'Online-Rückfall';

  @override
  String get identificationFallbackHint =>
      'Wenn das integrierte Modell unsicher ist, wird das Foto an Pl@ntNet gesendet. Ausgeschaltet bleibt alles auf dem Gerät.';

  @override
  String identificationStats(int local, int remote, int saved) {
    return '$local lokale Bestimmungen, $remote online, $saved Anfragen gespart';
  }

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

  @override
  String get outdoor => 'Draußen';

  @override
  String get outdoorHint => 'Balkon, Garten, Gewächshaus: das Wetter zählt.';

  @override
  String get weather => 'Wetter';

  @override
  String get weatherHint =>
      'Für deine Pflanzen draußen prüft Flora den Regen des Tages und erspart dir unnötiges Gießen. Open-Meteo-Daten, ohne Konto oder Schlüssel.';

  @override
  String get weatherPlace => 'Ort';

  @override
  String get weatherSearchHint => 'Stadt…';

  @override
  String get weatherNone => 'Kein Ort';

  @override
  String get weatherRemove => 'Ort entfernen';

  @override
  String get weatherNoResults => 'Kein Ort gefunden.';

  @override
  String weatherRainSkip(String names) {
    return 'Regen erwartet: $names muss heute nicht gegossen werden.';
  }

  @override
  String get postpone => 'Verschieben';

  @override
  String postponedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Gießvorgänge auf morgen verschoben',
      one: '1 Gießen auf morgen verschoben',
    );
    return '$_temp0';
  }

  @override
  String get condClear => 'Klar';

  @override
  String get condPartlyCloudy => 'Teils bewölkt';

  @override
  String get condCloudy => 'Bewölkt';

  @override
  String get condFog => 'Nebel';

  @override
  String get condDrizzle => 'Nieselregen';

  @override
  String get condRain => 'Regen';

  @override
  String get condSnow => 'Schnee';

  @override
  String get condThunderstorm => 'Gewitter';

  @override
  String rainChance(int percent) {
    return '$percent % Regen';
  }

  @override
  String get dataSection => 'Daten';

  @override
  String get exportData => 'Meine Daten exportieren';

  @override
  String get exportHint =>
      'Eine ZIP-Datei mit deinen Pflanzen, Verläufen, Inventar, Einstellungen und Fotos. Deine Daten gehören dir.';

  @override
  String get exporting => 'Export wird vorbereitet…';

  @override
  String get exportError => 'Export fehlgeschlagen. Bitte erneut versuchen.';

  @override
  String get play => 'Abspielen';

  @override
  String get timelapseHint => 'Tippen zum Pausieren.';

  @override
  String notifLowStockOne(String name) {
    return '$name ist fast aufgebraucht.';
  }

  @override
  String notifLowStockMany(int count) {
    return '$count Artikel sind fast aufgebraucht.';
  }

  @override
  String get accountTitle => 'Konto';

  @override
  String get signIn => 'Anmelden';

  @override
  String get signInHint =>
      'Ein Konto sichert deine Pflanzen, synchronisiert sie zwischen Geräten und erlaubt das Teilen eines Gartens. Ohne Konto bleibt alles auf diesem Telefon.';

  @override
  String get continueWithApple => 'Mit Apple fortfahren';

  @override
  String get continueWithGoogle => 'Mit Google fortfahren';

  @override
  String get continueWithEmail => 'Mit E-Mail fortfahren';

  @override
  String get emailHint => 'du@beispiel.ch';

  @override
  String get sendCode => 'Code senden';

  @override
  String codeSent(String email) {
    return 'Code an $email gesendet.';
  }

  @override
  String get codeHint => '6-stelliger Code';

  @override
  String get verifyCode => 'Bestätigen';

  @override
  String get signOut => 'Abmelden';

  @override
  String get signOutConfirm => 'Deine Daten bleiben auf diesem Telefon.';

  @override
  String get signedInAs => 'Angemeldet';

  @override
  String get syncNow => 'Jetzt synchronisieren';

  @override
  String syncIdle(String time) {
    return 'Aktuell · $time';
  }

  @override
  String get syncNever => 'Noch nicht synchronisiert';

  @override
  String syncPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ausstehende Änderungen',
      one: '1 ausstehende Änderung',
    );
    return '$_temp0';
  }

  @override
  String get syncOffline => 'Offline · wird automatisch fortgesetzt';

  @override
  String get syncError => 'Synchronisierungsfehler';

  @override
  String get syncSyncing => 'Synchronisiere…';

  @override
  String get authError =>
      'Anmeldung nicht möglich. Prüfe die Adresse und versuche es erneut.';

  @override
  String get appleUnavailable =>
      'Apple-Anmeldung ist auf iPhone und iPad verfügbar.';

  @override
  String get synchronization => 'Synchronisierung';

  @override
  String get membersTitle => 'Mitglieder';

  @override
  String get shareGarden => 'Garten teilen';

  @override
  String get inviteMember => 'Einladen';

  @override
  String get inviteHint =>
      'Die Person braucht bereits ein Flora-Konto mit dieser Adresse.';

  @override
  String get roleOwner => 'Eigentümer';

  @override
  String get roleMember => 'Mitglied';

  @override
  String get roleViewer => 'Nur lesen';

  @override
  String get invited => 'Einladung gesendet';

  @override
  String get inviteError =>
      'Einladung nicht möglich: diese Adresse hat noch kein Konto.';

  @override
  String get removeMember => 'Aus dem Garten entfernen';

  @override
  String get readOnlyHint => 'Du siehst diesen Garten nur lesend.';

  @override
  String byUser(String name) {
    return 'von $name';
  }

  @override
  String get you => 'du';

  @override
  String get diagnosisTitle => 'Meine Pflanze hat ein Problem';

  @override
  String get diagnosisHint =>
      'Fotografiere Blätter, Stängel oder Erde aus mehreren Winkeln. Ergebnisse sind Hinweise, keine Gewissheiten.';

  @override
  String get diagnosisSymptomsHint => 'Was dir aufgefallen ist (optional)…';

  @override
  String get analyze => 'Analysieren';

  @override
  String get analyzing => 'Analyse läuft…';

  @override
  String get diagnosisError =>
      'Analyse nicht möglich. Prüfe deine Verbindung und versuche es erneut.';

  @override
  String get diagnosisRefused => 'Dieses Foto konnte nicht analysiert werden.';

  @override
  String get diagnosisUnauthorized =>
      'API-Schlüssel abgelehnt. Prüfe ihn unter Profil › Diagnose.';

  @override
  String get possibleCauses => 'Mögliche Ursachen';

  @override
  String get urgentHint => 'Schnell handeln';

  @override
  String get saveToJournal => 'Im Verlauf speichern';

  @override
  String get markWatch => 'Als „beobachten“ markieren';

  @override
  String get diagnosisSettings => 'Diagnose';

  @override
  String get diagnosisSettingsHint =>
      'Fotoanalyse über die Claude-API von Anthropic mit deinem eigenen Schlüssel (console.anthropic.com). Fotos werden nur gesendet, wenn du eine Analyse startest.';

  @override
  String get diagnosisEnabled => 'Diagnose aktiviert';

  @override
  String get addPhotos => 'Fotos hinzufügen';

  @override
  String photosCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Fotos',
      one: '1 Foto',
    );
    return '$_temp0';
  }

  @override
  String get diagnosisSaved => 'Diagnose im Verlauf gespeichert';

  @override
  String get speciesInfo => 'Art';

  @override
  String get speciesSource =>
      'Quelle: GBIF — Global Biodiversity Information Facility';

  @override
  String get speciesCommonNames => 'Trivialnamen';

  @override
  String get speciesFamily => 'Familie';

  @override
  String get speciesOrder => 'Ordnung';

  @override
  String get speciesGenus => 'Gattung';

  @override
  String get speciesStatus => 'Status';

  @override
  String get speciesOpenGbif => 'Auf GBIF ansehen';

  @override
  String get speciesNotFound => 'Art in GBIF nicht gefunden.';

  @override
  String get speciesLoading => 'Suche in GBIF…';

  @override
  String get speciesPhotos => 'Beobachtungen';

  @override
  String speciesPhotoCredit(String author, String license) {
    return '$author · $license';
  }

  @override
  String get speciesSuggestions => 'Vorschläge';

  @override
  String get speciesUseName => 'Diesen Namen verwenden';

  @override
  String get speciesStatusAccepted => 'Akzeptierter Name';

  @override
  String get speciesStatusSynonym => 'Synonym';

  @override
  String get speciesPickerTitle => 'Art auswählen';

  @override
  String get speciesSearchHint => 'Trivialname, lateinischer Name, Familie…';

  @override
  String get speciesInGarden => 'In Ihrem Garten';

  @override
  String get speciesCommonList => 'Gängige Arten';

  @override
  String get speciesGbifResults => 'Alle Arten (GBIF)';

  @override
  String speciesGbifCount(int count) {
    return '$count passende Arten';
  }

  @override
  String speciesUseText(String name) {
    return '„$name“ verwenden';
  }

  @override
  String get speciesNoResults => 'Keine Art gefunden';

  @override
  String get speciesOffline =>
      'Die vollständige Liste benötigt eine Verbindung. Gängige Arten bleiben verfügbar.';

  @override
  String get speciesBrowse => 'Vollständige Liste';

  @override
  String get speciesCatAll => 'Alle';

  @override
  String get speciesCatIndoor => 'Zimmerpflanzen';

  @override
  String get speciesCatSucculent => 'Sukkulenten';

  @override
  String get speciesCatHerb => 'Kräuter';

  @override
  String get speciesCatVegetable => 'Gemüse';

  @override
  String get speciesCatFruit => 'Obst';

  @override
  String get speciesCatFlower => 'Blumen';

  @override
  String get speciesCatTree => 'Bäume und Sträucher';

  @override
  String get gardenTasks => 'Aufgaben';

  @override
  String get tasks => 'Aufgaben';

  @override
  String get newTask => 'Neue Aufgabe';

  @override
  String get editTask => 'Aufgabe bearbeiten';

  @override
  String get taskTitleHint => 'Was ist zu tun?';

  @override
  String get taskDescriptionHint => 'Details (optional)';

  @override
  String get taskPlant => 'Pflanze';

  @override
  String get taskNoPlant => 'Ohne Pflanze';

  @override
  String get taskDue => 'Fällig';

  @override
  String get taskNoDue => 'Ohne Datum';

  @override
  String get taskTime => 'Uhrzeit';

  @override
  String get taskAllDay => 'Ganztägig';

  @override
  String get taskRecurrence => 'Wiederholung';

  @override
  String get taskRecurrenceNone => 'Keine';

  @override
  String get taskEvery => 'Alle';

  @override
  String recurrenceLabel(String unit, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Alle $count Stunden',
      one: 'Jede Stunde',
    );
    String _temp1 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Alle $count Tage',
      one: 'Jeden Tag',
    );
    String _temp2 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Alle $count Wochen',
      one: 'Jede Woche',
    );
    String _temp3 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Alle $count Monate',
      one: 'Jeden Monat',
    );
    String _temp4 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Alle $count Jahre',
      one: 'Jedes Jahr',
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
  String get unitHours => 'Stunden';

  @override
  String get unitDays => 'Tage';

  @override
  String get unitWeeks => 'Wochen';

  @override
  String get unitMonths => 'Monate';

  @override
  String get unitYears => 'Jahre';

  @override
  String get taskFilterOpen => 'Offen';

  @override
  String get taskFilterOverdue => 'Überfällig';

  @override
  String get taskFilterDone => 'Erledigt';

  @override
  String get taskSectionOverdue => 'Überfällig';

  @override
  String get taskSectionToday => 'Heute';

  @override
  String get taskSectionUpcoming => 'Demnächst';

  @override
  String get taskSectionNoDate => 'Ohne Datum';

  @override
  String get noTasksTitle => 'Keine Aufgaben';

  @override
  String get noTasksSubtitle =>
      'Aussaat, Gewächshaus putzen, Erde bestellen: alles hier festhalten.';

  @override
  String get noDoneTasks => 'Noch nichts erledigt';

  @override
  String taskDoneToast(String title) {
    return '$title · Erledigt';
  }

  @override
  String taskNextToast(String title, String date) {
    return '$title · Nächstes Mal $date';
  }

  @override
  String get taskDeleted => 'Aufgabe gelöscht';

  @override
  String get deleteTask => 'Aufgabe löschen';

  @override
  String get reopenTask => 'Wieder öffnen';

  @override
  String taskDoneOn(String date) {
    return 'Erledigt $date';
  }

  @override
  String taskOverdueSince(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage überfällig',
      one: '1 Tag überfällig',
    );
    return '$_temp0';
  }

  @override
  String taskDueIn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'In $count Tagen',
      one: 'Morgen',
    );
    return '$_temp0';
  }

  @override
  String get tasksTodayTitle => 'Aufgaben';

  @override
  String get choosePlant => 'Pflanze auswählen';

  @override
  String notifTasksOne(String title) {
    return 'Aufgabe: $title.';
  }

  @override
  String notifTasksMany(int count, String titles) {
    return '$count Aufgaben: $titles.';
  }

  @override
  String notifTaskDue(String title) {
    return 'Jetzt fällig: $title';
  }

  @override
  String get careGuide => 'Pflegehinweise';

  @override
  String get careGuideSubtitle => 'Wann gießen, wie viel Licht, worauf achten.';

  @override
  String get careHowTo => 'So pflegen Sie sie';

  @override
  String get careWatering => 'Gießen';

  @override
  String get careLight => 'Licht';

  @override
  String get careHumidity => 'Luftfeuchtigkeit';

  @override
  String get careTemperature => 'Temperatur';

  @override
  String get careSoil => 'Substrat';

  @override
  String get careFertilizing => 'Dünger';

  @override
  String get careRepotting => 'Umtopfen';

  @override
  String get careToxicity => 'Giftigkeit';

  @override
  String get careDifficulty => 'Schwierigkeit';

  @override
  String get carePropagation => 'Vermehrung';

  @override
  String get careIssues => 'Darauf achten';

  @override
  String get careTips => 'Gute Gewohnheiten';

  @override
  String careEveryDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Alle $count Tage',
      one: 'Täglich',
    );
    return '$_temp0';
  }

  @override
  String careWateringNow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Zurzeit alle $count Tage',
      one: 'Zurzeit täglich',
    );
    return '$_temp0';
  }

  @override
  String careWateringSeasons(int summer, int winter) {
    return '$summer Tage in der Saison · $winter Tage im Winter';
  }

  @override
  String careFertilizeSeason(String from, String to) {
    return 'von $from bis $to';
  }

  @override
  String get careNoFertilizer => 'Kein Dünger nötig';

  @override
  String careRepotMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Alle $count Monate',
      one: 'Jeden Monat',
    );
    return '$_temp0';
  }

  @override
  String careRepotYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Alle $count Jahre',
      one: 'Jedes Jahr',
    );
    return '$_temp0';
  }

  @override
  String get careRepotNone => 'Kein Umtopfen: einjährige Kultur';

  @override
  String careTempIdeal(int min, int max) {
    return '$min bis $max °C';
  }

  @override
  String careTempMin(int min) {
    return 'Verträgt bis $min °C';
  }

  @override
  String get careLightShade => 'Schatten';

  @override
  String get careLightLow => 'Wenig Licht';

  @override
  String get careLightIndirect => 'Indirektes Licht';

  @override
  String get careLightBright => 'Helles indirektes Licht';

  @override
  String get careLightSome => 'Ein paar Stunden Sonne';

  @override
  String get careLightFull => 'Volle Sonne';

  @override
  String get careHumidityLow => 'Trockene Luft ist in Ordnung';

  @override
  String get careHumidityAverage => 'Normale Luftfeuchtigkeit';

  @override
  String get careHumidityHigh => 'Mag feuchte Luft';

  @override
  String get careDifficultyEasy => 'Einfach';

  @override
  String get careDifficultyMedium => 'Mittel';

  @override
  String get careDifficultyDemanding => 'Anspruchsvoll';

  @override
  String get careToxicSafe => 'Keine bekannte Gefahr';

  @override
  String get careToxicMild => 'Leicht reizend';

  @override
  String get careToxicToxic => 'Giftig beim Verzehr';

  @override
  String get careToxicUnknown => 'Giftigkeit unbekannt';

  @override
  String get careToxicPets => 'Von Haustieren und Kindern fernhalten.';

  @override
  String get careSoilStandard => 'Universalerde';

  @override
  String get careSoilDraining => 'Gut durchlässige Erde';

  @override
  String get careSoilCactus => 'Kakteenerde';

  @override
  String get careSoilOrchid => 'Orchideensubstrat';

  @override
  String get careSoilAcidic => 'Rhododendronerde';

  @override
  String get careSoilRich => 'Nährstoffreiche Erde';

  @override
  String get careSoilAquatic => 'Ganz ohne Substrat';

  @override
  String get carePropCutting => 'Stecklinge';

  @override
  String get carePropLeaf => 'Blattstecklinge';

  @override
  String get carePropDivision => 'Teilung';

  @override
  String get carePropOffsets => 'Kindel';

  @override
  String get carePropLayering => 'Absenker';

  @override
  String get carePropSeed => 'Aussaat';

  @override
  String get carePropWater => 'Bewurzeln im Wasser';

  @override
  String get carePropTuber => 'Knollen teilen';

  @override
  String get careMatchSpecies => 'Artenspezifisch';

  @override
  String careMatchGenus(String name) {
    return 'Gattung $name';
  }

  @override
  String careMatchFamily(String name) {
    return 'Familie $name';
  }

  @override
  String get careMatchGeneric => 'Allgemeine Hinweise';

  @override
  String get careMatchNote =>
      'Diese Angaben stammen von der botanischen Gruppe, nicht von der genauen Art. Art angeben, um sie zu verfeinern.';

  @override
  String get careDisclaimer =>
      'Richtwerte, keine Regeln: Ihr Licht, Ihr Topf und Ihre Luft zählen genauso.';

  @override
  String get careApplyToSchedule => 'Auf Plan übertragen';

  @override
  String get careScheduleApplied => 'Plan aktualisiert';

  @override
  String careSuggestedIntervals(int water, int fertilize) {
    return 'Alle $water Tage gießen, alle $fertilize Tage düngen';
  }

  @override
  String get careBadgeMist => 'Besprühen';

  @override
  String get careBadgeDormant => 'Winterruhe';

  @override
  String get careBadgeOutdoor => 'Verträgt Freiland';

  @override
  String get careIssueOverwatering => 'Zu viel Wasser: weiche, gelbe Blätter';

  @override
  String get careIssueUnderwatering => 'Zu wenig Wasser: hängende Blätter';

  @override
  String get careIssueRootRot => 'Wurzelfäule';

  @override
  String get careIssueSpiderMites => 'Spinnmilben (feine Gespinste)';

  @override
  String get careIssueMealybugs => 'Wollläuse';

  @override
  String get careIssueScale => 'Schildläuse';

  @override
  String get careIssueAphids => 'Blattläuse';

  @override
  String get careIssueFungusGnats => 'Trauermücken';

  @override
  String get careIssueWhitefly => 'Weiße Fliege';

  @override
  String get careIssueSlugs => 'Schnecken';

  @override
  String get careIssuePowderyMildew => 'Echter Mehltau';

  @override
  String get careIssueLeafSpot => 'Blattflecken';

  @override
  String get careIssueBlight => 'Kraut- und Braunfäule';

  @override
  String get careIssueSunburn => 'Sonnenbrand';

  @override
  String get careIssueDryTips => 'Trockene braune Blattspitzen';

  @override
  String get careIssueLeafDrop => 'Blattfall';

  @override
  String get careIssueEtiolation => 'Vergeilen bei Lichtmangel';

  @override
  String get careIssueChlorosis => 'Chlorose: blasse Blätter, grüne Adern';

  @override
  String get careIssueBlossomEndRot => 'Blütenendfäule';

  @override
  String get careTipFingerTest =>
      'Finger hineinstecken: gießen, wenn die oberen 2 cm trocken sind.';

  @override
  String get careTipDrySoilFirst =>
      'Substrat zwischen den Wassergaben ganz abtrocknen lassen.';

  @override
  String get careTipNeverDryOut => 'Das Substrat nie ganz austrocknen lassen.';

  @override
  String get careTipEvenWatering =>
      'Gleichmäßig gießen: Schwankungen lassen Früchte platzen.';

  @override
  String get careTipWaterAtBase => 'Am Fuß gießen, Blätter trocken halten.';

  @override
  String get careTipNoWaterOnLeaves =>
      'Blätter nicht benetzen: stehendes Wasser fleckt.';

  @override
  String get careTipBottomWatering =>
      'Von unten gießen: Topf 20 Minuten in Wasser stellen.';

  @override
  String get careTipFilteredWater =>
      'Regen- oder gefiltertes Wasser: Kalk bräunt die Spitzen.';

  @override
  String get careTipRainwaterOnly =>
      'Mit Regenwasser gießen: die Pflanze verträgt keinen Kalk.';

  @override
  String get careTipThirstyPlant => 'Trinkt viel: im Sommer täglich prüfen.';

  @override
  String get careTipDroopSignal =>
      'Sie lässt hängen, wenn sie durstig ist: Ihr Signal.';

  @override
  String get careTipWinterDry => 'Im Winter fast trocken halten.';

  @override
  String get careTipWinterRest => 'Im Winter kaum gießen: sie ruht.';

  @override
  String get careTipSummerDormant => 'Sie ruht im Sommer: dann kaum gießen.';

  @override
  String get careTipNoWaterWhileSplitting =>
      'Nicht gießen, während sie neue Blätter schiebt.';

  @override
  String get careTipOrchidSoak =>
      'Topf 10 Minuten tauchen, dann gut abtropfen.';

  @override
  String get careTipSoakMount =>
      'Ganze Pflanze tauchen, dann an der Luft trocknen.';

  @override
  String get careTipDryUpsideDown =>
      'Nach dem Bad kopfüber trocknen: Wasser im Herz führt zu Fäule.';

  @override
  String get careTipWaterInTheCup =>
      'Zentrale Rosette füllen und Wasser wöchentlich wechseln.';

  @override
  String get careTipNoSoil =>
      'Sie lebt ohne Erde: einfach auf einen Halter legen.';

  @override
  String get careTipGreenRoots => 'Grüne Wurzeln: versorgt. Silbrige: gießen.';

  @override
  String get careTipHumidityTray => 'Topf auf feuchte Blähtonkugeln stellen.';

  @override
  String get careTipNoDirectSun =>
      'Direkte Sonne meiden: sie verbrennt die Blätter.';

  @override
  String get careTipToleratesLowLight =>
      'Sie erträgt dunkle Räume, wächst am Fenster aber schneller.';

  @override
  String get careTipToleratesNeglect =>
      'Sie verzeiht Vergesslichkeit: im Zweifel nicht gießen.';

  @override
  String get careTipBrightForColor => 'Je heller, desto kräftiger die Farben.';

  @override
  String get careTipRotatePot =>
      'Topf wöchentlich um eine Vierteldrehung drehen.';

  @override
  String get careTipHatesMoving =>
      'Sie mag keinen Standortwechsel: einen Platz suchen und lassen.';

  @override
  String get careTipWipeLeaves =>
      'Blätter abwischen: sie atmen und nutzen Licht besser.';

  @override
  String get careTipTrimToBushOut =>
      'Lange Triebe kürzen, dann verzweigt sie sich.';

  @override
  String get careTipMonsteraSupport =>
      'Moosstab anbieten: Blätter werden größer und geschlitzter.';

  @override
  String get careTipShallowPot => 'Ein breiter, flacher Topf passt besser.';

  @override
  String get careTipLikesBeingPotbound =>
      'Sie blüht besser im engen Topf: selten umtopfen.';

  @override
  String get careTipTrunkStoresWater =>
      'Der dicke Fuß speichert Wasser: lieber zu wenig als zu viel.';

  @override
  String get careTipPupsToShare =>
      'Sie bildet Kindel: abtrennen zum Vermehren oder Verschenken.';

  @override
  String get careTipKeepFlowerSpike =>
      'Grünen Blütenstiel stehen lassen: er kann erneut blühen.';

  @override
  String get careTipDarkForRebloom =>
      'Zum Nachblühen sechs Wochen lange, kühle Nächte geben.';

  @override
  String get careTipNotADesertCactus =>
      'Kein Wüstenkaktus: mag Schatten und Feuchtigkeit.';

  @override
  String get careTipDeadheadFlowers =>
      'Verblühtes entfernen: sie blüht länger.';

  @override
  String get careTipPinchFlowers =>
      'Blütenknospen ausknipsen: die Blätter bleiben zart.';

  @override
  String get careTipHarvestTop => 'Von oben ernten, über einem Blattpaar.';

  @override
  String get careTipHarvestOutside =>
      'Äußere Blätter ernten: die Mitte wächst weiter.';

  @override
  String get careTipStakeAndPrune => 'Anbinden und Geiztriebe ausbrechen.';

  @override
  String get careTipPrunesInSpring =>
      'Im Frühjahr schneiden, nie ins alte Holz.';

  @override
  String get careTipPrunesAfterFlowering =>
      'Direkt nach der Blüte schneiden, damit sie kompakt bleibt.';

  @override
  String get careTipWinterPruning =>
      'Im frostfreien Winter schneiden, während der Ruhe.';

  @override
  String get careTipPruneAfterHarvest =>
      'Nach der Ernte schneiden, nicht im Frühjahr.';

  @override
  String get careTipCutSpentCanes => 'Abgetragene Ruten bodennah abschneiden.';

  @override
  String get careTipTrimTwiceAYear =>
      'Zweimal jährlich schneiden reicht: Juni und Ende August.';

  @override
  String get careTipContainItsRoots =>
      'In den Topf oder mit Rhizomsperre: sie breitet sich stark aus.';

  @override
  String get careTipMulchIt => 'Fuß mulchen: weniger gießen, weniger Unkraut.';

  @override
  String get careTipAcidSoil =>
      'Sie braucht sauren Boden: keine Universalerde.';

  @override
  String get careTipBlueNeedsAcid =>
      'Blaue Blüten brauchen sauren Boden; im Kalk werden sie rosa.';

  @override
  String get careTipCitrusFertilizer =>
      'Den ganzen Sommer über Zitrusdünger geben.';

  @override
  String get careTipNoFertilizer =>
      'Nicht düngen: zu nährstoffreich verliert sie Duft und Form.';

  @override
  String get careTipNoNitrogen =>
      'Keinen Stickstoffdünger: sie bildet ihn selbst.';

  @override
  String get careTipLetFoliageDieBack =>
      'Laub vergilben lassen: es füttert die Zwiebel.';

  @override
  String get careTipDiesBackInWinter =>
      'Sie zieht im Winter ein und treibt im Frühling neu aus.';

  @override
  String get careTipSummerOutdoors =>
      'Im Sommer nach draußen, anfangs in den Schatten.';

  @override
  String get careTipWinterIndoors => 'Vor dem ersten Frost hereinholen.';

  @override
  String get careTipWinterShelter => 'Kühl und hell überwintern.';

  @override
  String get careTipWinterCool =>
      'Ein kühler, heller Winter (10–14 °C) tut ihr gut.';

  @override
  String get careTipCoolerIsBetter =>
      'Sie mag es kühl: nicht neben die Heizung.';

  @override
  String get careTipHardyOutdoors =>
      'Winterhart: sie bleibt ungeschützt draußen.';

  @override
  String get careTipShelterFromWind =>
      'Windgeschützt stellen: das Laub reißt leicht.';

  @override
  String get careTipAirFlow =>
      'Für Luftzug sorgen: stehende Luft fördert Krankheiten.';

  @override
  String get careTipSpiderMiteWatch =>
      'Blattunterseiten prüfen: Spinnmilben lieben sie.';

  @override
  String get careTipSlugWatch =>
      'Junge Triebe im Frühjahr vor Schnecken schützen.';

  @override
  String get careTipBoxMothWatch =>
      'Auf den Buchsbaumzünsler achten: Raupen und Gespinste.';

  @override
  String get careTipSapIrritant =>
      'Der Saft reizt Haut und Augen: mit Handschuhen schneiden.';

  @override
  String get careTipVeryToxic =>
      'Alle Teile sind sehr giftig, auch der Rauch beim Verbrennen.';

  @override
  String get careTipSharpSpines =>
      'Die Dornen sind gefährlich: nicht an Wegen platzieren.';

  @override
  String get careTipSplitsAreNormal =>
      'Blätter reißen mit dem Alter ein: normal, keine Krankheit.';

  @override
  String get careTipDryToBloom => 'Leichter Trockenstress löst die Blüte aus.';

  @override
  String get customFields => 'Eigene Felder';

  @override
  String get addCustomField => 'Feld hinzufügen';

  @override
  String get editCustomField => 'Feld bearbeiten';

  @override
  String get deleteCustomField => 'Feld löschen';

  @override
  String get fieldLabel => 'Feldname';

  @override
  String get fieldLabelHint => 'Herkunft, Preis, Lage…';

  @override
  String get fieldType => 'Typ';

  @override
  String get fieldValue => 'Wert';

  @override
  String get fieldTypeBool => 'Ja / nein';

  @override
  String get fieldTypeInt => 'Ganze Zahl';

  @override
  String get fieldTypeDouble => 'Dezimalzahl';

  @override
  String get fieldTypeText => 'Text';

  @override
  String get fieldTypeDate => 'Datum';

  @override
  String get fieldEmpty => 'Nicht angegeben';

  @override
  String get noCustomFields => 'Keine eigenen Felder';

  @override
  String get fieldTemplates => 'Feldvorlagen';

  @override
  String get fieldTemplatesHint =>
      'Legen Sie hier Felder an, die Sie mehrfach nutzen: ein Tipp genügt später.';

  @override
  String get newFieldTemplate => 'Neue Vorlage';

  @override
  String get noFieldTemplates => 'Keine Vorlagen';

  @override
  String get fieldTemplateInactive => 'Ausgeblendet';

  @override
  String get fieldFromTemplate => 'Aus einer Vorlage';

  @override
  String get bulkSetField => 'Feld setzen';

  @override
  String bulkFieldApplied(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Feld für $count Pflanzen gesetzt',
      one: 'Feld für 1 Pflanze gesetzt',
    );
    return '$_temp0';
  }

  @override
  String get confirmDeleteField => 'Dieses Feld und seinen Wert löschen?';

  @override
  String get confirmDeleteTemplate =>
      'Vorlage löschen? Bereits ausgefüllte Felder bleiben erhalten.';

  @override
  String get yes => 'Ja';

  @override
  String get no => 'Nein';

  @override
  String get attachments => 'Dokumente';

  @override
  String get addAttachment => 'Dokument hinzufügen';

  @override
  String get noAttachments => 'Keine Dokumente';

  @override
  String get noAttachmentsHint => 'Rechnung, Züchterblatt, Bodenanalyse…';

  @override
  String get attachmentLabel => 'Dokumentname';

  @override
  String get renameAttachment => 'Umbenennen';

  @override
  String get deleteAttachment => 'Dokument löschen';

  @override
  String get confirmDeleteAttachment =>
      'Dokument löschen? Die Datei wird vom Gerät entfernt.';

  @override
  String get openAttachment => 'Öffnen';

  @override
  String get attachmentOpenFailed => 'Keine App kann diese Datei öffnen.';

  @override
  String get photoLabel => 'Fototitel';

  @override
  String get photoLabelHint => 'Vor dem Umtopfen, neues Blatt…';

  @override
  String get setAsMainPhoto => 'Als Hauptfoto';

  @override
  String get mainPhotoSet => 'Hauptfoto aktualisiert';

  @override
  String get addPhotoByUrl => 'Von einer Web-Adresse';

  @override
  String get photoUrlHint => 'https://…';

  @override
  String get photoUrlInvalid =>
      'Ungültige Adresse: sie muss mit https:// beginnen';

  @override
  String get photoRemote => 'Externes Foto';

  @override
  String get confirmDeletePhoto => 'Dieses Foto löschen?';

  @override
  String get shareByLink => 'Per Link teilen';

  @override
  String get sharedLinks => 'Geteilte Links';

  @override
  String get sharedLinksHint =>
      'Eine öffentliche Webseite, jederzeit widerrufbar.';

  @override
  String get noSharedLinks => 'Keine geteilten Links';

  @override
  String get shareTitle => 'Seitentitel';

  @override
  String get shareDescription => 'Beschreibung (optional)';

  @override
  String get shareKeywords => 'Schlagwörter (optional)';

  @override
  String get shareUnlisted => 'Nicht gelistet';

  @override
  String get shareUnlistedHint =>
      'Die Seite bittet Suchmaschinen, sie nicht zu indexieren. Wer den Link hat, sieht sie trotzdem.';

  @override
  String get shareExpiry => 'Läuft ab am';

  @override
  String get shareNoExpiry => 'Ohne Ablauf';

  @override
  String get shareCreate => 'Link erstellen';

  @override
  String get shareCopy => 'Link kopieren';

  @override
  String get shareCopied => 'Link kopiert';

  @override
  String get shareRevoke => 'Widerrufen';

  @override
  String get shareRevoked => 'Widerrufen';

  @override
  String get shareExpired => 'Abgelaufen';

  @override
  String get shareActive => 'Aktiv';

  @override
  String get confirmRevokeLink =>
      'Diesen Link widerrufen? Die Seite ist dann nicht mehr erreichbar.';

  @override
  String get shareNeedsAccount => 'Das Teilen per Link erfordert ein Konto.';

  @override
  String get shareFailed =>
      'Der Link konnte nicht erstellt werden. Erneut versuchen.';

  @override
  String get sharePhoto => 'Dieses Foto teilen';

  @override
  String get sharePlant => 'Diese Pflanze teilen';

  @override
  String get notesMarkdownHint =>
      'Formatierung: **fett**, *kursiv*, - Listen, [Links](https://…)';

  @override
  String get preview => 'Vorschau';

  @override
  String get locationNotes => 'Notizen zum Ort';

  @override
  String get locationLog => 'Journal';

  @override
  String get addLogEntry => 'Eintrag hinzufügen';

  @override
  String get editLogEntry => 'Eintrag bearbeiten';

  @override
  String get logEntryHint => 'Rollo gewechselt, Gewächshaus geputzt…';

  @override
  String get noLogEntries => 'Leeres Journal';

  @override
  String get confirmDeleteLogEntry => 'Diesen Eintrag löschen?';

  @override
  String get locationPhoto => 'Foto des Ortes';

  @override
  String get removeLocationPhoto => 'Foto entfernen';

  @override
  String get careAllPlants => 'Alle Pflanzen versorgen';

  @override
  String get waterAllHere => 'Hier alles gießen';

  @override
  String get fertilizeAllHere => 'Hier alles düngen';

  @override
  String get repotAllHere => 'Hier alles umtopfen';

  @override
  String plantNumber(int number) {
    return 'Nr. $number';
  }

  @override
  String get searchByNumberHint =>
      'Tipp: #42 eingeben, um Pflanze Nr. 42 zu finden.';

  @override
  String get inventoryGroups => 'Gruppen';

  @override
  String get manageGroups => 'Gruppen verwalten';

  @override
  String get newGroup => 'Neue Gruppe';

  @override
  String get editGroup => 'Gruppe bearbeiten';

  @override
  String get groupName => 'Gruppenname';

  @override
  String get groupNameHint => 'Dünger, Werkzeug, Töpfe…';

  @override
  String get deleteGroup => 'Gruppe löschen';

  @override
  String get deleteGroupHint =>
      'Artikel werden nicht gelöscht: sie wandern in die gewählte Gruppe.';

  @override
  String get moveItemsTo => 'Artikel verschieben nach';

  @override
  String get noGroup => 'Ohne Gruppe';

  @override
  String get noGroups => 'Keine eigenen Gruppen';

  @override
  String get itemGroup => 'Gruppe';

  @override
  String get itemTags => 'Tags';

  @override
  String get itemQr => 'QR-Code des Artikels';

  @override
  String get exportSelection => 'Auswahl exportieren';

  @override
  String get exportCsv => 'Als CSV exportieren';

  @override
  String get selectItems => 'Auswählen';

  @override
  String itemsSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Artikel',
      one: '1 Artikel',
    );
    return '$_temp0';
  }

  @override
  String get filterByTag => 'Nach Tag filtern';

  @override
  String get itemNotFound => 'Artikel nicht gefunden';

  @override
  String get noGroupsYet =>
      'Noch keine Gruppen. Erstelle eine, um deine Artikel nach deinem System zu ordnen.';

  @override
  String get deleteGroupExplain =>
      'Artikel werden nicht gelöscht: Sie haben danach einfach keine Gruppe mehr.';

  @override
  String get newEvent => 'Neuer Termin';

  @override
  String get editEvent => 'Termin bearbeiten';

  @override
  String get deleteEvent => 'Termin löschen';

  @override
  String get eventTitleHint => 'Pflanzenmarkt';

  @override
  String get eventNotesHint => 'Notizen (optional)';

  @override
  String get eventStart => 'Beginn';

  @override
  String get eventEnd => 'Ende';

  @override
  String get eventNoEnd => 'Gleicher Tag';

  @override
  String get eventAllDay => 'Ganztägig';

  @override
  String get eventCategory => 'Kategorie';

  @override
  String get eventNoCategory => 'Keine';

  @override
  String get eventReminder => 'Erinnerung';

  @override
  String get eventNoReminder => 'Keine';

  @override
  String get eventReminderAtStart => 'Zum Beginn';

  @override
  String eventReminderMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Minuten vorher',
      one: '1 Minute vorher',
    );
    return '$_temp0';
  }

  @override
  String eventReminderHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Stunden vorher',
      one: '1 Stunde vorher',
    );
    return '$_temp0';
  }

  @override
  String eventReminderDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage vorher',
      one: '1 Tag vorher',
    );
    return '$_temp0';
  }

  @override
  String get manageEventCategories => 'Terminkategorien';

  @override
  String get newEventCategory => 'Neue Kategorie';

  @override
  String get editEventCategory => 'Kategorie bearbeiten';

  @override
  String get deleteEventCategory => 'Kategorie löschen';

  @override
  String get deleteEventCategoryExplain =>
      'Termine werden nicht gelöscht: Sie verlieren nur ihre Kategorie.';

  @override
  String get noEventCategoriesYet =>
      'Noch keine Kategorien. Erstelle eine, um deine Termine einzufärben.';

  @override
  String get categoryNameHint => 'Name der Kategorie';

  @override
  String get eventPlant => 'Verknüpfte Pflanze';

  @override
  String get eventNoPlant => 'Keine';

  @override
  String get eventsOfDay => 'Termine';

  @override
  String get dashboardTitle => 'Übersicht';

  @override
  String get statsSection => 'Zahlen';

  @override
  String get statPlants => 'Pflanzen';

  @override
  String get statSpecies => 'Arten';

  @override
  String get statLocations => 'Standorte';

  @override
  String get statFavorites => 'Favoriten';

  @override
  String get statArchived => 'Archiviert';

  @override
  String get statNeedingCare => 'Pflege nötig';

  @override
  String get statOpenTasks => 'Offene Aufgaben';

  @override
  String get statLowStock => 'Wenig Vorrat';

  @override
  String get statActionsThisMonth => 'Pflege diesen Monat';

  @override
  String get statWateringsThisMonth => 'Gießvorgänge diesen Monat';

  @override
  String get statOldest => 'Am längsten dabei';

  @override
  String get warningsSection => 'Braucht Aufmerksamkeit';

  @override
  String get warningSick => 'Krank';

  @override
  String get warningWatch => 'Beobachten';

  @override
  String warningOverdue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage überfällig',
      one: '1 Tag überfällig',
    );
    return '$_temp0';
  }

  @override
  String get noWarnings => 'Im Garten ist alles in Ordnung.';

  @override
  String get recentPlantsSection => 'Neueste Pflanzen';

  @override
  String get recentAdded => 'Hinzugefügt';

  @override
  String get recentUpdated => 'Geändert';

  @override
  String get activityLogTitle => 'Aktivitätsprotokoll';

  @override
  String get activityEmpty =>
      'Noch nichts. Das Protokoll füllt sich mit der ersten Pflege.';

  @override
  String get activityPlantAdded => 'Zum Garten hinzugefügt';

  @override
  String get activityPlantArchived => 'Archiviert';

  @override
  String get activityLocationNote => 'Standortnotiz';

  @override
  String get activityTaskDone => 'Aufgabe erledigt';

  @override
  String get archiveNameTitle => 'Name des Archivs';

  @override
  String get archiveNameHint => 'Erinnerung, Die Vergangenheit…';

  @override
  String get archiveNameExplain =>
      'Leer lassen, um den Standardnamen zu behalten.';

  @override
  String get searchArchives => 'Archiv durchsuchen';

  @override
  String get archiveSortArchivedDesc => 'Zuletzt archiviert';

  @override
  String get archiveSortArchivedAsc => 'Zuerst archiviert';

  @override
  String get archiveSortName => 'Name';

  @override
  String get archiveSortLongestKept => 'Am längsten behalten';

  @override
  String get allYears => 'Alle';

  @override
  String keptForDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage behalten',
      one: '1 Tag behalten',
    );
    return '$_temp0';
  }

  @override
  String keptForYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Jahre behalten',
      one: '1 Jahr behalten',
    );
    return '$_temp0';
  }

  @override
  String get noArchiveMatch => 'Keine Pflanze passt.';

  @override
  String get weatherForecastTitle => 'Wettervorhersage';

  @override
  String get weatherPrecipitation => 'Niederschlag';

  @override
  String get weatherRainChance => 'Regenwahrscheinlichkeit';

  @override
  String get weatherWind => 'Wind';

  @override
  String get weatherHumidity => 'Luftfeuchtigkeit';

  @override
  String get weatherNoPlace => 'Wähle einen Ort, um die Vorhersage zu sehen.';

  @override
  String get weatherToday => 'Heute';

  @override
  String get weatherFailed => 'Vorhersage derzeit nicht verfügbar.';

  @override
  String get backupTitle => 'Sicherung';

  @override
  String get backupExplain =>
      'Eine .zip-Datei mit deinen Daten und Fotos. Offenes Format: Deine Daten bleiben deine.';

  @override
  String get backupWhatToExport => 'Was sichern';

  @override
  String get backupWhatToImport => 'Was wiederherstellen';

  @override
  String get sectionGarden => 'Garten und Standorte';

  @override
  String get sectionPlants => 'Pflanzen';

  @override
  String get sectionPhotos => 'Fotos';

  @override
  String get sectionCare => 'Pflege und Routinen';

  @override
  String get sectionInventory => 'Vorrat';

  @override
  String get sectionTasks => 'Aufgaben';

  @override
  String get sectionCalendar => 'Kalender';

  @override
  String get importBackup => 'Sicherung wiederherstellen';

  @override
  String get chooseBackupFile => 'Datei wählen';

  @override
  String get importing => 'Wird wiederhergestellt…';

  @override
  String importDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Einträge wiederhergestellt',
      one: '1 Eintrag wiederhergestellt',
    );
    return '$_temp0';
  }

  @override
  String importSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Zeilen übersprungen',
      one: '1 Zeile übersprungen',
    );
    return '$_temp0';
  }

  @override
  String get importConfirm =>
      'Daten aus der Datei ersetzen Einträge mit gleicher Kennung. Nichts wird gelöscht.';

  @override
  String get importErrorNotAZip => 'Diese Datei ist keine Flora-Sicherung.';

  @override
  String get importErrorWrongApp =>
      'Diese Sicherung stammt aus einer anderen App.';

  @override
  String get importErrorTooRecent =>
      'Diese Sicherung stammt aus einer neueren Version von Flora.';

  @override
  String get importErrorGeneric => 'Wiederherstellung fehlgeschlagen.';

  @override
  String backupFrom(String date) {
    return 'Sicherung vom $date';
  }

  @override
  String backupContains(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Einträge',
      one: '1 Eintrag',
    );
    return '$_temp0';
  }

  @override
  String get apiTitle => 'Externe API';

  @override
  String get apiExplain =>
      'Deine Daten sind über die REST-API deines Supabase-Projekts mit deinem eigenen Schlüssel erreichbar. Ohne Konto wird nichts freigegeben.';

  @override
  String get apiNotConnected => 'Verbinde ein Konto, um die API zu aktivieren.';

  @override
  String get apiEndpoints => 'Endpunkte';

  @override
  String get apiCopyBase => 'Basis-URL kopieren';

  @override
  String get apiCopied => 'URL kopiert';

  @override
  String get apiTokenHint =>
      'Authentifiziere dich mit dem Token deiner Supabase-Sitzung (Authorization: Bearer).';

  @override
  String get apiCopyToken => 'Zugriffstoken kopieren';

  @override
  String get apiTokenCopied => 'Token kopiert';

  @override
  String get apiTokenWarning =>
      'Einige Stunden gültig. Wird durch Abmelden widerrufen.';

  @override
  String get apiReadWrite => 'Lesen und Schreiben';

  @override
  String get apiOnlyYourGarden =>
      'Jede Anfrage sieht nur Gärten, in denen du Mitglied bist.';

  @override
  String get apiExample => 'Beispiel';

  @override
  String get onbTodayTitle => 'Jeden Morgen, was zu tun ist';

  @override
  String get onbTodayBody => 'Gegossen? Ein Tipp, und es ist notiert.';

  @override
  String get onbCareTitle => 'Im Winter seltener gießen';

  @override
  String get onbCareBody =>
      'Die Abstände passen sich von selbst an, wenn die Tage kürzer werden.';

  @override
  String get onbGardenTitle => 'Räume, Fotos, Kalender';

  @override
  String get onbGardenBody =>
      'Die Geschichte jeder Pflanze schreibt sich von allein.';

  @override
  String get onbPrivacyTitle => 'Alles bleibt auf deinem Handy';

  @override
  String get onbPrivacyBody => 'Kein Pflichtkonto, keine Werbung.';

  @override
  String get onbStart => 'Loslegen';

  @override
  String get replayOnboarding => 'Einführung erneut ansehen';

  @override
  String onbStepOf(int current, int total) {
    return 'Schritt $current von $total';
  }

  @override
  String get weatherPickPlace => 'Ort wählen';

  @override
  String get speciesMoreOffline => 'Weitere Arten';

  @override
  String get aboutSources => 'Datenquellen';

  @override
  String get aboutSourceWikidata => 'Artnamen in vier Sprachen, gemeinfrei';

  @override
  String get aboutSourceGbif =>
      'Taxonomie, Familien und fotografierte Nachweise';

  @override
  String get aboutSourceOpenMeteo =>
      'Wetter und Vorhersage, ohne Konto oder Schlüssel';

  @override
  String aboutSpeciesCount(String count) {
    return '$count Arten offline durchsuchbar';
  }

  @override
  String get supportTitle => 'Flora ist kostenlos';

  @override
  String get supportBody =>
      'Alle Funktionen sind kostenlos. Wenn dir die App hilft, kannst du ihrem Entwickler etwas zurückgeben — einmal, ohne Abo.';

  @override
  String get supportNothingLocked =>
      'Nichts bleibt denen vorbehalten, die geben.';

  @override
  String supportGive(String price) {
    return 'Unterstützen · $price';
  }

  @override
  String get supportRestore => 'Unterstützung wiederherstellen';

  @override
  String get supportThanksTitle => 'Danke';

  @override
  String get supportThanksBody =>
      'Deine Unterstützung ist gespeichert. Die App ändert sich nicht: Sie war bereits vollständig.';

  @override
  String get supportUnavailable =>
      'Der Kauf ist auf diesem Gerät nicht verfügbar.';

  @override
  String get supportFailed => 'Der Kauf ist nicht zustande gekommen.';

  @override
  String get supportNothingToRestore =>
      'Keine Unterstützung zum Wiederherstellen.';

  @override
  String get supportSettings => 'Entwickler unterstützen';

  @override
  String get supportFreeForever => 'Kostenlos, ohne Limit';

  @override
  String get supportAlready => 'Danke für deine Unterstützung';

  @override
  String get supportNoThanks => 'Ohne fortfahren';

  @override
  String get aboutTagline =>
      'Kümmere dich um deine Pflanzen und bewahre ihre Geschichte.';

  @override
  String get emptyGardenSubtitle =>
      'Füge deine erste Pflanze hinzu, mit Foto, wenn du magst.';
}
