import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/network/connectivity.dart';
import '../../../core/network/network_failure.dart';
import '../../../core/utils/scientific_name.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/community/species_tip.dart';
import '../../account/application/sign_in_availability.dart';
import '../../network/presentation/offline_notice.dart';
import 'write_tip_sheet.dart';

/// Les conseils publiés sur une espèce. La clé est celle du catalogue
/// (`hoya-kerrii`), pas le nom tel qu'il est écrit : deux personnes qui
/// saisissent « Hoya kerrii » et « hoya kerrii » lisent la même page.
final speciesTipsProvider = FutureProvider.autoDispose.family<List<SpeciesTip>, String>(retry: noRetry, (ref, speciesId) {
  ref.watch(connectivityProvider);
  final service = ref.watch(communityTipsServiceProvider);
  if (!service.isAvailable) return Future.value(const <SpeciesTip>[]);
  return ref.online(() => service.tips(speciesId));
});

/// « Conseils de la communauté » au bas d'une fiche d'entretien.
///
/// Le catalogue dit ce que l'espèce demande ; cette section dit ce que
/// d'autres ont observé en la gardant. Les deux ne se mélangent pas : la
/// provenance d'une fiche est affichée pour rester honnête (docs/06), et un
/// conseil écrit par quelqu'un ne se donne pas pour une donnée du catalogue.
///
/// Sans backend configuré, elle n'existe pas. Sans compte, elle se lit mais
/// ne s'écrit pas.
class CommunityTipsSection extends ConsumerWidget {
  const CommunityTipsSection({super.key, required this.speciesName});

  /// Nom scientifique de la plante. Vide ou inconnu, la section ne paraît
  /// pas : un conseil sans espèce ne se rattache à rien.
  final String? speciesName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(communityTipsServiceProvider);
    final name = speciesName?.trim() ?? '';
    final speciesId = name.isEmpty ? '' : internalPlantId(name);
    if (!service.isAvailable || speciesId.isEmpty) return const SizedBox.shrink();

    final l10n = context.l10n;
    final tips = ref.watch(speciesTipsProvider(speciesId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: Space.lg),
        SectionHeader(title: l10n.communityTipsTitle, padding: EdgeInsets.zero),
        const SizedBox(height: 2),
        Text(l10n.communityTipsHint, style: context.text.caption),
        const SizedBox(height: Space.sm),
        tips.when(
          loading: () => const Padding(padding: EdgeInsets.all(Space.lg), child: Center(child: AdaptiveProgress())),
          // Hors ligne, la liste n'est pas vide : elle est restée sur le
          // serveur. Le reste de la fiche, lui, se lit sans réseau.
          error: (error, _) => error is OfflineException
              ? OfflineNotice(
                  subtitle: l10n.offlineCommunityTips,
                  onRetry: () => ref.invalidate(speciesTipsProvider(speciesId)),
                )
              : EmptyState(
                  emoji: '📡',
                  title: l10n.genericError,
                  actionLabel: l10n.retry,
                  onAction: () => ref.invalidate(speciesTipsProvider(speciesId)),
                  compact: true,
                ),
          data: (items) => _List(speciesId: speciesId, speciesName: name, tips: items),
        ),
      ],
    );
  }
}

class _List extends ConsumerWidget {
  const _List({required this.speciesId, required this.speciesName, required this.tips});

  final String speciesId;
  final String speciesName;
  final List<SpeciesTip> tips;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final service = ref.watch(communityTipsServiceProvider);
    final mine = tips.where((t) => t.mine).firstOrNull;
    final canSignIn = ref.watch(signInAvailableProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (tips.isEmpty)
          Text(l10n.communityTipsEmpty, style: context.text.callout.copyWith(color: context.colors.inkSecondary))
        else
          for (final tip in tips)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.xs),
              child: _TipCard(tip: tip, speciesId: speciesId, speciesName: speciesName),
            ),
        const SizedBox(height: Space.sm),

        // Écrire demande un compte : sans lui, la section dit pourquoi le
        // bouton n'est pas là, et mène à l'écran du compte là où la connexion
        // existe. Sur Android elle n'existe pas encore : la phrase reste
        // seule plutôt que de promettre un écran sans issue.
        if (service.canPublish && mine == null)
          FloraButton(
            label: l10n.communityTipWrite,
            style: FloraButtonStyle.secondary,
            icon: CupertinoIcons.pencil,
            expand: true,
            onPressed: () => _write(context, ref, speciesId: speciesId, speciesName: speciesName),
          )
        else if (!service.canPublish) ...[
          Text(l10n.communityTipNeedsAccount, style: context.text.caption),
          if (canSignIn) ...[
            const SizedBox(height: Space.sm),
            FloraButton(
              label: l10n.signIn,
              style: FloraButtonStyle.secondary,
              expand: true,
              onPressed: () => context.push(Routes.account),
            ),
          ],
        ],
      ],
    );
  }
}

