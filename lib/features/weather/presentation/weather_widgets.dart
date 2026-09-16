import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/weather/outdoor_alert.dart';
import '../../../domain/weather/weather.dart';
import '../../../domain/weather/weather_advisor.dart';
import '../../account/application/membership_providers.dart';
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
    final temp = weatherTemp(weather.temperatureNow, metric: metric);
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

/// « 22° », « 72 °F » : une température, dans l'unité de l'utilisateur.
String weatherTemp(double celsius, {required bool metric}) => metric ? '${celsius.round()}°' : '${(celsius * 9 / 5 + 32).round()}°F';

/// La carte de la pluie, sur l'écran du matin. Elle dit l'une de deux
/// choses, jamais les deux :
///
/// - « Pluie · 8 mm — Arrosage noté fait pour Balcon. » quand il est tombé
///   de quoi arroser ; d'un tap, ou tout seul si le réglage est actif ;
/// - « Pluie aujourd'hui — L'arrosage de Balcon peut attendre. » [Reporter]
///   quand elle n'est qu'annoncée.
///
/// La pluie tombée l'emporte : reporter un arrosage que la pluie a déjà fait
/// n'aurait plus de sens.
class WeatherAdviceCard extends ConsumerStatefulWidget {
  const WeatherAdviceCard({super.key});

  @override
  ConsumerState<WeatherAdviceCard> createState() => _WeatherAdviceCardState();
}

class _WeatherAdviceCardState extends ConsumerState<WeatherAdviceCard> {
  /// Une seule tentative en vol : la carte se reconstruit à chaque bulletin,
  /// et l'écriture, elle, prend le temps d'une transaction.
  bool _applying = false;

  void _applyAfterFrame(AppLocalizations l10n) {
    if (_applying) return;
    _applying = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // La frame peut emporter la carte — on change d'onglet, le conseil
      // s'efface — avant que le rappel ne tourne.
      if (!mounted) return;
      await ref.read(rainWateringProvider.notifier).applyIfNeeded(l10n);
      if (mounted) _applying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final advice = ref.watch(weatherAdviceProvider);
    // L'automatisme demande le réglage et le droit d'écrire : un invité en
    // lecture seule garde la carte et son bouton, qui lui dira non.
    final auto = ref.watch(preferencesProvider.select((p) => p.rainCountsAsWatering)) && ref.watch(canEditProvider);
    ref.watch(rainWateringProvider);
    final watered = ref.read(rainWateringProvider.notifier).today;
    final dismissed = ref.watch(dismissedAdviceProvider.notifier).isDismissedToday;
    ref.watch(dismissedAdviceProvider);

    final pending = advice != null && advice.kind == RainAdviceKind.fallen && auto && watered == null;
    if (pending) _applyAfterFrame(l10n);

    // Trois états, dans cet ordre : l'écriture automatique en cours, où la
    // carte se tait — proposer un geste qu'on est en train de faire tout
    // seul la ferait clignoter ; ce qui a été noté ce matin, qui la tient
    // pour la journée même une fois les arrosages sortis de la liste du
    // jour ; et le conseil, quand il reste quelque chose à décider.
    final notice = pending
        ? null
        : watered != null
            ? _RainNotice(
                title: l10n.weatherRainFallenTitle(l10n.formatQuantity(watered.rainMm, '')),
                body: l10n.weatherRainWatered(l10n.joinNames(watered.locationNames)),
              )
            : advice == null
                ? null
                : switch (advice.kind) {
                    RainAdviceKind.fallen => _RainNotice(
                        title: l10n.weatherRainFallenTitle(l10n.formatQuantity(advice.rainMm, '')),
                        body: l10n.weatherRainWaterable(l10n.joinNames(advice.locationNames)),
                        actionLabel: l10n.weatherRainMarkWatered,
                        onAction: () => ref.read(rainWateringProvider.notifier).apply(l10n, advice),
                      ),
                    RainAdviceKind.expected => _RainNotice(
                        title: l10n.weatherRainTitle,
                        body: l10n.weatherRainSkip(l10n.joinNames(advice.locationNames)),
                        actionLabel: l10n.postpone,
                        onAction: () => _postpone(l10n, advice),
                      ),
                  };

    final show = notice != null && !dismissed;
    return TodayNoticeSlot(
      visible: show,
      child: !show
          ? const SizedBox.shrink()
          : TodayNotice(
              emoji: '🌧️',
              color: context.colors.waterSoft,
              title: notice.title,
              body: notice.body,
              onDismiss: () => ref.read(dismissedAdviceProvider.notifier).dismissToday(),
              actions: [
                if (notice.onAction case final action?)
                  FloraButton(label: notice.actionLabel!, size: FloraButtonSize.small, onPressed: action),
              ],
            ),
    );
  }

