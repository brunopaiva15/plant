import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `assets/model/model.json` fait foi, et la documentation ne le recopie qu'à
/// un seul endroit : la fiche du § 0 de `docs/09-plant-recognition.md`.
///
/// Ce test tient les deux ensemble. Livrer un modèle réentraîné sans toucher à
/// la fiche fait désormais échouer la suite, plutôt que de laisser la
/// documentation annoncer pendant des mois un modèle qui n'est plus là — c'est
/// exactement ce qui était arrivé à l'Iris 7, resté écrit partout après la
/// livraison de l'Iris 8.
///
/// Ailleurs dans les documents, un numéro **date une mesure** et ne bouge
/// pas : « l'Iris 7 rendait 0,5961 » restera vrai. Seules les phrases qui
/// nomment le modèle *livré* sont vérifiées ici, et elles sont listées dans
/// `etats`, en bas de fichier.
void main() {
  final meta = jsonDecode(File('assets/model/model.json').readAsStringSync()) as Map<String, dynamic>;
  final version = meta['version'] as String;

  /// La valeur d'un chemin pointé : `metrics.captive.top1`.
  Object? at(String path) {
    Object? node = meta;
    for (final key in path.split('.')) {
      if (node is! Map<String, dynamic>) return null;
      node = node[key];
    }
    return node;
  }

  const doc = 'docs/09-plant-recognition.md';
  const ouvre = '<!-- fiche:model.json -->';
  const ferme = '<!-- /fiche -->';

  /// Les lignes de la fiche : chemin dans `model.json` → valeur telle qu'elle
  /// est écrite dans le tableau.
  Map<String, String> fiche() {
    final texte = File(doc).readAsStringSync();
    final debut = texte.indexOf(ouvre);
    final fin = texte.indexOf(ferme);
    expect(debut, isNonNegative, reason: '$doc a perdu la fiche du modèle ($ouvre)');
    expect(fin, greaterThan(debut), reason: '$doc a perdu la fin de la fiche ($ferme)');
    final lignes = <String, String>{};
    for (final ligne in texte.substring(debut + ouvre.length, fin).split('\n')) {
      final m = RegExp(r'^\|\s*`([a-z0-9_.]+)`\s*\|([^|]*)\|').firstMatch(ligne.trim());
      if (m != null) lignes[m.group(1)!] = m.group(2)!.trim().replaceAll('`', '');
    }
    return lignes;
  }

  // Ce que la fiche doit porter, quoi qu'il arrive : le numéro affiché, ce que
  // le modèle sait, ce qu'il pèse et ce qu'il vaut.
  const obligatoires = [
    'version',
    'architecture',
    'classes',
    'input_size',
    'bytes',
    'sha256',
    'metrics.top1',
    'metrics.top3',
    'metrics.captive.top1',
  ];

  test('la fiche du § 0 dit ce que le modèle livré annonce', () {
    final lignes = fiche();
    expect(lignes, isNotEmpty, reason: 'aucune ligne lue dans la fiche de $doc');

    for (final chemin in obligatoires) {
      expect(lignes.keys, contains(chemin), reason: 'la fiche de $doc ne porte plus `$chemin`');
    }

    lignes.forEach((chemin, ecrit) {
      final valeur = at(chemin);
      expect(valeur, isNotNull, reason: '`$chemin` est dans la fiche de $doc mais plus dans model.json');

      if (valeur is num) {
        // Le tableau écrit les nombres en français : espace pour les milliers,
        // virgule pour les décimales.
        final lu = num.tryParse(ecrit.replaceAll(' ', '').replaceAll(',', '.'));
        expect(lu, isNotNull, reason: '`$chemin` : « $ecrit » n\'est pas un nombre');
        expect((lu! - valeur).abs() < 1e-9, isTrue,
            reason: '`$chemin` : la fiche dit « $ecrit », model.json dit « $valeur »');
      } else if (ecrit.endsWith('…')) {
        // Une empreinte ne se recopie pas en entier : la fiche en donne la tête.
        final tete = ecrit.substring(0, ecrit.length - 1);
        expect('$valeur'.startsWith(tete), isTrue,
            reason: '`$chemin` : la fiche dit « $ecrit », model.json dit « $valeur »');
      } else {
        expect(ecrit, '$valeur', reason: '`$chemin` : la fiche et model.json ne disent pas la même chose');
      }
    });
  });

  test('la fiche recopie la taille du fichier de poids, pas une autre', () {
    final poids = File('assets/model/plants.tflite');
    expect(poids.existsSync(), isTrue, reason: 'assets/model/plants.tflite manque');
    expect(poids.lengthSync(), meta['bytes'], reason: 'model.json annonce une taille que le .tflite n\'a pas');
  });

  test('le compte de classes est celui de labels.txt', () {
    final labels = File('assets/model/labels.txt')
        .readAsLinesSync()
        .where((l) => l.trim().isNotEmpty)
        .length;
    expect(labels, meta['classes'], reason: 'model.json et labels.txt ne comptent pas les mêmes classes');
  });

  // Les phrases qui nomment le modèle *livré*. Partout ailleurs, un numéro
  // appartient à la version qui l'a mesuré et ne doit pas bouger.
  final etats = <String, RegExp>{
    'docs/09-plant-recognition.md': RegExp(r"\*\*Iris " + version + r"\*\* que l'application nomme à l'écran"),
    'docs/00-roadmap.md': RegExp(r"le modèle embarqué en est à \*\*Iris " + version + r"\*\*"),
    'docs/10-entrainer-sur-son-poste.md':
        RegExp(r"La version que l'application livre aujourd'hui est l'\*\*Iris " + version + r"\*\*"),
  };

  test('les documents qui nomment le modèle livré nomment celui qui est livré', () {
    etats.forEach((chemin, attendu) {
      final texte = File(chemin).readAsStringSync();
      expect(attendu.hasMatch(texte), isTrue,
          reason: '$chemin ne dit plus que le modèle livré est Iris $version — '
              'model.json fait foi, c\'est le document qui se met à jour');
    });
  });
}
