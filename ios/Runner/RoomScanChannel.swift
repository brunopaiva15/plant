import ARKit
import CoreLocation
import Flutter
import RoomPlan
import UIKit

/// Le relevé d'une pièce — ou de l'appartement — par RoomPlan, pour la
/// partie Dart (`lib/data/services/room_scan_service.dart`). Voir docs/17.
///
/// Trois questions : ce que l'appareil sait faire, relever une pièce dans
/// un fichier, relever l'appartement pièce après pièce dans un dossier. Le
/// relevé lui-même est celui du système, avec son coaching ; au
/// « Terminer », les `CapturedRoom` sont encodés en JSON à l'endroit
/// demandé et rien d'autre n'en sort — ni maillage, ni `.usdz`, ni réseau.
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
      scan(mode: .room(path: path), nextRoomLabel: nil, result: result)
    case "scanStructure":
      guard let args = call.arguments as? [String: Any], let dir = args["directory"] as? String, !dir.isEmpty else {
        result(FlutterError(code: "bad_args", message: "directory missing", details: nil))
        return
      }
      guard #available(iOS 17.0, *) else {
        result(FlutterError(code: "unsupported", message: "structure needs iOS 17", details: nil))
        return
      }
      scan(mode: .structure(directory: dir), nextRoomLabel: args["nextRoomLabel"] as? String, result: result)
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

  private func scan(mode: RoomScanMode, nextRoomLabel: String?, result: @escaping FlutterResult) {
    guard RoomCaptureSession.isSupported else {
      result(nil)
      return
    }
    guard controller == nil, let root = Self.rootViewController() else {
      result(FlutterError(code: "busy", message: "a scan is already running", details: nil))
      return
    }
    let once = Once()
    let vc = RoomScanViewController(mode: mode, nextRoomLabel: nextRoomLabel) { [weak self] answer in
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

/// Une pièce dans un fichier, ou l'appartement dans un dossier, une pièce
/// par fichier, placées les unes par rapport aux autres.
enum RoomScanMode {
  case room(path: String)
  case structure(directory: String)
}

/// Le contrôleur du relevé : la vue de RoomPlan, ses boutons, et la
/// boussole qui tourne à côté le temps du relevé.
///
/// Pour l'appartement, « Pièce suivante » arrête la session sans mettre
/// ARKit en pause — le repère reste le même d'une pièce à l'autre — et la
/// relance une fois la pièce rendue ; au « Terminer », `StructureBuilder`
/// assemble les pièces et chacune part dans son fichier.
final class RoomScanViewController: UIViewController, RoomCaptureViewDelegate, RoomCaptureSessionDelegate, CLLocationManagerDelegate {
  private let mode: RoomScanMode
  private let nextRoomLabel: String?
  private let finish: ([String: Any]?) -> Void

  private var captureView: RoomCaptureView!
  private var doneButton: UIBarButtonItem!
  private var nextButton: UIBarButtonItem?
  private var rooms: [CapturedRoom] = []
  private var cancelled = false
  private var continuing = false

  private let location = CLLocationManager()
  private let north = NorthEstimator()

  init(mode: RoomScanMode, nextRoomLabel: String?, finish: @escaping ([String: Any]?) -> Void) {
    self.mode = mode
    self.nextRoomLabel = nextRoomLabel
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
    var items = [cancel, UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)]
    if case .structure = mode {
      let next = UIBarButtonItem(title: nextRoomLabel ?? "→", style: .plain, target: self, action: #selector(nextRoomTapped))
      nextButton = next
      items.append(next)
      items.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil))
    }
    items.append(doneButton)
    bar.items = items
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
    run()
  }

  private func run() {
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

  /// La pièce en cours se rend, et le relevé continue dans le même repère.
  @objc private func nextRoomTapped() {
    guard !continuing else { return }
    continuing = true
    nextButton?.isEnabled = false
    doneButton.isEnabled = false
    if #available(iOS 17.0, *) {
      captureView.captureSession.stop(pauseARSession: false)
    } else {
      captureView.captureSession.stop()
    }
  }

  @objc private func doneTapped() {
    doneButton.isEnabled = false
    nextButton?.isEnabled = false
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
    rooms.append(processedResult)
    if continuing {
      continuing = false
      nextButton?.isEnabled = true
      doneButton.isEnabled = true
      run()
      return
    }
    switch mode {
    case .room(let path):
      write(rooms: [processedResult], to: [path], error: error)
    case .structure(let directory):
      assemble(into: directory, error: error)
    }
  }

  /// Les pièces, placées les unes par rapport aux autres par
  /// `StructureBuilder` ; si l'assemblage échoue, les pièces telles quelles,
  /// qui partagent déjà le repère de la session.
  private func assemble(into directory: String, error: Error?) {
    let captured = rooms
    guard #available(iOS 17.0, *) else {
      writeStructure(rooms: captured, to: directory, error: error)
      return
    }
    Task { @MainActor in
      var assembled = captured
      do {
        let structure = try await StructureBuilder(options: [.beautifyObjects]).capturedStructure(from: captured)
        if !structure.rooms.isEmpty { assembled = structure.rooms }
      } catch {
        // Les pièces brutes suffisent : même repère, moins de finition.
      }
      self.writeStructure(rooms: assembled, to: directory, error: error)
    }
  }

  private func writeStructure(rooms: [CapturedRoom], to directory: String, error: Error?) {
    let url = URL(fileURLWithPath: directory)
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    let paths = rooms.indices.map { url.appendingPathComponent("\($0).json").path }
    write(rooms: rooms, to: paths, error: error)
  }

  private func write(rooms: [CapturedRoom], to paths: [String], error: Error?) {
    var answer: [String: Any] = [:]
    var written: [String] = []
    var errors: [String] = []
    let encoder = JSONEncoder()
    for (room, path) in zip(rooms, paths) {
      do {
        let data = try encoder.encode(room)
        try data.write(to: URL(fileURLWithPath: path), options: .atomic)
        written.append(path)
      } catch {
        errors.append(error.localizedDescription)
      }
    }
    if !written.isEmpty {
      answer["paths"] = written
      answer["path"] = written[0]
      if let offset = north.offsetDegrees { answer["northOffsetDeg"] = offset }
    }
    if let error = error { errors.append(error.localizedDescription) }
    if !errors.isEmpty { answer["error"] = errors.joined(separator: "; ") }
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
