import 'package:flora/app/providers.dart';
import 'package:flora/core/network/connectivity.dart';
import 'package:flora/data/services/preferences_service.dart';
import 'package:flora/design_system/design_system.dart';
import 'package:flora/domain/support/support_service.dart';
import 'package:flora/features/support/presentation/support_screen.dart';
import 'package:flora/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// « Auxine est gratuite » : la page qui demande sans rien vendre.
///
/// Quatre invariants : ce qui est ouvert est écrit avant le montant, le
/// montant ne paraît que là où le magasin le propose, la restauration est
/// offerte partout où l'achat l'est — l'achat est un non consommable, et la
/// règle 3.1.1 de l'App Store demande un mécanisme de restauration —, et une
/// fois le soutien versé la page ne redemande rien.

Future<AppLocalizations> _pump(
  WidgetTester tester, {
  SupportOffer? offer = const SupportOffer(id: 'ch.vergasta.plant.support', price: 'CHF 5.00'),
  bool supported = false,
  bool online = true,
  bool compact = false,
}) async {
  SharedPreferences.setMockInitialValues({if (supported) 'has_supported': true});
  final prefs = await PreferencesService.load();
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        preferencesServiceProvider.overrideWithValue(prefs),
        isOnlineProvider.overrideWithValue(online),
        supportOfferProvider.overrideWith((ref) async => offer),
      ],
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildFloraTheme(Brightness.light),
        // La plante du héros respire sans fin : rien ne se stabiliserait.
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: compact
            ? Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(Space.page),
                  child: SupportPitch(onDone: () {}, compact: true),
                ),
              )
            : const SupportScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return AppLocalizations.of(tester.element(find.byType(SupportPitch)));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ce qui est ouvert est écrit avant le montant', (tester) async {
    final l10n = await _pump(tester);
    expect(
      tester.getTopLeft(find.text(l10n.supportBody)).dy,
      lessThan(tester.getTopLeft(find.text('CHF 5.00')).dy),
      reason: 'on montre ce qui est donné avant de demander',
    );
  });

  testWidgets('le montant est écrit en toutes lettres, une fois', (tester) async {
    final l10n = await _pump(tester);
    expect(find.text('CHF 5.00'), findsOneWidget);
    expect(find.text(l10n.supportOnce), findsOneWidget);
    expect(find.text(l10n.supportGive), findsOneWidget);
    expect(find.text(l10n.supportNothingLocked), findsOneWidget);
    expect(find.text(l10n.supportRestore), findsOneWidget);
  });

  testWidgets("sans magasin, une phrase plutôt qu'un bouton mort", (tester) async {
    final l10n = await _pump(tester, offer: null);
    expect(find.text(l10n.supportUnavailable), findsOneWidget);
    expect(find.text(l10n.supportGive), findsNothing);
    expect(find.text('CHF 5.00'), findsNothing);
    // Ce que l'application est, en revanche, reste écrit.
    expect(find.text(l10n.supportBody), findsOneWidget);
  });

  testWidgets("hors ligne, l'achat ne se propose pas", (tester) async {
    final l10n = await _pump(tester, online: false);
    expect(find.text(l10n.offlineSupport), findsOneWidget);
    expect(find.text(l10n.supportGive), findsNothing);
  });

  testWidgets('une fois le soutien versé, la page ne redemande rien', (tester) async {
    final l10n = await _pump(tester, supported: true);
    expect(find.text(l10n.supportThanksTitle), findsOneWidget);
    expect(find.text(l10n.supportGive), findsNothing);
    expect(find.text('CHF 5.00'), findsNothing);
    // La phrase du haut descend sous le trait : la page se ferme sur ce
    // qu'elle est venue dire plutôt que sur un blanc.
    expect(find.text(l10n.supportBody), findsOneWidget);
  });

  testWidgets("la restauration est offerte partout où l'achat l'est", (tester) async {
    // Non consommable, donc restaurable : règle 3.1.1. Et c'est à
    // l'onboarding qu'elle sert le plus — quelqu'un qui change de téléphone y
    // repasse avant de voir les réglages.
    final l10n = await _pump(tester, compact: true);
    expect(find.text(l10n.supportRestore), findsOneWidget);
  });

  testWidgets("la version courte tient moins de place, sans rien retirer à l'offre", (tester) async {
    await _pump(tester);
    final full = tester.getSize(find.byType(SupportPitch)).height;
    final l10n = await _pump(tester, compact: true);
    expect(tester.getSize(find.byType(SupportPitch)).height, lessThan(full));
    expect(find.text('CHF 5.00'), findsOneWidget);
    expect(find.text(l10n.supportGive), findsOneWidget);
    // « Continuer sans » est de la navigation d'onboarding : c'est l'étape
    // qui le dessine, dans son propre style, et non la proposition.
    expect(find.text(l10n.supportNoThanks), findsNothing);
  });
}
