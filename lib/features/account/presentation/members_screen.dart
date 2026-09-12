import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../app/sync_coordinator.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/sharing/garden_collaboration.dart';
import '../application/membership_providers.dart';
import '../application/sign_in_availability.dart';
import 'gardens_screen.dart' show gardenLabel, leaveGarden;
import 'invite_sheet.dart';

/// Les gens du jardin : qui en est, ce qu'ils peuvent y faire, et les
/// invitations en attente. Le propriétaire invite, change les rôles et
/// retire ; les autres voient la liste et peuvent partir.
class MembersScreen extends ConsumerWidget {
  const MembersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final service = ref.watch(collaborationServiceProvider);
    final user = ref.watch(currentUserProvider).value;
    final signedIn = user != null && !user.isLocal;
    final meId = user?.id;
    final members = ref.watch(gardenMembersProvider).value ?? const <GardenMemberInfo>[];
    final isOwner = ref.watch(canManageMembersProvider);
    final gardenName = gardenLabel(context, ref.watch(activeGardenNameProvider).value ?? '', isMine: isOwner);

    if (!service.isAvailable || !signedIn) {
      final canSignIn = signInAvailable(ref.watch(authRepositoryProvider));
      return FloraPage(
        title: l10n.membersTitle,
        child: EmptyState(
          emoji: '🤝',
          title: l10n.collaborationNeedsAccount,
          subtitle: canSignIn ? l10n.signInHint : l10n.localAccountHint,
          actionLabel: canSignIn ? l10n.signIn : null,
          onAction: canSignIn ? () => context.push(Routes.account) : null,
          compact: true,
        ),
      );
    }

