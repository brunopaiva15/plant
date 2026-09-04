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
  String get gardenLocations => 'Lieux';

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

  @override
  String get membersTitle => 'Membres';

  @override
  String get shareGarden => 'Partager le jardin';

  @override
  String get inviteMember => 'Inviter';

  @override
  String get inviteHint =>
      'L\'invité doit déjà avoir un compte Flora avec cette adresse.';

  @override
  String get roleOwner => 'Propriétaire';

  @override
  String get roleMember => 'Membre';

  @override
  String get roleViewer => 'Lecture seule';

  @override
  String get invited => 'Invitation envoyée';

  @override
  String get inviteError =>
      'Impossible d\'inviter : cette adresse n\'a pas encore de compte.';

  @override
  String get removeMember => 'Retirer du jardin';

  @override
  String get readOnlyHint => 'Vous consultez ce jardin en lecture seule.';

  @override
  String byUser(String name) {
    return 'par $name';
  }

  @override
  String get you => 'vous';

  @override
  String get diagnosisTitle => 'Ma plante a un problème';

  @override
  String get diagnosisHint =>
      'Photographiez les feuilles, la tige ou la terre sous plusieurs angles. Les résultats sont des pistes, jamais des certitudes.';

  @override
  String get diagnosisSymptomsHint => 'Ce que vous avez remarqué (facultatif)…';

  @override
  String get analyze => 'Analyser';

  @override
  String get analyzing => 'Analyse en cours…';

  @override
  String get diagnosisError =>
      'Analyse impossible. Vérifiez votre connexion et réessayez.';

  @override
  String get diagnosisRefused =>
      'L\'analyse n\'a pas pu être effectuée pour cette photo.';

  @override
  String get diagnosisUnauthorized =>
      'Clé API refusée. Vérifiez-la dans Profil › Diagnostic.';

  @override
  String get possibleCauses => 'Pistes possibles';

  @override
  String get urgentHint => 'À traiter rapidement';

  @override
  String get saveToJournal => 'Enregistrer dans le journal';

  @override
  String get markWatch => 'Marquer à surveiller';

  @override
  String get diagnosisSettings => 'Diagnostic';

  @override
  String get diagnosisSettingsHint =>
      'Analyse de photos par l\'API Claude d\'Anthropic, avec votre propre clé (console.anthropic.com). Les photos sont envoyées uniquement lors d\'une analyse que vous lancez.';

  @override
  String get diagnosisEnabled => 'Diagnostic activé';

  @override
  String get addPhotos => 'Ajouter des photos';

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
  String get diagnosisSaved => 'Diagnostic ajouté au journal';

  @override
  String get speciesInfo => 'Fiche espèce';

  @override
  String get speciesSource =>
      'Source : GBIF — Global Biodiversity Information Facility';

  @override
  String get speciesCommonNames => 'Noms communs';

  @override
  String get speciesFamily => 'Famille';

  @override
  String get speciesOrder => 'Ordre';

  @override
  String get speciesGenus => 'Genre';

  @override
  String get speciesStatus => 'Statut';

  @override
  String get speciesOpenGbif => 'Voir sur GBIF';

  @override
  String get speciesNotFound => 'Espèce introuvable dans GBIF.';

  @override
  String get speciesLoading => 'Recherche dans GBIF…';

  @override
  String get speciesPhotos => 'Observations';

  @override
  String speciesPhotoCredit(String author, String license) {
    return '$author · $license';
  }

  @override
  String get speciesSuggestions => 'Suggestions';

  @override
  String get speciesUseName => 'Utiliser ce nom';

  @override
  String get speciesStatusAccepted => 'Nom accepté';

  @override
  String get speciesStatusSynonym => 'Synonyme';

  @override
  String get speciesPickerTitle => 'Choisir une espèce';

  @override
  String get speciesSearchHint => 'Nom commun, latin, famille…';

  @override
  String get speciesInGarden => 'Dans votre jardin';

  @override
  String get speciesCommonList => 'Espèces courantes';

  @override
  String get speciesGbifResults => 'Toutes les espèces (GBIF)';

  @override
  String speciesGbifCount(int count) {
    return '$count espèces correspondantes';
  }

  @override
  String speciesUseText(String name) {
    return 'Utiliser « $name »';
  }

  @override
  String get speciesNoResults => 'Aucune espèce trouvée';

  @override
  String get speciesOffline =>
      'La liste complète nécessite une connexion. Les espèces courantes restent disponibles.';

  @override
  String get speciesBrowse => 'Liste complète';

  @override
  String get speciesCatAll => 'Toutes';

  @override
  String get speciesCatIndoor => 'Intérieur';

  @override
  String get speciesCatSucculent => 'Succulentes';

  @override
  String get speciesCatHerb => 'Aromatiques';

  @override
  String get speciesCatVegetable => 'Potager';

  @override
  String get speciesCatFruit => 'Fruitiers';

  @override
  String get speciesCatFlower => 'Fleurs';

  @override
  String get speciesCatTree => 'Arbres et arbustes';

  @override
  String get gardenTasks => 'Tâches';

  @override
  String get tasks => 'Tâches';

  @override
  String get newTask => 'Nouvelle tâche';

  @override
  String get editTask => 'Modifier la tâche';

  @override
  String get taskTitleHint => 'Que faut-il faire ?';

  @override
  String get taskDescriptionHint => 'Détails (facultatif)';

  @override
  String get taskPlant => 'Plante';

  @override
  String get taskNoPlant => 'Sans plante';

  @override
  String get taskDue => 'Échéance';

  @override
  String get taskNoDue => 'Sans date';

  @override
  String get taskTime => 'Heure';

  @override
  String get taskAllDay => 'Toute la journée';

  @override
  String get taskRecurrence => 'Récurrence';

  @override
  String get taskRecurrenceNone => 'Aucune';

  @override
  String get taskEvery => 'Toutes les';

  @override
  String recurrenceLabel(String unit, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Toutes les $count heures',
      one: 'Toutes les heures',
    );
    String _temp1 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tous les $count jours',
      one: 'Tous les jours',
    );
    String _temp2 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Toutes les $count semaines',
      one: 'Toutes les semaines',
    );
    String _temp3 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tous les $count mois',
      one: 'Tous les mois',
    );
    String _temp4 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tous les $count ans',
      one: 'Tous les ans',
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
  String get unitHours => 'heures';

  @override
  String get unitDays => 'jours';

  @override
  String get unitWeeks => 'semaines';

  @override
  String get unitMonths => 'mois';

  @override
  String get unitYears => 'ans';

  @override
  String get taskFilterOpen => 'Ouvertes';

  @override
  String get taskFilterOverdue => 'En retard';

  @override
  String get taskFilterDone => 'Terminées';

  @override
  String get taskSectionOverdue => 'En retard';

  @override
  String get taskSectionToday => 'Aujourd\'hui';

  @override
  String get taskSectionUpcoming => 'À venir';

  @override
  String get taskSectionNoDate => 'Sans date';

  @override
  String get noTasksTitle => 'Aucune tâche';

  @override
  String get noTasksSubtitle =>
      'Semis, nettoyage de la serre, commande de terreau : notez tout ici.';

  @override
  String get noDoneTasks => 'Rien de terminé pour l\'instant';

  @override
  String taskDoneToast(String title) {
    return '$title · Terminée';
  }

  @override
  String taskNextToast(String title, String date) {
    return '$title · Prochaine fois $date';
  }

  @override
  String get taskDeleted => 'Tâche supprimée';

  @override
  String get deleteTask => 'Supprimer la tâche';

  @override
  String get reopenTask => 'Rouvrir';

  @override
  String taskDoneOn(String date) {
    return 'Terminée $date';
  }

  @override
  String taskOverdueSince(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'En retard de $count jours',
      one: 'En retard d\'un jour',
    );
    return '$_temp0';
  }

  @override
  String taskDueIn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dans $count jours',
      one: 'Demain',
    );
    return '$_temp0';
  }

  @override
  String get tasksTodayTitle => 'Tâches';

  @override
  String get choosePlant => 'Choisir une plante';

  @override
  String notifTasksOne(String title) {
    return 'Tâche : $title.';
  }

  @override
  String notifTasksMany(int count, String titles) {
    return '$count tâches à faire : $titles.';
  }

  @override
  String notifTaskDue(String title) {
    return 'C\'est le moment : $title';
  }

  @override
  String get careGuide => 'Fiche d\'entretien';

  @override
  String get careGuideSubtitle =>
      'Quand arroser, quelle lumière, que surveiller.';

  @override
  String get careHowTo => 'Comment en prendre soin';

  @override
  String get careWatering => 'Arrosage';

  @override
  String get careLight => 'Lumière';

  @override
  String get careHumidity => 'Humidité';

  @override
  String get careTemperature => 'Température';

  @override
  String get careSoil => 'Substrat';

  @override
  String get careFertilizing => 'Engrais';

  @override
  String get careRepotting => 'Rempotage';

  @override
  String get careToxicity => 'Toxicité';

  @override
  String get careDifficulty => 'Difficulté';

  @override
  String get carePropagation => 'Multiplication';

  @override
  String get careIssues => 'À surveiller';

  @override
  String get careTips => 'Bons réflexes';

  @override
  String careEveryDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tous les $count jours',
      one: 'Tous les jours',
    );
    return '$_temp0';
  }

  @override
  String careWateringNow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tous les $count jours en ce moment',
      one: 'Tous les jours en ce moment',
    );
    return '$_temp0';
  }

  @override
  String careWateringSeasons(int summer, int winter) {
    return '$summer j en pleine saison · $winter j en hiver';
  }

  @override
  String careFertilizeSeason(String from, String to) {
    return 'de $from à $to';
  }

  @override
  String get careNoFertilizer => 'Aucun engrais nécessaire';

  @override
  String careRepotMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tous les $count mois',
      one: 'Chaque mois',
    );
    return '$_temp0';
  }

  @override
  String careRepotYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tous les $count ans',
      one: 'Tous les ans',
    );
    return '$_temp0';
  }

  @override
  String get careRepotNone => 'Pas de rempotage : culture annuelle';

  @override
  String careTempIdeal(int min, int max) {
    return '$min à $max °C';
  }

  @override
  String careTempMin(int min) {
    return 'Supporte jusqu\'à $min °C';
  }

  @override
  String get careLightShade => 'Ombre';

  @override
  String get careLightLow => 'Faible lumière';

  @override
  String get careLightIndirect => 'Lumière indirecte';

  @override
  String get careLightBright => 'Lumière vive indirecte';

  @override
  String get careLightSome => 'Quelques heures de soleil';

  @override
  String get careLightFull => 'Plein soleil';

  @override
  String get careHumidityLow => 'Air sec accepté';

  @override
  String get careHumidityAverage => 'Humidité ordinaire';

  @override
  String get careHumidityHigh => 'Aime l\'air humide';

  @override
  String get careDifficultyEasy => 'Facile';

  @override
  String get careDifficultyMedium => 'Moyenne';

  @override
  String get careDifficultyDemanding => 'Exigeante';

  @override
  String get careToxicSafe => 'Sans danger connu';

  @override
  String get careToxicMild => 'Légèrement irritante';

  @override
  String get careToxicToxic => 'Toxique si ingérée';

  @override
  String get careToxicUnknown => 'Toxicité non renseignée';

  @override
  String get careToxicPets =>
      'Tenir hors de portée des animaux et des enfants.';

  @override
  String get careSoilStandard => 'Terreau universel';

  @override
  String get careSoilDraining => 'Terreau très drainant';

  @override
  String get careSoilCactus => 'Terreau cactus et succulentes';

  @override
  String get careSoilOrchid => 'Écorces pour orchidées';

  @override
  String get careSoilAcidic => 'Terre de bruyère';

  @override
  String get careSoilRich => 'Terreau riche en compost';

  @override
  String get careSoilAquatic => 'Sans substrat';

  @override
  String get carePropCutting => 'Bouture de tige';

  @override
  String get carePropLeaf => 'Bouture de feuille';

  @override
  String get carePropDivision => 'Division de la touffe';

  @override
  String get carePropOffsets => 'Rejets';

  @override
  String get carePropLayering => 'Marcottage';

  @override
  String get carePropSeed => 'Semis';

  @override
  String get carePropWater => 'Bouture dans l\'eau';

  @override
  String get carePropTuber => 'Séparation des tubercules';

  @override
  String get careMatchSpecies => 'Fiche de l\'espèce';

  @override
  String careMatchGenus(String name) {
    return 'Fiche du genre $name';
  }

  @override
  String careMatchFamily(String name) {
    return 'Fiche de la famille des $name';
  }

  @override
  String get careMatchGeneric => 'Repères généraux';

  @override
  String get careMatchNote =>
      'Ces repères viennent du groupe botanique, pas de l\'espèce exacte. Précisez l\'espèce pour affiner.';

  @override
  String get careDisclaimer =>
      'Des repères, pas des règles : votre lumière, votre pot et votre air comptent autant.';

  @override
  String get careApplyToSchedule => 'Appliquer au planning';

  @override
  String get careScheduleApplied => 'Planning mis à jour';

  @override
  String careSuggestedIntervals(int water, int fertilize) {
    return 'Arrosage tous les $water jours, engrais tous les $fertilize jours';
  }

  @override
  String get careBadgeMist => 'Brumiser';

  @override
  String get careBadgeDormant => 'Repos hivernal';

  @override
  String get careBadgeOutdoor => 'Supporte l\'extérieur';

  @override
  String get careIssueOverwatering =>
      'Excès d\'eau : feuilles molles et jaunes';

  @override
  String get careIssueUnderwatering => 'Manque d\'eau : feuilles qui retombent';

  @override
  String get careIssueRootRot => 'Pourriture des racines';

  @override
  String get careIssueSpiderMites => 'Araignées rouges (fines toiles)';

  @override
  String get careIssueMealybugs => 'Cochenilles farineuses';

  @override
  String get careIssueScale => 'Cochenilles à bouclier';

  @override
  String get careIssueAphids => 'Pucerons';

  @override
  String get careIssueFungusGnats => 'Moucherons du terreau';

  @override
  String get careIssueWhitefly => 'Aleurodes (mouches blanches)';

  @override
  String get careIssueSlugs => 'Limaces et escargots';

  @override
  String get careIssuePowderyMildew => 'Oïdium (feutrage blanc)';

  @override
  String get careIssueLeafSpot => 'Taches foliaires';

  @override
  String get careIssueBlight => 'Mildiou';

  @override
  String get careIssueSunburn => 'Brûlures du soleil';

  @override
  String get careIssueDryTips => 'Pointes sèches et brunes';

  @override
  String get careIssueLeafDrop => 'Chute de feuilles';

  @override
  String get careIssueEtiolation => 'Étiolement par manque de lumière';

  @override
  String get careIssueChlorosis => 'Chlorose : feuilles pâles, nervures vertes';

  @override
  String get careIssueBlossomEndRot => 'Nécrose apicale des fruits';

  @override
  String get careTipFingerTest =>
      'Enfoncez un doigt : arrosez quand les 2 premiers centimètres sont secs.';

  @override
  String get careTipDrySoilFirst =>
      'Laissez le terreau sécher complètement entre deux arrosages.';

  @override
  String get careTipNeverDryOut =>
      'Ne laissez jamais le terreau sécher complètement.';

  @override
  String get careTipEvenWatering =>
      'Arrosez régulièrement : les à-coups font éclater les fruits.';

  @override
  String get careTipWaterAtBase =>
      'Arrosez au pied, sans mouiller le feuillage.';

  @override
  String get careTipNoWaterOnLeaves =>
      'Ne mouillez pas les feuilles : l\'eau stagnante les tache.';

  @override
  String get careTipBottomWatering =>
      'Arrosez par le bas : posez le pot dans une soucoupe d\'eau 20 minutes.';

  @override
  String get careTipFilteredWater =>
      'Préférez l\'eau de pluie ou filtrée : le calcaire brunit les pointes.';

  @override
  String get careTipRainwaterOnly =>
      'Arrosez à l\'eau de pluie : cette plante déteste le calcaire.';

  @override
  String get careTipThirstyPlant =>
      'Grosse buveuse : en été, vérifiez tous les jours.';

  @override
  String get careTipDroopSignal =>
      'Elle s\'affaisse quand elle a soif : c\'est votre signal.';

  @override
  String get careTipWinterDry => 'En hiver, gardez-la presque au sec.';

  @override
  String get careTipWinterRest =>
      'Ralentissez fortement l\'arrosage en hiver : elle se repose.';

  @override
  String get careTipSummerDormant =>
      'Elle se repose en été : arrosez très peu à cette période.';

  @override
  String get careTipNoWaterWhileSplitting =>
      'N\'arrosez pas pendant qu\'elle change de feuilles.';

  @override
  String get careTipOrchidSoak =>
      'Trempez le pot 10 minutes, puis laissez bien égoutter.';

  @override
  String get careTipSoakMount =>
      'Trempez la plante entière, puis laissez-la sécher à l\'air.';

  @override
  String get careTipDryUpsideDown =>
      'Après le bain, laissez-la sécher tête en bas : l\'eau au cœur la fait pourrir.';

  @override
  String get careTipWaterInTheCup =>
      'Remplissez la rosette centrale et renouvelez l\'eau chaque semaine.';

  @override
  String get careTipNoSoil =>
      'Elle vit sans terre : posez-la simplement sur un support.';

  @override
  String get careTipGreenRoots =>
      'Racines vertes = bien hydratée. Argentées = il est temps d\'arroser.';

  @override
  String get careTipHumidityTray =>
      'Posez le pot sur un lit de billes d\'argile humides.';

  @override
  String get careTipNoDirectSun =>
      'Évitez le soleil direct : il brûle le feuillage.';

  @override
  String get careTipToleratesLowLight =>
      'Elle supporte une pièce peu lumineuse, mais pousse plus vite près d\'une fenêtre.';

  @override
  String get careTipToleratesNeglect =>
      'Elle pardonne les oublis : en cas de doute, n\'arrosez pas.';

  @override
  String get careTipBrightForColor =>
      'Plus la lumière est vive, plus les couleurs sont marquées.';

  @override
  String get careTipRotatePot =>
      'Tournez le pot d\'un quart de tour chaque semaine pour qu\'elle reste droite.';

  @override
  String get careTipHatesMoving =>
      'Elle déteste être déplacée : trouvez-lui une place et laissez-la.';

  @override
  String get careTipWipeLeaves =>
      'Dépoussiérez les feuilles : elles respirent et captent mieux la lumière.';

  @override
  String get careTipTrimToBushOut =>
      'Taillez les tiges trop longues : elle se ramifiera.';

  @override
  String get careTipMonsteraSupport =>
      'Offrez-lui un tuteur moussu : les feuilles deviendront plus grandes et découpées.';

  @override
  String get careTipShallowPot =>
      'Un pot large et peu profond lui convient mieux.';

  @override
  String get careTipLikesBeingPotbound =>
      'Elle fleurit mieux à l\'étroit : rempotez rarement.';

  @override
  String get careTipTrunkStoresWater =>
      'Son pied renflé stocke l\'eau : mieux vaut trop peu que trop.';

  @override
  String get careTipPupsToShare =>
      'Elle fait des rejets : détachez-les pour multiplier ou offrir.';

  @override
  String get careTipKeepFlowerSpike =>
      'Ne coupez pas la hampe verte : elle peut refleurir dessus.';

  @override
  String get careTipDarkForRebloom =>
      'Pour la refaire fleurir, offrez-lui six semaines de nuits longues et fraîches.';

  @override
  String get careTipNotADesertCactus =>
      'Ce n\'est pas un cactus du désert : il aime l\'ombre et l\'humidité.';

  @override
  String get careTipDeadheadFlowers =>
      'Retirez les fleurs fanées : elle refleurira plus longtemps.';

  @override
  String get careTipPinchFlowers =>
      'Pincez les fleurs dès qu\'elles montent : les feuilles restent tendres.';

  @override
  String get careTipHarvestTop =>
      'Récoltez par le haut, au-dessus d\'une paire de feuilles.';

  @override
  String get careTipHarvestOutside =>
      'Cueillez les feuilles extérieures : le cœur continue de pousser.';

  @override
  String get careTipStakeAndPrune =>
      'Tuteurez et supprimez les gourmands entre tige et branche.';

  @override
  String get careTipPrunesInSpring =>
      'Taillez au printemps, jamais dans le vieux bois sec.';

  @override
  String get careTipPrunesAfterFlowering =>
      'Taillez juste après la floraison pour garder une touffe compacte.';

  @override
  String get careTipWinterPruning =>
      'Taillez en hiver, hors gel, quand la plante dort.';

  @override
  String get careTipPruneAfterHarvest =>
      'Taillez après la récolte, pas au printemps.';

  @override
  String get careTipCutSpentCanes =>
      'Coupez à ras les tiges qui ont fructifié.';

  @override
  String get careTipTrimTwiceAYear =>
      'Deux tailles par an suffisent : juin et fin août.';

  @override
  String get careTipContainItsRoots =>
      'Plantez-la en pot ou posez une barrière anti-rhizome : elle envahit tout.';

  @override
  String get careTipMulchIt =>
      'Paillez le pied : moins d\'arrosages, moins de mauvaises herbes.';

  @override
  String get careTipAcidSoil =>
      'Elle exige une terre acide : évitez le terreau universel.';

  @override
  String get careTipBlueNeedsAcid =>
      'Les fleurs bleues demandent un sol acide ; en sol calcaire elles virent au rose.';

  @override
  String get careTipCitrusFertilizer =>
      'Utilisez un engrais spécial agrumes pendant toute la belle saison.';

  @override
  String get careTipNoFertilizer =>
      'Pas d\'engrais : trop riche, elle perd son parfum et sa tenue.';

  @override
  String get careTipNoNitrogen =>
      'Évitez l\'engrais azoté : elle fabrique son propre azote.';

  @override
  String get careTipLetFoliageDieBack =>
      'Laissez le feuillage jaunir sur pied : il recharge le bulbe.';

  @override
  String get careTipDiesBackInWinter =>
      'Elle disparaît en hiver et repart au printemps : c\'est normal.';

  @override
  String get careTipSummerOutdoors =>
      'Sortez-la l\'été, à l\'ombre les premiers jours.';

  @override
  String get careTipWinterIndoors => 'Rentrez-la avant les premières gelées.';

  @override
  String get careTipWinterShelter =>
      'Abritez-la l\'hiver dans une pièce fraîche et lumineuse.';

  @override
  String get careTipWinterCool =>
      'Un hiver frais (10–14 °C) et lumineux lui fait du bien.';

  @override
  String get careTipCoolerIsBetter =>
      'Elle préfère la fraîcheur : évitez la proximité d\'un radiateur.';

  @override
  String get careTipHardyOutdoors =>
      'Rustique : elle passe l\'hiver dehors sans protection.';

  @override
  String get careTipShelterFromWind =>
      'Placez-la à l\'abri du vent : le feuillage s\'abîme vite.';

  @override
  String get careTipAirFlow =>
      'Aérez autour d\'elle : l\'air confiné favorise les maladies.';

  @override
  String get careTipSpiderMiteWatch =>
      'Inspectez le dessous des feuilles : les araignées rouges l\'adorent.';

  @override
  String get careTipSlugWatch =>
      'Protégez les jeunes pousses des limaces au printemps.';

  @override
  String get careTipBoxMothWatch =>
      'Surveillez la pyrale : chenilles et fils de soie dans le feuillage.';

  @override
  String get careTipSapIrritant =>
      'Sa sève irrite la peau et les yeux : portez des gants pour la tailler.';

  @override
  String get careTipVeryToxic =>
      'Toutes ses parties sont très toxiques, y compris la fumée si on la brûle.';

  @override
  String get careTipSharpSpines =>
      'Ses pointes sont dangereuses : éloignez-la des passages.';

  @override
  String get careTipSplitsAreNormal =>
      'Les feuilles se fendent avec l\'âge : c\'est normal, pas une maladie.';

  @override
  String get careTipDryToBloom =>
      'Un léger stress hydrique déclenche la floraison.';

  @override
  String get customFields => 'Champs personnalisés';

  @override
  String get addCustomField => 'Ajouter un champ';

  @override
  String get editCustomField => 'Modifier le champ';

  @override
  String get deleteCustomField => 'Supprimer le champ';

  @override
  String get fieldLabel => 'Nom du champ';

  @override
  String get fieldLabelHint => 'Provenance, prix, exposition…';

  @override
  String get fieldType => 'Type';

  @override
  String get fieldValue => 'Valeur';

  @override
  String get fieldTypeBool => 'Oui / non';

  @override
  String get fieldTypeInt => 'Nombre entier';

  @override
  String get fieldTypeDouble => 'Nombre décimal';

  @override
  String get fieldTypeText => 'Texte';

  @override
  String get fieldTypeDate => 'Date';

  @override
  String get fieldEmpty => 'Non renseigné';

  @override
  String get noCustomFields => 'Aucun champ personnalisé';

  @override
  String get fieldTemplates => 'Modèles de champs';

  @override
  String get fieldTemplatesHint =>
      'Créez ici les champs que vous réutilisez sur plusieurs plantes : ils vous seront proposés en un tap.';

  @override
  String get newFieldTemplate => 'Nouveau modèle';

  @override
  String get noFieldTemplates => 'Aucun modèle';

  @override
  String get fieldTemplateInactive => 'Masqué';

  @override
  String get fieldFromTemplate => 'Depuis un modèle';

  @override
  String get bulkSetField => 'Renseigner un champ';

  @override
  String bulkFieldApplied(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Champ appliqué à $count plantes',
      one: 'Champ appliqué à 1 plante',
    );
    return '$_temp0';
  }

  @override
  String get confirmDeleteField => 'Supprimer ce champ et sa valeur ?';

  @override
  String get confirmDeleteTemplate =>
      'Supprimer ce modèle ? Les champs déjà renseignés sont conservés.';

  @override
  String get yes => 'Oui';

  @override
  String get no => 'Non';

  @override
  String get attachments => 'Documents';

  @override
  String get addAttachment => 'Ajouter un document';

  @override
  String get noAttachments => 'Aucun document';

  @override
  String get noAttachmentsHint =>
      'Facture, fiche du producteur, analyse de sol…';

  @override
  String get attachmentLabel => 'Nom du document';

  @override
  String get renameAttachment => 'Renommer';

  @override
  String get deleteAttachment => 'Supprimer le document';

  @override
  String get confirmDeleteAttachment =>
      'Supprimer ce document ? Le fichier sera effacé de l\'appareil.';

  @override
  String get openAttachment => 'Ouvrir';

  @override
  String get attachmentOpenFailed =>
      'Aucune application ne peut ouvrir ce fichier.';

  @override
  String get photoLabel => 'Titre de la photo';

  @override
  String get photoLabelHint => 'Avant rempotage, nouvelle feuille…';

  @override
  String get setAsMainPhoto => 'Photo principale';

  @override
  String get mainPhotoSet => 'Photo principale mise à jour';

  @override
  String get addPhotoByUrl => 'Depuis une adresse web';

  @override
  String get photoUrlHint => 'https://…';

  @override
  String get photoUrlInvalid =>
      'Adresse invalide : elle doit commencer par https://';

  @override
  String get photoRemote => 'Photo distante';

  @override
  String get confirmDeletePhoto => 'Supprimer cette photo ?';

  @override
  String get shareByLink => 'Partager par lien';

  @override
  String get sharedLinks => 'Liens partagés';

  @override
  String get sharedLinksHint =>
      'Une page web publique, révocable à tout moment.';

  @override
  String get noSharedLinks => 'Aucun lien partagé';

  @override
  String get shareTitle => 'Titre de la page';

  @override
  String get shareDescription => 'Description (facultatif)';

  @override
  String get shareKeywords => 'Mots-clés (facultatif)';

  @override
  String get shareUnlisted => 'Non référencé';

  @override
  String get shareUnlistedHint =>
      'La page demande aux moteurs de recherche de ne pas l\'indexer. Toute personne ayant le lien peut la voir.';

  @override
  String get shareExpiry => 'Expire le';

  @override
  String get shareNoExpiry => 'Sans expiration';

  @override
  String get shareCreate => 'Créer le lien';

  @override
  String get shareCopy => 'Copier le lien';

  @override
  String get shareCopied => 'Lien copié';

  @override
  String get shareRevoke => 'Révoquer';

  @override
  String get shareRevoked => 'Révoqué';

  @override
  String get shareExpired => 'Expiré';

  @override
  String get shareActive => 'Actif';

  @override
  String get confirmRevokeLink =>
      'Révoquer ce lien ? La page ne sera plus accessible.';

  @override
  String get shareNeedsAccount => 'Le partage par lien nécessite un compte.';

  @override
  String get shareFailed => 'Le lien n\'a pas pu être créé. Réessayez.';

  @override
  String get sharePhoto => 'Partager cette photo';

  @override
  String get sharePlant => 'Partager cette plante';

  @override
  String get notesMarkdownHint =>
      'Mise en forme : **gras**, *italique*, - listes, [liens](https://…)';

  @override
  String get preview => 'Aperçu';
}
