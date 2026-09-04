/// Types d'action intégrés. Les types personnalisés utilisent une clé libre
/// préfixée `custom:` et sont décrits par [ActionType].
enum CareKind {
  watering('watering', '💧'),
  fertilizing('fertilizing', '🌱'),
  repotting('repotting', '🪴'),
  pruning('pruning', '✂️'),
  cleaning('cleaning', '🧼'),
  treatment('treatment', '🌿'),
  measurement('measurement', '📏'),
  photo('photo', '📷'),
  note('note', '📝');

  const CareKind(this.key, this.emoji);

  final String key;
  final String emoji;

  /// Types pouvant faire l'objet d'une routine planifiée.
  bool get isSchedulable => switch (this) {
        watering || fertilizing || repotting || pruning || cleaning || treatment => true,
        measurement || photo || note => false,
      };

  static CareKind? fromKey(String key) {
    for (final k in values) {
      if (k.key == key) return k;
    }
    return null;
  }
}
