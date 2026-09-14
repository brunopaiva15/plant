import 'package:flora/design_system/design_system.dart';
import 'package:flora/domain/identification/plant_identifier.dart';
import 'package:flora/features/identification/presentation/identification_source_note.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Le signe de la provenance, au-dessus des propositions d'espèce.
///
/// La phrase disait déjà d'où venait la liste, et une légende grise se saute.
/// Un téléphone et un nuage se voient sans se lire — et c'est la seule
/// information de ces écrans qui dit si la photo est sortie de l'appareil.

const _phone = CupertinoIcons.device_phone_portrait;
const _cloud = CupertinoIcons.cloud;

/// Ce que chaque écran écrit sous les propositions, source par source.
const _labels = {
  IdentificationSource.local: 'Trouvé sur votre appareil, sans réseau',
  IdentificationSource.remote: 'Proposé en ligne par Pl@ntNet',
  IdentificationSource.unknown: 'Suggestions d’espèce, à confirmer',
};

/// Les crans d'iOS, du plus petit au plus grand des réglages d'accessibilité.
const _scales = [0.82, 1.0, 1.35, 2.0, 3.0, 3.5];

Future<void> _pump(WidgetTester tester, IdentificationSource source, {double scale = 1.0}) async {
  await tester.pumpWidget(MaterialApp(
    theme: buildFloraTheme(Brightness.light),
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(scale)),
      child: Scaffold(
        body: Center(
          child: SizedBox(
            width: 320,
            child: IdentificationSourceNote(source: source, label: _labels[source]!),
          ),
        ),
      ),
    ),
  ));
  await tester.pump();
}

void main() {
  testWidgets('le modèle embarqué met un téléphone', (tester) async {
    await _pump(tester, IdentificationSource.local);
    expect(find.byIcon(_phone), findsOneWidget);
    expect(find.byIcon(_cloud), findsNothing);
  });

  testWidgets('Pl@ntNet met un nuage', (tester) async {
    await _pump(tester, IdentificationSource.remote);
    expect(find.byIcon(_cloud), findsOneWidget);
    expect(find.byIcon(_phone), findsNothing);
  });

  testWidgets('une provenance inconnue n’affirme rien', (tester) async {
    await _pump(tester, IdentificationSource.unknown);
    expect(find.byIcon(_phone), findsNothing);
    expect(find.byIcon(_cloud), findsNothing);
    // La phrase reste : elle ne promettait rien qu'on doive retirer.
    expect(find.text(_labels[IdentificationSource.unknown]!), findsOneWidget);
  });

  testWidgets('le signe grandit avec le texte', (tester) async {
    await _pump(tester, IdentificationSource.local);
    final small = tester.getSize(find.byIcon(_phone)).height;
    await _pump(tester, IdentificationSource.local, scale: 3.0);
    expect(tester.getSize(find.byIcon(_phone)).height, greaterThan(small));
  });

  group('la ligne ne déborde pas', () {
    for (final scale in _scales) {
      testWidgets('à ${(scale * 100).round()} %', (tester) async {
        await _pump(tester, IdentificationSource.remote, scale: scale);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
