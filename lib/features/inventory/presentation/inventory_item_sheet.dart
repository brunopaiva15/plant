import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../attachments/presentation/attachments_section.dart' show showRenameSheet;
import 'inventory_list.dart';
import 'inventory_qr_sheet.dart';

import '../../../app/providers.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models/models.dart';
import '../../locations/presentation/location_picker_sheet.dart';

/// Création / édition d'un article d'inventaire.
Future<void> showInventoryItemSheet(BuildContext context, {InventoryItem? existing, InventoryCategory? category, String? groupId}) =>
    showFloraSheet<void>(context, scrollable: true, builder: (_) => _ItemBody(existing: existing, initialCategory: category, initialGroupId: groupId));

class _ItemBody extends ConsumerStatefulWidget {
  const _ItemBody({this.existing, this.initialCategory, this.initialGroupId});

  final InventoryItem? existing;
  final InventoryCategory? initialCategory;
  final String? initialGroupId;

  @override
  ConsumerState<_ItemBody> createState() => _ItemBodyState();
}

class _ItemBodyState extends ConsumerState<_ItemBody> {
  late InventoryCategory _category = widget.existing?.category ?? widget.initialCategory ?? InventoryCategory.fertilizer;
  late String? _groupId = widget.existing?.groupId ?? widget.initialGroupId;
  late List<String> _tagIds = const [];
  bool _tagsLoaded = false;
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _quantity = TextEditingController(text: widget.existing == null ? '' : _fmt(widget.existing!.quantity));
  late final _threshold = TextEditingController(text: widget.existing?.lowThreshold == null ? '' : _fmt(widget.existing!.lowThreshold!));
  late final _notes = TextEditingController(text: widget.existing?.notes ?? '');
  late String _unit = widget.existing?.unit ?? _category.defaultUnit;
  late String? _locationId = widget.existing?.locationId;
  bool _more = false;
  bool _saving = false;

  static String _fmt(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();
  static double? _parse(String s) => double.tryParse(s.trim().replaceAll(',', '.'));

  @override
  void dispose() {
    for (final c in [_name, _quantity, _threshold, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty || _saving) return;
    setState(() => _saving = true);
    final repo = ref.read(inventoryRepositoryProvider);
    final qty = _parse(_quantity.text) ?? 0;
    final threshold = _parse(_threshold.text);
    if (widget.existing == null) {
      final created = await repo.create(category: _category, groupId: _groupId, name: _name.text, quantity: qty, unit: _unit, lowThreshold: threshold, locationId: _locationId, notes: _notes.text);
      await repo.setItemTags(created.id, _tagIds);
    } else {
      await repo.setItemTags(widget.existing!.id, _tagIds);
      await repo.update(widget.existing!.copyWith(
        category: _category,
        groupId: () => _groupId,
        name: _name.text,
        quantity: qty,
        unit: _unit,
        lowThreshold: () => threshold,
        locationId: () => _locationId,
        notes: () => _notes.text,
      ));
    }
    Haptics.success();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    final ok = await showAdaptiveConfirm(context, title: l10n.deleteItem, confirmLabel: l10n.delete, cancelLabel: l10n.cancel, destructive: true);
    if (!ok) return;
    await ref.read(inventoryRepositoryProvider).delete(widget.existing!.id);
    Haptics.warning();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final locations = ref.watch(locationsProvider).value ?? const <Location>[];
    final location = locations.where((l) => l.id == _locationId).firstOrNull;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(
            title: widget.existing == null ? l10n.newItem : l10n.editItem,
            trailing: widget.existing == null
                ? null
                : FloraIconButton(
                    icon: CupertinoIcons.qrcode,
                    semanticLabel: l10n.itemQr,
                    size: 32,
                    filled: false,
                    onPressed: () => showInventoryQrSheet(context, widget.existing!),
                  ),
          ),
          Wrap(
            spacing: Space.xs,
            runSpacing: Space.xs,
            children: [
              for (final cat in InventoryCategory.values)
                FloraChip(
                  emoji: cat.emoji,
                  label: l10n.categoryName(cat),
                  selected: cat == _category,
                  onTap: () => setState(() {
                    _category = cat;
                    if (widget.existing == null) _unit = cat.defaultUnit;
                  }),
                ),
            ],
          ),
          const SizedBox(height: Space.md),
          _GroupPicker(selected: _groupId, onChanged: (id) => setState(() => _groupId = id)),
          const SizedBox(height: Space.md),
          _TagPicker(
            itemId: widget.existing?.id,
            selected: _tagIds,
            onLoaded: (ids) {
              if (_tagsLoaded) return;
              _tagsLoaded = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _tagIds = ids);
              });
            },
            onChanged: (ids) => setState(() => _tagIds = ids),
          ),
          const SizedBox(height: Space.md),
          FloraTextField(controller: _name, hint: l10n.itemNameHint, autofocus: widget.existing == null, textCapitalization: TextCapitalization.sentences),
          const SizedBox(height: Space.xs),
          Row(
            children: [
              Expanded(
                child: FloraTextField(
                  controller: _quantity,
                  hint: l10n.quantity,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textCapitalization: TextCapitalization.none,
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.xs),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final u in inventoryUnits)
                  Padding(
                    padding: const EdgeInsets.only(right: Space.xs),
                    child: FloraChip(label: u.isEmpty ? l10n.unitPieces : u, selected: _unit == u, onTap: () => setState(() => _unit = u)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Space.md),
          Pressable(
            onTap: () => setState(() => _more = !_more),
            scale: 1,
            child: Row(
              children: [
                Text(l10n.moreOptions, style: context.text.callout.copyWith(color: c.sage, fontWeight: FontWeight.w600)),
                const SizedBox(width: 4),
                AnimatedRotation(turns: _more ? 0.5 : 0, duration: Motion.of(context, Motion.standard), child: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: c.sage)),
              ],
            ),
          ),
          AnimatedSize(
            duration: Motion.of(context, Motion.standard),
            curve: Motion.easeOut,
            alignment: Alignment.topCenter,
            child: !_more
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: Space.md),
                    child: FloraGroup(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(Space.md, Space.sm, Space.md, Space.sm),
                          child: Row(
                            children: [
                              Expanded(child: Text(l10n.lowThreshold, style: context.text.body)),
                              SizedBox(
                                width: 110,
                                child: FloraTextField(controller: _threshold, hint: _unit.isEmpty ? '0' : '0 $_unit', keyboardType: const TextInputType.numberWithOptions(decimal: true), textCapitalization: TextCapitalization.none),
                              ),
                            ],
                          ),
                        ),
                        FloraListRow(
                          leading: Text(location?.icon ?? '📍', style: const TextStyle(fontSize: 18)),
                          title: l10n.filterLocation,
                          trailing: Text(location?.name ?? l10n.none, style: context.text.callout.copyWith(color: c.sage, fontWeight: FontWeight.w600)),
                          chevron: false,
                          onTap: () async {
                            final choice = await showLocationPicker(context, selectedId: _locationId);
                            if (choice != null) setState(() => _locationId = choice.id);
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.all(Space.sm),
                          child: FloraTextField(controller: _notes, hint: l10n.notesHint, minLines: 2, maxLines: 5),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: Space.xl),
          FloraButton(label: widget.existing == null ? l10n.add : l10n.save, expand: true, loading: _saving, onPressed: _save),
          if (widget.existing != null) ...[
            const SizedBox(height: Space.xs),
            FloraButton(label: l10n.deleteItem, style: FloraButtonStyle.ghost, expand: true, onPressed: _delete),
          ],
        ],
      ),
    );
  }
}

