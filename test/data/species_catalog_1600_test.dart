import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flora/data/species/iris_detailed_catalog.dart';
import 'package:flora/data/species/species_index.dart';

void main() {
  test('encyclopédie : 1600 fiches dont les 1444 classes Iris', () {
    final modelJson = jsonDecode(File('assets/model/model.json').readAsStringSync()) as Map<String, dynamic>;
    final modelSpecies = (modelJson['species'] as Map<String, dynamic>).values.cast<String>().toList();
    final modelNames = modelSpecies.map((e) => e.toLowerCase()).toSet();
    final index = SpeciesIndex.parse(File('assets/species/catalog.tsv').readAsStringSync());

    final irisOnly = IrisDetailedCatalog.from(modelSpecies: modelSpecies, index: index);
    final encyclopedia = IrisDetailedCatalog.from(
      modelSpecies: modelSpecies,
      index: index,
      targetCount: IrisDetailedCatalog.encyclopediaTargetCount,
    );

    final names = encyclopedia.entries.map((e) => e.scientificName.toLowerCase()).toList();
    final extras = encyclopedia.entries.where((e) => !modelNames.contains(e.scientificName.toLowerCase())).toList();

    expect(modelJson['classes'], 1444);
    expect(irisOnly.entries, hasLength(1444));
    expect(encyclopedia.entries, hasLength(1600));
    expect(names.toSet().length, names.length);
    expect(modelNames.difference(names.toSet()), isEmpty);
    expect(extras, hasLength(156));
    expect(extras.every((e) => e.family.trim().isNotEmpty), isTrue);
    expect(
      extras.every((e) => [e.fr, e.en, e.de, e.it].any((name) => name.trim().isNotEmpty)),
      isTrue,
    );
  });
}
