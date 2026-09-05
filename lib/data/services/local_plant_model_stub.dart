import '../../domain/identification/local_plant_model.dart';

/// Web, et toute plateforme sans `dart:ffi` : pas de modèle embarqué.
LocalPlantModel createLocalPlantModel() => const NoLocalModel();
