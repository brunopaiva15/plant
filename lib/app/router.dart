import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../design_system/components/adaptive.dart';
import '../features/account/presentation/account_screen.dart';
import '../features/archive/presentation/archive_screen.dart';
import '../features/garden/presentation/garden_screen.dart';
import '../features/identification/presentation/identification_settings_screen.dart';
import '../features/locations/presentation/location_detail_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/plants/presentation/plant_detail_screen.dart';
import '../features/plants/presentation/plant_gallery_screen.dart';
import '../features/plants/presentation/plant_schedule_screen.dart';
import '../features/plants/presentation/plant_timeline_screen.dart';
import '../features/plants/presentation/plants_screen.dart';
import '../features/profile/presentation/about_screen.dart';
import '../features/profile/presentation/action_types_screen.dart';
import '../features/profile/presentation/appearance_screen.dart';
import '../features/profile/presentation/notifications_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/profile/presentation/tags_screen.dart';
import '../features/qr/presentation/scanner_screen.dart';
import '../features/today/presentation/today_screen.dart';
import '../features/weather/presentation/weather_settings_screen.dart';
import 'providers.dart';
import 'shell.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Page native : transition Cupertino (avec retour par glissement) sur iOS,
/// Material (predictive back) sur Android.
Page<T> platformPage<T>(BuildContext context, GoRouterState state, Widget child) => isCupertino(context)
    ? CupertinoPage<T>(key: state.pageKey, title: state.name, child: child)
    : MaterialPage<T>(key: state.pageKey, child: child);

abstract final class Routes {
  static const onboarding = '/onboarding';
  static const today = '/today';
  static const plants = '/plants';
  static const garden = '/garden';
  static const profile = '/profile';
  static String plant(String id) => '/plants/$id';
  static String plantTimeline(String id) => '/plants/$id/timeline';
  static String plantGallery(String id) => '/plants/$id/gallery';
  static String plantSchedule(String id) => '/plants/$id/schedule';
  static String location(String id) => '/locations/$id';
  static const appearance = '/settings/appearance';
  static const notifications = '/settings/notifications';
  static const actionTypes = '/settings/action-types';
  static const tags = '/settings/tags';
  static const archive = '/settings/archive';
  static const about = '/settings/about';
  static const identification = '/settings/identification';
  static const scan = '/scan';
  static const weather = '/settings/weather';
  static const account = '/settings/account';
}

final routerProvider = Provider<GoRouter>((ref) {
  final onboardingDone = ref.read(preferencesProvider).onboardingDone;
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: onboardingDone ? Routes.today : Routes.onboarding,
    routes: [
      GoRoute(
        path: Routes.onboarding,
        pageBuilder: (context, state) => platformPage(context, state, const OnboardingScreen()),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.today, pageBuilder: (c, s) => NoTransitionPage(key: s.pageKey, child: const TodayScreen())),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.plants, pageBuilder: (c, s) => NoTransitionPage(key: s.pageKey, child: const PlantsScreen())),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.garden, pageBuilder: (c, s) => NoTransitionPage(key: s.pageKey, child: const GardenScreen())),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.profile, pageBuilder: (c, s) => NoTransitionPage(key: s.pageKey, child: const ProfileScreen())),
          ]),
        ],
      ),
      // Écrans plein écran (la barre d'onglets se masque, comme un push iOS immersif).
      // Routes à plat (pas d'imbrication) : un `push` n'empile qu'une seule page.
      GoRoute(
        path: '/plants/:id',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (c, s) => platformPage(c, s, PlantDetailScreen(plantId: s.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/plants/:id/timeline',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (c, s) => platformPage(c, s, PlantTimelineScreen(plantId: s.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/plants/:id/gallery',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (c, s) => platformPage(c, s, PlantGalleryScreen(plantId: s.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/plants/:id/schedule',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (c, s) => platformPage(c, s, PlantScheduleScreen(plantId: s.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/locations/:id',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (c, s) => platformPage(c, s, LocationDetailScreen(locationId: s.pathParameters['id']!)),
      ),
      GoRoute(path: Routes.appearance, parentNavigatorKey: rootNavigatorKey, pageBuilder: (c, s) => platformPage(c, s, const AppearanceScreen())),
      GoRoute(path: Routes.notifications, parentNavigatorKey: rootNavigatorKey, pageBuilder: (c, s) => platformPage(c, s, const NotificationsScreen())),
      GoRoute(path: Routes.actionTypes, parentNavigatorKey: rootNavigatorKey, pageBuilder: (c, s) => platformPage(c, s, const ActionTypesScreen())),
      GoRoute(path: Routes.tags, parentNavigatorKey: rootNavigatorKey, pageBuilder: (c, s) => platformPage(c, s, const TagsScreen())),
      GoRoute(path: Routes.archive, parentNavigatorKey: rootNavigatorKey, pageBuilder: (c, s) => platformPage(c, s, const ArchiveScreen())),
      GoRoute(path: Routes.about, parentNavigatorKey: rootNavigatorKey, pageBuilder: (c, s) => platformPage(c, s, const AboutScreen())),
      GoRoute(path: Routes.identification, parentNavigatorKey: rootNavigatorKey, pageBuilder: (c, s) => platformPage(c, s, const IdentificationSettingsScreen())),
      GoRoute(path: Routes.weather, parentNavigatorKey: rootNavigatorKey, pageBuilder: (c, s) => platformPage(c, s, const WeatherSettingsScreen())),
      GoRoute(path: Routes.account, parentNavigatorKey: rootNavigatorKey, pageBuilder: (c, s) => platformPage(c, s, const AccountScreen())),
      GoRoute(
        path: Routes.scan,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (c, s) => isCupertino(c)
            ? CupertinoPage<void>(key: s.pageKey, fullscreenDialog: true, child: const ScannerScreen())
            : MaterialPage<void>(key: s.pageKey, fullscreenDialog: true, child: const ScannerScreen()),
      ),
    ],
  );
});
