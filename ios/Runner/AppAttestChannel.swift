import CryptoKit
import DeviceCheck
import Flutter
import UIKit

/// App Attest, côté appareil.
///
/// La Secure Enclave fabrique une paire de clés dont la partie privée ne sort
/// jamais — ni vers Dart, ni vers le relais, ni vers Apple. Ce canal n'en
/// manipule donc que trois choses : l'identifiant de la clé, l'attestation
/// qu'Apple signe une fois, et les assertions qu'elle produit ensuite.
///
/// Ce que le relais en fait est dans `docs/19-relais-des-cles.md` ; ce qu'il
/// en vérifie, dans `supabase/functions/relay/attest.ts`.
///
/// Rend `false` à `isSupported` là où le mécanisme n'existe pas — le
/// simulateur, où il n'y a pas d'enclave —, et Dart passe alors par le
/// laissez-passer de développement. Sur un appareil, c'est la seule entrée.
final class AppAttestChannel {
  static let name = "ch.vergasta.plant/app_attest"

  static func register(with messenger: FlutterBinaryMessenger) {
    let instance = AppAttestChannel()
    let channel = FlutterMethodChannel(name: name, binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in instance.handle(call, result: result) }
  }

  private let service = DCAppAttestService.shared

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isSupported":
      result(service.isSupported)

    case "generateKey":
      guard service.isSupported else {
        result(FlutterError(code: "unsupported", message: "App Attest n'existe pas ici", details: nil))
        return
      }
      service.generateKey { keyId, error in
        DispatchQueue.main.async {
          guard let keyId else {
            result(AppAttestChannel.failure(error, "la clé n'a pas pu être créée"))
            return
          }
          result(keyId)
        }
      }

    case "attest", "assert":
      guard let arguments = call.arguments as? [String: Any],
            let keyId = arguments["keyId"] as? String,
            let challenge = arguments["challenge"] as? String
      else {
        result(FlutterError(code: "bad_args", message: "keyId et challenge attendus", details: nil))
        return
      }
      // Le relais signe sur les octets UTF-8 du défi, et lui seul décide de
      // ce qu'il y met : c'est le « clientData » qu'Apple laisse libre, à la
      // condition que les deux bords en fassent le même condensé.
      let hash = Data(SHA256.hash(data: Data(challenge.utf8)))
      let completion: (Data?, Error?) -> Void = { payload, error in
        DispatchQueue.main.async {
          guard let payload else {
            result(AppAttestChannel.failure(error, "l'appareil n'a pas pu signer"))
            return
          }
          result(FlutterStandardTypedData(bytes: payload))
        }
      }
      if call.method == "attest" {
        service.attestKey(keyId, clientDataHash: hash, completionHandler: completion)
      } else {
        service.generateAssertion(keyId, clientDataHash: hash, completionHandler: completion)
      }

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// Les causes que Dart a de quoi distinguer, parce qu'elles n'appellent pas
  /// la même suite : une clé qu'Apple ne reconnaît plus se refait, un service
  /// indisponible se retente plus tard, et le reste attend la prochaine fois.
  private static func failure(_ error: Error?, _ what: String) -> FlutterError {
    let code: String
    switch (error as? NSError).flatMap({ $0.domain == DCError.errorDomain ? DCError.Code(rawValue: $0.code) : nil }) {
    case .invalidKey: code = "invalid_key"
    case .serverUnavailable: code = "server_unavailable"
    case .featureUnsupported: code = "unsupported"
    case .invalidInput: code = "bad_args"
    default: code = "failed"
    }
    return FlutterError(code: code, message: what, details: error?.localizedDescription)
  }
}
