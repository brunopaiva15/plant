import '../../domain/cuttings/cutting_guide.dart';
import 'preferences_service.dart';

/// Les guides de bouturage précisés par l'IA, gardés dans les réglages de
/// l'appareil.
///
/// C'est un cache, pas une donnée de l'utilisateur : il ne part ni dans la
/// sauvegarde ni dans la synchronisation, et le perdre ne coûte qu'un appel.
/// Il est borné, sans quoi il grossirait à chaque espèce bouturée.
class PreferencesCuttingStore implements CuttingGuideStore {
  PreferencesCuttingStore(this._service);

  /// Au-delà, les plus anciennes entrées sortent. Six phrases par espèce :
  /// une entrée pèse un kilooctet environ.
  static const int max = 60;

  final PreferencesService _service;
  Map<String, CuttingGuideRefinement>? _cached;

  Map<String, CuttingGuideRefinement> get _entries => _cached ??= CuttingGuideStore.decode(_service.cuttingGuides);

  @override
  CuttingGuideRefinement? read(String scientificName, String language) =>
      _entries[CuttingGuideStore.keyOf(scientificName, language)];

  @override
  Future<void> write(String scientificName, String language, CuttingGuideRefinement refinement) {
    final entries = _entries;
    // Réinsérée en dernier : l'ordre des clés dit l'ordre d'arrivée, et c'est
    // par là qu'on taille quand le cache déborde.
    final key = CuttingGuideStore.keyOf(scientificName, language);
    entries.remove(key);
    entries[key] = refinement;
    while (entries.length > max) {
      entries.remove(entries.keys.first);
    }
    return _service.setCuttingGuides(CuttingGuideStore.encode(entries));
  }
}
