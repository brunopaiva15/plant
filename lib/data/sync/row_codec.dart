import 'package:drift/drift.dart';

/// Conversion lignes drift ⇄ lignes distantes.
///
/// - Clés : camelCase (data classes drift) ⇄ snake_case (Postgres).
/// - Dates : `DateTime` ⇄ ISO 8601 UTC.
/// - Booléens et JSON passent tels quels.
abstract final class RowCodec {
  static const _serializer = _IsoSerializer();

  /// Ligne locale → ligne distante.
  static Map<String, Object?> toRemote(DataClass row, {Map<String, Object?> extra = const {}, Set<String> drop = const {}}) {
    final json = row.toJson(serializer: _serializer);
    final out = <String, Object?>{};
    for (final e in json.entries) {
      final key = toSnake(e.key);
      if (drop.contains(key)) continue;
      out[key] = e.value;
    }
    out.addAll(extra);
    return out;
  }

  /// Ligne distante → JSON camelCase attendu par `fromJson` des data classes drift.
  static Map<String, Object?> toLocalJson(Map<String, Object?> remote, {Set<String> drop = const {}}) => {
        for (final e in remote.entries)
          if (!drop.contains(e.key)) toCamel(e.key): e.value,
      };

  static ValueSerializer get serializer => _serializer;

  static String toSnake(String s) => s.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]!.toLowerCase()}');

  static String toCamel(String s) => s.replaceAllMapped(RegExp('_([a-z0-9])'), (m) => m[1]!.toUpperCase());
}

/// Dates en ISO 8601 (UTC) au lieu d'entiers, pour un format lisible et portable.
class _IsoSerializer extends ValueSerializer {
  const _IsoSerializer();

  @override
  Object? toJson<T>(T value) {
    if (value is DateTime) return value.toUtc().toIso8601String();
    if (value is Uint8List) return value.toList();
    return value;
  }

  @override
  T fromJson<T>(dynamic json) {
    if (json == null) return null as T;
    final type = T.toString();
    if (type == 'DateTime' || type == 'DateTime?') {
      if (json is String) return DateTime.parse(json).toLocal() as T;
      if (json is int) return DateTime.fromMillisecondsSinceEpoch(json * 1000) as T;
    }
    if (type == 'double' || type == 'double?') return (json as num).toDouble() as T;
    if (type == 'int' || type == 'int?') return (json as num).toInt() as T;
    if (type == 'bool' || type == 'bool?') {
      if (json is bool) return json as T;
      if (json is num) return (json != 0) as T;
      if (json is String) return (json == 'true' || json == '1') as T;
    }
    return json as T;
  }
}
