import 'package:flutter/cupertino.dart';

import '../../core/haptics.dart';
import '../theme/flora_theme.dart';
import '../tokens/radius.dart';
import 'pressable.dart';

/// Stepper [−  valeur  +], en pilule.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.min = 1,
    this.max = 365,
    this.step = 1,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final String label;
  final int min;
  final int max;
  final int step;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget button(IconData icon, bool enabled, int delta) => Pressable(
          onTap: enabled
              ? () {
                  Haptics.selection();
                  onChanged((value + delta).clamp(min, max));
                }
              : null,
          enabled: enabled,
          haptic: false,
          scale: 0.85,
          child: SizedBox(width: 44, height: 40, child: Icon(icon, size: 18, color: c.ink)),
        );
    return Container(
      decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: Radii.fullAll),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          button(CupertinoIcons.minus, value - step >= min, -step),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 80),
            child: Text(label, style: context.text.callout.copyWith(color: c.ink, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          ),
          button(CupertinoIcons.plus, value + step <= max, step),
        ],
      ),
    );
  }
}
