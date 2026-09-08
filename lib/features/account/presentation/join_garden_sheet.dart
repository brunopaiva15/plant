import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../data/db/database.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/sharing/garden_collaboration.dart';
import '../application/membership_providers.dart';

/// Rejoindre un jardin partagé : on saisit le code (ou il arrive tout fait par
/// le lien d'invitation), on voit ce qu'il promet, et on accepte.
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

  Future<void> _accept() async {
    if (_busy) return;
    setState(() => _busy = true);
    final l10n = context.l10n;
    try {
      final gardenId = await ref.read(collaborationServiceProvider).acceptInvite(_clean);
      // Le rôle est inscrit tout de suite : sans lui, l'application croirait
      // l'invité propriétaire jusqu'à la première synchronisation, et lui
      // proposerait des gestes que le serveur refuserait.
      final user = ref.read(currentUserProvider).value;
      final role = _preview?.role;
      if (user != null && role != null) {
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
          ],
          const SizedBox(height: Space.lg),
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
