import 'dart:io';

import 'package:flora/core/utils/search_text.dart';
import 'package:flora/data/species/species_index.dart';
import 'package:flutter_test/flutter_test.dart';

/// Vérifie l'actif réellement embarqué, pas un extrait de test : c'est lui
/// que l'application charge, et une régénération ratée doit se voir ici.
void main() {
  final file = File('assets/species/catalog.tsv');
  if (!file.existsSync() || file.lengthSync() == 0) {
    // L'actif se régénère avec tool/harvest_species.py : on n'échoue pas
    // une machine qui ne l'a pas encore construit.
    test('catalogue étendu absent — régénérer avec tool/harvest_species.py', () {}, skip: true);
    return;
  }

  final index = SpeciesIndex.parse(file.readAsStringSync());

  test('le catalogue est substantiel', () {
    expect(index.records.length, greaterThan(10000));
  });

  test('chaque ligne a un nom binomial et au moins un nom courant', () {
    for (final r in index.records.take(2000)) {
      expect(r.scientificName.split(' ').length, greaterThanOrEqualTo(2), reason: r.scientificName);
      expect([r.fr, r.en, r.de, r.it].any((n) => n.isNotEmpty), isTrue, reason: r.scientificName);
    }
  });

  test('pas de doublon de nom scientifique', () {
    final seen = <String>{};
    final dupes = <String>[];
    for (final r in index.records) {
      if (!seen.add(r.scientificName.toLowerCase())) dupes.add(r.scientificName);
    }
    expect(dupes, isEmpty, reason: dupes.take(5).join(', '));
  });

  group('espèces attendues', () {
    void expectFound(String query, String scientificName) {
      final hit = index.search(query).where((r) => r.scientificName == scientificName);
      expect(hit, isNotEmpty, reason: '« $query » devrait trouver $scientificName');
    }

    test('l\'edelweiss se trouve par son nom courant', () {
      expectFound('edelweiss', 'Leontopodium nivale');
    });

    test('en allemand et en italien aussi', () {
      expect(index.search('Edelweiß'), isNotEmpty);
      expect(index.search('stella alpina'), isNotEmpty);
    });

    test('quelques classiques du jardin', () {
      expectFound('gentiane jaune', 'Gentiana lutea');
      expectFound('coquelicot', 'Papaver rhoeas');
      expectFound('muguet', 'Convallaria majalis');
    });
  });

  test("aucun homonyme d'un autre règne", () {
    // Un nom de genre n'est pas unique entre les règnes : « Batis » est un
    // arbuste et un gobe-mouches, « Oenanthe » une ombellifère et un traquet.
    // Moissonné par nom de genre seul, le catalogue avait accueilli des
    // oiseaux, des poissons et des papillons. Quelques-uns servent de témoins.
    const animals = [
      'Batis capensis', // gobe-mouches du Cap
      'Oenanthe oenanthe', // traquet motteux
      'Glaucidium passerinum', // chevêchette d'Europe
      'Coris julis', // girelle
      'Morelia viridis', // python vert
      'Pieris brassicae', // piéride du chou
      'Morus bassanus', // fou de Bassan
      'Prunella modularis', // accenteur mouchet
      'Linaria cannabina', // linotte mélodieuse
      'Arenaria interpres', // tournepierre à collier
    ];
    final present = animals.where((n) => index.find(n) != null).toList();
    expect(present, isEmpty, reason: present.join(', '));
  });

  test('les noms courants ne sont pas de simples binômes latins', () {
    // Un nom vernaculaire qui répète le nom scientifique n'apporte rien :
    // le filtre du générateur doit les avoir écartés.
    final leaked = index.records.where((r) {
      final fr = foldSpeciesName(r.fr);
      return fr.isNotEmpty && fr == foldSpeciesName(r.scientificName);
    }).toList();
    expect(leaked, isEmpty, reason: leaked.take(5).map((r) => r.scientificName).join(', '));
  });

  test('la recherche reste instantanée sur le catalogue complet', () {
    final watch = Stopwatch()..start();
    for (final q in ['edel', 'gentia', 'erable', 'rosa', 'thym', 'muguet']) {
      index.search(q, limit: 30);
    }
    watch.stop();
    // Une frappe ne doit jamais coûter une image : 6 recherches en moins de
    // 300 ms laissent une marge confortable même sur un téléphone lent.
    expect(watch.elapsedMilliseconds, lessThan(300), reason: '${watch.elapsedMilliseconds} ms');
  });
}
