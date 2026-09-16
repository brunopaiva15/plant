// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appName => 'Auxine';

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
  String get openSettings => 'Apri Impostazioni';

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
  String get soon => 'In arrivo';

  @override
  String get genericError => 'Si è verificato un errore. Riprova.';

  @override
  String get offlineTitle => 'Offline';

  @override
  String get offlineHint =>
      'Serve una connessione. I dati già sul dispositivo restano leggibili.';

  @override
  String get offlineActionFailed => 'Offline. Riprova quando la rete torna.';

  @override
  String get offlineSharing =>
      'Creare, revocare ed elencare i link richiede una connessione.';

  @override
  String get offlineCollaboration =>
      'Invitare, unirsi a un giardino e cambiare ruolo richiede una connessione.';

  @override
  String get offlineDiagnosis => 'L\'analisi richiede una connessione.';

  @override
  String get offlineIdentification =>
      'La ricerca online richiede una connessione. Il riconoscimento sul dispositivo no.';

  @override
  String get offlineSupport => 'L\'acquisto richiede una connessione.';

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
  String greetingEvening(String name) {
    return 'Buonasera $name';
  }

  @override
  String get greetingEveningAnonymous => 'Buonasera';

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
  String get allDoneSubtitle => 'Nessuna cura prevista oggi.';

  @override
  String get emptyGardenTitle => 'Nessuna pianta';

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
  String get sortEdited => 'Modifica recente';

  @override
  String get sortLastWatered => 'Ultima annaffiatura';

  @override
  String get sortLastFertilized => 'Ultima concimazione';

  @override
  String get sortLastRepotted => 'Ultimo rinvaso';

  @override
  String get sortAcquired => 'Acquisto';

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
  String get showAsGrid => 'Mostra come griglia';

  @override
  String get showAsList => 'Mostra come elenco';

  @override
  String get noResultsTitle => 'Nessun risultato';

  @override
  String get noResultsSubtitle => 'Prova con un\'altra parola.';

  @override
  String get emptyPlantsTitle => 'Nessuna pianta';

  @override
  String get emptyPlantsSubtitle => 'Aggiungete la prima pianta.';

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
  String get stepPhotoTitle => 'Foto';

  @override
  String get stepPhotoSubtitle =>
      'Inquadra la pianta intera, alla luce del giorno.';

  @override
  String get stepPhotoSubtitleCutting =>
      'Inquadra la talea intera, alla luce del giorno.';

  @override
  String get takePhoto => 'Scatta una foto';

  @override
  String get choosePhoto => 'Scegli una foto';

  @override
  String get withoutPhoto => 'Continua senza foto';

  @override
  String get changePhoto => 'Cambia';

  @override
  String get stepNameTitle => 'Nome';

  @override
  String get plantNameHint => 'Nome della pianta';

  @override
  String get speciesHint => 'Specie (facoltativo)';

  @override
  String get stepLocationTitle => 'Posizione';

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
  String get notesHint => 'Esposizione, rinvaso, osservazioni…';

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
  String get offspring => 'Piante figlie';

  @override
  String get editSchedule => 'Modifica il programma';

  @override
  String cuttingOf(String name) {
    return 'Talea di $name';
  }

  @override
  String get propagate => 'Crea una talea';

  @override
  String get pgPickTitle => 'Moltiplicare questa pianta';

  @override
  String get pgPickBody =>
      'Questa pianta si moltiplica in più modi. Il gesto scelto determina i passaggi.';

  @override
  String get pgRecommended => 'Consigliato';

  @override
  String pgIntroTitle(String name, String species) {
    return '$name di $species';
  }

  @override
  String pgIntroBody(int count) {
    return '$count passaggi. Ognuno è mostrato con un gesto, poi detto in una frase, adattata alla specie quando è nota.';
  }

  @override
  String get pgStartCutting => 'Crea la talea';

  @override
  String get pgStartPlant => 'Crea la pianta';

  @override
  String get pgNoteSpot => 'Da notare';

  @override
  String get pgNoteAvoid => 'Da evitare';

  @override
  String get pgNoteUsual => 'In genere';

  @override
  String get pgNoteMedium => 'Radicazione';

  @override
  String get pgMediumWater => 'In acqua';

  @override
  String get pgMediumSubstrate => 'In substrato leggero';

  @override
  String get pgMediumEither => 'Acqua o substrato leggero';

  @override
  String get pgVineName => 'Talea di fusto';

  @override
  String get pgVineHint => 'Un nodo, un taglio netto, l’acqua';

  @override
  String get pgVineNodeTitle => 'Il nodo';

  @override
  String get pgVineNodeBody =>
      'Il rigonfiamento da cui parte una foglia, spesso con una radice aerea accanto. La talea ne conserva almeno uno.';

  @override
  String get pgVineNodeNote => 'Nodo e radice aerea';

  @override
  String get pgVineCutTitle => 'Il taglio';

  @override
  String get pgVineCutBody =>
      'Lama pulita, taglio netto un centimetro sotto il nodo. Il nodo resta sulla talea.';

  @override
  String get pgVineCutNote => 'Tagliare sopra il nodo';

  @override
  String get pgVineClearTitle => 'Il nodo libero';

  @override
  String get pgVineClearBody =>
      'Le foglie che resterebbero sott’acqua vengono tolte. Due o tre foglie in alto nutrono la talea.';

  @override
  String get pgVineWaterTitle => 'L’acqua';

  @override
  String get pgVineWaterBody =>
      'Il nodo sotto la superficie, le foglie sopra. Luce viva, senza sole diretto.';

  @override
  String get pgVineRootsTitle => 'Le radici';

  @override
  String get pgVineRootsBody =>
      'Escono dal nodo, non dalla base del fusto. L’acqua si cambia ogni settimana.';

  @override
  String get pgVineRootsNote => 'Prime radici in due-sei settimane';

  @override
  String get pgVinePotTitle => 'Il vaso';

  @override
  String get pgVinePotBody =>
      'A qualche centimetro di radice la talea passa in terriccio leggero. Il nodo resta appena sotto la superficie.';

  @override
  String get pgSoftName => 'Talea di getto tenero';

  @override
  String get pgSoftHint => 'Un getto giovane, radici rapide';

  @override
  String get pgSoftStemTitle => 'Il getto';

  @override
  String get pgSoftStemBody =>
      'Un getto giovane e sodo, senza fiori, di una decina di centimetri. Il legno vecchio radica male.';

  @override
  String get pgSoftCutTitle => 'Il taglio';

  @override
  String get pgSoftCutBody =>
      'Lama pulita, taglio appena sotto una coppia di foglie. Le radici partiranno da lì.';

  @override
  String get pgSoftStripTitle => 'Le foglie basse';

  @override
  String get pgSoftStripBody =>
      'La coppia più bassa viene tolta: tre o quattro centimetri di fusto restano nudi.';

  @override
  String get pgSoftStripNote => 'Lasciare una foglia sott’acqua';

  @override
  String get pgSoftRootTitle => 'La radicazione';

  @override
  String get pgSoftRootBody =>
      'Il fusto nudo resta in acqua, le foglie all’asciutto. Luce viva, senza sole diretto.';

  @override
  String get pgSoftRootsTitle => 'Le radici';

  @override
  String get pgSoftRootsBody =>
      'Fini e numerose, escono da tutta la parte immersa.';

  @override
  String get pgSoftRootsNote => 'Prime radici in una-tre settimane';

  @override
  String get pgSoftPotTitle => 'Il trapianto';

  @override
  String get pgSoftPotBody =>
      'Trapiantata presto, a due o tre centimetri di radice: un getto tenero aspetta male.';

  @override
  String get pgLeafName => 'Talea di foglia';

  @override
  String get pgLeafHint => 'Più lenta, basta una foglia';

  @override
  String get pgLeafChooseTitle => 'La foglia';

  @override
  String get pgLeafChooseBody =>
      'Una foglia matura, soda, senza segni. Le foglie giovani non hanno riserve.';

  @override
  String get pgLeafCutTitle => 'Il taglio';

  @override
  String get pgLeafCutBody =>
      'Lama pulita, taglio alla base della foglia, a filo del substrato.';

  @override
  String get pgLeafSplitTitle => 'I segmenti';

  @override
  String get pgLeafSplitBody =>
      'La foglia si divide in pezzi di cinque-otto centimetri. Una V incisa in basso dice quale estremità va in terra.';

  @override
  String get pgLeafSplitNote => 'La V indica il basso';

  @override
  String get pgLeafCallusTitle => 'L’asciugatura';

  @override
  String get pgLeafCallusBody =>
      'I tagli asciugano all’aria, all’ombra, prima di andare nel substrato.';

  @override
  String get pgLeafCallusNote => 'Uno-due giorni di asciugatura';

  @override
  String get pgLeafPlantTitle => 'Il substrato';

  @override
  String get pgLeafPlantBody =>
      'La V entra per due centimetri in un substrato drenante.';

  @override
  String get pgLeafPlantNote => 'Piantare un segmento al contrario';

  @override
  String get pgLeafGrowthTitle => 'La ripresa';

  @override
  String get pgLeafGrowthBody =>
      'Prima arrivano le radici, poi un giovane getto esce dal substrato accanto al segmento.';

  @override
  String get pgLeafGrowthNote => 'Nuovo getto in due-quattro mesi';

  @override
  String get pgDivisionName => 'Divisione';

  @override
  String get pgDivisionHint => 'Rapida e sicura, il cespo si divide';

  @override
  String get pgDivPlantTitle => 'Il cespo';

  @override
  String get pgDivPlantBody =>
      'La pianta esce intera dal vaso. Un substrato bagnato il giorno prima tiene meglio.';

  @override
  String get pgDivUnpotTitle => 'Fuori dal vaso';

  @override
  String get pgDivUnpotBody =>
      'Il vaso scivola via dal pane di terra e la pianta è libera.';

  @override
  String get pgDivRootsTitle => 'Il pane di terra';

  @override
  String get pgDivRootsBody =>
      'La terra si sbriciola finché si vedono le radici e la base dei getti.';

  @override
  String get pgDivClustersTitle => 'I due gruppi';

  @override
  String get pgDivClustersBody =>
      'Ogni gruppo conserva i suoi getti e le sue radici.';

  @override
  String get pgDivClustersNote => 'Foglie e radici da entrambi i lati';

  @override
  String get pgDivSplitTitle => 'La separazione';

  @override
  String get pgDivSplitBody =>
      'I gruppi si staccano a mano. La lama serve solo se i colletti resistono.';

  @override
  String get pgDivSplitNote => 'Tagliare un fusto sopra la terra';

  @override
  String get pgDivRepotTitle => 'Il rinvaso';

  @override
  String get pgDivRepotBody =>
      'Ogni divisione va nel suo vaso, alla profondità di prima, e riceve una prima annaffiatura.';

  @override
  String get pgOffsetName => 'Separare un pollone';

  @override
  String get pgOffsetHint => 'Il pollone parte con le sue radici';

  @override
  String get pgOffSpotTitle => 'Il pollone';

  @override
  String get pgOffSpotBody =>
      'Un pollone grande un terzo della madre, con foglie proprie, è pronto.';

  @override
  String get pgOffSpotNote => 'Pollone già formato';

  @override
  String get pgOffClearTitle => 'La liberazione';

  @override
  String get pgOffClearBody =>
      'Il substrato si allontana attorno alla base e il legame con la pianta madre appare.';

  @override
  String get pgOffDetachTitle => 'La separazione';

  @override
  String get pgOffDetachBody =>
      'Il pollone si stacca dal legame, con le sue radici. La lama serve solo se il legame è legnoso.';

  @override
  String get pgOffDetachNote => 'Strappare il pollone senza radici';

  @override
  String get pgOffRootsTitle => 'Le radici';

  @override
  String get pgOffRootsBody =>
      'Bastano poche radici sane. Senza di esse il pollone secca prima di riprendere.';

  @override
  String get pgOffPotTitle => 'Il vaso';

  @override
  String get pgOffPotBody =>
      'Un vaso piccolo, il substrato della specie e una leggera annaffiatura.';

  @override
  String get pgOffSettleTitle => 'La ripresa';

  @override
  String get pgOffSettleBody =>
      'Una foglia nuova al centro dice che il pollone ha attecchito.';

  @override
  String get pgOffSettleNote => 'Ripresa in tre-sei settimane';

  @override
  String get pgSegmentName => 'Talea di segmento';

  @override
  String get pgSegmentHint => 'Un segmento staccato, asciugato, piantato';

  @override
  String get pgSegChooseTitle => 'Il segmento';

  @override
  String get pgSegChooseBody =>
      'Un segmento terminale sodo e senza grinze, di due o tre articoli.';

  @override
  String get pgSegDetachTitle => 'Il distacco';

  @override
  String get pgSegDetachBody =>
      'Il segmento si stacca all’articolazione, con una torsione. Lama pulita se l’articolo resiste.';

  @override
  String get pgSegDetachNote => 'Tirare e strappare l’articolo';

  @override
  String get pgSegWoundTitle => 'La ferita';

  @override
  String get pgSegWoundBody =>
      'Il taglio è chiaro e umido. Piantato subito, marcisce.';

  @override
  String get pgSegCallusTitle => 'La cicatrizzazione';

  @override
  String get pgSegCallusBody =>
      'La ferita asciuga all’aria, all’ombra, fino a formare un callo opaco.';

  @override
  String get pgSegCallusNote => 'Tre-sette giorni di asciugatura';

  @override
  String get pgSegPlantTitle => 'Il substrato';

  @override
  String get pgSegPlantBody =>
      'Il callo entra appena un centimetro in un substrato molto drenante.';

  @override
  String get pgSegPlantNote => 'Interrare il segmento';

  @override
  String get pgSegRootsTitle => 'La ripresa';

  @override
  String get pgSegRootsBody =>
      'Prima arrivano le radici, poi un nuovo articolo. L’annaffiatura aspetta che le radici tengano.';

  @override
  String get parentPlant => 'Pianta madre';

  @override
  String get schedule => 'Programma';

  @override
  String get editPlant => 'Modifica pianta';

  @override
  String get archivePlant => 'Archivia pianta';

  @override
  String get archiveReasonTitle => 'Motivo';

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
  String get healthIssue => 'Problema';

  @override
  String get issueOverwatering => 'Troppa acqua';

  @override
  String get issueUnderwatering => 'Poca acqua';

  @override
  String get issuePests => 'Parassiti';

  @override
  String get issueDisease => 'Malattia';

  @override
  String get issueRootRot => 'Marciume radicale';

  @override
  String get issueTransplantShock => 'Shock da trapianto';

  @override
  String get issueDeficiency => 'Carenza';

  @override
  String get issueSunburn => 'Scottatura solare';

  @override
  String get issueFrost => 'Gelo';

  @override
  String get needsSection => 'Esigenze';

  @override
  String get detailsSection => 'Dettagli';

  @override
  String get lifespan => 'Ciclo di vita';

  @override
  String get lifespanAnnual => 'Annuale';

  @override
  String get lifespanBiennial => 'Biennale';

  @override
  String get lifespanPerennial => 'Perenne';

  @override
  String get hardiness => 'Rusticità';

  @override
  String get hardinessHardy => 'Rustica';

  @override
  String get hardinessTender => 'Sensibile al gelo';

  @override
  String get cuttingMonth => 'Mese di talea';

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
  String get strategyFixedHint => 'Lo stesso intervallo tutto l\'anno.';

  @override
  String get enabled => 'Attiva';

  @override
  String get interval => 'Intervallo';

  @override
  String get intervalSuggested => 'Intervallo consigliato';

  @override
  String intervalSuggestedDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Intervallo consigliato: $count giorni',
      one: 'Intervallo consigliato: 1 giorno',
    );
    return '$_temp0';
  }

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
  String get whatDidYouDo => 'Azione';

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
      'Per impostazione predefinita, vale il valore del sistema.';

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
      'Una notifica al giorno, solo se è prevista una cura.';

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
  String get localAccountHint => 'I dati restano su questo telefono.';

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
  String get onboardingSubtitle => 'Aggiungetele con o senza foto.';

  @override
  String get onbPlaceTitle => 'La vostra città';

  @override
  String get onbPlaceBody =>
      'Per il meteo e l\'irrigazione all\'aperto. Basta una città, la posizione esatta non viene salvata.';

  @override
  String get useMyLocation => 'Usa la mia posizione';

  @override
  String get locating => 'Ricerca della tua città…';

  @override
  String get locationFailed =>
      'Posizione non disponibile. Potrai scegliere una città in Profilo › Meteo.';

  @override
  String get onbHomeTitle => 'La vostra casa';

  @override
  String get onbHomeBody =>
      'I sensori di Casa di Apple e di Google Home danno temperatura e umidità della stanza. Consigli e diagnosi delle piante da interno ne tengono conto. La misura resta nell\'app.';

  @override
  String get homeClimate => 'Sensori di casa';

  @override
  String get homeClimateHint =>
      'Temperatura e umidità di un sensore di casa adattano i consigli delle piante da interno e completano le diagnosi. La misura resta nell\'app.';

  @override
  String get homeClimateApple => 'Casa di Apple';

  @override
  String get homeClimateGoogle => 'Google Home';

  @override
  String get homeClimateConnect => 'Collega una casa';

  @override
  String get homeClimateConnectApple => 'Collega Casa di Apple';

  @override
  String get homeClimateConnectGoogle => 'Collega Google Home';

  @override
  String get homeClimateSearching => 'Ricerca dei sensori…';

  @override
  String get homeClimateSensor => 'Sensore';

  @override
  String get homeClimateSensors => 'Sensori trovati';

  @override
  String get homeClimateChoose => 'Scegli un sensore';

  @override
  String get homeClimateChange => 'Cambia sensore';

  @override
  String get homeClimateHome => 'Casa';

  @override
  String get homeClimateSource => 'Piattaforma';

  @override
  String get homeClimateNoRoom => 'Senza stanza';

  @override
  String get homeClimateTemperatureSensor => 'Sensore di temperatura';

  @override
  String get homeClimateHumiditySensor => 'Sensore di umidità';

  @override
  String get homeClimateSameSensor => 'Stesso sensore';

  @override
  String get homeClimateHumidityMissing =>
      'Umidità non ricevuta da questo sensore. Un altro si sceglie nella riga Umidità.';

  @override
  String get homeClimateNone => 'Nessun sensore';

  @override
  String get homeClimateRemove => 'Rimuovi sensore';

  @override
  String get homeClimateReading => 'Misura';

  @override
  String get homeClimateUnavailable => 'Sensore non raggiungibile per ora.';

  @override
  String homeClimateUpdatedAgo(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes min fa',
      one: '1 min fa',
      zero: 'Adesso',
    );
    return '$_temp0';
  }

  @override
  String homeClimateNoSensorsIn(String home) {
    return 'Nessun sensore di temperatura o umidità in $home.';
  }

  @override
  String get homeClimateDeniedApple =>
      'Accesso a Casa di Apple rifiutato. Si riattiva in Impostazioni › Privacy › Casa.';

  @override
  String get homeClimateDeniedGoogle =>
      'Accesso a Google Home rifiutato. Si riattiva nell\'app Google Home, nelle autorizzazioni.';

  @override
  String homeClimateFailedIn(String home) {
    return '$home non disponibile. Potrai collegare un sensore in Profilo › Sensori di casa.';
  }

  @override
  String get homeClimateAppleNote =>
      'Casa di Apple legge gli accessori sul dispositivo.';

  @override
  String get homeClimateGoogleNote =>
      'Google Home legge i dispositivi tramite il tuo account Google.';

  @override
  String get homeClimateDisconnect => 'Disconnetti';

  @override
  String get homeClimateDisconnectGoogle => 'Disconnetti Google Home';

  @override
  String get homeClimateDisconnectGoogleHint =>
      'I sensori di Google Home vengono dimenticati su questo dispositivo. L\'autorizzazione concessa resta nell\'account Google e si revoca da lì.';

  @override
  String get homeClimateDisconnectedGoogle => 'Google Home disconnesso.';

  @override
  String get homeClimateGoogleAccess => 'Autorizzazioni dell\'account Google';

  @override
  String get homeClimateAtHome => 'Da voi';

  @override
  String get homeClimateFits => 'Niente che disturbi questa specie.';

  @override
  String get homeClimateTooDry => 'Aria troppo secca per questa specie.';

  @override
  String get homeClimateTooHumid => 'Aria troppo umida per questa specie.';

  @override
  String get homeClimateTooCold => 'Troppo freddo per questa specie.';

  @override
  String get homeClimateTooHot => 'Troppo caldo per questa specie.';

  @override
  String homeTipDryAir(String names) {
    return 'Aria secca: nebulizzare o raggruppare $names.';
  }

  @override
  String get homeTipHumidAir => 'Aria umida: arieggiare la stanza.';

  @override
  String homeTipHumidAirPlants(String names) {
    return 'Aria umida: arieggiare, e lasciare asciugare $names tra due annaffiature.';
  }

  @override
  String homeTipCold(String names) {
    return 'Troppo freddo per $names.';
  }

  @override
  String homeTipHot(String names) {
    return 'Caldo: $names si asciugano più in fretta, controllare la terra.';
  }

  @override
  String diagnosisWithHome(String reading) {
    return 'Misura di casa allegata: $reading.';
  }

  @override
  String placeChosen(String place) {
    return 'Meteo impostato su $place.';
  }

  @override
  String get askNameTitle => 'Il vostro nome';

  @override
  String get askNameSubtitle => 'Modificabile in seguito nel profilo.';

  @override
  String get onbAccountTitle => 'Backup e condivisione';

  @override
  String get onbAccountBody =>
      'Un account salva i dati e permette di condividere un giardino. Accesso con il vostro ID Apple.';

  @override
  String get notificationAskTitle => 'Promemoria giornaliero';

  @override
  String get notificationAskBody =>
      'Una notifica al giorno, all\'ora scelta, solo se è prevista una cura.';

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
    return '$name: irrigazione prevista oggi.';
  }

  @override
  String notifWaterMany(String names) {
    return '$names: irrigazione prevista oggi.';
  }

  @override
  String notifOther(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count altre cure previste.',
      one: '1 altra cura prevista.',
    );
    return '$_temp0';
  }

  @override
  String notifOnlyOther(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cure previste oggi.',
      one: '1 cura prevista oggi.',
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
  String get fertForm => 'Forma';

  @override
  String get fertFormLiquid => 'Liquido';

  @override
  String get fertFormGranules => 'Granuli';

  @override
  String get fertFormSticks => 'Bastoncini';

  @override
  String get fertFormSolublePowder => 'Polvere solubile';

  @override
  String get fertFormFoliar => 'Fogliare';

  @override
  String get fertFormOther => 'Altro';

  @override
  String get fertOrigin => 'Origine';

  @override
  String get fertOriginMineral => 'Minerale';

  @override
  String get fertOriginOrganic => 'Organico';

  @override
  String get fertOriginOrganomineral => 'Organo-minerale';

  @override
  String get fertNpk => 'NPK';

  @override
  String get fertNpkPercent => 'NPK (%)';

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
  String get noInventorySubtitle => 'Concimi, terricci, vasi, attrezzi…';

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
      'Scansionato, questo codice apre la scheda della pianta.';

  @override
  String get scan => 'Scansiona';

  @override
  String get quickActionScan => 'Scansionare un\'etichetta';

  @override
  String get scanHint => 'Inquadra il codice QR di una pianta.';

  @override
  String get unknownQr => 'Codice QR sconosciuto.';

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
  String get identifyTitle => 'Specie';

  @override
  String get identifyHint => 'Suggerimenti di specie, da confermare';

  @override
  String get searchOnline => 'Cerca online';

  @override
  String get identifyAnotherPhoto => 'Aggiungi una foto';

  @override
  String get identifyAnotherPhotoHint =>
      'Una foglia, un fiore o la pianta intera aiuta a precisare.';

  @override
  String get identifyConfirmWithPhoto => 'Conferma con una foto';

  @override
  String get searchingOnline => 'Ricerca online…';

  @override
  String get suggestionsLocal => 'Trovato sul tuo dispositivo, senza rete';

  @override
  String get suggestionsRemote => 'Proposto online da Pl@ntNet';

  @override
  String identifyOnDevice(String name) {
    return 'Riconosciuta da $name sul dispositivo. Scegliete la specie';
  }

  @override
  String get identifyViaPlantNet =>
      'Riconosciuta online da Pl@ntNet. Scegliete la specie';

  @override
  String get identifyPhotoSource =>
      'Foto da Pl@ntNet e GBIF. Toccane una per aprire la scheda della specie.';

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
  String identificationHint(String name) {
    return 'Riconoscimento delle specie sul dispositivo da parte di $name, senza rete. In caso di dubbio, la foto può essere inviata a Pl@ntNet.';
  }

  @override
  String get identificationEnabled => 'Identificazione attiva';

  @override
  String get identificationDisabled => 'Non configurata';

  @override
  String get identificationFallback => 'Fallback online';

  @override
  String identificationFallbackHint(String name) {
    return 'In caso di dubbio di $name, la foto viene inviata a Pl@ntNet. Disattivato, tutto resta sul dispositivo.';
  }

  @override
  String get irisFeedback => 'Invio delle foto identificate';

  @override
  String irisFeedbackHint(String name) {
    return 'Le foto scattate per identificare e il nome scelto vengono inviati appena una pianta viene nominata, e addestrano le prossime versioni del modello $name. Sono leggibili solo dall\'account che le invia, e la sua eliminazione le cancella. Disattivato, non lasciano il dispositivo.';
  }

  @override
  String get irisFeedbackNeedsAccount =>
      'Serve un account per inviare le foto.';

  @override
  String get irisFeedbackAskTitle => 'Invio delle foto identificate';

  @override
  String irisFeedbackAskBody(String name) {
    return 'Le foto scattate per identificare e il nome scelto possono essere inviati per addestrare le prossime versioni del modello $name. Sono leggibili solo dall\'account che le invia, e la sua eliminazione le cancella. La scelta si cambia nelle impostazioni di identificazione.';
  }

  @override
  String get genusUncertainSpecies => 'Specie incerta';

  @override
  String modelMissing(String name) {
    return '$name non disponibile su questo dispositivo';
  }

  @override
  String get modelLoading => 'Caricamento del modello…';

  @override
  String identificationStats(int local, int accepted, int remote) {
    return '$local analizzate sul dispositivo, $accepted decise qui; $remote inviate online';
  }

  @override
  String onlineSearchesMonth(int used, int limit) {
    return '$used ricerche online su $limit questo mese.';
  }

  @override
  String get irisSection => 'Il modello a bordo';

  @override
  String get irisTagline =>
      'Riconoscimento delle specie sul telefono, senza rete né account.';

  @override
  String get irisSpeciesLabel => 'specie';

  @override
  String get irisOfflineValue => 'offline';

  @override
  String get irisOfflineLabel => 'anche in aereo';

  @override
  String get irisTwoPhotosTitle => 'Due foto valgono più di una';

  @override
  String irisTwoPhotosBody(String name) {
    return 'La pianta intera, poi una foglia da vicino. Con due foto, $name trova la specie giusta due volte su tre, invece di una su due.';
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
  String get outdoorHint =>
      'Balcone, giardino o serra: il meteo viene considerato.';

  @override
  String get weather => 'Meteo';

  @override
  String get weatherHint =>
      'Per le piante all\'aperto: la pioggia caduta vale come annaffiatura, quella prevista la rinvia, e gelo e caldo vengono segnalati. Dati Open-Meteo, senza account né chiave.';

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
  String get weatherRainTitle => 'Pioggia oggi';

  @override
  String weatherRainSkip(String names) {
    return 'L\'irrigazione di $names può aspettare.';
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
      'Un file ZIP con piante, cronologia, inventario, impostazioni e foto.';

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
    return '$name: scorta bassa.';
  }

  @override
  String notifLowStockMany(int count) {
    return '$count articoli con scorta bassa.';
  }

  @override
  String get accountTitle => 'Account';

  @override
  String get signIn => 'Accedi';

  @override
  String get signInWithAppleId => 'Con il tuo ID Apple';

  @override
  String get signInHint =>
      'Un account salva i dati, li sincronizza tra dispositivi e permette di condividere un giardino.';

  @override
  String get continueWithApple => 'Continua con Apple';

  @override
  String get continueWithGoogle => 'Continua con Google';

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
  String syncUnknownColumns(String columns) {
    return 'Colonne sconosciute al server: $columns';
  }

  @override
  String get syncSyncing => 'Sincronizzazione…';

  @override
  String get authError => 'Accesso non riuscito. Riprova tra un momento.';

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
      'La persona deve già avere un account Auxine con questo indirizzo.';

  @override
  String get roleOwner => 'Proprietario';

  @override
  String get roleMember => 'Membro';

  @override
  String get roleViewer => 'Sola lettura';

  @override
  String get invited => 'Invito inviato';

  @override
  String get inviteError => 'Questo indirizzo non ha ancora un account.';

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
  String get diagnosisTitle => 'Diagnosi';

  @override
  String get diagnosisHint =>
      'Fotografate foglie, fusto o terra da più angolazioni. I risultati sono indicativi.';

  @override
  String get diagnosisSymptomsHint => 'Cosa hai notato (facoltativo)…';

  @override
  String get diagnosisChecks => 'Osservazioni';

  @override
  String get diagnosisChecksHint =>
      'Facoltativo: ciò che la foto non mostra affina l\'analisi.';

  @override
  String get diagnosisSoil => 'Terra';

  @override
  String get diagnosisSoilDry => 'Asciutta';

  @override
  String get diagnosisSoilMoist => 'Umida';

  @override
  String get diagnosisSoilSoggy => 'Fradicia';

  @override
  String get diagnosisRoots => 'Radici';

  @override
  String get diagnosisRootsFirm => 'Sode e chiare';

  @override
  String get diagnosisRootsSoft => 'Brune o molli';

  @override
  String get diagnosisRootsCrowded => 'Strette';

  @override
  String get diagnosisLightDirect => 'Sole diretto';

  @override
  String get diagnosisLightBright => 'Viva, senza sole diretto';

  @override
  String get diagnosisLightDim => 'Scarsa';

  @override
  String get diagnosisBugs => 'Insetti';

  @override
  String get diagnosisBugsNone => 'Nessuno visto';

  @override
  String get diagnosisBugsOnPlant => 'Sulla pianta';

  @override
  String get diagnosisBugsInSoil => 'Nella terra';

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
      'La diagnosi non è disponibile al momento. Riprova più tardi.';

  @override
  String get possibleCauses => 'Cause possibili';

  @override
  String get causesHint => 'Ordinate per verosimiglianza, da confermare.';

  @override
  String get likelihoodLikely => 'Probabile';

  @override
  String get likelihoodPossible => 'Possibile';

  @override
  String get likelihoodUnlikely => 'Poco probabile';

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
      'Le foto sono analizzate da un modello ospitato in Svizzera (AI Services di Infomaniak). Vengono inviate solo quando avvii un\'analisi e non vengono conservate.';

  @override
  String get diagnosisEnabled => 'Diagnosi attiva';

  @override
  String get diagnosisUnavailable => 'Diagnosi non disponibile';

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
  String get diagnosisEntry => 'Diagnosi';

  @override
  String get diagnosisOpen => 'Vedere la diagnosi completa';

  @override
  String get diagnosisSymptomsNoted => 'Sintomi segnalati';

  @override
  String diagnosisMoreCauses(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count altre piste',
      one: '1 altra pista',
    );
    return '$_temp0';
  }

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
  String get taskTitleHint => 'Titolo';

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
      'Semine, pulizia della serra, ordine di terriccio…';

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
    return 'Da fare: $title';
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
  String get careSupport => 'Tutore';

  @override
  String get careSupportMossPole => 'Tutore di muschio';

  @override
  String get careSupportStake => 'Tutore diritto';

  @override
  String get careSupportTrellis => 'Traliccio';

  @override
  String get careSupportMossPoleCare =>
      'Inumidire il tutore a ogni annaffiatura: le radici aeree vi si attaccano.';

  @override
  String get careSupportStakeCare =>
      'Legare il fusto senza stringere, man mano che sale.';

  @override
  String get careSupportTrellisCare => 'Guidare i fusti man mano che crescono.';

  @override
  String get careIssues => 'Da tenere d\'occhio';

  @override
  String get careKnownProblems => 'Problemi noti su questa pianta';

  @override
  String get careKnownProblemsNote =>
      'Segnalati su questa specie o su specie affini.';

  @override
  String get careLeafSigns => 'Segni sulle foglie';

  @override
  String get careLeafSignsNote =>
      'Ciò che una foglia mostra, e ciò che lo spiega più spesso.';

  @override
  String get leafSignPaling => 'Foglie che schiariscono';

  @override
  String get leafSignYellowing => 'Foglie gialle';

  @override
  String get leafSignScorched => 'Foglie bruciate';

  @override
  String get leafSignSpots => 'Macchie al centro della foglia';

  @override
  String get leafSignBrownTips => 'Punte e bordi marroni';

  @override
  String get leafSignStunted => 'Foglie che non crescono più';

  @override
  String get leafSignDrooping => 'Foglie molli';

  @override
  String get leafSignFalling => 'Foglie che cadono';

  @override
  String get leafSignSticky => 'Foglie appiccicose';

  @override
  String get leafCauseTooMuchSun => 'Troppo sole diretto';

  @override
  String get leafCauseNotEnoughLight => 'Luce insufficiente';

  @override
  String get leafCauseOverwatering => 'Annaffiature troppo ravvicinate';

  @override
  String get leafCauseUnderwatering => 'Terriccio rimasto secco troppo a lungo';

  @override
  String get leafCauseDryAir => 'Aria troppo secca';

  @override
  String get leafCauseColdDraught => 'Freddo o corrente d\'aria';

  @override
  String get leafCauseHardWater =>
      'Acqua calcarea o concime troppo concentrato';

  @override
  String get leafCausePoorSoil => 'Terriccio esaurito';

  @override
  String get leafCausePotBound => 'Radici strette nel vaso';

  @override
  String get leafCauseDamagedRoots => 'Radici rovinate dal ristagno d\'acqua';

  @override
  String get leafCauseLeafPests => 'Punture di ragnetto rosso o tripidi';

  @override
  String get leafCauseHoneydewPests =>
      'Cocciniglie o afidi, sulla pianta o sopra di essa';

  @override
  String get leafCauseSootyMould =>
      'Fumaggine, il nero che cresce sulla melata';

  @override
  String get leafCauseLeafFungus => 'Fungo o batterio sulla foglia';

  @override
  String get leafCauseWetLeaves => 'Acqua rimasta sul fogliame';

  @override
  String get leafCauseRecentMove => 'Spostamento o rinvaso recente';

  @override
  String get leafCauseOldLeaves => 'Invecchiamento delle foglie basse';

  @override
  String get leafCauseWinterRest => 'Riposo invernale';

  @override
  String get problemKindDisorder => 'Disturbo';

  @override
  String get problemKindPest => 'Parassita';

  @override
  String get problemKindDisease => 'Malattia';

  @override
  String get problemKindCondition => 'Affezione';

  @override
  String get problemKindDisorders => 'Disturbi';

  @override
  String get problemKindPests => 'Parassiti';

  @override
  String get problemKindDiseases => 'Malattie';

  @override
  String get problemKindConditions => 'Affezioni';

  @override
  String get careTips => 'Consigli';

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
  String get careDryDownAlwaysMoist => 'Terriccio sempre umido';

  @override
  String get careDryDownSurfaceDry => 'Lasciare asciugare la superficie';

  @override
  String get careDryDownTopQuarterDry =>
      'Lasciare asciugare il quarto superiore';

  @override
  String get careDryDownHalfDry => 'Lasciare asciugare a metà';

  @override
  String get careDryDownMostlyDry => 'Lasciare asciugare quasi del tutto';

  @override
  String get careDryDownFullyDry => 'Lasciare asciugare completamente';

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
  String get careRepotNone => 'Nessun rinvaso (coltura annuale)';

  @override
  String get carePotSnug => 'Ama stare stretta';

  @override
  String get carePotRoomy => 'Ama lo spazio';

  @override
  String get carePotSnugNote =>
      'Una radice che esce dal foro non basta: rinvasa quando il pane di terra è un blocco di radici, o quando l\'acqua non penetra più.';

  @override
  String get carePotSteadyNote =>
      'Rinvasa quando le radici escono dal foro e girano sul fondo del vaso.';

  @override
  String get carePotRoomyNote =>
      'Rinvasa appena le radici toccano la parete: stretta, smette di crescere.';

  @override
  String get carePotDormantNote =>
      'Il rinvaso si fa alla ripresa, alla fine del riposo, non per una radice che esce.';

  @override
  String careTempIdeal(int min, int max) {
    return 'Da $min a $max °C';
  }

  @override
  String careTempMin(int min) {
    return 'Non sotto $min °C';
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
  String careLightLamp(int min, int max, int hours) {
    return 'Sotto lampada · LED a spettro completo, da $min a $max µmol/m²/s, $hours h al giorno';
  }

  @override
  String careLightLampDli(int min, int max) {
    return 'Ossia da $min a $max mol/m²/giorno sul fogliame.';
  }

  @override
  String get careHumidityLow => 'Aria secca va bene';

  @override
  String get careHumidityAverage => 'Umidità normale';

  @override
  String get careHumidityHigh => 'Ama l\'aria umida';

  @override
  String careHumidityRange(int min, int max) {
    return 'Da $min a $max % di umidità dell\'aria';
  }

  @override
  String get careHumidityLowDetail =>
      'Tollera bene l\'aria secca di casa. Un\'umidità stabilmente più alta la rovina.';

  @override
  String get careHumidityAverageDetail =>
      'L\'aria normale di casa le basta. D\'inverno lontano dal calorifero, le punte delle foglie restano verdi.';

  @override
  String get careHumidityHighDetail =>
      'L\'aria secca di una casa riscaldata la danneggia: l\'aria va mantenuta umida.';

  @override
  String get careHumidityMethodMist => 'Nebulizzare le foglie le fa bene.';

  @override
  String get careHumidityMethodHumidifier => 'Un umidificatore d\'aria.';

  @override
  String get careHumidityMethodTray =>
      'Un sottovaso di argilla espansa umida, o più piante raggruppate.';

  @override
  String get careHumidityMethodTerrarium =>
      'Sotto vetro: terrario, campana o barattolo.';

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
  String get careToxicityFromSpecies => 'Verificata per questa specie';

  @override
  String careToxicityFromGenus(String name) {
    return 'Genere $name · non verificata per questa specie';
  }

  @override
  String careToxicityFromFamily(String name) {
    return 'Famiglia $name · non verificata per questa specie';
  }

  @override
  String careToxicitySource(String name) {
    return 'Fonte: $name';
  }

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
  String get careSoilNone => 'Senza substrato';

  @override
  String get careGrowthMedium => 'Ambiente di crescita';

  @override
  String get careMediumTerrestrial => 'Terrestre';

  @override
  String get careMediumEpiphytic => 'Epifita';

  @override
  String get careMediumLithophytic => 'Litofita';

  @override
  String get careMediumAquatic => 'Acquatica';

  @override
  String get careMediumSemiAquatic => 'Semi-acquatica';

  @override
  String get careMediumTerrestrialNote => 'Cresce in terra.';

  @override
  String get careMediumEpiphyticNote =>
      'Cresce su un supporto, senza terriccio: corteccia, sfagno o niente.';

  @override
  String get careMediumLithophyticNote =>
      'Cresce sulla pietra, con le radici nelle fessure.';

  @override
  String get careMediumAquaticNote => 'Le sue radici vivono nell\'acqua.';

  @override
  String get careMediumSemiAquaticNote =>
      'Vive in terreno intriso, a bordo dell\'acqua.';

  @override
  String get careWater => 'Acqua';

  @override
  String get careWaterTolerant => 'Acqua del rubinetto';

  @override
  String get careWaterSensitive => 'Acqua povera di calcare';

  @override
  String get careWaterStrict => 'Acqua senza calcare';

  @override
  String get careWaterTolerantNote => 'Il calcare non la disturba.';

  @override
  String get careWaterSensitiveNote => 'Il calcare fa imbrunire le punte.';

  @override
  String get careWaterFluorideSensitive =>
      'Il fluoro dell\'acqua di rete fa imbrunire le punte: acqua piovana o osmosi.';

  @override
  String get careWaterStrictNote =>
      'Il calcare la danneggia, anche in piccole quantità.';

  @override
  String get careWaterTypes => 'Tipi di acqua';

  @override
  String get careWaterTypesNote =>
      'La durezza dell\'acqua del rubinetto cambia da un comune all\'altro; l\'analisi annuale del gestore la indica.';

  @override
  String get careWaterBest => 'Consigliata';

  @override
  String get careWaterOk => 'Adatta';

  @override
  String get careWaterCaution => 'Con riserva';

  @override
  String get careWaterAvoid => 'Da evitare';

  @override
  String get careWaterTap => 'Acqua del rubinetto';

  @override
  String get careWaterTapNote =>
      'L\'acqua di rete, così come esce. La sua durezza dipende dal comune.';

  @override
  String get careWaterTapRisk =>
      'Il calcare si accumula nel terriccio e ne alza il pH. Lasciare riposare l\'acqua elimina il cloro, non il calcare.';

  @override
  String get careWaterRain => 'Acqua di pioggia';

  @override
  String get careWaterRainNote => 'Dolce, senza calcare, leggermente acida.';

  @override
  String get careWaterRainRisk =>
      'Raccolta da un tetto, porta con sé polvere ed escrementi; una riserva all\'aperto diventa verde. Lasciare scorrere i primi minuti di pioggia e coprire il bidone.';

  @override
  String get careWaterFiltered => 'Acqua filtrata';

  @override
  String get careWaterFilteredNote =>
      'Una caraffa filtrante toglie il cloro e una parte del calcare.';

  @override
  String get careWaterFilteredRisk =>
      'Quanto trattiene dipende dalla cartuccia, e una cartuccia esaurita non trattiene più nulla. Il calcare non se ne va mai del tutto.';

  @override
  String get careWaterOsmosis => 'Acqua osmotizzata';

  @override
  String get careWaterOsmosisNote =>
      'Quasi priva di minerali, come l\'acqua di pioggia.';

  @override
  String get careWaterOsmosisRisk =>
      'Non porta alcun nutriente: il fertilizzante resta l\'unica fonte. Per una pianta comune, un terzo di acqua del rubinetto la riequilibra.';

  @override
  String get careWaterDemineralized => 'Acqua demineralizzata';

  @override
  String get careWaterDemineralizedNote =>
      'Venduta per i ferri da stiro, vale l\'acqua osmotizzata quando è pura.';

  @override
  String get careWaterDemineralizedRisk =>
      'Alcune taniche contengono un anticalcare o un profumo: leggere l\'etichetta. Come l\'acqua osmotizzata, non porta alcun nutriente.';

  @override
  String get careWaterCondensate => 'Acqua del climatizzatore';

  @override
  String get careWaterCondensateNote =>
      'La condensa di un climatizzatore o di un deumidificatore, distillata dall\'apparecchio.';

  @override
  String get careWaterCondensateRisk =>
      'È scorsa su uno scambiatore e in una vasca dove si accumulano polvere, biofilm e batteri, e può portare tracce di metalli. Da riservare alle piante ornamentali, da un apparecchio pulito, mai su ciò che si mangia.';

  @override
  String get careWaterSoftened => 'Acqua addolcita';

  @override
  String get careWaterSoftenedNote =>
      'Un addolcitore a resine sostituisce il calcare con il sodio.';

  @override
  String get careWaterSoftenedRisk =>
      'Il sodio si accumula nel terriccio, danneggia le radici e chiude la struttura del suolo. Il rubinetto di acqua grezza, a monte dell\'addolcitore, resta quello giusto.';

  @override
  String get careSoilMixStandard =>
      'Alleggerito con il 20 % di perlite, perché l\'acqua scorra.';

  @override
  String get careSoilMixDraining =>
      '50 % di terriccio, 25 % di perlite, 25 % di sabbia grossa o lapillo.';

  @override
  String get careSoilMixCactus =>
      '30 % di terriccio, 70 % di lapillo, pomice o sabbia grossa.';

  @override
  String get careSoilMixOrchid =>
      'Bark di pino medio, 10 % di perlite, un po\' di sfagno; mai terriccio.';

  @override
  String get careSoilMixAcidic =>
      'Alleggerita con il 25 % di corteccia di pino, senza calcare né compost.';

  @override
  String get careSoilMixRich =>
      '40 % di terriccio, 40 % di compost, 20 % di perlite.';

  @override
  String get careSoilMixNone =>
      'Nessun substrato: le radici vivono all\'aria o nell\'acqua.';

  @override
  String careSoilFree(String water, String pon) {
    return 'In acqua: $water · In pon: $pon';
  }

  @override
  String get careSoilFreeYes => 'sì';

  @override
  String get careSoilFreeNo => 'no';

  @override
  String get careSoilFreeCuttings => 'solo talee';

  @override
  String get careFertBalanced =>
      'Concime equilibrato per piante verdi, diluito a metà.';

  @override
  String get careFertFoliage => 'Concime ricco di azoto, quello del fogliame.';

  @override
  String get careFertFlowering =>
      'Concime ricco di potassio, quello della fioritura.';

  @override
  String get careFertCactus => 'Concime per cactus, povero di azoto.';

  @override
  String get careFertOrchid => 'Concime per orchidee, molto diluito.';

  @override
  String get careFertAcidic => 'Concime per piante acidofile, senza calcare.';

  @override
  String get careFertCitrus =>
      'Concime per agrumi, ricco di azoto e microelementi.';

  @override
  String get careFertVegetable => 'Concime per pomodori, ricco di potassio.';

  @override
  String get careCalciumAvoid =>
      'Calcio: nessun apporto e acqua piovana; il calcare le ingiallisce le foglie.';

  @override
  String get careCalciumWelcome =>
      'Calcio: l\'acqua dura le va bene, come i gusci d\'uovo tritati al rinvaso.';

  @override
  String get careCalciumNeeded =>
      'Calcio: un apporto regolare evita il marciume apicale.';

  @override
  String get careGreenhouse => 'In serra';

  @override
  String get careGreenhouseWarmHumid => 'Calore e aria umida';

  @override
  String get careGreenhouseWarmLight => 'Calore e luce';

  @override
  String get careGreenhouseWarmDry => 'Calore, luce e aria secca';

  @override
  String get careGreenhouseGrowth =>
      'Mantenute tutto l\'anno, queste condizioni accelerano la crescita: irrigazione e concime si avvicinano altrettanto.';

  @override
  String get careGreenhouseHold =>
      'Mantieni l\'intervallo di umidità di giorno, lascialo scendere di notte e fai circolare l\'aria.';

  @override
  String get careGreenhouseAir =>
      'Arieggiare ogni giorno: l\'aria ferma fa marcire ciò che ama l\'asciutto.';

  @override
  String get careGreenhouseEarly =>
      'In serra fredda o sotto cassone, le semine partono con quattro-sei settimane di anticipo.';

  @override
  String get careBloom => 'Fioritura';

  @override
  String careSeasonRange(String from, String to) {
    return 'Da $from a $to';
  }

  @override
  String get careBloomOutdoors => 'Raramente in casa';

  @override
  String get careBloomChillBulb => 'Freddo al bulbo';

  @override
  String get careBloomChillBulbNote =>
      'Conta da dieci a quindici settimane tra 5 e 9 °C al buio, prima di riportare il vaso al caldo e alla luce.';

  @override
  String get careBloomFertilizer => 'Un concime da fioritura';

  @override
  String get careBloomFertilizerNote =>
      'Appena si formano i boccioli, passa a un concime da fioritura, più ricco di potassio di quello per il fogliame.';

  @override
  String get careBloomMaturity => 'Un po\' di età';

  @override
  String get careBloomMaturityNote =>
      'Fiorisce solo dai tre o quattro anni: prima di quell\'età nessuna condizione cambia le cose.';

  @override
  String get careBloomDeadhead => 'Fiori appassiti tagliati';

  @override
  String get careBloomDeadheadNote =>
      'Taglia i fiori appassiti man mano: la pianta rimette energia nei successivi.';

  @override
  String get careBloomKeepSpike => 'Uno stelo tenuto';

  @override
  String get careBloomKeepSpikeNote =>
      'Finché lo stelo resta verde, lascialo: può rifiorire da una gemma più in basso.';

  @override
  String get careBloomNoMove => 'Un posto fisso';

  @override
  String get careBloomNoMoveNote =>
      'Una volta formati i boccioli, non spostarla e non girarla: il cambiamento li fa cadere.';

  @override
  String get careBloomEvenWater => 'Annaffiature regolari';

  @override
  String get careBloomEvenWaterNote =>
      'Durante la formazione dei boccioli annaffia regolarmente: basta un colpo di secco per farli cadere.';

  @override
  String get careRest => 'Riposo';

  @override
  String careRestStoreDarkTemp(int min, int max) {
    return 'All\'asciutto e al buio, tra $min e $max °C';
  }

  @override
  String careRestStoreTemp(int min, int max) {
    return 'All\'asciutto, tra $min e $max °C';
  }

  @override
  String get careRestStoreDark => 'All\'asciutto e al buio';

  @override
  String get careRestStorePlain => 'All\'asciutto';

  @override
  String get careRestNote =>
      'Lascia ingiallire e seccare il fogliame senza tagliarlo, poi sospendi le annaffiature. Alla fine di questo periodo rimetti il vaso alla luce e riprendi ad annaffiare.';

  @override
  String get careBloomCoolRest => 'Un inverno fresco';

  @override
  String get careBloomCoolRestNote =>
      'Per preparare la fioritura, tienila per circa due mesi tra 10 e 12 °C e riduci molto le annaffiature.';

  @override
  String get careBloomCoolNights => 'Notti fresche';

  @override
  String get careBloomCoolNightsNote =>
      'In autunno, circa tre settimane con notti intorno ai 15 °C possono stimolare lo stelo fiorale.';

  @override
  String get careBloomShortDays => 'Giorni corti';

  @override
  String get careBloomShortDaysNote =>
      'Per circa sei settimane, garantisci almeno 12 ore di buio continuo ogni notte per favorire la formazione dei boccioli.';

  @override
  String get careBloomDrySpell => 'Un periodo secco';

  @override
  String get careBloomDrySpellNote =>
      'Riduci molto le annaffiature per alcune settimane, poi riprendile gradualmente: questo contrasto può stimolare la fioritura.';

  @override
  String get careBloomPotbound => 'Un vaso stretto';

  @override
  String get careBloomPotboundNote =>
      'Spesso fiorisce meglio quando le radici occupano bene il vaso. Evita quindi di rinvasare troppo presto.';

  @override
  String get careBloomBrightLight => 'Più luce';

  @override
  String get careBloomBrightLightNote =>
      'Per fiorire ha bisogno di più luce che per crescere. Sistemala in un luogo molto luminoso, evitando il sole troppo forte.';

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
      'Valori indicativi, da adattare a luce, vaso e aria ambiente.';

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
  String get careIssueOverwatering => 'Troppa acqua (foglie molli e gialle)';

  @override
  String get careIssueUnderwatering => 'Poca acqua (foglie cadenti)';

  @override
  String get careIssueRootRot => 'Marciume radicale';

  @override
  String get careIssueSpiderMites => 'Ragnetto rosso (ragnatele sottili)';

  @override
  String get careIssueThrips => 'Tripidi (foglie argentate)';

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
  String get careIssueTrueBugs => 'Cimici';

  @override
  String get careIssueSlugs => 'Lumache';

  @override
  String get careIssuePowderyMildew => 'Oidio';

  @override
  String get careIssueGreyMould => 'Muffa grigia (Botrytis)';

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
  String get careIssueChlorosis => 'Clorosi (foglie pallide, nervature verdi)';

  @override
  String get careIssueBlossomEndRot => 'Marciume apicale';

  @override
  String get careTipFingerTest =>
      'Infila un dito e annaffia quando i primi 2 cm sono asciutti.';

  @override
  String get careTipDrySoilFirst =>
      'Lascia asciugare completamente il terriccio tra un\'annaffiatura e l\'altra.';

  @override
  String get careTipNeverDryOut =>
      'Non lasciare mai asciugare del tutto il terriccio.';

  @override
  String get careTipEvenWatering =>
      'Annaffia con regolarità, perché gli sbalzi spaccano i frutti.';

  @override
  String get careTipWaterAtBase =>
      'Annaffia alla base, senza bagnare le foglie.';

  @override
  String get careTipNoWaterOnLeaves =>
      'Non bagnare le foglie, perché l\'acqua ferma le macchia.';

  @override
  String get careTipBottomWatering =>
      'Annaffia dal basso, mettendo il vaso in acqua per 20 minuti.';

  @override
  String get careTipThirstyPlant =>
      'Beve molto, in estate controllala ogni giorno.';

  @override
  String get careTipDroopSignal => 'Quando si affloscia, ha sete.';

  @override
  String get careTipWinterDry => 'In inverno tienila quasi all\'asciutto.';

  @override
  String get careTipWinterRest => 'In inverno riposa e vuole molta meno acqua.';

  @override
  String get careTipSummerDormant =>
      'Riposa in estate e in quel periodo vuole pochissima acqua.';

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
      'Dopo il bagno asciugala capovolta, perché l\'acqua nel cuore la fa marcire.';

  @override
  String get careTipWaterInTheCup =>
      'Riempi la rosetta centrale e cambia l\'acqua ogni settimana.';

  @override
  String get careTipNoSoil => 'Vive senza terra, appoggiata su un supporto.';

  @override
  String get careTipGreenRoots =>
      'Le radici verdi indicano che è idratata, quelle argentate che è ora di annaffiare.';

  @override
  String get careTipHumidityTray => 'Metti il vaso su argilla espansa umida.';

  @override
  String get careTipNoDirectSun =>
      'Evita il sole diretto, che brucia le foglie.';

  @override
  String get careTipToleratesLowLight =>
      'Tollera una stanza poco luminosa, ma cresce più in fretta vicino a una finestra.';

  @override
  String get careTipToleratesNeglect =>
      'Perdona le dimenticanze, quindi nel dubbio non annaffiare.';

  @override
  String get careTipBrightForColor => 'Più luce, più i colori sono intensi.';

  @override
  String get careTipRotatePot =>
      'Ruota il vaso di un quarto ogni settimana perché cresca dritta.';

  @override
  String get careTipHatesMoving =>
      'Trovale un posto e lasciala lì, odia essere spostata.';

  @override
  String get careTipWipeLeaves =>
      'Pulisci le foglie perché respirino e catturino meglio la luce.';

  @override
  String get careTipTrimToBushOut =>
      'Accorcia gli steli lunghi e si ramificherà.';

  @override
  String get careTipMonsteraSupport =>
      'Dalle un tutore di muschio e le foglie diventeranno più grandi e incise.';

  @override
  String get careTipShallowPot => 'Un vaso largo e basso le si addice di più.';

  @override
  String get careTipLikesBeingPotbound =>
      'Fiorisce meglio se stretta, quindi rinvasa di rado.';

  @override
  String get careTipTrunkStoresWater =>
      'Il piede rigonfio immagazzina acqua, quindi meglio poca che troppa.';

  @override
  String get careTipPupsToShare =>
      'Fa polloni, staccali per moltiplicare o regalare.';

  @override
  String get careTipKeepFlowerSpike =>
      'Non tagliare lo stelo verde, perché può rifiorire.';

  @override
  String get careTipDarkForRebloom =>
      'Per rifiorire, dalle sei settimane di notti lunghe e fresche.';

  @override
  String get careTipNotADesertCactus =>
      'Non è un cactus del deserto, ama ombra e umidità.';

  @override
  String get careTipDeadheadFlowers =>
      'Togli i fiori appassiti e fiorirà più a lungo.';

  @override
  String get careTipPinchFlowers =>
      'Elimina i boccioli per mantenere tenere le foglie.';

  @override
  String get careTipHarvestTop =>
      'Raccogli dall\'alto, sopra una coppia di foglie.';

  @override
  String get careTipHarvestOutside =>
      'Raccogli le foglie esterne e il cuore continuerà a crescere.';

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
      'Bastano due potature l\'anno, a giugno e a fine agosto.';

  @override
  String get careTipContainItsRoots =>
      'Invade tutto, coltivala in vaso o metti una barriera.';

  @override
  String get careTipMulchIt =>
      'Pacciama la base per annaffiare meno e limitare le erbacce.';

  @override
  String get careTipAcidSoil =>
      'Richiede terra acida, non terriccio universale.';

  @override
  String get careTipFeedsOnInsects =>
      'Si nutre di insetti: niente fertilizzante e un terreno povero.';

  @override
  String get careTipBlueNeedsAcid =>
      'I fiori blu richiedono terreno acido; nel calcare diventano rosa.';

  @override
  String get careTipCitrusFertilizer =>
      'Usa un concime per agrumi per tutta la bella stagione.';

  @override
  String get careTipNoFertilizer =>
      'Niente concime, un terreno troppo ricco le toglie profumo e portamento.';

  @override
  String get careTipNoNitrogen =>
      'Evita il concime azotato, se lo produce da sola.';

  @override
  String get careTipLetFoliageDieBack =>
      'Lascia ingiallire il fogliame, perché ricarica il bulbo.';

  @override
  String get careTipDiesBackInWinter =>
      'Scompare in inverno e riparte in primavera, è normale.';

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
      'Preferisce il fresco, tienila lontana dai termosifoni.';

  @override
  String get careTipHardyOutdoors =>
      'Rustica, sverna all\'aperto senza protezione.';

  @override
  String get careTipShelterFromWind =>
      'Mettila al riparo dal vento, perché il fogliame si rovina in fretta.';

  @override
  String get careTipAirFlow =>
      'Fai circolare l\'aria, perché l\'aria ferma favorisce le malattie.';

  @override
  String get careTipSpiderMiteWatch =>
      'Controlla sotto le foglie, dove si annida il ragnetto rosso.';

  @override
  String get careTipSlugWatch =>
      'Proteggi i germogli dalle lumache in primavera.';

  @override
  String get careTipBoxMothWatch =>
      'Attenzione alla piralide, i bruchi lasciano fili di seta nel fogliame.';

  @override
  String get careTipSapIrritant =>
      'La linfa irrita pelle e occhi, quindi pota con i guanti.';

  @override
  String get careTipVeryToxic =>
      'Ogni sua parte è molto tossica, anche il fumo se bruciata.';

  @override
  String get careTipSharpSpines =>
      'Le sue punte sono pericolose, tienila lontana dai passaggi.';

  @override
  String get careTipSplitsAreNormal =>
      'Le foglie si fendono con l\'età, è normale e non una malattia.';

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
  String get fieldTemplatesHint => 'Campi riutilizzabili su più piante.';

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
  String get photoUrlInvalid => 'L\'indirizzo deve iniziare con https://';

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
  String get searchByNumberHint => 'Digita #42 per trovare la pianta n. 42.';

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
      'Gli articoli non vengono eliminati, passano al gruppo scelto.';

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
  String get noGroupsYet => 'Nessun gruppo.';

  @override
  String get deleteGroupExplain =>
      'Gli articoli non vengono eliminati, perdono il gruppo.';

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
      'Gli eventi non vengono eliminati, perdono la categoria.';

  @override
  String get noEventCategoriesYet => 'Nessuna categoria.';

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
  String get statOldest => 'Più vecchia';

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
  String get noWarnings => 'Niente da segnalare.';

  @override
  String get recentPlantsSection => 'Piante recenti';

  @override
  String get recentAdded => 'Aggiunte';

  @override
  String get recentUpdated => 'Modificate';

  @override
  String get activityLogTitle => 'Registro attività';

  @override
  String get activityEmpty => 'Nessuna attività.';

  @override
  String get activityPlantAdded => 'Aggiunta al giardino';

  @override
  String get activityPlantArchived => 'Archiviata';

  @override
  String get activityLocationNote => 'Nota di posizione';

  @override
  String get activityTaskDone => 'Attività completata';

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
  String get backupExplain => 'Un file .zip con i dati e le foto.';

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
  String get importErrorNotAZip => 'Questo file non è un backup Auxine.';

  @override
  String get importErrorWrongApp => 'Questo backup proviene da un\'altra app.';

  @override
  String get importErrorTooRecent =>
      'Questo backup proviene da una versione più recente di Auxine.';

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
  String get onbTodayTitle => 'Le cure del giorno';

  @override
  String get onbTodayBody => 'Un tocco per registrare ogni cura.';

  @override
  String get onbCareTitle => 'Meno annaffiature d\'inverno';

  @override
  String get onbCareBody => 'Gli intervalli si adattano alla stagione.';

  @override
  String get onbGardenTitle => 'Stanze, foto, calendario';

  @override
  String get onbGardenBody =>
      'Ogni annaffiatura, ogni rinvaso è datato e archiviato con la pianta.';

  @override
  String onbIrisTitle(String name) {
    return '$name riconosce le tue piante offline';
  }

  @override
  String get onbIrisBody =>
      'Pianta sconosciuta a Iris: la ricerca continua online.';

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
  String get whatsNewTitle => 'Novità';

  @override
  String get whatsNewModelUpdate => 'Aggiornamento del modello';

  @override
  String get whatsNewIrisIntro =>
      'Il modello integrato è stato riaddestrato: più specie, meno errori, sempre senza rete.';

  @override
  String whatsNewIrisSpeciesTitle(String count) {
    return '$count specie riconosciute';
  }

  @override
  String get whatsNewIrisSpeciesBody =>
      'Piante d\'interno più rare si aggiungono al catalogo.';

  @override
  String get whatsNewIrisOfflineTitle => 'Sempre sul dispositivo';

  @override
  String get whatsNewIrisOfflineBody =>
      'Il riconoscimento resta locale: niente esce senza il tuo consenso, e il ripiego online si disattiva con un interruttore.';

  @override
  String get whatsNewIrisDoubtTitle => 'Dubbio segnalato';

  @override
  String get whatsNewIrisDoubtBody =>
      'Due specie che si somigliano: vengono proposte entrambe.';

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
  String get privacyPolicy => 'Informativa sulla privacy';

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
  String get supportTitle => 'Auxine è gratuita';

  @override
  String get supportBody =>
      'Tutte le funzioni sono accessibili. Nessun abbonamento, nessuna pubblicità, nessun account obbligatorio.';

  @override
  String get supportOffer =>
      'Se desiderate comunque aiutare lo sviluppatore, basta un acquisto unico.';

  @override
  String get supportOnce => 'Una sola volta';

  @override
  String supportGive(String price) {
    return 'Sostieni · $price';
  }

  @override
  String get supportRestore => 'Ripristina il mio sostegno';

  @override
  String get supportThanksTitle => 'Grazie';

  @override
  String get supportThanksBody => 'Il vostro sostegno è stato registrato.';

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
  String get supportNoThanks => 'No grazie';

  @override
  String get emptyGardenSubtitle => 'Aggiungete la prima pianta.';

  @override
  String get finderTitle => 'Trovare una pianta';

  @override
  String get finderEntryHint => 'Aiuto nella scelta';

  @override
  String get finderStepSpot => 'Posizione';

  @override
  String get finderStepSpotHint => 'La luce è il criterio principale.';

  @override
  String get finderSpotBright => 'Stanza luminosa';

  @override
  String get finderSpotMedium => 'Luce media';

  @override
  String get finderSpotDark => 'Angolo buio';

  @override
  String get finderSpotOutdoor => 'Fuori, balcone o giardino';

  @override
  String get finderStepEffort => 'Quanta cura?';

  @override
  String get finderStepEffortHint => 'Quanto spesso potete annaffiare.';

  @override
  String get finderEffortForgiving => 'Irrigazione occasionale';

  @override
  String get finderEffortNormal => 'Irrigazione regolare';

  @override
  String get finderEffortAttentive => 'Cura frequente';

  @override
  String get finderStepSafety => 'Animali o bambini?';

  @override
  String get finderStepSafetyHint =>
      'Molte piante da appartamento sono tossiche se masticate.';

  @override
  String get finderSafetyYes => 'Sì, solo non tossiche';

  @override
  String get finderSafetyNo => 'Nessun vincolo';

  @override
  String get finderNote => 'Dettagli';

  @override
  String get finderNoteHint =>
      'Un bagno senza finestre, un gatto che mordicchia tutto…';

  @override
  String get finderResults => 'Proposte';

  @override
  String get finderEmptyTitle => 'Nessun risultato';

  @override
  String get finderEmptySubtitle =>
      'Nessuna specie del catalogo corrisponde a tutti i criteri. Modificate una risposta o ampliate i tipi di pianta.';

  @override
  String get finderRestart => 'Ricomincia';

  @override
  String get finderAdd => 'Aggiungi al giardino';

  @override
  String get finderAskAi => 'Chiedi all\'IA';

  @override
  String get finderAiSection => 'Proposte dell\'IA';

  @override
  String get finderAiHint =>
      'Fuori catalogo, da verificare prima di acquistare.';

  @override
  String get finderAiError => 'Nessuna proposta dall\'IA.';

  @override
  String get finderReasonLight => 'Ama questa luce';

  @override
  String get finderReasonLowLight => 'Tollera l\'ombra';

  @override
  String get finderReasonForgiving => 'Tollera le dimenticanze';

  @override
  String get finderReasonEasy => 'Facile';

  @override
  String get finderReasonSafe => 'Non tossica';

  @override
  String get finderReasonOutdoor => 'Sta bene all\'aperto';

  @override
  String get finderAnyAnswer => 'Non importa';

  @override
  String finderQuestionOf(int n, int total) {
    return 'Domanda $n di $total';
  }

  @override
  String get finderSpotBrightHint => 'Vicino a una finestra, molta luce';

  @override
  String get finderSpotMediumHint => 'A qualche passo da una finestra';

  @override
  String get finderSpotDarkHint => 'Lontano dalle finestre, poca luce';

  @override
  String get finderSpotOutdoorHint => 'Balcone, terrazzo o giardino';

  @override
  String get finderEffortForgivingHint =>
      'Una pianta che tollera le dimenticanze';

  @override
  String get finderEffortNormalHint => 'Circa un\'annaffiatura a settimana';

  @override
  String get finderEffortAttentiveHint =>
      'Nebulizzazione, rinvaso, controlli regolari';

  @override
  String get finderSafetyYesHint => 'Solo specie non tossiche';

  @override
  String get finderSafetyNoHint => 'Tutte le specie, anche tossiche';

  @override
  String get finderTopPick => 'Prima scelta';

  @override
  String get finderAlternatives => 'Altre proposte';

  @override
  String get finderChangeAnswer => 'Cambia questa risposta';

  @override
  String get finderChipSpotAny => 'Posto: indifferente';

  @override
  String get finderChipEffortAny => 'Cura: indifferente';

  @override
  String get finderChipSafe => 'Senza rischi';

  @override
  String finderFactWater(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Acqua ogni $count g',
      one: 'Acqua ogni giorno',
    );
    return '$_temp0';
  }

  @override
  String get finderAiTitle => 'Andare oltre';

  @override
  String get finderAiBody =>
      'Ricerca oltre il catalogo, partendo dalle sue risposte e da ciò che aggiunge qui.';

  @override
  String get finderPhotoSource =>
      'Foto: osservazioni GBIF, con licenza libera.';

  @override
  String get onbWelcomeTitle => 'Benvenuto in Auxine';

  @override
  String get onbWelcomeBody => 'Il diario di cura delle vostre piante.';

  @override
  String get careMatchAssisted => 'Completata dall\'IA';

  @override
  String get careAssistedNote =>
      'Specie assente dal catalogo: questi riferimenti vengono dall\'IA. È stato inviato solo il nome scientifico. La tossicità non è indicata.';

  @override
  String get careMatchEdited => 'Scheda modificata';

  @override
  String get careEditedNote =>
      'Scheda corretta a mano; il resto viene dal catalogo.';

  @override
  String get careStudio => 'Care Studio';

  @override
  String get careStudioHint =>
      'Correggi una scheda di cura. La modifica vale su questo dispositivo.';

  @override
  String get careStudioSearch => 'Cerca una specie';

  @override
  String get careStudioPrompt =>
      'Cerca una specie per correggere la sua scheda.';

  @override
  String get careStudioEmpty => 'Nessuna specie corrisponde.';

  @override
  String get careStudioWateringSummer => 'Annaffiatura, stagione piena';

  @override
  String get careStudioWateringWinter => 'Annaffiatura, inverno';

  @override
  String get careStudioDamageBelow => 'Non sotto';

  @override
  String get careStudioSave => 'Salva';

  @override
  String get careStudioSaved => 'Modifica salvata';

  @override
  String get careStudioReset => 'Torna al catalogo';

  @override
  String get careAssistSetting => 'Completa le schede con l\'IA';

  @override
  String get careAssistHint =>
      'Per una specie assente dal catalogo, il nome scientifico viene inviato all\'IA per completare la scheda. Nient\'altro lascia il dispositivo. La risposta viene conservata.';

  @override
  String get gardensTitle => 'I miei giardini';

  @override
  String get gardensHint =>
      'Il giardino aperto è quello mostrato ovunque nell\'app. Il passaggio dall\'uno all\'altro avviene qui.';

  @override
  String get gardenMine => 'Il mio giardino';

  @override
  String get gardenUnnamed => 'Giardino condiviso';

  @override
  String gardenSharedBy(String name) {
    return 'Condiviso da $name';
  }

  @override
  String gardenOpened(String name) {
    return 'Giardino: $name';
  }

  @override
  String get someone => 'qualcuno';

  @override
  String memberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count membri',
      one: '1 membro',
    );
    return '$_temp0';
  }

  @override
  String get renameGarden => 'Rinomina il giardino';

  @override
  String get renameGardenHint => 'Nome visibile alle persone invitate.';

  @override
  String get gardenNameHint => 'Il giardino di casa';

  @override
  String get joinGarden => 'Unirsi a un giardino';

  @override
  String get joinGardenHint =>
      'Inserite il codice ricevuto, o aprite il link d\'invito.';

  @override
  String get inviteCodeHint => 'Codice d\'invito';

  @override
  String get joinLook => 'Vedi l\'invito';

  @override
  String get joinConfirm => 'Unisciti';

  @override
  String get joinInvalid =>
      'Questo codice non vale più. Già usato, scaduto o inesistente.';

  @override
  String get joinWrongEmail =>
      'Questo invito è riservato a un altro indirizzo e-mail.';

  @override
  String get joinNeedsAccount => 'Serve un account per unirsi a un giardino.';

  @override
  String get joinSignInHint => 'Accesso con il vostro ID Apple.';

  @override
  String joinInvitedBy(String name, String garden) {
    return '$name vi invita in «$garden»';
  }

  @override
  String joinGardenName(String garden) {
    return 'Invito in «$garden»';
  }

  @override
  String get joinAsMember => 'Aggiunta, modifica ed eliminazione di piante.';

  @override
  String get joinAsViewer => 'Sola consultazione, senza modifiche.';

  @override
  String get joinAlreadyMember => 'Fate già parte di questo giardino.';

  @override
  String joined(String name) {
    return 'Giardino «$name» aggiunto';
  }

  @override
  String get leaveGarden => 'Lascia questo giardino';

  @override
  String leaveGardenConfirm(String name) {
    return 'Non avrete più accesso a «$name».';
  }

  @override
  String leftGarden(String name) {
    return 'Avete lasciato «$name»';
  }

  @override
  String get deleteGarden => 'Elimina il giardino';

  @override
  String deleteGardenConfirm(String name) {
    return 'Il giardino «$name», le sue piante e la sua cronologia saranno eliminati, per voi e per le persone invitate.';
  }

  @override
  String gardenDeleted(String name) {
    return 'Giardino «$name» eliminato';
  }

  @override
  String get deleteGardenLast => 'Un account conserva almeno un giardino.';

  @override
  String get openGardenTitle => 'I vostri giardini';

  @override
  String get openGardenHint =>
      'Questo account dà accesso a questi giardini. Aprite quello con le vostre piante.';

  @override
  String get collaborationNeedsAccount =>
      'Per condividere un giardino serve un account';

  @override
  String get inviteSomeone => 'Invita qualcuno';

  @override
  String get inviteReady => 'Invito pronto';

  @override
  String get inviteRoleHint =>
      'Membro: aggiunge, modifica ed elimina piante. Lettore: sola consultazione.';

  @override
  String get inviteEmailOptional => 'Indirizzo e-mail (facoltativo)';

  @override
  String get inviteEmailHint =>
      'Se indicato, solo questo indirizzo potrà accettare l\'invito.';

  @override
  String get inviteCreate => 'Crea l\'invito';

  @override
  String get inviteShareHint =>
      'Inviate questo link o codice. L\'app non è necessaria per riceverlo.';

  @override
  String get inviteShare => 'Condividi il link';

  @override
  String inviteMessage(String link) {
    return 'Invito a unirvi al mio giardino su Auxine: $link';
  }

  @override
  String get inviteOnceHint => 'Un invito vale una volta sola.';

  @override
  String inviteExpires(String date) {
    return 'Scade il $date';
  }

  @override
  String get inviteFailed => 'Impossibile creare l\'invito.';

  @override
  String get invitesTitle => 'Inviti in sospeso';

  @override
  String get inviteRevoke => 'Revoca';

  @override
  String get inviteRevokeConfirm => 'Il codice non funzionerà più.';

  @override
  String get inviteRevoked => 'Invito revocato';

  @override
  String get membersHint =>
      'I membri vedono le stesse piante e possono prendersene cura.';

  @override
  String get membersGuestHint => 'Giardino condiviso da un altro utente.';

  @override
  String get memberRoleHint =>
      'Membro: aggiunge, modifica ed elimina piante. Lettore: sola consultazione.';

  @override
  String makeRole(String role) {
    return 'Passa a «$role»';
  }

  @override
  String roleChanged(String name, String role) {
    return '$name ora è «$role»';
  }

  @override
  String removeMemberConfirm(String name) {
    return '$name perderà l\'accesso a questo giardino.';
  }

  @override
  String get photoFirstTitle => 'Prima foto';

  @override
  String get photoNextTitle => 'Nuova foto';

  @override
  String get photoFirstHint => 'Sarà la foto principale.';

  @override
  String get photoFrameHint =>
      'Mantieni la stessa inquadratura ogni volta per seguire la crescita.';

  @override
  String get photoGhostToggle => 'Sovrapponi l\'ultima foto';

  @override
  String get photoGhostHint => 'Allinea la pianta alla foto in trasparenza.';

  @override
  String get photoTitleStepTitle => 'Titolo';

  @override
  String get photoTitleStepSubtitle => 'Facoltativo.';

  @override
  String get photoTagNewLeaf => 'Foglia nuova';

  @override
  String get photoTagFlowering => 'Fioritura';

  @override
  String get photoTagBeforeRepotting => 'Prima del rinvaso';

  @override
  String get photoTagAfterRepotting => 'Dopo il rinvaso';

  @override
  String get photoTagCutting => 'Talea';

  @override
  String get photoTagAfterPruning => 'Dopo la potatura';

  @override
  String get mainPhotoHint => 'Mostrata nella scheda e nella lista.';

  @override
  String get retake => 'Rifai';

  @override
  String get growthEmptySubtitle =>
      'Aggiungete foto regolarmente per seguire la crescita.';

  @override
  String growthSummary(int count, String since) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count foto · da $since',
      one: '1 foto · da $since',
    );
    return '$_temp0';
  }

  @override
  String growthNudge(String date) {
    return 'Ultima foto il $date.';
  }

  @override
  String get timelapse => 'Timelapse';

  @override
  String get beforeAfter => 'Prima / dopo';

  @override
  String photoCounter(int index, int total) {
    return '$index / $total';
  }

  @override
  String get photoTitleShort => 'Titolo';

  @override
  String get mainPhotoShort => 'Principale';

  @override
  String get share => 'Condividi';

  @override
  String get addTitle => 'Aggiungi un titolo';

  @override
  String get swap => 'Inverti';

  @override
  String get pause => 'Pausa';

  @override
  String get stepPhotoDoneTitle => 'Anteprima';

  @override
  String stepPhotoDoneSubtitle(String name) {
    return 'Una foglia da vicino aiuta $name a riconoscere la specie.';
  }

  @override
  String get stepPhotoDonePlain => 'Potrai aggiungerne altre dalla sua scheda.';

  @override
  String get viewPlant => 'La pianta';

  @override
  String get viewLeafClose => 'Una foglia da vicino';

  @override
  String get viewAnother => 'Altra vista';

  @override
  String viewForModel(String name) {
    return 'Usata da $name per riconoscere la specie, non conservata.';
  }

  @override
  String get strategyWeather => 'Meteo';

  @override
  String get strategyWeatherHint =>
      'L\'intervallo della stagione, accorciato dal caldo secco, allungato da pioggia e freddo.';

  @override
  String strategyWeatherNow(String interval) {
    return 'Con il tempo di questa settimana: $interval';
  }

  @override
  String get strategyWeatherNoPlace =>
      'Senza un luogo meteo, l\'intervallo resta quello della stagione.';

  @override
  String get weatherWhenTonight => 'stanotte';

  @override
  String get weatherWhenToday => 'oggi';

  @override
  String get weatherWhenTomorrow => 'domani';

  @override
  String weatherWhenInDays(int count) {
    return 'tra $count giorni';
  }

  @override
  String weatherFrostTitle(String when, String temp) {
    return 'Gelo $when · $temp';
  }

  @override
  String weatherHeatTitle(String when, String temp) {
    return 'Caldo $when · $temp';
  }

  @override
  String weatherFrostBody(String names) {
    return 'Da riparare o coprire: $names.';
  }

  @override
  String weatherHeatBody(String names) {
    return 'Da spostare all\'ombra e annaffiare presto: $names.';
  }

  @override
  String weatherAlertMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'e altre $count',
      one: 'e 1 altra',
    );
    return '$_temp0';
  }

  @override
  String weatherAlertFamily(String name) {
    return 'la famiglia $name';
  }

  @override
  String notifFrost(String when, String names) {
    return 'Gelo $when · da riparare o coprire: $names.';
  }

  @override
  String notifHeat(String when, String names) {
    return 'Caldo $when · da spostare all\'ombra: $names.';
  }

  @override
  String weatherRainFallenTitle(String mm) {
    return 'Pioggia · $mm mm';
  }

  @override
  String weatherRainWatered(String names) {
    return 'Annaffiatura registrata per $names.';
  }

  @override
  String weatherRainWaterable(String names) {
    return 'La pioggia vale l\'annaffiatura di $names.';
  }

  @override
  String get weatherRainMarkWatered => 'Segna annaffiata';

  @override
  String weatherRainWateredToast(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count annaffiature registrate',
      one: '1 annaffiatura registrata',
    );
    return '$_temp0';
  }

  @override
  String weatherRainNote(String mm) {
    return 'Annaffiata dalla pioggia ($mm mm).';
  }

  @override
  String get weatherRainCounts => 'La pioggia vale come annaffiatura';

  @override
  String get weatherRainCountsHint =>
      'Oltre 5 mm in tre giorni, l\'annaffiatura dei luoghi esterni viene registrata come fatta. Disattivato, la schermata del mattino la propone con un tocco. Un vaso riparato dalle foglie riceve meno pioggia.';

  @override
  String get weatherClimate => 'Clima';

  @override
  String get weatherClimateHint =>
      'Le proposte di piante per l\'esterno seguono gli inverni e le estati del luogo.';

  @override
  String weatherClimateZone(String zone) {
    return 'Zona $zone';
  }

  @override
  String weatherClimateRange(String low, String high) {
    return 'Inverni a $low, estati a $high';
  }

  @override
  String get weatherClimateNone => 'Sconosciuto';

  @override
  String get finderReasonHardy => 'Sverna all\'aperto qui';

  @override
  String get finderReasonSheltered => 'Sverna all\'aperto, riparata';

  @override
  String finderRegion(String zone, String low) {
    return 'Zona $zone · inverni a $low';
  }

  @override
  String get encyclopediaTitle => 'Enciclopedia';

  @override
  String get encyclopediaHint =>
      'I problemi della base, le specie del catalogo e il vocabolario delle schede di cura.';

  @override
  String get encyclopediaProblems => 'Problemi';

  @override
  String get encyclopediaSpecies => 'Specie';

  @override
  String get encyclopediaGlossary => 'Vocabolario';

  @override
  String get encyclopediaSearchProblems => 'Nome, parassita, malattia…';

  @override
  String get encyclopediaSearchGlossary => 'Luce, substrato, talea…';

  @override
  String encyclopediaProblemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count problemi',
      one: '1 problema',
      zero: 'Nessun problema',
    );
    return '$_temp0';
  }

  @override
  String encyclopediaSpeciesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count specie',
      one: '1 specie',
      zero: 'Nessuna specie',
    );
    return '$_temp0';
  }

  @override
  String get encyclopediaNoTerm => 'Nessun termine trovato';

  @override
  String problemNumber(String id) {
    return 'Voce $id';
  }

  @override
  String get problemScope => 'Estensione';

  @override
  String get problemScopeGeneral => 'Tutte le piante';

  @override
  String get problemScopeWide => 'Molti ospiti';

  @override
  String get problemScopeTarget => 'Ospiti specifici';

  @override
  String get problemScopeGeneralNote =>
      'Possibile sulle piante vascolari, secondo le condizioni e lo stadio.';

  @override
  String get problemScopeWideNote => 'Molti ospiti; i taxa citati sono esempi.';

  @override
  String get problemScopeTargetNote =>
      'Ospiti principali di un gruppo mirato; l\'elenco non è esaustivo.';

  @override
  String get problemHosts => 'Ospiti';

  @override
  String get problemHostsAll => 'Tutte le piante vascolari';

  @override
  String get problemHostsNote =>
      'Un genere o una famiglia non rende sensibili tutte le sue specie.';

  @override
  String get problemInGarden => 'Nel giardino';

  @override
  String get problemKindsTitle => 'Famiglie di problemi';

  @override
  String get problemKindDisorderNote =>
      'Né parassita né malattia: l\'acqua, la luce, il freddo, il substrato, una carenza.';

  @override
  String get problemKindPestNote =>
      'Un essere vivente che attacca la pianta: insetto, acaro, lumaca, nematode.';

  @override
  String get problemKindDiseaseNote =>
      'Un fungo, un batterio, un virus o un fitoplasma insediato nella pianta.';

  @override
  String get problemKindConditionNote =>
      'Né l\'uno né l\'altro: la fumaggine cresce sulla melata, senza attaccare la pianta.';

  @override
  String get careLightShadeNote =>
      'Lontano dalle finestre, senza raggio diretto durante il giorno.';

  @override
  String get careLightLowNote =>
      'Una stanza chiara ma lontana dalla finestra, o esposta a nord.';

  @override
  String get careLightIndirectNote =>
      'A qualche passo da una finestra, o dietro una tenda leggera.';

  @override
  String get careLightBrightNote =>
      'Vicino a una finestra, fuori dal raggio del sole.';

  @override
  String get careLightSomeNote =>
      'Il sole del mattino o di fine giornata, non quello di mezzogiorno.';

  @override
  String get careLightFullNote =>
      'Sei ore di sole diretto o più, in piena giornata.';

  @override
  String get careHumidityLowNote => 'L\'aria di una casa riscaldata le basta.';

  @override
  String get careHumidityAverageNote =>
      'Intorno al 50%, lontano dal termosifone d\'inverno.';

  @override
  String get careHumidityHighNote =>
      'Oltre il 60%: bagno, cucina o un vassoio di argilla espansa umida.';

  @override
  String get careDifficultyEasyNote =>
      'Sopporta le dimenticanze e i cambi di luce.';

  @override
  String get careDifficultyMediumNote =>
      'Richiede un ritmo di irrigazione regolare e una posizione stabile.';

  @override
  String get careDifficultyDemandingNote =>
      'Luce, umidità e irrigazione vanno seguite da vicino.';

  @override
  String get careToxicSafeNote =>
      'Nessuna tossicità nota per animali e bambini.';

  @override
  String get careToxicMildNote => 'La linfa irrita la pelle e la bocca.';

  @override
  String get careToxicToxicNote =>
      'Ingerire una foglia o un frutto provoca malessere.';

  @override
  String get careToxicUnknownNote =>
      'Per questa specie non è indicato nulla; tenerla fuori portata per precauzione.';

  @override
  String get careSoilStandardNote =>
      'Il terriccio da piante verdi, senza aggiunte.';

  @override
  String get careSoilDrainingNote =>
      'Terriccio alleggerito con perlite, sabbia o pomice.';

  @override
  String get careSoilCactusNote =>
      'Molto minerale: l\'acqua passa senza ristagnare.';

  @override
  String get careSoilOrchidNote =>
      'Corteccia grossa: le radici vivono all\'aria.';

  @override
  String get careSoilAcidicNote =>
      'Un pH acido, per le piante che il calcare ingiallisce.';

  @override
  String get careSoilRichNote =>
      'Terriccio arricchito di compost, per le piante esigenti.';

  @override
  String get careSoilNoneNote =>
      'Le radici stanno nell\'acqua, o su un supporto senza terra.';

  @override
  String get carePropCuttingNote =>
      'Un fusto tagliato sotto un nodo, messo in substrato umido.';

  @override
  String get carePropLeafNote =>
      'Una foglia intera, o un frammento, posata sul substrato.';

  @override
  String get carePropDivisionNote =>
      'Il cespo si divide in due al rinvaso, radici comprese.';

  @override
  String get carePropOffsetsNote =>
      'I germogli nati alla base si staccano una volta radicati.';

  @override
  String get carePropLayeringNote =>
      'Un fusto radicato mentre è ancora attaccato alla pianta madre.';

  @override
  String get carePropSeedNote =>
      'Semi seminati, più lenti di una talea e spesso meno fedeli.';

  @override
  String get carePropWaterNote =>
      'La talea resta in un bicchiere d\'acqua finché partono le radici.';

  @override
  String get carePropTuberNote =>
      'Il tubero si taglia in pezzi, ciascuno con una gemma.';

  @override
  String get communityTipsTitle => 'Consigli della comunità';

  @override
  String get communityTipsHint =>
      'Ciò che altre persone hanno osservato coltivando questa specie, fuori dal catalogo.';

  @override
  String get communityTipsEmpty => 'Nessun consiglio su questa specie.';

  @override
  String get offlineCommunityTips =>
      'Leggere e pubblicare consigli richiede una connessione.';

  @override
  String get communityTipWrite => 'Scrivere un consiglio';

  @override
  String get communityTipYours => 'Il tuo consiglio';

  @override
  String get communityTipPlaceholder =>
      'Ciò che ha funzionato su questa pianta, in poche frasi.';

  @override
  String get communityTipPublicNote =>
      'Il consiglio appare con il tuo nome sulla scheda di questa specie, per tutti.';

  @override
  String communityTipLength(int used, int max) {
    return '$used / $max';
  }

  @override
  String get communityTipPublish => 'Pubblica';

  @override
  String get communityTipPublished => 'Consiglio pubblicato.';

  @override
  String get communityTipNeedsAccount =>
      'Pubblicare un consiglio richiede un account.';

  @override
  String get communityTipAnonymous => 'Anonimo';

  @override
  String get communityTipHelpful => 'Utile';

  @override
  String get communityTipReport => 'Segnala';

  @override
  String get communityTipReported => 'Consiglio segnalato.';

  @override
  String communityTipReportNote(int count) {
    return 'Un consiglio segnalato da $count persone non appare più.';
  }

  @override
  String get communityTipHidden => 'Segnalato: gli altri non lo vedono più.';

  @override
  String get confirmDeleteTip => 'Eliminare questo consiglio?';

  @override
  String get confirmReportTip => 'Segnalare questo consiglio?';

  @override
  String get moderationTitle => 'Moderazione';

  @override
  String get moderationHint =>
      'I consigli segnalati, dal più segnalato al meno segnalato.';

  @override
  String get moderationEmpty => 'Nessun consiglio segnalato.';

  @override
  String moderationReports(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count segnalazioni',
      one: '1 segnalazione',
    );
    return '$_temp0';
  }

  @override
  String get moderationHide => 'Nascondi';

  @override
  String get moderationRestore => 'Ripristina';

  @override
  String get confirmRestoreTip =>
      'Ripristinare questo consiglio? Le sue segnalazioni vengono cancellate.';
}
