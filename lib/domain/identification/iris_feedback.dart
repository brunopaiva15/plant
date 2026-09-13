import 'dart:io';

import 'plant_identifier.dart';

/// Ce qu'une identification laisse derrière elle quand la personne
/// enregistre : les photos, ce qu'Iris croyait, ce qui a été retenu.
///
/// Le geste d'enregistrer étiquette la photo sans rien demander de plus. Et
/// il en dit plus long que « Iris s'est trompé » : selon d'où vient le nom
/// retenu, la même photo apprend trois choses différentes ([FeedbackKind]).
/// Rien de tout ça ne quitte l'appareil sans le consentement des réglages
/// d'identification, et rien ne retient jamais l'enregistrement de la plante.
class IrisFeedback {
  const IrisFeedback({
    required this.photos,
    required this.local,
    required this.chosenName,
    required this.chosenSource,
    required this.modelVersion,
    this.chosenId,
    this.remoteTop,
  });

  /// Les photos prises pour identifier, une à trois — une observation.
  final List<File> photos;

  /// Ce qu'Iris proposait, dans l'ordre. Vide si le modèle local n'a pas
  /// tourné : il n'y a alors rien à lui apprendre.
  final List<IdentificationCandidate> local;

  /// Le nom scientifique enregistré, et son identifiant interne s'il est
  /// connu.
  final String chosenName;
  final String? chosenId;

  /// D'où vient le nom retenu.
  final ChosenSource chosenSource;

  /// La réponse de Pl@ntNet quand c'est elle qui a été retenue : son score
  /// dit si l'étiquette est solide (§ 13.5 de docs/09).
  final IdentificationCandidate? remoteTop;

  /// La version d'Iris qui s'est prononcée — le retour n'a de sens que
  /// rapporté à elle.
  final String modelVersion;

  FeedbackKind get kind => feedbackKind(local, chosenName, chosenSource);
}

/// Comment le nom retenu se situe par rapport à ce qu'Iris proposait.
enum FeedbackKind {
  /// Pris ailleurs — Pl@ntNet ou le sélecteur d'espèces. Iris s'était
  /// trompé, et la ligne dit pour quoi il avait pris la plante.
  corrigee,

  /// La première proposition d'Iris, acceptée. Une photo du bon domaine,
  /// celle qui manque au jeu d'entraînement (§ 13.1 de docs/09).
  confirmee,

  /// Une proposition d'Iris, mais pas la première : une erreur de rang.
  reclassee,
}

/// D'où vient le nom retenu.
enum ChosenSource {
  /// Une candidate d'Iris.
  local,

  /// Une candidate de Pl@ntNet, après « Recherche en ligne ».
  remote,

  /// Le sélecteur d'espèces, sans candidate.
  picker,
}

/// Le type de retour, à partir de ce qu'Iris proposait et de ce qui a été
/// retenu. Une candidate dite locale mais absente de la liste est traitée
/// comme une correction : on ne peut pas la confirmer.
FeedbackKind feedbackKind(List<IdentificationCandidate> local, String chosenName, ChosenSource source) {
  if (source != ChosenSource.local) return FeedbackKind.corrigee;
  final rank = local.indexWhere((c) => c.scientificName == chosenName);
  if (rank == 0) return FeedbackKind.confirmee;
  if (rank > 0) return FeedbackKind.reclassee;
  return FeedbackKind.corrigee;
}

/// Où partent les retours. Nulle part sans consentement, sans compte
/// distant ou sans Supabase — c'est le fournisseur qui choisit.
abstract class IrisFeedbackRecorder {
  Future<void> record(IrisFeedback feedback);
}

/// Ne fait rien : le cas par défaut, et celui des tests.
class NoFeedbackRecorder implements IrisFeedbackRecorder {
  const NoFeedbackRecorder();

  @override
  Future<void> record(IrisFeedback feedback) async {}
}
