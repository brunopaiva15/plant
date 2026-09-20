import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// **Prototype.** Le titre et les boutons de la page, confiés à UIKit.
///
/// Ce qu'on cherche à savoir, et rien d'autre : sur iPhone Duo, iOS déplace-t-il
/// nos boutons dans la bande verticale de droite, de quoi ont-ils l'air une
/// fois là, et que fait-il quand il y en a trop ? Voir
/// `ios/Runner/DuoNativeChrome.swift` et `docs/duo-native-prototype.md`.
///
/// Rien ici ne remplace quoi que ce soit : la colonne Flutter reste en place,
/// et ce service se contente de publier une description à côté. Muet hors
/// d'iOS, et sans effet si le natif n'écoute pas.
enum NativeChromePlacement {
  /// Le haut de la bande : retour, fermeture.
  primary,

  /// À la suite : les actions de la page.
  trailing,

  /// Le bas de la bande, là où va aussi la barre d'onglets.
  bottom,
}

@immutable
class NativeChromeItem {
  const NativeChromeItem({
    required this.id,
    required this.symbol,
    required this.title,
    this.placement = NativeChromePlacement.trailing,
  });

  /// Ce que le natif renvoie quand on touche le bouton.
  final String id;

  /// Un nom de SF Symbol. UIKit ne dessine pas nos icônes Cupertino ; c'est
  /// l'un des points que le prototype doit rendre visibles.
  final String symbol;

  /// Dit à VoiceOver, et par iOS quand il déplie un menu de débordement.
  final String title;

  final NativeChromePlacement placement;

  Map<String, Object?> toMap() => {
    'id': id,
    'symbol': symbol,
    'title': title,
    'placement': placement.name,
  };
}

abstract final class NativeChrome {
  static const MethodChannel _channel = MethodChannel('ch.vergasta.plant/native_chrome');

  /// Le canal n'existe que côté iOS.
  static bool get isSupported => !kIsWeb && Platform.isIOS;

  /// Ce qu'on fait d'un bouton touché. Le prototype se contente de l'écrire.
  static void Function(String id)? onItem;

  static bool _branche = false;
  static String? _dernier;

  static void attach() {
    if (!isSupported || _branche) return;
    _branche = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onItem') {
        final id = call.arguments as String;
        debugPrint('[auxine:natif] bouton touché : $id');
        onItem?.call(id);
      }
      return null;
    });
  }

  /// Publie le titre et les boutons de la page ouverte.
  ///
  /// Une description identique à la précédente n'est pas renvoyée : la
  /// coquille se reconstruit à chaque image, et UIKit n'a pas à refaire ses
  /// boutons pour autant.
  static Future<void> publish({required String title, List<NativeChromeItem> items = const []}) async {
    if (!isSupported) return;
    final charge = {'title': title, 'items': [for (final i in items) i.toMap()]};
    final empreinte = charge.toString();
    if (empreinte == _dernier) return;
    _dernier = empreinte;
    try {
      await _channel.invokeMethod<bool>('setChrome', charge);
    } on MissingPluginException {
      // Le prototype n'est pas dans ce binaire. On n'insiste pas.
      _dernier = null;
    } on PlatformException catch (e) {
      debugPrint('[auxine:natif] refus : ${e.message}');
    }
  }
}
