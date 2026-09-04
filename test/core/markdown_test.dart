import 'package:flora/core/utils/markdown.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('inline', () {
    test('gras, italique et code', () {
      expect(Markdown.inline('un **gras** ici'), [const MdSpan('un '), const MdSpan('gras', bold: true), const MdSpan(' ici')]);
      expect(Markdown.inline('*penché*'), [const MdSpan('penché', italic: true)]);
      expect(Markdown.inline('_penché_'), [const MdSpan('penché', italic: true)]);
      expect(Markdown.inline('`code`'), [const MdSpan('code', code: true)]);
    });

    test('lien nommé et lien nu', () {
      expect(Markdown.inline('voir [le guide](https://exemple.test/g)'), [
        const MdSpan('voir '),
        const MdSpan('le guide', link: 'https://exemple.test/g'),
      ]);
      expect(Markdown.inline('https://exemple.test'), [const MdSpan('https://exemple.test', link: 'https://exemple.test')]);
    });

    test('le texte sans balise reste intact', () {
      expect(Markdown.inline('rien de special'), [const MdSpan('rien de special')]);
      expect(Markdown.inline(''), [const MdSpan('')]);
    });

    test('un astérisque isolé n\'est pas de l\'italique', () {
      expect(Markdown.inline('2 * 3 = 6'), [const MdSpan('2 * 3 = 6')]);
    });
  });

  group('blocs', () {
    test('titres de trois niveaux', () {
      final blocks = Markdown.parse('# Un\n## Deux\n### Trois');
      expect(blocks.map((b) => b.kind), [MdBlockKind.heading1, MdBlockKind.heading2, MdBlockKind.heading3]);
      expect(blocks.first.spans.single.text, 'Un');
    });

    test('listes à puces et numérotées', () {
      final blocks = Markdown.parse('- un\n* deux\n1. trois\n2) quatre');
      expect(blocks.map((b) => b.kind), [MdBlockKind.bullet, MdBlockKind.bullet, MdBlockKind.numbered, MdBlockKind.numbered]);
      expect(blocks.last.number, 2);
    });

    test('les lignes vides séparent les paragraphes', () {
      final blocks = Markdown.parse('premier\nencore\n\nsecond');
      expect(blocks, hasLength(2));
      expect(blocks.first.spans.single.text, 'premier\nencore');
    });

    test('citation', () {
      final blocks = Markdown.parse('> conseil du pépiniériste');
      expect(blocks.single.kind, MdBlockKind.quote);
      expect(blocks.single.spans.single.text, 'conseil du pépiniériste');
    });

    test('un texte vide ne produit aucun bloc', () {
      expect(Markdown.parse(''), isEmpty);
      expect(Markdown.parse('\n\n  \n'), isEmpty);
    });
  });

  group('hasFormatting', () {
    test('détecte la mise en forme', () {
      expect(Markdown.hasFormatting('**gras**'), isTrue);
      expect(Markdown.hasFormatting('- liste'), isTrue);
      expect(Markdown.hasFormatting('# titre'), isTrue);
      expect(Markdown.hasFormatting('https://exemple.test'), isTrue);
    });

    test('ignore le texte ordinaire', () {
      expect(Markdown.hasFormatting('Arrosée ce matin, terre encore humide.'), isFalse);
      expect(Markdown.hasFormatting(''), isFalse);
    });
  });

  test('stripped rend le texte nu, pour les aperçus', () {
    expect(Markdown.stripped('# Titre\n\nUn **gras** et [un lien](https://x.test)'), 'Titre Un gras et un lien');
  });
}
