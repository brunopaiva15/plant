import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/home/home_climate.dart';
import '../application/home_climate_providers.dart';
import 'home_climate_widgets.dart';
import 'home_sensor_picker_sheet.dart';

/// Profil › Apple Maison : le capteur de température, celui de l'humidité,
/// leur mesure, et de quoi en changer.
class HomeClimateSettingsScreen extends ConsumerStatefulWidget {
  const HomeClimateSettingsScreen({super.key});

  @override
  ConsumerState<HomeClimateSettingsScreen> createState() => _HomeClimateSettingsScreenState();
}

class _HomeClimateSettingsScreenState extends ConsumerState<HomeClimateSettingsScreen> {
  bool _busy = false;
  bool _searched = false;
  List<HomeSensor> _sensors = const [];

  @override
  void initState() {
    super.initState();
    // Un capteur déjà branché : la liste se charge d'elle-même, l'accès est
    // déjà accordé. Sans capteur, rien ne part avant le bouton — c'est lui
    // qui ouvre la demande du système.
    if (ref.read(preferencesProvider).homeSensor != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _connect(silent: true));
    }
  }

  Future<void> _connect({bool silent = false}) async {
    if (_busy || !mounted) return;
    final l10n = context.l10n;
    setState(() => _busy = true);
    final service = ref.read(homeClimateServiceProvider);
    List<HomeSensor> sensors = const [];
    var access = HomeAccess.unavailable;
    try {
      sensors = await service.sensors();
      access = await service.access();
    } catch (e, st) {
      ref.read(crashReporterProvider).report(e, st, context: 'home_climate.sensors');
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _searched = true;
      _sensors = sensors;
    });
    if (silent) return;
    if (sensors.isEmpty) {
      ref.read(toastProvider.notifier).show(ToastData(message: access == HomeAccess.denied ? l10n.homeClimateDenied : l10n.homeClimateNoSensors, emoji: '🏠'));
      return;
    }
    // Un seul capteur : c'est lui. Plusieurs : la maison, puis le capteur.
    if (ref.read(preferencesProvider).homeSensor != null) return;
    if (sensors.length == 1) {
      await _select(sensors.single);
    } else {
      await _pick();
    }
  }

  Future<void> _pick([HomeQuantity quantity = HomeQuantity.temperature]) async {
    final prefs = ref.read(preferencesProvider);
    final current = quantity == HomeQuantity.temperature ? prefs.homeSensor : (prefs.homeHumiditySensor ?? prefs.homeSensor);
    final chosen = await showHomeSensorPicker(context, sensors: _sensors, quantity: quantity, selectedId: current?.id);
    if (chosen == null) return;
    if (quantity == HomeQuantity.temperature) {
      await _select(chosen);
    } else {
      await ref.read(preferencesProvider.notifier).setHomeHumiditySensor(chosen.id == prefs.homeSensor?.id ? null : chosen);
      ref.invalidate(homeReadingProvider);
      Haptics.success();
    }
  }

  Future<void> _select(HomeSensor sensor) async {
    await ref.read(preferencesProvider.notifier).setHomeSensor(sensor);
    ref.invalidate(homeReadingProvider);
    Haptics.success();
  }

  /// Ce que dit un capteur sous son nom : l'accessoire quand la pièce fait
  /// titre, et la maison.
  static String? _detail(HomeSensor s) {
    final parts = [if (s.roomName != null) s.name, ?s.homeName];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  Future<void> _remove() async {
    await ref.read(preferencesProvider.notifier).setHomeSensor(null);
    ref.invalidate(homeReadingProvider);
    if (mounted) setState(() => _sensors = const []);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final sensor = ref.watch(preferencesProvider.select((p) => p.homeSensor));
    final humiditySensor = ref.watch(preferencesProvider.select((p) => p.homeHumiditySensor));
    final reading = ref.watch(homeReadingProvider);
    final canPick = _sensors.isNotEmpty && !_busy;
    // Ce que le capteur de température sait mesurer, d'après la liste
    // fraîche quand on l'a, sinon d'après la préférence.
    final live = sensor == null ? null : _sensors.where((s) => s.id == sensor.id).firstOrNull ?? sensor;
    final humidityExpected = humiditySensor != null || (live?.hasHumidity ?? false);
    final hygrometers = _sensors.any((s) => s.hasHumidity && s.id != sensor?.id);
    final metric = ref.watch(preferencesProvider.select((p) => p.metricUnits));
    return FloraPage(
      title: l10n.homeClimate,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.homeClimateHint, style: context.text.callout),
          const SizedBox(height: Space.lg),
          FloraGroup(
            header: l10n.homeClimateSensors,
            children: [
              // Un capteur par grandeur : chaque ligne s'ouvre sur la feuille
              // de choix, limitée aux accessoires qui mesurent celle-là.
              FloraListRow(
                leading: const Text('🌡️', style: TextStyle(fontSize: 18)),
                title: l10n.careTemperature,
                // Sous le nom, ce que HomeKit dit que l'accessoire mesure :
                // si « Humidité » n'y est pas, on sait d'où vient le tiret.
                subtitle: sensor == null ? l10n.homeClimateNone : [sensor.label, ?_detail(sensor), measuresLabel(l10n, live ?? sensor)].join(' · '),
                trailing: sensor == null
                    ? null
                    : FloraIconButton(
                        icon: CupertinoIcons.xmark_circle_fill,
                        semanticLabel: l10n.homeClimateRemove,
                        filled: false,
                        color: c.inkTertiary,
                        onPressed: _remove,
                      ),
                chevron: canPick,
                onTap: canPick ? () => _pick(HomeQuantity.temperature) : null,
              ),
              if (sensor != null)
                FloraListRow(
                  leading: const Text('💧', style: TextStyle(fontSize: 18)),
                  title: l10n.weatherHumidity,
                  // « Même capteur » seulement s'il mesure vraiment
                  // l'humidité ; sinon il n'y a pas d'hygromètre, et la
                  // ligne le dit, et mène à en choisir un s'il en existe.
                  subtitle: humiditySensor != null
                      ? [humiditySensor.label, ?_detail(humiditySensor)].join(' · ')
                      : (live?.hasHumidity ?? false)
                          ? l10n.homeClimateSameSensor
                          : l10n.homeClimateNone,
                  chevron: canPick && (hygrometers || humiditySensor != null),
                  onTap: canPick && (hygrometers || humiditySensor != null) ? () => _pick(HomeQuantity.humidity) : null,
                ),
              if (sensor != null)
                FloraListRow(
                  leading: const Text('📈', style: TextStyle(fontSize: 18)),
                  title: l10n.homeClimateReading,
                  subtitle: switch (reading) {
                    // Une humidité attendue et absente se dit : sans cela,
                    // « 24° » seul ne distingue pas un capteur muet d'un
                    // capteur qui ne la mesure pas.
                    AsyncData(:final value) when value != null && value.humidity == null && humidityExpected =>
                      [l10n.homeClimateHumidityMissing, ?value.error].join(' '),
                    AsyncData(:final value) when value != null && !value.isEmpty => l10n.homeClimateUpdatedAgo(DateTime.now().difference(value.at).inMinutes),
                    AsyncData(:final value) when value != null => [l10n.homeClimateUnavailable, ?value.error].join(' '),
                    AsyncLoading() => null,
                    _ => l10n.homeClimateUnavailable,
                  },
                  subtitleColor: switch (reading) {
                    AsyncData(:final value) when value != null && ((value.humidity == null && humidityExpected) || value.isEmpty) => c.danger,
                    _ => null,
                  },
                  trailing: switch (reading) {
                    AsyncData(:final value) when value != null && !value.isEmpty =>
                      Text(homeReadingLabel(value, metric: metric), style: context.text.callout.copyWith(color: c.ink, fontWeight: FontWeight.w600)),
                    AsyncLoading() => const AdaptiveProgress(),
                    _ => null,
                  },
                  chevron: false,
                  onTap: () => ref.invalidate(homeReadingProvider),
                ),
            ],
          ),
          const SizedBox(height: Space.lg),
          if (_busy)
            const Padding(padding: EdgeInsets.all(Space.md), child: Center(child: AdaptiveProgress()))
          else if (_sensors.isNotEmpty && sensor == null)
            // La maison, la pièce, l'accessoire : le choix se fait dans une
            // feuille, la même qu'à l'onboarding.
            FloraButton(label: l10n.homeClimateChoose, icon: CupertinoIcons.house_fill, expand: true, onPressed: _pick)
          else if (_sensors.isEmpty && (sensor == null || _searched))
            FloraButton(label: l10n.homeClimateConnect, icon: CupertinoIcons.house_fill, style: sensor == null ? FloraButtonStyle.primary : FloraButtonStyle.ghost, expand: true, onPressed: _connect),
        ],
      ),
    );
  }
}
