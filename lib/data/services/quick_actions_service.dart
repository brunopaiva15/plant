import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Un raccourci de l'icône : ce qu'iOS montre quand on appuie longtemps sur
/// l'application, sur l'écran d'accueil.
class QuickAction {
  const QuickAction({required this.type, required this.title, required this.icon});

  /// Clé stable, rendue à l'application quand le raccourci est choisi.
  final String type;

  /// Le libellé, dans la langue de l'application.
  final String title;

  /// Un symbole SF (`plus`, `qrcode.viewfinder`…).
  final String icon;

  Map<String, String> toMap() => {'type': type, 'title': title, 'icon': icon};
}

/// Les raccourcis de l'icône, pour la partie Dart
/// (`ios/Runner/QuickActionsChannel.swift`).
///
/// Deux sens : l'application pose ses raccourcis avec leurs libellés du
/// moment ; le système rend celui qui a été choisi — par [onAction] quand
/// l'application tourne, par [launchAction] quand c'est lui qui l'a lancée.
/// Muet hors iOS : chaque appel se résout sans rien faire.
class QuickActionsService {
  QuickActionsService({MethodChannel? channel}) : _channel = channel ?? const MethodChannel(channelName) {
    _channel.setMethodCallHandler(_handle);
  }

  static const String channelName = 'ch.vergasta.plant/quick_actions';

  final MethodChannel _channel;

  /// Appelé avec le type du raccourci choisi pendant que l'application tourne.
  void Function(String type)? onAction;

  Future<dynamic> _handle(MethodCall call) async {
    if (call.method == 'perform') {
      final type = call.arguments as String?;
      if (type != null && type.isNotEmpty) onAction?.call(type);
    }
    return null;
  }

  /// Remplace les raccourcis de l'icône.
  Future<void> setItems(List<QuickAction> items) => _invoke<void>('setItems', [for (final i in items) i.toMap()]);

  /// Le raccourci qui a lancé l'application, s'il y en a un — rendu une fois.
  ///
  /// C'est aussi ce qui dit au natif que Dart écoute : ce qui arrive ensuite
  /// passe par [onAction].
  Future<String?> launchAction() async {
    final type = await _invoke<String>('launchAction');
    return type == null || type.isEmpty ? null : type;
  }

  Future<T?> _invoke<T>(String method, [Object? arguments]) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on MissingPluginException {
      return null;
    } on PlatformException catch (e) {
      debugPrint('quick actions: $method failed: ${e.message}');
      return null;
    }
  }
}