  Future<void> _postpone(AppLocalizations l10n, WeatherAdvice advice) async {
    final care = ref.read(careRepositoryProvider);
    final now = DateTime.now();
    for (final t in advice.tasks) {
      await care.snooze(t.schedule.id, now);
    }
    Haptics.success();
    ref.read(dismissedAdviceProvider.notifier).dismissToday();
    ref.read(toastProvider.notifier).show(ToastData(message: l10n.postponedCount(advice.tasks.length), emoji: '🌧️'));
    await ref.read(reminderSchedulerProvider).reschedule();
  }
}

/// Ce que la carte de la pluie a à dire, une fois le cas tranché.
class _RainNotice {
  const _RainNotice({required this.title, required this.body, this.actionLabel, this.onAction});

  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;
}

String outdoorAlertEmoji(OutdoorAlertKind kind) => switch (kind) {
      OutdoorAlertKind.frost => '❄️',
      OutdoorAlertKind.heat => '🥵',
    };

/// « Gel cette nuit · −2° — À rentrer ou à couvrir : Olivier, Citronnier. »
///
/// Une carte par sorte d'avertissement, deux au plus, et seulement pour les
/// plantes dont la fiche dit qu'elles ne tiendront pas. La teinte est celle
/// de l'urgence pour le gel — on a une nuit —, celle du soleil pour la
/// chaleur, qui laisse la journée.
class OutdoorAlertCard extends ConsumerWidget {
  const OutdoorAlertCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final alerts = ref.watch(outdoorAlertsProvider);
    ref.watch(dismissedAlertsProvider);
    final dismissed = ref.watch(dismissedAlertsProvider.notifier).isDismissedToday;
    final metric = ref.watch(preferencesProvider.select((p) => p.metricUnits));
    final show = alerts.isNotEmpty && !dismissed;
    final now = DateTime.now();
    return TodayNoticeSlot(
      visible: show,
      child: !show
          ? const SizedBox.shrink()
          : Column(
              children: [
                for (final (i, alert) in alerts.indexed)
                  Padding(
                    padding: EdgeInsets.only(top: i == 0 ? 0 : Space.sm),
                    child: TodayNotice(
                      emoji: outdoorAlertEmoji(alert.kind),
                      color: alert.kind == OutdoorAlertKind.frost ? c.terracottaSoft : c.sunSoft,
                      title: switch (alert.kind) {
                        OutdoorAlertKind.frost => l10n.weatherFrostTitle(l10n.alertWhen(alert, now), weatherTemp(alert.temperatureC, metric: metric)),
                        OutdoorAlertKind.heat => l10n.weatherHeatTitle(l10n.alertWhen(alert, now), weatherTemp(alert.temperatureC, metric: metric)),
                      },
                      body: switch (alert.kind) {
                        OutdoorAlertKind.frost => l10n.weatherFrostBody(l10n.alertPlantList(alert)),
                        OutdoorAlertKind.heat => l10n.weatherHeatBody(l10n.alertPlantList(alert)),
                      },
                      // Une croix sur la première suffit : les deux
                      // avertissements parlent du même bulletin.
                      onDismiss: i == 0 ? () => ref.read(dismissedAlertsProvider.notifier).dismissToday() : null,
                    ),
                  ),
              ],
            ),
    );
  }
}
