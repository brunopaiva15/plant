import ARKit
import CoreLocation
import Flutter
import RoomPlan
import UIKit

/// Le relevé d'une pièce par RoomPlan, pour la partie Dart
/// (`lib/data/services/room_scan_service.dart`). Voir docs/17.
///
/// Deux questions : ce que l'appareil sait faire, et relever une pièce dans
/// un fichier. Le relevé lui-même est celui du système, avec son coaching ;
/// au « Terminer », le `CapturedRoom` est encodé en JSON à l'endroit demandé
/// et rien d'autre n'en sort — ni maillage, ni `.usdz`, ni réseau.
///
/// Ce que RoomPlan ne donne pas, et qu'on mesure ici : le nord. Le repère
/// d'ARKit est orienté au hasard au lancement ; pendant le relevé, la
/// boussole et le lacet de la caméra sont lus au même instant, plusieurs
/// fois, et la moyenne circulaire de leur écart dit où est le nord dans le
/// repère du relevé. Une boussole de téléphone vaut dix à quinze degrés :
/// l'écran Dart montre l'orientation trouvée et demande de la confirmer.
final class RoomScanChannel: NSObject {
  static let name = "ch.vergasta.plant/room_scan"

  private static var shared: RoomScanChannel?

  static func register(with messenger: FlutterBinaryMessenger) {
    let instance = RoomScanChannel()
    shared = instance
    let channel = FlutterMethodChannel(name: name, binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in instance.handle(call, result: result) }
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "support":
      result(support())
    case "scan":
      guard let args = call.arguments as? [String: Any], let path = args["path"] as? String, !path.isEmpty else {
        result(FlutterError(code: "bad_args", message: "path missing", details: nil))
        return
      }
      scan(to: path, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func support() -> [String: Any] {
    var out: [String: Any] = ["lidar": RoomCaptureSession.isSupported, "sections": false, "structure": false]
    if #available(iOS 17.0, *) {
      out["sections"] = true
      out["structure"] = true
    }
    return out
  }

  // MARK: - Relevé

  private var controller: RoomScanViewController?

  private func scan(to path: String, result: @escaping FlutterResult) {
    guard RoomCaptureSession.isSupported else {
      result(nil)
      return
    }
    guard controller == nil, let root = Self.rootViewController() else {
      result(FlutterError(code: "busy", message: "a scan is already running", details: nil))
      return
    }
    let once = Once()
    let vc = RoomScanViewController(path: path) { [weak self] answer in
      self?.controller = nil
      once.run { result(answer) }
    }
    controller = vc
    vc.modalPresentationStyle = .fullScreen
    root.present(vc, animated: true)
  }

  private static func rootViewController() -> UIViewController? {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    let window = scenes.flatMap { $0.windows }.first { $0.isKeyWindow } ?? scenes.first?.windows.first
    var top = window?.rootViewController
    while let presented = top?.presentedViewController { top = presented }
    return top
  }
}

/// Le contrôleur du relevé : la vue de RoomPlan, ses boutons, et la
/// boussole qui tourne à côté le temps du relevé.
final class RoomScanViewController: UIViewController, RoomCaptureViewDelegate, RoomCaptureSessionDelegate, CLLocationManagerDelegate {
  private let path: String
  private let finish: ([String: Any]?) -> Void

  private var captureView: RoomCaptureView!
  private var doneButton: UIBarButtonItem!
  private var finalRoom: CapturedRoom?
  private var cancelled = false

  private let location = CLLocationManager()
  private let north = NorthEstimator()

