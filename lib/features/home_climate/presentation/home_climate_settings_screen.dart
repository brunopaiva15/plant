import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/home/home_climate.dart';
import '../application/home_climate_providers.dart';
import 'home_climate_widgets.dart';

/// Profil › Apple Maison : le capteur retenu, sa mesure, et les autres
/// capteurs de la maison pour en changer.
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
    // Un seul capteur : c'est lui. Plusieurs : la liste attend un choix.
    if (sensors.length == 1 && ref.read(preferencesProvider).homeSensor == null) await _select(sensors.single);
  }

  Future<void> _select(HomeSensor sensor) async {
    await ref.read(preferencesProvider.notifier).setHomeSensor(sensor);
    ref.invalidate(homeReadingProvider);
    Haptics.success();
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
    final reading = ref.watch(homeReadingProvider);
    final metric = ref.watch(preferencesProvider.select((p) => p.metricUnits));
    final others = [
      for (final s in _sensors)
        if (s.id != sensor?.id) s,
    ];
    return FloraPage(
      title: l10n.homeClimate,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.homeClimateHint, style: context.text.callout),
          const SizedBox(height: Space.lg),
          FloraGroup(
            header: l10n.homeClimateSensor,
            children: [
              FloraListRow(
                leading: Text(sensor == null ? '🏠' : '🌡️', style: const TextStyle(fontSize: 18)),
                title: sensor?.label ?? l10n.homeClimateNone,
                subtitle: sensor == null || sensor.roomName == null ? null : sensor.name,
                trailing: sensor == null
                    ? null
                    : FloraIconButton(
                        icon: CupertinoIcons.xmark_circle_fill,
                        semanticLabel: l10n.homeClimateRemove,
                        filled: false,
                        color: c.inkTertiary,
                        onPressed: _remove,
                      ),
                chevron: false,
              ),
              if (sensor != null)
                FloraListRow(
                  leading: const Text('📈', style: TextStyle(fontSize: 18)),
                  title: l10n.homeClimateReading,
                  subtitle: switch (reading) {
                    AsyncData(:final value) when value != null && !value.isEmpty => l10n.homeClimateUpdatedAgo(DateTime.now().difference(value.at).inMinutes),
                    AsyncLoading() => null,
                    _ => l10n.homeClimateUnavailable,
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
          else if (others.isNotEmpty)
            FloraGroup(
              header: l10n.homeClimateSensors,
              children: [
                for (final s in others)
                  FloraListRow(
                    leading: const Text('🌡️', style: TextStyle(fontSize: 18)),
                    title: s.label,
                    subtitle: s.roomName == null ? s.homeName : s.name,
                    onTap: () => _select(s),
                  ),
              ],
            )
          else if (sensor == null)
            FloraButton(label: l10n.homeClimateConnect, icon: CupertinoIcons.house_fill, expand: true, onPressed: _connect)
          else if (_searched)
            FloraButton(label: l10n.homeClimateConnect, style: FloraButtonStyle.ghost, expand: true, onPressed: _connect),
        ],
      ),
    );
  }
}
