import '../../domain/care/care_completion.dart';
import 'preferences_service.dart';

/// Les fiches complétées par l'IA, gardées dans les réglages de l'appareil.
///
/// C'est un cache, pas une donnée de l'utilisateur : il ne part ni dans la
/// sauvegarde ni dans la synchronisation, et le perdre ne coûte qu'un appel.
/// Il est borné, sans quoi il grossirait à chaque espèce consultée.
class PreferencesCareStore implements CareCompletionStore {
  PreferencesCareStore(this._service);

  /// Au-delà, les plus anciennes entrées sortent. Un jardin dépasse rarement
  /// quelques dizaines d'espèces, et une entrée pèse quelques dizaines
  /// d'octets.
  static const int max = 120;

  final PreferencesService _service;
  Map<String, CareCompletion>? _cached;

  Map<String, CareCompletion> get _entries =>
      _cached ??= CareCompletionStore.decode(_service.careCompletions);

  @override
  CareCompletion? read(String scientificName, String language) =>
      _entries[CareCompletionStore.keyOf(scientificName, language)];

  @override
  Future<void> write(String scientificName, String language, CareCompletion completion) {
    final entries = _entries;
    // Réinsérée en dernier : l'ordre des clés dit l'ordre d'arrivée, et c'est
    // par là qu'on taille quand le cache déborde.
    final key = CareCompletionStore.keyOf(scientificName, language);
    entries.remove(key);
    entries[key] = completion;
    while (entries.length > max) {
      entries.remove(entries.keys.first);
    }
    return _service.setCareCompletions(CareCompletionStore.encode(entries));
  }
}
