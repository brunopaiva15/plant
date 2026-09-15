import 'dart:convert';

import '../../core/utils/search_text.dart';
import '../../domain/species/species_info.dart';

/// Une espèce du catalogue étendu, moissonnée dans Wikidata.
///
/// Contrairement aux [SpeciesCatalogEntry] triés à la main, ces entrées n'ont
/// pas de catégorie : elles servent à la recherche, pas au parcours par thème.
class SpeciesRecord {
  const SpeciesRecord({
    required this.scientificName,
    required this.family,
    required this.fr,
    required this.en,
    required this.de,
    required this.it,
    required this.alternates,
    required this.haystack,
    required this.primary,
  });

  final String scientificName;
  final String family;
  final String fr;
  final String en;
  final String de;
  final String it;

  /// Autres noms connus, toutes langues confondues. Cherchables, jamais
  /// affichés : « Édelweiß » doit trouver l'espèce sans encombrer la liste.
  final List<String> alternates;

  /// Tous les noms concaténés et normalisés, prêts pour la comparaison.
  final String haystack;

  /// Les seuls noms affichés, normalisés et encadrés de barres. Sert au
  /// classement : un nom principal doit primer sur un synonyme obscur.
  final String primary;

  /// Le nom courant dans la langue demandée, ou `null` quand l'espèce n'en
  /// a pas dans cette langue.
  ///
  /// Jamais le nom d'une autre langue : dans une application en français,
  /// « Japanische Faserbanane » se lit comme une erreur, pas comme un
  /// secours. Beaucoup d'espèces n'ont de nom courant qu'en anglais, et
  /// les montrer sous leur nom scientifique reste juste dans les quatre
  /// langues.
  String? vernacularName(String languageCode) {
    final name = switch (languageCode) { 'fr' => fr, 'de' => de, 'it' => it, _ => en };
    final trimmed = name.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Nom d'affichage : le nom courant de la langue demandée, à défaut le
  /// nom scientifique.
  String commonName(String languageCode) => capitalizeSpeciesDisplayName(vernacularName(languageCode) ?? scientificName);

  SpeciesSuggestion toSuggestion(String languageCode) {
    final vernacular = vernacularName(languageCode);
    return SpeciesSuggestion(
      key: 0,
      scientificName: scientificName,
      family: family.isEmpty ? null : family,
      commonName: vernacular == null ? null : capitalizeSpeciesDisplayName(vernacular),
    );
  }
}

/// Catalogue étendu : des dizaines de milliers d'espèces et leurs noms
/// courants, disponibles hors ligne.
///
/// Le fichier est un TSV chargé à la demande, jamais au démarrage : il ne
/// sert que dans le sélecteur d'espèces.
class SpeciesIndex {
  SpeciesIndex(this.records);

  final List<SpeciesRecord> records;

  static SpeciesIndex parse(String tsv) {
    final records = <SpeciesRecord>[];
    for (final line in const LineSplitter().convert(tsv)) {
      if (line.isEmpty) continue;
      final cells = line.split('\t');
      if (cells.length < 6) continue;
      final alternates = cells.length > 6 && cells[6].isNotEmpty ? cells[6].split('~') : const <String>[];
      final shown = [cells[2], cells[3], cells[4], cells[5]].where((s) => s.isNotEmpty).toList();
      records.add(SpeciesRecord(
        scientificName: cells[0],
        family: cells[1],
        fr: cells[2],
        en: cells[3],
        de: cells[4],
        it: cells[5],
        alternates: alternates,
        haystack: foldSpeciesName([cells[0], ...shown, ...alternates].join(' ')),
        // Encadré de barres : « |coquelicot| » ne se confond pas avec
        // « coquelicot bleu de l'Himalaya ».
        primary: '|${shown.map(foldSpeciesName).join('|')}|',
      ));
    }
    return SpeciesIndex(records);
  }

  /// Résultats classés, du plus évident au plus lointain :
  /// 1. un nom affiché est exactement la requête (« coquelicot ») ;
  /// 2. un nom affiché commence par la requête ;
  /// 3. n'importe quel nom, synonymes compris, commence par la requête ;
  /// 4. la requête apparaît quelque part.
  List<SpeciesRecord> search(String query, {int limit = 60, Set<String> exclude = const {}}) {
    final q = foldSpeciesName(query.trim());
    if (q.isEmpty) return const [];
    final buckets = List.generate(4, (_) => <SpeciesRecord>[]);
    for (final r in records) {
      if (exclude.contains(r.scientificName.toLowerCase())) continue;
      final at = r.haystack.indexOf(q);
      if (at == -1) continue;
      final rank = r.primary.contains('|$q|')
          ? 0
          : r.primary.contains('|$q')
              ? 1
              : (at == 0 || r.haystack[at - 1] == ' ')
                  ? 2
                  : 3;
      buckets[rank].add(r);
      // Assez de résultats parfaits : inutile de balayer le reste.
      if (buckets[0].length >= limit) break;
    }
    final out = [for (final b in buckets) ...b];
    return out.length > limit ? out.sublist(0, limit) : out;
  }

  SpeciesRecord? find(String scientificName) {
    final n = scientificName.trim().toLowerCase();
    for (final r in records) {
      if (r.scientificName.toLowerCase() == n) return r;
    }
    return null;
  }
}
