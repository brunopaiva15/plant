import 'package:flora/features/diagnosis/presentation/analysis_eta.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sans analyse passée, l’attente annoncée est celle par défaut', () {
    expect(AnalysisEta.expected(null), AnalysisEta.initial);
    expect(AnalysisEta.expected(12), const Duration(seconds: 12));
  });

  test('une nouvelle mesure compte pour moitié', () {
    expect(AnalysisEta.blend(null, const Duration(seconds: 12)), 12);
    // Trois analyses de 12 s après une habitude de 80 s : l'annonce rejoint
    // le nouveau modèle sans basculer au premier essai.
    var stored = 80;
    stored = AnalysisEta.blend(stored, const Duration(seconds: 12));
    expect(stored, 46);
    stored = AnalysisEta.blend(stored, const Duration(seconds: 12));
    stored = AnalysisEta.blend(stored, const Duration(seconds: 12));
    expect(stored, 21);
  });

  test('le temps restant s’arrondit aux cinq secondes, puis à la seconde', () {
    const expected = Duration(seconds: 80);
    expect(AnalysisEta.remaining(expected, const Duration(seconds: 3)), const Duration(seconds: 80));
    expect(AnalysisEta.remaining(expected, const Duration(seconds: 42)), const Duration(seconds: 40));
    expect(AnalysisEta.remaining(expected, const Duration(seconds: 73)), const Duration(seconds: 7));
    expect(AnalysisEta.remaining(expected, const Duration(seconds: 80)), isNull);
    expect(AnalysisEta.remaining(expected, const Duration(seconds: 95)), isNull);
  });

  test('le temps s’écrit en secondes, puis en minutes', () {
    expect(AnalysisEta.format(const Duration(seconds: 40)), '40 s');
    expect(AnalysisEta.format(const Duration(seconds: 60)), '1 min');
    expect(AnalysisEta.format(const Duration(seconds: 85)), '1 min 25 s');
  });
}
