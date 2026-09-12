import 'package:flora/app/providers.dart';
import 'package:flora/app/router.dart';
import 'package:flora/data/species/care_profiles.dart';
import 'package:flora/domain/care/care_suggestions.dart';
import 'package:flora/domain/models/models.dart';
import 'package:flora/domain/repositories/repositories.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../app/app_smoke_test.dart' as harness;

/// La feuille d'édition d'une routine, côté lisibilité du chiffre.
///
/// L'intervalle proposé sort de la fiche d'entretien de l'espèce. Il ne
/// s'écrivait nulle part d'où il venait, et le mode « Fixe » le répétait
/// au-dessus du stepper : trois fois la même valeur sur une feuille de dix
/// lignes. Le chiffre ne s'affiche donc plus qu'une fois, et sa provenance
/// est dite.

/// Ce que la fiche de l'espèce conseille pour l'arrosage ce mois-ci — la
/// valeur dépend de la saison, le test la recalcule plutôt que de la figer.
int suggestedWatering() => CareProfiles.bySpecies['Ficus lyrata']!.suggestedIntervalDays(CareKind.watering.key)!;

Future<void> openWatering(WidgetTester tester, ProviderContainer container, String plantId) async {
  container.read(routerProvider).go('/plants/$plantId/schedule');
  await harness.settle(tester);
  await tester.tap(find.text('Arrosage'));
  await harness.settle(tester);
}

void main() {
  testWidgets('un intervalle repris de la fiche le dit, sans répéter le chiffre', (tester) async {
    late String plantId;
    final suggested = suggestedWatering();
    final container = await harness.boot(tester, seed: (c) async {
      plantId = (await c.read(plantRepositoryProvider).create(
                NewPlant(name: 'Ficus', speciesName: 'Ficus lyrata', wateringIntervalDays: suggested),
              ))
          .id;
    });
    await harness.pumpApp(tester, container);
    await openWatering(tester, container, plantId);

    // Le mode « Fixe » dit ce qu'il fait ; le chiffre reste au stepper, une
    // seule fois.
    expect(find.text('Le même intervalle toute l\'année.'), findsOneWidget);
    expect(find.text('$suggested jours'), findsOneWidget);
    expect(find.text('Intervalle conseillé · Fiche de l\'espèce'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('un intervalle réglé à la main laisse lire la valeur conseillée', (tester) async {
    late String plantId;
    final container = await harness.boot(tester, seed: (c) async {
      // Sept jours : le défaut de l'application, que la fiche du Ficus lyrata
      // (huit jours l'été, quatorze l'hiver) ne conseille aucun mois.
      plantId = (await c.read(plantRepositoryProvider).create(NewPlant(name: 'Ficus', speciesName: 'Ficus lyrata'))).id;
    });
    await harness.pumpApp(tester, container);
    await openWatering(tester, container, plantId);

    expect(find.text('7 jours'), findsOneWidget);
    expect(find.text('Intervalle conseillé : ${suggestedWatering()} jours · Fiche de l\'espèce'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('sans espèce reconnue, aucun conseil n\'est mis au compte de la plante', (tester) async {
    late String plantId;
    final container = await harness.boot(tester, seed: (c) async {
      plantId = (await c.read(plantRepositoryProvider).create(const NewPlant(name: 'Bouture'))).id;
    });
    await harness.pumpApp(tester, container);
    await openWatering(tester, container, plantId);

    expect(find.text('7 jours'), findsOneWidget);
    expect(find.textContaining('Intervalle conseillé'), findsNothing);
    await tester.pump(const Duration(seconds: 6));
  });
}
