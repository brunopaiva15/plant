import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models/models.dart';
import '../../plants/application/plant_providers.dart';

/// « Anciennes plantes » : archives avec restauration.
class ArchiveScreen extends ConsumerWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final archived = ref.watch(archivedPlantsProvider).value ?? const <PlantSummary>[];
    return FloraPage(
      title: l10n.archives,
      child: archived.isEmpty
          ? EmptyState(emoji: '🍂', title: l10n.noArchivesTitle, subtitle: l10n.noArchivesSubtitle, compact: true)
          : Column(
              children: [
                for (final s in archived) ...[
                  FloraCard(
                    padding: const EdgeInsets.all(Space.xs),
                    child: Row(
                      children: [
                        ClipRRect(borderRadius: BorderRadius.circular(16), child: SizedBox(width: 60, height: 60, child: PlantImage(relativePath: s.thumbPath, cacheWidth: 180))),
                        const SizedBox(width: Space.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.plant.name, style: context.text.title3),
                              Text(
                                [
                                  if (s.plant.archivedAt != null) l10n.archivedOn(Dates.dayYear(context, s.plant.archivedAt!)),
                                  if (s.plant.archiveReason != null) _reason(l10n, s.plant.archiveReason!),
                                ].join(' · '),
                                style: context.text.caption,
                              ),
                            ],
                          ),
                        ),
                        FloraIconButton(
                          icon: CupertinoIcons.ellipsis,
                          semanticLabel: l10n.more,
                          filled: false,
                          onPressed: () => showAdaptiveActionSheet(
                            context,
                            title: s.plant.name,
                            cancelLabel: l10n.cancel,
                            actions: [
                              SheetAction(
                                label: l10n.restore,
                                icon: CupertinoIcons.arrow_uturn_left,
                                onPressed: () async {
                                  await ref.read(plantRepositoryProvider).restore([s.plant.id]);
                                  Haptics.success();
                                  ref.read(toastProvider.notifier).show(ToastData(message: l10n.plantRestored(s.plant.name), emoji: '🌱'));
                                },
                              ),
                              SheetAction(
                                label: l10n.deleteForever,
                                icon: CupertinoIcons.trash,
                                destructive: true,
                                onPressed: () async {
                                  final ok = await showAdaptiveConfirm(context, title: l10n.deleteForever, message: l10n.deleteForeverConfirm, confirmLabel: l10n.delete, cancelLabel: l10n.cancel, destructive: true);
                                  if (!ok) return;
                                  await ref.read(plantRepositoryProvider).deleteForever(s.plant.id);
                                  Haptics.warning();
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Space.xs),
                ],
                const SizedBox(height: Space.md),
              ],
            ),
    );
  }

  String _reason(AppLocalizations l10n, String key) => switch (key) {
        'died' => l10n.reasonDied,
        'given' => l10n.reasonGiven,
        'sold' => l10n.reasonSold,
        _ => l10n.reasonOther,
      };
}
