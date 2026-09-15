import 'dart:convert';

import 'package:flutter/services.dart';

import 'iris_detailed_catalog.dart';
import 'species_index.dart';

/// Construit le catalogue détaillé depuis la liste de classes réellement
/// embarquée avec Iris. `model.json` reste ainsi l'unique source du nombre
/// d'espèces reconnaissables hors ligne.
class IrisDetailedCatalogLoader {
  IrisDetailedCatalogLoader({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const modelMetaAsset = 'assets/model/model.json';

  final AssetBundle _bundle;

  Future<IrisDetailedCatalog> load(SpeciesIndex index) async {
    final raw = await _bundle.loadString(modelMetaAsset);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final species = (json['species'] as Map<String, dynamic>? ?? const <String, dynamic>{}).values.whereType<String>();
    return IrisDetailedCatalog.from(modelSpecies: species, index: index);
  }
}
