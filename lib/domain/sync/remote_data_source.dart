import 'dart:io';

/// Une ligne distante, colonnes en snake_case, dates en ISO 8601.
typedef RemoteRow = Map<String, Object?>;

/// Un changement notifié en temps réel par le backend.
class RemoteChange {
  const RemoteChange({required this.table, required this.id});

  final String table;
  final String id;
}

/// Accès distant abstrait. Implémenté par Supabase ; remplaçable.
abstract class RemoteDataSource {
  /// Crée ou met à jour une ligne (clé primaire `id`, ou clés composites pour `plant_tags`).
  Future<void> upsert(String table, RemoteRow row);

  /// Suppression physique (utilisée uniquement pour `deleteForever` et les clés composites).
  Future<void> delete(String table, Map<String, Object?> keys);

  /// Lignes d'une table du jardin modifiées après [since] (toutes si `null`).
  Future<List<RemoteRow>> pullSince(String table, {required String gardenId, DateTime? since});

  /// Téléverse une photo ; retourne le chemin de stockage distant.
  Future<String> uploadFile(String storagePath, File file);

  /// Télécharge une photo distante dans [target].
  Future<void> downloadFile(String storagePath, File target);

  /// Changements en temps réel sur le jardin (peut être vide si non supporté).
  Stream<RemoteChange> watchChanges(String gardenId);
}
