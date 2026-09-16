import 'dart:convert';

import '../../domain/care/care_override.dart';

/// Les retouches de Care Studio, rangées par espèce et encodées en JSON.
///
/// Le rangement tient sur l'appareil pour l'instant : une retouche se vérifie
/// sur place avant de se partager. La clé est le nom scientifique normalisé en
/// minuscules, la même forme pour tous ceux qui écrivent le nom d'une plante.
abstract final class CareOverrideStore {
  static String keyOf(String scientificName) => scientificName.trim().toLowerCase();

  static String encode(Map<String, CareOverride> entries) =>
      jsonEncode({for (final e in entries.entries) e.key: e.value.toJson()});

  static Map<String, CareOverride> decode(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    try {
      final json = jsonDecode(raw);
      if (json is! Map) return {};
      final out = <String, CareOverride>{};
      for (final e in json.entries) {
        if (e.value is! Map) continue;
        final override = CareOverride.fromJson(Map<String, Object?>.from(e.value as Map));
        if (override != null) out[e.key as String] = override;
      }
      return out;
    } on FormatException {
      return {};
    }
  }
}
