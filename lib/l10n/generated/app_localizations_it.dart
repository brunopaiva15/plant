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
  String get freeLimitTitle => 'Limite raggiunto';

  @override
  String freeLimitBody(int count) {
    return 'La versione gratuita include $count piante. Passa a Premium per una collezione illimitata.';
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
  String get premium => 'Premium';

  @override
  String get premiumBody =>
      'Piante illimitate, identificazione, diagnosi, collaborazione. Presto disponibile.';

  @override
  String premiumPlantCount(int count, int limit) {
    return '$count / $limit piante';
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
  String get onboardingTitle => 'Il tuo giardino, semplicemente.';

  @override
  String get onboardingSubtitle =>
      'Prenditi cura delle tue piante e conserva la loro storia.';

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
  String get gardenLocations => 'Posizioni';

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
}
