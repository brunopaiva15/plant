import 'package:flutter/widgets.dart';

import '../core/native_shell.dart';

/// Efface la chrome native tant qu'une page couvre la coquille.
///
/// UIKit ne sait rien de la navigation de Flutter : une fiche de plante, un
/// scanner de QR code, une feuille d'ajout sont des routes que go_router pose
/// par-dessus la coquille, et les barres natives restaient là, posées sur la
/// page ouverte avec les boutons de celle d'en dessous.
///
/// Un observateur du navigateur racine suffit à le dire : tant qu'il reste
/// une route au-dessus de la première — la coquille —, les barres s'effacent.
/// Les pages des branches d'onglets, elles, ne passent pas par ici : elles
/// ont leur propre navigateur, et c'est bien la coquille qu'on regarde.
class NativeChromeObserver extends NavigatorObserver {
  int _empilees = 0;

  void _dire() => NativeShell.setChromeHidden(_empilees > 0);

  @override
  void didPush(Route<Object?> route, Route<Object?>? previousRoute) {
    // La toute première route est la coquille : elle ne compte pas.
    if (previousRoute == null) return;
    _empilees += 1;
    _dire();
  }

  @override
  void didPop(Route<Object?> route, Route<Object?>? previousRoute) {
    if (previousRoute == null) return;
    _empilees = _empilees > 0 ? _empilees - 1 : 0;
    _dire();
  }

  @override
  void didRemove(Route<Object?> route, Route<Object?>? previousRoute) {
    if (previousRoute == null) return;
    _empilees = _empilees > 0 ? _empilees - 1 : 0;
    _dire();
  }
}
