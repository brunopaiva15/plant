// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Flora';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Annuler';

  @override
  String get save => 'Enregistrer';

  @override
  String get done => 'Terminé';

  @override
  String get continueLabel => 'Continuer';

  @override
  String get back => 'Retour';

  @override
  String get delete => 'Supprimer';

  @override
  String get edit => 'Modifier';

  @override
  String get add => 'Ajouter';

  @override
  String get search => 'Rechercher';

  @override
  String get close => 'Fermer';

  @override
  String get undo => 'Annuler';

  @override
  String get later => 'Plus tard';

  @override
  String get skip => 'Passer';

  @override
  String get next => 'Suivant';

  @override
  String get retry => 'Réessayer';

  @override
  String get more => 'Plus';

  @override
  String get seeAll => 'Tout voir';

  @override
  String get optional => 'facultatif';

  @override
  String get none => 'Aucun';

  @override
  String get genericError => 'Quelque chose n\'a pas fonctionné. Réessayez.';

  @override
  String get tabToday => 'Aujourd\'hui';

  @override
  String get tabPlants => 'Plantes';

  @override
  String get tabGarden => 'Jardin';

  @override
  String get tabProfile => 'Profil';

  @override
  String greeting(String name) {
    return 'Bonjour $name';
  }

  @override
  String get greetingAnonymous => 'Bonjour';

  @override
  String careCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count soins',
      one: '1 soin',
      zero: 'Aucun soin',
    );
    return '$_temp0';
  }

  @override
  String get sectionOverdue => 'En retard';

  @override
  String get sectionToday => 'Aujourd\'hui';

  @override
  String get sectionUpcoming => 'À venir';

  @override
  String get allDoneTitle => 'Tout est en ordre';

  @override
  String get allDoneSubtitle =>
      'Vos plantes n\'ont besoin de rien aujourd\'hui.';

  @override
  String get emptyGardenTitle => 'Votre jardin commence ici.';

  @override
  String get addFirstPlant => 'Ajouter ma première plante';

  @override
  String get yourGarden => 'Votre jardin';

  @override
  String get recentPhotos => 'Photos récentes';

  @override
  String plantCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count plantes',
      one: '1 plante',
      zero: 'Aucune plante',
    );
    return '$_temp0';
  }

  @override
  String get kindWatering => 'Arrosage';

  @override
  String get kindFertilizing => 'Engrais';

  @override
  String get kindRepotting => 'Rempotage';

  @override
  String get kindPruning => 'Taille';

  @override
  String get kindCleaning => 'Nettoyage';

  @override
  String get kindTreatment => 'Traitement';

  @override
  String get kindMeasurement => 'Mesure';

  @override
  String get kindPhoto => 'Photo';

  @override
  String get kindNote => 'Note';

  @override
  String get verbWatering => 'Arroser';

  @override
  String get verbFertilizing => 'Fertiliser';

  @override
  String get verbRepotting => 'Rempoter';

  @override
  String get verbPruning => 'Tailler';

  @override
  String get verbCleaning => 'Nettoyer';

  @override
  String get verbTreatment => 'Traiter';

  @override
  String get verbMeasurement => 'Mesurer';

  @override
  String get verbPhoto => 'Photo';

  @override
  String get verbNote => 'Note';

  @override
  String get doneWatering => 'Arrosée';

  @override
  String get doneFertilizing => 'Fertilisée';

  @override
  String get doneRepotting => 'Rempotée';

  @override
  String get donePruning => 'Taillée';

  @override
  String get doneCleaning => 'Nettoyée';

  @override
  String get doneTreatment => 'Traitée';

  @override
  String get doneMeasurement => 'Mesurée';

  @override
  String get donePhoto => 'Photo ajoutée';

  @override
  String get doneNote => 'Note ajoutée';

  @override
  String get doneCustom => 'Fait';

  @override
  String actionDoneToast(String plant, String action) {
    return '$plant · $action';
  }

  @override
  String multiActionDone(int count, String action) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count plantes · $action',
      one: '1 plante · $action',
    );
    return '$_temp0';
  }

  @override
  String get dueToday => 'Aujourd\'hui';

  @override
  String get dueTomorrow => 'Demain';

  @override
  String dueInDays(int count) {
    return 'Dans $count jours';
  }

  @override
  String dueOverdue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'En retard de $count jours',
      one: 'En retard d\'un jour',
    );
    return '$_temp0';
  }

  @override
  String get dueNone => 'Sans rappel';

  @override
  String careDueLabel(String action, String when) {
    return '$action · $when';
  }

  @override
  String verbToday(String verb) {
    return '$verb aujourd\'hui';
  }

  @override
  String get plantsTitle => 'Plantes';

  @override
  String get searchPlants => 'Nom, espèce, emplacement…';

  @override
  String get filters => 'Filtres';

  @override
  String get sortBy => 'Trier par';

  @override
  String get sortName => 'Nom';

  @override
  String get sortNextCare => 'Prochain soin';

  @override
  String get sortRecent => 'Ajout récent';

  @override
  String get filterLocation => 'Emplacement';

  @override
  String get filterNeedsAttention => 'À soigner';

  @override
  String get filterFavorites => 'Favoris';

  @override
  String get filterTag => 'Tag';

  @override
  String get clearFilters => 'Effacer les filtres';

  @override
  String get gridView => 'Grille';

  @override
  String get listView => 'Liste';

  @override
  String get noResultsTitle => 'Aucun résultat';

  @override
  String get noResultsSubtitle => 'Essayez un autre mot.';

  @override
  String get emptyPlantsTitle => 'Aucune plante';

  @override
  String get emptyPlantsSubtitle => 'Votre jardin commence ici.';

  @override
  String get addPlant => 'Ajouter une plante';

  @override
  String selectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sélectionnées',
      one: '1 sélectionnée',
    );
    return '$_temp0';
  }

  @override
  String get select => 'Sélectionner';

  @override
  String get move => 'Déplacer';

  @override
  String get archive => 'Archiver';

  @override
  String get addTag => 'Ajouter un tag';

  @override
  String get favorite => 'Favori';

  @override
  String get unfavorite => 'Retirer des favoris';

  @override
  String movedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count plantes déplacées',
      one: '1 plante déplacée',
    );
    return '$_temp0';
  }

  @override
  String archivedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count plantes archivées',
      one: '1 plante archivée',
    );
    return '$_temp0';
  }

  @override
  String get newPlant => 'Nouvelle plante';

  @override
  String get stepPhotoTitle => 'Une photo ?';

  @override
  String get stepPhotoSubtitle => 'Elle deviendra le visage de votre plante.';

  @override
  String get takePhoto => 'Prendre une photo';

  @override
  String get choosePhoto => 'Choisir une photo';

  @override
  String get withoutPhoto => 'Continuer sans photo';

  @override
  String get changePhoto => 'Changer';

  @override
  String get stepNameTitle => 'Comment s\'appelle-t-elle ?';

  @override
  String get plantNameHint => 'Monstera du salon';

  @override
  String get speciesHint => 'Espèce (facultatif)';

  @override
  String get stepLocationTitle => 'Où se trouve-t-elle ?';

  @override
  String get newLocationChip => 'Nouveau';

  @override
  String get noLocation => 'Sans emplacement';

  @override
  String get finish => 'Terminer';

  @override
  String plantAdded(String name) {
    return '$name ajoutée';
  }

  @override
  String get moreOptions => 'Plus d\'options';

  @override
  String get acquiredAt => 'Date d\'acquisition';

  @override
  String get source => 'Provenance';

  @override
  String get sourceHint => 'Pépinière, bouture d\'un ami…';

  @override
  String get price => 'Prix';

  @override
  String get potSize => 'Diamètre du pot';

  @override
  String get notes => 'Notes';

  @override
  String get notesHint => 'Tout ce qui vous semble utile…';

  @override
  String get wateringEvery => 'Arrosage';

  @override
  String get fertilizingEvery => 'Engrais';

  @override
  String everyDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tous les $count jours',
      one: 'Tous les jours',
    );
    return '$_temp0';
  }

  @override
  String get freeLimitTitle => 'Limite atteinte';

  @override
  String freeLimitBody(int count) {
    return 'L\'offre gratuite permet $count plantes. Passez à Premium pour une collection illimitée.';
  }

  @override
  String sinceDate(String date) {
    return 'Depuis $date';
  }

  @override
  String get nextCare => 'Prochains soins';

  @override
  String get addAction => 'Ajouter une action';

  @override
  String get history => 'Historique';

  @override
  String get seeFullHistory => 'Tout l\'historique';

  @override
  String get growth => 'Croissance';

  @override
  String get photos => 'Photos';

  @override
  String get info => 'Informations';

  @override
  String get cuttings => 'Boutures';

  @override
  String get createCutting => 'Créer une bouture';

  @override
  String cuttingOf(String name) {
    return 'Bouture de $name';
  }

  @override
  String get parentPlant => 'Plante mère';

  @override
  String get schedule => 'Planning';

  @override
  String get editPlant => 'Modifier la plante';

  @override
  String get archivePlant => 'Archiver la plante';

  @override
  String get archiveReasonTitle => 'Que s\'est-il passé ?';

  @override
  String get reasonDied => 'Morte';

  @override
  String get reasonGiven => 'Donnée';

  @override
  String get reasonSold => 'Vendue';

  @override
  String get reasonOther => 'Autre';

  @override
  String plantArchived(String name) {
    return '$name archivée';
  }

  @override
  String get restore => 'Restaurer';

  @override
  String plantRestored(String name) {
    return '$name restaurée';
  }

  @override
  String get deleteForever => 'Supprimer définitivement';

  @override
  String get deleteForeverConfirm =>
      'Cette plante et tout son historique seront supprimés.';

  @override
  String get noHistoryTitle => 'Aucune action pour l\'instant';

  @override
  String get noHistorySubtitle => 'Chaque soin apparaîtra ici.';

  @override
  String get noPhotosTitle => 'Aucune photo';

  @override
  String get noPhotosSubtitle => 'Ajoutez une photo pour suivre sa croissance.';

  @override
  String get setAsPrimary => 'Photo principale';

  @override
  String get deletePhoto => 'Supprimer la photo';

  @override
  String get health => 'Santé';

  @override
  String get healthHealthy => 'En forme';

  @override
  String get healthWatch => 'À surveiller';

  @override
  String get healthSick => 'Malade';

  @override
  String get noSchedule => 'Aucun rappel';

  @override
  String get addRoutine => 'Ajouter une routine';

  @override
  String get frequency => 'Fréquence';

  @override
  String get strategyFixed => 'Fixe';

  @override
  String get strategySeasonal => 'Saisonnier';

  @override
  String get strategyManual => 'Manuel';

  @override
  String get strategySeasonalHint => 'Espacé en hiver, rapproché en été.';

  @override
  String get strategyManualHint => 'Aucun rappel automatique.';

  @override
  String get enabled => 'Activée';

  @override
  String get interval => 'Intervalle';

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours',
      one: '1 jour',
    );
    return '$_temp0';
  }

  @override
  String lastDone(String date) {
    return 'Dernier : $date';
  }

  @override
  String nextDue(String date) {
    return 'Prochain : $date';
  }

  @override
  String get deleteRoutine => 'Supprimer la routine';

  @override
  String get snooze => 'Plus tard';

  @override
  String snoozed(String name) {
    return '$name · reportée à demain';
  }

  @override
  String get measurements => 'Mesures';

  @override
  String measurementDelta(String delta, String date) {
    return '$delta depuis $date';
  }

  @override
  String get whatDidYouDo => 'Qu\'avez-vous fait ?';

  @override
  String get when => 'Quand';

  @override
  String get noteHint => 'Ajouter une note…';

  @override
  String get quantity => 'Quantité';

  @override
  String get value => 'Valeur';

  @override
  String get measureHeight => 'Hauteur';

  @override
  String get measureWidth => 'Largeur';

  @override
  String get measureLeaves => 'Feuilles';

  @override
  String get measurePot => 'Pot';

  @override
  String get record => 'Enregistrer';

  @override
  String get addNote => 'Ajouter une note';

  @override
  String get addPhoto => 'Ajouter une photo';

  @override
  String get camera => 'Appareil photo';

  @override
  String get gallery => 'Galerie';

  @override
  String get photoError => 'Impossible d\'ajouter la photo. Réessayez.';

  @override
  String get newActionType => 'Nouveau type d\'action';

  @override
  String get actionTypeLabel => 'Nom';

  @override
  String get actionTypeLabelHint => 'Brumisation';

  @override
  String get actionTypeEmoji => 'Emoji';

  @override
  String get actionTypes => 'Types d\'actions';

  @override
  String get actionTypesHint =>
      'Créez vos propres actions, en plus des types intégrés.';

  @override
  String get deleteActionType => 'Supprimer ce type';

  @override
  String get builtin => 'Intégré';

  @override
  String get gardenTitle => 'Jardin';

  @override
  String get locations => 'Emplacements';

  @override
  String get newLocationTitle => 'Nouvel emplacement';

  @override
  String get locationName => 'Nom';

  @override
  String get locationNameHint => 'Salon';

  @override
  String get locationIcon => 'Icône';

  @override
  String get parentLocation => 'Dans';

  @override
  String get noParent => 'Aucun';

  @override
  String get light => 'Lumière';

  @override
  String get lightLow => 'Faible';

  @override
  String get lightMedium => 'Moyenne';

  @override
  String get lightHigh => 'Forte';

  @override
  String get orientation => 'Orientation';

  @override
  String get orientationHint => 'Sud-ouest';

  @override
  String get deleteLocation => 'Supprimer l\'emplacement';

  @override
  String get deleteLocationHint => 'Les plantes ne seront pas supprimées.';

  @override
  String get noLocationsTitle => 'Aucun emplacement';

  @override
  String get noLocationsSubtitle => 'Créez un salon, un balcon, une serre…';

  @override
  String get editLocation => 'Modifier l\'emplacement';

  @override
  String get noPlantsHereTitle => 'Aucune plante ici';

  @override
  String get noPlantsHereSubtitle =>
      'Déplacez-y des plantes ou ajoutez-en une.';

  @override
  String get chooseLocation => 'Choisir un emplacement';

  @override
  String get defaultLivingRoom => 'Salon';

  @override
  String get defaultKitchen => 'Cuisine';

  @override
  String get defaultBedroom => 'Chambre';

  @override
  String get defaultBalcony => 'Balcon';

  @override
  String get defaultOffice => 'Bureau';

  @override
  String get defaultBathroom => 'Salle de bain';

  @override
  String get defaultGarden => 'Jardin';

  @override
  String get defaultGreenhouse => 'Serre';

  @override
  String get profileTitle => 'Profil';

  @override
  String get yourName => 'Votre prénom';

  @override
  String get yourNameHint => 'Prénom';

  @override
  String get appearance => 'Apparence';

  @override
  String get themeSystem => 'Système';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get reduceMotion => 'Réduire les animations';

  @override
  String get reduceMotionHint =>
      'Par défaut, Flora suit le réglage du système.';

  @override
  String get notifications => 'Notifications';

  @override
  String get enableNotifications => 'Rappel quotidien';

  @override
  String get notificationTime => 'Heure';

  @override
  String get quietDays => 'Jours silencieux';

  @override
  String get notificationPreview => 'Aperçu';

  @override
  String get notificationHint =>
      'Une seule notification par jour, uniquement quand une plante a besoin de vous.';

  @override
  String get notificationPermissionDenied =>
      'Autorisez les notifications dans les Réglages de votre téléphone.';

  @override
  String get archives => 'Anciennes plantes';

  @override
  String get noArchivesTitle => 'Aucune ancienne plante';

  @override
  String get noArchivesSubtitle => 'Les plantes archivées apparaîtront ici.';

  @override
  String archivedOn(String date) {
    return 'Archivée le $date';
  }

  @override
  String get units => 'Unités';

  @override
  String get metric => 'Métrique';

  @override
  String get imperial => 'Impérial';

  @override
  String get language => 'Langue';

  @override
  String get languageSystem => 'Système';

  @override
  String get account => 'Compte';

  @override
  String get localAccount => 'Données sur cet appareil';

  @override
  String get localAccountHint =>
      'Vos plantes et photos restent privées, sur ce téléphone. Les comptes et la synchronisation arriveront dans une prochaine version.';

  @override
  String get about => 'À propos';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String get premium => 'Premium';

  @override
  String get premiumBody =>
      'Plantes illimitées, identification, diagnostic, collaboration. Bientôt disponible.';

  @override
  String premiumPlantCount(int count, int limit) {
    return '$count / $limit plantes';
  }

  @override
  String get tags => 'Tags';

  @override
  String get newTag => 'Nouveau tag';

  @override
  String get tagNameHint => 'Tropicale, Rare, À surveiller…';

  @override
  String get noTags => 'Aucun tag';

  @override
  String get manageTags => 'Gérer les tags';

  @override
  String get onboardingTitle => 'Votre jardin, simplement.';

  @override
  String get onboardingSubtitle =>
      'Prenez soin de vos plantes et gardez leur histoire.';

  @override
  String get askNameTitle => 'Comment vous appelez-vous ?';

  @override
  String get askNameSubtitle =>
      'Pour vous saluer chaque matin. Vous pourrez changer plus tard.';

  @override
  String get notificationAskTitle => 'Un rappel utile, chaque jour';

  @override
  String get notificationAskBody =>
      'Une seule notification par jour, à l\'heure que vous choisissez, seulement quand une plante en a besoin.';

  @override
  String get enable => 'Activer';

  @override
  String get notNow => 'Pas maintenant';

  @override
  String get notificationTitle => 'Vos plantes';

  @override
  String get notificationChannel => 'Rappels d\'entretien';

  @override
  String notifWaterOne(String name) {
    return '$name a probablement besoin d\'eau aujourd\'hui.';
  }

  @override
  String notifWaterMany(String names) {
    return '$names ont probablement besoin d\'eau aujourd\'hui.';
  }

  @override
  String notifOther(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count autres soins vous attendent.',
      one: '1 autre soin vous attend.',
    );
    return '$_temp0';
  }

  @override
  String notifOnlyOther(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count soins vous attendent aujourd\'hui.',
      one: '1 soin vous attend aujourd\'hui.',
    );
    return '$_temp0';
  }

  @override
  String andJoin(String a, String b) {
    return '$a et $b';
  }

  @override
  String get listSeparator => ', ';

  @override
  String get timelineToday => 'Aujourd\'hui';

  @override
  String get timelineYesterday => 'Hier';

  @override
  String get photoAddedToast => 'Photo ajoutée';

  @override
  String get noteAddedToast => 'Note ajoutée';

  @override
  String get actionAddedToast => 'Action enregistrée';

  @override
  String locationCreated(String name) {
    return '$name créé';
  }

  @override
  String get saved => 'Enregistré';

  @override
  String get gardenLocations => 'Emplacements';

  @override
  String get gardenInventory => 'Inventaire';

  @override
  String get gardenCalendar => 'Calendrier';

  @override
  String get inventoryTitle => 'Inventaire';

  @override
  String get newItem => 'Nouvel article';

  @override
  String get editItem => 'Modifier l\'article';

  @override
  String get itemName => 'Nom';

  @override
  String get itemNameHint => 'Engrais plantes vertes';

  @override
  String get category => 'Catégorie';

  @override
  String get catFertilizer => 'Engrais';

  @override
  String get catSoil => 'Terreaux';

  @override
  String get catSubstrate => 'Substrats';

  @override
  String get catPot => 'Pots';

  @override
  String get catTool => 'Outils';

  @override
  String get catTreatment => 'Traitements';

  @override
  String get catSeed => 'Graines';

  @override
  String get catAccessory => 'Accessoires';

  @override
  String get unit => 'Unité';

  @override
  String get unitPieces => 'unités';

  @override
  String get lowThreshold => 'Seuil de stock bas';

  @override
  String get lowStock => 'Stock bas';

  @override
  String remaining(String amount) {
    return '$amount restants';
  }

  @override
  String get noInventoryTitle => 'Inventaire vide';

  @override
  String get noInventorySubtitle =>
      'Engrais, terreaux, pots, outils : gardez l\'œil sur vos réserves.';

  @override
  String get deleteItem => 'Supprimer l\'article';

  @override
  String lowStockItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count articles en stock bas',
      one: '1 article en stock bas',
    );
    return '$_temp0';
  }

  @override
  String get calendarTitle => 'Calendrier';

  @override
  String get agenda => 'Agenda';

  @override
  String get month => 'Mois';

  @override
  String get noEventsTitle => 'Rien de prévu';

  @override
  String get noEventsSubtitle => 'Les soins à venir apparaîtront ici.';

  @override
  String get projected => 'prévu';

  @override
  String get today => 'Aujourd\'hui';

  @override
  String get measurementsTitle => 'Mesures';

  @override
  String get addMeasurement => 'Ajouter une mesure';

  @override
  String sinceFirst(String delta, String date) {
    return '$delta depuis $date';
  }

  @override
  String get qrCode => 'QR code';

  @override
  String get qrHint =>
      'Collez-le sur le pot : le scanner ouvre directement la fiche.';

  @override
  String get scan => 'Scanner';

  @override
  String get scanHint => 'Visez le QR code d\'une plante.';

  @override
  String get unknownQr => 'Ce QR code n\'appartient pas à votre jardin.';

  @override
  String get shareQr => 'Partager';

  @override
  String get printLabels => 'Étiquettes PDF';

  @override
  String get labels => 'Étiquettes';

  @override
  String get cameraPermission =>
      'Autorisez l\'accès à l\'appareil photo dans les Réglages.';

  @override
  String get identify => 'Identifier';

  @override
  String get identifying => 'Analyse en cours…';

  @override
  String get identifyTitle => 'Est-ce bien…';

  @override
  String get identifyHint => 'Suggestions à confirmer, jamais des certitudes.';

  @override
  String get identifyNone => 'Aucune correspondance fiable.';

  @override
  String get identifyError =>
      'Identification impossible. Vérifiez votre connexion et réessayez.';

  @override
  String get useThis => 'Utiliser';

  @override
  String get identificationSettings => 'Identification';

  @override
  String get identificationHint =>
      'Reconnaissance d\'espèce à partir d\'une photo, via le service Pl@ntNet. Créez une clé gratuite sur my.plantnet.org et collez-la ici.';

  @override
  String get apiKey => 'Clé API';

  @override
  String get apiKeyHint => 'Collez votre clé';

  @override
  String get identificationEnabled => 'Identification activée';

  @override
  String get identificationDisabled => 'Non configurée';

  @override
  String confidence(int percent) {
    return '$percent %';
  }

  @override
  String get speciesSet => 'Espèce mise à jour';

  @override
  String get compare => 'Comparer';

  @override
  String get compareHint => 'Glissez pour comparer.';

  @override
  String get before => 'Avant';

  @override
  String get after => 'Après';

  @override
  String get comparePickFirst => 'Choisissez deux photos.';

  @override
  String get outdoor => 'Extérieur';

  @override
  String get outdoorHint => 'Balcon, jardin, serre : la météo compte.';

  @override
  String get weather => 'Météo';

  @override
  String get weatherHint =>
      'Pour vos plantes dehors, Flora regarde la pluie du jour et vous évite un arrosage inutile. Données Open-Meteo, sans compte ni clé.';

  @override
  String get weatherPlace => 'Lieu';

  @override
  String get weatherSearchHint => 'Ville…';

  @override
  String get weatherNone => 'Aucun lieu';

  @override
  String get weatherRemove => 'Retirer le lieu';

  @override
  String get weatherNoResults => 'Aucun lieu trouvé.';

  @override
  String weatherRainSkip(String names) {
    return 'Pluie prévue : pas besoin d\'arroser $names aujourd\'hui.';
  }

  @override
  String get postpone => 'Reporter';

  @override
  String postponedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count arrosages reportés à demain',
      one: '1 arrosage reporté à demain',
    );
    return '$_temp0';
  }

  @override
  String get condClear => 'Ciel dégagé';

  @override
  String get condPartlyCloudy => 'Éclaircies';

  @override
  String get condCloudy => 'Nuageux';

  @override
  String get condFog => 'Brouillard';

  @override
  String get condDrizzle => 'Bruine';

  @override
  String get condRain => 'Pluie';

  @override
  String get condSnow => 'Neige';

  @override
  String get condThunderstorm => 'Orage';

  @override
  String rainChance(int percent) {
    return '$percent % de pluie';
  }

  @override
  String get dataSection => 'Données';

  @override
  String get exportData => 'Exporter mes données';

  @override
  String get exportHint =>
      'Un fichier ZIP avec vos plantes, historiques, inventaire, réglages et photos. Vos données vous appartiennent.';

  @override
  String get exporting => 'Préparation de l\'export…';

  @override
  String get exportError => 'Export impossible. Réessayez.';

  @override
  String get play => 'Lire';

  @override
  String get timelapseHint => 'Touchez pour mettre en pause.';

  @override
  String notifLowStockOne(String name) {
    return 'Il ne vous reste presque plus de $name.';
  }

  @override
  String notifLowStockMany(int count) {
    return '$count articles sont presque épuisés.';
  }

  @override
  String get accountTitle => 'Compte';

  @override
  String get signIn => 'Se connecter';

  @override
  String get signInHint =>
      'Un compte sauvegarde vos plantes, les synchronise entre vos appareils et permet de partager un jardin. Sans compte, tout reste sur ce téléphone.';

  @override
  String get continueWithApple => 'Continuer avec Apple';

  @override
  String get continueWithGoogle => 'Continuer avec Google';

  @override
  String get continueWithEmail => 'Continuer avec un e-mail';

  @override
  String get emailHint => 'vous@exemple.ch';

  @override
  String get sendCode => 'Recevoir un code';

  @override
  String codeSent(String email) {
    return 'Code envoyé à $email.';
  }

  @override
  String get codeHint => 'Code à 6 chiffres';

  @override
  String get verifyCode => 'Valider';

  @override
  String get signOut => 'Se déconnecter';

  @override
  String get signOutConfirm => 'Vos données restent sur ce téléphone.';

  @override
  String get signedInAs => 'Connecté';

  @override
  String get syncNow => 'Synchroniser maintenant';

  @override
  String syncIdle(String time) {
    return 'À jour · $time';
  }

  @override
  String get syncNever => 'Pas encore synchronisé';

  @override
  String syncPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changements en attente',
      one: '1 changement en attente',
    );
    return '$_temp0';
  }

  @override
  String get syncOffline => 'Hors ligne · reprise automatique';

  @override
  String get syncError => 'Erreur de synchronisation';

  @override
  String get syncSyncing => 'Synchronisation…';

  @override
  String get authError =>
      'Connexion impossible. Vérifiez l\'adresse et réessayez.';

  @override
  String get appleUnavailable => 'Apple est disponible sur iPhone et iPad.';

  @override
  String get synchronization => 'Synchronisation';
}
