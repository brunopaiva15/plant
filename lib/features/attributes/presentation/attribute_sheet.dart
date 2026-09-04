import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models/models.dart';
import '../application/attribute_providers.dart';

/// Libellé localisé d'un type d'attribut.
String attributeTypeName(AppLocalizations l10n, AttributeType t) => switch (t) {
      AttributeType.boolean => l10n.fieldTypeBool,
      AttributeType.integer => l10n.fieldTypeInt,
      AttributeType.decimal => l10n.fieldTypeDouble,
      AttributeType.text => l10n.fieldTypeText,
      AttributeType.date => l10n.fieldTypeDate,
    };

/// Valeur affichable d'un attribut, selon son type.
String attributeValueLabel(BuildContext context, PlantAttribute a) {
  final l10n = context.l10n;
  if (a.isEmpty) return l10n.fieldEmpty;
  return switch (a.type) {
    AttributeType.boolean => (a.asBool ?? false) ? l10n.yes : l10n.no,
    AttributeType.date => a.asDate == null ? a.value! : Dates.dayYear(context, a.asDate!),
    _ => a.value!,
  };
}

/// Création ou édition d'un champ personnalisé d'une plante.
Future<void> showAttributeSheet(BuildContext context, {required String plantId, PlantAttribute? existing}) =>
    showFloraSheet<void>(context, scrollable: true, builder: (_) => _AttributeBody(plantId: plantId, existing: existing));

class _AttributeBody extends ConsumerStatefulWidget {
  const _AttributeBody({required this.plantId, this.existing});

  final String plantId;
  final PlantAttribute? existing;

  @override
  ConsumerState<_AttributeBody> createState() => _AttributeBodyState();
}

class _AttributeBodyState extends ConsumerState<_AttributeBody> {
  late final _label = TextEditingController(text: widget.existing?.label ?? '');
  late final _text = TextEditingController(text: widget.existing?.type == AttributeType.date ? '' : (widget.existing?.value ?? ''));
  late AttributeType _type = widget.existing?.type ?? AttributeType.text;
  late bool _bool = widget.existing?.asBool ?? false;
  late DateTime? _date = widget.existing?.asDate;
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

  Future<void> _save() async {
    if (_label.text.trim().isEmpty || _saving) return;
    setState(() => _saving = true);
    final repo = ref.read(attributeRepositoryProvider);
    if (widget.existing == null) {
      await repo.add(plantId: widget.plantId, label: _label.text, type: _type, value: _encoded);
    } else {
      await repo.update(widget.existing!.copyWith(label: _label.text, type: _type, value: () => _encoded));
    }
    Haptics.success();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    final ok = await showAdaptiveConfirm(context, title: l10n.confirmDeleteField, confirmLabel: l10n.delete, cancelLabel: l10n.cancel, destructive: true);
    if (!ok || !mounted) return;
    await ref.read(attributeRepositoryProvider).delete(widget.existing!.id);
    Haptics.warning();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _pickDate() async {
    final l10n = context.l10n;
    final picked = await showAdaptiveDatePicker(context, initial: _date ?? DateTime.now(), first: DateTime(1900), doneLabel: l10n.done);
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final schemas = ref.watch(activeAttributeSchemasProvider).value ?? const <AttributeSchema>[];
    final suggestions = widget.existing != null ? const <AttributeSchema>[] : schemas.where((s) => s.label.toLowerCase() != _label.text.trim().toLowerCase()).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(title: widget.existing == null ? l10n.addCustomField : l10n.editCustomField),
          FloraTextField(controller: _label, hint: l10n.fieldLabelHint, autofocus: widget.existing == null, onChanged: (_) => setState(() {})),
          if (suggestions.isNotEmpty) ...[
            const SizedBox(height: Space.sm),
            Text(l10n.fieldFromTemplate, style: context.text.caption),
            const SizedBox(height: Space.xs),
            Wrap(
              spacing: Space.xs,
              runSpacing: Space.xs,
              children: [
                for (final s in suggestions)
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
              for (final t in AttributeType.values)
                FloraChip(label: attributeTypeName(l10n, t), selected: _type == t, onTap: () => setState(() => _type = t)),
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
                  trailing: _date == null
                      ? null
                      : FloraButton(label: l10n.delete, style: FloraButtonStyle.ghost, size: FloraButtonSize.small, onPressed: () => setState(() => _date = null)),
                  onTap: _pickDate,
                ),
              ),
            AttributeType.integer || AttributeType.decimal => FloraTextField(
                controller: _text,
                hint: l10n.fieldValue,
                keyboardType: TextInputType.numberWithOptions(decimal: _type == AttributeType.decimal),
              ),
            AttributeType.text => FloraTextField(controller: _text, hint: l10n.fieldValue, minLines: 1, maxLines: 4),
          },
          const SizedBox(height: Space.xl),
          FloraButton(label: widget.existing == null ? l10n.add : l10n.save, expand: true, loading: _saving, onPressed: _label.text.trim().isEmpty ? null : _save),
          if (widget.existing != null) ...[
            const SizedBox(height: Space.xs),
            FloraButton(label: l10n.deleteCustomField, style: FloraButtonStyle.ghost, expand: true, onPressed: _delete),
          ],
        ],
      ),
    );
  }
}
