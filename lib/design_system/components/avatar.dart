import 'package:flutter/material.dart';

import '../theme/flora_theme.dart';
import 'clay.dart';

/// Avatar initiales, sur une pastille d'argile aux coins irréguliers.
///
/// La forme est tirée du nom et ne change plus : deux membres d'un jardin
/// n'ont pas la même pastille, et celle de chacun est la même d'un écran à
/// l'autre. C'est ce qui en fait une pièce modelée plutôt qu'un rond.
class FloraAvatar extends StatelessWidget {
  const FloraAvatar({super.key, required this.name, this.size = 44});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final trimmed = name.trim();
    final initial = trimmed.isEmpty ? '🌿' : trimmed[0].toUpperCase();
    return ClayBox(
      width: size,
      height: size,
      color: c.sageSoft,
      shape: ClayShape.blob(trimmed.hashCode),
      alignment: Alignment.center,
      child: Text(initial, style: TextStyle(fontSize: size * 0.42, fontWeight: FontWeight.w700, color: c.sage, height: 1)),
    );
  }
}
