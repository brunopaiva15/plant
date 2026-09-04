import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models/models.dart';
import '../../../domain/repositories/repositories.dart';
import '../../plants/application/plant_providers.dart';
import '../../plants/presentation/plant_picker_sheet.dart';
import '../../today/application/reminder_scheduler.dart';
import '../application/task_providers.dart';

/// Création / édition d'une tâche libre.
Future<void> showTaskSheet(BuildContext context, {FreeTask? existing, String? plantId}) =>
    showFloraSheet<void>(context, scrollable: true, builder: (_) => _TaskBody(existing: existing, initialPlantId: plantId));

class _TaskBody extends ConsumerStatefulWidget {
  const _TaskBody({this.existing, this.initialPlantId});

  final FreeTask? existing;
  final String? initialPlantId;

  @override
  ConsumerState<_TaskBody> createState() => _TaskBodyState();
}

class _TaskBodyState extends ConsumerState<_TaskBody> {
  late final _title = TextEditingController(text: widget.existing?.title ?? '');
  late final _description = TextEditingController(text: widget.existing?.description ?? '');
  late String? _plantId = widget.existing?.plantId ?? widget.initialPlantId;
  late DateTime? _dueAt = widget.existing?.dueAt;
  late bool _allDay = widget.existing?.allDay ?? true;
  late int _recValue = widget.existing?.recurrence?.value ?? 1;
  late RecurrenceUnit? _recUnit = widget.existing?.recurrence?.unit;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  TaskRecurrence? get _recurrence => _recUnit == null ? null : TaskRecurrence(value: _recValue, unit: _recUnit!);

  Future<void> _save() async {
    if (_title.text.trim().isEmpty || _saving) return;
    setState(() => _saving = true);
    final repo = ref.read(taskRepositoryProvider);
    if (widget.existing == null) {
      await repo.create(NewTask(title: _title.text, description: _description.text, plantId: _plantId, dueAt: _dueAt, allDay: _allDay, recurrence: _recurrence));
    } else {
      await repo.update(widget.existing!.copyWith(
        title: _title.text,
        description: () => _description.text,
        plantId: () => _plantId,
        dueAt: () => _dueAt,
        allDay: _allDay,
        recurrence: () => _recurrence,
      ));
    }
    await ref.read(reminderSchedulerProvider).reschedule();
    Haptics.success();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    final ok = await showAdaptiveConfirm(context, title: l10n.deleteTask, confirmLabel: l10n.delete, cancelLabel: l10n.cancel, destructive: true);
    if (!ok || !mounted) return;
    final task = widget.existing!;
    Navigator.of(context).pop();
    await ref.read(taskActionsProvider).delete(context, task);
  }

  Future<void> _pickDate() async {
    final l10n = context.l10n;
    final now = DateTime.now();
    final picked = await showAdaptiveDatePicker(context, initial: _dueAt ?? now, first: DateTime(now.year - 1), doneLabel: l10n.done);
    if (picked == null) return;
    setState(() {
      final prev = _dueAt;
      _dueAt = _allDay || prev == null ? DateTime(picked.year, picked.month, picked.day) : DateTime(picked.year, picked.month, picked.day, prev.hour, prev.minute);
    });
  }

