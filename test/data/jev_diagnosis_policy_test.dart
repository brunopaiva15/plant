import 'package:flora/data/services/jev_decision_service.dart';
import 'package:flora/data/services/jev_diagnosis_policy.dart';
import 'package:flora/domain/diagnosis/diagnosis_observations.dart';
import 'package:flora/domain/diagnosis/diagnosis_policy.dart';
import 'package:flora/domain/diagnosis/plant_diagnoser.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeJev extends JevDecisionService {
  FakeJev(this.response, {this.error});

  final Map<String, dynamic> response;

  /// Modifiable : un incident réseau se répare, et la fenêtre de silence est
  /// là pour laisser cela arriver.
  Object? error;
  int calls = 0;
  Object? lastState;
  Map<String, dynamic>? lastQuestions;

  @override
  Future<Map<String, dynamic>> decide({
    required Object state,
    required Map<String, dynamic> questions,
    required Duration timeout,
  }) async {
    calls++;
    lastState = state;
    lastQuestions = questions;
    if (error != null) throw error!;
    return response;
  }
}

Map<String, dynamic> answer(String choice) => {
      'answers': {
        'decision': {'type': 'choice', 'choice': choice, 'probabilities': {choice: 0.91}},
      },
    };

DiagnosisCause _cause(Likelihood likelihood, {String? problemId}) => DiagnosisCause(
      title: 'piste',
      likelihood: likelihood,
      explanation: '…',
      actions: const [],
      problemId: problemId,
    );

/// Deux pistes également probables : le compte rendu ne tranche pas, et
/// c'est exactement le cas que Jev arbitre.
final _ambigu = Diagnosis(
  summary: 'Feuilles jaunes en bas.',
  causes: [_cause(Likelihood.likely, problemId: '002'), _cause(Likelihood.likely), _cause(Likelihood.possible)],
  suggestedView: DiagnosisView.leafUnderside,
);

final _net = Diagnosis(summary: '…', causes: [_cause(Likelihood.likely, problemId: '060'), _cause(Likelihood.unlikely)]);

void main() {
  test('un compte rendu qui désigne une seule piste ne consulte jamais Jev', () async {
    final fake = FakeJev(answer('ask_another_photo'));
    final policy = JevDiagnosisPolicy(service: fake, configured: true);

    final step = await policy.evaluate(diagnosis: _net, photos: 1, maxPhotos: 3);

    expect(step, DiagnosisNextStep.showResult);
    expect(fake.calls, 0, reason: 'rien à arbitrer, donc rien à demander');
  });

  test('sans relais, la règle locale répond seule', () async {
    final fake = FakeJev(answer('show_result'));
    final policy = JevDiagnosisPolicy(service: fake, configured: false);

    expect(await policy.evaluate(diagnosis: _ambigu, photos: 1, maxPhotos: 3), DiagnosisNextStep.askAnotherPhoto);
    expect(fake.calls, 0);
  });

  test('hors ligne, aucun appel ne part', () async {
    final fake = FakeJev(answer('show_result'));
    final policy = JevDiagnosisPolicy(service: fake, configured: true);

    expect(await policy.evaluate(diagnosis: _ambigu, photos: 1, maxPhotos: 3, online: false), DiagnosisNextStep.askAnotherPhoto);
    expect(fake.calls, 0);
  });

  test('Jev peut conclure qu’une photo de plus ne changerait rien', () async {
    final fake = FakeJev(answer('show_result'));
    final policy = JevDiagnosisPolicy(service: fake, configured: true);

    final step = await policy.evaluate(diagnosis: _ambigu, photos: 1, maxPhotos: 3);

    expect(step, DiagnosisNextStep.showResult, reason: 'la règle locale demandait une photo, Jev la retire');
    expect(fake.calls, 1);
  });

  test('ce qui part n’est ni une photo ni un mot de la personne', () async {
    final fake = FakeJev(answer('keep_uncertain'));
    final policy = JevDiagnosisPolicy(service: fake, configured: true);

    await policy.evaluate(
      diagnosis: _ambigu,
      photos: 2,
      maxPhotos: 3,
      observations: const DiagnosisObservations(soil: SoilState.soggy, bugs: BugSighting.none),
      symptomsGiven: true,
    );

    final state = fake.lastState! as Map<String, Object?>;
    expect(state['photo_count'], 2);
    expect(state['likely_count'], 2);
    expect(state['checked_by_hand'], ['soil', 'bugs']);
    expect(state['not_checked'], ['roots', 'light']);
    expect(state['owner_described_symptoms'], isTrue);
    expect(state['view_the_report_would_like'], 'leaf_underside');
    expect(state['causes'], hasLength(3));
    // Ni le résumé, ni les titres, ni les symptômes écrits : des rangs, des
    // crans et des numéros.
    final texte = state.toString();
    expect(texte, isNot(contains('Feuilles jaunes')));
    expect(texte, isNot(contains('piste')));
  });

  test('à la dernière photo, la demande d’une vue de plus est retirée', () async {
    final fake = FakeJev(answer('ask_another_photo'));
    final policy = JevDiagnosisPolicy(service: fake, configured: true);

    final step = await policy.evaluate(diagnosis: _ambigu, photos: 3, maxPhotos: 3);

    expect(step, DiagnosisNextStep.keepUncertain, reason: 'aucune photo ne reste à demander');
    final questions = fake.lastQuestions!['decision']! as Map<String, dynamic>;
    final criteria = questions['criteria']! as Map<String, dynamic>;
    expect(criteria.containsKey('ask_another_photo'), isFalse);
  });

  test('une réponse illisible ne pilote rien', () async {
    final fake = FakeJev({'answers': {'decision': {'choice': 'peut-être'}}});
    final policy = JevDiagnosisPolicy(service: fake, configured: true);

    expect(await policy.evaluate(diagnosis: _ambigu, photos: 3, maxPhotos: 3), DiagnosisNextStep.keepUncertain);
  });

  test('un incident laisse la règle locale répondre, puis la question se repose', () async {
    final fake = FakeJev(answer('show_result'), error: const JevDecisionException('délai dépassé'));
    var maintenant = DateTime(2026, 9, 19, 10);
    final policy = JevDiagnosisPolicy(service: fake, configured: true, now: () => maintenant);

    expect(await policy.evaluate(diagnosis: _ambigu, photos: 1, maxPhotos: 3), DiagnosisNextStep.askAnotherPhoto);
    expect(fake.calls, 1);

    // Pendant la fenêtre de silence, l'écran ne rappelle pas OpenRouter.
    fake.error = null;
    expect(await policy.evaluate(diagnosis: _ambigu, photos: 1, maxPhotos: 3), DiagnosisNextStep.askAnotherPhoto);
    expect(fake.calls, 1);

    maintenant = maintenant.add(const Duration(seconds: 25));
    expect(await policy.evaluate(diagnosis: _ambigu, photos: 1, maxPhotos: 3), DiagnosisNextStep.showResult);
    expect(fake.calls, 2);
  });

  test('une décision rendue est mémorisée : un rebuild ne la redemande pas', () async {
    final fake = FakeJev(answer('keep_uncertain'));
    final policy = JevDiagnosisPolicy(service: fake, configured: true);

    expect(await policy.evaluate(diagnosis: _ambigu, photos: 1, maxPhotos: 3), DiagnosisNextStep.keepUncertain);
    expect(await policy.evaluate(diagnosis: _ambigu, photos: 1, maxPhotos: 3), DiagnosisNextStep.keepUncertain);
    expect(fake.calls, 1);
  });
}
