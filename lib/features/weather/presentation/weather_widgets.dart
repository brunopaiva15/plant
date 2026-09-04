import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/weather/weather.dart';
import '../../today/application/reminder_scheduler.dart';
import '../application/weather_providers.dart';

/// Ligne discrète « 22° · Pluie · 80 % de pluie » sous la date de l'écran Aujourd'hui.
class WeatherLine extends ConsumerWidget {
  const WeatherLine({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final weather = ref.watch(todayWeatherProvider).value;
    final hasOutdoor = ref.watch(outdoorLocationIdsProvider).isNotEmpty;
    if (weather == null || !hasOutdoor) return const SizedBox.shrink();
    final metric = ref.watch(preferencesProvider).metricUnits;
    final temp = metric ? '${weather.temperatureNow.round()}°' : '${(weather.temperatureNow * 9 / 5 + 32).round()}°F';
    final parts = [temp, l10n.conditionName(weather.condition), if (weather.precipitationProbability >= 30) l10n.rainChance(weather.precipitationProbability)].where((s) => s.isNotEmpty);
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Text(_emoji(weather.condition), style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          Flexible(child: Text(parts.join(' · '), style: context.text.caption, maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  static String _emoji(WeatherCondition c) => switch (c) {
        WeatherCondition.clear => '☀️',
        WeatherCondition.partlyCloudy => '🌤️',
        WeatherCondition.cloudy => '☁️',
        WeatherCondition.fog => '🌫️',
        WeatherCondition.drizzle => '🌦️',
        WeatherCondition.rain => '🌧️',
        WeatherCondition.snow => '🌨️',
        WeatherCondition.thunderstorm => '⛈️',
        WeatherCondition.unknown => '🌡️',
      };
}

/// « Pluie prévue : pas besoin d'arroser Balcon aujourd'hui. » [Reporter]
class WeatherAdviceCard extends ConsumerWidget {
  const WeatherAdviceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final advice = ref.watch(weatherAdviceProvider);
    final dismissed = ref.watch(dismissedAdviceProvider.notifier).isDismissedToday;
    ref.watch(dismissedAdviceProvider);
    final show = advice != null && !dismissed;
    return AnimatedSize(
      duration: Motion.of(context, Motion.emphasis),
      curve: Motion.emphasized,
      child: !show
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.fromLTRB(Space.page, Space.md, Space.page, 0),
              child: FloraCard(
                color: c.waterSoft,
                padding: const EdgeInsets.all(Space.md),
                child: Row(
                  children: [
                    const Text('🌧️', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: Space.sm),
                    Expanded(child: Text(l10n.weatherRainSkip(l10n.joinNames(advice.locationNames)), style: context.text.callout.copyWith(color: c.ink))),
                    const SizedBox(width: Space.xs),
                    FloraButton(
                      label: l10n.postpone,
                      size: FloraButtonSize.small,
                      onPressed: () async {
                        final care = ref.read(careRepositoryProvider);
                        final now = DateTime.now();
                        for (final t in advice.skipWateringTasks) {
                          await care.snooze(t.schedule.id, now);
                        }
                        Haptics.success();
                        ref.read(dismissedAdviceProvider.notifier).dismissToday();
                        ref.read(toastProvider.notifier).show(ToastData(message: l10n.postponedCount(advice.skipWateringTasks.length), emoji: '🌧️'));
                        await ref.read(reminderSchedulerProvider).reschedule();
                      },
                    ),
                    FloraIconButton(icon: CupertinoIcons.xmark, semanticLabel: l10n.close, filled: false, size: 32, onPressed: () => ref.read(dismissedAdviceProvider.notifier).dismissToday()),
                  ],
                ),
              ),
            ),
    );
  }
}
