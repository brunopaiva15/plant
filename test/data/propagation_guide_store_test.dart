import 'package:flora/data/services/preferences_propagation_store.dart';
import 'package:flora/data/services/preferences_service.dart';
import 'package:flora/domain/cuttings/propagation_guide.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Le cache des guides précisés : il rend ce qu'on lui a donné, langue par
/// langue et geste par geste, se souvient des réponses vides, et ne grossit
/// pas sans fin.

Future<PreferencesPropagationStore> _store([Map<String, Object> values = const {}]) async {
  SharedPreferences.setMockInitialValues(values);
  return PreferencesPropagationStore(await PreferencesService.load());
}

const _textes = ['a', 'b', 'c', 'd', 'e', 'f'];
const _vine = PropagationGuideKind.stemNodeVine;
const _division = PropagationGuideKind.division;

void main() {
  test('rend ce qui a été écrit, par espèce et par langue', () async {
    final store = await _store();
    await store.write('Epipremnum aureum', 'fr', _vine, const PropagationRefinement(steps: _textes));
    expect(store.read('  epipremnum AUREUM ', 'fr', _vine)?.steps, _textes);
    expect(store.read('Epipremnum aureum', 'de', _vine), isNull);
  });

  test('le texte d\'un geste ne ressort pas pour un autre', () async {
    final store = await _store();
    await store.write('Dracaena trifasciata', 'fr', _division, const PropagationRefinement(steps: _textes));
    expect(store.read('Dracaena trifasciata', 'fr', _division)?.steps, _textes);
    expect(store.read('Dracaena trifasciata', 'fr', PropagationGuideKind.leafCutting), isNull);
  });

  test('une réponse vide se garde aussi : la question ne repart pas', () async {
    final store = await _store();
    await store.write('Inconnue', 'fr', _vine, const PropagationRefinement());
    final lu = store.read('Inconnue', 'fr', _vine);
    expect(lu, isNotNull);
    expect(lu!.isEmpty, isTrue);
  });

  test('survit au redémarrage', () async {
    final premier = await _store();
    await premier.write('Monstera deliciosa', 'it', _vine, const PropagationRefinement(steps: _textes));
    final brut = (await SharedPreferences.getInstance()).getString('cutting_guides')!;
    final second = await _store({'cutting_guides': brut});
    expect(second.read('Monstera deliciosa', 'it', _vine)?.steps, _textes);
  });

  test('les plus anciennes entrées sortent quand le cache déborde', () async {
    final store = await _store();
    for (var i = 0; i < PreferencesPropagationStore.max + 5; i++) {
      await store.write('Espece $i', 'fr', _vine, const PropagationRefinement(steps: _textes));
    }
    expect(store.read('Espece 0', 'fr', _vine), isNull);
    expect(store.read('Espece ${PreferencesPropagationStore.max + 4}', 'fr', _vine), isNotNull);
  });

  test('un cache abîmé se lit comme vide', () {
    expect(PropagationGuideStore.decode('{pas du json'), isEmpty);
    expect(PropagationGuideStore.decode('[1, 2]'), isEmpty);
    // Une entrée dont un texte manque ne vaut rien : le guide local est
    // meilleur qu'un guide à trous.
    final troue = PropagationGuideStore.decode('{"fr|division|x": {"s": ["a", "", "c"]}}');
    expect(troue['fr|division|x']!.isEmpty, isTrue);
  });

  test('la clé porte la langue, le geste et l\'espèce', () {
    expect(PropagationGuideStore.keyOf(' Monstera Deliciosa ', 'fr', _vine), 'fr|stemNodeVine|monstera deliciosa');
  });
}
