import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../data/db/database.dart';
import '../../../domain/sharing/garden_collaboration.dart';

/// Membres du jardin ouvert, lus dans le cache local alimenté par la synchro :
/// la liste s'affiche hors ligne, et sert à nommer l'auteur d'un soin.
final gardenMembersProvider = StreamProvider<List<GardenMemberInfo>>((ref) {
  final db = ref.watch(databaseProvider);
  final gardenId = ref.watch(gardenIdProvider);
  final q = db.select(db.gardenMembers).join([leftOuterJoin(db.profiles, db.profiles.id.equalsExp(db.gardenMembers.userId))])
    ..where(db.gardenMembers.gardenId.equals(gardenId));
  return q.watch().map((rows) => rows.map((r) {
        final m = r.readTable(db.gardenMembers);
        final p = r.readTableOrNull(db.profiles);
        return GardenMemberInfo(userId: m.userId, role: GardenRole.parse(m.role), displayName: p?.displayName ?? '', email: p?.email);
      }).toList()
        ..sort((a, b) => a.role == b.role ? a.label.compareTo(b.label) : (a.role == GardenRole.owner ? -1 : 1)));
});

/// Noms des auteurs (id → nom) pour « Arrosée par Laura ».
final profileNamesProvider = Provider<Map<String, String>>((ref) {
  final members = ref.watch(gardenMembersProvider).value ?? const <GardenMemberInfo>[];
  return {for (final m in members) m.userId: m.displayName.isEmpty ? (m.email ?? '') : m.displayName};
});

/// Rôle de l'utilisateur courant dans le jardin ouvert. Sans compte distant,
/// il n'y a qu'un jardin et il est à lui : propriétaire.
final currentRoleProvider = Provider<GardenRole>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null || user.isLocal) return GardenRole.owner;
  final members = ref.watch(gardenMembersProvider).value ?? const <GardenMemberInfo>[];
  return members.where((m) => m.userId == user.id).firstOrNull?.role ?? GardenRole.owner;
});

/// `false` pour un « viewer » : l'UI masque les actions d'écriture.
final canEditProvider = Provider<bool>((ref) => ref.watch(currentRoleProvider).canEdit);

/// `true` pour le propriétaire du jardin : lui seul invite et retire.
final canManageMembersProvider = Provider<bool>((ref) => ref.watch(currentRoleProvider).canManageMembers);

/// Le jardin ouvert, tel qu'il s'appelle. Vide tant que rien n'est chargé.
final activeGardenNameProvider = StreamProvider<String>((ref) {
  final db = ref.watch(databaseProvider);
  final gardenId = ref.watch(gardenIdProvider);
  return (db.select(db.gardens)..where((g) => g.id.equals(gardenId))).watchSingleOrNull().map((g) => g?.name ?? '');
});

/// Tous les jardins du compte : le sien, puis ceux qu'on lui a partagés.
///
/// La liste vient du serveur, puis est recopiée en base pour rester lisible
/// hors ligne — c'est elle qui donne son nom au jardin dans le sélecteur.
final myGardensProvider = FutureProvider<List<GardenAccess>>((ref) async {
  final service = ref.watch(collaborationServiceProvider);
  final db = ref.watch(databaseProvider);
  final user = ref.watch(currentUserProvider).value;
  final own = ref.watch(gardenIdProvider);
  if (!service.isAvailable || user == null || user.isLocal) {
    final garden = await (db.select(db.gardens)..where((g) => g.id.equals(own))).getSingleOrNull();
    return [GardenAccess(id: own, name: garden?.name ?? '', role: GardenRole.owner, ownerId: garden?.ownerId)];
  }
  try {
    final gardens = await service.gardens();
    await db.transaction(() async {
      final now = DateTime.now();
      for (final g in gardens) {
        await db.into(db.gardens).insert(
              GardensCompanion.insert(id: g.id, ownerId: g.ownerId ?? '', name: g.name, createdAt: now, updatedAt: now),
              mode: InsertMode.insertOrIgnore,
            );
        await (db.update(db.gardens)..where((x) => x.id.equals(g.id))).write(GardensCompanion(name: Value(g.name)));
        await db.into(db.gardenMembers).insertOnConflictUpdate(GardenMembersCompanion.insert(gardenId: g.id, userId: user.id, role: g.role.key));
      }
    });
    return gardens;
  } catch (_) {
    // Hors ligne : on retombe sur ce que la base connaît déjà.
    final rows = await (db.select(db.gardens).join([
      innerJoin(db.gardenMembers, db.gardenMembers.gardenId.equalsExp(db.gardens.id) & db.gardenMembers.userId.equals(user.id)),
    ])).get();
    return [
      for (final r in rows)
        GardenAccess(
          id: r.readTable(db.gardens).id,
          name: r.readTable(db.gardens).name,
          role: GardenRole.parse(r.readTable(db.gardenMembers).role),
          ownerId: r.readTable(db.gardens).ownerId,
        ),
    ];
  }
});

/// Invitations en cours pour le jardin ouvert (propriétaire seulement).
final gardenInvitesProvider = FutureProvider<List<GardenInvite>>((ref) async {
  final service = ref.watch(collaborationServiceProvider);
  if (!service.isAvailable || !ref.watch(canManageMembersProvider)) return const [];
  return service.invites(ref.watch(gardenIdProvider));
});
