import 'care_kind.dart';

/// Un type d'action, intégré ([CareKind]) ou créé par l'utilisateur.
class ActionType {
  const ActionType({
    required this.key,
    required this.emoji,
    required this.isBuiltin,
    required this.sortOrder,
    this.label,
    this.schedulable = true,
  });

  /// Clé stable (`watering`, `custom:…`).
  final String key;
  final String emoji;

  /// Libellé saisi par l'utilisateur ; `null` pour les types intégrés (localisés).
  final String? label;
  final bool isBuiltin;
  final int sortOrder;
  final bool schedulable;

  CareKind? get builtin => CareKind.fromKey(key);

  static const String customPrefix = 'custom:';
}
