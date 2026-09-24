import '../../domain/identification/comparison_model.dart';
import '../../domain/identification/local_plant_model.dart';

/// Web, et toute plateforme sans `dart:ffi` : pas de modèle embarqué.
LocalPlantModel createLocalPlantModel() => const NoLocalModel();

/// Ni Iris ni modèle de comparaison : sans `dart:ffi`, pas de comparaison.
LocalPlantModel createComparisonPlantModel(ComparisonModel model) => const NoLocalModel();
