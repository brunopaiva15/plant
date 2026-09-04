import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'app/router.dart';
import 'core/l10n/l10n.dart';
import 'data/auth/local_auth_repository.dart';
import 'data/db/database.dart';
import 'data/services/notification_service.dart';
import 'data/services/preferences_service.dart';
import 'features/today/application/reminder_scheduler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await PreferencesService.load();
  final db = FloraDatabase(driftDatabase(name: 'flora'));
  final auth = LocalAuthRepository(db, prefs);
  await auth.ensureLocalUser();
  final notifications = NotificationService();
  await notifications.init();

  final container = ProviderContainer(overrides: [
    databaseProvider.overrideWithValue(db),
    preferencesServiceProvider.overrideWithValue(prefs),
    notificationServiceProvider.overrideWithValue(notifications),
    authRepositoryProvider.overrideWithValue(auth),
    gardenIdProvider.overrideWithValue(auth.gardenId),
  ]);

  // Emplacements de départ, dans la langue de l'appareil.
  final l10n = resolveLocalizations(prefs.localeCode == null ? null : Locale(prefs.localeCode!));
  await container.read(locationRepositoryProvider).ensureDefaults([
    (name: l10n.defaultLivingRoom, icon: '🛋️'),
    (name: l10n.defaultKitchen, icon: '🍳'),
    (name: l10n.defaultBedroom, icon: '🛏️'),
    (name: l10n.defaultBalcony, icon: '🌤️'),
  ]);

  notifications.onOpen = (payload) {
    if (payload != null && payload.isNotEmpty) container.read(routerProvider).go(payload);
  };
  // Les rappels sont recalculés à chaque lancement (dates et réglages ont pu changer).
  container.read(reminderSchedulerProvider).reschedule();

  runApp(UncontrolledProviderScope(container: container, child: const FloraApp()));
}
