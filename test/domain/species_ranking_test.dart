import 'package:flora/domain/species/species_ranking.dart';
import 'package:flutter_test/flutter_test.dart';

int rank(
  String q, {
  String? common,
  String sci = 'Genus species',
  String? family,
  List<String> others = const [],
}) =>
    speciesRelevance(q, commonName: common, scientificName: sci, family: family, otherNames: others);

void main() {
  test('le nom courant exact passe avant le préfixe', () {
    expect(rank('Basilic', common: 'Basilic'), SpeciesRank.exact);
    expect(rank('basilic', common: 'Basilic citron'), SpeciesRank.prefix);
  });

  test('le préfixe passe avant le contenu, le contenu avant le scientifique', () {
    expect(rank('orchid', common: 'Orchidée papillon'), SpeciesRank.prefix);
    expect(rank('orchid', common: 'Arbre à orchidées'), SpeciesRank.commonContains);
    expect(rank('orchid', common: 'Cymbidium', sci: 'Orchidantha'), SpeciesRank.scientific);
  });

  test('le nom scientifique passe avant la famille', () {
    expect(rank('orchid', sci: 'Orchidantha', family: 'Orchidaceae'), SpeciesRank.scientific);
    expect(rank('orchid', sci: 'Cymbidium hybridum', family: 'Orchidaceae'), SpeciesRank.family);
  });

  test('la famille passe avant les autres langues', () {
    expect(rank('orchid', sci: 'Cymbidium hybridum', family: 'Orchidaceae'), SpeciesRank.family);
    expect(rank('orchid', sci: 'Cymbidium hybridum', others: ['Kahnorchidee']), SpeciesRank.other);
  });

  test('accents, casse et ligatures sont neutralisés', () {
    expect(rank('orchidee', common: 'Orchidée papillon'), SpeciesRank.prefix);
    expect(rank('edelweiss', common: 'Edelweiß'), SpeciesRank.exact);
  });

  test('sans correspondance', () {
    expect(rank('zzz', common: 'Orchidée', sci: 'Phalaenopsis'), SpeciesRank.none);
  });

  test('requête vide', () {
    expect(rank('   ', common: 'Orchidée'), SpeciesRank.none);
  });
}
