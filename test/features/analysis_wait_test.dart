import 'package:flora/design_system/design_system.dart';
import 'package:flora/features/diagnosis/presentation/analysis_wait.dart';
import 'package:flora/features/problems/presentation/problem_kind_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// La scène d'attente du diagnostic : la photo au centre, les quatre familles
/// autour. Le ticker tourne sans fin, donc jamais de `pumpAndSettle` ici : on
/// avance à la main et on démonte la scène pour l'arrêter.
void main() {
  Widget scene({bool reduceMotion = false}) => MaterialApp(
        theme: buildFloraTheme(Brightness.light),
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduceMotion),
          child: const Scaffold(
            body: Center(child: AnalysisWait(photo: ColoredBox(color: Colors.green))),
          ),
        ),
      );

  // L'ordre des symboles dans l'arbre change en cours de route — ceux qui
  // passent devant la photo sont peints après —, donc on compare l'ensemble
  // des positions et non chacune à son rang.
  Set<Offset> centres(WidgetTester tester) =>
      {for (var i = 0; i < 4; i++) tester.getCenter(find.byType(ProblemKindIcon).at(i))};

  testWidgets('les quatre familles gravitent autour de la photo', (tester) async {
    await tester.pumpWidget(scene());
    expect(find.byType(ProblemKindIcon), findsNWidgets(4));

    final depart = centres(tester);
    // Un quatorzième de tour : les positions ont visiblement bougé.
    await tester.pump(const Duration(seconds: 1));
    expect(centres(tester), isNot(depart));

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('avec « réduire les animations », la scène reste posée', (tester) async {
    await tester.pumpWidget(scene(reduceMotion: true));
    expect(find.byType(ProblemKindIcon), findsNWidgets(4));

    final depart = centres(tester);
    await tester.pump(const Duration(seconds: 3));
    expect(centres(tester), depart, reason: 'aucun ticker ne doit tourner');

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('les symboles se répartissent autour du centre', (tester) async {
    await tester.pumpWidget(scene(reduceMotion: true));
    final centre = tester.getCenter(find.byType(AnalysisWait));
    final positions = centres(tester);
    // Au repos, un symbole de chaque côté : deux à gauche et à droite, deux
    // au-dessus et au-dessous.
    expect(positions.where((p) => p.dx < centre.dx - 1), hasLength(1));
    expect(positions.where((p) => p.dx > centre.dx + 1), hasLength(1));
    expect(positions.where((p) => p.dy < centre.dy - 1), hasLength(1));
    expect(positions.where((p) => p.dy > centre.dy + 1), hasLength(1));

    await tester.pumpWidget(const SizedBox());
  });
}
