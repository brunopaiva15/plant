import 'package:flora/domain/identification/identification_confidence.dart';
import 'package:flora/domain/identification/identification_policy.dart';
import 'package:flora/domain/identification/plant_identifier.dart';
import 'package:flutter_test/flutter_test.dart';

IdentificationCandidate _local(String name, double score) =>
    IdentificationCandidate(scientificName: name, score: score, source: IdentificationSource.local);
IdentificationCandidate _remote(String name, double score) =>
    IdentificationCandidate(scientificName: name, score: score, source: IdentificationSource.remote);

/// Ce que le modèle embarqué a le droit de dire d'une plante qui vit dehors.
///
/// Iris Indoor n'expose que des plantes d'intérieur. Mesuré sur 40 photos de
/// plantes hors catalogue, il en **affirme 27,5 %** au-dessus du seuil et
/// avec la marge (§ 12.7 de `docs/09`) : une plante de jardin reçoit le nom
/// d'une plante d'appartement, sans réserve, et ni le seuil ni la marge ni le
/// repli ne le voient — l'erreur est confiante.
///
/// Dehors, Iris propose donc au lieu d'affirmer. Ce n'est pas une
/// interdiction : `docs/14` § 8 veut que le contexte donne un a priori, jamais
/// une interdiction. Les candidates restent toutes là, le genre parle encore,
/// et la seconde photo est proposée puisque la réponse n'est plus tenue pour
/// sûre.
void main() {
  const dedans = FallbackPolicy();
  final dehors = const FallbackPolicy().outdoors();

  test('dedans, rien ne change', () {
    expect(dedans.localMayAffirm, isTrue);
    expect(dedans.decide([_local('Monstera deliciosa', 0.95), _local('Monstera adansonii', 0.02)]),
        IdentificationVerdict.accepted);
  });

  test('dehors, la même liste est proposée mais pas affirmée', () {
    // Le cas mesuré : Veronica elliptica rendue Nephrolepis cordifolia à
    // 0,8978, acceptée sans réserve. Dehors, elle reste montrée — elle n'est
    // simplement plus présentée comme sûre.
    final candidats = [_local('Nephrolepis cordifolia', 0.8978), _local('Asplenium nidus', 0.02)];
    expect(dedans.decide(candidats), IdentificationVerdict.accepted);
    expect(dehors.decide(candidats), IdentificationVerdict.plausible);
  });

  test('dehors, les seuils eux-mêmes ne bougent pas', () {
    // On ne remonte pas le seuil : ce serait payer de la justesse sur les
    // plantes d'intérieur pour un défaut qui ne les concerne pas.
    expect(dehors.acceptThreshold, dedans.acceptThreshold);
    expect(dehors.plausibleThreshold, dedans.plausibleThreshold);
    expect(dehors.minMargin, dedans.minMargin);
    expect(dehors.floor, dedans.floor);
  });

  test('dehors, une réponse faible reste ce qu elle était', () {
    final faible = [_local('Monstera deliciosa', 0.40), _local('Monstera adansonii', 0.05)];
    expect(dehors.decide(faible), IdentificationVerdict.plausible);
    final nulle = [_local('Monstera deliciosa', 0.04)];
    expect(dehors.decide(nulle), IdentificationVerdict.noCandidate);
  });

  test('une réponse distante affirme dehors comme dedans', () {
    // Pl@ntNet connaît des dizaines de milliers d'espèces et a déjà tranché :
    // l'a priori d'intérieur ne le concerne pas.
    final candidats = [_remote('Acer palmatum', 0.95), _remote('Acer japonicum', 0.02)];
    expect(dehors.decide(candidats), IdentificationVerdict.accepted);
  });

  test('dehors, le genre reprend la parole que l espèce a perdue', () {
    // Trois érables à 0,30 : l'espèce n'est pas sûre, le genre l'est.
    final erables = [
      _local('Acer palmatum', 0.30),
      _local('Acer japonicum', 0.28),
      _local('Acer platanoides', 0.22),
    ];
    final reponse = genusAnswer(dehors, erables);
    expect(reponse?.genus, 'Acer');
    expect(reponse!.species, 3);
  });

  test('un genre d une seule espèce n est pas une réponse de genre', () {
    // Sans cette garde, retirer le droit d'affirmer ferait passer une réponse
    // d'espèce pour une réponse de genre, en la rhabillant.
    final seule = [_local('Nephrolepis cordifolia', 0.8978), _local('Asplenium nidus', 0.02)];
    expect(genusAnswer(dehors, seule), isNull);
    expect(genusAnswer(dedans, seule), isNull);
  });

  test('dehors, la seconde photo est proposée puisque rien n est tranché', () {
    // Elle est gratuite et hors ligne, et vaut 13,7 points de top-1.
    final candidats = [_local('Nephrolepis cordifolia', 0.8978), _local('Asplenium nidus', 0.02)];
    expect(secondPhotoOffer(dedans, candidats, photos: 1, maxPhotos: 2), SecondPhotoOffer.none);
    expect(secondPhotoOffer(dehors, candidats, photos: 1, maxPhotos: 2), SecondPhotoOffer.prominent);
  });

  test('dehors, le mot affiché suit la décision prise', () {
    // « probable » est réservé à ce que la politique accepterait sans appel :
    // si elle n'accepte plus, le mot doit descendre avec elle.
    final candidat = _local('Nephrolepis cordifolia', 0.8978);
    expect(IdentificationConfidence.of(candidat, policy: dedans), IdentificationConfidence.likely);
    expect(IdentificationConfidence.of(candidat, policy: dehors), IdentificationConfidence.possible);
  });
}
