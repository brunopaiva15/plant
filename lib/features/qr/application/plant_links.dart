import '../../../core/config/app_config.dart';

/// Liens encodés dans les QR codes : `flora://plant/<id>`.
/// Le même format servira aux tags NFC (Phase 4).
abstract final class PlantLinks {
  static String encode(String plantId) => '${AppConfig.linkScheme}://plant/$plantId';

  /// Retourne l'id de plante si [raw] est un lien Flora valide, sinon `null`.
  static String? decode(String raw) {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null || uri.scheme != AppConfig.linkScheme || uri.host != 'plant') return null;
    if (uri.pathSegments.length != 1) return null;
    final id = uri.pathSegments.single;
    return id.isEmpty ? null : id;
  }
}
