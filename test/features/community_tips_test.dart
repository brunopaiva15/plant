import 'dart:async';

import 'package:flora/app/providers.dart';
import 'package:flora/core/network/connectivity.dart';
import 'package:flora/core/network/network_failure.dart';
import 'package:flora/design_system/design_system.dart';
import 'package:flora/domain/community/species_tip.dart';
import 'package:flora/features/community/presentation/community_tips_section.dart';
import 'package:flora/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_auth_repository.dart';

/// Un service de laboratoire : des conseils donnés d'avance, et de quoi jouer
/// les trois états qui comptent — pas de backend, backend sans compte, et une
/// requête qui part sans jamais revenir.
class _Tips implements CommunityTipsService {
  _Tips({this.available = true, this.writes = true, this.items = const [], this.hangs = false});

  final bool available;
  final bool writes;
  final List<SpeciesTip> items;
  final bool hangs;

  /// La clé demandée au dernier appel : c'est elle qui relie deux personnes
  /// qui n'écrivent pas le nom de la même façon.
  String? asked;

  @override
  bool get isAvailable => available;

  @override
  bool get canPublish => writes;

  @override
  Future<List<SpeciesTip>> tips(String speciesId) {
    asked = speciesId;
    // Le vrai service borne sa requête de la même façon : sans cela, un appel
    // parti sans réseau n'a ni réponse ni erreur.
    return hangs ? Completer<List<SpeciesTip>>().future.timeout(networkTimeout) : Future.value(items);
  }

  @override
  Future<SpeciesTip> publish({required String speciesId, required String speciesName, required String body}) async =>
      throw UnimplementedError();

  @override
  Future<void> withdraw(String tipId) async {}

  @override
  Future<SpeciesTip> vote(String tipId, {required bool helpful}) async => throw UnimplementedError();

  @override
  Future<void> report(String tipId) async {}

  @override
  Future<bool> isModerator() async => false;

  @override
  Future<List<SpeciesTip>> reported() async => const [];

  @override
  Future<void> moderate(String tipId, {required bool hidden}) async {}

  @override
  Future<void> remove(String tipId) async {}
}

class _Probe implements Reachability {
  _Probe(this.reachable);

  final bool reachable;

  @override
  Future<bool> probe() async => reachable;
}

SpeciesTip _tip({
  String id = 't1',
  String author = 'Laura',
  String body = 'Un bain de vingt minutes vaut mieux qu\'un arrosage par-dessus.',
  int votes = 0,
  bool mine = false,
  bool hidden = false,
}) =>
    SpeciesTip(
      id: id,
      speciesId: 'hoya-kerrii',
      authorName: author,
      body: body,
      votes: votes,
      createdAt: DateTime(2026, 1, 1),
      mine: mine,
      hidden: hidden,
    );

Future<void> _pump(
  WidgetTester tester, {
  required _Tips service,
  bool online = true,
  bool remoteAuth = false,
  String species = 'Hoya kerrii',
}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        communityTipsServiceProvider.overrideWithValue(service),
        authRepositoryProvider.overrideWithValue(FakeAuthRepository(remote: remoteAuth)),
        reachabilityProvider.overrideWithValue(_Probe(online)),
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
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(Space.page),
            child: CommunityTipsSection(speciesName: species),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sans backend, la section n\'existe pas', (tester) async {
    final service = _Tips(available: false, items: [_tip()]);
    await _pump(tester, service: service);

    expect(find.text('Conseils de la communauté'), findsNothing);
    expect(service.asked, isNull);
  });

  testWidgets('sans nom d\'espèce, rien à rattacher', (tester) async {
    final service = _Tips(items: [_tip()]);
    await _pump(tester, service: service, species: '   ');

    expect(find.text('Conseils de la communauté'), findsNothing);
    expect(service.asked, isNull);
  });

  testWidgets('les conseils se lisent, rangés sous la clé de l\'espèce', (tester) async {
    final service = _Tips(items: [_tip(votes: 3), _tip(id: 't2', author: 'Théo', body: 'Il tient très bien derrière un voilage, au sud.')]);
    await _pump(tester, service: service);

    // La clé, pas le nom tel qu'il est écrit : « Hoya kerrii », « hoya
    // kerrii » et « HOYA KERRII » lisent la même page.
    expect(service.asked, 'hoya-kerrii');
    expect(find.text('Conseils de la communauté'), findsOneWidget);
    expect(find.textContaining('Un bain de vingt minutes'), findsOneWidget);
    expect(find.textContaining('derrière un voilage'), findsOneWidget);
    expect(find.text('Utile · 3'), findsOneWidget);
  });

  testWidgets('aucun conseil, la section le dit plutôt que de disparaître', (tester) async {
    await _pump(tester, service: _Tips());

    expect(find.text('Conseils de la communauté'), findsOneWidget);
    expect(find.text('Aucun conseil sur cette espèce.'), findsOneWidget);
    expect(find.text('Écrire un conseil'), findsOneWidget);
  });

  testWidgets('sans compte, la lecture reste et le bouton laisse la place à sa raison', (tester) async {
    await _pump(tester, service: _Tips(writes: false, items: [_tip()]));

    expect(find.textContaining('Un bain de vingt minutes'), findsOneWidget);
    expect(find.text('Écrire un conseil'), findsNothing);
    expect(find.text('Publier un conseil demande un compte.'), findsOneWidget);
    // Là où la connexion n'existe pas, aucun écran ne la promet.
    expect(find.text('Se connecter'), findsNothing);
  });

  testWidgets('son propre conseil s\'ouvre en modification, pas en signalement', (tester) async {
    await _pump(tester, service: _Tips(items: [_tip(mine: true, hidden: true)]));

    // L'auteur et la date tiennent sur une ligne : c'est le début qui compte.
    expect(find.textContaining('Votre conseil'), findsOneWidget);
    expect(find.text('Écrire un conseil'), findsNothing);
    // Signalé, il disparaît pour les autres sans disparaître pour son auteur :
    // sans cette ligne, il le croirait encore en ligne.
    expect(find.text('Signalé : les autres ne le voient plus.'), findsOneWidget);
  });

  testWidgets('hors ligne, la section le dit au lieu de tourner', (tester) async {
    final service = _Tips(hangs: true);
    await _pump(tester, service: service, online: false);

    expect(find.text('Hors ligne'), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);
    expect(find.byType(AdaptiveProgress), findsNothing);

    // Le reste de la fiche d'entretien, lui, se lit sans réseau : rien ici ne
    // doit empêcher la page de se dessiner.
    expect(find.text('Conseils de la communauté'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // La requête a pu partir avant que la sonde ne conclue « hors ligne » :
    // son délai finit par s'écouler, on le laisse passer pour ne pas laisser
    // un minuteur en suspens après le test.
    await tester.pump(networkTimeout);
  });
}
