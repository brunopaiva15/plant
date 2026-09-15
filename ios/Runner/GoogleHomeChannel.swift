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
/// Les appels au SDK sont écrits contre l'interface publique du SDK 1.10.1
/// (`GoogleHomeSDK.xcframework`, `GoogleHomeTypes.xcframework`), et lisent de
/// vrais capteurs sur un iPhone. Le SDK demande iOS 17, d'où la disponibilité
/// posée sur toute l'extension.
final class GoogleHomeChannel {
  static let name = "ch.vergasta.plant/google_home_climate"

  /// Gardé en vie tant que l'application tourne : la session Google Home
  /// s'ouvre une fois, et le canal ne retient pas son gestionnaire.
  private static var shared: GoogleHomeChannel?

  #if canImport(GoogleHomeSDK)
    /// La session ouverte, le consentement refusé — un refus n'est pas une
    /// question jamais posée, et l'écran ne dit pas la même chose —, et la
    /// configuration, qui ne se pose qu'une fois.
    @available(iOS 17.0, *)
    fileprivate static var session: Home? {
      get { _session as? Home }
      set { _session = newValue }
    }
    private static var _session: AnyObject?
    fileprivate static var refused = false
    fileprivate static var configured = false
  #endif

  static func register(with messenger: FlutterBinaryMessenger) {
    #if canImport(GoogleHomeSDK)
      guard #available(iOS 17.0, *) else {
        // Le SDK est là mais le système est trop vieux : même réponse que
        // s'il n'y était pas.
        return
      }
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

  @available(iOS 17.0, *)
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
        Task { @MainActor in result(await self.accessName()) }
      case "sensors":
        Task { @MainActor in result(await self.sensors()) }
      case "disconnect":
        Task { @MainActor in
          await self.disconnect()
          result(nil)
        }
      case "read":
        guard let args = call.arguments as? [String: Any], let id = args["id"] as? String, !id.isEmpty else {
          result(FlutterError(code: "bad_args", message: "sensor id missing", details: nil))
          return
        }
        Task { @MainActor in result(await self.read(id: id)) }
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
    @MainActor
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

    /// Ferme la session, et rien de plus.
    ///
    /// Le SDK est explicite : `disconnect` ne révoque pas ce que le compte a
    /// accordé. Cela se retire depuis le compte Google, et l'écran des
    /// capteurs y mène. Le refus mémorisé part avec la session : la question
    /// pourra se reposer.
    @MainActor
    private func disconnect() async {
      await Self.session?.disconnect()
      Self.session = nil
      Self.refused = false
    }

    @MainActor
    private func accessName() async -> String {
      guard Project() != nil else { return "unavailable" }
      if await home(prompting: false) != nil { return "authorized" }
      return Self.refused ? "denied" : "notDetermined"
    }

    // MARK: - Appareils

    /// Les appareils qui mesurent la température ou l'humidité de l'air,
    /// avec leur pièce et leur maison.
    ///
    /// Les appareils, les pièces et les maisons se demandent à plat, puis se
    /// recollent par identifiant : un appareil porte la pièce où il est
    /// rangé, et la pièce porte son nom.
    @MainActor
    private func sensors() async -> [[String: Any]] {
      guard let home = await home(prompting: true) else { return [] }
      do {
        let devices = try await home.devices().list()
        let rooms = try await home.rooms().list()
        let structures = try await home.structures().list()
        // `uniquingKeysWith` plutôt que `uniqueKeysWithValues` : deux
        // identifiants identiques feraient tomber l'application, et un nom
        // de pièce ne vaut pas ça.
        let roomNames = Dictionary(rooms.map { ($0.id, $0.name) }, uniquingKeysWith: { first, _ in first })
        let structureNames = Dictionary(structures.map { ($0.id, $0.name) }, uniquingKeysWith: { first, _ in first })
        var out: [[String: Any]] = []
        for device in devices {
          let (temperature, humidity) = await measures(of: device)
          if temperature == nil && humidity == nil { continue }
          var item: [String: Any] = [
            "id": device.id,
            "name": device.name,
            "temperature": temperature != nil,
            "humidity": humidity != nil,
          ]
          if let id = device.roomID, let room = roomNames[id], !room.isEmpty { item["room"] = room }
          if let id = device.structureID, let structure = structureNames[id], !structure.isEmpty { item["home"] = structure }
          out.append(item)
        }
        return out
      } catch {
        return []
      }
    }

    @MainActor
    private func device(id: String, in home: Home) async -> HomeDevice? {
      guard let devices = try? await home.devices().list() else { return nil }
      return devices.first { $0.id == id }
    }

    /// Ce qu'un appareil mesure de l'air d'une pièce, en centièmes d'unité
    /// comme Matter les compte.
    ///
    /// Trois types portent ces deux grandeurs : le capteur de température et
    /// l'hygromètre, chacun avec son trait de mesure, et le thermostat, dont
    /// la température de la pièce est `localTemperature` — il n'a pas de
    /// trait de mesure à lui. Un même appareil peut porter plusieurs de ces
    /// types ; on prend la première valeur trouvée.
    @MainActor
    private func measures(of device: HomeDevice) async -> (temperature: Int16?, humidity: UInt16?) {
      var temperature: Int16?
      var humidity: UInt16?
      if let sensor = await device.types.get(TemperatureSensorDeviceType.self) {
        temperature = sensor.matterTraits.temperatureMeasurementTrait?.attributes.measuredValue
      }
      if let sensor = await device.types.get(HumiditySensorDeviceType.self) {
        humidity = sensor.matterTraits.relativeHumidityMeasurementTrait?.attributes.measuredValue
      }
      if temperature == nil, let thermostat = await device.types.get(ThermostatDeviceType.self) {
        temperature = thermostat.matterTraits.thermostatTrait?.attributes.localTemperature
      }
      return (temperature, humidity)
    }

    // MARK: - Mesure

    @MainActor
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
      var (temperature, humidity) = await measures(of: device)
      // Rien en cache : on redemande à l'appareil, une fois, et on relit.
      // Un capteur sur pile peut n'avoir rien publié depuis le démarrage.
      if temperature == nil && humidity == nil {
        await forceRead(device)
        if let again = await self.device(id: id, in: home) {
          (temperature, humidity) = await measures(of: again)
        }
      }
      // Matter compte en centièmes de degré et de pour cent.
      if let t = temperature { out["temperature"] = Double(t) / 100 }
      if let h = humidity { out["humidity"] = Double(h) / 100 }
      if temperature == nil && humidity == nil { out["error"] = "no measurement" }
      return out
    }

    /// Redemande ses valeurs à l'appareil. Un échec n'est pas une panne : la
    /// lecture suivante rendra ce qu'elle a, et l'écran dira le tiret.
    @MainActor
    private func forceRead(_ device: HomeDevice) async {
      if let sensor = await device.types.get(TemperatureSensorDeviceType.self) {
        try? await sensor.matterTraits.temperatureMeasurementTrait?.forceRead()
      }
      if let sensor = await device.types.get(HumiditySensorDeviceType.self) {
        try? await sensor.matterTraits.relativeHumidityMeasurementTrait?.forceRead()
      }
      if let thermostat = await device.types.get(ThermostatDeviceType.self) {
        try? await thermostat.matterTraits.thermostatTrait?.forceRead()
      }
    }
  }

#endif
