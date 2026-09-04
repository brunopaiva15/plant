import 'package:flutter/material.dart';

import '../theme/flora_theme.dart';

/// Avatar initiales, sur pastille sauge.
class FloraAvatar extends StatelessWidget {
  const FloraAvatar({super.key, required this.name, this.size = 44});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final initial = name.trim().isEmpty ? '🌿' : name.trim()[0].toUpperCase();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: c.sageSoft, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(initial, style: TextStyle(fontSize: size * 0.42, fontWeight: FontWeight.w700, color: c.sage, height: 1)),
    );
  }
}
