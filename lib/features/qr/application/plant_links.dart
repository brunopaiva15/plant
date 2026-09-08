import '../../../core/config/app_config.dart';

/// Ce vers quoi pointe un lien Flora.
enum FloraLinkKind { plant, item, join }

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
///
/// `flora://join/<code>` s'y ajoute pour les invitations : c'est le bouton
/// « Ouvrir dans Auxine » de la page d'atterrissage qui l'appelle.
abstract final class PlantLinks {
  static String encode(String plantId) => '${AppConfig.linkScheme}://plant/$plantId';

  static String encodeItem(String itemId) => '${AppConfig.linkScheme}://item/$itemId';

  static String encodeJoin(String code) => '${AppConfig.linkScheme}://join/$code';

  /// Retourne l'id de plante si [raw] est un lien de plante, sinon `null`.
  static String? decode(String raw) {
    final link = decodeLink(raw);
    return link?.kind == FloraLinkKind.plant ? link!.id : null;
  }

  /// Décode n'importe quel lien Flora : plante, article d'inventaire, ou
  /// invitation à rejoindre un jardin.
  static FloraLink? decodeLink(String raw) {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null) return null;
    // Le lien d'invitation qu'on envoie est une adresse https — pour rester
    // cliquable dans un message, et lisible par n'importe quel appareil photo.
    // Le scanner de l'application sait la lire aussi : `…/join/<code>`.
    if (uri.scheme == 'https' || uri.scheme == 'http') {
      final path = uri.pathSegments;
      final joined = path.length >= 2 && path[path.length - 2] == 'join' ? path.last : null;
      return joined == null || joined.isEmpty ? null : FloraLink(FloraLinkKind.join, joined);
    }
    if (uri.scheme != AppConfig.linkScheme) return null;
    final kind = switch (uri.host) {
      'plant' => FloraLinkKind.plant,
      'item' => FloraLinkKind.item,
      'join' => FloraLinkKind.join,
      _ => null,
    };
    if (kind == null || uri.pathSegments.length != 1) return null;
    final id = uri.pathSegments.single;
    return id.isEmpty ? null : FloraLink(kind, id);
  }
}
