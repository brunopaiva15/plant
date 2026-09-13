import Flutter
import UIKit

/// Les raccourcis de l'icône — l'appui long sur l'application, sur l'écran
/// d'accueil — pour la partie Dart (`lib/data/services/quick_actions_service.dart`).
///
/// Dart pose les raccourcis avec leurs libellés dans sa langue ; le système
/// rend celui qui a été choisi. Quand l'application tourne, il arrive par la
/// scène et part aussitôt vers Dart ; quand c'est lui qui a lancé
/// l'application, il attend que Dart le demande (`launchAction`), sans quoi
/// il partirait avant que personne n'écoute.
///
/// Enregistré comme délégué de scène de Flutter plutôt qu'en surchargeant
/// `SceneDelegate` : Flutter garde ainsi la main sur la connexion de la scène
/// et ne fait que passer l'événement.
final class QuickActionsChannel: NSObject, FlutterSceneLifeCycleDelegate {
  static let name = "ch.vergasta.plant/quick_actions"

  private static var shared: QuickActionsChannel?

  static func register(with registry: FlutterPluginRegistry) {
    guard let registrar = registry.registrar(forPlugin: "QuickActionsChannel") else { return }
    let instance = QuickActionsChannel()
    shared = instance
    let channel = FlutterMethodChannel(name: name, binaryMessenger: registrar.messenger())
    instance.channel = channel
    channel.setMethodCallHandler { call, result in instance.handle(call, result: result) }
    registrar.addSceneDelegate(instance)
  }

  private var channel: FlutterMethodChannel?

  /// Le raccourci qui a lancé l'application, tant que Dart ne l'a pas pris.
  private var pending: String?

  /// Dart a demandé le raccourci de lancement : il écoute, désormais.
  private var dartListens = false

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "setItems":
      guard let items = call.arguments as? [[String: String]] else {
        result(FlutterError(code: "bad_args", message: "items expected", details: nil))
        return
      }
      UIApplication.shared.shortcutItems = items.compactMap { item in
        guard let type = item["type"], let title = item["title"] else { return nil }
        let icon = item["icon"].map { UIApplicationShortcutIcon(systemImageName: $0) }
        return UIApplicationShortcutItem(type: type, localizedTitle: title, localizedSubtitle: nil, icon: icon, userInfo: nil)
      }
      result(nil)
    case "launchAction":
      dartListens = true
      result(pending)
      pending = nil
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func deliver(_ type: String) {
    if dartListens, let channel {
      channel.invokeMethod("perform", arguments: type)
    } else {
      pending = type
    }
  }

  // MARK: - FlutterSceneLifeCycleDelegate

  @objc(scene:willConnectToSession:options:)
  func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UISceneConnectionOptions?) -> Bool {
    if let item = connectionOptions?.shortcutItem { deliver(item.type) }
    // On a regardé, on n'a rien pris : la scène reste à Flutter.
    return false
  }

  @objc(windowScene:performActionForShortcutItem:completionHandler:)
  func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) -> Bool {
    deliver(shortcutItem.type)
    completionHandler(true)
    return true
  }
}
