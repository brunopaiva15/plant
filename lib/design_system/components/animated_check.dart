import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/flora_theme.dart';
import '../tokens/motion.dart';
import '../tokens/radius.dart';
import '../tokens/spacing.dart';
import 'pressable.dart';

/// Bouton d'action qui se transforme en « ✓ Fait » après le tap.
class CompletableButton extends StatelessWidget {
  const CompletableButton({
    super.key,
    required this.label,
    required this.doneLabel,
    required this.done,
    required this.onPressed,
    this.color,
    this.compact = false,
  });

  final String label;
  final String doneLabel;
  final bool done;
  final VoidCallback onPressed;
  final Color? color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final accent = color ?? c.sage;
    return Pressable(
      onTap: done ? null : onPressed,
      enabled: !done,
      scale: 0.94,
      semanticLabel: done ? doneLabel : label,
      child: AnimatedContainer(
        duration: Motion.of(context, Motion.standard),
        curve: Motion.easeOut,
        height: compact ? 36 : 44,
        padding: EdgeInsets.symmetric(horizontal: compact ? Space.sm : Space.md),
        decoration: BoxDecoration(color: done ? c.sageSoft : accent, borderRadius: Radii.fullAll),
        child: AnimatedSwitcher(
          duration: Motion.of(context, Motion.standard),
          switchInCurve: Motion.spring,
          transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: ScaleTransition(scale: anim, child: child)),
          child: Row(
            key: ValueKey(done),
            mainAxisSize: MainAxisSize.min,
            children: [
              if (done) ...[
                Icon(CupertinoIcons.checkmark_alt, size: 16, color: c.sage),
                const SizedBox(width: 4),
              ],
              Text(
                done ? doneLabel : label,
                style: (compact ? context.text.caption : context.text.callout).copyWith(
                  color: done ? c.sage : Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
