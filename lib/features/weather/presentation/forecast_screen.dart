import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/weather/weather.dart';
import '../application/weather_providers.dart';
import 'weather_widgets.dart' show weatherEmoji;

/// Prévisions sur cinq jours : ce qu'il faut savoir avant d'arroser dehors.
class ForecastScreen extends ConsumerWidget {
  const ForecastScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final place = ref.watch(preferencesProvider).weatherPlace;
    final forecast = ref.watch(forecastProvider);

    if (place == null) {
      return FloraPage(
        title: l10n.weatherForecastTitle,
        child: Padding(
          padding: const EdgeInsets.only(top: Space.huge),
          child: EmptyState(
            emoji: '🌤️',
            title: l10n.weather,
            subtitle: l10n.weatherNoPlace,
            actionLabel: l10n.weather,
            onAction: () => context.push(Routes.weather),
            compact: true,
          ),
        ),
      );
    }

    return FloraPage(
      title: l10n.weatherForecastTitle,
      child: switch (forecast) {
        AsyncData(:final value) when value.isNotEmpty => _Forecast(days: value, placeName: place.name),
        AsyncError() => Padding(
            padding: const EdgeInsets.only(top: Space.huge),
            child: Text(l10n.weatherFailed, style: context.text.callout, textAlign: TextAlign.center),
          ),
        _ => const Padding(padding: EdgeInsets.only(top: Space.huge), child: Center(child: AdaptiveProgress())),
      },
    );
  }
}

class _Forecast extends ConsumerWidget {
  const _Forecast({required this.days, required this.placeName});

  final List<DailyWeather> days;
  final String placeName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final metric = ref.watch(preferencesProvider).metricUnits;
    final today = days.first;

    String temp(double celsius) => metric ? '${celsius.round()}°' : '${(celsius * 9 / 5 + 32).round()}°F';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FloraCard(
          padding: const EdgeInsets.all(Space.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(placeName, style: context.text.caption.copyWith(color: c.inkSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: Space.xs),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(weatherEmoji(today.condition), style: const TextStyle(fontSize: 40)),
                  const SizedBox(width: Space.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(temp(today.temperatureNow), style: context.text.display),
                        Text(l10n.conditionName(today.condition), style: context.text.callout.copyWith(color: c.inkSecondary)),
                      ],
                    ),
                  ),
                  Text('${temp(today.temperatureMax)} / ${temp(today.temperatureMin)}', style: context.text.callout.copyWith(color: c.inkSecondary)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: Space.md),
        FloraGroup(
          children: [
            _DetailRow(emoji: '🌧️', label: l10n.weatherPrecipitation, value: '${today.precipitationMm.toStringAsFixed(1)} mm'),
            _DetailRow(emoji: '☔', label: l10n.weatherRainChance, value: '${today.precipitationProbability} %'),
            if (today.windKph > 0) _DetailRow(emoji: '💨', label: l10n.weatherWind, value: '${today.windKph.round()} km/h'),
            if (today.humidity > 0) _DetailRow(emoji: '💧', label: l10n.weatherHumidity, value: '${today.humidity} %'),
          ],
        ),
        const SizedBox(height: Space.lg),
        SectionHeader(title: l10n.weatherForecastTitle, padding: const EdgeInsets.only(bottom: Space.sm)),
        FloraGroup(
          children: [
            for (final (i, day) in days.indexed)
              FloraListRow(
                leading: Text(weatherEmoji(day.condition), style: const TextStyle(fontSize: 20)),
                title: i == 0 ? l10n.weatherToday : _weekday(context, day.date),
                subtitle: [
                  l10n.conditionName(day.condition),
                  if (day.precipitationProbability >= 20) l10n.rainChance(day.precipitationProbability),
                ].where((s) => s.isNotEmpty).join(' · '),
                trailing: Text(
                  '${temp(day.temperatureMax)}  ${temp(day.temperatureMin)}',
                  style: context.text.callout.copyWith(color: c.inkSecondary),
                ),
                chevron: false,
                dense: true,
              ),
          ],
        ),
      ],
    );
  }

  /// « Lundi 8 » : le jour de la semaine suffit sur cinq jours.
  static String _weekday(BuildContext context, DateTime date) {
    final label = Dates.weekdayShort(context, date).replaceAll('.', '');
    final capitalized = label.isEmpty ? label : label[0].toUpperCase() + label.substring(1);
    return '$capitalized ${date.day}';
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.emoji, required this.label, required this.value});

  final String emoji;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return FloraListRow(
      leading: Text(emoji, style: const TextStyle(fontSize: 18)),
      title: label,
      trailing: Text(value, style: context.text.callout.copyWith(fontWeight: FontWeight.w600)),
      chevron: false,
      dense: true,
    );
  }
}
