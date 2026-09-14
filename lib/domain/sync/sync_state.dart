enum SyncStatus { idle, syncing, offline, error }

/// État observable de la synchronisation (pour l'écran Compte).
class SyncState {
  const SyncState({required this.status, this.lastSyncedAt, this.pendingCount = 0, this.message, this.unknownColumns = const []});

  final SyncStatus status;
  final DateTime? lastSyncedAt;
  final int pendingCount;
  final String? message;

  /// Colonnes que le serveur ne connaît pas (« plants.cutting_month ») : son
  /// schéma est en retard sur l'application, et ces champs-là restent sur
  /// l'appareil. Le reste se synchronise normalement.
  final List<String> unknownColumns;

  SyncState copyWith({SyncStatus? status, DateTime? lastSyncedAt, int? pendingCount, String? message, List<String>? unknownColumns}) => SyncState(
        status: status ?? this.status,
        lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
        pendingCount: pendingCount ?? this.pendingCount,
        message: message,
        unknownColumns: unknownColumns ?? this.unknownColumns,
      );

  static const initial = SyncState(status: SyncStatus.idle);
}
