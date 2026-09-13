import 'package:flora/domain/identification/iris_feedback.dart';
import 'package:flora/domain/identification/plant_identifier.dart';
import 'package:flutter_test/flutter_test.dart';

IdentificationCandidate c(String name, double score, {IdentificationSource source = IdentificationSource.local}) =>
    IdentificationCandidate(scientificName: name, score: score, source: source);

/// Le geste d'enregistrer étiquette la photo, et le type d'étiquette dépend
/// de la provenance du nom retenu. Une erreur ici ne planterait rien : elle
/// classerait mal des milliers de photos, en silence.
void main() {
  final local = [c('Hoya carnosa', 0.55), c('Hoya kerrii', 0.30), c('Hoya linearis', 0.05)];

  group('le type de retour', () {
    test('la première proposition d’Iris, acceptée : confirmée', () {
      expect(feedbackKind(local, 'Hoya carnosa', ChosenSource.local), FeedbackKind.confirmee);
    });

    test('une proposition d’Iris, mais pas la première : reclassée', () {
      expect(feedbackKind(local, 'Hoya kerrii', ChosenSource.local), FeedbackKind.reclassee);
      expect(feedbackKind(local, 'Hoya linearis', ChosenSource.local), FeedbackKind.reclassee);
    });

    test('un nom pris chez Pl@ntNet ou au sélecteur : corrigée, même s’il figurait dans la liste', () {
      // Iris avait la bonne réponse en deuxième ; la personne ne l’a pas vue
      // ou ne l’a pas crue, et l’a retrouvée ailleurs. C’est une correction
      // de son point de vue, et c’est ce point de vue qu’on enregistre.
      expect(feedbackKind(local, 'Hoya kerrii', ChosenSource.remote), FeedbackKind.corrigee);
      expect(feedbackKind(local, 'Hoya kerrii', ChosenSource.picker), FeedbackKind.corrigee);
    });

    test('une candidate dite locale mais absente de la liste : corrigée, faute de pouvoir la confirmer', () {
      expect(feedbackKind(local, 'Monstera deliciosa', ChosenSource.local), FeedbackKind.corrigee);
    });

    test('sans proposition locale, rien ne se confirme', () {
      expect(feedbackKind(const [], 'Hoya kerrii', ChosenSource.local), FeedbackKind.corrigee);
    });
  });

  group('poser la question', () {
    test('une fois, à qui n’a pas encore dit oui, là où un oui peut servir', () {
      expect(shouldAskForFeedback(asked: false, enabled: false, available: true), isTrue);
    });

    test('jamais deux fois, quelle qu’ait été la réponse', () {
      expect(shouldAskForFeedback(asked: true, enabled: false, available: true), isFalse);
    });

    test('pas à qui a déjà dit oui', () {
      expect(shouldAskForFeedback(asked: false, enabled: true, available: true), isFalse);
    });

    test('pas sans compte distant ni Supabase : on ne promet pas ce qu’on ne peut pas tenir', () {
      expect(shouldAskForFeedback(asked: false, enabled: false, available: false), isFalse);
    });
  });

  test('le retour porte son type', () {
    final f = IrisFeedback(photos: const [], local: local, chosenName: 'Hoya carnosa', chosenSource: ChosenSource.local, modelVersion: '8');
    expect(f.kind, FeedbackKind.confirmee);
  });

  test('sans consentement, l’enregistreur ne fait rien et ne lève rien', () async {
    const recorder = NoFeedbackRecorder();
    await recorder.record(IrisFeedback(photos: const [], local: local, chosenName: 'Hoya carnosa', chosenSource: ChosenSource.local, modelVersion: '8'));
  });
}
