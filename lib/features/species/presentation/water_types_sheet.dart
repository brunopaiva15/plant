import 'package:flutter/material.dart';

import '../../../core/l10n/care_labels.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/care/care_profile.dart';
import '../../../domain/care/water_quality.dart';

/// Ce que vaut chaque eau pour une plante : le robinet, la pluie, la carafe,
/// l'osmoseur, le bidon de déminéralisée, le bac du climatiseur, la résine de
/// l'adoucisseur.
///
/// La fiche d'entretien dit en deux mots l'eau qui convient ; cette liste dit
/// pourquoi, et ce que chaque eau emporte avec elle. Le verdict change avec
/// la plante, le risque non : un condensat reste une eau de bac.
Future<void> showWaterTypesSheet(BuildContext context, {required WaterTolerance tolerance, bool fluorideSensitive = false}) =>
    showFloraSheet<void>(context, scrollable: true, builder: (_) => _WaterTypesBody(tolerance: tolerance, fluorideSensitive: fluorideSensitive));

class _WaterTypesBody extends StatelessWidget {
  const _WaterTypesBody({required this.tolerance, required this.fluorideSensitive});

  final WaterTolerance tolerance;
  final bool fluorideSensitive;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetHeader(title: l10n.careWaterTypes),

          // Ce que cette plante demande, en tête : les sept eaux se lisent
          // par rapport à elle.
          MergeSemantics(
            child: FloraCard(
              color: c.waterSoft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EmojiTile(emoji: '💧', background: c.surface, variant: 0),
                  const SizedBox(width: Space.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.waterToleranceName(tolerance), style: context.text.title3),
                        const SizedBox(height: 2),
                        Text(l10n.waterToleranceNote(tolerance), style: context.text.callout),
                        if (fluorideSensitive) ...[
                          const SizedBox(height: Space.xs),
                          Text(l10n.careWaterFluorideSensitive, style: context.text.caption),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Space.md),

          for (final kind in WaterKind.values) ...[
            _WaterKindCard(kind: kind, verdict: waterVerdictFor(kind, tolerance, fluorideSensitive: fluorideSensitive)),
            const SizedBox(height: Space.xs),
          ],

          const SizedBox(height: Space.xs),
          Text(l10n.careWaterTypesNote, style: context.text.caption),
        ],
      ),
    );
  }
}

/// Une eau : son nom, le verdict pour cette plante, ce qu'elle est, ce
/// qu'elle emporte.
class _WaterKindCard extends StatelessWidget {
  const _WaterKindCard({required this.kind, required this.verdict});

  final WaterKind kind;
  final WaterVerdict verdict;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MergeSemantics(
      child: FloraCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Le nom à gauche, le verdict à droite tant qu'ils tiennent sur
            // la ligne ; en Dynamic Type poussé, la pastille passe dessous
            // plutôt que de rogner le nom.
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: Space.sm,
              runSpacing: Space.xs,
              children: [
                Text(l10n.waterKindName(kind), style: context.text.callout.copyWith(fontWeight: FontWeight.w600)),
                _VerdictBadge(verdict: verdict),
              ],
            ),
            const SizedBox(height: Space.xxs),
            Text(l10n.waterKindNote(kind), style: context.text.callout),
            const SizedBox(height: Space.xxs),
            Text(l10n.waterKindRisk(kind), style: context.text.caption),
          ],
        ),
      ),
    );
  }
}

/// Le verdict, écrit. La couleur le renforce, elle ne le porte pas : les
/// quatre teintes sont celles qui tiennent 4,5:1 sur leur pastel
/// (docs/06, « Le contrat de contraste »).
class _VerdictBadge extends StatelessWidget {
  const _VerdictBadge({required this.verdict});

  final WaterVerdict verdict;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (bg, fg) = switch (verdict) {
      WaterVerdict.recommended => (c.sageSoft, c.sage),
      WaterVerdict.suitable => (c.waterSoft, c.water),
      WaterVerdict.caution => (c.terracottaSoft, c.terracotta),
      WaterVerdict.avoid => (c.surfaceMuted, c.danger),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: Radii.fullAll),
      child: Text(
        context.l10n.waterVerdictName(verdict),
        style: context.text.caption.copyWith(color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }
}
