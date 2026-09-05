import 'dart:io';

import 'plant_identifier.dart';

/// Modèle de reconnaissance embarqué. L'implémentation réelle (TFLite ou
/// Core ML) viendra avec le premier modèle entraîné ; d'ici là, l'app
/// utilise [NoLocalModel] et la cascade passe directement au service distant.
abstract class LocalPlantModel {
  /// Faux tant que le fichier de modèle n'est pas présent et chargé.
  bool get isAvailable;

  /// Version du modèle chargé (`null` sans modèle), pour les métriques et
  /// les mises à jour.
  String? get version;

  /// Classe une image. Les noms rendus sont les noms canoniques des classes
  /// (voir `tools/plant_dataset/plants.csv`), scores entre 0 et 1, somme ≤ 1.
  Future<List<IdentificationCandidate>> classify(File image);
}

class NoLocalModel implements LocalPlantModel {
  const NoLocalModel();

  @override
  bool get isAvailable => false;

  @override
  String? get version => null;

  @override
  Future<List<IdentificationCandidate>> classify(File image) async => const [];
}
