enum SyncStatus { idle, syncing, offline, error }

/// État observable de la synchronisation (pour l'écran Compte).
class SyncState {
  const SyncState({required this.status, this.lastSyncedAt, this.pendingCount = 0, this.message});

  final SyncStatus status;
  final DateTime? lastSyncedAt;
  final int pendingCount;
  final String? message;

  SyncState copyWith({SyncStatus? status, DateTime? lastSyncedAt, int? pendingCount, String? message}) => SyncState(
        status: status ?? this.status,
        lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
        pendingCount: pendingCount ?? this.pendingCount,
        message: message,
      );

  static const initial = SyncState(status: SyncStatus.idle);
}
