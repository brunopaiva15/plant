import Flutter

#if canImport(GoogleHomeSDK)
  import GoogleHomeSDK
  import GoogleHomeTypes
#endif

/// Les appareils de Google Home, lus par les Home APIs pour la partie Dart
/// (`lib/data/services/google_home_climate_service.dart`).
///
/// Mêmes trois questions que pour Apple Maison, sur un autre canal : ce que
/// la maison laisse faire, la liste des appareils qui mesurent la
/// température ou l'humidité, la mesure de l'un d'eux. Aucune commande
/// envoyée, aucun autre appareil lu.
///
/// À la différence de HomeKit, les Home APIs ne sont pas dans le système :
/// leur SDK se télécharge depuis la console Google Home et s'ajoute au
/// projet. Sans lui, `canImport` est faux, le canal ne s'enregistre pas, et
/// Dart n'obtient rien — `AppConfig.googleHomeEnabled` garde alors la maison
/// hors de l'écran. Le reste de la marche à suivre — projet, client OAuth,
/// App Attest, groupe d'applications — est dans
/// `docs/05-technical-architecture.md`, section « Google Home ».
///
/// Les appels au SDK suivent la documentation des Home APIs ; faute de SDK
/// ici, ils n'ont pas été compilés, et se vérifient à la première
/// construction avec lui.
final class GoogleHomeChannel {
  static let name = "ch.vergasta.plant/google_home_climate"

  /// Gardé en vie tant que l'application tourne : la session Google Home
  /// s'ouvre une fois, et le canal ne retient pas son gestionnaire.
  private static var shared: GoogleHomeChannel?

  #if canImport(GoogleHomeSDK)
    /// La session ouverte, et le consentement refusé — un refus n'est pas
    /// une question jamais posée, et l'écran ne dit pas la même chose.
    fileprivate static var session: Home?
    fileprivate static var refused = false
    fileprivate static var configured = false
  #endif

  static func register(with messenger: FlutterBinaryMessenger) {
    #if canImport(GoogleHomeSDK)
      let instance = GoogleHomeChannel()
      shared = instance
      let channel = FlutterMethodChannel(name: name, binaryMessenger: messenger)
      channel.setMethodCallHandler { call, result in instance.handle(call, result: result) }
    #else
      // Sans le SDK, rien à enregistrer : le canal reste absent, et Dart lit
      // une maison vide au lieu d'attendre une réponse qui ne viendrait pas.
      _ = messenger
    #endif
  }
}

