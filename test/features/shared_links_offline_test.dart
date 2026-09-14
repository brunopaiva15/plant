import 'dart:async';

import 'package:flora/app/providers.dart';
import 'package:flora/core/network/connectivity.dart';
import 'package:flora/core/network/network_failure.dart';
import 'package:flora/design_system/design_system.dart';
import 'package:flora/domain/sharing/shared_link.dart';
import 'package:flora/features/sharing/presentation/share_link_sheet.dart';
import 'package:flora/features/sharing/presentation/shared_links_screen.dart';
import 'package:flora/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Le serveur des liens partagés, tel qu'un appareil sans réseau le voit :
/// une requête qui part et ne revient jamais. C'est exactement ce que faisait
/// l'écran — un tourniquet sans fin.
class _Sharing implements SharingService {
  _Sharing({this.links = const [], this.hangs = false});

  final List<SharedLink> links;
  final bool hangs;
  int calls = 0;

  @override
  bool get isAvailable => true;

  @override
  String get baseUrl => 'https://x.test/s';

  @override
  Future<List<SharedLink>> list() {
    calls++;
    // Le vrai service borne sa requête Postgrest de la même façon : sans cela
    // une requête partie sans réseau n'a ni réponse ni erreur.
    return hangs ? Completer<List<SharedLink>>().future.timeout(networkTimeout) : Future.value(links);
  }

  @override
  Future<SharedLink> create(NewSharedLink data) async => throw UnimplementedError();

  @override
  Future<void> revoke(String id) async {}

  @override
  Future<void> delete(String id) async {}
}

class _Probe implements Reachability {
  _Probe(this.reachable);

  bool reachable;

  @override
  Future<bool> probe() async => reachable;
}

SharedLink _link() => SharedLink(
      id: 'l1',
      plantId: 'p1',
      kind: SharedKind.plant,
      token: 'abcDEF123456789012345x',
      title: 'Mon monstera',
      unlisted: true,
      createdAt: DateTime(2026, 1, 1),
    );

Future<void> _pump(WidgetTester tester, {required _Sharing sharing, required _Probe probe}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharingServiceProvider.overrideWithValue(sharing),
        reachabilityProvider.overrideWithValue(probe),
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
        home: const SharedLinksScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('hors ligne, l\'écran le dit au lieu de tourner', (tester) async {
    final sharing = _Sharing(hangs: true);
    await _pump(tester, sharing: sharing, probe: _Probe(false));

    expect(find.text('Hors ligne'), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);
    expect(find.byType(AdaptiveProgress), findsNothing);

    // Et une fois le réseau constaté absent, la requête ne repart plus : la
    // réponse est immédiate, là où le délai d'attente durait vingt secondes.
    final container = ProviderScope.containerOf(tester.element(find.byType(SharedLinksScreen)));
    final before = sharing.calls;
    container.invalidate(sharedLinksProvider);
    await tester.pumpAndSettle();
    expect(sharing.calls, before);
    expect(find.text('Hors ligne'), findsOneWidget);

    // La requête partie avant que la sonde n'ait tranché s'éteint toute seule,
    // et son résultat tardif ne ramène pas le tourniquet. Dans l'application,
    // la sonde part au lancement : cet aller-retour n'a lieu qu'au tout
    // premier instant.
    await tester.pump(networkTimeout + const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Hors ligne'), findsOneWidget);
    expect(find.byType(AdaptiveProgress), findsNothing);
  });

  testWidgets('en ligne, la liste s\'affiche', (tester) async {
    final sharing = _Sharing(links: [_link()]);
    await _pump(tester, sharing: sharing, probe: _Probe(true));

    expect(find.text('Mon monstera'), findsOneWidget);
    expect(find.text('Hors ligne'), findsNothing);
    expect(sharing.calls, 1);
  });

  testWidgets('une requête partie qui ne revient pas finit par rendre la main', (tester) async {
    // La sonde se trompe — un réseau qui laisse ouvrir une connexion mais ne
    // porte rien — et la requête reste en l'air. C'est le cas qui faisait
    // tourner l'écran sans fin : Riverpod réessayait dix fois derrière le
    // tourniquet, et la branche « erreur » n'arrivait qu'au bout de plusieurs
    // minutes. Une tentative, un délai, un écran sur lequel on peut agir.
    final sharing = _Sharing(hangs: true);
    await _pump(tester, sharing: sharing, probe: _Probe(true));

    // Deux tours : le premier laisse le provider partir en requête, le second
    // dépasse son délai d'expiration.
    await tester.pump(networkTimeout + const Duration(seconds: 1));
    await tester.pump(networkTimeout + const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.byType(AdaptiveProgress), findsNothing);
    expect(find.text('Réessayer'), findsOneWidget);
    // Une seule tentative : la reprise est au doigt de la personne, pas dans
    // une boucle invisible.
    expect(sharing.calls, 1);
  });

  testWidgets('le réseau revient, la liste se remplit seule', (tester) async {
    final sharing = _Sharing(links: [_link()]);
    final probe = _Probe(false);
    await _pump(tester, sharing: sharing, probe: probe);
    expect(find.text('Hors ligne'), findsOneWidget);

    // Personne ne touche l'écran : c'est la sonde qui rouvre le passage, et
    // le provider repart parce qu'il suit l'état du réseau.
    probe.reachable = true;
    final element = tester.element(find.byType(SharedLinksScreen));
    await ProviderScope.containerOf(element).read(connectivityProvider.notifier).refresh();
    await tester.pumpAndSettle();

    expect(find.text('Mon monstera'), findsOneWidget);
    expect(find.text('Hors ligne'), findsNothing);
  });
}
