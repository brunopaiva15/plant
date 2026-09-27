import 'package:flora/app/providers.dart';
import 'package:flora/app/router.dart';
import 'package:flora/features/whats_new/application/whats_new.dart';
import 'package:flora/features/whats_new/presentation/whats_new_sheet.dart';
import 'package:flutter_test/flutter_test.dart';

import '../app/app_smoke_test.dart' as harness;

/// Les nouveautés : une fois par édition, après l'accueil, et jamais
/// par-dessus ce qu'un lien ou un raccourci a déjà ouvert.
void main() {
  group('quand les montrer', () {
    test('une installation neuve ou une mise à jour les voit, une fois l\'accueil passé', () {
      expect(WhatsNew.shouldShow(seen: null, onboardingDone: true), isTrue);
      expect(WhatsNew.shouldShow(seen: null, onboardingDone: false), isFalse);
    });

    test('une édition vue ne revient pas, une nouvelle si', () {
      expect(WhatsNew.shouldShow(seen: WhatsNew.edition, onboardingDone: true), isFalse);
      expect(WhatsNew.shouldShow(seen: WhatsNew.edition - 1, onboardingDone: true), isTrue);
    });
  });

  testWidgets('elles s\'ouvrent après l\'animation d\'ouverture, et sont notées vues', (tester) async {
    final container = await harness.boot(tester, whatsNewSeen: false);
    await harness.pumpApp(tester, container, settleAfter: false);
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Nouveautés'), findsNothing, reason: 'pas pendant l\'ouverture');
    await tester.pump(WhatsNewHost.delay);
    await harness.settle(tester);
    expect(find.text('Nouveautés'), findsOneWidget);
    expect(find.text("L'arrosage selon le pot"), findsOneWidget);
    expect(container.read(preferencesServiceProvider).whatsNewSeen, WhatsNew.edition);

    // La police des tests est plus large que la vraie : la feuille défile.
    await tester.ensureVisible(find.text('Continuer'));
    await harness.settle(tester);
    await tester.tap(find.text('Continuer'));
    await harness.settle(tester);
    expect(find.text('Nouveautés'), findsNothing);
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('une édition déjà vue ne s\'ouvre pas', (tester) async {
    final container = await harness.boot(tester);
    await harness.pumpApp(tester, container);
    await tester.pump(WhatsNewHost.delay * 2);
    await harness.settle(tester);
    expect(find.text('Nouveautés'), findsNothing);
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('une page déjà ouverte par-dessus : elles attendent la prochaine ouverture', (tester) async {
    final container = await harness.boot(tester, whatsNewSeen: false);
    await harness.pumpApp(tester, container);
    container.read(routerProvider).push(Routes.finder);
    await harness.settle(tester);

    await tester.pump(WhatsNewHost.delay);
    await harness.settle(tester);
    expect(find.text('Nouveautés'), findsNothing);
    expect(container.read(preferencesServiceProvider).whatsNewSeen, isNull, reason: 'pas vues, donc pas marquées');
    await tester.pump(const Duration(seconds: 6));
  });
}
