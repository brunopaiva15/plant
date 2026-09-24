import '../../domain/identification/local_plant_model.dart';
import 'tflite_plant_model.dart';

/// iOS, Android, bureau : le modèle TensorFlow Lite livré dans les assets.
LocalPlantModel createLocalPlantModel() => TflitePlantModel();

/// Pl@ntNet-300K : le même moteur, ses propres assets. Le graphe porte sa
/// normalisation comme celui d'Iris, et `model.json` sa recette de cadrage :
/// rien d'autre ne distingue les deux côté application.
LocalPlantModel createComparisonPlantModel() => TflitePlantModel(
      modelAsset: 'assets/model/plantnet300k/plants.tflite',
      labelsAsset: 'assets/model/plantnet300k/labels.txt',
      metaAsset: 'assets/model/plantnet300k/model.json',
    );
