import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/care/care_profile.dart';
import '../../../domain/home/home_climate.dart';
import '../../../domain/home/home_climate_advisor.dart';
import '../application/home_climate_providers.dart';

/// « 21° · 38 % » : la mesure, dans l'unité de l'utilisateur.
String homeReadingLabel(HomeReading reading, {required bool metric}) {
  final parts = <String>[
    if (reading.temperatureC case final t?) metric ? '${t.round()}°' : '${(t * 9 / 5 + 32).round()}°F',
    if (reading.humidity case final h?) '$h %',
  ];
  return parts.join(' · ');
}

/// La température seule, dans l'unité de l'utilisateur, pour une phrase.
String homeTemperatureLabel(num celsius, {required bool metric}) => metric ? '${celsius.round()}°' : '${(celsius * 9 / 5 + 32).round()}°F';

/// Ligne discrète « 🏠 21° · 38 % · Salon » sous la météo de l'écran Aujourd'hui.
class HomeClimateLine extends ConsumerWidget {
  const HomeClimateLine({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reading = ref.watch(homeReadingProvider).value;
    if (reading == null || reading.isEmpty) return const SizedBox.shrink();
    final metric = ref.watch(preferencesProvider.select((p) => p.metricUnits));
    final label = reading.sensor?.label;
    final text = [homeReadingLabel(reading, metric: metric), if (label != null && label.isNotEmpty) label].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Pressable(
        onTap: () => context.push(Routes.homeClimate),
        scale: 1,
        child: Row(
          children: [
            const Text('🏠', style: TextStyle(fontSize: 13)),
            const SizedBox(width: 4),
            Flexible(child: Text(text, style: context.text.caption, maxLines: 1, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 2),
            Icon(CupertinoIcons.chevron_right, size: 11, color: context.colors.inkTertiary),
          ],
        ),
      ),
    );
  }
}

/// Le texte d'un conseil, dans la langue et l'unité de l'utilisateur.
String homeTipText(AppLocalizations l10n, HomeClimateTip tip, {required bool metric}) {
  final names = l10n.joinNames(tip.plantNames);
  return switch (tip.kind) {
    HomeClimateTipKind.dryAir => l10n.homeTipDryAir(tip.value.round(), names),
    HomeClimateTipKind.humidAir => tip.plantNames.isEmpty ? l10n.homeTipHumidAir(tip.value.round()) : l10n.homeTipHumidAirPlants(tip.value.round(), names),
    HomeClimateTipKind.cold => l10n.homeTipCold(homeTemperatureLabel(tip.value, metric: metric), names),
    HomeClimateTipKind.hot => l10n.homeTipHot(homeTemperatureLabel(tip.value, metric: metric), names),
  };
}

String homeTipEmoji(HomeClimateTipKind kind) => switch (kind) {
      HomeClimateTipKind.dryAir => '💨',
      HomeClimateTipKind.humidAir => '💧',
      HomeClimateTipKind.cold => '🥶',
      HomeClimateTipKind.hot => '🥵',
    };

/// « Air sec (32 %) : brumiser ou regrouper Calathea et Monstera. » [×]
///
/// Une carte, un conseil par ligne, trois au plus. Elle se ferme pour la
/// journée ; demain la mesure aura changé, ou pas, et elle reviendra.
class HomeClimateAdviceCard extends ConsumerWidget {
  const HomeClimateAdviceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final tips = ref.watch(homeClimateTipsProvider);
    ref.watch(dismissedHomeTipsProvider);
    final dismissed = ref.watch(dismissedHomeTipsProvider.notifier).isDismissedToday;
    final metric = ref.watch(preferencesProvider.select((p) => p.metricUnits));
    final show = tips.isNotEmpty && !dismissed;
    return AnimatedSize(
      duration: Motion.of(context, Motion.emphasis),
      curve: Motion.emphasized,
      child: !show
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.fromLTRB(Space.page, Space.md, Space.page, 0),
              child: FloraCard(
                color: c.sunSoft,
                padding: const EdgeInsets.all(Space.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final (i, tip) in tips.take(3).indexed)
                            Padding(
                              padding: EdgeInsets.only(top: i == 0 ? 0 : Space.xs),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(homeTipEmoji(tip.kind), style: const TextStyle(fontSize: 20)),
                                  const SizedBox(width: Space.sm),
                                  Expanded(child: Text(homeTipText(l10n, tip, metric: metric), style: context.text.callout.copyWith(color: c.ink))),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: Space.xs),
                    FloraIconButton(icon: CupertinoIcons.xmark, semanticLabel: l10n.close, filled: false, size: 32, onPressed: () => ref.read(dismissedHomeTipsProvider.notifier).dismissToday()),
                  ],
                ),
              ),
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
