// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appName => 'Auxine';

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
  String get openSettings => 'Einstellungen öffnen';

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
  String get soon => 'Bald';

  @override
  String get genericError => 'Ein Fehler ist aufgetreten. Erneut versuchen.';

  @override
  String get offlineTitle => 'Offline';

  @override
  String get offlineHint =>
      'Dafür ist eine Verbindung nötig. Bereits auf dem Gerät gespeicherte Daten bleiben lesbar.';

  @override
  String get offlineActionFailed =>
      'Offline. Erneut versuchen, sobald das Netz zurück ist.';

  @override
  String get offlineSharing =>
      'Links erstellen, widerrufen und auflisten erfordert eine Verbindung.';

  @override
  String get offlineCollaboration =>
      'Einladen, einem Garten beitreten und Rollen ändern erfordert eine Verbindung.';

  @override
  String get offlineDiagnosis => 'Die Analyse erfordert eine Verbindung.';

  @override
  String get offlineIdentification =>
      'Die Online-Suche erfordert eine Verbindung. Die Erkennung auf dem Gerät nicht.';

  @override
  String get offlineSupport => 'Der Kauf erfordert eine Verbindung.';

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
  String greetingEvening(String name) {
    return 'Guten Abend $name';
  }

  @override
  String get greetingEveningAnonymous => 'Guten Abend';

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
  String get allDoneSubtitle => 'Heute ist keine Pflege fällig.';

  @override
  String get emptyGardenTitle => 'Keine Pflanzen';

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
  String get sortEdited => 'Zuletzt bearbeitet';

  @override
  String get sortLastWatered => 'Zuletzt gegossen';

  @override
  String get sortLastFertilized => 'Zuletzt gedüngt';

  @override
  String get sortLastRepotted => 'Zuletzt umgetopft';

  @override
  String get sortAcquired => 'Anschaffung';

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
  String get showAsGrid => 'Als Raster anzeigen';

  @override
  String get showAsList => 'Als Liste anzeigen';

  @override
  String get noResultsTitle => 'Keine Ergebnisse';

  @override
  String get noResultsSubtitle => 'Versuch es mit einem anderen Wort.';

  @override
  String get emptyPlantsTitle => 'Noch keine Pflanzen';

  @override
  String get emptyPlantsSubtitle => 'Fügen Sie Ihre erste Pflanze hinzu.';

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
  String get stepPhotoTitle => 'Foto';

  @override
  String get stepPhotoSubtitle => 'Nimm die ganze Pflanze bei Tageslicht auf.';

  @override
  String get stepPhotoSubtitleCutting =>
      'Nimm den ganzen Ableger bei Tageslicht auf.';

  @override
  String get takePhoto => 'Foto aufnehmen';

  @override
  String get choosePhoto => 'Foto auswählen';

  @override
  String get withoutPhoto => 'Ohne Foto fortfahren';

  @override
  String get changePhoto => 'Ändern';

  @override
  String get stepNameTitle => 'Name';

  @override
  String get plantNameHint => 'Name der Pflanze';

  @override
  String get speciesHint => 'Art (optional)';

  @override
  String get stepLocationTitle => 'Standort';

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
  String get notesHint => 'Licht, Umtopfen, Anmerkungen…';

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
  String get offspring => 'Tochterpflanzen';

  @override
  String get editSchedule => 'Pflegeplan anpassen';

  @override
  String cuttingOf(String name) {
    return 'Ableger von $name';
  }

  @override
  String get propagate => 'Ableger anlegen';

  @override
  String get pgPickTitle => 'Diese Pflanze vermehren';

  @override
  String get pgPickBody =>
      'Diese Pflanze lässt sich auf mehrere Arten vermehren. Der gewählte Handgriff bestimmt die Schritte.';

  @override
  String get pgRecommended => 'Empfohlen';

  @override
  String pgIntroTitle(String name, String species) {
    return '$name von $species';
  }

  @override
  String pgIntroBody(int count) {
    return '$count Schritte. Jeder wird als Handgriff gezeigt und in einem Satz gesagt, auf die Art abgestimmt, wenn sie bekannt ist.';
  }

  @override
  String get pgStartCutting => 'Steckling anlegen';

  @override
  String get pgStartPlant => 'Pflanze anlegen';

  @override
  String get pgNoteSpot => 'Zu erkennen';

  @override
  String get pgNoteAvoid => 'Zu vermeiden';

  @override
  String get pgNoteUsual => 'Meist';

  @override
  String get pgNoteMedium => 'Bewurzelung';

  @override
  String get pgMediumWater => 'Im Wasser';

  @override
  String get pgMediumSubstrate => 'In lockerem Substrat';

  @override
  String get pgMediumEither => 'Wasser oder lockeres Substrat';

  @override
  String get pgVineName => 'Triebsteckling';

  @override
  String get pgVineHint => 'Ein Nodium, ein sauberer Schnitt, Wasser';

  @override
  String get pgVineNodeTitle => 'Das Nodium';

  @override
  String get pgVineNodeBody =>
      'Die Verdickung, aus der ein Blatt kommt, oft mit einer Luftwurzel daneben. Der Steckling behält mindestens eine.';

  @override
  String get pgVineNodeNote => 'Nodium und Luftwurzel';

  @override
  String get pgVineCutTitle => 'Der Schnitt';

  @override
  String get pgVineCutBody =>
      'Saubere Klinge, glatter Schnitt einen Zentimeter unter dem Nodium. Das Nodium bleibt am Steckling.';

  @override
  String get pgVineCutNote => 'Über dem Nodium schneiden';

  @override
  String get pgVineClearTitle => 'Das freie Nodium';

  @override
  String get pgVineClearBody =>
      'Die Blätter, die im Wasser stünden, kommen ab. Zwei oder drei Blätter oben versorgen den Steckling.';

  @override
  String get pgVineWaterTitle => 'Das Wasser';

  @override
  String get pgVineWaterBody =>
      'Das Nodium unter der Oberfläche, die Blätter darüber. Helles Licht, keine direkte Sonne.';

  @override
  String get pgVineRootsTitle => 'Die Wurzeln';

  @override
  String get pgVineRootsBody =>
      'Sie kommen aus dem Nodium, nicht aus dem Stielende. Das Wasser wird wöchentlich gewechselt.';

  @override
  String get pgVineRootsNote => 'Erste Wurzeln in zwei bis sechs Wochen';

  @override
  String get pgVinePotTitle => 'Der Topf';

  @override
  String get pgVinePotBody =>
      'Bei einigen Zentimetern Wurzel kommt der Steckling in lockere Erde. Das Nodium bleibt dicht unter der Oberfläche.';

  @override
  String get pgSoftName => 'Kopfsteckling';

  @override
  String get pgSoftHint => 'Ein junger Trieb, schnelle Wurzeln';

  @override
  String get pgSoftStemTitle => 'Der Trieb';

  @override
  String get pgSoftStemBody =>
      'Ein junger, fester Trieb ohne Blüte, etwa zehn Zentimeter. Altes Holz bewurzelt schlecht.';

  @override
  String get pgSoftCutTitle => 'Der Schnitt';

  @override
  String get pgSoftCutBody =>
      'Saubere Klinge, Schnitt dicht unter einem Blattpaar. Von dort kommen die Wurzeln.';

  @override
  String get pgSoftStripTitle => 'Die unteren Blätter';

  @override
  String get pgSoftStripBody =>
      'Das unterste Paar kommt ab: drei bis vier Zentimeter Stiel bleiben kahl.';

  @override
  String get pgSoftStripNote => 'Ein Blatt im Wasser lassen';

  @override
  String get pgSoftRootTitle => 'Die Bewurzelung';

  @override
  String get pgSoftRootBody =>
      'Der kahle Stiel steht im Wasser, die Blätter bleiben trocken. Helles Licht, keine direkte Sonne.';

  @override
  String get pgSoftRootsTitle => 'Die Wurzeln';

  @override
  String get pgSoftRootsBody =>
      'Fein und zahlreich kommen sie aus dem ganzen eingetauchten Teil.';

  @override
  String get pgSoftRootsNote => 'Erste Wurzeln in einer bis drei Wochen';

  @override
  String get pgSoftPotTitle => 'Das Umsetzen';

  @override
  String get pgSoftPotBody =>
      'Früh umgesetzt, bei zwei bis drei Zentimetern Wurzel: ein weicher Trieb hält nicht lange.';

  @override
  String get pgLeafName => 'Blattsteckling';

  @override
  String get pgLeafHint => 'Langsamer, ein Blatt genügt';

  @override
  String get pgLeafChooseTitle => 'Das Blatt';

  @override
  String get pgLeafChooseBody =>
      'Ein ausgereiftes, festes Blatt ohne Flecken. Junge Blätter haben keine Reserven.';

  @override
  String get pgLeafCutTitle => 'Der Schnitt';

  @override
  String get pgLeafCutBody =>
      'Saubere Klinge, Schnitt am Blattgrund, dicht über dem Substrat.';

  @override
  String get pgLeafSplitTitle => 'Die Stücke';

  @override
  String get pgLeafSplitBody =>
      'Das Blatt wird in Stücke von fünf bis acht Zentimetern geteilt. Ein V am unteren Ende zeigt, welche Seite nach unten gehört.';

  @override
  String get pgLeafSplitNote => 'Das V markiert unten';

  @override
  String get pgLeafCallusTitle => 'Das Trocknen';

  @override
  String get pgLeafCallusBody =>
      'Die Schnittflächen trocknen an der Luft im Schatten, bevor sie ins Substrat kommen.';

  @override
  String get pgLeafCallusNote => 'Ein bis zwei Tage trocknen';

  @override
  String get pgLeafPlantTitle => 'Das Substrat';

  @override
  String get pgLeafPlantBody =>
      'Das V steckt zwei Zentimeter tief in durchlässigem Substrat.';

  @override
  String get pgLeafPlantNote => 'Ein Stück verkehrt herum setzen';

  @override
  String get pgLeafGrowthTitle => 'Der Austrieb';

  @override
  String get pgLeafGrowthBody =>
      'Zuerst kommen die Wurzeln, dann ein junger Trieb neben dem Blattstück.';

  @override
  String get pgLeafGrowthNote => 'Neuer Trieb in zwei bis vier Monaten';

  @override
  String get pgDivisionName => 'Teilung';

  @override
  String get pgDivisionHint => 'Schnell und sicher, der Horst wird geteilt';

  @override
  String get pgDivPlantTitle => 'Der Horst';

  @override
  String get pgDivPlantBody =>
      'Die Pflanze kommt am Stück aus dem Topf. Ein tags zuvor gegossenes Substrat hält besser zusammen.';

  @override
  String get pgDivUnpotTitle => 'Aus dem Topf';

  @override
  String get pgDivUnpotBody =>
      'Der Topf gleitet vom Ballen, die Pflanze ist frei.';

  @override
  String get pgDivRootsTitle => 'Der Ballen';

  @override
  String get pgDivRootsBody =>
      'Die Erde bröckelt ab, bis Wurzeln und Triebbasis zu sehen sind.';

  @override
  String get pgDivClustersTitle => 'Die zwei Gruppen';

  @override
  String get pgDivClustersBody =>
      'Jede Gruppe behält ihre Triebe und ihre Wurzeln.';

  @override
  String get pgDivClustersNote => 'Blätter und Wurzeln auf beiden Seiten';

  @override
  String get pgDivSplitTitle => 'Das Trennen';

  @override
  String get pgDivSplitBody =>
      'Die Gruppen lassen sich von Hand lösen. Die Klinge kommt nur bei festen Herzen zum Einsatz.';

  @override
  String get pgDivSplitNote => 'Einen Trieb über der Erde abschneiden';

  @override
  String get pgDivRepotTitle => 'Das Eintopfen';

  @override
  String get pgDivRepotBody =>
      'Jede Teilung kommt in einen eigenen Topf, so tief wie zuvor, und wird angegossen.';

  @override
  String get pgOffsetName => 'Kindel abtrennen';

  @override
  String get pgOffsetHint => 'Das Kindel geht mit eigenen Wurzeln';

  @override
  String get pgOffSpotTitle => 'Das Kindel';

  @override
  String get pgOffSpotBody =>
      'Ein Kindel von einem Drittel der Mutterpflanze, mit eigenen Blättern, ist bereit.';

  @override
  String get pgOffSpotNote => 'Bereits gebildetes Kindel';

  @override
  String get pgOffClearTitle => 'Das Freilegen';

  @override
  String get pgOffClearBody =>
      'Das Substrat wird am Fuß beiseite geräumt, die Verbindung zur Mutterpflanze wird sichtbar.';

  @override
  String get pgOffDetachTitle => 'Das Trennen';

  @override
  String get pgOffDetachBody =>
      'Das Kindel löst sich von der Verbindung, mit seinen Wurzeln. Die Klinge kommt nur bei verholzter Verbindung zum Einsatz.';

  @override
  String get pgOffDetachNote => 'Das Kindel ohne Wurzeln abreißen';

  @override
  String get pgOffRootsTitle => 'Die Wurzeln';

  @override
  String get pgOffRootsBody =>
      'Ein paar saubere Wurzeln genügen. Ohne sie trocknet das Kindel, bevor es anwächst.';

  @override
  String get pgOffPotTitle => 'Der Topf';

  @override
  String get pgOffPotBody =>
      'Ein kleiner Topf, das Substrat der Art, und ein leichter Guss.';

  @override
  String get pgOffSettleTitle => 'Das Anwachsen';

  @override
  String get pgOffSettleBody =>
      'Ein neues Blatt in der Mitte zeigt, dass das Kindel angewachsen ist.';

  @override
  String get pgOffSettleNote => 'Anwachsen in drei bis sechs Wochen';

  @override
  String get pgKeikiName => 'Ein Keiki abtrennen';

  @override
  String get pgKeikiHint => 'Der Orchideen-Ableger geht mit seinen Wurzeln';

  @override
  String get pgKeikiSpotTitle => 'Das Keiki';

  @override
  String get pgKeikiSpotBody =>
      'An einem Knoten des Blütentriebs wächst eine Jungpflanze: zwei Blätter und Luftwurzeln machen sie erkennbar.';

  @override
  String get pgKeikiSpotNote => 'Bereits gebildetes Kindel';

  @override
  String get pgKeikiWaitTitle => 'Die Wurzeln';

  @override
  String get pgKeikiWaitBody =>
      'Die Wurzeln wachsen am Trieb entlang. Drei bis fünf von einigen Zentimetern Länge, und das Keiki lebt allein.';

  @override
  String get pgKeikiWaitNote => 'Wurzeln bereit in zwei bis drei Monaten';

  @override
  String get pgKeikiDetachTitle => 'Das Trennen';

  @override
  String get pgKeikiDetachBody =>
      'Der Trieb wird beidseits des Keikis ein bis zwei Zentimeter entfernt durchtrennt. Ziehen würde die Basis verletzen.';

  @override
  String get pgKeikiDetachNote => 'Das Keiki abreißen';

  @override
  String get pgKeikiRootsTitle => 'Die Wurzeln des Keikis';

  @override
  String get pgKeikiRootsBody =>
      'Das Keiki behält seine Luftwurzeln: sie wachsen im Topf an.';

  @override
  String get pgKeikiPotTitle => 'Der Topf';

  @override
  String get pgKeikiPotBody =>
      'Ein kleiner Topf mit Rinde, die Basis des Keikis auf Substrathöhe, nicht eingegraben.';

  @override
  String get pgKeikiSettleTitle => 'Das Anwachsen';

  @override
  String get pgKeikiSettleBody =>
      'Ein neues Blatt in der Mitte zeigt, dass das Keiki angewachsen ist.';

  @override
  String get pgKeikiSettleNote => 'Anwachsen in ein bis zwei Monaten';

  @override
  String get pgSegmentName => 'Gliedsteckling';

  @override
  String get pgSegmentHint => 'Ein Glied gelöst, getrocknet, gesetzt';

  @override
  String get pgSegChooseTitle => 'Das Glied';

  @override
  String get pgSegChooseBody =>
      'Ein festes Endglied ohne Falten, zwei oder drei Glieder lang.';

  @override
  String get pgSegDetachTitle => 'Das Lösen';

  @override
  String get pgSegDetachBody =>
      'Das Glied löst sich am Gelenk, mit einer Drehung. Eine saubere Klinge, wenn es hält.';

  @override
  String get pgSegDetachNote => 'Am Glied reißen';

  @override
  String get pgSegWoundTitle => 'Die Wunde';

  @override
  String get pgSegWoundBody =>
      'Die Schnittfläche ist hell und feucht. Sofort gesetzt, fault sie.';

  @override
  String get pgSegCallusTitle => 'Die Wundheilung';

  @override
  String get pgSegCallusBody =>
      'Die Wunde trocknet an der Luft im Schatten, bis sich ein matter Kallus bildet.';

  @override
  String get pgSegCallusNote => 'Drei bis sieben Tage trocknen';

  @override
  String get pgSegPlantTitle => 'Das Substrat';

  @override
  String get pgSegPlantBody =>
      'Das verheilte Ende steckt kaum einen Zentimeter tief in sehr durchlässigem Substrat.';

  @override
  String get pgSegPlantNote => 'Das Glied vergraben';

  @override
  String get pgSegRootsTitle => 'Der Austrieb';

  @override
  String get pgSegRootsBody =>
      'Zuerst kommen die Wurzeln, dann ein neues Glied. Gegossen wird erst, wenn die Wurzeln halten.';

  @override
  String get parentPlant => 'Mutterpflanze';

  @override
  String get schedule => 'Pflegeplan';

  @override
  String get editPlant => 'Pflanze bearbeiten';

  @override
  String get archivePlant => 'Pflanze archivieren';

  @override
  String get archiveReasonTitle => 'Grund';

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
  String get healthIssue => 'Problem';

  @override
  String get issueOverwatering => 'Zu viel Wasser';

  @override
  String get issueUnderwatering => 'Zu wenig Wasser';

  @override
  String get issuePests => 'Schädlinge';

  @override
  String get issueDisease => 'Krankheit';

  @override
  String get issueRootRot => 'Wurzelfäule';

  @override
  String get issueTransplantShock => 'Umtopfschock';

  @override
  String get issueDeficiency => 'Nährstoffmangel';

  @override
  String get issueSunburn => 'Sonnenbrand';

  @override
  String get issueFrost => 'Frostschaden';

  @override
  String get needsSection => 'Bedürfnisse';

  @override
  String get detailsSection => 'Details';

  @override
  String get lifespan => 'Lebenszyklus';

  @override
  String get lifespanAnnual => 'Einjährig';

  @override
  String get lifespanBiennial => 'Zweijährig';

  @override
  String get lifespanPerennial => 'Mehrjährig';

  @override
  String get hardiness => 'Winterhärte';

  @override
  String get hardinessHardy => 'Winterhart';

  @override
  String get hardinessTender => 'Frostempfindlich';

  @override
  String get cuttingMonth => 'Monat für Stecklinge';

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
  String get strategyFixedHint => 'Das ganze Jahr dasselbe Intervall.';

  @override
  String get enabled => 'Aktiv';

  @override
  String get interval => 'Intervall';

  @override
  String get intervalSuggested => 'Empfohlenes Intervall';

  @override
  String intervalSuggestedDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Empfohlenes Intervall: $count Tage',
      one: 'Empfohlenes Intervall: 1 Tag',
    );
    return '$_temp0';
  }

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
  String get whatDidYouDo => 'Aktion';

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
      'Foto konnte nicht hinzugefügt werden. Erneut versuchen.';

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
  String get reduceMotionHint => 'Standardmäßig gilt die Systemeinstellung.';

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
      'Eine Benachrichtigung pro Tag, nur wenn Pflege fällig ist.';

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
  String get localAccountHint => 'Ihre Daten bleiben auf diesem Telefon.';

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
  String get onboardingSubtitle => 'Mit oder ohne Foto hinzufügen.';

  @override
  String get onbPlaceTitle => 'Ihre Stadt';

  @override
  String get onbPlaceBody =>
      'Für Wetter und Gießen im Freien. Eine Stadt genügt, die genaue Position wird nicht gespeichert.';

  @override
  String get useMyLocation => 'Meinen Standort verwenden';

  @override
  String get locating => 'Deine Stadt wird gesucht…';

  @override
  String get locationFailed =>
      'Standort nicht verfügbar. Du kannst unter Profil › Wetter eine Stadt wählen.';

  @override
  String get locationUnavailable => 'Standort nicht verfügbar.';

  @override
  String get onbHomeTitle => 'Dein Zuhause';

  @override
  String get onbHomeBody =>
      'Sensoren von Apple Home und Google Home liefern Temperatur und Luftfeuchtigkeit des Raums. Tipps und Diagnosen für Zimmerpflanzen berücksichtigen sie. Der Messwert bleibt in der App.';

  @override
  String get homeClimate => 'Sensoren im Zuhause';

  @override
  String get homeClimateHint =>
      'Temperatur und Luftfeuchtigkeit eines Sensors im Zuhause passen die Tipps für Zimmerpflanzen an und ergänzen Diagnosen. Der Messwert bleibt in der App.';

  @override
  String get homeClimateApple => 'Apple Home';

  @override
  String get homeClimateGoogle => 'Google Home';

  @override
  String get homeClimateConnect => 'Zuhause verbinden';

  @override
  String get homeClimateConnectApple => 'Apple Home verbinden';

  @override
  String get homeClimateConnectGoogle => 'Google Home verbinden';

  @override
  String get homeClimateSearching => 'Sensoren werden gesucht…';

  @override
  String get homeClimateSensor => 'Sensor';

  @override
  String get homeClimateSensors => 'Gefundene Sensoren';

  @override
  String get homeClimateChoose => 'Sensor wählen';

  @override
  String get homeClimateChange => 'Sensor wechseln';

  @override
  String get homeClimateHome => 'Zuhause';

  @override
  String get homeClimateSource => 'Plattform';

  @override
  String get homeClimateNoRoom => 'Ohne Raum';

  @override
  String get homeClimateTemperatureSensor => 'Temperatursensor';

  @override
  String get homeClimateHumiditySensor => 'Feuchtigkeitssensor';

  @override
  String get homeClimateSameSensor => 'Derselbe Sensor';

  @override
  String get homeClimateHumidityMissing =>
      'Keine Luftfeuchtigkeit von diesem Sensor empfangen. Ein anderer wird in der Zeile Luftfeuchtigkeit gewählt.';

  @override
  String get homeClimateNone => 'Kein Sensor';

  @override
  String get homeClimateRemove => 'Sensor entfernen';

  @override
  String get homeClimateReading => 'Messwert';

  @override
  String get homeClimateUnavailable => 'Sensor im Moment nicht erreichbar.';

  @override
  String homeClimateUpdatedAgo(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'Vor $minutes Min.',
      one: 'Vor 1 Min.',
      zero: 'Gerade eben',
    );
    return '$_temp0';
  }

  @override
  String homeClimateNoSensorsIn(String home) {
    return 'Kein Temperatur- oder Feuchtigkeitssensor in $home.';
  }

  @override
  String get homeClimateDeniedApple =>
      'Zugriff auf Apple Home abgelehnt. Er lässt sich unter Einstellungen › Datenschutz › Home wieder erteilen.';

  @override
  String get homeClimateDeniedGoogle =>
      'Zugriff auf Google Home abgelehnt. Er lässt sich in der Google-Home-App bei den Berechtigungen wieder erteilen.';

  @override
  String homeClimateFailedIn(String home) {
    return '$home nicht verfügbar. Du kannst unter Profil › Sensoren im Zuhause einen Sensor verbinden.';
  }

  @override
  String get homeClimateAppleNote => 'Apple Home liest Zubehör auf dem Gerät.';

  @override
  String get homeClimateGoogleNote =>
      'Google Home liest Geräte über dein Google-Konto.';

  @override
  String get homeClimateDisconnect => 'Trennen';

  @override
  String get homeClimateDisconnectGoogle => 'Google Home trennen';

  @override
  String get homeClimateDisconnectGoogleHint =>
      'Die Sensoren von Google Home werden auf diesem Gerät vergessen. Die erteilte Berechtigung bleibt im Google-Konto und wird dort entzogen.';

  @override
  String get homeClimateDisconnectedGoogle => 'Google Home getrennt.';

  @override
  String get homeClimateGoogleAccess => 'Berechtigungen im Google-Konto';

  @override
  String get homeClimateAtHome => 'Bei dir';

  @override
  String get homeClimateFits => 'Nichts, was dieser Art zusetzt.';

  @override
  String get homeClimateTooDry => 'Luft zu trocken für diese Art.';

  @override
  String get homeClimateTooHumid => 'Luft zu feucht für diese Art.';

  @override
  String get homeClimateTooCold => 'Zu kalt für diese Art.';

  @override
  String get homeClimateTooHot => 'Zu warm für diese Art.';

  @override
  String homeTipDryAir(String names) {
    return 'Trockene Luft: $names besprühen oder zusammenstellen.';
  }

  @override
  String get homeTipHumidAir => 'Feuchte Luft: den Raum lüften.';

  @override
  String homeTipHumidAirPlants(String names) {
    return 'Feuchte Luft: lüften, und $names zwischen zwei Wassergaben abtrocknen lassen.';
  }

  @override
  String homeTipCold(String names) {
    return 'Zu kalt für $names.';
  }

  @override
  String homeTipHot(String names) {
    return 'Hitze: $names trocknen schneller aus, Erde prüfen.';
  }

  @override
  String diagnosisWithHome(String reading) {
    return 'Messwert aus dem Zuhause angehängt: $reading.';
  }

  @override
  String placeChosen(String place) {
    return 'Wetter auf $place eingestellt.';
  }

  @override
  String get askNameTitle => 'Ihr Vorname';

  @override
  String get askNameSubtitle => 'Später im Profil änderbar.';

  @override
  String get onbAccountTitle => 'Sicherung und Teilen';

  @override
  String get onbAccountBody =>
      'Ein Konto sichert Ihre Daten und ermöglicht das Teilen eines Gartens. Anmeldung mit Ihrer Apple-ID.';

  @override
  String get notificationAskTitle => 'Tägliche Erinnerung';

  @override
  String get notificationAskBody =>
      'Eine Benachrichtigung pro Tag, zur gewählten Uhrzeit, nur wenn Pflege fällig ist.';

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
    return '$name: heute gießen.';
  }

  @override
  String notifWaterMany(String names) {
    return '$names: heute gießen.';
  }

  @override
  String notifOther(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weitere Pflegen fällig.',
      one: '1 weitere Pflege fällig.',
    );
    return '$_temp0';
  }

  @override
  String notifOnlyOther(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Pflegen heute fällig.',
      one: '1 Pflege heute fällig.',
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
  String get fertForm => 'Form';

  @override
  String get fertFormLiquid => 'Flüssig';

  @override
  String get fertFormGranules => 'Granulat';

  @override
  String get fertFormSticks => 'Stäbchen';

  @override
  String get fertFormSolublePowder => 'Lösliches Pulver';

  @override
  String get fertFormFoliar => 'Blattdünger';

  @override
  String get fertFormOther => 'Andere';

  @override
  String get fertOrigin => 'Herkunft';

  @override
  String get fertOriginMineral => 'Mineralisch';

  @override
  String get fertOriginOrganic => 'Organisch';

  @override
  String get fertOriginOrganomineral => 'Organisch-mineralisch';

  @override
  String get fertNpk => 'NPK';

  @override
  String get fertNpkPercent => 'NPK (%)';

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
  String get noInventorySubtitle => 'Dünger, Erde, Töpfe, Werkzeuge …';

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
  String get qrHint => 'Gescannt öffnet dieser Code die Pflanzenseite.';

  @override
  String get scan => 'Scannen';

  @override
  String get quickActionScan => 'Etikett scannen';

  @override
  String get scanHint => 'Richte die Kamera auf den QR-Code einer Pflanze.';

  @override
  String get unknownQr => 'Unbekannter QR-Code.';

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
  String get identifyTitle => 'Art';

  @override
  String get identifyHint => 'Artvorschläge, zu bestätigen';

  @override
  String get searchOnline => 'Online suchen';

  @override
  String get identifyAnotherPhoto => 'Foto hinzufügen';

  @override
  String get identifyAnotherPhotoHint =>
      'Ein Blatt, eine Blüte oder die ganze Pflanze hilft beim Eingrenzen.';

  @override
  String get identificationUncertainTitle => 'Bestimmung unsicher';

  @override
  String get identificationUncertainBody =>
      'Auch mit den verfügbaren Fotos hebt sich keine Art deutlich genug ab. Sie können online suchen oder manuell auswählen, wenn Sie die Pflanze erkennen.';

  @override
  String get identificationSuggestionsToCheck => 'Vorschläge zum Prüfen';

  @override
  String get identifyConfirmWithPhoto => 'Mit einem Foto bestätigen';

  @override
  String get searchingOnline => 'Online-Suche…';

  @override
  String get suggestionsLocal =>
      'Iris-Ergebnisse auf deinem Gerät · Foto nicht hochgeladen';

  @override
  String get suggestionsRemote => 'Online von Pl@ntNet vorgeschlagen';

  @override
  String identifyOnDevice(String name) {
    return 'Von $name auf dem Gerät erkannt. Wählen Sie die Art';
  }

  @override
  String get identifyViaPlantNet =>
      'Online von Pl@ntNet erkannt. Wählen Sie die Art';

  @override
  String get identifyPhotoSource =>
      'Fotos von Pl@ntNet und GBIF. Ein Foto antippen, um die Artenseite zu öffnen.';

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
  String identificationHint(String name) {
    return 'Arterkennung auf dem Gerät durch $name, ohne Netz. Im Zweifel kann das Foto an Pl@ntNet gesendet werden.';
  }

  @override
  String get identificationEnabled => 'Bestimmung aktiviert';

  @override
  String get identificationDisabled => 'Nicht konfiguriert';

  @override
  String get identificationFallback => 'Online-Rückfall';

  @override
  String identificationFallbackHint(String name) {
    return 'Im Zweifel von $name wird das Foto an Pl@ntNet gesendet. Aus: alles bleibt auf dem Gerät.';
  }

  @override
  String get irisFeedback => 'Senden identifizierter Fotos';

  @override
  String irisFeedbackHint(String name) {
    return 'Die zum Identifizieren aufgenommenen Fotos und der gewählte Name werden gesendet, sobald eine Pflanze benannt wird, und trainieren die nächsten Versionen des Modells $name. Sie sind nur für das sendende Konto lesbar, und dessen Löschung entfernt sie. Ausgeschaltet verlassen sie das Gerät nicht.';
  }

  @override
  String get irisFeedbackNeedsAccount =>
      'Zum Senden von Fotos braucht es ein Konto.';

  @override
  String get irisFeedbackAskTitle => 'Senden identifizierter Fotos';

  @override
  String irisFeedbackAskBody(String name) {
    return 'Die zum Identifizieren aufgenommenen Fotos und der gewählte Name können gesendet werden, um die nächsten Versionen des Modells $name zu trainieren. Sie sind nur für das sendende Konto lesbar, und dessen Löschung entfernt sie. Die Wahl lässt sich in den Einstellungen zur Erkennung ändern.';
  }

  @override
  String get genusUncertainSpecies => 'Art unsicher';

  @override
  String modelMissing(String name) {
    return '$name auf diesem Gerät nicht verfügbar';
  }

  @override
  String get modelLoading => 'Modell wird geladen…';

  @override
  String identificationStats(int local, int accepted, int remote) {
    return '$local auf dem Gerät analysiert, $accepted hier entschieden; $remote online gesendet';
  }

  @override
  String onlineSearchesMonth(int used, int limit) {
    return '$used von $limit Online-Suchen diesen Monat.';
  }

  @override
  String get irisSection => 'Das Modell im Gerät';

  @override
  String get irisTagline =>
      'Artenerkennung auf dem Telefon, ohne Netz und ohne Konto.';

  @override
  String get irisSpeciesLabel => 'Arten';

  @override
  String get irisOfflineValue => 'offline';

  @override
  String get irisOfflineLabel => 'auch im Flugzeug';

  @override
  String get irisTwoPhotosTitle => 'Zwei Fotos sind besser als eins';

  @override
  String irisTwoPhotosBody(String name) {
    return 'Die ganze Pflanze, dann ein Blatt aus der Nähe. Mit zwei Fotos findet $name die richtige Art in zwei von drei Fällen statt in einem von zwei.';
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
  String get outdoorHint =>
      'Balkon, Garten oder Gewächshaus: das Wetter wird berücksichtigt.';

  @override
  String get weather => 'Wetter';

  @override
  String get weatherHint =>
      'Für Pflanzen im Freien: gefallener Regen zählt als Gießen, angekündigter Regen verschiebt es, und Frost wie Hitze werden gemeldet. Daten von Open-Meteo.';

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
  String get weatherRainTitle => 'Heute Regen';

  @override
  String weatherRainSkip(String names) {
    return 'Das Gießen von $names kann warten.';
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
      'Eine ZIP-Datei mit Ihren Pflanzen, Verläufen, Inventar, Einstellungen und Fotos.';

  @override
  String get exporting => 'Export wird vorbereitet…';

  @override
  String get exportError => 'Export fehlgeschlagen. Erneut versuchen.';

  @override
  String get play => 'Abspielen';

  @override
  String get timelapseHint => 'Tippen zum Pausieren.';

  @override
  String notifLowStockOne(String name) {
    return '$name: geringer Vorrat.';
  }

  @override
  String notifLowStockMany(int count) {
    return '$count Artikel mit geringem Vorrat.';
  }

  @override
  String get accountTitle => 'Konto';

  @override
  String get signIn => 'Anmelden';

  @override
  String get signInWithAppleId => 'Mit deiner Apple-ID';

  @override
  String get signInHint =>
      'Ein Konto sichert Ihre Daten, synchronisiert sie zwischen Geräten und ermöglicht das Teilen eines Gartens.';

  @override
  String get continueWithApple => 'Mit Apple fortfahren';

  @override
  String get continueWithGoogle => 'Mit Google fortfahren';

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
  String syncUnknownColumns(String columns) {
    return 'Dem Server unbekannte Spalten: $columns';
  }

  @override
  String get syncSyncing => 'Synchronisiere…';

  @override
  String get authError =>
      'Anmeldung nicht möglich. Versuche es gleich noch einmal.';

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
      'Die Person braucht bereits ein Auxine-Konto mit dieser Adresse.';

  @override
  String get roleOwner => 'Eigentümer';

  @override
  String get roleMember => 'Mitglied';

  @override
  String get roleViewer => 'Nur lesen';

  @override
  String get invited => 'Einladung gesendet';

  @override
  String get inviteError => 'Diese Adresse hat noch kein Konto.';

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
  String get diagnosisTitle => 'Diagnose';

  @override
  String get diagnosisHint =>
      'Fotografieren Sie Blätter, Stängel und Erde, aus der Nähe und ganz. Die Ergebnisse sind Hinweise.';

  @override
  String get diagnosisMoreBelow => 'Weiter unten: Symptome und Beobachtungen';

  @override
  String get diagnosisSymptomsHint => 'Was dir aufgefallen ist…';

  @override
  String get diagnosisNeedsPhoto => 'Mindestens ein Foto.';

  @override
  String get diagnosisNeedsSymptoms =>
      'Was dir aufgefallen ist, auch in wenigen Worten.';

  @override
  String get diagnosisChecks => 'Beobachtungen';

  @override
  String get diagnosisChecksHint =>
      'Optional: Was das Foto nicht zeigt, schärft die Analyse.';

  @override
  String get diagnosisSoil => 'Erde';

  @override
  String get diagnosisSoilDry => 'Trocken';

  @override
  String get diagnosisSoilMoist => 'Feucht';

  @override
  String get diagnosisSoilSoggy => 'Durchnässt';

  @override
  String get diagnosisRoots => 'Wurzeln';

  @override
  String get diagnosisRootsFirm => 'Fest und hell';

  @override
  String get diagnosisRootsSoft => 'Braun oder weich';

  @override
  String get diagnosisRootsCrowded => 'Zu eng';

  @override
  String get diagnosisLightDirect => 'Direkte Sonne';

  @override
  String get diagnosisLightBright => 'Hell, ohne direkte Sonne';

  @override
  String get diagnosisLightDim => 'Wenig';

  @override
  String get diagnosisBugs => 'Insekten';

  @override
  String get diagnosisBugsNone => 'Keine gesehen';

  @override
  String get diagnosisBugsOnPlant => 'An der Pflanze';

  @override
  String get diagnosisBugsInSoil => 'In der Erde';

  @override
  String get diagnosisSymptoms => 'Symptome';

  @override
  String get diagnosisAround => 'Um die Pflanze herum';

  @override
  String get diagnosisPhotosFull => 'Höchstens drei Fotos.';

  @override
  String get diagnosisRemovePhoto => 'Dieses Foto entfernen';

  @override
  String get diagnosisFinding => 'Befund';

  @override
  String get diagnosisNothingWrong => 'Nichts Auffälliges';

  @override
  String get diagnosisNatural => 'Normale Erscheinung';

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
      'Die Diagnose ist im Moment nicht verfügbar. Versuche es später noch einmal.';

  @override
  String get diagnosisBusy =>
      'Der Analysedienst antwortet nicht. In einem Moment erneut versuchen.';

  @override
  String get diagnosisUnreadable =>
      'Die Analyse ist fehlgeschlagen. Erneut versuchen.';

  @override
  String get diagnosisUncertain =>
      'Die Fotos reichen für keinen Schluss. Die Spuren unten müssen geprüft werden.';

  @override
  String get diagnosisAnotherPhotoHint =>
      'Ein weiteres Foto würde die Analyse schärfen.';

  @override
  String get diagnosisQuestionsHint => 'Was zum Entscheiden fehlt.';

  @override
  String get diagnosisAnswerHint => 'Antwort…';

  @override
  String get diagnosisAnswerAgain => 'Analyse erneut starten';

  @override
  String get diagnosisAnswersNoted => 'Gegebene Antworten';

  @override
  String diagnosisAnotherPhotoView(String view) {
    return 'Zu fotografieren: $view.';
  }

  @override
  String get diagnosisAnotherPhoto => 'Foto hinzufügen';

  @override
  String get diagnosisViewLeafCloseup => 'ein Blatt aus der Nähe';

  @override
  String get diagnosisViewLeafUnderside => 'die Blattunterseite';

  @override
  String get diagnosisViewWholePlant => 'die ganze Pflanze';

  @override
  String get diagnosisViewStemBase => 'der Stängelansatz';

  @override
  String get diagnosisViewSoilRoots => 'die Erde am Fuß';

  @override
  String get possibleCauses => 'Mögliche Ursachen';

  @override
  String get causesHint => 'Nach Wahrscheinlichkeit geordnet, zu bestätigen.';

  @override
  String get likelihoodLikely => 'Wahrscheinlich';

  @override
  String get likelihoodPossible => 'Möglich';

  @override
  String get likelihoodUnlikely => 'Wenig wahrscheinlich';

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
      'Die Fotos werden von einem in der Schweiz gehosteten Modell analysiert (Infomaniak AI Services). Sie werden nur gesendet, wenn du eine Analyse startest, und nicht gespeichert.';

  @override
  String get diagnosisEnabled => 'Diagnose aktiviert';

  @override
  String get diagnosisUnavailable => 'Diagnose nicht verfügbar';

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
  String get diagnosisEntry => 'Diagnose';

  @override
  String get diagnosisOpen => 'Vollständige Diagnose ansehen';

  @override
  String get diagnosisSymptomsNoted => 'Gemeldete Symptome';

  @override
  String diagnosisMoreCauses(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weitere Spuren',
      one: '1 weitere Spur',
    );
    return '$_temp0';
  }

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
  String get taskTitleHint => 'Titel';

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
      'Aussaat, Gewächshaus reinigen, Erde bestellen …';

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
    return 'Zu erledigen: $title';
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
  String get careSupport => 'Rankhilfe';

  @override
  String get careSupportMossPole => 'Moosstab';

  @override
  String get careSupportStake => 'Pflanzstab';

  @override
  String get careSupportTrellis => 'Spalier';

  @override
  String get careSupportMossPoleCare =>
      'Den Moosstab bei jedem Gießen befeuchten: daran halten sich die Luftwurzeln.';

  @override
  String get careSupportStakeCare =>
      'Den Trieb locker anbinden, während er nach oben wächst.';

  @override
  String get careSupportTrellisCare =>
      'Die Triebe führen, während sie wachsen.';

  @override
  String get careIssues => 'Darauf achten';

  @override
  String get careKnownProblems => 'Bekannte Probleme an dieser Pflanze';

  @override
  String get careKnownProblemsNote =>
      'Bei dieser Art oder verwandten Arten gemeldet.';

  @override
  String get careLeafSigns => 'Anzeichen an den Blättern';

  @override
  String get careLeafSignsNote =>
      'Was ein Blatt zeigt, und was es meistens erklärt.';

  @override
  String get leafSignPaling => 'Blätter werden heller';

  @override
  String get leafSignYellowing => 'Gelbe Blätter';

  @override
  String get leafSignScorched => 'Verbrannte Blätter';

  @override
  String get leafSignSpots => 'Flecken mitten auf dem Blatt';

  @override
  String get leafSignBrownTips => 'Braune Spitzen und Ränder';

  @override
  String get leafSignStunted => 'Blätter wachsen nicht mehr';

  @override
  String get leafSignDrooping => 'Schlaffe Blätter';

  @override
  String get leafSignFalling => 'Blätter fallen ab';

  @override
  String get leafSignSticky => 'Klebrige Blätter';

  @override
  String get leafCauseTooMuchSun => 'Zu viel direkte Sonne';

  @override
  String get leafCauseNotEnoughLight => 'Zu wenig Licht';

  @override
  String get leafCauseOverwatering => 'Zu häufiges Gießen';

  @override
  String get leafCauseUnderwatering => 'Substrat zu lange trocken geblieben';

  @override
  String get leafCauseDryAir => 'Zu trockene Luft';

  @override
  String get leafCauseColdDraught => 'Kälte oder Zugluft';

  @override
  String get leafCauseHardWater => 'Kalkhaltiges Wasser oder zu viel Dünger';

  @override
  String get leafCausePoorSoil => 'Erschöpftes Substrat';

  @override
  String get leafCausePotBound => 'Wurzeln zu eng im Topf';

  @override
  String get leafCauseDamagedRoots => 'Wurzeln durch Staunässe geschädigt';

  @override
  String get leafCauseLeafPests => 'Saugschäden von Spinnmilben oder Thripsen';

  @override
  String get leafCauseHoneydewPests =>
      'Woll- oder Blattläuse, an der Pflanze oder darüber';

  @override
  String get leafCauseSootyMould =>
      'Rußtau, das Schwarze, das auf dem Honigtau wächst';

  @override
  String get leafCauseLeafFungus => 'Pilz oder Bakterium auf dem Blatt';

  @override
  String get leafCauseWetLeaves => 'Wasser auf dem Laub geblieben';

  @override
  String get leafCauseRecentMove => 'Kürzlicher Standortwechsel oder Umtopfen';

  @override
  String get leafCauseOldLeaves => 'Alternde untere Blätter';

  @override
  String get leafCauseWinterRest => 'Winterruhe';

  @override
  String get problemKindDisorder => 'Störung';

  @override
  String get problemKindPest => 'Schädling';

  @override
  String get problemKindDisease => 'Krankheit';

  @override
  String get problemKindCondition => 'Belag';

  @override
  String get problemKindDisorders => 'Störungen';

  @override
  String get problemKindPests => 'Schädlinge';

  @override
  String get problemKindDiseases => 'Krankheiten';

  @override
  String get problemKindConditions => 'Beläge';

  @override
  String get careTips => 'Tipps';

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
  String get careDryDownAlwaysMoist => 'Substrat immer feucht halten';

  @override
  String get careDryDownSurfaceDry => 'Oberfläche antrocknen lassen';

  @override
  String get careDryDownTopQuarterDry => 'Oberes Viertel antrocknen lassen';

  @override
  String get careDryDownHalfDry => 'Zur Hälfte antrocknen lassen';

  @override
  String get careDryDownMostlyDry => 'Fast durchtrocknen lassen';

  @override
  String get careDryDownFullyDry => 'Vollständig durchtrocknen lassen';

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
  String get careRepotNone => 'Kein Umtopfen (einjährige Kultur)';

  @override
  String get carePotSnug => 'Besser eng';

  @override
  String get carePotRoomy => 'Ein breiter Topf';

  @override
  String get carePotSnugNote =>
      'Eine Wurzel aus dem Abzugsloch reicht nicht: umtopfen, wenn der Ballen ein Wurzelblock ist oder das Wasser nicht mehr einzieht.';

  @override
  String get carePotSteadyNote =>
      'Umtopfen, wenn Wurzeln aus dem Abzugsloch treten und sich am Topfboden drehen.';

  @override
  String get carePotRoomyNote =>
      'Umtopfen, sobald die Wurzeln die Topfwand erreichen: zu eng, und das Wachstum hört auf.';

  @override
  String get carePotDormantNote =>
      'Umgetopft wird beim Neuaustrieb, am Ende der Ruhe, nicht wegen einer austretenden Wurzel.';

  @override
  String careTempIdeal(int min, int max) {
    return '$min bis $max °C';
  }

  @override
  String careTempMin(int min) {
    return 'Nicht unter $min °C';
  }

  @override
  String get careEnvTitle => 'Idealer Standort';

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
    return 'Temperatur von $min bis $max Grad';
  }

  @override
  String careEnvSemanticTempMin(int min) {
    return 'Temperatur über $min Grad';
  }

  @override
  String get careAirflow => 'Zugluft';

  @override
  String get careAirflowSheltered => 'Vor Zugluft geschützt';

  @override
  String get careAirflowNormal => 'Gewöhnliche Luft';

  @override
  String get careAirflowVentilated => 'Gut belüftete Luft';

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
  String careLightFloor(String value) {
    return 'Hält bis $value';
  }

  @override
  String careLightLamp(int min, int max, int hours) {
    return 'Unter Lampe · Vollspektrum-LED, $min bis $max µmol/m²/s, $hours h am Tag';
  }

  @override
  String careLightLampDli(int min, int max) {
    return 'Das sind $min bis $max mol/m²/Tag am Blattwerk.';
  }

  @override
  String get careHumidityLow => 'Trockene Luft ist in Ordnung';

  @override
  String get careHumidityAverage => 'Normale Luftfeuchtigkeit';

  @override
  String get careHumidityHigh => 'Feuchte Luft';

  @override
  String careHumidityRange(int min, int max) {
    return '$min bis $max % Luftfeuchte';
  }

  @override
  String get careHumidityLowDetail =>
      'Sie verträgt die trockene Zimmerluft gut. Dauerhaft höhere Feuchte schadet ihr.';

  @override
  String get careHumidityAverageDetail =>
      'Normale Zimmerluft genügt. Im Winter fern der Heizung bleiben die Blattspitzen grün.';

  @override
  String get careHumidityHighDetail =>
      'Die trockene Luft einer beheizten Wohnung schadet ihr: die Luft muss feucht gehalten werden.';

  @override
  String get careHumidityMethodMist => 'Die Blätter besprühen.';

  @override
  String get careHumidityMethodHumidifier => 'Ein Luftbefeuchter.';

  @override
  String get careHumidityMethodTray =>
      'Ein Untersetzer mit feuchten Blähtonkugeln oder zusammengestellte Pflanzen.';

  @override
  String get careHumidityMethodTerrarium =>
      'Unter Glas: Terrarium, Glocke oder Glas.';

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
  String get careToxicityFromSpecies => 'Für diese Art belegt';

  @override
  String careToxicityFromGenus(String name) {
    return 'Gattung $name · für diese Art nicht belegt';
  }

  @override
  String careToxicityFromFamily(String name) {
    return 'Familie $name · für diese Art nicht belegt';
  }

  @override
  String careToxicitySource(String name) {
    return 'Quelle: $name';
  }

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
  String get careSoilNone => 'Ganz ohne Substrat';

  @override
  String get careGrowthMedium => 'Lebensraum';

  @override
  String get careMediumTerrestrial => 'Terrestrisch';

  @override
  String get careMediumEpiphytic => 'Epiphytisch';

  @override
  String get careMediumLithophytic => 'Lithophytisch';

  @override
  String get careMediumAquatic => 'Aquatisch';

  @override
  String get careMediumSemiAquatic => 'Halbaquatisch';

  @override
  String get careMediumTerrestrialNote => 'Sie wächst in Erde.';

  @override
  String get careMediumEpiphyticNote =>
      'Sie wächst auf einem Träger ohne Erde: Rinde, Moos oder nichts.';

  @override
  String get careMediumLithophyticNote =>
      'Sie wächst auf Stein, die Wurzeln in den Spalten.';

  @override
  String get careMediumAquaticNote => 'Ihre Wurzeln leben im Wasser.';

  @override
  String get careMediumSemiAquaticNote =>
      'Sie lebt in durchnässtem Boden, am Wasserrand.';

  @override
  String get careWater => 'Wasser';

  @override
  String get careWaterTolerant => 'Leitungswasser';

  @override
  String get careWaterSensitive => 'Kalkarmes Wasser';

  @override
  String get careWaterStrict => 'Kalkfreies Wasser';

  @override
  String get careWaterTolerantNote => 'Kalk hat keine Wirkung.';

  @override
  String get careWaterSensitiveNote => 'Kalk färbt ihre Blattspitzen braun.';

  @override
  String get careWaterFluorideSensitive =>
      'Fluorid im Leitungswasser färbt die Blattspitzen braun: Regen- oder Osmosewasser.';

  @override
  String get careWaterStrictNote =>
      'Kalk schadet ihr, schon in kleinen Mengen.';

  @override
  String get careWaterTypes => 'Wasserarten';

  @override
  String get careWaterTypesNote =>
      'Die Härte des Leitungswassers ändert sich von Gemeinde zu Gemeinde; die jährliche Analyse des Versorgers nennt sie.';

  @override
  String get careWaterBest => 'Empfohlen';

  @override
  String get careWaterOk => 'Geeignet';

  @override
  String get careWaterCaution => 'Mit Vorbehalt';

  @override
  String get careWaterAvoid => 'Zu vermeiden';

  @override
  String get careWaterTap => 'Leitungswasser';

  @override
  String get careWaterTapNote =>
      'Wasser aus dem Netz, so wie es kommt. Seine Härte hängt von der Gemeinde ab.';

  @override
  String get careWaterTapRisk =>
      'Kalk sammelt sich in der Erde und hebt ihren pH-Wert. Abgestandenes Wasser verliert das Chlor, nicht den Kalk.';

  @override
  String get careWaterRain => 'Regenwasser';

  @override
  String get careWaterRainNote => 'Weich, kalkfrei, leicht sauer.';

  @override
  String get careWaterRainRisk =>
      'Vom Dach gesammelt, trägt es Staub und Vogelkot mit; ein offenes Fass wird grün. Die ersten Minuten Regen ablaufen lassen und die Tonne abdecken.';

  @override
  String get careWaterFiltered => 'Gefiltertes Wasser';

  @override
  String get careWaterFilteredNote =>
      'Ein Filterkrug entfernt das Chlor und einen Teil des Kalks.';

  @override
  String get careWaterFilteredRisk =>
      'Wie viel zurückgehalten wird, hängt von der Kartusche ab, und eine erschöpfte Kartusche hält nichts mehr zurück. Der Kalk verschwindet nie vollständig.';

  @override
  String get careWaterOsmosis => 'Osmosewasser';

  @override
  String get careWaterOsmosisNote => 'Nahezu mineralfrei, wie Regenwasser.';

  @override
  String get careWaterOsmosisRisk =>
      'Es bringt keine Nährstoffe mit: der Dünger bleibt die einzige Quelle. Bei einer gewöhnlichen Pflanze gleicht ein Drittel Leitungswasser das aus.';

  @override
  String get careWaterDemineralized => 'Entmineralisiertes Wasser';

  @override
  String get careWaterDemineralizedNote =>
      'Für Bügeleisen verkauft, entspricht es Osmosewasser, solange es rein ist.';

  @override
  String get careWaterDemineralizedRisk =>
      'Manche Kanister enthalten einen Entkalkerzusatz oder einen Duftstoff: das Etikett lesen. Wie Osmosewasser bringt es keine Nährstoffe mit.';

  @override
  String get careWaterCondensate => 'Klimaanlagenwasser';

  @override
  String get careWaterCondensateNote =>
      'Das Kondensat einer Klimaanlage oder eines Luftentfeuchters, vom Gerät destilliert.';

  @override
  String get careWaterCondensateRisk =>
      'Es ist über einen Wärmetauscher und durch eine Wanne gelaufen, in der sich Staub, Biofilm und Bakterien sammeln, und kann Metallspuren mitführen. Nur für Zierpflanzen, aus einem sauberen Gerät, nie auf Essbares.';

  @override
  String get careWaterSoftened => 'Enthärtetes Wasser';

  @override
  String get careWaterSoftenedNote =>
      'Ein Enthärter mit Harz tauscht den Kalk gegen Natrium.';

  @override
  String get careWaterSoftenedRisk =>
      'Natrium sammelt sich in der Erde, schädigt die Wurzeln und verdichtet das Bodengefüge. Der unbehandelte Hahn vor dem Enthärter bleibt der richtige.';

  @override
  String get careSoilMixStandard =>
      'Mit 20 % Perlit aufgelockert, damit das Wasser durchläuft.';

  @override
  String get careSoilMixDraining =>
      '50 % Erde, 25 % Perlit, 25 % grober Sand oder Lavagranulat.';

  @override
  String get careSoilMixCactus =>
      '30 % Erde, 70 % Lavagranulat, Bims oder grober Sand.';

  @override
  String get careSoilMixOrchid =>
      'Mittlere Pinienrinde, 10 % Perlit, etwas Sphagnum; niemals Blumenerde.';

  @override
  String get careSoilMixAcidic =>
      'Mit 25 % Pinienrinde aufgelockert, ohne Kalk und ohne Kompost.';

  @override
  String get careSoilMixRich => '40 % Erde, 40 % Kompost, 20 % Perlit.';

  @override
  String get careSoilMixNone =>
      'Kein Substrat: die Wurzeln leben in der Luft oder im Wasser.';

  @override
  String careSoilFree(String water, String pon) {
    return 'Im Wasser: $water · In Pon: $pon';
  }

  @override
  String get careSoilFreeYes => 'ja';

  @override
  String get careSoilFreeNo => 'nein';

  @override
  String get careSoilFreeCuttings => 'nur Stecklinge';

  @override
  String get careFertBalanced =>
      'Ausgewogener Grünpflanzendünger, halb dosiert.';

  @override
  String get careFertFoliage =>
      'Stickstoffbetonter Dünger, der fürs Blattwerk.';

  @override
  String get careFertFlowering => 'Kalibetonter Dünger, der für die Blüte.';

  @override
  String get careFertCactus => 'Kakteendünger, stickstoffarm.';

  @override
  String get careFertOrchid => 'Orchideendünger, stark verdünnt.';

  @override
  String get careFertAcidic => 'Rhododendrondünger, kalkfrei.';

  @override
  String get careFertCitrus =>
      'Zitrusdünger, stickstoffreich und mit Spurenelementen.';

  @override
  String get careFertVegetable => 'Tomatendünger, kalireich.';

  @override
  String get careCalciumAvoid =>
      'Kalzium: keine Gabe, dazu Regenwasser; Kalk lässt ihr Laub vergilben.';

  @override
  String get careCalciumWelcome =>
      'Kalzium: hartes Wasser ist unbedenklich; zerstoßene Eierschalen beim Umtopfen liefern welches.';

  @override
  String get careCalciumNeeded =>
      'Kalzium: eine stetige Versorgung verhindert Blütenendfäule.';

  @override
  String get careGreenhouse => 'Im Gewächshaus';

  @override
  String get careGreenhouseWarmHumid => 'Wärme und feuchte Luft';

  @override
  String get careGreenhouseWarmLight => 'Wärme und Licht';

  @override
  String get careGreenhouseWarmDry => 'Wärme, Licht und trockene Luft';

  @override
  String get careGreenhouseGrowth =>
      'Das ganze Jahr gehalten, beschleunigen diese Bedingungen den Wuchs: Gießen und Düngen rücken ebenso zusammen.';

  @override
  String get careGreenhouseHold =>
      'Den Feuchtebereich tagsüber halten, nachts absinken lassen und die Luft bewegen.';

  @override
  String get careGreenhouseAir =>
      'Täglich lüften: stehende Luft lässt Pflanzen aus trockenen Lebensräumen faulen.';

  @override
  String get careGreenhouseEarly =>
      'Im Frühbeet oder Mini-Gewächshaus starten Aussaaten vier bis sechs Wochen früher.';

  @override
  String get careBloom => 'Blüte';

  @override
  String careSeasonRange(String from, String to) {
    return 'Von $from bis $to';
  }

  @override
  String get careBloomOutdoors => 'Selten im Zimmer';

  @override
  String get careBloomChillBulb => 'Kälte für die Zwiebel';

  @override
  String get careBloomChillBulbNote =>
      'Rechnen Sie mit zehn bis fünfzehn Wochen bei 5 bis 9 °C im Dunkeln, bevor der Topf wieder warm und hell steht.';

  @override
  String get careBloomFertilizer => 'Blühdünger';

  @override
  String get careBloomFertilizerNote =>
      'Sobald sich Knospen bilden, auf Blühdünger wechseln, der kalireicher ist als der fürs Laub.';

  @override
  String get careBloomMaturity => 'Etwas Alter';

  @override
  String get careBloomMaturityNote =>
      'Sie blüht erst ab drei oder vier Jahren: davor ändert keine Maßnahme etwas.';

  @override
  String get careBloomDeadhead => 'Verblühtes abschneiden';

  @override
  String get careBloomDeadheadNote =>
      'Verblühtes laufend abschneiden: ohne Samenbildung blüht die Pflanze erneut.';

  @override
  String get careBloomKeepSpike => 'Ein behaltener Blütentrieb';

  @override
  String get careBloomKeepSpikeNote =>
      'Solange der Blütentrieb grün bleibt, stehen lassen: er kann aus einem tieferen Auge erneut blühen.';

  @override
  String get careBloomNoMove => 'Ein fester Platz';

  @override
  String get careBloomNoMoveNote =>
      'Nach der Knospenbildung nicht mehr umstellen und nicht mehr drehen: der Wechsel lässt sie abfallen.';

  @override
  String get careBloomEvenWater => 'Gleichmäßiges Gießen';

  @override
  String get careBloomEvenWaterNote =>
      'Während der Knospenbildung gleichmäßig gießen: eine einzige Trockenphase lässt sie abfallen.';

  @override
  String get careRest => 'Ruhe';

  @override
  String careRestStoreDarkTemp(int min, int max) {
    return 'Trocken und dunkel, zwischen $min und $max °C';
  }

  @override
  String careRestStoreTemp(int min, int max) {
    return 'Trocken, zwischen $min und $max °C';
  }

  @override
  String get careRestStoreDark => 'Trocken und dunkel';

  @override
  String get careRestStorePlain => 'Trocken';

  @override
  String get careRestNote =>
      'Das Laub vergilben und trocknen lassen, ohne es zu schneiden, dann das Gießen einstellen. Am Ende dieser Zeit den Topf wieder ans Licht stellen und erneut gießen.';

  @override
  String get careBloomCoolRest => 'Ein kühler Winter';

  @override
  String get careBloomCoolRestNote =>
      'Für die Blütenbildung etwa zwei Monate bei 10–12 °C halten und deutlich weniger gießen.';

  @override
  String get careBloomCoolNights => 'Kühle Nächte';

  @override
  String get careBloomCoolNightsNote =>
      'Im Herbst können etwa drei Wochen mit Nächten um 15 °C die Bildung des Blütentriebs anregen.';

  @override
  String get careBloomShortDays => 'Kurze Tage';

  @override
  String get careBloomShortDaysNote =>
      'Etwa sechs Wochen lang lösen Nächte mit mindestens 12 Stunden Dunkelheit die Knospenbildung aus.';

  @override
  String get careBloomDrySpell => 'Eine Trockenzeit';

  @override
  String get careBloomDrySpellNote =>
      'Gießen Sie einige Wochen deutlich weniger und steigern Sie danach langsam wieder. Dieser Wechsel kann die Blüte auslösen.';

  @override
  String get careBloomPotbound => 'Ein enger Topf';

  @override
  String get careBloomPotboundNote =>
      'Sie blüht oft besser, wenn die Wurzeln den Topf gut ausfüllen. Deshalb nicht zu früh umtopfen.';

  @override
  String get careBloomBrightLight => 'Mehr Licht';

  @override
  String get careBloomBrightLightNote =>
      'Blühen braucht mehr Licht als Wachsen: ein sehr heller Platz, ohne sengende Sonne.';

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
      'Richtwerte, anzupassen an Licht, Topf und Raumluft.';

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
  String get careIssueOverwatering => 'Zu viel Wasser (weiche, gelbe Blätter)';

  @override
  String get careIssueUnderwatering => 'Zu wenig Wasser (hängende Blätter)';

  @override
  String get careIssueRootRot => 'Wurzelfäule';

  @override
  String get careIssueSpiderMites => 'Spinnmilben (feine Gespinste)';

  @override
  String get careIssueThrips => 'Thripse (silbrige Blätter)';

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
  String get careIssueTrueBugs => 'Wanzen';

  @override
  String get careIssueSlugs => 'Schnecken';

  @override
  String get careIssuePowderyMildew => 'Echter Mehltau';

  @override
  String get careIssueGreyMould => 'Grauschimmel (Botrytis)';

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
  String get careIssueChlorosis => 'Chlorose (blasse Blätter, grüne Adern)';

  @override
  String get careIssueBlossomEndRot => 'Blütenendfäule';

  @override
  String get careTipFingerTest =>
      'Finger hineinstecken und gießen, wenn die oberen 2 cm trocken sind.';

  @override
  String get careTipDrySoilFirst =>
      'Substrat zwischen den Wassergaben ganz abtrocknen lassen.';

  @override
  String get careTipNeverDryOut => 'Das Substrat nie ganz austrocknen lassen.';

  @override
  String get careTipEvenWatering =>
      'Gleichmäßig gießen, denn Schwankungen lassen Früchte platzen.';

  @override
  String get careTipWaterAtBase => 'Am Fuß gießen, Blätter trocken halten.';

  @override
  String get careTipNoWaterOnLeaves =>
      'Blätter nicht benetzen, denn stehendes Wasser fleckt.';

  @override
  String get careTipBottomWatering =>
      'Von unten gießen, den Topf 20 Minuten in Wasser stellen.';

  @override
  String get careTipThirstyPlant =>
      'Hoher Wasserbedarf: im Sommer täglich die Erde prüfen.';

  @override
  String get careTipDroopSignal => 'Hängende Blätter zeigen Wassermangel an.';

  @override
  String get careTipWinterDry => 'Im Winter fast trocken halten.';

  @override
  String get careTipWinterRest =>
      'Im Winter steht das Wachstum still: viel weniger Wasser.';

  @override
  String get careTipSummerDormant =>
      'Ruhe im Sommer: in dieser Zeit sehr wenig Wasser.';

  @override
  String get careTipNoWaterWhileSplitting =>
      'Während des Blattwechsels nicht gießen.';

  @override
  String get careTipOrchidSoak =>
      'Topf 10 Minuten tauchen, dann gut abtropfen.';

  @override
  String get careTipSoakMount =>
      'Ganze Pflanze tauchen, dann an der Luft trocknen.';

  @override
  String get careTipDryUpsideDown =>
      'Nach dem Bad kopfüber trocknen, denn Wasser im Herz führt zu Fäule.';

  @override
  String get careTipWaterInTheCup =>
      'Zentrale Rosette füllen und Wasser wöchentlich wechseln.';

  @override
  String get careTipNoSoil =>
      'Sie lebt ohne Erde und liegt einfach auf einem Halter.';

  @override
  String get careTipGreenRoots =>
      'Grüne Wurzeln zeigen genug Wasser, silbrige zeigen Durst.';

  @override
  String get careTipHumidityTray => 'Topf auf feuchte Blähtonkugeln stellen.';

  @override
  String get careTipNoDirectSun =>
      'Direkte Sonne meiden, sie verbrennt die Blätter.';

  @override
  String get careTipToleratesLowLight =>
      'Sie erträgt dunkle Räume, wächst am Fenster aber schneller.';

  @override
  String get careTipToleratesNeglect =>
      'Vergessenes Gießen schadet nicht: im Zweifel nicht gießen.';

  @override
  String get careTipBrightForColor => 'Je heller, desto kräftiger die Farben.';

  @override
  String get careTipRotatePot =>
      'Eine Vierteldrehung des Topfs pro Woche hält den Trieb gerade.';

  @override
  String get careTipHatesMoving =>
      'Einen festen Platz behalten: jeder Ortswechsel kostet Blätter.';

  @override
  String get careTipWipeLeaves => 'Blätter abwischen: Staub hält das Licht ab.';

  @override
  String get careTipTrimToBushOut =>
      'Lange Triebe kürzen lässt die Pflanze verzweigen.';

  @override
  String get careTipMonsteraSupport =>
      'An einem Moosstab werden die Blätter größer und geschlitzter.';

  @override
  String get careTipShallowPot => 'Ein breiter, flacher Topf.';

  @override
  String get careTipLikesBeingPotbound =>
      'Die Blüte ist im engen Topf besser: selten umtopfen.';

  @override
  String get careTipTrunkStoresWater =>
      'Der dicke Fuß speichert Wasser, lieber zu wenig als zu viel.';

  @override
  String get careTipPupsToShare =>
      'Kindel lassen sich abtrennen, zum Vermehren oder Verschenken.';

  @override
  String get careTipKeepFlowerSpike =>
      'Grünen Blütenstiel stehen lassen, er kann erneut blühen.';

  @override
  String get careTipDarkForRebloom =>
      'Zum Nachblühen: sechs Wochen lange, kühle Nächte.';

  @override
  String get careTipNotADesertCactus =>
      'Ein Waldkaktus, kein Wüstenkaktus: Schatten und feuchte Luft.';

  @override
  String get careTipDeadheadFlowers =>
      'Verblühtes entfernen verlängert die Blüte.';

  @override
  String get careTipPinchFlowers =>
      'Blütenknospen ausknipsen, damit die Blätter zart bleiben.';

  @override
  String get careTipHarvestTop => 'Von oben ernten, über einem Blattpaar.';

  @override
  String get careTipHarvestOutside =>
      'Äußere Blätter ernten, die Mitte wächst weiter.';

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
      'Zweimal jährlich schneiden reicht, im Juni und Ende August.';

  @override
  String get careTipContainItsRoots =>
      'Die Rhizome breiten sich überall aus: in den Topf, oder hinter eine Rhizomsperre.';

  @override
  String get careTipMulchIt =>
      'Den Fuß mulchen, das spart Wasser und bremst Unkraut.';

  @override
  String get careTipAcidSoil => 'Saurer Boden, keine Universalerde.';

  @override
  String get careTipFeedsOnInsects =>
      'Sie ernährt sich von Insekten: kein Dünger und ein armer Boden.';

  @override
  String get careTipBlueNeedsAcid =>
      'Blaue Blüten brauchen sauren Boden; im Kalk werden sie rosa.';

  @override
  String get careTipCitrusFertilizer =>
      'Den ganzen Sommer über Zitrusdünger geben.';

  @override
  String get careTipNoFertilizer =>
      'Nicht düngen: nährstoffreiche Erde schwächt Duft und Form.';

  @override
  String get careTipNoNitrogen =>
      'Kein Stickstoffdünger: die Pflanze bindet Stickstoff selbst.';

  @override
  String get careTipLetFoliageDieBack =>
      'Laub vergilben lassen, es füttert die Zwiebel.';

  @override
  String get careTipDiesBackInWinter =>
      'Das Laub zieht im Winter ein und treibt im Frühling neu aus.';

  @override
  String get careTipSummerOutdoors =>
      'Im Sommer nach draußen, anfangs in den Schatten.';

  @override
  String get careTipWinterIndoors => 'Vor dem ersten Frost hereinholen.';

  @override
  String get careTipWinterShelter => 'Kühl und hell überwintern.';

  @override
  String get careTipWinterCool => 'Kühler (10–14 °C), heller Winter.';

  @override
  String get careTipCoolerIsBetter => 'Besser kühl: nicht neben die Heizung.';

  @override
  String get careTipHardyOutdoors =>
      'Winterhart, sie bleibt ungeschützt draußen.';

  @override
  String get careTipShelterFromWind =>
      'Windgeschützt stellen, das Laub reißt leicht.';

  @override
  String get careTipAirFlow =>
      'Luft um die Pflanze: stehende Luft fördert Krankheiten.';

  @override
  String get careTipSpiderMiteWatch =>
      'Blattunterseiten prüfen, dort sitzen Spinnmilben.';

  @override
  String get careTipSlugWatch =>
      'Junge Triebe im Frühjahr vor Schnecken schützen.';

  @override
  String get careTipBoxMothWatch =>
      'Auf den Buchsbaumzünsler achten, Raupen und Gespinste verraten ihn.';

  @override
  String get careTipSapIrritant =>
      'Der Saft reizt Haut und Augen, daher mit Handschuhen schneiden.';

  @override
  String get careTipVeryToxic =>
      'Alle Teile sind sehr giftig, auch der Rauch beim Verbrennen.';

  @override
  String get careTipSharpSpines => 'Spitze Dornen: nicht an Wegen.';

  @override
  String get careTipSplitsAreNormal =>
      'Blätter reißen mit dem Alter ein, das ist normal und keine Krankheit.';

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
      'Felder, die für mehrere Pflanzen wiederverwendbar sind.';

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
  String get photoUrlInvalid => 'Die Adresse muss mit https:// beginnen';

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
  String get searchByNumberHint => '#42 eingeben, um Pflanze Nr. 42 zu finden.';

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
      'Artikel werden nicht gelöscht, sie wandern in die gewählte Gruppe.';

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
  String get noGroupsYet => 'Keine Gruppen.';

  @override
  String get deleteGroupExplain =>
      'Artikel werden nicht gelöscht, sie verlieren ihre Gruppe.';

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
      'Ereignisse werden nicht gelöscht, sie verlieren ihre Kategorie.';

  @override
  String get noEventCategoriesYet => 'Keine Kategorien.';

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
  String get statOldest => 'Älteste';

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
  String get noWarnings => 'Nichts zu melden.';

  @override
  String get recentPlantsSection => 'Neueste Pflanzen';

  @override
  String get recentAdded => 'Hinzugefügt';

  @override
  String get recentUpdated => 'Geändert';

  @override
  String get activityLogTitle => 'Aktivitätsprotokoll';

  @override
  String get activityEmpty => 'Keine Aktivität.';

  @override
  String get activityPlantAdded => 'Zum Garten hinzugefügt';

  @override
  String get activityPlantArchived => 'Archiviert';

  @override
  String get activityLocationNote => 'Standortnotiz';

  @override
  String get activityTaskDone => 'Aufgabe erledigt';

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
  String get backupExplain => 'Eine .zip-Datei mit Ihren Daten und Fotos.';

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
  String get importErrorNotAZip => 'Diese Datei ist keine Auxine-Sicherung.';

  @override
  String get importErrorWrongApp =>
      'Diese Sicherung stammt aus einer anderen App.';

  @override
  String get importErrorTooRecent =>
      'Diese Sicherung stammt aus einer neueren Version von Auxine.';

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
  String get onbTodayTitle => 'Die Pflege des Tages';

  @override
  String get onbTodayBody => 'Ein Tipp, um jede Pflege zu vermerken.';

  @override
  String get onbCareTitle => 'Im Winter seltener gießen';

  @override
  String get onbCareBody => 'Die Intervalle passen sich der Jahreszeit an.';

  @override
  String get onbGardenTitle => 'Räume, Fotos, Kalender';

  @override
  String get onbGardenBody =>
      'Jedes Gießen, jedes Umtopfen wird datiert und bei der Pflanze abgelegt.';

  @override
  String onbIrisTitle(String name) {
    return '$name erkennt deine Pflanzen offline';
  }

  @override
  String get onbIrisBody =>
      'Iris unbekannte Pflanze: die Suche geht online weiter.';

  @override
  String get onbPrivacyTitle => 'Alles bleibt auf deinem Handy';

  @override
  String get onbPrivacyBody => 'Kein Pflichtkonto, keine Werbung.';

  @override
  String get onbStart => 'Loslegen';

  @override
  String get replayOnboarding => 'Einführung erneut ansehen';

  @override
  String get whatsNewTitle => 'Neuerungen';

  @override
  String get whatsNewModelUpdate => 'Modell-Update';

  @override
  String get whatsNewIrisIntro =>
      'Das eingebaute Modell wurde neu trainiert: mehr Arten, weniger Fehler, weiterhin ohne Netz.';

  @override
  String whatsNewIrisSpeciesTitle(String count) {
    return '$count erkannte Arten';
  }

  @override
  String get whatsNewIrisSpeciesBody =>
      'Seltenere Zimmerpflanzen kommen in den Katalog.';

  @override
  String get whatsNewIrisOfflineTitle => 'Weiterhin auf dem Gerät';

  @override
  String get whatsNewIrisOfflineBody =>
      'Die Erkennung bleibt lokal: Ohne deine Zustimmung geht nichts raus, und der Online-Rückfall lässt sich abschalten.';

  @override
  String get whatsNewIrisDoubtTitle => 'Zweifel werden angezeigt';

  @override
  String get whatsNewIrisDoubtBody =>
      'Zwei Arten, die sich ähneln: beide werden vorgeschlagen.';

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
  String get privacyPolicy => 'Datenschutzerklärung';

  @override
  String get aboutSourceWikidata => 'Artnamen in vier Sprachen, gemeinfrei';

  @override
  String get aboutSourceGbif =>
      'Taxonomie, Familien und fotografierte Nachweise';

  @override
  String get aboutSourceOpenMeteo =>
      'Wetter und Vorhersage, ohne Konto oder Schlüssel';

  @override
  String get aboutSourceRhs => 'Winterhärte, Böden und Kulturhinweise';

  @override
  String get aboutSourceAspca => 'Pflanzengiftigkeit für Haustiere';

  @override
  String aboutSpeciesCount(String count) {
    return '$count Arten offline durchsuchbar';
  }

  @override
  String get supportTitle => 'Auxine ist kostenlos';

  @override
  String get supportBody =>
      'Alle Funktionen sind verfügbar. Kein Abo, keine Werbung, kein Pflichtkonto.';

  @override
  String get supportOffer =>
      'Wenn Sie den Entwickler dennoch unterstützen möchten, genügt ein einmaliger Kauf.';

  @override
  String get supportOnce => 'Nur einmal';

  @override
  String supportGive(String price) {
    return 'Unterstützen · $price';
  }

  @override
  String get supportRestore => 'Unterstützung wiederherstellen';

  @override
  String get supportThanksTitle => 'Danke';

  @override
  String get supportThanksBody => 'Ihre Unterstützung wurde gespeichert.';

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
  String get supportNoThanks => 'Nein danke';

  @override
  String get emptyGardenSubtitle => 'Fügen Sie Ihre erste Pflanze hinzu.';

  @override
  String get finderTitle => 'Pflanze finden';

  @override
  String get finderEntryHint => 'Hilfe bei der Auswahl';

  @override
  String get finderStepSpot => 'Standort';

  @override
  String get finderStepSpotHint => 'Licht ist das wichtigste Kriterium.';

  @override
  String get finderSpotBright => 'Heller Raum';

  @override
  String get finderSpotMedium => 'Mittleres Licht';

  @override
  String get finderSpotDark => 'Dunkle Ecke';

  @override
  String get finderSpotOutdoor => 'Draußen, Balkon oder Garten';

  @override
  String get finderStepEffort => 'Wie viel Pflege?';

  @override
  String get finderStepEffortHint => 'Wie oft Sie gießen können.';

  @override
  String get finderEffortForgiving => 'Gelegentliches Gießen';

  @override
  String get finderEffortNormal => 'Regelmäßiges Gießen';

  @override
  String get finderEffortAttentive => 'Häufige Pflege';

  @override
  String get finderStepSafety => 'Tiere oder Kinder?';

  @override
  String get finderStepSafetyHint =>
      'Viele Zimmerpflanzen sind giftig, wenn daran geknabbert wird.';

  @override
  String get finderSafetyYes => 'Ja, nur ungiftige';

  @override
  String get finderSafetyNo => 'Keine Einschränkung';

  @override
  String get finderNote => 'Details';

  @override
  String get finderNoteHint =>
      'Ein Bad ohne Fenster, eine Katze, die an allem knabbert …';

  @override
  String get finderResults => 'Vorschläge';

  @override
  String get finderEmptyTitle => 'Keine Ergebnisse';

  @override
  String get finderEmptySubtitle =>
      'Keine Art im Katalog erfüllt alle Kriterien. Ändern Sie eine Antwort oder erweitern Sie die Pflanzenarten.';

  @override
  String get finderRestart => 'Von vorne';

  @override
  String get finderAdd => 'Zum Garten hinzufügen';

  @override
  String get finderAskAi => 'Die KI fragen';

  @override
  String get finderAiSection => 'KI-Vorschläge';

  @override
  String get finderAiHint => 'Außerhalb des Katalogs, vor dem Kauf prüfen.';

  @override
  String get finderAiError => 'Kein Vorschlag von der KI.';

  @override
  String get finderReasonLight => 'Passendes Licht';

  @override
  String get finderReasonLowLight => 'Verträgt Schatten';

  @override
  String get finderReasonForgiving => 'Verträgt vergessenes Gießen';

  @override
  String get finderReasonEasy => 'Einfach';

  @override
  String get finderReasonSafe => 'Ungiftig';

  @override
  String get finderReasonOutdoor => 'Hält es draußen aus';

  @override
  String get finderAnyAnswer => 'Egal';

  @override
  String finderQuestionOf(int n, int total) {
    return 'Frage $n von $total';
  }

  @override
  String get finderSpotBrightHint => 'Nah am Fenster, viel Tageslicht';

  @override
  String get finderSpotMediumHint => 'Ein paar Schritte vom Fenster entfernt';

  @override
  String get finderSpotDarkHint => 'Weit vom Fenster, wenig Tageslicht';

  @override
  String get finderSpotOutdoorHint => 'Balkon, Terrasse oder Garten';

  @override
  String get finderEffortForgivingHint =>
      'Eine Pflanze, die vergessenes Gießen verträgt';

  @override
  String get finderEffortNormalHint => 'Etwa einmal pro Woche gießen';

  @override
  String get finderEffortAttentiveHint =>
      'Sprühen, Umtopfen, regelmäßige Kontrolle';

  @override
  String get finderSafetyYesHint => 'Nur ungiftige Arten';

  @override
  String get finderSafetyNoHint => 'Alle Arten, auch giftige';

  @override
  String get finderTopPick => 'Erste Wahl';

  @override
  String get finderAlternatives => 'Weitere Vorschläge';

  @override
  String get finderChangeAnswer => 'Diese Antwort ändern';

  @override
  String get finderChipSpotAny => 'Standort: egal';

  @override
  String get finderChipEffortAny => 'Pflege: egal';

  @override
  String get finderChipSafe => 'Ungiftig';

  @override
  String finderFactWater(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Alle $count T. gießen',
      one: 'Täglich gießen',
    );
    return '$_temp0';
  }

  @override
  String get finderAiTitle => 'Weiter suchen';

  @override
  String get finderAiBody =>
      'Suche über den Katalog hinaus, anhand Ihrer Antworten und dem, was Sie hier ergänzen.';

  @override
  String get finderPhotoSource => 'Fotos: GBIF-Beobachtungen, frei lizenziert.';

  @override
  String get onbWelcomeTitle => 'Willkommen bei Auxine';

  @override
  String get onbWelcomeBody => 'Das Pflegetagebuch Ihrer Pflanzen.';

  @override
  String get careMatchAssisted => 'Von der KI ergänzt';

  @override
  String get careAssistedNote =>
      'Art nicht im Katalog: diese Richtwerte stammen von der KI. Nur der wissenschaftliche Name wurde gesendet. Giftigkeit ist nicht enthalten.';

  @override
  String get careMatchEdited => 'Bearbeitetes Profil';

  @override
  String get careEditedNote =>
      'Von Hand korrigiertes Profil; der Rest stammt aus dem Katalog.';

  @override
  String careVerifiedFields(String source, String fields) {
    return 'Geprüft nach $source: $fields';
  }

  @override
  String get careSourceHabitat => 'Herkunftshabitat';

  @override
  String get careSourceDerived => 'Kultivierungsregel';

  @override
  String get careStudio => 'Care Studio';

  @override
  String get careStudioHint =>
      'Korrigieren Sie ein Pflegeprofil. Die Änderung gilt auf diesem Gerät.';

  @override
  String get careStudioSearch => 'Art suchen';

  @override
  String get careStudioPrompt =>
      'Suchen Sie eine Art, um ihr Profil zu korrigieren.';

  @override
  String get careStudioEmpty => 'Keine Art passt.';

  @override
  String get careStudioWateringSummer => 'Gießen, Wachstumszeit';

  @override
  String get careStudioWateringWinter => 'Gießen, Winter';

  @override
  String get careStudioDamageBelow => 'Nicht unter';

  @override
  String get careStudioSave => 'Speichern';

  @override
  String get careStudioSaved => 'Änderung gespeichert';

  @override
  String get careStudioReset => 'Zum Katalog zurück';

  @override
  String get careAssistSetting => 'Pflegeinfos mit der KI ergänzen';

  @override
  String get careAssistHint =>
      'Bei einer Art, die nicht im Katalog ist, wird der wissenschaftliche Name an die KI gesendet, um die Anleitung zu ergänzen. Sonst verlässt nichts das Gerät. Die Antwort wird gespeichert.';

  @override
  String get gardensTitle => 'Meine Gärten';

  @override
  String get gardensHint =>
      'Der geöffnete Garten ist der überall in der App angezeigte. Der Wechsel geschieht hier.';

  @override
  String get gardenMine => 'Mein Garten';

  @override
  String get gardenUnnamed => 'Geteilter Garten';

  @override
  String gardenSharedBy(String name) {
    return 'Geteilt von $name';
  }

  @override
  String gardenOpened(String name) {
    return 'Garten: $name';
  }

  @override
  String get someone => 'jemandem';

  @override
  String memberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Mitglieder',
      one: '1 Mitglied',
    );
    return '$_temp0';
  }

  @override
  String get renameGarden => 'Garten umbenennen';

  @override
  String get renameGardenHint => 'Name, den eingeladene Personen sehen.';

  @override
  String get gardenNameHint => 'Der Garten zu Hause';

  @override
  String get joinGarden => 'Einem Garten beitreten';

  @override
  String get joinGardenHint =>
      'Geben Sie den erhaltenen Code ein oder öffnen Sie den Einladungslink.';

  @override
  String get inviteCodeHint => 'Einladungscode';

  @override
  String get joinLook => 'Einladung ansehen';

  @override
  String get joinConfirm => 'Beitreten';

  @override
  String get joinInvalid =>
      'Dieser Code gilt nicht mehr. Bereits benutzt, abgelaufen oder unbekannt.';

  @override
  String get joinWrongEmail =>
      'Diese Einladung gilt für eine andere E-Mail-Adresse.';

  @override
  String get joinNeedsAccount =>
      'Für den Beitritt zu einem Garten braucht es ein Konto.';

  @override
  String get joinSignInHint => 'Anmeldung mit Ihrer Apple-ID.';

  @override
  String joinInvitedBy(String name, String garden) {
    return '$name lädt Sie in „$garden“ ein';
  }

  @override
  String joinGardenName(String garden) {
    return 'Einladung in „$garden“';
  }

  @override
  String get joinAsMember => 'Pflanzen hinzufügen, ändern und löschen.';

  @override
  String get joinAsViewer => 'Nur ansehen, keine Änderungen.';

  @override
  String get joinAlreadyMember => 'Sie gehören bereits zu diesem Garten.';

  @override
  String joined(String name) {
    return '„$name“ beigetreten';
  }

  @override
  String get leaveGarden => 'Diesen Garten verlassen';

  @override
  String leaveGardenConfirm(String name) {
    return 'Sie haben keinen Zugriff mehr auf „$name“.';
  }

  @override
  String leftGarden(String name) {
    return 'Sie haben „$name“ verlassen';
  }

  @override
  String get deleteGarden => 'Garten löschen';

  @override
  String deleteGardenConfirm(String name) {
    return '„$name“, seine Pflanzen und sein Verlauf werden gelöscht, für Sie und für die eingeladenen Personen.';
  }

  @override
  String gardenDeleted(String name) {
    return 'Garten „$name“ gelöscht';
  }

  @override
  String get deleteGardenLast => 'Ein Konto behält mindestens einen Garten.';

  @override
  String get openGardenTitle => 'Ihre Gärten';

  @override
  String get openGardenHint =>
      'Dieses Konto hat bereits Gärten. Öffnen Sie den mit Ihren Pflanzen.';

  @override
  String get collaborationNeedsAccount =>
      'Zum Teilen eines Gartens braucht es ein Konto';

  @override
  String get inviteSomeone => 'Jemanden einladen';

  @override
  String get inviteReady => 'Einladung bereit';

  @override
  String get inviteRoleHint =>
      'Mitglied: fügt Pflanzen hinzu, ändert und löscht sie. Leser: nur ansehen.';

  @override
  String get inviteEmailOptional => 'E-Mail-Adresse (optional)';

  @override
  String get inviteEmailHint =>
      'Falls angegeben, kann nur diese Adresse die Einladung annehmen.';

  @override
  String get inviteCreate => 'Einladung erstellen';

  @override
  String get inviteShareHint =>
      'Senden Sie diesen Link oder Code. Zum Empfang ist die App nicht nötig.';

  @override
  String get inviteShare => 'Link teilen';

  @override
  String inviteMessage(String link) {
    return 'Einladung in meinen Garten auf Auxine: $link';
  }

  @override
  String get inviteOnceHint => 'Eine Einladung gilt nur einmal.';

  @override
  String inviteExpires(String date) {
    return 'Läuft am $date ab';
  }

  @override
  String get inviteFailed => 'Die Einladung konnte nicht erstellt werden.';

  @override
  String get invitesTitle => 'Offene Einladungen';

  @override
  String get inviteRevoke => 'Widerrufen';

  @override
  String get inviteRevokeConfirm => 'Der Code funktioniert dann nicht mehr.';

  @override
  String get inviteRevoked => 'Einladung widerrufen';

  @override
  String get membersHint =>
      'Mitglieder sehen dieselben Pflanzen und können sie pflegen.';

  @override
  String get membersGuestHint => 'Von einem anderen Nutzer geteilter Garten.';

  @override
  String get memberRoleHint =>
      'Mitglied: fügt Pflanzen hinzu, ändert und löscht sie. Leser: nur ansehen.';

  @override
  String makeRole(String role) {
    return 'Auf „$role“ ändern';
  }

  @override
  String roleChanged(String name, String role) {
    return '$name ist jetzt „$role“';
  }

  @override
  String removeMemberConfirm(String name) {
    return '$name verliert den Zugang zu diesem Garten.';
  }

  @override
  String get photoFirstTitle => 'Erstes Foto';

  @override
  String get photoNextTitle => 'Neues Foto';

  @override
  String get photoFirstHint => 'Es wird das Hauptfoto.';

  @override
  String get photoFrameHint =>
      'Wähle jedes Mal denselben Ausschnitt, um das Wachstum zu verfolgen.';

  @override
  String get photoGhostToggle => 'Letztes Foto einblenden';

  @override
  String get photoGhostHint =>
      'Richte die Pflanze am durchscheinenden Foto aus.';

  @override
  String get photoTitleStepTitle => 'Titel';

  @override
  String get photoTitleStepSubtitle => 'Optional.';

  @override
  String get photoTagNewLeaf => 'Neues Blatt';

  @override
  String get photoTagFlowering => 'Blüte';

  @override
  String get photoTagBeforeRepotting => 'Vor dem Umtopfen';

  @override
  String get photoTagAfterRepotting => 'Nach dem Umtopfen';

  @override
  String get photoTagCutting => 'Steckling';

  @override
  String get photoTagAfterPruning => 'Nach dem Schnitt';

  @override
  String get mainPhotoHint =>
      'Auf der Pflanzenseite und in der Liste zu sehen.';

  @override
  String get retake => 'Neu aufnehmen';

  @override
  String get growthEmptySubtitle =>
      'Fügen Sie regelmäßig Fotos hinzu, um das Wachstum zu verfolgen.';

  @override
  String growthSummary(int count, String since) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Fotos · seit $since',
      one: '1 Foto · seit $since',
    );
    return '$_temp0';
  }

  @override
  String growthNudge(String date) {
    return 'Letztes Foto am $date.';
  }

  @override
  String get timelapse => 'Zeitraffer';

  @override
  String get beforeAfter => 'Vorher / Nachher';

  @override
  String photoCounter(int index, int total) {
    return '$index / $total';
  }

  @override
  String get photoTitleShort => 'Titel';

  @override
  String get mainPhotoShort => 'Hauptfoto';

  @override
  String get share => 'Teilen';

  @override
  String get addTitle => 'Titel hinzufügen';

  @override
  String get swap => 'Tauschen';

  @override
  String get pause => 'Pause';

  @override
  String get stepPhotoDoneTitle => 'Vorschau';

  @override
  String stepPhotoDoneSubtitle(String name) {
    return 'Ein Blatt aus der Nähe hilft $name, die Art zu erkennen.';
  }

  @override
  String get stepPhotoDonePlain =>
      'Weitere Fotos kannst du später auf ihrer Seite hinzufügen.';

  @override
  String get viewPlant => 'Die Pflanze';

  @override
  String get viewLeafClose => 'Ein Blatt aus der Nähe';

  @override
  String get viewAnother => 'Weitere Ansicht';

  @override
  String viewForModel(String name) {
    return 'Von $name zur Artenerkennung genutzt, nicht gespeichert.';
  }

  @override
  String get strategyWeather => 'Wetter';

  @override
  String get strategyWeatherHint =>
      'Der saisonale Abstand, verkürzt durch trockene Hitze, verlängert durch Regen und Kälte.';

  @override
  String strategyWeatherNow(String interval) {
    return 'Mit dem Wetter dieser Woche: $interval';
  }

  @override
  String get strategyWeatherNoPlace =>
      'Ohne Wetterort bleibt der Abstand der saisonale.';

  @override
  String get weatherWhenTonight => 'heute Nacht';

  @override
  String get weatherWhenToday => 'heute';

  @override
  String get weatherWhenTomorrow => 'morgen';

  @override
  String weatherWhenInDays(int count) {
    return 'in $count Tagen';
  }

  @override
  String weatherFrostTitle(String when, String temp) {
    return 'Frost $when · $temp';
  }

  @override
  String weatherHeatTitle(String when, String temp) {
    return 'Hitze $when · $temp';
  }

  @override
  String weatherFrostBody(String names) {
    return 'Hereinholen oder abdecken: $names.';
  }

  @override
  String weatherHeatBody(String names) {
    return 'In den Schatten stellen und früh gießen: $names.';
  }

  @override
  String weatherAlertMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'und $count weitere',
      one: 'und 1 weitere',
    );
    return '$_temp0';
  }

  @override
  String weatherAlertFamily(String name) {
    return 'Familie $name';
  }

  @override
  String notifFrost(String when, String names) {
    return 'Frost $when · hereinholen oder abdecken: $names.';
  }

  @override
  String notifHeat(String when, String names) {
    return 'Hitze $when · in den Schatten stellen: $names.';
  }

  @override
  String weatherRainFallenTitle(String mm) {
    return 'Regen · $mm mm';
  }

  @override
  String weatherRainWatered(String names) {
    return 'Gießen für $names eingetragen.';
  }

  @override
  String weatherRainWaterable(String names) {
    return 'Der Regen ersetzt das Gießen für $names.';
  }

  @override
  String get weatherRainMarkWatered => 'Als gegossen eintragen';

  @override
  String weatherRainWateredToast(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Mal Gießen eingetragen',
      one: '1 Mal Gießen eingetragen',
    );
    return '$_temp0';
  }

  @override
  String weatherRainNote(String mm) {
    return 'Vom Regen gegossen ($mm mm).';
  }

  @override
  String get weatherRainCounts => 'Regen zählt als Gießen';

  @override
  String get weatherRainCountsHint =>
      'Ab 5 mm in drei Tagen wird das Gießen an Standorten im Freien als erledigt eingetragen. Ausgeschaltet, bietet der Morgenbildschirm es mit einem Tippen an. Ein Topf unter Blattwerk bekommt weniger Regen ab.';

  @override
  String get weatherClimate => 'Klima';

  @override
  String get weatherClimateHint =>
      'Pflanzenvorschläge für draußen richten sich nach Wintern und Sommern des Orts.';

  @override
  String weatherClimateZone(String zone) {
    return 'Zone $zone';
  }

  @override
  String weatherClimateRange(String low, String high) {
    return 'Winter bei $low, Sommer bei $high';
  }

  @override
  String get weatherClimateNone => 'Unbekannt';

  @override
  String get finderReasonHardy => 'Überwintert hier draußen';

  @override
  String get finderReasonSheltered => 'Überwintert draußen, geschützt';

  @override
  String finderRegion(String zone, String low) {
    return 'Zone $zone · Winter bei $low';
  }

  @override
  String get encyclopediaTitle => 'Enzyklopädie';

  @override
  String get encyclopediaHint =>
      'Die Probleme der Datenbank, die Arten des Katalogs und die Begriffe der Pflegeblätter.';

  @override
  String get encyclopediaProblems => 'Probleme';

  @override
  String get encyclopediaSpecies => 'Arten';

  @override
  String get encyclopediaGlossary => 'Begriffe';

  @override
  String get encyclopediaSearchProblems => 'Name, Schädling, Krankheit…';

  @override
  String get encyclopediaSearchGlossary => 'Licht, Substrat, Steckling…';

  @override
  String encyclopediaProblemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Probleme',
      one: '1 Problem',
      zero: 'Kein Problem',
    );
    return '$_temp0';
  }

  @override
  String encyclopediaNaturalCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count normale Erscheinungen',
      one: '1 normale Erscheinung',
      zero: 'Keine normale Erscheinung',
    );
    return '$_temp0';
  }

  @override
  String encyclopediaSpeciesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Arten',
      one: '1 Art',
      zero: 'Keine Art',
    );
    return '$_temp0';
  }

  @override
  String get encyclopediaNoTerm => 'Kein Begriff gefunden';

  @override
  String problemNumber(String id) {
    return 'Eintrag $id';
  }

  @override
  String get problemScope => 'Verbreitung';

  @override
  String get problemScopeGeneral => 'Alle Pflanzen';

  @override
  String get problemScopeWide => 'Viele Wirte';

  @override
  String get problemScopeTarget => 'Bestimmte Wirte';

  @override
  String get problemScopeGeneralNote =>
      'Möglich bei Gefäßpflanzen, je nach Bedingungen und Entwicklungsstadium.';

  @override
  String get problemScopeWideNote =>
      'Viele Wirte; die genannten Taxa sind Beispiele.';

  @override
  String get problemScopeTargetNote =>
      'Hauptwirte einer Zielgruppe; die Liste ist nicht vollständig.';

  @override
  String get problemOtherNames => 'Weitere Namen';

  @override
  String get problemOtherNamesNote =>
      'Gebräuchliche und wissenschaftliche Namen für dieselbe Sache.';

  @override
  String get problemHosts => 'Wirte';

  @override
  String get problemHostsAll => 'Alle Gefäßpflanzen';

  @override
  String get problemHostsNote =>
      'Eine Gattung oder Familie macht nicht alle ihre Arten anfällig.';

  @override
  String get problemInGarden => 'Im Garten';

  @override
  String get problemKindsTitle => 'Problemfamilien';

  @override
  String get problemKindDisorderNote =>
      'Weder Schädling noch Krankheit: Wasser, Licht, Kälte, Substrat, ein Mangel.';

  @override
  String get problemKindPestNote =>
      'Ein Lebewesen, das die Pflanze befällt: Insekt, Milbe, Schnecke, Nematode.';

  @override
  String get problemKindDiseaseNote =>
      'Ein Pilz, ein Bakterium, ein Virus oder ein Phytoplasma in der Pflanze.';

  @override
  String get problemKindConditionNote =>
      'Weder noch: Rußtau wächst auf Honigtau, ohne die Pflanze zu befallen.';

  @override
  String get naturalCauses => 'Normale Erscheinungen';

  @override
  String get naturalCauseNote =>
      'Was die Pflanze normalerweise tut und für ein Problem gehalten wird: nichts zu behandeln.';

  @override
  String get careLightShadeNote =>
      'Weit vom Fenster entfernt, ohne direkten Strahl am Tag.';

  @override
  String get careLightLowNote =>
      'Ein heller Raum, aber weit vom Fenster oder nach Norden.';

  @override
  String get careLightIndirectNote =>
      'Ein paar Schritte vom Fenster entfernt oder hinter einem Vorhang.';

  @override
  String get careLightBrightNote =>
      'Nah am Fenster, außerhalb des Sonnenstrahls.';

  @override
  String get careLightSomeNote =>
      'Morgen- oder Abendsonne, nicht die Mittagssonne.';

  @override
  String get careLightFullNote =>
      'Sechs Stunden direkte Sonne oder mehr, mitten am Tag.';

  @override
  String get careHumidityLowNote => 'Die Luft einer beheizten Wohnung genügt.';

  @override
  String get careHumidityAverageNote =>
      'Etwa 50 %, im Winter fern der Heizung.';

  @override
  String get careHumidityHighNote =>
      'Über 60 %: Bad, Küche oder eine Schale mit feuchten Blähtonkugeln.';

  @override
  String get careDifficultyEasyNote =>
      'Verträgt vergessene Wassergaben und wechselndes Licht.';

  @override
  String get careDifficultyMediumNote =>
      'Braucht einen regelmäßigen Gießrhythmus und einen festen Platz.';

  @override
  String get careDifficultyDemandingNote =>
      'Licht, Luftfeuchtigkeit und Gießen müssen genau stimmen.';

  @override
  String get careToxicSafeNote =>
      'Keine bekannte Giftigkeit für Tiere oder Kinder.';

  @override
  String get careToxicMildNote => 'Der Saft reizt Haut und Mund.';

  @override
  String get careToxicToxicNote =>
      'Das Verschlucken eines Blattes oder einer Frucht macht krank.';

  @override
  String get careToxicUnknownNote =>
      'Für diese Art ist nichts hinterlegt; vorsichtshalber außer Reichweite halten.';

  @override
  String get careSoilStandardNote => 'Handelsübliche Blumenerde, ohne Zusatz.';

  @override
  String get careSoilDrainingNote =>
      'Blumenerde, mit Perlit, Sand oder Bims aufgelockert.';

  @override
  String get careSoilCactusNote =>
      'Stark mineralisch: Wasser läuft durch, ohne zu stehen.';

  @override
  String get careSoilOrchidNote =>
      'Grobe Rinde: die Wurzeln leben an der Luft.';

  @override
  String get careSoilAcidicNote =>
      'Saurer pH-Wert, für Pflanzen, die Kalk vergilben lässt.';

  @override
  String get careSoilRichNote =>
      'Mit Kompost angereicherte Erde, für zehrende Pflanzen.';

  @override
  String get careSoilNoneNote =>
      'Die Wurzeln stehen im Wasser oder auf einer erdlosen Unterlage.';

  @override
  String get carePropCuttingNote =>
      'Ein unter einem Knoten geschnittener Trieb, in feuchtes Substrat gesteckt.';

  @override
  String get carePropLeafNote =>
      'Ein ganzes Blatt oder ein Stück davon, auf das Substrat gelegt.';

  @override
  String get carePropDivisionNote =>
      'Der Horst wird beim Umtopfen samt Wurzeln geteilt.';

  @override
  String get carePropOffsetsNote =>
      'Junge Triebe am Fuß werden abgetrennt, sobald sie Wurzeln haben.';

  @override
  String get carePropLayeringNote =>
      'Ein Trieb, der bewurzelt wird, solange er noch an der Mutterpflanze hängt.';

  @override
  String get carePropSeedNote =>
      'Aussaat, langsamer als ein Steckling und oft nicht sortenecht.';

  @override
  String get carePropWaterNote =>
      'Der Steckling steht im Wasserglas, bis Wurzeln kommen.';

  @override
  String get carePropTuberNote =>
      'Die Knolle wird in Stücke geteilt, jedes mit einem Auge.';

  @override
  String get communityTipsTitle => 'Tipps aus der Gemeinschaft';

  @override
  String get communityTipsHint =>
      'Was andere beim Pflegen dieser Art beobachtet haben, außerhalb des Katalogs.';

  @override
  String get communityTipsEmpty => 'Keine Tipps zu dieser Art.';

  @override
  String get offlineCommunityTips =>
      'Tipps lesen und veröffentlichen erfordert eine Verbindung.';

  @override
  String get communityTipWrite => 'Tipp schreiben';

  @override
  String get communityTipYours => 'Dein Tipp';

  @override
  String get communityTipPlaceholder =>
      'Was bei dieser Pflanze funktioniert hat, in wenigen Sätzen.';

  @override
  String get communityTipPublicNote =>
      'Der Tipp erscheint mit deinem Namen auf der Seite dieser Art, für alle.';

  @override
  String communityTipLength(int used, int max) {
    return '$used / $max';
  }

  @override
  String get communityTipPublish => 'Veröffentlichen';

  @override
  String get communityTipPublished => 'Tipp veröffentlicht.';

  @override
  String get communityTipNeedsAccount =>
      'Einen Tipp zu veröffentlichen erfordert ein Konto.';

  @override
  String get communityTipAnonymous => 'Anonym';

  @override
  String get communityTipHelpful => 'Hilfreich';

  @override
  String get communityTipReport => 'Melden';

  @override
  String get communityTipReported => 'Tipp gemeldet.';

  @override
  String communityTipReportNote(int count) {
    return 'Ein von $count Personen gemeldeter Tipp erscheint nicht mehr.';
  }

  @override
  String get communityTipHidden => 'Gemeldet: andere sehen ihn nicht mehr.';

  @override
  String get confirmDeleteTip => 'Diesen Tipp löschen?';

  @override
  String get confirmReportTip => 'Diesen Tipp melden?';

  @override
  String get moderationTitle => 'Moderation';

  @override
  String get moderationHint => 'Gemeldete Tipps, die meistgemeldeten zuerst.';

  @override
  String get moderationEmpty => 'Keine gemeldeten Tipps.';

  @override
  String moderationReports(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Meldungen',
      one: '1 Meldung',
    );
    return '$_temp0';
  }

  @override
  String get moderationHide => 'Ausblenden';

  @override
  String get moderationRestore => 'Wiederherstellen';

  @override
  String get confirmRestoreTip =>
      'Diesen Tipp wiederherstellen? Seine Meldungen werden gelöscht.';

  @override
  String get roomScan => 'Scan der Wohnung';

  @override
  String get roomScanHint =>
      'Scanne einen Raum mit Kamera und LiDAR: Die App erkennt Wände, Fenster und Türen und berechnet, wie viel Licht jeder Platz bekommt – damit du weißt, wohin deine Pflanzen gehören. Alles bleibt auf deinem Gerät.';

  @override
  String get roomScanStart => 'Raum scannen';

  @override
  String get roomScanRooms => 'Gescannte Räume';

  @override
  String get roomScanEmptyTitle => 'Kein Raum gescannt';

  @override
  String get roomScanEmptySubtitle => 'Rechne mit 1 bis 2 Minuten pro Raum.';

  @override
  String get roomScanNoLidar =>
      'Dieses Gerät hat kein LiDAR. Zum Scannen brauchst du ein iPhone Pro oder ein iPad Pro.';

  @override
  String get roomScanBeforeTitle => 'Vor dem Scan';

  @override
  String get roomScanBeforeText =>
      'Die Kamera öffnet den Scanner von iOS. Geh langsam an den Wänden entlang, bis der Raum vollständig gezeichnet ist, und tippe dann auf Fertig.';

  @override
  String get roomScanFailed => 'Der Scan ist fehlgeschlagen.';

  @override
  String get roomScanDefaultName => 'Raum';

  @override
  String roomScanArea(String area) {
    return '$area m²';
  }

  @override
  String roomScanWindowsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Fenster',
      one: 'ein Fenster',
      zero: 'kein Fenster',
    );
    return '$_temp0';
  }

  @override
  String get roomScanName => 'Name des Raums';

  @override
  String get roomScanLinkedLocation => 'Ort';

  @override
  String get roomScanWindows => 'Fenster';

  @override
  String roomScanWindowN(int n) {
    return 'Fenster $n';
  }

  @override
  String get roomScanWindowUnknown => 'Ausrichtung unbekannt';

  @override
  String get roomScanWindowFromCompass => 'Laut Kompass';

  @override
  String get roomScanWindowConfirmed => 'Bestätigt';

  @override
  String get roomScanOrientationHelp =>
      'Der Kompass weicht um 10 bis 15° ab. Korrigiere hier die Ausrichtung jedes Fensters.';

  @override
  String get roomScanDelete => 'Scan löschen';

  @override
  String get roomScanDeleteConfirm =>
      'Der Scan und seine Markierungen werden von deinem Gerät gelöscht.';

  @override
  String roomScanCapturedOn(String date) {
    return 'Gescannt am $date';
  }

  @override
  String get roomSectionBathroom => 'Badezimmer';

  @override
  String get roomSectionBedroom => 'Schlafzimmer';

  @override
  String get roomSectionDiningRoom => 'Esszimmer';

  @override
  String get roomSectionKitchen => 'Küche';

  @override
  String get roomSectionLaundryRoom => 'Waschküche';

  @override
  String get roomSectionLivingRoom => 'Wohnzimmer';

  @override
  String get directionNorth => 'Norden';

  @override
  String get directionNorthEast => 'Nordosten';

  @override
  String get directionEast => 'Osten';

  @override
  String get directionSouthEast => 'Südosten';

  @override
  String get directionSouth => 'Süden';

  @override
  String get directionSouthWest => 'Südwesten';

  @override
  String get directionWest => 'Westen';

  @override
  String get directionNorthWest => 'Nordwesten';

  @override
  String get placementTitle => 'Wohin damit';

  @override
  String get placementHint =>
      'Die Plätze sind danach geordnet, wie gut ihr Licht zu dem passt, das die Pflegekarte verlangt.';

  @override
  String placementRoomsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gescannte Räume',
      one: 'ein gescannter Raum',
    );
    return '$_temp0';
  }

  @override
  String get placementVerdictGood => 'Geeigneter Raum.';

  @override
  String get placementVerdictAcceptable =>
      'Annehmbarer Raum, ohne idealen Platz.';

  @override
  String get placementVerdictUnsuitable => 'Ungeeigneter Raum.';

  @override
  String get placementShortfallTooDark => 'Zu dunkel für das geforderte Licht.';

  @override
  String get placementShortfallTooBright => 'Zu viel direkte Sonne.';

  @override
  String get placementShortfallDrafty =>
      'Jeder Platz liegt nahe einer Tür: Durchzug.';

  @override
  String get placementShortfallTooDry =>
      'Feuchtraum, feuchte Luft: Die Pflegekarte verlangt trockene Luft.';

  @override
  String get placementGeneric =>
      'Ohne Art ist das geforderte Licht unbekannt: Die Pflegekarte bleibt allgemein.';

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
    return '$distance vom Fenster nach $direction';
  }

  @override
  String placementNearWindowUnknown(String distance) {
    return '$distance vom Fenster';
  }

  @override
  String get placementOnTable => 'auf dem Tisch';

  @override
  String get placementOnStorage => 'auf der Kommode';

  @override
  String placementOnSill(String direction) {
    return 'auf der Fensterbank nach $direction';
  }

  @override
  String get placementOnSillUnknown => 'auf der Fensterbank';

  @override
  String get placementDeepInRoom => 'hinten im Raum, weit weg von den Fenstern';

  @override
  String get placementDraftyNote => 'Nahe einer Tür: Durchzug.';

  @override
  String get placementHumidRoomNote => 'Feuchtraum: feuchtere Luft.';

  @override
  String placementPlanSemantics(int count) {
    return 'Grundriss des Raums von oben, $count ausgewählte Plätze.';
  }

  @override
  String get roomScanHeaters => 'Heizkörper';

  @override
  String get roomScanHeatersHelp =>
      'Der Scan erkennt keine Heizkörper. Setze sie auf den Grundriss: Im Umkreis von 80 cm gilt die Luft als trocken und warm.';

  @override
  String get roomScanAddHeater => 'Heizkörper setzen';

  @override
  String get roomScanTapForHeater =>
      'Tippe auf dem Grundriss dorthin, wo der Heizkörper steht.';

  @override
  String roomScanHeatersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Heizkörper',
      one: 'ein Heizkörper',
      zero: 'kein Heizkörper',
    );
    return '$_temp0';
  }

  @override
  String get roomScanRemoveHeater => 'Diesen Heizkörper entfernen';

  @override
  String get roomScanFillLocation => 'Ort ausfüllen';

  @override
  String roomScanFillLocationDetail(String orientation, String light) {
    return 'Laut Scan: Ausrichtung $orientation, Licht $light. Schon ausgefüllte Felder bleiben unverändert.';
  }

  @override
  String get roomScanLocationFilled => 'Ort ausgefüllt';

  @override
  String get roomScanWhoFitsHere => 'Der Garten in diesem Raum';

  @override
  String get roomScanWhoFitsHint =>
      'Jede Pflanze wird bewertet, indem das Licht des Raums mit dem ihrer Pflegekarte verglichen wird.';

  @override
  String get roomScanNoPlantsToRank => 'Keine Pflanze mit bekannter Art.';

  @override
  String get placementShortfallHeater =>
      'Jeder Platz liegt nahe einem Heizkörper: Die Luft ist trocken und warm.';

  @override
  String get placementHeaterNote =>
      'Nahe einem Heizkörper: trockene, warme Luft.';

  @override
  String get placementAtHome => 'Sensor des Raums';

  @override
  String get roomScanStartStructure => 'Ganze Wohnung scannen';

  @override
  String get roomScanStructureHint =>
      'Scanne deine Räume nacheinander: nach jedem „Nächster Raum“, am Ende „Fertig“. Die App fügt sie zu einem Grundriss zusammen.';

  @override
  String get roomScanNextRoom => 'Nächster Raum';

  @override
  String roomScanRoomNumber(int n) {
    return 'Raum $n';
  }

  @override
  String get roomScanPlantsOnPlan => 'Pflanzen auf dem Grundriss';

  @override
  String get roomScanPlantsHelp =>
      'Setze deine Pflanzen auf den Grundriss: Jede bekommt eine Bewertung, und die Liste zeigt einen deutlich besseren Platz.';

  @override
  String get roomScanAddPlant => 'Pflanze setzen';

  @override
  String roomScanTapForPlant(String plant) {
    return 'Tippe auf dem Grundriss dorthin, wo $plant steht.';
  }

  @override
  String roomScanRemovePlant(String plant) {
    return '$plant vom Grundriss entfernen';
  }

  @override
  String get roomScanNoPlantToPlace => 'Keine Pflanze zu setzen.';

  @override
  String roomScanPlantWellPlaced(String light) {
    return 'Geeigneter Platz · $light';
  }

  @override
  String roomScanPlantBetterAt(String light, String place) {
    return 'Hier $light · besser $place';
  }

  @override
  String get placementAllRooms => 'Alle Räume';

  @override
  String get placementChoose => 'Hierhin setzen';

  @override
  String placementChosen(String place) {
    return 'Gesetzt $place';
  }

  @override
  String placementCurrent(String place, String light) {
    return 'Aktueller Platz: $place · $light';
  }

  @override
  String get sectionRooms => 'Raumscans';

  @override
  String get roomScanCurtain => 'Vorhang';

  @override
  String get roomScanCurtainNone => 'Kein Vorhang';

  @override
  String get roomScanCurtainSheer => 'Gardine';

  @override
  String get roomScanCurtainDrawn => 'Vorhang meist zugezogen';

  @override
  String get roomScanCurtainHelp =>
      'Der Scan erkennt keine Vorhänge. Eine Gardine halbiert das Licht und nimmt direkte Sonne; ein meist zugezogener Vorhang teilt es durch 3.';

  @override
  String get roomScanPlace => 'Setzen';

  @override
  String roomScanRoomsShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Räume',
      one: '1 Raum',
      zero: 'Keiner',
    );
    return '$_temp0';
  }

  @override
  String get roomScanThisRoom => 'Diesen Raum scannen';

  @override
  String get roomScanThisRoomHint =>
      'Der Grundriss zeigt das Licht an jedem Platz – so wählst du, wo eine Pflanze steht.';

  @override
  String get roomScanRoomPlan => 'Grundriss des Raums';

  @override
  String roomScanPlantsOnPlanCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Pflanzen auf dem Grundriss',
      one: 'eine Pflanze auf dem Grundriss',
      zero: 'keine Pflanze auf dem Grundriss',
    );
    return '$_temp0';
  }
}
