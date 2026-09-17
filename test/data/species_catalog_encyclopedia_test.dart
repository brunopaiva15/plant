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

  test('encyclopédie : toutes les fiches qui ont un profil, dont les 1444 classes Iris', () {
    final modelJson = jsonDecode(File('assets/model/model.json').readAsStringSync()) as Map<String, dynamic>;
    final modelSpecies = (modelJson['species'] as Map<String, dynamic>).values.cast<String>().toList();
    final modelNames = modelSpecies.map((e) => e.toLowerCase()).toSet();
    final modelAccepted = modelSpecies
        .map((e) => acceptedSpeciesName(normalizeScientificName(e)).toLowerCase())
        .toSet();
    final index = SpeciesIndex.parse(File('assets/species/catalog.tsv').readAsStringSync());

    final encyclopedia = IrisDetailedCatalog.from(
      modelSpecies: modelSpecies,
      index: index,
    );

    final names = encyclopedia.entries.map((e) => e.scientificName.toLowerCase()).toList();
    final extras = encyclopedia.entries.where((e) => !modelNames.contains(e.scientificName.toLowerCase())).toList();
    final extraAccepted = extras
        .map((e) => acceptedSpeciesName(normalizeScientificName(e.scientificName)).toLowerCase())
        .toList();

    expect(modelJson['classes'], 1444);
    // Sans plafond : toutes les classes Iris, toutes les fiches curatées qui
    // ont un profil, puis tout le catalogue étendu qui en a un aussi.
    expect(encyclopedia.entries, hasLength(33344));
    expect(names.toSet().length, names.length, reason: 'noms scientifiques dupliqués');
    expect(modelNames.difference(names.toSet()), isEmpty);
    expect(extras, hasLength(31900));
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
    );
    final gbif = jsonDecode(File('tools/plant_dataset/cache/species.json').readAsStringSync()) as Map<String, dynamic>;

    // Divergences connues entre le catalogue et le cache GBIF, revues à la
    // main : noms de famille encore valides mais moins récents que ceux du
    // backbone GBIF (APG contre GBIF), et onze hybrides ou synonymes que
    // GBIF ne résout pas — Sorbus aria est Aria edulis, Chenopodium rubrum
    // est Oxybasis rubra, les agrumes jabara et unshiu n'ont pas de nom
    // accepté stable. Le test reste un garde-fou pour tout le reste.
    const famillesEquivalentes = <String, String>{
      'Phacelia tanacetifolia': 'Hydrophyllaceae',
      'Sambucus ebulus': 'Viburnaceae',
      'Sambucus nigra': 'Viburnaceae',
      'Sambucus racemosa': 'Viburnaceae',
      'Viburnum rhytidophyllum': 'Viburnaceae',
      'Viburnum tinus': 'Viburnaceae',
      'Viburnum × bodnantense': 'Viburnaceae',
    };
    const sansResolutionGbif = <String>{
      'Cymbidium hybridum',
      'Allium porrum',
      'Prunus dulcis',
      'Rosa × hybrida',
      'Chenopodium rubrum',
      'Citrus jabara',
      'Citrus unshiu',
      'Desmodium elegans',
      'Piper methysticum',
      'Sorbus aria',
      'Sorbus intermedia',
    };

    final bad = <String>[];
    for (final entry in encyclopedia.entries) {
      final resolved = gbif[entry.scientificName] as Map<String, dynamic>?;
      if (resolved == null) continue;
      if (resolved['usable'] != true) {
        if (!sansResolutionGbif.contains(entry.scientificName)) {
          bad.add('${entry.scientificName}: résolution GBIF inutilisable');
        }
        continue;
      }
      final family = (resolved['family'] as String? ?? '').trim();
      if (family.isNotEmpty && entry.family.trim().isNotEmpty && family != entry.family.trim()) {
        if (famillesEquivalentes[entry.scientificName] != family) {
          bad.add('${entry.scientificName}: ${entry.family} != GBIF $family');
        }
      }
    }

    expect(bad, isEmpty, reason: bad.join('\n'));
  });
}
