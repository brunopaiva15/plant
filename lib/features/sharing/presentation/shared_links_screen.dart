import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/network/connectivity.dart';
import '../../../core/network/network_failure.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/sharing/shared_link.dart';
import '../../network/presentation/offline_notice.dart';
import 'share_link_sheet.dart';

/// Réglages : tous les liens publics créés, avec révocation.
class SharedLinksScreen extends ConsumerWidget {
  const SharedLinksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final service = ref.watch(sharingServiceProvider);
    final links = ref.watch(sharedLinksProvider);
    final now = DateTime.now();

    return FloraPage(
      title: l10n.sharedLinks,
      child: !service.isAvailable
          ? EmptyState(emoji: '🔗', title: l10n.shareNeedsAccount, compact: true)
          : links.when(
              loading: () => const Padding(padding: EdgeInsets.all(Space.xxl), child: Center(child: AdaptiveProgress())),
              // Hors ligne, la liste n'est ni vide ni en erreur : elle est
              // restée sur le serveur. Le tourniquet ne le disait pas, et
              // rien ne l'arrêtait.
              error: (error, _) => error is OfflineException
                  ? OfflineNotice(subtitle: l10n.offlineSharing, onRetry: () => ref.invalidate(sharedLinksProvider))
                  : EmptyState(
                      emoji: '📡',
                      title: l10n.genericError,
                      actionLabel: l10n.retry,
                      onAction: () => ref.invalidate(sharedLinksProvider),
                      compact: true,
                    ),
              data: (items) => items.isEmpty
                  ? EmptyState(emoji: '🔗', title: l10n.noSharedLinks, subtitle: l10n.sharedLinksHint, compact: true)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(l10n.sharedLinksHint, style: context.text.callout),
                        const SizedBox(height: Space.lg),
                        FloraGroup(
                          children: [
                            for (final link in items)
                              FloraListRow(
                                leading: Text(link.kind == SharedKind.photo ? '🖼️' : '🪴', style: const TextStyle(fontSize: 18)),
                                title: link.title ?? link.token,
                                subtitle: _status(context, link, now),
                                subtitleColor: link.isLive(now) ? c.sage : c.inkTertiary,
                                chevron: false,
                                trailing: FloraIconButton(
                                  icon: CupertinoIcons.ellipsis,
                                  semanticLabel: l10n.moreOptions,
                                  size: 32,
                                  filled: false,
                                  onPressed: () => _menu(context, ref, link, service.baseUrl),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
            ),
    );
  }

  static String _status(BuildContext context, SharedLink link, DateTime now) {
    final l10n = context.l10n;
    if (link.isRevoked) return l10n.shareRevoked;
    if (link.isExpired(now)) return l10n.shareExpired;
    if (link.expiresAt != null) return '${l10n.shareActive} · ${l10n.shareExpiry} ${Dates.dayYear(context, link.expiresAt!)}';
    return l10n.shareActive;
  }

  /// Révoquer et supprimer touchent le serveur : hors ligne le geste ne part
  /// pas, et l'écran le dit plutôt que de laisser croire qu'il est passé.
  static Future<void> _run(BuildContext context, WidgetRef ref, Future<void> Function() action) async {
    final l10n = context.l10n;
    try {
      await ref.online(action);
      Haptics.warning();
      ref.invalidate(sharedLinksProvider);
    } catch (error) {
      if (error is! OfflineException) ref.read(crashReporterProvider).report(error, StackTrace.current, context: 'shared-link');
      if (!context.mounted) return;
      ref.read(toastProvider.notifier).show(ToastData(message: error is OfflineException ? l10n.offlineActionFailed : l10n.genericError, emoji: error is OfflineException ? '📡' : '!'));
    }
  }

  Future<void> _menu(BuildContext context, WidgetRef ref, SharedLink link, String baseUrl) async {
    final l10n = context.l10n;
    await showAdaptiveActionSheet(
      context,
      cancelLabel: l10n.cancel,
      actions: [
        if (link.isLive(DateTime.now()))
          SheetAction(
            label: l10n.shareCopy,
            icon: CupertinoIcons.doc_on_doc,
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: link.url(baseUrl)));
              Haptics.light();
              if (context.mounted) ref.read(toastProvider.notifier).show(ToastData(message: l10n.shareCopied, emoji: '🔗'));
            },
          ),
        if (!link.isRevoked)
          SheetAction(
            label: l10n.shareRevoke,
            icon: CupertinoIcons.eye_slash,
            destructive: true,
            onPressed: () async {
              final ok = await showAdaptiveConfirm(context, title: l10n.confirmRevokeLink, confirmLabel: l10n.shareRevoke, cancelLabel: l10n.cancel, destructive: true);
              if (!ok || !context.mounted) return;
              await _run(context, ref, () => ref.read(sharingServiceProvider).revoke(link.id));
            },
          ),
        SheetAction(
          label: l10n.delete,
          icon: CupertinoIcons.trash,
          destructive: true,
          onPressed: () => _run(context, ref, () => ref.read(sharingServiceProvider).delete(link.id)),
        ),
      ],
    );
  }
}
