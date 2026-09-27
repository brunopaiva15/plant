/// Une nouveauté : un emoji, et un titre et une phrase que la couche i18n
/// résout (`whatsNew…Title`, `whatsNew…Body`).
enum WhatsNewItem {
  pot('🪴'),
  camera('📷'),
  species('🌿'),
  diagnosis('⏱️');

  const WhatsNewItem(this.emoji);

  final String emoji;
}

/// Les nouveautés montrées une fois, à l'ouverture qui suit une installation
/// ou une mise à jour.
///
/// Elles se comptent en éditions, pas en numéros de version : une version
/// peut sortir sans rien de neuf à dire, et un build de plus sous le même
/// numéro peut en apporter. Écrire de nouvelles nouveautés, c'est remplacer
/// [items] et augmenter [edition] ; chaque appareil les verra une fois.
abstract final class WhatsNew {
  /// L'édition en cours. À augmenter avec [items].
  static const int edition = 1;

  /// Ce que l'édition en cours présente, du plus visible au plus discret.
  static const List<WhatsNewItem> items = WhatsNewItem.values;

  /// À montrer : l'accueil est passé, et cette édition n'a pas encore été vue.
  static bool shouldShow({required int? seen, required bool onboardingDone}) =>
      onboardingDone && items.isNotEmpty && (seen ?? 0) < edition;
}
