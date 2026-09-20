import Flutter
import UIKit

/// Ce que le système réserve dans la fenêtre, rendu à Dart en points.
///
/// Trois choses, et trois raisons :
///
/// - les **régions d'occlusion** (`.occlusion`), c'est-à-dire la caméra sous
///   l'écran. Leur milieu donne l'axe de la colonne du système, celui sur
///   lequel le menu debout s'aligne (`FloraTabRail`). Il était mesuré à la
///   main sur des captures ; il est désormais demandé ;
/// - les **régions de division** (`.division`), c'est-à-dire le pli. C'est ce
///   que `MediaQuery.displayFeatures` ne donne pas sur iOS, et la seule façon
///   pour une mise en page d'éviter la charnière ;
/// - le **cadre de la barre d'état**, qui passe debout sur un pliable. C'est
///   lui qui dit jusqu'où descendent l'heure et le wifi — ce qu'aucune marge
///   sûre n'annonce : `padding.top` vaut 82 là où la pile descend à 140.
///
/// Tout est rendu dans le repère de la vue Flutter, en points. Sans réponse
/// utilisable, Dart garde ses valeurs mesurées : voir
/// `lib/core/window_regions.dart`.
///
/// `reservedRegions(kind:)` n'existe qu'à partir du SDK iOS 27.1, livré avec
/// Swift 6.4. Le `#if swift(>=6.4)` n'est donc pas une coquetterie : sans
/// lui, ce fichier ne compilerait pas sur un Xcode plus ancien — le symbole
/// n'y existe pas, et `#available` seul ne suffirait pas à le cacher au
/// compilateur.
final class WindowRegionsChannel {
  static let name = "ch.vergasta.plant/window_regions"

  static func register(with messenger: FlutterBinaryMessenger) {
    let instance = WindowRegionsChannel()
    let channel = FlutterMethodChannel(name: name, binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "read" else {
        result(FlutterMethodNotImplemented)
        return
      }
      result(instance.read())
    }
  }

  private func read() -> [String: Any] {
    guard let scene = Self.activeScene(), let window = Self.keyWindow(in: scene),
      let view = window.rootViewController?.view
    else {
      return ["available": false, "reason": "noView"]
    }

    var payload: [String: Any] = [
      "available": true,
      // De quoi lire un tableau vide : sans ces trois-là, « aucune région »
      // ne dit pas si c'est le SDK, le système ou la pose qui se tait.
      "swift": Self.swiftVersion,
      "os": UIDevice.current.systemVersion,
      "posee": view.window != nil,
      "reservedRegions": "SDK antérieur à 27.1 — non compilé",
      "occlusions": [[String: Any]](),
      "divisions": [[String: Any]](),
    ]

    // La barre d'état est donnée dans le repère de l'écran ; on la ramène
    // dans celui de la vue, qui est le seul dont Dart connaisse les cotes.
    //
    // Sur l'iPhone Duo elle ne vaut rien : mesurée sur l'écran extérieur,
    // elle rend 466 × 2 points en haut à gauche pendant que l'heure et le
    // wifi sont debout contre le bord droit. Le cadre part quand même — Dart
    // l'écarte (`WindowRegionsService.parse`), et sur un appareil ordinaire
    // il reste juste.
    if let bar = scene.statusBarManager?.statusBarFrame, !bar.isEmpty {
      payload["statusBar"] = Self.encode(view.convert(bar, from: nil))
    }

    #if swift(>=6.4)
      if #available(iOS 27.1, *) {
        payload["reservedRegions"] = "lues"
        // La vue d'abord, la fenêtre ensuite : une région n'est rendue qu'aux
        // vues qu'elle recouvre, et rien ne dit que celle de Flutter en soit
        // une. La fenêtre, elle, les recouvre toutes ; ses cadres reviennent
        // alors dans le repère de la vue.
        var occlusions = view.reservedRegions(kind: .occlusion).map { $0.frame }
        if occlusions.isEmpty {
          occlusions = window.reservedRegions(kind: .occlusion).map {
            view.convert($0.frame, from: window)
          }
        }
        var divisions = view.reservedRegions(kind: .division).map { $0.frame }
        if divisions.isEmpty {
          divisions = window.reservedRegions(kind: .division).map {
            view.convert($0.frame, from: window)
          }
        }
        payload["occlusions"] = occlusions.map(Self.encode)
        payload["divisions"] = divisions.map(Self.encode)
      } else {
        payload["reservedRegions"] = "système antérieur à 27.1"
      }
    #endif

    return payload
  }

  /// La version du compilateur, parce que c'est elle qui décide si le bloc
  /// ci-dessus existe — et qu'un tableau vide ne le dit pas tout seul.
  private static var swiftVersion: String {
    #if swift(>=6.5)
      return "6.5+"
    #elseif swift(>=6.4)
      return "6.4"
    #elseif swift(>=6.3)
      return "6.3"
    #elseif swift(>=6.2)
      return "6.2"
    #else
      return "< 6.2"
    #endif
  }

  private static func activeScene() -> UIWindowScene? {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    return scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
  }

  private static func keyWindow(in scene: UIWindowScene) -> UIWindow? {
    return scene.windows.first { $0.isKeyWindow } ?? scene.windows.first
  }

  private static func encode(_ rect: CGRect) -> [String: Any] {
    return [
      "x": Double(rect.minX), "y": Double(rect.minY),
      "width": Double(rect.width), "height": Double(rect.height),
    ]
  }
}
