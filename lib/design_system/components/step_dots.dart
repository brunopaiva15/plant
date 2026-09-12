import 'package:flutter/material.dart';

import '../theme/flora_theme.dart';
import '../tokens/motion.dart';
import '../tokens/radius.dart';

/// La progression d'un flow en quelques points : celui de l'étape en cours
/// s'étire en trait. Discret, parce qu'un flow de deux ou trois étapes n'a
/// pas besoin d'une barre de progression.
class StepDots extends StatelessWidget {
  const StepDots({super.key, required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: Motion.of(context, Motion.standard),
            curve: Motion.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == index ? 20 : 6,
            height: 6,
            decoration: BoxDecoration(color: i == index ? c.sage : c.line, borderRadius: Radii.fullAll),
          ),
      ],
    );
  }
}
