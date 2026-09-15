import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flora/core/utils/scientific_name.dart';
import 'package:flora/data/species/catalog_care_guide.dart';
import 'package:flora/data/species/iris_detailed_catalog.dart';
import 'package:flora/data/species/species_index.dart';
import 'package:flora/domain/care/care_guide.dart';

void main() {
  const careGuide = CatalogCareGuide();

  test('encyclopédie : 1900 fiches dont les 1444 classes Iris', () {
    final modelJson = jsonDecode(File('assets/model/model.json').readAsStringSync()) as Map<String, dynamic>;
    final modelSpecies = (modelJson['species'] as Map<String, dynamic>).values.cast<String>().toList();
    final modelNames = modelSpecies.map((e) => e.toLowerCase()).toSet();
    final modelAccepted = modelSpecies
        .map((e) => acceptedSpeciesName(normalizeScientificName(e)).toLowerCase())
        .toSet();
    final index = SpeciesIndex.parse(File('assets/species/catalog.tsv').readAsStringSync());

    final irisOnly = IrisDetailedCatalog.from(modelSpecies: modelSpecies, index: index);
    final encyclopedia = IrisDetailedCatalog.from(
      modelSpecies: modelSpecies,
      index: index,
      targetCount: IrisDetailedCatalog.encyclopediaTargetCount,
    );

    final names = encyclopedia.entries.map((e) => e.scientificName.toLowerCase()).toList();
    final extras = encyclopedia.entries.where((e) => !modelNames.contains(e.scientificName.toLowerCase())).toList();
    final extraAccepted = extras
        .map((e) => acceptedSpeciesName(normalizeScientificName(e.scientificName)).toLowerCase())
        .toList();

    expect(modelJson['classes'], 1444);
    expect(irisOnly.entries, hasLength(1444));
    expect(encyclopedia.entries, hasLength(1900));
    expect(names.toSet().length, names.length, reason: 'noms scientifiques dupliqués');
    expect(modelNames.difference(names.toSet()), isEmpty);
    expect(extras, hasLength(456));
    expect(extraAccepted.toSet().length, extraAccepted.length, reason: 'synonymes rejoués parmi les fiches hors Iris');
    expect(extraAccepted.where(modelAccepted.contains), isEmpty, reason: 'une fiche hors Iris rejoue une classe Iris sous un synonyme');

    for (final entry in extras) {
      expect(entry.family.trim(), isNotEmpty, reason: entry.scientificName);
      expect(
        [entry.fr, entry.en, entry.de, entry.it].any((name) => name.trim().isNotEmpty),
        isTrue,
        reason: '${entry.scientificName} sans nom courant',
      );
      final care = careGuide.resolve(entry.scientificName, family: entry.family);
      expect(
        {CareMatch.species, CareMatch.genus, CareMatch.family},
        contains(care.match),
        reason: '${entry.scientificName} tombe sur ${care.match.name}',
      );
    }
  });

  test('encyclopédie : les résolutions déjà présentes dans le cache GBIF restent utilisables', () {
    final modelJson = jsonDecode(File('assets/model/model.json').readAsStringSync()) as Map<String, dynamic>;
    final modelSpecies = (modelJson['species'] as Map<String, dynamic>).values.cast<String>();
    final index = SpeciesIndex.parse(File('assets/species/catalog.tsv').readAsStringSync());
    final encyclopedia = IrisDetailedCatalog.from(
      modelSpecies: modelSpecies,
      index: index,
      targetCount: IrisDetailedCatalog.encyclopediaTargetCount,
    );
    final gbif = jsonDecode(File('tools/plant_dataset/cache/species.json').readAsStringSync()) as Map<String, dynamic>;

    final bad = <String>[];
    for (final entry in encyclopedia.entries) {
      final resolved = gbif[entry.scientificName] as Map<String, dynamic>?;
      if (resolved == null) continue;
      if (resolved['usable'] != true) {
        bad.add('${entry.scientificName}: résolution GBIF inutilisable');
        continue;
      }
      final family = (resolved['family'] as String? ?? '').trim();
      if (family.isNotEmpty && entry.family.trim().isNotEmpty && family != entry.family.trim()) {
        bad.add('${entry.scientificName}: ${entry.family} != GBIF $family');
      }
    }

    expect(bad, isEmpty, reason: bad.join('\n'));
  });
}
