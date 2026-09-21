import 'package:flutter/widgets.dart';

import '../core/native_shell.dart';

/// Efface la chrome native tant qu'une page couvre la coquille.
///
/// UIKit ne sait rien de la navigation de Flutter : une fiche de plante, un
/// scanner de QR code, une feuille d'ajout sont des routes que go_router pose
/// par-dessus la coquille, et les barres natives restaient là, posées sur la
/// page ouverte avec les boutons de celle d'en dessous.
///
/// Un observateur du navigateur racine suffit à le dire : il compte les
/// routes posées au-dessus de la première — la coquille. À partir de là, la
/// barre d'onglets s'efface, comme sur iOS, et la barre du haut aussi —
/// jusqu'à ce que la page ouverte la redemande, si elle sait la remplir. Une
/// fiche à grand titre le fait ; un scanner non.
///
/// **Une page et une surcouche ne se valent pas.** Un menu d'action, une
/// alerte, une feuille à hauteur de contenu ne prennent pas la place de la
/// page : elles se posent dessus le temps d'un choix. L'effacer pour de bon
/// changerait la marge sûre, et la page glisserait sous le menu — ce qu'elle
/// faisait. Ces routes-là ne font donc que voiler la chrome : la barre s'en
/// va, mais sa place lui reste (voir `NativeShell.swift`).
///
/// Les pages des branches d'onglets ne passent pas par ici : elles ont leur
/// propre navigateur, et c'est bien la coquille qu'on regarde alors.
class NativeChromeObserver extends NavigatorObserver {
  /// Les pages posées sur la coquille : une fiche, un scanner, une feuille.
  int _pages = 0;

  /// Les surcouches qui ne sont pas des pages : un menu d'action, une
  /// alerte. Elles n'occupent pas la place, elles se posent dessus.
  int _surcouches = 0;

  void _dire() {
    // Le premier maillon de la chaîne, écrit en debug : si cette ligne ne
    // paraît pas quand une page s'ouvre, c'est que l'observateur n'a rien vu,
    // et il est inutile de chercher plus loin. La suivante est
    // `[auxine:natif] chrome …`, et la dernière est ce que montre l'écran.
    assert(() {
      debugPrint('[auxine:natif] routes pages=$_pages surcouches=$_surcouches');
      return true;
    }());
    NativeShell.setOverlay(pages: _pages, veils: _surcouches);
  }

  void _compter(Route<Object?> route, int sens) {
    if (route is PageRoute) {
      _pages = (_pages + sens).clamp(0, 99);
    } else {
      _surcouches = (_surcouches + sens).clamp(0, 99);
    }
    _dire();
  }

  @override
  void didPush(Route<Object?> route, Route<Object?>? previousRoute) {
    // La toute première route est la coquille : elle ne compte pas.
    if (previousRoute == null) return;
    _compter(route, 1);
  }

  @override
  void didPop(Route<Object?> route, Route<Object?>? previousRoute) {
    if (previousRoute == null) return;
    _compter(route, -1);
  }

  @override
  void didRemove(Route<Object?> route, Route<Object?>? previousRoute) {
    if (previousRoute == null) return;
    _compter(route, -1);
  }
}
