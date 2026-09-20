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
///   --dart-define=INFOMANIAK_AI_MODEL=Qwen/Qwen3.5-397B-A17B-FP8
/// ```
abstract final class DiagnosisConfig {
  /// Jeton d'API Infomaniak (manager.infomaniak.com → jetons d'API, portée AI).
  static const String apiKey = String.fromEnvironment('INFOMANIAK_AI_API_KEY');

  /// Identifiant du produit AI Services, visible dans l'URL du manager.
  static const String productId = String.fromEnvironment('INFOMANIAK_AI_PRODUCT_ID');

  /// Modèle, changeable au build sans toucher au code. Qwen 3.5 397B voit les
  /// images, parle bien français et lit une photo de plante malade avec plus
  /// de justesse que Mistral Small 4, pour quatre fois son prix : de l'ordre
  /// de quelques millièmes de franc par diagnostic.
  static const String model = String.fromEnvironment('INFOMANIAK_AI_MODEL', defaultValue: 'Qwen/Qwen3.5-397B-A17B-FP8');

  static bool get isConfigured => apiKey.trim().isNotEmpty && productId.trim().isNotEmpty;
}
