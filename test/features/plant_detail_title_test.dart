import 'package:flora/app/providers.dart';
import 'package:flora/domain/repositories/repositories.dart';
import 'package:flora/features/plants/presentation/plant_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../app/app_smoke_test.dart' as harness;

/// Sur la fiche d'une plante, le nom devient le titre de la page.
///
/// L'en-tête est une photo, pas un grand titre : une fois la photo défilée, la
/// barre restait nue et plus rien ne disait quelle plante on regardait. Le nom
/// y monte donc au moment où il passe dessous, comme le fait iOS d'un grand
/// titre. Le système le porte là où il tient la barre ; sous `flutter test`,
/// c'est la barre de Flutter qu'on voit ici.
void main() {
  /// L'opacité du fondu qui porte le nom dans la barre.
  double opacite(WidgetTester tester, Finder texte) =>
      tester.widget<AnimatedOpacity>(find.ancestor(of: texte, matching: find.byType(AnimatedOpacity)).first).opacity;

  testWidgets('le nom de la plante monte dans la barre quand il passe dessous', (tester) async {
    final container = await harness.boot(
      tester,
      seed: (c) => c.read(plantRepositoryProvider).create(const NewPlant(name: 'Pilea')),
    );
    await harness.pumpApp(tester, container);
    await tester.tap(find.text('Plantes'));
    await harness.settle(tester);
    expect(find.text('Pilea'), findsOneWidget);
    await tester.tap(find.text('Pilea'));
    await harness.settle(tester);
    expect(find.text('Prochains soins'), findsOneWidget);

    final dansLaBarre = find.descendant(of: find.byType(AppBar), matching: find.text('Pilea'));
    expect(dansLaBarre, findsOneWidget, reason: 'la barre porte le nom, et l\'efface tant qu\'il se lit dessous');
    expect(opacite(tester, dansLaBarre), 0, reason: 'en haut de la fiche, le nom se lit déjà sous l\'en-tête');

    final liste = find.descendant(of: find.byType(PlantDetailScreen), matching: find.byType(CustomScrollView));
    await tester.drag(liste, const Offset(0, -320));
    await harness.settle(tester);
    expect(opacite(tester, dansLaBarre), 1, reason: 'le nom est passé sous la barre : elle le prend');

    await tester.drag(liste, const Offset(0, 320));
    await harness.settle(tester);
    expect(opacite(tester, dansLaBarre), 0, reason: 'revenu en haut, la fiche reprend son titre');
  });
}
