import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../app/sync_coordinator.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/auth/auth_repository.dart';
import '../../../domain/sync/sync_state.dart';

/// Compte : connexion (Apple, Google, e-mail par code), état de synchronisation.
class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  bool _emailMode = false;
  bool _codeSent = false;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action, {String? errorOverride}) async {
    if (_busy) return;
    setState(() => _busy = true);
    final l10n = context.l10n;
    try {
      await action();
      Haptics.success();
    } on AuthException catch (e) {
      ref.read(toastProvider.notifier).show(ToastData(message: e.message == 'apple_unavailable' ? l10n.appleUnavailable : (errorOverride ?? l10n.authError), emoji: '!'));
    } catch (e, st) {
      ref.read(crashReporterProvider).report(e, st, context: 'auth');
      if (mounted) ref.read(toastProvider.notifier).show(ToastData(message: l10n.authError, emoji: '!'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final auth = ref.watch(authRepositoryProvider);
    final user = ref.watch(currentUserProvider).value;
    final signedIn = user != null && !user.isLocal;
    return FloraPage(
      title: l10n.accountTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!auth.supportsRemote) ...[
            FloraGroup(footer: l10n.localAccountHint, children: [FloraListRow(leading: Icon(CupertinoIcons.lock, size: 20, color: context.colors.inkSecondary), title: l10n.localAccount)]),
          ] else if (signedIn) ...[
            _SignedIn(user: user, onSignOut: () => _run(() async {
              final ok = await showAdaptiveConfirm(context, title: l10n.signOut, message: l10n.signOutConfirm, confirmLabel: l10n.signOut, cancelLabel: l10n.cancel, destructive: true);
              if (ok) await auth.signOut();
            })),
          ] else ...[
            Text(l10n.signInHint, style: context.text.callout),
            const SizedBox(height: Space.xl),
            if (defaultTargetPlatform == TargetPlatform.iOS) ...[
              FloraButton(label: l10n.continueWithApple, icon: CupertinoIcons.person_crop_circle, expand: true, loading: _busy, onPressed: () => _run(auth.signInWithApple)),
              const SizedBox(height: Space.xs),
            ],
            FloraButton(label: l10n.continueWithGoogle, icon: CupertinoIcons.globe, style: FloraButtonStyle.secondary, expand: true, onPressed: _busy ? null : () => _run(auth.signInWithGoogle)),
            const SizedBox(height: Space.xs),
            FloraButton(label: l10n.continueWithEmail, icon: CupertinoIcons.mail, style: FloraButtonStyle.secondary, expand: true, onPressed: _busy ? null : () => setState(() => _emailMode = true)),
            AnimatedSize(
              duration: Motion.of(context, Motion.standard),
              curve: Motion.easeOut,
              alignment: Alignment.topCenter,
              child: !_emailMode
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(top: Space.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          FloraTextField(controller: _email, hint: l10n.emailHint, keyboardType: TextInputType.emailAddress, textCapitalization: TextCapitalization.none, autofocus: true, enabled: !_codeSent, textInputAction: TextInputAction.send, onSubmitted: (_) => _sendCode()),
                          const SizedBox(height: Space.xs),
                          if (!_codeSent)
                            FloraButton(label: l10n.sendCode, expand: true, loading: _busy, onPressed: _sendCode)
                          else ...[
                            Text(l10n.codeSent(_email.text.trim()), style: context.text.caption),
                            const SizedBox(height: Space.xs),
                            FloraTextField(controller: _code, hint: l10n.codeHint, keyboardType: TextInputType.number, textCapitalization: TextCapitalization.none, autofocus: true, textInputAction: TextInputAction.done, onSubmitted: (_) => _verify()),
                            const SizedBox(height: Space.xs),
                            FloraButton(label: l10n.verifyCode, expand: true, loading: _busy, onPressed: _verify),
                          ],
                        ],
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _sendCode() => _run(() async {
        if (!_email.text.contains('@')) throw const AuthException('bad_email');
        await ref.read(authRepositoryProvider).requestEmailCode(_email.text);
        if (mounted) setState(() => _codeSent = true);
      });

  Future<void> _verify() => _run(() => ref.read(authRepositoryProvider).verifyEmailCode(email: _email.text, code: _code.text));
}

class _SignedIn extends ConsumerWidget {
  const _SignedIn({required this.user, required this.onSignOut});

  final AppUser user;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final sync = ref.watch(syncCoordinatorProvider);
    final status = switch (sync.status) {
      SyncStatus.syncing => l10n.syncSyncing,
      SyncStatus.offline => l10n.syncOffline,
      SyncStatus.error => l10n.syncError,
      SyncStatus.idle => sync.lastSyncedAt == null ? l10n.syncNever : l10n.syncIdle(Dates.time(context, sync.lastSyncedAt!)),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FloraCard(
          child: Row(
            children: [
              FloraAvatar(name: user.displayName, size: 52),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.displayName.isEmpty ? l10n.signedInAs : user.displayName, style: context.text.title3),
                    if (user.email != null) Text(user.email!, style: context.text.caption),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Space.lg),
        FloraGroup(
          header: l10n.synchronization,
          children: [
            FloraListRow(
              leading: sync.status == SyncStatus.syncing ? const AdaptiveProgress() : Icon(sync.status == SyncStatus.error ? CupertinoIcons.exclamationmark_circle : CupertinoIcons.checkmark_circle, size: 20, color: sync.status == SyncStatus.error ? c.terracotta : c.sage),
              title: status,
              subtitle: sync.pendingCount > 0 ? l10n.syncPending(sync.pendingCount) : null,
            ),
            FloraListRow(leading: Icon(CupertinoIcons.arrow_2_circlepath, size: 20, color: c.inkSecondary), title: l10n.syncNow, onTap: () => ref.read(syncCoordinatorProvider.notifier).syncNow(), chevron: false),
          ],
        ),
        const SizedBox(height: Space.lg),
        FloraGroup(children: [FloraListRow(leading: Icon(CupertinoIcons.person_2, size: 20, color: c.inkSecondary), title: l10n.membersTitle, subtitle: l10n.shareGarden, onTap: () => context.push(Routes.members))]),
        const SizedBox(height: Space.lg),
        FloraGroup(children: [FloraListRow(title: l10n.signOut, destructive: true, onTap: onSignOut, chevron: false)]),
      ],
    );
  }
}
