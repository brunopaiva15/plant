import 'package:flora/domain/community/species_tip.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ce qui part sur le réseau et l'ordre dans lequel les conseils se lisent.
/// Les bornes de longueur sont tenues des deux côtés — ici et dans
/// `supabase/schema.sql` — et les deux doivent dire la même chose.
void main() {
  group('cleanTipBody', () {
    test('replie les espaces sans coller les paragraphes', () {
      expect(
        cleanTipBody('  Arroser   quand le  substrat est sec. \n\n\n  Rempoter au printemps.  '),
        'Arroser quand le substrat est sec.\n\nRempoter au printemps.',
      );
    });

    test('refuse ce qui ne dit rien', () {
      expect(cleanTipBody(''), isNull);
      expect(cleanTipBody('   \n  '), isNull);
      expect(cleanTipBody('Trop peu'), isNull);
    });

    test('accepte la borne basse et refuse un caractère de moins', () {
      expect(cleanTipBody('a' * speciesTipMinLength), 'a' * speciesTipMinLength);
      expect(cleanTipBody('a' * (speciesTipMinLength - 1)), isNull);
    });

    test('accepte la borne haute et refuse un caractère de plus', () {
      expect(cleanTipBody('a' * speciesTipMaxLength)?.length, speciesTipMaxLength);
      expect(cleanTipBody('a' * (speciesTipMaxLength + 1)), isNull);
    });

    test('les espaces de bord ne comptent pas dans la longueur', () {
      expect(cleanTipBody('   ${'a' * speciesTipMaxLength}   ')?.length, speciesTipMaxLength);
    });
  });

  group('ordre de lecture', () {
    SpeciesTip tip(String id, {int votes = 0, bool mine = false, int day = 1}) => SpeciesTip(
          id: id,
          speciesId: 'hoya-kerrii',
          authorName: 'Laura',
          body: 'Un conseil qui tient la longueur minimale.',
          votes: votes,
          createdAt: DateTime(2026, 1, day),
          mine: mine,
        );

    test('le sien passe devant, même sans voix', () {
      final list = SpeciesTip.sorted([tip('a', votes: 9), tip('moi', mine: true)]);
      expect(list.first.id, 'moi');
    });

    test('puis les plus utiles', () {
      final list = SpeciesTip.sorted([tip('a', votes: 1), tip('b', votes: 7), tip('c', votes: 3)]);
      expect([for (final t in list) t.id], ['b', 'c', 'a']);
    });

    test('à voix égales, le plus récent', () {
      final list = SpeciesTip.sorted([tip('vieux', votes: 2, day: 1), tip('neuf', votes: 2, day: 20)]);
      expect([for (final t in list) t.id], ['neuf', 'vieux']);
    });
  });
}
