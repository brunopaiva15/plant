import '../../domain/identification/comparison_model.dart';
import '../../domain/identification/local_plant_model.dart';
import 'tflite_plant_model.dart';

/// iOS, Android, bureau : le modèle TensorFlow Lite livré dans les assets.
LocalPlantModel createLocalPlantModel() => TflitePlantModel();

/// Un modèle de comparaison : le même moteur, ses propres assets, rangés
/// sous `assets/model/<key>/`. Le graphe porte sa normalisation comme celui
/// d'Iris, et `model.json` sa recette de cadrage : rien d'autre ne distingue
/// les modèles côté application.
LocalPlantModel createComparisonPlantModel(ComparisonModel model) => TflitePlantModel(
      modelAsset: 'assets/model/${model.key}/plants.tflite',
      labelsAsset: 'assets/model/${model.key}/labels.txt',
      metaAsset: 'assets/model/${model.key}/model.json',
    );
