import '../../domain/cuttings/propagation_guide.dart';
import 'preferences_service.dart';

/// Les guides précisés par l'IA, gardés dans les préférences.
///
/// Un seul espace de rangement, indexé par langue, par guide et par espèce :
/// le texte d'une division ne doit jamais ressortir pour une bouture de
/// feuille de la même plante.
class PreferencesPropagationStore implements PropagationGuideStore {
  PreferencesPropagationStore(this._service);

  /// Au-delà, les plus anciennes entrées sortent. Quelques phrases par
  /// espèce : une entrée pèse un kilooctet environ.
  static const int max = 60;

  final PreferencesService _service;
  Map<String, PropagationRefinement>? _cached;

  Map<String, PropagationRefinement> get _entries => _cached ??= PropagationGuideStore.decode(_service.cuttingGuides);

  @override
  PropagationRefinement? read(String scientificName, String language, PropagationGuideKind kind) =>
      _entries[PropagationGuideStore.keyOf(scientificName, language, kind)];

  @override
  Future<void> write(String scientificName, String language, PropagationGuideKind kind, PropagationRefinement refinement) {
    final entries = _entries;
    // Réinsérée en dernier : l'ordre des clés dit l'ordre d'arrivée, et c'est
    // par là qu'on taille quand le cache déborde.
    final key = PropagationGuideStore.keyOf(scientificName, language, kind);
    entries.remove(key);
    entries[key] = refinement;
    while (entries.length > max) {
      entries.remove(entries.keys.first);
    }
    return _service.setCuttingGuides(PropagationGuideStore.encode(entries));
  }
}
