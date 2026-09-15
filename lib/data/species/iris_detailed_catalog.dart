import '../../core/utils/scientific_name.dart';
import '../../core/utils/search_text.dart';
import '../../domain/care/care_guide.dart';
import '../../domain/species/species_info.dart';
import 'catalog_care_guide.dart';
import 'species_catalog.dart';
import 'species_index.dart';

/// Une fiche d'encyclopédie. Les classes d'Iris sont toujours incluses ;
/// l'encyclopédie peut ensuite les compléter avec des espèces hors modèle.
///
/// Les espèces déjà curatées gardent leurs noms et leur catégorie éditoriale.
/// Pour les autres, la famille et les noms viennent du catalogue étendu hors
/// ligne. On n'invente donc ni taxonomie ni traduction pour atteindre le
/// nombre de fiches voulu.
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

  /// [scientificName] permet de garder le nom de la classe du modèle quand
  /// la fiche est celle de l'autre nom de la même plante.
  factory IrisDetailedSpecies.fromCurated(SpeciesCatalogEntry entry, {String? scientificName}) => IrisDetailedSpecies(
        scientificName: scientificName ?? entry.scientificName,
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

  /// Le nom courant dans la langue demandée, ou `null` à défaut — jamais
  /// celui d'une autre langue, comme dans [SpeciesRecord].
  String? vernacularName(String languageCode) {
    final name = switch (languageCode) { 'fr' => fr, 'de' => de, 'it' => it, _ => en };
    final trimmed = name.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Nom d'affichage : le nom courant de la langue demandée, à défaut le
  /// nom scientifique.
  String commonName(String languageCode) => vernacularName(languageCode) ?? scientificName;

  bool matches(String query) {
    final q = foldSpeciesName(query.trim());
    if (q.isEmpty) return true;
    return foldSpeciesName('$scientificName $family $fr $en $de $it').contains(q);
  }
}

/// Catalogue détaillé dont la base est toujours l'ensemble exact des classes
/// Iris. Quand [targetCount] est supérieur au nombre de classes, les fiches
/// curatées hors Iris sont ajoutées en premier, puis les meilleures entrées
/// du catalogue étendu jusqu'au seuil demandé.
class IrisDetailedCatalog {
  const IrisDetailedCatalog(this.entries);

  /// Nombre de fiches affichées dans l'encyclopédie. Cela ne change pas le
  /// nombre de classes qu'Iris sait reconnaître : Iris 8 reste à 1 444.
  static const int encyclopediaTargetCount = 1900;

  factory IrisDetailedCatalog.from({
    required Iterable<String> modelSpecies,
    required SpeciesIndex index,
    int? targetCount,
  }) {
    const careGuide = CatalogCareGuide();
    final curated = <String, SpeciesCatalogEntry>{
      for (final entry in SpeciesCatalog.entries) entry.scientificName.toLowerCase(): entry,
    };
    final indexed = <String, SpeciesRecord>{
      for (final record in index.records) record.scientificName.toLowerCase(): record,
    };
    final seenNames = <String>{};
    final seenAccepted = <String>{};
    final entries = <IrisDetailedSpecies>[];

    String acceptedKey(String scientificName) =>
        acceptedSpeciesName(normalizeScientificName(scientificName)).trim().toLowerCase();

    bool hasDetailedCare(String scientificName, String family) {
      final care = careGuide.resolve(
        scientificName,
        family: family.trim().isEmpty ? null : family,
      );
      return care.match == CareMatch.species || care.match == CareMatch.genus || care.match == CareMatch.family;
    }

    for (final rawName in modelSpecies) {
      final scientificName = rawName.trim();
      if (scientificName.isEmpty) continue;
      final key = scientificName.toLowerCase();
      if (!seenNames.add(key)) continue;

      // La même résolution qu'ailleurs dans l'app : le nom accepté d'abord.
      // Sans lui, « Vriesea splendens » ou « Heptapleurum arboricola »
      // ouvriraient une fiche sans famille alors que l'app connaît la plante
      // sous son autre nom.
      final accepted = acceptedKey(scientificName);
      seenAccepted.add(accepted);
      final entry = curated[key] ?? curated[accepted];
      if (entry != null) {
        entries.add(IrisDetailedSpecies.fromCurated(entry, scientificName: scientificName));
        continue;
      }
      entries.add(IrisDetailedSpecies.fromIndex(scientificName, indexed[key] ?? indexed[accepted]));
    }

    final wanted = targetCount;
    if (wanted != null && wanted > entries.length) {
      // 1. Les fiches déjà écrites à la main mais hors Iris : on garde leur
      // catégorie et leurs noms éditoriaux avant d'aller chercher plus loin.
      // Même ici, une fiche supplémentaire doit être adossée à un profil
      // espèce, genre ou famille : une simple catégorie ne suffit plus.
      for (final entry in SpeciesCatalog.entries) {
        if (entries.length >= wanted) break;
        final key = entry.scientificName.toLowerCase();
        final accepted = acceptedKey(entry.scientificName);
        if (seenNames.contains(key) || seenAccepted.contains(accepted)) continue;
        if (!hasDetailedCare(entry.scientificName, entry.family)) continue;
        seenNames.add(key);
        seenAccepted.add(accepted);
        entries.add(IrisDetailedSpecies.fromCurated(entry));
      }

      // 2. Puis le catalogue étendu. Ses noms viennent de Wikidata mais son
      // ossature genre → famille est celle du GBIF Backbone ; le pipeline
      // écarte notamment les homonymes d'autres règnes. Pour être promue de
      // simple résultat de recherche à fiche d'encyclopédie, une espèce doit
      // aussi avoir une famille, au moins un nom courant, et un vrai profil
      // d'entretien espèce/genre/famille — jamais le profil générique.
      for (final record in index.records) {
        if (entries.length >= wanted) break;
        if (record.family.trim().isEmpty) continue;
        if ([record.fr, record.en, record.de, record.it].every((name) => name.trim().isEmpty)) continue;
        if (!hasDetailedCare(record.scientificName, record.family)) continue;

        final key = record.scientificName.toLowerCase();
        final accepted = acceptedKey(record.scientificName);
        if (seenNames.contains(key) || seenAccepted.contains(accepted)) continue;
        seenNames.add(key);
        seenAccepted.add(accepted);
        entries.add(IrisDetailedSpecies.fromIndex(record.scientificName, record));
      }
    }

    return IrisDetailedCatalog(List<IrisDetailedSpecies>.unmodifiable(entries));
  }

  final List<IrisDetailedSpecies> entries;
}
