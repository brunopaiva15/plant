/// Diagnostic « Ma plante a un problème » : AI Services d'Infomaniak.
///
/// Comme pour Pl@ntNet, la clé est celle de l'éditeur, fournie au build par
/// `--dart-define` ; l'utilisateur n'a rien à saisir. Sans clé, le
/// diagnostic est simplement absent de l'application.
///
/// ```bash
/// flutter build ipa \
///   --dart-define=INFOMANIAK_AI_API_KEY=… \
///   --dart-define=INFOMANIAK_AI_PRODUCT_ID=… \
///   --dart-define=INFOMANIAK_AI_MODEL=mistralai/Mistral-Small-4-119B-2603
/// ```
abstract final class DiagnosisConfig {
  /// Jeton d'API Infomaniak (manager.infomaniak.com → jetons d'API, portée AI).
  static const String apiKey = String.fromEnvironment('INFOMANIAK_AI_API_KEY');

  /// Identifiant du produit AI Services, visible dans l'URL du manager.
  static const String productId = String.fromEnvironment('INFOMANIAK_AI_PRODUCT_ID');

  /// Modèle, changeable au build sans toucher au code. Mistral Small 4 voit
  /// les images, est stable, parle bien français et coûte le moins cher des
  /// modèles de sa taille : environ un millième de franc par diagnostic.
  static const String model = String.fromEnvironment('INFOMANIAK_AI_MODEL', defaultValue: 'mistralai/Mistral-Small-4-119B-2603');

  static bool get isConfigured => apiKey.trim().isNotEmpty && productId.trim().isNotEmpty;
}
