/// Nature d'une ligne du journal d'activité.
enum ActivityKind {
  /// Un soin enregistré (arrosage, photo, note…).
  action,

  /// Une plante ajoutée au jardin.
  plantAdded,

  /// Une plante archivée.
  plantArchived,

  /// Une note écrite dans le journal d'un emplacement.
  locationNote,

  /// Une tâche libre terminée.
  taskDone,
}

/// Une ligne du journal d'activité, toutes sources confondues.
class ActivityEntry {
  const ActivityEntry({
    required this.id,
    required this.at,
    required this.kind,
    this.plantId,
    this.plantName,
    this.thumbPath,
    this.typeKey,
    this.text,
  });

  final String id;
  final DateTime at;
  final ActivityKind kind;
  final String? plantId;
  final String? plantName;
  final String? thumbPath;

  /// Type d'action, pour les lignes de soin uniquement.
  final String? typeKey;

  /// Texte libre : note de l'action, titre de la tâche, contenu du journal.
  final String? text;
}
