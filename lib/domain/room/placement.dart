import '../care/care_profile.dart';
import 'scanned_room.dart';

/// Sur quoi la plante se pose.
enum PlacementSurface { floor, table, storage, sill }

/// Une place dans une pièce relevée, et ce qui la motive.
///
/// Les raisons sont des faits, pas des phrases : l'écran les dit dans la
/// langue de l'interface, les ARB en tiennent les mots.
class Placement {
  const Placement({
    required this.point,
    required this.surface,
    required this.light,
    required this.score,
    required this.drafty,
    required this.humidRoom,
    this.windowIndex,
    this.windowDistance,
    this.windowDirection,
  });

  final RoomPoint point;
  final PlacementSurface surface;

  /// La lumière lue à cet endroit.
  final LightNeed light;

  /// De 0 à 1 : ce que la place vaut pour la fiche.
  final double score;
  final bool drafty;
  final bool humidRoom;

  /// La fenêtre la plus proche qui se voit d'ici, et sa distance en mètres.
  final int? windowIndex;
  final double? windowDistance;
  final CardinalDirection? windowDirection;

  /// Loin de toute fenêtre visible : le repère est le fond de la pièce.
  bool get deepInRoom => windowIndex == null || (windowDistance ?? 0) > 3.0;
}

/// Ce que la pièce vaut pour la plante, en un mot.
enum RoomFitVerdict {
  /// Une place au moins convient sans réserve.
  good,

  /// Le mieux qu'on trouve laisse à désirer : la fiche le dit.
  acceptable,

  /// Rien ne convient : trop sombre, trop de soleil, ou trop exposé.
  unsuitable,
}

/// Pourquoi une pièce ne convient pas, quand c'est le cas.
enum RoomFitShortfall { tooDark, tooBright, drafty, tooDry }

class RoomFit {
  const RoomFit({required this.verdict, required this.placements, this.shortfall, this.all = const []});

  final RoomFitVerdict verdict;

  /// Les places retenues, de la meilleure à la troisième.
  final List<Placement> placements;
  final RoomFitShortfall? shortfall;

  /// Toutes les places évaluées, pour le lavis de lumière du plan.
  final List<Placement> all;

  static const empty = RoomFit(verdict: RoomFitVerdict.unsuitable, placements: []);
}
