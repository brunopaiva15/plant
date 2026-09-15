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

/// Écrire, remplacer ou retirer son conseil sur une espèce.
///
/// Une personne, un conseil par espèce : la feuille s'ouvre sur celui qui est
/// déjà publié plutôt que d'en empiler un second. Répondre à ce qu'on a écrit
/// se fait donc au même endroit que l'écrire.
///
/// Renvoie `true` quand quelque chose est parti — la liste se relit alors.
Future<bool> showWriteTipSheet(
  BuildContext context, {
  required String speciesId,
  required String speciesName,
  SpeciesTip? existing,
}) async {
  final changed = await showFloraSheet<bool>(
    context,
    scrollable: true,
    builder: (_) => _WriteTipSheet(speciesId: speciesId, speciesName: speciesName, existing: existing),
  );
  return changed ?? false;
}

class _WriteTipSheet extends ConsumerStatefulWidget {
  const _WriteTipSheet({required this.speciesId, required this.speciesName, this.existing});

  final String speciesId;
  final String speciesName;
  final SpeciesTip? existing;

  @override
  ConsumerState<_WriteTipSheet> createState() => _WriteTipSheetState();
}

class _WriteTipSheetState extends ConsumerState<_WriteTipSheet> {
  late final _body = TextEditingController(text: widget.existing?.body ?? '');
  bool _busy = false;

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  /// Le texte tel qu'il partirait, ou `null` tant qu'il est trop court ou
  /// trop long : c'est lui qui décide si le bouton répond.
  String? get _ready => cleanTipBody(_body.text);

  Future<void> _publish() async {
    final body = _ready;
    if (_busy || body == null) return;
    setState(() => _busy = true);
    final l10n = context.l10n;
    try {
      await ref.online(() => ref.read(communityTipsServiceProvider).publish(
            speciesId: widget.speciesId,
            speciesName: widget.speciesName,
            body: body,
          ));
      Haptics.success();
      if (!mounted) return;
      ref.read(toastProvider.notifier).show(ToastData(message: l10n.communityTipPublished, emoji: '🌿'));
      Navigator.of(context).pop(true);
    } catch (e, st) {
      if (e is! OfflineException) ref.read(crashReporterProvider).report(e, st, context: 'community-tip');
      if (!mounted) return;
      setState(() => _busy = false);
      ref.read(toastProvider.notifier).show(
            ToastData(message: e is OfflineException ? l10n.offlineActionFailed : l10n.genericError, emoji: e is OfflineException ? '📡' : '!'),
          );
    }
  }

  Future<void> _withdraw() async {
    final tip = widget.existing;
    if (_busy || tip == null) return;
    final l10n = context.l10n;
    final ok = await showAdaptiveConfirm(
      context,
      title: l10n.confirmDeleteTip,
      confirmLabel: l10n.delete,
      cancelLabel: l10n.cancel,
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.online(() => ref.read(communityTipsServiceProvider).withdraw(tip.id));
      Haptics.warning();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e, st) {
      if (e is! OfflineException) ref.read(crashReporterProvider).report(e, st, context: 'community-tip');
      if (!mounted) return;
      setState(() => _busy = false);
      ref.read(toastProvider.notifier).show(
            ToastData(message: e is OfflineException ? l10n.offlineActionFailed : l10n.genericError, emoji: e is OfflineException ? '📡' : '!'),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final used = _body.text.characters.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(title: l10n.communityTipYours),
          // Un conseil ne part pas sans réseau : la feuille le dit avant
          // qu'on écrive trois lignes, pas après.
          if (!ref.watch(isOnlineProvider))
            OfflineNotice(subtitle: l10n.offlineCommunityTips)
          else ...[
            Text(l10n.communityTipPublicNote, style: context.text.callout),
            const SizedBox(height: Space.md),
            FloraTextField(
              controller: _body,
              hint: l10n.communityTipPlaceholder,
              autofocus: true,
              minLines: 3,
              maxLines: 6,
              enabled: !_busy,
              keyboardType: TextInputType.multiline,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: Space.xs),
            // Le compte des signes plutôt qu'un champ qui refuse la frappe :
            // on voit venir la limite, et un conseil trop long se raccourcit
            // au lieu d'être coupé au milieu d'un mot.
            Text(
              l10n.communityTipLength(used, speciesTipMaxLength),
              style: context.text.caption.copyWith(color: used > speciesTipMaxLength ? c.danger : c.inkTertiary),
              textAlign: TextAlign.end,
            ),
            const SizedBox(height: Space.lg),
            FloraButton(
              label: l10n.communityTipPublish,
              expand: true,
              loading: _busy,
              onPressed: _ready == null ? null : _publish,
            ),
            if (widget.existing != null) ...[
              const SizedBox(height: Space.sm),
              FloraButton(
                label: l10n.delete,
                style: FloraButtonStyle.ghost,
                expand: true,
                onPressed: _busy ? null : _withdraw,
              ),
            ],
          ],
        ],
      ),
    );
  }
}
