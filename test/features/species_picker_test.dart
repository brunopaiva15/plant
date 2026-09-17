import 'package:flora/app/providers.dart';
import 'package:flora/data/species/species_index.dart';
import 'package:flora/design_system/design_system.dart';
import 'package:flora/domain/species/species_info.dart';
import 'package:flora/domain/models/models.dart';
import 'package:flora/features/plants/application/plant_providers.dart';
import 'package:flora/features/species/presentation/species_picker_screen.dart';
import 'package:flora/features/species/presentation/species_thumbnail.dart';
import 'package:flora/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// GBIF hors d'atteinte : la recherche locale doit suffire à la liste, et la
/// vignette vient d'un faux service pour ne pas dépendre du réseau.
class _FakeSpecies implements SpeciesService {
  _FakeSpecies(this.image);

  final SpeciesImage? image;

  @override
  Future<List<SpeciesSuggestion>> suggest(String query, {String? languageCode}) async => const [];

  @override
  Future<SpeciesSearchPage> search(String query, {int offset = 0, int limit = 30, String? languageCode}) async =>
      const SpeciesSearchPage(results: [], endOfRecords: true);

  @override
  Future<SpeciesInfo?> lookup(String scientificName) async =>
      SpeciesInfo(key: 1, scientificName: scientificName, canonicalName: scientificName, family: 'Orchidaceae');

  @override
  Future<SpeciesInfo?> byKey(int key) async => null;

  @override
  Future<SpeciesImage?> thumbnail(String scientificName) async => image;
}

class _NoPhotos implements SpeciesImageSource {
  @override
  Future<List<SpeciesImage>> photos(String scientificName) async => const [];
}

Future<void> _pump(WidgetTester tester, {required SpeciesService service}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        speciesServiceProvider.overrideWithValue(service),
        speciesImageSourceProvider.overrideWithValue(_NoPhotos()),
        // Le catalogue étendu n'entre pas dans un test.
        speciesIndexProvider.overrideWith((ref) => SpeciesIndex(const [])),
        plantSummariesProvider.overrideWith((ref, filter) => Stream.value(const <PlantSummary>[])),
      ],
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildFloraTheme(Brightness.light),
        home: const SpeciesPickerScreen(initialQuery: 'Orchidée'),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('la recherche montre la vignette, et la photo ouvre la fiche espèce', (tester) async {
    final service = _FakeSpecies(
      const SpeciesImage(url: 'https://example.org/orchid.jpg', license: 'CC0', rightsHolder: 'Ana'),
    );
    await _pump(tester, service: service);

    // La ligne classée par pertinence est là, avec sa vignette.
    expect(find.text('Orchidée papillon'), findsOneWidget);
    expect(find.byType(SpeciesThumbnail), findsWidgets);

    // Toucher la photo ouvre la fiche espèce — pas le choix de l'espèce.
    await tester.tap(find.byType(SpeciesThumbnail).first);
    await tester.pumpAndSettle();
    expect(find.text("Fiche d'entretien"), findsOneWidget);
  });
}
