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
          child: SizedBox(width: 40, height: 40, child: Icon(icon, size: 18, color: c.ink)),
        );
    final text = ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 64),
      child: Text(
        label,
        style: context.text.callout.copyWith(color: c.ink, fontWeight: FontWeight.w600),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
    return Container(
      decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: Radii.fullAll),
      child: Row(
        // Au plus juste, et le libellé plie avant les boutons : à l'étroit il
        // se resserre, mais le « + » ne sort jamais de la pilule. Sans borne
        // de largeur, il reprend sa taille naturelle — c'est ce que permet la
        // rangée au plus juste avec un enfant souple.
        mainAxisSize: MainAxisSize.min,
        children: [
          button(CupertinoIcons.minus, value - step >= min, -step),
          Flexible(child: text),
          button(CupertinoIcons.plus, value + step <= max, step),
        ],
      ),
    );
  }
}
