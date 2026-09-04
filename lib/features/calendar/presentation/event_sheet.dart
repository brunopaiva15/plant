import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/utils/dates.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models/models.dart';
import '../../../domain/repositories/repositories.dart';
import '../../plants/application/plant_providers.dart';
import '../../plants/presentation/plant_picker_sheet.dart';
import '../../today/application/reminder_scheduler.dart';
import 'event_categories_sheet.dart';

/// Rappels proposés, en minutes avant le début.
const _reminderChoices = <int?>[null, 0, 15, 60, 60 * 24];

/// Création / édition d'un événement du calendrier.
Future<void> showEventSheet(BuildContext context, {CalendarEntry? existing, DateTime? day, String? plantId}) =>
    showFloraSheet<void>(context, scrollable: true, builder: (_) => _EventBody(existing: existing, day: day, initialPlantId: plantId));

class _EventBody extends ConsumerStatefulWidget {
  const _EventBody({this.existing, this.day, this.initialPlantId});

  final CalendarEntry? existing;
  final DateTime? day;
  final String? initialPlantId;

  @override
  ConsumerState<_EventBody> createState() => _EventBodyState();
}

class _EventBodyState extends ConsumerState<_EventBody> {
  late final _title = TextEditingController(text: widget.existing?.title ?? '');
  late final _notes = TextEditingController(text: widget.existing?.notes ?? '');
  late DateTime _startAt = widget.existing?.startAt ?? (widget.day ?? DateTime.now()).dateOnly;
  late DateTime? _endAt = widget.existing?.endAt;
  late bool _allDay = widget.existing?.allDay ?? true;
  late String? _plantId = widget.existing?.plantId ?? widget.initialPlantId;
  late String? _categoryId = widget.existing?.categoryId;
  late int? _reminder = widget.existing?.reminderMinutes;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty || _saving) return;
    setState(() => _saving = true);
    final repo = ref.read(calendarRepositoryProvider);
    if (widget.existing == null) {
      await repo.create(NewCalendarEntry(
        title: _title.text,
        notes: _notes.text,
        startAt: _startAt,
        endAt: _endAt,
        allDay: _allDay,
        plantId: _plantId,
        categoryId: _categoryId,
        reminderMinutes: _reminder,
      ));
    } else {
      await repo.update(widget.existing!.copyWith(
        title: _title.text,
        notes: () => _notes.text,
        startAt: _startAt,
        endAt: () => _endAt,
        allDay: _allDay,
        plantId: () => _plantId,
        categoryId: () => _categoryId,
        reminderMinutes: () => _reminder,
      ));
    }
    await ref.read(reminderSchedulerProvider).reschedule();
    Haptics.success();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    final ok = await showAdaptiveConfirm(context, title: l10n.deleteEvent, confirmLabel: l10n.delete, cancelLabel: l10n.cancel, destructive: true);
    if (!ok) return;
    await ref.read(calendarRepositoryProvider).delete(widget.existing!.id);
    await ref.read(reminderSchedulerProvider).reschedule();
    Haptics.warning();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _pickStartDate() async {
    final l10n = context.l10n;
    final picked = await showAdaptiveDatePicker(context, initial: _startAt, first: DateTime(_startAt.year - 5), doneLabel: l10n.done);
    if (picked == null) return;
    setState(() {
      _startAt = DateTime(picked.year, picked.month, picked.day, _allDay ? 0 : _startAt.hour, _allDay ? 0 : _startAt.minute);
      // Une fin devenue antérieure au début n'aurait plus de sens.
      if (_endAt != null && _endAt!.isBefore(_startAt)) _endAt = null;
    });
  }

  Future<void> _pickTime() async {
    final l10n = context.l10n;
    final picked = await showAdaptiveTimePicker(context, initial: TimeOfDay(hour: _allDay ? 9 : _startAt.hour, minute: _allDay ? 0 : _startAt.minute), doneLabel: l10n.done);
    if (picked == null) return;
    setState(() {
      _allDay = false;
      _startAt = DateTime(_startAt.year, _startAt.month, _startAt.day, picked.hour, picked.minute);
    });
  }

  Future<void> _pickEndDate() async {
    final l10n = context.l10n;
    final picked = await showAdaptiveDatePicker(context, initial: _endAt ?? _startAt, first: _startAt, doneLabel: l10n.done);
    if (picked == null) return;
    final end = DateTime(picked.year, picked.month, picked.day);
    setState(() => _endAt = end.isAfter(_startAt.dateOnly) ? end : null);
  }

  String _reminderLabel(AppLocalizations l10n, int? minutes) => switch (minutes) {
        null => l10n.eventNoReminder,
        0 => l10n.eventReminderAtStart,
        final m when m % (60 * 24) == 0 => l10n.eventReminderDays(m ~/ (60 * 24)),
        final m when m % 60 == 0 => l10n.eventReminderHours(m ~/ 60),
        final m => l10n.eventReminderMinutes(m),
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final accent = context.text.callout.copyWith(color: c.sage, fontWeight: FontWeight.w600);
    final categories = ref.watch(eventCategoriesProvider).value ?? const <EventCategory>[];
    final plant = _plantId == null ? null : ref.watch(plantSummaryProvider(_plantId!)).value;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(title: widget.existing == null ? l10n.newEvent : l10n.editEvent),
          FloraTextField(controller: _title, hint: l10n.eventTitleHint, autofocus: widget.existing == null, textCapitalization: TextCapitalization.sentences),
          const SizedBox(height: Space.xs),
          FloraTextField(controller: _notes, hint: l10n.eventNotesHint, minLines: 1, maxLines: 4),
          const SizedBox(height: Space.md),
          FloraGroup(
            children: [
              FloraListRow(
                leading: const Text('📅', style: TextStyle(fontSize: 18)),
                title: l10n.eventStart,
                trailing: Text(Dates.relativeDay(context, _startAt), style: accent),
                chevron: false,
                onTap: _pickStartDate,
              ),
              FloraListRow(
                leading: const Text('🕘', style: TextStyle(fontSize: 18)),
                title: l10n.eventAllDay,
                trailing: Text(_allDay ? l10n.eventAllDay : Dates.time(context, _startAt), style: accent),
                chevron: false,
                onTap: _allDay
                    ? _pickTime
                    : () => setState(() {
                          _allDay = true;
                          _startAt = _startAt.dateOnly;
                        }),
              ),
              FloraListRow(
                leading: const Text('🏁', style: TextStyle(fontSize: 18)),
                title: l10n.eventEnd,
                trailing: Text(_endAt == null ? l10n.eventNoEnd : Dates.relativeDay(context, _endAt!), style: accent),
                chevron: false,
                onTap: _pickEndDate,
              ),
              FloraListRow(
                leading: const Text('🔔', style: TextStyle(fontSize: 18)),
                title: l10n.eventReminder,
                trailing: Text(_reminderLabel(l10n, _reminder), style: accent),
                chevron: false,
                onTap: () async {
                  await showAdaptiveActionSheet(
                    context,
                    title: l10n.eventReminder,
                    actions: [
                      for (final choice in _reminderChoices)
                        SheetAction(label: _reminderLabel(l10n, choice), onPressed: () => setState(() => _reminder = choice)),
                    ],
                    cancelLabel: l10n.cancel,
                  );
                },
              ),
              FloraListRow(
                leading: const Text('🪴', style: TextStyle(fontSize: 18)),
                title: l10n.eventPlant,
                trailing: Text(plant?.plant.name ?? l10n.eventNoPlant, style: accent, maxLines: 1, overflow: TextOverflow.ellipsis),
                chevron: false,
                onTap: () async {
                  final choice = await showPlantPicker(context, selectedId: _plantId);
                  if (choice != null) setState(() => _plantId = choice.id);
                },
              ),
            ],
          ),
          const SizedBox(height: Space.md),
          Text(l10n.eventCategory, style: context.text.caption),
          const SizedBox(height: Space.xs),
          Wrap(
            spacing: Space.xs,
            runSpacing: Space.xs,
            children: [
              FloraChip(label: l10n.eventNoCategory, selected: _categoryId == null, onTap: () => setState(() => _categoryId = null)),
              for (final cat in categories)
                FloraChip(emoji: cat.emoji, label: cat.label, selected: _categoryId == cat.id, onTap: () => setState(() => _categoryId = cat.id)),
              FloraChip(label: l10n.newEventCategory, dashed: true, onTap: () => showEventCategoriesSheet(context)),
            ],
          ),
          const SizedBox(height: Space.xl),
          FloraButton(label: widget.existing == null ? l10n.add : l10n.save, expand: true, loading: _saving, onPressed: _save),
          if (widget.existing != null) ...[
            const SizedBox(height: Space.xs),
            FloraButton(label: l10n.deleteEvent, style: FloraButtonStyle.ghost, expand: true, onPressed: _delete),
          ],
        ],
      ),
    );
  }
}
