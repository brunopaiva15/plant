import 'package:flora/design_system/design_system.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 44 × 44 points : le minimum que posent les HIG pour tout ce qui se touche.
///
/// Le dessin, lui, ne change pas — un rond de 32 reste un rond de 32. C'est la
/// surface qui écoute le doigt qui s'élargit autour, et c'est elle que
/// `iOSTapTargetGuideline` mesure.

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildFloraTheme(Brightness.light),
      home: Scaffold(body: Center(child: child)),
    ),
  );
  await tester.pump();
}

void main() {
  group('cibles tactiles', () {
    testWidgets('un bouton icône de 30 points reste touchable sur 44', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, FloraIconButton(icon: CupertinoIcons.trash, semanticLabel: 'Supprimer', size: 30, onPressed: () {}));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('… et de 32, la taille la plus courante dans les listes', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, FloraIconButton(icon: CupertinoIcons.xmark, semanticLabel: 'Fermer', size: 32, onPressed: () {}));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('le dessin garde sa taille, seule la zone grandit', (tester) async {
      await _pump(tester, FloraIconButton(icon: CupertinoIcons.xmark, semanticLabel: 'Fermer', size: 32, onPressed: () {}));
      // Le rond peint mesure toujours 32…
      expect(tester.getSize(find.byType(Icon).first).width, lessThanOrEqualTo(32));
      // … et la boîte qui écoute en fait 44.
      expect(tester.getSize(find.byType(MinTapTarget).first), const Size(44, 44));
    });

    testWidgets('une chip de filtre', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, FloraChip(label: 'Salon', onTap: () {}));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('les boutons − et + du stepper', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, QuantityStepper(value: 3, label: '3 jours', onChanged: (_) {}));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('le « Voir tout » d\'un en-tête de section', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, SectionHeader(title: 'Aujourd\'hui', actionLabel: 'Voir tout', onAction: () {}));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('une ligne de liste', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        SizedBox(
          width: 320,
          child: FloraListRow(title: 'Monstera', subtitle: 'Salon', onTap: () {}),
        ),
      );
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('un bouton pleine largeur ne change pas de mise en page', (tester) async {
      // Le parent impose déjà la largeur : la cible minimale ne doit pas
      // s'en mêler et rétrécir le bouton.
      await _pump(
        tester,
        SizedBox(
          width: 300,
          child: FloraButton(label: 'Enregistrer', expand: true, onPressed: () {}),
        ),
      );
      expect(tester.getSize(find.byType(FloraButton)).width, 300);
      expect(tester.getSize(find.byType(FloraButton)).height, greaterThanOrEqualTo(44));
    });
  });

  group('VoiceOver', () {
    testWidgets('une ligne de liste s\'annonce d\'un seul tenant', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        SizedBox(
          width: 320,
          child: FloraListRow(title: 'Monstera', subtitle: 'Arrosée il y a 3 jours', onTap: () {}),
        ),
      );
      final node = tester.getSemantics(find.byType(FloraListRow));
      // Un seul bouton, qui porte le titre et le sous-titre…
      expect(node.hasFlag(SemanticsFlag.isButton), isTrue);
      expect(node.label, contains('Monstera'));
      expect(node.label, contains('Arrosée il y a 3 jours'));
      // … et qui ne les répète pas : un libellé recopié en plus des enfants
      // ferait dire deux fois la même chose à VoiceOver.
      expect('Monstera'.allMatches(node.label).length, 1);
      handle.dispose();
    });

    testWidgets('un titre de section est un en-tête', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, const SectionHeader(title: 'Votre jardin'));
      final node = tester.getSemantics(find.text('Votre jardin'));
      expect(node.hasFlag(SemanticsFlag.isHeader), isTrue);
      handle.dispose();
    });
  });
}