  Future<void> _pickTime() async {
    final l10n = context.l10n;
    final base = _dueAt ?? DateTime.now();
    final picked = await showAdaptiveTimePicker(context, initial: TimeOfDay(hour: _allDay ? 9 : base.hour, minute: _allDay ? 0 : base.minute), doneLabel: l10n.done);
    if (picked == null) return;
    setState(() {
      _allDay = false;
      _dueAt = DateTime(base.year, base.month, base.day, picked.hour, picked.minute);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final plant = _plantId == null ? null : ref.watch(plantSummaryProvider(_plantId!)).value;
    final accent = context.text.callout.copyWith(color: c.sage, fontWeight: FontWeight.w600);
    final units = {
      RecurrenceUnit.hours: l10n.unitHours,
      RecurrenceUnit.days: l10n.unitDays,
      RecurrenceUnit.weeks: l10n.unitWeeks,
      RecurrenceUnit.months: l10n.unitMonths,
      RecurrenceUnit.years: l10n.unitYears,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(title: widget.existing == null ? l10n.newTask : l10n.editTask),
          FloraTextField(controller: _title, hint: l10n.taskTitleHint, autofocus: widget.existing == null, textInputAction: TextInputAction.next, onSubmitted: (_) {}),
          const SizedBox(height: Space.xs),
          FloraTextField(controller: _description, hint: l10n.taskDescriptionHint, minLines: 1, maxLines: 4),
          const SizedBox(height: Space.md),
          FloraGroup(
            children: [
              FloraListRow(
                leading: const Text('🪴', style: TextStyle(fontSize: 18)),
                title: l10n.taskPlant,
                trailing: Text(plant?.plant.name ?? l10n.taskNoPlant, style: accent, maxLines: 1, overflow: TextOverflow.ellipsis),
                chevron: false,
                onTap: () async {
                  final choice = await showPlantPicker(context, selectedId: _plantId);
                  if (choice != null) setState(() => _plantId = choice.id);
                },
              ),
              FloraListRow(
                leading: const Text('📅', style: TextStyle(fontSize: 18)),
                title: l10n.taskDue,
                trailing: Text(_dueAt == null ? l10n.taskNoDue : Dates.relativeDay(context, _dueAt!), style: accent),
                chevron: false,
                onTap: _pickDate,
              ),
              if (_dueAt != null) ...[
                FloraListRow(
                  leading: const Text('🕘', style: TextStyle(fontSize: 18)),
                  title: l10n.taskTime,
                  trailing: Text(_allDay ? l10n.taskAllDay : Dates.time(context, _dueAt!), style: accent),
                  chevron: false,
                  onTap: _pickTime,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.sm),
                  child: Row(
                    children: [
                      FloraButton(
                        label: l10n.taskNoDue,
                        style: FloraButtonStyle.ghost,
                        size: FloraButtonSize.small,
                        onPressed: () => setState(() {
                          _dueAt = null;
                          _allDay = true;
                        }),
                      ),
                      if (!_allDay)
                        FloraButton(
                          label: l10n.taskAllDay,
                          style: FloraButtonStyle.ghost,
                          size: FloraButtonSize.small,
                          onPressed: () => setState(() {
                            _allDay = true;
                            _dueAt = DateTime(_dueAt!.year, _dueAt!.month, _dueAt!.day);
                          }),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: Space.md),
          Text(l10n.taskRecurrence, style: context.text.caption),
          const SizedBox(height: Space.xs),
          Wrap(
            spacing: Space.xs,
            runSpacing: Space.xs,
            children: [
              FloraChip(label: l10n.taskRecurrenceNone, selected: _recUnit == null, onTap: () => setState(() => _recUnit = null)),
              for (final e in units.entries) FloraChip(label: e.value, selected: _recUnit == e.key, onTap: () => setState(() => _recUnit = e.key)),
            ],
          ),
          AnimatedSize(
            duration: Motion.of(context, Motion.standard),
            curve: Motion.easeOut,
            alignment: Alignment.topCenter,
            child: _recUnit == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: Space.sm),
                    child: FloraCard(
                      padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.xs),
                      child: Row(
                        children: [
                          Expanded(child: Text(l10n.recurrenceLabel(_recUnit!.key, _recValue), style: context.text.body)),
                          QuantityStepper(value: _recValue, min: 1, max: 999, label: l10n.taskEvery, onChanged: (v) => setState(() => _recValue = v)),
                        ],
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: Space.xl),
          FloraButton(label: widget.existing == null ? l10n.add : l10n.save, expand: true, loading: _saving, onPressed: _save),
          if (widget.existing != null) ...[
            const SizedBox(height: Space.xs),
            FloraButton(label: l10n.deleteTask, style: FloraButtonStyle.ghost, expand: true, onPressed: _delete),
          ],
        ],
      ),
    );
  }
}
