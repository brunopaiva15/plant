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
  plant;

  static RoomMarkerKind? decode(String? raw) => values.where((k) => k.name == raw).firstOrNull;
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
