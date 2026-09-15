import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flora/data/services/gbif_species_service.dart';
import 'package:flora/core/utils/scientific_name.dart';
import 'package:flora/data/species/catalog_800/species_catalog_800.dart';
import 'package:flora/data/species/catalog_1000/species_catalog_1000.dart';
import 'package:flora/data/species/catalog_1200/species_catalog_1200.dart';
import 'package:flora/data/species/iris_detailed_catalog.dart';
import 'package:flora/data/species/species_catalog.dart';
import 'package:flora/data/species/species_catalog_iris_only.dart';
import 'package:flora/data/species/species_index.dart';
import 'package:flora/domain/species/species_info.dart';

void main() {
  test('catalogue éditorial : 1187 fiches curatées, uniques, avec famille et catégorie', () {
    // 1 187 et non 1 200 : les paliers 1 000 et 1 200 rejouaient 72 espèces
    // déjà curatées, et 59 classes d'Iris que personne ne nommait ont été
    // écrites à la main (`species_catalog_iris_only.dart`).
    final names = SpeciesCatalog.entries.map((e) => e.scientificName.toLowerCase()).toList();
    expect(SpeciesCatalog.entries, hasLength(1187));
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

  test('catalogue éditorial : presque toutes les fiches ont un nom français', () {
    // Les quatre assertions ci-dessus ne disent rien : faute de nom, une
    // entrée prend le nom scientifique, qui n'est pas vide. Celle-ci compte
    // les fiches qui en sont là. Seize espèces restent sans nom courant
    // français sûr — aucune source n'en donne, et l'inventer serait pire.
    final sansNom = [
      for (final e in SpeciesCatalog.entries)
        if (e.vernacularName('fr') == null) e.scientificName,
    ];
    expect(sansNom, hasLength(lessThanOrEqualTo(16)), reason: sansNom.join(', '));
  });

  test('catalogue éditorial : une entrée muette ne masque pas le catalogue étendu', () {
    // Une entrée écrite sans nom prend la valeur du nom scientifique dans les
    // quatre langues, et couvre alors ce que le catalogue étendu sait dire.
    // Les deux paliers générés l'ont fait pour 296 fiches.
    final index = SpeciesIndex.parse(File('assets/species/catalog.tsv').readAsStringSync());
    final parNom = {for (final r in index.records) r.scientificName.toLowerCase(): r};
    final masquees = <String>[];
    for (final e in SpeciesCatalog.entries) {
      final record = parNom[e.scientificName.toLowerCase()];
      if (record == null) continue;
      for (final lang in const ['fr', 'en', 'de', 'it']) {
        final connu = record.vernacularName(lang);
        if (connu != null && e.vernacularName(lang) == null) {
          masquees.add('${e.scientificName} ($lang : « $connu »)');
        }
      }
    }
    // Quatorze noms moissonnés restent écartés à la main : ils ne sont que le
    // nom latin remaquillé (« Boophane disticha », « Dryopteris ×tavelii »)
    // ou une traduction automatique (« Zykadee der Arme »).
    expect(masquees, hasLength(14), reason: masquees.join(', '));
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
    // Une fiche sans famille est une fiche à moitié vide : 63 classes en
    // étaient là, absentes des deux catalogues.
    expect(detailed.entries.where((e) => e.family.trim().isEmpty), isEmpty);

    // Le nom affiché est celui de la langue lue, ou le nom scientifique —
    // jamais celui d'une autre langue : « Japanische Faserbanane » en tête
    // d'une liste française se lit comme une erreur.
    for (final e in detailed.entries) {
      for (final lang in const ['fr', 'en', 'de', 'it']) {
        final name = switch (lang) { 'fr' => e.fr, 'de' => e.de, 'it' => e.it, _ => e.en };
        final own = name.trim();
        expect(e.commonName(lang), own.isEmpty ? e.scientificName : own, reason: '${e.scientificName} en $lang');
      }
    }
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

  test('catalogue : les 196 entrées du palier 1000 sont des classes Iris 8', () {
    final modelJson = jsonDecode(File('assets/model/model.json').readAsStringSync()) as Map<String, dynamic>;
    final modelSpecies = (modelJson['species'] as Map<String, dynamic>).values.cast<String>().toSet();
    final addedNames = SpeciesCatalog1000.entries.map((e) => e.scientificName).toList();

    expect(modelJson['classes'], 1444);
    expect(addedNames, hasLength(196));
    expect(addedNames.toSet().length, addedNames.length);
    expect(addedNames.where((name) => !modelSpecies.contains(name)), isEmpty);
    expect(SpeciesCatalog.find('Ranunculus flammula')?.category, SpeciesCategory.flower);
    expect(SpeciesCatalog.find('Parrotia persica')?.category, SpeciesCategory.tree);
    expect(SpeciesCatalog.find('Zingiber officinale')?.category, SpeciesCategory.herb);
    expect(SpeciesCatalog.find('Pistacia vera')?.category, SpeciesCategory.fruit);
    expect(SpeciesCatalog.find('Ranunculus flammula')?.fr, 'Renoncule flammette');
  });

  test('catalogue : les 132 entrées du palier 1200 sont des classes Iris 8', () {
    final modelJson = jsonDecode(File('assets/model/model.json').readAsStringSync()) as Map<String, dynamic>;
    final modelSpecies = (modelJson['species'] as Map<String, dynamic>).values.cast<String>().toSet();
    final addedNames = SpeciesCatalog1200.entries.map((e) => e.scientificName).toList();

    expect(modelJson['classes'], 1444);
    expect(addedNames, hasLength(132));
    expect(addedNames.toSet().length, addedNames.length);
    expect(addedNames.where((name) => !modelSpecies.contains(name)), isEmpty);
    expect(SpeciesCatalog.find('Adiantum capillus-veneris')?.category, SpeciesCategory.indoor);
    expect(SpeciesCatalog.find('Austrocylindropuntia subulata')?.category, SpeciesCategory.succulent);
    expect(SpeciesCatalog.find('Arctium tomentosum')?.category, SpeciesCategory.herb);
    expect(SpeciesCatalog.find('Avena sativa')?.category, SpeciesCategory.vegetable);
    expect(SpeciesCatalog.find('Aronia melanocarpa')?.category, SpeciesCategory.fruit);
    expect(SpeciesCatalog.find('Akebia quinata')?.category, SpeciesCategory.flower);
    expect(SpeciesCatalog.find('Aesculus × carnea')?.category, SpeciesCategory.tree);
    expect(SpeciesCatalog.find('Akebia quinata')?.fr, 'Akébie à cinq feuilles');
  });

  test('catalogue : aucun palier ne rejoue une espèce déjà curatée', () {
    // Les deux derniers paliers ont été écrits sans regarder les précédents :
    // 72 espèces y revenaient, sans nom cette fois. La liste étant parcourue
    // dans l'ordre par `find` mais indexée par un `Map` ailleurs, la même
    // plante s'appelait « Rose du désert » ici et « Adenium obesum » là.
    final vus = <String>{};
    final rejouees = <String>[];
    for (final e in SpeciesCatalog.entries) {
      if (!vus.add(e.scientificName.toLowerCase())) rejouees.add(e.scientificName);
    }
    expect(rejouees, isEmpty);
    expect(SpeciesCatalog.find('Adenium obesum')?.fr, 'Rose du désert');
    expect(SpeciesCatalog.find('Adonis vernalis')?.fr, 'Adonis de printemps');
  });

  test("catalogue : les classes qu'aucun catalogue ne nommait ont leur fiche", () {
    // Le moissonnage Wikidata a manqué le genre Euphorbia en entier, et des
    // arbres aussi communs que le chêne-liège : 63 classes du modèle
    // n'avaient ni famille ni nom, dans aucune des quatre langues.
    expect(SpeciesCatalogIrisOnly.entries, hasLength(59));
    expect(SpeciesCatalog.find('Quercus suber')?.fr, 'Chêne-liège');
    expect(SpeciesCatalog.find('Quercus suber')?.family, 'Fagaceae');
    expect(SpeciesCatalog.find('Robinia pseudoacacia')?.de, 'Gewöhnliche Robinie');
    expect(SpeciesCatalog.find('Euphorbia tirucalli')?.category, SpeciesCategory.succulent);
    expect(SpeciesCatalog.find('Pinus nigra')?.it, 'Pino nero');

    // Les quatre dernières passent par la table des noms acceptés plutôt que
    // par une fiche à elles : l'app les connaît déjà sous leur autre nom.
    expect(SpeciesCatalog.find('Vriesea splendens'), isNull);
    expect(acceptedSpeciesName('Vriesea splendens'), 'Lutheria splendens');
    expect(acceptedSpeciesName('Heptapleurum arboricola'), 'Schefflera arboricola');
    expect(acceptedSpeciesName('Anemonoides nemorosa'), 'Anemone nemorosa');
    expect(acceptedSpeciesName('Sedum rubrotinctum'), 'Sedum × rubrotinctum');
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
