import 'package:flora/data/services/jev_decision_service.dart';
import 'package:flora/data/services/jev_identification_policy.dart';
import 'package:flora/domain/identification/identification_metrics.dart';
import 'package:flora/domain/identification/identification_policy.dart';
import 'package:flora/domain/identification/plant_identifier.dart';
import 'package:flutter_test/flutter_test.dart';

IdentificationCandidate c(String name, double score) => IdentificationCandidate(
      scientificName: name,
      score: score,
      source: IdentificationSource.local,
    );

class FakeJev extends JevDecisionService {
  FakeJev(this.response, {this.error});

  final Map<String, dynamic> response;

  /// Modifiable : un incident réseau se répare, et c'est justement ce que
  /// la fenêtre de silence doit laisser arriver.
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

Map<String, dynamic> answer(String choice, double probability) => {
      'model': 'typesafe/jev-test',
      'usage': {'cost': 0.000042},
      'answers': {
        'decision': {
          'type': 'choice',
          'choice': choice,
          'probabilities': {
            'show_result': choice == 'show_result' ? probability : 0.02,
            'ask_another_photo':
                choice == 'ask_another_photo' ? probability : 0.02,
            'keep_uncertain': choice == 'keep_uncertain' ? probability : 0.02,
          },
        },
      },
    };

void main() {
  const local = FallbackPolicy();

  test('un scan Iris déjà accepté ne consulte jamais Jev', () async {
    final fake = FakeJev(answer('ask_another_photo', 0.99));
    final policy = JevIdentificationPolicy(service: fake, configured: true);

    final offer = await policy.secondPhotoOfferFor(
      policy: local,
      candidates: [c('Dracaena trifasciata', 0.98), c('Aloe maculata', 0.01)],
      photos: 1,
      maxPhotos: 2,
    );

    expect(offer, SecondPhotoOffer.none);
    expect(fake.calls, 0);
  });

  test('Jev peut supprimer une seconde photo que la politique locale proposerait', () async {
    final fake = FakeJev(answer('show_result', 0.91));
    final policy = JevIdentificationPolicy(service: fake, configured: true);

    final offer = await policy.secondPhotoOfferFor(
      policy: local,
      candidates: [
        c('Aloe maculata', 0.23),
        c('Gasteria carinata', 0.17),
        c('Haworthiopsis attenuata', 0.16),
      ],
      photos: 1,
      maxPhotos: 2,
    );

    expect(offer, SecondPhotoOffer.none);
    expect(fake.calls, 1);
  });

  test('Jev peut confirmer que la seconde photo est le bon geste', () async {
    final fake = FakeJev(answer('ask_another_photo', 0.95));
    final policy = JevIdentificationPolicy(service: fake, configured: true);

    final offer = await policy.secondPhotoOfferFor(
      policy: local,
      candidates: [
        c('Aloe maculata', 0.23),
        c('Gasteria carinata', 0.17),
        c('Haworthiopsis attenuata', 0.16),
      ],
      photos: 1,
      maxPhotos: 2,
    );

    expect(offer, SecondPhotoOffer.prominent);
    expect(fake.calls, 1);
    final decision = fake.lastQuestions?['decision'] as Map<String, dynamic>;
    final criteria = decision['criteria'] as Map<String, dynamic>;
    expect(criteria.containsKey('ask_another_photo'), isTrue);
  });

  test('une erreur Jev retombe sur la politique Iris', () async {
    final fake = FakeJev(const {}, error: StateError('offline'));
    final policy = JevIdentificationPolicy(service: fake, configured: true);
    final candidates = [c('Aloe maculata', 0.23), c('Gasteria carinata', 0.17)];

    expect(
      secondPhotoOffer(local, candidates, photos: 1, maxPhotos: 2),
      SecondPhotoOffer.prominent,
    );

    final offer = await policy.secondPhotoOfferFor(
      policy: local,
      candidates: candidates,
      photos: 1,
      maxPhotos: 2,
    );

    expect(offer, SecondPhotoOffer.prominent);
  });

  test('hors ligne, Auxine ne consulte jamais Jev', () async {
    final fake = FakeJev(answer('keep_uncertain', 0.91));
    final policy = JevIdentificationPolicy(service: fake, configured: true);
    final candidates = [c('Aloe maculata', 0.23), c('Gasteria carinata', 0.17)];

    final evaluation = await policy.evaluate(
      policy: local,
      candidates: candidates,
      photos: 1,
      maxPhotos: 2,
      online: false,
    );

    expect(fake.calls, 0);
    expect(evaluation.consultedJev, isFalse);
    expect(evaluation.usedFallback, isTrue);
    expect(evaluation.offer, SecondPhotoOffer.prominent);
    expect(evaluation.keepsUncertain, isFalse);
  });

  test('le retour du réseau rouvre une question laissée hors ligne', () async {
    final fake = FakeJev(answer('show_result', 0.86));
    final policy = JevIdentificationPolicy(service: fake, configured: true);
    final candidates = [c('Aloe maculata', 0.23), c('Gasteria carinata', 0.17)];

    await policy.evaluate(
      policy: local,
      candidates: candidates,
      photos: 1,
      maxPhotos: 2,
      online: false,
    );
    final evaluation = await policy.evaluate(
      policy: local,
      candidates: candidates,
      photos: 1,
      maxPhotos: 2,
    );

    expect(fake.calls, 1);
    expect(evaluation.decision?.action, JevProductAction.showResult);
  });

  test('un incident Jev ne condamne pas le scan pour la session', () async {
    var clock = DateTime(2026, 9, 19, 10);
    final fake = FakeJev(answer('show_result', 0.81), error: StateError('boom'));
    final policy = JevIdentificationPolicy(
      service: fake,
      configured: true,
      now: () => clock,
    );
    final candidates = [c('Aloe maculata', 0.23), c('Gasteria carinata', 0.17)];

    Future<JevPipelineEvaluation> evaluate() => policy.evaluate(
          policy: local,
          candidates: candidates,
          photos: 1,
          maxPhotos: 2,
        );

    expect((await evaluate()).usedFallback, isTrue);
    expect(fake.calls, 1);

    // Un écran qui se reconstruit ne doit pas rappeler OpenRouter à chaque
    // image : la fenêtre de silence tient.
    expect((await evaluate()).usedFallback, isTrue);
    expect(fake.calls, 1);

    // Passé la fenêtre, la question se repose — et le réseau est revenu.
    clock = clock.add(const Duration(seconds: 30));
    fake.error = null;
    final repaired = await evaluate();

    expect(fake.calls, 2);
    expect(repaired.usedFallback, isFalse);
    expect(repaired.decision?.action, JevProductAction.showResult);
  });

  test('l’état local est disponible sans attendre Jev', () {
    final fake = FakeJev(answer('show_result', 0.81));
    final policy = JevIdentificationPolicy(service: fake, configured: true);

    final evaluation = policy.localEvaluation(
      policy: local,
      candidates: [c('Aloe maculata', 0.23), c('Gasteria carinata', 0.17)],
      photos: 1,
      maxPhotos: 2,
    );

    expect(fake.calls, 0);
    expect(evaluation.offer, SecondPhotoOffer.prominent);
    expect(evaluation.consultedJev, isFalse);
    expect(evaluation.keepsUncertain, isFalse);
  });

  test('une même évaluation pipeline est réutilisée sans second appel', () async {
    final fake = FakeJev(answer('keep_uncertain', 0.88));
    final policy = JevIdentificationPolicy(service: fake, configured: true);
    final candidates = [
      c('Aloe maculata', 0.23),
      c('Gasteria carinata', 0.17),
      c('Haworthiopsis attenuata', 0.16),
    ];

    final offer = await policy.secondPhotoOfferFor(
      policy: local,
      candidates: candidates,
      photos: 1,
      maxPhotos: 2,
    );
    final evaluation = await policy.evaluate(
      policy: local,
      candidates: candidates,
      photos: 1,
      maxPhotos: 2,
    );

    expect(fake.calls, 1);
    expect(offer, SecondPhotoOffer.none);
    expect(evaluation.consultedJev, isTrue);
    expect(evaluation.usedFallback, isFalse);
    expect(evaluation.decision?.action, JevProductAction.keepUncertain);
    expect(evaluation.decision?.probability, 0.88);
    expect(evaluation.keepsUncertain, isTrue);
  });

  test('l’évaluation expose clairement le fallback Iris après erreur Jev', () async {
    final fake = FakeJev(const {}, error: StateError('offline'));
    final policy = JevIdentificationPolicy(service: fake, configured: true);
    final candidates = [
      c('Aloe maculata', 0.23),
      c('Gasteria carinata', 0.17),
    ];

    final evaluation = await policy.evaluate(
      policy: local,
      candidates: candidates,
      photos: 1,
      maxPhotos: 2,
    );

    expect(evaluation.consultedJev, isTrue);
    expect(evaluation.usedFallback, isTrue);
    expect(evaluation.offer, SecondPhotoOffer.prominent);
    expect(evaluation.decision, isNull);
    expect(evaluation.keepsUncertain, isFalse);
  });

  test('après deux photos ambiguës Jev tranche sans option de troisième photo', () async {
    final fake = FakeJev(answer('keep_uncertain', 0.94));
    final policy = JevIdentificationPolicy(service: fake, configured: true);

    final evaluation = await policy.evaluate(
      policy: local,
      candidates: [
        c('Aloe maculata', 0.31),
        c('Gasteria carinata', 0.27),
        c('Haworthiopsis attenuata', 0.21),
      ],
      photos: 2,
      maxPhotos: 2,
    );

    expect(fake.calls, 1);
    expect(evaluation.offer, SecondPhotoOffer.none);
    expect(evaluation.decision?.action, JevProductAction.keepUncertain);
    expect(evaluation.keepsUncertain, isTrue);

    final decision = fake.lastQuestions?['decision'] as Map<String, dynamic>;
    final criteria = decision['criteria'] as Map<String, dynamic>;
    expect(criteria.keys, containsAll(['show_result', 'keep_uncertain']));
    expect(criteria.containsKey('ask_another_photo'), isFalse);
  });

  test('une réponse ask_another_photo impossible après deux photos est neutralisée', () async {
    final fake = FakeJev(answer('ask_another_photo', 0.99));
    final policy = JevIdentificationPolicy(service: fake, configured: true);

    final evaluation = await policy.evaluate(
      policy: local,
      candidates: [
        c('Aloe maculata', 0.31),
        c('Gasteria carinata', 0.27),
      ],
      photos: 2,
      maxPhotos: 2,
    );

    expect(fake.calls, 1);
    expect(evaluation.offer, SecondPhotoOffer.none);
    expect(evaluation.decision?.action, JevProductAction.keepUncertain);
  });

  test('après deux photos ambiguës une panne Jev garde le résultat incertain', () async {
    final fake = FakeJev(const {}, error: StateError('offline'));
    final policy = JevIdentificationPolicy(service: fake, configured: true);

    final evaluation = await policy.evaluate(
      policy: local,
      candidates: [
        c('Aloe maculata', 0.31),
        c('Gasteria carinata', 0.27),
      ],
      photos: 2,
      maxPhotos: 2,
    );

    expect(fake.calls, 1);
    expect(evaluation.usedFallback, isTrue);
    expect(evaluation.offer, SecondPhotoOffer.none);
    expect(evaluation.keepsUncertain, isTrue);
    expect(evaluation.decision?.action, JevProductAction.keepUncertain);
  });

  test('après deux photos une réponse Jev invalide reste silencieusement incertaine', () async {
    final fake = FakeJev(const {'answers': {}});
    final policy = JevIdentificationPolicy(service: fake, configured: true);

    final evaluation = await policy.evaluate(
      policy: local,
      candidates: [
        c('Aloe maculata', 0.31),
        c('Gasteria carinata', 0.27),
      ],
      photos: 2,
      maxPhotos: 2,
    );

    expect(fake.calls, 1);
    expect(evaluation.usedFallback, isTrue);
    expect(evaluation.offer, SecondPhotoOffer.none);
    expect(evaluation.keepsUncertain, isTrue);
  });

  test('après deux photos un résultat Iris déjà net ne consulte toujours pas Jev', () async {
    final fake = FakeJev(answer('keep_uncertain', 0.99));
    final policy = JevIdentificationPolicy(service: fake, configured: true);

    final evaluation = await policy.evaluate(
      policy: local,
      candidates: [
        c('Dracaena trifasciata', 0.92),
        c('Aloe maculata', 0.03),
      ],
      photos: 2,
      maxPhotos: 2,
    );

    expect(fake.calls, 0);
    expect(evaluation.consultedJev, isFalse);
    expect(evaluation.offer, SecondPhotoOffer.none);
  });

  group('compteurs', () {
    final candidates = [c('Aloe maculata', 0.23), c('Gasteria carinata', 0.17)];

    Future<(JevIdentificationPolicy, InMemoryMetricsStore)> run(
      FakeJev fake, {
      int photos = 1,
    }) async {
      final store = InMemoryMetricsStore();
      final policy = JevIdentificationPolicy(
        service: fake,
        configured: true,
        metrics: store,
      );
      await policy.evaluate(
        policy: local,
        candidates: candidates,
        photos: photos,
        maxPhotos: 2,
      );
      return (policy, store);
    }

    test('une décision rendue se compte, avec sa latence', () async {
      final (_, store) = await run(FakeJev(answer('show_result', 0.87)));
      final m = store.read();

      expect(m.jevConsulted, 1);
      expect(m.jevShowResult, 1);
      expect(m.jevAskAnotherPhoto, 0);
      expect(m.jevKeepUncertain, 0);
      expect(m.jevIncidents, 0);
      expect(m.jevAnswered, 1);
      expect(m.jevLatencyMsSum, greaterThanOrEqualTo(0));
    });

    test('un appel sans réponse se compte comme incident', () async {
      final (_, store) =
          await run(FakeJev(const {}, error: StateError('boom')));
      final m = store.read();

      expect(m.jevConsulted, 1);
      expect(m.jevIncidents, 1);
      expect(m.jevAnswered, 0);
    });

    test('un scan qu’Iris accepte ne compte aucun arbitrage', () async {
      final store = InMemoryMetricsStore();
      final policy = JevIdentificationPolicy(
        service: FakeJev(answer('show_result', 0.9)),
        configured: true,
        metrics: store,
      );

      await policy.evaluate(
        policy: local,
        candidates: [c('Aloe maculata', 0.91), c('Gasteria carinata', 0.04)],
        photos: 1,
        maxPhotos: 2,
      );

      expect(store.read().jevConsulted, 0);
    });

    test('une incertitude tranchée malgré tout se compte une seule fois',
        () async {
      final (policy, store) =
          await run(FakeJev(answer('keep_uncertain', 0.9)), photos: 2);

      policy.noteCandidateChosen(JevProductAction.keepUncertain);
      // La personne change d'avis : le geste reste le même scan.
      policy.noteCandidateChosen(JevProductAction.keepUncertain);

      final m = store.read();
      expect(m.jevKeepUncertain, 1);
      expect(m.jevKeepUncertainThenPicked, 1);
      expect(m.jevKeepUncertainOverrideRate, 1);
    });

    test('un résultat montré puis cherché en ligne se compte', () async {
      final (policy, store) = await run(FakeJev(answer('show_result', 0.87)));

      policy.noteOnlineSearch(JevProductAction.showResult);

      final m = store.read();
      expect(m.jevShowResultThenSearched, 1);
      expect(m.jevShowResultDoubtRate, 1);
    });

    test('les gestes qui ne contredisent aucune décision ne comptent pas',
        () async {
      final (policy, store) = await run(FakeJev(answer('show_result', 0.87)));

      // Retenir une candidate après `show_result` est le cours normal des
      // choses, et chercher en ligne après une incertitude aussi.
      policy.noteCandidateChosen(JevProductAction.showResult);
      policy.noteOnlineSearch(JevProductAction.keepUncertain);
      policy.noteCandidateChosen(null);
      policy.noteOnlineSearch(null);

      final m = store.read();
      expect(m.jevKeepUncertainThenPicked, 0);
      expect(m.jevShowResultThenSearched, 0);
    });

    test('les compteurs Jev survivent à un aller-retour JSON', () {
      const m = IdentificationMetrics(
        jevConsulted: 9,
        jevIncidents: 2,
        jevShowResult: 4,
        jevAskAnotherPhoto: 2,
        jevKeepUncertain: 1,
        jevShowResultThenSearched: 1,
        jevKeepUncertainThenPicked: 1,
        jevLatencyMsSum: 7200,
      );

      final back = IdentificationMetrics.decode(m.encode());

      expect(back.jevConsulted, 9);
      expect(back.jevIncidents, 2);
      expect(back.jevShowResult, 4);
      expect(back.jevAskAnotherPhoto, 2);
      expect(back.jevKeepUncertain, 1);
      expect(back.jevShowResultThenSearched, 1);
      expect(back.jevKeepUncertainThenPicked, 1);
      expect(back.jevLatencyMsSum, 7200);
      expect(back.jevAverageLatencyMs, 800);
    });
  });
}
