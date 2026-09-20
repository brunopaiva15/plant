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

/// Un bouton de page, tel que le natif le dessine.
@immutable
class NativeAction {
  const NativeAction({required this.id, required this.symbol, required this.title, this.enabled = true});

  /// Ce que le natif renvoie quand on le touche.
  final String id;

  /// Un nom de SF Symbol. Voir `core/sf_symbols.dart`.
  final String symbol;

  /// Dit à VoiceOver, et par iOS quand il déplie un menu de débordement.
  final String title;

  final bool enabled;

  Map<String, Object?> toMap() => {'id': id, 'symbol': symbol, 'title': title, 'enabled': enabled};
}

abstract final class NativeShell {
  static const MethodChannel _channel = MethodChannel('ch.vergasta.plant/native_shell');

  /// La chrome native n'existe que côté iOS.
  static bool get isSupported => !kIsWeb && Platform.isIOS;

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
    final declaration = [for (final t in tabs) t.toMap()].toString();
    if (declaration != _derniers) {
      _derniers = declaration;
      _dernierChoisi = selected;
      await _invoke('setTabs', {'tabs': [for (final t in tabs) t.toMap()], 'selected': selected});
      return;
    }
    if (selected == _dernierChoisi) return;
    _dernierChoisi = selected;
    await _invoke('setSelected', selected);
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

  static bool? _derniereEclipse;

  /// Masque ou rend la chrome native.
  ///
  /// Une page ouverte par Flutter par-dessus la coquille — une fiche, un
  /// scanner, une feuille — n'existe pas pour UIKit : sans cela, ses barres
  /// restaient posées par-dessus, avec les boutons de la page d'en dessous.
  static Future<void> setChromeHidden(bool hidden) async {
    if (!isSupported || hidden == _derniereEclipse) return;
    _derniereEclipse = hidden;
    await _invoke('setChromeHidden', hidden);
  }

  static Future<void> _invoke(String methode, Object? arguments) async {
    try {
      await _channel.invokeMethod<bool>(methode, arguments);
    } on MissingPluginException {
      // Un binaire sans la coquille native. On oublie, et on redemandera.
      _derniers = null;
      _dernierChoisi = null;
      _dernieresActions = null;
      _derniereEclipse = null;
    } on PlatformException catch (e) {
      debugPrint('[auxine:natif] refus de $methode : ${e.message}');
    }
  }
}
