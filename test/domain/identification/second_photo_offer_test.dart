import 'package:flora/domain/identification/identification_policy.dart';
import 'package:flora/domain/identification/plant_identifier.dart';
import 'package:flutter_test/flutter_test.dart';

IdentificationCandidate c(double score, {IdentificationSource source = IdentificationSource.local}) =>
    IdentificationCandidate(scientificName: 'Monstera deliciosa', score: score, source: source);

void main() {
  const policy = FallbackPolicy();

  group('proposer une photo de plus', () {
    test('le modèle hésite : on le propose en évidence', () {
      final results = [c(0.45), c(0.30)];
      expect(policy.decide(results), isNot(IdentificationVerdict.accepted));
      expect(secondPhotoOffer(policy, results, photos: 1, maxPhotos: 3), SecondPhotoOffer.prominent);
    });

    test('la réponse est acceptée : on le propose quand même, discrètement', () {
      // C'est tout le § 12.3 : une réponse acceptée à 0,70 est juste neuf
      // fois sur dix, et la dixième ne se voyait jamais offrir le geste qui
      // la corrigerait.
      final results = [c(0.92), c(0.02)];
      expect(policy.decide(results), IdentificationVerdict.accepted);
      expect(secondPhotoOffer(policy, results, photos: 1, maxPhotos: 3), SecondPhotoOffer.quiet);
    });

    test('au maximum de photos, plus rien à proposer', () {
      expect(secondPhotoOffer(policy, [c(0.92)], photos: 3, maxPhotos: 3), SecondPhotoOffer.none);
      expect(secondPhotoOffer(policy, [c(0.45)], photos: 4, maxPhotos: 3), SecondPhotoOffer.none);
    });

    test('sur une réponse du service distant, la photo de plus ne rejoue rien', () {
      // Une photo de plus ne relancerait pas Pl@ntNet sans un nouvel appel,
      // donc sans entamer le quota : ce n'est plus le geste gratuit.
      final results = [c(0.92, source: IdentificationSource.remote)];
      expect(secondPhotoOffer(policy, results, photos: 1, maxPhotos: 3), SecondPhotoOffer.none);
    });

    test('sans candidat, rien', () {
      expect(secondPhotoOffer(policy, const [], photos: 1, maxPhotos: 3), SecondPhotoOffer.none);
    });

    test('une liste sous le plancher ne coupe pas la proposition', () {
      // `noCandidate` n'est pas `accepted` : la photo de plus reste le
      // meilleur geste disponible, et c'est le cas où elle sert le plus.
      final results = [c(0.05)];
      expect(policy.decide(results), IdentificationVerdict.noCandidate);
      expect(secondPhotoOffer(policy, results, photos: 1, maxPhotos: 3), SecondPhotoOffer.prominent);
    });
  });
}
