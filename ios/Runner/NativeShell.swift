import CoreText
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
  /// Vrai tant qu'une surcouche voile la chrome, et ce que la chrome occupait
  /// au moment où le voile est tombé. Voir `appliquerLaChrome`.
  private var voilee = false
  private var margesVoilees: UIEdgeInsets = .zero
  /// L'état de la chrome, tel que Dart l'a demandé en dernier.
  ///
  /// Les deux barres partent **cachées** : au lancement, le contrôleur
  /// d'onglets n'a qu'un onglet de service — un rond sans nom — et Dart n'a
  /// encore rien dit. Les montrer en attendant, c'est ce rond qu'on montre,
  /// et c'est ce qu'on voyait pendant toute l'introduction.
  ///
  /// L'état est gardé parce que `rebatir` refait les contrôleurs de
  /// navigation : neufs, ils arrivent avec leur barre visible, et Dart ne
  /// redit pas une chrome qui n'a pas changé.
  private var barreDemandee = false
  private var ongletsDemandes = false
  /// Le ton de la barre du haut, tel que la page ouverte l'a demandé.
  private var ton: TonDeBarre = .ordinaire

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

    Typographie.enregistrer()
    // Le vert d'Auxine plutôt que le bleu du système : boutons de barre,
    // onglet choisi, menus. Ce que la fenêtre teinte, tout le reste l'hérite.
    window.tintColor = Palette.sauge
    let onglets = OngletsDAuxine()
    onglets.delegate = shared
    shared.flutter = flutter
    shared.onglets = onglets
    // Un seul hôte au départ : Dart dira combien il en faut, et lesquels.
    // Rien ne se montre avant qu'il l'ait dit — voir `barreDemandee`.
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
    case "setChrome":
      // Une page ouverte par Flutter par-dessus la coquille n'existe pas pour
      // UIKit : sans cela, ses barres restaient posées dessus, avec les
      // boutons de la page d'en dessous. Les deux barres se décident
      // séparément — une fiche garde la sienne, la barre d'onglets non.
      let args = call.arguments as? [String: Any] ?? [:]
      appliquerLaChrome(
        barre: (args["bar"] as? Bool) ?? true,
        onglets: (args["tabs"] as? Bool) ?? true,
        voile: (args["veil"] as? Bool) ?? false)
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

  /// Montre, voile ou efface les deux barres.
  ///
  /// **Les deux se masquent par leur contrôleur**, jamais par leur vue.
  /// `isHidden` et `alpha` portent sur des vues que `UINavigationController`
  /// et `UITabBarController` possèdent : ils les remettent comme ils
  /// l'entendent à chaque mise en page, et sur l'iPhone Duo ce sont eux, non
  /// leurs barres, qui décident de ce que le système range dans la bande
  /// verticale. La barre d'onglets l'a appris en trois tentatives ; la barre
  /// du haut, voilée par son opacité, reparaissait de la même façon — une
  /// feuille du relevé s'ouvrait coiffée du titre et du retour de la page
  /// d'en dessous, et son propre titre se lisait au travers.
  ///
  /// **Voiler n'est pourtant pas effacer.** Une barre retirée rend sa place
  /// au contenu, et la page glisserait sous le menu qui vient de s'ouvrir.
  /// Ce que la vue ne peut pas tenir, la marge sûre le tient : la chrome part
  /// pour de bon, et `additionalSafeAreaInsets` garde sa place au chaud le
  /// temps de la surcouche. La place se mesure pendant que la chrome est
  /// encore là — partie, elle ne dit plus ce qu'elle prenait — et dans les
  /// quatre sens, parce qu'une barre rangée dans la bande verticale ne prend
  /// pas la sienne en haut.
  private func appliquerLaChrome(barre: Bool, onglets ongletsVisibles: Bool, voile: Bool) {
    // Sous un voile, la place se reprend chaque fois que la chrome demandée
    // change : au lancement, l'ouverture voile une chrome qui n'a encore
    // jamais paru, et c'est la coquille, arrivée ensuite, qui la demande.
    let aMesurer = voile && (voile != voilee || barre != barreDemandee || ongletsVisibles != ongletsDemandes)
    barreDemandee = barre
    ongletsDemandes = ongletsVisibles
    if voile != voilee || aMesurer {
      voilee = voile
      margesVoilees = voile ? mesurerLaChrome(barre: barre, onglets: ongletsVisibles) : .zero
    }
    let montrerLaBarre = barre && !voile
    for navigation in navigations {
      navigation.setNavigationBarHidden(!montrerLaBarre, animated: false)
      // L'opacité ne voile plus rien, mais une version qui la mettait à zéro
      // a pu laisser une barre invisible derrière elle.
      navigation.navigationBar.alpha = 1
      navigation.navigationBar.isUserInteractionEnabled = true
      navigation.setNeedsStatusBarAppearanceUpdate()
    }
    let montrerLesOnglets = ongletsVisibles && !voile
    // `setTabBarHidden(_:animated:)` est l'API faite pour ça, depuis iOS 18.
    // En deçà, on retombe sur la vue, faute de mieux.
    if #available(iOS 18.0, *) {
      onglets?.setTabBarHidden(!montrerLesOnglets, animated: false)
    } else if let barreDOnglets = onglets?.tabBar {
      barreDOnglets.isHidden = !montrerLesOnglets
      barreDOnglets.alpha = 1
      barreDOnglets.isUserInteractionEnabled = montrerLesOnglets
    }
    flutter?.additionalSafeAreaInsets = margesVoilees
  }

  /// La place que prendra la chrome demandée, qu'elle soit déjà à l'écran ou
  /// non.
  ///
  /// Une chrome qui n'a jamais paru n'occupe rien, et la mesurer en l'état
  /// donnerait zéro : au lancement, la page sauterait sous les barres le jour
  /// où l'ouverture les rend. On la pose donc le temps d'une mise en page,
  /// transparente, et on la mesure. Tout se passe avant que l'écran ne se
  /// redessine — `appliquerLaChrome` la cache aussitôt après — : elle ne se
  /// voit jamais.
  private func mesurerLaChrome(barre: Bool, onglets ongletsVisibles: Bool) -> UIEdgeInsets {
    if barre {
      for navigation in navigations {
        navigation.navigationBar.alpha = 0
        navigation.setNavigationBarHidden(false, animated: false)
      }
    }
    if ongletsVisibles, let barreDOnglets = onglets?.tabBar {
      barreDOnglets.alpha = 0
      if #available(iOS 18.0, *) {
        onglets?.setTabBarHidden(false, animated: false)
      } else {
        barreDOnglets.isHidden = false
      }
    }
    onglets?.view.setNeedsLayout()
    onglets?.view.layoutIfNeeded()
    flutter?.view.layoutIfNeeded()
    let marges = margesDeLaChrome()
    for navigation in navigations { navigation.navigationBar.alpha = 1 }
    onglets?.tabBar.alpha = 1
    return marges
  }

  /// Ce que la chrome ajoute aujourd'hui à la marge sûre de Flutter.
  ///
  /// La différence entre ce que la vue reçoit et ce que la fenêtre réserve
  /// d'elle-même — l'heure, l'indicateur d'accueil, la bande de la caméra.
  /// Le reste est aux barres, où qu'elles soient posées, et c'est cela seul
  /// qu'un voile doit rendre. Une chrome déjà effacée n'occupe rien, et la
  /// mesure vaut alors zéro : une surcouche posée sur une page plein écran
  /// n'a rien à compenser.
  private func margesDeLaChrome() -> UIEdgeInsets {
    guard let vue = flutter?.view, let fenetre = vue.window else { return .zero }
    let recues = vue.safeAreaInsets
    let systeme = fenetre.safeAreaInsets
    let deja = flutter?.additionalSafeAreaInsets ?? .zero
    return UIEdgeInsets(
      top: max(0, recues.top - systeme.top - deja.top),
      left: max(0, recues.left - systeme.left - deja.left),
      bottom: max(0, recues.bottom - systeme.bottom - deja.bottom),
      right: max(0, recues.right - systeme.right - deja.right))
  }

  /// Refait les hôtes, un par onglet, et redonne sa vue à Flutter.
  private func rebatir(titres: [String], symboles: [String]) {
    guard let onglets else { return }
    let choisi = min(onglets.selectedIndex, max(0, titres.count - 1))
    hotes = titres.indices.map { _ in HostViewController() }
    navigations = titres.indices.map { i in
      let navigation = NavigationDOnglet(rootViewController: hotes[i])
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
    habiller(hotes[choisi], ton: ton)
    // Des contrôleurs neufs arrivent avec leurs barres visibles. Dart ne
    // redit pas une chrome qui n'a pas changé : c'est donc ici qu'on la
    // remet, et au lancement elle vaut « rien de visible ».
    appliquerLaChrome(barre: barreDemandee, onglets: ongletsDemandes, voile: voilee)
  }

  private func choisir(_ index: Int) {
    guard let onglets, index >= 0, index < hotes.count, index != onglets.selectedIndex else { return }
    enEcho = true
    onglets.selectedIndex = index
    enEcho = false
    heberger(dans: hotes[index])
    habiller(hotes[index], ton: ton)
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
    let hote = hotes[onglets.selectedIndex]
    let item = hote.navigationItem
    ton = (args["tone"] as? String) == "brand" ? .marque : .ordinaire
    habiller(hote, ton: ton)
    let titre = args["title"] as? String
    item.title = (titre?.isEmpty ?? true) ? nil : titre

    identifiants = []
    let aGauche = boutons(args["leading"])
    let (aDroite, proeminents) = boutonsDeDroite(args["actions"])
    item.leftBarButtonItems = aGauche.isEmpty ? nil : aGauche
    item.rightBarButtonItems = aDroite.isEmpty ? nil : aDroite.reversed()

    // Le placement des actions proéminentes : iOS les garde visibles quand la
    // bande déborde, au lieu de les replier dans le menu. Il n'existe pas
    // avant iOS 26 ; sans lui, l'action reste un bouton ordinaire, ce qui
    // était le cas jusqu'ici.
    #if compiler(>=6.2)
      if #available(iOS 26.0, *) {
        item.pinnedTrailingGroup = proeminents.isEmpty
          ? nil
          : UIBarButtonItemGroup(barButtonItems: proeminents, representativeItem: nil)
      }
    #endif
  }

  /// Donne à la barre de l'hôte le ton demandé, et à la barre d'état celui
  /// qui va avec.
  ///
  /// **Sur la tête verte**, la barre est transparente : le vert passe dessous
  /// sans voile, et le titre replié, les boutons et l'heure sont blancs.
  /// **Ailleurs**, c'est la barre ordinaire d'iOS — son flou, son filet —,
  /// avec le titre en Bricolage et les boutons au vert d'Auxine.
  ///
  /// L'apparence se pose sur l'élément de navigation de l'hôte, pas sur la
  /// barre : c'est ainsi qu'UIKit la fait suivre d'une page à l'autre, et
  /// qu'il fond le passage de l'une à l'autre au lieu de sauter.
  private func habiller(_ hote: UIViewController, ton: TonDeBarre) {
    let apparence = UINavigationBarAppearance()
    switch ton {
    case .marque:
      apparence.configureWithTransparentBackground()
      apparence.titleTextAttributes = [.foregroundColor: UIColor.white, .font: Typographie.titreDeBarre]
    case .ordinaire:
      apparence.configureWithDefaultBackground()
      apparence.titleTextAttributes = [.font: Typographie.titreDeBarre]
    }
    let item = hote.navigationItem
    item.standardAppearance = apparence
    item.scrollEdgeAppearance = apparence
    item.compactAppearance = apparence
    let navigation = hote.navigationController as? NavigationDOnglet
    navigation?.navigationBar.tintColor = ton == .marque ? .white : nil
    if navigation?.ton != ton {
      navigation?.ton = ton
      navigation?.setNeedsStatusBarAppearanceUpdate()
    }
  }

  /// Les boutons de droite, séparés de celui qu'il ne faut pas replier.
  ///
  /// Si le système ne sait pas épingler, le proéminent rejoint les autres :
  /// une action qui disparaîtrait de la barre serait pire qu'une action mal
  /// classée.
  private func boutonsDeDroite(_ brut: Any?) -> ([UIBarButtonItem], [UIBarButtonItem]) {
    var epinglable = false
    #if compiler(>=6.2)
      if #available(iOS 26.0, *) { epinglable = true }
    #endif
    guard epinglable else { return (boutons(brut), []) }

    let descriptions = brut as? [[String: Any]] ?? []
    let ordinaires = descriptions.filter { ($0["prominent"] as? Bool) != true }
    let proeminents = descriptions.filter { ($0["prominent"] as? Bool) == true }
    return (boutons(ordinaires), boutons(proeminents))
  }

  /// Bâtit les boutons d'un côté, en notant leur identité au passage.
  private func boutons(_ brut: Any?) -> [UIBarButtonItem] {
    var faits: [UIBarButtonItem] = []
    for description in brut as? [[String: Any]] ?? [] {
      guard let id = description["id"] as? String,
        let symbole = description["symbol"] as? String
      else { continue }
      let image = UIImage(systemName: symbole)
      // Un bouton qui porte un menu ne « touche » pas : c'est UIKit qui le
      // déplie, depuis le bouton lui-même, et chaque entrée sait déjà ce
      // qu'elle a à dire. Les autres passent par la cible et le tag, comme
      // avant.
      let bouton: UIBarButtonItem
      if let menu = menuDeplie(description["menu"], de: id) {
        bouton = UIBarButtonItem(image: image, menu: menu)
      } else {
        bouton = UIBarButtonItem(
          image: image,
          style: .plain,
          target: self,
          action: #selector(touche(_:)))
      }
      bouton.tag = identifiants.count
      bouton.accessibilityLabel = description["title"] as? String
      bouton.isEnabled = (description["enabled"] as? Bool) ?? true
      identifiants.append(id)
      faits.append(bouton)
    }
    return faits
  }

  /// Le `UIMenu` d'un bouton, ou `nil` s'il n'en déplie pas.
  ///
  /// C'est là toute la différence avec une feuille d'actions : iOS fait
  /// sortir un menu **du bouton touché**, à sa place dans la barre, et floute
  /// ce qu'il recouvre le temps du choix. Une feuille, elle, monte du bas et
  /// recouvre la page. Seul UIKit sait dessiner le premier ; c'est pour cela
  /// que les entrées traversent le canal plutôt que d'être imitées en argile.
  ///
  /// `separated` ouvre un groupe : iOS sépare ses groupes d'un trait, comme
  /// dans ses propres applications. Un seul groupe ne s'enveloppe pas —
  /// autant donner les entrées telles quelles.
  private func menuDeplie(_ brut: Any?, de id: String) -> UIMenu? {
    let descriptions = brut as? [[String: Any]] ?? []
    guard !descriptions.isEmpty else { return nil }

    var groupes: [[UIAction]] = [[]]
    for (i, description) in descriptions.enumerated() {
      guard let titre = description["title"] as? String else { continue }
      if (description["separated"] as? Bool) == true, !(groupes[groupes.count - 1].isEmpty) {
        groupes.append([])
      }
      var attributs: UIMenuElement.Attributes = []
      if (description["destructive"] as? Bool) == true { attributs.insert(.destructive) }
      if (description["enabled"] as? Bool) == false { attributs.insert(.disabled) }
      // L'identité de l'entrée, et non l'index d'un tableau qu'une autre
      // page aurait remplacé entre-temps : `R1.3`, que Dart sait relire.
      let identite = "\(id).\(i)"
      let symbole = description["symbol"] as? String
      let action = UIAction(
        title: titre,
        image: symbole.flatMap { UIImage(systemName: $0) },
        attributes: attributs
      ) { [weak self] _ in
        self?.channel?.invokeMethod("onAction", arguments: identite)
      }
      groupes[groupes.count - 1].append(action)
    }

    let pleins = groupes.filter { !$0.isEmpty }
    guard !pleins.isEmpty else { return nil }
    let enfants: [UIMenuElement]
    if pleins.count == 1 {
      enfants = pleins[0]
    } else {
      enfants = pleins.map { UIMenu(title: "", options: .displayInline, children: $0) }
    }
    return UIMenu(title: "", children: enfants)
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

/// Le ton de la barre du haut : posée sur la tête verte, ou ordinaire.
enum TonDeBarre { case ordinaire, marque }

/// Le contrôleur d'onglets, qui laisse l'onglet ouvert dire la couleur de
/// l'heure. Sans lui, c'est le contrôleur d'onglets qui en déciderait, et il
/// ne sait rien de la tête verte.
final class OngletsDAuxine: UITabBarController {
  override var childForStatusBarStyle: UIViewController? { selectedViewController }
}

/// La navigation d'un onglet : l'heure en blanc sur la tête verte, dans la
/// couleur du thème ailleurs.
final class NavigationDOnglet: UINavigationController {
  var ton: TonDeBarre = .ordinaire

  /// Sans barre, c'est la page qui décide : Flutter, par ce qu'il déclare
  /// sous l'heure (une photo en tête de fiche la veut blanche). Avec une
  /// barre, c'est le ton de la barre.
  override var childForStatusBarStyle: UIViewController? {
    isNavigationBarHidden ? topViewController : nil
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    ton == .marque && !isNavigationBarHidden ? .lightContent : .default
  }
}

/// Les couleurs d'Auxine dont UIKit a besoin, recopiées de
/// `lib/design_system/tokens/colors.dart`.
enum Palette {
  /// `sage` : le vert qui écrit, sombre en clair et clair en sombre.
  static let sauge = UIColor { trait in
    trait.userInterfaceStyle == .dark
      ? UIColor(red: CGFloat(0x74) / 255, green: CGFloat(0xCF) / 255, blue: CGFloat(0x95) / 255, alpha: 1)
      : UIColor(red: CGFloat(0x2A) / 255, green: CGFloat(0x74) / 255, blue: CGFloat(0x47) / 255, alpha: 1)
  }
}

/// Bricolage Grotesque, la police des titres d'Auxine, pour les titres que
/// dessine UIKit.
///
/// Flutter l'embarque dans ses propres ressources ; UIKit ne la voit pas tant
/// qu'on ne la lui déclare pas. On la déclare donc depuis le même fichier —
/// `assets/fonts/BricolageGrotesque-VF.ttf` —, sans en garder une copie à
/// part dans le projet Xcode. C'est une fonte variable : le poids et la
/// taille optique se règlent sur ses axes, comme côté Dart.
enum Typographie {
  private static var enregistree = false
  private static let nom = "BricolageGrotesque-96ptExtraBold"

  static func enregistrer() {
    guard !enregistree else { return }
    enregistree = true
    let cle = FlutterDartProject.lookupKey(forAsset: "assets/fonts/BricolageGrotesque-VF.ttf")
    guard let chemin = Bundle.main.path(forResource: cle, ofType: nil) else { return }
    CTFontManagerRegisterFontsForURL(URL(fileURLWithPath: chemin) as CFURL, .process, nil)
  }

  /// Le titre replié d'une barre : 17 points, comme celui du système, mais
  /// gras et serré. Le texte agrandi le fait grandir avec lui.
  static var titreDeBarre: UIFont {
    let taille = UIFontMetrics(forTextStyle: .headline).scaledValue(for: 17)
    guard let base = UIFont(name: nom, size: taille) else {
      return .preferredFont(forTextStyle: .headline)
    }
    let axes: [NSNumber: NSNumber] = [
      0x7767_6874: 720,  // 'wght'
      0x6F70_737A: NSNumber(value: Double(taille)),  // 'opsz'
    ]
    let descripteur = base.fontDescriptor.addingAttributes([
      UIFontDescriptor.AttributeName(rawValue: kCTFontVariationAttribute as String): axes
    ])
    return UIFont(descriptor: descripteur, size: taille)
  }
}

/// L'hôte d'un onglet : une vue vide, qui reçoit celle de Flutter quand c'est
/// son tour. Elle ne dessine rien et ne capte rien — tout vient de Flutter.
final class HostViewController: UIViewController {
  /// La vue de Flutter, quand elle est ici : c'est elle qui dit la couleur de
  /// l'heure d'une page sans barre.
  override var childForStatusBarStyle: UIViewController? { children.first }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .clear
  }
}