/// Ouvre la feuille d'écriture, et relit la liste quand quelque chose est
/// parti.
Future<void> _write(BuildContext context, WidgetRef ref, {required String speciesId, required String speciesName, SpeciesTip? existing}) async {
  final changed = await showWriteTipSheet(context, speciesId: speciesId, speciesName: speciesName, existing: existing);
  if (changed) ref.invalidate(speciesTipsProvider(speciesId));
}

/// Un conseil : qui l'a écrit, quand, ce qu'il dit, et ce qu'on peut en
/// faire — le trouver utile, le signaler, ou le reprendre quand il est de
/// soi.
class _TipCard extends ConsumerWidget {
  const _TipCard({required this.tip, required this.speciesId, required this.speciesName});

  final SpeciesTip tip;
  final String speciesId;
  final String speciesName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final author = tip.mine ? l10n.communityTipYours : (tip.authorName.isEmpty ? l10n.communityTipAnonymous : tip.authorName);
    return FloraCard(
      color: tip.mine ? c.sageSoft : null,
      onTap: tip.mine ? () => _write(context, ref, speciesId: speciesId, speciesName: speciesName, existing: tip) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$author · ${Dates.relativeDay(context, tip.createdAt)}',
            style: context.text.caption.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: Space.xs),
          Text(tip.body, style: context.text.callout.copyWith(color: c.ink)),

          // Un conseil signalé disparaît pour les autres sans disparaître
          // pour son auteur : sans cette ligne, il le croirait toujours
          // visible.
          if (tip.hidden) ...[
            const SizedBox(height: Space.xs),
            Text(l10n.communityTipHidden, style: context.text.caption.copyWith(color: c.danger)),
          ],
          const SizedBox(height: Space.sm),
          Row(
            children: [
              FloraChip(
                label: tip.votes == 0 ? l10n.communityTipHelpful : '${l10n.communityTipHelpful} · ${tip.votes}',
                emoji: '👍',
                selected: tip.voted,
                onTap: tip.mine ? null : () => _vote(context, ref),
              ),
              const Spacer(),
              if (!tip.mine)
                FloraIconButton(
                  icon: CupertinoIcons.ellipsis,
                  semanticLabel: l10n.moreOptions,
                  size: 32,
                  filled: false,
                  onPressed: () => _menu(context, ref),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Une voix part et revient : le serveur tient le compte (une par personne
  /// et par conseil), la liste se relit pour le montrer.
  Future<void> _vote(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    try {
      await ref.online(() => ref.read(communityTipsServiceProvider).vote(tip.id, helpful: !tip.voted));
      Haptics.light();
      ref.invalidate(speciesTipsProvider(speciesId));
    } catch (e, st) {
      if (e is! OfflineException) ref.read(crashReporterProvider).report(e, st, context: 'community-tip');
      if (!context.mounted) return;
      ref.read(toastProvider.notifier).show(
            ToastData(message: e is OfflineException ? l10n.offlineActionFailed : l10n.genericError, emoji: e is OfflineException ? '📡' : '!'),
          );
    }
  }

  Future<void> _menu(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    await showAdaptiveActionSheet(
      context,
      cancelLabel: l10n.cancel,
      actions: [
        SheetAction(
          label: l10n.communityTipReport,
          icon: CupertinoIcons.flag,
          destructive: true,
          onPressed: () async {
            final ok = await showAdaptiveConfirm(
              context,
              title: l10n.confirmReportTip,
              message: l10n.communityTipReportNote(speciesTipReportsToHide),
              confirmLabel: l10n.communityTipReport,
              cancelLabel: l10n.cancel,
              destructive: true,
            );
            if (!ok || !context.mounted) return;
            await _report(context, ref);
          },
        ),
      ],
    );
  }

  Future<void> _report(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    try {
      await ref.online(() => ref.read(communityTipsServiceProvider).report(tip.id));
      Haptics.warning();
      ref.invalidate(speciesTipsProvider(speciesId));
      if (!context.mounted) return;
      ref.read(toastProvider.notifier).show(ToastData(message: l10n.communityTipReported, emoji: '🚩'));
    } catch (e, st) {
      if (e is! OfflineException) ref.read(crashReporterProvider).report(e, st, context: 'community-tip');
      if (!context.mounted) return;
      ref.read(toastProvider.notifier).show(
            ToastData(message: e is OfflineException ? l10n.offlineActionFailed : l10n.genericError, emoji: e is OfflineException ? '📡' : '!'),
          );
    }
  }
}
