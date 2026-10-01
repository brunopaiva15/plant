import '../../domain/identification/local_plant_model.dart';
import 'fused_plant_model.dart';

/// iOS, Android, bureau : Iris 10, la fusion d'Iris 9 et de l'encodeur
/// distillé, livrés dans les assets — Iris 9 seul si Iris 10 manque.
LocalPlantModel createLocalPlantModel() => FusedPlantModel();
