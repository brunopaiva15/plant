import '../care/care_engine.dart';
import 'plant.dart';

/// Vue « liste » d'une plante : ce qu'il faut pour une carte, sans requête
/// supplémentaire (emplacement, miniature, prochain soin).
class PlantSummary {
  const PlantSummary({
    required this.plant,
    this.locationName,
    this.thumbPath,
    this.nextDueAt,
    this.nextDueTypeKey,
    this.tags = const [],
  });

  final Plant plant;
  final String? locationName;
  final String? thumbPath;
  final DateTime? nextDueAt;
  final String? nextDueTypeKey;
  final List<String> tags;

  DueStatus dueStatus(DateTime now) => CareEngine.status(nextDueAt, now);
}