/// Choix du groupe : les groupes personnalisés, plus « sans groupe ».
class _GroupPicker extends ConsumerWidget {
  const _GroupPicker({required this.selected, required this.onChanged});

  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final groups = ref.watch(inventoryGroupsProvider).value ?? const <InventoryGroup>[];
    if (groups.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.itemGroup, style: context.text.caption),
        const SizedBox(height: Space.xs),
        Wrap(
          spacing: Space.xs,
          runSpacing: Space.xs,
          children: [
            FloraChip(label: l10n.noGroup, selected: selected == null, onTap: () => onChanged(null)),
            for (final g in groups) FloraChip(emoji: g.emoji, label: g.label, selected: selected == g.id, onTap: () => onChanged(g.id)),
          ],
        ),
      ],
    );
  }
}

/// Tags de l'article, avec création à la volée.
class _TagPicker extends ConsumerWidget {
  const _TagPicker({required this.itemId, required this.selected, required this.onChanged, required this.onLoaded});

  final String? itemId;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;
  final ValueChanged<List<String>> onLoaded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final tags = ref.watch(tagsProvider).value ?? const <Tag>[];
    if (itemId != null) {
      final current = ref.watch(_itemTagsProvider(itemId!)).value;
      if (current != null) onLoaded(current.map((t) => t.id).toList());
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.itemTags, style: context.text.caption),
        const SizedBox(height: Space.xs),
        Wrap(
          spacing: Space.xs,
          runSpacing: Space.xs,
          children: [
            for (final t in tags)
              FloraChip(
                label: t.name,
                emoji: '🏷️',
                selected: selected.contains(t.id),
                onTap: () => onChanged(selected.contains(t.id) ? ([...selected]..remove(t.id)) : [...selected, t.id]),
              ),
            FloraChip(
              label: l10n.newTag,
              dashed: true,
              onTap: () async {
                final name = await showRenameSheet(context, title: l10n.newTag, hint: l10n.tagNameHint);
                if (name == null || name.isEmpty) return;
                final tag = await ref.read(tagRepositoryProvider).create(name);
                onChanged([...selected, tag.id]);
              },
            ),
          ],
        ),
      ],
    );
  }
}

final _itemTagsProvider = StreamProvider.autoDispose.family<List<Tag>, String>((ref, id) => ref.watch(inventoryRepositoryProvider).watchItemTags(id));
