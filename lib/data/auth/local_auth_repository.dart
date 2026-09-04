import 'dart:async';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/auth/auth_repository.dart';
import '../db/database.dart';
import '../services/preferences_service.dart';

/// Compte local : aucune donnée ne quitte l'appareil. Un jardin est créé pour
/// l'utilisateur à la première ouverture. La liaison à un compte distant
/// (Apple / Google / e-mail) se fera en Phase 2 en réattribuant `owner_id`.
class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository(this._db, this._prefs);

  final FloraDatabase _db;
  final PreferencesService _prefs;
  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _current;

  String get gardenId => _prefs.gardenId!;

  @override
  Stream<AppUser?> watchUser() async* {
    yield _current;
    yield* _controller.stream;
  }

  @override
  AppUser? get currentUser => _current;

  @override
  bool get supportsRemote => false;

  @override
  Future<void> requestEmailCode(String email) => throw UnsupportedError('local account');

  @override
  Future<void> verifyEmailCode({required String email, required String code}) => throw UnsupportedError('local account');

  @override
  Future<void> signInWithApple() => throw UnsupportedError('local account');

  @override
  Future<void> signInWithGoogle() => throw UnsupportedError('local account');

  @override
  Future<AppUser> ensureLocalUser() async {
    var userId = _prefs.userId;
    var gardenId = _prefs.gardenId;
    if (userId == null || gardenId == null) {
      userId = const Uuid().v4();
      gardenId = const Uuid().v4();
      final now = DateTime.now();
      await _db.into(_db.gardens).insert(
            GardensCompanion.insert(id: gardenId, ownerId: userId, name: 'home', createdAt: now, updatedAt: now),
            mode: InsertMode.insertOrIgnore,
          );
      await _prefs.setIdentity(userId: userId, gardenId: gardenId);
    }
    _current = AppUser(id: userId, displayName: _prefs.displayName ?? '');
    _controller.add(_current);
    return _current!;
  }

  @override
  Future<void> updateDisplayName(String name) async {
    await _prefs.setDisplayName(name.trim());
    if (_current != null) {
      _current = AppUser(id: _current!.id, displayName: name.trim());
      _controller.add(_current);
    }
  }

  @override
  Future<void> signOut() async {
    // Compte local : rien à révoquer. Conservé pour la parité d'interface.
  }
}
