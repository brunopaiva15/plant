import '../../../core/config/app_config.dart';

/// Ce vers quoi pointe un QR code Flora.
enum FloraLinkKind { plant, item }

/// Cible décodée d'un QR code.
class FloraLink {
  const FloraLink(this.kind, this.id);

  final FloraLinkKind kind;
  final String id;

  @override
  bool operator ==(Object other) => other is FloraLink && other.kind == kind && other.id == id;

  @override
  int get hashCode => Object.hash(kind, id);
}

/// Liens encodés dans les QR codes : `flora://plant/<id>` et
/// `flora://item/<id>`. Le même format servira aux tags NFC (Phase 4).
abstract final class PlantLinks {
  static String encode(String plantId) => '${AppConfig.linkScheme}://plant/$plantId';

  static String encodeItem(String itemId) => '${AppConfig.linkScheme}://item/$itemId';

  /// Retourne l'id de plante si [raw] est un lien de plante, sinon `null`.
  static String? decode(String raw) {
    final link = decodeLink(raw);
    return link?.kind == FloraLinkKind.plant ? link!.id : null;
  }

  /// Décode n'importe quel lien Flora (plante ou article d'inventaire).
  static FloraLink? decodeLink(String raw) {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null || uri.scheme != AppConfig.linkScheme) return null;
    final kind = switch (uri.host) {
      'plant' => FloraLinkKind.plant,
      'item' => FloraLinkKind.item,
      _ => null,
    };
    if (kind == null || uri.pathSegments.length != 1) return null;
    final id = uri.pathSegments.single;
    return id.isEmpty ? null : FloraLink(kind, id);
  }
}
