import Flutter
import UIKit

/// **Prototype.** La chrome de navigation rendue par UIKit plutôt que par
/// Flutter, pour voir ce que l'iPhone Duo en fait.
///
/// La question à laquelle ce fichier sert à répondre, et rien d'autre : iOS
/// déplace-t-il vraiment nos boutons dans la bande verticale de droite, à quoi
/// ressemblent-ils une fois là, et que se passe-t-il quand il y en a trop ?
///
/// Apple est explicite sur la condition : une `UINavigationBar`, une
/// `UIToolbar` ou une `UITabBar` posée seule n'est **pas** prise en compte
/// pour le placement vertical. Il faut un `UINavigationController` ou un
/// `UITabBarController`, qui possèdent leur barre. D'où le seul geste natif de
/// ce prototype : envelopper le contrôleur de Flutter dans un contrôleur de
/// navigation, et laisser iOS décider du reste.
///
/// Ce que ce prototype ne fait **pas**, volontairement :
///
/// - pas de `UITabBarController` : il voudrait quatre contrôleurs enfants,
///   donc quatre moteurs Flutter, et go_router ne posséderait plus les
///   onglets. La colonne Flutter reste en place pour eux ;
/// - pas de `pinnedTrailingGroup` : c'est le placement des « actions
///   proéminentes », et il demande une API dont on n'a pas encore vu le
///   comportement. Une fois le placement de base constaté, ce sera l'étape
///   suivante ;
/// - pas de bouton retour natif : la pile de navigation n'a qu'un élément,
///   celui de Flutter. Un « retour » envoyé d'ici est un bouton ordinaire que
///   Dart traite comme il l'entend.
///
/// Rien de tout cela n'est branché dans l'application : la branche de ce
/// prototype l'est, `main` ne l'est pas.
final class DuoNativeChrome: NSObject {
  static let name = "ch.vergasta.plant/native_chrome"
  static let shared = DuoNativeChrome()

  private var channel: FlutterMethodChannel?
  private weak var host: UIViewController?
  private weak var navigation: UINavigationController?
  /// L'identité des boutons, dans l'ordre où Dart les a envoyés. Un
  /// `UIBarButtonItem` ne porte qu'un entier — `tag` —, pas une chaîne.
  private var identifiants: [String] = []

  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: name, binaryMessenger: messenger)
    shared.channel = channel
    channel.setMethodCallHandler { call, result in
      shared.handle(call, result)
    }
  }

  /// Enveloppe le contrôleur de Flutter dans un `UINavigationController`.
  ///
  /// Appelé une fois la scène montée : c'est elle qui possède la fenêtre, et
  /// le contrôleur de Flutter y est déjà posé par le storyboard.
  static func install(in scene: UIScene) {
    guard let windowScene = scene as? UIWindowScene else { return }
    let fenetres = windowScene.windows
    guard let window = fenetres.first(where: { $0.isKeyWindow }) ?? fenetres.first,
      let flutter = window.rootViewController,
      !(flutter is UINavigationController)
    else { return }

    // Flutter garde toute sa surface : la barre se pose par-dessus, et ce que
    // l'application mesure comme marge sûre en tient compte.
    flutter.extendedLayoutIncludesOpaqueBars = true
    let navigation = UINavigationController(rootViewController: flutter)
    navigation.navigationBar.prefersLargeTitles = false
    navigation.navigationBar.isTranslucent = true
    window.rootViewController = navigation
    shared.host = flutter
    shared.navigation = navigation
    #if DEBUG
      print("[auxine:natif] contrôleur de navigation posé autour de \(type(of: flutter))")
    #endif
  }

  private func handle(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    guard call.method == "setChrome" else {
      result(FlutterMethodNotImplemented)
      return
    }
    guard let args = call.arguments as? [String: Any] else {
      result(false)
      return
    }
    result(apply(args))
  }

  private func apply(_ args: [String: Any]) -> Bool {
    guard let hote = host else { return false }
    let item = hote.navigationItem
    item.title = args["title"] as? String

    var primaires: [UIBarButtonItem] = []
    var suivants: [UIBarButtonItem] = []
    var enBas: [UIBarButtonItem] = []
    identifiants = []

    for brut in args["items"] as? [[String: Any]] ?? [] {
      guard let id = brut["id"] as? String, let symbole = brut["symbol"] as? String else { continue }
      let bouton = UIBarButtonItem(
        image: UIImage(systemName: symbole),
        style: .plain,
        target: self,
        action: #selector(touche(_:)))
      bouton.tag = identifiants.count
      bouton.accessibilityLabel = brut["title"] as? String
      identifiants.append(id)
      switch brut["placement"] as? String {
      case "primary": primaires.append(bouton)
      case "bottom": enBas.append(bouton)
      default: suivants.append(bouton)
      }
    }

    item.leftBarButtonItems = primaires.isEmpty ? nil : primaires
    // De droite à gauche : le premier envoyé doit rester le plus au bord.
    item.rightBarButtonItems = suivants.isEmpty ? nil : suivants.reversed()
    hote.toolbarItems = enBas.isEmpty ? nil : enBas
    navigation?.isToolbarHidden = enBas.isEmpty
    return true
  }

  @objc private func touche(_ envoyeur: UIBarButtonItem) {
    guard envoyeur.tag >= 0, envoyeur.tag < identifiants.count else { return }
    channel?.invokeMethod("onItem", arguments: identifiants[envoyeur.tag])
  }
}
