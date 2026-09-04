/// Découpage d'une sauvegarde en parties que l'utilisateur peut cocher.
enum BackupSection {
  /// Le jardin lui-même : emplacements, journal, tags, types d'action.
  garden,

  /// Les plantes et ce qui les décrit.
  plants,

  /// Les fichiers photo et leurs métadonnées.
  photos,

  /// Historique des soins et routines.
  care,
  inventory,
  tasks,
  calendar,
}

extension BackupSectionTables on BackupSection {
  /// Tables portées par la section, dans l'ordre où elles doivent être
  /// réimportées (les parents avant les enfants).
  List<String> get tables => switch (this) {
        BackupSection.garden => ['gardens', 'locations', 'location_logs', 'action_types', 'tags'],
        BackupSection.plants => ['plants', 'plant_tags', 'attribute_schemas', 'plant_attributes', 'plant_attachments', 'measurements'],
        BackupSection.photos => ['plant_photos'],
        BackupSection.care => ['plant_actions', 'care_schedules'],
        BackupSection.inventory => ['inventory_groups', 'inventory_items', 'inventory_tags'],
        BackupSection.tasks => ['tasks'],
        BackupSection.calendar => ['event_categories', 'calendar_entries'],
      };

  /// Sections dont celle-ci a besoin pour que ses lignes tiennent debout.
  Set<BackupSection> get requires => switch (this) {
        BackupSection.garden => const {},
        BackupSection.plants => const {BackupSection.garden},
        BackupSection.photos || BackupSection.care => const {BackupSection.garden, BackupSection.plants},
        BackupSection.inventory || BackupSection.tasks || BackupSection.calendar => const {BackupSection.garden},
      };
}

/// Ordre global d'import : parents d'abord, quelles que soient les sections
/// choisies. Une table absente de la sélection est simplement sautée.
const backupTableOrder = <String>[
  'gardens',
  'locations',
  'action_types',
  'tags',
  'plants',
  'plant_photos',
  'plant_actions',
  'care_schedules',
  'plant_tags',
  'measurements',
  'attribute_schemas',
  'plant_attributes',
  'plant_attachments',
  'location_logs',
  'inventory_groups',
  'inventory_items',
  'inventory_tags',
  'event_categories',
  'calendar_entries',
  'tasks',
];

/// Complète une sélection avec ce dont elle dépend : importer des photos sans
/// leurs plantes ne donnerait que des lignes orphelines.
Set<BackupSection> withDependencies(Set<BackupSection> chosen) {
  final result = {...chosen};
  var changed = true;
  while (changed) {
    changed = false;
    for (final section in {...result}) {
      for (final need in section.requires) {
        if (result.add(need)) changed = true;
      }
    }
  }
  return result;
}

/// Tables couvertes par une sélection, dans l'ordre d'import.
List<String> tablesFor(Set<BackupSection> sections) {
  final wanted = {for (final s in withDependencies(sections)) ...s.tables};
  return [for (final t in backupTableOrder) if (wanted.contains(t)) t];
}
