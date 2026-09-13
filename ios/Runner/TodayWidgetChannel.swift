import Flutter
import WidgetKit

/// Ce que le widget de l'écran d'accueil lit, écrit par la partie Dart
/// (`lib/data/services/today_widget_service.dart`).
///
/// Une méthode : déposer l'instantané du jour, en JSON, dans les préférences
/// de l'App Group que l'application et l'extension partagent, puis demander
/// au système de redessiner. L'extension (`ios/AuxineWidget/`) lit la même
/// clé ; ni l'une ni l'autre ne connaît la base.
final class TodayWidgetChannel {
  static let name = "ch.vergasta.plant/widgets"

  /// Le groupe et la clé que l'extension lit : à changer des deux côtés.
  static let group = "group.ch.vergasta.plant"
  static let key = "today"

  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: name, binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "publish":
        guard let json = call.arguments as? String else {
          result(FlutterError(code: "bad_args", message: "json string expected", details: nil))
          return
        }
        guard let store = UserDefaults(suiteName: group) else {
          // Pas d'App Group sur ce build (capability absente) : rien à
          // écrire, et rien à dire — l'application n'en souffre pas.
          result(nil)
          return
        }
        store.set(json, forKey: key)
        WidgetCenter.shared.reloadAllTimelines()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
