import Flutter
import UIKit

/// Délégué de scène. Sous le cycle de vie UIScene, c'est la scène et non
/// l'application qui possède la fenêtre.
///
/// Il ne sert qu'à une chose de plus, et seulement en debug : dire dans quel
/// mode l'iPhone Duo fait tourner l'application. Apple n'ouvre l'expérience
/// bord-à-bord qu'aux binaires construits avec le SDK iOS 27.1 ou plus
/// récent ; en deçà, iOS applique un mode de compatibilité — bande noire,
/// fenêtre réduite — et la fenêtre que Flutter mesure n'est pas celle de
/// l'appareil ouvert. Les deux se ressemblent assez pour qu'on prenne l'un
/// pour l'autre, et les cotes changent de 80 points selon le cas (voir
/// docs/05-technical-architecture.md, section « La fenêtre »).
///
/// À lire dans la console de Xcode, à côté des relevés `[auxine:fenêtre]`
/// qu'écrit `app/window_probe.dart`. Changer de simulateur ne suffit pas :
/// c'est le SDK inscrit dans le bundle qui décide, donc le Xcode sélectionné
/// au moment de la construction.
class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    logDuoBuild(scene)
    // Prototype : la chrome de navigation passe à UIKit. Cette ligne est
    // toute la bascule — l'enlever rend l'application à Flutter seul.
    DuoNativeChrome.install(in: scene)
  }

  private func logDuoBuild(_ scene: UIScene) {
    #if DEBUG
      let info = Bundle.main.infoDictionary ?? [:]
      let sdk = info["DTSDKName"] as? String ?? "inconnu"
      let xcode = info["DTXcode"] as? String ?? "inconnu"
      print("[auxine:sdk] sdk=\(sdk) xcode=\(xcode)")

      let version =
        sdk
        .replacingOccurrences(of: "iphonesimulator", with: "")
        .replacingOccurrences(of: "iphoneos", with: "")
      if version != "inconnu",
        version.compare("27.1", options: .numeric) == .orderedAscending
      {
        print(
          "[auxine:sdk] mode de compatibilité : le bord-à-bord de l'iPhone Duo "
            + "demande le SDK iOS 27.1 ou plus récent.")
      }

      guard let windowScene = scene as? UIWindowScene else { return }
      print(
        "[auxine:sdk] scène=\(windowScene.coordinateSpace.bounds) "
          + "écran=\(windowScene.screen.bounds)")
    #endif
  }
}
