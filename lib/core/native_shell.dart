import 'dart:async' show unawaited;
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// La chrome de navigation rendue par UIKit, vue de Dart.
///
/// Sur iOS, ce n'est plus Flutter qui dessine la barre d'onglets : c'est un
/// `UITabBarController`, parce que le système ne déplace dans la bande
/// verticale de l'iPhone Duo que les barres qu'il possède lui-même. Voir
/// `ios/Runner/NativeShell.swift`.
///
/// Le partage est net. Le natif a la chrome ; Dart garde la navigation —
/// toucher un onglet ne fait rien tout seul, le natif le dit ici, et c'est
/// go_router qui change de branche. Ailleurs que sur iOS, ce service est muet
/// et la pilule en argile reste en place.
@immutable
class NativeTab {
  const NativeTab({required this.title, required this.symbol});

  final String title;

  /// Un nom de SF Symbol : UIKit dessine ses onglets avec les siens.
  final String symbol;

  Map<String, Object?> toMap() => {'title': title, 'symbol': symbol};
}

/// Une entrée du menu qu'un bouton déplie.
///
/// iOS ne présente pas un menu comme une feuille : il le fait sortir du
/// bouton touché, à sa place dans la barre, et floute ce qu'il recouvre.
/// C'est un `UIMenu`, et seul UIKit sait le dessiner — d'où ce passage par
/// le canal plutôt qu'une imitation en argile.
@immutable
class NativeMenuItem {
  const NativeMenuItem({
    required this.id,
    required this.title,
    this.symbol,
    this.enabled = true,
    this.destructive = false,
    this.separated = false,
  });

  /// Ce que le natif renvoie quand on la choisit.
  final String id;

  final String title;

  /// Un nom de SF Symbol, ou `null` pour une entrée sans image. Une entrée
  /// n'entraîne pas le bouton entier dans sa chute : là où un bouton sans
  /// symbole rend toute la barre à Flutter, une entrée sans symbole n'est
  /// qu'une ligne de texte, ce qu'iOS accepte très bien.
  final String? symbol;

  final bool enabled;

  /// Rouge, et rangée à part par qui lit les couleurs.
  final bool destructive;

  /// Ouvre un groupe : iOS trace un trait au-dessus. Les entrées qui suivent
  /// restent dans ce groupe jusqu'à la prochaine qui le demande.
  final bool separated;

  Map<String, Object?> toMap() => {
    'id': id,
    'title': title,
    'symbol': symbol,
    'enabled': enabled,
    'destructive': destructive,
    'separated': separated,
  };
}

/// Un bouton de page, tel que le natif le dessine.
@immutable
class NativeAction {
  const NativeAction({
    required this.id,
    required this.symbol,
    required this.title,
    this.enabled = true,
    this.prominent = false,
    this.menu = const [],
  });

  /// Ce que le natif renvoie quand on le touche.
  final String id;

  /// Un nom de SF Symbol. Voir `core/sf_symbols.dart`.
  final String symbol;

  /// Dit à VoiceOver, et par iOS quand il déplie un menu de débordement.
  final String title;

  final bool enabled;

  /// L'action principale de la page — l'ajout, chez Auxine. iOS la garde
  /// visible quand la bande déborde, au lieu de la replier dans le menu.
  final bool prominent;

  /// Ce que le bouton déplie au lieu d'agir. Vide, il agit comme avant.
  final List<NativeMenuItem> menu;

  Map<String, Object?> toMap() => {
    'id': id,
    'symbol': symbol,
    'title': title,
    'enabled': enabled,
    'prominent': prominent,
    'menu': [for (final m in menu) m.toMap()],
  };
}

abstract final class NativeShell {
  static const MethodChannel _channel = MethodChannel('ch.vergasta.plant/native_shell');

  /// La chrome native n'existe que côté iOS.
  static bool get isSupported => debugForceSupported || (!kIsWeb && Platform.isIOS);

  /// Pour qu'un test puisse répondre à la place du natif. Faux ailleurs.
  @visibleForTesting
  static bool debugForceSupported = false;