  init(path: String, finish: @escaping ([String: Any]?) -> Void) {
    self.path = path
    self.finish = finish
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { fatalError() }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .black
    captureView = RoomCaptureView(frame: view.bounds)
    captureView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    captureView.delegate = self
    captureView.captureSession.delegate = self
    view.addSubview(captureView)

    let bar = UIToolbar()
    bar.translatesAutoresizingMaskIntoConstraints = false
    let cancel = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
    doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneTapped))
    bar.items = [cancel, UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), doneButton]
    view.addSubview(bar)
    NSLayoutConstraint.activate([
      bar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      bar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      bar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
    ])

    // La boussole : le cap vrai demande la position, que l'application a
    // pu obtenir pour la météo ; sans elle, le cap magnétique fait l'affaire.
    location.delegate = self
    location.headingFilter = 2
    if CLLocationManager.headingAvailable() { location.startUpdatingHeading() }
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    var configuration = RoomCaptureSession.Configuration()
    configuration.isCoachingEnabled = true
    captureView.captureSession.run(configuration: configuration)
  }

  @objc private func cancelTapped() {
    cancelled = true
    captureView.captureSession.stop()
    location.stopUpdatingHeading()
    dismiss(animated: true) { self.finish(nil) }
  }

  @objc private func doneTapped() {
    doneButton.isEnabled = false
    location.stopUpdatingHeading()
    // L'arrêt lance le traitement final ; `didPresent` rend la pièce.
    captureView.captureSession.stop()
  }

  // MARK: RoomCaptureViewDelegate

  func captureView(shouldPresent roomDataForProcessing: CapturedRoomData, error: Error?) -> Bool {
    return !cancelled
  }

  func captureView(didPresent processedResult: CapturedRoom, error: Error?) {
    if cancelled { return }
    finalRoom = processedResult
    var answer: [String: Any] = [:]
    do {
      let data = try JSONEncoder().encode(processedResult)
      try data.write(to: URL(fileURLWithPath: path), options: .atomic)
      answer["path"] = path
      if let offset = north.offsetDegrees { answer["northOffsetDeg"] = offset }
    } catch {
      answer["error"] = error.localizedDescription
    }
    if let error = error { answer["error"] = [answer["error"] as? String, error.localizedDescription].compactMap { $0 }.joined(separator: "; ") }
    // Sans fichier ni raison, c'est un relevé vide : rien à dire. Avec une
    // raison, Dart la montre.
    dismiss(animated: true) { self.finish(answer.isEmpty ? nil : answer) }
  }

  // MARK: RoomCaptureSessionDelegate

  func captureSession(_ session: RoomCaptureSession, didUpdate room: CapturedRoom) {
    // Rien : la vue du système se redessine seule.
  }

  // MARK: CLLocationManagerDelegate

  func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
    guard newHeading.headingAccuracy >= 0, newHeading.headingAccuracy <= 25 else { return }
    guard let frame = captureView.captureSession.arSession.currentFrame else { return }
    let compass = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
    north.add(cameraTransform: frame.camera.transform, compassDegrees: compass)
  }
}

/// Le nord dans le repère d'ARKit, par la moyenne circulaire de l'écart
/// entre le cap de la boussole et le lacet de la caméra, pris ensemble.
///
/// Le cap d'une direction du repère se lit comme `atan2(x, −z)` : zéro vers
/// −z, quatre-vingt-dix vers +x, dans le sens horaire vu du dessus — la
/// même convention que `ScannedRoom.headingOf` côté Dart. Le nord est alors
/// `cap(caméra) − boussole`, et une direction quelconque a pour cap compas
/// `cap(direction) − nord`.
final class NorthEstimator {
  private var sinSum = 0.0
  private var cosSum = 0.0
  private var count = 0

  func add(cameraTransform t: simd_float4x4, compassDegrees: Double) {
    // La caméra regarde le long de −z de son repère : la colonne 2, inversée.
    let forward = simd_float3(-t.columns.2.x, -t.columns.2.y, -t.columns.2.z)
    let flat = simd_float2(forward.x, forward.z)
    guard simd_length(flat) > 0.2 else { return }  // Caméra vers le sol ou le plafond : pas de lacet lisible.
    let heading = atan2(Double(flat.x), Double(-flat.y)) * 180 / .pi
    let offset = (heading - compassDegrees) * .pi / 180
    sinSum += sin(offset)
    cosSum += cos(offset)
    count += 1
  }

  /// Le cap du nord, en degrés dans [0, 360), ou rien avec moins de cinq
  /// mesures d'accord : une seule lecture de boussole ne vaut rien.
  var offsetDegrees: Double? {
    guard count >= 5 else { return nil }
    let r = sqrt(sinSum * sinSum + cosSum * cosSum) / Double(count)
    guard r >= 0.8 else { return nil }  // Les mesures se contredisent : la boussole est troublée.
    let deg = atan2(sinSum, cosSum) * 180 / .pi
    return (deg.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360)
  }
}

/// Un bloc qui ne s'exécute qu'une fois : une réponse Flutter ne se donne
/// pas deux fois.
private final class Once {
  private var done = false
  func run(_ body: () -> Void) {
    if done { return }
    done = true
    body()
  }
}
