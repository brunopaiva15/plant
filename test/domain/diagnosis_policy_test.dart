import 'package:flora/domain/diagnosis/diagnosis_policy.dart';
import 'package:flora/domain/diagnosis/plant_diagnoser.dart';
import 'package:flutter_test/flutter_test.dart';

DiagnosisCause _cause(Likelihood likelihood) =>
    DiagnosisCause(title: 'piste', likelihood: likelihood, explanation: '…', actions: const []);

Diagnosis _diagnosis(List<Likelihood> likelihoods) =>
    Diagnosis(summary: '…', causes: [for (final l in likelihoods) _cause(l)]);

/// La règle locale du diagnostic : celle qui vaut sans réseau, et le repli
/// de l'arbitrage Jev. Une seule décision produit, trois cas exclusifs.
void main() {
  test('une piste probable et une seule : le compte rendu se lit tel quel', () {
    final step = diagnosisNextStep(
      _diagnosis([Likelihood.likely, Likelihood.possible, Likelihood.unlikely]),
      photos: 1,
      maxPhotos: 3,
    );
    expect(step, DiagnosisNextStep.showResult);
  });

  test('deux pistes probables appellent une photo de plus', () {
    // Deux gestes différents, aucune raison de trancher pour la personne.
    final step = diagnosisNextStep(_diagnosis([Likelihood.likely, Likelihood.likely]), photos: 1, maxPhotos: 3);
    expect(step, DiagnosisNextStep.askAnotherPhoto);
  });

  test('aucune piste probable appelle une photo de plus', () {
    final step = diagnosisNextStep(_diagnosis([Likelihood.possible, Likelihood.unlikely]), photos: 2, maxPhotos: 3);
    expect(step, DiagnosisNextStep.askAnotherPhoto);
  });

  test('sans photo à demander, l’incertitude se dit', () {
    final step = diagnosisNextStep(_diagnosis([Likelihood.possible, Likelihood.possible]), photos: 3, maxPhotos: 3);
    expect(step, DiagnosisNextStep.keepUncertain);
  });

  test('un compte rendu sans aucune piste ne se lit pas comme une réponse', () {
    expect(diagnosisNextStep(_diagnosis(const []), photos: 1, maxPhotos: 3), DiagnosisNextStep.askAnotherPhoto);
    expect(diagnosisNextStep(_diagnosis(const []), photos: 3, maxPhotos: 3), DiagnosisNextStep.keepUncertain);
  });

  test('la netteté se lit sur les pistes probables, pas sur leur nombre', () {
    expect(diagnosisIsSettled(_diagnosis([Likelihood.likely])), isTrue);
    expect(diagnosisIsSettled(_diagnosis([Likelihood.likely, Likelihood.likely])), isFalse);
    expect(diagnosisIsSettled(_diagnosis([Likelihood.possible])), isFalse);
  });
}
