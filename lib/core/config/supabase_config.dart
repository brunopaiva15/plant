/// Backend optionnel. Fourni au build :
/// `flutter run --dart-define=SUPABASE_URL=… --dart-define=SUPABASE_ANON_KEY=…`
/// Sans ces valeurs, l'app reste entièrement locale.
abstract final class SupabaseConfig {
  static const String url = String.fromEnvironment('SUPABASE_URL');
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const String photoBucket = 'plant-photos';

  /// Redirection OAuth (Google) : `flora://login-callback`.
  static const String authRedirect = 'flora://login-callback';

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;

  /// Base des liens de partage public, servie par la fonction Edge `share`.
  /// Surchargeable pour un domaine personnalisé :
  /// `--dart-define=SHARE_BASE_URL=https://flora.exemple/s`.
  static const String _shareBaseOverride = String.fromEnvironment('SHARE_BASE_URL');

  static String get shareBaseUrl => _shareBaseOverride.isNotEmpty ? _shareBaseOverride : '$url/functions/v1/share';
}
