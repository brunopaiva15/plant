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
  test('catalogue éditorial : 1458 fiches curatées, uniques, avec famille et catégorie', () {
    // 1 453 et non 1 200 : les paliers 1 000 et 1 200 rejouaient 72 espèces
    // déjà curatées, et 59 classes d'Iris que personne ne nommait ont été
    // écrites à la main (`species_catalog_iris_only.dart`). Le lot des plantes
    // d'intérieur en a ajouté 266 : aracées de collection, orchidées,
    // broméliacées, carnivores, caudex, palmiers et fougères d'appartement,
    // dont les noms anglais, allemands et italiens ont été repris du catalogue
    // étendu quand il les connaissait. Iris Indoor en a ajouté cinq de plus :
    // des classes de sa collecte que ni l'un ni l'autre catalogue ne nommait.
    final names = SpeciesCatalog.entries.map((e) => e.scientificName.toLowerCase()).toList();
    expect(SpeciesCatalog.entries, hasLength(1458));
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
    // les fiches qui en sont là.
    //
    // Les premiers paliers tenaient en seize espèces ; les paliers 1000 et
    // 1200 ont ajouté des espèces exotiques — Hoya, Philodendron, Anthurium,
    // Encephalartos — dont aucune source ne donne de nom courant français sûr,
    // et l'inventer serait pire. Le plafond suit ce que le catalogue porte.
    final sansNom = [
      for (final e in SpeciesCatalog.entries)
        if (e.vernacularName('fr') == null) e.scientificName,
    ];
    expect(sansNom, hasLength(lessThanOrEqualTo(65)), reason: sansNom.join(', '));
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
    // Vingt-sept noms moissonnés restent écartés à la main : ils ne sont que
    // le nom latin remaquillé (« Boophane disticha », « Dryopteris tavelii »,
    // « Crataegus ×permixta ») ou une traduction automatique
    // (« Zykadee der Arme », « Erba della tigre e dell'elefante »).
    expect(masquees, hasLength(27), reason: masquees.join(', '));
  });

  test('encyclopédie Iris : exactement les classes du modèle livré', () {
    final modelJson = jsonDecode(File('assets/model/model.json').readAsStringSync()) as Map<String, dynamic>;
    final modelSpecies = (modelJson['species'] as Map<String, dynamic>).values.cast<String>().toList();
    final index = SpeciesIndex.parse(File('assets/species/catalog.tsv').readAsStringSync());
    final detailed = IrisDetailedCatalog.from(modelSpecies: modelSpecies, index: index);
    final names = detailed.entries.map((e) => e.scientificName).toList();

    // Le nombre de classes appartient au modèle livré, pas au test : il suit
    // la fiche du § 0, que `model_facts_test.dart` tient contre `labels.txt`.
    final classes = modelJson['classes'] as int;
    expect(modelSpecies, hasLength(classes));
    expect(modelSpecies.toSet(), hasLength(classes));
    // Les classes du modèle sont toutes dans l'encyclopédie, qui en couvre
    // bien plus depuis que le plafond de 1 900 fiches est tombé.
    expect(names.toSet().length, names.length);
    expect(modelSpecies.toSet().difference(names.toSet()), isEmpty);
    expect(detailed.entries.length, greaterThan(classes));
    expect(detailed.entries.every((e) => e.commonName('fr').trim().isNotEmpty), isTrue);
    // Une fiche sans famille est une fiche à moitié vide.
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
    expect(SpeciesCatalog.search('Basilikum').map((e) => e.scientificName), contains('Ocimum basilicum'));
    expect(SpeciesCatalog.search('lamiaceae').length, greaterThan(5));
    expect(SpeciesCatalog.find('ocimum BASILICUM')?.fr, 'Basilic');
    expect(SpeciesCatalog.byCategory(SpeciesCategory.succulent), everyElement(predicate<SpeciesCatalogEntry>((e) => e.category == SpeciesCategory.succulent)));
  });

  test('catalogue : la recherche classe par pertinence, pas par alphabet', () {
    // « Orchidée » doit remonter Phalaenopsis avant les orchidées obscures,
    // et non se contenter de l'ordre alphabétique.
    final orchid = SpeciesCatalog.search('Orchidée', languageCode: 'fr');
    expect(orchid.first.scientificName, 'Phalaenopsis amabilis');
    expect(orchid.first.commonName('fr'), 'Orchidée papillon');

    // Le nom courant exact (« Monstera ») passe avant les noms qui
    // commencent par la requête.
    final monstera = SpeciesCatalog.search('monstera', languageCode: 'fr');
    expect(monstera.first.scientificName, 'Monstera deliciosa');
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

  test('catalogue : les 150 entrées du palier 800, uniques et catégorisées', () {
    final addedNames = SpeciesCatalog800.entries.map((e) => e.scientificName).toList();

    expect(addedNames, hasLength(150));
    expect(addedNames.toSet().length, addedNames.length);
    expect(SpeciesCatalog.find('Abies bracteata')?.category, SpeciesCategory.tree);
    expect(SpeciesCatalog.find('Salvia microphylla')?.category, SpeciesCategory.flower);
  });

  test('catalogue : les 196 entrées du palier 1000, uniques et catégorisées', () {
    final addedNames = SpeciesCatalog1000.entries.map((e) => e.scientificName).toList();

    expect(addedNames, hasLength(196));
    expect(addedNames.toSet().length, addedNames.length);
    expect(SpeciesCatalog.find('Ranunculus flammula')?.category, SpeciesCategory.flower);
    expect(SpeciesCatalog.find('Parrotia persica')?.category, SpeciesCategory.tree);
    expect(SpeciesCatalog.find('Zingiber officinale')?.category, SpeciesCategory.herb);
    expect(SpeciesCatalog.find('Pistacia vera')?.category, SpeciesCategory.fruit);
    expect(SpeciesCatalog.find('Ranunculus flammula')?.fr, 'Renoncule flammette');
  });

  test('catalogue : les 132 entrées du palier 1200, uniques et catégorisées', () {
    final addedNames = SpeciesCatalog1200.entries.map((e) => e.scientificName).toList();

    expect(addedNames, hasLength(132));
    expect(addedNames.toSet().length, addedNames.length);
    expect(SpeciesCatalog.find('Adiantum capillus-veneris')?.category, SpeciesCategory.indoor);
    expect(SpeciesCatalog.find('Austrocylindropuntia subulata')?.category, SpeciesCategory.succulent);
    expect(SpeciesCatalog.find('Arctium tomentosum')?.category, SpeciesCategory.herb);
    expect(SpeciesCatalog.find('Avena sativa')?.category, SpeciesCategory.vegetable);
    expect(SpeciesCatalog.find('Aronia melanocarpa')?.category, SpeciesCategory.fruit);
    expect(SpeciesCatalog.find('Akebia quinata')?.category, SpeciesCategory.flower);
    expect(SpeciesCatalog.find('Aesculus × carnea')?.category, SpeciesCategory.tree);
    expect(SpeciesCatalog.find('Akebia quinata')?.fr, 'Akébie à cinq feuilles');
  });

  // Trois tests affirmaient « les 150 entrées du palier 800 sont des classes
  // Iris 8 » : les paliers avaient été curatés depuis la liste des classes du
  // modèle d'alors. Iris Indoor n'expose plus que ce qui pousse à l'intérieur,
  // et l'affirmation est devenue fausse par construction — c'est la décision
  // du § 13.3 de `docs/09`, pas un accident.
  //
  // Une fiche que le modèle ne nomme pas n'est donc pas un défaut : elle tombe
  // sur la réponse de genre et le repli Pl@ntNet. Mais le nombre doit rester
  // visible, et ne pas remonter sans qu'on l'ait décidé.
  test('catalogue : ce que le modèle livré ne sait pas nommer, compté', () {
    final modelJson = jsonDecode(File('assets/model/model.json').readAsStringSync()) as Map<String, dynamic>;
    final modelSpecies = (modelJson['species'] as Map<String, dynamic>).values
        .cast<String>()
        .map((name) => name.toLowerCase())
        .toSet();
    final curatees = SpeciesCatalog.entries.map((e) => e.scientificName).toList();
    final muettes = curatees.where((name) => !modelSpecies.contains(name.toLowerCase())).toList();

    expect(curatees, hasLength(1458));
    expect(
      muettes,
      hasLength(lessThanOrEqualTo(_fichesSansClasse)),
      reason: 'le modèle nommait ${curatees.length - _fichesSansClasse} fiches curatées '
          'sur ${curatees.length}, il en nomme ${curatees.length - muettes.length}',
    );
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
    expect(SpeciesCatalogIrisOnly.entries, hasLength(64));
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

  test('résolution : un synonyme retrouve la fiche de son nom accepté', () {
    // Le modèle et GBIF rendent « Hesperocyparis macrocarpa » ; le catalogue
    // ne porte que « Cupressus macrocarpa ». Sans ce détour, la catégorie
    // reste introuvable et la plante est classée d'intérieur.
    expect(SpeciesCatalog.find('Hesperocyparis macrocarpa'), isNull);
    expect(SpeciesCatalog.findAccepted('Hesperocyparis macrocarpa')?.category, SpeciesCategory.tree);
    expect(SpeciesCatalog.findAccepted('Heptapleurum arboricola')?.scientificName, 'Schefflera arboricola');
    // Le nom déjà accepté et la casse passent sans s'abîmer.
    expect(SpeciesCatalog.findAccepted('cupressus macrocarpa')?.scientificName, 'Cupressus macrocarpa');
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

/// Mesuré sur Iris Indoor : 1 139 des 1 458 fiches curatées n'ont pas de classe
/// dans le modèle livré, qui en nomme 319. Le plafond n'interdit pas d'en
/// perdre — il interdit d'en perdre sans le voir.
const int _fichesSansClasse = 1139;
