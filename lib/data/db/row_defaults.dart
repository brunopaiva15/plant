/// Valeurs par défaut des colonnes non nullables ajoutées après coup.
///
/// Une ligne écrite par une version plus ancienne (client distant ou vieille
/// sauvegarde) n'a pas ces colonnes : on comble plutôt que d'échouer.
abstract final class RowDefaults {
  static const _byTable = <String, Map<String, Object?>>{
    'plants': {'number': 0},
    'gardens': {'plantCounter': 0},
    'locations': {'sortOrder': 0},
    'plant_attributes': {'position': 0},
    'attribute_schemas': {'position': 0, 'active': true},
    'tasks': {'allDay': true, 'done': false},
    'plant_photos': {'width': 0, 'height': 0},
    'inventory_groups': {'position': 0, 'emoji': '📦'},
    'event_categories': {'position': 0, 'emoji': '📅'},
    'calendar_entries': {'allDay': true},
  };

  static void fill(String table, Map<String, Object?> json) {
    final missing = _byTable[table];
    if (missing == null) return;
    for (final e in missing.entries) {
      json[e.key] ??= e.value;
    }
  }
}
