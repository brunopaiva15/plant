/// Analyseur Markdown minimal : ce qu'on écrit vraiment dans une note de
/// plante, et rien de plus. Gras, italique, code, liens, listes, titres.
///
/// Volontairement sans dépendance : le sous-ensemble est petit, stable et
/// entièrement testable.
library;

/// Un morceau de texte avec son style.
class MdSpan {
  const MdSpan(this.text, {this.bold = false, this.italic = false, this.code = false, this.link});

  final String text;
  final bool bold;
  final bool italic;
  final bool code;

  /// Cible du lien, `null` si ce n'est pas un lien.
  final String? link;

  @override
  bool operator ==(Object other) =>
      other is MdSpan && other.text == text && other.bold == bold && other.italic == italic && other.code == code && other.link == link;

  @override
  int get hashCode => Object.hash(text, bold, italic, code, link);

  @override
  String toString() => 'MdSpan($text${bold ? ' b' : ''}${italic ? ' i' : ''}${code ? ' c' : ''}${link == null ? '' : ' → $link'})';
}

enum MdBlockKind { paragraph, heading1, heading2, heading3, bullet, numbered, quote }

/// Un bloc : un paragraphe, un titre, un élément de liste.
class MdBlock {
  const MdBlock(this.kind, this.spans, {this.number});

  final MdBlockKind kind;
  final List<MdSpan> spans;

  /// Numéro affiché pour une liste ordonnée.
  final int? number;

  bool get isList => kind == MdBlockKind.bullet || kind == MdBlockKind.numbered;
}

abstract final class Markdown {
  static final _heading = RegExp(r'^(#{1,3})\s+(.*)$');
  static final _bullet = RegExp(r'^\s*[-*+]\s+(.*)$');
  static final _numbered = RegExp(r'^\s*(\d+)[.)]\s+(.*)$');
  static final _quote = RegExp(r'^>\s?(.*)$');

  /// Le texte contient-il de la mise en forme ? Sert à n'activer l'aperçu
  /// que quand il apporte quelque chose.
  static bool hasFormatting(String text) {
    if (text.isEmpty) return false;
    for (final line in text.split('\n')) {
      if (_heading.hasMatch(line) || _bullet.hasMatch(line) || _numbered.hasMatch(line) || _quote.hasMatch(line)) return true;
    }
    return RegExp(r'\*\*.+\*\*|\*.+\*|_.+_|`.+`|\[.+\]\(.+\)|https?://\S+').hasMatch(text);
  }

  /// Découpe le texte en blocs. Les lignes vides séparent les paragraphes ;
  /// à l'intérieur d'un paragraphe, les retours simples sont conservés.
  static List<MdBlock> parse(String source) {
    final blocks = <MdBlock>[];
    final paragraph = <String>[];

    void flush() {
      if (paragraph.isEmpty) return;
      blocks.add(MdBlock(MdBlockKind.paragraph, inline(paragraph.join('\n'))));
      paragraph.clear();
    }

    for (final raw in source.split('\n')) {
      final line = raw.trimRight();
      if (line.trim().isEmpty) {
        flush();
        continue;
      }
      if (_heading.firstMatch(line) case final m?) {
        flush();
        final level = m.group(1)!.length;
        blocks.add(MdBlock(switch (level) { 1 => MdBlockKind.heading1, 2 => MdBlockKind.heading2, _ => MdBlockKind.heading3 }, inline(m.group(2)!)));
        continue;
      }
      if (_numbered.firstMatch(line) case final m?) {
        flush();
        blocks.add(MdBlock(MdBlockKind.numbered, inline(m.group(2)!), number: int.tryParse(m.group(1)!)));
        continue;
      }
      if (_bullet.firstMatch(line) case final m?) {
        flush();
        blocks.add(MdBlock(MdBlockKind.bullet, inline(m.group(1)!)));
        continue;
      }
      if (_quote.firstMatch(line) case final m?) {
        flush();
        blocks.add(MdBlock(MdBlockKind.quote, inline(m.group(1)!)));
        continue;
      }
      paragraph.add(line);
    }
    flush();
    return blocks;
  }

  static final _inline = RegExp(
    r'(\*\*(?<bold>[^*]+)\*\*)'
    r'|(\*(?<ital>[^*\n]+)\*)'
    r'|(_(?<ital2>[^_\n]+)_)'
    r'|(`(?<code>[^`\n]+)`)'
    r'|(\[(?<text>[^\]\n]+)\]\((?<href>[^)\s]+)\))'
    r'|(?<bare>https?://[^\s<>\)]+)',
  );

  /// Découpe une ligne en fragments stylés.
  static List<MdSpan> inline(String source) {
    final spans = <MdSpan>[];
    var index = 0;
    for (final m in _inline.allMatches(source)) {
      if (m.start > index) spans.add(MdSpan(source.substring(index, m.start)));
      if (m.namedGroup('bold') case final t?) {
        spans.add(MdSpan(t, bold: true));
      } else if (m.namedGroup('ital') case final t?) {
        spans.add(MdSpan(t, italic: true));
      } else if (m.namedGroup('ital2') case final t?) {
        spans.add(MdSpan(t, italic: true));
      } else if (m.namedGroup('code') case final t?) {
        spans.add(MdSpan(t, code: true));
      } else if (m.namedGroup('text') case final t?) {
        spans.add(MdSpan(t, link: m.namedGroup('href')));
      } else if (m.namedGroup('bare') case final t?) {
        spans.add(MdSpan(t, link: t));
      }
      index = m.end;
    }
    if (index < source.length) spans.add(MdSpan(source.substring(index)));
    return spans.isEmpty ? [MdSpan(source)] : spans;
  }

  /// Texte nu, pour les aperçus d'une ligne et la recherche.
  static String stripped(String source) => parse(source).map((b) => b.spans.map((s) => s.text).join()).join(' ').trim();
}
