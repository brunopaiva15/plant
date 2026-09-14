import 'package:flora/design_system/design_system.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Le titre qui reste dans la barre quand le grand titre s'en va.
///
/// L'écran du matin salue la personne. Replié dans la barre, « Bonjour
/// Bruno » ne dit plus où l'on est : c'est le nom de l'application qui y
/// reste. Les deux gabarits n'ont pas la même mécanique — iOS tient deux
/// cases côte à côte et les croise en fondu, Material n'en a qu'une et rend
/// le même widget deux fois —, d'où deux vérifications.

/// Une page à grand titre qui salue, avec de quoi défiler dessous.
Widget _page() => MaterialApp(
      theme: buildFloraTheme(Brightness.light),
      home: const LargeTitlePage(
        title: 'Bonjour Bruno',
        collapsedTitle: 'Auxine',
        slivers: [SliverToBoxAdapter(child: SizedBox(height: 2000, child: Text('contenu')))],
      ),
    );

/// Un téléphone tenu droit : sans cela la surface de test est couchée, et le
/// gabarit iOS n'affiche aucun grand titre.
void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Future<void> _on(TargetPlatform platform, Future<void> Function() body) async {
  debugDefaultTargetPlatformOverride = platform;
  try {
    await body();
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
}

void main() {
  testWidgets('sur iOS, le salut ne se lit qu\'une fois et le nom tient la barre', (tester) => _on(TargetPlatform.iOS, () async {
        _phone(tester);
        await tester.pumpWidget(_page());
        await tester.pumpAndSettle();
        // Avant, le salut était rendu deux fois : en grand, et dans la barre
        // où il se repliait. La barre a maintenant sa propre case.
        expect(find.text('Bonjour Bruno'), findsOneWidget);
        expect(find.text('Auxine'), findsOneWidget);
      }));

  testWidgets('sur Android, le nom prend la place une fois la barre repliée', (tester) => _on(TargetPlatform.android, () async {
        _phone(tester);
        await tester.pumpWidget(_page());
        await tester.pumpAndSettle();
        expect(find.text('Bonjour Bruno'), findsWidgets);
        expect(find.text('Auxine'), findsNothing);

        await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
        await tester.pumpAndSettle();
        expect(find.text('Auxine'), findsWidgets);
        expect(find.text('Bonjour Bruno'), findsNothing);
      }));

  testWidgets('sans titre replié, rien ne change', (tester) => _on(TargetPlatform.iOS, () async {
        _phone(tester);
        await tester.pumpWidget(
          MaterialApp(
            theme: buildFloraTheme(Brightness.light),
            home: const LargeTitlePage(
              title: 'Jardin',
              slivers: [SliverToBoxAdapter(child: Text('contenu'))],
            ),
          ),
        );
        await tester.pumpAndSettle();
        // Le grand titre se replie lui-même dans la barre : le gabarit natif
        // le rend aux deux places.
        expect(find.text('Jardin'), findsWidgets);
      }));
}
