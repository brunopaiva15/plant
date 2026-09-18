import 'package:flora/data/services/jev_decision_service.dart';
import 'package:flora/data/services/jev_identification_policy.dart';
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
  final Object? error;
  int calls = 0;
  Object? lastState;
  Map<String, dynamic>? lastQuestions;

  @override
  Future<Map<String, dynamic>> decide({
    required Object state,
    required Map<String, dynamic> questions,
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
}
