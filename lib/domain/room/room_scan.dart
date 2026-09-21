import 'scanned_room.dart';

/// Un relevé de pièce : une ligne en base, un fichier JSON dans les
/// documents de l'application. Le fichier ne se synchronise pas et ne
/// quitte pas l'appareil.
class RoomScan {
  const RoomScan({
    required this.id,
    required this.gardenId,
    required this.name,
    required this.capturedAt,
    required this.filePath,
    required this.floorAreaM2,
    required this.createdAt,
    required this.updatedAt,
    this.locationId,
    this.northOffsetDeg,
    this.section,
    this.structureId,
  });

  final String id;
  final String gardenId;

  /// L'emplacement (« Salon ») que ce relevé décrit, quand il est lié.
  final String? locationId;
  final String name;
  final DateTime capturedAt;

  /// Le cap du nord dans le repère du relevé ; `null` si la boussole n'a
  /// rien donné de stable.
  final double? northOffsetDeg;

  /// Le chemin du JSON, relatif au dossier des relevés.
  final String filePath;
  final double floorAreaM2;
  final RoomSectionLabel? section;

  /// Les pièces d'un même relevé d'appartement partagent cet identifiant.
  final String? structureId;
  final DateTime createdAt;
  final DateTime updatedAt;

  RoomScan copyWith({String? name, String? Function()? locationId, RoomSectionLabel? Function()? section}) => RoomScan(
        id: id,
        gardenId: gardenId,
        name: name ?? this.name,
        capturedAt: capturedAt,
        filePath: filePath,
        floorAreaM2: floorAreaM2,
        createdAt: createdAt,
        updatedAt: updatedAt,
        locationId: locationId != null ? locationId() : this.locationId,
        northOffsetDeg: northOffsetDeg,
        section: section != null ? section() : this.section,
        structureId: structureId,
      );
}

/// Ce que la main ajoute au relevé, séparé de ce que le capteur a vu :
/// refaire un relevé ne perd pas les repères.
enum RoomMarkerKind {
  /// L'orientation confirmée d'une fenêtre, indexée par son rang dans le JSON.
  windowOrientation,

  /// Un radiateur posé sur le plan.
  heater,

  /// La place actuelle d'une plante.
  plant,

  /// Un voilage devant une fenêtre, indexée par son rang dans le JSON.
  windowSheer,

  /// Un rideau ou un store souvent tiré devant une fenêtre.
  windowDrawn,

  /// Une fenêtre que la main a ajoutée, à sa taille : le relevé manque
  /// celles qu'un rideau tiré cache. La taille est dans le genre, comme
  /// pour le voilage et le rideau — la base ne porte pas de dimensions.
  windowSmall,
  windowStandard,
  windowWide;

  static RoomMarkerKind? decode(String? raw) => values.where((k) => k.name == raw).firstOrNull;

  /// La taille de la fenêtre que ce genre porte ; `null` quand le repère
  /// n'est pas une fenêtre ajoutée à la main.
  HandWindow? get handWindow => switch (this) {
        windowSmall => HandWindow.small,
        windowStandard => HandWindow.standard,
        windowWide => HandWindow.wide,
        _ => null,
      };

  /// Le genre de repère d'une taille de fenêtre.
  static RoomMarkerKind of(HandWindow size) => switch (size) {
        HandWindow.small => windowSmall,
        HandWindow.standard => windowStandard,
        HandWindow.wide => windowWide,
      };
}

class RoomMarker {
  const RoomMarker({
    required this.id,
    required this.scanId,
    required this.kind,
    required this.x,
    required this.z,
    required this.createdAt,
    required this.updatedAt,
    this.windowIndex,
    this.orientation,
    this.plantId,
  });

  final String id;
  final String scanId;
  final RoomMarkerKind kind;
  final double x;
  final double z;
  final int? windowIndex;
  final CardinalDirection? orientation;
  final String? plantId;
  final DateTime createdAt;
  final DateTime updatedAt;
}

/// Les orientations à donner au modèle : la fenêtre confirmée prime sur la
/// boussole, et une fenêtre sans rien reste inconnue.
List<CardinalDirection?> windowDirections(ScannedRoom room, List<RoomMarker> markers) => [
      for (var i = 0; i < room.windows.length; i++)
        markers.where((m) => m.kind == RoomMarkerKind.windowOrientation && m.windowIndex == i).firstOrNull?.orientation ??
            room.windowDirection(room.windows[i]),
    ];

/// Les repères des fenêtres ajoutées à la main, dans l'ordre où elles se
/// posent — celui où elles s'ajoutent aux fenêtres du relevé.
List<RoomMarker> handWindowMarkers(List<RoomMarker> markers) => [
      for (final m in markers)
        if (m.kind.handWindow != null) m,
    ];

/// Les fenêtres que la main a ajoutées à une pièce, couchées sur le mur le
/// plus proche du point où on les a posées. [ScannedRoom.withWindows] les
/// met à la suite des fenêtres du relevé : les rangs du JSON tiennent, et
/// l'orientation comme le rideau continuent de s'indexer par le rang.
List<RoomSurface> handWindows(ScannedRoom room, List<RoomMarker> markers) => [
      for (final m in handWindowMarkers(markers))
        ?room.handWindowAt(RoomPoint(m.x, m.z), m.kind.handWindow!),
    ];

/// Le repère de la fenêtre de rang [index] d'une pièce complétée, quand
/// c'est la main qui l'a ajoutée ; `null` pour une fenêtre du relevé.
RoomMarker? handWindowMarkerAt(ScannedRoom room, List<RoomMarker> markers, int index) {
  if (index >= room.windows.length || !room.windows[index].byHand) return null;
  final rank = room.windows.take(index).where((w) => w.byHand).length;
  final hands = handWindowMarkers(markers);
  return rank < hands.length ? hands[rank] : null;
}

/// Les radiateurs posés sur le plan.
List<RoomPoint> heaterPoints(List<RoomMarker> markers) => [
      for (final m in markers)
        if (m.kind == RoomMarkerKind.heater) RoomPoint(m.x, m.z),
    ];

/// Les plantes posées sur le plan, par identifiant de plante.
Map<String, RoomPoint> plantPoints(List<RoomMarker> markers) => {
      for (final m in markers)
        if (m.kind == RoomMarkerKind.plant && m.plantId != null) m.plantId!: RoomPoint(m.x, m.z),
    };

/// Ce qui habille chaque fenêtre, dans l'ordre des fenêtres : rien, un
/// voilage, ou un rideau souvent tiré.
List<WindowDressing> windowDressings(ScannedRoom room, List<RoomMarker> markers) => [
      for (var i = 0; i < room.windows.length; i++)
        markers.any((m) => m.kind == RoomMarkerKind.windowDrawn && m.windowIndex == i)
            ? WindowDressing.drawn
            : markers.any((m) => m.kind == RoomMarkerKind.windowSheer && m.windowIndex == i)
                ? WindowDressing.sheer
                : WindowDressing.none,
    ];
