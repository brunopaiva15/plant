import 'package:flora/app/providers.dart';
import 'package:flora/app/router.dart';
import 'package:flora/domain/models/models.dart';
import 'package:flora/domain/repositories/repositories.dart';
import 'package:flora/features/qr/application/plant_links.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_smoke_test.dart' as harness;

void main() {
  testWidgets('un QR scanné hors de l\'application ouvre la fiche, sans impasse', (tester) async {
    late String plantId;
    final container = await harness.boot(tester, seed: (c) async {
      plantId = (await c.read(plantRepositoryProvider).create(NewPlant(name: 'Monstera'))).id;
    });
    await harness.pumpApp(tester, container);

    // Ce que le système livre quand on scanne l'étiquette avec l'appareil
    // photo : le lien brut, pas un chemin de l'application.
    container.read(routerProvider).go(PlantLinks.encode(plantId));
    await harness.settle(tester);

    expect(find.text('Monstera'), findsWidgets);
    // La fiche s'est posée sur l'accueil : son bouton retour mène quelque part.
    expect(rootNavigatorKey.currentState!.canPop(), isTrue);
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('une étiquette dont la plante n\'existe plus laisse à l\'accueil', (tester) async {
    final container = await harness.boot(tester);
    await harness.pumpApp(tester, container);

    container.read(routerProvider).go(PlantLinks.encode('4b3c9d5e-0000-0000-0000-000000000000'));
    await harness.settle(tester);

    expect(rootNavigatorKey.currentState!.canPop(), isFalse);
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('un lien qu\'on ne sait pas lire ne montre pas d\'erreur de routage', (tester) async {
    final container = await harness.boot(tester);
    await harness.pumpApp(tester, container);

    container.read(routerProvider).go('flora://login-callback');
    await harness.settle(tester);

    expect(find.textContaining('Page Not Found'), findsNothing);
    expect(find.textContaining('no routes for location'), findsNothing);
    await tester.pump(const Duration(seconds: 6));
  });
}