#if canImport(GoogleHomeSDK)

  extension GoogleHomeChannel {
    /// Le projet déclaré dans la console Google Home, lu dans `Info.plist` :
    /// rien de tout cela n'est un secret, mais rien de tout cela n'a sa
    /// place en dur dans le code.
    fileprivate struct Project {
      let clientID: String
      let teamID: String
      let appGroup: String?

      init?() {
        let info = Bundle.main.infoDictionary ?? [:]
        guard let clientID = info["GoogleHomeClientID"] as? String, !clientID.isEmpty,
          let teamID = info["GoogleHomeTeamID"] as? String, !teamID.isEmpty
        else { return nil }
        self.clientID = clientID
        self.teamID = teamID
        self.appGroup = info["GoogleHomeAppGroup"] as? String
      }
    }

    fileprivate func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
      switch call.method {
      case "access":
        Task { result(await self.accessName()) }
      case "sensors":
        Task { result(await self.sensors()) }
      case "read":
        guard let args = call.arguments as? [String: Any], let id = args["id"] as? String, !id.isEmpty else {
          result(FlutterError(code: "bad_args", message: "sensor id missing", details: nil))
          return
        }
        Task { result(await self.read(id: id)) }
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    // MARK: - Session

    /// La maison, une fois ouverte.
    ///
    /// `restoreSession` ne demande rien ; c'est `connect` qui ouvre la
    /// fenêtre de consentement, et seule la liste des appareils la
    /// déclenche — lire une mesure ne doit pas la poser sous les yeux de qui
    /// consulte une fiche de plante.
    private func home(prompting: Bool) async -> Home? {
      if let open = Self.session { return open }
      guard let project = Project() else { return nil }
      if !Self.configured {
        Home.configure {
          $0.clientID = project.clientID
          $0.teamID = project.teamID
          if let group = project.appGroup { $0.sharedAppGroup = group }
        }
        Self.configured = true
      }
      if let restored = await Home.restoreSession() {
        Self.session = restored
        return restored
      }
      guard prompting else { return nil }
      do {
        let opened = try await Home.connect()
        Self.session = opened
        return opened
      } catch {
        Self.refused = true
        return nil
      }
    }

    private func accessName() async -> String {
      guard Project() != nil else { return "unavailable" }
      if await home(prompting: false) != nil { return "authorized" }
      return Self.refused ? "denied" : "notDetermined"
    }

    // MARK: - Appareils

    /// Les appareils qui mesurent la température ou l'humidité de l'air,
    /// avec leur pièce et leur maison.
    private func sensors() async -> [[String: Any]] {
      guard let home = await home(prompting: true) else { return [] }
      var out: [[String: Any]] = []
      do {
        for structure in try await home.structures().list() {
          // La pièce vient de la pièce elle-même : c'est elle qui connaît
          // ses appareils, et le nom qu'elle porte chez la personne.
          var roomNames: [String: String] = [:]
          for room in try await structure.rooms().list() {
            for device in try await room.devices().list() {
              roomNames[device.id.id] = room.name
            }
          }
          for device in try await structure.devices().list() {
            let (temperature, humidity) = await measures(of: device)
            if temperature == nil && humidity == nil { continue }
            var item: [String: Any] = [
              "id": device.id.id,
              "name": device.name,
              "home": structure.name,
              "temperature": temperature != nil,
              "humidity": humidity != nil,
            ]
            if let room = roomNames[device.id.id], !room.isEmpty { item["room"] = room }
            out.append(item)
          }
        }
      } catch {
        return out
      }
      return out
    }

    private func device(id: String, in home: Home) async -> HomeDevice? {
      guard let structures = try? await home.structures().list() else { return nil }
      for structure in structures {
        guard let devices = try? await structure.devices().list() else { continue }
        if let found = devices.first(where: { $0.id.id == id }) { return found }
      }
      return nil
    }

    /// Ce qu'un appareil mesure de l'air d'une pièce, par les types qui le
    /// portent : le capteur de température, l'hygromètre, et le thermostat,
    /// qui mesure la pièce où il est posé. Un type de plus s'ajoute ici.
    private func measures(of device: HomeDevice) async -> (temperature: Double?, humidity: Double?) {
      var temperature: Double?
      var humidity: Double?
      if let sensor = await device.types.get(Matter.TemperatureSensorDeviceType.self) {
        temperature = number(sensor.matterTraits.temperatureMeasurementTrait?.attributes.measuredValue)
      }
      if let sensor = await device.types.get(Matter.HumiditySensorDeviceType.self) {
        humidity = number(sensor.matterTraits.relativeHumidityMeasurementTrait?.attributes.measuredValue)
      }
      if let thermostat = await device.types.get(Matter.ThermostatDeviceType.self) {
        temperature = temperature ?? number(thermostat.matterTraits.temperatureMeasurementTrait?.attributes.measuredValue)
        humidity = humidity ?? number(thermostat.matterTraits.relativeHumidityMeasurementTrait?.attributes.measuredValue)
      }
      return (temperature, humidity)
    }

    private func number(_ value: Any?) -> Double? {
      if let n = value as? NSNumber { return n.doubleValue }
      if let d = value as? Double { return d }
      if let i = value as? Int { return Double(i) }
      if let f = value as? Float { return Double(f) }
      return nil
    }

    // MARK: - Mesure

    private func read(id: String) async -> [String: Any] {
      var out: [String: Any] = ["at": Int(Date().timeIntervalSince1970 * 1000)]
      guard let home = await home(prompting: false) else {
        out["error"] = "unauthorized"
        return out
      }
      guard let device = await device(id: id, in: home) else {
        out["error"] = "unknown device"
        return out
      }
      let (temperature, humidity) = await measures(of: device)
      if let t = temperature { out["temperature"] = Self.celsius(t) }
      if let h = humidity { out["humidity"] = Self.percent(h) }
      if temperature == nil && humidity == nil { out["error"] = "no measurement" }
      return out
    }

    /// Matter compte en centièmes de degré ; selon sa version, le SDK rend
    /// déjà des degrés. Une pièce ne dépasse pas cent degrés : au-delà, la
    /// valeur est en centièmes, et se divise par cent.
    fileprivate static func celsius(_ raw: Double) -> Double { abs(raw) > 100 ? raw / 100 : raw }

    /// Même règle pour l'humidité relative, comptée en centièmes de pour cent.
    fileprivate static func percent(_ raw: Double) -> Double { raw > 100 ? raw / 100 : raw }
  }

#endif
