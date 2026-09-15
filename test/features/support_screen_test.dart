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
/// Ce qu'elle promet tient en trois invariants, et ce sont eux qu'on tient
/// ici : le relevé des gratuités est écrit avant le montant, le montant ne
/// paraît que là où le magasin le propose, et une fois le soutien versé la
/// page ne redemande rien.

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

  testWidgets('le relevé des gratuités est écrit avant le montant', (tester) async {
    final l10n = await _pump(tester);
    for (final perk in [l10n.supportPerkFeatures, l10n.supportPerkNoAds, l10n.supportPerkNoSubscription, l10n.supportPerkNoAccount]) {
      expect(find.text(perk), findsOneWidget, reason: 'le relevé a perdu « $perk »');
    }
    expect(find.text(l10n.supportOptional.toUpperCase()), findsOneWidget, reason: "l'étiquette dit que rien n'est exigé");
    expect(
      tester.getTopLeft(find.text(l10n.supportPerkFeatures)).dy,
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
    // Le relevé, lui, reste vrai : c'est l'application qu'il décrit.
    expect(find.text(l10n.supportPerkFeatures), findsOneWidget);
  });

  testWidgets("hors ligne, l'achat ne se propose pas", (tester) async {
    final l10n = await _pump(tester, online: false);
    expect(find.text(l10n.offlineSupport), findsOneWidget);
    expect(find.text(l10n.supportGive), findsNothing);
  });

  testWidgets('une fois le soutien versé, la page ne redemande rien', (tester) async {
    final l10n = await _pump(tester, supported: true);
    expect(find.text(l10n.supportThanksTitle), findsOneWidget);
    expect(find.text(l10n.supportAlready), findsOneWidget);
    expect(find.text(l10n.supportGive), findsNothing);
    expect(find.text('CHF 5.00'), findsNothing);
    expect(find.text(l10n.supportOptional.toUpperCase()), findsNothing, reason: "l'étiquette a laissé la place au sceau");
  });

  testWidgets("dans l'onboarding, la version courte tient moins de place", (tester) async {
    // Là, la page partage la hauteur avec les points de progression : elle
    // laisse le relevé aux réglages pour que « Continuer sans » reste sous
    // les yeux de qui vient d'installer l'application.
    await _pump(tester);
    final full = tester.getSize(find.byType(SupportPitch)).height;
    final l10n = await _pump(tester, compact: true);
    expect(tester.getSize(find.byType(SupportPitch)).height, lessThan(full));
    expect(find.text(l10n.supportPerkFeatures), findsNothing);
    expect(find.text(l10n.supportNoThanks), findsOneWidget);
    expect(find.text('CHF 5.00'), findsOneWidget, reason: 'la proposition, elle, reste entière');
  });
}
