// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appName => 'Flora';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Annulla';

  @override
  String get save => 'Salva';

  @override
  String get done => 'Fine';

  @override
  String get continueLabel => 'Continua';

  @override
  String get back => 'Indietro';

  @override
  String get delete => 'Elimina';

  @override
  String get edit => 'Modifica';

  @override
  String get add => 'Aggiungi';

  @override
  String get search => 'Cerca';

  @override
  String get close => 'Chiudi';

  @override
  String get undo => 'Annulla';

  @override
  String get later => 'Più tardi';

  @override
  String get skip => 'Salta';

  @override
  String get next => 'Avanti';

  @override
  String get retry => 'Riprova';

  @override
  String get more => 'Altro';

  @override
  String get seeAll => 'Vedi tutto';

  @override
  String get optional => 'facoltativo';

  @override
  String get none => 'Nessuno';

  @override
  String get genericError => 'Qualcosa non ha funzionato. Riprova.';

  @override
  String get tabToday => 'Oggi';

  @override
  String get tabPlants => 'Piante';

  @override
  String get tabGarden => 'Giardino';

  @override
  String get tabProfile => 'Profilo';

  @override
  String greeting(String name) {
    return 'Ciao $name';
  }

  @override
  String get greetingAnonymous => 'Ciao';

  @override
  String careCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cure',
      one: '1 cura',
      zero: 'Niente da fare',
    );
    return '$_temp0';
  }

  @override
  String get sectionOverdue => 'In ritardo';

  @override
  String get sectionToday => 'Oggi';

  @override
  String get sectionUpcoming => 'In arrivo';

  @override
  String get allDoneTitle => 'Tutto in ordine';

  @override
  String get allDoneSubtitle =>
      'Le tue piante non hanno bisogno di nulla oggi.';

  @override
  String get emptyGardenTitle => 'Il tuo giardino inizia qui.';

  @override
  String get addFirstPlant => 'Aggiungi la mia prima pianta';

  @override
  String get yourGarden => 'Il tuo giardino';

  @override
  String get recentPhotos => 'Foto recenti';

  @override
  String plantCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count piante',
      one: '1 pianta',
      zero: 'Nessuna pianta',
    );
    return '$_temp0';
  }

  @override
  String get kindWatering => 'Annaffiatura';

  @override
  String get kindFertilizing => 'Concime';

  @override
  String get kindRepotting => 'Rinvaso';

  @override
  String get kindPruning => 'Potatura';

  @override
  String get kindCleaning => 'Pulizia';

  @override
  String get kindTreatment => 'Trattamento';

  @override
  String get kindMeasurement => 'Misura';

  @override
  String get kindPhoto => 'Foto';

  @override
  String get kindNote => 'Nota';

  @override
  String get verbWatering => 'Annaffia';

  @override
  String get verbFertilizing => 'Concima';

  @override
  String get verbRepotting => 'Rinvasa';

  @override
  String get verbPruning => 'Pota';

  @override
  String get verbCleaning => 'Pulisci';

  @override
  String get verbTreatment => 'Tratta';

  @override
  String get verbMeasurement => 'Misura';

  @override
  String get verbPhoto => 'Foto';

  @override
  String get verbNote => 'Nota';

  @override
  String get doneWatering => 'Annaffiata';

  @override
  String get doneFertilizing => 'Concimata';

  @override
  String get doneRepotting => 'Rinvasata';

  @override
  String get donePruning => 'Potata';

  @override
  String get doneCleaning => 'Pulita';

  @override
  String get doneTreatment => 'Trattata';

  @override
  String get doneMeasurement => 'Misurata';

  @override
  String get donePhoto => 'Foto aggiunta';

  @override
  String get doneNote => 'Nota aggiunta';

  @override
  String get doneCustom => 'Fatto';

  @override
  String actionDoneToast(String plant, String action) {
    return '$plant · $action';
  }

  @override
  String multiActionDone(int count, String action) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count piante · $action',
      one: '1 pianta · $action',
    );
    return '$_temp0';
  }

  @override
  String get dueToday => 'Oggi';

  @override
  String get dueTomorrow => 'Domani';

  @override
  String dueInDays(int count) {
    return 'Tra $count giorni';
  }

  @override
  String dueOverdue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count giorni di ritardo',
      one: '1 giorno di ritardo',
    );
    return '$_temp0';
  }

  @override
  String get dueNone => 'Nessun promemoria';

  @override
  String careDueLabel(String action, String when) {
    return '$action · $when';
  }

  @override
  String verbToday(String verb) {
    return '$verb oggi';
  }

  @override
  String get plantsTitle => 'Piante';

  @override
  String get searchPlants => 'Nome, specie, posizione…';

  @override
  String get filters => 'Filtri';

  @override
  String get sortBy => 'Ordina per';

  @override
  String get sortName => 'Nome';

  @override
  String get sortNextCare => 'Prossima cura';

  @override
  String get sortRecent => 'Aggiunte di recente';

  @override
  String get filterLocation => 'Posizione';

  @override
  String get filterNeedsAttention => 'Da curare';

  @override
  String get filterFavorites => 'Preferite';

  @override
  String get filterTag => 'Tag';

  @override
  String get clearFilters => 'Rimuovi filtri';

  @override
  String get gridView => 'Griglia';

  @override
  String get listView => 'Elenco';

  @override
  String get noResultsTitle => 'Nessun risultato';

  @override
  String get noResultsSubtitle => 'Prova con un\'altra parola.';

  @override
  String get emptyPlantsTitle => 'Nessuna pianta';

  @override
  String get emptyPlantsSubtitle => 'Il tuo giardino inizia qui.';

  @override
  String get addPlant => 'Aggiungi una pianta';

  @override
  String selectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selezionate',
      one: '1 selezionata',
    );
    return '$_temp0';
  }

  @override
  String get select => 'Seleziona';

  @override
  String get move => 'Sposta';

  @override
  String get archive => 'Archivia';

  @override
  String get addTag => 'Aggiungi tag';

  @override
  String get favorite => 'Preferita';

  @override
  String get unfavorite => 'Rimuovi dai preferiti';

  @override
  String movedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count piante spostate',
      one: '1 pianta spostata',
    );
    return '$_temp0';
  }

  @override
  String archivedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count piante archiviate',
      one: '1 pianta archiviata',
    );
    return '$_temp0';
  }

  @override
  String get newPlant => 'Nuova pianta';

  @override
  String get stepPhotoTitle => 'Una foto?';

  @override
  String get stepPhotoSubtitle => 'Diventerà il volto della tua pianta.';

  @override
  String get takePhoto => 'Scatta una foto';

  @override
  String get choosePhoto => 'Scegli una foto';

  @override
  String get withoutPhoto => 'Continua senza foto';

  @override
  String get changePhoto => 'Cambia';

  @override
  String get stepNameTitle => 'Come si chiama?';

  @override
  String get plantNameHint => 'Monstera del salotto';

  @override
  String get speciesHint => 'Specie (facoltativo)';

  @override
  String get stepLocationTitle => 'Dove si trova?';

  @override
  String get newLocationChip => 'Nuovo';

  @override
  String get noLocation => 'Senza posizione';

  @override
  String get finish => 'Fine';

  @override
  String plantAdded(String name) {
    return '$name aggiunta';
  }

  @override
  String get moreOptions => 'Altre opzioni';

  @override
  String get acquiredAt => 'Data di acquisto';

  @override
  String get source => 'Provenienza';

  @override
  String get sourceHint => 'Vivaio, talea di un amico…';

  @override
  String get price => 'Prezzo';

  @override
  String get potSize => 'Diametro del vaso';

  @override
  String get notes => 'Note';

  @override
  String get notesHint => 'Tutto ciò che può essere utile…';

  @override
  String get wateringEvery => 'Annaffiatura';

  @override
  String get fertilizingEvery => 'Concime';

  @override
  String everyDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ogni $count giorni',
      one: 'Ogni giorno',
    );
    return '$_temp0';
  }

  @override
  String sinceDate(String date) {
    return 'Dal $date';
  }

  @override
  String get nextCare => 'Prossime cure';

  @override
  String get addAction => 'Aggiungi un\'azione';

  @override
  String get history => 'Cronologia';

  @override
  String get seeFullHistory => 'Tutta la cronologia';

  @override
  String get growth => 'Crescita';

  @override
  String get photos => 'Foto';

  @override
  String get info => 'Informazioni';

  @override
  String get cuttings => 'Talee';

  @override
  String get createCutting => 'Crea una talea';

  @override
  String cuttingOf(String name) {
    return 'Talea di $name';
  }

  @override
  String get parentPlant => 'Pianta madre';

  @override
  String get schedule => 'Programma';

  @override
  String get editPlant => 'Modifica pianta';

  @override
  String get archivePlant => 'Archivia pianta';

  @override
  String get archiveReasonTitle => 'Cos\'è successo?';

  @override
  String get reasonDied => 'Morta';

  @override
  String get reasonGiven => 'Regalata';

  @override
  String get reasonSold => 'Venduta';

  @override
  String get reasonOther => 'Altro';

  @override
  String plantArchived(String name) {
    return '$name archiviata';
  }

  @override
  String get restore => 'Ripristina';

  @override
  String plantRestored(String name) {
    return '$name ripristinata';
  }

  @override
  String get deleteForever => 'Elimina definitivamente';

  @override
  String get deleteForeverConfirm =>
      'Questa pianta e tutta la sua cronologia saranno eliminate.';

  @override
  String get noHistoryTitle => 'Nessuna azione per ora';

  @override
  String get noHistorySubtitle => 'Ogni cura apparirà qui.';

  @override
  String get noPhotosTitle => 'Nessuna foto';

  @override
  String get noPhotosSubtitle => 'Aggiungi una foto per seguirne la crescita.';

  @override
  String get setAsPrimary => 'Foto principale';

  @override
  String get deletePhoto => 'Elimina foto';

  @override
  String get health => 'Salute';

  @override
  String get healthHealthy => 'In forma';

  @override
  String get healthWatch => 'Da tenere d\'occhio';

  @override
  String get healthSick => 'Malata';

  @override
  String get noSchedule => 'Nessun promemoria';

  @override
  String get addRoutine => 'Aggiungi una routine';

  @override
  String get frequency => 'Frequenza';

  @override
  String get strategyFixed => 'Fissa';

  @override
  String get strategySeasonal => 'Stagionale';

  @override
  String get strategyManual => 'Manuale';

  @override
  String get strategySeasonalHint =>
      'Meno spesso in inverno, più spesso in estate.';

  @override
  String get strategyManualHint => 'Nessun promemoria automatico.';

  @override
  String get enabled => 'Attiva';

  @override
  String get interval => 'Intervallo';

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count giorni',
      one: '1 giorno',
    );
    return '$_temp0';
  }

  @override
  String lastDone(String date) {
    return 'Ultima: $date';
  }

  @override
  String nextDue(String date) {
    return 'Prossima: $date';
  }

  @override
  String get deleteRoutine => 'Elimina routine';

  @override
  String get snooze => 'Più tardi';

  @override
  String snoozed(String name) {
    return '$name · rimandata a domani';
  }

  @override
  String get measurements => 'Misure';

  @override
  String measurementDelta(String delta, String date) {
    return '$delta da $date';
  }

  @override
  String get whatDidYouDo => 'Cosa hai fatto?';

  @override
  String get when => 'Quando';

  @override
  String get noteHint => 'Aggiungi una nota…';

  @override
  String get quantity => 'Quantità';

  @override
  String get value => 'Valore';

  @override
  String get measureHeight => 'Altezza';

  @override
  String get measureWidth => 'Larghezza';

  @override
  String get measureLeaves => 'Foglie';

  @override
  String get measurePot => 'Vaso';

  @override
  String get record => 'Salva';

  @override
  String get addNote => 'Aggiungi una nota';

  @override
  String get addPhoto => 'Aggiungi una foto';

  @override
  String get camera => 'Fotocamera';

  @override
  String get gallery => 'Libreria foto';

  @override
  String get photoError => 'Impossibile aggiungere la foto. Riprova.';

  @override
  String get newActionType => 'Nuovo tipo di azione';

  @override
  String get actionTypeLabel => 'Nome';

  @override
  String get actionTypeLabelHint => 'Nebulizzazione';

  @override
  String get actionTypeEmoji => 'Emoji';

  @override
  String get actionTypes => 'Tipi di azione';

  @override
  String get actionTypesHint => 'Crea le tue azioni, oltre a quelle integrate.';

  @override
  String get deleteActionType => 'Elimina questo tipo';

  @override
  String get builtin => 'Integrato';

  @override
  String get gardenTitle => 'Giardino';

  @override
  String get locations => 'Posizioni';

  @override
  String get newLocationTitle => 'Nuova posizione';

  @override
  String get locationName => 'Nome';

  @override
  String get locationNameHint => 'Salotto';

  @override
  String get locationIcon => 'Icona';

  @override
  String get parentLocation => 'In';

  @override
  String get noParent => 'Nessuna';

  @override
  String get light => 'Luce';

  @override
  String get lightLow => 'Bassa';

  @override
  String get lightMedium => 'Media';

  @override
  String get lightHigh => 'Alta';

  @override
  String get orientation => 'Esposizione';

  @override
  String get orientationHint => 'Sud-ovest';

  @override
  String get deleteLocation => 'Elimina posizione';

  @override
  String get deleteLocationHint => 'Le piante non saranno eliminate.';

  @override
  String get noLocationsTitle => 'Nessuna posizione';

  @override
  String get noLocationsSubtitle => 'Crea un salotto, un balcone, una serra…';

  @override
  String get editLocation => 'Modifica posizione';

  @override
  String get noPlantsHereTitle => 'Nessuna pianta qui';

  @override
  String get noPlantsHereSubtitle =>
      'Sposta qui delle piante o aggiungine una.';

  @override
  String get chooseLocation => 'Scegli una posizione';

  @override
  String get defaultLivingRoom => 'Salotto';

  @override
  String get defaultKitchen => 'Cucina';

  @override
  String get defaultBedroom => 'Camera';

  @override
  String get defaultBalcony => 'Balcone';

  @override
  String get defaultOffice => 'Ufficio';

  @override
  String get defaultBathroom => 'Bagno';

  @override
  String get defaultGarden => 'Giardino';

  @override
  String get defaultGreenhouse => 'Serra';

  @override
  String get profileTitle => 'Profilo';

  @override
  String get yourName => 'Il tuo nome';

  @override
  String get yourNameHint => 'Nome';

  @override
  String get appearance => 'Aspetto';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Chiaro';

  @override
  String get themeDark => 'Scuro';

  @override
  String get reduceMotion => 'Riduci animazioni';

  @override
  String get reduceMotionHint =>
      'Per impostazione predefinita, Flora segue il sistema.';

  @override
  String get notifications => 'Notifiche';

  @override
  String get enableNotifications => 'Promemoria giornaliero';

  @override
  String get notificationTime => 'Ora';

  @override
  String get quietDays => 'Giorni silenziosi';

  @override
  String get notificationPreview => 'Anteprima';

  @override
  String get notificationHint =>
      'Una sola notifica al giorno, solo quando una pianta ha bisogno di te.';

  @override
  String get notificationPermissionDenied =>
      'Consenti le notifiche nelle Impostazioni del telefono.';

  @override
  String get archives => 'Piante passate';

  @override
  String get noArchivesTitle => 'Nessuna pianta passata';

  @override
  String get noArchivesSubtitle => 'Le piante archiviate appariranno qui.';

  @override
  String archivedOn(String date) {
    return 'Archiviata il $date';
  }

  @override
  String get units => 'Unità';

  @override
  String get metric => 'Metrico';

  @override
  String get imperial => 'Imperiale';

  @override
  String get language => 'Lingua';

  @override
  String get languageSystem => 'Sistema';

  @override
  String get account => 'Account';

  @override
  String get localAccount => 'Dati su questo dispositivo';

  @override
  String get localAccountHint =>
      'Le tue piante e foto restano private, su questo telefono. Account e sincronizzazione arriveranno in una versione futura.';

  @override
  String get about => 'Informazioni';

  @override
  String version(String version) {
    return 'Versione $version';
  }

  @override
  String get tags => 'Tag';

  @override
  String get newTag => 'Nuovo tag';

  @override
  String get tagNameHint => 'Tropicale, Rara, Da osservare…';

  @override
  String get noTags => 'Nessun tag';

  @override
  String get manageTags => 'Gestisci tag';

  @override
  String get onboardingTitle => 'Tutte le tue piante, qui';

  @override
  String get onboardingSubtitle =>
      'Aggiungile una alla volta, con una foto se vuoi.';

  @override
  String get askNameTitle => 'Come ti chiami?';

  @override
  String get askNameSubtitle =>
      'Per salutarti ogni mattina. Potrai cambiarlo più tardi.';

  @override
  String get notificationAskTitle => 'Un promemoria utile, ogni giorno';

  @override
  String get notificationAskBody =>
      'Una sola notifica al giorno, all\'ora che scegli, solo quando una pianta ne ha bisogno.';

  @override
  String get enable => 'Attiva';

  @override
  String get notNow => 'Non ora';

  @override
  String get notificationTitle => 'Le tue piante';

  @override
  String get notificationChannel => 'Promemoria di cura';

  @override
  String notifWaterOne(String name) {
    return '$name ha probabilmente bisogno d\'acqua oggi.';
  }

  @override
  String notifWaterMany(String names) {
    return '$names hanno probabilmente bisogno d\'acqua oggi.';
  }

  @override
  String notifOther(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count altre cure ti aspettano.',
      one: '1 altra cura ti aspetta.',
    );
    return '$_temp0';
  }

  @override
  String notifOnlyOther(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cure ti aspettano oggi.',
      one: '1 cura ti aspetta oggi.',
    );
    return '$_temp0';
  }

  @override
  String andJoin(String a, String b) {
    return '$a e $b';
  }

  @override
  String get listSeparator => ', ';

  @override
  String get timelineToday => 'Oggi';

  @override
  String get timelineYesterday => 'Ieri';

  @override
  String get photoAddedToast => 'Foto aggiunta';

  @override
  String get noteAddedToast => 'Nota aggiunta';

  @override
  String get actionAddedToast => 'Azione salvata';

  @override
  String locationCreated(String name) {
    return '$name creato';
  }

  @override
  String get saved => 'Salvato';

  @override
  String get gardenLocations => 'Luoghi';

  @override
  String get gardenInventory => 'Inventario';

  @override
  String get gardenCalendar => 'Calendario';

  @override
  String get inventoryTitle => 'Inventario';

  @override
  String get newItem => 'Nuovo articolo';

  @override
  String get editItem => 'Modifica articolo';

  @override
  String get itemName => 'Nome';

  @override
  String get itemNameHint => 'Concime piante verdi';

  @override
  String get category => 'Categoria';

  @override
  String get catFertilizer => 'Concimi';

  @override
  String get catSoil => 'Terricci';

  @override
  String get catSubstrate => 'Substrati';

  @override
  String get catPot => 'Vasi';

  @override
  String get catTool => 'Attrezzi';

  @override
  String get catTreatment => 'Trattamenti';

  @override
  String get catSeed => 'Semi';

  @override
  String get catAccessory => 'Accessori';

  @override
  String get unit => 'Unità';

  @override
  String get unitPieces => 'pezzi';

  @override
  String get lowThreshold => 'Soglia di scorta bassa';

  @override
  String get lowStock => 'Scorta bassa';

  @override
  String remaining(String amount) {
    return '$amount rimasti';
  }

  @override
  String get noInventoryTitle => 'Inventario vuoto';

  @override
  String get noInventorySubtitle =>
      'Concimi, terricci, vasi, attrezzi: tieni d\'occhio le scorte.';

  @override
  String get deleteItem => 'Elimina articolo';

  @override
  String lowStockItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count articoli in esaurimento',
      one: '1 articolo in esaurimento',
    );
    return '$_temp0';
  }

  @override
  String get calendarTitle => 'Calendario';

  @override
  String get agenda => 'Agenda';

  @override
  String get month => 'Mese';

  @override
  String get noEventsTitle => 'Niente in programma';

  @override
  String get noEventsSubtitle => 'Le cure in arrivo appariranno qui.';

  @override
  String get projected => 'previsto';

  @override
  String get today => 'Oggi';

  @override
  String get measurementsTitle => 'Misure';

  @override
  String get addMeasurement => 'Aggiungi una misura';

  @override
  String sinceFirst(String delta, String date) {
    return '$delta dal $date';
  }

  @override
  String get qrCode => 'Codice QR';

  @override
  String get qrHint =>
      'Attaccalo al vaso: la scansione apre direttamente la pianta.';

  @override
  String get scan => 'Scansiona';

  @override
  String get scanHint => 'Inquadra il codice QR di una pianta.';

  @override
  String get unknownQr => 'Questo codice QR non appartiene al tuo giardino.';

  @override
  String get shareQr => 'Condividi';

  @override
  String get printLabels => 'Etichette PDF';

  @override
  String get labels => 'Etichette';

  @override
  String get cameraPermission =>
      'Consenti l\'accesso alla fotocamera nelle Impostazioni.';

  @override
  String get identify => 'Identifica';

  @override
  String get identifying => 'Analisi in corso…';

  @override
  String get identifyTitle => 'È forse…';

  @override
  String get identifyHint => 'Suggerimenti da confermare, mai certezze.';

  @override
  String get identifyNone => 'Nessuna corrispondenza affidabile.';

  @override
  String get identifyError =>
      'Identificazione impossibile. Controlla la connessione e riprova.';

  @override
  String get useThis => 'Usa';

  @override
  String get identificationSettings => 'Identificazione';

  @override
  String get identificationHint =>
      'Riconoscimento della specie da una foto, tramite Pl@ntNet. Crea una chiave gratuita su my.plantnet.org e incollala qui.';

  @override
  String get apiKey => 'Chiave API';

  @override
  String get apiKeyHint => 'Incolla la chiave';

  @override
  String get identificationEnabled => 'Identificazione attiva';

  @override
  String get identificationDisabled => 'Non configurata';

  @override
  String get identificationFallback => 'Fallback online';

  @override
  String get identificationFallbackHint =>
      'Quando il modello integrato è incerto, la foto viene inviata a Pl@ntNet. Disattivato, tutto resta sul dispositivo.';

  @override
  String identificationStats(int local, int remote, int saved) {
    return '$local identificazioni locali, $remote online, $saved chiamate risparmiate';
  }

  @override
  String confidence(int percent) {
    return '$percent%';
  }

  @override
  String get speciesSet => 'Specie aggiornata';

  @override
  String get compare => 'Confronta';

  @override
  String get compareHint => 'Trascina per confrontare.';

  @override
  String get before => 'Prima';

  @override
  String get after => 'Dopo';

  @override
  String get comparePickFirst => 'Scegli due foto.';

  @override
  String get outdoor => 'Esterno';

  @override
  String get outdoorHint => 'Balcone, giardino, serra: il meteo conta.';

  @override
  String get weather => 'Meteo';

  @override
  String get weatherHint =>
      'Per le piante all\'aperto, Flora controlla la pioggia del giorno e ti evita un\'annaffiatura inutile. Dati Open-Meteo, senza account né chiave.';

  @override
  String get weatherPlace => 'Luogo';

  @override
  String get weatherSearchHint => 'Città…';

  @override
  String get weatherNone => 'Nessun luogo';

  @override
  String get weatherRemove => 'Rimuovi luogo';

  @override
  String get weatherNoResults => 'Nessun luogo trovato.';

  @override
  String weatherRainSkip(String names) {
    return 'Pioggia prevista: oggi non serve annaffiare $names.';
  }

  @override
  String get postpone => 'Rimanda';

  @override
  String postponedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count annaffiature rimandate a domani',
      one: '1 annaffiatura rimandata a domani',
    );
    return '$_temp0';
  }

  @override
  String get condClear => 'Sereno';

  @override
  String get condPartlyCloudy => 'Parzialmente nuvoloso';

  @override
  String get condCloudy => 'Nuvoloso';

  @override
  String get condFog => 'Nebbia';

  @override
  String get condDrizzle => 'Pioviggine';

  @override
  String get condRain => 'Pioggia';

  @override
  String get condSnow => 'Neve';

  @override
  String get condThunderstorm => 'Temporale';

  @override
  String rainChance(int percent) {
    return '$percent% di pioggia';
  }

  @override
  String get dataSection => 'Dati';

  @override
  String get exportData => 'Esporta i miei dati';

  @override
  String get exportHint =>
      'Un file ZIP con piante, cronologia, inventario, impostazioni e foto. I tuoi dati sono tuoi.';

  @override
  String get exporting => 'Preparazione dell\'esportazione…';

  @override
  String get exportError => 'Esportazione non riuscita. Riprova.';

  @override
  String get play => 'Riproduci';

  @override
  String get timelapseHint => 'Tocca per mettere in pausa.';

  @override
  String notifLowStockOne(String name) {
    return '$name è quasi finito.';
  }

  @override
  String notifLowStockMany(int count) {
    return '$count articoli sono quasi finiti.';
  }

  @override
  String get accountTitle => 'Account';

  @override
  String get signIn => 'Accedi';

  @override
  String get signInHint =>
      'Un account salva le tue piante, le sincronizza tra i dispositivi e permette di condividere un giardino. Senza account, tutto resta su questo telefono.';

  @override
  String get continueWithApple => 'Continua con Apple';

  @override
  String get continueWithGoogle => 'Continua con Google';

  @override
  String get continueWithEmail => 'Continua con e-mail';

  @override
  String get emailHint => 'tu@esempio.ch';

  @override
  String get sendCode => 'Ricevi un codice';

  @override
  String codeSent(String email) {
    return 'Codice inviato a $email.';
  }

  @override
  String get codeHint => 'Codice a 6 cifre';

  @override
  String get verifyCode => 'Conferma';

  @override
  String get signOut => 'Esci';

  @override
  String get signOutConfirm => 'I tuoi dati restano su questo telefono.';

  @override
  String get signedInAs => 'Connesso';

  @override
  String get syncNow => 'Sincronizza ora';

  @override
  String syncIdle(String time) {
    return 'Aggiornato · $time';
  }

  @override
  String get syncNever => 'Non ancora sincronizzato';

  @override
  String syncPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count modifiche in attesa',
      one: '1 modifica in attesa',
    );
    return '$_temp0';
  }

  @override
  String get syncOffline => 'Offline · riprenderà automaticamente';

  @override
  String get syncError => 'Errore di sincronizzazione';

  @override
  String get syncSyncing => 'Sincronizzazione…';

  @override
  String get authError =>
      'Accesso non riuscito. Controlla l\'indirizzo e riprova.';

  @override
  String get appleUnavailable =>
      'L\'accesso con Apple è disponibile su iPhone e iPad.';

  @override
  String get synchronization => 'Sincronizzazione';

  @override
  String get membersTitle => 'Membri';

  @override
  String get shareGarden => 'Condividi il giardino';

  @override
  String get inviteMember => 'Invita';

  @override
  String get inviteHint =>
      'La persona deve già avere un account Flora con questo indirizzo.';

  @override
  String get roleOwner => 'Proprietario';

  @override
  String get roleMember => 'Membro';

  @override
  String get roleViewer => 'Sola lettura';

  @override
  String get invited => 'Invito inviato';

  @override
  String get inviteError =>
      'Impossibile invitare: questo indirizzo non ha ancora un account.';

  @override
  String get removeMember => 'Rimuovi dal giardino';

  @override
  String get readOnlyHint =>
      'Stai consultando questo giardino in sola lettura.';

  @override
  String byUser(String name) {
    return 'di $name';
  }

  @override
  String get you => 'tu';

  @override
  String get diagnosisTitle => 'La mia pianta ha un problema';

  @override
  String get diagnosisHint =>
      'Fotografa foglie, fusto o terra da più angolazioni. I risultati sono piste, mai certezze.';

  @override
  String get diagnosisSymptomsHint => 'Cosa hai notato (facoltativo)…';

  @override
  String get analyze => 'Analizza';

  @override
  String get analyzing => 'Analisi in corso…';

  @override
  String get diagnosisError =>
      'Analisi impossibile. Controlla la connessione e riprova.';

  @override
  String get diagnosisRefused => 'Questa foto non ha potuto essere analizzata.';

  @override
  String get diagnosisUnauthorized =>
      'Chiave API rifiutata. Controllala in Profilo › Diagnosi.';

  @override
  String get possibleCauses => 'Cause possibili';

  @override
  String get urgentHint => 'Da trattare rapidamente';

  @override
  String get saveToJournal => 'Salva nel diario';

  @override
  String get markWatch => 'Segna “da tenere d\'occhio”';

  @override
  String get diagnosisSettings => 'Diagnosi';

  @override
  String get diagnosisSettingsHint =>
      'Analisi delle foto tramite l\'API Claude di Anthropic, con la tua chiave (console.anthropic.com). Le foto vengono inviate solo quando avvii un\'analisi.';

  @override
  String get diagnosisEnabled => 'Diagnosi attiva';

  @override
  String get addPhotos => 'Aggiungi foto';

  @override
  String photosCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count foto',
      one: '1 foto',
    );
    return '$_temp0';
  }

  @override
  String get diagnosisSaved => 'Diagnosi aggiunta al diario';

  @override
  String get speciesInfo => 'Specie';

  @override
  String get speciesSource =>
      'Fonte: GBIF — Global Biodiversity Information Facility';

  @override
  String get speciesCommonNames => 'Nomi comuni';

  @override
  String get speciesFamily => 'Famiglia';

  @override
  String get speciesOrder => 'Ordine';

  @override
  String get speciesGenus => 'Genere';

  @override
  String get speciesStatus => 'Stato';

  @override
  String get speciesOpenGbif => 'Vedi su GBIF';

  @override
  String get speciesNotFound => 'Specie non trovata in GBIF.';

  @override
  String get speciesLoading => 'Ricerca in GBIF…';

  @override
  String get speciesPhotos => 'Osservazioni';

  @override
  String speciesPhotoCredit(String author, String license) {
    return '$author · $license';
  }

  @override
  String get speciesSuggestions => 'Suggerimenti';

  @override
  String get speciesUseName => 'Usa questo nome';

  @override
  String get speciesStatusAccepted => 'Nome accettato';

  @override
  String get speciesStatusSynonym => 'Sinonimo';

  @override
  String get speciesPickerTitle => 'Scegli una specie';

  @override
  String get speciesSearchHint => 'Nome comune, latino, famiglia…';

  @override
  String get speciesInGarden => 'Nel tuo giardino';

  @override
  String get speciesCommonList => 'Specie comuni';

  @override
  String get speciesGbifResults => 'Tutte le specie (GBIF)';

  @override
  String speciesGbifCount(int count) {
    return '$count specie corrispondenti';
  }

  @override
  String speciesUseText(String name) {
    return 'Usa “$name”';
  }

  @override
  String get speciesNoResults => 'Nessuna specie trovata';

  @override
  String get speciesOffline =>
      'L\'elenco completo richiede una connessione. Le specie comuni restano disponibili.';

  @override
  String get speciesBrowse => 'Elenco completo';

  @override
  String get speciesCatAll => 'Tutte';

  @override
  String get speciesCatIndoor => 'Da interno';

  @override
  String get speciesCatSucculent => 'Succulente';

  @override
  String get speciesCatHerb => 'Aromatiche';

  @override
  String get speciesCatVegetable => 'Orto';

  @override
  String get speciesCatFruit => 'Da frutto';

  @override
  String get speciesCatFlower => 'Fiori';

  @override
  String get speciesCatTree => 'Alberi e arbusti';

  @override
  String get gardenTasks => 'Attività';

  @override
  String get tasks => 'Attività';

  @override
  String get newTask => 'Nuova attività';

  @override
  String get editTask => 'Modifica attività';

  @override
  String get taskTitleHint => 'Cosa c\'è da fare?';

  @override
  String get taskDescriptionHint => 'Dettagli (facoltativo)';

  @override
  String get taskPlant => 'Pianta';

  @override
  String get taskNoPlant => 'Senza pianta';

  @override
  String get taskDue => 'Scadenza';

  @override
  String get taskNoDue => 'Senza data';

  @override
  String get taskTime => 'Ora';

  @override
  String get taskAllDay => 'Tutto il giorno';

  @override
  String get taskRecurrence => 'Ripetizione';

  @override
  String get taskRecurrenceNone => 'Nessuna';

  @override
  String get taskEvery => 'Ogni';

  @override
  String recurrenceLabel(String unit, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ogni $count ore',
      one: 'Ogni ora',
    );
    String _temp1 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ogni $count giorni',
      one: 'Ogni giorno',
    );
    String _temp2 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ogni $count settimane',
      one: 'Ogni settimana',
    );
    String _temp3 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ogni $count mesi',
      one: 'Ogni mese',
    );
    String _temp4 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ogni $count anni',
      one: 'Ogni anno',
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
  String get unitHours => 'ore';

  @override
  String get unitDays => 'giorni';

  @override
  String get unitWeeks => 'settimane';

  @override
  String get unitMonths => 'mesi';

  @override
  String get unitYears => 'anni';

  @override
  String get taskFilterOpen => 'Aperte';

  @override
  String get taskFilterOverdue => 'In ritardo';

  @override
  String get taskFilterDone => 'Completate';

  @override
  String get taskSectionOverdue => 'In ritardo';

  @override
  String get taskSectionToday => 'Oggi';

  @override
  String get taskSectionUpcoming => 'In arrivo';

  @override
  String get taskSectionNoDate => 'Senza data';

  @override
  String get noTasksTitle => 'Nessuna attività';

  @override
  String get noTasksSubtitle =>
      'Semine, pulizia della serra, ordine di terriccio: annota tutto qui.';

  @override
  String get noDoneTasks => 'Niente di completato per ora';

  @override
  String taskDoneToast(String title) {
    return '$title · Completata';
  }

  @override
  String taskNextToast(String title, String date) {
    return '$title · Prossima volta $date';
  }

  @override
  String get taskDeleted => 'Attività eliminata';

  @override
  String get deleteTask => 'Elimina attività';

  @override
  String get reopenTask => 'Riapri';

  @override
  String taskDoneOn(String date) {
    return 'Completata $date';
  }

  @override
  String taskOverdueSince(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'In ritardo di $count giorni',
      one: 'In ritardo di un giorno',
    );
    return '$_temp0';
  }

  @override
  String taskDueIn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tra $count giorni',
      one: 'Domani',
    );
    return '$_temp0';
  }

  @override
  String get tasksTodayTitle => 'Attività';

  @override
  String get choosePlant => 'Scegli una pianta';

  @override
  String notifTasksOne(String title) {
    return 'Attività: $title.';
  }

  @override
  String notifTasksMany(int count, String titles) {
    return '$count attività da fare: $titles.';
  }

  @override
  String notifTaskDue(String title) {
    return 'È il momento: $title';
  }

  @override
  String get careGuide => 'Scheda di cura';

  @override
  String get careGuideSubtitle =>
      'Quando annaffiare, quanta luce, cosa controllare.';

  @override
  String get careHowTo => 'Come prendersene cura';

  @override
  String get careWatering => 'Irrigazione';

  @override
  String get careLight => 'Luce';

  @override
  String get careHumidity => 'Umidità';

  @override
  String get careTemperature => 'Temperatura';

  @override
  String get careSoil => 'Substrato';

  @override
  String get careFertilizing => 'Concime';

  @override
  String get careRepotting => 'Rinvaso';

  @override
  String get careToxicity => 'Tossicità';

  @override
  String get careDifficulty => 'Difficoltà';

  @override
  String get carePropagation => 'Propagazione';

  @override
  String get careIssues => 'Da tenere d\'occhio';

  @override
  String get careTips => 'Buone abitudini';

  @override
  String careEveryDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ogni $count giorni',
      one: 'Ogni giorno',
    );
    return '$_temp0';
  }

  @override
  String careWateringNow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ogni $count giorni in questo periodo',
      one: 'Ogni giorno in questo periodo',
    );
    return '$_temp0';
  }

  @override
  String careWateringSeasons(int summer, int winter) {
    return '$summer g in stagione · $winter g in inverno';
  }

  @override
  String careFertilizeSeason(String from, String to) {
    return 'da $from a $to';
  }

  @override
  String get careNoFertilizer => 'Nessun concime necessario';

  @override
  String careRepotMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ogni $count mesi',
      one: 'Ogni mese',
    );
    return '$_temp0';
  }

  @override
  String careRepotYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ogni $count anni',
      one: 'Ogni anno',
    );
    return '$_temp0';
  }

  @override
  String get careRepotNone => 'Nessun rinvaso: coltura annuale';

  @override
  String careTempIdeal(int min, int max) {
    return 'Da $min a $max °C';
  }

  @override
  String careTempMin(int min) {
    return 'Resiste fino a $min °C';
  }

  @override
  String get careLightShade => 'Ombra';

  @override
  String get careLightLow => 'Poca luce';

  @override
  String get careLightIndirect => 'Luce indiretta';

  @override
  String get careLightBright => 'Luce viva indiretta';

  @override
  String get careLightSome => 'Qualche ora di sole';

  @override
  String get careLightFull => 'Pieno sole';

  @override
  String get careHumidityLow => 'Aria secca va bene';

  @override
  String get careHumidityAverage => 'Umidità normale';

  @override
  String get careHumidityHigh => 'Ama l\'aria umida';

  @override
  String get careDifficultyEasy => 'Facile';

  @override
  String get careDifficultyMedium => 'Media';

  @override
  String get careDifficultyDemanding => 'Esigente';

  @override
  String get careToxicSafe => 'Nessun pericolo noto';

  @override
  String get careToxicMild => 'Leggermente irritante';

  @override
  String get careToxicToxic => 'Tossica se ingerita';

  @override
  String get careToxicUnknown => 'Tossicità non nota';

  @override
  String get careToxicPets => 'Tenere lontano da animali e bambini.';

  @override
  String get careSoilStandard => 'Terriccio universale';

  @override
  String get careSoilDraining => 'Terriccio ben drenante';

  @override
  String get careSoilCactus => 'Terriccio per cactus';

  @override
  String get careSoilOrchid => 'Bark per orchidee';

  @override
  String get careSoilAcidic => 'Terra acida';

  @override
  String get careSoilRich => 'Terriccio ricco di compost';

  @override
  String get careSoilAquatic => 'Senza substrato';

  @override
  String get carePropCutting => 'Talea di fusto';

  @override
  String get carePropLeaf => 'Talea di foglia';

  @override
  String get carePropDivision => 'Divisione';

  @override
  String get carePropOffsets => 'Polloni';

  @override
  String get carePropLayering => 'Margotta';

  @override
  String get carePropSeed => 'Semina';

  @override
  String get carePropWater => 'Radicazione in acqua';

  @override
  String get carePropTuber => 'Divisione dei tuberi';

  @override
  String get careMatchSpecies => 'Scheda della specie';

  @override
  String careMatchGenus(String name) {
    return 'Scheda del genere $name';
  }

  @override
  String careMatchFamily(String name) {
    return 'Scheda della famiglia $name';
  }

  @override
  String get careMatchGeneric => 'Indicazioni generali';

  @override
  String get careMatchNote =>
      'Questi valori vengono dal gruppo botanico, non dalla specie esatta. Indica la specie per affinarli.';

  @override
  String get careDisclaimer =>
      'Indicazioni, non regole: la tua luce, il tuo vaso e la tua aria contano altrettanto.';

  @override
  String get careApplyToSchedule => 'Applica al planning';

  @override
  String get careScheduleApplied => 'Planning aggiornato';

  @override
  String careSuggestedIntervals(int water, int fertilize) {
    return 'Acqua ogni $water giorni, concime ogni $fertilize giorni';
  }

  @override
  String get careBadgeMist => 'Nebulizza';

  @override
  String get careBadgeDormant => 'Riposo invernale';

  @override
  String get careBadgeOutdoor => 'Sta bene all\'aperto';

  @override
  String get careIssueOverwatering => 'Troppa acqua: foglie molli e gialle';

  @override
  String get careIssueUnderwatering => 'Poca acqua: foglie cadenti';

  @override
  String get careIssueRootRot => 'Marciume radicale';

  @override
  String get careIssueSpiderMites => 'Ragnetto rosso (ragnatele sottili)';

  @override
  String get careIssueMealybugs => 'Cocciniglia farinosa';

  @override
  String get careIssueScale => 'Cocciniglia a scudetto';

  @override
  String get careIssueAphids => 'Afidi';

  @override
  String get careIssueFungusGnats => 'Moscerini del terriccio';

  @override
  String get careIssueWhitefly => 'Mosca bianca';

  @override
  String get careIssueSlugs => 'Lumache';

  @override
  String get careIssuePowderyMildew => 'Oidio';

  @override
  String get careIssueLeafSpot => 'Macchie fogliari';

  @override
  String get careIssueBlight => 'Peronospora';

  @override
  String get careIssueSunburn => 'Scottature solari';

  @override
  String get careIssueDryTips => 'Punte secche e brune';

  @override
  String get careIssueLeafDrop => 'Caduta delle foglie';

  @override
  String get careIssueEtiolation => 'Filatura per poca luce';

  @override
  String get careIssueChlorosis => 'Clorosi: foglie pallide, nervature verdi';

  @override
  String get careIssueBlossomEndRot => 'Marciume apicale';

  @override
  String get careTipFingerTest =>
      'Infila un dito: annaffia quando i primi 2 cm sono asciutti.';

  @override
  String get careTipDrySoilFirst =>
      'Lascia asciugare completamente il terriccio tra un\'annaffiatura e l\'altra.';

  @override
  String get careTipNeverDryOut =>
      'Non lasciare mai asciugare del tutto il terriccio.';

  @override
  String get careTipEvenWatering =>
      'Annaffia con regolarità: gli sbalzi spaccano i frutti.';

  @override
  String get careTipWaterAtBase =>
      'Annaffia alla base, senza bagnare le foglie.';

  @override
  String get careTipNoWaterOnLeaves =>
      'Non bagnare le foglie: l\'acqua ferma le macchia.';

  @override
  String get careTipBottomWatering =>
      'Annaffia dal basso: metti il vaso in acqua per 20 minuti.';

  @override
  String get careTipFilteredWater =>
      'Usa acqua piovana o filtrata: il calcare brunisce le punte.';

  @override
  String get careTipRainwaterOnly =>
      'Annaffia con acqua piovana: questa pianta odia il calcare.';

  @override
  String get careTipThirstyPlant =>
      'Beve molto: in estate controlla ogni giorno.';

  @override
  String get careTipDroopSignal =>
      'Si affloscia quando ha sete: è il tuo segnale.';

  @override
  String get careTipWinterDry => 'In inverno tienila quasi all\'asciutto.';

  @override
  String get careTipWinterRest => 'In inverno riduci molto l\'acqua: riposa.';

  @override
  String get careTipSummerDormant =>
      'Riposa in estate: annaffia pochissimo in quel periodo.';

  @override
  String get careTipNoWaterWhileSplitting =>
      'Non annaffiare mentre cambia le foglie.';

  @override
  String get careTipOrchidSoak =>
      'Immergi il vaso 10 minuti, poi fai sgocciolare bene.';

  @override
  String get careTipSoakMount =>
      'Immergi tutta la pianta, poi falla asciugare all\'aria.';

  @override
  String get careTipDryUpsideDown =>
      'Dopo il bagno asciugala capovolta: l\'acqua nel cuore la fa marcire.';

  @override
  String get careTipWaterInTheCup =>
      'Riempi la rosetta centrale e cambia l\'acqua ogni settimana.';

  @override
  String get careTipNoSoil => 'Vive senza terra: appoggiala su un supporto.';

  @override
  String get careTipGreenRoots =>
      'Radici verdi: idratata. Argentate: è ora di annaffiare.';

  @override
  String get careTipHumidityTray => 'Metti il vaso su argilla espansa umida.';

  @override
  String get careTipNoDirectSun => 'Evita il sole diretto: brucia le foglie.';

  @override
  String get careTipToleratesLowLight =>
      'Tollera una stanza poco luminosa, ma cresce più in fretta vicino a una finestra.';

  @override
  String get careTipToleratesNeglect =>
      'Perdona le dimenticanze: nel dubbio, non annaffiare.';

  @override
  String get careTipBrightForColor => 'Più luce, più i colori sono intensi.';

  @override
  String get careTipRotatePot =>
      'Ruota il vaso di un quarto ogni settimana perché cresca dritta.';

  @override
  String get careTipHatesMoving =>
      'Odia essere spostata: trovale un posto e lasciala lì.';

  @override
  String get careTipWipeLeaves =>
      'Pulisci le foglie: respirano e catturano meglio la luce.';

  @override
  String get careTipTrimToBushOut => 'Accorcia i steli lunghi: si ramificherà.';

  @override
  String get careTipMonsteraSupport =>
      'Dalle un tutore di muschio: le foglie diventeranno più grandi e incise.';

  @override
  String get careTipShallowPot => 'Un vaso largo e basso le si addice di più.';

  @override
  String get careTipLikesBeingPotbound =>
      'Fiorisce meglio se stretta: rinvasa di rado.';

  @override
  String get careTipTrunkStoresWater =>
      'Il piede rigonfio immagazzina acqua: meglio poca che troppa.';

  @override
  String get careTipPupsToShare =>
      'Fa polloni: staccali per moltiplicare o regalare.';

  @override
  String get careTipKeepFlowerSpike =>
      'Non tagliare lo stelo verde: può rifiorire.';

  @override
  String get careTipDarkForRebloom =>
      'Per rifiorire, dalle sei settimane di notti lunghe e fresche.';

  @override
  String get careTipNotADesertCactus =>
      'Non è un cactus del deserto: ama ombra e umidità.';

  @override
  String get careTipDeadheadFlowers =>
      'Togli i fiori appassiti: fiorirà più a lungo.';

  @override
  String get careTipPinchFlowers =>
      'Elimina i boccioli: le foglie restano tenere.';

  @override
  String get careTipHarvestTop =>
      'Raccogli dall\'alto, sopra una coppia di foglie.';

  @override
  String get careTipHarvestOutside =>
      'Raccogli le foglie esterne: il cuore continua a crescere.';

  @override
  String get careTipStakeAndPrune => 'Mettile un tutore e togli le femminelle.';

  @override
  String get careTipPrunesInSpring =>
      'Pota in primavera, mai sul legno vecchio.';

  @override
  String get careTipPrunesAfterFlowering =>
      'Pota subito dopo la fioritura per mantenerla compatta.';

  @override
  String get careTipWinterPruning =>
      'Pota in inverno, senza gelo, mentre riposa.';

  @override
  String get careTipPruneAfterHarvest =>
      'Pota dopo il raccolto, non in primavera.';

  @override
  String get careTipCutSpentCanes =>
      'Taglia alla base i tralci che hanno fruttificato.';

  @override
  String get careTipTrimTwiceAYear =>
      'Bastano due potature l\'anno: giugno e fine agosto.';

  @override
  String get careTipContainItsRoots =>
      'Coltivala in vaso o metti una barriera: invade tutto.';

  @override
  String get careTipMulchIt => 'Pacciama la base: meno acqua, meno erbacce.';

  @override
  String get careTipAcidSoil =>
      'Richiede terra acida: evita il terriccio universale.';

  @override
  String get careTipBlueNeedsAcid =>
      'I fiori blu richiedono terreno acido; nel calcare diventano rosa.';

  @override
  String get careTipCitrusFertilizer =>
      'Usa un concime per agrumi per tutta la bella stagione.';

  @override
  String get careTipNoFertilizer =>
      'Niente concime: troppo ricco perde profumo e portamento.';

  @override
  String get careTipNoNitrogen =>
      'Evita il concime azotato: se lo produce da sola.';

  @override
  String get careTipLetFoliageDieBack =>
      'Lascia ingiallire il fogliame: ricarica il bulbo.';

  @override
  String get careTipDiesBackInWinter =>
      'Scompare in inverno e riparte in primavera: è normale.';

  @override
  String get careTipSummerOutdoors =>
      'Portala fuori in estate, all\'ombra i primi giorni.';

  @override
  String get careTipWinterIndoors => 'Portala dentro prima delle prime gelate.';

  @override
  String get careTipWinterShelter =>
      'Svernala in una stanza fresca e luminosa.';

  @override
  String get careTipWinterCool =>
      'Un inverno fresco (10–14 °C) e luminoso le fa bene.';

  @override
  String get careTipCoolerIsBetter =>
      'Preferisce il fresco: tienila lontana dai termosifoni.';

  @override
  String get careTipHardyOutdoors =>
      'Rustica: sverna all\'aperto senza protezione.';

  @override
  String get careTipShelterFromWind =>
      'Mettila al riparo dal vento: il fogliame si rovina in fretta.';

  @override
  String get careTipAirFlow =>
      'Fai circolare l\'aria: l\'aria ferma favorisce le malattie.';

  @override
  String get careTipSpiderMiteWatch =>
      'Controlla sotto le foglie: il ragnetto rosso la adora.';

  @override
  String get careTipSlugWatch =>
      'Proteggi i germogli dalle lumache in primavera.';

  @override
  String get careTipBoxMothWatch =>
      'Attenzione alla piralide: bruchi e fili di seta nel fogliame.';

  @override
  String get careTipSapIrritant =>
      'La linfa irrita pelle e occhi: pota con i guanti.';

  @override
  String get careTipVeryToxic =>
      'Ogni sua parte è molto tossica, anche il fumo se bruciata.';

  @override
  String get careTipSharpSpines =>
      'Le sue punte sono pericolose: tienila lontana dai passaggi.';

  @override
  String get careTipSplitsAreNormal =>
      'Le foglie si fendono con l\'età: è normale, non è una malattia.';

  @override
  String get careTipDryToBloom =>
      'Un leggero stress idrico stimola la fioritura.';

  @override
  String get customFields => 'Campi personalizzati';

  @override
  String get addCustomField => 'Aggiungi un campo';

  @override
  String get editCustomField => 'Modifica campo';

  @override
  String get deleteCustomField => 'Elimina campo';

  @override
  String get fieldLabel => 'Nome del campo';

  @override
  String get fieldLabelHint => 'Provenienza, prezzo, esposizione…';

  @override
  String get fieldType => 'Tipo';

  @override
  String get fieldValue => 'Valore';

  @override
  String get fieldTypeBool => 'Sì / no';

  @override
  String get fieldTypeInt => 'Numero intero';

  @override
  String get fieldTypeDouble => 'Numero decimale';

  @override
  String get fieldTypeText => 'Testo';

  @override
  String get fieldTypeDate => 'Data';

  @override
  String get fieldEmpty => 'Non indicato';

  @override
  String get noCustomFields => 'Nessun campo personalizzato';

  @override
  String get fieldTemplates => 'Modelli di campo';

  @override
  String get fieldTemplatesHint =>
      'Crea qui i campi che riutilizzi su più piante: te li proporremo con un tocco.';

  @override
  String get newFieldTemplate => 'Nuovo modello';

  @override
  String get noFieldTemplates => 'Nessun modello';

  @override
  String get fieldTemplateInactive => 'Nascosto';

  @override
  String get fieldFromTemplate => 'Da un modello';

  @override
  String get bulkSetField => 'Imposta un campo';

  @override
  String bulkFieldApplied(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Campo applicato a $count piante',
      one: 'Campo applicato a 1 pianta',
    );
    return '$_temp0';
  }

  @override
  String get confirmDeleteField => 'Eliminare questo campo e il suo valore?';

  @override
  String get confirmDeleteTemplate =>
      'Eliminare questo modello? I campi già compilati restano.';

  @override
  String get yes => 'Sì';

  @override
  String get no => 'No';

  @override
  String get attachments => 'Documenti';

  @override
  String get addAttachment => 'Aggiungi un documento';

  @override
  String get noAttachments => 'Nessun documento';

  @override
  String get noAttachmentsHint =>
      'Fattura, scheda del produttore, analisi del suolo…';

  @override
  String get attachmentLabel => 'Nome del documento';

  @override
  String get renameAttachment => 'Rinomina';

  @override
  String get deleteAttachment => 'Elimina documento';

  @override
  String get confirmDeleteAttachment =>
      'Eliminare questo documento? Il file sarà rimosso dal dispositivo.';

  @override
  String get openAttachment => 'Apri';

  @override
  String get attachmentOpenFailed => 'Nessuna app può aprire questo file.';

  @override
  String get photoLabel => 'Titolo della foto';

  @override
  String get photoLabelHint => 'Prima del rinvaso, foglia nuova…';

  @override
  String get setAsMainPhoto => 'Foto principale';

  @override
  String get mainPhotoSet => 'Foto principale aggiornata';

  @override
  String get addPhotoByUrl => 'Da un indirizzo web';

  @override
  String get photoUrlHint => 'https://…';

  @override
  String get photoUrlInvalid =>
      'Indirizzo non valido: deve iniziare con https://';

  @override
  String get photoRemote => 'Foto remota';

  @override
  String get confirmDeletePhoto => 'Eliminare questa foto?';

  @override
  String get shareByLink => 'Condividi con un link';

  @override
  String get sharedLinks => 'Link condivisi';

  @override
  String get sharedLinksHint =>
      'Una pagina web pubblica, revocabile in qualsiasi momento.';

  @override
  String get noSharedLinks => 'Nessun link condiviso';

  @override
  String get shareTitle => 'Titolo della pagina';

  @override
  String get shareDescription => 'Descrizione (facoltativa)';

  @override
  String get shareKeywords => 'Parole chiave (facoltative)';

  @override
  String get shareUnlisted => 'Non elencato';

  @override
  String get shareUnlistedHint =>
      'La pagina chiede ai motori di ricerca di non indicizzarla. Chi ha il link può comunque vederla.';

  @override
  String get shareExpiry => 'Scade il';

  @override
  String get shareNoExpiry => 'Senza scadenza';

  @override
  String get shareCreate => 'Crea il link';

  @override
  String get shareCopy => 'Copia il link';

  @override
  String get shareCopied => 'Link copiato';

  @override
  String get shareRevoke => 'Revoca';

  @override
  String get shareRevoked => 'Revocato';

  @override
  String get shareExpired => 'Scaduto';

  @override
  String get shareActive => 'Attivo';

  @override
  String get confirmRevokeLink =>
      'Revocare questo link? La pagina non sarà più accessibile.';

  @override
  String get shareNeedsAccount =>
      'La condivisione tramite link richiede un account.';

  @override
  String get shareFailed => 'Impossibile creare il link. Riprova.';

  @override
  String get sharePhoto => 'Condividi questa foto';

  @override
  String get sharePlant => 'Condividi questa pianta';

  @override
  String get notesMarkdownHint =>
      'Formattazione: **grassetto**, *corsivo*, - elenchi, [link](https://…)';

  @override
  String get preview => 'Anteprima';

  @override
  String get locationNotes => 'Note del luogo';

  @override
  String get locationLog => 'Diario';

  @override
  String get addLogEntry => 'Aggiungi una voce';

  @override
  String get editLogEntry => 'Modifica la voce';

  @override
  String get logEntryHint => 'Tenda sostituita, serra pulita…';

  @override
  String get noLogEntries => 'Diario vuoto';

  @override
  String get confirmDeleteLogEntry => 'Eliminare questa voce?';

  @override
  String get locationPhoto => 'Foto del luogo';

  @override
  String get removeLocationPhoto => 'Rimuovi la foto';

  @override
  String get careAllPlants => 'Cura tutte le piante';

  @override
  String get waterAllHere => 'Annaffia tutto qui';

  @override
  String get fertilizeAllHere => 'Concima tutto qui';

  @override
  String get repotAllHere => 'Rinvasa tutto qui';

  @override
  String plantNumber(int number) {
    return 'N. $number';
  }

  @override
  String get searchByNumberHint =>
      'Suggerimento: digita #42 per trovare la pianta n. 42.';

  @override
  String get inventoryGroups => 'Gruppi';

  @override
  String get manageGroups => 'Gestisci i gruppi';

  @override
  String get newGroup => 'Nuovo gruppo';

  @override
  String get editGroup => 'Modifica gruppo';

  @override
  String get groupName => 'Nome del gruppo';

  @override
  String get groupNameHint => 'Concimi, attrezzi, vasi…';

  @override
  String get deleteGroup => 'Elimina gruppo';

  @override
  String get deleteGroupHint =>
      'Gli articoli non vengono eliminati: passano al gruppo scelto.';

  @override
  String get moveItemsTo => 'Sposta gli articoli in';

  @override
  String get noGroup => 'Senza gruppo';

  @override
  String get noGroups => 'Nessun gruppo personalizzato';

  @override
  String get itemGroup => 'Gruppo';

  @override
  String get itemTags => 'Tag';

  @override
  String get itemQr => 'QR dell\'articolo';

  @override
  String get exportSelection => 'Esporta la selezione';

  @override
  String get exportCsv => 'Esporta in CSV';

  @override
  String get selectItems => 'Seleziona';

  @override
  String itemsSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count articoli',
      one: '1 articolo',
    );
    return '$_temp0';
  }

  @override
  String get filterByTag => 'Filtra per tag';

  @override
  String get itemNotFound => 'Articolo non trovato';

  @override
  String get noGroupsYet =>
      'Nessun gruppo per ora. Creane uno per organizzare gli articoli a modo tuo.';

  @override
  String get deleteGroupExplain =>
      'Gli articoli non vengono eliminati: tornano semplicemente senza gruppo.';

  @override
  String get newEvent => 'Nuovo evento';

  @override
  String get editEvent => 'Modifica evento';

  @override
  String get deleteEvent => 'Elimina evento';

  @override
  String get eventTitleHint => 'Mercato delle piante';

  @override
  String get eventNotesHint => 'Note (facoltativo)';

  @override
  String get eventStart => 'Inizio';

  @override
  String get eventEnd => 'Fine';

  @override
  String get eventNoEnd => 'Stesso giorno';

  @override
  String get eventAllDay => 'Tutto il giorno';

  @override
  String get eventCategory => 'Categoria';

  @override
  String get eventNoCategory => 'Nessuna';

  @override
  String get eventReminder => 'Promemoria';

  @override
  String get eventNoReminder => 'Nessuno';

  @override
  String get eventReminderAtStart => 'All\'inizio';

  @override
  String eventReminderMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minuti prima',
      one: '1 minuto prima',
    );
    return '$_temp0';
  }

  @override
  String eventReminderHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ore prima',
      one: '1 ora prima',
    );
    return '$_temp0';
  }

  @override
  String eventReminderDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count giorni prima',
      one: '1 giorno prima',
    );
    return '$_temp0';
  }

  @override
  String get manageEventCategories => 'Categorie di eventi';

  @override
  String get newEventCategory => 'Nuova categoria';

  @override
  String get editEventCategory => 'Modifica categoria';

  @override
  String get deleteEventCategory => 'Elimina categoria';

  @override
  String get deleteEventCategoryExplain =>
      'Gli eventi non vengono eliminati: perdono soltanto la categoria.';

  @override
  String get noEventCategoriesYet =>
      'Nessuna categoria. Creane una per colorare i tuoi eventi.';

  @override
  String get categoryNameHint => 'Nome della categoria';

  @override
  String get eventPlant => 'Pianta collegata';

  @override
  String get eventNoPlant => 'Nessuna';

  @override
  String get eventsOfDay => 'Eventi';

  @override
  String get dashboardTitle => 'Cruscotto';

  @override
  String get statsSection => 'Numeri';

  @override
  String get statPlants => 'Piante';

  @override
  String get statSpecies => 'Specie';

  @override
  String get statLocations => 'Posizioni';

  @override
  String get statFavorites => 'Preferite';

  @override
  String get statArchived => 'Archiviate';

  @override
  String get statNeedingCare => 'Da curare';

  @override
  String get statOpenTasks => 'Attività aperte';

  @override
  String get statLowStock => 'Scorte basse';

  @override
  String get statActionsThisMonth => 'Cure questo mese';

  @override
  String get statWateringsThisMonth => 'Annaffiature questo mese';

  @override
  String get statOldest => 'La più anziana';

  @override
  String get warningsSection => 'Da tenere d\'occhio';

  @override
  String get warningSick => 'Malata';

  @override
  String get warningWatch => 'Da osservare';

  @override
  String warningOverdue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count giorni di ritardo',
      one: '1 giorno di ritardo',
    );
    return '$_temp0';
  }

  @override
  String get noWarnings => 'Va tutto bene nel giardino.';

  @override
  String get recentPlantsSection => 'Piante recenti';

  @override
  String get recentAdded => 'Aggiunte';

  @override
  String get recentUpdated => 'Modificate';

  @override
  String get activityLogTitle => 'Registro attività';

  @override
  String get activityEmpty =>
      'Ancora nulla. Il registro si riempie dalla prima cura.';

  @override
  String get activityPlantAdded => 'Aggiunta al giardino';

  @override
  String get activityPlantArchived => 'Archiviata';

  @override
  String get activityLocationNote => 'Nota di posizione';

  @override
  String get activityTaskDone => 'Attività completata';

  @override
  String get archiveNameTitle => 'Nome dell\'archivio';

  @override
  String get archiveNameHint => 'Memoriale, Il passato…';

  @override
  String get archiveNameExplain =>
      'Lascia vuoto per mantenere il nome predefinito.';

  @override
  String get searchArchives => 'Cerca negli archivi';

  @override
  String get archiveSortArchivedDesc => 'Archiviate di recente';

  @override
  String get archiveSortArchivedAsc => 'Archiviate per prime';

  @override
  String get archiveSortName => 'Nome';

  @override
  String get archiveSortLongestKept => 'Tenute più a lungo';

  @override
  String get allYears => 'Tutte';

  @override
  String keptForDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tenuta $count giorni',
      one: 'Tenuta 1 giorno',
    );
    return '$_temp0';
  }

  @override
  String keptForYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tenuta $count anni',
      one: 'Tenuta 1 anno',
    );
    return '$_temp0';
  }

  @override
  String get noArchiveMatch => 'Nessuna pianta corrisponde.';

  @override
  String get weatherForecastTitle => 'Previsioni';

  @override
  String get weatherPrecipitation => 'Precipitazioni';

  @override
  String get weatherRainChance => 'Probabilità di pioggia';

  @override
  String get weatherWind => 'Vento';

  @override
  String get weatherHumidity => 'Umidità';

  @override
  String get weatherNoPlace => 'Scegli un luogo per vedere le previsioni.';

  @override
  String get weatherToday => 'Oggi';

  @override
  String get weatherFailed => 'Previsioni non disponibili al momento.';

  @override
  String get backupTitle => 'Backup';

  @override
  String get backupExplain =>
      'Un file .zip con i tuoi dati e le tue foto. Formato aperto: i dati restano tuoi.';

  @override
  String get backupWhatToExport => 'Cosa salvare';

  @override
  String get backupWhatToImport => 'Cosa ripristinare';

  @override
  String get sectionGarden => 'Giardino e posizioni';

  @override
  String get sectionPlants => 'Piante';

  @override
  String get sectionPhotos => 'Foto';

  @override
  String get sectionCare => 'Cure e routine';

  @override
  String get sectionInventory => 'Inventario';

  @override
  String get sectionTasks => 'Attività';

  @override
  String get sectionCalendar => 'Calendario';

  @override
  String get importBackup => 'Ripristina un backup';

  @override
  String get chooseBackupFile => 'Scegli un file';

  @override
  String get importing => 'Ripristino…';

  @override
  String importDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count elementi ripristinati',
      one: '1 elemento ripristinato',
    );
    return '$_temp0';
  }

  @override
  String importSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count righe ignorate',
      one: '1 riga ignorata',
    );
    return '$_temp0';
  }

  @override
  String get importConfirm =>
      'I dati del file sostituiscono quelli con lo stesso identificatore. Nulla viene eliminato.';

  @override
  String get importErrorNotAZip => 'Questo file non è un backup Flora.';

  @override
  String get importErrorWrongApp => 'Questo backup proviene da un\'altra app.';

  @override
  String get importErrorTooRecent =>
      'Questo backup proviene da una versione più recente di Flora.';

  @override
  String get importErrorGeneric => 'Ripristino non riuscito.';

  @override
  String backupFrom(String date) {
    return 'Backup del $date';
  }

  @override
  String backupContains(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count elementi',
      one: '1 elemento',
    );
    return '$_temp0';
  }

  @override
  String get apiTitle => 'API esterna';

  @override
  String get apiExplain =>
      'I tuoi dati sono raggiungibili tramite l\'API REST del tuo progetto Supabase, con la tua chiave. Nulla è esposto senza account.';

  @override
  String get apiNotConnected => 'Collega un account per abilitare l\'API.';

  @override
  String get apiEndpoints => 'Endpoint';

  @override
  String get apiCopyBase => 'Copia l\'URL di base';

  @override
  String get apiCopied => 'URL copiato';

  @override
  String get apiTokenHint =>
      'Autenticati con il token della tua sessione Supabase (intestazione Authorization: Bearer).';

  @override
  String get apiCopyToken => 'Copia il token di accesso';

  @override
  String get apiTokenCopied => 'Token copiato';

  @override
  String get apiTokenWarning =>
      'Valido per alcune ore. Si revoca disconnettendoti.';

  @override
  String get apiReadWrite => 'Lettura e scrittura';

  @override
  String get apiOnlyYourGarden =>
      'Ogni richiesta vede solo i giardini di cui fai parte.';

  @override
  String get apiExample => 'Esempio';

  @override
  String get onbTodayTitle => 'Ogni mattina, cosa c\'è da fare';

  @override
  String get onbTodayBody => 'Annaffiata? Un tocco, ed è segnato.';

  @override
  String get onbCareTitle => 'Meno annaffiature d\'inverno';

  @override
  String get onbCareBody =>
      'Gli intervalli si adattano da soli quando le giornate si accorciano.';

  @override
  String get onbGardenTitle => 'Stanze, foto, calendario';

  @override
  String get onbGardenBody => 'La storia di ogni pianta si conserva da sola.';

  @override
  String get onbPrivacyTitle => 'Tutto resta sul tuo telefono';

  @override
  String get onbPrivacyBody =>
      'Nessun account obbligatorio, nessuna pubblicità.';

  @override
  String get onbStart => 'Iniziare';

  @override
  String get replayOnboarding => 'Rivedi la presentazione';

  @override
  String onbStepOf(int current, int total) {
    return 'Passo $current di $total';
  }

  @override
  String get weatherPickPlace => 'Scegli un luogo';

  @override
  String get speciesMoreOffline => 'Altre specie';

  @override
  String get aboutSources => 'Fonti dei dati';

  @override
  String get aboutSourceWikidata =>
      'Nomi delle specie in quattro lingue, dominio pubblico';

  @override
  String get aboutSourceGbif =>
      'Tassonomia, famiglie e osservazioni fotografate';

  @override
  String get aboutSourceOpenMeteo =>
      'Meteo e previsioni, senza account né chiave';

  @override
  String aboutSpeciesCount(String count) {
    return '$count specie consultabili offline';
  }

  @override
  String get supportTitle => 'Flora è gratuita';

  @override
  String get supportBody =>
      'Tutte le funzioni sono gratuite. Se l\'app ti è utile, puoi dare una mano al suo sviluppatore — una volta, senza abbonamento.';

  @override
  String get supportNothingLocked => 'Niente è riservato a chi dona.';

  @override
  String supportGive(String price) {
    return 'Sostieni · $price';
  }

  @override
  String get supportRestore => 'Ripristina il mio sostegno';

  @override
  String get supportThanksTitle => 'Grazie';

  @override
  String get supportThanksBody =>
      'Il tuo sostegno è registrato. L\'app non cambia: era già completa.';

  @override
  String get supportUnavailable =>
      'L\'acquisto non è disponibile su questo dispositivo.';

  @override
  String get supportFailed => 'L\'acquisto non è andato a buon fine.';

  @override
  String get supportNothingToRestore => 'Nessun sostegno da ripristinare.';

  @override
  String get supportSettings => 'Sostieni lo sviluppatore';

  @override
  String get supportFreeForever => 'Gratuita, senza limiti';

  @override
  String get supportAlready => 'Grazie per il tuo sostegno';

  @override
  String get supportNoThanks => 'Continua senza';

  @override
  String get aboutTagline =>
      'Prenditi cura delle tue piante e conserva la loro storia.';

  @override
  String get emptyGardenSubtitle =>
      'Aggiungi la tua prima pianta, con una foto se vuoi.';
}
