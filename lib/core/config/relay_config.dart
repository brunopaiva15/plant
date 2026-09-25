import 'supabase_config.dart';

/// Le relais qui tient les clés d'API de l'éditeur.
///
/// Pl@ntNet, les AI Services d'Infomaniak et OpenRouter demandent chacun une
/// clé, et ces clés appartiennent à l'éditeur : personne n'a de compte à
/// créer chez un tiers pour identifier une plante. Elles ont longtemps été
/// fournies au build par `--dart-define`, ce qui ne les cachait pas — une
/// valeur passée ainsi devient une constante du binaire, que `strings` sort
/// d'un paquet démonté en quelques secondes.
///
/// Elles vivent maintenant dans la fonction Edge `relay`
/// (`supabase/functions/relay/`), et l'application ne parle qu'à elle. Ce qui
/// reste ici n'est plus un secret, c'est une adresse.
///
/// Qui a le droit d'appeler le relais est une autre question, et elle se
/// règle par App Attest sur iPhone, par Play Integrity sur Android : voir
/// `core/network/relay_client.dart`.
abstract final class RelayConfig {
  /// Le relais vit dans le projet Supabase, à côté de la fonction `share` ;
  /// son adresse se déduit donc de `SUPABASE_URL`, déjà connue. Surchargeable
  /// pour pointer un relais local ou un domaine à soi :
  /// `--dart-define=RELAY_BASE_URL=http://localhost:54321/functions/v1/relay`.
  static const String _baseOverride = String.fromEnvironment('RELAY_BASE_URL');

  /// Le laissez-passer des constructions qui ne peuvent pas attester : le
  /// simulateur, où App Attest n'existe pas, et une construction Android qui
  /// ne vient pas de Google Play, que Play Integrity ne reconnaît pas. Ce
  /// n'en est pas moins un secret partagé — il n'a rien à faire dans une
  /// construction publiée, et le relais le coupe d'un
  /// `supabase secrets unset RELAY_DEV_TOKEN`.
  static const String devToken = String.fromEnvironment('RELAY_DEV_TOKEN');

  /// Le numéro du projet Google Cloud lié à l'application dans la console
  /// Play (*Intégrité de l'application › API Play Integrity*). Ce n'est pas
  /// un secret : il dit seulement à Google quel projet paie les verdicts.
  ///
  /// Écrit ici plutôt que passé par `--dart-define` : un `--dart-define`
  /// oublié ne se voit pas, et Android perdrait sans bruit l'identification
  /// de secours et le diagnostic. Zéro tant qu'il n'est pas renseigné — voir
  /// `docs/20-android.md`.
  static const int playCloudProjectNumber = 0;

  static String get baseUrl {
    if (_baseOverride.isNotEmpty) return _baseOverride.replaceAll(RegExp(r'/+$'), '');
    final project = SupabaseConfig.url.replaceAll(RegExp(r'/+$'), '');
    return project.isEmpty ? '' : '$project/functions/v1/relay';
  }

  /// Sans adresse, pas de relais — et les fonctions qui en dépendent sont
  /// simplement absentes de l'application, comme elles l'étaient sans clé.
  static bool get isConfigured => baseUrl.isNotEmpty;

  static Uri route(String name) => Uri.parse('$baseUrl/$name');
}
