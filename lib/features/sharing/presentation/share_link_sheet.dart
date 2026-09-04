import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show SelectableText;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/providers.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/sharing/shared_link.dart';

/// Liens de partage du jardin, rafraîchis à chaque ouverture.
final sharedLinksProvider = FutureProvider.autoDispose<List<SharedLink>>((ref) => ref.watch(sharingServiceProvider).list());

/// Crée un lien public vers une plante ou une photo.
Future<void> showShareLinkSheet(BuildContext context, {required String plantId, String? photoId, String? suggestedTitle}) => showFloraSheet<void>(
      context,
      scrollable: true,
      builder: (_) => _ShareBody(plantId: plantId, photoId: photoId, suggestedTitle: suggestedTitle),
    );

class _ShareBody extends ConsumerStatefulWidget {
  const _ShareBody({required this.plantId, this.photoId, this.suggestedTitle});

  final String plantId;
  final String? photoId;
  final String? suggestedTitle;

  @override
  ConsumerState<_ShareBody> createState() => _ShareBodyState();
}

class _ShareBodyState extends ConsumerState<_ShareBody> {
  late final _title = TextEditingController(text: widget.suggestedTitle ?? '');
  final _description = TextEditingController();
  final _keywords = TextEditingController();
  bool _unlisted = true;
  DateTime? _expiresAt;
  bool _saving = false;
  SharedLink? _created;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _keywords.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final l10n = context.l10n;
    try {
      final link = await ref.read(sharingServiceProvider).create(NewSharedLink(
            plantId: widget.plantId,
            photoId: widget.photoId,
            kind: widget.photoId == null ? SharedKind.plant : SharedKind.photo,
            title: _title.text,
            description: _description.text,
            keywords: _keywords.text,
            unlisted: _unlisted,
            expiresAt: _expiresAt,
          ));
      Haptics.success();
      ref.invalidate(sharedLinksProvider);
      if (mounted) setState(() => _created = link);
    } catch (_) {
      Haptics.warning();
      if (mounted) {
        setState(() {
          _saving = false;
          _error = l10n.shareFailed;
        });
      }
    }
  }

  Future<void> _pickExpiry() async {
    final l10n = context.l10n;
    final now = DateTime.now();
    final picked = await showAdaptiveDatePicker(context, initial: _expiresAt ?? now.add(const Duration(days: 30)), first: now, doneLabel: l10n.done);
    if (picked != null) setState(() => _expiresAt = DateTime(picked.year, picked.month, picked.day, 23, 59));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final service = ref.watch(sharingServiceProvider);

    if (!service.isAvailable) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SheetHeader(title: l10n.shareByLink),
            EmptyState(emoji: '🔗', title: l10n.shareNeedsAccount, compact: true),
          ],
        ),
      );
    }

    final link = _created;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(title: widget.photoId == null ? l10n.sharePlant : l10n.sharePhoto),
          if (link != null) ...[
            FloraCard(
              color: c.sageSoft,
              padding: const EdgeInsets.all(Space.md),
              child: SelectableText(link.url(service.baseUrl), style: context.text.callout.copyWith(color: c.ink)),
            ),
            const SizedBox(height: Space.md),
            FloraButton(
              label: l10n.shareCopy,
              icon: CupertinoIcons.doc_on_doc,
              expand: true,
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: link.url(service.baseUrl)));
                Haptics.light();
                if (context.mounted) ref.read(toastProvider.notifier).show(ToastData(message: l10n.shareCopied, emoji: '🔗'));
              },
            ),
            const SizedBox(height: Space.xs),
            FloraButton(
              label: l10n.shareQr,
              style: FloraButtonStyle.secondary,
              expand: true,
              onPressed: () => SharePlus.instance.share(ShareParams(text: link.url(service.baseUrl))),
            ),
            const SizedBox(height: Space.xs),
            FloraButton(label: l10n.close, style: FloraButtonStyle.ghost, expand: true, onPressed: () => Navigator.of(context).pop()),
          ] else ...[
            Text(l10n.sharedLinksHint, style: context.text.caption),
            const SizedBox(height: Space.md),
            FloraTextField(controller: _title, hint: l10n.shareTitle),
            const SizedBox(height: Space.xs),
            FloraTextField(controller: _description, hint: l10n.shareDescription, minLines: 1, maxLines: 3),
            const SizedBox(height: Space.xs),
            FloraTextField(controller: _keywords, hint: l10n.shareKeywords),
            const SizedBox(height: Space.md),
            FloraGroup(
              children: [
                FloraListRow(
                  leading: const Text('🙈', style: TextStyle(fontSize: 18)),
                  title: l10n.shareUnlisted,
                  subtitle: l10n.shareUnlistedHint,
                  chevron: false,
                  trailing: AdaptiveSwitch(value: _unlisted, onChanged: (v) => setState(() => _unlisted = v)),
                ),
                FloraListRow(
                  leading: const Text('⏳', style: TextStyle(fontSize: 18)),
                  title: l10n.shareExpiry,
                  chevron: false,
                  trailing: Text(
                    _expiresAt == null ? l10n.shareNoExpiry : Dates.dayYear(context, _expiresAt!),
                    style: context.text.callout.copyWith(color: c.sage, fontWeight: FontWeight.w600),
                  ),
                  onTap: _pickExpiry,
                ),
              ],
            ),
            if (_expiresAt != null)
              Align(
                alignment: Alignment.centerLeft,
                child: FloraButton(
                  label: l10n.shareNoExpiry,
                  style: FloraButtonStyle.ghost,
                  size: FloraButtonSize.small,
                  onPressed: () => setState(() => _expiresAt = null),
                ),
              ),
            if (_error != null) ...[
              const SizedBox(height: Space.sm),
              Text(_error!, style: context.text.caption.copyWith(color: c.danger)),
            ],
            const SizedBox(height: Space.xl),
            FloraButton(label: l10n.shareCreate, expand: true, loading: _saving, onPressed: _create),
          ],
        ],
      ),
    );
  }
}
