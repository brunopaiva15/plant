import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models/models.dart';
import '../../locations/presentation/location_picker_sheet.dart';

/// Création / édition d'un article d'inventaire.
Future<void> showInventoryItemSheet(BuildContext context, {InventoryItem? existing, InventoryCategory? category}) =>
    showFloraSheet<void>(context, scrollable: true, builder: (_) => _ItemBody(existing: existing, initialCategory: category));

class _ItemBody extends ConsumerStatefulWidget {
  const _ItemBody({this.existing, this.initialCategory});

  final InventoryItem? existing;
  final InventoryCategory? initialCategory;

  @override
  ConsumerState<_ItemBody> createState() => _ItemBodyState();
}

class _ItemBodyState extends ConsumerState<_ItemBody> {
  late InventoryCategory _category = widget.existing?.category ?? widget.initialCategory ?? InventoryCategory.fertilizer;
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
      await repo.create(category: _category, name: _name.text, quantity: qty, unit: _unit, lowThreshold: threshold, locationId: _locationId, notes: _notes.text);
    } else {
      await repo.update(widget.existing!.copyWith(
        category: _category,
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
          SheetHeader(title: widget.existing == null ? l10n.newItem : l10n.editItem),
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
