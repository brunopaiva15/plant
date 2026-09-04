import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models/models.dart';
import '../../actions/presentation/action_type_sheet.dart';
import '../../today/application/reminder_scheduler.dart';
import '../application/plant_providers.dart';

/// Planning d'entretien : une ligne par routine, édition en sheet.
class PlantScheduleScreen extends ConsumerWidget {
  const PlantScheduleScreen({super.key, required this.plantId});

  final String plantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final schedules = ref.watch(plantSchedulesProvider(plantId)).value ?? const <CareSchedule>[];
    final types = ref.watch(actionTypeByKeyProvider);
    final now = DateTime.now();
    return FloraPage(
      title: l10n.schedule,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (schedules.isEmpty)
            EmptyState(emoji: '⏰', title: l10n.noSchedule, compact: true)
          else
            FloraGroup(
              children: [
                for (final s in schedules)
                  FloraListRow(
                    leading: Text(types[s.typeKey]?.emoji ?? '✓', style: const TextStyle(fontSize: 20)),
                    title: l10n.kindName(s.typeKey, custom: types[s.typeKey]),
                    subtitle: !s.enabled
                        ? l10n.strategyManualHint
                        : s.strategy == CareStrategy.manual
                            ? l10n.strategyManual
                            : '${l10n.everyDays(s.intervalDays)}${s.strategy == CareStrategy.seasonal ? ' · ${l10n.strategySeasonal}' : ''} · ${l10n.dueLabel(s.nextDueAt, now)}',
                    trailing: Opacity(
                      opacity: s.enabled ? 1 : 0.4,
                      child: Icon(CupertinoIcons.chevron_right, size: 16, color: c.inkTertiary),
                    ),
                    chevron: false,
                    onTap: () => showScheduleEditSheet(context, schedule: s),
                  ),
              ],
            ),
          const SizedBox(height: Space.md),
          FloraButton(
            label: l10n.addRoutine,
            icon: CupertinoIcons.plus,
            style: FloraButtonStyle.tonal,
            onPressed: () => _addRoutine(context, ref, schedules),
          ),
        ],
      ),
    );
  }

  Future<void> _addRoutine(BuildContext context, WidgetRef ref, List<CareSchedule> existing) async {
    final l10n = context.l10n;
    final types = (ref.read(actionTypesProvider).value ?? const <ActionType>[])
        .where((t) => t.schedulable && !existing.any((s) => s.typeKey == t.key))
        .toList();
    await showAdaptiveActionSheet(
      context,
      title: l10n.addRoutine,
      cancelLabel: l10n.cancel,
      actions: [
        for (final t in types)
          SheetAction(
            label: '${t.emoji}  ${l10n.kindName(t.key, custom: t)}',
            onPressed: () => _createFor(context, t.key),
          ),
        SheetAction(
          label: l10n.newActionType,
          icon: CupertinoIcons.plus,
          onPressed: () async {
            final created = await showNewActionTypeSheet(context);
            if (created != null && context.mounted) _createFor(context, created.key);
          },
        ),
      ],
    );
  }

  void _createFor(BuildContext context, String typeKey) {
    final now = DateTime.now();
    showScheduleEditSheet(
      context,
      schedule: CareSchedule(
        id: '',
        plantId: plantId,
        typeKey: typeKey,
        strategy: CareStrategy.fixed,
        intervalDays: typeKey == CareKind.watering.key ? 7 : 30,
        enabled: true,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }
}

Future<void> showScheduleEditSheet(BuildContext context, {required CareSchedule schedule}) =>
    showFloraSheet<void>(context, scrollable: true, builder: (_) => _ScheduleEditBody(schedule: schedule));

class _ScheduleEditBody extends ConsumerStatefulWidget {
  const _ScheduleEditBody({required this.schedule});

  final CareSchedule schedule;

  @override
  ConsumerState<_ScheduleEditBody> createState() => _ScheduleEditBodyState();
}

class _ScheduleEditBodyState extends ConsumerState<_ScheduleEditBody> {
  late CareStrategy _strategy = widget.schedule.strategy;
  late int _interval = widget.schedule.intervalDays;
  late bool _enabled = widget.schedule.enabled;
  bool _saving = false;

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    await ref.read(careRepositoryProvider).upsert(widget.schedule.copyWith(strategy: _strategy, intervalDays: _interval, enabled: _enabled));
    await ref.read(reminderSchedulerProvider).reschedule();
    Haptics.success();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    final ok = await showAdaptiveConfirm(context, title: l10n.deleteRoutine, confirmLabel: l10n.delete, cancelLabel: l10n.cancel, destructive: true);
    if (!ok) return;
    await ref.read(careRepositoryProvider).delete(widget.schedule.id);
    await ref.read(reminderSchedulerProvider).reschedule();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final type = ref.watch(actionTypeByKeyProvider)[widget.schedule.typeKey];
    final isNew = widget.schedule.id.isEmpty;
    final hint = switch (_strategy) {
      CareStrategy.seasonal => l10n.strategySeasonalHint,
      CareStrategy.manual => l10n.strategyManualHint,
      CareStrategy.fixed => l10n.everyDays(_interval),
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(title: '${type?.emoji ?? ''}  ${l10n.kindName(widget.schedule.typeKey, custom: type)}'),
          AdaptiveSegmented<CareStrategy>(
            segments: {for (final s in CareStrategy.values) s: l10n.strategyName(s)},
            value: _strategy,
            onChanged: (v) => setState(() => _strategy = v),
          ),
          const SizedBox(height: Space.xs),
          Text(hint, style: context.text.caption, textAlign: TextAlign.center),
          const SizedBox(height: Space.lg),
          AnimatedOpacity(
            duration: Motion.of(context, Motion.standard),
            opacity: _strategy == CareStrategy.manual ? 0.35 : 1,
            child: IgnorePointer(
              ignoring: _strategy == CareStrategy.manual,
              child: FloraGroup(
                children: [
                  FloraListRow(
                    title: l10n.interval,
                    trailing: QuantityStepper(value: _interval, min: 1, max: 365, label: l10n.daysCount(_interval), onChanged: (v) => setState(() => _interval = v)),
                  ),
                  FloraListRow(title: l10n.enabled, trailing: AdaptiveSwitch(value: _enabled, onChanged: (v) => setState(() => _enabled = v))),
                ],
              ),
            ),
          ),
          if (!isNew && widget.schedule.lastCompletedAt != null) ...[
            const SizedBox(height: Space.sm),
            Text(l10n.lastDone(Dates.dayYear(context, widget.schedule.lastCompletedAt!)), style: context.text.caption, textAlign: TextAlign.center),
          ],
          const SizedBox(height: Space.xl),
          FloraButton(label: l10n.save, expand: true, loading: _saving, onPressed: _save),
          if (!isNew) ...[
            const SizedBox(height: Space.xs),
            FloraButton(label: l10n.deleteRoutine, style: FloraButtonStyle.ghost, expand: true, onPressed: _delete),
          ],
        ],
      ),
    );
  }
}
