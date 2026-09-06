import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/utils/markdown.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models/models.dart';
import '../../account/application/membership_providers.dart';

/// Une entrée du journal : « 💧 Arrosée · 09:42 », note, photo, mesure.
class TimelineRow extends ConsumerWidget {
  const TimelineRow({super.key, required this.action, this.photo, required this.isLast, this.onPhotoTap});

  final PlantAction action;
  final PlantPhoto? photo;
  final bool isLast;
  final VoidCallback? onPhotoTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l10n = context.l10n;
    final custom = ref.watch(actionTypeByKeyProvider)[action.typeKey];
    final emoji = custom?.emoji ?? CareKind.fromKey(action.typeKey)?.emoji ?? '✓';
    final title = action.typeKey == CareKind.note.key ? Markdown.stripped(action.notes ?? l10n.kindNote) : l10n.kindDone(action.typeKey, custom: custom);
    final detail = _detail(l10n);
    final me = ref.watch(currentUserProvider).value;
    final authorName = action.userId != null && action.userId != me?.id ? ref.watch(profileNamesProvider)[action.userId!] : null;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              EmojiTile(emoji: emoji, size: 36, background: c.softFor(action.typeKey)),
              if (!isLast) Expanded(child: Container(width: 1.5, margin: const EdgeInsets.symmetric(vertical: 4), color: c.line)),
            ],
          ),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : Space.lg, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Text(title, style: action.typeKey == CareKind.note.key ? context.text.body : context.text.title3)),
                      const SizedBox(width: Space.xs),
                      Text(
                        authorName == null || authorName.isEmpty ? Dates.time(context, action.occurredAt) : '${Dates.time(context, action.occurredAt)} · ${l10n.byUser(authorName)}',
                        style: context.text.caption,
                      ),
                    ],
                  ),
                  if (detail != null) ...[const SizedBox(height: 2), Text(detail, style: context.text.callout)],
                  if (action.typeKey != CareKind.note.key && action.notes != null) ...[const SizedBox(height: 4), MarkdownText(action.notes!, style: context.text.callout)],
                  if (photo != null) ...[
                    const SizedBox(height: Space.xs),
                    Pressable(
                      onTap: onPhotoTap,
                      scale: 0.97,
                      child: ClipRRect(
                        borderRadius: Radii.mediumAll,
                        child: SizedBox(height: 160, width: double.infinity, child: PlantImage(relativePath: photo!.thumbPath, cacheWidth: 600, heroTag: 'photo-${photo!.id}', heroRadius: Radii.mediumAll)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _detail(AppLocalizations l10n) {
    final m = action.metadata;
    if (action.typeKey == CareKind.measurement.key && m['value'] is num) {
      final kind = switch (m['kind']) { 'width' => l10n.measureWidth, 'leaves' => l10n.measureLeaves, 'pot' => l10n.measurePot, _ => l10n.measureHeight };
      final v = (m['value'] as num);
      final text = v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
      return '$kind · $text ${m['unit'] ?? ''}'.trim();
    }
    if (m['quantity'] is num) return '${(m['quantity'] as num).toStringAsFixed(0)} ${m['unit'] ?? 'ml'}';
    return null;
  }
}

/// Groupe les actions par jour (« Aujourd'hui », « Hier », « 27 août »).
List<(String, List<PlantAction>)> groupByDay(BuildContext context, List<PlantAction> actions) {
  final groups = <(String, List<PlantAction>)>[];
  for (final a in actions) {
    final label = Dates.relativeDay(context, a.occurredAt);
    if (groups.isNotEmpty && groups.last.$1 == label) {
      groups.last.$2.add(a);
    } else {
      groups.add((label, [a]));
    }
  }
  return groups;
}

class TimelineDayLabel extends StatelessWidget {
  const TimelineDayLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm, top: Space.xs),
      child: Text(label, style: context.text.caption.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.3)),
    );
  }
}
