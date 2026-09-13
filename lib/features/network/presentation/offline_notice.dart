import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/network/connectivity.dart';
import '../../../design_system/design_system.dart';

/// Ce qui prend la place d'un contenu qui n'existe que sur le réseau.
///
/// Un écran qui charge sans fin ne dit rien : ni ce qui manque, ni ce qu'on
/// peut y faire. Celui-ci dit les deux, et son bouton relit l'état du réseau
/// — quand il est revenu, l'écran se remplit de lui-même.
class OfflineNotice extends ConsumerStatefulWidget {
  const OfflineNotice({super.key, this.subtitle, this.onRetry, this.compact = true});

  /// Ce que cet écran-là ne peut pas faire hors ligne. À défaut, la phrase
  /// générale : les données locales restent lisibles.
  final String? subtitle;

  /// Geste supplémentaire une fois le réseau retrouvé — relancer une requête
  /// qui ne repart pas d'elle-même.
  final VoidCallback? onRetry;
  final bool compact;

  @override
  ConsumerState<OfflineNotice> createState() => _OfflineNoticeState();
}

class _OfflineNoticeState extends ConsumerState<OfflineNotice> {
  var _busy = false;

  Future<void> _retry() async {
    if (_busy) return;
    setState(() => _busy = true);
    await ref.read(connectivityProvider.notifier).refresh();
    if (!mounted) return;
    setState(() => _busy = false);
    widget.onRetry?.call();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return EmptyState(
      emoji: '📡',
      title: l10n.offlineTitle,
      subtitle: widget.subtitle ?? l10n.offlineHint,
      actionLabel: _busy ? null : l10n.retry,
      onAction: _busy ? null : _retry,
      compact: widget.compact,
    );
  }
}

/// Bandeau posé en tête d'un écran qui marche sans réseau, mais pas en
/// entier : la liste se lit, le geste qui la modifie attendra.
///
/// Il ne s'affiche que hors ligne et disparaît seul au retour du réseau.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key, this.message, this.padding = const EdgeInsets.only(bottom: Space.lg)});

  /// Ce qui, sur cet écran, attend le réseau. À défaut, la phrase générale.
  final String? message;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(isOnlineProvider)) return const SizedBox.shrink();
    final c = context.colors;
    return Padding(
      padding: padding,
      child: FloraCard(
        color: c.sageSoft,
        padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(CupertinoIcons.wifi_slash, size: 18, color: c.inkSecondary),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Text(
                message ?? context.l10n.offlineHint,
                style: context.text.caption.copyWith(color: c.inkSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
