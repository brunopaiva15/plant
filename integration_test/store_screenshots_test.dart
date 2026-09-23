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
import 'package:flora/core/native_shell.dart';
import 'package:flora/l10n/generated/app_localizations.dart';
import 'package:flora/main.dart' as app;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const lang = String.fromEnvironment('STORE_LANG', defaultValue: 'fr');

/// Les scènes à jouer, séparées par des virgules ; toutes sans rien.
/// `--dart-define=STORE_SCENES=identify,diagnosis` pour en reprendre deux.
const only = String.fromEnvironment('STORE_SCENES');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('captures du magasin ($lang)', (tester) async {
    String tr(String fr, String en, String de, String it) => switch (lang) { 'en' => en, 'de' => de, 'it' => it, _ => fr };

    // Un téléphone déjà réglé, pas un premier lancement.
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await prefs.setString('locale', lang);
    await prefs.setBool('onboarding_done', true);
    await prefs.setBool('notification_prompt_shown', true);
    // « À venir » en grille sur l'écran du matin.
    await prefs.setBool('upcoming_grid_view', true);
    await prefs.setString('display_name', 'Camille');
    await prefs.setString('weather_place', 'Lausanne|46.5197|6.6323');
    // La question des photos d'entraînement d'Iris se pose après une
    // identification : déjà posée, pour que la feuille « Espèce » reste seule.
    await prefs.setBool('iris_feedback_asked', true);

    // Deux minutes de silence dans la sortie de `flutter drive`, c'est long
    // quand on ne sait pas si ça avance : chaque étape se dit.
    debugPrint('démarrage : le jeu de démo se charge, ses photos comprises…');
    await app.main();
    await wait(tester, 5000);
    debugPrint('application ouverte en « $lang »');

    final l10n = lookupAppLocalizations(Locale(lang));
    final router = ProviderScope.containerOf(tester.element(find.byType(FloraApp))).read(routerProvider);
    final basil = tr('Basilic', 'Basil', 'Basilikum', 'Basilico');

    Future<void> go(String path, [int ms = 3000]) async {
      router.go(path);
      await wait(tester, ms);
    }

    Future<void> shot(String name) async {
      await wait(tester, 1000);
      await binding.takeScreenshot(name);
      debugPrint('  capture « $name »');
    }

    // Le navigateur racine, celui des feuilles ; les pages d'un onglet vivent
    // dans le navigateur de leur branche, et chaque branche garde sa pile
    // d'un passage à l'autre : go() ne la vide pas.
    NavigatorState rootNavigator() => tester.state<NavigatorState>(find.byType(Navigator).first);

    /// Ferme ce qui est ouvert par-dessus : une feuille sur le navigateur
    /// racine d'abord, sinon la page poussée dans l'onglet.
    Future<void> dismiss() async {
      if (rootNavigator().canPop()) {
        rootNavigator().pop();
      } else if (router.canPop()) {
        router.pop();
      }
      await wait(tester, 1500);
    }

    /// Remet l'app à plat : plus rien par-dessus, chaque onglet à sa racine.
    Future<void> reset() async {
      for (var i = 0; i < 6 && rootNavigator().canPop(); i++) {
        rootNavigator().pop();
        await wait(tester, 600);
      }
      for (final tab in [Routes.plants, Routes.garden, Routes.profile, Routes.today]) {
        router.go(tab);
        await wait(tester, 400);
        for (var i = 0; i < 6 && router.canPop(); i++) {
          router.pop();
          await wait(tester, 600);
        }
      }
      await wait(tester, 1000);
    }

    /// Ce qui est touchable en premier, ou à défaut la première occurrence :
    /// les onglets gardent leurs pages en mémoire, et un texte existe souvent
    /// plusieurs fois dans l'arbre.
    Finder touchable(Finder finder) => finder.hitTestable().evaluate().isNotEmpty ? finder.hitTestable().first : finder.first;

    Future<void> tapText(String text) async {
      await tester.tap(touchable(find.text(text)), warnIfMissed: false);
      await wait(tester, 2500);
    }

    Future<void> tapLabel(String label) async {
      await tester.tap(touchable(find.bySemanticsLabel(label)), warnIfMissed: false);
      await wait(tester, 2500);
    }

    /// Fait défiler la page jusqu'à ce que [finder] soit touchable, par des
    /// glissements au milieu de l'écran.
    ///
    /// Pas `dragUntilVisible` : il s'accroche à un défilement précis, et
    /// celui de la fiche est reconstruit en cours de route — le finder ne
    /// retrouve alors plus rien. Un doigt au milieu de la page, lui, tombe
    /// toujours sur la bonne liste.
    Future<void> reveal(Finder finder) async {
      final size = tester.view.physicalSize / tester.view.devicePixelRatio;
      final from = Offset(size.width / 2, size.height * 0.62);
      // La barre d'onglets flotte au-dessus du bas de la page : une cible
      // qui s'arrête dessous est visible mais intouchable, et le doigt
      // tomberait sur un onglet. On déroule jusqu'à ce qu'elle remonte.
      final ceiling = size.height * 0.78;
      bool reached() {
        final found = finder.hitTestable().evaluate();
        return found.isNotEmpty && tester.getCenter(finder.hitTestable().first).dy < ceiling;
      }

      for (var i = 0; i < 25 && !reached(); i++) {
        await tester.dragFrom(from, const Offset(0, -260));
        await wait(tester, 400);
      }
      if (finder.hitTestable().evaluate().isEmpty) throw StateError('rien trouvé après avoir déroulé la page');
      await wait(tester, 800);
    }

    Future<void> scene(String name, Future<void> Function() body) async {
      if (only.isNotEmpty && !only.split(',').contains(name)) return;
      debugPrint('scène « $name »…');
      await reset();
      try {
        await body();
      } catch (e, st) {
        // L'écran du moment et ce qu'on y lit, pour comprendre depuis la machine.
        final visible = find.byType(Text).hitTestable().evaluate().map((e) => (e.widget as Text).data).whereType<String>().take(30).join(' | ');
        debugPrint('capture « $name » manquée : $e\nà l’écran : $visible\n$st');
        try {
          await binding.takeScreenshot('$name-echec');
        } catch (_) {}
      }
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

    // L'étape photo de la création, une fois la photo prise : Iris a posé ses
    // trois premiers noms dessus, et ils y restent jusqu'à « Continuer ».
    // C'est l'écran que vend le visuel « Quelle est cette plante ? ».
    //
    // Le simulateur n'a pas de caméra : l'étape montre donc ses deux boutons
    // de repli, et « Choisir une photo » passe par le magasin de photos de la
    // démo, qui rend le Ficus lyrata (core/demo/demo_photo_storage.dart).
    await scene('capture', () async {
      // Le « + » d'Aujourd'hui, seul bouton de droite de la page. Sur iOS, la
      // barre est celle d'UIKit : le bouton n'existe pas dans l'arbre de
      // Flutter, et le chercher par son étiquette ne trouvait rien — la scène
      // échouait avant même d'ouvrir la création. On passe alors par le canal
      // du bouton natif, comme son toucher (`R0`, le premier à droite).
      await go(Routes.today);
      if (NativeShell.isSupported && NativeShell.onAction != null) {
        NativeShell.onAction!('R0');
        await wait(tester, 2500);
      } else {
        await tapLabel(l10n.addPlant);
      }
      await tapText(l10n.choosePhoto);
      // Le champ d'analyse tient deux secondes au minimum, le modèle prend le
      // reste : les noms n'arrivent qu'après, un par un.
      await wait(tester, 8000);
      // Une photo sans noms ne vaut pas un visuel : c'est la scène qu'il faut
      // réparer, pas le visuel qu'il faut livrer. Le chapeau de l'étape ne
      // dit « Suggestions d'espèce » qu'une fois les noms posés — il dit
      // « Analyse en cours… » tant que le modèle cherche, et « Aucune
      // correspondance fiable » quand la photo n'a pas été servie.
      if (find.text(l10n.identifyHint).evaluate().isEmpty) throw StateError('les noms d’Iris ne sont pas arrivés sur la photo');
      await shot('capture');
      await dismiss();
    });

    // L'identification par Iris, sur la photo du Ficus lyrata : le modèle
    // tourne vraiment, la feuille « Espèce » est celle de l'app.
    await scene('identify', () async {
      await go(Routes.plants);
      // La tête verte pousse la grille : le Ficus, en deuxième rangée, peut
      // finir sous la barre d'onglets.
      await reveal(find.text('Ficus lyrata'));
      await tapText('Ficus lyrata');
      await tapLabel(l10n.more);
      await tapText(l10n.identify);
      await wait(tester, 8000);
      // Une feuille vide ne vaut pas un visuel : sans fichier à lire, Iris
      // ne répond rien, et c'est la scène qu'il faut réparer.
      if (find.text(l10n.identifyNone).evaluate().isNotEmpty) throw StateError('Iris n’a rien reconnu : la photo de démo n’a pas de fichier local');
      await shot('identify');
      await dismiss();
    });

    // Le diagnostic gardé au journal de la Calathea, rouvert en entier.
    // La carte du journal se cherche par son texte, pas par son étiquette :
    // le texte est là quoi qu'il arrive à l'arbre sémantique.
    await scene('diagnosis', () async {
      await go(Routes.plants);
      await tapText('Calathea');
      final open = find.textContaining(l10n.diagnosisOpen);
      await reveal(open);
      await tester.tap(open.hitTestable().first, warnIfMissed: false);
      await wait(tester, 2500);
      await shot('diagnosis');
      await dismiss();
    });

    // La fiche du Ficus seule : c'est elle que la feuille « Espèce »
    // recouvre, et le repli du web la redessine par-dessus.
    await scene('plant-ficus', () async {
      await go(Routes.plants);
      // La tête verte pousse la grille : le Ficus, en deuxième rangée, peut
      // finir sous la barre d'onglets.
      await reveal(find.text('Ficus lyrata'));
      await tapText('Ficus lyrata');
      await shot('plant-ficus');
    });
  });
}

/// Laisse l'app vivre [ms] millisecondes réelles : les animations se posent,
/// les images arrivent, les requêtes répondent. Une attente de repos complet
/// (`pumpAndSettle`) ne finirait jamais sur les écrans qui respirent.
Future<void> wait(WidgetTester tester, int ms) => tester.pump(Duration(milliseconds: ms));
