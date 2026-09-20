import Flutter
import UIKit

/// La chrome de navigation d'Auxine sur iOS, rendue par UIKit.
///
/// **Pourquoi du natif.** Sur iPhone Duo, iOS déplace les commandes d'une
/// application dans une bande verticale au bord de l'écran. Apple est
/// explicite sur la condition : une `UITabBar` ou une `UINavigationBar` posée
/// seule n'est pas prise en compte pour ce placement ; il faut un
/// `UITabBarController` ou un `UINavigationController`, qui possèdent leur
/// barre. Une barre dessinée par Flutter, si fidèle soit-elle, reste du
/// contenu aux yeux du système.
///
/// **La forme retenue.** Un seul moteur Flutter, et go_router garde la
/// navigation entre les pages. Le contrôleur d'onglets ne sert qu'à la chrome :
///
/// ```
/// UITabBarController          ← possède la barre, qu'iOS place
/// ├── HostViewController      ← un par onglet, vide
/// │   └── (la vue de Flutter, quand cet onglet est choisi)
/// └── …
/// ```
///
/// Un contrôleur d'onglets tire ses onglets de ses enfants : il en faut donc
/// autant que d'onglets. Mais il n'y a qu'un moteur, donc qu'une vue Flutter,
/// et elle déménage d'un hôte à l'autre au changement d'onglet. C'est la
/// contenance UIKit ordinaire — `addChild`, `didMove` —, pas un tour de passe-
/// passe : l'hôte sélectionné est le parent, les autres sont vides.
///
/// Toucher un onglet ne change rien tout seul : le natif le dit à Dart, Dart
/// change de branche go_router, et c'est Flutter qui redessine. L'inverse
/// vaut aussi — un lien profond change l'onglet depuis Dart.
final class NativeShell: NSObject, UITabBarControllerDelegate {
  static let name = "ch.vergasta.plant/native_shell"
  static let shared = NativeShell()

  private var channel: FlutterMethodChannel?
  private weak var flutter: UIViewController?
  private var onglets: UITabBarController?
  private var hotes: [HostViewController] = []
  /// Vrai pendant qu'on applique une sélection venue de Dart : le contrôleur
  /// préviendrait sinon Dart d'un changement que Dart vient de demander.
  private var enEcho = false

  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: name, binaryMessenger: messenger)
    shared.channel = channel
    channel.setMethodCallHandler { call, result in shared.handle(call, result) }
  }

  /// Pose le contrôleur d'onglets autour du contrôleur de Flutter.
  ///
  /// Appelé une fois la scène montée : c'est elle qui possède la fenêtre, et
  /// le storyboard y a déjà posé Flutter.
  static func install(in scene: UIScene) {
    guard let windowScene = scene as? UIWindowScene else { return }
    let fenetres = windowScene.windows
    guard let window = fenetres.first(where: { $0.isKeyWindow }) ?? fenetres.first,
      let flutter = window.rootViewController,
      !(flutter is UITabBarController)
    else { return }

    let onglets = UITabBarController()
    onglets.delegate = shared
    shared.flutter = flutter
    shared.onglets = onglets
    // Un seul hôte au départ : Dart dira combien il en faut, et lesquels.
    shared.rebatir(titres: [""], symboles: ["circle"])
    window.rootViewController = onglets
    #if DEBUG
      print("[auxine:natif] coquille posée autour de \(type(of: flutter))")
    #endif
  }

  private func handle(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    switch call.method {
    case "setTabs":
      guard let args = call.arguments as? [String: Any],
        let bruts = args["tabs"] as? [[String: Any]], !bruts.isEmpty
      else {
        result(false)
        return
      }
      rebatir(
        titres: bruts.map { $0["title"] as? String ?? "" },
        symboles: bruts.map { $0["symbol"] as? String ?? "circle" })
      if let choisi = args["selected"] as? Int { choisir(choisi) }
      result(true)
    case "setSelected":
      choisir((call.arguments as? Int) ?? 0)
      result(true)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// Refait les hôtes, un par onglet, et redonne sa vue à Flutter.
  private func rebatir(titres: [String], symboles: [String]) {
    guard let onglets else { return }
    let choisi = min(onglets.selectedIndex, max(0, titres.count - 1))
    hotes = titres.indices.map { i in
      let hote = HostViewController()
      hote.tabBarItem = UITabBarItem(
        title: titres[i],
        image: UIImage(systemName: symboles[i]),
        tag: i)
      return hote
    }
    onglets.setViewControllers(hotes, animated: false)
    enEcho = true
    onglets.selectedIndex = choisi
    enEcho = false
    heberger(dans: hotes[choisi])
  }

  private func choisir(_ index: Int) {
    guard let onglets, index >= 0, index < hotes.count, index != onglets.selectedIndex else { return }
    enEcho = true
    onglets.selectedIndex = index
    enEcho = false
    heberger(dans: hotes[index])
  }

  /// Déménage la vue de Flutter dans l'hôte donné. Sans effet s'il y est déjà.
  private func heberger(dans hote: UIViewController) {
    guard let flutter, flutter.parent !== hote else { return }
    if flutter.parent != nil {
      flutter.willMove(toParent: nil)
      flutter.view.removeFromSuperview()
      flutter.removeFromParent()
    }
    hote.addChild(flutter)
    flutter.view.frame = hote.view.bounds
    flutter.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    hote.view.insertSubview(flutter.view, at: 0)
    flutter.didMove(toParent: hote)
  }

  // MARK: - UITabBarControllerDelegate

  func tabBarController(_ controller: UITabBarController, didSelect viewController: UIViewController) {
    guard !enEcho, let index = hotes.firstIndex(where: { $0 === viewController }) else { return }
    heberger(dans: hotes[index])
    channel?.invokeMethod("onTab", arguments: index)
  }
}

/// L'hôte d'un onglet : une vue vide, qui reçoit celle de Flutter quand c'est
/// son tour. Elle ne dessine rien et ne capte rien — tout vient de Flutter.
final class HostViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .clear
  }
}