  /// Remet le service à neuf entre deux tests.
  @visibleForTesting
  static void debugReset() {
    debugForceSupported = false;
    _derniers = null;
    _dernierChoisi = null;
    _dernieresActions = null;
    _derniereChrome = null;
    _profondeur = 0;
    overlay.value = 0;
    _barreDemandee = false;
    _voilee = false;
    _ouverture = false;
    _coquilleDeclaree = false;
  }

  /// Ce que fait un onglet touché. Posé par la coquille.
  static void Function(int index)? onTab;

  /// Ce que fait un bouton de page touché. Posé par la page ouverte.
  static void Function(String id)? onAction;

  static bool _branche = false;
  static String? _derniers;
  static int? _dernierChoisi;

  static void attach() {
    if (!isSupported || _branche) return;
    _branche = true;
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onTab':
          onTab?.call(call.arguments as int);
        case 'onAction':
          onAction?.call(call.arguments as String);
      }
      return null;
    });
  }

  /// Déclare les onglets, et lequel est ouvert.
  ///
  /// Appelé à chaque image de la coquille : une déclaration identique à la
  /// précédente n'est pas renvoyée. UIKit refait ses onglets quand on les lui
  /// redonne, et les refaire soixante fois par seconde coûterait cher pour
  /// rien.
  static Future<void> publish({required List<NativeTab> tabs, required int selected}) async {
    if (!isSupported) return;
    // Les onglets d'abord, la barre ensuite. Le contrôleur natif démarre avec
    // un onglet de service — un rond sans nom —, et le montrer le temps d'une
    // image suffit à le faire voir. Un canal de méthode livre dans l'ordre où
    // on lui confie : la barre ne reparaît donc qu'une fois remplie.
    final declaration = [for (final t in tabs) t.toMap()].toString();
    Future<void>? envoi;
    if (declaration != _derniers) {
      _derniers = declaration;
      _dernierChoisi = selected;
      envoi = _invoke('setTabs', {'tabs': [for (final t in tabs) t.toMap()], 'selected': selected});
    } else if (selected != _dernierChoisi) {
      _dernierChoisi = selected;
      envoi = _invoke('setSelected', selected);
    }
    if (!_coquilleDeclaree) {
      _coquilleDeclaree = true;
      _appliquerChrome();
    }
    if (envoi != null) await envoi;
  }

  static String? _dernieresActions;

  /// Déclare le titre et les boutons de la page ouverte.
  ///
  /// Une déclaration identique à la précédente n'est pas renvoyée : une page
  /// se reconstruit souvent, et UIKit refait ses boutons chaque fois qu'on
  /// les lui redonne.
  static Future<void> publishActions({
    String? title,
    List<NativeAction> leading = const [],
    List<NativeAction> actions = const [],
  }) async {
    if (!isSupported) return;
    final charge = {
      'title': title ?? '',
      'leading': [for (final a in leading) a.toMap()],
      'actions': [for (final a in actions) a.toMap()],
    };
    final empreinte = charge.toString();
    if (empreinte == _dernieresActions) return;
    _dernieresActions = empreinte;
    await _invoke('setActions', charge);
  }

  static String? _derniereChrome;
  static int _profondeur = 0;
  static bool _barreDemandee = false;
  static bool _voilee = false;
  static bool _ouverture = false;
  /// La coquille a-t-elle dit ses onglets ?
  ///
  /// Au premier lancement, l'accueil s'ouvre sans elle : sans ce verrou, le
  /// contrôleur d'onglets montrait son onglet de départ — un rond sans nom —
  /// par-dessus, et une barre vide avec.
  static bool _coquilleDeclaree = false;

  /// Ce qui couvre la coquille — les pages d'un côté, les surcouches de
  /// l'autre. Dit par l'observateur du
  /// navigateur racine (`app/native_chrome_observer.dart`).
  ///
  /// UIKit ne sait rien de la navigation de Flutter : une fiche, un scanner,
  /// une feuille sont des routes qu'il ne voit pas, et ses barres restaient
  /// posées par-dessus avec les boutons de la page d'en dessous. Toute route
  /// qui couvre la coquille les efface donc, **et la page qui s'ouvre les
  /// redemande si elle sait les remplir** — une fiche à grand titre le fait,
  /// un scanner non.
  static void setOverlay({required int pages, required int veils}) {
    _voilee = veils > 0;
    if (pages != _profondeur) {
      _profondeur = pages;
      overlay.value = pages;
      // À chaque changement d'étage, la barre est à reconquérir.
      _barreDemandee = false;
    }
    _appliquerChrome();
  }

  /// L'animation d'ouverture (`LaunchSplash`) couvre l'écran : la chrome se
  /// voile le temps qu'elle dure.
  ///
  /// Les barres natives sont posées par-dessus Flutter, et rien de ce que
  /// Flutter dessine ne les cache : sans cela, la barre d'onglets et celle du
  /// haut paraissaient sur l'écran de lancement dès que la coquille se
  /// déclarait. Voiler, et non effacer : la page garde leur place, et ne
  /// saute pas quand elles reviennent.
  static void setLaunching(bool value) {
    if (_ouverture == value) return;
    _ouverture = value;
    _appliquerChrome();
  }

  /// Combien de pages couvrent la coquille, pour qui a besoin de le savoir.
  ///
  /// Écoutable : une page couverte cesse de prétendre à la barre, et doit la
  /// reprendre quand ce qui la couvrait s'en va. Rien ne la forcerait sinon
  /// à se redessiner, et la barre reviendrait vide.
  static final ValueNotifier<int> overlay = ValueNotifier<int>(0);

  static int get overlayDepth => overlay.value;

  /// Une page dit qu'elle sait remplir la barre. Sans effet sur la coquille,
  /// qui l'a de droit.
  static void requestBar() {
    if (_barreDemandee) return;
    _barreDemandee = true;
    _appliquerChrome();
  }

  /// La barre d'onglets ne survit pas à une page empilée : c'est la règle
  /// d'iOS, et `hidesBottomBarWhenPushed` ne dit rien d'autre.
  /// Sans `await` entre les deux envois, et ce n'est pas un détail.
  ///
  /// Le garde-fou ci-dessous vidait la barre puis **attendait** avant de la
  /// masquer. Cette attente laissait passer une image : la page qui s'ouvrait
  /// demandait la barre et publiait ses boutons dans l'intervalle, et le
  /// masquage arrivait après, effaçant ce qu'elle venait de poser. Une fiche
  /// de plante se retrouvait sans aucun bouton.
  ///
  /// Un canal de méthode livre dans l'ordre où on lui confie : il suffit donc
  /// de lui confier les deux à la suite, sans rien attendre entre.
  static void _appliquerChrome() {
    if (!isSupported) return;
    final charge = {
      'bar': _coquilleDeclaree && (_profondeur == 0 || _barreDemandee),
      'tabs': _coquilleDeclaree && _profondeur == 0,
      // Voiler plutôt qu'effacer : une barre retirée rend sa place au
      // contenu, et la page glisse sous le menu qui vient de s'ouvrir.
      'veil': _voilee || _ouverture,
    };
    final empreinte = charge.toString();
    if (empreinte == _derniereChrome) return;
    _derniereChrome = empreinte;
    debugPrint('[auxine:natif] chrome $empreinte');
    // Une barre effacée ne garde pas ses boutons : sinon elle montrerait ceux
    // de la page d'en dessous le jour où l'effacement échouerait.
    if (charge['bar'] == false) {
      _dernieresActions = null;
      unawaited(_invoke('setActions', const {'title': '', 'leading': [], 'actions': []}));
    }
    unawaited(_invoke('setChrome', charge));
  }

  static Future<void> _invoke(String methode, Object? arguments) async {
    try {
      await _channel.invokeMethod<bool>(methode, arguments);
    } on MissingPluginException {
      // Un binaire sans la coquille native. On oublie, et on redemandera.
      _derniers = null;
      _dernierChoisi = null;
      _dernieresActions = null;
      _derniereChrome = null;
    } on PlatformException catch (e) {
      debugPrint('[auxine:natif] refus de $methode : ${e.message}');
    }
  }
}
