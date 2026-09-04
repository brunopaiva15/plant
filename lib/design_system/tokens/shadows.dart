import 'package:flutter/painting.dart';

/// Une seule ombre, extrêmement discrète. Nulle en dark mode (couleur transparente).
abstract final class Shadows {
  static List<BoxShadow> soft(Color shadow) => [
        BoxShadow(color: shadow, blurRadius: 24, offset: const Offset(0, 8)),
      ];

  static List<BoxShadow> floating(Color shadow) => [
        BoxShadow(color: shadow.withValues(alpha: shadow.a * 2.5), blurRadius: 32, offset: const Offset(0, 12)),
      ];
}
