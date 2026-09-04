import 'package:flutter_test/flutter_test.dart';
import 'package:flora/data/services/gbif_species_service.dart';
import 'package:flora/data/species/species_catalog.dart';
import 'package:flora/domain/species/species_info.dart';

void main() {
  test('catalogue : noms scientifiques uniques et noms communs présents dans les 4 langues', () {
    final names = SpeciesCatalog.entries.map((e) => e.scientificName.toLowerCase()).toList();
    expect(names.toSet().length, names.length, reason: 'doublons : ${_dups(names)}');
    for (final e in SpeciesCatalog.entries) {
      expect(e.fr.trim(), isNotEmpty);
      expect(e.en.trim(), isNotEmpty);
      expect(e.de.trim(), isNotEmpty);
      expect(e.it.trim(), isNotEmpty);
      expect(e.family.trim(), isNotEmpty);
      expect(e.scientificName.split(' ').length, greaterThanOrEqualTo(2));
    }
    expect(SpeciesCatalog.entries.length, greaterThan(200));
  });

  test('catalogue : recherche par nom commun, latin ou famille, insensible à la casse', () {
    expect(SpeciesCatalog.search('monstera').map((e) => e.scientificName), contains('Monstera deliciosa'));
    expect(SpeciesCatalog.search('Basilikum').single.scientificName, 'Ocimum basilicum');
    expect(SpeciesCatalog.search('lamiaceae').length, greaterThan(5));
    expect(SpeciesCatalog.find('ocimum BASILICUM')?.fr, 'Basilic');
    expect(SpeciesCatalog.byCategory(SpeciesCategory.succulent), everyElement(predicate<SpeciesCatalogEntry>((e) => e.category == SpeciesCategory.succulent)));
  });

  test('GBIF : parse d\'une page de recherche (total, fin de liste)', () {
    const body = '{"offset":0,"limit":2,"endOfRecords":false,"count":143,"results":['
        '{"key":1,"canonicalName":"Ficus lyrata","family":"Moraceae","vernacularNames":[{"vernacularName":"Figuier lyre","language":"fra"}]},'
        '{"key":2,"canonicalName":"Ficus elastica","family":"Moraceae","vernacularNames":[]}]}';
    final page = GbifSpeciesService.parseSearchPage(body, languageCode: 'fr');
    expect(page.endOfRecords, isFalse);
    expect(page.total, 143);
    expect(page.results.map((s) => s.scientificName), ['Ficus lyrata', 'Ficus elastica']);
    expect(page.results.first.commonName, 'Figuier lyre');
  });
}

List<String> _dups(List<String> l) {
  final seen = <String>{};
  return l.where((n) => !seen.add(n)).toList();
}
