import '../../domain/identification/local_plant_model.dart';
import 'tflite_plant_model.dart';

/// iOS, Android, bureau : le modèle TensorFlow Lite livré dans les assets.
LocalPlantModel createLocalPlantModel() => TflitePlantModel();
