import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/care/care_profile.dart';
import '../../../domain/home/home_climate.dart';
import '../../../domain/home/home_climate_advisor.dart';
import '../../today/presentation/today_notice.dart';
import '../application/home_climate_providers.dart';

/// « 21° · 38 % » : la mesure, dans l'unité de l'utilisateur.
String homeReadingLabel(HomeReading reading, {required bool metric}) {
  final parts = <String>[
    if (reading.temperatureC case final t?) metric ? '${t.round()}°' : '${(t * 9 / 5 + 32).round()}°F',
    if (reading.humidity case final h?) '$h %',
  ];
  return parts.join(' · ');
}

/// « 25° · 41 % · Salon », ou « Chez vous · 25° » quand le capteur n'a pas
/// de pièce : la mesure en titre, telle que la pilule du jour la montre.
String homeReadingTitle(AppLocalizations l10n, HomeReading reading, {required bool metric}) {
  final room = reading.sensor?.label;
  final value = homeReadingLabel(reading, metric: metric);
  return room == null || room.isEmpty ? '${l10n.homeClimateAtHome} · $value' : '$value · $room';
}

/// « 🏠 21° · 38 % · Salon › » : la pilule de la maison, à côté de celle du
/// temps, sous la date de l'écran Aujourd'hui. Mène aux réglages du capteur.
class HomeClimatePill extends ConsumerWidget {
  const HomeClimatePill({super.key, required this.reading});

  final HomeReading reading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metric = ref.watch(preferencesProvider.select((p) => p.metricUnits));
    return FloraPill(emoji: '🏠', label: homeReadingLabel(reading, metric: metric), detail: reading.sensor?.label, chevron: true, onTap: () => context.push(Routes.homeClimate));
  }
}

/// Le texte d'un conseil, dans la langue de l'utilisateur. La mesure n'y est
/// pas : c'est le titre de la carte qui la porte.
String homeTipText(AppLocalizations l10n, HomeClimateTip tip) {
  final names = l10n.joinNames(tip.plantNames);
  return switch (tip.kind) {
    HomeClimateTipKind.dryAir => l10n.homeTipDryAir(names),
    HomeClimateTipKind.humidAir => tip.plantNames.isEmpty ? l10n.homeTipHumidAir : l10n.homeTipHumidAirPlants(names),
    HomeClimateTipKind.cold => l10n.homeTipCold(names),
    HomeClimateTipKind.hot => l10n.homeTipHot(names),
  };
}

String homeTipEmoji(HomeClimateTipKind kind) => switch (kind) {
      HomeClimateTipKind.dryAir => '💨',
      HomeClimateTipKind.humidAir => '💧',
      HomeClimateTipKind.cold => '🥶',
      HomeClimateTipKind.hot => '🥵',
    };

/// « 25° · 41 % · Salon » puis, dessous, ce que l'air de la pièce demande :
/// « Air sec : brumiser ou regrouper Calathea et Monstera. » [×]
///
/// Une carte, un conseil par ligne, trois au plus. Elle paraît une fois par
/// jour : les plantes signalées le restent tant que la pièce ne change pas,
/// et les redire à chaque passage serait du bruit. Elle tient jusqu'à la
/// croix ou jusqu'à la fermeture de l'application ; demain la mesure aura
/// changé, ou pas, et elle reviendra.
class HomeClimateAdviceCard extends ConsumerStatefulWidget {
  const HomeClimateAdviceCard({super.key});

  @override
  ConsumerState<HomeClimateAdviceCard> createState() => _HomeClimateAdviceCardState();
}

class _HomeClimateAdviceCardState extends ConsumerState<HomeClimateAdviceCard> {
  /// La carte est à l'écran : le jour se note une fois la frame posée —
  /// pendant la construction, l'écriture rebâtirait l'arbre en plein vol.
  void _markShownAfterFrame() {
    if (ref.read(homeTipsNoticeProvider)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(homeTipsNoticeProvider.notifier).markShown();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tips = ref.watch(homeClimateTipsProvider);
    final reading = ref.watch(homeReadingProvider).value;
    ref.watch(homeTipsNoticeProvider);
    final metric = ref.watch(preferencesProvider.select((p) => p.metricUnits));
    final show = tips.isNotEmpty && reading != null && ref.read(homeTipsNoticeProvider.notifier).canShow;
    if (show) _markShownAfterFrame();
    final shown = tips.take(3).toList();
    return TodayNoticeSlot(
      visible: show,
      child: !show
          ? const SizedBox.shrink()
          : TodayNotice(
              // Un seul conseil : son emoji. Plusieurs : la maison.
              emoji: shown.length == 1 ? homeTipEmoji(shown.single.kind) : '🏠',
              color: context.colors.sunSoft,
              title: homeReadingTitle(l10n, reading, metric: metric),
              body: shown.map((t) => homeTipText(l10n, t)).join('\n'),
              onDismiss: () => ref.read(homeTipsNoticeProvider.notifier).dismiss(),
            ),
    );
  }
}

/// La carte « Chez vous » d'une fiche d'entretien : la mesure de la pièce,
/// et ce qu'elle vaut pour l'espèce. Absente sans capteur.
class HomeClimateFitCard extends ConsumerWidget {
  const HomeClimateFitCard({super.key, required this.profile});

  final CareProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final reading = ref.watch(homeReadingProvider).value;
    if (reading == null || reading.isEmpty) return const SizedBox.shrink();
    final metric = ref.watch(preferencesProvider.select((p) => p.metricUnits));
    final fit = homeFit(reading, profile);
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.md),
      child: FloraCard(
        color: fit == null ? c.sageSoft : c.sunSoft,
        child: Row(
          children: [
            const EmojiTile(emoji: '🏠'),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${l10n.homeClimateAtHome} · ${homeReadingLabel(reading, metric: metric)}', style: context.text.title3),
                  const SizedBox(height: 2),
                  Text(
                    switch (fit) {
                      null => l10n.homeClimateFits,
                      HomeClimateTipKind.cold => l10n.homeClimateTooCold,
                      HomeClimateTipKind.hot => l10n.homeClimateTooHot,
                      HomeClimateTipKind.dryAir => l10n.homeClimateTooDry,
                      HomeClimateTipKind.humidAir => l10n.homeClimateTooHumid,
                    },
                    style: context.text.callout,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// L'écart entre la mesure et ce que l'espèce attend, ou `null` si tout va.
/// Le premier écart trouvé l'emporte : le froid avant l'air sec, parce qu'il
/// abîme plus vite. Mêmes seuils que le conseil du jour.
HomeClimateTipKind? homeFit(HomeReading reading, CareProfile profile) {
  final tips = HomeClimateAdvisor.advise(reading: reading, plants: [IndoorPlant(name: '·', profile: profile)]);
  for (final kind in HomeClimateTipKind.values) {
    if (tips.any((t) => t.kind == kind && t.plantNames.isNotEmpty)) return kind;
  }
  return null;
}
