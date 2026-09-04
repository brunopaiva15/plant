import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/utils/dates.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/care/calendar_projector.dart';
import '../../../domain/models/models.dart';
import '../../../domain/repositories/repositories.dart';

enum CalendarMode { agenda, month }

class CalendarModeController extends Notifier<CalendarMode> {
  @override
  CalendarMode build() => CalendarMode.agenda;
  void set(CalendarMode m) => state = m;
}

final calendarModeProvider = NotifierProvider<CalendarModeController, CalendarMode>(CalendarModeController.new);

class VisibleMonthController extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  void shift(int months) => state = DateTime(state.year, state.month + months);
}

final visibleMonthProvider = NotifierProvider<VisibleMonthController, DateTime>(VisibleMonthController.new);

class SelectedDayController extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime.now().dateOnly;
  void set(DateTime d) => state = d.dateOnly;
}

final selectedDayProvider = NotifierProvider<SelectedDayController, DateTime>(SelectedDayController.new);

/// Événements (passés + projetés) sur une plage.
final calendarEventsProvider = StreamProvider.autoDispose.family<List<CalendarEvent>, ({DateTime from, DateTime to})>((ref, range) async* {
  final schedules = ref.watch(careRepositoryProvider).watchAllEnabled();
  final actions = ref.watch(actionRepositoryProvider).watchBetween(range.from, range.to);
  final plants = ref.watch(plantRepositoryProvider).watchSummaries(const PlantFilter());
  List<CareSchedule>? s;
  List<PlantAction>? a;
  List<PlantSummary>? p;
  final controller = StreamController<List<CalendarEvent>>();
  void emit() {
    if (s == null || a == null || p == null) return;
    controller.add(CalendarProjector.project(schedules: s!, actions: a!, plants: {for (final x in p!) x.plant.id: x}, from: range.from, to: range.to));
  }

  final subs = [
    schedules.listen((v) {
      s = v;
      emit();
    }),
    actions.listen((v) {
      a = v;
      emit();
    }),
    plants.listen((v) {
      p = v;
      emit();
    }),
  ];
  ref.onDispose(() {
    for (final sub in subs) {
      sub.cancel();
    }
    controller.close();
  });
  yield* controller.stream;
});

/// Calendrier : agenda en priorité, vue mois optionnelle.
class CalendarSlivers extends ConsumerWidget {
  const CalendarSlivers({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final mode = ref.watch(calendarModeProvider);
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.md),
            child: AdaptiveSegmented<CalendarMode>(
              segments: {CalendarMode.agenda: l10n.agenda, CalendarMode.month: l10n.month},
              value: mode,
              onChanged: (m) => ref.read(calendarModeProvider.notifier).set(m),
            ),
          ),
        ),
        if (mode == CalendarMode.agenda) const _Agenda() else const _MonthView(),
      ],
    );
  }
}

class _Agenda extends ConsumerWidget {
  const _Agenda();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final today = DateTime.now().dateOnly;
    final range = (from: today, to: today.addDays(30));
    final events = ref.watch(calendarEventsProvider(range));
    final days = CalendarProjector.byDay(events.value ?? const []);
    if (events.hasValue && days.isEmpty) {
      return SliverFillRemaining(hasScrollBody: false, child: Center(child: EmptyState(emoji: '🗓️', title: l10n.noEventsTitle, subtitle: l10n.noEventsSubtitle, compact: true)));
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: Space.page),
      sliver: SliverList.list(
        children: [
          for (final entry in days.entries) ...[
            _DayHeader(date: entry.key),
            FloraGroup(children: [for (final e in entry.value) _EventRow(event: e)]),
            const SizedBox(height: Space.lg),
          ],
        ],
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isToday = date.isSameDay(DateTime.now());
    return Padding(
      padding: const EdgeInsets.only(left: Space.xxs, bottom: Space.xs),
      child: Row(
        children: [
          Flexible(child: Text(isToday ? l10n.today : Dates.longDate(context, date), style: context.text.title3, maxLines: 1, overflow: TextOverflow.ellipsis)),
          if (isToday) ...[const SizedBox(width: Space.xs), Container(width: 6, height: 6, decoration: BoxDecoration(color: context.colors.sage, shape: BoxShape.circle))],
        ],
      ),
    );
  }
}

class _EventRow extends ConsumerWidget {
  const _EventRow({required this.event});

