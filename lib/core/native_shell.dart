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

abstract final class NativeShell {
  static const MethodChannel _channel = MethodChannel('ch.vergasta.plant/native_shell');

  /// La chrome native n'existe que côté iOS.
  static bool get isSupported => !kIsWeb && Platform.isIOS;

  /// Ce que fait un onglet touché. Posé par la coquille.
  static void Function(int index)? onTab;

  static bool _branche = false;
  static String? _derniers;
  static int? _dernierChoisi;

  static void attach() {
    if (!isSupported || _branche) return;
    _branche = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onTab') onTab?.call(call.arguments as int);
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

  static Future<void> _invoke(String methode, Object? arguments) async {
    try {
      await _channel.invokeMethod<bool>(methode, arguments);
    } on MissingPluginException {
      // Un binaire sans la coquille native. On oublie, et on redemandera.
      _derniers = null;
      _dernierChoisi = null;
    } on PlatformException catch (e) {
      debugPrint('[auxine:natif] refus de $methode : ${e.message}');
    }
  }
}
