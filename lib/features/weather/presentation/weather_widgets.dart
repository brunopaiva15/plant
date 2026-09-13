import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/weather/weather.dart';
import '../../today/application/reminder_scheduler.dart';
import '../../today/presentation/today_notice.dart';
import '../application/weather_providers.dart';

/// « ☁️ 22° · Nuageux · 38 % de pluie › » : la pilule du temps qu'il fait,
/// sous la date de l'écran Aujourd'hui. Mène aux prévisions.
class WeatherPill extends ConsumerWidget {
  const WeatherPill({super.key, required this.weather});

  final DailyWeather weather;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final metric = ref.watch(preferencesProvider.select((p) => p.metricUnits));
    final temp = metric ? '${weather.temperatureNow.round()}°' : '${(weather.temperatureNow * 9 / 5 + 32).round()}°F';
    final parts = [temp, l10n.conditionName(weather.condition), if (weather.precipitationProbability >= 30) l10n.rainChance(weather.precipitationProbability)].where((s) => s.isNotEmpty);
    return FloraPill(emoji: weatherEmoji(weather.condition), label: parts.join(' · '), chevron: true, onTap: () => context.push(Routes.forecast));
  }
}

/// Emoji du temps, partagé par la ligne du jour et l'écran de prévisions.
String weatherEmoji(WeatherCondition c) => switch (c) {
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

/// « Pluie aujourd'hui · L'arrosage de Balcon peut attendre. » [Reporter] [×]
class WeatherAdviceCard extends ConsumerWidget {
  const WeatherAdviceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final advice = ref.watch(weatherAdviceProvider);
    final dismissed = ref.watch(dismissedAdviceProvider.notifier).isDismissedToday;
    ref.watch(dismissedAdviceProvider);
    final show = advice != null && !dismissed;
    return TodayNoticeSlot(
      visible: show,
      child: !show
          ? const SizedBox.shrink()
          : TodayNotice(
              emoji: '🌧️',
              color: context.colors.waterSoft,
              title: l10n.weatherRainTitle,
              body: l10n.weatherRainSkip(l10n.joinNames(advice.locationNames)),
              onDismiss: () => ref.read(dismissedAdviceProvider.notifier).dismissToday(),
              actions: [
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
              ],
            ),
    );
  }
}