    return FloraPage(
      title: l10n.membersTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(isOwner ? l10n.membersHint : l10n.membersGuestHint, style: context.text.callout),
          const SizedBox(height: Space.lg),
          FloraGroup(
            header: gardenName,
            children: [
              for (final m in members)
                FloraListRow(
                  leading: FloraAvatar(name: m.label, size: 32),
                  title: m.label,
                  subtitle: [_roleName(context, m.role), if (m.userId == meId) l10n.you].join(' · '),
                  chevron: false,
                  trailing: isOwner && m.role != GardenRole.owner
                      ? FloraIconButton(
                          icon: CupertinoIcons.ellipsis,
                          semanticLabel: l10n.moreOptions,
                          size: 32,
                          filled: false,
                          onPressed: () => _memberMenu(context, ref, m),
                        )
                      : null,
                ),
            ],
          ),
          if (isOwner) ...[
            const SizedBox(height: Space.lg),
            FloraButton(
              label: l10n.inviteSomeone,
              icon: CupertinoIcons.person_add,
              expand: true,
              onPressed: () => showInviteSheet(context),
            ),
            const SizedBox(height: Space.xl),
            const _PendingInvites(),
          ] else ...[
            const SizedBox(height: Space.lg),
            if (!ref.watch(canEditProvider)) ...[
              Text(l10n.readOnlyHint, style: context.text.callout.copyWith(color: c.inkSecondary)),
              const SizedBox(height: Space.lg),
            ],
            FloraGroup(
              children: [
                FloraListRow(
                  leading: Icon(CupertinoIcons.square_arrow_left, size: 20, color: c.danger),
                  title: l10n.leaveGarden,
                  destructive: true,
                  chevron: false,
                  onTap: () => leaveGarden(context, ref, ref.read(gardenIdProvider), gardenName),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _roleName(BuildContext context, GardenRole role) {
    final l10n = context.l10n;
    return switch (role) {
      GardenRole.owner => l10n.roleOwner,
      GardenRole.viewer => l10n.roleViewer,
      GardenRole.member => l10n.roleMember,
    };
  }

  Future<void> _memberMenu(BuildContext context, WidgetRef ref, GardenMemberInfo member) async {
    final l10n = context.l10n;
    final other = member.role == GardenRole.viewer ? GardenRole.member : GardenRole.viewer;
    await showAdaptiveActionSheet(
      context,
      title: member.label,
      message: l10n.memberRoleHint,
      cancelLabel: l10n.cancel,
      actions: [
        SheetAction(
          label: l10n.makeRole(_roleName(context, other)),
          icon: other == GardenRole.viewer ? CupertinoIcons.eye : CupertinoIcons.pencil,
          onPressed: () => _setRole(context, ref, member, other),
        ),
        SheetAction(
          label: l10n.removeMember,
          icon: CupertinoIcons.minus_circle,
          destructive: true,
          onPressed: () => _remove(context, ref, member),
        ),
      ],
    );
  }

  Future<void> _setRole(BuildContext context, WidgetRef ref, GardenMemberInfo member, GardenRole role) async {
    final l10n = context.l10n;
    try {
      await ref.read(collaborationServiceProvider).setRole(gardenId: ref.read(gardenIdProvider), userId: member.userId, role: role);
      Haptics.success();
      await ref.read(syncCoordinatorProvider.notifier).syncNow();
      if (context.mounted) {
        ref.read(toastProvider.notifier).show(ToastData(message: l10n.roleChanged(member.label, _roleName(context, role)), emoji: '✓'));
      }
    } catch (e, st) {
      ref.read(crashReporterProvider).report(e, st, context: 'set-role');
      if (context.mounted) ref.read(toastProvider.notifier).show(ToastData(message: l10n.genericError, emoji: '!'));
    }
  }

  Future<void> _remove(BuildContext context, WidgetRef ref, GardenMemberInfo member) async {
    final l10n = context.l10n;
    final ok = await showAdaptiveConfirm(
      context,
      title: l10n.removeMember,
      message: l10n.removeMemberConfirm(member.label),
      confirmLabel: l10n.removeMember,
      cancelLabel: l10n.cancel,
      destructive: true,
    );
    if (!ok) return;
    try {
      await ref.read(collaborationServiceProvider).removeMember(gardenId: ref.read(gardenIdProvider), userId: member.userId);
      Haptics.warning();
      await ref.read(syncCoordinatorProvider.notifier).syncNow();
    } catch (e, st) {
      ref.read(crashReporterProvider).report(e, st, context: 'remove-member');
      if (context.mounted) ref.read(toastProvider.notifier).show(ToastData(message: l10n.genericError, emoji: '!'));
    }
  }
}

/// Invitations créées et pas encore utilisées : de quoi les renvoyer ou les
/// annuler tant que personne ne s'en est servi.
class _PendingInvites extends ConsumerWidget {
  const _PendingInvites();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final invites = ref.watch(gardenInvitesProvider).value ?? const <GardenInvite>[];
    final now = DateTime.now();
    final pending = invites.where((i) => i.isPending(now)).toList();
    if (pending.isEmpty) return const SizedBox.shrink();
    return FloraGroup(
      header: l10n.invitesTitle,
      footer: l10n.inviteOnceHint,
      children: [
        for (final invite in pending)
          FloraListRow(
            leading: const Text('✉️', style: TextStyle(fontSize: 18)),
            title: invite.prettyCode,
            subtitle: [
              invite.role == GardenRole.viewer ? l10n.roleViewer : l10n.roleMember,
              if (invite.email != null) invite.email!,
              if (invite.expiresAt != null) l10n.inviteExpires(Dates.dayYear(context, invite.expiresAt!)),
            ].join(' · '),
            chevron: false,
            trailing: FloraIconButton(
              icon: CupertinoIcons.xmark_circle,
              semanticLabel: l10n.inviteRevoke,
              size: 32,
              filled: false,
              color: c.danger,
              onPressed: () => _revoke(context, ref, invite),
            ),
          ),
      ],
    );
  }

  Future<void> _revoke(BuildContext context, WidgetRef ref, GardenInvite invite) async {
    final l10n = context.l10n;
    final ok = await showAdaptiveConfirm(
      context,
      title: l10n.inviteRevoke,
      message: l10n.inviteRevokeConfirm,
      confirmLabel: l10n.inviteRevoke,
      cancelLabel: l10n.cancel,
      destructive: true,
    );
    if (!ok) return;
    await ref.read(collaborationServiceProvider).revokeInvite(invite.id);
    Haptics.warning();
    ref.invalidate(gardenInvitesProvider);
    if (context.mounted) ref.read(toastProvider.notifier).show(ToastData(message: l10n.inviteRevoked, emoji: '🚫'));
  }
}
