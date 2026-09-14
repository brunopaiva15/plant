import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/weather/weather.dart';
import '../application/weather_providers.dart';
import 'weather_widgets.dart' show weatherTemp;

/// Choix du lieu météo (recherche de ville Open-Meteo).
class WeatherSettingsScreen extends ConsumerStatefulWidget {
  const WeatherSettingsScreen({super.key});

  @override
  ConsumerState<WeatherSettingsScreen> createState() => _WeatherSettingsScreenState();
}

class _WeatherSettingsScreenState extends ConsumerState<WeatherSettingsScreen> {
  final _query = TextEditingController();
  Timer? _debounce;
  List<WeatherPlace> _results = const [];
  bool _searching = false;
  bool _searched = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(q));
  }

  Future<void> _search(String q) async {
    if (q.trim().length < 2) {
      setState(() => _results = const []);
      return;
    }
    setState(() => _searching = true);
    final lang = ref.read(preferencesProvider).locale?.languageCode ?? WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    List<WeatherPlace> results = const [];
    try {
      results = await ref.read(weatherServiceProvider).searchPlaces(q, language: lang);
    } catch (_) {}
    if (mounted) {
      setState(() {
        _results = results;
        _searching = false;
        _searched = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final place = ref.watch(preferencesProvider).weatherPlace;
    return FloraPage(
      title: l10n.weather,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.weatherHint, style: context.text.callout),
          const SizedBox(height: Space.lg),
          FloraGroup(
            header: l10n.weatherPlace,
            children: [
              FloraListRow(
                leading: Text(place == null ? '📍' : '🌤️', style: const TextStyle(fontSize: 18)),
                title: place?.name ?? l10n.weatherNone,
                trailing: place == null
                    ? null
                    : FloraIconButton(
                        icon: CupertinoIcons.xmark_circle_fill,
                        semanticLabel: l10n.weatherRemove,
                        filled: false,
                        color: c.inkTertiary,
                        onPressed: () => ref.read(preferencesProvider.notifier).setWeatherPlace(null),
                      ),
                chevron: false,
              ),
              if (place != null)
                FloraListRow(
                  leading: const Text('📅', style: TextStyle(fontSize: 18)),
                  title: l10n.weatherForecastTitle,
                  onTap: () => context.push(Routes.forecast),
                ),
            ],
          ),
          if (place != null) ...[
            const SizedBox(height: Space.lg),
            FloraGroup(
              header: l10n.weatherClimate,
              footer: l10n.weatherClimateHint,
              children: const [_ClimateRow()],
            ),
            const SizedBox(height: Space.lg),
            FloraGroup(
              footer: l10n.weatherRainCountsHint,
              children: [
                FloraListRow(
                  leading: const Text('🌧️', style: TextStyle(fontSize: 18)),
                  title: l10n.weatherRainCounts,
                  trailing: AdaptiveSwitch(
                    value: ref.watch(preferencesProvider.select((p) => p.rainCountsAsWatering)),
                    onChanged: (v) => ref.read(preferencesProvider.notifier).setRainCountsAsWatering(v),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: Space.lg),
          FloraTextField(
            controller: _query,
            hint: l10n.weatherSearchHint,
            prefix: Icon(CupertinoIcons.search, size: 18, color: c.inkTertiary),
            onChanged: _onChanged,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.search,
            onSubmitted: _search,
          ),
          const SizedBox(height: Space.sm),
          if (_searching)
            const Padding(padding: EdgeInsets.all(Space.md), child: Center(child: AdaptiveProgress()))
          else if (_results.isNotEmpty)
            FloraGroup(
              children: [
                for (final r in _results)
                  FloraListRow(
                    title: r.name,
                    onTap: () async {
                      await ref.read(preferencesProvider.notifier).setWeatherPlace(r);
                      Haptics.success();
                      _query.clear();
                      setState(() => _results = const []);
                    },
                  ),
              ],
            )
          else if (_searched && _query.text.trim().length >= 2)
            Padding(padding: const EdgeInsets.all(Space.md), child: Text(l10n.weatherNoResults, style: context.text.callout, textAlign: TextAlign.center)),
        ],
      ),
    );
  }
}

/// « 🌡️ Zone 8a · Hivers à −6°, étés à 32° ». Le climat met un appel
/// d'archives à arriver la première fois ; la ligne attend sans rien dire de
/// plus, et reste sur « Inconnu » si l'historique ne donne rien.
class _ClimateRow extends ConsumerWidget {
  const _ClimateRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final metric = ref.watch(preferencesProvider.select((p) => p.metricUnits));
    final climate = ref.watch(regionClimateProvider);
    final value = climate.value;
    return FloraListRow(
      leading: const Text('🌡️', style: TextStyle(fontSize: 18)),
      title: switch ((climate, value)) {
        (_, final v?) => l10n.weatherClimateZone(v.hardinessLabel),
        (AsyncLoading(), _) => l10n.locating,
        _ => l10n.weatherClimateNone,
      },
      subtitle: value == null
          ? null
          : l10n.weatherClimateRange(weatherTemp(value.winterLowC, metric: metric), weatherTemp(value.summerHighC, metric: metric)),
      chevron: false,
    );
  }
}
