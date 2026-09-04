import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models/models.dart';
import '../../../domain/repositories/repositories.dart';
import '../application/care_actions.dart';
import 'action_type_sheet.dart';

/// « Qu'avez-vous fait ? » : type, date (aujourd'hui par défaut), note, et
/// champs contextuels (quantité, mesure). Deux taps suffisent.
Future<void> showAddActionSheet(BuildContext context, {required String plantId, required String plantName, String? initialTypeKey}) {
  return showFloraSheet<void>(
    context,
    scrollable: true,
    builder: (ctx) => _AddActionBody(plantId: plantId, plantName: plantName, initialTypeKey: initialTypeKey),
  );
}

class _AddActionBody extends ConsumerStatefulWidget {
  const _AddActionBody({required this.plantId, required this.plantName, this.initialTypeKey});

  final String plantId;
  final String plantName;
  final String? initialTypeKey;

  @override
  ConsumerState<_AddActionBody> createState() => _AddActionBodyState();
}

class _AddActionBodyState extends ConsumerState<_AddActionBody> {
  late String _type = widget.initialTypeKey ?? CareKind.watering.key;
  DateTime _when = DateTime.now();
  final _note = TextEditingController();
  final _quantity = TextEditingController();
  final _value = TextEditingController();
  String _measureKind = 'height';
  bool _saving = false;

  @override
  void dispose() {
    _note.dispose();
    _quantity.dispose();
    _value.dispose();
    super.dispose();
  }

  bool get _isMeasurement => _type == CareKind.measurement.key;
  bool get _hasQuantity => _type == CareKind.watering.key || _type == CareKind.fertilizing.key;

  Future<void> _pickDate() async {
    final d = await showAdaptiveDatePicker(context, initial: _when, last: DateTime.now(), doneLabel: context.l10n.done);
    if (d != null) setState(() => _when = DateTime(d.year, d.month, d.day, _when.hour, _when.minute));
  }

  Future<void> _save() async {
    if (_saving) return;
    final l10n = context.l10n;
    final metadata = <String, Object?>{};
    if (_hasQuantity && _quantity.text.trim().isNotEmpty) {
      metadata['quantity'] = double.tryParse(_quantity.text.trim().replaceAll(',', '.'));
      metadata['unit'] = 'ml';
    }
    if (_isMeasurement) {
      final v = double.tryParse(_value.text.trim().replaceAll(',', '.'));
      if (v == null) return;
      metadata['kind'] = _measureKind;
      metadata['value'] = v;
      metadata['unit'] = _measureKind == 'leaves' ? '' : (ref.read(preferencesProvider).metricUnits ? 'cm' : 'in');
    }
    setState(() => _saving = true);
    final custom = ref.read(actionTypeByKeyProvider)[_type];
    await ref.read(careActionsProvider).log(
          NewAction(plantId: widget.plantId, typeKey: _type, occurredAt: _when, notes: _note.text, metadata: metadata),
          message: l10n.actionDoneToast(widget.plantName, l10n.kindDone(_type, custom: custom)),
          undoLabel: l10n.undo,
          emoji: custom?.emoji ?? '✓',
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final types = (ref.watch(actionTypesProvider).value ?? const <ActionType>[]).where((t) => t.key != CareKind.photo.key).toList();
    final isToday = DateUtils.isSameDay(_when, DateTime.now());
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SheetHeader(title: l10n.whatDidYouDo),
          Wrap(
            spacing: Space.xs,
            runSpacing: Space.xs,
            children: [
              for (final t in types)
                FloraChip(
                  emoji: t.emoji,
                  label: l10n.kindName(t.key, custom: t),
                  selected: t.key == _type,
                  onTap: () => setState(() => _type = t.key),
                ),
              FloraChip(
                icon: CupertinoIcons.plus,
                label: l10n.newActionType,
                onTap: () async {
                  final created = await showNewActionTypeSheet(context);
                  if (created != null) setState(() => _type = created.key);
                },
              ),
            ],
          ),
          const SizedBox(height: Space.lg),
          FloraGroup(
            children: [
              FloraListRow(
                leading: Icon(CupertinoIcons.calendar, size: 20, color: c.inkSecondary),
                title: l10n.when,
                trailing: Text(isToday ? l10n.dueToday : Dates.day(context, _when), style: context.text.callout.copyWith(color: c.sage, fontWeight: FontWeight.w600)),
                onTap: _pickDate,
                chevron: false,
                dense: true,
              ),
              if (_hasQuantity)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.xs),
                  child: Row(
                    children: [
                      Icon(CupertinoIcons.drop, size: 20, color: c.inkSecondary),
                      const SizedBox(width: Space.sm + 8),
                      Expanded(child: Text(l10n.quantity, style: context.text.body)),
                      SizedBox(
                        width: 110,
                        child: FloraTextField(
                          controller: _quantity,
                          hint: 'ml',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textCapitalization: TextCapitalization.none,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (_isMeasurement) ...[
            const SizedBox(height: Space.md),
            AdaptiveSegmented<String>(
              segments: {'height': l10n.measureHeight, 'width': l10n.measureWidth, 'leaves': l10n.measureLeaves, 'pot': l10n.measurePot},
              value: _measureKind,
              onChanged: (v) => setState(() => _measureKind = v),
            ),
            const SizedBox(height: Space.sm),
            FloraTextField(
              controller: _value,
              hint: _measureKind == 'leaves' ? l10n.value : '${l10n.value} (${ref.watch(preferencesProvider).metricUnits ? 'cm' : 'in'})',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textCapitalization: TextCapitalization.none,
              autofocus: true,
            ),
          ],
          const SizedBox(height: Space.md),
          FloraTextField(controller: _note, hint: l10n.noteHint, minLines: 1, maxLines: 4, textInputAction: TextInputAction.newline),
          const SizedBox(height: Space.xl),
          FloraButton(label: l10n.record, expand: true, loading: _saving, onPressed: _save),
        ],
      ),
    );
  }
}
