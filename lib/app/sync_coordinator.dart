import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_config.dart';
import '../data/sync/supabase_remote_data_source.dart';
import '../data/sync/sync_service.dart';
import '../domain/sync/sync_state.dart';
import 'providers.dart';

/// Curseurs de synchronisation persistés (par table).
class PrefsCursorStore implements SyncCursorStore {
  PrefsCursorStore(this._read, this._write, this._clearAll);

  final DateTime? Function(String) _read;
  final Future<void> Function(String, DateTime) _write;
  final Future<void> Function() _clearAll;

  @override
  DateTime? read(String table) => _read(table);
  @override
  Future<void> write(String table, DateTime value) => _write(table, value);
  @override
  Future<void> clear() => _clearAll();
}

/// Orchestre la synchronisation quand un compte est connecté :
/// démarrage, retour au premier plan, après chaque écriture (débounce),
/// et sur changement distant (temps réel).
class SyncCoordinator extends Notifier<SyncState> with WidgetsBindingObserver {
  SyncService? _service;
  StreamSubscription<Object?>? _outboxSub;
  StreamSubscription<Object?>? _remoteSub;
  StreamSubscription<SyncState>? _stateSub;
  Timer? _debounce;

  @override
  SyncState build() {
    final user = ref.watch(currentUserProvider).value;
    ref.onDispose(_teardown);
    if (!SupabaseConfig.isConfigured || user == null || user.isLocal) {
      _teardown();
      return SyncState.initial;
    }
    _setup(user.id);
    return _service?.currentState ?? SyncState.initial;
  }

  void _setup(String userId) {
    _teardown();
    final prefs = ref.read(preferencesServiceProvider);
    final db = ref.read(databaseProvider);
    final storage = ref.read(photoStorageProvider);
    final gardenId = ref.read(gardenIdProvider);
    final remote = SupabaseRemoteDataSource(Supabase.instance.client);
    final service = SyncService(
      db: db,
      remote: remote,
      cursors: PrefsCursorStore(prefs.syncCursor, prefs.setSyncCursor, prefs.clearSyncCursors),
      localFile: (rel) async => File(await storage.absolutePath(rel)),
      gardenId: gardenId,
      userId: userId,
    );
    _service = service;
    _stateSub = service.state.listen((s) => state = s);
    WidgetsBinding.instance.addObserver(this);

    // Écritures locales → synchro après 3 s de calme.
    _outboxSub = db.select(db.syncOutbox).watch().listen((rows) {
      if (rows.isEmpty) return;
      _debounce?.cancel();
      _debounce = Timer(const Duration(seconds: 3), service.sync);
    });
    // Changements distants → synchro après 1 s de calme.
    _remoteSub = remote.watchChanges(gardenId).listen((_) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(seconds: 1), service.sync);
    });

    unawaited(_firstSync(userId, service, prefs));
  }

  Future<void> _firstSync(String userId, SyncService service, dynamic prefs) async {
    // Première connexion sur cet appareil : tout le jardin local est poussé.
    if (prefs.syncedAccountId != userId) {
      await prefs.clearSyncCursors();
      await service.enqueueEverything();
      await prefs.setSyncedAccountId(userId);
    }
    await service.sync();
  }

  void _teardown() {
    _debounce?.cancel();
    _outboxSub?.cancel();
    _remoteSub?.cancel();
    _stateSub?.cancel();
    _outboxSub = _remoteSub = _stateSub = null;
    WidgetsBinding.instance.removeObserver(this);
    _service?.dispose();
    _service = null;
  }

  @override
  // ignore: avoid_renaming_method_parameters
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    if (lifecycle == AppLifecycleState.resumed) _service?.sync();
  }

  Future<void> syncNow() async => _service?.sync();
}

final syncCoordinatorProvider = NotifierProvider<SyncCoordinator, SyncState>(SyncCoordinator.new);
