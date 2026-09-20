import 'package:flora/core/window_regions.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Le vrai trajet de la réponse du natif.
///
/// Les autres tests de lecture donnent à `parse` des littéraux `Map<String,
/// Object?>`. Le canal, lui, passe par le codec standard, qui rend des
/// `Map<Object?, Object?>` jusque dans les rectangles imbriqués. Ce test-là
/// vérifie que la lecture survit à ces types — sur la réponse mesurée le
/// 20 septembre 2026, recopiée telle quelle.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('la réponse mesurée, décodée comme le moteur la décode', () async {
    final brut = <Object?, Object?>{
      'available': true,
      'compilateur': '6.4',
      'divisions': <Object?>[],
      'occlusions': <Object?>[
        <Object?, Object?>{'height': 37.0, 'width': 37.0, 'x': 399.6666666666667, 'y': 29.333333333333332},
        <Object?, Object?>{'height': 170.0, 'width': 84.0, 'x': 382.0, 'y': 0.0},
      ],
      'os': '27.1',
      'posee': true,
      'reservedRegions': 'lues',
      'statusBar': <Object?, Object?>{'height': 2.0, 'width': 466.0, 'x': 0.0, 'y': 0.0},
      'width': 466.0,
      'height': 678.0,
    };

    // Aller-retour par le codec, exactement comme un canal de plateforme.
    final enveloppe = const StandardMethodCodec().encodeSuccessEnvelope(brut);
    final decode = const StandardMethodCodec().decodeEnvelope(enveloppe);
    // Le codec rend des `Map<Object?, Object?>`, jusque dans les rectangles.
    expect(decode, isA<Map<Object?, Object?>>());
    final carte = (decode as Map).cast<String, Object?>();
    expect((carte['occlusions'] as List).first, isA<Map<Object?, Object?>>());

    final regions = WindowRegionsService.parse(carte);
    expect(regions.systemStackBottom, 170);
    expect(regions.systemAxisFromRight, closeTo(47.8, 0.1));
    expect(regions.fold, isNull);
  });
}
