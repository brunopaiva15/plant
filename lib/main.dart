import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'app/router.dart';
import 'app/sync_coordinator.dart';
import 'core/l10n/l10n.dart';
import 'core/config/supabase_config.dart';
import 'core/demo/demo_seed.dart';
import 'data/auth/local_auth_repository.dart';
import 'data/auth/supabase_auth_repository.dart';
import 'domain/auth/auth_repository.dart';
import 'data/db/database.dart';
import 'data/services/notification_service.dart';
import 'data/services/preferences_service.dart';
import 'features/today/application/reminder_scheduler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Revue visuelle des variantes Cupertino depuis un navigateur : `?ios`.
  if (!kReleaseMode && kIsWeb && Uri.base.queryParameters.containsKey('ios')) {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
  }

  final prefs = await PreferencesService.load();
  final db = FloraDatabase(driftDatabase(
    name: 'flora',
    web: DriftWebOptions(sqlite3Wasm: Uri.parse('sqlite3.wasm'), driftWorker: Uri.parse('drift_worker.js')),
  ));
  final AuthRepository auth;
  final String gardenId;
  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(url: SupabaseConfig.url, publishableKey: SupabaseConfig.anonKey);
    final remoteAuth = SupabaseAuthRepository(Supabase.instance.client, db, prefs);
    await remoteAuth.ensureLocalUser();
    auth = remoteAuth;
    gardenId = remoteAuth.gardenId;
  } else {
    final localAuth = LocalAuthRepository(db, prefs);
    await localAuth.ensureLocalUser();
    auth = localAuth;
    gardenId = localAuth.gardenId;
  }
  final notifications = NotificationService();
  await notifications.init();

  final container = ProviderContainer(overrides: [
    databaseProvider.overrideWithValue(db),
    preferencesServiceProvider.overrideWithValue(prefs),
    notificationServiceProvider.overrideWithValue(notifications),
    authRepositoryProvider.overrideWithValue(auth),
    gardenIdProvider.overrideWithValue(gardenId),
  ]);

  // Emplacements de départ, dans la langue de l'appareil.
  final l10n = resolveLocalizations(prefs.localeCode == null ? null : Locale(prefs.localeCode!));
  await container.read(locationRepositoryProvider).ensureDefaults([
    (name: l10n.defaultLivingRoom, icon: '🛋️', outdoor: false),
    (name: l10n.defaultKitchen, icon: '🍳', outdoor: false),
    (name: l10n.defaultBedroom, icon: '🛏️', outdoor: false),
    (name: l10n.defaultBalcony, icon: '🌤️', outdoor: true),
  ]);

  if (DemoSeed.requested) await DemoSeed.apply(db, gardenId);

  notifications.onOpen = (payload) {
    if (payload != null && payload.isNotEmpty) container.read(routerProvider).go(payload);
  };
  // Les rappels sont recalculés à chaque lancement (dates et réglages ont pu changer).
  container.read(reminderSchedulerProvider).reschedule();
  // Démarre la synchronisation si un compte est connecté (no-op sinon).
  container.listen(syncCoordinatorProvider, (_, _) {});

  runApp(UncontrolledProviderScope(container: container, child: const FloraApp()));
}
