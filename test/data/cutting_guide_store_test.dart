import 'package:flora/data/services/preferences_cutting_store.dart';
import 'package:flora/data/services/preferences_service.dart';
import 'package:flora/domain/cuttings/cutting_guide.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Le cache des guides précisés : il rend ce qu'on lui a donné, langue par
/// langue, se souvient des réponses vides, et ne grossit pas sans fin.

Future<PreferencesCuttingStore> _store([Map<String, Object> values = const {}]) async {
  SharedPreferences.setMockInitialValues(values);
  return PreferencesCuttingStore(await PreferencesService.load());
}

const _six = ['a', 'b', 'c', 'd', 'e', 'f'];

void main() {
  test('rend ce qui a été écrit, par espèce et par langue', () async {
    final store = await _store();
    await store.write('Epipremnum aureum', 'fr', const CuttingGuideRefinement(steps: _six, method: 'water'));
    final lu = store.read('  epipremnum AUREUM ', 'fr');
    expect(lu?.steps, _six);
    expect(lu?.method, 'water');
    expect(store.read('Epipremnum aureum', 'de'), isNull);
  });

  test('une réponse vide se garde aussi : la question ne repart pas', () async {
    final store = await _store();
    await store.write('Inconnue', 'fr', const CuttingGuideRefinement());
    final lu = store.read('Inconnue', 'fr');
    expect(lu, isNotNull);
    expect(lu!.isEmpty, isTrue);
  });

  test('survit au redémarrage', () async {
    final premier = await _store();
    await premier.write('Monstera deliciosa', 'it', const CuttingGuideRefinement(steps: _six));
    final brut = (await SharedPreferences.getInstance()).getString('cutting_guides')!;
    final second = await _store({'cutting_guides': brut});
    expect(second.read('Monstera deliciosa', 'it')?.steps, _six);
  });

  test('les plus anciennes entrées sortent quand le cache déborde', () async {
    final store = await _store();
    for (var i = 0; i < PreferencesCuttingStore.max + 5; i++) {
      await store.write('Espece $i', 'fr', const CuttingGuideRefinement(steps: _six));
    }
    expect(store.read('Espece 0', 'fr'), isNull);
    expect(store.read('Espece ${PreferencesCuttingStore.max + 4}', 'fr'), isNotNull);
  });

  test('un cache abîmé se lit comme vide', () {
    expect(CuttingGuideStore.decode('{pas du json'), isEmpty);
    expect(CuttingGuideStore.decode('[1, 2]'), isEmpty);
    // Cinq étapes rangées par une ancienne version : elles ne valent rien.
    final cinq = CuttingGuideStore.decode('{"fr|x": {"s": ["a", "b", "c", "d", "e"]}}');
    expect(cinq['fr|x']!.isEmpty, isTrue);
  });
}
