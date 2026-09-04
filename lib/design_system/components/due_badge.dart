import 'package:flutter/material.dart';

import '../../domain/care/care_engine.dart';
import '../../domain/models/models.dart';
import '../theme/flora_theme.dart';
import '../tokens/colors.dart';
import '../tokens/radius.dart';

/// Pastille « 💧 Dans 2 j » — la couleur seule ne porte jamais l'information.
class DueBadge extends StatelessWidget {
  const DueBadge({super.key, required this.emoji, required this.label, required this.status, this.compact = false});

  final String emoji;
  final String label;
  final DueStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (bg, fg) = switch (status) {
      DueStatus.overdue => (c.terracottaSoft, c.terracotta),
      DueStatus.today => (c.waterSoft, c.water),
      DueStatus.upcoming => (c.surfaceMuted, c.inkSecondary),
      DueStatus.none => (c.surfaceMuted, c.inkTertiary),
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 3 : 5),
      decoration: BoxDecoration(color: bg, borderRadius: Radii.fullAll),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: TextStyle(fontSize: compact ? 11 : 13, height: 1)),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: context.text.caption.copyWith(color: fg, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Couleur pastel associée à un type de soin (arrosage bleu, engrais jaune…).
extension CareKindColors on FloraColors {
  Color softFor(String typeKey) => switch (CareKind.fromKey(typeKey)) {
        CareKind.watering => waterSoft,
        CareKind.fertilizing => sunSoft,
        CareKind.repotting => terracottaSoft,
        CareKind.pruning || CareKind.cleaning || CareKind.treatment => sageSoft,
        CareKind.photo || CareKind.note || CareKind.measurement => surfaceMuted,
        null => roseSoft,
      };

  Color strongFor(String typeKey) => switch (CareKind.fromKey(typeKey)) {
        CareKind.watering => water,
        CareKind.fertilizing => sun,
        CareKind.repotting => terracotta,
        CareKind.pruning || CareKind.cleaning || CareKind.treatment => sage,
        CareKind.photo || CareKind.note || CareKind.measurement => inkSecondary,
        null => rose,
      };
}
