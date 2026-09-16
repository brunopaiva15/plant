import 'dart:convert';
import 'dart:io';

import 'package:flora/data/species/catalog_care_guide.dart';
import 'package:flora/data/species/iris_detailed_catalog.dart';
import 'package:flora/data/species/species_index.dart';
import 'package:flutter_test/flutter_test.dart';

/// Le rayon réel de l'encyclopédie, mesuré et figé.
///
/// Les 1 900 fiches n'ont pas la même valeur : treize portent une donnée
/// d'espèce, 1 277 viennent de la famille. Sans mesure commitée, chaque
/// décision sur l'héritage se discute à l'aveugle et une régression ne se
/// voit pas.
///
/// Le test échoue quand `care_coverage_snapshot.json` ne correspond plus. La
/// marche à suivre est de le régénérer et de relire le diff : « ce commit
/// fait passer quarante espèces de genre à famille » doit se voir.
void main() {
  const careGuide = CatalogCareGuide();

  Map<String, Object?> measure() {
    final modelJson = jsonDecode(File('assets/model/model.json').readAsStringSync()) as Map<String, dynamic>;
    final modelSpecies = (modelJson['species'] as Map<String, dynamic>).values.cast<String>().toList();
    final index = SpeciesIndex.parse(File('assets/species/catalog.tsv').readAsStringSync());
    final encyclopedia = IrisDetailedCatalog.from(
      modelSpecies: modelSpecies,
      index: index,
      targetCount: IrisDetailedCatalog.encyclopediaTargetCount,
    );

    final resolution = <String, int>{};
    final toxicity = <String, int>{};
    final profiles = <String, int>{};
    for (final entry in encyclopedia.entries) {
      final care = careGuide.resolve(entry.scientificName, family: entry.family);
      resolution[care.match.name] = (resolution[care.match.name] ?? 0) + 1;
      toxicity[care.toxicity.level.name] = (toxicity[care.toxicity.level.name] ?? 0) + 1;
      final key = '${care.match.name}:${care.matchedOn ?? '(none)'}';
      profiles[key] = (profiles[key] ?? 0) + 1;
    }

    Map<String, int> sorted(Map<String, int> source) => {
          for (final key in source.keys.toList()..sort()) key: source[key]!,
        };

    return {
      'totalSpecies': encyclopedia.entries.length,
      'resolution': sorted(resolution),
      'toxicityByLevel': sorted(toxicity),
      // Les profils qui portent plus de dix espèces. Les seuils de cinquante
      // et de cent se lisent dedans : sept profils, puis trois, au
      // 16 septembre 2026.
      'heavyProfiles': sorted({
        for (final entry in profiles.entries)
          if (entry.value > 10) entry.key: entry.value,
      }),
    };
  }

  test('la couverture réelle correspond à l\'instantané', () {
    const path = 'test/data/care_coverage_snapshot.json';
    final actual = measure();
    // Pour régénérer l'instantané après un changement voulu, lancer ce test
    // avec UPDATE_CARE_COVERAGE=1, puis relire le diff avant de le committer.
    if (Platform.environment['UPDATE_CARE_COVERAGE'] == '1') {
      File(path).writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(actual)}\n');
    }
    final snapshot = jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
    expect(actual, equals(snapshot));
  });

  test('cliquet : la part de la famille ne remonte pas', () {
    final measured = measure();
    final resolution = (measured['resolution']! as Map).cast<String, int>();
    final total = measured['totalSpecies']! as int;
    final share = resolution['family']! / total;
    expect(
      share,
      lessThanOrEqualTo(_familyShareCeiling),
      reason: 'la famille portait ${(_familyShareCeiling * 100).toStringAsFixed(1)} % des fiches, elle en porte ${(share * 100).toStringAsFixed(1)} %',
    );
  });
}

/// La part famille acceptée le jour où ce test a été écrit : 1 277 fiches sur
/// 1 900. Le cliquet empêche de la relever, même en régénérant l'instantané.
const double _familyShareCeiling = 1277 / 1900;
