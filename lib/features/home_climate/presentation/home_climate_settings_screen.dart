import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/config/app_config.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../data/services/google_home_climate_service.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/home/home_climate.dart';
import '../application/home_climate_providers.dart';
import 'home_climate_widgets.dart';
import 'home_sensor_picker_sheet.dart';

/// Profil › Capteurs de la maison : le capteur de température, celui de
/// l'humidité, leur mesure, et de quoi en changer. Les capteurs viennent
/// d'Apple Maison, de Google Home, ou des deux — chaque maison se branche
/// par son propre bouton, et une demande d'accès à la fois.
class HomeClimateSettingsScreen extends ConsumerStatefulWidget {
  const HomeClimateSettingsScreen({super.key});

  @override
  ConsumerState<HomeClimateSettingsScreen> createState() => _HomeClimateSettingsScreenState();
}

class _HomeClimateSettingsScreenState extends ConsumerState<HomeClimateSettingsScreen> {
  bool _busy = false;

  /// Les maisons déjà interrogées : sans capteur trouvé, leur bouton reste,
  /// mais il n'est plus le bouton principal de l'écran.
  final Set<HomeSource> _searched = {};

  /// Les capteurs trouvés, toutes maisons confondues.
  List<HomeSensor> _sensors = const [];

  @override
  void initState() {
    super.initState();
    // Un capteur déjà branché : sa maison se relit d'elle-même, l'accès est
    // déjà accordé. Sans capteur, rien ne part avant le bouton — c'est lui
    // qui ouvre la demande du système, pour une maison à la fois.
    final prefs = ref.read(preferencesProvider);
    final known = {?prefs.homeSensor?.source, ?prefs.homeHumiditySensor?.source};
    if (known.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _search(known, silent: true));
    }
  }

  bool _hasFrom(HomeSource source) => _sensors.any((s) => s.source == source);

  /// Interroge des maisons, l'une après l'autre : deux demandes d'accès du
  /// système en même temps se marcheraient dessus.
  Future<void> _search(Iterable<HomeSource> sources, {bool silent = false}) async {
    if (_busy || !mounted) return;
    final l10n = context.l10n;
    setState(() => _busy = true);
    final service = ref.read(homeClimateServiceProvider);
    final found = <HomeSource, List<HomeSensor>>{};
    final access = <HomeSource, HomeAccess>{};
    for (final source in sources) {
      final one = service.of(source);
      if (one == null) continue;
      try {
        found[source] = await one.sensors();
        access[source] = await one.access();
      } catch (e, st) {
        ref.read(crashReporterProvider).report(e, st, context: 'home_climate.sensors');
      }
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _searched.addAll(found.keys);
      // Chaque maison remplace ses propres capteurs, et laisse ceux de l'autre.
      _sensors = [
        for (final s in _sensors)
          if (!found.containsKey(s.source)) s,
        for (final list in found.values) ...list,
      ];
    });
    if (silent) return;
    // Rien trouvé dans les maisons qu'on vient d'interroger : le message est
    // pour elles, même si l'autre maison a déjà donné ses capteurs.
    if (found.values.every((list) => list.isEmpty)) {
      final source = found.keys.firstOrNull ?? sources.firstOrNull;
      ref.read(toastProvider.notifier).show(ToastData(message: _emptyMessage(l10n, source, access[source]), emoji: '🏠'));
      return;
    }
    // Un seul capteur : c'est lui. Plusieurs : la maison, puis le capteur.
    if (ref.read(preferencesProvider).homeSensor != null) return;
    if (_sensors.length == 1) {
      await _select(_sensors.single);
    } else {
      await _pick();
    }
  }

  /// Rien trouvé : l'accès refusé se dit avec l'endroit où il se rouvre, et
  /// il n'est pas le même selon la maison.
  String _emptyMessage(AppLocalizations l10n, HomeSource? source, HomeAccess? access) {
    if (access == HomeAccess.denied) {
      return source == HomeSource.google ? l10n.homeClimateDeniedGoogle : l10n.homeClimateDeniedApple;
    }
    return l10n.homeClimateNoSensorsIn(homeSourceLabel(l10n, source ?? HomeSource.apple));
  }

  Future<void> _pick([HomeQuantity quantity = HomeQuantity.temperature]) async {
    final prefs = ref.read(preferencesProvider);
    final current = quantity == HomeQuantity.temperature ? prefs.homeSensor : (prefs.homeHumiditySensor ?? prefs.homeSensor);
    final chosen = await showHomeSensorPicker(context, sensors: _sensors, quantity: quantity, selectedKey: current?.key);
    if (chosen == null) return;
    if (quantity == HomeQuantity.temperature) {
      await _select(chosen);
    } else {
      await ref.read(preferencesProvider.notifier).setHomeHumiditySensor(chosen.key == prefs.homeSensor?.key ? null : chosen);
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
  /// titre, la maison, et la plateforme quand l'appareil en lit deux.
  String? _detail(HomeSensor s, {required bool named}) {
    final l10n = context.l10n;
    final parts = [if (s.roomName != null) s.name, ?s.homeName, if (named) homeSourceLabel(l10n, s.source)];
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
    // Les maisons lisibles ici, dans l'ordre où on les propose.
    final sources = ref.watch(homeClimateServiceProvider).sources;
    // La plateforme ne se dit sous un capteur que si l'appareil en lit deux :
    // sur Android, « Google Home » sous chaque ligne n'apprend rien.
    final named = sources.length > 1;
    // Google Home est écrit et lit de vrais capteurs, mais les Home APIs
    // plafonnent à cent comptes tant que leur console n'ouvre pas ses
    // inscriptions (voir [AppConfig.googleHomeSoon]). La ligne l'annonce,
    // tant qu'aucun capteur Google n'est lisible ici.
    final soon = AppConfig.googleHomeSoon && GoogleHomeClimateService.isPossible && !sources.contains(HomeSource.google);
    // Ce que le capteur de température sait mesurer, d'après la liste
    // fraîche quand on l'a, sinon d'après la préférence.
    final live = sensor == null ? null : _sensors.where((s) => s.key == sensor.key).firstOrNull ?? sensor;
    final humidityExpected = humiditySensor != null || (live?.hasHumidity ?? false);
    final hygrometers = _sensors.any((s) => s.hasHumidity && s.key != sensor?.key);
    final metric = ref.watch(preferencesProvider.select((p) => p.metricUnits));
    return FloraPage(
      title: l10n.homeClimate,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.homeClimateHint, style: context.text.callout),
          // D'où vient la mesure, maison par maison : HomeKit la lit sur
          // l'appareil, Google Home passe par le compte de la personne. Ce
          // n'est pas la même promesse, et chacune se dit.
          const SizedBox(height: Space.xs),
          if (sources.contains(HomeSource.apple)) Text(l10n.homeClimateAppleNote, style: context.text.caption),
          if (sources.contains(HomeSource.google)) Text(l10n.homeClimateGoogleNote, style: context.text.caption),
          const SizedBox(height: Space.lg),
          FloraGroup(
            header: l10n.homeClimateSensors,
            children: [
              // Un capteur par grandeur : chaque ligne s'ouvre sur la feuille
              // de choix, limitée aux accessoires qui mesurent celle-là.
              FloraListRow(
                leading: const Text('🌡️', style: TextStyle(fontSize: 18)),
                title: l10n.careTemperature,
                // Sous le nom, ce que la maison dit que l'accessoire mesure :
                // si « Humidité » n'y est pas, on sait d'où vient le tiret.
                subtitle: sensor == null
                    ? l10n.homeClimateNone
                    : [sensor.label, ?_detail(sensor, named: named), measuresLabel(l10n, live ?? sensor)].join(' · '),
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
                      ? [humiditySensor.label, ?_detail(humiditySensor, named: named)].join(' · ')
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
          else ...[
            if (_sensors.isNotEmpty && sensor == null)
              // La plateforme, la maison, la pièce, l'accessoire : le choix
              // se fait dans une feuille, la même qu'à l'onboarding.
              FloraButton(label: l10n.homeClimateChoose, icon: CupertinoIcons.house_fill, expand: true, onPressed: _pick),
            // Une maison qui n'a encore rien donné garde son bouton : c'est
            // par là qu'on la branche, ou qu'on la rebranche. Celle qui a
            // donné ses capteurs n'a plus rien à demander.
            for (final source in sources)
              if (!_hasFrom(source))
                Padding(
                  padding: const EdgeInsets.only(top: Space.xs),
                  child: FloraButton(
                    label: source == HomeSource.google ? l10n.homeClimateConnectGoogle : l10n.homeClimateConnectApple,
                    icon: CupertinoIcons.house_fill,
                    style: sensor == null && _sensors.isEmpty && !_searched.contains(source) ? FloraButtonStyle.primary : FloraButtonStyle.ghost,
                    expand: true,
                    onPressed: () => _search([source]),
                  ),
                ),
          ],
          // Une maison qu'on ne peut pas encore brancher : son nom, une
          // étiquette, et rien à toucher. Elle dit ce qui vient, elle ne
          // promet pas de date.
          if (soon) ...[
            const SizedBox(height: Space.lg),
            FloraGroup(
              children: [
                FloraListRow(
                  leading: const Text('🏠', style: TextStyle(fontSize: 18)),
                  title: l10n.homeClimateGoogle,
                  trailing: FloraTag(label: l10n.soon),
                  chevron: false,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
