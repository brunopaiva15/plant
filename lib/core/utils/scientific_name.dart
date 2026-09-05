/// Noms scientifiques : la même forme canonique que l'outil de dataset
/// (`tools/plant_dataset/plant_dataset/taxonomy.py`). Les deux doivent
/// rester d'accord : c'est cette clé qui relie une classe du modèle, un
/// résultat Pl@ntNet et une entrée du catalogue.
///
/// « Genre épithète », sans auteur ni année, signe d'hybride conservé
/// (« Citrus × aurantium »), rangs infraspécifiques abrégés
/// (« Ficus benjamina var. nuda »), cultivar entre apostrophes simples.
library;

import 'search_text.dart';

const _hybrid = '×';
const _ranks = {'subsp', 'ssp', 'var', 'f', 'forma', 'cv', 'subvar'};

String normalizeScientificName(String raw) {
  final s = raw.replaceAll('_', ' ').trim().replaceAll(RegExp(r'\s+'), ' ');
  if (s.isEmpty) return '';
  final out = <String>[];
  var expectingEpithet = false;
  final words = s.split(' ');
  for (var i = 0; i < words.length; i++) {
    final token = words[i].replaceAll(RegExp(r'^[,;]+|[,;]+$'), '');
    if (token.isEmpty) continue;
    if (i == 0) {
      out.add(token.substring(0, 1).toUpperCase() + token.substring(1).toLowerCase());
      expectingEpithet = true;
      continue;
    }
    final low = token.toLowerCase().replaceAll(RegExp(r'\.+$'), '');
    if ((token == 'x' || token == 'X' || token == _hybrid) && expectingEpithet) {
      out.add(_hybrid);
      continue;
    }
    if (_ranks.contains(low)) {
      out.add('$low.');
      expectingEpithet = true;
      continue;
    }
    final first = token[0];
    if (first == "'" || first == '"' || first == '‘' || first == '“') {
      out.add("'${token.replaceAll(RegExp('[\'"‘’“”]'), '')}'");
      expectingEpithet = false;
      continue;
    }
    if (expectingEpithet) {
      final shouting = token.length >= 3 && _isAlpha(token) && token == token.toUpperCase();
      final startsUpper = first == first.toUpperCase() && first != first.toLowerCase();
      if ((startsUpper && !shouting) || first == '(' || RegExp(r'\d').hasMatch(token)) break;
      out.add(low);
      expectingEpithet = false;
      continue;
    }
    break;
  }
  if (out.isNotEmpty && out.last == _hybrid) out.removeLast();
  return out.join(' ');
}

/// « Monstera deliciosa » → « monstera-deliciosa » : l'identifiant interne
/// d'une plante, le même que dans `plants.csv` et dans les classes du modèle.
String internalPlantId(String scientificName) {
  final canonical = normalizeScientificName(scientificName);
  final folded = foldSpeciesName(canonical).replaceAll(_hybrid, 'x');
  return folded.replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');
}

bool _isAlpha(String s) => RegExp(r'^[A-Za-z]+$').hasMatch(s);
