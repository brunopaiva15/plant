import 'package:flora/design_system/design_system.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Le retour d'une page à grand titre.
///
/// Le gabarit sert d'abord aux quatre onglets, qui sont des racines : aucun
/// retour n'y a de sens. Mais « Anciennes plantes » le reprend alors qu'elle
/// est poussée depuis les réglages, et n'offrait rien pour revenir — ni
/// bouton, ni chevron : seuls le glissement d'iOS et le geste système
/// d'Android ramenaient en arrière.

/// L'icône du retour sur la plateforme testée.
IconData _backIcon(TargetPlatform platform) =>
    platform == TargetPlatform.iOS ? CupertinoIcons.chevron_left : Icons.arrow_back_rounded;

Widget _page(String title, {Widget? leading}) => LargeTitlePage(
      title: title,
      leading: leading,
      slivers: [SliverToBoxAdapter(child: Text('contenu de $title'))],
    );

/// Une racine à grand titre, avec de quoi pousser une seconde page dessus.
Future<void> _pump(WidgetTester tester, {Widget? pushedLeading}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildFloraTheme(Brightness.light),
      home: Builder(
        builder: (context) => LargeTitlePage(
          title: 'Profil',
          slivers: [
            SliverToBoxAdapter(
              child: FloraButton(
                label: 'Ouvrir',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => _page('Anciennes plantes', leading: pushedLeading)),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
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
  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    final name = platform == TargetPlatform.iOS ? 'iOS' : 'Android';

    group("le retour d'une page à grand titre, sur $name", () {
      testWidgets("un onglet reste sans retour : il n'y a rien à dépiler", (tester) => _on(platform, () async {
            await _pump(tester);
            expect(find.text('Ouvrir'), findsOneWidget);
            expect(find.byIcon(_backIcon(platform)), findsNothing);
          }));

      testWidgets('une page poussée en reçoit un, qui ramène en arrière', (tester) => _on(platform, () async {
            await _pump(tester);
            await tester.tap(find.text('Ouvrir'));
            await tester.pumpAndSettle();
            expect(find.text('contenu de Anciennes plantes'), findsOneWidget);

            final back = find.byIcon(_backIcon(platform));
            expect(back, findsOneWidget);
            await tester.tap(back);
            await tester.pumpAndSettle();
            expect(find.text('contenu de Anciennes plantes'), findsNothing);
            expect(find.text('Ouvrir'), findsOneWidget);
          }));

      testWidgets('le retour porte le libellé de sa langue', (tester) => _on(platform, () async {
            final handle = tester.ensureSemantics();
            await _pump(tester);
            await tester.tap(find.text('Ouvrir'));
            await tester.pumpAndSettle();
            // Sans délégué d'app, le test tourne en anglais : c'est le libellé
            // que Flutter traduit lui-même dans les quatre langues livrées.
            expect(find.bySemanticsLabel('Back'), findsOneWidget);
            handle.dispose();
          }));

      testWidgets('un leading explicite garde sa place', (tester) => _on(platform, () async {
            await _pump(
              tester,
              pushedLeading: FloraIconButton(icon: CupertinoIcons.chart_bar, semanticLabel: 'Tableau de bord', onPressed: () {}),
            );
            await tester.tap(find.text('Ouvrir'));
            await tester.pumpAndSettle();
            expect(find.byIcon(CupertinoIcons.chart_bar), findsOneWidget);
            expect(find.byIcon(_backIcon(platform)), findsNothing);
          }));
    });
  }
}
