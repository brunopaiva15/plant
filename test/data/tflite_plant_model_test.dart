import 'dart:io';

import 'package:flora/data/services/tflite_plant_model.dart';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
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

  group('cadrage de la photo', () {
    /// Une image dont on connaît la vérité : fond noir, bande rouge sur le
    /// bord gauche, carré vert au centre.
    Uint8List picture(int seed, {int width = 640, int height = 480}) {
      final im = img.Image(width: width, height: height);
      img.fill(im, color: img.ColorRgb8(0, 0, 0));
      img.fillRect(im, x1: 0, y1: 0, x2: width ~/ 40, y2: height - 1, color: img.ColorRgb8(255, 0, 0));
      final cx = width ~/ 2, cy = height ~/ 2;
      final half = (width ~/ 16).clamp(20, 400);
      img.fillRect(im, x1: cx - half, y1: cy - half, x2: cx + half, y2: cy + half, color: img.ColorRgb8(0, 255, 0));
      return img.encodeJpg(im, quality: 95);
    }

    bool hasChannel(List<List<List<List<double>>>> t, int channel) {
      for (final row in t.first) {
        for (final px in row) {
          if (px[channel] > 200 && px[(channel + 1) % 3] < 80) return true;
        }
      }
      return false;
    }

    test('la sortie a la forme attendue par le modèle', () {
      final out = TflitePlantModel.decodeForTest(picture(1), 224, 256)!;
      expect(out.length, 1);
      expect(out.first.length, 224);
      expect(out.first.first.length, 224);
      expect(out.first.first.first.length, 3);
      // Octets 0–255 : la normalisation est dans le graphe, pas ici.
      final values = [for (final r in out.first) for (final p in r) ...p];
      expect(values.reduce((a, b) => a > b ? a : b), greaterThan(1.0));
      expect(values.every((v) => v >= 0 && v <= 255), isTrue);
    });

    test('le carré central est conservé, les bords sont écartés', () {
      final out = TflitePlantModel.decodeForTest(picture(1), 224, 256)!;
      // Le vert du centre survit ; le rouge du bord gauche est hors du carré
      // central puis hors du recadrage 256 → 224.
      expect(hasChannel(out, 1), isTrue, reason: 'le sujet au centre doit rester');
      expect(hasChannel(out, 0), isFalse, reason: 'le bord de l\'image doit être écarté');
    });

    test('une grande photo passe par la réduction en deux temps', () {
      // 3000 px ramenés d'un coup à 224 par bilinéaire créeraient un
      // crénelage que le modèle n'a jamais vu ; la réduction intermédiaire
      // conserve la couleur moyenne des zones.
      final out = TflitePlantModel.decodeForTest(picture(20, width: 3000, height: 2400), 224, 256, 448)!;
      expect(out.first.length, 224);
      expect(hasChannel(out, 1), isTrue, reason: 'le sujet central survit à la réduction');
      expect(hasChannel(out, 0), isFalse, reason: 'le bord reste écarté');
    });

    test('sans recadrage supplémentaire, la recette reste valide', () {
      // loadSize == inputSize : redimensionnement direct, pour un modèle
      // futur entraîné ainsi.
      final out = TflitePlantModel.decodeForTest(picture(1), 224, 224)!;
      expect(out.first.length, 224);
    });

    test('une image illisible ne fait pas tomber l\'app', () {
      expect(TflitePlantModel.decodeForTest(Uint8List.fromList([1, 2, 3]), 224, 256), isNull);
    });
  });
}
