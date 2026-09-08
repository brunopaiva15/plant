import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/providers.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/sharing/garden_collaboration.dart';
import '../application/membership_providers.dart';

/// Créer une invitation, puis en partager le lien.
///
/// Deux temps dans la même feuille : on choisit ce que la personne pourra
/// faire, puis on récupère de quoi le lui envoyer. Le code ne sert qu'une
/// fois — ce qu'on partage n'ouvre pas le jardin à qui le relaierait ensuite.
Future<void> showInviteSheet(BuildContext context) async {
  await showFloraSheet<void>(context, scrollable: true, builder: (_) => const _InviteSheet());
}

class _InviteSheet extends ConsumerStatefulWidget {
  const _InviteSheet();

  @override
  ConsumerState<_InviteSheet> createState() => _InviteSheetState();
}

class _InviteSheetState extends ConsumerState<_InviteSheet> {
  final _email = TextEditingController();
  GardenRole _role = GardenRole.member;
  bool _busy = false;
  GardenInvite? _invite;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_busy) return;
    setState(() => _busy = true);
    final l10n = context.l10n;
    try {
      final invite = await ref.read(collaborationServiceProvider).createInvite(
            gardenId: ref.read(gardenIdProvider),
            email: _email.text,
            role: _role,
          );
      Haptics.success();
      ref.invalidate(gardenInvitesProvider);
      if (mounted) setState(() => _invite = invite);
    } catch (e, st) {
      ref.read(crashReporterProvider).report(e, st, context: 'invite');
      if (mounted) ref.read(toastProvider.notifier).show(ToastData(message: l10n.inviteFailed, emoji: '!'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final invite = _invite;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(title: invite == null ? l10n.inviteSomeone : l10n.inviteReady),
          if (invite == null) ..._form(context) else ..._share(context, invite),
        ],
      ),
    );
  }

  List<Widget> _form(BuildContext context) {
    final l10n = context.l10n;
    return [
      Text(l10n.inviteRoleHint, style: context.text.callout),
      const SizedBox(height: Space.md),
      AdaptiveSegmented<GardenRole>(
        segments: {GardenRole.member: l10n.roleMember, GardenRole.viewer: l10n.roleViewer},
        value: _role,
        onChanged: (v) => setState(() => _role = v),
      ),
      const SizedBox(height: Space.lg),
      FloraTextField(
        controller: _email,
        hint: l10n.inviteEmailOptional,
        keyboardType: TextInputType.emailAddress,
        textCapitalization: TextCapitalization.none,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _create(),
      ),
      const SizedBox(height: Space.xs),
      Text(l10n.inviteEmailHint, style: context.text.caption),
      const SizedBox(height: Space.lg),
      FloraButton(label: l10n.inviteCreate, icon: CupertinoIcons.person_add, expand: true, loading: _busy, onPressed: _create),
    ];
  }

  List<Widget> _share(BuildContext context, GardenInvite invite) {
    final l10n = context.l10n;
    final c = context.colors;
    final link = ref.read(collaborationServiceProvider).inviteLink(invite.code);
    return [
      Text(l10n.inviteShareHint, style: context.text.callout),
      const SizedBox(height: Space.lg),
      FloraCard(
        child: Column(
          children: [
            // Le même lien en QR : la personne d'en face le scanne sans rien
            // recopier, avec son appareil photo ou le scanner d'Auxine.
            Container(
              padding: const EdgeInsets.all(Space.sm),
              decoration: BoxDecoration(color: const Color(0xFFFFFFFF), borderRadius: Radii.largeAll, border: Border.all(color: c.line)),
              child: QrImageView(
                data: link,
                size: 160,
                padding: EdgeInsets.zero,
                eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF1A1F1B)),
                dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Color(0xFF1A1F1B)),
              ),
            ),
            const SizedBox(height: Space.md),
            Text(invite.prettyCode, style: context.text.title2.copyWith(letterSpacing: 3)),
            const SizedBox(height: Space.xxs),
            Text(
              [
                invite.role == GardenRole.viewer ? l10n.roleViewer : l10n.roleMember,
                if (invite.email != null) invite.email!,
                if (invite.expiresAt != null) l10n.inviteExpires(Dates.dayYear(context, invite.expiresAt!)),
              ].join(' · '),
              style: context.text.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      const SizedBox(height: Space.lg),
      FloraButton(
        label: l10n.inviteShare,
        icon: CupertinoIcons.square_arrow_up,
        expand: true,
        onPressed: () => SharePlus.instance.share(ShareParams(text: l10n.inviteMessage(link))),
      ),
      const SizedBox(height: Space.xs),
      FloraButton(
        label: l10n.shareCopy,
        icon: CupertinoIcons.doc_on_doc,
        style: FloraButtonStyle.secondary,
        expand: true,
        onPressed: () async {
          await Clipboard.setData(ClipboardData(text: link));
          Haptics.light();
          if (context.mounted) ref.read(toastProvider.notifier).show(ToastData(message: l10n.shareCopied, emoji: '🔗'));
        },
      ),
      const SizedBox(height: Space.md),
      Text(l10n.inviteOnceHint, style: context.text.caption.copyWith(color: c.inkTertiary), textAlign: TextAlign.center),
    ];
  }
}
