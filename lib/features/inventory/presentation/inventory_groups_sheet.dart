import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, ReorderableListView;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models/models.dart';

/// Emoji proposés pour un groupe d'inventaire : boîtes, outils, produits.
const _groupEmojis = ['📦', '🧰', '🧪', '🪣', '🧴', '🌱', '🪴', '🌸', '🍅', '🧤', '✂️', '🏷️'];

/// Gestion des groupes personnalisés : créer, renommer, réordonner, supprimer.
Future<void> showInventoryGroupsSheet(BuildContext context) =>
    showFloraSheet<void>(context, scrollable: true, builder: (_) => const _GroupsBody());

class _GroupsBody extends ConsumerWidget {
  const _GroupsBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final groups = ref.watch(inventoryGroupsSheetProvider).value ?? const <InventoryGroup>[];
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(title: l10n.manageGroups),
          if (groups.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Space.lg),
              child: Text(l10n.noGroupsYet, style: context.text.callout.copyWith(color: c.inkSecondary), textAlign: TextAlign.center),
            )
          else
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              onReorderItem: (from, to) {
                final ids = groups.map((g) => g.id).toList();
                ids.insert(to, ids.removeAt(from));
                Haptics.selection();
                ref.read(inventoryRepositoryProvider).reorderGroups(ids);
              },
              children: [
                for (final (index, g) in groups.indexed)
                  Padding(
                    key: ValueKey(g.id),
                    padding: const EdgeInsets.only(bottom: Space.xs),
                    child: FloraCard(
                      padding: EdgeInsets.zero,
                      child: FloraListRow(
                        leading: EmojiTile(emoji: g.emoji, background: c.sageSoft),
                        title: g.label,
                        trailing: ReorderableDragStartListener(
                          index: index,
                          child: Icon(CupertinoIcons.line_horizontal_3, size: 18, color: c.inkTertiary),
                        ),
                        chevron: false,
                        onTap: () => _edit(context, ref, g),
                      ),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: Space.md),
          FloraButton(
            label: l10n.newGroup,
            icon: CupertinoIcons.plus,
            style: FloraButtonStyle.secondary,
            expand: true,
            onPressed: () => _edit(context, ref, null),
          ),
        ],
      ),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, InventoryGroup? existing) =>
      showFloraSheet<void>(context, builder: (_) => _GroupEditBody(existing: existing));
}

/// Fourni ici pour que la feuille soit autonome (sans dépendre de la liste).
final inventoryGroupsSheetProvider =
    StreamProvider.autoDispose<List<InventoryGroup>>((ref) => ref.watch(inventoryRepositoryProvider).watchGroups());

class _GroupEditBody extends ConsumerStatefulWidget {
  const _GroupEditBody({this.existing});

  final InventoryGroup? existing;

  @override
  ConsumerState<_GroupEditBody> createState() => _GroupEditBodyState();
}

class _GroupEditBodyState extends ConsumerState<_GroupEditBody> {
  late final _label = TextEditingController(text: widget.existing?.label ?? '');
  late String _emoji = widget.existing?.emoji ?? _groupEmojis.first;
  bool _saving = false;

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final label = _label.text.trim();
    if (label.isEmpty || _saving) return;
    setState(() => _saving = true);
    final repo = ref.read(inventoryRepositoryProvider);
    if (widget.existing == null) {
      await repo.createGroup(label: label, emoji: _emoji);
    } else {
      await repo.updateGroup(widget.existing!.copyWith(label: label, emoji: _emoji));
    }
    Haptics.success();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    // Les articles ne sont jamais supprimés avec le groupe : ils redeviennent
    // simplement « sans groupe ».
    final ok = await showAdaptiveConfirm(context, title: l10n.deleteGroup, message: l10n.deleteGroupExplain, confirmLabel: l10n.delete, cancelLabel: l10n.cancel, destructive: true);
    if (!ok) return;
    await ref.read(inventoryRepositoryProvider).deleteGroup(widget.existing!.id);
    Haptics.warning();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(title: widget.existing == null ? l10n.newGroup : l10n.editGroup),
          Row(
            children: [
              EmojiTile(emoji: _emoji, size: 52, background: c.sageSoft),
              const SizedBox(width: Space.sm),
              Expanded(
                child: FloraTextField(
                  controller: _label,
                  hint: l10n.groupNameHint,
                  autofocus: widget.existing == null,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _save(),
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.md),
          Wrap(
            spacing: Space.xs,
            runSpacing: Space.xs,
            children: [
              for (final e in _groupEmojis)
                Pressable(
                  onTap: () => setState(() => _emoji = e),
                  scale: 0.9,
                  child: AnimatedContainer(
                    duration: Motion.of(context, Motion.micro),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: e == _emoji ? c.sageSoft : c.surfaceMuted,
                      borderRadius: Radii.mediumAll,
                      border: Border.all(color: e == _emoji ? c.sage : Colors.transparent, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(e, style: const TextStyle(fontSize: 20)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: Space.xl),
          FloraButton(label: widget.existing == null ? l10n.add : l10n.save, expand: true, loading: _saving, onPressed: _save),
          if (widget.existing != null) ...[
            const SizedBox(height: Space.xs),
            FloraButton(label: l10n.deleteGroup, style: FloraButtonStyle.ghost, expand: true, onPressed: _delete),
          ],
        ],
      ),
    );
  }
}
