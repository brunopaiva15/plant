import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/l10n/likelihood_labels.dart';
import '../../../core/utils/markdown.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/care/care_engine.dart';
import '../../../domain/diagnosis/diagnosis_record.dart';
import '../../../domain/models/models.dart';
import '../../account/application/membership_providers.dart';
import '../../diagnosis/presentation/diagnosis_report.dart';

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
    // Un diagnostic est enregistré comme une note, mais il en porte le compte
    // rendu entier : la ligne le dit et le rend rouvrable.
    final diagnosis = DiagnosisRecord.fromMetadata(action.metadata);
    final isNote = action.typeKey == CareKind.note.key && diagnosis == null;
    final emoji = diagnosis != null ? '🩺' : (custom?.emoji ?? CareKind.fromKey(action.typeKey)?.emoji ?? '✓');
    final title = diagnosis != null
        ? l10n.diagnosisEntry
        : isNote
            ? Markdown.stripped(action.notes ?? l10n.kindNote)
            : l10n.kindDone(action.typeKey, custom: custom);
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
                      Expanded(child: Text(title, style: isNote ? context.text.body : context.text.title3)),
                      const SizedBox(width: Space.xs),
                      Text(
                        authorName == null || authorName.isEmpty ? Dates.time(context, action.occurredAt) : '${Dates.time(context, action.occurredAt)} · ${l10n.byUser(authorName)}',
                        style: context.text.caption,
                      ),
                    ],
                  ),
                  if (detail != null) ...[const SizedBox(height: 2), Text(detail, style: context.text.callout)],
                  if (diagnosis != null) ...[
                    const SizedBox(height: Space.xs),
                    DiagnosisTimelineCard(record: diagnosis, date: action.occurredAt),
                  ] else if (!isNote && action.notes != null) ...[
                    const SizedBox(height: 4),
                    MarkdownText(action.notes!, style: context.text.callout),
                  ],
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

/// L'aperçu d'un diagnostic dans le journal, et la porte pour le rouvrir.
///
/// Un journal montre des dizaines d'entrées : le résumé et les pistes
/// principales suffisent à retrouver de quoi il s'agissait. Le reste — ce que
/// chaque piste expliquait, les gestes proposés, les photos regardées — est
/// gardé entier et n'est jamais qu'à un doigt de là.
class DiagnosisTimelineCard extends ConsumerWidget {
  const DiagnosisTimelineCard({super.key, required this.record, required this.date});

  final DiagnosisRecord record;
  final DateTime date;

  /// Combien de pistes tiennent dans l'aperçu avant qu'il ne devienne un
  /// second compte rendu.
  static const _previewCauses = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l10n = context.l10n;
    // Les pistes sont nommées par la base, comme dans le compte rendu : les
    // deux doivent nommer la même chose de la même façon.
    final catalog = ref.watch(problemCatalogProvider).value;
    final language = Localizations.localeOf(context).languageCode;
    final diagnosis = record.diagnosis;
    final shown = diagnosis.causes.take(_previewCauses).toList();
    final hidden = diagnosis.causes.length - shown.length;
    return Pressable(
      onTap: () => showDiagnosisReportSheet(context, record: record, date: date),
      scale: 0.98,
      semanticLabel: l10n.diagnosisOpen,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Space.sm),
        decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: Radii.mediumAll),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (diagnosis.urgent) ...[
              DueBadge(emoji: '⚠️', label: l10n.urgentHint, status: DueStatus.overdue, compact: true),
              const SizedBox(height: Space.xs),
            ],
            if (diagnosis.summary.isNotEmpty)
              Text(diagnosis.summary, style: context.text.callout, maxLines: 3, overflow: TextOverflow.ellipsis),
            for (final cause in shown)
              Padding(
                padding: const EdgeInsets.only(top: Space.xxs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(likelihoodMark(cause.likelihood), style: context.text.caption.copyWith(color: c.sage)),
                    const SizedBox(width: Space.xxs),
                    Expanded(
                      child: Text(
                        diagnosisCauseTitle(cause, catalog, language),
                        style: context.text.callout.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: Space.xs),
                    Text(l10n.likelihoodLabel(cause.likelihood), style: context.text.caption),
                  ],
                ),
              ),
            const SizedBox(height: Space.xs),
            Row(
              children: [
                Expanded(
                  child: Text(
                    hidden > 0 ? '${l10n.diagnosisOpen} · ${l10n.diagnosisMoreCauses(hidden)}' : l10n.diagnosisOpen,
                    style: context.text.caption.copyWith(color: c.sage, fontWeight: FontWeight.w700),
                  ),
                ),
                Icon(CupertinoIcons.chevron_right, size: 13, color: c.sage),
              ],
            ),
          ],
        ),
      ),
    );
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
