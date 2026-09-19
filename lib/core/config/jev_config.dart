/// Jev / OpenRouter, la couche de décision consultée quand Iris reste
/// ambigu. Sans clé, Auxine s'en passe : l'identification reste entière.
///
/// La clé est fournie au build :
/// `--dart-define=OPENROUTER_API_KEY=…`
abstract final class JevConfig {
  static const String apiKey = String.fromEnvironment('OPENROUTER_API_KEY');
  static const String model = '~typesafe/jev-latest';
  static const String endpoint = 'https://openrouter.ai/api/alpha/decisions';

  static bool get isConfigured => apiKey.trim().isNotEmpty;
}
