import 'package:drift/drift.dart' show InsertMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../app/providers.dart';
import '../../../app/sync_coordinator.dart';
import '../../../core/network/connectivity.dart';
import '../../../data/db/database.dart';
import 'membership_providers.dart';

/// Supprimer un jardin : sur le serveur d'abord, sur l'appareil ensuite.
///
/// Dans l'autre sens, un serveur qui refuse laisserait un jardin bien vivant
/// là-bas et plus rien ici : la synchronisation suivante le ramènerait, vide.
///
/// [openInstead] prend la place du supprimé — il en faut toujours un, et c'est
/// pourquoi un compte ne supprime pas son dernier jardin. [ownInstead] devient
/// le jardin de l'appareil quand c'est celui-là qui part ; sans jardin à nous
/// parmi ceux qui restent, l'appareil s'en crée un neuf : la ligne d'un jardin
/// partagé appartient à quelqu'un d'autre et ne peut pas tenir ce rôle.
Future<void> deleteGarden(
  WidgetRef ref, {
  required String gardenId,
  required String openInstead,
  String? ownInstead,
}) async {
  final prefs = ref.read(preferencesServiceProvider);
  final db = ref.read(databaseProvider);
  // Les images partent en premier : une fois le jardin supprimé, les règles du
  // bucket ne nous laisseraient plus y toucher.
  await ref.read(syncCoordinatorProvider.notifier).removeGardenFiles(gardenId);
  await ref.online(() => ref.read(collaborationServiceProvider).deleteGarden(gardenId));
  final wasDeviceGarden = prefs.gardenId == gardenId;
  if (wasDeviceGarden) await prefs.setGardenId(ownInstead ?? await _newDeviceGarden(ref, db));
  // Ouvrir le remplaçant avant de vider : l'écran se reconstruit sur un jardin
  // qui existe, au lieu de se vider sous les yeux.
  await ref.read(activeGardenProvider.notifier).select(openInstead);
  await db.purgeGarden(gardenId);
  await prefs.clearSyncCursorsOf(gardenId);
  // La synchronisation retient le jardin de l'appareil à sa mise en route :
  // sans ce rappel, elle garderait le nom de celui qui n'existe plus, et
  // refuserait de pousser la ligne de son remplaçant.
  if (wasDeviceGarden) ref.invalidate(syncCoordinatorProvider);
  ref.invalidate(myGardensProvider);
  // Les fichiers des photos n'ont plus de ligne pour les réclamer : le ménage
  // les ramasse. Personne ne l'attend.
  ref.read(photoMaintenanceProvider).run().catchError((Object _) => 0);
}

/// Un jardin où personne n'a rien mis. Les emplacements par défaut, créés à
/// chaque lancement, n'y changent rien : ils ne viennent de personne.
Future<bool> gardenIsEmpty(FloraDatabase db, String gardenId) async {
  final plants = await (db.select(db.plants)
        ..where((p) => p.gardenId.equals(gardenId))
        ..limit(1))
      .get();
  if (plants.isNotEmpty) return false;
  final items = await (db.select(db.inventoryItems)
        ..where((i) => i.gardenId.equals(gardenId))
        ..limit(1))
      .get();
  if (items.isNotEmpty) return false;
  final tasks = await (db.select(db.tasks)
        ..where((t) => t.gardenId.equals(gardenId))
        ..limit(1))
      .get();
  if (tasks.isNotEmpty) return false;
  final entries = await (db.select(db.calendarEntries)
        ..where((e) => e.gardenId.equals(gardenId))
        ..limit(1))
      .get();
  return entries.isEmpty;
}

/// Un jardin neuf pour l'appareil, vide, portant le nom interne des jardins
/// que personne n'a nommés. Rien n'en part tant que rien n'y est écrit.
Future<String> _newDeviceGarden(WidgetRef ref, FloraDatabase db) async {
  final id = const Uuid().v4();
  final now = DateTime.now();
  final ownerId = ref.read(authRepositoryProvider).currentUser?.id ?? ref.read(preferencesServiceProvider).userId ?? '';
  await db.into(db.gardens).insert(
        GardensCompanion.insert(id: id, ownerId: ownerId, name: 'home', createdAt: now, updatedAt: now),
        mode: InsertMode.insertOrIgnore,
      );
  return id;
}
