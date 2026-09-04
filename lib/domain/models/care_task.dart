import '../care/care_engine.dart';
import 'care_schedule.dart';
import 'plant_summary.dart';

/// Un soin à faire (écran Aujourd'hui) : une routine échue pour une plante.
class CareTask {
  const CareTask({required this.summary, required this.schedule});

  final PlantSummary summary;
  final CareSchedule schedule;

  String get plantId => summary.plant.id;
  String get typeKey => schedule.typeKey;
  DateTime? get dueAt => schedule.nextDueAt;

  DueStatus status(DateTime now) => CareEngine.status(dueAt, now);
}
