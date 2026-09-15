import 'package:flora/app/providers.dart';
import 'package:flora/core/network/connectivity.dart';
import 'package:flora/design_system/design_system.dart';
import 'package:flora/domain/community/species_tip.dart';
import 'package:flora/features/community/application/moderation_providers.dart';
import 'package:flora/features/community/presentation/moderation_screen.dart';
import 'package:flora/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// La modération, telle que le serveur la gouverne : la liste des modérateurs
/// est une table que rien ne laisse écrire depuis l'application, et à qui ne
/// modère pas le serveur ne rend rien. L'écran ne fait que montrer ce qu'il
/// reçoit et renvoyer deux gestes.
class _Tips implements CommunityTipsService {
  _Tips({this.moderator = true, this.items = const []});

  final bool moderator;
  final List<SpeciesTip> items;

  final moderated = <(String, bool)>[];
  final removed = <String>[];

  @override
  bool get isAvailable => true;

  @override
  bool get canPublish => true;

  @override
  Future<bool> isModerator() async => moderator;

  @override
  Future<List<SpeciesTip>> reported() async => moderator ? items : const [];

  @override
  Future<void> moderate(String tipId, {required bool hidden}) async => moderated.add((tipId, hidden));

  @override
  Future<void> remove(String tipId) async => removed.add(tipId);

  @override
  Future<List<SpeciesTip>> tips(String speciesId) async => const [];

  @override
  Future<SpeciesTip> publish({required String speciesId, required String speciesName, required String body}) async =>
      throw UnimplementedError();

  @override
  Future<void> withdraw(String tipId) async {}

  @override
  Future<SpeciesTip> vote(String tipId, {required bool helpful}) async => throw UnimplementedError();

  @override
  Future<void> report(String tipId) async {}
}

SpeciesTip _reported({String id = 't1', int reports = 4, bool hidden = true}) => SpeciesTip(
      id: id,
      speciesId: 'hoya-kerrii',
      speciesName: 'Hoya kerrii',
      authorName: 'Théo',
      body: 'Un conseil que plusieurs personnes ont signalé.',
      votes: 0,
      createdAt: DateTime(2026, 1, 1),
      reports: reports,
      hidden: hidden,
    );

Future<ProviderContainer> _pump(WidgetTester tester, _Tips service) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [communityTipsServiceProvider.overrideWithValue(service)],
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
        home: const ModerationScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(ModerationScreen)));
}

void main() {
  testWidgets('les conseils signalés se lisent avec leur espèce et leur compte', (tester) async {
    await _pump(tester, _Tips(items: [_reported()]));

    expect(find.text('Hoya kerrii'), findsOneWidget);
    expect(find.text('4 signalements'), findsOneWidget);
    expect(find.textContaining('plusieurs personnes ont signalé'), findsOneWidget);
    // Déjà masqué : le geste qui reste est de le rétablir.
    expect(find.text('Rétablir'), findsOneWidget);
    expect(find.text('Masquer'), findsNothing);
  });

  testWidgets('un conseil encore visible se masque', (tester) async {
    final service = _Tips(items: [_reported(hidden: false, reports: 1)]);
    await _pump(tester, service);

    expect(find.text('1 signalement'), findsOneWidget);
    await tester.tap(find.text('Masquer'));
    await tester.pumpAndSettle();
    expect(service.moderated, [('t1', true)]);
  });

  testWidgets('rien à modérer, l\'écran le dit', (tester) async {
    await _pump(tester, _Tips());

    expect(find.text('Aucun conseil signalé.'), findsOneWidget);
  });

  testWidgets('qui ne modère pas ne reçoit rien du serveur', (tester) async {
    final service = _Tips(moderator: false, items: [_reported()]);
    final container = await _pump(tester, service);

    expect(find.text('Hoya kerrii'), findsNothing);
    expect(find.text('Aucun conseil signalé.'), findsOneWidget);
    // Et la ligne des réglages ne paraît pas : c'est le serveur qui tranche,
    // pas une colonne que l'application pourrait écrire.
    await expectLater(container.read(tipModeratorProvider.future), completion(isFalse));
  });

  testWidgets('hors ligne, l\'écran le dit au lieu de tourner', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          communityTipsServiceProvider.overrideWithValue(_Tips(items: [_reported()])),
          reachabilityProvider.overrideWithValue(_Offline()),
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
          home: const ModerationScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hors ligne'), findsOneWidget);
    expect(find.byType(AdaptiveProgress), findsNothing);
  });
}

class _Offline implements Reachability {
  @override
  Future<bool> probe() async => false;
}
