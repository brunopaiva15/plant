import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';

/// Un membre du jardin (cache local alimenté par la synchro).
class GardenMember {
  const GardenMember({required this.userId, required this.role, required this.displayName, this.email});

  final String userId;
  final String role;
  final String displayName;
  final String? email;

  bool get isOwner => role == 'owner';
}

final gardenMembersProvider = StreamProvider<List<GardenMember>>((ref) {
  final db = ref.watch(databaseProvider);
  final gardenId = ref.watch(gardenIdProvider);
  final q = db.select(db.gardenMembers).join([leftOuterJoin(db.profiles, db.profiles.id.equalsExp(db.gardenMembers.userId))])
    ..where(db.gardenMembers.gardenId.equals(gardenId));
  return q.watch().map((rows) => rows.map((r) {
        final m = r.readTable(db.gardenMembers);
        final p = r.readTableOrNull(db.profiles);
        return GardenMember(userId: m.userId, role: m.role, displayName: p?.displayName ?? '', email: p?.email);
      }).toList()
        ..sort((a, b) => a.isOwner == b.isOwner ? a.displayName.compareTo(b.displayName) : (a.isOwner ? -1 : 1)));
});

/// Noms des auteurs (id → nom) pour « Arrosée par Laura ».
final profileNamesProvider = Provider<Map<String, String>>((ref) {
  final members = ref.watch(gardenMembersProvider).value ?? const [];
  return {for (final m in members) m.userId: m.displayName.isEmpty ? (m.email ?? '') : m.displayName};
});

/// Rôle de l'utilisateur courant dans le jardin (`owner` par défaut, hors compte).
final currentRoleProvider = Provider<String>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null || user.isLocal) return 'owner';
  final members = ref.watch(gardenMembersProvider).value ?? const [];
  return members.where((m) => m.userId == user.id).firstOrNull?.role ?? 'owner';
});

/// `false` pour un « viewer » : l'UI masque les actions d'écriture.
final canEditProvider = Provider<bool>((ref) => ref.watch(currentRoleProvider) != 'viewer');
