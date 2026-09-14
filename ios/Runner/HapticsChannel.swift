import CoreHaptics
import Flutter
import UIKit

/// Les retours haptiques qui racontent quelque chose, pour la partie Dart
/// (`lib/core/haptics.dart`) : la goutte de l'arrosage, le roulement d'une
/// action enregistrée, le coup sourd d'un geste sensible.
///
/// `UIFeedbackGenerator` ne sait donner qu'un coup ; Core Haptics enchaîne
/// des impulsions d'intensité et de netteté réglées, et c'est ce qui fait
/// qu'une goutte ne ressemble pas à une validation. Le moteur se lance à la
/// première demande et s'éteint tout seul quand il ne sert plus.
///
/// Rend `false` quand rien ne peut être joué — pas de moteur (iPad,
/// simulateur), *Vibrations* coupé, moteur en panne — et Dart retombe sur le
/// retour du système. Un motif inconnu est une erreur.
final class HapticsChannel {
  static let name = "ch.vergasta.plant/haptics"

  private static var shared: HapticsChannel?

  static func register(with messenger: FlutterBinaryMessenger) {
    let instance = HapticsChannel()
    shared = instance
    let channel = FlutterMethodChannel(name: name, binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in instance.handle(call, result: result) }
  }

  private var engine: CHHapticEngine?

  /// Les motifs compilés une fois ; les lecteurs, eux, ne survivent pas à
  /// une remise à zéro du moteur, on les refait à chaque lecture.
  private var patterns: [String: CHHapticPattern] = [:]

  private lazy var supported = CHHapticEngine.capabilitiesForHardware().supportsHaptics

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "play":
      guard let name = call.arguments as? String, let events = HapticsChannel.events[name] else {
        result(FlutterError(code: "bad_args", message: "unknown pattern", details: call.arguments))
        return
      }
      result(play(name, events))
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - Les motifs

  /// Une impulsion : `at` en secondes, intensité et netteté de 0 à 1 ;
  /// `during` la prolonge, et `fade` la laisse s'éteindre sur sa durée.
  private struct Pulse {
    let at: Double
    let intensity: Float
    let sharpness: Float
    var during: Double = 0
    var fade: Bool = false
  }

  private static let events: [String: [Pulse]] = [
    // Deux gouttes légères, puis celle qui touche la terre et s'y étale.
    "drop": [
      Pulse(at: 0.00, intensity: 0.35, sharpness: 0.25),
      Pulse(at: 0.08, intensity: 0.45, sharpness: 0.30),
      Pulse(at: 0.20, intensity: 1.00, sharpness: 0.55),
      Pulse(at: 0.21, intensity: 0.35, sharpness: 0.15, during: 0.18, fade: true),
    ],
    // Un roulement qui monte et se pose : la chose est faite.
    "success": [
      Pulse(at: 0.00, intensity: 0.70, sharpness: 0.30, during: 0.22, fade: false),
      Pulse(at: 0.22, intensity: 0.85, sharpness: 0.50),
    ],
    // Un coup sourd et son écho : on a touché à quelque chose.
    "warning": [
      Pulse(at: 0.00, intensity: 1.00, sharpness: 0.35),
      Pulse(at: 0.12, intensity: 0.45, sharpness: 0.25),
    ],
  ]

  private func pattern(_ name: String, _ pulses: [Pulse]) throws -> CHHapticPattern {
    if let cached = patterns[name] { return cached }
    var events: [CHHapticEvent] = []
    var curves: [CHHapticParameterCurve] = []
    for p in pulses {
      let parameters = [
        CHHapticEventParameter(parameterID: .hapticIntensity, value: p.intensity),
        CHHapticEventParameter(parameterID: .hapticSharpness, value: p.sharpness),
      ]
      if p.during > 0 {
        events.append(CHHapticEvent(eventType: .hapticContinuous, parameters: parameters, relativeTime: p.at, duration: p.during))
        // Le roulement monte ; l'eau qui s'étale s'éteint.
        let from: Float = p.fade ? 1 : 0.2
        let to: Float = p.fade ? 0 : 1
        curves.append(CHHapticParameterCurve(
          parameterID: .hapticIntensityControl,
          controlPoints: [
            CHHapticParameterCurve.ControlPoint(relativeTime: p.at, value: from),
            CHHapticParameterCurve.ControlPoint(relativeTime: p.at + p.during, value: to),
          ],
          relativeTime: 0))
      } else {
        events.append(CHHapticEvent(eventType: .hapticTransient, parameters: parameters, relativeTime: p.at))
      }
    }
    let built = try CHHapticPattern(events: events, parameterCurves: curves)
    patterns[name] = built
    return built
  }

  // MARK: - Le moteur

  private func play(_ name: String, _ pulses: [Pulse]) -> Bool {
    guard supported else { return false }
    do {
      let engine = try startedEngine()
      let player = try engine.makePlayer(with: pattern(name, pulses))
      try player.start(atTime: CHHapticTimeImmediate)
      return true
    } catch {
      // Le moteur a lâché : on le laisse tomber, le prochain appel en
      // refera un ; en attendant Dart joue le retour du système.
      engine = nil
      return false
    }
  }

  private func startedEngine() throws -> CHHapticEngine {
    if let engine {
      try engine.start()
      return engine
    }
    let created = try CHHapticEngine()
    created.playsHapticsOnly = true
    // Il s'arrête de lui-même quand plus rien ne joue, et repart au prochain
    // `start()` : pas de moteur qui tourne pour rien entre deux arrosages.
    created.isAutoShutdownEnabled = true
    created.resetHandler = { [weak self] in
      // Le système l'a remis à zéro (appel, autre application) : les motifs
      // compilés restent bons, seul le moteur est à relancer.
      guard let self, let engine = self.engine else { return }
      try? engine.start()
    }
    created.stoppedHandler = { [weak self] reason in
      // Un arrêt que l'on n'a pas demandé — et ce n'est pas la mise en
      // veille automatique — signifie que le moteur est à refaire.
      if reason != .idleTimeout && reason != .applicationSuspended { self?.engine = nil }
    }
    try created.start()
    engine = created
    return created
  }
}
