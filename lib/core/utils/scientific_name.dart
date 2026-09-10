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
  // Le signe d'hybride est parfois collé à l'épithète (« Citrus ×sinensis »
  // chez GBIF comme dans les flores) : sans ce décollement, le nom donnerait
  // une clé différente de « Citrus × sinensis », donc une autre plante.
  final s = raw.replaceAll('_', ' ').replaceAll(RegExp('$_hybrid(?=\\S)'), '$_hybrid ').trim().replaceAll(RegExp(r'\s+'), ' ');
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

/// Deux noms d'une même plante, ramenés à celui que l'app sait le mieux
/// nommer. Les couples sont vérifiés un par un contre le taxon accepté de
/// GBIF (`tools/plant_dataset/doublons.py`, § 12.14 de
/// `docs/09-plant-recognition.md`).
///
/// **Ce ne sont pas des espèces voisines : ce sont les mêmes plantes.** La
/// sansevière a changé de genre en 2017, le coléus en 2019. Les deux noms
/// sont au catalogue étendu *et* dans les classes du modèle, si bien que la
/// même plante donnait deux résultats selon la photo : identifiée
/// « Dracaena trifasciata » elle trouvait la fiche soignée à la main et son
/// nom français, identifiée « Sansevieria trifasciata » elle tombait dans le
/// catalogue étendu et ressortait « Mother-in-law's tongue », en anglais
/// seulement — avec un identifiant interne différent, donc un autre profil
/// de soin.
///
/// **Le sens de la flèche n'est pas celui qu'on croit.** GBIF dit *quels*
/// noms sont la même plante ; il ne dit pas lequel garder. Ce qui décide
/// ici, c'est ce que l'app possède : la fiche soignée à la main d'abord, le
/// catalogue étendu ensuite. Canoniser vers le nom accepté de GBIF
/// donnerait *Coleus scutellarioides*, que ni l'une ni l'autre ne
/// contiennent — la plante ne serait plus reconnue du tout —, et
/// *Kroenleinia grusonii*, qui n'est que dans le catalogue étendu là où
/// *Echinocactus grusonii* a sa fiche soignée. On perdrait ce qu'on croyait
/// réparer.
///
/// *Citrus × bergamia* est volontairement absente : GBIF la rattache au
/// citron, mais la bergamote n'est pas un citron pour qui la cultive, et
/// aucune des deux données de l'app ne la porte — il n'y a donc pas de
/// contradiction à lever.
///
/// La table est courte et le restera : elle ne recense pas les synonymes en
/// général — c'est le travail de GBIF, en ligne — mais les seuls cas où
/// **les deux noms sont dans nos propres données** et se contredisent.
const _acceptedNames = {
  'Sansevieria trifasciata': 'Dracaena trifasciata',
  'Coleus scutellarioides': 'Plectranthus scutellarioides',
  'Kroenleinia grusonii': 'Echinocactus grusonii',
  'Hesperocyparis macrocarpa': 'Cupressus macrocarpa',
  'Citrus myrtifolia': 'Citrus × aurantium',
};

/// Le nom sous lequel l'app connaît le mieux cette plante, quand elle en
/// connaît deux. Sinon le nom tel quel.
///
/// À appliquer **après** [normalizeScientificName], et à l'endroit qui
/// résout une espèce — pas à l'affichage : « Sansevieria trifasciata » reste
/// un nom juste, que l'utilisateur a le droit de lire s'il l'a cherché.
String acceptedSpeciesName(String canonical) => _acceptedNames[canonical] ?? canonical;

/// « Monstera deliciosa » → « monstera-deliciosa » : l'identifiant interne
/// d'une plante, le même que dans `plants.csv` et dans les classes du modèle.
String internalPlantId(String scientificName) {
  final canonical = normalizeScientificName(scientificName);
  final folded = foldSpeciesName(canonical).replaceAll(_hybrid, 'x');
  return folded.replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');
}

bool _isAlpha(String s) => RegExp(r'^[A-Za-z]+$').hasMatch(s);
