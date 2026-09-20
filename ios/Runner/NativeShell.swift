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
/// UITabBarController              ← possède la barre d'onglets
/// ├── UINavigationController      ← un par onglet, possède sa barre
/// │   └── HostViewController      ← vide, porte le titre et les boutons
/// │       └── (la vue de Flutter, quand cet onglet est choisi)
/// └── …
/// ```
///
/// Les deux contrôleurs sont là pour la même raison : ce sont eux, et non
/// leurs barres prises isolément, qu'iOS considère pour le placement
/// vertical. Les boutons des pages sont donc de vrais `UIBarButtonItem`,
/// dessinés en SF Symbols — voir `core/sf_symbols.dart`, qui traduit les
/// icônes d'Auxine sans que les pages aient à changer.
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
  private var navigations: [UINavigationController] = []
  /// L'identité des boutons de la page ouverte, dans l'ordre reçu. Un
  /// `UIBarButtonItem` ne porte qu'un entier, pas une chaîne.
  private var identifiants: [String] = []
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
    case "setChromeHidden":
      // Une page ouverte par Flutter par-dessus la coquille n'existe pas pour
      // UIKit : sans cela, ses barres restaient posées dessus, avec les
      // boutons de la page d'en dessous.
      let cache = (call.arguments as? Bool) ?? false
      for navigation in navigations {
        navigation.setNavigationBarHidden(cache, animated: false)
      }
      onglets?.tabBar.isHidden = cache
      result(true)
    case "setActions":
      guard let args = call.arguments as? [String: Any] else {
        result(false)
        return
      }
      appliquer(args)
      result(true)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// Refait les hôtes, un par onglet, et redonne sa vue à Flutter.
  private func rebatir(titres: [String], symboles: [String]) {
    guard let onglets else { return }
    let choisi = min(onglets.selectedIndex, max(0, titres.count - 1))
    hotes = titres.indices.map { _ in HostViewController() }
    navigations = titres.indices.map { i in
      let navigation = UINavigationController(rootViewController: hotes[i])
      navigation.navigationBar.prefersLargeTitles = false
      navigation.tabBarItem = UITabBarItem(
        title: titres[i],
        image: UIImage(systemName: symboles[i]),
        tag: i)
      return navigation
    }
    onglets.setViewControllers(navigations, animated: false)
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
  ///
  /// Par contraintes et non par cadre : au moment du déménagement, l'hôte n'a
  /// pas encore été mis en page, et `bounds` y vaut ce qu'il veut. Un cadre
  /// recopié de là fige une erreur que le redimensionnement automatique
  /// reporte ensuite — les marges sûres de Flutter annonçaient 34 points en
  /// bas là où la barre d'onglets en prenait 83, et le contenu passait
  /// dessous. Les contraintes, elles, se résolvent quand la mise en page
  /// arrive, et disparaissent avec la vue quand elle repart.
  private func heberger(dans hote: UIViewController) {
    guard let flutter, flutter.parent !== hote else { return }
    if flutter.parent != nil {
      flutter.willMove(toParent: nil)
      flutter.view.removeFromSuperview()
      flutter.removeFromParent()
    }
    hote.addChild(flutter)
    let vue = flutter.view!
    vue.translatesAutoresizingMaskIntoConstraints = false
    hote.view.insertSubview(vue, at: 0)
    NSLayoutConstraint.activate([
      vue.topAnchor.constraint(equalTo: hote.view.topAnchor),
      vue.leadingAnchor.constraint(equalTo: hote.view.leadingAnchor),
      vue.trailingAnchor.constraint(equalTo: hote.view.trailingAnchor),
      vue.bottomAnchor.constraint(equalTo: hote.view.bottomAnchor),
    ])
    flutter.didMove(toParent: hote)
    hote.view.setNeedsLayout()
  }

  /// Pose le titre et les boutons de la page ouverte sur l'onglet courant.
  ///
  /// Le bouton de tête va à gauche, là où iOS met la navigation ; les autres
  /// à droite. `rightBarButtonItems` les range de droite à gauche, donc la
  /// liste est retournée pour que le premier déclaré reste le plus près du
  /// bord — l'ordre qu'une page écrit.
  private func appliquer(_ args: [String: Any]) {
    guard let onglets, onglets.selectedIndex < hotes.count else { return }
    let item = hotes[onglets.selectedIndex].navigationItem
    let titre = args["title"] as? String
    item.title = (titre?.isEmpty ?? true) ? nil : titre

    identifiants = []
    let aGauche = boutons(args["leading"])
    let aDroite = boutons(args["actions"])
    item.leftBarButtonItems = aGauche.isEmpty ? nil : aGauche
    item.rightBarButtonItems = aDroite.isEmpty ? nil : aDroite.reversed()
  }

  /// Bâtit les boutons d'un côté, en notant leur identité au passage.
  private func boutons(_ brut: Any?) -> [UIBarButtonItem] {
    var faits: [UIBarButtonItem] = []
    for description in brut as? [[String: Any]] ?? [] {
      guard let id = description["id"] as? String,
        let symbole = description["symbol"] as? String
      else { continue }
      let bouton = UIBarButtonItem(
        image: UIImage(systemName: symbole),
        style: .plain,
        target: self,
        action: #selector(touche(_:)))
      bouton.tag = identifiants.count
      bouton.accessibilityLabel = description["title"] as? String
      bouton.isEnabled = (description["enabled"] as? Bool) ?? true
      identifiants.append(id)
      faits.append(bouton)
    }
    return faits
  }

  @objc private func touche(_ envoyeur: UIBarButtonItem) {
    guard envoyeur.tag >= 0, envoyeur.tag < identifiants.count else { return }
    channel?.invokeMethod("onAction", arguments: identifiants[envoyeur.tag])
  }

  // MARK: - UITabBarControllerDelegate

  func tabBarController(_ controller: UITabBarController, didSelect viewController: UIViewController) {
    guard !enEcho, let index = navigations.firstIndex(where: { $0 === viewController }) else { return }
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
