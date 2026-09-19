import 'dart:io';

import 'identification_context.dart';
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

  /// Nombre d'espèces que le modèle sait nommer, 0 s'il n'est pas chargé.
  int get speciesCount;

  /// Pourquoi le chargement a échoué, `null` s'il a réussi ou n'a pas eu
  /// lieu. Montré tel quel dans les réglages : sans lui, « indisponible »
  /// ne dit pas si l'asset manque ou si la bibliothèque native n'est pas
  /// liée, et ce sont deux corrections très différentes.
  String? get loadError;

  /// Les lieux pour lesquels le modèle porte un masque, tels que
  /// `model.json` les déclare. Vide quand il n'en porte aucun — c'est le cas
  /// d'un spécialiste unique comme Iris Indoor, et [classify] ignore alors
  /// le contexte qu'on lui donne.
  ///
  /// C'est ce qui dit si le modèle couvre l'extérieur. Tant qu'il ne le
  /// couvre pas, l'application propose au lieu d'affirmer dehors
  /// (`FallbackPolicy.outdoors`) ; le jour où un modèle d'union est livré,
  /// la réserve tombe d'elle-même, sans qu'une constante soit à changer.
  Set<IdentificationContext> get contexts;

  /// Classe une image. Les noms rendus sont les noms canoniques des classes
  /// (voir `tools/plant_dataset/plants.csv`), scores entre 0 et 1, somme ≤ 1.
  ///
  /// Avec un [context] que le modèle connaît, les scores rendus sont
  /// renormalisés sur les classes de ce lieu — `exp(zᵢ) / Σ_gardées` — et les
  /// classes des autres lieux sont rendues **en plus**, marquées
  /// `inContext: false` et portant leur score global. Voir le § 14 de
  /// `docs/09`.
  Future<List<IdentificationCandidate>> classify(File image,
      {IdentificationContext context = IdentificationContext.unknown});

  /// Charge le modèle sans rien classer. À appeler quand on sait qu'une
  /// identification arrive (ouverture de l'appareil photo) : le chargement
  /// se fait pendant que l'utilisateur cadre. Rend `false` s'il n'y a pas
  /// de modèle utilisable.
  Future<bool> warmUp();

  /// Libère l'interpréteur natif. Sans effet s'il n'y en a pas.
  void dispose();
}

class NoLocalModel implements LocalPlantModel {
  const NoLocalModel();

  @override
  bool get isAvailable => false;

  @override
  String? get version => null;

  @override
  int get speciesCount => 0;

  @override
  String? get loadError => null;

  @override
  Set<IdentificationContext> get contexts => const {};

  @override
  Future<List<IdentificationCandidate>> classify(File image,
          {IdentificationContext context = IdentificationContext.unknown}) async =>
      const [];

  @override
  Future<bool> warmUp() async => false;

  @override
  void dispose() {}
}
