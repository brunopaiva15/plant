import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models/models.dart';
import '../application/attribute_providers.dart';
import 'attribute_sheet.dart';

/// Renseigne un même champ sur plusieurs plantes d'un coup.
/// Retourne `true` si la valeur a été appliquée.
Future<bool?> showBulkAttributeSheet(BuildContext context, {required List<String> plantIds}) =>
    showFloraSheet<bool>(context, scrollable: true, builder: (_) => _BulkBody(plantIds: plantIds));

class _BulkBody extends ConsumerStatefulWidget {
  const _BulkBody({required this.plantIds});

  final List<String> plantIds;

  @override
  ConsumerState<_BulkBody> createState() => _BulkBodyState();
}

class _BulkBodyState extends ConsumerState<_BulkBody> {
  final _label = TextEditingController();
  final _text = TextEditingController();
  AttributeType _type = AttributeType.text;
  bool _bool = false;
  DateTime? _date;
  bool _saving = false;

  @override
  void dispose() {
    _label.dispose();
    _text.dispose();
    super.dispose();
  }

  String? get _encoded => switch (_type) {
        AttributeType.boolean => PlantAttribute.encode(_type, _bool),
        AttributeType.date => PlantAttribute.encode(_type, _date),
        _ => _text.text.trim().isEmpty ? null : _text.text.trim(),
      };

  Future<void> _apply() async {
    if (_label.text.trim().isEmpty || _saving) return;
    setState(() => _saving = true);
    await ref.read(attributeRepositoryProvider).applyToPlants(widget.plantIds, label: _label.text, type: _type, value: _encoded);
    Haptics.success();
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final schemas = ref.watch(activeAttributeSchemasProvider).value ?? const <AttributeSchema>[];
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(title: l10n.bulkSetField),
          Text(l10n.selectedCount(widget.plantIds.length), style: context.text.caption),
          const SizedBox(height: Space.sm),
          FloraTextField(controller: _label, hint: l10n.fieldLabelHint, autofocus: true, onChanged: (_) => setState(() {})),
          if (schemas.isNotEmpty) ...[
            const SizedBox(height: Space.sm),
            Wrap(
              spacing: Space.xs,
              runSpacing: Space.xs,
              children: [
                for (final s in schemas)
                  FloraChip(
                    label: s.label,
                    onTap: () => setState(() {
                      _label.text = s.label;
                      _type = s.type;
                    }),
                  ),
              ],
            ),
          ],
          const SizedBox(height: Space.md),
          Text(l10n.fieldType, style: context.text.caption),
          const SizedBox(height: Space.xs),
          Wrap(
            spacing: Space.xs,
            runSpacing: Space.xs,
            children: [
              for (final t in AttributeType.values) FloraChip(label: attributeTypeName(l10n, t), selected: _type == t, onTap: () => setState(() => _type = t)),
            ],
          ),
          const SizedBox(height: Space.md),
          Text(l10n.fieldValue, style: context.text.caption),
          const SizedBox(height: Space.xs),
          switch (_type) {
            AttributeType.boolean => FloraCard(
                padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.xs),
                child: Row(
                  children: [
                    Expanded(child: Text(_bool ? l10n.yes : l10n.no, style: context.text.body)),
                    AdaptiveSwitch(value: _bool, onChanged: (v) => setState(() => _bool = v)),
                  ],
                ),
              ),
            AttributeType.date => FloraCard(
                padding: EdgeInsets.zero,
                child: FloraListRow(
                  title: _date == null ? l10n.fieldEmpty : Dates.dayYear(context, _date!),
                  leading: const Text('📅', style: TextStyle(fontSize: 18)),
                  chevron: false,
                  onTap: () async {
                    final picked = await showAdaptiveDatePicker(context, initial: _date ?? DateTime.now(), first: DateTime(1900), doneLabel: l10n.done);
                    if (picked != null) setState(() => _date = picked);
                  },
                ),
              ),
            AttributeType.integer || AttributeType.decimal => FloraTextField(
                controller: _text,
                hint: l10n.fieldValue,
                keyboardType: TextInputType.numberWithOptions(decimal: _type == AttributeType.decimal),
              ),
            AttributeType.text => FloraTextField(controller: _text, hint: l10n.fieldValue, minLines: 1, maxLines: 3),
          },
          const SizedBox(height: Space.xl),
          FloraButton(label: l10n.save, expand: true, loading: _saving, onPressed: _label.text.trim().isEmpty ? null : _apply),
        ],
      ),
    );
  }
}
