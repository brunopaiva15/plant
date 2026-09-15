import 'package:flora/domain/care/care_profile.dart';
import 'package:flora/domain/care/grow_light.dart';
import 'package:flutter_test/flutter_test.dart';

/// La lampe qui remplace la fenêtre qu'on n'a pas : plus la plante demande de
/// lumière, plus la lampe en donne, et la dose du jour suit.
void main() {
  test('le besoin en lumière commande l\'intensité et la durée', () {
    final ombre = GrowLight.forNeed(LightNeed.shade);
    final soleil = GrowLight.forNeed(LightNeed.fullSun);
    expect(soleil.ppfdMin, greaterThan(ombre.ppfdMin));
    expect(soleil.hours, greaterThanOrEqualTo(ombre.hours));
  });

  test('chaque palier en donne plus que le précédent', () {
    var previous = 0;
    for (final need in LightNeed.values) {
      final lamp = GrowLight.forNeed(need);
      expect(lamp.ppfdMin, greaterThanOrEqualTo(previous), reason: '$need recule');
      expect(lamp.ppfdMax, greaterThan(lamp.ppfdMin));
      previous = lamp.ppfdMin;
    }
  });

  test('la dose du jour est le produit de l\'intensité par la durée', () {
    // 150 µmol/m²/s pendant 12 h font 150 × 12 × 3600 / 1 000 000 mol/m².
    const lamp = GrowLight(ppfdMin: 150, ppfdMax: 250, hours: 12);
    expect(lamp.dliMin, 6);
    expect(lamp.dliMax, 11);
  });
}
