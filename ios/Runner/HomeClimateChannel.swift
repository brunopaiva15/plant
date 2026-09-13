import Flutter
import HomeKit

/// Les capteurs d'Apple Maison, lus par HomeKit pour la partie Dart
/// (`lib/data/services/home_kit_climate_service.dart`).
///
/// Trois questions, et rien d'autre : ce que HomeKit laisse faire, la liste
/// des accessoires qui mesurent la température ou l'humidité, et la mesure
/// de l'un d'eux. Aucune écriture, aucune scène, aucun autre accessoire :
/// l'application lit deux nombres, sur l'appareil, et c'est tout.
final class HomeClimateChannel: NSObject, HMHomeManagerDelegate {
  static let name = "ch.vergasta.plant/home_climate"

  /// Gardé en vie tant que l'application tourne : le gestionnaire HomeKit
  /// charge les maisons une fois, et les délégués ne sont pas retenus.
  private static var shared: HomeClimateChannel?

  static func register(with messenger: FlutterBinaryMessenger) {
    let instance = HomeClimateChannel()
    shared = instance
    let channel = FlutterMethodChannel(name: name, binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in instance.handle(call, result: result) }
  }

  private var manager: HMHomeManager?
  private var homesLoaded = false
  private var waiters: [() -> Void] = []

  /// Délai au-delà duquel on répond avec ce qu'on a : HomeKit peut mettre
  /// quelques secondes à livrer les maisons, mais pas l'éternité.
  private let loadTimeout: TimeInterval = 10
  private let readTimeout: TimeInterval = 10

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "access":
      withHomes { result(self.accessName()) }
    case "sensors":
      withHomes { result(self.sensors()) }
    case "read":
      guard let args = call.arguments as? [String: Any], let id = args["id"] as? String, !id.isEmpty else {
        result(FlutterError(code: "bad_args", message: "sensor id missing", details: nil))
        return
      }
      withHomes { self.read(id: id, result: result) }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - Maisons

  /// Exécute `body` une fois les maisons chargées. Le premier appel crée le
  /// gestionnaire, ce qui ouvre la demande d'accès du système.
  private func withHomes(_ body: @escaping () -> Void) {
    if manager == nil {
      let m = HMHomeManager()
      m.delegate = self
      manager = m
      DispatchQueue.main.asyncAfter(deadline: .now() + loadTimeout) { [weak self] in
        self?.flush()
      }
    }
    if homesLoaded {
      body()
    } else {
      waiters.append(body)
    }
  }

  func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
    flush()
  }

  @available(iOS 13.0, *)
  func homeManager(_ manager: HMHomeManager, didUpdate status: HMHomeManagerAuthorizationStatus) {
    // Un refus ne livre jamais de maison : sans cela, un utilisateur qui
    // refuse attendrait le délai entier.
    if !status.contains(.authorized) && status.contains(.determined) { flush() }
  }

  private func flush() {
    homesLoaded = true
    let pending = waiters
    waiters = []
    for w in pending { w() }
  }

  private func accessName() -> String {
    guard let manager = manager else { return "unavailable" }
    let status = manager.authorizationStatus
    if status.contains(.authorized) { return "authorized" }
    if status.contains(.restricted) { return "denied" }
    if status.contains(.determined) { return "denied" }
    return "notDetermined"
  }

  // MARK: - Capteurs

  private func sensors() -> [[String: Any]] {
    guard let manager = manager else { return [] }
    var out: [[String: Any]] = []
    for home in manager.homes {
      for accessory in home.accessories {
        let (temperature, humidity) = characteristics(of: accessory)
        if temperature.isEmpty && humidity.isEmpty { continue }
        var item: [String: Any] = [
          "id": accessory.uniqueIdentifier.uuidString,
          "name": accessory.name,
          "home": home.name,
          "temperature": !temperature.isEmpty,
          "humidity": !humidity.isEmpty,
        ]
        if let room = accessory.room?.name, !room.isEmpty { item["room"] = room }
        out.append(item)
      }
    }
    return out
  }

  private func accessory(id: String) -> HMAccessory? {
    guard let manager = manager else { return nil }
    for home in manager.homes {
      if let a = home.accessories.first(where: { $0.uniqueIdentifier.uuidString == id }) { return a }
    }
    return nil
  }

  /// Les caractéristiques qui nous intéressent, toutes : un accessoire peut
  /// porter la même grandeur sur plusieurs services (un thermostat et son
  /// capteur de pièce), et le premier n'est pas toujours celui qui répond.
  private func characteristics(of accessory: HMAccessory) -> (temperature: [HMCharacteristic], humidity: [HMCharacteristic]) {
    var temperature: [HMCharacteristic] = []
    var humidity: [HMCharacteristic] = []
    for service in accessory.services {
      for c in service.characteristics {
        if c.characteristicType == HMCharacteristicTypeCurrentTemperature { temperature.append(c) }
        if c.characteristicType == HMCharacteristicTypeCurrentRelativeHumidity { humidity.append(c) }
      }
    }
    return (temperature, humidity)
  }

  /// La première valeur connue parmi plusieurs caractéristiques.
  private func firstValue(_ list: [HMCharacteristic]) -> Double? {
    for c in list {
      if let n = c.value as? NSNumber { return n.doubleValue }
    }
    return nil
  }

  // MARK: - Mesure

  private func read(id: String, result: @escaping FlutterResult) {
    guard let accessory = accessory(id: id) else {
      result(nil)
      return
    }
    let (temperature, humidity) = characteristics(of: accessory)
    let group = DispatchGroup()
    let once = Once()
    for c in temperature + humidity {
      group.enter()
      // Une lecture qui échoue garde la dernière valeur connue : un capteur
      // qui a répondu il y a dix minutes vaut mieux qu'un tiret.
      c.readValue { _ in group.leave() }
    }
    let answer = {
      once.run {
        var out: [String: Any] = ["at": Int(Date().timeIntervalSince1970 * 1000)]
        if let t = self.firstValue(temperature) { out["temperature"] = t }
        if let h = self.firstValue(humidity) { out["humidity"] = h }
        result(out.count > 1 ? out : nil)
      }
    }
    group.notify(queue: .main) { answer() }
    DispatchQueue.main.asyncAfter(deadline: .now() + readTimeout) { answer() }
  }
}

/// Un bloc qui ne s'exécute qu'une fois : une réponse Flutter ne se donne
/// pas deux fois, que la lecture aboutisse ou que le délai tombe avant.
private final class Once {
  private var done = false
  func run(_ body: () -> Void) {
    if done { return }
    done = true
    body()
  }
}
