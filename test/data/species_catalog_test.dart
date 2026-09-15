import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flora/data/services/gbif_species_service.dart';
import 'package:flora/data/species/catalog_800/species_catalog_800.dart';
import 'package:flora/data/species/catalog_1000/species_catalog_1000.dart';
import 'package:flora/data/species/catalog_1200/species_catalog_1200.dart';
import 'package:flora/data/species/iris_detailed_catalog.dart';
import 'package:flora/data/species/species_catalog.dart';
import 'package:flora/data/species/species_index.dart';
import 'package:flora/domain/species/species_info.dart';

void main() {
  test('catalogue éditorial : exactement 1200 fiches curatées, uniques et complètes', () {
    final names = SpeciesCatalog.entries.map((e) => e.scientificName.toLowerCase()).toList();
    expect(SpeciesCatalog.entries, hasLength(1200));
    expect(names.toSet().length, names.length, reason: 'doublons : ${_dups(names)}');
    for (final e in SpeciesCatalog.entries) {
      expect(e.fr.trim(), isNotEmpty);
      expect(e.en.trim(), isNotEmpty);
      expect(e.de.trim(), isNotEmpty);
      expect(e.it.trim(), isNotEmpty);
      expect(e.family.trim(), isNotEmpty);
      expect(e.scientificName.split(' ').length, greaterThanOrEqualTo(2));
    }
  });

  test('encyclopédie Iris : exactement les 1444 classes du modèle', () {
    final modelJson = jsonDecode(File('assets/model/model.json').readAsStringSync()) as Map<String, dynamic>;
    final modelSpecies = (modelJson['species'] as Map<String, dynamic>).values.cast<String>().toList();
    final index = SpeciesIndex.parse(File('assets/species/catalog.tsv').readAsStringSync());
    final detailed = IrisDetailedCatalog.from(modelSpecies: modelSpecies, index: index);
    final names = detailed.entries.map((e) => e.scientificName).toList();

    expect(modelJson['classes'], 1444);
    expect(modelSpecies, hasLength(1444));
    expect(modelSpecies.toSet(), hasLength(1444));
    expect(detailed.entries, hasLength(1444));
    expect(names.toSet(), modelSpecies.toSet());
    expect(names.toSet().length, names.length);
    expect(detailed.entries.every((e) => e.commonName('fr').trim().isNotEmpty), isTrue);
  });

  test('catalogue : recherche par nom commun, latin ou famille, insensible à la casse', () {
    expect(SpeciesCatalog.search('monstera').map((e) => e.scientificName), contains('Monstera deliciosa'));
    expect(SpeciesCatalog.search('Basilikum').single.scientificName, 'Ocimum basilicum');
    expect(SpeciesCatalog.search('lamiaceae').length, greaterThan(5));
    expect(SpeciesCatalog.find('ocimum BASILICUM')?.fr, 'Basilic');
    expect(SpeciesCatalog.byCategory(SpeciesCategory.succulent), everyElement(predicate<SpeciesCatalogEntry>((e) => e.category == SpeciesCategory.succulent)));
  });

  test('catalogue : les extensions et corrections taxonomiques sont exposées', () {
    expect(SpeciesCatalog.find('Monstera obliqua')?.family, 'Araceae');
    expect(SpeciesCatalog.find('Monstera acuminata')?.family, 'Araceae');
    expect(SpeciesCatalog.find('Taxus baccata')?.family, 'Taxaceae');
    expect(SpeciesCatalog.find('Pinus sylvestris')?.family, 'Pinaceae');
    expect(SpeciesCatalog.find('Lutheria splendens')?.family, 'Bromeliaceae');
    expect(SpeciesCatalog.find('Pilea ovalis')?.family, 'Urticaceae');
    expect(SpeciesCatalog.find('Vriesea splendens'), isNull);
    expect(SpeciesCatalog.find('Pilea involucrata'), isNull);
  });

  test('catalogue : le palier 650 ajoute des classes Iris 8 dans chaque catégorie', () {
    expect(SpeciesCatalog.find('Aeschynanthus radicans')?.category, SpeciesCategory.indoor);
    expect(SpeciesCatalog.find('Carnegiea gigantea')?.category, SpeciesCategory.succulent);
    expect(SpeciesCatalog.find('Curcuma longa')?.category, SpeciesCategory.herb);
    expect(SpeciesCatalog.find('Chenopodium quinoa')?.category, SpeciesCategory.vegetable);
    expect(SpeciesCatalog.find('Tamarindus indica')?.category, SpeciesCategory.fruit);
    expect(SpeciesCatalog.find('Cyclamen hederifolium')?.category, SpeciesCategory.flower);
    expect(SpeciesCatalog.find('Metasequoia glyptostroboides')?.category, SpeciesCategory.tree);
  });

  test('catalogue : les 150 entrées du palier 800 sont des classes Iris 8', () {
    final modelJson = jsonDecode(File('assets/model/model.json').readAsStringSync()) as Map<String, dynamic>;
    final modelSpecies = (modelJson['species'] as Map<String, dynamic>).values.cast<String>().toSet();
    final addedNames = SpeciesCatalog800.entries.map((e) => e.scientificName).toList();

    expect(modelJson['classes'], 1444);
    expect(addedNames, hasLength(150));
    expect(addedNames.toSet().length, addedNames.length);
    expect(addedNames.where((name) => !modelSpecies.contains(name)), isEmpty);
    expect(SpeciesCatalog.find('Abies bracteata')?.category, SpeciesCategory.tree);
    expect(SpeciesCatalog.find('Salvia microphylla')?.category, SpeciesCategory.flower);
  });

  test('catalogue : les 200 entrées du palier 1000 sont des classes Iris 8', () {
    final modelJson = jsonDecode(File('assets/model/model.json').readAsStringSync()) as Map<String, dynamic>;
    final modelSpecies = (modelJson['species'] as Map<String, dynamic>).values.cast<String>().toSet();
    final addedNames = SpeciesCatalog1000.entries.map((e) => e.scientificName).toList();

    expect(modelJson['classes'], 1444);
    expect(addedNames, hasLength(200));
    expect(addedNames.toSet().length, addedNames.length);
    expect(addedNames.where((name) => !modelSpecies.contains(name)), isEmpty);
    expect(SpeciesCatalog.find('Ranunculus flammula')?.category, SpeciesCategory.flower);
    expect(SpeciesCatalog.find('Parrotia persica')?.category, SpeciesCategory.tree);
    expect(SpeciesCatalog.find('Zingiber officinale')?.category, SpeciesCategory.herb);
    expect(SpeciesCatalog.find('Pistacia vera')?.category, SpeciesCategory.fruit);
    expect(SpeciesCatalog.find('Ranunculus flammula')?.fr, 'Ranunculus flammula');
  });

  test('catalogue : les 200 entrées du palier 1200 sont des classes Iris 8', () {
    final modelJson = jsonDecode(File('assets/model/model.json').readAsStringSync()) as Map<String, dynamic>;
    final modelSpecies = (modelJson['species'] as Map<String, dynamic>).values.cast<String>().toSet();
    final addedNames = SpeciesCatalog1200.entries.map((e) => e.scientificName).toList();

    expect(modelJson['classes'], 1444);
    expect(addedNames, hasLength(200));
    expect(addedNames.toSet().length, addedNames.length);
    expect(addedNames.where((name) => !modelSpecies.contains(name)), isEmpty);
    expect(SpeciesCatalog.find('Adenium obesum')?.category, SpeciesCategory.indoor);
    expect(SpeciesCatalog.find('Astrophytum myriostigma')?.category, SpeciesCategory.succulent);
    expect(SpeciesCatalog.find('Agastache foeniculum')?.category, SpeciesCategory.herb);
    expect(SpeciesCatalog.find('Cynara scolymus')?.category, SpeciesCategory.vegetable);
    expect(SpeciesCatalog.find('Citrus × bergamia')?.category, SpeciesCategory.fruit);
    expect(SpeciesCatalog.find('Adonis vernalis')?.category, SpeciesCategory.flower);
    expect(SpeciesCatalog.find('Aesculus hippocastanum')?.category, SpeciesCategory.tree);
    expect(SpeciesCatalog.find('Adonis vernalis')?.fr, 'Adonis vernalis');
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
