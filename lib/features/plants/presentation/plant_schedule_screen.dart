import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/config/app_config.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/care_labels.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/care/care_engine.dart';
import '../../../domain/care/care_guide.dart';
import '../../../domain/care/care_profile.dart';
import '../../../domain/care/care_suggestions.dart';
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
    final advice = _adviceFor(ref, plantId);
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
                            : '${l10n.everyDays(s.intervalDays)}${s.strategy == CareStrategy.fixed ? '' : ' · ${l10n.strategyName(s.strategy)}'} · ${l10n.dueLabel(s.nextDueAt, now)}',
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
            onPressed: () => _addRoutine(context, ref, schedules, advice),
          ),
        ],
      ),
    );
  }

  Future<void> _addRoutine(BuildContext context, WidgetRef ref, List<CareSchedule> existing, _Advice advice) async {
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
            onPressed: () => _createFor(context, t.key, advice),
          ),
        SheetAction(
          label: l10n.newActionType,
          icon: CupertinoIcons.plus,
          onPressed: () async {
            final created = await showNewActionTypeSheet(context);
            if (created != null && context.mounted) _createFor(context, created.key, advice);
          },
        ),
      ],
    );
  }

  void _createFor(BuildContext context, String typeKey, _Advice advice) {
    final now = DateTime.now();
    showScheduleEditSheet(
      context,
      schedule: CareSchedule(
        id: '',
        plantId: plantId,
        typeKey: typeKey,
        strategy: CareStrategy.fixed,
        intervalDays: advice.intervalFor(typeKey, now),
        enabled: true,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }
}

/// Ce que la fiche d'entretien de la plante conseille, prêt à préremplir une
/// nouvelle routine et à dire d'où sort le chiffre proposé. Sans fiche
/// parlante (type personnalisé, espèce inconnue), on retombe sur les
/// intervalles par défaut de l'application.
class _Advice {
  const _Advice({required this.care, this.light, this.south = false});

  /// Fiche retenue, avec sa provenance : « Fiche de l'espèce » et « Fiche du
  /// genre Ficus » ne se valent pas, et l'écran le dit.
  final ResolvedCare care;

  final LightNeed? light;

  /// Le jardin est dans l'hémisphère sud : l'arrosage conseillé suit ses
  /// saisons, pas celles du calendrier européen.
  final bool south;

  int intervalFor(String typeKey, DateTime now) =>
      _fromProfile(typeKey, now) ??
      (typeKey == CareKind.watering.key ? AppConfig.defaultWateringInterval : AppConfig.defaultFertilizingInterval);

  /// Le même intervalle, mais seulement quand il vient vraiment de la plante :
  /// un défaut d'application ne se présente pas comme un conseil tiré de
  /// l'espèce.
  int? suggestionFor(String typeKey, DateTime now) => care.match == CareMatch.generic ? null : _fromProfile(typeKey, now);

  int? _fromProfile(String typeKey, DateTime now) =>
      care.profile.suggestedIntervalDays(typeKey, now: now, actualLight: light, south: south);
}

/// Fiche d'entretien de la plante et lumière réelle de son emplacement : de
/// quoi conseiller un intervalle de départ, plutôt qu'un chiffre rond sorti de
/// nulle part, et dire ensuite d'où il sort.
_Advice _adviceFor(WidgetRef ref, String plantId) {
  final plant = ref.watch(plantSummaryProvider(plantId)).value?.plant;
  final care = ref.watch(careGuideProvider).resolve(plant?.speciesName, family: speciesFamilyLookup(ref)(plant?.speciesName));
  final location = plant?.locationId == null ? null : (ref.watch(locationsProvider).value ?? const <Location>[]).where((l) => l.id == plant!.locationId).firstOrNull;
  // La lumière dite sur la plante prime sur celle de son emplacement.
  return _Advice(care: care, light: plant?.light ?? lightNeedFromCode(location?.light), south: ref.watch(southernHemisphereProvider));
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

  /// Le rempotage se compte en mois, pas en jours : le pas et la borne haute
  /// suivent, sinon « tous les deux ans » serait hors d'atteinte au bouton.
  late final bool _monthly = widget.schedule.typeKey == CareKind.repotting.key;

  /// « Avec le temps de la semaine : 9 jours », ou ce qui manque pour le
  /// dire : un lieu, un bulletin. Hors ligne, rien — l'intervalle est alors
  /// exactement celui de la saison, que le stepper montre déjà.
  String? _weatherNote(AppLocalizations l10n) {
    if (ref.watch(preferencesProvider.select((p) => p.weatherPlace)) == null) return l10n.strategyWeatherNoPlace;
    final trend = ref.watch(weatherTrendProvider);
    if (trend == null) return null;
    final days = CareEngine.effectiveInterval(
      widget.schedule.copyWith(strategy: CareStrategy.weather, intervalDays: _interval),
      DateTime.now(),
      south: ref.watch(southernHemisphereProvider),
      trend: trend,
    );
    return l10n.strategyWeatherNow(l10n.daysCount(days));
  }

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
    final advice = _adviceFor(ref, widget.schedule.plantId);
    final isNew = widget.schedule.id.isEmpty;
    final hint = switch (_strategy) {
      CareStrategy.seasonal => l10n.strategySeasonalHint,
      CareStrategy.weather => l10n.strategyWeatherHint,
      CareStrategy.manual => l10n.strategyManualHint,
      // Ce que fait le mode, pas l'intervalle : le chiffre est déjà sous les
      // yeux, au stepper, et l'écrire deux fois le rend illisible.
      CareStrategy.fixed => l10n.strategyFixedHint,
    };
    // La stratégie météo dit ce qu'elle fait en ce moment : sans ce chiffre,
    // « resserré par la chaleur sèche » reste une promesse, et le stepper
    // affiche un intervalle qui n'est pas celui qui sera retenu.
    final weatherNote = _strategy != CareStrategy.weather ? null : _weatherNote(l10n);
    // D'où vient l'intervalle affiché : la fiche d'entretien de la plante.
    // Tant qu'il vaut ce qu'elle conseille, on le dit sans répéter le chiffre ;
    // une fois réglé à la main, la valeur conseillée reste lisible.
    final suggested = advice.suggestionFor(widget.schedule.typeKey, DateTime.now());
    final source = suggested == null
        ? null
        : '${suggested == _interval ? l10n.intervalSuggested : l10n.intervalSuggestedDays(suggested)} · ${l10n.careMatchLabel(advice.care)}';
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
          if (weatherNote != null) ...[
            const SizedBox(height: 2),
            Text(weatherNote, style: context.text.caption.copyWith(color: context.colors.water), textAlign: TextAlign.center),
          ],
          const SizedBox(height: Space.lg),
          AnimatedOpacity(
            duration: Motion.of(context, Motion.standard),
            opacity: _strategy == CareStrategy.manual ? 0.35 : 1,
            child: IgnorePointer(
              ignoring: _strategy == CareStrategy.manual,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FloraGroup(
                    children: [
                      FloraListRow(
                        title: l10n.interval,
                        trailing: QuantityStepper(
                          value: _interval,
                          min: _monthly ? 30 : 1,
                          max: _monthly ? 1825 : 365,
                          step: _monthly ? 30 : 1,
                          label: l10n.daysCount(_interval),
                          onChanged: (v) => setState(() => _interval = v),
                        ),
                      ),
                      FloraListRow(title: l10n.enabled, trailing: AdaptiveSwitch(value: _enabled, onChanged: (v) => setState(() => _enabled = v))),
                    ],
                  ),
                  if (source != null) ...[
                    const SizedBox(height: Space.xs),
                    Text(source, style: context.text.caption, textAlign: TextAlign.center),
                  ],
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