  final CalendarEvent event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final types = ref.watch(actionTypeByKeyProvider);
    final custom = types[event.typeKey];
    final label = switch (event.kind) {
      CalendarEventKind.past => '${l10n.kindDone(event.typeKey, custom: custom)} · ${Dates.time(context, event.date)}',
      CalendarEventKind.due => l10n.kindName(event.typeKey, custom: custom),
      CalendarEventKind.projected => '${l10n.kindName(event.typeKey, custom: custom)} · ${l10n.projected}',
    };
    return FloraListRow(
      leading: ClipRRect(borderRadius: BorderRadius.circular(10), child: SizedBox(width: 32, height: 32, child: PlantImage(relativePath: event.thumbPath, cacheWidth: 96))),
      title: event.plantName,
      subtitle: label,
      trailing: Text(custom?.emoji ?? CareKind.fromKey(event.typeKey)?.emoji ?? '✓', style: TextStyle(fontSize: 18, color: event.kind == CalendarEventKind.projected ? c.inkTertiary : null)),
      chevron: false,
      dense: true,
      onTap: () => context.push(Routes.plant(event.plantId)),
    );
  }
}

class _MonthView extends ConsumerWidget {
  const _MonthView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final month = ref.watch(visibleMonthProvider);
    final selected = ref.watch(selectedDayProvider);
    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month + 1, 0);
    final events = ref.watch(calendarEventsProvider((from: first, to: last)));
    final days = CalendarProjector.byDay(events.value ?? const []);
    final leading = (first.weekday - 1) % 7;
    final cells = leading + last.day;
    final rows = (cells / 7).ceil();
    final selectedEvents = days[selected] ?? const <CalendarEvent>[];
    final weekdayLabels = [for (var d = 1; d <= 7; d++) Dates.weekdayShort(context, DateTime(2026, 9, 6 + d)).replaceAll('.', '')];

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: Space.page),
      sliver: SliverList.list(
        children: [
          FloraCard(
            child: Column(
              children: [
                Row(
                  children: [
                    FloraIconButton(icon: CupertinoIcons.chevron_left, semanticLabel: l10n.back, onPressed: () => ref.read(visibleMonthProvider.notifier).shift(-1), filled: false),
                    Expanded(child: Text(_capitalize(Dates.monthYear(context, month)), style: context.text.title3, textAlign: TextAlign.center)),
                    FloraIconButton(icon: CupertinoIcons.chevron_right, semanticLabel: l10n.next, onPressed: () => ref.read(visibleMonthProvider.notifier).shift(1), filled: false),
                  ],
                ),
                const SizedBox(height: Space.xs),
                Row(children: [for (final w in weekdayLabels) Expanded(child: Text(w, style: context.text.caption, textAlign: TextAlign.center))]),
                const SizedBox(height: Space.xs),
                for (var r = 0; r < rows; r++)
                  Row(
                    children: [
                      for (var col = 0; col < 7; col++)
                        Expanded(
                          child: Builder(builder: (context) {
                            final index = r * 7 + col - leading;
                            if (index < 0 || index >= last.day) return const SizedBox(height: 44);
                            final date = DateTime(month.year, month.month, index + 1);
                            final dayEvents = days[date] ?? const <CalendarEvent>[];
                            final isSelected = date == selected;
                            final isToday = date.isSameDay(DateTime.now());
                            return Pressable(
                              onTap: () => ref.read(selectedDayProvider.notifier).set(date),
                              scale: 0.9,
                              child: Container(
                                height: 44,
                                margin: const EdgeInsets.all(2),
                                decoration: BoxDecoration(color: isSelected ? c.sage : Colors.transparent, borderRadius: Radii.mediumAll),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${index + 1}',
                                      style: context.text.callout.copyWith(color: isSelected ? c.onSage : c.ink, fontWeight: isToday || isSelected ? FontWeight.w700 : FontWeight.w400),
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        for (final e in dayEvents.take(3))
                                          Container(
                                            width: 5,
                                            height: 5,
                                            margin: const EdgeInsets.symmetric(horizontal: 1),
                                            decoration: BoxDecoration(color: isSelected ? c.onSage : c.strongFor(e.typeKey), shape: BoxShape.circle),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: Space.lg),
          _DayHeader(date: selected),
          if (selectedEvents.isEmpty)
            Padding(padding: const EdgeInsets.only(left: Space.xxs), child: Text(l10n.noEventsTitle, style: context.text.callout))
          else
            FloraGroup(children: [for (final e in selectedEvents) _EventRow(event: e)]),
        ],
      ),
    );
  }

  static String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
