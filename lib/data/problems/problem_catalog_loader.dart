import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'problem_catalog.dart';

/// Charge la base des problèmes depuis les actifs, une seule fois.
///
/// Deux cents lignes se lisent en un clin d'œil, mais la lecture passe par un
/// isolat comme celle du catalogue d'espèces : rien ne justifie de bloquer
/// l'interface, même brièvement.
class ProblemCatalogLoader {
  ProblemCatalogLoader({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const assetPath = 'assets/problems/catalog.txt';

  final AssetBundle _bundle;
  Future<ProblemCatalog>? _pending;

  Future<ProblemCatalog> load() => _pending ??= _read();

  Future<ProblemCatalog> _read() async {
    try {
      final raw = await _bundle.loadString(assetPath, cache: false);
      return await compute(ProblemCatalog.parse, raw);
    } catch (_) {
      // Actif absent (tests, build partiel) : le diagnostic repart sans
      // liste de pistes, comme avant qu'elle existe.
      _pending = null;
      return ProblemCatalog(const []);
    }
  }
}
