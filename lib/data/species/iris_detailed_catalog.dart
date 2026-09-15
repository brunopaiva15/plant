import '../../core/utils/search_text.dart';
import '../../domain/species/species_info.dart';
import 'species_catalog.dart';
import 'species_index.dart';

/// Une fiche d'encyclopédie adossée à une classe du modèle Iris.
///
/// Les espèces déjà curatées gardent leurs noms et leur catégorie éditoriale.
/// Pour les autres classes Iris, la famille et les noms viennent du catalogue
/// étendu hors ligne. On n'invente donc ni taxonomie ni traduction pour
/// combler l'écart entre le catalogue curaté et le modèle embarqué.
class IrisDetailedSpecies {
  const IrisDetailedSpecies({
    required this.scientificName,
    required this.family,
    required this.fr,
    required this.en,
    required this.de,
    required this.it,
    this.category,
  });

  factory IrisDetailedSpecies.fromCurated(SpeciesCatalogEntry entry) => IrisDetailedSpecies(
        scientificName: entry.scientificName,
        family: entry.family,
        fr: entry.fr,
        en: entry.en,
        de: entry.de,
        it: entry.it,
        category: entry.category,
      );

  factory IrisDetailedSpecies.fromIndex(String scientificName, SpeciesRecord? record) => IrisDetailedSpecies(
        scientificName: scientificName,
        family: record?.family ?? '',
        fr: record?.fr ?? '',
        en: record?.en ?? '',
        de: record?.de ?? '',
        it: record?.it ?? '',
      );

  final String scientificName;
  final String family;
  final String fr;
  final String en;
  final String de;
  final String it;
  final SpeciesCategory? category;

  String commonName(String languageCode) {
    final ordered = switch (languageCode) {
      'fr' => [fr, en, de, it],
      'de' => [de, en, fr, it],
      'it' => [it, en, fr, de],
      _ => [en, fr, de, it],
    };
    for (final value in ordered) {
      if (value.trim().isNotEmpty) return value;
    }
    return scientificName;
  }

  bool matches(String query) {
    final q = foldSpeciesName(query.trim());
    if (q.isEmpty) return true;
    return foldSpeciesName('$scientificName $family $fr $en $de $it').contains(q);
  }
}

/// Vue détaillée alignée exactement sur les classes du modèle Iris.
///
/// Le catalogue curaté reste la source premium pour ses espèces ; les classes
/// Iris qui n'y figurent pas sont enrichies par [SpeciesIndex]. L'ordre du
/// modèle est conservé et les doublons éventuels du JSON sont éliminés.
class IrisDetailedCatalog {
  const IrisDetailedCatalog(this.entries);

  factory IrisDetailedCatalog.from({
    required Iterable<String> modelSpecies,
    required SpeciesIndex index,
  }) {
    final curated = <String, SpeciesCatalogEntry>{
      for (final entry in SpeciesCatalog.entries) entry.scientificName.toLowerCase(): entry,
    };
    final indexed = <String, SpeciesRecord>{
      for (final record in index.records) record.scientificName.toLowerCase(): record,
    };
    final seen = <String>{};
    final entries = <IrisDetailedSpecies>[];

    for (final rawName in modelSpecies) {
      final scientificName = rawName.trim();
      if (scientificName.isEmpty) continue;
      final key = scientificName.toLowerCase();
      if (!seen.add(key)) continue;

      final entry = curated[key];
      if (entry != null) {
        entries.add(IrisDetailedSpecies.fromCurated(entry));
        continue;
      }
      entries.add(IrisDetailedSpecies.fromIndex(scientificName, indexed[key]));
    }

    return IrisDetailedCatalog(List<IrisDetailedSpecies>.unmodifiable(entries));
  }

  final List<IrisDetailedSpecies> entries;
}
