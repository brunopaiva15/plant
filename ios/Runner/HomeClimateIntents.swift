import AppIntents
import Foundation

/// « Transmettre le climat à Auxine », pour l'app Raccourcis.
///
/// Les capteurs des HomePod n'existent pas pour HomeKit vu d'une app tierce :
/// Apple les réserve à Maison. Raccourcis, lui, les lit (action Maison
/// « Obtenir l'état »), et peut appeler cette action avec la valeur. Elle
/// l'écrit dans les préférences de l'application, là où la partie Dart la
/// relit (`home_shortcut_reading`, sous le préfixe `flutter.` de
/// shared_preferences). Rien ne quitte l'appareil.
@available(iOS 16.0, *)
struct ReportHomeClimateIntent: AppIntent {
  static var title: LocalizedStringResource = "Transmettre le climat à Auxine"
  static var description = IntentDescription("Température et humidité d'une pièce, transmises à Auxine (celles d'un HomePod, par exemple).")
  /// Sans ouvrir l'application : l'action tourne en arrière-plan.
  static var openAppWhenRun = false

  @Parameter(title: "Température (°C)")
  var temperature: Double?

  @Parameter(title: "Humidité (%)")
  var humidity: Double?

  @Parameter(title: "Pièce")
  var room: String?

  static var parameterSummary: some ParameterSummary {
    Summary("Transmettre \(\.$temperature) et \(\.$humidity) à Auxine") {
      \.$room
    }
  }

  func perform() async throws -> some IntentResult {
    let millis = Int(Date().timeIntervalSince1970 * 1000)
    let t = temperature.map { String($0) } ?? ""
    let h = humidity.map { String($0) } ?? ""
    let r = (room ?? "").replacingOccurrences(of: "|", with: " ")
    UserDefaults.standard.set("\(t)|\(h)|\(millis)|\(r)", forKey: "flutter.home_shortcut_reading")
    return .result()
  }
}
