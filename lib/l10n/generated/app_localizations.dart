import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('fr'),
    Locale('it'),
  ];

  /// No description provided for @appName.
  ///
  /// In fr, this message translates to:
  /// **'Auxine'**
  String get appName;

  /// No description provided for @ok.
  ///
  /// In fr, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get save;

  /// No description provided for @done.
  ///
  /// In fr, this message translates to:
  /// **'Terminé'**
  String get done;

  /// No description provided for @continueLabel.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get continueLabel;

  /// No description provided for @back.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get back;

  /// No description provided for @delete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get add;

  /// No description provided for @search.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher'**
  String get search;

  /// No description provided for @close.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get close;

  /// No description provided for @undo.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get undo;

  /// No description provided for @later.
  ///
  /// In fr, this message translates to:
  /// **'Plus tard'**
  String get later;

  /// No description provided for @openSettings.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir les Réglages'**
  String get openSettings;

  /// No description provided for @skip.
  ///
  /// In fr, this message translates to:
  /// **'Passer'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get next;

  /// No description provided for @retry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retry;

  /// No description provided for @more.
  ///
  /// In fr, this message translates to:
  /// **'Plus'**
  String get more;

  /// No description provided for @seeAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout voir'**
  String get seeAll;

  /// No description provided for @optional.
  ///
  /// In fr, this message translates to:
  /// **'facultatif'**
  String get optional;

  /// No description provided for @none.
  ///
  /// In fr, this message translates to:
  /// **'Aucun'**
  String get none;

  /// No description provided for @soon.
  ///
  /// In fr, this message translates to:
  /// **'Bientôt'**
  String get soon;

  /// No description provided for @genericError.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue. Réessayez.'**
  String get genericError;

  /// No description provided for @offlineTitle.
  ///
  /// In fr, this message translates to:
  /// **'Hors ligne'**
  String get offlineTitle;

  /// No description provided for @offlineHint.
  ///
  /// In fr, this message translates to:
  /// **'Cette fonction demande une connexion. Les données déjà sur l\'appareil restent lisibles.'**
  String get offlineHint;

  /// No description provided for @offlineActionFailed.
  ///
  /// In fr, this message translates to:
  /// **'Hors ligne. Réessayez une fois le réseau revenu.'**
  String get offlineActionFailed;

  /// No description provided for @offlineSharing.
  ///
  /// In fr, this message translates to:
  /// **'Créer, révoquer et lister des liens demande une connexion.'**
  String get offlineSharing;

  /// No description provided for @offlineCollaboration.
  ///
  /// In fr, this message translates to:
  /// **'Inviter, rejoindre un jardin et changer un rôle demande une connexion.'**
  String get offlineCollaboration;

  /// No description provided for @offlineDiagnosis.
  ///
  /// In fr, this message translates to:
  /// **'L\'analyse demande une connexion.'**
  String get offlineDiagnosis;

  /// No description provided for @offlineIdentification.
  ///
  /// In fr, this message translates to:
  /// **'La recherche en ligne demande une connexion. La reconnaissance sur l\'appareil, non.'**
  String get offlineIdentification;

  /// No description provided for @offlineSupport.
  ///
  /// In fr, this message translates to:
  /// **'L\'achat demande une connexion.'**
  String get offlineSupport;

  /// No description provided for @tabToday.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get tabToday;

  /// No description provided for @tabPlants.
  ///
  /// In fr, this message translates to:
  /// **'Plantes'**
  String get tabPlants;

  /// No description provided for @tabGarden.
  ///
  /// In fr, this message translates to:
  /// **'Jardin'**
  String get tabGarden;

  /// No description provided for @tabProfile.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get tabProfile;

  /// No description provided for @greeting.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour {name}'**
  String greeting(String name);

  /// No description provided for @greetingAnonymous.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour'**
  String get greetingAnonymous;

  /// No description provided for @greetingEvening.
  ///
  /// In fr, this message translates to:
  /// **'Bonsoir {name}'**
  String greetingEvening(String name);

  /// No description provided for @greetingEveningAnonymous.
  ///
  /// In fr, this message translates to:
  /// **'Bonsoir'**
  String get greetingEveningAnonymous;

  /// No description provided for @careCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun soin} =1{1 soin} other{{count} soins}}'**
  String careCount(int count);

  /// No description provided for @sectionOverdue.
  ///
  /// In fr, this message translates to:
  /// **'En retard'**
  String get sectionOverdue;

  /// No description provided for @sectionToday.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get sectionToday;

  /// No description provided for @sectionUpcoming.
  ///
  /// In fr, this message translates to:
  /// **'À venir'**
  String get sectionUpcoming;

  /// No description provided for @allDoneTitle.
  ///
  /// In fr, this message translates to:
  /// **'Tout est en ordre'**
  String get allDoneTitle;

  /// No description provided for @allDoneSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun soin prévu aujourd\'hui.'**
  String get allDoneSubtitle;

  /// No description provided for @emptyGardenTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune plante'**
  String get emptyGardenTitle;

  /// No description provided for @addFirstPlant.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter ma première plante'**
  String get addFirstPlant;

  /// No description provided for @yourGarden.
  ///
  /// In fr, this message translates to:
  /// **'Votre jardin'**
  String get yourGarden;

  /// No description provided for @recentPhotos.
  ///
  /// In fr, this message translates to:
  /// **'Photos récentes'**
  String get recentPhotos;

  /// No description provided for @plantCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucune plante} =1{1 plante} other{{count} plantes}}'**
  String plantCount(int count);

  /// No description provided for @kindWatering.
  ///
  /// In fr, this message translates to:
  /// **'Arrosage'**
  String get kindWatering;

  /// No description provided for @kindFertilizing.
  ///
  /// In fr, this message translates to:
  /// **'Engrais'**
  String get kindFertilizing;

  /// No description provided for @kindRepotting.
  ///
  /// In fr, this message translates to:
  /// **'Rempotage'**
  String get kindRepotting;

  /// No description provided for @kindPruning.
  ///
  /// In fr, this message translates to:
  /// **'Taille'**
  String get kindPruning;

  /// No description provided for @kindCleaning.
  ///
  /// In fr, this message translates to:
  /// **'Nettoyage'**
  String get kindCleaning;

  /// No description provided for @kindTreatment.
  ///
  /// In fr, this message translates to:
  /// **'Traitement'**
  String get kindTreatment;

  /// No description provided for @kindMeasurement.
  ///
  /// In fr, this message translates to:
  /// **'Mesure'**
  String get kindMeasurement;

  /// No description provided for @kindPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Photo'**
  String get kindPhoto;

  /// No description provided for @kindNote.
  ///
  /// In fr, this message translates to:
  /// **'Note'**
  String get kindNote;

  /// No description provided for @verbWatering.
  ///
  /// In fr, this message translates to:
  /// **'Arroser'**
  String get verbWatering;

  /// No description provided for @verbFertilizing.
  ///
  /// In fr, this message translates to:
  /// **'Fertiliser'**
  String get verbFertilizing;

  /// No description provided for @verbRepotting.
  ///
  /// In fr, this message translates to:
  /// **'Rempoter'**
  String get verbRepotting;

  /// No description provided for @verbPruning.
  ///
  /// In fr, this message translates to:
  /// **'Tailler'**
  String get verbPruning;

  /// No description provided for @verbCleaning.
  ///
  /// In fr, this message translates to:
  /// **'Nettoyer'**
  String get verbCleaning;

  /// No description provided for @verbTreatment.
  ///
  /// In fr, this message translates to:
  /// **'Traiter'**
  String get verbTreatment;

  /// No description provided for @verbMeasurement.
  ///
  /// In fr, this message translates to:
  /// **'Mesurer'**
  String get verbMeasurement;

  /// No description provided for @verbPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Photo'**
  String get verbPhoto;

  /// No description provided for @verbNote.
  ///
  /// In fr, this message translates to:
  /// **'Note'**
  String get verbNote;

  /// No description provided for @doneWatering.
  ///
  /// In fr, this message translates to:
  /// **'Arrosée'**
  String get doneWatering;

  /// No description provided for @doneFertilizing.
  ///
  /// In fr, this message translates to:
  /// **'Fertilisée'**
  String get doneFertilizing;

  /// No description provided for @doneRepotting.
  ///
  /// In fr, this message translates to:
  /// **'Rempotée'**
  String get doneRepotting;

  /// No description provided for @donePruning.
  ///
  /// In fr, this message translates to:
  /// **'Taillée'**
  String get donePruning;

  /// No description provided for @doneCleaning.
  ///
  /// In fr, this message translates to:
  /// **'Nettoyée'**
  String get doneCleaning;

  /// No description provided for @doneTreatment.
  ///
  /// In fr, this message translates to:
  /// **'Traitée'**
  String get doneTreatment;

  /// No description provided for @doneMeasurement.
  ///
  /// In fr, this message translates to:
  /// **'Mesurée'**
  String get doneMeasurement;

  /// No description provided for @donePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Photo ajoutée'**
  String get donePhoto;

  /// No description provided for @doneNote.
  ///
  /// In fr, this message translates to:
  /// **'Note ajoutée'**
  String get doneNote;

  /// No description provided for @doneCustom.
  ///
  /// In fr, this message translates to:
  /// **'Fait'**
  String get doneCustom;

  /// No description provided for @actionDoneToast.
  ///
  /// In fr, this message translates to:
  /// **'{plant} · {action}'**
  String actionDoneToast(String plant, String action);

  /// No description provided for @multiActionDone.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 plante · {action}} other{{count} plantes · {action}}}'**
  String multiActionDone(int count, String action);

  /// No description provided for @dueToday.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get dueToday;

  /// No description provided for @dueTomorrow.
  ///
  /// In fr, this message translates to:
  /// **'Demain'**
  String get dueTomorrow;

  /// No description provided for @dueInDays.
  ///
  /// In fr, this message translates to:
  /// **'Dans {count} jours'**
  String dueInDays(int count);

  /// No description provided for @dueOverdue.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{En retard d\'un jour} other{En retard de {count} jours}}'**
  String dueOverdue(int count);

  /// No description provided for @dueNone.
  ///
  /// In fr, this message translates to:
  /// **'Sans rappel'**
  String get dueNone;

  /// No description provided for @careDueLabel.
  ///
  /// In fr, this message translates to:
  /// **'{action} · {when}'**
  String careDueLabel(String action, String when);

  /// No description provided for @verbToday.
  ///
  /// In fr, this message translates to:
  /// **'{verb} aujourd\'hui'**
  String verbToday(String verb);

  /// No description provided for @plantsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Plantes'**
  String get plantsTitle;

  /// No description provided for @searchPlants.
  ///
  /// In fr, this message translates to:
  /// **'Nom, espèce, emplacement…'**
  String get searchPlants;

  /// No description provided for @filters.
  ///
  /// In fr, this message translates to:
  /// **'Filtres'**
  String get filters;

  /// No description provided for @sortBy.
  ///
  /// In fr, this message translates to:
  /// **'Trier par'**
  String get sortBy;

  /// No description provided for @sortName.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get sortName;

  /// No description provided for @sortNextCare.
  ///
  /// In fr, this message translates to:
  /// **'Prochain soin'**
  String get sortNextCare;

  /// No description provided for @sortRecent.
  ///
  /// In fr, this message translates to:
  /// **'Ajout récent'**
  String get sortRecent;

  /// No description provided for @sortEdited.
  ///
  /// In fr, this message translates to:
  /// **'Modification récente'**
  String get sortEdited;

  /// No description provided for @sortLastWatered.
  ///
  /// In fr, this message translates to:
  /// **'Dernier arrosage'**
  String get sortLastWatered;

  /// No description provided for @sortLastFertilized.
  ///
  /// In fr, this message translates to:
  /// **'Dernier engrais'**
  String get sortLastFertilized;

  /// No description provided for @sortLastRepotted.
  ///
  /// In fr, this message translates to:
  /// **'Dernier rempotage'**
  String get sortLastRepotted;

  /// No description provided for @sortAcquired.
  ///
  /// In fr, this message translates to:
  /// **'Acquisition'**
  String get sortAcquired;

  /// No description provided for @filterLocation.
  ///
  /// In fr, this message translates to:
  /// **'Emplacement'**
  String get filterLocation;

  /// No description provided for @filterNeedsAttention.
  ///
  /// In fr, this message translates to:
  /// **'À soigner'**
  String get filterNeedsAttention;

  /// No description provided for @filterFavorites.
  ///
  /// In fr, this message translates to:
  /// **'Favoris'**
  String get filterFavorites;

  /// No description provided for @filterTag.
  ///
  /// In fr, this message translates to:
  /// **'Tag'**
  String get filterTag;

  /// No description provided for @clearFilters.
  ///
  /// In fr, this message translates to:
  /// **'Effacer les filtres'**
  String get clearFilters;

  /// No description provided for @gridView.
  ///
  /// In fr, this message translates to:
  /// **'Grille'**
  String get gridView;

  /// No description provided for @listView.
  ///
  /// In fr, this message translates to:
  /// **'Liste'**
  String get listView;

  /// No description provided for @showAsGrid.
  ///
  /// In fr, this message translates to:
  /// **'Afficher en grille'**
  String get showAsGrid;

  /// No description provided for @showAsList.
  ///
  /// In fr, this message translates to:
  /// **'Afficher en liste'**
  String get showAsList;

  /// No description provided for @noResultsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun résultat'**
  String get noResultsTitle;

  /// No description provided for @noResultsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Essayez un autre mot.'**
  String get noResultsSubtitle;

  /// No description provided for @emptyPlantsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune plante'**
  String get emptyPlantsTitle;

  /// No description provided for @emptyPlantsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez votre première plante.'**
  String get emptyPlantsSubtitle;

  /// No description provided for @addPlant.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une plante'**
  String get addPlant;

  /// No description provided for @selectedCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 sélectionnée} other{{count} sélectionnées}}'**
  String selectedCount(int count);

  /// No description provided for @select.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner'**
  String get select;

  /// No description provided for @move.
  ///
  /// In fr, this message translates to:
  /// **'Déplacer'**
  String get move;

  /// No description provided for @archive.
  ///
  /// In fr, this message translates to:
  /// **'Archiver'**
  String get archive;

  /// No description provided for @addTag.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un tag'**
  String get addTag;

  /// No description provided for @favorite.
  ///
  /// In fr, this message translates to:
  /// **'Favori'**
  String get favorite;

  /// No description provided for @unfavorite.
  ///
  /// In fr, this message translates to:
  /// **'Retirer des favoris'**
  String get unfavorite;

  /// No description provided for @movedCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 plante déplacée} other{{count} plantes déplacées}}'**
  String movedCount(int count);

  /// No description provided for @archivedCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 plante archivée} other{{count} plantes archivées}}'**
  String archivedCount(int count);

  /// No description provided for @newPlant.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle plante'**
  String get newPlant;

  /// No description provided for @stepPhotoTitle.
  ///
  /// In fr, this message translates to:
  /// **'Photo'**
  String get stepPhotoTitle;

  /// No description provided for @stepPhotoSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Cadrez la plante en entier, à la lumière du jour.'**
  String get stepPhotoSubtitle;

  /// No description provided for @stepPhotoSubtitleCutting.
  ///
  /// In fr, this message translates to:
  /// **'Cadrez la bouture en entier, à la lumière du jour.'**
  String get stepPhotoSubtitleCutting;

  /// No description provided for @takePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Prendre une photo'**
  String get takePhoto;

  /// No description provided for @choosePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une photo'**
  String get choosePhoto;

  /// No description provided for @withoutPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Continuer sans photo'**
  String get withoutPhoto;

  /// No description provided for @changePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Changer'**
  String get changePhoto;

  /// No description provided for @stepNameTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get stepNameTitle;

  /// No description provided for @plantNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Nom de la plante'**
  String get plantNameHint;

  /// No description provided for @speciesHint.
  ///
  /// In fr, this message translates to:
  /// **'Espèce (facultatif)'**
  String get speciesHint;

  /// No description provided for @stepLocationTitle.
  ///
  /// In fr, this message translates to:
  /// **'Emplacement'**
  String get stepLocationTitle;

  /// No description provided for @newLocationChip.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau'**
  String get newLocationChip;

  /// No description provided for @noLocation.
  ///
  /// In fr, this message translates to:
  /// **'Sans emplacement'**
  String get noLocation;

  /// No description provided for @finish.
  ///
  /// In fr, this message translates to:
  /// **'Terminer'**
  String get finish;

  /// No description provided for @plantAdded.
  ///
  /// In fr, this message translates to:
  /// **'{name} ajoutée'**
  String plantAdded(String name);

  /// No description provided for @moreOptions.
  ///
  /// In fr, this message translates to:
  /// **'Plus d\'options'**
  String get moreOptions;

  /// No description provided for @acquiredAt.
  ///
  /// In fr, this message translates to:
  /// **'Date d\'acquisition'**
  String get acquiredAt;

  /// No description provided for @source.
  ///
  /// In fr, this message translates to:
  /// **'Provenance'**
  String get source;

  /// No description provided for @sourceHint.
  ///
  /// In fr, this message translates to:
  /// **'Pépinière, bouture d\'un ami…'**
  String get sourceHint;

  /// No description provided for @price.
  ///
  /// In fr, this message translates to:
  /// **'Prix'**
  String get price;

  /// No description provided for @potSize.
  ///
  /// In fr, this message translates to:
  /// **'Diamètre du pot'**
  String get potSize;

  /// No description provided for @notes.
  ///
  /// In fr, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @notesHint.
  ///
  /// In fr, this message translates to:
  /// **'Exposition, rempotage, remarques…'**
  String get notesHint;

  /// No description provided for @wateringEvery.
  ///
  /// In fr, this message translates to:
  /// **'Arrosage'**
  String get wateringEvery;

  /// No description provided for @fertilizingEvery.
  ///
  /// In fr, this message translates to:
  /// **'Engrais'**
  String get fertilizingEvery;

  /// No description provided for @everyDays.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Tous les jours} other{Tous les {count} jours}}'**
  String everyDays(int count);

  /// No description provided for @sinceDate.
  ///
  /// In fr, this message translates to:
  /// **'Depuis {date}'**
  String sinceDate(String date);

  /// No description provided for @nextCare.
  ///
  /// In fr, this message translates to:
  /// **'Prochains soins'**
  String get nextCare;

  /// No description provided for @addAction.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une action'**
  String get addAction;

  /// No description provided for @history.
  ///
  /// In fr, this message translates to:
  /// **'Historique'**
  String get history;

  /// No description provided for @seeFullHistory.
  ///
  /// In fr, this message translates to:
  /// **'Tout l\'historique'**
  String get seeFullHistory;

  /// No description provided for @growth.
  ///
  /// In fr, this message translates to:
  /// **'Croissance'**
  String get growth;

  /// No description provided for @photos.
  ///
  /// In fr, this message translates to:
  /// **'Photos'**
  String get photos;

  /// No description provided for @info.
  ///
  /// In fr, this message translates to:
  /// **'Informations'**
  String get info;

  /// No description provided for @offspring.
  ///
  /// In fr, this message translates to:
  /// **'Plantes filles'**
  String get offspring;

  /// No description provided for @editSchedule.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le planning'**
  String get editSchedule;

  /// No description provided for @cuttingOf.
  ///
  /// In fr, this message translates to:
  /// **'Bouture de {name}'**
  String cuttingOf(String name);

  /// No description provided for @propagate.
  ///
  /// In fr, this message translates to:
  /// **'Créer une bouture'**
  String get propagate;

  /// No description provided for @pgPickTitle.
  ///
  /// In fr, this message translates to:
  /// **'Multiplier cette plante'**
  String get pgPickTitle;

  /// No description provided for @pgPickBody.
  ///
  /// In fr, this message translates to:
  /// **'Cette plante se multiplie de plusieurs façons. Le geste choisi décide des étapes.'**
  String get pgPickBody;

  /// No description provided for @pgRecommended.
  ///
  /// In fr, this message translates to:
  /// **'Conseillée'**
  String get pgRecommended;

  /// No description provided for @pgIntroTitle.
  ///
  /// In fr, this message translates to:
  /// **'{name} de {species}'**
  String pgIntroTitle(String name, String species);

  /// No description provided for @pgIntroBody.
  ///
  /// In fr, this message translates to:
  /// **'{count} étapes. Chacune est montrée en geste, puis dite en une phrase, adaptée à l’espèce quand elle est connue.'**
  String pgIntroBody(int count);

  /// No description provided for @pgStartCutting.
  ///
  /// In fr, this message translates to:
  /// **'Créer la bouture'**
  String get pgStartCutting;

  /// No description provided for @pgStartPlant.
  ///
  /// In fr, this message translates to:
  /// **'Créer la plante'**
  String get pgStartPlant;

  /// No description provided for @pgNoteSpot.
  ///
  /// In fr, this message translates to:
  /// **'À repérer'**
  String get pgNoteSpot;

  /// No description provided for @pgNoteAvoid.
  ///
  /// In fr, this message translates to:
  /// **'À éviter'**
  String get pgNoteAvoid;

  /// No description provided for @pgNoteUsual.
  ///
  /// In fr, this message translates to:
  /// **'En général'**
  String get pgNoteUsual;

  /// No description provided for @pgNoteMedium.
  ///
  /// In fr, this message translates to:
  /// **'Enracinement'**
  String get pgNoteMedium;

  /// No description provided for @pgMediumWater.
  ///
  /// In fr, this message translates to:
  /// **'Dans l’eau'**
  String get pgMediumWater;

  /// No description provided for @pgMediumSubstrate.
  ///
  /// In fr, this message translates to:
  /// **'En substrat léger'**
  String get pgMediumSubstrate;

  /// No description provided for @pgMediumEither.
  ///
  /// In fr, this message translates to:
  /// **'Eau ou substrat léger'**
  String get pgMediumEither;

  /// No description provided for @pgVineName.
  ///
  /// In fr, this message translates to:
  /// **'Bouture de tige'**
  String get pgVineName;

  /// No description provided for @pgVineHint.
  ///
  /// In fr, this message translates to:
  /// **'Un nœud, une coupe nette, l’eau'**
  String get pgVineHint;

  /// No description provided for @pgVineNodeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Le nœud'**
  String get pgVineNodeTitle;

  /// No description provided for @pgVineNodeBody.
  ///
  /// In fr, this message translates to:
  /// **'Le renflement d’où part une feuille, souvent doublé d’une racine aérienne. La bouture en garde au moins un.'**
  String get pgVineNodeBody;

  /// No description provided for @pgVineNodeNote.
  ///
  /// In fr, this message translates to:
  /// **'Nœud et racine aérienne'**
  String get pgVineNodeNote;

  /// No description provided for @pgVineCutTitle.
  ///
  /// In fr, this message translates to:
  /// **'La coupe'**
  String get pgVineCutTitle;

  /// No description provided for @pgVineCutBody.
  ///
  /// In fr, this message translates to:
  /// **'Lame propre, coupe nette à un centimètre sous le nœud. Le nœud reste du côté de la bouture.'**
  String get pgVineCutBody;

  /// No description provided for @pgVineCutNote.
  ///
  /// In fr, this message translates to:
  /// **'Couper au-dessus du nœud'**
  String get pgVineCutNote;

  /// No description provided for @pgVineClearTitle.
  ///
  /// In fr, this message translates to:
  /// **'Le nœud dégagé'**
  String get pgVineClearTitle;

  /// No description provided for @pgVineClearBody.
  ///
  /// In fr, this message translates to:
  /// **'Les feuilles qui tremperaient sont retirées. Deux ou trois feuilles en haut nourrissent la bouture.'**
  String get pgVineClearBody;

  /// No description provided for @pgVineWaterTitle.
  ///
  /// In fr, this message translates to:
  /// **'L’eau'**
  String get pgVineWaterTitle;

  /// No description provided for @pgVineWaterBody.
  ///
  /// In fr, this message translates to:
  /// **'Le nœud sous la surface, les feuilles au-dessus. Lumière vive, sans soleil direct.'**
  String get pgVineWaterBody;

  /// No description provided for @pgVineRootsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Les racines'**
  String get pgVineRootsTitle;

  /// No description provided for @pgVineRootsBody.
  ///
  /// In fr, this message translates to:
  /// **'Elles sortent du nœud, pas du bas de la tige. L’eau se change chaque semaine.'**
  String get pgVineRootsBody;

  /// No description provided for @pgVineRootsNote.
  ///
  /// In fr, this message translates to:
  /// **'Premières racines en deux à six semaines'**
  String get pgVineRootsNote;

  /// No description provided for @pgVinePotTitle.
  ///
  /// In fr, this message translates to:
  /// **'Le pot'**
  String get pgVinePotTitle;

  /// No description provided for @pgVinePotBody.
  ///
  /// In fr, this message translates to:
  /// **'À quelques centimètres de racines, la bouture passe en terreau léger. Le nœud reste à fleur de terre.'**
  String get pgVinePotBody;

  /// No description provided for @pgSoftName.
  ///
  /// In fr, this message translates to:
  /// **'Bouture de tige tendre'**
  String get pgSoftName;

  /// No description provided for @pgSoftHint.
  ///
  /// In fr, this message translates to:
  /// **'Un jeune brin, des racines rapides'**
  String get pgSoftHint;

  /// No description provided for @pgSoftStemTitle.
  ///
  /// In fr, this message translates to:
  /// **'Le brin'**
  String get pgSoftStemTitle;

  /// No description provided for @pgSoftStemBody.
  ///
  /// In fr, this message translates to:
  /// **'Un jeune brin ferme, sans fleur, de dix centimètres environ. Le vieux bois s’enracine mal.'**
  String get pgSoftStemBody;

  /// No description provided for @pgSoftCutTitle.
  ///
  /// In fr, this message translates to:
  /// **'La coupe'**
  String get pgSoftCutTitle;

  /// No description provided for @pgSoftCutBody.
  ///
  /// In fr, this message translates to:
  /// **'Lame propre, coupe juste sous une paire de feuilles. Les racines partiront de là.'**
  String get pgSoftCutBody;

  /// No description provided for @pgSoftStripTitle.
  ///
  /// In fr, this message translates to:
  /// **'Les feuilles du bas'**
  String get pgSoftStripTitle;

  /// No description provided for @pgSoftStripBody.
  ///
  /// In fr, this message translates to:
  /// **'La paire du bas est retirée : la tige reste nue sur trois ou quatre centimètres.'**
  String get pgSoftStripBody;

  /// No description provided for @pgSoftStripNote.
  ///
  /// In fr, this message translates to:
  /// **'Laisser une feuille sous l’eau'**
  String get pgSoftStripNote;

  /// No description provided for @pgSoftRootTitle.
  ///
  /// In fr, this message translates to:
  /// **'L’enracinement'**
  String get pgSoftRootTitle;

  /// No description provided for @pgSoftRootBody.
  ///
  /// In fr, this message translates to:
  /// **'La tige nue trempe, les feuilles restent au sec. Lumière vive, sans soleil direct.'**
  String get pgSoftRootBody;

  /// No description provided for @pgSoftRootsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Les racines'**
  String get pgSoftRootsTitle;

  /// No description provided for @pgSoftRootsBody.
  ///
  /// In fr, this message translates to:
  /// **'Fines et nombreuses, elles partent de toute la partie immergée.'**
  String get pgSoftRootsBody;

  /// No description provided for @pgSoftRootsNote.
  ///
  /// In fr, this message translates to:
  /// **'Premières racines en une à trois semaines'**
  String get pgSoftRootsNote;

  /// No description provided for @pgSoftPotTitle.
  ///
  /// In fr, this message translates to:
  /// **'Le repiquage'**
  String get pgSoftPotTitle;

  /// No description provided for @pgSoftPotBody.
  ///
  /// In fr, this message translates to:
  /// **'Repiquée tôt, à deux ou trois centimètres de racines : une tige tendre supporte mal l\'attente.'**
  String get pgSoftPotBody;

  /// No description provided for @pgLeafName.
  ///
  /// In fr, this message translates to:
  /// **'Bouture de feuille'**
  String get pgLeafName;

  /// No description provided for @pgLeafHint.
  ///
  /// In fr, this message translates to:
  /// **'Plus lente, une feuille suffit'**
  String get pgLeafHint;

  /// No description provided for @pgLeafChooseTitle.
  ///
  /// In fr, this message translates to:
  /// **'La feuille'**
  String get pgLeafChooseTitle;

  /// No description provided for @pgLeafChooseBody.
  ///
  /// In fr, this message translates to:
  /// **'Une feuille mature, ferme, sans marque. Les jeunes feuilles manquent de réserves.'**
  String get pgLeafChooseBody;

  /// No description provided for @pgLeafCutTitle.
  ///
  /// In fr, this message translates to:
  /// **'La coupe'**
  String get pgLeafCutTitle;

  /// No description provided for @pgLeafCutBody.
  ///
  /// In fr, this message translates to:
  /// **'Lame propre, coupe à la base de la feuille, au ras du substrat.'**
  String get pgLeafCutBody;

  /// No description provided for @pgLeafSplitTitle.
  ///
  /// In fr, this message translates to:
  /// **'Les segments'**
  String get pgLeafSplitTitle;

  /// No description provided for @pgLeafSplitBody.
  ///
  /// In fr, this message translates to:
  /// **'La feuille se partage en morceaux de cinq à huit centimètres. Un V taillé en bas de chacun dit quel bout va en terre.'**
  String get pgLeafSplitBody;

  /// No description provided for @pgLeafSplitNote.
  ///
  /// In fr, this message translates to:
  /// **'Le V marque le bas'**
  String get pgLeafSplitNote;

  /// No description provided for @pgLeafCallusTitle.
  ///
  /// In fr, this message translates to:
  /// **'Le séchage'**
  String get pgLeafCallusTitle;

  /// No description provided for @pgLeafCallusBody.
  ///
  /// In fr, this message translates to:
  /// **'Les coupes sèchent à l’air, à l’ombre, avant d’aller en terre.'**
  String get pgLeafCallusBody;

  /// No description provided for @pgLeafCallusNote.
  ///
  /// In fr, this message translates to:
  /// **'Un à deux jours de séchage'**
  String get pgLeafCallusNote;

  /// No description provided for @pgLeafPlantTitle.
  ///
  /// In fr, this message translates to:
  /// **'Le substrat'**
  String get pgLeafPlantTitle;

  /// No description provided for @pgLeafPlantBody.
  ///
  /// In fr, this message translates to:
  /// **'Le V s’enfonce de deux centimètres dans un substrat drainant.'**
  String get pgLeafPlantBody;

  /// No description provided for @pgLeafPlantNote.
  ///
  /// In fr, this message translates to:
  /// **'Planter un segment à l’envers'**
  String get pgLeafPlantNote;

  /// No description provided for @pgLeafGrowthTitle.
  ///
  /// In fr, this message translates to:
  /// **'La reprise'**
  String get pgLeafGrowthTitle;

  /// No description provided for @pgLeafGrowthBody.
  ///
  /// In fr, this message translates to:
  /// **'Les racines viennent d’abord, la jeune pousse sort du substrat à côté du segment.'**
  String get pgLeafGrowthBody;

  /// No description provided for @pgLeafGrowthNote.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle pousse en deux à quatre mois'**
  String get pgLeafGrowthNote;

  /// No description provided for @pgDivisionName.
  ///
  /// In fr, this message translates to:
  /// **'Division'**
  String get pgDivisionName;

  /// No description provided for @pgDivisionHint.
  ///
  /// In fr, this message translates to:
  /// **'Rapide et sûre, la touffe se partage'**
  String get pgDivisionHint;

  /// No description provided for @pgDivPlantTitle.
  ///
  /// In fr, this message translates to:
  /// **'La touffe'**
  String get pgDivPlantTitle;

  /// No description provided for @pgDivPlantBody.
  ///
  /// In fr, this message translates to:
  /// **'La plante se sort du pot en entier. Un substrat arrosé la veille tient mieux.'**
  String get pgDivPlantBody;

  /// No description provided for @pgDivUnpotTitle.
  ///
  /// In fr, this message translates to:
  /// **'Le dépotage'**
  String get pgDivUnpotTitle;

  /// No description provided for @pgDivUnpotBody.
  ///
  /// In fr, this message translates to:
  /// **'Le pot glisse le long de la motte, la plante est libre.'**
  String get pgDivUnpotBody;

  /// No description provided for @pgDivRootsTitle.
  ///
  /// In fr, this message translates to:
  /// **'La motte'**
  String get pgDivRootsTitle;

  /// No description provided for @pgDivRootsBody.
  ///
  /// In fr, this message translates to:
  /// **'La terre s’émiette jusqu’à voir les racines et le pied des pousses.'**
  String get pgDivRootsBody;

  /// No description provided for @pgDivClustersTitle.
  ///
  /// In fr, this message translates to:
  /// **'Les deux groupes'**
  String get pgDivClustersTitle;

  /// No description provided for @pgDivClustersBody.
  ///
  /// In fr, this message translates to:
  /// **'Chaque groupe garde ses pousses et ses racines.'**
  String get pgDivClustersBody;

  /// No description provided for @pgDivClustersNote.
  ///
  /// In fr, this message translates to:
  /// **'Feuilles et racines de chaque côté'**
  String get pgDivClustersNote;

  /// No description provided for @pgDivSplitTitle.
  ///
  /// In fr, this message translates to:
  /// **'La séparation'**
  String get pgDivSplitTitle;

  /// No description provided for @pgDivSplitBody.
  ///
  /// In fr, this message translates to:
  /// **'Les groupes se défont à la main. La lame ne sert que si les couronnes tiennent.'**
  String get pgDivSplitBody;

  /// No description provided for @pgDivSplitNote.
  ///
  /// In fr, this message translates to:
  /// **'Couper une tige au-dessus de la terre'**
  String get pgDivSplitNote;

  /// No description provided for @pgDivRepotTitle.
  ///
  /// In fr, this message translates to:
  /// **'Le rempotage'**
  String get pgDivRepotTitle;

  /// No description provided for @pgDivRepotBody.
  ///
  /// In fr, this message translates to:
  /// **'Chaque division part dans son pot, à la même profondeur qu’avant, et reçoit un premier arrosage.'**
  String get pgDivRepotBody;

  /// No description provided for @pgOffsetName.
  ///
  /// In fr, this message translates to:
  /// **'Séparer un rejet'**
  String get pgOffsetName;

  /// No description provided for @pgOffsetHint.
  ///
  /// In fr, this message translates to:
  /// **'Le rejet part avec ses racines'**
  String get pgOffsetHint;

  /// No description provided for @pgOffSpotTitle.
  ///
  /// In fr, this message translates to:
  /// **'Le rejet'**
  String get pgOffSpotTitle;

  /// No description provided for @pgOffSpotBody.
  ///
  /// In fr, this message translates to:
  /// **'Un rejet du tiers de la mère, avec ses propres feuilles, est prêt à partir.'**
  String get pgOffSpotBody;

  /// No description provided for @pgOffSpotNote.
  ///
  /// In fr, this message translates to:
  /// **'Rejet déjà formé'**
  String get pgOffSpotNote;

  /// No description provided for @pgOffClearTitle.
  ///
  /// In fr, this message translates to:
  /// **'Le dégagement'**
  String get pgOffClearTitle;

  /// No description provided for @pgOffClearBody.
  ///
  /// In fr, this message translates to:
  /// **'Le substrat s’écarte autour du pied : le lien avec la plante mère paraît.'**
  String get pgOffClearBody;

  /// No description provided for @pgOffDetachTitle.
  ///
  /// In fr, this message translates to:
  /// **'La séparation'**
  String get pgOffDetachTitle;

  /// No description provided for @pgOffDetachBody.
  ///
  /// In fr, this message translates to:
  /// **'Le rejet se détache du lien, avec ses racines. La lame ne sert que si le lien est ligneux.'**
  String get pgOffDetachBody;

  /// No description provided for @pgOffDetachNote.
  ///
  /// In fr, this message translates to:
  /// **'Arracher le rejet sans racines'**
  String get pgOffDetachNote;

  /// No description provided for @pgOffRootsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Les racines'**
  String get pgOffRootsTitle;

  /// No description provided for @pgOffRootsBody.
  ///
  /// In fr, this message translates to:
  /// **'Quelques racines propres suffisent. Sans elles, le rejet sèche avant de reprendre.'**
  String get pgOffRootsBody;

  /// No description provided for @pgOffPotTitle.
  ///
  /// In fr, this message translates to:
  /// **'Le pot'**
  String get pgOffPotTitle;

  /// No description provided for @pgOffPotBody.
  ///
  /// In fr, this message translates to:
  /// **'Un petit pot, le substrat de l’espèce, et un arrosage léger.'**
  String get pgOffPotBody;

  /// No description provided for @pgOffSettleTitle.
  ///
  /// In fr, this message translates to:
  /// **'La reprise'**
  String get pgOffSettleTitle;

  /// No description provided for @pgOffSettleBody.
  ///
  /// In fr, this message translates to:
  /// **'Une feuille neuve au cœur dit que le rejet a pris.'**
  String get pgOffSettleBody;

  /// No description provided for @pgOffSettleNote.
  ///
  /// In fr, this message translates to:
  /// **'Reprise en trois à six semaines'**
  String get pgOffSettleNote;

  /// No description provided for @pgKeikiName.
  ///
  /// In fr, this message translates to:
  /// **'Séparer un keiki'**
  String get pgKeikiName;

  /// No description provided for @pgKeikiHint.
  ///
  /// In fr, this message translates to:
  /// **'Le rejet d’orchidée part avec ses racines'**
  String get pgKeikiHint;

  /// No description provided for @pgKeikiSpotTitle.
  ///
  /// In fr, this message translates to:
  /// **'Le keiki'**
  String get pgKeikiSpotTitle;

  /// No description provided for @pgKeikiSpotBody.
  ///
  /// In fr, this message translates to:
  /// **'Un jeune plant naît sur un nœud de la hampe : deux feuilles et des racines aériennes le rendent identifiable.'**
  String get pgKeikiSpotBody;

  /// No description provided for @pgKeikiSpotNote.
  ///
  /// In fr, this message translates to:
  /// **'Rejet déjà formé'**
  String get pgKeikiSpotNote;

  /// No description provided for @pgKeikiWaitTitle.
  ///
  /// In fr, this message translates to:
  /// **'Les racines'**
  String get pgKeikiWaitTitle;

  /// No description provided for @pgKeikiWaitBody.
  ///
  /// In fr, this message translates to:
  /// **'Les racines s’allongent sur la hampe. Trois à cinq, longues de quelques centimètres, et le keiki vivra seul.'**
  String get pgKeikiWaitBody;

  /// No description provided for @pgKeikiWaitNote.
  ///
  /// In fr, this message translates to:
  /// **'Racines prêtes en deux à trois mois'**
  String get pgKeikiWaitNote;

  /// No description provided for @pgKeikiDetachTitle.
  ///
  /// In fr, this message translates to:
  /// **'La séparation'**
  String get pgKeikiDetachTitle;

  /// No description provided for @pgKeikiDetachBody.
  ///
  /// In fr, this message translates to:
  /// **'La hampe se coupe de part et d’autre du keiki, à un ou deux centimètres. Tirer meurtrissait la base.'**
  String get pgKeikiDetachBody;

  /// No description provided for @pgKeikiDetachNote.
  ///
  /// In fr, this message translates to:
  /// **'Arracher le keiki'**
  String get pgKeikiDetachNote;

  /// No description provided for @pgKeikiRootsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Les racines du keiki'**
  String get pgKeikiRootsTitle;

  /// No description provided for @pgKeikiRootsBody.
  ///
  /// In fr, this message translates to:
  /// **'Le keiki garde ses racines aériennes : ce sont elles qui reprennent dans le pot.'**
  String get pgKeikiRootsBody;

  /// No description provided for @pgKeikiPotTitle.
  ///
  /// In fr, this message translates to:
  /// **'Le pot'**
  String get pgKeikiPotTitle;

  /// No description provided for @pgKeikiPotBody.
  ///
  /// In fr, this message translates to:
  /// **'Un petit pot d’écorces, la base du keiki affleurant le substrat, sans l’enterrer.'**
  String get pgKeikiPotBody;

  /// No description provided for @pgKeikiSettleTitle.
  ///
  /// In fr, this message translates to:
  /// **'La reprise'**
  String get pgKeikiSettleTitle;

  /// No description provided for @pgKeikiSettleBody.
  ///
  /// In fr, this message translates to:
  /// **'Une feuille neuve au cœur dit que le keiki a pris.'**
  String get pgKeikiSettleBody;

  /// No description provided for @pgKeikiSettleNote.
  ///
  /// In fr, this message translates to:
  /// **'Reprise en un à deux mois'**
  String get pgKeikiSettleNote;

  /// No description provided for @pgSegmentName.
  ///
  /// In fr, this message translates to:
  /// **'Bouture de segment'**
  String get pgSegmentName;

  /// No description provided for @pgSegmentHint.
  ///
  /// In fr, this message translates to:
  /// **'Un segment détaché, séché, planté'**
  String get pgSegmentHint;

  /// No description provided for @pgSegChooseTitle.
  ///
  /// In fr, this message translates to:
  /// **'Le segment'**
  String get pgSegChooseTitle;

  /// No description provided for @pgSegChooseBody.
  ///
  /// In fr, this message translates to:
  /// **'Un segment terminal ferme et sans ride, de deux ou trois articles.'**
  String get pgSegChooseBody;

  /// No description provided for @pgSegDetachTitle.
  ///
  /// In fr, this message translates to:
  /// **'Le détachement'**
  String get pgSegDetachTitle;

  /// No description provided for @pgSegDetachBody.
  ///
  /// In fr, this message translates to:
  /// **'Le segment se détache à l’articulation, en le tournant. Une lame propre si l’article résiste.'**
  String get pgSegDetachBody;

  /// No description provided for @pgSegDetachNote.
  ///
  /// In fr, this message translates to:
  /// **'Tirer et déchirer l’article'**
  String get pgSegDetachNote;

  /// No description provided for @pgSegWoundTitle.
  ///
  /// In fr, this message translates to:
  /// **'La plaie'**
  String get pgSegWoundTitle;

  /// No description provided for @pgSegWoundBody.
  ///
  /// In fr, this message translates to:
  /// **'La coupe est claire et humide. Mise en terre tout de suite, elle pourrit.'**
  String get pgSegWoundBody;

  /// No description provided for @pgSegCallusTitle.
  ///
  /// In fr, this message translates to:
  /// **'La cicatrisation'**
  String get pgSegCallusTitle;

  /// No description provided for @pgSegCallusBody.
  ///
  /// In fr, this message translates to:
  /// **'La plaie sèche à l’air, à l’ombre, jusqu’à former un cal mat.'**
  String get pgSegCallusBody;

  /// No description provided for @pgSegCallusNote.
  ///
  /// In fr, this message translates to:
  /// **'Trois à sept jours de séchage'**
  String get pgSegCallusNote;

  /// No description provided for @pgSegPlantTitle.
  ///
  /// In fr, this message translates to:
  /// **'Le substrat'**
  String get pgSegPlantTitle;

  /// No description provided for @pgSegPlantBody.
  ///
  /// In fr, this message translates to:
  /// **'Le cal se pose à peine dans un substrat très drainant, sur un centimètre.'**
  String get pgSegPlantBody;

  /// No description provided for @pgSegPlantNote.
  ///
  /// In fr, this message translates to:
  /// **'Enterrer le segment'**
  String get pgSegPlantNote;

  /// No description provided for @pgSegRootsTitle.
  ///
  /// In fr, this message translates to:
  /// **'La reprise'**
  String get pgSegRootsTitle;

  /// No description provided for @pgSegRootsBody.
  ///
  /// In fr, this message translates to:
  /// **'Les racines viennent d’abord, un nouvel article ensuite. L’arrosage attend que les racines tiennent.'**
  String get pgSegRootsBody;

  /// No description provided for @parentPlant.
  ///
  /// In fr, this message translates to:
  /// **'Plante mère'**
  String get parentPlant;

  /// No description provided for @schedule.
  ///
  /// In fr, this message translates to:
  /// **'Planning'**
  String get schedule;

  /// No description provided for @editPlant.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la plante'**
  String get editPlant;

  /// No description provided for @archivePlant.
  ///
  /// In fr, this message translates to:
  /// **'Archiver la plante'**
  String get archivePlant;

  /// No description provided for @archiveReasonTitle.
  ///
  /// In fr, this message translates to:
  /// **'Motif'**
  String get archiveReasonTitle;

  /// No description provided for @reasonDied.
  ///
  /// In fr, this message translates to:
  /// **'Morte'**
  String get reasonDied;

  /// No description provided for @reasonGiven.
  ///
  /// In fr, this message translates to:
  /// **'Donnée'**
  String get reasonGiven;

  /// No description provided for @reasonSold.
  ///
  /// In fr, this message translates to:
  /// **'Vendue'**
  String get reasonSold;

  /// No description provided for @reasonOther.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get reasonOther;

  /// No description provided for @plantArchived.
  ///
  /// In fr, this message translates to:
  /// **'{name} archivée'**
  String plantArchived(String name);

  /// No description provided for @restore.
  ///
  /// In fr, this message translates to:
  /// **'Restaurer'**
  String get restore;

  /// No description provided for @plantRestored.
  ///
  /// In fr, this message translates to:
  /// **'{name} restaurée'**
  String plantRestored(String name);

  /// No description provided for @deleteForever.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer définitivement'**
  String get deleteForever;

  /// No description provided for @deleteForeverConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Cette plante et tout son historique seront supprimés.'**
  String get deleteForeverConfirm;

  /// No description provided for @noHistoryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune action pour l\'instant'**
  String get noHistoryTitle;

  /// No description provided for @noHistorySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Chaque soin apparaîtra ici.'**
  String get noHistorySubtitle;

  /// No description provided for @noPhotosTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune photo'**
  String get noPhotosTitle;

  /// No description provided for @noPhotosSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez une photo pour suivre sa croissance.'**
  String get noPhotosSubtitle;

  /// No description provided for @setAsPrimary.
  ///
  /// In fr, this message translates to:
  /// **'Photo principale'**
  String get setAsPrimary;

  /// No description provided for @deletePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la photo'**
  String get deletePhoto;

  /// No description provided for @health.
  ///
  /// In fr, this message translates to:
  /// **'Santé'**
  String get health;

  /// No description provided for @healthHealthy.
  ///
  /// In fr, this message translates to:
  /// **'En forme'**
  String get healthHealthy;

  /// No description provided for @healthWatch.
  ///
  /// In fr, this message translates to:
  /// **'À surveiller'**
  String get healthWatch;

  /// No description provided for @healthSick.
  ///
  /// In fr, this message translates to:
  /// **'Malade'**
  String get healthSick;

  /// No description provided for @healthIssue.
  ///
  /// In fr, this message translates to:
  /// **'Problème'**
  String get healthIssue;

  /// No description provided for @issueOverwatering.
  ///
  /// In fr, this message translates to:
  /// **'Excès d\'eau'**
  String get issueOverwatering;

  /// No description provided for @issueUnderwatering.
  ///
  /// In fr, this message translates to:
  /// **'Manque d\'eau'**
  String get issueUnderwatering;

  /// No description provided for @issuePests.
  ///
  /// In fr, this message translates to:
  /// **'Ravageurs'**
  String get issuePests;

  /// No description provided for @issueDisease.
  ///
  /// In fr, this message translates to:
  /// **'Maladie'**
  String get issueDisease;

  /// No description provided for @issueRootRot.
  ///
  /// In fr, this message translates to:
  /// **'Pourriture des racines'**
  String get issueRootRot;

  /// No description provided for @issueTransplantShock.
  ///
  /// In fr, this message translates to:
  /// **'Choc de rempotage'**
  String get issueTransplantShock;

  /// No description provided for @issueDeficiency.
  ///
  /// In fr, this message translates to:
  /// **'Carence'**
  String get issueDeficiency;

  /// No description provided for @issueSunburn.
  ///
  /// In fr, this message translates to:
  /// **'Brûlure du soleil'**
  String get issueSunburn;

  /// No description provided for @issueFrost.
  ///
  /// In fr, this message translates to:
  /// **'Gel'**
  String get issueFrost;

  /// No description provided for @needsSection.
  ///
  /// In fr, this message translates to:
  /// **'Besoins'**
  String get needsSection;

  /// No description provided for @detailsSection.
  ///
  /// In fr, this message translates to:
  /// **'Détails'**
  String get detailsSection;

  /// No description provided for @lifespan.
  ///
  /// In fr, this message translates to:
  /// **'Cycle de vie'**
  String get lifespan;

  /// No description provided for @lifespanAnnual.
  ///
  /// In fr, this message translates to:
  /// **'Annuelle'**
  String get lifespanAnnual;

  /// No description provided for @lifespanBiennial.
  ///
  /// In fr, this message translates to:
  /// **'Bisannuelle'**
  String get lifespanBiennial;

  /// No description provided for @lifespanPerennial.
  ///
  /// In fr, this message translates to:
  /// **'Vivace'**
  String get lifespanPerennial;

  /// No description provided for @hardiness.
  ///
  /// In fr, this message translates to:
  /// **'Rusticité'**
  String get hardiness;

  /// No description provided for @hardinessHardy.
  ///
  /// In fr, this message translates to:
  /// **'Rustique'**
  String get hardinessHardy;

  /// No description provided for @hardinessTender.
  ///
  /// In fr, this message translates to:
  /// **'Gélive'**
  String get hardinessTender;

  /// No description provided for @cuttingMonth.
  ///
  /// In fr, this message translates to:
  /// **'Mois de bouturage'**
  String get cuttingMonth;

  /// No description provided for @noSchedule.
  ///
  /// In fr, this message translates to:
  /// **'Aucun rappel'**
  String get noSchedule;

  /// No description provided for @addRoutine.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une routine'**
  String get addRoutine;

  /// No description provided for @frequency.
  ///
  /// In fr, this message translates to:
  /// **'Fréquence'**
  String get frequency;

  /// No description provided for @strategyFixed.
  ///
  /// In fr, this message translates to:
  /// **'Fixe'**
  String get strategyFixed;

  /// No description provided for @strategySeasonal.
  ///
  /// In fr, this message translates to:
  /// **'Saisonnier'**
  String get strategySeasonal;

  /// No description provided for @strategyManual.
  ///
  /// In fr, this message translates to:
  /// **'Manuel'**
  String get strategyManual;

  /// No description provided for @strategySeasonalHint.
  ///
  /// In fr, this message translates to:
  /// **'Espacé en hiver, rapproché en été.'**
  String get strategySeasonalHint;

  /// No description provided for @strategyManualHint.
  ///
  /// In fr, this message translates to:
  /// **'Aucun rappel automatique.'**
  String get strategyManualHint;

  /// No description provided for @strategyFixedHint.
  ///
  /// In fr, this message translates to:
  /// **'Le même intervalle toute l\'année.'**
  String get strategyFixedHint;

  /// No description provided for @enabled.
  ///
  /// In fr, this message translates to:
  /// **'Activée'**
  String get enabled;

  /// No description provided for @interval.
  ///
  /// In fr, this message translates to:
  /// **'Intervalle'**
  String get interval;

  /// No description provided for @intervalSuggested.
  ///
  /// In fr, this message translates to:
  /// **'Intervalle conseillé'**
  String get intervalSuggested;

  /// No description provided for @intervalSuggestedDays.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Intervalle conseillé : 1 jour} other{Intervalle conseillé : {count} jours}}'**
  String intervalSuggestedDays(int count);

  /// No description provided for @daysCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 jour} other{{count} jours}}'**
  String daysCount(int count);

  /// No description provided for @lastDone.
  ///
  /// In fr, this message translates to:
  /// **'Dernier : {date}'**
  String lastDone(String date);

  /// No description provided for @nextDue.
  ///
  /// In fr, this message translates to:
  /// **'Prochain : {date}'**
  String nextDue(String date);

  /// No description provided for @deleteRoutine.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la routine'**
  String get deleteRoutine;

  /// No description provided for @snooze.
  ///
  /// In fr, this message translates to:
  /// **'Plus tard'**
  String get snooze;

  /// No description provided for @snoozed.
  ///
  /// In fr, this message translates to:
  /// **'{name} · reportée à demain'**
  String snoozed(String name);

  /// No description provided for @measurements.
  ///
  /// In fr, this message translates to:
  /// **'Mesures'**
  String get measurements;

  /// No description provided for @measurementDelta.
  ///
  /// In fr, this message translates to:
  /// **'{delta} depuis {date}'**
  String measurementDelta(String delta, String date);

  /// No description provided for @whatDidYouDo.
  ///
  /// In fr, this message translates to:
  /// **'Action'**
  String get whatDidYouDo;

  /// No description provided for @when.
  ///
  /// In fr, this message translates to:
  /// **'Quand'**
  String get when;

  /// No description provided for @noteHint.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une note…'**
  String get noteHint;

  /// No description provided for @quantity.
  ///
  /// In fr, this message translates to:
  /// **'Quantité'**
  String get quantity;

  /// No description provided for @value.
  ///
  /// In fr, this message translates to:
  /// **'Valeur'**
  String get value;

  /// No description provided for @measureHeight.
  ///
  /// In fr, this message translates to:
  /// **'Hauteur'**
  String get measureHeight;

  /// No description provided for @measureWidth.
  ///
  /// In fr, this message translates to:
  /// **'Largeur'**
  String get measureWidth;

  /// No description provided for @measureLeaves.
  ///
  /// In fr, this message translates to:
  /// **'Feuilles'**
  String get measureLeaves;

  /// No description provided for @measurePot.
  ///
  /// In fr, this message translates to:
  /// **'Pot'**
  String get measurePot;

  /// No description provided for @record.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get record;

  /// No description provided for @addNote.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une note'**
  String get addNote;

  /// No description provided for @addPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une photo'**
  String get addPhoto;

  /// No description provided for @camera.
  ///
  /// In fr, this message translates to:
  /// **'Appareil photo'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In fr, this message translates to:
  /// **'Galerie'**
  String get gallery;

  /// No description provided for @photoError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ajouter la photo. Réessayez.'**
  String get photoError;

  /// No description provided for @newActionType.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau type d\'action'**
  String get newActionType;

  /// No description provided for @actionTypeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get actionTypeLabel;

  /// No description provided for @actionTypeLabelHint.
  ///
  /// In fr, this message translates to:
  /// **'Brumisation'**
  String get actionTypeLabelHint;

  /// No description provided for @actionTypeEmoji.
  ///
  /// In fr, this message translates to:
  /// **'Emoji'**
  String get actionTypeEmoji;

  /// No description provided for @actionTypes.
  ///
  /// In fr, this message translates to:
  /// **'Types d\'actions'**
  String get actionTypes;

  /// No description provided for @actionTypesHint.
  ///
  /// In fr, this message translates to:
  /// **'Créez vos propres actions, en plus des types intégrés.'**
  String get actionTypesHint;

  /// No description provided for @deleteActionType.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce type'**
  String get deleteActionType;

  /// No description provided for @builtin.
  ///
  /// In fr, this message translates to:
  /// **'Intégré'**
  String get builtin;

  /// No description provided for @gardenTitle.
  ///
  /// In fr, this message translates to:
  /// **'Jardin'**
  String get gardenTitle;

  /// No description provided for @locations.
  ///
  /// In fr, this message translates to:
  /// **'Emplacements'**
  String get locations;

  /// No description provided for @newLocationTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouvel emplacement'**
  String get newLocationTitle;

  /// No description provided for @locationName.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get locationName;

  /// No description provided for @locationNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Salon'**
  String get locationNameHint;

  /// No description provided for @locationIcon.
  ///
  /// In fr, this message translates to:
  /// **'Icône'**
  String get locationIcon;

  /// No description provided for @parentLocation.
  ///
  /// In fr, this message translates to:
  /// **'Dans'**
  String get parentLocation;

  /// No description provided for @noParent.
  ///
  /// In fr, this message translates to:
  /// **'Aucun'**
  String get noParent;

  /// No description provided for @light.
  ///
  /// In fr, this message translates to:
  /// **'Lumière'**
  String get light;

  /// No description provided for @lightLow.
  ///
  /// In fr, this message translates to:
  /// **'Faible'**
  String get lightLow;

  /// No description provided for @lightMedium.
  ///
  /// In fr, this message translates to:
  /// **'Moyenne'**
  String get lightMedium;

  /// No description provided for @lightHigh.
  ///
  /// In fr, this message translates to:
  /// **'Forte'**
  String get lightHigh;

  /// No description provided for @orientation.
  ///
  /// In fr, this message translates to:
  /// **'Orientation'**
  String get orientation;

  /// No description provided for @orientationHint.
  ///
  /// In fr, this message translates to:
  /// **'Sud-ouest'**
  String get orientationHint;

  /// No description provided for @deleteLocation.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer l\'emplacement'**
  String get deleteLocation;

  /// No description provided for @deleteLocationHint.
  ///
  /// In fr, this message translates to:
  /// **'Les plantes ne seront pas supprimées.'**
  String get deleteLocationHint;

  /// No description provided for @noLocationsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun emplacement'**
  String get noLocationsTitle;

  /// No description provided for @noLocationsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Créez un salon, un balcon, une serre…'**
  String get noLocationsSubtitle;

  /// No description provided for @editLocation.
  ///
  /// In fr, this message translates to:
  /// **'Modifier l\'emplacement'**
  String get editLocation;

  /// No description provided for @noPlantsHereTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune plante ici'**
  String get noPlantsHereTitle;

  /// No description provided for @noPlantsHereSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Déplacez-y des plantes ou ajoutez-en une.'**
  String get noPlantsHereSubtitle;

  /// No description provided for @chooseLocation.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un emplacement'**
  String get chooseLocation;

  /// No description provided for @defaultLivingRoom.
  ///
  /// In fr, this message translates to:
  /// **'Salon'**
  String get defaultLivingRoom;

  /// No description provided for @defaultKitchen.
  ///
  /// In fr, this message translates to:
  /// **'Cuisine'**
  String get defaultKitchen;

  /// No description provided for @defaultBedroom.
  ///
  /// In fr, this message translates to:
  /// **'Chambre'**
  String get defaultBedroom;

  /// No description provided for @defaultBalcony.
  ///
  /// In fr, this message translates to:
  /// **'Balcon'**
  String get defaultBalcony;

  /// No description provided for @defaultOffice.
  ///
  /// In fr, this message translates to:
  /// **'Bureau'**
  String get defaultOffice;

  /// No description provided for @defaultBathroom.
  ///
  /// In fr, this message translates to:
  /// **'Salle de bain'**
  String get defaultBathroom;

  /// No description provided for @defaultGarden.
  ///
  /// In fr, this message translates to:
  /// **'Jardin'**
  String get defaultGarden;

  /// No description provided for @defaultGreenhouse.
  ///
  /// In fr, this message translates to:
  /// **'Serre'**
  String get defaultGreenhouse;

  /// No description provided for @profileTitle.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get profileTitle;

  /// No description provided for @yourName.
  ///
  /// In fr, this message translates to:
  /// **'Votre prénom'**
  String get yourName;

  /// No description provided for @yourNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Prénom'**
  String get yourNameHint;

  /// No description provided for @appearance.
  ///
  /// In fr, this message translates to:
  /// **'Apparence'**
  String get appearance;

  /// No description provided for @themeSystem.
  ///
  /// In fr, this message translates to:
  /// **'Système'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In fr, this message translates to:
  /// **'Clair'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In fr, this message translates to:
  /// **'Sombre'**
  String get themeDark;

  /// No description provided for @reduceMotion.
  ///
  /// In fr, this message translates to:
  /// **'Réduire les animations'**
  String get reduceMotion;

  /// No description provided for @reduceMotionHint.
  ///
  /// In fr, this message translates to:
  /// **'Par défaut, le réglage du système s\'applique.'**
  String get reduceMotionHint;

  /// No description provided for @notifications.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @enableNotifications.
  ///
  /// In fr, this message translates to:
  /// **'Rappel quotidien'**
  String get enableNotifications;

  /// No description provided for @notificationTime.
  ///
  /// In fr, this message translates to:
  /// **'Heure'**
  String get notificationTime;

  /// No description provided for @quietDays.
  ///
  /// In fr, this message translates to:
  /// **'Jours silencieux'**
  String get quietDays;

  /// No description provided for @notificationPreview.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu'**
  String get notificationPreview;

  /// No description provided for @notificationHint.
  ///
  /// In fr, this message translates to:
  /// **'Une notification par jour, seulement si un soin est prévu.'**
  String get notificationHint;

  /// No description provided for @notificationPermissionDenied.
  ///
  /// In fr, this message translates to:
  /// **'Autorisez les notifications dans les Réglages de votre téléphone.'**
  String get notificationPermissionDenied;

  /// No description provided for @archives.
  ///
  /// In fr, this message translates to:
  /// **'Anciennes plantes'**
  String get archives;

  /// No description provided for @noArchivesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune ancienne plante'**
  String get noArchivesTitle;

  /// No description provided for @noArchivesSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Les plantes archivées apparaîtront ici.'**
  String get noArchivesSubtitle;

  /// No description provided for @archivedOn.
  ///
  /// In fr, this message translates to:
  /// **'Archivée le {date}'**
  String archivedOn(String date);

  /// No description provided for @units.
  ///
  /// In fr, this message translates to:
  /// **'Unités'**
  String get units;

  /// No description provided for @metric.
  ///
  /// In fr, this message translates to:
  /// **'Métrique'**
  String get metric;

  /// No description provided for @imperial.
  ///
  /// In fr, this message translates to:
  /// **'Impérial'**
  String get imperial;

  /// No description provided for @language.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In fr, this message translates to:
  /// **'Système'**
  String get languageSystem;

  /// No description provided for @account.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get account;

  /// No description provided for @localAccount.
  ///
  /// In fr, this message translates to:
  /// **'Données sur cet appareil'**
  String get localAccount;

  /// No description provided for @localAccountHint.
  ///
  /// In fr, this message translates to:
  /// **'Vos données restent sur ce téléphone.'**
  String get localAccountHint;

  /// No description provided for @version.
  ///
  /// In fr, this message translates to:
  /// **'Version {version}'**
  String version(String version);

  /// No description provided for @tags.
  ///
  /// In fr, this message translates to:
  /// **'Tags'**
  String get tags;

  /// No description provided for @newTag.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau tag'**
  String get newTag;

  /// No description provided for @tagNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Tropicale, Rare, À surveiller…'**
  String get tagNameHint;

  /// No description provided for @noTags.
  ///
  /// In fr, this message translates to:
  /// **'Aucun tag'**
  String get noTags;

  /// No description provided for @manageTags.
  ///
  /// In fr, this message translates to:
  /// **'Gérer les tags'**
  String get manageTags;

  /// No description provided for @onboardingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Toutes vos plantes, ici'**
  String get onboardingTitle;

  /// No description provided for @onboardingSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez-les avec ou sans photo.'**
  String get onboardingSubtitle;

  /// No description provided for @onbPlaceTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre ville'**
  String get onbPlaceTitle;

  /// No description provided for @onbPlaceBody.
  ///
  /// In fr, this message translates to:
  /// **'Pour la météo et l\'arrosage en extérieur. Une ville suffit, la position exacte n\'est pas conservée.'**
  String get onbPlaceBody;

  /// No description provided for @useMyLocation.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser ma position'**
  String get useMyLocation;

  /// No description provided for @locating.
  ///
  /// In fr, this message translates to:
  /// **'Recherche de votre ville…'**
  String get locating;

  /// No description provided for @locationFailed.
  ///
  /// In fr, this message translates to:
  /// **'Position indisponible. Vous pourrez choisir une ville dans Profil › Météo.'**
  String get locationFailed;

  /// No description provided for @locationUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Position indisponible.'**
  String get locationUnavailable;

  /// No description provided for @onbHomeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre intérieur'**
  String get onbHomeTitle;

  /// No description provided for @onbHomeBody.
  ///
  /// In fr, this message translates to:
  /// **'Les capteurs d\'Apple Maison et de Google Home donnent la température et l\'humidité de la pièce. Les conseils et les diagnostics des plantes d\'intérieur en tiennent compte. La mesure ne quitte pas l\'application.'**
  String get onbHomeBody;

  /// No description provided for @homeClimate.
  ///
  /// In fr, this message translates to:
  /// **'Capteurs de la maison'**
  String get homeClimate;

  /// No description provided for @homeClimateHint.
  ///
  /// In fr, this message translates to:
  /// **'La température et l\'humidité d\'un capteur de la maison ajustent les conseils des plantes d\'intérieur et complètent les diagnostics. La mesure ne quitte pas l\'application.'**
  String get homeClimateHint;

  /// No description provided for @homeClimateApple.
  ///
  /// In fr, this message translates to:
  /// **'Apple Maison'**
  String get homeClimateApple;

  /// No description provided for @homeClimateGoogle.
  ///
  /// In fr, this message translates to:
  /// **'Google Home'**
  String get homeClimateGoogle;

  /// No description provided for @homeClimateConnect.
  ///
  /// In fr, this message translates to:
  /// **'Connecter la maison'**
  String get homeClimateConnect;

  /// No description provided for @homeClimateConnectApple.
  ///
  /// In fr, this message translates to:
  /// **'Connecter Apple Maison'**
  String get homeClimateConnectApple;

  /// No description provided for @homeClimateConnectGoogle.
  ///
  /// In fr, this message translates to:
  /// **'Connecter Google Home'**
  String get homeClimateConnectGoogle;

  /// No description provided for @homeClimateSearching.
  ///
  /// In fr, this message translates to:
  /// **'Recherche des capteurs…'**
  String get homeClimateSearching;

  /// No description provided for @homeClimateSensor.
  ///
  /// In fr, this message translates to:
  /// **'Capteur'**
  String get homeClimateSensor;

  /// No description provided for @homeClimateSensors.
  ///
  /// In fr, this message translates to:
  /// **'Capteurs trouvés'**
  String get homeClimateSensors;

  /// No description provided for @homeClimateChoose.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un capteur'**
  String get homeClimateChoose;

  /// No description provided for @homeClimateChange.
  ///
  /// In fr, this message translates to:
  /// **'Changer de capteur'**
  String get homeClimateChange;

  /// No description provided for @homeClimateHome.
  ///
  /// In fr, this message translates to:
  /// **'Maison'**
  String get homeClimateHome;

  /// No description provided for @homeClimateSource.
  ///
  /// In fr, this message translates to:
  /// **'Plateforme'**
  String get homeClimateSource;

  /// No description provided for @homeClimateNoRoom.
  ///
  /// In fr, this message translates to:
  /// **'Sans pièce'**
  String get homeClimateNoRoom;

  /// No description provided for @homeClimateTemperatureSensor.
  ///
  /// In fr, this message translates to:
  /// **'Capteur de température'**
  String get homeClimateTemperatureSensor;

  /// No description provided for @homeClimateHumiditySensor.
  ///
  /// In fr, this message translates to:
  /// **'Capteur d\'humidité'**
  String get homeClimateHumiditySensor;

  /// No description provided for @homeClimateSameSensor.
  ///
  /// In fr, this message translates to:
  /// **'Même capteur'**
  String get homeClimateSameSensor;

  /// No description provided for @homeClimateHumidityMissing.
  ///
  /// In fr, this message translates to:
  /// **'Humidité non reçue de ce capteur. Un autre se choisit dans la ligne Humidité.'**
  String get homeClimateHumidityMissing;

  /// No description provided for @homeClimateNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucun capteur'**
  String get homeClimateNone;

  /// No description provided for @homeClimateRemove.
  ///
  /// In fr, this message translates to:
  /// **'Retirer le capteur'**
  String get homeClimateRemove;

  /// No description provided for @homeClimateReading.
  ///
  /// In fr, this message translates to:
  /// **'Mesure'**
  String get homeClimateReading;

  /// No description provided for @homeClimateUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Capteur injoignable pour l\'instant.'**
  String get homeClimateUnavailable;

  /// No description provided for @homeClimateUpdatedAgo.
  ///
  /// In fr, this message translates to:
  /// **'{minutes, plural, =0{À l\'instant} =1{Il y a 1 min} other{Il y a {minutes} min}}'**
  String homeClimateUpdatedAgo(int minutes);

  /// No description provided for @homeClimateNoSensorsIn.
  ///
  /// In fr, this message translates to:
  /// **'Aucun capteur de température ou d\'humidité dans {home}.'**
  String homeClimateNoSensorsIn(String home);

  /// No description provided for @homeClimateDeniedApple.
  ///
  /// In fr, this message translates to:
  /// **'Accès à Apple Maison refusé. Il se rouvre dans Réglages › Confidentialité › Maison.'**
  String get homeClimateDeniedApple;

  /// No description provided for @homeClimateDeniedGoogle.
  ///
  /// In fr, this message translates to:
  /// **'Accès à Google Home refusé. Il se rouvre dans l\'application Google Home, aux autorisations.'**
  String get homeClimateDeniedGoogle;

  /// No description provided for @homeClimateFailedIn.
  ///
  /// In fr, this message translates to:
  /// **'{home} indisponible. Vous pourrez connecter un capteur dans Profil › Capteurs de la maison.'**
  String homeClimateFailedIn(String home);

  /// No description provided for @homeClimateAppleNote.
  ///
  /// In fr, this message translates to:
  /// **'Apple Maison lit les accessoires sur l\'appareil.'**
  String get homeClimateAppleNote;

  /// No description provided for @homeClimateGoogleNote.
  ///
  /// In fr, this message translates to:
  /// **'Google Home lit les appareils via votre compte Google.'**
  String get homeClimateGoogleNote;

  /// No description provided for @homeClimateDisconnect.
  ///
  /// In fr, this message translates to:
  /// **'Déconnecter'**
  String get homeClimateDisconnect;

  /// No description provided for @homeClimateDisconnectGoogle.
  ///
  /// In fr, this message translates to:
  /// **'Déconnecter Google Home'**
  String get homeClimateDisconnectGoogle;

  /// No description provided for @homeClimateDisconnectGoogleHint.
  ///
  /// In fr, this message translates to:
  /// **'Les capteurs de Google Home sont oubliés sur cet appareil. L\'autorisation accordée reste dans le compte Google, et se retire depuis ce compte.'**
  String get homeClimateDisconnectGoogleHint;

  /// No description provided for @homeClimateDisconnectedGoogle.
  ///
  /// In fr, this message translates to:
  /// **'Google Home déconnecté.'**
  String get homeClimateDisconnectedGoogle;

  /// No description provided for @homeClimateGoogleAccess.
  ///
  /// In fr, this message translates to:
  /// **'Autorisations du compte Google'**
  String get homeClimateGoogleAccess;

  /// No description provided for @homeClimateAtHome.
  ///
  /// In fr, this message translates to:
  /// **'Chez vous'**
  String get homeClimateAtHome;

  /// No description provided for @homeClimateFits.
  ///
  /// In fr, this message translates to:
  /// **'Rien qui gêne cette espèce.'**
  String get homeClimateFits;

  /// No description provided for @homeClimateTooDry.
  ///
  /// In fr, this message translates to:
  /// **'Air trop sec pour cette espèce.'**
  String get homeClimateTooDry;

  /// No description provided for @homeClimateTooHumid.
  ///
  /// In fr, this message translates to:
  /// **'Air trop humide pour cette espèce.'**
  String get homeClimateTooHumid;

  /// No description provided for @homeClimateTooCold.
  ///
  /// In fr, this message translates to:
  /// **'Trop froid pour cette espèce.'**
  String get homeClimateTooCold;

  /// No description provided for @homeClimateTooHot.
  ///
  /// In fr, this message translates to:
  /// **'Trop chaud pour cette espèce.'**
  String get homeClimateTooHot;

  /// No description provided for @homeTipDryAir.
  ///
  /// In fr, this message translates to:
  /// **'Air sec : brumiser ou regrouper {names}.'**
  String homeTipDryAir(String names);

  /// No description provided for @homeTipHumidAir.
  ///
  /// In fr, this message translates to:
  /// **'Air humide : aérer la pièce.'**
  String get homeTipHumidAir;

  /// No description provided for @homeTipHumidAirPlants.
  ///
  /// In fr, this message translates to:
  /// **'Air humide : aérer, et laisser sécher {names} entre deux arrosages.'**
  String homeTipHumidAirPlants(String names);

  /// No description provided for @homeTipCold.
  ///
  /// In fr, this message translates to:
  /// **'Trop froid pour {names}.'**
  String homeTipCold(String names);

  /// No description provided for @homeTipHot.
  ///
  /// In fr, this message translates to:
  /// **'Chaleur : {names} sèchent plus vite, vérifier la terre.'**
  String homeTipHot(String names);

  /// No description provided for @diagnosisWithHome.
  ///
  /// In fr, this message translates to:
  /// **'Mesure de la maison jointe : {reading}.'**
  String diagnosisWithHome(String reading);

  /// No description provided for @placeChosen.
  ///
  /// In fr, this message translates to:
  /// **'Météo réglée sur {place}.'**
  String placeChosen(String place);

  /// No description provided for @askNameTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre prénom'**
  String get askNameTitle;

  /// No description provided for @askNameSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifiable plus tard dans le profil.'**
  String get askNameSubtitle;

  /// No description provided for @onbAccountTitle.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde et partage'**
  String get onbAccountTitle;

  /// No description provided for @onbAccountBody.
  ///
  /// In fr, this message translates to:
  /// **'Un compte sauvegarde vos données et permet de partager un jardin. Connexion avec votre identifiant Apple.'**
  String get onbAccountBody;

  /// No description provided for @notificationAskTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rappel quotidien'**
  String get notificationAskTitle;

  /// No description provided for @notificationAskBody.
  ///
  /// In fr, this message translates to:
  /// **'Une notification par jour, à l\'heure choisie, seulement si un soin est prévu.'**
  String get notificationAskBody;

  /// No description provided for @enable.
  ///
  /// In fr, this message translates to:
  /// **'Activer'**
  String get enable;

  /// No description provided for @notNow.
  ///
  /// In fr, this message translates to:
  /// **'Pas maintenant'**
  String get notNow;

  /// No description provided for @notificationTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vos plantes'**
  String get notificationTitle;

  /// No description provided for @notificationChannel.
  ///
  /// In fr, this message translates to:
  /// **'Rappels d\'entretien'**
  String get notificationChannel;

  /// No description provided for @notifWaterOne.
  ///
  /// In fr, this message translates to:
  /// **'{name} : arrosage prévu aujourd\'hui.'**
  String notifWaterOne(String name);

  /// No description provided for @notifWaterMany.
  ///
  /// In fr, this message translates to:
  /// **'{names} : arrosage prévu aujourd\'hui.'**
  String notifWaterMany(String names);

  /// No description provided for @notifOther.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 autre soin prévu.} other{{count} autres soins prévus.}}'**
  String notifOther(int count);

  /// No description provided for @notifOnlyOther.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 soin prévu aujourd\'hui.} other{{count} soins prévus aujourd\'hui.}}'**
  String notifOnlyOther(int count);

  /// No description provided for @andJoin.
  ///
  /// In fr, this message translates to:
  /// **'{a} et {b}'**
  String andJoin(String a, String b);

  /// No description provided for @listSeparator.
  ///
  /// In fr, this message translates to:
  /// **', '**
  String get listSeparator;

  /// No description provided for @timelineToday.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get timelineToday;

  /// No description provided for @timelineYesterday.
  ///
  /// In fr, this message translates to:
  /// **'Hier'**
  String get timelineYesterday;

  /// No description provided for @photoAddedToast.
  ///
  /// In fr, this message translates to:
  /// **'Photo ajoutée'**
  String get photoAddedToast;

  /// No description provided for @noteAddedToast.
  ///
  /// In fr, this message translates to:
  /// **'Note ajoutée'**
  String get noteAddedToast;

  /// No description provided for @actionAddedToast.
  ///
  /// In fr, this message translates to:
  /// **'Action enregistrée'**
  String get actionAddedToast;

  /// No description provided for @locationCreated.
  ///
  /// In fr, this message translates to:
  /// **'{name} créé'**
  String locationCreated(String name);

  /// No description provided for @saved.
  ///
  /// In fr, this message translates to:
  /// **'Enregistré'**
  String get saved;

  /// No description provided for @gardenLocations.
  ///
  /// In fr, this message translates to:
  /// **'Lieux'**
  String get gardenLocations;

  /// No description provided for @gardenInventory.
  ///
  /// In fr, this message translates to:
  /// **'Inventaire'**
  String get gardenInventory;

  /// No description provided for @gardenCalendar.
  ///
  /// In fr, this message translates to:
  /// **'Calendrier'**
  String get gardenCalendar;

  /// No description provided for @inventoryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Inventaire'**
  String get inventoryTitle;

  /// No description provided for @newItem.
  ///
  /// In fr, this message translates to:
  /// **'Nouvel article'**
  String get newItem;

  /// No description provided for @editItem.
  ///
  /// In fr, this message translates to:
  /// **'Modifier l\'article'**
  String get editItem;

  /// No description provided for @itemName.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get itemName;

  /// No description provided for @itemNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Engrais plantes vertes'**
  String get itemNameHint;

  /// No description provided for @category.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get category;

  /// No description provided for @catFertilizer.
  ///
  /// In fr, this message translates to:
  /// **'Engrais'**
  String get catFertilizer;

  /// No description provided for @catSoil.
  ///
  /// In fr, this message translates to:
  /// **'Terreaux'**
  String get catSoil;

  /// No description provided for @catSubstrate.
  ///
  /// In fr, this message translates to:
  /// **'Substrats'**
  String get catSubstrate;

  /// No description provided for @catPot.
  ///
  /// In fr, this message translates to:
  /// **'Pots'**
  String get catPot;

  /// No description provided for @catTool.
  ///
  /// In fr, this message translates to:
  /// **'Outils'**
  String get catTool;

  /// No description provided for @catTreatment.
  ///
  /// In fr, this message translates to:
  /// **'Traitements'**
  String get catTreatment;

  /// No description provided for @catSeed.
  ///
  /// In fr, this message translates to:
  /// **'Graines'**
  String get catSeed;

  /// No description provided for @catAccessory.
  ///
  /// In fr, this message translates to:
  /// **'Accessoires'**
  String get catAccessory;

  /// No description provided for @fertForm.
  ///
  /// In fr, this message translates to:
  /// **'Forme'**
  String get fertForm;

  /// No description provided for @fertFormLiquid.
  ///
  /// In fr, this message translates to:
  /// **'Liquide'**
  String get fertFormLiquid;

  /// No description provided for @fertFormGranules.
  ///
  /// In fr, this message translates to:
  /// **'Granulés'**
  String get fertFormGranules;

  /// No description provided for @fertFormSticks.
  ///
  /// In fr, this message translates to:
  /// **'Bâtonnets'**
  String get fertFormSticks;

  /// No description provided for @fertFormSolublePowder.
  ///
  /// In fr, this message translates to:
  /// **'Poudre soluble'**
  String get fertFormSolublePowder;

  /// No description provided for @fertFormFoliar.
  ///
  /// In fr, this message translates to:
  /// **'Foliaire'**
  String get fertFormFoliar;

  /// No description provided for @fertFormOther.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get fertFormOther;

  /// No description provided for @fertOrigin.
  ///
  /// In fr, this message translates to:
  /// **'Origine'**
  String get fertOrigin;

  /// No description provided for @fertOriginMineral.
  ///
  /// In fr, this message translates to:
  /// **'Minéral'**
  String get fertOriginMineral;

  /// No description provided for @fertOriginOrganic.
  ///
  /// In fr, this message translates to:
  /// **'Organique'**
  String get fertOriginOrganic;

  /// No description provided for @fertOriginOrganomineral.
  ///
  /// In fr, this message translates to:
  /// **'Organo-minéral'**
  String get fertOriginOrganomineral;

  /// No description provided for @fertNpk.
  ///
  /// In fr, this message translates to:
  /// **'NPK'**
  String get fertNpk;

  /// No description provided for @fertNpkPercent.
  ///
  /// In fr, this message translates to:
  /// **'NPK (%)'**
  String get fertNpkPercent;

  /// No description provided for @unit.
  ///
  /// In fr, this message translates to:
  /// **'Unité'**
  String get unit;

  /// No description provided for @unitPieces.
  ///
  /// In fr, this message translates to:
  /// **'unités'**
  String get unitPieces;

  /// No description provided for @lowThreshold.
  ///
  /// In fr, this message translates to:
  /// **'Seuil de stock bas'**
  String get lowThreshold;

  /// No description provided for @lowStock.
  ///
  /// In fr, this message translates to:
  /// **'Stock bas'**
  String get lowStock;

  /// No description provided for @remaining.
  ///
  /// In fr, this message translates to:
  /// **'{amount} restants'**
  String remaining(String amount);

  /// No description provided for @noInventoryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Inventaire vide'**
  String get noInventoryTitle;

  /// No description provided for @noInventorySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Engrais, terreaux, pots, outils…'**
  String get noInventorySubtitle;

  /// No description provided for @deleteItem.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer l\'article'**
  String get deleteItem;

  /// No description provided for @lowStockItems.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 article en stock bas} other{{count} articles en stock bas}}'**
  String lowStockItems(int count);

  /// No description provided for @calendarTitle.
  ///
  /// In fr, this message translates to:
  /// **'Calendrier'**
  String get calendarTitle;

  /// No description provided for @agenda.
  ///
  /// In fr, this message translates to:
  /// **'Agenda'**
  String get agenda;

  /// No description provided for @month.
  ///
  /// In fr, this message translates to:
  /// **'Mois'**
  String get month;

  /// No description provided for @noEventsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rien de prévu'**
  String get noEventsTitle;

  /// No description provided for @noEventsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Les soins à venir apparaîtront ici.'**
  String get noEventsSubtitle;

  /// No description provided for @projected.
  ///
  /// In fr, this message translates to:
  /// **'prévu'**
  String get projected;

  /// No description provided for @today.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get today;

  /// No description provided for @measurementsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mesures'**
  String get measurementsTitle;

  /// No description provided for @addMeasurement.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une mesure'**
  String get addMeasurement;

  /// No description provided for @sinceFirst.
  ///
  /// In fr, this message translates to:
  /// **'{delta} depuis {date}'**
  String sinceFirst(String delta, String date);

  /// No description provided for @qrCode.
  ///
  /// In fr, this message translates to:
  /// **'QR code'**
  String get qrCode;

  /// No description provided for @qrHint.
  ///
  /// In fr, this message translates to:
  /// **'Scanné, ce code ouvre la fiche de la plante.'**
  String get qrHint;

  /// No description provided for @scan.
  ///
  /// In fr, this message translates to:
  /// **'Scanner'**
  String get scan;

  /// No description provided for @quickActionScan.
  ///
  /// In fr, this message translates to:
  /// **'Scanner une étiquette'**
  String get quickActionScan;

  /// No description provided for @scanHint.
  ///
  /// In fr, this message translates to:
  /// **'Visez le QR code d\'une plante.'**
  String get scanHint;

  /// No description provided for @unknownQr.
  ///
  /// In fr, this message translates to:
  /// **'QR code inconnu.'**
  String get unknownQr;

  /// No description provided for @shareQr.
  ///
  /// In fr, this message translates to:
  /// **'Partager'**
  String get shareQr;

  /// No description provided for @printLabels.
  ///
  /// In fr, this message translates to:
  /// **'Étiquettes PDF'**
  String get printLabels;

  /// No description provided for @labels.
  ///
  /// In fr, this message translates to:
  /// **'Étiquettes'**
  String get labels;

  /// No description provided for @cameraPermission.
  ///
  /// In fr, this message translates to:
  /// **'Autorisez l\'accès à l\'appareil photo dans les Réglages.'**
  String get cameraPermission;

  /// No description provided for @identify.
  ///
  /// In fr, this message translates to:
  /// **'Identifier'**
  String get identify;

  /// No description provided for @identifying.
  ///
  /// In fr, this message translates to:
  /// **'Analyse en cours…'**
  String get identifying;

  /// No description provided for @identifyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Espèce'**
  String get identifyTitle;

  /// No description provided for @identifyHint.
  ///
  /// In fr, this message translates to:
  /// **'Suggestions d\'espèce, à confirmer'**
  String get identifyHint;

  /// No description provided for @searchOnline.
  ///
  /// In fr, this message translates to:
  /// **'Chercher en ligne'**
  String get searchOnline;

  /// No description provided for @identifyAnotherPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une photo'**
  String get identifyAnotherPhoto;

  /// No description provided for @identifyAnotherPhotoHint.
  ///
  /// In fr, this message translates to:
  /// **'Une feuille, une fleur ou la plante entière permet d\'affiner.'**
  String get identifyAnotherPhotoHint;

  /// No description provided for @identificationUncertainTitle.
  ///
  /// In fr, this message translates to:
  /// **'Identification incertaine'**
  String get identificationUncertainTitle;

  /// No description provided for @identificationUncertainBody.
  ///
  /// In fr, this message translates to:
  /// **'Même avec les photos disponibles, aucune espèce ne ressort assez nettement. Vous pouvez chercher en ligne ou choisir manuellement si vous reconnaissez la plante.'**
  String get identificationUncertainBody;

  /// No description provided for @identificationSuggestionsToCheck.
  ///
  /// In fr, this message translates to:
  /// **'Suggestions à vérifier'**
  String get identificationSuggestionsToCheck;

  /// No description provided for @identifyConfirmWithPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer avec une photo'**
  String get identifyConfirmWithPhoto;

  /// No description provided for @searchingOnline.
  ///
  /// In fr, this message translates to:
  /// **'Recherche en ligne…'**
  String get searchingOnline;

  /// No description provided for @suggestionsLocal.
  ///
  /// In fr, this message translates to:
  /// **'Résultats Iris sur votre appareil · photo non envoyée'**
  String get suggestionsLocal;

  /// No description provided for @suggestionsRemote.
  ///
  /// In fr, this message translates to:
  /// **'Proposé en ligne par Pl@ntNet'**
  String get suggestionsRemote;

  /// No description provided for @identifyOnDevice.
  ///
  /// In fr, this message translates to:
  /// **'Reconnu par {name} sur l\'appareil. Choisissez l\'espèce'**
  String identifyOnDevice(String name);

  /// No description provided for @identifyViaPlantNet.
  ///
  /// In fr, this message translates to:
  /// **'Reconnu en ligne par Pl@ntNet. Choisissez l\'espèce'**
  String get identifyViaPlantNet;

  /// No description provided for @identifyPhotoSource.
  ///
  /// In fr, this message translates to:
  /// **'Photos Pl@ntNet et GBIF. Touchez-en une pour ouvrir la fiche de l\'espèce.'**
  String get identifyPhotoSource;

  /// No description provided for @identifyNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucune correspondance fiable.'**
  String get identifyNone;

  /// No description provided for @identifyError.
  ///
  /// In fr, this message translates to:
  /// **'Identification impossible. Vérifiez votre connexion et réessayez.'**
  String get identifyError;

  /// No description provided for @useThis.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser'**
  String get useThis;

  /// No description provided for @identificationSettings.
  ///
  /// In fr, this message translates to:
  /// **'Identification'**
  String get identificationSettings;

  /// No description provided for @identificationHint.
  ///
  /// In fr, this message translates to:
  /// **'Reconnaissance des espèces sur l\'appareil par {name}, sans réseau. En cas de doute, la photo peut être envoyée à Pl@ntNet.'**
  String identificationHint(String name);

  /// No description provided for @identificationEnabled.
  ///
  /// In fr, this message translates to:
  /// **'Identification activée'**
  String get identificationEnabled;

  /// No description provided for @identificationDisabled.
  ///
  /// In fr, this message translates to:
  /// **'Non configurée'**
  String get identificationDisabled;

  /// No description provided for @identificationFallback.
  ///
  /// In fr, this message translates to:
  /// **'Repli en ligne'**
  String get identificationFallback;

  /// No description provided for @identificationFallbackHint.
  ///
  /// In fr, this message translates to:
  /// **'En cas de doute de {name}, la photo est envoyée à Pl@ntNet. Désactivé, tout reste sur l\'appareil.'**
  String identificationFallbackHint(String name);

  /// No description provided for @irisFeedback.
  ///
  /// In fr, this message translates to:
  /// **'Envoi des photos identifiées'**
  String get irisFeedback;

  /// No description provided for @irisFeedbackHint.
  ///
  /// In fr, this message translates to:
  /// **'Les photos prises pour identifier et le nom retenu sont envoyés dès qu\'une plante est nommée, et entraînent les prochaines versions du modèle {name}. Elles ne sont lisibles que par le compte qui les envoie, et sa suppression les efface. Désactivé, elles ne quittent pas l\'appareil.'**
  String irisFeedbackHint(String name);

  /// No description provided for @irisFeedbackNeedsAccount.
  ///
  /// In fr, this message translates to:
  /// **'Il faut un compte pour envoyer des photos.'**
  String get irisFeedbackNeedsAccount;

  /// No description provided for @irisFeedbackAskTitle.
  ///
  /// In fr, this message translates to:
  /// **'Envoi des photos identifiées'**
  String get irisFeedbackAskTitle;

  /// No description provided for @irisFeedbackAskBody.
  ///
  /// In fr, this message translates to:
  /// **'Les photos prises pour identifier et le nom retenu peuvent être envoyés pour entraîner les prochaines versions du modèle {name}. Elles ne sont lisibles que par le compte qui les envoie, et sa suppression les efface. Le choix se change dans les réglages d\'identification.'**
  String irisFeedbackAskBody(String name);

  /// No description provided for @genusUncertainSpecies.
  ///
  /// In fr, this message translates to:
  /// **'Espèce incertaine'**
  String get genusUncertainSpecies;

  /// No description provided for @modelMissing.
  ///
  /// In fr, this message translates to:
  /// **'{name} indisponible sur cet appareil'**
  String modelMissing(String name);

  /// No description provided for @modelLoading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement du modèle…'**
  String get modelLoading;

  /// No description provided for @identificationStats.
  ///
  /// In fr, this message translates to:
  /// **'{local} analysées sur l’appareil, dont {accepted} tranchées ici ; {remote} envoyées en ligne'**
  String identificationStats(int local, int accepted, int remote);

  /// No description provided for @onlineSearchesMonth.
  ///
  /// In fr, this message translates to:
  /// **'{used} recherches en ligne sur {limit} ce mois-ci.'**
  String onlineSearchesMonth(int used, int limit);

  /// No description provided for @irisSection.
  ///
  /// In fr, this message translates to:
  /// **'Le modèle embarqué'**
  String get irisSection;

  /// No description provided for @irisTagline.
  ///
  /// In fr, this message translates to:
  /// **'Reconnaissance des espèces sur le téléphone, sans réseau ni compte.'**
  String get irisTagline;

  /// No description provided for @irisSpeciesLabel.
  ///
  /// In fr, this message translates to:
  /// **'espèces'**
  String get irisSpeciesLabel;

  /// No description provided for @irisOfflineValue.
  ///
  /// In fr, this message translates to:
  /// **'hors ligne'**
  String get irisOfflineValue;

  /// No description provided for @irisOfflineLabel.
  ///
  /// In fr, this message translates to:
  /// **'même en avion'**
  String get irisOfflineLabel;

  /// No description provided for @irisTwoPhotosTitle.
  ///
  /// In fr, this message translates to:
  /// **'Deux photos valent mieux qu’une'**
  String get irisTwoPhotosTitle;

  /// No description provided for @irisTwoPhotosBody.
  ///
  /// In fr, this message translates to:
  /// **'La plante entière, puis une feuille de près. Avec deux photos, {name} trouve la bonne espèce deux fois sur trois, contre une fois sur deux.'**
  String irisTwoPhotosBody(String name);

  /// No description provided for @confidence.
  ///
  /// In fr, this message translates to:
  /// **'{percent} %'**
  String confidence(int percent);

  /// No description provided for @speciesSet.
  ///
  /// In fr, this message translates to:
  /// **'Espèce mise à jour'**
  String get speciesSet;

  /// No description provided for @compare.
  ///
  /// In fr, this message translates to:
  /// **'Comparer'**
  String get compare;

  /// No description provided for @compareHint.
  ///
  /// In fr, this message translates to:
  /// **'Glissez pour comparer.'**
  String get compareHint;

  /// No description provided for @before.
  ///
  /// In fr, this message translates to:
  /// **'Avant'**
  String get before;

  /// No description provided for @after.
  ///
  /// In fr, this message translates to:
  /// **'Après'**
  String get after;

  /// No description provided for @comparePickFirst.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez deux photos.'**
  String get comparePickFirst;

  /// No description provided for @outdoor.
  ///
  /// In fr, this message translates to:
  /// **'Extérieur'**
  String get outdoor;

  /// No description provided for @outdoorHint.
  ///
  /// In fr, this message translates to:
  /// **'Balcon, jardin ou serre : la météo est prise en compte.'**
  String get outdoorHint;

  /// No description provided for @weather.
  ///
  /// In fr, this message translates to:
  /// **'Météo'**
  String get weather;

  /// No description provided for @weatherHint.
  ///
  /// In fr, this message translates to:
  /// **'Pour les plantes en extérieur : la pluie tombée vaut un arrosage, la pluie annoncée le reporte, et le gel comme la canicule sont signalés. Données Open-Meteo.'**
  String get weatherHint;

  /// No description provided for @weatherPlace.
  ///
  /// In fr, this message translates to:
  /// **'Lieu'**
  String get weatherPlace;

  /// No description provided for @weatherSearchHint.
  ///
  /// In fr, this message translates to:
  /// **'Ville…'**
  String get weatherSearchHint;

  /// No description provided for @weatherNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucun lieu'**
  String get weatherNone;

  /// No description provided for @weatherRemove.
  ///
  /// In fr, this message translates to:
  /// **'Retirer le lieu'**
  String get weatherRemove;

  /// No description provided for @weatherNoResults.
  ///
  /// In fr, this message translates to:
  /// **'Aucun lieu trouvé.'**
  String get weatherNoResults;

  /// No description provided for @weatherRainTitle.
  ///
  /// In fr, this message translates to:
  /// **'Pluie aujourd\'hui'**
  String get weatherRainTitle;

  /// No description provided for @weatherRainSkip.
  ///
  /// In fr, this message translates to:
  /// **'L\'arrosage de {names} peut attendre.'**
  String weatherRainSkip(String names);

  /// No description provided for @postpone.
  ///
  /// In fr, this message translates to:
  /// **'Reporter'**
  String get postpone;

  /// No description provided for @postponedCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 arrosage reporté à demain} other{{count} arrosages reportés à demain}}'**
  String postponedCount(int count);

  /// No description provided for @condClear.
  ///
  /// In fr, this message translates to:
  /// **'Ciel dégagé'**
  String get condClear;

  /// No description provided for @condPartlyCloudy.
  ///
  /// In fr, this message translates to:
  /// **'Éclaircies'**
  String get condPartlyCloudy;

  /// No description provided for @condCloudy.
  ///
  /// In fr, this message translates to:
  /// **'Nuageux'**
  String get condCloudy;

  /// No description provided for @condFog.
  ///
  /// In fr, this message translates to:
  /// **'Brouillard'**
  String get condFog;

  /// No description provided for @condDrizzle.
  ///
  /// In fr, this message translates to:
  /// **'Bruine'**
  String get condDrizzle;

  /// No description provided for @condRain.
  ///
  /// In fr, this message translates to:
  /// **'Pluie'**
  String get condRain;

  /// No description provided for @condSnow.
  ///
  /// In fr, this message translates to:
  /// **'Neige'**
  String get condSnow;

  /// No description provided for @condThunderstorm.
  ///
  /// In fr, this message translates to:
  /// **'Orage'**
  String get condThunderstorm;

  /// No description provided for @rainChance.
  ///
  /// In fr, this message translates to:
  /// **'{percent} % de pluie'**
  String rainChance(int percent);

  /// No description provided for @dataSection.
  ///
  /// In fr, this message translates to:
  /// **'Données'**
  String get dataSection;

  /// No description provided for @exportData.
  ///
  /// In fr, this message translates to:
  /// **'Exporter mes données'**
  String get exportData;

  /// No description provided for @exportHint.
  ///
  /// In fr, this message translates to:
  /// **'Un fichier ZIP avec vos plantes, historiques, inventaire, réglages et photos.'**
  String get exportHint;

  /// No description provided for @exporting.
  ///
  /// In fr, this message translates to:
  /// **'Préparation de l\'export…'**
  String get exporting;

  /// No description provided for @exportError.
  ///
  /// In fr, this message translates to:
  /// **'Export impossible. Réessayez.'**
  String get exportError;

  /// No description provided for @play.
  ///
  /// In fr, this message translates to:
  /// **'Lire'**
  String get play;

  /// No description provided for @timelapseHint.
  ///
  /// In fr, this message translates to:
  /// **'Touchez pour mettre en pause.'**
  String get timelapseHint;

  /// No description provided for @notifLowStockOne.
  ///
  /// In fr, this message translates to:
  /// **'{name} : stock bas.'**
  String notifLowStockOne(String name);

  /// No description provided for @notifLowStockMany.
  ///
  /// In fr, this message translates to:
  /// **'{count} articles en stock bas.'**
  String notifLowStockMany(int count);

  /// No description provided for @accountTitle.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get accountTitle;

  /// No description provided for @signIn.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get signIn;

  /// No description provided for @signInWithAppleId.
  ///
  /// In fr, this message translates to:
  /// **'Avec votre identifiant Apple'**
  String get signInWithAppleId;

  /// No description provided for @signInHint.
  ///
  /// In fr, this message translates to:
  /// **'Un compte sauvegarde vos données, les synchronise entre appareils et permet de partager un jardin.'**
  String get signInHint;

  /// No description provided for @continueWithApple.
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec Apple'**
  String get continueWithApple;

  /// No description provided for @continueWithGoogle.
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec Google'**
  String get continueWithGoogle;

  /// No description provided for @signOut.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get signOut;

  /// No description provided for @signOutConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Vos données restent sur ce téléphone.'**
  String get signOutConfirm;

  /// No description provided for @signedInAs.
  ///
  /// In fr, this message translates to:
  /// **'Connecté'**
  String get signedInAs;

  /// No description provided for @syncNow.
  ///
  /// In fr, this message translates to:
  /// **'Synchroniser maintenant'**
  String get syncNow;

  /// No description provided for @syncIdle.
  ///
  /// In fr, this message translates to:
  /// **'À jour · {time}'**
  String syncIdle(String time);

  /// No description provided for @syncNever.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore synchronisé'**
  String get syncNever;

  /// No description provided for @syncPending.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 changement en attente} other{{count} changements en attente}}'**
  String syncPending(int count);

  /// No description provided for @syncOffline.
  ///
  /// In fr, this message translates to:
  /// **'Hors ligne · reprise automatique'**
  String get syncOffline;

  /// No description provided for @syncError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de synchronisation'**
  String get syncError;

  /// No description provided for @syncUnknownColumns.
  ///
  /// In fr, this message translates to:
  /// **'Colonnes inconnues du serveur : {columns}'**
  String syncUnknownColumns(String columns);

  /// No description provided for @syncSyncing.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisation…'**
  String get syncSyncing;

  /// No description provided for @authError.
  ///
  /// In fr, this message translates to:
  /// **'Connexion impossible. Réessayez dans un moment.'**
  String get authError;

  /// No description provided for @appleUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Apple est disponible sur iPhone et iPad.'**
  String get appleUnavailable;

  /// No description provided for @synchronization.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisation'**
  String get synchronization;

  /// No description provided for @membersTitle.
  ///
  /// In fr, this message translates to:
  /// **'Membres'**
  String get membersTitle;

  /// No description provided for @shareGarden.
  ///
  /// In fr, this message translates to:
  /// **'Partager le jardin'**
  String get shareGarden;

  /// No description provided for @inviteMember.
  ///
  /// In fr, this message translates to:
  /// **'Inviter'**
  String get inviteMember;

  /// No description provided for @inviteHint.
  ///
  /// In fr, this message translates to:
  /// **'L\'invité doit déjà avoir un compte Auxine avec cette adresse.'**
  String get inviteHint;

  /// No description provided for @roleOwner.
  ///
  /// In fr, this message translates to:
  /// **'Propriétaire'**
  String get roleOwner;

  /// No description provided for @roleMember.
  ///
  /// In fr, this message translates to:
  /// **'Membre'**
  String get roleMember;

  /// No description provided for @roleViewer.
  ///
  /// In fr, this message translates to:
  /// **'Lecture seule'**
  String get roleViewer;

  /// No description provided for @invited.
  ///
  /// In fr, this message translates to:
  /// **'Invitation envoyée'**
  String get invited;

  /// No description provided for @inviteError.
  ///
  /// In fr, this message translates to:
  /// **'Cette adresse n\'a pas encore de compte.'**
  String get inviteError;

  /// No description provided for @removeMember.
  ///
  /// In fr, this message translates to:
  /// **'Retirer du jardin'**
  String get removeMember;

  /// No description provided for @readOnlyHint.
  ///
  /// In fr, this message translates to:
  /// **'Vous consultez ce jardin en lecture seule.'**
  String get readOnlyHint;

  /// No description provided for @byUser.
  ///
  /// In fr, this message translates to:
  /// **'par {name}'**
  String byUser(String name);

  /// No description provided for @you.
  ///
  /// In fr, this message translates to:
  /// **'vous'**
  String get you;

  /// No description provided for @diagnosisTitle.
  ///
  /// In fr, this message translates to:
  /// **'Diagnostic'**
  String get diagnosisTitle;

  /// No description provided for @diagnosisHint.
  ///
  /// In fr, this message translates to:
  /// **'Photographiez les feuilles, la tige et la terre, de près et en entier. Les résultats sont indicatifs.'**
  String get diagnosisHint;

  /// No description provided for @diagnosisMoreBelow.
  ///
  /// In fr, this message translates to:
  /// **'Plus bas : symptômes et observations'**
  String get diagnosisMoreBelow;

  /// No description provided for @diagnosisSymptomsHint.
  ///
  /// In fr, this message translates to:
  /// **'Ce que vous avez remarqué…'**
  String get diagnosisSymptomsHint;

  /// No description provided for @diagnosisNeedsPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Une photo au moins.'**
  String get diagnosisNeedsPhoto;

  /// No description provided for @diagnosisNeedsSymptoms.
  ///
  /// In fr, this message translates to:
  /// **'Ce que vous avez remarqué, même en quelques mots.'**
  String get diagnosisNeedsSymptoms;

  /// No description provided for @diagnosisChecks.
  ///
  /// In fr, this message translates to:
  /// **'Observations'**
  String get diagnosisChecks;

  /// No description provided for @diagnosisChecksHint.
  ///
  /// In fr, this message translates to:
  /// **'Facultatif : ce que la photo ne montre pas affine l\'analyse.'**
  String get diagnosisChecksHint;

  /// No description provided for @diagnosisSoil.
  ///
  /// In fr, this message translates to:
  /// **'Terre'**
  String get diagnosisSoil;

  /// No description provided for @diagnosisSoilDry.
  ///
  /// In fr, this message translates to:
  /// **'Sèche'**
  String get diagnosisSoilDry;

  /// No description provided for @diagnosisSoilMoist.
  ///
  /// In fr, this message translates to:
  /// **'Humide'**
  String get diagnosisSoilMoist;

  /// No description provided for @diagnosisSoilSoggy.
  ///
  /// In fr, this message translates to:
  /// **'Détrempée'**
  String get diagnosisSoilSoggy;

  /// No description provided for @diagnosisRoots.
  ///
  /// In fr, this message translates to:
  /// **'Racines'**
  String get diagnosisRoots;

  /// No description provided for @diagnosisRootsFirm.
  ///
  /// In fr, this message translates to:
  /// **'Fermes et claires'**
  String get diagnosisRootsFirm;

  /// No description provided for @diagnosisRootsSoft.
  ///
  /// In fr, this message translates to:
  /// **'Brunes ou molles'**
  String get diagnosisRootsSoft;

  /// No description provided for @diagnosisRootsCrowded.
  ///
  /// In fr, this message translates to:
  /// **'À l\'étroit'**
  String get diagnosisRootsCrowded;

  /// No description provided for @diagnosisLightDirect.
  ///
  /// In fr, this message translates to:
  /// **'Soleil direct'**
  String get diagnosisLightDirect;

  /// No description provided for @diagnosisLightBright.
  ///
  /// In fr, this message translates to:
  /// **'Vive, sans soleil'**
  String get diagnosisLightBright;

  /// No description provided for @diagnosisLightDim.
  ///
  /// In fr, this message translates to:
  /// **'Faible'**
  String get diagnosisLightDim;

  /// No description provided for @diagnosisBugs.
  ///
  /// In fr, this message translates to:
  /// **'Insectes'**
  String get diagnosisBugs;

  /// No description provided for @diagnosisBugsNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucun vu'**
  String get diagnosisBugsNone;

  /// No description provided for @diagnosisBugsOnPlant.
  ///
  /// In fr, this message translates to:
  /// **'Sur la plante'**
  String get diagnosisBugsOnPlant;

  /// No description provided for @diagnosisBugsInSoil.
  ///
  /// In fr, this message translates to:
  /// **'Dans la terre'**
  String get diagnosisBugsInSoil;

  /// No description provided for @diagnosisSymptoms.
  ///
  /// In fr, this message translates to:
  /// **'Symptômes'**
  String get diagnosisSymptoms;

  /// No description provided for @diagnosisAround.
  ///
  /// In fr, this message translates to:
  /// **'Autour de la plante'**
  String get diagnosisAround;

  /// No description provided for @diagnosisPhotosFull.
  ///
  /// In fr, this message translates to:
  /// **'Trois photos au maximum.'**
  String get diagnosisPhotosFull;

  /// No description provided for @diagnosisRemovePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Retirer cette photo'**
  String get diagnosisRemovePhoto;

  /// No description provided for @diagnosisFinding.
  ///
  /// In fr, this message translates to:
  /// **'Constat'**
  String get diagnosisFinding;

  /// No description provided for @diagnosisNothingWrong.
  ///
  /// In fr, this message translates to:
  /// **'Rien d\'anormal'**
  String get diagnosisNothingWrong;

  /// No description provided for @diagnosisNatural.
  ///
  /// In fr, this message translates to:
  /// **'Phénomène normal'**
  String get diagnosisNatural;

  /// No description provided for @analyze.
  ///
  /// In fr, this message translates to:
  /// **'Analyser'**
  String get analyze;

  /// No description provided for @analyzing.
  ///
  /// In fr, this message translates to:
  /// **'Analyse en cours…'**
  String get analyzing;

  /// No description provided for @diagnosisError.
  ///
  /// In fr, this message translates to:
  /// **'Analyse impossible. Vérifiez votre connexion et réessayez.'**
  String get diagnosisError;

  /// No description provided for @diagnosisRefused.
  ///
  /// In fr, this message translates to:
  /// **'L\'analyse n\'a pas pu être effectuée pour cette photo.'**
  String get diagnosisRefused;

  /// No description provided for @diagnosisUnauthorized.
  ///
  /// In fr, this message translates to:
  /// **'Le diagnostic est indisponible pour le moment. Réessayez plus tard.'**
  String get diagnosisUnauthorized;

  /// No description provided for @diagnosisBusy.
  ///
  /// In fr, this message translates to:
  /// **'Le service d\'analyse ne répond pas. Réessayez dans un moment.'**
  String get diagnosisBusy;

  /// No description provided for @diagnosisUnreadable.
  ///
  /// In fr, this message translates to:
  /// **'L\'analyse n\'a pas abouti. Réessayez.'**
  String get diagnosisUnreadable;

  /// No description provided for @diagnosisUncertain.
  ///
  /// In fr, this message translates to:
  /// **'Les photos ne suffisent pas pour conclure. Les pistes ci-dessous restent à vérifier.'**
  String get diagnosisUncertain;

  /// No description provided for @diagnosisAnotherPhotoHint.
  ///
  /// In fr, this message translates to:
  /// **'Une photo de plus préciserait l\'analyse.'**
  String get diagnosisAnotherPhotoHint;

  /// No description provided for @diagnosisQuestionsHint.
  ///
  /// In fr, this message translates to:
  /// **'Ce qui manque pour trancher.'**
  String get diagnosisQuestionsHint;

  /// No description provided for @diagnosisAnswerHint.
  ///
  /// In fr, this message translates to:
  /// **'Réponse…'**
  String get diagnosisAnswerHint;

  /// No description provided for @diagnosisAnswerAgain.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre l\'analyse'**
  String get diagnosisAnswerAgain;

  /// No description provided for @diagnosisAnswersNoted.
  ///
  /// In fr, this message translates to:
  /// **'Réponses données'**
  String get diagnosisAnswersNoted;

  /// No description provided for @diagnosisAnotherPhotoView.
  ///
  /// In fr, this message translates to:
  /// **'À photographier : {view}.'**
  String diagnosisAnotherPhotoView(String view);

  /// No description provided for @diagnosisAnotherPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une photo'**
  String get diagnosisAnotherPhoto;

  /// No description provided for @diagnosisViewLeafCloseup.
  ///
  /// In fr, this message translates to:
  /// **'une feuille de près'**
  String get diagnosisViewLeafCloseup;

  /// No description provided for @diagnosisViewLeafUnderside.
  ///
  /// In fr, this message translates to:
  /// **'le revers d\'une feuille'**
  String get diagnosisViewLeafUnderside;

  /// No description provided for @diagnosisViewWholePlant.
  ///
  /// In fr, this message translates to:
  /// **'la plante entière'**
  String get diagnosisViewWholePlant;

  /// No description provided for @diagnosisViewStemBase.
  ///
  /// In fr, this message translates to:
  /// **'la base de la tige'**
  String get diagnosisViewStemBase;

  /// No description provided for @diagnosisViewSoilRoots.
  ///
  /// In fr, this message translates to:
  /// **'la terre au pied'**
  String get diagnosisViewSoilRoots;

  /// No description provided for @possibleCauses.
  ///
  /// In fr, this message translates to:
  /// **'Pistes possibles'**
  String get possibleCauses;

  /// No description provided for @causesHint.
  ///
  /// In fr, this message translates to:
  /// **'Classées par vraisemblance, à confirmer.'**
  String get causesHint;

  /// No description provided for @likelihoodLikely.
  ///
  /// In fr, this message translates to:
  /// **'Probable'**
  String get likelihoodLikely;

  /// No description provided for @likelihoodPossible.
  ///
  /// In fr, this message translates to:
  /// **'Possible'**
  String get likelihoodPossible;

  /// No description provided for @likelihoodUnlikely.
  ///
  /// In fr, this message translates to:
  /// **'Peu probable'**
  String get likelihoodUnlikely;

  /// No description provided for @urgentHint.
  ///
  /// In fr, this message translates to:
  /// **'À traiter rapidement'**
  String get urgentHint;

  /// No description provided for @saveToJournal.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer dans le journal'**
  String get saveToJournal;

  /// No description provided for @markWatch.
  ///
  /// In fr, this message translates to:
  /// **'Marquer à surveiller'**
  String get markWatch;

  /// No description provided for @diagnosisSettings.
  ///
  /// In fr, this message translates to:
  /// **'Diagnostic'**
  String get diagnosisSettings;

  /// No description provided for @diagnosisSettingsHint.
  ///
  /// In fr, this message translates to:
  /// **'Les photos sont analysées par un modèle hébergé en Suisse (AI Services d\'Infomaniak). Elles ne partent que lorsque vous lancez une analyse, et ne sont pas conservées.'**
  String get diagnosisSettingsHint;

  /// No description provided for @diagnosisEnabled.
  ///
  /// In fr, this message translates to:
  /// **'Diagnostic activé'**
  String get diagnosisEnabled;

  /// No description provided for @diagnosisUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Diagnostic indisponible'**
  String get diagnosisUnavailable;

  /// No description provided for @addPhotos.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter des photos'**
  String get addPhotos;

  /// No description provided for @photosCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 photo} other{{count} photos}}'**
  String photosCount(int count);

  /// No description provided for @diagnosisSaved.
  ///
  /// In fr, this message translates to:
  /// **'Diagnostic ajouté au journal'**
  String get diagnosisSaved;

  /// No description provided for @diagnosisEntry.
  ///
  /// In fr, this message translates to:
  /// **'Diagnostic'**
  String get diagnosisEntry;

  /// No description provided for @diagnosisOpen.
  ///
  /// In fr, this message translates to:
  /// **'Voir le diagnostic complet'**
  String get diagnosisOpen;

  /// No description provided for @diagnosisSymptomsNoted.
  ///
  /// In fr, this message translates to:
  /// **'Symptômes signalés'**
  String get diagnosisSymptomsNoted;

  /// No description provided for @diagnosisMoreCauses.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 autre piste} other{{count} autres pistes}}'**
  String diagnosisMoreCauses(int count);

  /// No description provided for @speciesInfo.
  ///
  /// In fr, this message translates to:
  /// **'Fiche espèce'**
  String get speciesInfo;

  /// No description provided for @speciesSource.
  ///
  /// In fr, this message translates to:
  /// **'Source : GBIF — Global Biodiversity Information Facility'**
  String get speciesSource;

  /// No description provided for @speciesCommonNames.
  ///
  /// In fr, this message translates to:
  /// **'Noms communs'**
  String get speciesCommonNames;

  /// No description provided for @speciesFamily.
  ///
  /// In fr, this message translates to:
  /// **'Famille'**
  String get speciesFamily;

  /// No description provided for @speciesOrder.
  ///
  /// In fr, this message translates to:
  /// **'Ordre'**
  String get speciesOrder;

  /// No description provided for @speciesGenus.
  ///
  /// In fr, this message translates to:
  /// **'Genre'**
  String get speciesGenus;

  /// No description provided for @speciesStatus.
  ///
  /// In fr, this message translates to:
  /// **'Statut'**
  String get speciesStatus;

  /// No description provided for @speciesOpenGbif.
  ///
  /// In fr, this message translates to:
  /// **'Voir sur GBIF'**
  String get speciesOpenGbif;

  /// No description provided for @speciesNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Espèce introuvable dans GBIF.'**
  String get speciesNotFound;

  /// No description provided for @speciesLoading.
  ///
  /// In fr, this message translates to:
  /// **'Recherche dans GBIF…'**
  String get speciesLoading;

  /// No description provided for @speciesPhotos.
  ///
  /// In fr, this message translates to:
  /// **'Observations'**
  String get speciesPhotos;

  /// No description provided for @speciesPhotoCredit.
  ///
  /// In fr, this message translates to:
  /// **'{author} · {license}'**
  String speciesPhotoCredit(String author, String license);

  /// No description provided for @speciesSuggestions.
  ///
  /// In fr, this message translates to:
  /// **'Suggestions'**
  String get speciesSuggestions;

  /// No description provided for @speciesUseName.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser ce nom'**
  String get speciesUseName;

  /// No description provided for @speciesStatusAccepted.
  ///
  /// In fr, this message translates to:
  /// **'Nom accepté'**
  String get speciesStatusAccepted;

  /// No description provided for @speciesStatusSynonym.
  ///
  /// In fr, this message translates to:
  /// **'Synonyme'**
  String get speciesStatusSynonym;

  /// No description provided for @speciesPickerTitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une espèce'**
  String get speciesPickerTitle;

  /// No description provided for @speciesSearchHint.
  ///
  /// In fr, this message translates to:
  /// **'Nom commun, latin, famille…'**
  String get speciesSearchHint;

  /// No description provided for @speciesInGarden.
  ///
  /// In fr, this message translates to:
  /// **'Dans votre jardin'**
  String get speciesInGarden;

  /// No description provided for @speciesCommonList.
  ///
  /// In fr, this message translates to:
  /// **'Espèces courantes'**
  String get speciesCommonList;

  /// No description provided for @speciesGbifResults.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les espèces (GBIF)'**
  String get speciesGbifResults;

  /// No description provided for @speciesGbifCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} espèces correspondantes'**
  String speciesGbifCount(int count);

  /// No description provided for @speciesUseText.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser « {name} »'**
  String speciesUseText(String name);

  /// No description provided for @speciesNoResults.
  ///
  /// In fr, this message translates to:
  /// **'Aucune espèce trouvée'**
  String get speciesNoResults;

  /// No description provided for @speciesOffline.
  ///
  /// In fr, this message translates to:
  /// **'La liste complète nécessite une connexion. Les espèces courantes restent disponibles.'**
  String get speciesOffline;

  /// No description provided for @speciesBrowse.
  ///
  /// In fr, this message translates to:
  /// **'Liste complète'**
  String get speciesBrowse;

  /// No description provided for @speciesCatAll.
  ///
  /// In fr, this message translates to:
  /// **'Toutes'**
  String get speciesCatAll;

  /// No description provided for @speciesCatIndoor.
  ///
  /// In fr, this message translates to:
  /// **'Intérieur'**
  String get speciesCatIndoor;

  /// No description provided for @speciesCatSucculent.
  ///
  /// In fr, this message translates to:
  /// **'Succulentes'**
  String get speciesCatSucculent;

  /// No description provided for @speciesCatHerb.
  ///
  /// In fr, this message translates to:
  /// **'Aromatiques'**
  String get speciesCatHerb;

  /// No description provided for @speciesCatVegetable.
  ///
  /// In fr, this message translates to:
  /// **'Potager'**
  String get speciesCatVegetable;

  /// No description provided for @speciesCatFruit.
  ///
  /// In fr, this message translates to:
  /// **'Fruitiers'**
  String get speciesCatFruit;

  /// No description provided for @speciesCatFlower.
  ///
  /// In fr, this message translates to:
  /// **'Fleurs'**
  String get speciesCatFlower;

  /// No description provided for @speciesCatTree.
  ///
  /// In fr, this message translates to:
  /// **'Arbres et arbustes'**
  String get speciesCatTree;

  /// No description provided for @gardenTasks.
  ///
  /// In fr, this message translates to:
  /// **'Tâches'**
  String get gardenTasks;

  /// No description provided for @tasks.
  ///
  /// In fr, this message translates to:
  /// **'Tâches'**
  String get tasks;

  /// No description provided for @newTask.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle tâche'**
  String get newTask;

  /// No description provided for @editTask.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la tâche'**
  String get editTask;

  /// No description provided for @taskTitleHint.
  ///
  /// In fr, this message translates to:
  /// **'Titre'**
  String get taskTitleHint;

  /// No description provided for @taskDescriptionHint.
  ///
  /// In fr, this message translates to:
  /// **'Détails (facultatif)'**
  String get taskDescriptionHint;

  /// No description provided for @taskPlant.
  ///
  /// In fr, this message translates to:
  /// **'Plante'**
  String get taskPlant;

  /// No description provided for @taskNoPlant.
  ///
  /// In fr, this message translates to:
  /// **'Sans plante'**
  String get taskNoPlant;

  /// No description provided for @taskDue.
  ///
  /// In fr, this message translates to:
  /// **'Échéance'**
  String get taskDue;

  /// No description provided for @taskNoDue.
  ///
  /// In fr, this message translates to:
  /// **'Sans date'**
  String get taskNoDue;

  /// No description provided for @taskTime.
  ///
  /// In fr, this message translates to:
  /// **'Heure'**
  String get taskTime;

  /// No description provided for @taskAllDay.
  ///
  /// In fr, this message translates to:
  /// **'Toute la journée'**
  String get taskAllDay;

  /// No description provided for @taskRecurrence.
  ///
  /// In fr, this message translates to:
  /// **'Récurrence'**
  String get taskRecurrence;

  /// No description provided for @taskRecurrenceNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucune'**
  String get taskRecurrenceNone;

  /// No description provided for @taskEvery.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les'**
  String get taskEvery;

  /// No description provided for @recurrenceLabel.
  ///
  /// In fr, this message translates to:
  /// **'{unit, select, hours{{count, plural, =1{Toutes les heures} other{Toutes les {count} heures}}} days{{count, plural, =1{Tous les jours} other{Tous les {count} jours}}} weeks{{count, plural, =1{Toutes les semaines} other{Toutes les {count} semaines}}} months{{count, plural, =1{Tous les mois} other{Tous les {count} mois}}} years{{count, plural, =1{Tous les ans} other{Tous les {count} ans}}} other{—}}'**
  String recurrenceLabel(String unit, int count);

  /// No description provided for @unitHours.
  ///
  /// In fr, this message translates to:
  /// **'heures'**
  String get unitHours;

  /// No description provided for @unitDays.
  ///
  /// In fr, this message translates to:
  /// **'jours'**
  String get unitDays;

  /// No description provided for @unitWeeks.
  ///
  /// In fr, this message translates to:
  /// **'semaines'**
  String get unitWeeks;

  /// No description provided for @unitMonths.
  ///
  /// In fr, this message translates to:
  /// **'mois'**
  String get unitMonths;

  /// No description provided for @unitYears.
  ///
  /// In fr, this message translates to:
  /// **'ans'**
  String get unitYears;

  /// No description provided for @taskFilterOpen.
  ///
  /// In fr, this message translates to:
  /// **'Ouvertes'**
  String get taskFilterOpen;

  /// No description provided for @taskFilterOverdue.
  ///
  /// In fr, this message translates to:
  /// **'En retard'**
  String get taskFilterOverdue;

  /// No description provided for @taskFilterDone.
  ///
  /// In fr, this message translates to:
  /// **'Terminées'**
  String get taskFilterDone;

  /// No description provided for @taskSectionOverdue.
  ///
  /// In fr, this message translates to:
  /// **'En retard'**
  String get taskSectionOverdue;

  /// No description provided for @taskSectionToday.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get taskSectionToday;

  /// No description provided for @taskSectionUpcoming.
  ///
  /// In fr, this message translates to:
  /// **'À venir'**
  String get taskSectionUpcoming;

  /// No description provided for @taskSectionNoDate.
  ///
  /// In fr, this message translates to:
  /// **'Sans date'**
  String get taskSectionNoDate;

  /// No description provided for @noTasksTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune tâche'**
  String get noTasksTitle;

  /// No description provided for @noTasksSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Semis, nettoyage de la serre, commande de terreau…'**
  String get noTasksSubtitle;

  /// No description provided for @noDoneTasks.
  ///
  /// In fr, this message translates to:
  /// **'Rien de terminé pour l\'instant'**
  String get noDoneTasks;

  /// No description provided for @taskDoneToast.
  ///
  /// In fr, this message translates to:
  /// **'{title} · Terminée'**
  String taskDoneToast(String title);

  /// No description provided for @taskNextToast.
  ///
  /// In fr, this message translates to:
  /// **'{title} · Prochaine fois {date}'**
  String taskNextToast(String title, String date);

  /// No description provided for @taskDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Tâche supprimée'**
  String get taskDeleted;

  /// No description provided for @deleteTask.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la tâche'**
  String get deleteTask;

  /// No description provided for @reopenTask.
  ///
  /// In fr, this message translates to:
  /// **'Rouvrir'**
  String get reopenTask;

  /// No description provided for @taskDoneOn.
  ///
  /// In fr, this message translates to:
  /// **'Terminée {date}'**
  String taskDoneOn(String date);

  /// No description provided for @taskOverdueSince.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{En retard d\'un jour} other{En retard de {count} jours}}'**
  String taskOverdueSince(int count);

  /// No description provided for @taskDueIn.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Demain} other{Dans {count} jours}}'**
  String taskDueIn(int count);

  /// No description provided for @tasksTodayTitle.
  ///
  /// In fr, this message translates to:
  /// **'Tâches'**
  String get tasksTodayTitle;

  /// No description provided for @choosePlant.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une plante'**
  String get choosePlant;

  /// No description provided for @notifTasksOne.
  ///
  /// In fr, this message translates to:
  /// **'Tâche : {title}.'**
  String notifTasksOne(String title);

  /// No description provided for @notifTasksMany.
  ///
  /// In fr, this message translates to:
  /// **'{count} tâches à faire : {titles}.'**
  String notifTasksMany(int count, String titles);

  /// No description provided for @notifTaskDue.
  ///
  /// In fr, this message translates to:
  /// **'À faire : {title}'**
  String notifTaskDue(String title);

  /// No description provided for @careGuide.
  ///
  /// In fr, this message translates to:
  /// **'Fiche d\'entretien'**
  String get careGuide;

  /// No description provided for @careGuideSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Quand arroser, quelle lumière, que surveiller.'**
  String get careGuideSubtitle;

  /// No description provided for @careHowTo.
  ///
  /// In fr, this message translates to:
  /// **'Comment en prendre soin'**
  String get careHowTo;

  /// No description provided for @careWatering.
  ///
  /// In fr, this message translates to:
  /// **'Arrosage'**
  String get careWatering;

  /// No description provided for @careLight.
  ///
  /// In fr, this message translates to:
  /// **'Lumière'**
  String get careLight;

  /// No description provided for @careHumidity.
  ///
  /// In fr, this message translates to:
  /// **'Humidité'**
  String get careHumidity;

  /// No description provided for @careTemperature.
  ///
  /// In fr, this message translates to:
  /// **'Température'**
  String get careTemperature;

  /// No description provided for @careSoil.
  ///
  /// In fr, this message translates to:
  /// **'Substrat'**
  String get careSoil;

  /// No description provided for @careFertilizing.
  ///
  /// In fr, this message translates to:
  /// **'Engrais'**
  String get careFertilizing;

  /// No description provided for @careRepotting.
  ///
  /// In fr, this message translates to:
  /// **'Rempotage'**
  String get careRepotting;

  /// No description provided for @careToxicity.
  ///
  /// In fr, this message translates to:
  /// **'Toxicité'**
  String get careToxicity;

  /// No description provided for @careDifficulty.
  ///
  /// In fr, this message translates to:
  /// **'Difficulté'**
  String get careDifficulty;

  /// No description provided for @carePropagation.
  ///
  /// In fr, this message translates to:
  /// **'Multiplication'**
  String get carePropagation;

  /// No description provided for @careSupport.
  ///
  /// In fr, this message translates to:
  /// **'Tuteur'**
  String get careSupport;

  /// No description provided for @careSupportMossPole.
  ///
  /// In fr, this message translates to:
  /// **'Tuteur moussu'**
  String get careSupportMossPole;

  /// No description provided for @careSupportStake.
  ///
  /// In fr, this message translates to:
  /// **'Tuteur droit'**
  String get careSupportStake;

  /// No description provided for @careSupportTrellis.
  ///
  /// In fr, this message translates to:
  /// **'Treillis'**
  String get careSupportTrellis;

  /// No description provided for @careSupportMossPoleCare.
  ///
  /// In fr, this message translates to:
  /// **'Humidifier le tuteur à chaque arrosage : les racines aériennes s\'y fixent.'**
  String get careSupportMossPoleCare;

  /// No description provided for @careSupportStakeCare.
  ///
  /// In fr, this message translates to:
  /// **'Attacher la tige sans serrer, à mesure qu\'elle monte.'**
  String get careSupportStakeCare;

  /// No description provided for @careSupportTrellisCare.
  ///
  /// In fr, this message translates to:
  /// **'Guider les tiges à mesure qu\'elles poussent.'**
  String get careSupportTrellisCare;

  /// No description provided for @careIssues.
  ///
  /// In fr, this message translates to:
  /// **'À surveiller'**
  String get careIssues;

  /// No description provided for @careKnownProblems.
  ///
  /// In fr, this message translates to:
  /// **'Problèmes connus sur cette plante'**
  String get careKnownProblems;

  /// No description provided for @careKnownProblemsNote.
  ///
  /// In fr, this message translates to:
  /// **'Signalés sur cette espèce ou des espèces proches.'**
  String get careKnownProblemsNote;

  /// No description provided for @careLeafSigns.
  ///
  /// In fr, this message translates to:
  /// **'Signes sur les feuilles'**
  String get careLeafSigns;

  /// No description provided for @careLeafSignsNote.
  ///
  /// In fr, this message translates to:
  /// **'Ce qu\'une feuille montre, et ce qui l\'explique le plus souvent.'**
  String get careLeafSignsNote;

  /// No description provided for @leafSignPaling.
  ///
  /// In fr, this message translates to:
  /// **'Feuilles qui s\'éclaircissent'**
  String get leafSignPaling;

  /// No description provided for @leafSignYellowing.
  ///
  /// In fr, this message translates to:
  /// **'Feuilles jaunes'**
  String get leafSignYellowing;

  /// No description provided for @leafSignScorched.
  ///
  /// In fr, this message translates to:
  /// **'Feuilles brûlées'**
  String get leafSignScorched;

  /// No description provided for @leafSignSpots.
  ///
  /// In fr, this message translates to:
  /// **'Taches au milieu de la feuille'**
  String get leafSignSpots;

  /// No description provided for @leafSignBrownTips.
  ///
  /// In fr, this message translates to:
  /// **'Pointes et bords bruns'**
  String get leafSignBrownTips;

  /// No description provided for @leafSignStunted.
  ///
  /// In fr, this message translates to:
  /// **'Feuilles qui ne grandissent plus'**
  String get leafSignStunted;

  /// No description provided for @leafSignDrooping.
  ///
  /// In fr, this message translates to:
  /// **'Feuilles molles'**
  String get leafSignDrooping;

  /// No description provided for @leafSignFalling.
  ///
  /// In fr, this message translates to:
  /// **'Feuilles qui tombent'**
  String get leafSignFalling;

  /// No description provided for @leafSignSticky.
  ///
  /// In fr, this message translates to:
  /// **'Feuilles collantes'**
  String get leafSignSticky;

  /// No description provided for @leafCauseTooMuchSun.
  ///
  /// In fr, this message translates to:
  /// **'Trop de soleil direct'**
  String get leafCauseTooMuchSun;

  /// No description provided for @leafCauseNotEnoughLight.
  ///
  /// In fr, this message translates to:
  /// **'Pas assez de lumière'**
  String get leafCauseNotEnoughLight;

  /// No description provided for @leafCauseOverwatering.
  ///
  /// In fr, this message translates to:
  /// **'Arrosages trop rapprochés'**
  String get leafCauseOverwatering;

  /// No description provided for @leafCauseUnderwatering.
  ///
  /// In fr, this message translates to:
  /// **'Terreau resté sec trop longtemps'**
  String get leafCauseUnderwatering;

  /// No description provided for @leafCauseDryAir.
  ///
  /// In fr, this message translates to:
  /// **'Air trop sec'**
  String get leafCauseDryAir;

  /// No description provided for @leafCauseColdDraught.
  ///
  /// In fr, this message translates to:
  /// **'Froid ou courant d\'air'**
  String get leafCauseColdDraught;

  /// No description provided for @leafCauseHardWater.
  ///
  /// In fr, this message translates to:
  /// **'Eau calcaire, ou engrais trop concentré'**
  String get leafCauseHardWater;

  /// No description provided for @leafCausePoorSoil.
  ///
  /// In fr, this message translates to:
  /// **'Substrat épuisé'**
  String get leafCausePoorSoil;

  /// No description provided for @leafCausePotBound.
  ///
  /// In fr, this message translates to:
  /// **'Racines à l\'étroit dans le pot'**
  String get leafCausePotBound;

  /// No description provided for @leafCauseDamagedRoots.
  ///
  /// In fr, this message translates to:
  /// **'Racines abîmées par l\'eau stagnante'**
  String get leafCauseDamagedRoots;

  /// No description provided for @leafCauseLeafPests.
  ///
  /// In fr, this message translates to:
  /// **'Piqûres d\'araignées rouges ou de thrips'**
  String get leafCauseLeafPests;

  /// No description provided for @leafCauseHoneydewPests.
  ///
  /// In fr, this message translates to:
  /// **'Cochenilles ou pucerons, sur la plante ou au-dessus'**
  String get leafCauseHoneydewPests;

  /// No description provided for @leafCauseSootyMould.
  ///
  /// In fr, this message translates to:
  /// **'Fumagine, le noir qui pousse sur le miellat'**
  String get leafCauseSootyMould;

  /// No description provided for @leafCauseLeafFungus.
  ///
  /// In fr, this message translates to:
  /// **'Champignon ou bactérie sur la feuille'**
  String get leafCauseLeafFungus;

  /// No description provided for @leafCauseWetLeaves.
  ///
  /// In fr, this message translates to:
  /// **'Eau restée sur le feuillage'**
  String get leafCauseWetLeaves;

  /// No description provided for @leafCauseRecentMove.
  ///
  /// In fr, this message translates to:
  /// **'Déménagement ou rempotage récent'**
  String get leafCauseRecentMove;

  /// No description provided for @leafCauseOldLeaves.
  ///
  /// In fr, this message translates to:
  /// **'Vieillissement des feuilles du bas'**
  String get leafCauseOldLeaves;

  /// No description provided for @leafCauseWinterRest.
  ///
  /// In fr, this message translates to:
  /// **'Repos hivernal'**
  String get leafCauseWinterRest;

  /// No description provided for @problemKindDisorder.
  ///
  /// In fr, this message translates to:
  /// **'Trouble'**
  String get problemKindDisorder;

  /// No description provided for @problemKindPest.
  ///
  /// In fr, this message translates to:
  /// **'Ravageur'**
  String get problemKindPest;

  /// No description provided for @problemKindDisease.
  ///
  /// In fr, this message translates to:
  /// **'Maladie'**
  String get problemKindDisease;

  /// No description provided for @problemKindCondition.
  ///
  /// In fr, this message translates to:
  /// **'Affection'**
  String get problemKindCondition;

  /// No description provided for @problemKindDisorders.
  ///
  /// In fr, this message translates to:
  /// **'Troubles'**
  String get problemKindDisorders;

  /// No description provided for @problemKindPests.
  ///
  /// In fr, this message translates to:
  /// **'Ravageurs'**
  String get problemKindPests;

  /// No description provided for @problemKindDiseases.
  ///
  /// In fr, this message translates to:
  /// **'Maladies'**
  String get problemKindDiseases;

  /// No description provided for @problemKindConditions.
  ///
  /// In fr, this message translates to:
  /// **'Affections'**
  String get problemKindConditions;

  /// No description provided for @careTips.
  ///
  /// In fr, this message translates to:
  /// **'Conseils'**
  String get careTips;

  /// No description provided for @careEveryDays.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Tous les jours} other{Tous les {count} jours}}'**
  String careEveryDays(int count);

  /// No description provided for @careWateringNow.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Tous les jours en ce moment} other{Tous les {count} jours en ce moment}}'**
  String careWateringNow(int count);

  /// No description provided for @careWateringSeasons.
  ///
  /// In fr, this message translates to:
  /// **'{summer} j en pleine saison · {winter} j en hiver'**
  String careWateringSeasons(int summer, int winter);

  /// No description provided for @careDryDownAlwaysMoist.
  ///
  /// In fr, this message translates to:
  /// **'Terreau toujours humide'**
  String get careDryDownAlwaysMoist;

  /// No description provided for @careDryDownSurfaceDry.
  ///
  /// In fr, this message translates to:
  /// **'Laisser sécher la surface'**
  String get careDryDownSurfaceDry;

  /// No description provided for @careDryDownTopQuarterDry.
  ///
  /// In fr, this message translates to:
  /// **'Laisser sécher le quart supérieur'**
  String get careDryDownTopQuarterDry;

  /// No description provided for @careDryDownHalfDry.
  ///
  /// In fr, this message translates to:
  /// **'Laisser sécher à moitié'**
  String get careDryDownHalfDry;

  /// No description provided for @careDryDownMostlyDry.
  ///
  /// In fr, this message translates to:
  /// **'Laisser sécher presque à fond'**
  String get careDryDownMostlyDry;

  /// No description provided for @careDryDownFullyDry.
  ///
  /// In fr, this message translates to:
  /// **'Laisser sécher complètement'**
  String get careDryDownFullyDry;

  /// No description provided for @careFertilizeSeason.
  ///
  /// In fr, this message translates to:
  /// **'de {from} à {to}'**
  String careFertilizeSeason(String from, String to);

  /// No description provided for @careNoFertilizer.
  ///
  /// In fr, this message translates to:
  /// **'Aucun engrais nécessaire'**
  String get careNoFertilizer;

  /// No description provided for @careRepotMonths.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Chaque mois} other{Tous les {count} mois}}'**
  String careRepotMonths(int count);

  /// No description provided for @careRepotYears.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Tous les ans} other{Tous les {count} ans}}'**
  String careRepotYears(int count);

  /// No description provided for @careRepotNone.
  ///
  /// In fr, this message translates to:
  /// **'Pas de rempotage (culture annuelle)'**
  String get careRepotNone;

  /// No description provided for @carePotSnug.
  ///
  /// In fr, this message translates to:
  /// **'Mieux à l\'étroit'**
  String get carePotSnug;

  /// No description provided for @carePotRoomy.
  ///
  /// In fr, this message translates to:
  /// **'Un pot large'**
  String get carePotRoomy;

  /// No description provided for @carePotSnugNote.
  ///
  /// In fr, this message translates to:
  /// **'Une racine qui sort par le fond ne suffit pas : rempotez quand la motte est un bloc de racines, ou quand l\'eau ne pénètre plus.'**
  String get carePotSnugNote;

  /// No description provided for @carePotSteadyNote.
  ///
  /// In fr, this message translates to:
  /// **'Rempotez quand les racines sortent par le fond et tournent au fond du pot.'**
  String get carePotSteadyNote;

  /// No description provided for @carePotRoomyNote.
  ///
  /// In fr, this message translates to:
  /// **'Rempotez dès que les racines atteignent la paroi : à l\'étroit, elle arrête de pousser.'**
  String get carePotRoomyNote;

  /// No description provided for @carePotDormantNote.
  ///
  /// In fr, this message translates to:
  /// **'Le rempotage se fait à la reprise, quand le repos s\'achève, et non sur une racine qui sort.'**
  String get carePotDormantNote;

  /// No description provided for @careTempIdeal.
  ///
  /// In fr, this message translates to:
  /// **'{min} à {max} °C'**
  String careTempIdeal(int min, int max);

  /// No description provided for @careTempMin.
  ///
  /// In fr, this message translates to:
  /// **'Éviter sous {min} °C'**
  String careTempMin(int min);

  /// No description provided for @careEnvTitle.
  ///
  /// In fr, this message translates to:
  /// **'Emplacement idéal'**
  String get careEnvTitle;

  /// No description provided for @careEnvHumidity.
  ///
  /// In fr, this message translates to:
  /// **'{min}–{max} %'**
  String careEnvHumidity(int min, int max);

  /// No description provided for @careEnvTempRange.
  ///
  /// In fr, this message translates to:
  /// **'{min}–{max} °C'**
  String careEnvTempRange(int min, int max);

  /// No description provided for @careEnvTempMin.
  ///
  /// In fr, this message translates to:
  /// **'≥ {min} °C'**
  String careEnvTempMin(int min);

  /// No description provided for @careEnvSemanticTemp.
  ///
  /// In fr, this message translates to:
  /// **'température de {min} à {max} degrés'**
  String careEnvSemanticTemp(int min, int max);

  /// No description provided for @careEnvSemanticTempMin.
  ///
  /// In fr, this message translates to:
  /// **'température au-dessus de {min} degrés'**
  String careEnvSemanticTempMin(int min);

  /// No description provided for @careAirflow.
  ///
  /// In fr, this message translates to:
  /// **'Courants d\'air'**
  String get careAirflow;

  /// No description provided for @careAirflowSheltered.
  ///
  /// In fr, this message translates to:
  /// **'À l\'abri des courants d\'air'**
  String get careAirflowSheltered;

  /// No description provided for @careAirflowNormal.
  ///
  /// In fr, this message translates to:
  /// **'Air ordinaire'**
  String get careAirflowNormal;

  /// No description provided for @careAirflowVentilated.
  ///
  /// In fr, this message translates to:
  /// **'Air bien ventilé'**
  String get careAirflowVentilated;

  /// No description provided for @careLightShade.
  ///
  /// In fr, this message translates to:
  /// **'Ombre'**
  String get careLightShade;

  /// No description provided for @careLightLow.
  ///
  /// In fr, this message translates to:
  /// **'Faible lumière'**
  String get careLightLow;

  /// No description provided for @careLightIndirect.
  ///
  /// In fr, this message translates to:
  /// **'Lumière indirecte'**
  String get careLightIndirect;

  /// No description provided for @careLightBright.
  ///
  /// In fr, this message translates to:
  /// **'Lumière vive indirecte'**
  String get careLightBright;

  /// No description provided for @careLightSome.
  ///
  /// In fr, this message translates to:
  /// **'Quelques heures de soleil'**
  String get careLightSome;

  /// No description provided for @careLightFull.
  ///
  /// In fr, this message translates to:
  /// **'Plein soleil'**
  String get careLightFull;

  /// No description provided for @careLightFloor.
  ///
  /// In fr, this message translates to:
  /// **'Tient jusqu\'à {value}'**
  String careLightFloor(String value);

  /// No description provided for @careLightLamp.
  ///
  /// In fr, this message translates to:
  /// **'Sous lampe · LED à spectre complet, {min} à {max} µmol/m²/s, {hours} h par jour'**
  String careLightLamp(int min, int max, int hours);

  /// No description provided for @careLightLampDli.
  ///
  /// In fr, this message translates to:
  /// **'Soit {min} à {max} mol/m²/jour reçus par le feuillage.'**
  String careLightLampDli(int min, int max);

  /// No description provided for @careHumidityLow.
  ///
  /// In fr, this message translates to:
  /// **'Air sec accepté'**
  String get careHumidityLow;

  /// No description provided for @careHumidityAverage.
  ///
  /// In fr, this message translates to:
  /// **'Humidité ordinaire'**
  String get careHumidityAverage;

  /// No description provided for @careHumidityHigh.
  ///
  /// In fr, this message translates to:
  /// **'Air humide'**
  String get careHumidityHigh;

  /// No description provided for @careHumidityRange.
  ///
  /// In fr, this message translates to:
  /// **'{min} à {max} % d\'humidité de l\'air'**
  String careHumidityRange(int min, int max);

  /// No description provided for @careHumidityLowDetail.
  ///
  /// In fr, this message translates to:
  /// **'Elle tolère bien l\'air sec d\'un logement. Une humidité durablement plus haute l\'abîme.'**
  String get careHumidityLowDetail;

  /// No description provided for @careHumidityAverageDetail.
  ///
  /// In fr, this message translates to:
  /// **'L\'air ordinaire d\'un logement convient. Loin d\'un radiateur en hiver, les pointes des feuilles ne brunissent pas.'**
  String get careHumidityAverageDetail;

  /// No description provided for @careHumidityHighDetail.
  ///
  /// In fr, this message translates to:
  /// **'L\'air sec d\'un logement chauffé l\'abîme : il faut le maintenir humide.'**
  String get careHumidityHighDetail;

  /// No description provided for @careHumidityMethodMist.
  ///
  /// In fr, this message translates to:
  /// **'Brumiser le feuillage.'**
  String get careHumidityMethodMist;

  /// No description provided for @careHumidityMethodHumidifier.
  ///
  /// In fr, this message translates to:
  /// **'Un humidificateur d\'air.'**
  String get careHumidityMethodHumidifier;

  /// No description provided for @careHumidityMethodTray.
  ///
  /// In fr, this message translates to:
  /// **'Un plateau de billes d\'argile humides, ou des plantes regroupées.'**
  String get careHumidityMethodTray;

  /// No description provided for @careHumidityMethodTerrarium.
  ///
  /// In fr, this message translates to:
  /// **'Sous verre : terrarium, cloche ou bocal.'**
  String get careHumidityMethodTerrarium;

  /// No description provided for @careDifficultyEasy.
  ///
  /// In fr, this message translates to:
  /// **'Facile'**
  String get careDifficultyEasy;

  /// No description provided for @careDifficultyMedium.
  ///
  /// In fr, this message translates to:
  /// **'Moyenne'**
  String get careDifficultyMedium;

  /// No description provided for @careDifficultyDemanding.
  ///
  /// In fr, this message translates to:
  /// **'Exigeante'**
  String get careDifficultyDemanding;

  /// No description provided for @careToxicSafe.
  ///
  /// In fr, this message translates to:
  /// **'Sans danger connu'**
  String get careToxicSafe;

  /// No description provided for @careToxicMild.
  ///
  /// In fr, this message translates to:
  /// **'Légèrement irritante'**
  String get careToxicMild;

  /// No description provided for @careToxicToxic.
  ///
  /// In fr, this message translates to:
  /// **'Toxique si ingérée'**
  String get careToxicToxic;

  /// No description provided for @careToxicUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Toxicité non renseignée'**
  String get careToxicUnknown;

  /// No description provided for @careToxicPets.
  ///
  /// In fr, this message translates to:
  /// **'Tenir hors de portée des animaux et des enfants.'**
  String get careToxicPets;

  /// No description provided for @careToxicityFromSpecies.
  ///
  /// In fr, this message translates to:
  /// **'Vérifié pour cette espèce'**
  String get careToxicityFromSpecies;

  /// No description provided for @careToxicityFromGenus.
  ///
  /// In fr, this message translates to:
  /// **'Genre {name} · non vérifié pour cette espèce'**
  String careToxicityFromGenus(String name);

  /// No description provided for @careToxicityFromFamily.
  ///
  /// In fr, this message translates to:
  /// **'Famille des {name} · non vérifié pour cette espèce'**
  String careToxicityFromFamily(String name);

  /// No description provided for @careToxicitySource.
  ///
  /// In fr, this message translates to:
  /// **'Source : {name}'**
  String careToxicitySource(String name);

  /// No description provided for @careSoilStandard.
  ///
  /// In fr, this message translates to:
  /// **'Terreau universel'**
  String get careSoilStandard;

  /// No description provided for @careSoilDraining.
  ///
  /// In fr, this message translates to:
  /// **'Terreau très drainant'**
  String get careSoilDraining;

  /// No description provided for @careSoilCactus.
  ///
  /// In fr, this message translates to:
  /// **'Terreau cactus et succulentes'**
  String get careSoilCactus;

  /// No description provided for @careSoilOrchid.
  ///
  /// In fr, this message translates to:
  /// **'Écorces pour orchidées'**
  String get careSoilOrchid;

  /// No description provided for @careSoilAcidic.
  ///
  /// In fr, this message translates to:
  /// **'Terre de bruyère'**
  String get careSoilAcidic;

  /// No description provided for @careSoilRich.
  ///
  /// In fr, this message translates to:
  /// **'Terreau riche en compost'**
  String get careSoilRich;

  /// No description provided for @careSoilNone.
  ///
  /// In fr, this message translates to:
  /// **'Sans substrat'**
  String get careSoilNone;

  /// No description provided for @careGrowthMedium.
  ///
  /// In fr, this message translates to:
  /// **'Milieu de vie'**
  String get careGrowthMedium;

  /// No description provided for @careMediumTerrestrial.
  ///
  /// In fr, this message translates to:
  /// **'Terrestre'**
  String get careMediumTerrestrial;

  /// No description provided for @careMediumEpiphytic.
  ///
  /// In fr, this message translates to:
  /// **'Épiphyte'**
  String get careMediumEpiphytic;

  /// No description provided for @careMediumLithophytic.
  ///
  /// In fr, this message translates to:
  /// **'Lithophyte'**
  String get careMediumLithophytic;

  /// No description provided for @careMediumAquatic.
  ///
  /// In fr, this message translates to:
  /// **'Aquatique'**
  String get careMediumAquatic;

  /// No description provided for @careMediumSemiAquatic.
  ///
  /// In fr, this message translates to:
  /// **'Semi-aquatique'**
  String get careMediumSemiAquatic;

  /// No description provided for @careMediumTerrestrialNote.
  ///
  /// In fr, this message translates to:
  /// **'Elle pousse en terre.'**
  String get careMediumTerrestrialNote;

  /// No description provided for @careMediumEpiphyticNote.
  ///
  /// In fr, this message translates to:
  /// **'Elle pousse sur un support, sans terreau : écorces, sphaigne, ou rien.'**
  String get careMediumEpiphyticNote;

  /// No description provided for @careMediumLithophyticNote.
  ///
  /// In fr, this message translates to:
  /// **'Elle pousse sur la pierre, ses racines dans les fissures.'**
  String get careMediumLithophyticNote;

  /// No description provided for @careMediumAquaticNote.
  ///
  /// In fr, this message translates to:
  /// **'Ses racines vivent dans l\'eau.'**
  String get careMediumAquaticNote;

  /// No description provided for @careMediumSemiAquaticNote.
  ///
  /// In fr, this message translates to:
  /// **'Elle vit en sol détrempé, au bord de l\'eau.'**
  String get careMediumSemiAquaticNote;

  /// No description provided for @careWater.
  ///
  /// In fr, this message translates to:
  /// **'Eau'**
  String get careWater;

  /// No description provided for @careWaterTolerant.
  ///
  /// In fr, this message translates to:
  /// **'Eau du robinet'**
  String get careWaterTolerant;

  /// No description provided for @careWaterSensitive.
  ///
  /// In fr, this message translates to:
  /// **'Eau peu calcaire'**
  String get careWaterSensitive;

  /// No description provided for @careWaterStrict.
  ///
  /// In fr, this message translates to:
  /// **'Eau sans calcaire'**
  String get careWaterStrict;

  /// No description provided for @careWaterTolerantNote.
  ///
  /// In fr, this message translates to:
  /// **'Le calcaire est sans effet.'**
  String get careWaterTolerantNote;

  /// No description provided for @careWaterSensitiveNote.
  ///
  /// In fr, this message translates to:
  /// **'Le calcaire lui brunit les pointes.'**
  String get careWaterSensitiveNote;

  /// No description provided for @careWaterFluorideSensitive.
  ///
  /// In fr, this message translates to:
  /// **'Le fluor du robinet lui brunit les pointes : eau de pluie ou osmosée.'**
  String get careWaterFluorideSensitive;

  /// No description provided for @careWaterStrictNote.
  ///
  /// In fr, this message translates to:
  /// **'Le calcaire l\'abîme, même en petite quantité.'**
  String get careWaterStrictNote;

  /// No description provided for @careWaterTypes.
  ///
  /// In fr, this message translates to:
  /// **'Types d\'eau'**
  String get careWaterTypes;

  /// No description provided for @careWaterTypesNote.
  ///
  /// In fr, this message translates to:
  /// **'La dureté de l\'eau du robinet change d\'une commune à l\'autre ; l\'analyse annuelle du distributeur la donne.'**
  String get careWaterTypesNote;

  /// No description provided for @careWaterBest.
  ///
  /// In fr, this message translates to:
  /// **'Recommandée'**
  String get careWaterBest;

  /// No description provided for @careWaterOk.
  ///
  /// In fr, this message translates to:
  /// **'Convient'**
  String get careWaterOk;

  /// No description provided for @careWaterCaution.
  ///
  /// In fr, this message translates to:
  /// **'Avec réserve'**
  String get careWaterCaution;

  /// No description provided for @careWaterAvoid.
  ///
  /// In fr, this message translates to:
  /// **'À éviter'**
  String get careWaterAvoid;

  /// No description provided for @careWaterTap.
  ///
  /// In fr, this message translates to:
  /// **'Eau du robinet'**
  String get careWaterTap;

  /// No description provided for @careWaterTapNote.
  ///
  /// In fr, this message translates to:
  /// **'L\'eau du réseau, telle qu\'elle sort. Sa dureté dépend de la commune.'**
  String get careWaterTapNote;

  /// No description provided for @careWaterTapRisk.
  ///
  /// In fr, this message translates to:
  /// **'Le calcaire s\'accumule dans le terreau et fait monter son pH. Laisser reposer l\'eau chasse le chlore, pas le calcaire.'**
  String get careWaterTapRisk;

  /// No description provided for @careWaterRain.
  ///
  /// In fr, this message translates to:
  /// **'Eau de pluie'**
  String get careWaterRain;

  /// No description provided for @careWaterRainNote.
  ///
  /// In fr, this message translates to:
  /// **'Douce, sans calcaire, légèrement acide.'**
  String get careWaterRainNote;

  /// No description provided for @careWaterRainRisk.
  ///
  /// In fr, this message translates to:
  /// **'Recueillie sur un toit, elle emporte poussières et fientes ; une réserve à l\'air libre verdit. Écarter les premières minutes de pluie, couvrir le tonneau.'**
  String get careWaterRainRisk;

  /// No description provided for @careWaterFiltered.
  ///
  /// In fr, this message translates to:
  /// **'Eau filtrée'**
  String get careWaterFiltered;

  /// No description provided for @careWaterFilteredNote.
  ///
  /// In fr, this message translates to:
  /// **'Une carafe filtrante retire le chlore et une part du calcaire.'**
  String get careWaterFilteredNote;

  /// No description provided for @careWaterFilteredRisk.
  ///
  /// In fr, this message translates to:
  /// **'La part retenue dépend de la cartouche, et une cartouche épuisée ne retient plus rien. Le calcaire n\'est jamais entièrement retiré.'**
  String get careWaterFilteredRisk;

  /// No description provided for @careWaterOsmosis.
  ///
  /// In fr, this message translates to:
  /// **'Eau osmosée'**
  String get careWaterOsmosis;

  /// No description provided for @careWaterOsmosisNote.
  ///
  /// In fr, this message translates to:
  /// **'Presque sans minéraux, comme l\'eau de pluie.'**
  String get careWaterOsmosisNote;

  /// No description provided for @careWaterOsmosisRisk.
  ///
  /// In fr, this message translates to:
  /// **'Elle n\'apporte aucun élément nutritif : l\'engrais devient la seule source. Pour une plante ordinaire, un tiers d\'eau du robinet la rééquilibre.'**
  String get careWaterOsmosisRisk;

  /// No description provided for @careWaterDemineralized.
  ///
  /// In fr, this message translates to:
  /// **'Eau déminéralisée'**
  String get careWaterDemineralized;

  /// No description provided for @careWaterDemineralizedNote.
  ///
  /// In fr, this message translates to:
  /// **'Vendue pour les fers à repasser, elle vaut l\'eau osmosée quand elle est pure.'**
  String get careWaterDemineralizedNote;

  /// No description provided for @careWaterDemineralizedRisk.
  ///
  /// In fr, this message translates to:
  /// **'Certains bidons contiennent un antitartre ou un parfum : lire l\'étiquette. Comme l\'eau osmosée, elle n\'apporte aucun élément nutritif.'**
  String get careWaterDemineralizedRisk;

  /// No description provided for @careWaterCondensate.
  ///
  /// In fr, this message translates to:
  /// **'Eau de climatiseur'**
  String get careWaterCondensate;

  /// No description provided for @careWaterCondensateNote.
  ///
  /// In fr, this message translates to:
  /// **'Le condensat d\'un climatiseur ou d\'un déshumidificateur, une eau distillée par l\'appareil.'**
  String get careWaterCondensateNote;

  /// No description provided for @careWaterCondensateRisk.
  ///
  /// In fr, this message translates to:
  /// **'Elle a ruisselé sur un échangeur et dans un bac où s\'accumulent poussières, biofilm et bactéries, et peut emporter des traces de métaux. À réserver aux plantes d\'ornement, sur un appareil propre, jamais sur ce qui se mange.'**
  String get careWaterCondensateRisk;

  /// No description provided for @careWaterSoftened.
  ///
  /// In fr, this message translates to:
  /// **'Eau adoucie'**
  String get careWaterSoftened;

  /// No description provided for @careWaterSoftenedNote.
  ///
  /// In fr, this message translates to:
  /// **'Un adoucisseur à résine remplace le calcaire par du sodium.'**
  String get careWaterSoftenedNote;

  /// No description provided for @careWaterSoftenedRisk.
  ///
  /// In fr, this message translates to:
  /// **'Le sodium s\'accumule dans le terreau, abîme les racines et ferme la structure du sol. Le robinet d\'eau brute, en amont de l\'adoucisseur, reste le bon.'**
  String get careWaterSoftenedRisk;

  /// No description provided for @careSoilMixStandard.
  ///
  /// In fr, this message translates to:
  /// **'Allégé de 20 % de perlite, pour que l\'eau traverse.'**
  String get careSoilMixStandard;

  /// No description provided for @careSoilMixDraining.
  ///
  /// In fr, this message translates to:
  /// **'50 % de terreau, 25 % de perlite, 25 % de sable grossier ou de pouzzolane.'**
  String get careSoilMixDraining;

  /// No description provided for @careSoilMixCactus.
  ///
  /// In fr, this message translates to:
  /// **'30 % de terreau, 70 % de pouzzolane, de pierre ponce ou de sable grossier.'**
  String get careSoilMixCactus;

  /// No description provided for @careSoilMixOrchid.
  ///
  /// In fr, this message translates to:
  /// **'Écorces de pin moyennes, 10 % de perlite, un peu de sphaigne ; jamais de terreau.'**
  String get careSoilMixOrchid;

  /// No description provided for @careSoilMixAcidic.
  ///
  /// In fr, this message translates to:
  /// **'Allégée de 25 % d\'écorce de pin, sans calcaire ni compost.'**
  String get careSoilMixAcidic;

  /// No description provided for @careSoilMixRich.
  ///
  /// In fr, this message translates to:
  /// **'40 % de terreau, 40 % de compost, 20 % de perlite.'**
  String get careSoilMixRich;

  /// No description provided for @careSoilMixNone.
  ///
  /// In fr, this message translates to:
  /// **'Pas de substrat : les racines vivent à l\'air ou dans l\'eau.'**
  String get careSoilMixNone;

  /// No description provided for @careSoilFree.
  ///
  /// In fr, this message translates to:
  /// **'Dans l\'eau : {water} · En pon : {pon}'**
  String careSoilFree(String water, String pon);

  /// No description provided for @careSoilFreeYes.
  ///
  /// In fr, this message translates to:
  /// **'oui'**
  String get careSoilFreeYes;

  /// No description provided for @careSoilFreeNo.
  ///
  /// In fr, this message translates to:
  /// **'non'**
  String get careSoilFreeNo;

  /// No description provided for @careSoilFreeCuttings.
  ///
  /// In fr, this message translates to:
  /// **'bouture seulement'**
  String get careSoilFreeCuttings;

  /// No description provided for @careFertBalanced.
  ///
  /// In fr, this message translates to:
  /// **'Engrais plantes vertes équilibré, dilué de moitié.'**
  String get careFertBalanced;

  /// No description provided for @careFertFoliage.
  ///
  /// In fr, this message translates to:
  /// **'Engrais riche en azote, celui du feuillage.'**
  String get careFertFoliage;

  /// No description provided for @careFertFlowering.
  ///
  /// In fr, this message translates to:
  /// **'Engrais riche en potasse, celui de la floraison.'**
  String get careFertFlowering;

  /// No description provided for @careFertCactus.
  ///
  /// In fr, this message translates to:
  /// **'Engrais cactées, pauvre en azote.'**
  String get careFertCactus;

  /// No description provided for @careFertOrchid.
  ///
  /// In fr, this message translates to:
  /// **'Engrais orchidées, très dilué.'**
  String get careFertOrchid;

  /// No description provided for @careFertAcidic.
  ///
  /// In fr, this message translates to:
  /// **'Engrais pour terre de bruyère, sans calcaire.'**
  String get careFertAcidic;

  /// No description provided for @careFertCitrus.
  ///
  /// In fr, this message translates to:
  /// **'Engrais agrumes, riche en azote et en oligo-éléments.'**
  String get careFertCitrus;

  /// No description provided for @careFertVegetable.
  ///
  /// In fr, this message translates to:
  /// **'Engrais tomates, riche en potasse.'**
  String get careFertVegetable;

  /// No description provided for @careCalciumAvoid.
  ///
  /// In fr, this message translates to:
  /// **'Calcium : aucun apport, et de l\'eau de pluie ; le calcaire fait jaunir son feuillage.'**
  String get careCalciumAvoid;

  /// No description provided for @careCalciumWelcome.
  ///
  /// In fr, this message translates to:
  /// **'Calcium : l\'eau calcaire est sans risque ; des coquilles d\'œufs broyées au rempotage en apportent.'**
  String get careCalciumWelcome;

  /// No description provided for @careCalciumNeeded.
  ///
  /// In fr, this message translates to:
  /// **'Calcium : un apport régulier évite la nécrose apicale des fruits.'**
  String get careCalciumNeeded;

  /// No description provided for @careGreenhouse.
  ///
  /// In fr, this message translates to:
  /// **'Sous serre'**
  String get careGreenhouse;

  /// No description provided for @careGreenhouseWarmHumid.
  ///
  /// In fr, this message translates to:
  /// **'Chaleur et air humide'**
  String get careGreenhouseWarmHumid;

  /// No description provided for @careGreenhouseWarmLight.
  ///
  /// In fr, this message translates to:
  /// **'Chaleur et lumière'**
  String get careGreenhouseWarmLight;

  /// No description provided for @careGreenhouseWarmDry.
  ///
  /// In fr, this message translates to:
  /// **'Chaleur, lumière et air sec'**
  String get careGreenhouseWarmDry;

  /// No description provided for @careGreenhouseGrowth.
  ///
  /// In fr, this message translates to:
  /// **'Tenues toute l\'année, ces conditions accélèrent la pousse : l\'arrosage et l\'engrais se rapprochent d\'autant.'**
  String get careGreenhouseGrowth;

  /// No description provided for @careGreenhouseHold.
  ///
  /// In fr, this message translates to:
  /// **'Tenez la plage d\'humidité le jour, laissez-la descendre la nuit, et faites circuler l\'air.'**
  String get careGreenhouseHold;

  /// No description provided for @careGreenhouseAir.
  ///
  /// In fr, this message translates to:
  /// **'Aérer chaque jour : l\'air confiné fait pourrir les plantes de milieu sec.'**
  String get careGreenhouseAir;

  /// No description provided for @careGreenhouseEarly.
  ///
  /// In fr, this message translates to:
  /// **'En mini-serre ou sous châssis, les semis partent quatre à six semaines plus tôt.'**
  String get careGreenhouseEarly;

  /// No description provided for @careBloom.
  ///
  /// In fr, this message translates to:
  /// **'Floraison'**
  String get careBloom;

  /// No description provided for @careSeasonRange.
  ///
  /// In fr, this message translates to:
  /// **'De {from} à {to}'**
  String careSeasonRange(String from, String to);

  /// No description provided for @careBloomOutdoors.
  ///
  /// In fr, this message translates to:
  /// **'Rarement en intérieur'**
  String get careBloomOutdoors;

  /// No description provided for @careBloomChillBulb.
  ///
  /// In fr, this message translates to:
  /// **'Un froid au bulbe'**
  String get careBloomChillBulb;

  /// No description provided for @careBloomChillBulbNote.
  ///
  /// In fr, this message translates to:
  /// **'Comptez dix à quinze semaines entre 5 et 9 °C, au noir, avant de remettre le pot à la chaleur et à la lumière.'**
  String get careBloomChillBulbNote;

  /// No description provided for @careBloomFertilizer.
  ///
  /// In fr, this message translates to:
  /// **'Un engrais de floraison'**
  String get careBloomFertilizer;

  /// No description provided for @careBloomFertilizerNote.
  ///
  /// In fr, this message translates to:
  /// **'Dès que les boutons se forment, passez à un engrais de floraison, plus riche en potasse que celui du feuillage.'**
  String get careBloomFertilizerNote;

  /// No description provided for @careBloomMaturity.
  ///
  /// In fr, this message translates to:
  /// **'De l\'âge'**
  String get careBloomMaturity;

  /// No description provided for @careBloomMaturityNote.
  ///
  /// In fr, this message translates to:
  /// **'Elle ne fleurit qu\'à partir de trois ou quatre ans : avant cet âge, aucune condition n\'y changera rien.'**
  String get careBloomMaturityNote;

  /// No description provided for @careBloomDeadhead.
  ///
  /// In fr, this message translates to:
  /// **'Des fleurs coupées'**
  String get careBloomDeadhead;

  /// No description provided for @careBloomDeadheadNote.
  ///
  /// In fr, this message translates to:
  /// **'Coupez les fleurs fanées au fur et à mesure : sans graines à former, la plante refleurit.'**
  String get careBloomDeadheadNote;

  /// No description provided for @careBloomKeepSpike.
  ///
  /// In fr, this message translates to:
  /// **'Une hampe gardée'**
  String get careBloomKeepSpike;

  /// No description provided for @careBloomKeepSpikeNote.
  ///
  /// In fr, this message translates to:
  /// **'Tant que la hampe reste verte, laissez-la en place : elle peut refleurir depuis un œil situé plus bas.'**
  String get careBloomKeepSpikeNote;

  /// No description provided for @careBloomNoMove.
  ///
  /// In fr, this message translates to:
  /// **'Une place fixe'**
  String get careBloomNoMove;

  /// No description provided for @careBloomNoMoveNote.
  ///
  /// In fr, this message translates to:
  /// **'Une fois les boutons formés, ne la déplacez plus et ne la tournez plus : le changement les fait tomber.'**
  String get careBloomNoMoveNote;

  /// No description provided for @careBloomEvenWater.
  ///
  /// In fr, this message translates to:
  /// **'Un arrosage régulier'**
  String get careBloomEvenWater;

  /// No description provided for @careBloomEvenWaterNote.
  ///
  /// In fr, this message translates to:
  /// **'Pendant la formation des boutons, arrosez régulièrement : un seul coup de sec suffit à les faire tomber.'**
  String get careBloomEvenWaterNote;

  /// No description provided for @careRest.
  ///
  /// In fr, this message translates to:
  /// **'Repos'**
  String get careRest;

  /// No description provided for @careRestStoreDarkTemp.
  ///
  /// In fr, this message translates to:
  /// **'Au sec et à l\'obscurité, entre {min} et {max} °C'**
  String careRestStoreDarkTemp(int min, int max);

  /// No description provided for @careRestStoreTemp.
  ///
  /// In fr, this message translates to:
  /// **'Au sec, entre {min} et {max} °C'**
  String careRestStoreTemp(int min, int max);

  /// No description provided for @careRestStoreDark.
  ///
  /// In fr, this message translates to:
  /// **'Au sec et à l\'obscurité'**
  String get careRestStoreDark;

  /// No description provided for @careRestStorePlain.
  ///
  /// In fr, this message translates to:
  /// **'Au sec'**
  String get careRestStorePlain;

  /// No description provided for @careRestNote.
  ///
  /// In fr, this message translates to:
  /// **'Laissez le feuillage jaunir et sécher sans le couper, puis arrêtez l\'arrosage. Remettez le pot à la lumière et reprenez l\'arrosage à la fin de cette période.'**
  String get careRestNote;

  /// No description provided for @careBloomCoolRest.
  ///
  /// In fr, this message translates to:
  /// **'Un hiver frais'**
  String get careBloomCoolRest;

  /// No description provided for @careBloomCoolRestNote.
  ///
  /// In fr, this message translates to:
  /// **'Pour préparer la floraison, gardez-la environ deux mois entre 10 et 12 °C et réduisez fortement les arrosages.'**
  String get careBloomCoolRestNote;

  /// No description provided for @careBloomCoolNights.
  ///
  /// In fr, this message translates to:
  /// **'Des nuits fraîches'**
  String get careBloomCoolNights;

  /// No description provided for @careBloomCoolNightsNote.
  ///
  /// In fr, this message translates to:
  /// **'En automne, environ trois semaines avec des nuits autour de 15 °C peuvent déclencher la hampe florale.'**
  String get careBloomCoolNightsNote;

  /// No description provided for @careBloomShortDays.
  ///
  /// In fr, this message translates to:
  /// **'Des jours courts'**
  String get careBloomShortDays;

  /// No description provided for @careBloomShortDaysNote.
  ///
  /// In fr, this message translates to:
  /// **'Pendant environ six semaines, des nuits d\'au moins 12 heures d\'obscurité déclenchent la formation des boutons.'**
  String get careBloomShortDaysNote;

  /// No description provided for @careBloomDrySpell.
  ///
  /// In fr, this message translates to:
  /// **'Une sécheresse'**
  String get careBloomDrySpell;

  /// No description provided for @careBloomDrySpellNote.
  ///
  /// In fr, this message translates to:
  /// **'Réduisez fortement les arrosages pendant quelques semaines, puis reprenez progressivement : ce contraste peut déclencher la floraison.'**
  String get careBloomDrySpellNote;

  /// No description provided for @careBloomPotbound.
  ///
  /// In fr, this message translates to:
  /// **'Un pot à l\'étroit'**
  String get careBloomPotbound;

  /// No description provided for @careBloomPotboundNote.
  ///
  /// In fr, this message translates to:
  /// **'Elle fleurit souvent mieux lorsque ses racines occupent bien le pot. Évitez donc de rempoter trop tôt.'**
  String get careBloomPotboundNote;

  /// No description provided for @careBloomBrightLight.
  ///
  /// In fr, this message translates to:
  /// **'Plus de lumière'**
  String get careBloomBrightLight;

  /// No description provided for @careBloomBrightLightNote.
  ///
  /// In fr, this message translates to:
  /// **'La floraison demande plus de lumière que la pousse : un endroit très lumineux, sans soleil brûlant.'**
  String get careBloomBrightLightNote;

  /// No description provided for @carePropCutting.
  ///
  /// In fr, this message translates to:
  /// **'Bouture de tige'**
  String get carePropCutting;

  /// No description provided for @carePropLeaf.
  ///
  /// In fr, this message translates to:
  /// **'Bouture de feuille'**
  String get carePropLeaf;

  /// No description provided for @carePropDivision.
  ///
  /// In fr, this message translates to:
  /// **'Division de la touffe'**
  String get carePropDivision;

  /// No description provided for @carePropOffsets.
  ///
  /// In fr, this message translates to:
  /// **'Rejets'**
  String get carePropOffsets;

  /// No description provided for @carePropLayering.
  ///
  /// In fr, this message translates to:
  /// **'Marcottage'**
  String get carePropLayering;

  /// No description provided for @carePropSeed.
  ///
  /// In fr, this message translates to:
  /// **'Semis'**
  String get carePropSeed;

  /// No description provided for @carePropWater.
  ///
  /// In fr, this message translates to:
  /// **'Bouture dans l\'eau'**
  String get carePropWater;

  /// No description provided for @carePropTuber.
  ///
  /// In fr, this message translates to:
  /// **'Séparation des tubercules'**
  String get carePropTuber;

  /// No description provided for @careMatchSpecies.
  ///
  /// In fr, this message translates to:
  /// **'Fiche de l\'espèce'**
  String get careMatchSpecies;

  /// No description provided for @careMatchGenus.
  ///
  /// In fr, this message translates to:
  /// **'Fiche du genre {name}'**
  String careMatchGenus(String name);

  /// No description provided for @careMatchFamily.
  ///
  /// In fr, this message translates to:
  /// **'Fiche de la famille des {name}'**
  String careMatchFamily(String name);

  /// No description provided for @careMatchGeneric.
  ///
  /// In fr, this message translates to:
  /// **'Repères généraux'**
  String get careMatchGeneric;

  /// No description provided for @careMatchNote.
  ///
  /// In fr, this message translates to:
  /// **'Ces repères viennent du groupe botanique, pas de l\'espèce exacte. Précisez l\'espèce pour affiner.'**
  String get careMatchNote;

  /// No description provided for @careDisclaimer.
  ///
  /// In fr, this message translates to:
  /// **'Valeurs indicatives, à adapter à la lumière, au pot et à l\'air ambiant.'**
  String get careDisclaimer;

  /// No description provided for @careApplyToSchedule.
  ///
  /// In fr, this message translates to:
  /// **'Appliquer au planning'**
  String get careApplyToSchedule;

  /// No description provided for @careScheduleApplied.
  ///
  /// In fr, this message translates to:
  /// **'Planning mis à jour'**
  String get careScheduleApplied;

  /// No description provided for @careSuggestedIntervals.
  ///
  /// In fr, this message translates to:
  /// **'Arrosage tous les {water} jours, engrais tous les {fertilize} jours'**
  String careSuggestedIntervals(int water, int fertilize);

  /// No description provided for @careBadgeMist.
  ///
  /// In fr, this message translates to:
  /// **'Brumiser'**
  String get careBadgeMist;

  /// No description provided for @careBadgeDormant.
  ///
  /// In fr, this message translates to:
  /// **'Repos hivernal'**
  String get careBadgeDormant;

  /// No description provided for @careBadgeOutdoor.
  ///
  /// In fr, this message translates to:
  /// **'Supporte l\'extérieur'**
  String get careBadgeOutdoor;

  /// No description provided for @careIssueOverwatering.
  ///
  /// In fr, this message translates to:
  /// **'Excès d\'eau (feuilles molles et jaunes)'**
  String get careIssueOverwatering;

  /// No description provided for @careIssueUnderwatering.
  ///
  /// In fr, this message translates to:
  /// **'Manque d\'eau (feuilles qui retombent)'**
  String get careIssueUnderwatering;

  /// No description provided for @careIssueRootRot.
  ///
  /// In fr, this message translates to:
  /// **'Pourriture des racines'**
  String get careIssueRootRot;

  /// No description provided for @careIssueSpiderMites.
  ///
  /// In fr, this message translates to:
  /// **'Araignées rouges (fines toiles)'**
  String get careIssueSpiderMites;

  /// No description provided for @careIssueThrips.
  ///
  /// In fr, this message translates to:
  /// **'Thrips (feuilles argentées)'**
  String get careIssueThrips;

  /// No description provided for @careIssueMealybugs.
  ///
  /// In fr, this message translates to:
  /// **'Cochenilles farineuses'**
  String get careIssueMealybugs;

  /// No description provided for @careIssueScale.
  ///
  /// In fr, this message translates to:
  /// **'Cochenilles à bouclier'**
  String get careIssueScale;

  /// No description provided for @careIssueAphids.
  ///
  /// In fr, this message translates to:
  /// **'Pucerons'**
  String get careIssueAphids;

  /// No description provided for @careIssueFungusGnats.
  ///
  /// In fr, this message translates to:
  /// **'Moucherons du terreau'**
  String get careIssueFungusGnats;

  /// No description provided for @careIssueWhitefly.
  ///
  /// In fr, this message translates to:
  /// **'Aleurodes (mouches blanches)'**
  String get careIssueWhitefly;

  /// No description provided for @careIssueTrueBugs.
  ///
  /// In fr, this message translates to:
  /// **'Punaises'**
  String get careIssueTrueBugs;

  /// No description provided for @careIssueSlugs.
  ///
  /// In fr, this message translates to:
  /// **'Limaces et escargots'**
  String get careIssueSlugs;

  /// No description provided for @careIssuePowderyMildew.
  ///
  /// In fr, this message translates to:
  /// **'Oïdium (feutrage blanc)'**
  String get careIssuePowderyMildew;

  /// No description provided for @careIssueGreyMould.
  ///
  /// In fr, this message translates to:
  /// **'Pourriture grise (Botrytis)'**
  String get careIssueGreyMould;

  /// No description provided for @careIssueLeafSpot.
  ///
  /// In fr, this message translates to:
  /// **'Taches foliaires'**
  String get careIssueLeafSpot;

  /// No description provided for @careIssueBlight.
  ///
  /// In fr, this message translates to:
  /// **'Mildiou'**
  String get careIssueBlight;

  /// No description provided for @careIssueSunburn.
  ///
  /// In fr, this message translates to:
  /// **'Brûlures du soleil'**
  String get careIssueSunburn;

  /// No description provided for @careIssueDryTips.
  ///
  /// In fr, this message translates to:
  /// **'Pointes sèches et brunes'**
  String get careIssueDryTips;

  /// No description provided for @careIssueLeafDrop.
  ///
  /// In fr, this message translates to:
  /// **'Chute de feuilles'**
  String get careIssueLeafDrop;

  /// No description provided for @careIssueEtiolation.
  ///
  /// In fr, this message translates to:
  /// **'Étiolement par manque de lumière'**
  String get careIssueEtiolation;

  /// No description provided for @careIssueChlorosis.
  ///
  /// In fr, this message translates to:
  /// **'Chlorose (feuilles pâles, nervures vertes)'**
  String get careIssueChlorosis;

  /// No description provided for @careIssueBlossomEndRot.
  ///
  /// In fr, this message translates to:
  /// **'Nécrose apicale des fruits'**
  String get careIssueBlossomEndRot;

  /// No description provided for @careTipFingerTest.
  ///
  /// In fr, this message translates to:
  /// **'Enfoncez un doigt et arrosez quand les 2 premiers centimètres sont secs.'**
  String get careTipFingerTest;

  /// No description provided for @careTipDrySoilFirst.
  ///
  /// In fr, this message translates to:
  /// **'Laissez le terreau sécher complètement entre deux arrosages.'**
  String get careTipDrySoilFirst;

  /// No description provided for @careTipNeverDryOut.
  ///
  /// In fr, this message translates to:
  /// **'Ne laissez jamais le terreau sécher complètement.'**
  String get careTipNeverDryOut;

  /// No description provided for @careTipEvenWatering.
  ///
  /// In fr, this message translates to:
  /// **'Arrosez régulièrement, car les à-coups font éclater les fruits.'**
  String get careTipEvenWatering;

  /// No description provided for @careTipWaterAtBase.
  ///
  /// In fr, this message translates to:
  /// **'Arrosez au pied, sans mouiller le feuillage.'**
  String get careTipWaterAtBase;

  /// No description provided for @careTipNoWaterOnLeaves.
  ///
  /// In fr, this message translates to:
  /// **'Ne mouillez pas les feuilles, car l\'eau stagnante les tache.'**
  String get careTipNoWaterOnLeaves;

  /// No description provided for @careTipBottomWatering.
  ///
  /// In fr, this message translates to:
  /// **'Arrosez par le bas, en posant le pot dans une soucoupe d\'eau 20 minutes.'**
  String get careTipBottomWatering;

  /// No description provided for @careTipThirstyPlant.
  ///
  /// In fr, this message translates to:
  /// **'Gros besoin d\'eau : vérifiez la terre tous les jours en été.'**
  String get careTipThirstyPlant;

  /// No description provided for @careTipDroopSignal.
  ///
  /// In fr, this message translates to:
  /// **'Un feuillage qui s\'affaisse signale le manque d\'eau.'**
  String get careTipDroopSignal;

  /// No description provided for @careTipWinterDry.
  ///
  /// In fr, this message translates to:
  /// **'En hiver, gardez-la presque au sec.'**
  String get careTipWinterDry;

  /// No description provided for @careTipWinterRest.
  ///
  /// In fr, this message translates to:
  /// **'En hiver, la croissance s\'arrête : beaucoup moins d\'eau.'**
  String get careTipWinterRest;

  /// No description provided for @careTipSummerDormant.
  ///
  /// In fr, this message translates to:
  /// **'Repos en été : très peu d\'eau à cette période.'**
  String get careTipSummerDormant;

  /// No description provided for @careTipNoWaterWhileSplitting.
  ///
  /// In fr, this message translates to:
  /// **'N\'arrosez pas pendant le renouvellement des feuilles.'**
  String get careTipNoWaterWhileSplitting;

  /// No description provided for @careTipOrchidSoak.
  ///
  /// In fr, this message translates to:
  /// **'Trempez le pot 10 minutes, puis laissez bien égoutter.'**
  String get careTipOrchidSoak;

  /// No description provided for @careTipSoakMount.
  ///
  /// In fr, this message translates to:
  /// **'Trempez la plante entière, puis laissez-la sécher à l\'air.'**
  String get careTipSoakMount;

  /// No description provided for @careTipDryUpsideDown.
  ///
  /// In fr, this message translates to:
  /// **'Après le bain, laissez-la sécher tête en bas, car l\'eau au cœur la fait pourrir.'**
  String get careTipDryUpsideDown;

  /// No description provided for @careTipWaterInTheCup.
  ///
  /// In fr, this message translates to:
  /// **'Remplissez la rosette centrale et renouvelez l\'eau chaque semaine.'**
  String get careTipWaterInTheCup;

  /// No description provided for @careTipNoSoil.
  ///
  /// In fr, this message translates to:
  /// **'Elle vit sans terre, posée simplement sur un support.'**
  String get careTipNoSoil;

  /// No description provided for @careTipGreenRoots.
  ///
  /// In fr, this message translates to:
  /// **'Racines vertes = bien hydratée. Argentées = il est temps d\'arroser.'**
  String get careTipGreenRoots;

  /// No description provided for @careTipHumidityTray.
  ///
  /// In fr, this message translates to:
  /// **'Posez le pot sur un lit de billes d\'argile humides.'**
  String get careTipHumidityTray;

  /// No description provided for @careTipNoDirectSun.
  ///
  /// In fr, this message translates to:
  /// **'Évitez le soleil direct, qui brûle le feuillage.'**
  String get careTipNoDirectSun;

  /// No description provided for @careTipToleratesLowLight.
  ///
  /// In fr, this message translates to:
  /// **'Elle supporte une pièce peu lumineuse, mais pousse plus vite près d\'une fenêtre.'**
  String get careTipToleratesLowLight;

  /// No description provided for @careTipToleratesNeglect.
  ///
  /// In fr, this message translates to:
  /// **'Les oublis ne l\'abîment pas : en cas de doute, n\'arrosez pas.'**
  String get careTipToleratesNeglect;

  /// No description provided for @careTipBrightForColor.
  ///
  /// In fr, this message translates to:
  /// **'Plus la lumière est vive, plus les couleurs sont marquées.'**
  String get careTipBrightForColor;

  /// No description provided for @careTipRotatePot.
  ///
  /// In fr, this message translates to:
  /// **'Un quart de tour au pot chaque semaine garde la tige droite.'**
  String get careTipRotatePot;

  /// No description provided for @careTipHatesMoving.
  ///
  /// In fr, this message translates to:
  /// **'Gardez une place fixe : chaque déplacement fait tomber des feuilles.'**
  String get careTipHatesMoving;

  /// No description provided for @careTipWipeLeaves.
  ///
  /// In fr, this message translates to:
  /// **'Dépoussiérez les feuilles : la poussière bloque la lumière.'**
  String get careTipWipeLeaves;

  /// No description provided for @careTipTrimToBushOut.
  ///
  /// In fr, this message translates to:
  /// **'Tailler les tiges trop longues fait ramifier.'**
  String get careTipTrimToBushOut;

  /// No description provided for @careTipMonsteraSupport.
  ///
  /// In fr, this message translates to:
  /// **'Sur un tuteur moussu, les feuilles deviennent plus grandes et découpées.'**
  String get careTipMonsteraSupport;

  /// No description provided for @careTipShallowPot.
  ///
  /// In fr, this message translates to:
  /// **'Un pot large et peu profond.'**
  String get careTipShallowPot;

  /// No description provided for @careTipLikesBeingPotbound.
  ///
  /// In fr, this message translates to:
  /// **'La floraison est meilleure à l\'étroit : rempotez rarement.'**
  String get careTipLikesBeingPotbound;

  /// No description provided for @careTipTrunkStoresWater.
  ///
  /// In fr, this message translates to:
  /// **'Son pied renflé stocke l\'eau, mieux vaut donc trop peu que trop.'**
  String get careTipTrunkStoresWater;

  /// No description provided for @careTipPupsToShare.
  ///
  /// In fr, this message translates to:
  /// **'Les rejets se détachent pour multiplier ou offrir.'**
  String get careTipPupsToShare;

  /// No description provided for @careTipKeepFlowerSpike.
  ///
  /// In fr, this message translates to:
  /// **'Ne coupez pas la hampe verte, car elle peut refleurir dessus.'**
  String get careTipKeepFlowerSpike;

  /// No description provided for @careTipDarkForRebloom.
  ///
  /// In fr, this message translates to:
  /// **'Pour refleurir : six semaines de nuits longues et fraîches.'**
  String get careTipDarkForRebloom;

  /// No description provided for @careTipNotADesertCactus.
  ///
  /// In fr, this message translates to:
  /// **'Cactus de forêt, pas du désert : ombre et air humide.'**
  String get careTipNotADesertCactus;

  /// No description provided for @careTipDeadheadFlowers.
  ///
  /// In fr, this message translates to:
  /// **'Retirer les fleurs fanées prolonge la floraison.'**
  String get careTipDeadheadFlowers;

  /// No description provided for @careTipPinchFlowers.
  ///
  /// In fr, this message translates to:
  /// **'Pincez les fleurs dès qu\'elles montent pour garder des feuilles tendres.'**
  String get careTipPinchFlowers;

  /// No description provided for @careTipHarvestTop.
  ///
  /// In fr, this message translates to:
  /// **'Récoltez par le haut, au-dessus d\'une paire de feuilles.'**
  String get careTipHarvestTop;

  /// No description provided for @careTipHarvestOutside.
  ///
  /// In fr, this message translates to:
  /// **'Cueillez les feuilles extérieures et le cœur continuera de pousser.'**
  String get careTipHarvestOutside;

  /// No description provided for @careTipStakeAndPrune.
  ///
  /// In fr, this message translates to:
  /// **'Tuteurez et supprimez les gourmands entre tige et branche.'**
  String get careTipStakeAndPrune;

  /// No description provided for @careTipPrunesInSpring.
  ///
  /// In fr, this message translates to:
  /// **'Taillez au printemps, jamais dans le vieux bois sec.'**
  String get careTipPrunesInSpring;

  /// No description provided for @careTipPrunesAfterFlowering.
  ///
  /// In fr, this message translates to:
  /// **'Taillez juste après la floraison pour garder une touffe compacte.'**
  String get careTipPrunesAfterFlowering;

  /// No description provided for @careTipWinterPruning.
  ///
  /// In fr, this message translates to:
  /// **'Taillez en hiver, hors gel, quand la plante dort.'**
  String get careTipWinterPruning;

  /// No description provided for @careTipPruneAfterHarvest.
  ///
  /// In fr, this message translates to:
  /// **'Taillez après la récolte, pas au printemps.'**
  String get careTipPruneAfterHarvest;

  /// No description provided for @careTipCutSpentCanes.
  ///
  /// In fr, this message translates to:
  /// **'Coupez à ras les tiges qui ont fructifié.'**
  String get careTipCutSpentCanes;

  /// No description provided for @careTipTrimTwiceAYear.
  ///
  /// In fr, this message translates to:
  /// **'Deux tailles par an suffisent, en juin et fin août.'**
  String get careTipTrimTwiceAYear;

  /// No description provided for @careTipContainItsRoots.
  ///
  /// In fr, this message translates to:
  /// **'Les rhizomes envahissent tout : en pot, ou derrière une barrière anti-rhizome.'**
  String get careTipContainItsRoots;

  /// No description provided for @careTipMulchIt.
  ///
  /// In fr, this message translates to:
  /// **'Paillez le pied pour arroser moins et limiter les mauvaises herbes.'**
  String get careTipMulchIt;

  /// No description provided for @careTipAcidSoil.
  ///
  /// In fr, this message translates to:
  /// **'Terre acide, pas de terreau universel.'**
  String get careTipAcidSoil;

  /// No description provided for @careTipFeedsOnInsects.
  ///
  /// In fr, this message translates to:
  /// **'Elle se nourrit d\'insectes : pas d\'engrais, et une terre pauvre.'**
  String get careTipFeedsOnInsects;

  /// No description provided for @careTipBlueNeedsAcid.
  ///
  /// In fr, this message translates to:
  /// **'Les fleurs bleues demandent un sol acide ; en sol calcaire elles virent au rose.'**
  String get careTipBlueNeedsAcid;

  /// No description provided for @careTipCitrusFertilizer.
  ///
  /// In fr, this message translates to:
  /// **'Utilisez un engrais spécial agrumes pendant toute la belle saison.'**
  String get careTipCitrusFertilizer;

  /// No description provided for @careTipNoFertilizer.
  ///
  /// In fr, this message translates to:
  /// **'Pas d\'engrais : une terre riche affaiblit le parfum et la tenue.'**
  String get careTipNoFertilizer;

  /// No description provided for @careTipNoNitrogen.
  ///
  /// In fr, this message translates to:
  /// **'Pas d\'engrais azoté : la plante fixe elle-même l\'azote.'**
  String get careTipNoNitrogen;

  /// No description provided for @careTipLetFoliageDieBack.
  ///
  /// In fr, this message translates to:
  /// **'Laissez le feuillage jaunir sur pied, car il recharge le bulbe.'**
  String get careTipLetFoliageDieBack;

  /// No description provided for @careTipDiesBackInWinter.
  ///
  /// In fr, this message translates to:
  /// **'Le feuillage disparaît en hiver et repart au printemps.'**
  String get careTipDiesBackInWinter;

  /// No description provided for @careTipSummerOutdoors.
  ///
  /// In fr, this message translates to:
  /// **'Sortez-la l\'été, à l\'ombre les premiers jours.'**
  String get careTipSummerOutdoors;

  /// No description provided for @careTipWinterIndoors.
  ///
  /// In fr, this message translates to:
  /// **'Rentrez-la avant les premières gelées.'**
  String get careTipWinterIndoors;

  /// No description provided for @careTipWinterShelter.
  ///
  /// In fr, this message translates to:
  /// **'Abritez-la l\'hiver dans une pièce fraîche et lumineuse.'**
  String get careTipWinterShelter;

  /// No description provided for @careTipWinterCool.
  ///
  /// In fr, this message translates to:
  /// **'Hiver frais (10–14 °C) et lumineux.'**
  String get careTipWinterCool;

  /// No description provided for @careTipCoolerIsBetter.
  ///
  /// In fr, this message translates to:
  /// **'Mieux au frais : éloignez-la des radiateurs.'**
  String get careTipCoolerIsBetter;

  /// No description provided for @careTipHardyOutdoors.
  ///
  /// In fr, this message translates to:
  /// **'Rustique, elle passe l\'hiver dehors sans protection.'**
  String get careTipHardyOutdoors;

  /// No description provided for @careTipShelterFromWind.
  ///
  /// In fr, this message translates to:
  /// **'Placez-la à l\'abri du vent, car le feuillage s\'abîme vite.'**
  String get careTipShelterFromWind;

  /// No description provided for @careTipAirFlow.
  ///
  /// In fr, this message translates to:
  /// **'De l\'air autour de la plante : l\'air confiné favorise les maladies.'**
  String get careTipAirFlow;

  /// No description provided for @careTipSpiderMiteWatch.
  ///
  /// In fr, this message translates to:
  /// **'Inspectez le dessous des feuilles, où s\'installent les araignées rouges.'**
  String get careTipSpiderMiteWatch;

  /// No description provided for @careTipSlugWatch.
  ///
  /// In fr, this message translates to:
  /// **'Protégez les jeunes pousses des limaces au printemps.'**
  String get careTipSlugWatch;

  /// No description provided for @careTipBoxMothWatch.
  ///
  /// In fr, this message translates to:
  /// **'Surveillez la pyrale, ses chenilles laissent des fils de soie dans le feuillage.'**
  String get careTipBoxMothWatch;

  /// No description provided for @careTipSapIrritant.
  ///
  /// In fr, this message translates to:
  /// **'Sa sève irrite la peau et les yeux, taillez-la avec des gants.'**
  String get careTipSapIrritant;

  /// No description provided for @careTipVeryToxic.
  ///
  /// In fr, this message translates to:
  /// **'Toutes ses parties sont très toxiques, y compris la fumée si on la brûle.'**
  String get careTipVeryToxic;

  /// No description provided for @careTipSharpSpines.
  ///
  /// In fr, this message translates to:
  /// **'Pointes acérées : loin des passages.'**
  String get careTipSharpSpines;

  /// No description provided for @careTipSplitsAreNormal.
  ///
  /// In fr, this message translates to:
  /// **'Les feuilles se fendent avec l\'âge, c\'est normal et non une maladie.'**
  String get careTipSplitsAreNormal;

  /// No description provided for @careTipDryToBloom.
  ///
  /// In fr, this message translates to:
  /// **'Un léger stress hydrique déclenche la floraison.'**
  String get careTipDryToBloom;

  /// No description provided for @customFields.
  ///
  /// In fr, this message translates to:
  /// **'Champs personnalisés'**
  String get customFields;

  /// No description provided for @addCustomField.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un champ'**
  String get addCustomField;

  /// No description provided for @editCustomField.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le champ'**
  String get editCustomField;

  /// No description provided for @deleteCustomField.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le champ'**
  String get deleteCustomField;

  /// No description provided for @fieldLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nom du champ'**
  String get fieldLabel;

  /// No description provided for @fieldLabelHint.
  ///
  /// In fr, this message translates to:
  /// **'Provenance, prix, exposition…'**
  String get fieldLabelHint;

  /// No description provided for @fieldType.
  ///
  /// In fr, this message translates to:
  /// **'Type'**
  String get fieldType;

  /// No description provided for @fieldValue.
  ///
  /// In fr, this message translates to:
  /// **'Valeur'**
  String get fieldValue;

  /// No description provided for @fieldTypeBool.
  ///
  /// In fr, this message translates to:
  /// **'Oui / non'**
  String get fieldTypeBool;

  /// No description provided for @fieldTypeInt.
  ///
  /// In fr, this message translates to:
  /// **'Nombre entier'**
  String get fieldTypeInt;

  /// No description provided for @fieldTypeDouble.
  ///
  /// In fr, this message translates to:
  /// **'Nombre décimal'**
  String get fieldTypeDouble;

  /// No description provided for @fieldTypeText.
  ///
  /// In fr, this message translates to:
  /// **'Texte'**
  String get fieldTypeText;

  /// No description provided for @fieldTypeDate.
  ///
  /// In fr, this message translates to:
  /// **'Date'**
  String get fieldTypeDate;

  /// No description provided for @fieldEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Non renseigné'**
  String get fieldEmpty;

  /// No description provided for @noCustomFields.
  ///
  /// In fr, this message translates to:
  /// **'Aucun champ personnalisé'**
  String get noCustomFields;

  /// No description provided for @fieldTemplates.
  ///
  /// In fr, this message translates to:
  /// **'Modèles de champs'**
  String get fieldTemplates;

  /// No description provided for @fieldTemplatesHint.
  ///
  /// In fr, this message translates to:
  /// **'Champs réutilisables sur plusieurs plantes.'**
  String get fieldTemplatesHint;

  /// No description provided for @newFieldTemplate.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau modèle'**
  String get newFieldTemplate;

  /// No description provided for @noFieldTemplates.
  ///
  /// In fr, this message translates to:
  /// **'Aucun modèle'**
  String get noFieldTemplates;

  /// No description provided for @fieldTemplateInactive.
  ///
  /// In fr, this message translates to:
  /// **'Masqué'**
  String get fieldTemplateInactive;

  /// No description provided for @fieldFromTemplate.
  ///
  /// In fr, this message translates to:
  /// **'Depuis un modèle'**
  String get fieldFromTemplate;

  /// No description provided for @bulkSetField.
  ///
  /// In fr, this message translates to:
  /// **'Renseigner un champ'**
  String get bulkSetField;

  /// No description provided for @bulkFieldApplied.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Champ appliqué à 1 plante} other{Champ appliqué à {count} plantes}}'**
  String bulkFieldApplied(int count);

  /// No description provided for @confirmDeleteField.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce champ et sa valeur ?'**
  String get confirmDeleteField;

  /// No description provided for @confirmDeleteTemplate.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce modèle ? Les champs déjà renseignés sont conservés.'**
  String get confirmDeleteTemplate;

  /// No description provided for @yes.
  ///
  /// In fr, this message translates to:
  /// **'Oui'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In fr, this message translates to:
  /// **'Non'**
  String get no;

  /// No description provided for @attachments.
  ///
  /// In fr, this message translates to:
  /// **'Documents'**
  String get attachments;

  /// No description provided for @addAttachment.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un document'**
  String get addAttachment;

  /// No description provided for @noAttachments.
  ///
  /// In fr, this message translates to:
  /// **'Aucun document'**
  String get noAttachments;

  /// No description provided for @noAttachmentsHint.
  ///
  /// In fr, this message translates to:
  /// **'Facture, fiche du producteur, analyse de sol…'**
  String get noAttachmentsHint;

  /// No description provided for @attachmentLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nom du document'**
  String get attachmentLabel;

  /// No description provided for @renameAttachment.
  ///
  /// In fr, this message translates to:
  /// **'Renommer'**
  String get renameAttachment;

  /// No description provided for @deleteAttachment.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le document'**
  String get deleteAttachment;

  /// No description provided for @confirmDeleteAttachment.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce document ? Le fichier sera effacé de l\'appareil.'**
  String get confirmDeleteAttachment;

  /// No description provided for @openAttachment.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir'**
  String get openAttachment;

  /// No description provided for @attachmentOpenFailed.
  ///
  /// In fr, this message translates to:
  /// **'Aucune application ne peut ouvrir ce fichier.'**
  String get attachmentOpenFailed;

  /// No description provided for @photoLabel.
  ///
  /// In fr, this message translates to:
  /// **'Titre de la photo'**
  String get photoLabel;

  /// No description provided for @photoLabelHint.
  ///
  /// In fr, this message translates to:
  /// **'Avant rempotage, nouvelle feuille…'**
  String get photoLabelHint;

  /// No description provided for @setAsMainPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Photo principale'**
  String get setAsMainPhoto;

  /// No description provided for @mainPhotoSet.
  ///
  /// In fr, this message translates to:
  /// **'Photo principale mise à jour'**
  String get mainPhotoSet;

  /// No description provided for @addPhotoByUrl.
  ///
  /// In fr, this message translates to:
  /// **'Depuis une adresse web'**
  String get addPhotoByUrl;

  /// No description provided for @photoUrlHint.
  ///
  /// In fr, this message translates to:
  /// **'https://…'**
  String get photoUrlHint;

  /// No description provided for @photoUrlInvalid.
  ///
  /// In fr, this message translates to:
  /// **'L\'adresse doit commencer par https://'**
  String get photoUrlInvalid;

  /// No description provided for @photoRemote.
  ///
  /// In fr, this message translates to:
  /// **'Photo distante'**
  String get photoRemote;

  /// No description provided for @confirmDeletePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer cette photo ?'**
  String get confirmDeletePhoto;

  /// No description provided for @shareByLink.
  ///
  /// In fr, this message translates to:
  /// **'Partager par lien'**
  String get shareByLink;

  /// No description provided for @sharedLinks.
  ///
  /// In fr, this message translates to:
  /// **'Liens partagés'**
  String get sharedLinks;

  /// No description provided for @sharedLinksHint.
  ///
  /// In fr, this message translates to:
  /// **'Une page web publique, révocable à tout moment.'**
  String get sharedLinksHint;

  /// No description provided for @noSharedLinks.
  ///
  /// In fr, this message translates to:
  /// **'Aucun lien partagé'**
  String get noSharedLinks;

  /// No description provided for @shareTitle.
  ///
  /// In fr, this message translates to:
  /// **'Titre de la page'**
  String get shareTitle;

  /// No description provided for @shareDescription.
  ///
  /// In fr, this message translates to:
  /// **'Description (facultatif)'**
  String get shareDescription;

  /// No description provided for @shareKeywords.
  ///
  /// In fr, this message translates to:
  /// **'Mots-clés (facultatif)'**
  String get shareKeywords;

  /// No description provided for @shareUnlisted.
  ///
  /// In fr, this message translates to:
  /// **'Non référencé'**
  String get shareUnlisted;

  /// No description provided for @shareUnlistedHint.
  ///
  /// In fr, this message translates to:
  /// **'La page demande aux moteurs de recherche de ne pas l\'indexer. Toute personne ayant le lien peut la voir.'**
  String get shareUnlistedHint;

  /// No description provided for @shareExpiry.
  ///
  /// In fr, this message translates to:
  /// **'Expire le'**
  String get shareExpiry;

  /// No description provided for @shareNoExpiry.
  ///
  /// In fr, this message translates to:
  /// **'Sans expiration'**
  String get shareNoExpiry;

  /// No description provided for @shareCreate.
  ///
  /// In fr, this message translates to:
  /// **'Créer le lien'**
  String get shareCreate;

  /// No description provided for @shareCopy.
  ///
  /// In fr, this message translates to:
  /// **'Copier le lien'**
  String get shareCopy;

  /// No description provided for @shareCopied.
  ///
  /// In fr, this message translates to:
  /// **'Lien copié'**
  String get shareCopied;

  /// No description provided for @shareRevoke.
  ///
  /// In fr, this message translates to:
  /// **'Révoquer'**
  String get shareRevoke;

  /// No description provided for @shareRevoked.
  ///
  /// In fr, this message translates to:
  /// **'Révoqué'**
  String get shareRevoked;

  /// No description provided for @shareExpired.
  ///
  /// In fr, this message translates to:
  /// **'Expiré'**
  String get shareExpired;

  /// No description provided for @shareActive.
  ///
  /// In fr, this message translates to:
  /// **'Actif'**
  String get shareActive;

  /// No description provided for @confirmRevokeLink.
  ///
  /// In fr, this message translates to:
  /// **'Révoquer ce lien ? La page ne sera plus accessible.'**
  String get confirmRevokeLink;

  /// No description provided for @shareNeedsAccount.
  ///
  /// In fr, this message translates to:
  /// **'Le partage par lien nécessite un compte.'**
  String get shareNeedsAccount;

  /// No description provided for @shareFailed.
  ///
  /// In fr, this message translates to:
  /// **'Le lien n\'a pas pu être créé. Réessayez.'**
  String get shareFailed;

  /// No description provided for @sharePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Partager cette photo'**
  String get sharePhoto;

  /// No description provided for @sharePlant.
  ///
  /// In fr, this message translates to:
  /// **'Partager cette plante'**
  String get sharePlant;

  /// No description provided for @notesMarkdownHint.
  ///
  /// In fr, this message translates to:
  /// **'Mise en forme : **gras**, *italique*, - listes, [liens](https://…)'**
  String get notesMarkdownHint;

  /// No description provided for @preview.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu'**
  String get preview;

  /// No description provided for @locationNotes.
  ///
  /// In fr, this message translates to:
  /// **'Notes de l\'emplacement'**
  String get locationNotes;

  /// No description provided for @locationLog.
  ///
  /// In fr, this message translates to:
  /// **'Journal'**
  String get locationLog;

  /// No description provided for @addLogEntry.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une entrée'**
  String get addLogEntry;

  /// No description provided for @editLogEntry.
  ///
  /// In fr, this message translates to:
  /// **'Modifier l\'entrée'**
  String get editLogEntry;

  /// No description provided for @logEntryHint.
  ///
  /// In fr, this message translates to:
  /// **'Store changé, serre nettoyée…'**
  String get logEntryHint;

  /// No description provided for @noLogEntries.
  ///
  /// In fr, this message translates to:
  /// **'Journal vide'**
  String get noLogEntries;

  /// No description provided for @confirmDeleteLogEntry.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer cette entrée ?'**
  String get confirmDeleteLogEntry;

  /// No description provided for @locationPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Photo de l\'emplacement'**
  String get locationPhoto;

  /// No description provided for @removeLocationPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Retirer la photo'**
  String get removeLocationPhoto;

  /// No description provided for @careAllPlants.
  ///
  /// In fr, this message translates to:
  /// **'Soigner toutes les plantes'**
  String get careAllPlants;

  /// No description provided for @waterAllHere.
  ///
  /// In fr, this message translates to:
  /// **'Arroser tout ici'**
  String get waterAllHere;

  /// No description provided for @fertilizeAllHere.
  ///
  /// In fr, this message translates to:
  /// **'Fertiliser tout ici'**
  String get fertilizeAllHere;

  /// No description provided for @repotAllHere.
  ///
  /// In fr, this message translates to:
  /// **'Rempoter tout ici'**
  String get repotAllHere;

  /// No description provided for @searchByNumberHint.
  ///
  /// In fr, this message translates to:
  /// **'Tapez #42 pour retrouver la plante n° 42.'**
  String get searchByNumberHint;

  /// No description provided for @inventoryGroups.
  ///
  /// In fr, this message translates to:
  /// **'Groupes'**
  String get inventoryGroups;

  /// No description provided for @manageGroups.
  ///
  /// In fr, this message translates to:
  /// **'Gérer les groupes'**
  String get manageGroups;

  /// No description provided for @newGroup.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau groupe'**
  String get newGroup;

  /// No description provided for @editGroup.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le groupe'**
  String get editGroup;

  /// No description provided for @groupName.
  ///
  /// In fr, this message translates to:
  /// **'Nom du groupe'**
  String get groupName;

  /// No description provided for @groupNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Engrais, outils, poteries…'**
  String get groupNameHint;

  /// No description provided for @deleteGroup.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le groupe'**
  String get deleteGroup;

  /// No description provided for @deleteGroupHint.
  ///
  /// In fr, this message translates to:
  /// **'Les articles ne sont pas supprimés, ils rejoignent le groupe choisi.'**
  String get deleteGroupHint;

  /// No description provided for @moveItemsTo.
  ///
  /// In fr, this message translates to:
  /// **'Déplacer les articles vers'**
  String get moveItemsTo;

  /// No description provided for @noGroup.
  ///
  /// In fr, this message translates to:
  /// **'Sans groupe'**
  String get noGroup;

  /// No description provided for @noGroups.
  ///
  /// In fr, this message translates to:
  /// **'Aucun groupe personnalisé'**
  String get noGroups;

  /// No description provided for @itemGroup.
  ///
  /// In fr, this message translates to:
  /// **'Groupe'**
  String get itemGroup;

  /// No description provided for @itemTags.
  ///
  /// In fr, this message translates to:
  /// **'Tags'**
  String get itemTags;

  /// No description provided for @itemQr.
  ///
  /// In fr, this message translates to:
  /// **'QR de l\'article'**
  String get itemQr;

  /// No description provided for @exportSelection.
  ///
  /// In fr, this message translates to:
  /// **'Exporter la sélection'**
  String get exportSelection;

  /// No description provided for @exportCsv.
  ///
  /// In fr, this message translates to:
  /// **'Exporter en CSV'**
  String get exportCsv;

  /// No description provided for @selectItems.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner'**
  String get selectItems;

  /// No description provided for @itemsSelected.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 article} other{{count} articles}}'**
  String itemsSelected(int count);

  /// No description provided for @filterByTag.
  ///
  /// In fr, this message translates to:
  /// **'Filtrer par tag'**
  String get filterByTag;

  /// No description provided for @itemNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Article introuvable'**
  String get itemNotFound;

  /// No description provided for @noGroupsYet.
  ///
  /// In fr, this message translates to:
  /// **'Aucun groupe.'**
  String get noGroupsYet;

  /// No description provided for @deleteGroupExplain.
  ///
  /// In fr, this message translates to:
  /// **'Les articles ne sont pas supprimés, ils perdent leur groupe.'**
  String get deleteGroupExplain;

  /// No description provided for @newEvent.
  ///
  /// In fr, this message translates to:
  /// **'Nouvel événement'**
  String get newEvent;

  /// No description provided for @editEvent.
  ///
  /// In fr, this message translates to:
  /// **'Modifier l\'événement'**
  String get editEvent;

  /// No description provided for @deleteEvent.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer l\'événement'**
  String get deleteEvent;

  /// No description provided for @eventTitleHint.
  ///
  /// In fr, this message translates to:
  /// **'Marché aux plantes'**
  String get eventTitleHint;

  /// No description provided for @eventNotesHint.
  ///
  /// In fr, this message translates to:
  /// **'Notes (facultatif)'**
  String get eventNotesHint;

  /// No description provided for @eventStart.
  ///
  /// In fr, this message translates to:
  /// **'Début'**
  String get eventStart;

  /// No description provided for @eventEnd.
  ///
  /// In fr, this message translates to:
  /// **'Fin'**
  String get eventEnd;

  /// No description provided for @eventNoEnd.
  ///
  /// In fr, this message translates to:
  /// **'Même jour'**
  String get eventNoEnd;

  /// No description provided for @eventAllDay.
  ///
  /// In fr, this message translates to:
  /// **'Journée entière'**
  String get eventAllDay;

  /// No description provided for @eventCategory.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get eventCategory;

  /// No description provided for @eventNoCategory.
  ///
  /// In fr, this message translates to:
  /// **'Aucune'**
  String get eventNoCategory;

  /// No description provided for @eventReminder.
  ///
  /// In fr, this message translates to:
  /// **'Rappel'**
  String get eventReminder;

  /// No description provided for @eventNoReminder.
  ///
  /// In fr, this message translates to:
  /// **'Aucun'**
  String get eventNoReminder;

  /// No description provided for @eventReminderAtStart.
  ///
  /// In fr, this message translates to:
  /// **'À l\'heure'**
  String get eventReminderAtStart;

  /// No description provided for @eventReminderMinutes.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{1 minute avant} other{{count} minutes avant}}'**
  String eventReminderMinutes(int count);

  /// No description provided for @eventReminderHours.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{1 heure avant} other{{count} heures avant}}'**
  String eventReminderHours(int count);

  /// No description provided for @eventReminderDays.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{1 jour avant} other{{count} jours avant}}'**
  String eventReminderDays(int count);

  /// No description provided for @manageEventCategories.
  ///
  /// In fr, this message translates to:
  /// **'Catégories d\'événements'**
  String get manageEventCategories;

  /// No description provided for @newEventCategory.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle catégorie'**
  String get newEventCategory;

  /// No description provided for @editEventCategory.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la catégorie'**
  String get editEventCategory;

  /// No description provided for @deleteEventCategory.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la catégorie'**
  String get deleteEventCategory;

  /// No description provided for @deleteEventCategoryExplain.
  ///
  /// In fr, this message translates to:
  /// **'Les événements ne sont pas supprimés, ils perdent leur catégorie.'**
  String get deleteEventCategoryExplain;

  /// No description provided for @noEventCategoriesYet.
  ///
  /// In fr, this message translates to:
  /// **'Aucune catégorie.'**
  String get noEventCategoriesYet;

  /// No description provided for @categoryNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Nom de la catégorie'**
  String get categoryNameHint;

  /// No description provided for @eventPlant.
  ///
  /// In fr, this message translates to:
  /// **'Plante liée'**
  String get eventPlant;

  /// No description provided for @eventNoPlant.
  ///
  /// In fr, this message translates to:
  /// **'Aucune'**
  String get eventNoPlant;

  /// No description provided for @eventsOfDay.
  ///
  /// In fr, this message translates to:
  /// **'Événements'**
  String get eventsOfDay;

  /// No description provided for @dashboardTitle.
  ///
  /// In fr, this message translates to:
  /// **'Tableau de bord'**
  String get dashboardTitle;

  /// No description provided for @statsSection.
  ///
  /// In fr, this message translates to:
  /// **'Chiffres'**
  String get statsSection;

  /// No description provided for @statPlants.
  ///
  /// In fr, this message translates to:
  /// **'Plantes'**
  String get statPlants;

  /// No description provided for @statSpecies.
  ///
  /// In fr, this message translates to:
  /// **'Espèces'**
  String get statSpecies;

  /// No description provided for @statLocations.
  ///
  /// In fr, this message translates to:
  /// **'Emplacements'**
  String get statLocations;

  /// No description provided for @statFavorites.
  ///
  /// In fr, this message translates to:
  /// **'Favorites'**
  String get statFavorites;

  /// No description provided for @statArchived.
  ///
  /// In fr, this message translates to:
  /// **'Archivées'**
  String get statArchived;

  /// No description provided for @statNeedingCare.
  ///
  /// In fr, this message translates to:
  /// **'À soigner'**
  String get statNeedingCare;

  /// No description provided for @statOpenTasks.
  ///
  /// In fr, this message translates to:
  /// **'Tâches ouvertes'**
  String get statOpenTasks;

  /// No description provided for @statLowStock.
  ///
  /// In fr, this message translates to:
  /// **'Stock bas'**
  String get statLowStock;

  /// No description provided for @statActionsThisMonth.
  ///
  /// In fr, this message translates to:
  /// **'Soins ce mois'**
  String get statActionsThisMonth;

  /// No description provided for @statWateringsThisMonth.
  ///
  /// In fr, this message translates to:
  /// **'Arrosages ce mois'**
  String get statWateringsThisMonth;

  /// No description provided for @statOldest.
  ///
  /// In fr, this message translates to:
  /// **'Plus ancienne'**
  String get statOldest;

  /// No description provided for @warningsSection.
  ///
  /// In fr, this message translates to:
  /// **'À surveiller'**
  String get warningsSection;

  /// No description provided for @warningSick.
  ///
  /// In fr, this message translates to:
  /// **'Malade'**
  String get warningSick;

  /// No description provided for @warningWatch.
  ///
  /// In fr, this message translates to:
  /// **'À surveiller'**
  String get warningWatch;

  /// No description provided for @warningOverdue.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{1 jour de retard} other{{count} jours de retard}}'**
  String warningOverdue(int count);

  /// No description provided for @noWarnings.
  ///
  /// In fr, this message translates to:
  /// **'Rien à signaler.'**
  String get noWarnings;

  /// No description provided for @recentPlantsSection.
  ///
  /// In fr, this message translates to:
  /// **'Dernières plantes'**
  String get recentPlantsSection;

  /// No description provided for @recentAdded.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutées'**
  String get recentAdded;

  /// No description provided for @recentUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Modifiées'**
  String get recentUpdated;

  /// No description provided for @activityLogTitle.
  ///
  /// In fr, this message translates to:
  /// **'Journal d\'activité'**
  String get activityLogTitle;

  /// No description provided for @activityEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune activité.'**
  String get activityEmpty;

  /// No description provided for @activityPlantAdded.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutée au jardin'**
  String get activityPlantAdded;

  /// No description provided for @activityPlantArchived.
  ///
  /// In fr, this message translates to:
  /// **'Archivée'**
  String get activityPlantArchived;

  /// No description provided for @activityLocationNote.
  ///
  /// In fr, this message translates to:
  /// **'Note d\'emplacement'**
  String get activityLocationNote;

  /// No description provided for @activityTaskDone.
  ///
  /// In fr, this message translates to:
  /// **'Tâche terminée'**
  String get activityTaskDone;

  /// No description provided for @searchArchives.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher dans les archives'**
  String get searchArchives;

  /// No description provided for @archiveSortArchivedDesc.
  ///
  /// In fr, this message translates to:
  /// **'Archivées récemment'**
  String get archiveSortArchivedDesc;

  /// No description provided for @archiveSortArchivedAsc.
  ///
  /// In fr, this message translates to:
  /// **'Archivées d\'abord'**
  String get archiveSortArchivedAsc;

  /// No description provided for @archiveSortName.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get archiveSortName;

  /// No description provided for @archiveSortLongestKept.
  ///
  /// In fr, this message translates to:
  /// **'Gardées le plus longtemps'**
  String get archiveSortLongestKept;

  /// No description provided for @allYears.
  ///
  /// In fr, this message translates to:
  /// **'Toutes'**
  String get allYears;

  /// No description provided for @keptForDays.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{Gardée 1 jour} other{Gardée {count} jours}}'**
  String keptForDays(int count);

  /// No description provided for @keptForYears.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{Gardée 1 an} other{Gardée {count} ans}}'**
  String keptForYears(int count);

  /// No description provided for @noArchiveMatch.
  ///
  /// In fr, this message translates to:
  /// **'Aucune plante ne correspond.'**
  String get noArchiveMatch;

  /// No description provided for @weatherForecastTitle.
  ///
  /// In fr, this message translates to:
  /// **'Prévisions'**
  String get weatherForecastTitle;

  /// No description provided for @weatherPrecipitation.
  ///
  /// In fr, this message translates to:
  /// **'Précipitations'**
  String get weatherPrecipitation;

  /// No description provided for @weatherRainChance.
  ///
  /// In fr, this message translates to:
  /// **'Risque de pluie'**
  String get weatherRainChance;

  /// No description provided for @weatherWind.
  ///
  /// In fr, this message translates to:
  /// **'Vent'**
  String get weatherWind;

  /// No description provided for @weatherHumidity.
  ///
  /// In fr, this message translates to:
  /// **'Humidité'**
  String get weatherHumidity;

  /// No description provided for @weatherNoPlace.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez un lieu pour voir les prévisions.'**
  String get weatherNoPlace;

  /// No description provided for @weatherToday.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get weatherToday;

  /// No description provided for @weatherFailed.
  ///
  /// In fr, this message translates to:
  /// **'Prévisions indisponibles pour l\'instant.'**
  String get weatherFailed;

  /// No description provided for @backupTitle.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde'**
  String get backupTitle;

  /// No description provided for @backupExplain.
  ///
  /// In fr, this message translates to:
  /// **'Un fichier .zip contenant vos données et vos photos.'**
  String get backupExplain;

  /// No description provided for @backupWhatToExport.
  ///
  /// In fr, this message translates to:
  /// **'Que sauvegarder'**
  String get backupWhatToExport;

  /// No description provided for @backupWhatToImport.
  ///
  /// In fr, this message translates to:
  /// **'Que restaurer'**
  String get backupWhatToImport;

  /// No description provided for @sectionGarden.
  ///
  /// In fr, this message translates to:
  /// **'Jardin et emplacements'**
  String get sectionGarden;

  /// No description provided for @sectionPlants.
  ///
  /// In fr, this message translates to:
  /// **'Plantes'**
  String get sectionPlants;

  /// No description provided for @sectionPhotos.
  ///
  /// In fr, this message translates to:
  /// **'Photos'**
  String get sectionPhotos;

  /// No description provided for @sectionCare.
  ///
  /// In fr, this message translates to:
  /// **'Soins et routines'**
  String get sectionCare;

  /// No description provided for @sectionInventory.
  ///
  /// In fr, this message translates to:
  /// **'Inventaire'**
  String get sectionInventory;

  /// No description provided for @sectionTasks.
  ///
  /// In fr, this message translates to:
  /// **'Tâches'**
  String get sectionTasks;

  /// No description provided for @sectionCalendar.
  ///
  /// In fr, this message translates to:
  /// **'Calendrier'**
  String get sectionCalendar;

  /// No description provided for @importBackup.
  ///
  /// In fr, this message translates to:
  /// **'Restaurer une sauvegarde'**
  String get importBackup;

  /// No description provided for @chooseBackupFile.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un fichier'**
  String get chooseBackupFile;

  /// No description provided for @importing.
  ///
  /// In fr, this message translates to:
  /// **'Restauration…'**
  String get importing;

  /// No description provided for @importDone.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{1 élément restauré} other{{count} éléments restaurés}}'**
  String importDone(int count);

  /// No description provided for @importSkipped.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{1 ligne ignorée} other{{count} lignes ignorées}}'**
  String importSkipped(int count);

  /// No description provided for @importConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Les données du fichier remplacent celles de même identifiant. Rien n\'est supprimé.'**
  String get importConfirm;

  /// No description provided for @importErrorNotAZip.
  ///
  /// In fr, this message translates to:
  /// **'Ce fichier n\'est pas une sauvegarde Auxine.'**
  String get importErrorNotAZip;

  /// No description provided for @importErrorWrongApp.
  ///
  /// In fr, this message translates to:
  /// **'Cette sauvegarde vient d\'une autre application.'**
  String get importErrorWrongApp;

  /// No description provided for @importErrorTooRecent.
  ///
  /// In fr, this message translates to:
  /// **'Cette sauvegarde vient d\'une version plus récente d\'Auxine.'**
  String get importErrorTooRecent;

  /// No description provided for @importErrorGeneric.
  ///
  /// In fr, this message translates to:
  /// **'Restauration impossible.'**
  String get importErrorGeneric;

  /// No description provided for @backupFrom.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde du {date}'**
  String backupFrom(String date);

  /// No description provided for @backupContains.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{1 élément} other{{count} éléments}}'**
  String backupContains(int count);

  /// No description provided for @onbTodayTitle.
  ///
  /// In fr, this message translates to:
  /// **'Les soins du jour'**
  String get onbTodayTitle;

  /// No description provided for @onbTodayBody.
  ///
  /// In fr, this message translates to:
  /// **'Un geste pour noter chaque soin.'**
  String get onbTodayBody;

  /// No description provided for @onbCareTitle.
  ///
  /// In fr, this message translates to:
  /// **'Moins d\'arrosages en hiver'**
  String get onbCareTitle;

  /// No description provided for @onbCareBody.
  ///
  /// In fr, this message translates to:
  /// **'Les intervalles s\'ajustent selon la saison.'**
  String get onbCareBody;

  /// No description provided for @onbGardenTitle.
  ///
  /// In fr, this message translates to:
  /// **'Emplacements, photos, calendrier'**
  String get onbGardenTitle;

  /// No description provided for @onbGardenBody.
  ///
  /// In fr, this message translates to:
  /// **'Chaque arrosage, chaque rempotage est daté et rangé avec la plante.'**
  String get onbGardenBody;

  /// No description provided for @onbIrisTitle.
  ///
  /// In fr, this message translates to:
  /// **'{name} reconnaît vos plantes hors ligne'**
  String onbIrisTitle(String name);

  /// No description provided for @onbIrisBody.
  ///
  /// In fr, this message translates to:
  /// **'Plante inconnue d\'Iris : la recherche continue en ligne.'**
  String get onbIrisBody;

  /// No description provided for @onbPrivacyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Tout reste sur votre téléphone'**
  String get onbPrivacyTitle;

  /// No description provided for @onbPrivacyBody.
  ///
  /// In fr, this message translates to:
  /// **'Pas de compte obligatoire, pas de publicité.'**
  String get onbPrivacyBody;

  /// No description provided for @onbStart.
  ///
  /// In fr, this message translates to:
  /// **'Commencer'**
  String get onbStart;

  /// No description provided for @replayOnboarding.
  ///
  /// In fr, this message translates to:
  /// **'Revoir la présentation'**
  String get replayOnboarding;

  /// No description provided for @whatsNewTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouveautés'**
  String get whatsNewTitle;

  /// No description provided for @whatsNewModelUpdate.
  ///
  /// In fr, this message translates to:
  /// **'Mise à jour du modèle'**
  String get whatsNewModelUpdate;

  /// No description provided for @whatsNewIrisIntro.
  ///
  /// In fr, this message translates to:
  /// **'Le modèle embarqué a été réentraîné : plus d\'espèces, moins d\'erreurs, toujours sans réseau.'**
  String get whatsNewIrisIntro;

  /// No description provided for @whatsNewIrisSpeciesTitle.
  ///
  /// In fr, this message translates to:
  /// **'{count} espèces reconnues'**
  String whatsNewIrisSpeciesTitle(String count);

  /// No description provided for @whatsNewIrisSpeciesBody.
  ///
  /// In fr, this message translates to:
  /// **'Des plantes d\'intérieur plus rares s\'ajoutent au catalogue.'**
  String get whatsNewIrisSpeciesBody;

  /// No description provided for @whatsNewIrisOfflineTitle.
  ///
  /// In fr, this message translates to:
  /// **'Toujours sur l\'appareil'**
  String get whatsNewIrisOfflineTitle;

  /// No description provided for @whatsNewIrisOfflineBody.
  ///
  /// In fr, this message translates to:
  /// **'La reconnaissance reste locale : rien ne part sans votre accord, et le repli en ligne se coupe d\'un interrupteur.'**
  String get whatsNewIrisOfflineBody;

  /// No description provided for @whatsNewIrisDoubtTitle.
  ///
  /// In fr, this message translates to:
  /// **'Doute signalé'**
  String get whatsNewIrisDoubtTitle;

  /// No description provided for @whatsNewIrisDoubtBody.
  ///
  /// In fr, this message translates to:
  /// **'Deux espèces qui se ressemblent : les deux sont proposées.'**
  String get whatsNewIrisDoubtBody;

  /// No description provided for @onbStepOf.
  ///
  /// In fr, this message translates to:
  /// **'Étape {current} sur {total}'**
  String onbStepOf(int current, int total);

  /// No description provided for @weatherPickPlace.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un lieu'**
  String get weatherPickPlace;

  /// No description provided for @speciesMoreOffline.
  ///
  /// In fr, this message translates to:
  /// **'Autres espèces'**
  String get speciesMoreOffline;

  /// No description provided for @aboutSources.
  ///
  /// In fr, this message translates to:
  /// **'Sources des données'**
  String get aboutSources;

  /// No description provided for @privacyPolicy.
  ///
  /// In fr, this message translates to:
  /// **'Politique de confidentialité'**
  String get privacyPolicy;

  /// No description provided for @aboutSourceWikidata.
  ///
  /// In fr, this message translates to:
  /// **'Noms d\'espèces en quatre langues, domaine public'**
  String get aboutSourceWikidata;

  /// No description provided for @aboutSourceGbif.
  ///
  /// In fr, this message translates to:
  /// **'Taxonomie, familles et observations photographiées'**
  String get aboutSourceGbif;

  /// No description provided for @aboutSourceOpenMeteo.
  ///
  /// In fr, this message translates to:
  /// **'Météo et prévisions, sans compte ni clé'**
  String get aboutSourceOpenMeteo;

  /// No description provided for @aboutSourceRhs.
  ///
  /// In fr, this message translates to:
  /// **'Rusticité, sols et conseils de culture'**
  String get aboutSourceRhs;

  /// No description provided for @aboutSourceAspca.
  ///
  /// In fr, this message translates to:
  /// **'Toxicité des plantes pour les animaux domestiques'**
  String get aboutSourceAspca;

  /// No description provided for @aboutSpeciesCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} espèces consultables hors ligne'**
  String aboutSpeciesCount(String count);

  /// No description provided for @supportTitle.
  ///
  /// In fr, this message translates to:
  /// **'Auxine est gratuite'**
  String get supportTitle;

  /// No description provided for @supportBody.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les fonctions sont accessibles. Aucun abonnement, aucune publicité, aucun compte obligatoire.'**
  String get supportBody;

  /// No description provided for @supportOffer.
  ///
  /// In fr, this message translates to:
  /// **'Si vous souhaitez néanmoins aider le développeur, un achat unique suffit.'**
  String get supportOffer;

  /// No description provided for @supportOnce.
  ///
  /// In fr, this message translates to:
  /// **'Une seule fois'**
  String get supportOnce;

  /// No description provided for @supportGive.
  ///
  /// In fr, this message translates to:
  /// **'Soutenir · {price}'**
  String supportGive(String price);

  /// No description provided for @supportRestore.
  ///
  /// In fr, this message translates to:
  /// **'Restaurer mon soutien'**
  String get supportRestore;

  /// No description provided for @supportThanksTitle.
  ///
  /// In fr, this message translates to:
  /// **'Merci'**
  String get supportThanksTitle;

  /// No description provided for @supportThanksBody.
  ///
  /// In fr, this message translates to:
  /// **'Votre soutien est enregistré.'**
  String get supportThanksBody;

  /// No description provided for @supportUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'L\'achat n\'est pas disponible sur cet appareil.'**
  String get supportUnavailable;

  /// No description provided for @supportFailed.
  ///
  /// In fr, this message translates to:
  /// **'L\'achat n\'a pas abouti.'**
  String get supportFailed;

  /// No description provided for @supportNothingToRestore.
  ///
  /// In fr, this message translates to:
  /// **'Aucun soutien à restaurer.'**
  String get supportNothingToRestore;

  /// No description provided for @supportSettings.
  ///
  /// In fr, this message translates to:
  /// **'Soutenir le développeur'**
  String get supportSettings;

  /// No description provided for @supportFreeForever.
  ///
  /// In fr, this message translates to:
  /// **'Gratuite, sans limite'**
  String get supportFreeForever;

  /// No description provided for @supportAlready.
  ///
  /// In fr, this message translates to:
  /// **'Merci pour votre soutien'**
  String get supportAlready;

  /// No description provided for @supportNoThanks.
  ///
  /// In fr, this message translates to:
  /// **'Non merci'**
  String get supportNoThanks;

  /// No description provided for @emptyGardenSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez votre première plante.'**
  String get emptyGardenSubtitle;

  /// No description provided for @finderTitle.
  ///
  /// In fr, this message translates to:
  /// **'Trouver une plante'**
  String get finderTitle;

  /// No description provided for @finderEntryHint.
  ///
  /// In fr, this message translates to:
  /// **'Aide au choix'**
  String get finderEntryHint;

  /// No description provided for @finderStepSpot.
  ///
  /// In fr, this message translates to:
  /// **'Emplacement'**
  String get finderStepSpot;

  /// No description provided for @finderStepSpotHint.
  ///
  /// In fr, this message translates to:
  /// **'La lumière est le critère principal.'**
  String get finderStepSpotHint;

  /// No description provided for @finderSpotBright.
  ///
  /// In fr, this message translates to:
  /// **'Pièce lumineuse'**
  String get finderSpotBright;

  /// No description provided for @finderSpotMedium.
  ///
  /// In fr, this message translates to:
  /// **'Lumière moyenne'**
  String get finderSpotMedium;

  /// No description provided for @finderSpotDark.
  ///
  /// In fr, this message translates to:
  /// **'Coin sombre'**
  String get finderSpotDark;

  /// No description provided for @finderSpotOutdoor.
  ///
  /// In fr, this message translates to:
  /// **'Dehors, balcon ou jardin'**
  String get finderSpotOutdoor;

  /// No description provided for @finderStepEffort.
  ///
  /// In fr, this message translates to:
  /// **'Quel entretien ?'**
  String get finderStepEffort;

  /// No description provided for @finderStepEffortHint.
  ///
  /// In fr, this message translates to:
  /// **'Fréquence d\'arrosage que vous pouvez assurer.'**
  String get finderStepEffortHint;

  /// No description provided for @finderEffortForgiving.
  ///
  /// In fr, this message translates to:
  /// **'Arrosage occasionnel'**
  String get finderEffortForgiving;

  /// No description provided for @finderEffortNormal.
  ///
  /// In fr, this message translates to:
  /// **'Arrosage régulier'**
  String get finderEffortNormal;

  /// No description provided for @finderEffortAttentive.
  ///
  /// In fr, this message translates to:
  /// **'Entretien fréquent'**
  String get finderEffortAttentive;

  /// No description provided for @finderStepSafety.
  ///
  /// In fr, this message translates to:
  /// **'Des animaux ou des enfants ?'**
  String get finderStepSafety;

  /// No description provided for @finderStepSafetyHint.
  ///
  /// In fr, this message translates to:
  /// **'Beaucoup de plantes d\'intérieur sont toxiques si on les mordille.'**
  String get finderStepSafetyHint;

  /// No description provided for @finderSafetyYes.
  ///
  /// In fr, this message translates to:
  /// **'Oui, sans risque de préférence'**
  String get finderSafetyYes;

  /// No description provided for @finderSafetyNo.
  ///
  /// In fr, this message translates to:
  /// **'Pas de contrainte'**
  String get finderSafetyNo;

  /// No description provided for @finderNote.
  ///
  /// In fr, this message translates to:
  /// **'Précisions'**
  String get finderNote;

  /// No description provided for @finderNoteHint.
  ///
  /// In fr, this message translates to:
  /// **'Une salle de bain sans fenêtre, un chat qui mordille tout…'**
  String get finderNoteHint;

  /// No description provided for @finderResults.
  ///
  /// In fr, this message translates to:
  /// **'Propositions'**
  String get finderResults;

  /// No description provided for @finderEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun résultat'**
  String get finderEmptyTitle;

  /// No description provided for @finderEmptySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune espèce du catalogue ne correspond à tous les critères. Modifiez une réponse ou élargissez les genres de plantes.'**
  String get finderEmptySubtitle;

  /// No description provided for @finderRestart.
  ///
  /// In fr, this message translates to:
  /// **'Recommencer'**
  String get finderRestart;

  /// No description provided for @finderAdd.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter au jardin'**
  String get finderAdd;

  /// No description provided for @finderAskAi.
  ///
  /// In fr, this message translates to:
  /// **'Demander à l\'IA'**
  String get finderAskAi;

  /// No description provided for @finderAiSection.
  ///
  /// In fr, this message translates to:
  /// **'Propositions de l\'IA'**
  String get finderAiSection;

  /// No description provided for @finderAiHint.
  ///
  /// In fr, this message translates to:
  /// **'Hors catalogue, à vérifier avant d\'acheter.'**
  String get finderAiHint;

  /// No description provided for @finderAiError.
  ///
  /// In fr, this message translates to:
  /// **'Aucune proposition de l\'IA.'**
  String get finderAiError;

  /// No description provided for @finderReasonLight.
  ///
  /// In fr, this message translates to:
  /// **'Lumière adaptée'**
  String get finderReasonLight;

  /// No description provided for @finderReasonLowLight.
  ///
  /// In fr, this message translates to:
  /// **'Supporte l\'ombre'**
  String get finderReasonLowLight;

  /// No description provided for @finderReasonForgiving.
  ///
  /// In fr, this message translates to:
  /// **'Tolère les oublis d\'arrosage'**
  String get finderReasonForgiving;

  /// No description provided for @finderReasonEasy.
  ///
  /// In fr, this message translates to:
  /// **'Facile'**
  String get finderReasonEasy;

  /// No description provided for @finderReasonSafe.
  ///
  /// In fr, this message translates to:
  /// **'Non toxique'**
  String get finderReasonSafe;

  /// No description provided for @finderReasonOutdoor.
  ///
  /// In fr, this message translates to:
  /// **'Tient dehors'**
  String get finderReasonOutdoor;

  /// No description provided for @finderAnyAnswer.
  ///
  /// In fr, this message translates to:
  /// **'Peu importe'**
  String get finderAnyAnswer;

  /// No description provided for @finderQuestionOf.
  ///
  /// In fr, this message translates to:
  /// **'Question {n} sur {total}'**
  String finderQuestionOf(int n, int total);

  /// No description provided for @finderSpotBrightHint.
  ///
  /// In fr, this message translates to:
  /// **'Près d\'une fenêtre, beaucoup de jour'**
  String get finderSpotBrightHint;

  /// No description provided for @finderSpotMediumHint.
  ///
  /// In fr, this message translates to:
  /// **'À quelques pas d\'une fenêtre'**
  String get finderSpotMediumHint;

  /// No description provided for @finderSpotDarkHint.
  ///
  /// In fr, this message translates to:
  /// **'Loin des fenêtres, peu de jour'**
  String get finderSpotDarkHint;

  /// No description provided for @finderSpotOutdoorHint.
  ///
  /// In fr, this message translates to:
  /// **'Balcon, terrasse ou jardin'**
  String get finderSpotOutdoorHint;

  /// No description provided for @finderEffortForgivingHint.
  ///
  /// In fr, this message translates to:
  /// **'Une plante qui tolère les oublis'**
  String get finderEffortForgivingHint;

  /// No description provided for @finderEffortNormalHint.
  ///
  /// In fr, this message translates to:
  /// **'Un arrosage par semaine, à peu près'**
  String get finderEffortNormalHint;

  /// No description provided for @finderEffortAttentiveHint.
  ///
  /// In fr, this message translates to:
  /// **'Brumisation, rempotage, surveillance régulière'**
  String get finderEffortAttentiveHint;

  /// No description provided for @finderSafetyYesHint.
  ///
  /// In fr, this message translates to:
  /// **'Seulement des espèces non toxiques'**
  String get finderSafetyYesHint;

  /// No description provided for @finderSafetyNoHint.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les espèces, toxiques comprises'**
  String get finderSafetyNoHint;

  /// No description provided for @finderTopPick.
  ///
  /// In fr, this message translates to:
  /// **'Premier choix'**
  String get finderTopPick;

  /// No description provided for @finderAlternatives.
  ///
  /// In fr, this message translates to:
  /// **'Autres propositions'**
  String get finderAlternatives;

  /// No description provided for @finderChangeAnswer.
  ///
  /// In fr, this message translates to:
  /// **'Modifier cette réponse'**
  String get finderChangeAnswer;

  /// No description provided for @finderChipSpotAny.
  ///
  /// In fr, this message translates to:
  /// **'Endroit : peu importe'**
  String get finderChipSpotAny;

  /// No description provided for @finderChipEffortAny.
  ///
  /// In fr, this message translates to:
  /// **'Entretien : peu importe'**
  String get finderChipEffortAny;

  /// No description provided for @finderChipSafe.
  ///
  /// In fr, this message translates to:
  /// **'Sans risque'**
  String get finderChipSafe;

  /// No description provided for @finderFactWater.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Eau chaque jour} other{Eau tous les {count} j}}'**
  String finderFactWater(int count);

  /// No description provided for @finderAiTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aller plus loin'**
  String get finderAiTitle;

  /// No description provided for @finderAiBody.
  ///
  /// In fr, this message translates to:
  /// **'Recherche hors du catalogue, à partir de vos réponses et de ce que vous ajoutez ici.'**
  String get finderAiBody;

  /// No description provided for @finderPhotoSource.
  ///
  /// In fr, this message translates to:
  /// **'Photos : observations GBIF, libres de droits.'**
  String get finderPhotoSource;

  /// No description provided for @onbWelcomeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue sur Auxine'**
  String get onbWelcomeTitle;

  /// No description provided for @onbWelcomeBody.
  ///
  /// In fr, this message translates to:
  /// **'Le carnet d\'entretien de vos plantes.'**
  String get onbWelcomeBody;

  /// No description provided for @careMatchAssisted.
  ///
  /// In fr, this message translates to:
  /// **'Complétée par l\'IA'**
  String get careMatchAssisted;

  /// No description provided for @careAssistedNote.
  ///
  /// In fr, this message translates to:
  /// **'Espèce absente du catalogue : ces repères viennent de l\'IA. Seul le nom scientifique a été envoyé. La toxicité n\'est pas renseignée.'**
  String get careAssistedNote;

  /// No description provided for @careMatchEdited.
  ///
  /// In fr, this message translates to:
  /// **'Fiche retouchée'**
  String get careMatchEdited;

  /// No description provided for @careEditedNote.
  ///
  /// In fr, this message translates to:
  /// **'Fiche corrigée à la main ; le reste vient du catalogue.'**
  String get careEditedNote;

  /// No description provided for @careVerifiedFields.
  ///
  /// In fr, this message translates to:
  /// **'Vérifié d\'après {source} : {fields}'**
  String careVerifiedFields(String source, String fields);

  /// No description provided for @careSourceHabitat.
  ///
  /// In fr, this message translates to:
  /// **'habitat d\'origine'**
  String get careSourceHabitat;

  /// No description provided for @careSourceDerived.
  ///
  /// In fr, this message translates to:
  /// **'règle de culture'**
  String get careSourceDerived;

  /// No description provided for @careStudio.
  ///
  /// In fr, this message translates to:
  /// **'Care Studio'**
  String get careStudio;

  /// No description provided for @careStudioHint.
  ///
  /// In fr, this message translates to:
  /// **'Corrigez une fiche d\'entretien. La retouche s\'applique sur cet appareil.'**
  String get careStudioHint;

  /// No description provided for @careStudioSearch.
  ///
  /// In fr, this message translates to:
  /// **'Chercher une espèce'**
  String get careStudioSearch;

  /// No description provided for @careStudioPrompt.
  ///
  /// In fr, this message translates to:
  /// **'Cherchez une espèce pour corriger sa fiche.'**
  String get careStudioPrompt;

  /// No description provided for @careStudioEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune espèce ne correspond.'**
  String get careStudioEmpty;

  /// No description provided for @careStudioWateringSummer.
  ///
  /// In fr, this message translates to:
  /// **'Arrosage, pleine saison'**
  String get careStudioWateringSummer;

  /// No description provided for @careStudioWateringWinter.
  ///
  /// In fr, this message translates to:
  /// **'Arrosage, hiver'**
  String get careStudioWateringWinter;

  /// No description provided for @careStudioDamageBelow.
  ///
  /// In fr, this message translates to:
  /// **'Éviter sous'**
  String get careStudioDamageBelow;

  /// No description provided for @careStudioSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get careStudioSave;

  /// No description provided for @careStudioSaved.
  ///
  /// In fr, this message translates to:
  /// **'Retouche enregistrée'**
  String get careStudioSaved;

  /// No description provided for @careStudioReset.
  ///
  /// In fr, this message translates to:
  /// **'Revenir au catalogue'**
  String get careStudioReset;

  /// No description provided for @careAssistSetting.
  ///
  /// In fr, this message translates to:
  /// **'Compléter les fiches avec l\'IA'**
  String get careAssistSetting;

  /// No description provided for @careAssistHint.
  ///
  /// In fr, this message translates to:
  /// **'Pour une espèce absente du catalogue, le nom scientifique est envoyé à l\'IA pour compléter la fiche. Rien d\'autre ne quitte l\'appareil. La réponse est conservée.'**
  String get careAssistHint;

  /// No description provided for @gardensTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes jardins'**
  String get gardensTitle;

  /// No description provided for @gardensHint.
  ///
  /// In fr, this message translates to:
  /// **'Le jardin ouvert est celui affiché partout dans l\'application. Le passage de l\'un à l\'autre se fait ici.'**
  String get gardensHint;

  /// No description provided for @gardenMine.
  ///
  /// In fr, this message translates to:
  /// **'Mon jardin'**
  String get gardenMine;

  /// No description provided for @gardenUnnamed.
  ///
  /// In fr, this message translates to:
  /// **'Jardin partagé'**
  String get gardenUnnamed;

  /// No description provided for @gardenSharedBy.
  ///
  /// In fr, this message translates to:
  /// **'Partagé par {name}'**
  String gardenSharedBy(String name);

  /// No description provided for @gardenOpened.
  ///
  /// In fr, this message translates to:
  /// **'Jardin : {name}'**
  String gardenOpened(String name);

  /// No description provided for @someone.
  ///
  /// In fr, this message translates to:
  /// **'quelqu\'un'**
  String get someone;

  /// No description provided for @memberCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 membre} other{{count} membres}}'**
  String memberCount(int count);

  /// No description provided for @renameGarden.
  ///
  /// In fr, this message translates to:
  /// **'Renommer le jardin'**
  String get renameGarden;

  /// No description provided for @renameGardenHint.
  ///
  /// In fr, this message translates to:
  /// **'Nom visible par les personnes invitées.'**
  String get renameGardenHint;

  /// No description provided for @gardenNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Le jardin de la maison'**
  String get gardenNameHint;

  /// No description provided for @joinGarden.
  ///
  /// In fr, this message translates to:
  /// **'Rejoindre un jardin'**
  String get joinGarden;

  /// No description provided for @joinGardenHint.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez le code reçu, ou ouvrez le lien d\'invitation qu\'on vous a envoyé.'**
  String get joinGardenHint;

  /// No description provided for @inviteCodeHint.
  ///
  /// In fr, this message translates to:
  /// **'Code d\'invitation'**
  String get inviteCodeHint;

  /// No description provided for @joinLook.
  ///
  /// In fr, this message translates to:
  /// **'Voir l\'invitation'**
  String get joinLook;

  /// No description provided for @joinConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Rejoindre'**
  String get joinConfirm;

  /// No description provided for @joinInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Ce code ne vaut plus rien. Il a déjà servi, a expiré, ou n\'existe pas.'**
  String get joinInvalid;

  /// No description provided for @joinWrongEmail.
  ///
  /// In fr, this message translates to:
  /// **'Cette invitation est réservée à une autre adresse e-mail.'**
  String get joinWrongEmail;

  /// No description provided for @joinNeedsAccount.
  ///
  /// In fr, this message translates to:
  /// **'Il faut un compte pour rejoindre un jardin.'**
  String get joinNeedsAccount;

  /// No description provided for @joinSignInHint.
  ///
  /// In fr, this message translates to:
  /// **'Connexion avec votre identifiant Apple.'**
  String get joinSignInHint;

  /// No description provided for @joinInvitedBy.
  ///
  /// In fr, this message translates to:
  /// **'{name} vous invite dans « {garden} »'**
  String joinInvitedBy(String name, String garden);

  /// No description provided for @joinGardenName.
  ///
  /// In fr, this message translates to:
  /// **'Invitation dans « {garden} »'**
  String joinGardenName(String garden);

  /// No description provided for @joinAsMember.
  ///
  /// In fr, this message translates to:
  /// **'Ajout, modification et suppression de plantes.'**
  String get joinAsMember;

  /// No description provided for @joinAsViewer.
  ///
  /// In fr, this message translates to:
  /// **'Consultation seule, sans modification.'**
  String get joinAsViewer;

  /// No description provided for @joinAlreadyMember.
  ///
  /// In fr, this message translates to:
  /// **'Vous faites déjà partie de ce jardin.'**
  String get joinAlreadyMember;

  /// No description provided for @joined.
  ///
  /// In fr, this message translates to:
  /// **'Jardin « {name} » rejoint'**
  String joined(String name);

  /// No description provided for @leaveGarden.
  ///
  /// In fr, this message translates to:
  /// **'Quitter ce jardin'**
  String get leaveGarden;

  /// No description provided for @leaveGardenConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Vous n\'aurez plus accès à « {name} ».'**
  String leaveGardenConfirm(String name);

  /// No description provided for @leftGarden.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez quitté « {name} »'**
  String leftGarden(String name);

  /// No description provided for @deleteGarden.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le jardin'**
  String get deleteGarden;

  /// No description provided for @deleteGardenConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Le jardin « {name} », ses plantes et son journal seront supprimés, pour vous comme pour les personnes invitées.'**
  String deleteGardenConfirm(String name);

  /// No description provided for @gardenDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Jardin « {name} » supprimé'**
  String gardenDeleted(String name);

  /// No description provided for @deleteGardenLast.
  ///
  /// In fr, this message translates to:
  /// **'Un compte garde au moins un jardin.'**
  String get deleteGardenLast;

  /// No description provided for @openGardenTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vos jardins'**
  String get openGardenTitle;

  /// No description provided for @openGardenHint.
  ///
  /// In fr, this message translates to:
  /// **'Ce compte donne accès à ces jardins. Ouvrez celui où sont vos plantes.'**
  String get openGardenHint;

  /// No description provided for @collaborationNeedsAccount.
  ///
  /// In fr, this message translates to:
  /// **'Il faut un compte pour partager un jardin'**
  String get collaborationNeedsAccount;

  /// No description provided for @inviteSomeone.
  ///
  /// In fr, this message translates to:
  /// **'Inviter quelqu\'un'**
  String get inviteSomeone;

  /// No description provided for @inviteReady.
  ///
  /// In fr, this message translates to:
  /// **'Invitation prête'**
  String get inviteReady;

  /// No description provided for @inviteRoleHint.
  ///
  /// In fr, this message translates to:
  /// **'Membre : ajoute, modifie et supprime des plantes. Lecteur : consultation seule.'**
  String get inviteRoleHint;

  /// No description provided for @inviteEmailOptional.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail (facultatif)'**
  String get inviteEmailOptional;

  /// No description provided for @inviteEmailHint.
  ///
  /// In fr, this message translates to:
  /// **'Si renseignée, seule cette adresse pourra accepter l\'invitation.'**
  String get inviteEmailHint;

  /// No description provided for @inviteCreate.
  ///
  /// In fr, this message translates to:
  /// **'Créer l\'invitation'**
  String get inviteCreate;

  /// No description provided for @inviteShareHint.
  ///
  /// In fr, this message translates to:
  /// **'Envoyez ce lien ou ce code. L\'application n\'est pas nécessaire pour le recevoir.'**
  String get inviteShareHint;

  /// No description provided for @inviteShare.
  ///
  /// In fr, this message translates to:
  /// **'Partager le lien'**
  String get inviteShare;

  /// No description provided for @inviteMessage.
  ///
  /// In fr, this message translates to:
  /// **'Invitation à rejoindre mon jardin sur Auxine : {link}'**
  String inviteMessage(String link);

  /// No description provided for @inviteOnceHint.
  ///
  /// In fr, this message translates to:
  /// **'Une invitation ne sert qu\'une fois.'**
  String get inviteOnceHint;

  /// No description provided for @inviteExpires.
  ///
  /// In fr, this message translates to:
  /// **'Expire le {date}'**
  String inviteExpires(String date);

  /// No description provided for @inviteFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de créer l\'invitation.'**
  String get inviteFailed;

  /// No description provided for @invitesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Invitations en attente'**
  String get invitesTitle;

  /// No description provided for @inviteRevoke.
  ///
  /// In fr, this message translates to:
  /// **'Révoquer'**
  String get inviteRevoke;

  /// No description provided for @inviteRevokeConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Le code ne fonctionnera plus.'**
  String get inviteRevokeConfirm;

  /// No description provided for @inviteRevoked.
  ///
  /// In fr, this message translates to:
  /// **'Invitation révoquée'**
  String get inviteRevoked;

  /// No description provided for @membersHint.
  ///
  /// In fr, this message translates to:
  /// **'Les membres voient les mêmes plantes et peuvent s\'en occuper.'**
  String get membersHint;

  /// No description provided for @membersGuestHint.
  ///
  /// In fr, this message translates to:
  /// **'Jardin partagé par un autre utilisateur.'**
  String get membersGuestHint;

  /// No description provided for @memberRoleHint.
  ///
  /// In fr, this message translates to:
  /// **'Membre : ajoute, modifie et supprime des plantes. Lecteur : consultation seule.'**
  String get memberRoleHint;

  /// No description provided for @makeRole.
  ///
  /// In fr, this message translates to:
  /// **'Passer en « {role} »'**
  String makeRole(String role);

  /// No description provided for @roleChanged.
  ///
  /// In fr, this message translates to:
  /// **'{name} est maintenant « {role} »'**
  String roleChanged(String name, String role);

  /// No description provided for @removeMemberConfirm.
  ///
  /// In fr, this message translates to:
  /// **'{name} n\'aura plus accès à ce jardin.'**
  String removeMemberConfirm(String name);

  /// No description provided for @photoFirstTitle.
  ///
  /// In fr, this message translates to:
  /// **'Première photo'**
  String get photoFirstTitle;

  /// No description provided for @photoNextTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle photo'**
  String get photoNextTitle;

  /// No description provided for @photoFirstHint.
  ///
  /// In fr, this message translates to:
  /// **'Elle servira de photo principale.'**
  String get photoFirstHint;

  /// No description provided for @photoFrameHint.
  ///
  /// In fr, this message translates to:
  /// **'Gardez le même cadrage d\'une fois sur l\'autre pour suivre la croissance.'**
  String get photoFrameHint;

  /// No description provided for @photoGhostToggle.
  ///
  /// In fr, this message translates to:
  /// **'Superposer la dernière photo'**
  String get photoGhostToggle;

  /// No description provided for @photoGhostHint.
  ///
  /// In fr, this message translates to:
  /// **'Alignez la plante sur la photo en transparence.'**
  String get photoGhostHint;

  /// No description provided for @photoTitleStepTitle.
  ///
  /// In fr, this message translates to:
  /// **'Titre'**
  String get photoTitleStepTitle;

  /// No description provided for @photoTitleStepSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Facultatif.'**
  String get photoTitleStepSubtitle;

  /// No description provided for @photoTagNewLeaf.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle feuille'**
  String get photoTagNewLeaf;

  /// No description provided for @photoTagFlowering.
  ///
  /// In fr, this message translates to:
  /// **'Floraison'**
  String get photoTagFlowering;

  /// No description provided for @photoTagBeforeRepotting.
  ///
  /// In fr, this message translates to:
  /// **'Avant rempotage'**
  String get photoTagBeforeRepotting;

  /// No description provided for @photoTagAfterRepotting.
  ///
  /// In fr, this message translates to:
  /// **'Après rempotage'**
  String get photoTagAfterRepotting;

  /// No description provided for @photoTagCutting.
  ///
  /// In fr, this message translates to:
  /// **'Bouture'**
  String get photoTagCutting;

  /// No description provided for @photoTagAfterPruning.
  ///
  /// In fr, this message translates to:
  /// **'Après taille'**
  String get photoTagAfterPruning;

  /// No description provided for @mainPhotoHint.
  ///
  /// In fr, this message translates to:
  /// **'Affichée sur la fiche et dans la liste.'**
  String get mainPhotoHint;

  /// No description provided for @retake.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre'**
  String get retake;

  /// No description provided for @growthEmptySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez des photos régulièrement pour suivre la croissance.'**
  String get growthEmptySubtitle;

  /// No description provided for @growthSummary.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 photo · depuis {since}} other{{count} photos · depuis {since}}}'**
  String growthSummary(int count, String since);

  /// No description provided for @growthNudge.
  ///
  /// In fr, this message translates to:
  /// **'Dernière photo le {date}.'**
  String growthNudge(String date);

  /// No description provided for @timelapse.
  ///
  /// In fr, this message translates to:
  /// **'Timelapse'**
  String get timelapse;

  /// No description provided for @beforeAfter.
  ///
  /// In fr, this message translates to:
  /// **'Avant / après'**
  String get beforeAfter;

  /// No description provided for @photoCounter.
  ///
  /// In fr, this message translates to:
  /// **'{index} / {total}'**
  String photoCounter(int index, int total);

  /// No description provided for @photoTitleShort.
  ///
  /// In fr, this message translates to:
  /// **'Titre'**
  String get photoTitleShort;

  /// No description provided for @mainPhotoShort.
  ///
  /// In fr, this message translates to:
  /// **'Principale'**
  String get mainPhotoShort;

  /// No description provided for @share.
  ///
  /// In fr, this message translates to:
  /// **'Partager'**
  String get share;

  /// No description provided for @addTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un titre'**
  String get addTitle;

  /// No description provided for @swap.
  ///
  /// In fr, this message translates to:
  /// **'Inverser'**
  String get swap;

  /// No description provided for @pause.
  ///
  /// In fr, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @stepPhotoDoneTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu'**
  String get stepPhotoDoneTitle;

  /// No description provided for @stepPhotoDoneSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Une feuille de près aide {name} à reconnaître l\'espèce.'**
  String stepPhotoDoneSubtitle(String name);

  /// No description provided for @stepPhotoDonePlain.
  ///
  /// In fr, this message translates to:
  /// **'Vous pourrez en ajouter d\'autres depuis sa fiche.'**
  String get stepPhotoDonePlain;

  /// No description provided for @viewPlant.
  ///
  /// In fr, this message translates to:
  /// **'La plante'**
  String get viewPlant;

  /// No description provided for @viewLeafClose.
  ///
  /// In fr, this message translates to:
  /// **'Une feuille de près'**
  String get viewLeafClose;

  /// No description provided for @viewAnother.
  ///
  /// In fr, this message translates to:
  /// **'Autre vue'**
  String get viewAnother;

  /// No description provided for @viewForModel.
  ///
  /// In fr, this message translates to:
  /// **'Utilisée par {name} pour reconnaître l\'espèce, non conservée.'**
  String viewForModel(String name);

  /// No description provided for @strategyWeather.
  ///
  /// In fr, this message translates to:
  /// **'Météo'**
  String get strategyWeather;

  /// No description provided for @strategyWeatherHint.
  ///
  /// In fr, this message translates to:
  /// **'L\'intervalle de la saison, resserré par la chaleur sèche, espacé par la pluie et le froid.'**
  String get strategyWeatherHint;

  /// No description provided for @strategyWeatherNow.
  ///
  /// In fr, this message translates to:
  /// **'Avec le temps de la semaine : {interval}'**
  String strategyWeatherNow(String interval);

  /// No description provided for @strategyWeatherNoPlace.
  ///
  /// In fr, this message translates to:
  /// **'Sans lieu météo, l\'intervalle reste celui de la saison.'**
  String get strategyWeatherNoPlace;

  /// No description provided for @weatherWhenTonight.
  ///
  /// In fr, this message translates to:
  /// **'cette nuit'**
  String get weatherWhenTonight;

  /// No description provided for @weatherWhenToday.
  ///
  /// In fr, this message translates to:
  /// **'aujourd\'hui'**
  String get weatherWhenToday;

  /// No description provided for @weatherWhenTomorrow.
  ///
  /// In fr, this message translates to:
  /// **'demain'**
  String get weatherWhenTomorrow;

  /// No description provided for @weatherWhenInDays.
  ///
  /// In fr, this message translates to:
  /// **'dans {count} jours'**
  String weatherWhenInDays(int count);

  /// No description provided for @weatherFrostTitle.
  ///
  /// In fr, this message translates to:
  /// **'Gel {when} · {temp}'**
  String weatherFrostTitle(String when, String temp);

  /// No description provided for @weatherHeatTitle.
  ///
  /// In fr, this message translates to:
  /// **'Chaleur {when} · {temp}'**
  String weatherHeatTitle(String when, String temp);

  /// No description provided for @weatherFrostBody.
  ///
  /// In fr, this message translates to:
  /// **'À rentrer ou à couvrir : {names}.'**
  String weatherFrostBody(String names);

  /// No description provided for @weatherHeatBody.
  ///
  /// In fr, this message translates to:
  /// **'À mettre à l\'ombre, et à arroser tôt : {names}.'**
  String weatherHeatBody(String names);

  /// No description provided for @weatherAlertMore.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{et 1 autre} other{et {count} autres}}'**
  String weatherAlertMore(int count);

  /// No description provided for @weatherAlertFamily.
  ///
  /// In fr, this message translates to:
  /// **'la famille des {name}'**
  String weatherAlertFamily(String name);

  /// No description provided for @notifFrost.
  ///
  /// In fr, this message translates to:
  /// **'Gel {when} · à rentrer ou à couvrir : {names}.'**
  String notifFrost(String when, String names);

  /// No description provided for @notifHeat.
  ///
  /// In fr, this message translates to:
  /// **'Chaleur {when} · à mettre à l\'ombre : {names}.'**
  String notifHeat(String when, String names);

  /// No description provided for @weatherRainFallenTitle.
  ///
  /// In fr, this message translates to:
  /// **'Pluie · {mm} mm'**
  String weatherRainFallenTitle(String mm);

  /// No description provided for @weatherRainWatered.
  ///
  /// In fr, this message translates to:
  /// **'Arrosage noté fait pour {names}.'**
  String weatherRainWatered(String names);

  /// No description provided for @weatherRainWaterable.
  ///
  /// In fr, this message translates to:
  /// **'La pluie vaut l\'arrosage de {names}.'**
  String weatherRainWaterable(String names);

  /// No description provided for @weatherRainMarkWatered.
  ///
  /// In fr, this message translates to:
  /// **'Noter arrosé'**
  String get weatherRainMarkWatered;

  /// No description provided for @weatherRainWateredToast.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 arrosage noté} other{{count} arrosages notés}}'**
  String weatherRainWateredToast(int count);

  /// No description provided for @weatherRainNote.
  ///
  /// In fr, this message translates to:
  /// **'Arrosée par la pluie ({mm} mm).'**
  String weatherRainNote(String mm);

  /// No description provided for @weatherRainCounts.
  ///
  /// In fr, this message translates to:
  /// **'La pluie compte comme un arrosage'**
  String get weatherRainCounts;

  /// No description provided for @weatherRainCountsHint.
  ///
  /// In fr, this message translates to:
  /// **'Au-delà de 5 mm sur trois jours, l\'arrosage des emplacements extérieurs est noté fait. Coupé, l\'écran du matin le propose en un tap. Un pot abrité par un feuillage reçoit moins de pluie.'**
  String get weatherRainCountsHint;

  /// No description provided for @weatherClimate.
  ///
  /// In fr, this message translates to:
  /// **'Climat'**
  String get weatherClimate;

  /// No description provided for @weatherClimateHint.
  ///
  /// In fr, this message translates to:
  /// **'Les propositions de plantes pour l\'extérieur suivent les hivers et les étés du lieu.'**
  String get weatherClimateHint;

  /// No description provided for @weatherClimateZone.
  ///
  /// In fr, this message translates to:
  /// **'Zone {zone}'**
  String weatherClimateZone(String zone);

  /// No description provided for @weatherClimateRange.
  ///
  /// In fr, this message translates to:
  /// **'Hivers à {low}, étés à {high}'**
  String weatherClimateRange(String low, String high);

  /// No description provided for @weatherClimateNone.
  ///
  /// In fr, this message translates to:
  /// **'Inconnu'**
  String get weatherClimateNone;

  /// No description provided for @finderReasonHardy.
  ///
  /// In fr, this message translates to:
  /// **'Passe l\'hiver dehors ici'**
  String get finderReasonHardy;

  /// No description provided for @finderReasonSheltered.
  ///
  /// In fr, this message translates to:
  /// **'Hiverne dehors, protégée'**
  String get finderReasonSheltered;

  /// No description provided for @finderRegion.
  ///
  /// In fr, this message translates to:
  /// **'Zone {zone} · hivers à {low}'**
  String finderRegion(String zone, String low);

  /// No description provided for @encyclopediaTitle.
  ///
  /// In fr, this message translates to:
  /// **'Encyclopédie'**
  String get encyclopediaTitle;

  /// No description provided for @encyclopediaHint.
  ///
  /// In fr, this message translates to:
  /// **'Les problèmes de la base, les espèces du catalogue et le vocabulaire des fiches d\'entretien.'**
  String get encyclopediaHint;

  /// No description provided for @encyclopediaProblems.
  ///
  /// In fr, this message translates to:
  /// **'Problèmes'**
  String get encyclopediaProblems;

  /// No description provided for @encyclopediaSpecies.
  ///
  /// In fr, this message translates to:
  /// **'Espèces'**
  String get encyclopediaSpecies;

  /// No description provided for @encyclopediaGlossary.
  ///
  /// In fr, this message translates to:
  /// **'Vocabulaire'**
  String get encyclopediaGlossary;

  /// No description provided for @encyclopediaSearchProblems.
  ///
  /// In fr, this message translates to:
  /// **'Nom, ravageur, maladie…'**
  String get encyclopediaSearchProblems;

  /// No description provided for @encyclopediaSearchGlossary.
  ///
  /// In fr, this message translates to:
  /// **'Lumière, substrat, bouture…'**
  String get encyclopediaSearchGlossary;

  /// No description provided for @encyclopediaProblemCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun problème} =1{1 problème} other{{count} problèmes}}'**
  String encyclopediaProblemCount(int count);

  /// No description provided for @encyclopediaNaturalCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun phénomène normal} =1{1 phénomène normal} other{{count} phénomènes normaux}}'**
  String encyclopediaNaturalCount(int count);

  /// No description provided for @encyclopediaSpeciesCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucune espèce} =1{1 espèce} other{{count} espèces}}'**
  String encyclopediaSpeciesCount(int count);

  /// No description provided for @encyclopediaNoTerm.
  ///
  /// In fr, this message translates to:
  /// **'Aucun terme trouvé'**
  String get encyclopediaNoTerm;

  /// No description provided for @problemNumber.
  ///
  /// In fr, this message translates to:
  /// **'Entrée {id}'**
  String problemNumber(String id);

  /// No description provided for @problemScope.
  ///
  /// In fr, this message translates to:
  /// **'Étendue'**
  String get problemScope;

  /// No description provided for @problemScopeGeneral.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les plantes'**
  String get problemScopeGeneral;

  /// No description provided for @problemScopeWide.
  ///
  /// In fr, this message translates to:
  /// **'Nombreux hôtes'**
  String get problemScopeWide;

  /// No description provided for @problemScopeTarget.
  ///
  /// In fr, this message translates to:
  /// **'Hôtes ciblés'**
  String get problemScopeTarget;

  /// No description provided for @problemScopeGeneralNote.
  ///
  /// In fr, this message translates to:
  /// **'Possible sur les plantes vasculaires, selon les conditions et le stade.'**
  String get problemScopeGeneralNote;

  /// No description provided for @problemScopeWideNote.
  ///
  /// In fr, this message translates to:
  /// **'Nombreux hôtes ; les taxons cités sont des exemples.'**
  String get problemScopeWideNote;

  /// No description provided for @problemScopeTargetNote.
  ///
  /// In fr, this message translates to:
  /// **'Hôtes principaux d\'un groupe cible ; la liste n\'est pas exhaustive.'**
  String get problemScopeTargetNote;

  /// No description provided for @problemOtherNames.
  ///
  /// In fr, this message translates to:
  /// **'Autres noms'**
  String get problemOtherNames;

  /// No description provided for @problemOtherNamesNote.
  ///
  /// In fr, this message translates to:
  /// **'Noms courants et scientifiques qui désignent la même chose.'**
  String get problemOtherNamesNote;

  /// No description provided for @problemHosts.
  ///
  /// In fr, this message translates to:
  /// **'Hôtes'**
  String get problemHosts;

  /// No description provided for @problemHostsAll.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les plantes vasculaires'**
  String get problemHostsAll;

  /// No description provided for @problemHostsNote.
  ///
  /// In fr, this message translates to:
  /// **'Un genre ou une famille ne rend pas toutes ses espèces sensibles.'**
  String get problemHostsNote;

  /// No description provided for @problemInGarden.
  ///
  /// In fr, this message translates to:
  /// **'Dans le jardin'**
  String get problemInGarden;

  /// No description provided for @problemKindsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Familles de problèmes'**
  String get problemKindsTitle;

  /// No description provided for @problemKindDisorderNote.
  ///
  /// In fr, this message translates to:
  /// **'Ni ravageur ni maladie : l\'eau, la lumière, le froid, le substrat, une carence.'**
  String get problemKindDisorderNote;

  /// No description provided for @problemKindPestNote.
  ///
  /// In fr, this message translates to:
  /// **'Un être vivant qui s\'attaque à la plante : insecte, acarien, limace, nématode.'**
  String get problemKindPestNote;

  /// No description provided for @problemKindDiseaseNote.
  ///
  /// In fr, this message translates to:
  /// **'Un champignon, une bactérie, un virus ou un phytoplasme installé dans la plante.'**
  String get problemKindDiseaseNote;

  /// No description provided for @problemKindConditionNote.
  ///
  /// In fr, this message translates to:
  /// **'Ni l\'un ni l\'autre : la fumagine pousse sur le miellat, sans s\'attaquer à la plante.'**
  String get problemKindConditionNote;

  /// No description provided for @naturalCauses.
  ///
  /// In fr, this message translates to:
  /// **'Phénomènes normaux'**
  String get naturalCauses;

  /// No description provided for @naturalCauseNote.
  ///
  /// In fr, this message translates to:
  /// **'Ce que la plante fait normalement et qu\'on prend pour un problème : rien à soigner.'**
  String get naturalCauseNote;

  /// No description provided for @careLightShadeNote.
  ///
  /// In fr, this message translates to:
  /// **'Loin des fenêtres, sans rayon direct de la journée.'**
  String get careLightShadeNote;

  /// No description provided for @careLightLowNote.
  ///
  /// In fr, this message translates to:
  /// **'Une pièce claire mais éloignée de la fenêtre, ou exposée au nord.'**
  String get careLightLowNote;

  /// No description provided for @careLightIndirectNote.
  ///
  /// In fr, this message translates to:
  /// **'À quelques pas d\'une fenêtre, ou derrière un voilage.'**
  String get careLightIndirectNote;

  /// No description provided for @careLightBrightNote.
  ///
  /// In fr, this message translates to:
  /// **'Près d\'une fenêtre, hors du rayon du soleil.'**
  String get careLightBrightNote;

  /// No description provided for @careLightSomeNote.
  ///
  /// In fr, this message translates to:
  /// **'Le soleil du matin ou de fin de journée, pas celui de midi.'**
  String get careLightSomeNote;

  /// No description provided for @careLightFullNote.
  ///
  /// In fr, this message translates to:
  /// **'Six heures de soleil direct ou plus, en pleine journée.'**
  String get careLightFullNote;

  /// No description provided for @careHumidityLowNote.
  ///
  /// In fr, this message translates to:
  /// **'L\'air d\'un logement chauffé suffit.'**
  String get careHumidityLowNote;

  /// No description provided for @careHumidityAverageNote.
  ///
  /// In fr, this message translates to:
  /// **'Autour de 50 %, loin d\'un radiateur en hiver.'**
  String get careHumidityAverageNote;

  /// No description provided for @careHumidityHighNote.
  ///
  /// In fr, this message translates to:
  /// **'Au-delà de 60 % : salle de bains, cuisine, ou un plateau de billes d\'argile humides.'**
  String get careHumidityHighNote;

  /// No description provided for @careDifficultyEasyNote.
  ///
  /// In fr, this message translates to:
  /// **'Supporte les oublis et les écarts de lumière.'**
  String get careDifficultyEasyNote;

  /// No description provided for @careDifficultyMediumNote.
  ///
  /// In fr, this message translates to:
  /// **'Demande un rythme d\'arrosage régulier et un emplacement stable.'**
  String get careDifficultyMediumNote;

  /// No description provided for @careDifficultyDemandingNote.
  ///
  /// In fr, this message translates to:
  /// **'Lumière, humidité et arrosage demandent d\'être suivis de près.'**
  String get careDifficultyDemandingNote;

  /// No description provided for @careToxicSafeNote.
  ///
  /// In fr, this message translates to:
  /// **'Aucune toxicité connue pour les animaux ni les enfants.'**
  String get careToxicSafeNote;

  /// No description provided for @careToxicMildNote.
  ///
  /// In fr, this message translates to:
  /// **'La sève irrite la peau et la bouche.'**
  String get careToxicMildNote;

  /// No description provided for @careToxicToxicNote.
  ///
  /// In fr, this message translates to:
  /// **'Avaler une feuille ou un fruit rend malade.'**
  String get careToxicToxicNote;

  /// No description provided for @careToxicUnknownNote.
  ///
  /// In fr, this message translates to:
  /// **'Rien n\'est renseigné pour cette espèce ; à tenir hors de portée par précaution.'**
  String get careToxicUnknownNote;

  /// No description provided for @careSoilStandardNote.
  ///
  /// In fr, this message translates to:
  /// **'Le terreau vendu pour les plantes vertes, sans ajout.'**
  String get careSoilStandardNote;

  /// No description provided for @careSoilDrainingNote.
  ///
  /// In fr, this message translates to:
  /// **'Terreau allégé de perlite, de sable ou de pouzzolane.'**
  String get careSoilDrainingNote;

  /// No description provided for @careSoilCactusNote.
  ///
  /// In fr, this message translates to:
  /// **'Très minéral : l\'eau traverse sans stagner.'**
  String get careSoilCactusNote;

  /// No description provided for @careSoilOrchidNote.
  ///
  /// In fr, this message translates to:
  /// **'Des écorces grossières : les racines vivent à l\'air.'**
  String get careSoilOrchidNote;

  /// No description provided for @careSoilAcidicNote.
  ///
  /// In fr, this message translates to:
  /// **'Un pH acide, pour les plantes que le calcaire jaunit.'**
  String get careSoilAcidicNote;

  /// No description provided for @careSoilRichNote.
  ///
  /// In fr, this message translates to:
  /// **'Terreau enrichi de compost, pour les plantes gourmandes.'**
  String get careSoilRichNote;

  /// No description provided for @careSoilNoneNote.
  ///
  /// In fr, this message translates to:
  /// **'Les racines tiennent dans l\'eau, ou sur un support sans terre.'**
  String get careSoilNoneNote;

  /// No description provided for @carePropCuttingNote.
  ///
  /// In fr, this message translates to:
  /// **'Une tige coupée sous un nœud, plantée dans un substrat humide.'**
  String get carePropCuttingNote;

  /// No description provided for @carePropLeafNote.
  ///
  /// In fr, this message translates to:
  /// **'Une feuille entière, ou un fragment, posée sur le substrat.'**
  String get carePropLeafNote;

  /// No description provided for @carePropDivisionNote.
  ///
  /// In fr, this message translates to:
  /// **'La touffe se sépare en deux au rempotage, racines comprises.'**
  String get carePropDivisionNote;

  /// No description provided for @carePropOffsetsNote.
  ///
  /// In fr, this message translates to:
  /// **'Les jeunes pousses nées au pied se détachent une fois enracinées.'**
  String get carePropOffsetsNote;

  /// No description provided for @carePropLayeringNote.
  ///
  /// In fr, this message translates to:
  /// **'Une tige enracinée alors qu\'elle tient encore à la plante mère.'**
  String get carePropLayeringNote;

  /// No description provided for @carePropSeedNote.
  ///
  /// In fr, this message translates to:
  /// **'Des graines semées, plus lentes qu\'une bouture et souvent moins fidèles.'**
  String get carePropSeedNote;

  /// No description provided for @carePropWaterNote.
  ///
  /// In fr, this message translates to:
  /// **'La bouture patiente dans un verre d\'eau, le temps que les racines partent.'**
  String get carePropWaterNote;

  /// No description provided for @carePropTuberNote.
  ///
  /// In fr, this message translates to:
  /// **'Le tubercule se coupe en morceaux portant chacun un œil.'**
  String get carePropTuberNote;

  /// No description provided for @communityTipsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Conseils de la communauté'**
  String get communityTipsTitle;

  /// No description provided for @communityTipsHint.
  ///
  /// In fr, this message translates to:
  /// **'Ce que d\'autres personnes ont observé en gardant cette espèce, hors du catalogue.'**
  String get communityTipsHint;

  /// No description provided for @communityTipsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun conseil sur cette espèce.'**
  String get communityTipsEmpty;

  /// No description provided for @offlineCommunityTips.
  ///
  /// In fr, this message translates to:
  /// **'Lire et publier des conseils demande une connexion.'**
  String get offlineCommunityTips;

  /// No description provided for @communityTipWrite.
  ///
  /// In fr, this message translates to:
  /// **'Écrire un conseil'**
  String get communityTipWrite;

  /// No description provided for @communityTipYours.
  ///
  /// In fr, this message translates to:
  /// **'Votre conseil'**
  String get communityTipYours;

  /// No description provided for @communityTipPlaceholder.
  ///
  /// In fr, this message translates to:
  /// **'Ce qui a marché sur cette plante, en quelques phrases.'**
  String get communityTipPlaceholder;

  /// No description provided for @communityTipPublicNote.
  ///
  /// In fr, this message translates to:
  /// **'Le conseil paraît sous votre nom sur la fiche de cette espèce, pour tout le monde.'**
  String get communityTipPublicNote;

  /// No description provided for @communityTipLength.
  ///
  /// In fr, this message translates to:
  /// **'{used} / {max}'**
  String communityTipLength(int used, int max);

  /// No description provided for @communityTipPublish.
  ///
  /// In fr, this message translates to:
  /// **'Publier'**
  String get communityTipPublish;

  /// No description provided for @communityTipPublished.
  ///
  /// In fr, this message translates to:
  /// **'Conseil publié.'**
  String get communityTipPublished;

  /// No description provided for @communityTipNeedsAccount.
  ///
  /// In fr, this message translates to:
  /// **'Publier un conseil demande un compte.'**
  String get communityTipNeedsAccount;

  /// No description provided for @communityTipAnonymous.
  ///
  /// In fr, this message translates to:
  /// **'Anonyme'**
  String get communityTipAnonymous;

  /// No description provided for @communityTipHelpful.
  ///
  /// In fr, this message translates to:
  /// **'Utile'**
  String get communityTipHelpful;

  /// No description provided for @communityTipReport.
  ///
  /// In fr, this message translates to:
  /// **'Signaler'**
  String get communityTipReport;

  /// No description provided for @communityTipReported.
  ///
  /// In fr, this message translates to:
  /// **'Conseil signalé.'**
  String get communityTipReported;

  /// No description provided for @communityTipReportNote.
  ///
  /// In fr, this message translates to:
  /// **'Un conseil signalé par {count} personnes ne paraît plus.'**
  String communityTipReportNote(int count);

  /// No description provided for @communityTipHidden.
  ///
  /// In fr, this message translates to:
  /// **'Signalé : les autres ne le voient plus.'**
  String get communityTipHidden;

  /// No description provided for @confirmDeleteTip.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce conseil ?'**
  String get confirmDeleteTip;

  /// No description provided for @confirmReportTip.
  ///
  /// In fr, this message translates to:
  /// **'Signaler ce conseil ?'**
  String get confirmReportTip;

  /// No description provided for @moderationTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modération'**
  String get moderationTitle;

  /// No description provided for @moderationHint.
  ///
  /// In fr, this message translates to:
  /// **'Les conseils signalés, du plus signalé au moins signalé.'**
  String get moderationHint;

  /// No description provided for @moderationEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun conseil signalé.'**
  String get moderationEmpty;

  /// No description provided for @moderationReports.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 signalement} other{{count} signalements}}'**
  String moderationReports(int count);

  /// No description provided for @moderationHide.
  ///
  /// In fr, this message translates to:
  /// **'Masquer'**
  String get moderationHide;

  /// No description provided for @moderationRestore.
  ///
  /// In fr, this message translates to:
  /// **'Rétablir'**
  String get moderationRestore;

  /// No description provided for @confirmRestoreTip.
  ///
  /// In fr, this message translates to:
  /// **'Rétablir ce conseil ? Ses signalements sont effacés.'**
  String get confirmRestoreTip;

  /// No description provided for @roomScan.
  ///
  /// In fr, this message translates to:
  /// **'Relevé de la maison'**
  String get roomScan;

  /// No description provided for @roomScanHint.
  ///
  /// In fr, this message translates to:
  /// **'Une pièce relevée avec l\'appareil photo et le LiDAR donne ses murs, ses fenêtres et ses portes. La lumière de chaque place s\'en déduit, pour dire où poser une plante. Le relevé reste sur l\'appareil.'**
  String get roomScanHint;

  /// No description provided for @roomScanStart.
  ///
  /// In fr, this message translates to:
  /// **'Relever une pièce'**
  String get roomScanStart;

  /// No description provided for @roomScanRooms.
  ///
  /// In fr, this message translates to:
  /// **'Pièces relevées'**
  String get roomScanRooms;

  /// No description provided for @roomScanEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune pièce relevée'**
  String get roomScanEmptyTitle;

  /// No description provided for @roomScanEmptySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Le relevé prend une à deux minutes par pièce, en tournant lentement le long des murs.'**
  String get roomScanEmptySubtitle;

  /// No description provided for @roomScanNoLidar.
  ///
  /// In fr, this message translates to:
  /// **'Cet appareil n\'a pas de LiDAR : le relevé demande un iPhone Pro ou un iPad Pro.'**
  String get roomScanNoLidar;

  /// No description provided for @roomScanBeforeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Avant le relevé'**
  String get roomScanBeforeTitle;

  /// No description provided for @roomScanBeforeText.
  ///
  /// In fr, this message translates to:
  /// **'L\'appareil photo s\'ouvre sur le relevé du système. Tourner lentement le long des murs jusqu\'à ce que la pièce soit dessinée, puis terminer. Rien ne quitte l\'appareil.'**
  String get roomScanBeforeText;

  /// No description provided for @roomScanFailed.
  ///
  /// In fr, this message translates to:
  /// **'Le relevé n\'a pas abouti.'**
  String get roomScanFailed;

  /// No description provided for @roomScanDefaultName.
  ///
  /// In fr, this message translates to:
  /// **'Pièce'**
  String get roomScanDefaultName;

  /// No description provided for @roomScanArea.
  ///
  /// In fr, this message translates to:
  /// **'{area} m²'**
  String roomScanArea(String area);

  /// No description provided for @roomScanWindowsCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{aucune fenêtre} =1{une fenêtre} other{{count} fenêtres}}'**
  String roomScanWindowsCount(int count);

  /// No description provided for @roomScanName.
  ///
  /// In fr, this message translates to:
  /// **'Nom de la pièce'**
  String get roomScanName;

  /// No description provided for @roomScanLinkedLocation.
  ///
  /// In fr, this message translates to:
  /// **'Emplacement'**
  String get roomScanLinkedLocation;

  /// No description provided for @roomScanWindows.
  ///
  /// In fr, this message translates to:
  /// **'Fenêtres'**
  String get roomScanWindows;

  /// No description provided for @roomScanWindowN.
  ///
  /// In fr, this message translates to:
  /// **'Fenêtre {n}'**
  String roomScanWindowN(int n);

  /// No description provided for @roomScanWindowUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Orientation inconnue'**
  String get roomScanWindowUnknown;

  /// No description provided for @roomScanWindowFromCompass.
  ///
  /// In fr, this message translates to:
  /// **'D\'après la boussole'**
  String get roomScanWindowFromCompass;

  /// No description provided for @roomScanWindowConfirmed.
  ///
  /// In fr, this message translates to:
  /// **'Confirmée'**
  String get roomScanWindowConfirmed;

  /// No description provided for @roomScanOrientationHelp.
  ///
  /// In fr, this message translates to:
  /// **'La boussole a dix à quinze degrés d\'erreur. L\'orientation de chaque fenêtre se corrige ici.'**
  String get roomScanOrientationHelp;

  /// No description provided for @roomScanDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le relevé'**
  String get roomScanDelete;

  /// No description provided for @roomScanDeleteConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Le relevé et ses repères disparaissent de l\'appareil.'**
  String get roomScanDeleteConfirm;

  /// No description provided for @roomScanCapturedOn.
  ///
  /// In fr, this message translates to:
  /// **'Relevée le {date}'**
  String roomScanCapturedOn(String date);

  /// No description provided for @roomSectionBathroom.
  ///
  /// In fr, this message translates to:
  /// **'Salle de bain'**
  String get roomSectionBathroom;

  /// No description provided for @roomSectionBedroom.
  ///
  /// In fr, this message translates to:
  /// **'Chambre'**
  String get roomSectionBedroom;

  /// No description provided for @roomSectionDiningRoom.
  ///
  /// In fr, this message translates to:
  /// **'Salle à manger'**
  String get roomSectionDiningRoom;

  /// No description provided for @roomSectionKitchen.
  ///
  /// In fr, this message translates to:
  /// **'Cuisine'**
  String get roomSectionKitchen;

  /// No description provided for @roomSectionLaundryRoom.
  ///
  /// In fr, this message translates to:
  /// **'Buanderie'**
  String get roomSectionLaundryRoom;

  /// No description provided for @roomSectionLivingRoom.
  ///
  /// In fr, this message translates to:
  /// **'Salon'**
  String get roomSectionLivingRoom;

  /// No description provided for @directionNorth.
  ///
  /// In fr, this message translates to:
  /// **'nord'**
  String get directionNorth;

  /// No description provided for @directionNorthEast.
  ///
  /// In fr, this message translates to:
  /// **'nord-est'**
  String get directionNorthEast;

  /// No description provided for @directionEast.
  ///
  /// In fr, this message translates to:
  /// **'est'**
  String get directionEast;

  /// No description provided for @directionSouthEast.
  ///
  /// In fr, this message translates to:
  /// **'sud-est'**
  String get directionSouthEast;

  /// No description provided for @directionSouth.
  ///
  /// In fr, this message translates to:
  /// **'sud'**
  String get directionSouth;

  /// No description provided for @directionSouthWest.
  ///
  /// In fr, this message translates to:
  /// **'sud-ouest'**
  String get directionSouthWest;

  /// No description provided for @directionWest.
  ///
  /// In fr, this message translates to:
  /// **'ouest'**
  String get directionWest;

  /// No description provided for @directionNorthWest.
  ///
  /// In fr, this message translates to:
  /// **'nord-ouest'**
  String get directionNorthWest;

  /// No description provided for @placementTitle.
  ///
  /// In fr, this message translates to:
  /// **'Où la poser'**
  String get placementTitle;

  /// No description provided for @placementHint.
  ///
  /// In fr, this message translates to:
  /// **'Les places sont classées d\'après la lumière qu\'elles reçoivent, comparée à celle de la fiche.'**
  String get placementHint;

  /// No description provided for @placementRoomsCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{une pièce relevée} other{{count} pièces relevées}}'**
  String placementRoomsCount(int count);

  /// No description provided for @placementVerdictGood.
  ///
  /// In fr, this message translates to:
  /// **'Pièce adaptée.'**
  String get placementVerdictGood;

  /// No description provided for @placementVerdictAcceptable.
  ///
  /// In fr, this message translates to:
  /// **'Pièce acceptable, sans place idéale.'**
  String get placementVerdictAcceptable;

  /// No description provided for @placementVerdictUnsuitable.
  ///
  /// In fr, this message translates to:
  /// **'Pièce inadaptée.'**
  String get placementVerdictUnsuitable;

  /// No description provided for @placementShortfallTooDark.
  ///
  /// In fr, this message translates to:
  /// **'Trop sombre pour la lumière demandée.'**
  String get placementShortfallTooDark;

  /// No description provided for @placementShortfallTooBright.
  ///
  /// In fr, this message translates to:
  /// **'Trop de soleil direct.'**
  String get placementShortfallTooBright;

  /// No description provided for @placementShortfallDrafty.
  ///
  /// In fr, this message translates to:
  /// **'Chaque place est près d\'une porte : courants d\'air.'**
  String get placementShortfallDrafty;

  /// No description provided for @placementShortfallTooDry.
  ///
  /// In fr, this message translates to:
  /// **'Pièce d\'eau, air humide : la fiche demande l\'air sec.'**
  String get placementShortfallTooDry;

  /// No description provided for @placementGeneric.
  ///
  /// In fr, this message translates to:
  /// **'Fiche générique : sans espèce, la lumière demandée n\'est pas connue.'**
  String get placementGeneric;

  /// No description provided for @placementDistanceM.
  ///
  /// In fr, this message translates to:
  /// **'{m} m'**
  String placementDistanceM(String m);

  /// No description provided for @placementDistanceCm.
  ///
  /// In fr, this message translates to:
  /// **'{cm} cm'**
  String placementDistanceCm(int cm);

  /// No description provided for @placementNearWindow.
  ///
  /// In fr, this message translates to:
  /// **'à {distance} de la fenêtre {direction}'**
  String placementNearWindow(String distance, String direction);

  /// No description provided for @placementNearWindowUnknown.
  ///
  /// In fr, this message translates to:
  /// **'à {distance} de la fenêtre'**
  String placementNearWindowUnknown(String distance);

  /// No description provided for @placementOnTable.
  ///
  /// In fr, this message translates to:
  /// **'sur la table'**
  String get placementOnTable;

  /// No description provided for @placementOnStorage.
  ///
  /// In fr, this message translates to:
  /// **'sur le meuble'**
  String get placementOnStorage;

  /// No description provided for @placementOnSill.
  ///
  /// In fr, this message translates to:
  /// **'sur l\'appui de la fenêtre {direction}'**
  String placementOnSill(String direction);

  /// No description provided for @placementOnSillUnknown.
  ///
  /// In fr, this message translates to:
  /// **'sur l\'appui de la fenêtre'**
  String get placementOnSillUnknown;

  /// No description provided for @placementDeepInRoom.
  ///
  /// In fr, this message translates to:
  /// **'au fond, loin des fenêtres'**
  String get placementDeepInRoom;

  /// No description provided for @placementDraftyNote.
  ///
  /// In fr, this message translates to:
  /// **'Près d\'une porte : courant d\'air.'**
  String get placementDraftyNote;

  /// No description provided for @placementHumidRoomNote.
  ///
  /// In fr, this message translates to:
  /// **'Pièce d\'eau : air plus humide.'**
  String get placementHumidRoomNote;

  /// No description provided for @placementPlanSemantics.
  ///
  /// In fr, this message translates to:
  /// **'Plan de la pièce vu de dessus, {count} places retenues.'**
  String placementPlanSemantics(int count);

  /// No description provided for @roomScanHeaters.
  ///
  /// In fr, this message translates to:
  /// **'Radiateurs'**
  String get roomScanHeaters;

  /// No description provided for @roomScanHeatersHelp.
  ///
  /// In fr, this message translates to:
  /// **'Le relevé ne voit pas les radiateurs. Posé sur le plan, un radiateur compte comme air sec et chaud à moins de 80 cm.'**
  String get roomScanHeatersHelp;

  /// No description provided for @roomScanAddHeater.
  ///
  /// In fr, this message translates to:
  /// **'Poser un radiateur'**
  String get roomScanAddHeater;

  /// No description provided for @roomScanTapForHeater.
  ///
  /// In fr, this message translates to:
  /// **'Toucher le plan là où se trouve le radiateur.'**
  String get roomScanTapForHeater;

  /// No description provided for @roomScanHeatersCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{aucun radiateur} =1{un radiateur} other{{count} radiateurs}}'**
  String roomScanHeatersCount(int count);

  /// No description provided for @roomScanRemoveHeater.
  ///
  /// In fr, this message translates to:
  /// **'Retirer ce radiateur'**
  String get roomScanRemoveHeater;

  /// No description provided for @roomScanFillLocation.
  ///
  /// In fr, this message translates to:
  /// **'Renseigner l\'emplacement'**
  String get roomScanFillLocation;

  /// No description provided for @roomScanFillLocationDetail.
  ///
  /// In fr, this message translates to:
  /// **'Orientation {orientation}, lumière {light}, d\'après le relevé. Les champs déjà remplis ne changent pas.'**
  String roomScanFillLocationDetail(String orientation, String light);

  /// No description provided for @roomScanLocationFilled.
  ///
  /// In fr, this message translates to:
  /// **'Emplacement renseigné'**
  String get roomScanLocationFilled;

  /// No description provided for @roomScanWhoFitsHere.
  ///
  /// In fr, this message translates to:
  /// **'Le jardin dans cette pièce'**
  String get roomScanWhoFitsHere;

  /// No description provided for @roomScanWhoFitsHint.
  ///
  /// In fr, this message translates to:
  /// **'Chaque plante est notée d\'après la lumière de la pièce et sa fiche.'**
  String get roomScanWhoFitsHint;

  /// No description provided for @roomScanNoPlantsToRank.
  ///
  /// In fr, this message translates to:
  /// **'Aucune plante avec une espèce connue.'**
  String get roomScanNoPlantsToRank;

  /// No description provided for @placementShortfallHeater.
  ///
  /// In fr, this message translates to:
  /// **'Chaque place est près d\'un radiateur : air sec et chaud.'**
  String get placementShortfallHeater;

  /// No description provided for @placementHeaterNote.
  ///
  /// In fr, this message translates to:
  /// **'Près d\'un radiateur : air sec et chaud.'**
  String get placementHeaterNote;

  /// No description provided for @placementAtHome.
  ///
  /// In fr, this message translates to:
  /// **'Capteur de la pièce'**
  String get placementAtHome;

  /// No description provided for @roomScanStartStructure.
  ///
  /// In fr, this message translates to:
  /// **'Relever l\'appartement'**
  String get roomScanStartStructure;

  /// No description provided for @roomScanStructureHint.
  ///
  /// In fr, this message translates to:
  /// **'Relever l\'appartement enchaîne les pièces : « Pièce suivante » entre chaque, « Terminé » à la fin. Les pièces se placent les unes par rapport aux autres.'**
  String get roomScanStructureHint;

  /// No description provided for @roomScanNextRoom.
  ///
  /// In fr, this message translates to:
  /// **'Pièce suivante'**
  String get roomScanNextRoom;

  /// No description provided for @roomScanRoomNumber.
  ///
  /// In fr, this message translates to:
  /// **'Pièce {n}'**
  String roomScanRoomNumber(int n);

  /// No description provided for @roomScanPlantsOnPlan.
  ///
  /// In fr, this message translates to:
  /// **'Plantes sur le plan'**
  String get roomScanPlantsOnPlan;

  /// No description provided for @roomScanPlantsHelp.
  ///
  /// In fr, this message translates to:
  /// **'Une plante posée sur le plan est notée à sa place. La liste signale une place nettement meilleure.'**
  String get roomScanPlantsHelp;

  /// No description provided for @roomScanAddPlant.
  ///
  /// In fr, this message translates to:
  /// **'Poser une plante'**
  String get roomScanAddPlant;

  /// No description provided for @roomScanTapForPlant.
  ///
  /// In fr, this message translates to:
  /// **'Toucher le plan là où se trouve {plant}.'**
  String roomScanTapForPlant(String plant);

  /// No description provided for @roomScanRemovePlant.
  ///
  /// In fr, this message translates to:
  /// **'Retirer {plant} du plan'**
  String roomScanRemovePlant(String plant);

  /// No description provided for @roomScanNoPlantToPlace.
  ///
  /// In fr, this message translates to:
  /// **'Aucune plante à poser.'**
  String get roomScanNoPlantToPlace;

  /// No description provided for @roomScanPlantWellPlaced.
  ///
  /// In fr, this message translates to:
  /// **'Place adaptée · {light}'**
  String roomScanPlantWellPlaced(String light);

  /// No description provided for @roomScanPlantBetterAt.
  ///
  /// In fr, this message translates to:
  /// **'Place actuelle {light} · mieux {place}'**
  String roomScanPlantBetterAt(String light, String place);

  /// No description provided for @placementAllRooms.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les pièces'**
  String get placementAllRooms;

  /// No description provided for @placementChoose.
  ///
  /// In fr, this message translates to:
  /// **'Poser ici'**
  String get placementChoose;

  /// No description provided for @placementChosen.
  ///
  /// In fr, this message translates to:
  /// **'Posée {place}'**
  String placementChosen(String place);

  /// No description provided for @placementCurrent.
  ///
  /// In fr, this message translates to:
  /// **'Place actuelle : {place} · {light}'**
  String placementCurrent(String place, String light);

  /// No description provided for @sectionRooms.
  ///
  /// In fr, this message translates to:
  /// **'Relevés de la maison'**
  String get sectionRooms;

  /// No description provided for @roomScanCurtain.
  ///
  /// In fr, this message translates to:
  /// **'Rideau'**
  String get roomScanCurtain;

  /// No description provided for @roomScanCurtainNone.
  ///
  /// In fr, this message translates to:
  /// **'Sans rideau'**
  String get roomScanCurtainNone;

  /// No description provided for @roomScanCurtainSheer.
  ///
  /// In fr, this message translates to:
  /// **'Voilage'**
  String get roomScanCurtainSheer;

  /// No description provided for @roomScanCurtainDrawn.
  ///
  /// In fr, this message translates to:
  /// **'Rideau souvent tiré'**
  String get roomScanCurtainDrawn;

  /// No description provided for @roomScanCurtainHelp.
  ///
  /// In fr, this message translates to:
  /// **'Le relevé ne voit ni les voilages ni les rideaux. Un voilage divise la lumière par deux et ôte le soleil direct ; un rideau souvent tiré la divise par trois.'**
  String get roomScanCurtainHelp;

  /// No description provided for @roomScanPlace.
  ///
  /// In fr, this message translates to:
  /// **'Poser'**
  String get roomScanPlace;

  /// No description provided for @roomScanRoomsShort.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucune} =1{1 pièce} other{{count} pièces}}'**
  String roomScanRoomsShort(int count);

  /// No description provided for @roomScanThisRoom.
  ///
  /// In fr, this message translates to:
  /// **'Relever cette pièce'**
  String get roomScanThisRoom;

  /// No description provided for @roomScanThisRoomHint.
  ///
  /// In fr, this message translates to:
  /// **'Le plan de la pièce donne la lumière de chaque place, pour choisir où poser une plante.'**
  String get roomScanThisRoomHint;

  /// No description provided for @roomScanRoomPlan.
  ///
  /// In fr, this message translates to:
  /// **'Plan de la pièce'**
  String get roomScanRoomPlan;

  /// No description provided for @roomScanPlantsOnPlanCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{aucune plante sur le plan} =1{une plante sur le plan} other{{count} plantes sur le plan}}'**
  String roomScanPlantsOnPlanCount(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'fr', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
