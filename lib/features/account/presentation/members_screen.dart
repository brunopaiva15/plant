import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import '../../../app/providers.dart';
import '../../../app/sync_coordinator.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../data/sync/supabase_remote_data_source.dart';
import '../../../design_system/design_system.dart';
import '../application/membership_providers.dart';

/// Membres du jardin : invitation par e-mail, rôles, retrait.
class MembersScreen extends ConsumerStatefulWidget {
  const MembersScreen({super.key});

  @override
  ConsumerState<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends ConsumerState<MembersScreen> {
  final _email = TextEditingController();
  String _role = 'member';
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  SupabaseRemoteDataSource get _remote => SupabaseRemoteDataSource(Supabase.instance.client);

  Future<void> _invite() async {
    final l10n = context.l10n;
    if (!_email.text.contains('@') || _busy) return;
    setState(() => _busy = true);
    try {
      await _remote.inviteMember(gardenId: ref.read(gardenIdProvider), email: _email.text, role: _role);
      _email.clear();
      Haptics.success();
      ref.read(toastProvider.notifier).show(ToastData(message: l10n.invited, emoji: '✉️'));
      await ref.read(syncCoordinatorProvider.notifier).syncNow();
    } catch (e, st) {
      ref.read(crashReporterProvider).report(e, st, context: 'invite');
      ref.read(toastProvider.notifier).show(ToastData(message: l10n.inviteError, emoji: '!'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove(GardenMember m) async {
    final l10n = context.l10n;
    final ok = await showAdaptiveConfirm(context, title: l10n.removeMember, message: m.displayName.isEmpty ? m.email : m.displayName, confirmLabel: l10n.removeMember, cancelLabel: l10n.cancel, destructive: true);
    if (!ok) return;
    await _remote.removeMember(gardenId: ref.read(gardenIdProvider), userId: m.userId);
    Haptics.warning();
    await ref.read(syncCoordinatorProvider.notifier).syncNow();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final members = ref.watch(gardenMembersProvider).value ?? const <GardenMember>[];
    final me = ref.watch(currentUserProvider).value;
    final isOwner = ref.watch(currentRoleProvider) == 'owner';
    String roleName(String r) => switch (r) { 'owner' => l10n.roleOwner, 'viewer' => l10n.roleViewer, _ => l10n.roleMember };
    return FloraPage(
      title: l10n.membersTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FloraGroup(
            children: [
              for (final m in members)
                FloraListRow(
                  leading: FloraAvatar(name: m.displayName.isEmpty ? (m.email ?? '?') : m.displayName, size: 32),
                  title: m.displayName.isEmpty ? (m.email ?? m.userId) : m.displayName,
                  subtitle: [roleName(m.role), if (m.userId == me?.id) l10n.you].join(' · '),
                  trailing: isOwner && !m.isOwner
                      ? FloraIconButton(icon: CupertinoIcons.minus_circle, semanticLabel: l10n.removeMember, filled: false, color: c.danger, onPressed: () => _remove(m))
                      : null,
                  chevron: false,
                ),
            ],
          ),
          if (isOwner) ...[
            const SizedBox(height: Space.xl),
            Text(l10n.shareGarden, style: context.text.title3),
            const SizedBox(height: Space.xxs),
            Text(l10n.inviteHint, style: context.text.caption),
            const SizedBox(height: Space.sm),
            FloraTextField(controller: _email, hint: l10n.emailHint, keyboardType: TextInputType.emailAddress, textCapitalization: TextCapitalization.none, textInputAction: TextInputAction.send, onSubmitted: (_) => _invite()),
            const SizedBox(height: Space.xs),
            AdaptiveSegmented<String>(segments: {'member': l10n.roleMember, 'viewer': l10n.roleViewer}, value: _role, onChanged: (v) => setState(() => _role = v)),
            const SizedBox(height: Space.md),
            FloraButton(label: l10n.inviteMember, icon: CupertinoIcons.person_add, expand: true, loading: _busy, onPressed: _invite),
          ] else ...[
            const SizedBox(height: Space.md),
            Text(l10n.readOnlyHint, style: context.text.callout),
          ],
        ],
      ),
    );
  }
}
