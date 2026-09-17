import 'package:flora/app/providers.dart';
import 'package:flora/data/species/species_index.dart';
import 'package:flora/design_system/design_system.dart';
import 'package:flora/domain/species/species_info.dart';
import 'package:flora/features/species/presentation/species_field.dart';
import 'package:flora/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// GBIF n'est pas joignable depuis un test : la recherche locale doit suffire.
class _SilentSpecies implements SpeciesService {
  @override
  Future<List<SpeciesSuggestion>> suggest(String query, {String? languageCode}) async => const [];

  @override
  Future<SpeciesSearchPage> search(String query, {int offset = 0, int limit = 30, String? languageCode}) async =>
      const SpeciesSearchPage(results: [], endOfRecords: true);

  @override
  Future<SpeciesInfo?> lookup(String scientificName) async => null;

  @override
  Future<SpeciesInfo?> byKey(int key) async => null;

  @override
  Future<SpeciesImage?> thumbnail(String scientificName) async => null;
}

Future<void> _pump(WidgetTester tester, TextEditingController controller) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        speciesServiceProvider.overrideWithValue(_SilentSpecies()),
        // Le catalogue étendu n'entre pas dans un test ; la recherche locale
        // se limite au catalogue trié à la main.
        speciesIndexProvider.overrideWith((ref) => SpeciesIndex(const [])),
      ],
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildFloraTheme(Brightness.light),
        home: Scaffold(body: SpeciesField(controller: controller)),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('« Orchidée » propose le catalogue Auxine avant GBIF', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await _pump(tester, controller);

    await tester.enterText(find.byType(TextField), 'Orchidée');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('Phalaenopsis amabilis · Orchidée papillon'), findsOneWidget);
  });
}
