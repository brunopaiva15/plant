import 'package:flora/app/providers.dart';
import 'package:flora/data/problems/problem_catalog.dart';
import 'package:flora/design_system/design_system.dart';
import 'package:flora/domain/auth/auth_repository.dart';
import 'package:flora/domain/diagnosis/diagnosis_record.dart';
import 'package:flora/domain/diagnosis/plant_diagnoser.dart';
import 'package:flora/domain/models/models.dart';
import 'package:flora/domain/problems/plant_problem.dart';
import 'package:flora/features/account/application/membership_providers.dart';
import 'package:flora/features/plants/presentation/timeline_row.dart';
import 'package:flora/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Le journal d'une plante et les diagnostics qu'il garde : l'aperçu dit de
/// quoi il s'agissait, et le compte rendu entier se rouvre d'un doigt.
void main() {
  final catalogue = ProblemCatalog([
    PlantProblem(
      id: '002',
      kind: ProblemKind.disorder,
      scope: ProblemScope.wide,
      fr: "Excès d'eau et asphyxie racinaire",
      en: 'Waterlogging',
      it: 'it',
      de: 'de',
      hosts: const ['Tracheophyta'],
    ),
  ]);

  final diagnostic = Diagnosis(
    summary: 'Feuilles jaunes en bas, terre encore humide.',
    urgent: true,
    causes: [
      const DiagnosisCause(
        title: 'Arrosage trop fréquent',
        likelihood: Likelihood.likely,
        explanation: 'La terre ne sèche pas entre deux arrosages, les racines manquent d\'air.',
        actions: ['Laisser sécher trois centimètres', 'Vérifier le drainage du pot'],
        problemId: '002',
      ),
      const DiagnosisCause(
        title: 'Manque de lumière',
        likelihood: Likelihood.possible,
        explanation: 'La plante est loin de la fenêtre.',
        actions: ['Rapprocher de la fenêtre'],
      ),
      const DiagnosisCause(
        title: 'Carence en azote',
        likelihood: Likelihood.unlikely,
        explanation: 'Le substrat date.',
        actions: [],
      ),
      const DiagnosisCause(
        title: 'Vieillissement normal',
        likelihood: Likelihood.unlikely,
        explanation: 'Les feuilles du bas se retirent avec l\'âge.',
        actions: [],
      ),
    ],
  );

  PlantAction entry({Map<String, Object?> metadata = const {}, String? notes}) => PlantAction(
        id: 'a1',
        plantId: 'p1',
        typeKey: CareKind.note.key,
        occurredAt: DateTime(2026, 6, 15, 14, 32),
        createdAt: DateTime(2026, 6, 15, 14, 32),
        notes: notes,
        metadata: metadata,
      );

  Future<void> pumpJournal(WidgetTester tester, PlantAction action) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        actionTypeByKeyProvider.overrideWith((ref) => const <String, ActionType>{}),
        profileNamesProvider.overrideWith((ref) => const <String, String>{}),
        currentUserProvider.overrideWith((ref) => const Stream<AppUser?>.empty()),
        problemCatalogProvider.overrideWith((ref) async => catalogue),
      ],
      child: MaterialApp(
        theme: buildFloraTheme(Brightness.light),
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(child: TimelineRow(action: action, isLast: true)),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('un diagnostic gardé se rouvre entier depuis le journal', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final record = DiagnosisRecord(diagnosis: diagnostic, symptoms: 'Les feuilles tombent depuis une semaine.');
    await pumpJournal(tester, entry(metadata: {DiagnosisRecord.metadataKey: record.toJson()}, notes: 'Feuilles jaunes en bas, terre encore humide.'));

    // L'aperçu : la ligne se nomme, montre l'urgence, le résumé et les
    // premières pistes — nommées par la base, pas par le modèle.
    expect(find.text('Diagnostic'), findsOneWidget);
    expect(find.text('À traiter rapidement'), findsOneWidget);
    expect(find.text('Feuilles jaunes en bas, terre encore humide.'), findsOneWidget);
    expect(find.text("Excès d'eau et asphyxie racinaire"), findsOneWidget);
    expect(find.text('Arrosage trop fréquent'), findsNothing);

    // Ce qui reste dehors est annoncé, pas caché.
    expect(find.textContaining('Voir le diagnostic complet'), findsOneWidget);
    expect(find.textContaining('1 autre piste'), findsOneWidget);

    // Et tout est là derrière : les explications, les gestes, la quatrième
    // piste, les symptômes signalés au moment de l'analyse.
    await tester.tap(find.textContaining('Voir le diagnostic complet'));
    await tester.pumpAndSettle();

    expect(find.text('La terre ne sèche pas entre deux arrosages, les racines manquent d\'air.'), findsOneWidget);
    expect(find.text('Laisser sécher trois centimètres'), findsOneWidget);
    expect(find.text('Vérifier le drainage du pot'), findsOneWidget);
    expect(find.text('Vieillissement normal'), findsOneWidget);
    expect(find.text('Symptômes signalés'), findsOneWidget);
    expect(find.text('Les feuilles tombent depuis une semaine.'), findsOneWidget);
  });

  testWidgets('une note ordinaire reste une note', (tester) async {
    await pumpJournal(tester, entry(notes: 'Rempotée dans un pot de 20 cm.'));
    expect(find.text('Rempotée dans un pot de 20 cm.'), findsOneWidget);
    expect(find.text('Diagnostic'), findsNothing);
    expect(find.textContaining('Voir le diagnostic complet'), findsNothing);
  });
}
