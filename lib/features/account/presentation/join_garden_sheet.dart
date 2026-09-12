import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../data/db/database.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/auth/auth_repository.dart';
import '../../../domain/sharing/garden_collaboration.dart';
import '../application/membership_providers.dart';
import '../application/sign_in_availability.dart';

/// Rejoindre un jardin partagé : on saisit le code (ou il arrive tout fait par
/// le lien d'invitation), on voit ce qu'il promet, et on accepte.
///
/// C'est par ce lien qu'arrive le plus souvent quelqu'un qui n'a pas encore
/// de compte. La feuille ne le renvoie pas ailleurs : là où la connexion
/// existe, son bouton devient « Continuer avec Apple », et l'invitation est
/// acceptée dans la foulée. Là où elle n'existe pas (Android, pour l'heure),
/// elle le dit d'emblée plutôt qu'au moment d'accepter.
///
/// Retourne `true` si le jardin a été rejoint — l'application bascule alors
/// dessus.
Future<bool> showJoinGardenSheet(BuildContext context, {String? code}) async =>
    await showFloraSheet<bool>(context, scrollable: true, builder: (_) => _JoinSheet(initialCode: code)) ?? false;

class _JoinSheet extends ConsumerStatefulWidget {
  const _JoinSheet({this.initialCode});

  final String? initialCode;

  @override
  ConsumerState<_JoinSheet> createState() => _JoinSheetState();
}

class _JoinSheetState extends ConsumerState<_JoinSheet> {
  late final TextEditingController _code = TextEditingController(text: widget.initialCode ?? '');
  bool _busy = false;
  InvitePreview? _preview;
  String? _error;

  @override
  void initState() {
    super.initState();
    if ((widget.initialCode ?? '').isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _look());
    }
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  String get _clean => CollaborationService.normalizeCode(_code.text);

  /// Ce que promet le code, avant de l'utiliser.
  Future<void> _look() async {
    if (_busy || _clean.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final preview = await ref.read(collaborationServiceProvider).previewInvite(_clean);
      if (!mounted) return;
      setState(() {
        if (preview == null) {
          _error = context.l10n.joinInvalid;
        } else {
          _preview = preview;
        }
      });
    } on CollaborationException catch (e) {
      if (mounted) setState(() => _error = _message(e.error));
    } catch (e, st) {
      ref.read(crashReporterProvider).report(e, st, context: 'join-preview');
      if (mounted) setState(() => _error = context.l10n.genericError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Se connecter sans quitter la feuille, puis reprendre où l'on en était :
  /// accepter si l'invitation est déjà connue, la regarder sinon.
  Future<void> _signInThenContinue() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final l10n = context.l10n;
    try {
      await ref.read(authRepositoryProvider).signInWithApple();
      Haptics.success();
    } on AuthException catch (e) {
      // Refermer la feuille d'Apple n'est pas une erreur : on reste là.
      if (mounted) setState(() => _error = e.message == 'cancelled' ? null : (e.message == 'apple_unavailable' ? l10n.appleUnavailable : l10n.authError));
      return;
    } catch (e, st) {
      ref.read(crashReporterProvider).report(e, st, context: 'join-sign-in');
      if (mounted) setState(() => _error = l10n.authError);
      return;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (!mounted) return;
    await (_preview == null ? _look() : _accept());
  }

  Future<void> _accept() async {
    if (_busy) return;
    setState(() => _busy = true);
    final l10n = context.l10n;
    try {
      final gardenId = await ref.read(collaborationServiceProvider).acceptInvite(_clean);
      // Le rôle est inscrit tout de suite : sans lui, l'application croirait
      // l'invité propriétaire jusqu'à la première synchronisation, et lui
      // proposerait des gestes que le serveur refuserait. Le compte est lu
      // sur le dépôt, pas sur le flux : juste après une connexion faite ici,
      // le flux n'a pas encore livré le nouvel utilisateur.
      final user = ref.read(authRepositoryProvider).currentUser;
      final role = _preview?.role;
      if (user != null && !user.isLocal && role != null) {
        final db = ref.read(databaseProvider);
        await db.into(db.gardenMembers).insertOnConflictUpdate(GardenMembersCompanion.insert(gardenId: gardenId, userId: user.id, role: role.key));
      }
      await ref.read(activeGardenProvider.notifier).select(gardenId);
      ref.invalidate(myGardensProvider);
      Haptics.success();
      if (!mounted) return;
      ref.read(toastProvider.notifier).show(ToastData(message: l10n.joined(_preview?.gardenName ?? ''), emoji: '🌿'));
      Navigator.of(context).pop(true);
    } on CollaborationException catch (e) {
      if (mounted) setState(() => _error = _message(e.error));
    } catch (e, st) {
      ref.read(crashReporterProvider).report(e, st, context: 'join-accept');
      if (mounted) setState(() => _error = l10n.genericError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _message(CollaborationError error) {
    final l10n = context.l10n;
    return switch (error) {
      CollaborationError.invalidCode => l10n.joinInvalid,
      CollaborationError.wrongEmail => l10n.joinWrongEmail,
      CollaborationError.notSignedIn => l10n.joinNeedsAccount,
      _ => l10n.genericError,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final preview = _preview;
    final user = ref.watch(currentUserProvider).value;
    final signedIn = user != null && !user.isLocal;
    final canSignIn = !signedIn && signInAvailable(ref.watch(authRepositoryProvider));
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(title: l10n.joinGarden),
          if (preview == null) ...[
            Text(l10n.joinGardenHint, style: context.text.callout),
            const SizedBox(height: Space.md),
            FloraTextField(
              controller: _code,
              hint: l10n.inviteCodeHint,
              autofocus: widget.initialCode == null,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.go,
              onSubmitted: (_) => _look(),
            ),
          ] else ...[
            Text(
              preview.ownerName.isEmpty ? l10n.joinGardenName(preview.gardenName) : l10n.joinInvitedBy(preview.ownerName, preview.gardenName),
              style: context.text.title3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Space.xs),
            Text(
              preview.role == GardenRole.viewer ? l10n.joinAsViewer : l10n.joinAsMember,
              style: context.text.callout,
              textAlign: TextAlign.center,
            ),
            if (preview.alreadyMember) ...[
              const SizedBox(height: Space.xs),
              Text(l10n.joinAlreadyMember, style: context.text.caption, textAlign: TextAlign.center),
            ],
          ],
          if (_error != null) ...[
            const SizedBox(height: Space.md),
            Text(_error!, style: context.text.callout.copyWith(color: c.danger), textAlign: TextAlign.center),
          ] else if (!signedIn) ...[
            // Sans compte, on le dit avant le geste, pas après : ici la
            // connexion se fait sur place, ailleurs elle n'existe pas encore.
            const SizedBox(height: Space.md),
            Text(canSignIn ? l10n.joinSignInHint : l10n.joinNeedsAccount, style: context.text.caption, textAlign: TextAlign.center),
          ],
          const SizedBox(height: Space.lg),
          if (canSignIn)
            FloraButton(label: l10n.continueWithApple, icon: Icons.apple, expand: true, loading: _busy, onPressed: _signInThenContinue)
          else
            FloraButton(
              label: preview == null ? l10n.joinLook : l10n.joinConfirm,
              icon: preview == null ? CupertinoIcons.search : CupertinoIcons.checkmark_alt,
              expand: true,
              loading: _busy,
              onPressed: preview == null ? _look : _accept,
            ),
        ],
      ),
    );
  }
}
