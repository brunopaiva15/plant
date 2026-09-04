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
  /// **'Flora'**
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

  /// No description provided for @genericError.
  ///
  /// In fr, this message translates to:
  /// **'Quelque chose n\'a pas fonctionné. Réessayez.'**
  String get genericError;

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
  /// **'Vos plantes n\'ont besoin de rien aujourd\'hui.'**
  String get allDoneSubtitle;

  /// No description provided for @emptyGardenTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre jardin commence ici.'**
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
  /// **'Votre jardin commence ici.'**
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
  /// **'Une photo ?'**
  String get stepPhotoTitle;

  /// No description provided for @stepPhotoSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Elle deviendra le visage de votre plante.'**
  String get stepPhotoSubtitle;

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
  /// **'Comment s\'appelle-t-elle ?'**
  String get stepNameTitle;

  /// No description provided for @plantNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Monstera du salon'**
  String get plantNameHint;

  /// No description provided for @speciesHint.
  ///
  /// In fr, this message translates to:
  /// **'Espèce (facultatif)'**
  String get speciesHint;

  /// No description provided for @stepLocationTitle.
  ///
  /// In fr, this message translates to:
  /// **'Où se trouve-t-elle ?'**
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
  /// **'Tout ce qui vous semble utile…'**
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

  /// No description provided for @freeLimitTitle.
  ///
  /// In fr, this message translates to:
  /// **'Limite atteinte'**
  String get freeLimitTitle;

  /// No description provided for @freeLimitBody.
  ///
  /// In fr, this message translates to:
  /// **'L\'offre gratuite permet {count} plantes. Passez à Premium pour une collection illimitée.'**
  String freeLimitBody(int count);

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

  /// No description provided for @cuttings.
  ///
  /// In fr, this message translates to:
  /// **'Boutures'**
  String get cuttings;

  /// No description provided for @createCutting.
  ///
  /// In fr, this message translates to:
  /// **'Créer une bouture'**
  String get createCutting;

  /// No description provided for @cuttingOf.
  ///
  /// In fr, this message translates to:
  /// **'Bouture de {name}'**
  String cuttingOf(String name);

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
  /// **'Que s\'est-il passé ?'**
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
  /// **'Qu\'avez-vous fait ?'**
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
  /// **'Par défaut, Flora suit le réglage du système.'**
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
  /// **'Une seule notification par jour, uniquement quand une plante a besoin de vous.'**
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
  /// **'Vos plantes et photos restent privées, sur ce téléphone. Les comptes et la synchronisation arriveront dans une prochaine version.'**
  String get localAccountHint;

  /// No description provided for @about.
  ///
  /// In fr, this message translates to:
  /// **'À propos'**
  String get about;

  /// No description provided for @version.
  ///
  /// In fr, this message translates to:
  /// **'Version {version}'**
  String version(String version);

  /// No description provided for @premium.
  ///
  /// In fr, this message translates to:
  /// **'Premium'**
  String get premium;

  /// No description provided for @premiumBody.
  ///
  /// In fr, this message translates to:
  /// **'Plantes illimitées, identification, diagnostic, collaboration. Bientôt disponible.'**
  String get premiumBody;

  /// No description provided for @premiumPlantCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} / {limit} plantes'**
  String premiumPlantCount(int count, int limit);

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
  /// **'Votre jardin, simplement.'**
  String get onboardingTitle;

  /// No description provided for @onboardingSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Prenez soin de vos plantes et gardez leur histoire.'**
  String get onboardingSubtitle;

  /// No description provided for @askNameTitle.
  ///
  /// In fr, this message translates to:
  /// **'Comment vous appelez-vous ?'**
  String get askNameTitle;

  /// No description provided for @askNameSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Pour vous saluer chaque matin. Vous pourrez changer plus tard.'**
  String get askNameSubtitle;

  /// No description provided for @notificationAskTitle.
  ///
  /// In fr, this message translates to:
  /// **'Un rappel utile, chaque jour'**
  String get notificationAskTitle;

  /// No description provided for @notificationAskBody.
  ///
  /// In fr, this message translates to:
  /// **'Une seule notification par jour, à l\'heure que vous choisissez, seulement quand une plante en a besoin.'**
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
  /// **'{name} a probablement besoin d\'eau aujourd\'hui.'**
  String notifWaterOne(String name);

  /// No description provided for @notifWaterMany.
  ///
  /// In fr, this message translates to:
  /// **'{names} ont probablement besoin d\'eau aujourd\'hui.'**
  String notifWaterMany(String names);

  /// No description provided for @notifOther.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 autre soin vous attend.} other{{count} autres soins vous attendent.}}'**
  String notifOther(int count);

  /// No description provided for @notifOnlyOther.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 soin vous attend aujourd\'hui.} other{{count} soins vous attendent aujourd\'hui.}}'**
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
  /// **'Emplacements'**
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
  /// **'Engrais, terreaux, pots, outils : gardez l\'œil sur vos réserves.'**
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
  /// **'Collez-le sur le pot : le scanner ouvre directement la fiche.'**
  String get qrHint;

  /// No description provided for @scan.
  ///
  /// In fr, this message translates to:
  /// **'Scanner'**
  String get scan;

  /// No description provided for @scanHint.
  ///
  /// In fr, this message translates to:
  /// **'Visez le QR code d\'une plante.'**
  String get scanHint;

  /// No description provided for @unknownQr.
  ///
  /// In fr, this message translates to:
  /// **'Ce QR code n\'appartient pas à votre jardin.'**
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
  /// **'Est-ce bien…'**
  String get identifyTitle;

  /// No description provided for @identifyHint.
  ///
  /// In fr, this message translates to:
  /// **'Suggestions à confirmer, jamais des certitudes.'**
  String get identifyHint;

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
  /// **'Reconnaissance d\'espèce à partir d\'une photo, via le service Pl@ntNet. Créez une clé gratuite sur my.plantnet.org et collez-la ici.'**
  String get identificationHint;

  /// No description provided for @apiKey.
  ///
  /// In fr, this message translates to:
  /// **'Clé API'**
  String get apiKey;

  /// No description provided for @apiKeyHint.
  ///
  /// In fr, this message translates to:
  /// **'Collez votre clé'**
  String get apiKeyHint;

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
  /// **'Balcon, jardin, serre : la météo compte.'**
  String get outdoorHint;

  /// No description provided for @weather.
  ///
  /// In fr, this message translates to:
  /// **'Météo'**
  String get weather;

  /// No description provided for @weatherHint.
  ///
  /// In fr, this message translates to:
  /// **'Pour vos plantes dehors, Flora regarde la pluie du jour et vous évite un arrosage inutile. Données Open-Meteo, sans compte ni clé.'**
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

  /// No description provided for @weatherRainSkip.
  ///
  /// In fr, this message translates to:
  /// **'Pluie prévue : pas besoin d\'arroser {names} aujourd\'hui.'**
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
  /// **'Un fichier ZIP avec vos plantes, historiques, inventaire, réglages et photos. Vos données vous appartiennent.'**
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
  /// **'Il ne vous reste presque plus de {name}.'**
  String notifLowStockOne(String name);

  /// No description provided for @notifLowStockMany.
  ///
  /// In fr, this message translates to:
  /// **'{count} articles sont presque épuisés.'**
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

  /// No description provided for @signInHint.
  ///
  /// In fr, this message translates to:
  /// **'Un compte sauvegarde vos plantes, les synchronise entre vos appareils et permet de partager un jardin. Sans compte, tout reste sur ce téléphone.'**
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

  /// No description provided for @continueWithEmail.
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec un e-mail'**
  String get continueWithEmail;

  /// No description provided for @emailHint.
  ///
  /// In fr, this message translates to:
  /// **'vous@exemple.ch'**
  String get emailHint;

  /// No description provided for @sendCode.
  ///
  /// In fr, this message translates to:
  /// **'Recevoir un code'**
  String get sendCode;

  /// No description provided for @codeSent.
  ///
  /// In fr, this message translates to:
  /// **'Code envoyé à {email}.'**
  String codeSent(String email);

  /// No description provided for @codeHint.
  ///
  /// In fr, this message translates to:
  /// **'Code à 6 chiffres'**
  String get codeHint;

  /// No description provided for @verifyCode.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get verifyCode;

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

  /// No description provided for @syncSyncing.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisation…'**
  String get syncSyncing;

  /// No description provided for @authError.
  ///
  /// In fr, this message translates to:
  /// **'Connexion impossible. Vérifiez l\'adresse et réessayez.'**
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
  /// **'L\'invité doit déjà avoir un compte Flora avec cette adresse.'**
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
  /// **'Impossible d\'inviter : cette adresse n\'a pas encore de compte.'**
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
