import 'dart:io';

import 'package:flora/data/services/tflite_plant_model.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Un bundle qui ne contient que ce qu'on lui donne : tout le reste échoue,
/// comme un asset absent dans l'application réelle.
class FakeBundle extends CachingAssetBundle {
  FakeBundle(this.files);

  final Map<String, String> files;

  @override
  Future<ByteData> load(String key) async {
    final content = files[key];
    if (content == null) throw StateError('asset absent : $key');
    return ByteData.view(Uint8List.fromList(content.codeUnits).buffer);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('sans modèle livré, le service est simplement absent', () async {
    final model = TflitePlantModel(bundle: FakeBundle(const {}));
    expect(await model.warmUp(), isFalse);
    expect(model.isAvailable, isFalse);
    expect(model.version, isNull);
    expect(await model.classify(File('inexistant.jpg')), isEmpty);
  });

  test('un second appel ne retente pas un chargement déjà échoué', () async {
    final bundle = FakeBundle(const {});
    final model = TflitePlantModel(bundle: bundle);
    await model.warmUp();
    await model.warmUp();
    expect(model.isAvailable, isFalse);
  });

  test('des classes vides sont une erreur, pas un modèle à zéro espèce', () async {
    final model = TflitePlantModel(bundle: FakeBundle(const {'assets/model/labels.txt': '\n  \n'}));
    expect(await model.warmUp(), isFalse);
  });

  test('un identifiant interne redevient un nom scientifique lisible', () {
    expect(TflitePlantModel.scientificNameOf('monstera-deliciosa'), 'Monstera deliciosa');
    expect(TflitePlantModel.scientificNameOf('citrus-x-limon'), 'Citrus × limon');
    expect(TflitePlantModel.scientificNameOf('ficus-benjamina-var-nuda'), 'Ficus benjamina var. nuda');
    expect(TflitePlantModel.scientificNameOf('monstera'), 'Monstera');
  });
}
