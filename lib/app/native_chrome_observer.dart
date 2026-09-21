import 'package:flutter/widgets.dart';

import '../core/native_shell.dart';

/// Efface la chrome native tant qu'une page couvre la coquille.
///
/// UIKit ne sait rien de la navigation de Flutter : une fiche de plante, un
/// scanner de QR code, une feuille d'ajout sont des routes que go_router pose
/// par-dessus la coquille, et les barres natives restaient là, posées sur la
/// page ouverte avec les boutons de celle d'en dessous.
///
/// Un observateur du navigateur racine suffit à le dire : il tient la liste
/// des pages vivantes, et tout ce qui se trouve au-dessus de la plus basse
/// couvre la coquille. À partir de là, la barre d'onglets s'efface, comme sur
/// iOS, et la barre du haut aussi — jusqu'à ce que la page ouverte la
/// redemande, si elle sait la remplir. Une fiche à grand titre le fait ; un
/// scanner non.
///
/// **On tient la liste, et non un compteur.** Un compteur qui ignorait la
/// première page — « elle n'a rien en dessous, donc c'est la coquille » — se
/// trompait au sortir de l'introduction : `context.go` pose la coquille par
/// **dessus** l'introduction, puis retire celle-ci d'en dessous. Le premier
/// mouvement comptait une page de trop, le second ne la retirait pas, et
/// l'application restait sans aucune barre jusqu'au prochain lancement. Une
/// liste dit sans se tromper ce qui reste debout, quel que soit l'ordre des
/// deux mouvements.
///
/// **Une page et une surcouche ne se valent pas.** Un menu d'action, une
/// alerte, une feuille à hauteur de contenu ne prennent pas la place de la
/// page : elles se posent dessus le temps d'un choix. L'effacer pour de bon
/// changerait la marge sûre, et la page glisserait sous le menu — ce qu'elle
/// faisait. Ces routes-là ne font donc que voiler la chrome : la barre s'en
/// va, mais sa place lui reste (voir `NativeShell.swift`).
///
/// **Les pages des branches d'onglets ne comptent pas.** Elles ont leur propre
/// navigateur, et c'est bien la coquille qu'on regarde alors — mais go_router
/// renvoie par défaut ce qui s'y passe aux observateurs de la racine
/// (`notifyRootObserver`), et chaque page d'onglet y arrive avec
/// `previousRoute` à `null`. Le routeur coupe ce renvoi, et l'observateur
/// s'en tient de son côté au navigateur de sa première route — la racine, la
/// coquille de branche n'existant pas encore à ce moment-là. Les deux sont
/// utiles : le premier dit l'intention, le second tient même si un jour une
/// autre coquille oublie de le dire.
class NativeChromeObserver extends NavigatorObserver {
  /// Les pages vivantes du navigateur racine, de la plus basse à la plus
  /// haute. La plus basse est la coquille — ou l'introduction, au premier
  /// lancement ; les autres sont ce qui la couvre.
  final List<Route<Object?>> _pages = <Route<Object?>>[];

  /// Les surcouches vivantes qui ne sont pas des pages : un menu d'action,
  /// une alerte. Elles n'occupent pas la place, elles se posent dessus. On
  /// les tient par identité, comme les pages : ce qui n'a pas été compté à
  /// l'aller ne se décompte pas au retour.
  final Set<Route<Object?>> _surcouches = <Route<Object?>>{};

  /// Le navigateur dont on parle : celui de la première route vue.
  NavigatorState? _racine;

  /// Combien de pages couvrent la plus basse.
  int get _profondeur => _pages.isEmpty ? 0 : _pages.length - 1;

  /// Cette route est-elle de notre navigateur ?
  ///
  /// Une route sans navigateur est acceptée : c'est celle d'un test qui
  /// appelle l'observateur à la main.
  bool _aNous(Route<Object?> route) {
    final navigateur = route.navigator;
    if (navigateur == null) return true;
    _racine ??= navigateur;
    return identical(navigateur, _racine);
  }

  void _dire() {
    // Le premier maillon de la chaîne, écrit en debug : si cette ligne ne
    // paraît pas quand une page s'ouvre, c'est que l'observateur n'a rien vu,
    // et il est inutile de chercher plus loin. La suivante est
    // `[auxine:natif] chrome …`, et la dernière est ce que montre l'écran.
    assert(() {
      debugPrint('[auxine:natif] routes pages=$_profondeur surcouches=${_surcouches.length}');
      return true;
    }());
    NativeShell.setOverlay(pages: _profondeur, veils: _surcouches.length);
  }

  void _noter(Route<Object?> route) {
    if (!_aNous(route)) return;
    // Deux fois la même route ne fait pas deux étages : un navigateur qui la
    // redirait laisserait la barre effacée pour de bon.
    if (route is PageRoute) {
      if (!_pages.contains(route)) _pages.add(route);
    } else {
      _surcouches.add(route);
    }
  }

  void _oublier(Route<Object?> route) {
    if (route is PageRoute) {
      _pages.remove(route);
    } else {
      _surcouches.remove(route);
    }
  }

  @override
  void didPush(Route<Object?> route, Route<Object?>? previousRoute) {
    _noter(route);
    _dire();
  }

  @override
  void didPop(Route<Object?> route, Route<Object?>? previousRoute) {
    _oublier(route);
    _dire();
  }

  @override
  void didRemove(Route<Object?> route, Route<Object?>? previousRoute) {
    _oublier(route);
    _dire();
  }

  /// Une route prend la place d'une autre sans rien empiler : la hauteur ne
  /// change pas, mais la liste doit suivre, sans quoi la suivante retirée ne
  /// s'y retrouve plus.
  @override
  void didReplace({Route<Object?>? newRoute, Route<Object?>? oldRoute}) {
    if (oldRoute != null) _oublier(oldRoute);
    if (newRoute != null) _noter(newRoute);
    _dire();
  }
}
