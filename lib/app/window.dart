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
/// Les cotes, relevées dans Xcode 27.1 sur un binaire construit avec le SDK
/// 27.1 (DPR 3) : fermé 466 × 678 points, ouvert 669 × 951. Construite avec
/// le SDK 27.0, la même application tourne en mode de compatibilité et perd
/// 80 points sur un axe — 386 × 678 et 669 × 871. La limite des 600 points
/// tient dans les deux modes ; `[auxine:sdk]` dit lequel est en cours.
///
/// ## Pourquoi il n'y a pas de verrou d'orientation ici
///
/// Il y en a eu un : l'application demandait le portrait à
/// `SystemChrome.setPreferredOrientations` dès que la fenêtre était compacte.
/// Deux constats l'ont retiré.
///
/// Sur l'iPhone Duo, la demande est **refusée** : UIKit répond
/// `UISceneErrorDomain Code=101`, et Dart n'en sait rien — l'engine passe un
/// gestionnaire d'erreur vide. L'écran extérieur tourne donc quoi qu'on
/// demande, et 678 × 466 est un état à tenir, pas à empêcher.
///
/// Ailleurs, la demande ne faisait que répéter ce qui était déjà déclaré :
/// `ios/Runner/Info.plist` tient le portrait sur iPhone et les quatre
/// orientations sur iPad, le manifeste Android tient le portrait partout. Sur
/// iPad, Flutter note d'ailleurs que la demande n'est honorée que si le
/// multitâche est coupé — ce qu'on ne fait pas.
///
/// Ce qui reste, c'est de savoir dans quelle fenêtre on se trouve pour s'y
/// poser : c'est tout ce que cette fonction dit, et le viseur photo
/// (`features/plants/presentation/inline_camera.dart`) comme le menu
/// (`FloraTabRail.fitsIn`) s'en servent chacun à leur manière.
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
