import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/network/connectivity.dart';
import '../../../core/network/network_failure.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/community/species_tip.dart';
import '../../network/presentation/offline_notice.dart';
import '../application/moderation_providers.dart';

/// Les conseils signalés, et ce qu'on en fait.
///
/// Le seuil masque tout seul au troisième signalement ; il faut ensuite
/// quelqu'un pour trancher, et c'est ici. L'écran n'existe que pour les
/// comptes inscrits dans la table `moderators` — l'entrée des réglages ne
/// paraît pas aux autres, et le serveur ne leur rendrait rien de toute façon.
class ModerationScreen extends ConsumerWidget {
  const ModerationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final reported = ref.watch(reportedTipsProvider);
    return FloraPage(
      title: l10n.moderationTitle,
      child: reported.when(
        loading: () => const Padding(padding: EdgeInsets.all(Space.xxl), child: Center(child: AdaptiveProgress())),
        error: (error, _) => error is OfflineException
            ? OfflineNotice(subtitle: l10n.offlineCommunityTips, onRetry: () => ref.invalidate(reportedTipsProvider))
            : EmptyState(
                emoji: '📡',
                title: l10n.genericError,
                actionLabel: l10n.retry,
                onAction: () => ref.invalidate(reportedTipsProvider),
                compact: true,
              ),
        data: (tips) => tips.isEmpty
            ? EmptyState(emoji: '🛡️', title: l10n.moderationEmpty, subtitle: l10n.moderationHint, compact: true)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.moderationHint, style: context.text.callout),
                  const SizedBox(height: Space.lg),
                  for (final tip in tips)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Space.sm),
                      child: _ReportedCard(tip: tip),
                    ),
                ],
              ),
      ),
    );
  }
}

/// Un conseil signalé : l'espèce dont il parle, qui l'a écrit, ce qu'il dit,
/// et les deux gestes qui restent — le masquer, ou le retirer.
class _ReportedCard extends ConsumerWidget {
  const _ReportedCard({required this.tip});

  final SpeciesTip tip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final author = tip.authorName.isEmpty ? l10n.communityTipAnonymous : tip.authorName;
    return FloraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  tip.speciesName.isEmpty ? tip.speciesId : tip.speciesName,
                  style: context.text.callout.copyWith(fontWeight: FontWeight.w600, color: c.ink),
                ),
              ),
              const SizedBox(width: Space.sm),
              Text(
                l10n.moderationReports(tip.reports),
                style: context.text.caption.copyWith(color: c.danger, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text('$author · ${Dates.relativeDay(context, tip.createdAt)}', style: context.text.caption),
          const SizedBox(height: Space.xs),
          Text(tip.body, style: context.text.callout.copyWith(color: c.ink)),
          const SizedBox(height: Space.sm),
          Row(
            children: [
              // Rétablir efface les signalements : sans quoi le conseil
              // repasserait le seuil à la première humeur et le même dossier
              // reviendrait indéfiniment.
              Expanded(
                child: FloraButton(
                  label: tip.hidden ? l10n.moderationRestore : l10n.moderationHide,
                  style: FloraButtonStyle.secondary,
                  size: FloraButtonSize.small,
                  expand: true,
                  onPressed: () => _moderate(context, ref),
                ),
              ),
              const SizedBox(width: Space.xs),
              Expanded(
                child: FloraButton(
                  label: l10n.delete,
                  style: FloraButtonStyle.ghost,
                  size: FloraButtonSize.small,
                  expand: true,
                  onPressed: () => _remove(context, ref),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _moderate(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    if (tip.hidden) {
      final ok = await showAdaptiveConfirm(
        context,
        title: l10n.confirmRestoreTip,
        confirmLabel: l10n.moderationRestore,
        cancelLabel: l10n.cancel,
      );
      if (!ok || !context.mounted) return;
    }
    await _run(context, ref, () => ref.read(communityTipsServiceProvider).moderate(tip.id, hidden: !tip.hidden));
  }

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final ok = await showAdaptiveConfirm(
      context,
      title: l10n.confirmDeleteTip,
      confirmLabel: l10n.delete,
      cancelLabel: l10n.cancel,
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    await _run(context, ref, () => ref.read(communityTipsServiceProvider).remove(tip.id));
  }

  /// Masquer, rétablir et retirer touchent le serveur : hors ligne le geste
  /// ne part pas, et l'écran le dit plutôt que de laisser croire qu'il est
  /// passé.
  static Future<void> _run(BuildContext context, WidgetRef ref, Future<void> Function() action) async {
    final l10n = context.l10n;
    try {
      await ref.online(action);
      Haptics.warning();
      ref.invalidate(reportedTipsProvider);
    } catch (e, st) {
      if (e is! OfflineException) ref.read(crashReporterProvider).report(e, st, context: 'moderation');
      if (!context.mounted) return;
      ref.read(toastProvider.notifier).show(
            ToastData(message: e is OfflineException ? l10n.offlineActionFailed : l10n.genericError, emoji: e is OfflineException ? '📡' : '!'),
          );
    }
  }
}
