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

  @override
  Future<Map<String, dynamic>> decide({
    required Object state,
    required Map<String, dynamic> questions,
  }) async {
    calls++;
    if (error != null) throw error!;
    return response;
  }
}

Map<String, dynamic> answer(String choice, double probability) => {
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

  test('au maximum de photos Jev n’est pas consulté', () async {
    final fake = FakeJev(answer('ask_another_photo', 0.99));
    final policy = JevIdentificationPolicy(service: fake, configured: true);

    final offer = await policy.secondPhotoOfferFor(
      policy: local,
      candidates: [c('Aloe maculata', 0.23), c('Gasteria carinata', 0.17)],
      photos: 2,
      maxPhotos: 2,
    );

    expect(offer, SecondPhotoOffer.none);
    expect(fake.calls, 0);
  });
}
