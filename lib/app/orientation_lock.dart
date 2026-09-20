import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Largeur en deçà de laquelle la fenêtre est celle d'un téléphone : une
/// colonne, et rien à gagner à la coucher.
const double compactWindowWidth = 600;

/// Vrai quand la fenêtre courante est plus étroite que [compactWindowWidth].
///
/// La mesure est prise à chaque appel, jamais gardée. Sur un appareil pliable
/// — l'iPhone Duo — c'est la même application qui passe de l'écran extérieur
/// à l'écran intérieur et revient, sans rien relancer : une taille lue au
/// démarrage se périme au premier pli.
///
/// Les cotes, relevées dans Xcode 27.1 les 18 et 19 septembre 2026 (DPR 3) :
/// fermé 386 × 678 points, ouvert 669 × 871 en mode de compatibilité ;
/// 466 × 678 et 669 × 951 une fois l'application construite avec le SDK 27.1,
/// qui l'étend jusqu'au bord. La limite des 600 points tient dans les deux
/// modes.
bool isCompactWindow() {
  final dispatcher = WidgetsBinding.instance.platformDispatcher;
  // La vue implicite est celle que l'application occupe ; sur un appareil à
  // deux écrans, elle suit celui qui est ouvert.
  final view = dispatcher.implicitView ?? (dispatcher.views.isEmpty ? null : dispatcher.views.first);
  if (view == null) return false;
  final size = view.physicalSize / view.devicePixelRatio;
  // Tant que la fenêtre n'est pas mesurable, on ne conclut pas : mieux vaut
  // une tablette libre qu'un téléphone bloqué par erreur.
  return !size.isEmpty && size.shortestSide < compactWindowWidth;
}

/// Le verrou de portrait, tenu à jour tant que l'application tourne.
///
/// Sur téléphone, l'application se tient en portrait : chaque écran est une
/// colonne, et le paysage n'apporterait qu'une mise en page étirée. Sur
/// tablette, en revanche, on ne verrouille rien : iPadOS attend qu'une
/// application tourne et cohabite avec une autre, et le refuser est un motif
/// de rejet.
///
/// Le pliable tient les deux rôles dans la même séance, alors le verrou n'est
/// plus une décision de démarrage mais un état : [attach] écoute la fenêtre et
/// repose ou retire le verrou à chaque pli. Sur l'écran intérieur, iOS ignore
/// de toute façon `UISupportedInterfaceOrientations` — la page doit savoir
/// tourner, pas s'y opposer.
///
/// `Info.plist` dit déjà la même chose côté iOS ; ce code couvre le reste. Le
/// manifeste Android, lui, reste en portrait sur tous les appareils : c'est un
/// choix propre à cette plateforme, et il l'emporte sur ces lignes.
///
/// Tant que `UIRequiresFullScreen` reste absent — et il doit le rester, voir
/// `ios/Runner/Info.plist` —, iOS n'honore de toute façon pas la demande sur
/// les appareils qui font cohabiter deux applications. Le verrou est donc une
/// intention plus qu'une contrainte : ce qui compte est que l'application
/// cesse de la porter dès que la fenêtre s'élargit.
///
/// Sur l'iPhone Duo, la demande est carrément **refusée** : UIKit répond
/// `UISceneErrorDomain Code=101`, sans que Dart en sache rien — l'erreur part
/// dans le gestionnaire vide de l'engine. L'écran extérieur tourne donc, et
/// l'application doit être juste en 678 × 386 comme en 386 × 678. Ce sont
/// `Info.plist` et la mise en page qui tiennent la barre, pas ces lignes.
class OrientationLock with WidgetsBindingObserver {
  bool? _portrait;

  /// L'état demandé au système, ou `null` tant que rien ne l'a été.
  @visibleForTesting
  bool? get portrait => _portrait;

  /// Pose le verrou et l'accroche aux changements de fenêtre.
  Future<void> attach() async {
    if (kIsWeb) return;
    WidgetsBinding.instance.addObserver(this);
    await _apply();
  }

  /// Rend la fenêtre à elle-même. Réservé aux tests : dans l'application, le
  /// verrou vit aussi longtemps qu'elle.
  @visibleForTesting
  void detach() {
    WidgetsBinding.instance.removeObserver(this);
    _portrait = null;
  }

  @override
  void didChangeMetrics() {
    _apply();
  }

  Future<void> _apply() async {
    final portrait = isCompactWindow();
    // Le pli n'est pas le seul changement de fenêtre : le clavier en est un
    // aussi. On ne parle au système que lorsque la réponse change.
    if (portrait == _portrait) return;
    _portrait = portrait;
    // Une liste vide rend la main à `Info.plist` et au manifeste : c'est ainsi
    // que la tablette — et le pliable ouvert — retrouve ses orientations.
    await SystemChrome.setPreferredOrientations(
      portrait ? const [DeviceOrientation.portraitUp] : const <DeviceOrientation>[],
    );
  }
}
