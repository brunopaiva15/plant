import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'species_index.dart';

/// Charge le catalogue étendu depuis les actifs, une seule fois.
///
/// L'analyse tourne dans un isolat : ~30 000 lignes bloqueraient l'interface
/// une centaine de millisecondes sur un téléphone modeste.
class SpeciesIndexLoader {
  SpeciesIndexLoader({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const assetPath = 'assets/species/catalog.tsv';

  final AssetBundle _bundle;
  Future<SpeciesIndex>? _pending;

  Future<SpeciesIndex> load() => _pending ??= _read();

  Future<SpeciesIndex> _read() async {
    try {
      final raw = await _bundle.loadString(assetPath, cache: false);
      return await compute(SpeciesIndex.parse, raw);
    } catch (_) {
      // Actif absent (tests, build partiel) : le catalogue trié à la main et
      // la recherche GBIF suffisent, l'écran reste utilisable.
      _pending = null;
      return SpeciesIndex(const []);
    }
  }
}
