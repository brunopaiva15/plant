import '../../domain/identification/local_plant_model.dart';
import 'local_plant_model_stub.dart' if (dart.library.io) 'local_plant_model_io.dart' as platform;

/// Le modèle embarqué de la plateforme, choisi à la compilation.
///
/// TensorFlow Lite passe par `dart:ffi`, qui n'existe pas sur le web : un
/// simple garde `kIsWeb` à l'exécution ne suffit pas, l'import lui-même fait
/// échouer la compilation web. L'aiguillage se fait donc ici, par import
/// conditionnel — le web reçoit une implémentation qui se déclare absente,
/// et la cascade passe directement au service distant.
LocalPlantModel createLocalPlantModel() => platform.createLocalPlantModel();

/// Pl@ntNet-300K, le modèle qu'on mesure contre Iris (§ 15 de `docs/09`).
/// Même moteur, mêmes contraintes de plateforme.
LocalPlantModel createComparisonPlantModel() => platform.createComparisonPlantModel();
