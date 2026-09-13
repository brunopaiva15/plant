// Les captures du magasin, prises dans la vraie app sur le simulateur iPhone.
//
// Lancé par store/capture_ios.sh, une fois par langue :
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/store_screenshots_test.dart \
//     --dart-define=DEMO=true --dart-define=DEMO_PHOTOS=http://localhost:8081/demo-photos \
//     --dart-define=STORE_LANG=fr
//
// Le jeu de démo (core/demo/demo_seed.dart) fournit les plantes ; ici on
// règle les préférences d'un téléphone déjà en usage (prénom, ville pour la
// météo), puis on parcourt les écrans comme un doigt le ferait, et
// chaque capture part vers le driver, qui l'écrit sur la machine. Une scène
// qui échoue est dite, pas fatale : les autres captures se prennent quand même.
import 'package:flora/app/app.dart';
import 'package:flora/app/router.dart';
import 'package:flora/l10n/generated/app_localizations.dart';
import 'package:flora/main.dart' as app;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const lang = String.fromEnvironment('STORE_LANG', defaultValue: 'fr');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('captures du magasin ($lang)', (tester) async {
    final en = lang == 'en';

    // Un téléphone déjà réglé, pas un premier lancement.
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await prefs.setString('locale', lang);
    await prefs.setBool('onboarding_done', true);
    await prefs.setBool('notification_prompt_shown', true);
    await prefs.setString('display_name', 'Camille');
    await prefs.setString('weather_place', 'Lausanne|46.5197|6.6323');
    // La question des photos d'entraînement d'Iris se pose après une
    // identification : déjà posée, pour que la feuille « Espèce » reste seule.
    await prefs.setBool('iris_feedback_asked', true);

    await app.main();
    await wait(tester, 5000);

    final l10n = lookupAppLocalizations(Locale(lang));
    final router = ProviderScope.containerOf(tester.element(find.byType(FloraApp))).read(routerProvider);
    final basil = en ? 'Basil' : 'Basilic';

    Future<void> go(String path, [int ms = 3000]) async {
      router.go(path);
      await wait(tester, ms);
    }

    Future<void> shot(String name) async {
      await wait(tester, 1000);
      await binding.takeScreenshot(name);
    }

    /// Ferme ce qui est ouvert par-dessus (feuille, page poussée).
    Future<void> dismiss() async {
      await tester.state<NavigatorState>(find.byType(Navigator).first).maybePop();
      await wait(tester, 1500);
    }

    Future<void> tapText(String text) async {
      await tester.tap(find.text(text).hitTestable().first);
      await wait(tester, 2500);
    }

    Future<void> tapLabel(String label) async {
      await tester.tap(find.bySemanticsLabel(label).hitTestable().first);
      await wait(tester, 2500);
    }

    /// Fait défiler la page jusqu'à ce que [finder] soit visible.
    Future<void> reveal(Finder finder) async {
      await tester.dragUntilVisible(finder.hitTestable(), find.byType(Scrollable).hitTestable().first, const Offset(0, -250));
      await wait(tester, 800);
    }

    Future<void> scene(String name, Future<void> Function() body) async {
      try {
        await body();
      } catch (e, st) {
        debugPrint('capture « $name » manquée : $e\n$st');
      }
      await go(Routes.today, 1500);
    }

    await scene('today', () async {
      await go(Routes.today);
      await shot('today');
    });

    await scene('plants', () async {
      await go(Routes.plants);
      await shot('plants');
    });

    await scene('plant', () async {
      await go(Routes.plants);
      await tapText(basil);
      await shot('plant');
    });

    await scene('care', () async {
      await go(Routes.plants);
      await tapText(basil);
      await reveal(find.text(l10n.careHowTo));
      await tapText(l10n.careHowTo);
      await shot('care');
      await dismiss();
    });

    await scene('schedule', () async {
      await go(Routes.plants);
      await tapText(basil);
      await tapText(l10n.schedule);
      await shot('schedule');
      await dismiss();
    });

    await scene('garden', () async {
      await go(Routes.garden);
      await shot('garden');
      await tapText(l10n.gardenCalendar);
      await shot('garden-calendar');
      await tapText(l10n.gardenTasks);
      await shot('garden-tasks');
      await tapText(l10n.gardenInventory);
      await shot('garden-inventory');
    });

    await scene('dashboard', () async {
      await go(Routes.dashboard);
      await shot('dashboard');
    });

    await scene('backup', () async {
      await go(Routes.backup);
      await shot('backup');
    });

    await scene('profile', () async {
      await go(Routes.profile);
      await shot('profile');
    });

    // L'identification par Iris, sur la photo du Ficus lyrata : le modèle
    // tourne vraiment, la feuille « Espèce » est celle de l'app.
    await scene('identify', () async {
      await go(Routes.plants);
      await tapText('Ficus lyrata');
      await tapLabel(l10n.more);
      await tapText(l10n.identify);
      await wait(tester, 8000);
      await shot('identify');
      await dismiss();
    });

    // Le diagnostic gardé au journal de la Calathea, rouvert en entier.
    await scene('diagnosis', () async {
      await go(Routes.plants);
      await tapText('Calathea');
      await reveal(find.bySemanticsLabel(l10n.diagnosisOpen));
      await tapLabel(l10n.diagnosisOpen);
      await shot('diagnosis');
      await dismiss();
    });

    // En dernier : l'ajout d'une plante, à l'étape Photo.
    await scene('add-plant', () async {
      await go(Routes.plants);
      await tapLabel(l10n.addPlant);
      await wait(tester, 2000);
      await shot('add-plant');
      await dismiss();
    });
  });
}

/// Laisse l'app vivre [ms] millisecondes réelles : les animations se posent,
/// les images arrivent, les requêtes répondent. Une attente de repos complet
/// (`pumpAndSettle`) ne finirait jamais sur les écrans qui respirent.
Future<void> wait(WidgetTester tester, int ms) => tester.pump(Duration(milliseconds: ms));
