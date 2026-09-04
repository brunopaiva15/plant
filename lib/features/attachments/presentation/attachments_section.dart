import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/providers.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/utils/file_kinds.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models/models.dart';

final plantAttachmentsProvider =
    StreamProvider.autoDispose.family<List<PlantAttachment>, String>((ref, plantId) => ref.watch(attachmentRepositoryProvider).watchForPlant(plantId));

/// Documents rattachés à une plante : ajout, ouverture, renommage, partage.
class AttachmentsSection extends ConsumerWidget {
  const AttachmentsSection({super.key, required this.plantId});

  final String plantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final items = ref.watch(plantAttachmentsProvider(plantId)).value ?? const <PlantAttachment>[];
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: l10n.attachments, actionLabel: l10n.add, onAction: () => _pick(context, ref)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.page),
            child: items.isEmpty
                ? FloraCard(
                    child: FloraListRow(
                      leading: const Text('📎', style: TextStyle(fontSize: 18)),
                      title: l10n.noAttachments,
                      subtitle: l10n.noAttachmentsHint,
                      onTap: () => _pick(context, ref),
                    ),
                  )
                : FloraGroup(
                    children: [
                      for (final a in items)
                        FloraListRow(
                          leading: Text(FileKinds.emoji(a.kind), style: const TextStyle(fontSize: 18)),
                          title: a.label,
                          subtitle: [FileKinds.size(a.sizeBytes), Dates.dayYear(context, a.createdAt)].where((s) => s.isNotEmpty).join(' · '),
                          dense: true,
                          chevron: false,
                          trailing: FloraIconButton(
                            icon: CupertinoIcons.ellipsis,
                            semanticLabel: l10n.moreOptions,
                            size: 32,
                            filled: false,
                            onPressed: () => _menu(context, ref, a),
                          ),
                          onTap: () => _open(context, ref, a),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _pick(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final file = await FilePicker.pickFile(dialogTitle: l10n.addAttachment);
    final path = file?.path;
    if (path == null || !context.mounted) return;
    await ref.read(attachmentRepositoryProvider).add(plantId: plantId, sourcePath: path, label: file!.name);
    Haptics.success();
    if (context.mounted) ref.read(toastProvider.notifier).show(ToastData(message: l10n.addAttachment, emoji: '📎'));
  }

  Future<void> _open(BuildContext context, WidgetRef ref, PlantAttachment a) async {
    final l10n = context.l10n;
    final path = await ref.read(attachmentRepositoryProvider).absolutePath(a);
    final result = await OpenFilex.open(path);
    if (result.type != ResultType.done && context.mounted) {
      ref.read(toastProvider.notifier).show(ToastData(message: l10n.attachmentOpenFailed, emoji: '⚠️'));
    }
  }

  Future<void> _menu(BuildContext context, WidgetRef ref, PlantAttachment a) async {
    final l10n = context.l10n;
    await showAdaptiveActionSheet(
      context,
      cancelLabel: l10n.cancel,
      actions: [
        SheetAction(label: l10n.openAttachment, icon: CupertinoIcons.arrow_up_right_square, onPressed: () => _open(context, ref, a)),
        SheetAction(label: l10n.renameAttachment, icon: CupertinoIcons.textformat, onPressed: () => _rename(context, ref, a)),
        SheetAction(label: l10n.shareQr, icon: CupertinoIcons.share, onPressed: () => _share(context, ref, a)),
        SheetAction(label: l10n.deleteAttachment, icon: CupertinoIcons.trash, destructive: true, onPressed: () => _delete(context, ref, a)),
      ],
    );
  }

  Future<void> _rename(BuildContext context, WidgetRef ref, PlantAttachment a) async {
    final label = await showRenameSheet(context, title: context.l10n.renameAttachment, hint: context.l10n.attachmentLabel, initial: a.label);
    if (label == null || label.isEmpty) return;
    await ref.read(attachmentRepositoryProvider).rename(a.id, label);
    Haptics.success();
  }

  Future<void> _share(BuildContext context, WidgetRef ref, PlantAttachment a) async {
    final path = await ref.read(attachmentRepositoryProvider).absolutePath(a);
    await SharePlus.instance.share(ShareParams(files: [XFile(path)], title: a.label));
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, PlantAttachment a) async {
    final l10n = context.l10n;
    final ok = await showAdaptiveConfirm(context, title: l10n.confirmDeleteAttachment, confirmLabel: l10n.delete, cancelLabel: l10n.cancel, destructive: true);
    if (!ok) return;
    await ref.read(attachmentRepositoryProvider).delete(a.id);
    Haptics.warning();
  }
}

/// Petite feuille de renommage réutilisable.
Future<String?> showRenameSheet(BuildContext context, {required String title, required String hint, String? initial}) =>
    showFloraSheet<String>(context, builder: (_) => _RenameBody(title: title, hint: hint, initial: initial));

class _RenameBody extends StatefulWidget {
  const _RenameBody({required this.title, required this.hint, this.initial});

  final String title;
  final String hint;
  final String? initial;

  @override
  State<_RenameBody> createState() => _RenameBodyState();
}

class _RenameBodyState extends State<_RenameBody> {
  late final _controller = TextEditingController(text: widget.initial ?? '');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(title: widget.title),
          FloraTextField(
            controller: _controller,
            hint: widget.hint,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
          ),
          const SizedBox(height: Space.xl),
          FloraButton(label: context.l10n.save, expand: true, onPressed: () => Navigator.of(context).pop(_controller.text.trim())),
        ],
      ),
    );
  }
}
