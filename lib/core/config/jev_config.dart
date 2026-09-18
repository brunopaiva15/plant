/// Jev / OpenRouter est une piste expérimentale utilisée uniquement par les
/// outils de debug pour l'instant.
///
/// La clé est fournie au build :
/// `--dart-define=OPENROUTER_API_KEY=…`
abstract final class JevConfig {
  static const String apiKey = String.fromEnvironment('OPENROUTER_API_KEY');
  static const String model = '~typesafe/jev-latest';
  static const String endpoint = 'https://openrouter.ai/api/alpha/decisions';

  static bool get isConfigured => apiKey.trim().isNotEmpty;
}
