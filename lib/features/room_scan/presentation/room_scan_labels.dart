import '../../../domain/room/placement.dart';
import '../../../domain/room/room_fit_advisor.dart';
import '../../../domain/room/scanned_room.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Les mots du relevé : points cardinaux, types de pièce, et la phrase
/// d'une place. Les faits viennent du domaine, la langue d'ici.
extension RoomScanLabels on AppLocalizations {
  String directionName(CardinalDirection d) => switch (d) {
        CardinalDirection.north => directionNorth,
        CardinalDirection.northEast => directionNorthEast,
        CardinalDirection.east => directionEast,
        CardinalDirection.southEast => directionSouthEast,
        CardinalDirection.south => directionSouth,
        CardinalDirection.southWest => directionSouthWest,
        CardinalDirection.west => directionWest,
        CardinalDirection.northWest => directionNorthWest,
      };

  String sectionName(RoomSectionLabel s) => switch (s) {
        RoomSectionLabel.bathroom => roomSectionBathroom,
        RoomSectionLabel.bedroom => roomSectionBedroom,
        RoomSectionLabel.diningRoom => roomSectionDiningRoom,
        RoomSectionLabel.kitchen => roomSectionKitchen,
        RoomSectionLabel.laundryRoom => roomSectionLaundryRoom,
        RoomSectionLabel.livingRoom => roomSectionLivingRoom,
      };

  /// « 80 cm », « 1 m », « 1,5 m » : au demi-mètre au-delà d'un mètre, au
  /// décimètre en deçà — une place ne se mesure pas au centimètre.
  String distanceLabel(double meters) {
    if (meters < 1) return placementDistanceCm((meters * 10).round() * 10);
    final half = (meters * 2).round() / 2;
    final text = half == half.roundToDouble() ? half.round().toString() : half.toStringAsFixed(1).replaceAll('.', localeName == 'en' ? '.' : ',');
    return placementDistanceM(text);
  }

  /// Le repère d'une place : « à 1 m de la fenêtre sud-ouest », « sur la
  /// table », « au fond, loin des fenêtres ».
  String placementLine(Placement p) => _spotLine(p.surface, p.windowDirection, p.windowDistance, p.deepInRoom);

  /// Le même repère pour une place lue sans fiche — là où une plante est
  /// posée aujourd'hui.
  String spotLine(SurveyedSpot s) => _spotLine(s.surface, s.windowDirection, s.windowDistance, s.windowIndex == null || (s.windowDistance ?? 0) > 3.0);

  String _spotLine(PlacementSurface surface, CardinalDirection? windowDirection, double? windowDistance, bool deepInRoom) {
    final direction = windowDirection == null ? null : directionName(windowDirection);
    switch (surface) {
      case PlacementSurface.sill:
        return direction == null ? placementOnSillUnknown : placementOnSill(direction);
      case PlacementSurface.table:
        return placementOnTable;
      case PlacementSurface.storage:
        return placementOnStorage;
      case PlacementSurface.floor:
        if (deepInRoom || windowDistance == null) return placementDeepInRoom;
        final d = distanceLabel(windowDistance);
        return direction == null ? placementNearWindowUnknown(d) : placementNearWindow(d, direction);
    }
  }

  String dressingName(WindowDressing d) => switch (d) {
        WindowDressing.none => roomScanCurtainNone,
        WindowDressing.sheer => roomScanCurtainSheer,
        WindowDressing.drawn => roomScanCurtainDrawn,
      };

  String verdictLine(RoomFitVerdict v) => switch (v) {
        RoomFitVerdict.good => placementVerdictGood,
        RoomFitVerdict.acceptable => placementVerdictAcceptable,
        RoomFitVerdict.unsuitable => placementVerdictUnsuitable,
      };

  String shortfallLine(RoomFitShortfall s) => switch (s) {
        RoomFitShortfall.tooDark => placementShortfallTooDark,
        RoomFitShortfall.tooBright => placementShortfallTooBright,
        RoomFitShortfall.drafty => placementShortfallDrafty,
        RoomFitShortfall.tooDry => placementShortfallTooDry,
        RoomFitShortfall.heater => placementShortfallHeater,
      };

  /// Ce qu'une place a de particulier, sous sa lumière : l'air qui bouge,
  /// le radiateur à côté.
  List<String> placementNotes(Placement p) => [
        if (p.drafty) placementDraftyNote,
        if (p.nearHeater) placementHeaterNote,
      ];
}
