// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Auxine';

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
  String get openSettings => 'Ouvrir les Réglages';

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
  String get soon => 'Bientôt';

  @override
  String get genericError => 'Une erreur est survenue. Réessayez.';

  @override
  String get offlineTitle => 'Hors ligne';

  @override
  String get offlineHint =>
      'Cette fonction demande une connexion. Les données déjà sur l\'appareil restent lisibles.';

  @override
  String get offlineActionFailed =>
      'Hors ligne. Réessayez une fois le réseau revenu.';

  @override
  String get offlineSharing =>
      'Créer, révoquer et lister des liens demande une connexion.';

  @override
  String get offlineCollaboration =>
      'Inviter, rejoindre un jardin et changer un rôle demande une connexion.';

  @override
  String get offlineDiagnosis => 'L\'analyse demande une connexion.';

  @override
  String get offlineIdentification =>
      'La recherche en ligne demande une connexion. La reconnaissance sur l\'appareil, non.';

  @override
  String get offlineSupport => 'L\'achat demande une connexion.';

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
  String greetingEvening(String name) {
    return 'Bonsoir $name';
  }

  @override
  String get greetingEveningAnonymous => 'Bonsoir';

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
  String get allDoneSubtitle => 'Aucun soin prévu aujourd\'hui.';

  @override
  String get emptyGardenTitle => 'Aucune plante';

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
  String get sortEdited => 'Modification récente';

  @override
  String get sortLastWatered => 'Dernier arrosage';

  @override
  String get sortLastFertilized => 'Dernier engrais';

  @override
  String get sortLastRepotted => 'Dernier rempotage';

  @override
  String get sortAcquired => 'Acquisition';

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
  String get showAsGrid => 'Afficher en grille';

  @override
  String get showAsList => 'Afficher en liste';

  @override
  String get noResultsTitle => 'Aucun résultat';

  @override
  String get noResultsSubtitle => 'Essayez un autre mot.';

  @override
  String get emptyPlantsTitle => 'Aucune plante';

  @override
  String get emptyPlantsSubtitle => 'Ajoutez votre première plante.';

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
  String get stepPhotoTitle => 'Photo';

  @override
  String get stepPhotoSubtitle =>
      'Cadrez la plante en entier, à la lumière du jour.';

  @override
  String get stepPhotoSubtitleCutting =>
      'Cadrez la bouture en entier, à la lumière du jour.';

  @override
  String get takePhoto => 'Prendre une photo';

  @override
  String get choosePhoto => 'Choisir une photo';

  @override
  String get withoutPhoto => 'Continuer sans photo';

  @override
  String get changePhoto => 'Changer';

  @override
  String get stepNameTitle => 'Nom';

  @override
  String get plantNameHint => 'Nom de la plante';

  @override
  String get speciesHint => 'Espèce (facultatif)';

  @override
  String get stepLocationTitle => 'Emplacement';

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
  String get notesHint => 'Exposition, rempotage, remarques…';

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
  String get offspring => 'Plantes filles';

  @override
  String get editSchedule => 'Modifier le planning';

  @override
  String cuttingOf(String name) {
    return 'Bouture de $name';
  }

  @override
  String get propagate => 'Créer une bouture';

  @override
  String get pgPickTitle => 'Multiplier cette plante';

  @override
  String get pgPickBody =>
      'Cette plante se multiplie de plusieurs façons. Le geste choisi décide des étapes.';

  @override
  String get pgRecommended => 'Conseillée';

  @override
  String pgIntroTitle(String name, String species) {
    return '$name de $species';
  }

  @override
  String pgIntroBody(int count) {
    return '$count étapes. Chacune est montrée en geste, puis dite en une phrase, adaptée à l’espèce quand elle est connue.';
  }

  @override
  String get pgStartCutting => 'Créer la bouture';

  @override
  String get pgStartPlant => 'Créer la plante';

  @override
  String get pgNoteSpot => 'À repérer';

  @override
  String get pgNoteAvoid => 'À éviter';

  @override
  String get pgNoteUsual => 'En général';

  @override
  String get pgNoteMedium => 'Enracinement';

  @override
  String get pgMediumWater => 'Dans l’eau';

  @override
  String get pgMediumSubstrate => 'En substrat léger';

  @override
  String get pgMediumEither => 'Eau ou substrat léger';

  @override
  String get pgVineName => 'Bouture de tige';

  @override
  String get pgVineHint => 'Un nœud, une coupe nette, l’eau';

  @override
  String get pgVineNodeTitle => 'Le nœud';

  @override
  String get pgVineNodeBody =>
      'Le renflement d’où part une feuille, souvent doublé d’une racine aérienne. La bouture en garde au moins un.';

  @override
  String get pgVineNodeNote => 'Nœud et racine aérienne';

  @override
  String get pgVineCutTitle => 'La coupe';

  @override
  String get pgVineCutBody =>
      'Lame propre, coupe nette à un centimètre sous le nœud. Le nœud reste du côté de la bouture.';

  @override
  String get pgVineCutNote => 'Couper au-dessus du nœud';

  @override
  String get pgVineClearTitle => 'Le nœud dégagé';

  @override
  String get pgVineClearBody =>
      'Les feuilles qui tremperaient sont retirées. Deux ou trois feuilles en haut nourrissent la bouture.';

  @override
  String get pgVineWaterTitle => 'L’eau';

  @override
  String get pgVineWaterBody =>
      'Le nœud sous la surface, les feuilles au-dessus. Lumière vive, sans soleil direct.';

  @override
  String get pgVineRootsTitle => 'Les racines';

  @override
  String get pgVineRootsBody =>
      'Elles sortent du nœud, pas du bas de la tige. L’eau se change chaque semaine.';

  @override
  String get pgVineRootsNote => 'Premières racines en deux à six semaines';

  @override
  String get pgVinePotTitle => 'Le pot';

  @override
  String get pgVinePotBody =>
      'À quelques centimètres de racines, la bouture passe en terreau léger. Le nœud reste à fleur de terre.';

  @override
  String get pgSoftName => 'Bouture de tige tendre';

  @override
  String get pgSoftHint => 'Un jeune brin, des racines rapides';

  @override
  String get pgSoftStemTitle => 'Le brin';

  @override
  String get pgSoftStemBody =>
      'Un jeune brin ferme, sans fleur, de dix centimètres environ. Le vieux bois s’enracine mal.';

  @override
  String get pgSoftCutTitle => 'La coupe';

  @override
  String get pgSoftCutBody =>
      'Lame propre, coupe juste sous une paire de feuilles. Les racines partiront de là.';

  @override
  String get pgSoftStripTitle => 'Les feuilles du bas';

  @override
  String get pgSoftStripBody =>
      'La paire du bas est retirée : la tige reste nue sur trois ou quatre centimètres.';

  @override
  String get pgSoftStripNote => 'Laisser une feuille sous l’eau';

  @override
  String get pgSoftRootTitle => 'L’enracinement';

  @override
  String get pgSoftRootBody =>
      'La tige nue trempe, les feuilles restent au sec. Lumière vive, sans soleil direct.';

  @override
  String get pgSoftRootsTitle => 'Les racines';

  @override
  String get pgSoftRootsBody =>
      'Fines et nombreuses, elles partent de toute la partie immergée.';

  @override
  String get pgSoftRootsNote => 'Premières racines en une à trois semaines';

  @override
  String get pgSoftPotTitle => 'Le repiquage';

  @override
  String get pgSoftPotBody =>
      'Repiquée tôt, à deux ou trois centimètres de racines : une tige tendre attend mal.';

  @override
  String get pgLeafName => 'Bouture de feuille';

  @override
  String get pgLeafHint => 'Plus lente, une feuille suffit';

  @override
  String get pgLeafChooseTitle => 'La feuille';

  @override
  String get pgLeafChooseBody =>
      'Une feuille mature, ferme, sans marque. Les jeunes feuilles manquent de réserves.';

  @override
  String get pgLeafCutTitle => 'La coupe';

  @override
  String get pgLeafCutBody =>
      'Lame propre, coupe à la base de la feuille, au ras du substrat.';

  @override
  String get pgLeafSplitTitle => 'Les segments';

  @override
  String get pgLeafSplitBody =>
      'La feuille se partage en morceaux de cinq à huit centimètres. Un V taillé en bas de chacun dit quel bout va en terre.';

  @override
  String get pgLeafSplitNote => 'Le V marque le bas';

  @override
  String get pgLeafCallusTitle => 'Le séchage';

  @override
  String get pgLeafCallusBody =>
      'Les coupes sèchent à l’air, à l’ombre, avant d’aller en terre.';

  @override
  String get pgLeafCallusNote => 'Un à deux jours de séchage';

  @override
  String get pgLeafPlantTitle => 'Le substrat';

  @override
  String get pgLeafPlantBody =>
      'Le V s’enfonce de deux centimètres dans un substrat drainant.';

  @override
  String get pgLeafPlantNote => 'Planter un segment à l’envers';

  @override
  String get pgLeafGrowthTitle => 'La reprise';

  @override
  String get pgLeafGrowthBody =>
      'Les racines viennent d’abord, la jeune pousse sort du substrat à côté du segment.';

  @override
  String get pgLeafGrowthNote => 'Nouvelle pousse en deux à quatre mois';

  @override
  String get pgDivisionName => 'Division';

  @override
  String get pgDivisionHint => 'Rapide et sûre, la touffe se partage';

  @override
  String get pgDivPlantTitle => 'La touffe';

  @override
  String get pgDivPlantBody =>
      'La plante se sort du pot en entier. Un substrat arrosé la veille tient mieux.';

  @override
  String get pgDivUnpotTitle => 'Le dépotage';

  @override
  String get pgDivUnpotBody =>
      'Le pot glisse le long de la motte, la plante est libre.';

  @override
  String get pgDivRootsTitle => 'La motte';

  @override
  String get pgDivRootsBody =>
      'La terre s’émiette jusqu’à voir les racines et le pied des pousses.';

  @override
  String get pgDivClustersTitle => 'Les deux groupes';

  @override
  String get pgDivClustersBody =>
      'Chaque groupe garde ses pousses et ses racines.';

  @override
  String get pgDivClustersNote => 'Feuilles et racines de chaque côté';

  @override
  String get pgDivSplitTitle => 'La séparation';

  @override
  String get pgDivSplitBody =>
      'Les groupes se défont à la main. La lame ne sert que si les couronnes tiennent.';

  @override
  String get pgDivSplitNote => 'Couper une tige au-dessus de la terre';

  @override
  String get pgDivRepotTitle => 'Le rempotage';

  @override
  String get pgDivRepotBody =>
      'Chaque division part dans son pot, à la même profondeur qu’avant, et reçoit un premier arrosage.';

  @override
  String get pgOffsetName => 'Séparer un rejet';

  @override
  String get pgOffsetHint => 'Le rejet part avec ses racines';

  @override
  String get pgOffSpotTitle => 'Le rejet';

  @override
  String get pgOffSpotBody =>
      'Un rejet du tiers de la mère, avec ses propres feuilles, est prêt à partir.';

  @override
  String get pgOffSpotNote => 'Rejet déjà formé';

  @override
  String get pgOffClearTitle => 'Le dégagement';

  @override
  String get pgOffClearBody =>
      'Le substrat s’écarte autour du pied : le lien avec la plante mère paraît.';

  @override
  String get pgOffDetachTitle => 'La séparation';

  @override
  String get pgOffDetachBody =>
      'Le rejet se détache du lien, avec ses racines. La lame ne sert que si le lien est ligneux.';

  @override
  String get pgOffDetachNote => 'Arracher le rejet sans racines';

  @override
  String get pgOffRootsTitle => 'Les racines';

  @override
  String get pgOffRootsBody =>
      'Quelques racines propres suffisent. Sans elles, le rejet sèche avant de reprendre.';

  @override
  String get pgOffPotTitle => 'Le pot';

  @override
  String get pgOffPotBody =>
      'Un petit pot, le substrat de l’espèce, et un arrosage léger.';

  @override
  String get pgOffSettleTitle => 'La reprise';

  @override
  String get pgOffSettleBody =>
      'Une feuille neuve au cœur dit que le rejet a pris.';

  @override
  String get pgOffSettleNote => 'Reprise en trois à six semaines';

  @override
  String get pgKeikiName => 'Séparer un keiki';

  @override
  String get pgKeikiHint => 'Le rejet d’orchidée part avec ses racines';

  @override
  String get pgKeikiSpotTitle => 'Le keiki';

  @override
  String get pgKeikiSpotBody =>
      'Un jeune plant naît sur un nœud de la hampe : deux feuilles et des racines aériennes le rendent identifiable.';

  @override
  String get pgKeikiSpotNote => 'Rejet déjà formé';

  @override
  String get pgKeikiWaitTitle => 'Les racines';

  @override
  String get pgKeikiWaitBody =>
      'Les racines s’allongent sur la hampe. Trois à cinq, longues de quelques centimètres, et le keiki vivra seul.';

  @override
  String get pgKeikiWaitNote => 'Racines prêtes en deux à trois mois';

  @override
  String get pgKeikiDetachTitle => 'La séparation';

  @override
  String get pgKeikiDetachBody =>
      'La hampe se coupe de part et d’autre du keiki, à un ou deux centimètres. Tirer meurtrissait la base.';

  @override
  String get pgKeikiDetachNote => 'Arracher le keiki';

  @override
  String get pgKeikiRootsTitle => 'Les racines du keiki';

  @override
  String get pgKeikiRootsBody =>
      'Le keiki garde ses racines aériennes : ce sont elles qui reprennent dans le pot.';

  @override
  String get pgKeikiPotTitle => 'Le pot';

  @override
  String get pgKeikiPotBody =>
      'Un petit pot d’écorces, la base du keiki affleurant le substrat, sans l’enterrer.';

  @override
  String get pgKeikiSettleTitle => 'La reprise';

  @override
  String get pgKeikiSettleBody =>
      'Une feuille neuve au cœur dit que le keiki a pris.';

  @override
  String get pgKeikiSettleNote => 'Reprise en un à deux mois';

  @override
  String get pgSegmentName => 'Bouture de segment';

  @override
  String get pgSegmentHint => 'Un segment détaché, séché, planté';

  @override
  String get pgSegChooseTitle => 'Le segment';

  @override
  String get pgSegChooseBody =>
      'Un segment terminal ferme et sans ride, de deux ou trois articles.';

  @override
  String get pgSegDetachTitle => 'Le détachement';

  @override
  String get pgSegDetachBody =>
      'Le segment se détache à l’articulation, en le tournant. Une lame propre si l’article résiste.';

  @override
  String get pgSegDetachNote => 'Tirer et déchirer l’article';

  @override
  String get pgSegWoundTitle => 'La plaie';

  @override
  String get pgSegWoundBody =>
      'La coupe est claire et humide. Mise en terre tout de suite, elle pourrit.';

  @override
  String get pgSegCallusTitle => 'La cicatrisation';

  @override
  String get pgSegCallusBody =>
      'La plaie sèche à l’air, à l’ombre, jusqu’à former un cal mat.';

  @override
  String get pgSegCallusNote => 'Trois à sept jours de séchage';

  @override
  String get pgSegPlantTitle => 'Le substrat';

  @override
  String get pgSegPlantBody =>
      'Le cal se pose à peine dans un substrat très drainant, sur un centimètre.';

  @override
  String get pgSegPlantNote => 'Enterrer le segment';

  @override
  String get pgSegRootsTitle => 'La reprise';

  @override
  String get pgSegRootsBody =>
      'Les racines viennent d’abord, un nouvel article ensuite. L’arrosage attend que les racines tiennent.';

  @override
  String get parentPlant => 'Plante mère';

  @override
  String get schedule => 'Planning';

  @override
  String get editPlant => 'Modifier la plante';

  @override
  String get archivePlant => 'Archiver la plante';

  @override
  String get archiveReasonTitle => 'Motif';

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
  String get healthIssue => 'Problème';

  @override
  String get issueOverwatering => 'Excès d\'eau';

  @override
  String get issueUnderwatering => 'Manque d\'eau';

  @override
  String get issuePests => 'Ravageurs';

  @override
  String get issueDisease => 'Maladie';

  @override
  String get issueRootRot => 'Pourriture des racines';

  @override
  String get issueTransplantShock => 'Choc de rempotage';

  @override
  String get issueDeficiency => 'Carence';

  @override
  String get issueSunburn => 'Brûlure du soleil';

  @override
  String get issueFrost => 'Gel';

  @override
  String get needsSection => 'Besoins';

  @override
  String get detailsSection => 'Détails';

  @override
  String get lifespan => 'Cycle de vie';

  @override
  String get lifespanAnnual => 'Annuelle';

  @override
  String get lifespanBiennial => 'Bisannuelle';

  @override
  String get lifespanPerennial => 'Vivace';

  @override
  String get hardiness => 'Rusticité';

  @override
  String get hardinessHardy => 'Rustique';

  @override
  String get hardinessTender => 'Gélive';

  @override
  String get cuttingMonth => 'Mois de bouturage';

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
  String get strategyFixedHint => 'Le même intervalle toute l\'année.';

  @override
  String get enabled => 'Activée';

  @override
  String get interval => 'Intervalle';

  @override
  String get intervalSuggested => 'Intervalle conseillé';

  @override
  String intervalSuggestedDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Intervalle conseillé : $count jours',
      one: 'Intervalle conseillé : 1 jour',
    );
    return '$_temp0';
  }

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
  String get whatDidYouDo => 'Action';

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
      'Par défaut, le réglage du système s\'applique.';

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
      'Une notification par jour, seulement si un soin est prévu.';

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
  String get localAccountHint => 'Vos données restent sur ce téléphone.';

  @override
  String version(String version) {
    return 'Version $version';
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
  String get onboardingTitle => 'Toutes vos plantes, ici';

  @override
  String get onboardingSubtitle => 'Ajoutez-les avec ou sans photo.';

  @override
  String get onbPlaceTitle => 'Votre ville';

  @override
  String get onbPlaceBody =>
      'Pour la météo et l\'arrosage en extérieur. Une ville suffit, la position exacte n\'est pas conservée.';

  @override
  String get useMyLocation => 'Utiliser ma position';

  @override
  String get locating => 'Recherche de votre ville…';

  @override
  String get locationFailed =>
      'Position indisponible. Vous pourrez choisir une ville dans Profil › Météo.';

  @override
  String get locationUnavailable => 'Position indisponible.';

  @override
  String get onbHomeTitle => 'Votre intérieur';

  @override
  String get onbHomeBody =>
      'Les capteurs d\'Apple Maison et de Google Home donnent la température et l\'humidité de la pièce. Les conseils et les diagnostics des plantes d\'intérieur en tiennent compte. La mesure ne quitte pas l\'application.';

  @override
  String get homeClimate => 'Capteurs de la maison';

  @override
  String get homeClimateHint =>
      'La température et l\'humidité d\'un capteur de la maison ajustent les conseils des plantes d\'intérieur et complètent les diagnostics. La mesure ne quitte pas l\'application.';

  @override
  String get homeClimateApple => 'Apple Maison';

  @override
  String get homeClimateGoogle => 'Google Home';

  @override
  String get homeClimateConnect => 'Connecter la maison';

  @override
  String get homeClimateConnectApple => 'Connecter Apple Maison';

  @override
  String get homeClimateConnectGoogle => 'Connecter Google Home';

  @override
  String get homeClimateSearching => 'Recherche des capteurs…';

  @override
  String get homeClimateSensor => 'Capteur';

  @override
  String get homeClimateSensors => 'Capteurs trouvés';

  @override
  String get homeClimateChoose => 'Choisir un capteur';

  @override
  String get homeClimateChange => 'Changer de capteur';

  @override
  String get homeClimateHome => 'Maison';

  @override
  String get homeClimateSource => 'Plateforme';

  @override
  String get homeClimateNoRoom => 'Sans pièce';

  @override
  String get homeClimateTemperatureSensor => 'Capteur de température';

  @override
  String get homeClimateHumiditySensor => 'Capteur d\'humidité';

  @override
  String get homeClimateSameSensor => 'Même capteur';

  @override
  String get homeClimateHumidityMissing =>
      'Humidité non reçue de ce capteur. Un autre se choisit dans la ligne Humidité.';

  @override
  String get homeClimateNone => 'Aucun capteur';

  @override
  String get homeClimateRemove => 'Retirer le capteur';

  @override
  String get homeClimateReading => 'Mesure';

  @override
  String get homeClimateUnavailable => 'Capteur injoignable pour l\'instant.';

  @override
  String homeClimateUpdatedAgo(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'Il y a $minutes min',
      one: 'Il y a 1 min',
      zero: 'À l\'instant',
    );
    return '$_temp0';
  }

  @override
  String homeClimateNoSensorsIn(String home) {
    return 'Aucun capteur de température ou d\'humidité dans $home.';
  }

  @override
  String get homeClimateDeniedApple =>
      'Accès à Apple Maison refusé. Il se rouvre dans Réglages › Confidentialité › Maison.';

  @override
  String get homeClimateDeniedGoogle =>
      'Accès à Google Home refusé. Il se rouvre dans l\'application Google Home, aux autorisations.';

  @override
  String homeClimateFailedIn(String home) {
    return '$home indisponible. Vous pourrez connecter un capteur dans Profil › Capteurs de la maison.';
  }

  @override
  String get homeClimateAppleNote =>
      'Apple Maison lit les accessoires sur l\'appareil.';

  @override
  String get homeClimateGoogleNote =>
      'Google Home lit les appareils via votre compte Google.';

  @override
  String get homeClimateDisconnect => 'Déconnecter';

  @override
  String get homeClimateDisconnectGoogle => 'Déconnecter Google Home';

  @override
  String get homeClimateDisconnectGoogleHint =>
      'Les capteurs de Google Home sont oubliés sur cet appareil. L\'autorisation accordée reste dans le compte Google, et se retire depuis ce compte.';

  @override
  String get homeClimateDisconnectedGoogle => 'Google Home déconnecté.';

  @override
  String get homeClimateGoogleAccess => 'Autorisations du compte Google';

  @override
  String get homeClimateAtHome => 'Chez vous';

  @override
  String get homeClimateFits => 'Rien qui gêne cette espèce.';

  @override
  String get homeClimateTooDry => 'Air trop sec pour cette espèce.';

  @override
  String get homeClimateTooHumid => 'Air trop humide pour cette espèce.';

  @override
  String get homeClimateTooCold => 'Trop froid pour cette espèce.';

  @override
  String get homeClimateTooHot => 'Trop chaud pour cette espèce.';

  @override
  String homeTipDryAir(String names) {
    return 'Air sec : brumiser ou regrouper $names.';
  }

  @override
  String get homeTipHumidAir => 'Air humide : aérer la pièce.';

  @override
  String homeTipHumidAirPlants(String names) {
    return 'Air humide : aérer, et laisser sécher $names entre deux arrosages.';
  }

  @override
  String homeTipCold(String names) {
    return 'Trop froid pour $names.';
  }

  @override
  String homeTipHot(String names) {
    return 'Chaleur : $names sèchent plus vite, vérifier la terre.';
  }

  @override
  String diagnosisWithHome(String reading) {
    return 'Mesure de la maison jointe : $reading.';
  }

  @override
  String placeChosen(String place) {
    return 'Météo réglée sur $place.';
  }

  @override
  String get askNameTitle => 'Votre prénom';

  @override
  String get askNameSubtitle => 'Modifiable plus tard dans le profil.';

  @override
  String get onbAccountTitle => 'Sauvegarde et partage';

  @override
  String get onbAccountBody =>
      'Un compte sauvegarde vos données et permet de partager un jardin. Connexion avec votre identifiant Apple.';

  @override
  String get notificationAskTitle => 'Rappel quotidien';

  @override
  String get notificationAskBody =>
      'Une notification par jour, à l\'heure choisie, seulement si un soin est prévu.';

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
    return '$name : arrosage prévu aujourd\'hui.';
  }

  @override
  String notifWaterMany(String names) {
    return '$names : arrosage prévu aujourd\'hui.';
  }

  @override
  String notifOther(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count autres soins prévus.',
      one: '1 autre soin prévu.',
    );
    return '$_temp0';
  }

  @override
  String notifOnlyOther(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count soins prévus aujourd\'hui.',
      one: '1 soin prévu aujourd\'hui.',
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
  String get fertForm => 'Forme';

  @override
  String get fertFormLiquid => 'Liquide';

  @override
  String get fertFormGranules => 'Granulés';

  @override
  String get fertFormSticks => 'Bâtonnets';

  @override
  String get fertFormSolublePowder => 'Poudre soluble';

  @override
  String get fertFormFoliar => 'Foliaire';

  @override
  String get fertFormOther => 'Autre';

  @override
  String get fertOrigin => 'Origine';

  @override
  String get fertOriginMineral => 'Minéral';

  @override
  String get fertOriginOrganic => 'Organique';

  @override
  String get fertOriginOrganomineral => 'Organo-minéral';

  @override
  String get fertNpk => 'NPK';

  @override
  String get fertNpkPercent => 'NPK (%)';

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
  String get noInventorySubtitle => 'Engrais, terreaux, pots, outils…';

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
  String get qrHint => 'Scanné, ce code ouvre la fiche de la plante.';

  @override
  String get scan => 'Scanner';

  @override
  String get quickActionScan => 'Scanner une étiquette';

  @override
  String get scanHint => 'Visez le QR code d\'une plante.';

  @override
  String get unknownQr => 'QR code inconnu.';

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
  String get identifyTitle => 'Espèce';

  @override
  String get identifyHint => 'Suggestions d\'espèce, à confirmer';

  @override
  String get searchOnline => 'Chercher en ligne';

  @override
  String get identifyAnotherPhoto => 'Ajouter une photo';

  @override
  String get identifyAnotherPhotoHint =>
      'Une feuille, une fleur ou la plante entière permet d\'affiner.';

  @override
  String get identificationUncertainTitle => 'Identification incertaine';

  @override
  String get identificationUncertainBody =>
      'Même avec les photos disponibles, aucune espèce ne ressort assez nettement. Vous pouvez chercher en ligne ou choisir manuellement si vous reconnaissez la plante.';

  @override
  String get identificationSuggestionsToCheck => 'Suggestions à vérifier';

  @override
  String get identifyConfirmWithPhoto => 'Confirmer avec une photo';

  @override
  String get searchingOnline => 'Recherche en ligne…';

  @override
  String get suggestionsLocal =>
      'Résultats Iris sur votre appareil · photo non envoyée';

  @override
  String get suggestionsRemote => 'Proposé en ligne par Pl@ntNet';

  @override
  String identifyOnDevice(String name) {
    return 'Reconnu par $name sur l\'appareil. Choisissez l\'espèce';
  }

  @override
  String get identifyViaPlantNet =>
      'Reconnu en ligne par Pl@ntNet. Choisissez l\'espèce';

  @override
  String get identifyPhotoSource =>
      'Photos Pl@ntNet et GBIF. Touchez-en une pour ouvrir la fiche de l\'espèce.';

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
  String identificationHint(String name) {
    return 'Reconnaissance des espèces sur l\'appareil par $name, sans réseau. En cas de doute, la photo peut être envoyée à Pl@ntNet.';
  }

  @override
  String get identificationEnabled => 'Identification activée';

  @override
  String get identificationDisabled => 'Non configurée';

  @override
  String get identificationFallback => 'Repli en ligne';

  @override
  String identificationFallbackHint(String name) {
    return 'En cas de doute de $name, la photo est envoyée à Pl@ntNet. Désactivé, tout reste sur l\'appareil.';
  }

  @override
  String get irisFeedback => 'Envoi des photos identifiées';

  @override
  String irisFeedbackHint(String name) {
    return 'Les photos prises pour identifier et le nom retenu sont envoyés dès qu\'une plante est nommée, et entraînent les prochaines versions du modèle $name. Elles ne sont lisibles que par le compte qui les envoie, et sa suppression les efface. Désactivé, elles ne quittent pas l\'appareil.';
  }

  @override
  String get irisFeedbackNeedsAccount =>
      'Il faut un compte pour envoyer des photos.';

  @override
  String get irisFeedbackAskTitle => 'Envoi des photos identifiées';

  @override
  String irisFeedbackAskBody(String name) {
    return 'Les photos prises pour identifier et le nom retenu peuvent être envoyés pour entraîner les prochaines versions du modèle $name. Elles ne sont lisibles que par le compte qui les envoie, et sa suppression les efface. Le choix se change dans les réglages d\'identification.';
  }

  @override
  String get genusUncertainSpecies => 'Espèce incertaine';

  @override
  String modelMissing(String name) {
    return '$name indisponible sur cet appareil';
  }

  @override
  String get modelLoading => 'Chargement du modèle…';

  @override
  String identificationStats(int local, int accepted, int remote) {
    return '$local analysées sur l’appareil, dont $accepted tranchées ici ; $remote envoyées en ligne';
  }

  @override
  String onlineSearchesMonth(int used, int limit) {
    return '$used recherches en ligne sur $limit ce mois-ci.';
  }

  @override
  String get irisSection => 'Le modèle embarqué';

  @override
  String get irisTagline =>
      'Reconnaissance des espèces sur le téléphone, sans réseau ni compte.';

  @override
  String get irisSpeciesLabel => 'espèces';

  @override
  String get irisOfflineValue => 'hors ligne';

  @override
  String get irisOfflineLabel => 'même en avion';

  @override
  String get irisTwoPhotosTitle => 'Deux photos valent mieux qu’une';

  @override
  String irisTwoPhotosBody(String name) {
    return 'La plante entière, puis une feuille de près. Avec deux photos, $name trouve la bonne espèce deux fois sur trois, contre une fois sur deux.';
  }

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
  String get outdoorHint =>
      'Balcon, jardin ou serre : la météo est prise en compte.';

  @override
  String get weather => 'Météo';

  @override
  String get weatherHint =>
      'Pour les plantes en extérieur : la pluie tombée vaut un arrosage, la pluie annoncée le reporte, et le gel comme la canicule sont signalés. Données Open-Meteo.';

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
  String get weatherRainTitle => 'Pluie aujourd\'hui';

  @override
  String weatherRainSkip(String names) {
    return 'L\'arrosage de $names peut attendre.';
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
      'Un fichier ZIP avec vos plantes, historiques, inventaire, réglages et photos.';

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
    return '$name : stock bas.';
  }

  @override
  String notifLowStockMany(int count) {
    return '$count articles en stock bas.';
  }

  @override
  String get accountTitle => 'Compte';

  @override
  String get signIn => 'Se connecter';

  @override
  String get signInWithAppleId => 'Avec votre identifiant Apple';

  @override
  String get signInHint =>
      'Un compte sauvegarde vos données, les synchronise entre appareils et permet de partager un jardin.';

  @override
  String get continueWithApple => 'Continuer avec Apple';

  @override
  String get continueWithGoogle => 'Continuer avec Google';

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
  String syncUnknownColumns(String columns) {
    return 'Colonnes inconnues du serveur : $columns';
  }

  @override
  String get syncSyncing => 'Synchronisation…';

  @override
  String get authError => 'Connexion impossible. Réessayez dans un moment.';

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
      'L\'invité doit déjà avoir un compte Auxine avec cette adresse.';

  @override
  String get roleOwner => 'Propriétaire';

  @override
  String get roleMember => 'Membre';

  @override
  String get roleViewer => 'Lecture seule';

  @override
  String get invited => 'Invitation envoyée';

  @override
  String get inviteError => 'Cette adresse n\'a pas encore de compte.';

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
  String get diagnosisTitle => 'Diagnostic';

  @override
  String get diagnosisHint =>
      'Les feuilles, la tige, la terre — de près et en entier. Les résultats sont indicatifs.';

  @override
  String get diagnosisSymptomsHint => 'Ce que vous avez remarqué (facultatif)…';

  @override
  String get diagnosisChecks => 'Observations';

  @override
  String get diagnosisChecksHint =>
      'Facultatif : ce que la photo ne montre pas affine l\'analyse.';

  @override
  String get diagnosisSoil => 'Terre';

  @override
  String get diagnosisSoilDry => 'Sèche';

  @override
  String get diagnosisSoilMoist => 'Humide';

  @override
  String get diagnosisSoilSoggy => 'Détrempée';

  @override
  String get diagnosisRoots => 'Racines';

  @override
  String get diagnosisRootsFirm => 'Fermes et claires';

  @override
  String get diagnosisRootsSoft => 'Brunes ou molles';

  @override
  String get diagnosisRootsCrowded => 'À l\'étroit';

  @override
  String get diagnosisLightDirect => 'Soleil direct';

  @override
  String get diagnosisLightBright => 'Vive, sans soleil';

  @override
  String get diagnosisLightDim => 'Faible';

  @override
  String get diagnosisBugs => 'Insectes';

  @override
  String get diagnosisBugsNone => 'Aucun vu';

  @override
  String get diagnosisBugsOnPlant => 'Sur la plante';

  @override
  String get diagnosisBugsInSoil => 'Dans la terre';

  @override
  String get diagnosisSymptoms => 'Symptômes';

  @override
  String get diagnosisAround => 'Autour de la plante';

  @override
  String get diagnosisPhotosFull => 'Trois photos au maximum.';

  @override
  String get diagnosisRemovePhoto => 'Retirer cette photo';

  @override
  String get diagnosisFinding => 'Constat';

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
      'Le diagnostic est indisponible pour le moment. Réessayez plus tard.';

  @override
  String get diagnosisBusy =>
      'Le service d\'analyse ne répond pas. Réessayez dans un moment.';

  @override
  String get diagnosisUnreadable =>
      'L\'analyse n\'a rien rendu d\'exploitable. Réessayez.';

  @override
  String get diagnosisUncertain =>
      'Les photos ne suffisent pas à trancher. Les pistes ci-dessous restent à vérifier.';

  @override
  String get diagnosisAnotherPhotoHint =>
      'Une photo de plus préciserait l\'analyse.';

  @override
  String diagnosisAnotherPhotoView(String view) {
    return 'À photographier : $view.';
  }

  @override
  String get diagnosisAnotherPhoto => 'Ajouter une photo';

  @override
  String get diagnosisViewLeafCloseup => 'une feuille de près';

  @override
  String get diagnosisViewLeafUnderside => 'le revers d\'une feuille';

  @override
  String get diagnosisViewWholePlant => 'la plante entière';

  @override
  String get diagnosisViewStemBase => 'la base de la tige';

  @override
  String get diagnosisViewSoilRoots => 'la terre au pied';

  @override
  String get possibleCauses => 'Pistes possibles';

  @override
  String get causesHint => 'Classées par vraisemblance, à confirmer.';

  @override
  String get likelihoodLikely => 'Probable';

  @override
  String get likelihoodPossible => 'Possible';

  @override
  String get likelihoodUnlikely => 'Peu probable';

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
      'Les photos sont analysées par un modèle hébergé en Suisse (AI Services d\'Infomaniak). Elles ne partent que lorsque vous lancez une analyse, et ne sont pas conservées.';

  @override
  String get diagnosisEnabled => 'Diagnostic activé';

  @override
  String get diagnosisUnavailable => 'Diagnostic indisponible';

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
  String get diagnosisEntry => 'Diagnostic';

  @override
  String get diagnosisOpen => 'Voir le diagnostic complet';

  @override
  String get diagnosisSymptomsNoted => 'Symptômes signalés';

  @override
  String diagnosisMoreCauses(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count autres pistes',
      one: '1 autre piste',
    );
    return '$_temp0';
  }

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
  String get taskTitleHint => 'Titre';

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
      'Semis, nettoyage de la serre, commande de terreau…';

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
    return 'À faire : $title';
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
  String get careSupport => 'Tuteur';

  @override
  String get careSupportMossPole => 'Tuteur moussu';

  @override
  String get careSupportStake => 'Tuteur droit';

  @override
  String get careSupportTrellis => 'Treillis';

  @override
  String get careSupportMossPoleCare =>
      'Humidifier le tuteur à chaque arrosage : les racines aériennes s\'y fixent.';

  @override
  String get careSupportStakeCare =>
      'Attacher la tige sans serrer, à mesure qu\'elle monte.';

  @override
  String get careSupportTrellisCare =>
      'Guider les tiges à mesure qu\'elles poussent.';

  @override
  String get careIssues => 'À surveiller';

  @override
  String get careKnownProblems => 'Problèmes connus sur cette plante';

  @override
  String get careKnownProblemsNote =>
      'Signalés sur cette espèce ou des espèces proches.';

  @override
  String get careLeafSigns => 'Signes sur les feuilles';

  @override
  String get careLeafSignsNote =>
      'Ce qu\'une feuille montre, et ce qui l\'explique le plus souvent.';

  @override
  String get leafSignPaling => 'Feuilles qui s\'éclaircissent';

  @override
  String get leafSignYellowing => 'Feuilles jaunes';

  @override
  String get leafSignScorched => 'Feuilles brûlées';

  @override
  String get leafSignSpots => 'Taches au milieu de la feuille';

  @override
  String get leafSignBrownTips => 'Pointes et bords bruns';

  @override
  String get leafSignStunted => 'Feuilles qui ne grandissent plus';

  @override
  String get leafSignDrooping => 'Feuilles molles';

  @override
  String get leafSignFalling => 'Feuilles qui tombent';

  @override
  String get leafSignSticky => 'Feuilles collantes';

  @override
  String get leafCauseTooMuchSun => 'Trop de soleil direct';

  @override
  String get leafCauseNotEnoughLight => 'Pas assez de lumière';

  @override
  String get leafCauseOverwatering => 'Arrosages trop rapprochés';

  @override
  String get leafCauseUnderwatering => 'Terreau resté sec trop longtemps';

  @override
  String get leafCauseDryAir => 'Air trop sec';

  @override
  String get leafCauseColdDraught => 'Froid ou courant d\'air';

  @override
  String get leafCauseHardWater => 'Eau calcaire, ou engrais trop concentré';

  @override
  String get leafCausePoorSoil => 'Substrat épuisé';

  @override
  String get leafCausePotBound => 'Racines à l\'étroit dans le pot';

  @override
  String get leafCauseDamagedRoots => 'Racines abîmées par l\'eau stagnante';

  @override
  String get leafCauseLeafPests => 'Piqûres d\'araignées rouges ou de thrips';

  @override
  String get leafCauseHoneydewPests =>
      'Cochenilles ou pucerons, sur la plante ou au-dessus';

  @override
  String get leafCauseSootyMould =>
      'Fumagine, le noir qui pousse sur le miellat';

  @override
  String get leafCauseLeafFungus => 'Champignon ou bactérie sur la feuille';

  @override
  String get leafCauseWetLeaves => 'Eau restée sur le feuillage';

  @override
  String get leafCauseRecentMove => 'Déménagement ou rempotage récent';

  @override
  String get leafCauseOldLeaves => 'Vieillissement des feuilles du bas';

  @override
  String get leafCauseWinterRest => 'Repos hivernal';

  @override
  String get problemKindDisorder => 'Trouble';

  @override
  String get problemKindPest => 'Ravageur';

  @override
  String get problemKindDisease => 'Maladie';

  @override
  String get problemKindCondition => 'Affection';

  @override
  String get problemKindDisorders => 'Troubles';

  @override
  String get problemKindPests => 'Ravageurs';

  @override
  String get problemKindDiseases => 'Maladies';

  @override
  String get problemKindConditions => 'Affections';

  @override
  String get careTips => 'Conseils';

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
  String get careDryDownAlwaysMoist => 'Terreau toujours humide';

  @override
  String get careDryDownSurfaceDry => 'Laisser sécher la surface';

  @override
  String get careDryDownTopQuarterDry => 'Laisser sécher le quart supérieur';

  @override
  String get careDryDownHalfDry => 'Laisser sécher à moitié';

  @override
  String get careDryDownMostlyDry => 'Laisser sécher presque à fond';

  @override
  String get careDryDownFullyDry => 'Laisser sécher complètement';

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
  String get careRepotNone => 'Pas de rempotage (culture annuelle)';

  @override
  String get carePotSnug => 'Aime être à l\'étroit';

  @override
  String get carePotRoomy => 'Aime l\'espace';

  @override
  String get carePotSnugNote =>
      'Une racine qui sort par le fond ne suffit pas : rempotez quand la motte est un bloc de racines, ou quand l\'eau ne pénètre plus.';

  @override
  String get carePotSteadyNote =>
      'Rempotez quand les racines sortent par le fond et tournent au fond du pot.';

  @override
  String get carePotRoomyNote =>
      'Rempotez dès que les racines atteignent la paroi : à l\'étroit, elle arrête de pousser.';

  @override
  String get carePotDormantNote =>
      'Le rempotage se fait à la reprise, quand le repos s\'achève, et non sur une racine qui sort.';

  @override
  String careTempIdeal(int min, int max) {
    return '$min à $max °C';
  }

  @override
  String careTempMin(int min) {
    return 'Éviter sous $min °C';
  }

  @override
  String get careEnvTitle => 'Emplacement idéal';

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
    return 'température de $min à $max degrés';
  }

  @override
  String careEnvSemanticTempMin(int min) {
    return 'température au-dessus de $min degrés';
  }

  @override
  String get careAirflow => 'Courants d\'air';

  @override
  String get careAirflowSheltered => 'À l\'abri des courants d\'air';

  @override
  String get careAirflowNormal => 'Air ordinaire';

  @override
  String get careAirflowVentilated => 'Air bien ventilé';

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
  String careLightFloor(String value) {
    return 'Tient jusqu\'à $value';
  }

  @override
  String careLightLamp(int min, int max, int hours) {
    return 'Sous lampe · LED à spectre complet, $min à $max µmol/m²/s, $hours h par jour';
  }

  @override
  String careLightLampDli(int min, int max) {
    return 'Soit $min à $max mol/m²/jour reçus par le feuillage.';
  }

  @override
  String get careHumidityLow => 'Air sec accepté';

  @override
  String get careHumidityAverage => 'Humidité ordinaire';

  @override
  String get careHumidityHigh => 'Aime l\'air humide';

  @override
  String careHumidityRange(int min, int max) {
    return '$min à $max % d\'humidité de l\'air';
  }

  @override
  String get careHumidityLowDetail =>
      'Elle tolère bien l\'air sec d\'un logement. Une humidité durablement plus haute l\'abîme.';

  @override
  String get careHumidityAverageDetail =>
      'L\'air ordinaire d\'un logement convient. Loin d\'un radiateur en hiver, les pointes des feuilles ne brunissent pas.';

  @override
  String get careHumidityHighDetail =>
      'L\'air sec d\'un logement chauffé l\'abîme : il faut le maintenir humide.';

  @override
  String get careHumidityMethodMist => 'Brumiser le feuillage lui profite.';

  @override
  String get careHumidityMethodHumidifier => 'Un humidificateur d\'air.';

  @override
  String get careHumidityMethodTray =>
      'Un plateau de billes d\'argile humides, ou des plantes regroupées.';

  @override
  String get careHumidityMethodTerrarium =>
      'Sous verre : terrarium, cloche ou bocal.';

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
  String get careToxicityFromSpecies => 'Vérifié pour cette espèce';

  @override
  String careToxicityFromGenus(String name) {
    return 'Genre $name · non vérifié pour cette espèce';
  }

  @override
  String careToxicityFromFamily(String name) {
    return 'Famille des $name · non vérifié pour cette espèce';
  }

  @override
  String careToxicitySource(String name) {
    return 'Source : $name';
  }

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
  String get careSoilNone => 'Sans substrat';

  @override
  String get careGrowthMedium => 'Milieu de vie';

  @override
  String get careMediumTerrestrial => 'Terrestre';

  @override
  String get careMediumEpiphytic => 'Épiphyte';

  @override
  String get careMediumLithophytic => 'Lithophyte';

  @override
  String get careMediumAquatic => 'Aquatique';

  @override
  String get careMediumSemiAquatic => 'Semi-aquatique';

  @override
  String get careMediumTerrestrialNote => 'Elle pousse en terre.';

  @override
  String get careMediumEpiphyticNote =>
      'Elle pousse sur un support, sans terreau : écorces, sphaigne, ou rien.';

  @override
  String get careMediumLithophyticNote =>
      'Elle pousse sur la pierre, ses racines dans les fissures.';

  @override
  String get careMediumAquaticNote => 'Ses racines vivent dans l\'eau.';

  @override
  String get careMediumSemiAquaticNote =>
      'Elle vit en sol détrempé, au bord de l\'eau.';

  @override
  String get careWater => 'Eau';

  @override
  String get careWaterTolerant => 'Eau du robinet';

  @override
  String get careWaterSensitive => 'Eau peu calcaire';

  @override
  String get careWaterStrict => 'Eau sans calcaire';

  @override
  String get careWaterTolerantNote => 'Le calcaire ne la gêne pas.';

  @override
  String get careWaterSensitiveNote => 'Le calcaire lui brunit les pointes.';

  @override
  String get careWaterFluorideSensitive =>
      'Le fluor du robinet lui brunit les pointes : eau de pluie ou osmosée.';

  @override
  String get careWaterStrictNote =>
      'Le calcaire l\'abîme, même en petite quantité.';

  @override
  String get careWaterTypes => 'Types d\'eau';

  @override
  String get careWaterTypesNote =>
      'La dureté de l\'eau du robinet change d\'une commune à l\'autre ; l\'analyse annuelle du distributeur la donne.';

  @override
  String get careWaterBest => 'Recommandée';

  @override
  String get careWaterOk => 'Convient';

  @override
  String get careWaterCaution => 'Avec réserve';

  @override
  String get careWaterAvoid => 'À éviter';

  @override
  String get careWaterTap => 'Eau du robinet';

  @override
  String get careWaterTapNote =>
      'L\'eau du réseau, telle qu\'elle sort. Sa dureté dépend de la commune.';

  @override
  String get careWaterTapRisk =>
      'Le calcaire s\'accumule dans le terreau et fait monter son pH. Laisser reposer l\'eau chasse le chlore, pas le calcaire.';

  @override
  String get careWaterRain => 'Eau de pluie';

  @override
  String get careWaterRainNote => 'Douce, sans calcaire, légèrement acide.';

  @override
  String get careWaterRainRisk =>
      'Recueillie sur un toit, elle emporte poussières et fientes ; une réserve à l\'air libre verdit. Écarter les premières minutes de pluie, couvrir le tonneau.';

  @override
  String get careWaterFiltered => 'Eau filtrée';

  @override
  String get careWaterFilteredNote =>
      'Une carafe filtrante retire le chlore et une part du calcaire.';

  @override
  String get careWaterFilteredRisk =>
      'La part retenue dépend de la cartouche, et une cartouche épuisée ne retient plus rien. Le calcaire n\'est jamais entièrement retiré.';

  @override
  String get careWaterOsmosis => 'Eau osmosée';

  @override
  String get careWaterOsmosisNote =>
      'Presque sans minéraux, comme l\'eau de pluie.';

  @override
  String get careWaterOsmosisRisk =>
      'Elle n\'apporte aucun élément nutritif : l\'engrais devient la seule source. Pour une plante ordinaire, un tiers d\'eau du robinet la rééquilibre.';

  @override
  String get careWaterDemineralized => 'Eau déminéralisée';

  @override
  String get careWaterDemineralizedNote =>
      'Vendue pour les fers à repasser, elle vaut l\'eau osmosée quand elle est pure.';

  @override
  String get careWaterDemineralizedRisk =>
      'Certains bidons contiennent un antitartre ou un parfum : lire l\'étiquette. Comme l\'eau osmosée, elle n\'apporte aucun élément nutritif.';

  @override
  String get careWaterCondensate => 'Eau de climatiseur';

  @override
  String get careWaterCondensateNote =>
      'Le condensat d\'un climatiseur ou d\'un déshumidificateur, une eau distillée par l\'appareil.';

  @override
  String get careWaterCondensateRisk =>
      'Elle a ruisselé sur un échangeur et dans un bac où s\'accumulent poussières, biofilm et bactéries, et peut emporter des traces de métaux. À réserver aux plantes d\'ornement, sur un appareil propre, jamais sur ce qui se mange.';

  @override
  String get careWaterSoftened => 'Eau adoucie';

  @override
  String get careWaterSoftenedNote =>
      'Un adoucisseur à résine remplace le calcaire par du sodium.';

  @override
  String get careWaterSoftenedRisk =>
      'Le sodium s\'accumule dans le terreau, abîme les racines et ferme la structure du sol. Le robinet d\'eau brute, en amont de l\'adoucisseur, reste le bon.';

  @override
  String get careSoilMixStandard =>
      'Allégé de 20 % de perlite, pour que l\'eau traverse.';

  @override
  String get careSoilMixDraining =>
      '50 % de terreau, 25 % de perlite, 25 % de sable grossier ou de pouzzolane.';

  @override
  String get careSoilMixCactus =>
      '30 % de terreau, 70 % de pouzzolane, de pierre ponce ou de sable grossier.';

  @override
  String get careSoilMixOrchid =>
      'Écorces de pin moyennes, 10 % de perlite, un peu de sphaigne ; jamais de terreau.';

  @override
  String get careSoilMixAcidic =>
      'Allégée de 25 % d\'écorce de pin, sans calcaire ni compost.';

  @override
  String get careSoilMixRich =>
      '40 % de terreau, 40 % de compost, 20 % de perlite.';

  @override
  String get careSoilMixNone =>
      'Pas de substrat : les racines vivent à l\'air ou dans l\'eau.';

  @override
  String careSoilFree(String water, String pon) {
    return 'Dans l\'eau : $water · En pon : $pon';
  }

  @override
  String get careSoilFreeYes => 'oui';

  @override
  String get careSoilFreeNo => 'non';

  @override
  String get careSoilFreeCuttings => 'bouture seulement';

  @override
  String get careFertBalanced =>
      'Engrais plantes vertes équilibré, dilué de moitié.';

  @override
  String get careFertFoliage => 'Engrais riche en azote, celui du feuillage.';

  @override
  String get careFertFlowering =>
      'Engrais riche en potasse, celui de la floraison.';

  @override
  String get careFertCactus => 'Engrais cactées, pauvre en azote.';

  @override
  String get careFertOrchid => 'Engrais orchidées, très dilué.';

  @override
  String get careFertAcidic => 'Engrais pour terre de bruyère, sans calcaire.';

  @override
  String get careFertCitrus =>
      'Engrais agrumes, riche en azote et en oligo-éléments.';

  @override
  String get careFertVegetable => 'Engrais tomates, riche en potasse.';

  @override
  String get careCalciumAvoid =>
      'Calcium : aucun apport, et de l\'eau de pluie ; le calcaire fait jaunir son feuillage.';

  @override
  String get careCalciumWelcome =>
      'Calcium : l\'eau calcaire lui convient, des coquilles d\'œufs broyées au rempotage aussi.';

  @override
  String get careCalciumNeeded =>
      'Calcium : un apport régulier évite la nécrose apicale des fruits.';

  @override
  String get careGreenhouse => 'Sous serre';

  @override
  String get careGreenhouseWarmHumid => 'Chaleur et air humide';

  @override
  String get careGreenhouseWarmLight => 'Chaleur et lumière';

  @override
  String get careGreenhouseWarmDry => 'Chaleur, lumière et air sec';

  @override
  String get careGreenhouseGrowth =>
      'Tenues toute l\'année, ces conditions accélèrent la pousse : l\'arrosage et l\'engrais se rapprochent d\'autant.';

  @override
  String get careGreenhouseHold =>
      'Tenez la plage d\'humidité le jour, laissez-la descendre la nuit, et faites circuler l\'air.';

  @override
  String get careGreenhouseAir =>
      'Aérer chaque jour : l\'air confiné fait pourrir ce qui aime le sec.';

  @override
  String get careGreenhouseEarly =>
      'En mini-serre ou sous châssis, les semis partent quatre à six semaines plus tôt.';

  @override
  String get careBloom => 'Floraison';

  @override
  String careSeasonRange(String from, String to) {
    return 'De $from à $to';
  }

  @override
  String get careBloomOutdoors => 'Rarement en intérieur';

  @override
  String get careBloomChillBulb => 'Un froid au bulbe';

  @override
  String get careBloomChillBulbNote =>
      'Comptez dix à quinze semaines entre 5 et 9 °C, au noir, avant de remettre le pot à la chaleur et à la lumière.';

  @override
  String get careBloomFertilizer => 'Un engrais de floraison';

  @override
  String get careBloomFertilizerNote =>
      'Dès que les boutons se forment, passez à un engrais de floraison, plus riche en potasse que celui du feuillage.';

  @override
  String get careBloomMaturity => 'De l\'âge';

  @override
  String get careBloomMaturityNote =>
      'Elle ne fleurit qu\'à partir de trois ou quatre ans : avant cet âge, aucune condition n\'y changera rien.';

  @override
  String get careBloomDeadhead => 'Des fleurs coupées';

  @override
  String get careBloomDeadheadNote =>
      'Coupez les fleurs fanées au fur et à mesure : la plante remet alors son énergie dans les suivantes.';

  @override
  String get careBloomKeepSpike => 'Une hampe gardée';

  @override
  String get careBloomKeepSpikeNote =>
      'Tant que la hampe reste verte, laissez-la en place : elle peut refleurir depuis un œil situé plus bas.';

  @override
  String get careBloomNoMove => 'Une place fixe';

  @override
  String get careBloomNoMoveNote =>
      'Une fois les boutons formés, ne la déplacez plus et ne la tournez plus : le changement les fait tomber.';

  @override
  String get careBloomEvenWater => 'Un arrosage régulier';

  @override
  String get careBloomEvenWaterNote =>
      'Pendant la formation des boutons, arrosez régulièrement : un seul coup de sec suffit à les faire tomber.';

  @override
  String get careRest => 'Repos';

  @override
  String careRestStoreDarkTemp(int min, int max) {
    return 'Au sec et à l\'obscurité, entre $min et $max °C';
  }

  @override
  String careRestStoreTemp(int min, int max) {
    return 'Au sec, entre $min et $max °C';
  }

  @override
  String get careRestStoreDark => 'Au sec et à l\'obscurité';

  @override
  String get careRestStorePlain => 'Au sec';

  @override
  String get careRestNote =>
      'Laissez le feuillage jaunir et sécher sans le couper, puis arrêtez l\'arrosage. Remettez le pot à la lumière et reprenez l\'arrosage à la fin de cette période.';

  @override
  String get careBloomCoolRest => 'Un hiver frais';

  @override
  String get careBloomCoolRestNote =>
      'Pour préparer la floraison, gardez-la environ deux mois entre 10 et 12 °C et réduisez fortement les arrosages.';

  @override
  String get careBloomCoolNights => 'Des nuits fraîches';

  @override
  String get careBloomCoolNightsNote =>
      'En automne, environ trois semaines avec des nuits autour de 15 °C peuvent déclencher la hampe florale.';

  @override
  String get careBloomShortDays => 'Des jours courts';

  @override
  String get careBloomShortDaysNote =>
      'Pendant environ six semaines, offrez-lui des nuits d\'au moins 12 heures dans l\'obscurité pour favoriser la formation des boutons.';

  @override
  String get careBloomDrySpell => 'Une sécheresse';

  @override
  String get careBloomDrySpellNote =>
      'Réduisez fortement les arrosages pendant quelques semaines, puis reprenez progressivement : ce contraste peut déclencher la floraison.';

  @override
  String get careBloomPotbound => 'Un pot à l\'étroit';

  @override
  String get careBloomPotboundNote =>
      'Elle fleurit souvent mieux lorsque ses racines occupent bien le pot. Évitez donc de rempoter trop tôt.';

  @override
  String get careBloomBrightLight => 'Plus de lumière';

  @override
  String get careBloomBrightLightNote =>
      'Pour fleurir, elle a besoin de plus de lumière que pour simplement pousser. Placez-la dans un endroit très lumineux, sans soleil brûlant.';

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
      'Valeurs indicatives, à adapter à la lumière, au pot et à l\'air ambiant.';

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
      'Excès d\'eau (feuilles molles et jaunes)';

  @override
  String get careIssueUnderwatering => 'Manque d\'eau (feuilles qui retombent)';

  @override
  String get careIssueRootRot => 'Pourriture des racines';

  @override
  String get careIssueSpiderMites => 'Araignées rouges (fines toiles)';

  @override
  String get careIssueThrips => 'Thrips (feuilles argentées)';

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
  String get careIssueTrueBugs => 'Punaises';

  @override
  String get careIssueSlugs => 'Limaces et escargots';

  @override
  String get careIssuePowderyMildew => 'Oïdium (feutrage blanc)';

  @override
  String get careIssueGreyMould => 'Pourriture grise (Botrytis)';

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
  String get careIssueChlorosis => 'Chlorose (feuilles pâles, nervures vertes)';

  @override
  String get careIssueBlossomEndRot => 'Nécrose apicale des fruits';

  @override
  String get careTipFingerTest =>
      'Enfoncez un doigt et arrosez quand les 2 premiers centimètres sont secs.';

  @override
  String get careTipDrySoilFirst =>
      'Laissez le terreau sécher complètement entre deux arrosages.';

  @override
  String get careTipNeverDryOut =>
      'Ne laissez jamais le terreau sécher complètement.';

  @override
  String get careTipEvenWatering =>
      'Arrosez régulièrement, car les à-coups font éclater les fruits.';

  @override
  String get careTipWaterAtBase =>
      'Arrosez au pied, sans mouiller le feuillage.';

  @override
  String get careTipNoWaterOnLeaves =>
      'Ne mouillez pas les feuilles, car l\'eau stagnante les tache.';

  @override
  String get careTipBottomWatering =>
      'Arrosez par le bas, en posant le pot dans une soucoupe d\'eau 20 minutes.';

  @override
  String get careTipThirstyPlant =>
      'Grosse buveuse, vérifiez-la tous les jours en été.';

  @override
  String get careTipDroopSignal =>
      'Quand elle s\'affaisse, c\'est qu\'elle a soif.';

  @override
  String get careTipWinterDry => 'En hiver, gardez-la presque au sec.';

  @override
  String get careTipWinterRest =>
      'En hiver, elle se repose et demande beaucoup moins d\'eau.';

  @override
  String get careTipSummerDormant =>
      'Elle se repose en été et demande très peu d\'eau à cette période.';

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
      'Après le bain, laissez-la sécher tête en bas, car l\'eau au cœur la fait pourrir.';

  @override
  String get careTipWaterInTheCup =>
      'Remplissez la rosette centrale et renouvelez l\'eau chaque semaine.';

  @override
  String get careTipNoSoil =>
      'Elle vit sans terre, posée simplement sur un support.';

  @override
  String get careTipGreenRoots =>
      'Racines vertes = bien hydratée. Argentées = il est temps d\'arroser.';

  @override
  String get careTipHumidityTray =>
      'Posez le pot sur un lit de billes d\'argile humides.';

  @override
  String get careTipNoDirectSun =>
      'Évitez le soleil direct, qui brûle le feuillage.';

  @override
  String get careTipToleratesLowLight =>
      'Elle supporte une pièce peu lumineuse, mais pousse plus vite près d\'une fenêtre.';

  @override
  String get careTipToleratesNeglect =>
      'Elle pardonne les oublis, alors en cas de doute, n\'arrosez pas.';

  @override
  String get careTipBrightForColor =>
      'Plus la lumière est vive, plus les couleurs sont marquées.';

  @override
  String get careTipRotatePot =>
      'Tournez le pot d\'un quart de tour chaque semaine pour qu\'elle reste droite.';

  @override
  String get careTipHatesMoving =>
      'Trouvez-lui une place et laissez-la, elle déteste être déplacée.';

  @override
  String get careTipWipeLeaves =>
      'Dépoussiérez les feuilles pour qu\'elles respirent et captent mieux la lumière.';

  @override
  String get careTipTrimToBushOut =>
      'Taillez les tiges trop longues et elle se ramifiera.';

  @override
  String get careTipMonsteraSupport =>
      'Offrez-lui un tuteur moussu et les feuilles deviendront plus grandes et découpées.';

  @override
  String get careTipShallowPot =>
      'Un pot large et peu profond lui convient mieux.';

  @override
  String get careTipLikesBeingPotbound =>
      'Elle fleurit mieux à l\'étroit, alors rempotez rarement.';

  @override
  String get careTipTrunkStoresWater =>
      'Son pied renflé stocke l\'eau, mieux vaut donc trop peu que trop.';

  @override
  String get careTipPupsToShare =>
      'Elle fait des rejets, détachez-les pour multiplier ou offrir.';

  @override
  String get careTipKeepFlowerSpike =>
      'Ne coupez pas la hampe verte, car elle peut refleurir dessus.';

  @override
  String get careTipDarkForRebloom =>
      'Pour la refaire fleurir, offrez-lui six semaines de nuits longues et fraîches.';

  @override
  String get careTipNotADesertCactus =>
      'Ce n\'est pas un cactus du désert, il aime l\'ombre et l\'humidité.';

  @override
  String get careTipDeadheadFlowers =>
      'Retirez les fleurs fanées et elle refleurira plus longtemps.';

  @override
  String get careTipPinchFlowers =>
      'Pincez les fleurs dès qu\'elles montent pour garder des feuilles tendres.';

  @override
  String get careTipHarvestTop =>
      'Récoltez par le haut, au-dessus d\'une paire de feuilles.';

  @override
  String get careTipHarvestOutside =>
      'Cueillez les feuilles extérieures et le cœur continuera de pousser.';

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
      'Deux tailles par an suffisent, en juin et fin août.';

  @override
  String get careTipContainItsRoots =>
      'Elle envahit tout, plantez-la en pot ou posez une barrière anti-rhizome.';

  @override
  String get careTipMulchIt =>
      'Paillez le pied pour arroser moins et limiter les mauvaises herbes.';

  @override
  String get careTipAcidSoil =>
      'Elle exige une terre acide, pas du terreau universel.';

  @override
  String get careTipFeedsOnInsects =>
      'Elle se nourrit d\'insectes : pas d\'engrais, et une terre pauvre.';

  @override
  String get careTipBlueNeedsAcid =>
      'Les fleurs bleues demandent un sol acide ; en sol calcaire elles virent au rose.';

  @override
  String get careTipCitrusFertilizer =>
      'Utilisez un engrais spécial agrumes pendant toute la belle saison.';

  @override
  String get careTipNoFertilizer =>
      'Pas d\'engrais, une terre trop riche lui coûte son parfum et sa tenue.';

  @override
  String get careTipNoNitrogen =>
      'Évitez l\'engrais azoté, car elle fabrique le sien.';

  @override
  String get careTipLetFoliageDieBack =>
      'Laissez le feuillage jaunir sur pied, car il recharge le bulbe.';

  @override
  String get careTipDiesBackInWinter =>
      'Elle disparaît en hiver et repart au printemps, c\'est normal.';

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
      'Elle préfère la fraîcheur, éloignez-la des radiateurs.';

  @override
  String get careTipHardyOutdoors =>
      'Rustique, elle passe l\'hiver dehors sans protection.';

  @override
  String get careTipShelterFromWind =>
      'Placez-la à l\'abri du vent, car le feuillage s\'abîme vite.';

  @override
  String get careTipAirFlow =>
      'Aérez autour d\'elle, car l\'air confiné favorise les maladies.';

  @override
  String get careTipSpiderMiteWatch =>
      'Inspectez le dessous des feuilles, que les araignées rouges adorent.';

  @override
  String get careTipSlugWatch =>
      'Protégez les jeunes pousses des limaces au printemps.';

  @override
  String get careTipBoxMothWatch =>
      'Surveillez la pyrale, ses chenilles laissent des fils de soie dans le feuillage.';

  @override
  String get careTipSapIrritant =>
      'Sa sève irrite la peau et les yeux, taillez-la avec des gants.';

  @override
  String get careTipVeryToxic =>
      'Toutes ses parties sont très toxiques, y compris la fumée si on la brûle.';

  @override
  String get careTipSharpSpines =>
      'Ses pointes sont dangereuses, éloignez-la des passages.';

  @override
  String get careTipSplitsAreNormal =>
      'Les feuilles se fendent avec l\'âge, c\'est normal et non une maladie.';

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
      'Champs réutilisables sur plusieurs plantes.';

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
  String get photoUrlInvalid => 'L\'adresse doit commencer par https://';

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

  @override
  String get locationNotes => 'Notes de l\'emplacement';

  @override
  String get locationLog => 'Journal';

  @override
  String get addLogEntry => 'Ajouter une entrée';

  @override
  String get editLogEntry => 'Modifier l\'entrée';

  @override
  String get logEntryHint => 'Store changé, serre nettoyée…';

  @override
  String get noLogEntries => 'Journal vide';

  @override
  String get confirmDeleteLogEntry => 'Supprimer cette entrée ?';

  @override
  String get locationPhoto => 'Photo de l\'emplacement';

  @override
  String get removeLocationPhoto => 'Retirer la photo';

  @override
  String get careAllPlants => 'Soigner toutes les plantes';

  @override
  String get waterAllHere => 'Arroser tout ici';

  @override
  String get fertilizeAllHere => 'Fertiliser tout ici';

  @override
  String get repotAllHere => 'Rempoter tout ici';

  @override
  String get searchByNumberHint => 'Tapez #42 pour retrouver la plante n° 42.';

  @override
  String get inventoryGroups => 'Groupes';

  @override
  String get manageGroups => 'Gérer les groupes';

  @override
  String get newGroup => 'Nouveau groupe';

  @override
  String get editGroup => 'Modifier le groupe';

  @override
  String get groupName => 'Nom du groupe';

  @override
  String get groupNameHint => 'Engrais, outils, poteries…';

  @override
  String get deleteGroup => 'Supprimer le groupe';

  @override
  String get deleteGroupHint =>
      'Les articles ne sont pas supprimés, ils rejoignent le groupe choisi.';

  @override
  String get moveItemsTo => 'Déplacer les articles vers';

  @override
  String get noGroup => 'Sans groupe';

  @override
  String get noGroups => 'Aucun groupe personnalisé';

  @override
  String get itemGroup => 'Groupe';

  @override
  String get itemTags => 'Tags';

  @override
  String get itemQr => 'QR de l\'article';

  @override
  String get exportSelection => 'Exporter la sélection';

  @override
  String get exportCsv => 'Exporter en CSV';

  @override
  String get selectItems => 'Sélectionner';

  @override
  String itemsSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count articles',
      one: '1 article',
    );
    return '$_temp0';
  }

  @override
  String get filterByTag => 'Filtrer par tag';

  @override
  String get itemNotFound => 'Article introuvable';

  @override
  String get noGroupsYet => 'Aucun groupe.';

  @override
  String get deleteGroupExplain =>
      'Les articles ne sont pas supprimés, ils perdent leur groupe.';

  @override
  String get newEvent => 'Nouvel événement';

  @override
  String get editEvent => 'Modifier l\'événement';

  @override
  String get deleteEvent => 'Supprimer l\'événement';

  @override
  String get eventTitleHint => 'Marché aux plantes';

  @override
  String get eventNotesHint => 'Notes (facultatif)';

  @override
  String get eventStart => 'Début';

  @override
  String get eventEnd => 'Fin';

  @override
  String get eventNoEnd => 'Même jour';

  @override
  String get eventAllDay => 'Journée entière';

  @override
  String get eventCategory => 'Catégorie';

  @override
  String get eventNoCategory => 'Aucune';

  @override
  String get eventReminder => 'Rappel';

  @override
  String get eventNoReminder => 'Aucun';

  @override
  String get eventReminderAtStart => 'À l\'heure';

  @override
  String eventReminderMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes avant',
      one: '1 minute avant',
    );
    return '$_temp0';
  }

  @override
  String eventReminderHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count heures avant',
      one: '1 heure avant',
    );
    return '$_temp0';
  }

  @override
  String eventReminderDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours avant',
      one: '1 jour avant',
    );
    return '$_temp0';
  }

  @override
  String get manageEventCategories => 'Catégories d\'événements';

  @override
  String get newEventCategory => 'Nouvelle catégorie';

  @override
  String get editEventCategory => 'Modifier la catégorie';

  @override
  String get deleteEventCategory => 'Supprimer la catégorie';

  @override
  String get deleteEventCategoryExplain =>
      'Les événements ne sont pas supprimés, ils perdent leur catégorie.';

  @override
  String get noEventCategoriesYet => 'Aucune catégorie.';

  @override
  String get categoryNameHint => 'Nom de la catégorie';

  @override
  String get eventPlant => 'Plante liée';

  @override
  String get eventNoPlant => 'Aucune';

  @override
  String get eventsOfDay => 'Événements';

  @override
  String get dashboardTitle => 'Tableau de bord';

  @override
  String get statsSection => 'Chiffres';

  @override
  String get statPlants => 'Plantes';

  @override
  String get statSpecies => 'Espèces';

  @override
  String get statLocations => 'Emplacements';

  @override
  String get statFavorites => 'Favorites';

  @override
  String get statArchived => 'Archivées';

  @override
  String get statNeedingCare => 'À soigner';

  @override
  String get statOpenTasks => 'Tâches ouvertes';

  @override
  String get statLowStock => 'Stock bas';

  @override
  String get statActionsThisMonth => 'Soins ce mois';

  @override
  String get statWateringsThisMonth => 'Arrosages ce mois';

  @override
  String get statOldest => 'Plus ancienne';

  @override
  String get warningsSection => 'À surveiller';

  @override
  String get warningSick => 'Malade';

  @override
  String get warningWatch => 'À surveiller';

  @override
  String warningOverdue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours de retard',
      one: '1 jour de retard',
    );
    return '$_temp0';
  }

  @override
  String get noWarnings => 'Rien à signaler.';

  @override
  String get recentPlantsSection => 'Dernières plantes';

  @override
  String get recentAdded => 'Ajoutées';

  @override
  String get recentUpdated => 'Modifiées';

  @override
  String get activityLogTitle => 'Journal d\'activité';

  @override
  String get activityEmpty => 'Aucune activité.';

  @override
  String get activityPlantAdded => 'Ajoutée au jardin';

  @override
  String get activityPlantArchived => 'Archivée';

  @override
  String get activityLocationNote => 'Note d\'emplacement';

  @override
  String get activityTaskDone => 'Tâche terminée';

  @override
  String get searchArchives => 'Rechercher dans les archives';

  @override
  String get archiveSortArchivedDesc => 'Archivées récemment';

  @override
  String get archiveSortArchivedAsc => 'Archivées d\'abord';

  @override
  String get archiveSortName => 'Nom';

  @override
  String get archiveSortLongestKept => 'Gardées le plus longtemps';

  @override
  String get allYears => 'Toutes';

  @override
  String keptForDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Gardée $count jours',
      one: 'Gardée 1 jour',
    );
    return '$_temp0';
  }

  @override
  String keptForYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Gardée $count ans',
      one: 'Gardée 1 an',
    );
    return '$_temp0';
  }

  @override
  String get noArchiveMatch => 'Aucune plante ne correspond.';

  @override
  String get weatherForecastTitle => 'Prévisions';

  @override
  String get weatherPrecipitation => 'Précipitations';

  @override
  String get weatherRainChance => 'Risque de pluie';

  @override
  String get weatherWind => 'Vent';

  @override
  String get weatherHumidity => 'Humidité';

  @override
  String get weatherNoPlace => 'Choisissez un lieu pour voir les prévisions.';

  @override
  String get weatherToday => 'Aujourd\'hui';

  @override
  String get weatherFailed => 'Prévisions indisponibles pour l\'instant.';

  @override
  String get backupTitle => 'Sauvegarde';

  @override
  String get backupExplain =>
      'Un fichier .zip contenant vos données et vos photos.';

  @override
  String get backupWhatToExport => 'Que sauvegarder';

  @override
  String get backupWhatToImport => 'Que restaurer';

  @override
  String get sectionGarden => 'Jardin et emplacements';

  @override
  String get sectionPlants => 'Plantes';

  @override
  String get sectionPhotos => 'Photos';

  @override
  String get sectionCare => 'Soins et routines';

  @override
  String get sectionInventory => 'Inventaire';

  @override
  String get sectionTasks => 'Tâches';

  @override
  String get sectionCalendar => 'Calendrier';

  @override
  String get importBackup => 'Restaurer une sauvegarde';

  @override
  String get chooseBackupFile => 'Choisir un fichier';

  @override
  String get importing => 'Restauration…';

  @override
  String importDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments restaurés',
      one: '1 élément restauré',
    );
    return '$_temp0';
  }

  @override
  String importSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lignes ignorées',
      one: '1 ligne ignorée',
    );
    return '$_temp0';
  }

  @override
  String get importConfirm =>
      'Les données du fichier remplacent celles de même identifiant. Rien n\'est supprimé.';

  @override
  String get importErrorNotAZip =>
      'Ce fichier n\'est pas une sauvegarde Auxine.';

  @override
  String get importErrorWrongApp =>
      'Cette sauvegarde vient d\'une autre application.';

  @override
  String get importErrorTooRecent =>
      'Cette sauvegarde vient d\'une version plus récente d\'Auxine.';

  @override
  String get importErrorGeneric => 'Restauration impossible.';

  @override
  String backupFrom(String date) {
    return 'Sauvegarde du $date';
  }

  @override
  String backupContains(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments',
      one: '1 élément',
    );
    return '$_temp0';
  }

  @override
  String get onbTodayTitle => 'Les soins du jour';

  @override
  String get onbTodayBody => 'Un geste pour noter chaque soin.';

  @override
  String get onbCareTitle => 'Moins d\'arrosages en hiver';

  @override
  String get onbCareBody => 'Les intervalles s\'ajustent selon la saison.';

  @override
  String get onbGardenTitle => 'Emplacements, photos, calendrier';

  @override
  String get onbGardenBody =>
      'Chaque arrosage, chaque rempotage est daté et rangé avec la plante.';

  @override
  String onbIrisTitle(String name) {
    return '$name reconnaît vos plantes hors ligne';
  }

  @override
  String get onbIrisBody =>
      'Plante inconnue d\'Iris : la recherche continue en ligne.';

  @override
  String get onbPrivacyTitle => 'Tout reste sur votre téléphone';

  @override
  String get onbPrivacyBody => 'Pas de compte obligatoire, pas de publicité.';

  @override
  String get onbStart => 'Commencer';

  @override
  String get replayOnboarding => 'Revoir la présentation';

  @override
  String get whatsNewTitle => 'Nouveautés';

  @override
  String get whatsNewModelUpdate => 'Mise à jour du modèle';

  @override
  String get whatsNewIrisIntro =>
      'Le modèle embarqué a été réentraîné : plus d\'espèces, moins d\'erreurs, toujours sans réseau.';

  @override
  String whatsNewIrisSpeciesTitle(String count) {
    return '$count espèces reconnues';
  }

  @override
  String get whatsNewIrisSpeciesBody =>
      'Des plantes d\'intérieur plus rares s\'ajoutent au catalogue.';

  @override
  String get whatsNewIrisOfflineTitle => 'Toujours sur l\'appareil';

  @override
  String get whatsNewIrisOfflineBody =>
      'La reconnaissance reste locale : rien ne part sans votre accord, et le repli en ligne se coupe d\'un interrupteur.';

  @override
  String get whatsNewIrisDoubtTitle => 'Doute signalé';

  @override
  String get whatsNewIrisDoubtBody =>
      'Deux espèces qui se ressemblent : les deux sont proposées.';

  @override
  String onbStepOf(int current, int total) {
    return 'Étape $current sur $total';
  }

  @override
  String get weatherPickPlace => 'Choisir un lieu';

  @override
  String get speciesMoreOffline => 'Autres espèces';

  @override
  String get aboutSources => 'Sources des données';

  @override
  String get privacyPolicy => 'Politique de confidentialité';

  @override
  String get aboutSourceWikidata =>
      'Noms d\'espèces en quatre langues, domaine public';

  @override
  String get aboutSourceGbif =>
      'Taxonomie, familles et observations photographiées';

  @override
  String get aboutSourceOpenMeteo => 'Météo et prévisions, sans compte ni clé';

  @override
  String get aboutSourceRhs => 'Rusticité, sols et conseils de culture';

  @override
  String get aboutSourceAspca =>
      'Toxicité des plantes pour les animaux domestiques';

  @override
  String aboutSpeciesCount(String count) {
    return '$count espèces consultables hors ligne';
  }

  @override
  String get supportTitle => 'Auxine est gratuite';

  @override
  String get supportBody =>
      'Toutes les fonctions sont accessibles. Aucun abonnement, aucune publicité, aucun compte obligatoire.';

  @override
  String get supportOffer =>
      'Si vous souhaitez néanmoins aider le développeur, un achat unique suffit.';

  @override
  String get supportOnce => 'Une seule fois';

  @override
  String supportGive(String price) {
    return 'Soutenir · $price';
  }

  @override
  String get supportRestore => 'Restaurer mon soutien';

  @override
  String get supportThanksTitle => 'Merci';

  @override
  String get supportThanksBody => 'Votre soutien est enregistré.';

  @override
  String get supportUnavailable =>
      'L\'achat n\'est pas disponible sur cet appareil.';

  @override
  String get supportFailed => 'L\'achat n\'a pas abouti.';

  @override
  String get supportNothingToRestore => 'Aucun soutien à restaurer.';

  @override
  String get supportSettings => 'Soutenir le développeur';

  @override
  String get supportFreeForever => 'Gratuite, sans limite';

  @override
  String get supportAlready => 'Merci pour votre soutien';

  @override
  String get supportNoThanks => 'Non merci';

  @override
  String get emptyGardenSubtitle => 'Ajoutez votre première plante.';

  @override
  String get finderTitle => 'Trouver une plante';

  @override
  String get finderEntryHint => 'Aide au choix';

  @override
  String get finderStepSpot => 'Emplacement';

  @override
  String get finderStepSpotHint => 'La lumière est le critère principal.';

  @override
  String get finderSpotBright => 'Pièce lumineuse';

  @override
  String get finderSpotMedium => 'Lumière moyenne';

  @override
  String get finderSpotDark => 'Coin sombre';

  @override
  String get finderSpotOutdoor => 'Dehors, balcon ou jardin';

  @override
  String get finderStepEffort => 'Quel entretien ?';

  @override
  String get finderStepEffortHint =>
      'Fréquence d\'arrosage que vous pouvez assurer.';

  @override
  String get finderEffortForgiving => 'Arrosage occasionnel';

  @override
  String get finderEffortNormal => 'Arrosage régulier';

  @override
  String get finderEffortAttentive => 'Entretien fréquent';

  @override
  String get finderStepSafety => 'Des animaux ou des enfants ?';

  @override
  String get finderStepSafetyHint =>
      'Beaucoup de plantes d\'intérieur sont toxiques si on les mordille.';

  @override
  String get finderSafetyYes => 'Oui, sans risque de préférence';

  @override
  String get finderSafetyNo => 'Pas de contrainte';

  @override
  String get finderNote => 'Précisions';

  @override
  String get finderNoteHint =>
      'Une salle de bain sans fenêtre, un chat qui mordille tout…';

  @override
  String get finderResults => 'Propositions';

  @override
  String get finderEmptyTitle => 'Aucun résultat';

  @override
  String get finderEmptySubtitle =>
      'Aucune espèce du catalogue ne correspond à tous les critères. Modifiez une réponse ou élargissez les genres de plantes.';

  @override
  String get finderRestart => 'Recommencer';

  @override
  String get finderAdd => 'Ajouter au jardin';

  @override
  String get finderAskAi => 'Demander à l\'IA';

  @override
  String get finderAiSection => 'Propositions de l\'IA';

  @override
  String get finderAiHint => 'Hors catalogue, à vérifier avant d\'acheter.';

  @override
  String get finderAiError => 'Aucune proposition de l\'IA.';

  @override
  String get finderReasonLight => 'Aime cette lumière';

  @override
  String get finderReasonLowLight => 'Supporte l\'ombre';

  @override
  String get finderReasonForgiving => 'Tolère les oublis d\'arrosage';

  @override
  String get finderReasonEasy => 'Facile';

  @override
  String get finderReasonSafe => 'Non toxique';

  @override
  String get finderReasonOutdoor => 'Tient dehors';

  @override
  String get finderAnyAnswer => 'Peu importe';

  @override
  String finderQuestionOf(int n, int total) {
    return 'Question $n sur $total';
  }

  @override
  String get finderSpotBrightHint => 'Près d\'une fenêtre, beaucoup de jour';

  @override
  String get finderSpotMediumHint => 'À quelques pas d\'une fenêtre';

  @override
  String get finderSpotDarkHint => 'Loin des fenêtres, peu de jour';

  @override
  String get finderSpotOutdoorHint => 'Balcon, terrasse ou jardin';

  @override
  String get finderEffortForgivingHint => 'Une plante qui tolère les oublis';

  @override
  String get finderEffortNormalHint => 'Un arrosage par semaine, à peu près';

  @override
  String get finderEffortAttentiveHint =>
      'Brumisation, rempotage, surveillance régulière';

  @override
  String get finderSafetyYesHint => 'Seulement des espèces non toxiques';

  @override
  String get finderSafetyNoHint => 'Toutes les espèces, toxiques comprises';

  @override
  String get finderTopPick => 'Premier choix';

  @override
  String get finderAlternatives => 'Autres propositions';

  @override
  String get finderChangeAnswer => 'Modifier cette réponse';

  @override
  String get finderChipSpotAny => 'Endroit : peu importe';

  @override
  String get finderChipEffortAny => 'Entretien : peu importe';

  @override
  String get finderChipSafe => 'Sans risque';

  @override
  String finderFactWater(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Eau tous les $count j',
      one: 'Eau chaque jour',
    );
    return '$_temp0';
  }

  @override
  String get finderAiTitle => 'Aller plus loin';

  @override
  String get finderAiBody =>
      'Recherche hors du catalogue, à partir de vos réponses et de ce que vous ajoutez ici.';

  @override
  String get finderPhotoSource =>
      'Photos : observations GBIF, libres de droits.';

  @override
  String get onbWelcomeTitle => 'Bienvenue sur Auxine';

  @override
  String get onbWelcomeBody => 'Le carnet d\'entretien de vos plantes.';

  @override
  String get careMatchAssisted => 'Complétée par l\'IA';

  @override
  String get careAssistedNote =>
      'Espèce absente du catalogue : ces repères viennent de l\'IA. Seul le nom scientifique a été envoyé. La toxicité n\'est pas renseignée.';

  @override
  String get careMatchEdited => 'Fiche retouchée';

  @override
  String get careEditedNote =>
      'Fiche corrigée à la main ; le reste vient du catalogue.';

  @override
  String careVerifiedFields(String source, String fields) {
    return 'Vérifié d\'après $source : $fields';
  }

  @override
  String get careSourceHabitat => 'habitat d\'origine';

  @override
  String get careSourceDerived => 'règle de culture';

  @override
  String get careStudio => 'Care Studio';

  @override
  String get careStudioHint =>
      'Corrigez une fiche d\'entretien. La retouche s\'applique sur cet appareil.';

  @override
  String get careStudioSearch => 'Chercher une espèce';

  @override
  String get careStudioPrompt => 'Cherchez une espèce pour corriger sa fiche.';

  @override
  String get careStudioEmpty => 'Aucune espèce ne correspond.';

  @override
  String get careStudioWateringSummer => 'Arrosage, pleine saison';

  @override
  String get careStudioWateringWinter => 'Arrosage, hiver';

  @override
  String get careStudioDamageBelow => 'Éviter sous';

  @override
  String get careStudioSave => 'Enregistrer';

  @override
  String get careStudioSaved => 'Retouche enregistrée';

  @override
  String get careStudioReset => 'Revenir au catalogue';

  @override
  String get careAssistSetting => 'Compléter les fiches avec l\'IA';

  @override
  String get careAssistHint =>
      'Pour une espèce absente du catalogue, le nom scientifique est envoyé à l\'IA pour compléter la fiche. Rien d\'autre ne quitte l\'appareil. La réponse est conservée.';

  @override
  String get gardensTitle => 'Mes jardins';

  @override
  String get gardensHint =>
      'Le jardin ouvert est celui affiché partout dans l\'application. Le passage de l\'un à l\'autre se fait ici.';

  @override
  String get gardenMine => 'Mon jardin';

  @override
  String get gardenUnnamed => 'Jardin partagé';

  @override
  String gardenSharedBy(String name) {
    return 'Partagé par $name';
  }

  @override
  String gardenOpened(String name) {
    return 'Jardin : $name';
  }

  @override
  String get someone => 'quelqu\'un';

  @override
  String memberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count membres',
      one: '1 membre',
    );
    return '$_temp0';
  }

  @override
  String get renameGarden => 'Renommer le jardin';

  @override
  String get renameGardenHint => 'Nom visible par les personnes invitées.';

  @override
  String get gardenNameHint => 'Le jardin de la maison';

  @override
  String get joinGarden => 'Rejoindre un jardin';

  @override
  String get joinGardenHint =>
      'Saisissez le code reçu, ou ouvrez le lien d\'invitation qu\'on vous a envoyé.';

  @override
  String get inviteCodeHint => 'Code d\'invitation';

  @override
  String get joinLook => 'Voir l\'invitation';

  @override
  String get joinConfirm => 'Rejoindre';

  @override
  String get joinInvalid =>
      'Ce code ne vaut plus rien. Il a déjà servi, a expiré, ou n\'existe pas.';

  @override
  String get joinWrongEmail =>
      'Cette invitation est réservée à une autre adresse e-mail.';

  @override
  String get joinNeedsAccount => 'Il faut un compte pour rejoindre un jardin.';

  @override
  String get joinSignInHint => 'Connexion avec votre identifiant Apple.';

  @override
  String joinInvitedBy(String name, String garden) {
    return '$name vous invite dans « $garden »';
  }

  @override
  String joinGardenName(String garden) {
    return 'Invitation dans « $garden »';
  }

  @override
  String get joinAsMember => 'Ajout, modification et suppression de plantes.';

  @override
  String get joinAsViewer => 'Consultation seule, sans modification.';

  @override
  String get joinAlreadyMember => 'Vous faites déjà partie de ce jardin.';

  @override
  String joined(String name) {
    return 'Jardin « $name » rejoint';
  }

  @override
  String get leaveGarden => 'Quitter ce jardin';

  @override
  String leaveGardenConfirm(String name) {
    return 'Vous n\'aurez plus accès à « $name ».';
  }

  @override
  String leftGarden(String name) {
    return 'Vous avez quitté « $name »';
  }

  @override
  String get deleteGarden => 'Supprimer le jardin';

  @override
  String deleteGardenConfirm(String name) {
    return 'Le jardin « $name », ses plantes et son journal seront supprimés, pour vous comme pour les personnes invitées.';
  }

  @override
  String gardenDeleted(String name) {
    return 'Jardin « $name » supprimé';
  }

  @override
  String get deleteGardenLast => 'Un compte garde au moins un jardin.';

  @override
  String get openGardenTitle => 'Vos jardins';

  @override
  String get openGardenHint =>
      'Ce compte donne accès à ces jardins. Ouvrez celui où sont vos plantes.';

  @override
  String get collaborationNeedsAccount =>
      'Il faut un compte pour partager un jardin';

  @override
  String get inviteSomeone => 'Inviter quelqu\'un';

  @override
  String get inviteReady => 'Invitation prête';

  @override
  String get inviteRoleHint =>
      'Membre : ajoute, modifie et supprime des plantes. Lecteur : consultation seule.';

  @override
  String get inviteEmailOptional => 'Adresse e-mail (facultatif)';

  @override
  String get inviteEmailHint =>
      'Si renseignée, seule cette adresse pourra accepter l\'invitation.';

  @override
  String get inviteCreate => 'Créer l\'invitation';

  @override
  String get inviteShareHint =>
      'Envoyez ce lien ou ce code. L\'application n\'est pas nécessaire pour le recevoir.';

  @override
  String get inviteShare => 'Partager le lien';

  @override
  String inviteMessage(String link) {
    return 'Invitation à rejoindre mon jardin sur Auxine : $link';
  }

  @override
  String get inviteOnceHint => 'Une invitation ne sert qu\'une fois.';

  @override
  String inviteExpires(String date) {
    return 'Expire le $date';
  }

  @override
  String get inviteFailed => 'Impossible de créer l\'invitation.';

  @override
  String get invitesTitle => 'Invitations en attente';

  @override
  String get inviteRevoke => 'Révoquer';

  @override
  String get inviteRevokeConfirm => 'Le code ne fonctionnera plus.';

  @override
  String get inviteRevoked => 'Invitation révoquée';

  @override
  String get membersHint =>
      'Les membres voient les mêmes plantes et peuvent s\'en occuper.';

  @override
  String get membersGuestHint => 'Jardin partagé par un autre utilisateur.';

  @override
  String get memberRoleHint =>
      'Membre : ajoute, modifie et supprime des plantes. Lecteur : consultation seule.';

  @override
  String makeRole(String role) {
    return 'Passer en « $role »';
  }

  @override
  String roleChanged(String name, String role) {
    return '$name est maintenant « $role »';
  }

  @override
  String removeMemberConfirm(String name) {
    return '$name n\'aura plus accès à ce jardin.';
  }

  @override
  String get photoFirstTitle => 'Première photo';

  @override
  String get photoNextTitle => 'Nouvelle photo';

  @override
  String get photoFirstHint => 'Elle servira de photo principale.';

  @override
  String get photoFrameHint =>
      'Gardez le même cadrage d\'une fois sur l\'autre pour suivre la croissance.';

  @override
  String get photoGhostToggle => 'Superposer la dernière photo';

  @override
  String get photoGhostHint =>
      'Alignez la plante sur la photo en transparence.';

  @override
  String get photoTitleStepTitle => 'Titre';

  @override
  String get photoTitleStepSubtitle => 'Facultatif.';

  @override
  String get photoTagNewLeaf => 'Nouvelle feuille';

  @override
  String get photoTagFlowering => 'Floraison';

  @override
  String get photoTagBeforeRepotting => 'Avant rempotage';

  @override
  String get photoTagAfterRepotting => 'Après rempotage';

  @override
  String get photoTagCutting => 'Bouture';

  @override
  String get photoTagAfterPruning => 'Après taille';

  @override
  String get mainPhotoHint => 'Affichée sur la fiche et dans la liste.';

  @override
  String get retake => 'Reprendre';

  @override
  String get growthEmptySubtitle =>
      'Ajoutez des photos régulièrement pour suivre la croissance.';

  @override
  String growthSummary(int count, String since) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos · depuis $since',
      one: '1 photo · depuis $since',
    );
    return '$_temp0';
  }

  @override
  String growthNudge(String date) {
    return 'Dernière photo le $date.';
  }

  @override
  String get timelapse => 'Timelapse';

  @override
  String get beforeAfter => 'Avant / après';

  @override
  String photoCounter(int index, int total) {
    return '$index / $total';
  }

  @override
  String get photoTitleShort => 'Titre';

  @override
  String get mainPhotoShort => 'Principale';

  @override
  String get share => 'Partager';

  @override
  String get addTitle => 'Ajouter un titre';

  @override
  String get swap => 'Inverser';

  @override
  String get pause => 'Pause';

  @override
  String get stepPhotoDoneTitle => 'Aperçu';

  @override
  String stepPhotoDoneSubtitle(String name) {
    return 'Une feuille de près aide $name à reconnaître l\'espèce.';
  }

  @override
  String get stepPhotoDonePlain =>
      'Vous pourrez en ajouter d\'autres depuis sa fiche.';

  @override
  String get viewPlant => 'La plante';

  @override
  String get viewLeafClose => 'Une feuille de près';

  @override
  String get viewAnother => 'Autre vue';

  @override
  String viewForModel(String name) {
    return 'Utilisée par $name pour reconnaître l\'espèce, non conservée.';
  }

  @override
  String get strategyWeather => 'Météo';

  @override
  String get strategyWeatherHint =>
      'L\'intervalle de la saison, resserré par la chaleur sèche, espacé par la pluie et le froid.';

  @override
  String strategyWeatherNow(String interval) {
    return 'Avec le temps de la semaine : $interval';
  }

  @override
  String get strategyWeatherNoPlace =>
      'Sans lieu météo, l\'intervalle reste celui de la saison.';

  @override
  String get weatherWhenTonight => 'cette nuit';

  @override
  String get weatherWhenToday => 'aujourd\'hui';

  @override
  String get weatherWhenTomorrow => 'demain';

  @override
  String weatherWhenInDays(int count) {
    return 'dans $count jours';
  }

  @override
  String weatherFrostTitle(String when, String temp) {
    return 'Gel $when · $temp';
  }

  @override
  String weatherHeatTitle(String when, String temp) {
    return 'Chaleur $when · $temp';
  }

  @override
  String weatherFrostBody(String names) {
    return 'À rentrer ou à couvrir : $names.';
  }

  @override
  String weatherHeatBody(String names) {
    return 'À mettre à l\'ombre, et à arroser tôt : $names.';
  }

  @override
  String weatherAlertMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'et $count autres',
      one: 'et 1 autre',
    );
    return '$_temp0';
  }

  @override
  String weatherAlertFamily(String name) {
    return 'la famille des $name';
  }

  @override
  String notifFrost(String when, String names) {
    return 'Gel $when · à rentrer ou à couvrir : $names.';
  }

  @override
  String notifHeat(String when, String names) {
    return 'Chaleur $when · à mettre à l\'ombre : $names.';
  }

  @override
  String weatherRainFallenTitle(String mm) {
    return 'Pluie · $mm mm';
  }

  @override
  String weatherRainWatered(String names) {
    return 'Arrosage noté fait pour $names.';
  }

  @override
  String weatherRainWaterable(String names) {
    return 'La pluie vaut l\'arrosage de $names.';
  }

  @override
  String get weatherRainMarkWatered => 'Noter arrosé';

  @override
  String weatherRainWateredToast(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count arrosages notés',
      one: '1 arrosage noté',
    );
    return '$_temp0';
  }

  @override
  String weatherRainNote(String mm) {
    return 'Arrosée par la pluie ($mm mm).';
  }

  @override
  String get weatherRainCounts => 'La pluie compte comme un arrosage';

  @override
  String get weatherRainCountsHint =>
      'Au-delà de 5 mm sur trois jours, l\'arrosage des emplacements extérieurs est noté fait. Coupé, l\'écran du matin le propose en un tap. Un pot abrité par un feuillage reçoit moins de pluie.';

  @override
  String get weatherClimate => 'Climat';

  @override
  String get weatherClimateHint =>
      'Les propositions de plantes pour l\'extérieur suivent les hivers et les étés du lieu.';

  @override
  String weatherClimateZone(String zone) {
    return 'Zone $zone';
  }

  @override
  String weatherClimateRange(String low, String high) {
    return 'Hivers à $low, étés à $high';
  }

  @override
  String get weatherClimateNone => 'Inconnu';

  @override
  String get finderReasonHardy => 'Passe l\'hiver dehors ici';

  @override
  String get finderReasonSheltered => 'Hiverne dehors, protégée';

  @override
  String finderRegion(String zone, String low) {
    return 'Zone $zone · hivers à $low';
  }

  @override
  String get encyclopediaTitle => 'Encyclopédie';

  @override
  String get encyclopediaHint =>
      'Les problèmes de la base, les espèces du catalogue et le vocabulaire des fiches d\'entretien.';

  @override
  String get encyclopediaProblems => 'Problèmes';

  @override
  String get encyclopediaSpecies => 'Espèces';

  @override
  String get encyclopediaGlossary => 'Vocabulaire';

  @override
  String get encyclopediaSearchProblems => 'Nom, ravageur, maladie…';

  @override
  String get encyclopediaSearchGlossary => 'Lumière, substrat, bouture…';

  @override
  String encyclopediaProblemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count problèmes',
      one: '1 problème',
      zero: 'Aucun problème',
    );
    return '$_temp0';
  }

  @override
  String encyclopediaSpeciesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count espèces',
      one: '1 espèce',
      zero: 'Aucune espèce',
    );
    return '$_temp0';
  }

  @override
  String get encyclopediaNoTerm => 'Aucun terme trouvé';

  @override
  String problemNumber(String id) {
    return 'Entrée $id';
  }

  @override
  String get problemScope => 'Étendue';

  @override
  String get problemScopeGeneral => 'Toutes les plantes';

  @override
  String get problemScopeWide => 'Nombreux hôtes';

  @override
  String get problemScopeTarget => 'Hôtes ciblés';

  @override
  String get problemScopeGeneralNote =>
      'Possible sur les plantes vasculaires, selon les conditions et le stade.';

  @override
  String get problemScopeWideNote =>
      'Nombreux hôtes ; les taxons cités sont des exemples.';

  @override
  String get problemScopeTargetNote =>
      'Hôtes principaux d\'un groupe cible ; la liste n\'est pas exhaustive.';

  @override
  String get problemOtherNames => 'Autres noms';

  @override
  String get problemOtherNamesNote =>
      'Noms courants et scientifiques qui désignent la même chose.';

  @override
  String get problemHosts => 'Hôtes';

  @override
  String get problemHostsAll => 'Toutes les plantes vasculaires';

  @override
  String get problemHostsNote =>
      'Un genre ou une famille ne rend pas toutes ses espèces sensibles.';

  @override
  String get problemInGarden => 'Dans le jardin';

  @override
  String get problemKindsTitle => 'Familles de problèmes';

  @override
  String get problemKindDisorderNote =>
      'Ni ravageur ni maladie : l\'eau, la lumière, le froid, le substrat, une carence.';

  @override
  String get problemKindPestNote =>
      'Un être vivant qui s\'attaque à la plante : insecte, acarien, limace, nématode.';

  @override
  String get problemKindDiseaseNote =>
      'Un champignon, une bactérie, un virus ou un phytoplasme installé dans la plante.';

  @override
  String get problemKindConditionNote =>
      'Ni l\'un ni l\'autre : la fumagine pousse sur le miellat, sans s\'attaquer à la plante.';

  @override
  String get careLightShadeNote =>
      'Loin des fenêtres, sans rayon direct de la journée.';

  @override
  String get careLightLowNote =>
      'Une pièce claire mais éloignée de la fenêtre, ou exposée au nord.';

  @override
  String get careLightIndirectNote =>
      'À quelques pas d\'une fenêtre, ou derrière un voilage.';

  @override
  String get careLightBrightNote =>
      'Près d\'une fenêtre, hors du rayon du soleil.';

  @override
  String get careLightSomeNote =>
      'Le soleil du matin ou de fin de journée, pas celui de midi.';

  @override
  String get careLightFullNote =>
      'Six heures de soleil direct ou plus, en pleine journée.';

  @override
  String get careHumidityLowNote =>
      'L\'air d\'un logement chauffé lui convient.';

  @override
  String get careHumidityAverageNote =>
      'Autour de 50 %, loin d\'un radiateur en hiver.';

  @override
  String get careHumidityHighNote =>
      'Au-delà de 60 % : salle de bains, cuisine, ou un plateau de billes d\'argile humides.';

  @override
  String get careDifficultyEasyNote =>
      'Supporte les oublis et les écarts de lumière.';

  @override
  String get careDifficultyMediumNote =>
      'Demande un rythme d\'arrosage régulier et un emplacement stable.';

  @override
  String get careDifficultyDemandingNote =>
      'Lumière, humidité et arrosage demandent d\'être suivis de près.';

  @override
  String get careToxicSafeNote =>
      'Aucune toxicité connue pour les animaux ni les enfants.';

  @override
  String get careToxicMildNote => 'La sève irrite la peau et la bouche.';

  @override
  String get careToxicToxicNote =>
      'Avaler une feuille ou un fruit rend malade.';

  @override
  String get careToxicUnknownNote =>
      'Rien n\'est renseigné pour cette espèce ; à tenir hors de portée par précaution.';

  @override
  String get careSoilStandardNote =>
      'Le terreau vendu pour les plantes vertes, sans ajout.';

  @override
  String get careSoilDrainingNote =>
      'Terreau allégé de perlite, de sable ou de pouzzolane.';

  @override
  String get careSoilCactusNote =>
      'Très minéral : l\'eau traverse sans stagner.';

  @override
  String get careSoilOrchidNote =>
      'Des écorces grossières : les racines vivent à l\'air.';

  @override
  String get careSoilAcidicNote =>
      'Un pH acide, pour les plantes que le calcaire jaunit.';

  @override
  String get careSoilRichNote =>
      'Terreau enrichi de compost, pour les plantes gourmandes.';

  @override
  String get careSoilNoneNote =>
      'Les racines tiennent dans l\'eau, ou sur un support sans terre.';

  @override
  String get carePropCuttingNote =>
      'Une tige coupée sous un nœud, plantée dans un substrat humide.';

  @override
  String get carePropLeafNote =>
      'Une feuille entière, ou un fragment, posée sur le substrat.';

  @override
  String get carePropDivisionNote =>
      'La touffe se sépare en deux au rempotage, racines comprises.';

  @override
  String get carePropOffsetsNote =>
      'Les jeunes pousses nées au pied se détachent une fois enracinées.';

  @override
  String get carePropLayeringNote =>
      'Une tige enracinée alors qu\'elle tient encore à la plante mère.';

  @override
  String get carePropSeedNote =>
      'Des graines semées, plus lentes qu\'une bouture et souvent moins fidèles.';

  @override
  String get carePropWaterNote =>
      'La bouture patiente dans un verre d\'eau, le temps que les racines partent.';

  @override
  String get carePropTuberNote =>
      'Le tubercule se coupe en morceaux portant chacun un œil.';

  @override
  String get communityTipsTitle => 'Conseils de la communauté';

  @override
  String get communityTipsHint =>
      'Ce que d\'autres personnes ont observé en gardant cette espèce, hors du catalogue.';

  @override
  String get communityTipsEmpty => 'Aucun conseil sur cette espèce.';

  @override
  String get offlineCommunityTips =>
      'Lire et publier des conseils demande une connexion.';

  @override
  String get communityTipWrite => 'Écrire un conseil';

  @override
  String get communityTipYours => 'Votre conseil';

  @override
  String get communityTipPlaceholder =>
      'Ce qui a marché sur cette plante, en quelques phrases.';

  @override
  String get communityTipPublicNote =>
      'Le conseil paraît sous votre nom sur la fiche de cette espèce, pour tout le monde.';

  @override
  String communityTipLength(int used, int max) {
    return '$used / $max';
  }

  @override
  String get communityTipPublish => 'Publier';

  @override
  String get communityTipPublished => 'Conseil publié.';

  @override
  String get communityTipNeedsAccount =>
      'Publier un conseil demande un compte.';

  @override
  String get communityTipAnonymous => 'Anonyme';

  @override
  String get communityTipHelpful => 'Utile';

  @override
  String get communityTipReport => 'Signaler';

  @override
  String get communityTipReported => 'Conseil signalé.';

  @override
  String communityTipReportNote(int count) {
    return 'Un conseil signalé par $count personnes ne paraît plus.';
  }

  @override
  String get communityTipHidden => 'Signalé : les autres ne le voient plus.';

  @override
  String get confirmDeleteTip => 'Supprimer ce conseil ?';

  @override
  String get confirmReportTip => 'Signaler ce conseil ?';

  @override
  String get moderationTitle => 'Modération';

  @override
  String get moderationHint =>
      'Les conseils signalés, du plus signalé au moins signalé.';

  @override
  String get moderationEmpty => 'Aucun conseil signalé.';

  @override
  String moderationReports(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count signalements',
      one: '1 signalement',
    );
    return '$_temp0';
  }

  @override
  String get moderationHide => 'Masquer';

  @override
  String get moderationRestore => 'Rétablir';

  @override
  String get confirmRestoreTip =>
      'Rétablir ce conseil ? Ses signalements sont effacés.';
}
