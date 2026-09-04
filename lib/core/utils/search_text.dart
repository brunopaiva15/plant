/// Table de repli des caractères accentués et des ligatures.
///
/// Une correspondance explicite plutôt que deux chaînes parallèles : ces
/// dernières se décalent à la moindre faute de frappe, et le décalage est
/// invisible tant qu'on ne teste pas la lettre concernée.
const _folded = <String, String>{
  'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a', 'ā': 'a', 'ă': 'a',
  'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e', 'ē': 'e', 'ĕ': 'e', 'ė': 'e', 'ę': 'e',
  'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i', 'ī': 'i', 'į': 'i',
  'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', 'ø': 'o', 'ō': 'o', 'ő': 'o',
  'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u', 'ū': 'u', 'ů': 'u', 'ű': 'u',
  'ý': 'y', 'ÿ': 'y',
  'ç': 'c', 'ć': 'c', 'č': 'c',
  'ñ': 'n', 'ń': 'n', 'ň': 'n',
  'š': 's', 'ś': 's', 'ş': 's',
  'ž': 'z', 'ź': 'z', 'ż': 'z',
  'ł': 'l', 'đ': 'd', 'ð': 'd', 'þ': 'th', 'ř': 'r', 'ť': 't', 'ď': 'd',
  'ß': 'ss', 'œ': 'oe', 'æ': 'ae',
};

/// Normalise pour la recherche : sans accents, sans casse, ligatures dépliées.
///
/// Indispensable ici : personne ne tape « Édelweiß » avec les bons signes,
/// et « erable » doit trouver « érable ».
String foldSpeciesName(String input) {
  final lower = input.toLowerCase();
  // La très grande majorité des requêtes est déjà en ASCII : on évite alors
  // de reconstruire la chaîne caractère par caractère.
  var needsFolding = false;
  for (var i = 0; i < lower.length; i++) {
    if (lower.codeUnitAt(i) > 127) {
      needsFolding = true;
      break;
    }
  }
  if (!needsFolding) return lower.trim();

  final buffer = StringBuffer();
  for (final rune in lower.runes) {
    final ch = String.fromCharCode(rune);
    buffer.write(_folded[ch] ?? ch);
  }
  return buffer.toString().trim();
}
