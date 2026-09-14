import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../../core/l10n/l10n.dart';
import '../../../data/services/notification_service.dart';
import '../../../domain/care/reminder_planner.dart';
import '../../../domain/models/models.dart';
import '../../../domain/repositories/repositories.dart';
import '../../../domain/weather/outdoor_alert.dart';
import '../../weather/application/weather_providers.dart';

/// Planifie la notification quotidienne à partir des soins dus.
///
/// Appelé au démarrage, après chaque action et après tout changement de
/// réglage. Une seule notification, groupée, utile : « Monstera et Pilea ont
/// probablement besoin d'eau aujourd'hui. »
class ReminderScheduler {
  ReminderScheduler(this._ref);

  final Ref _ref;

  Future<void> reschedule() async {
    final prefs = _ref.read(preferencesProvider);
    final notifications = _ref.read(notificationServiceProvider);
    if (!prefs.notificationsEnabled) {
      await notifications.cancelAll();
      return;
    }
    final now = DateTime.now();
    await _rescheduleEvents(now, prefs);
    final fireAt = ReminderPlanner.nextFireTime(
      now,
      hour: prefs.notificationTime.hour,
      minute: prefs.notificationTime.minute,
      quietWeekdays: prefs.quietWeekdays,
    );
    // On évalue les soins qui seront dus au moment de la notification.
    final tasks = await _ref.read(careRepositoryProvider).watchTasks(until: DateTime(fireAt.year, fireAt.month, fireAt.day, 23, 59, 59)).first;
    final digest = ReminderPlanner.digest(tasks, fireAt);
    final lowStock = await _ref.read(inventoryRepositoryProvider).watchLowStock().first;
    // Tâches libres échues au moment de la notification (sans date : ignorées).
    final openTasks = await _ref.read(taskRepositoryProvider).watchOpen().first;
    final dueTasks = openTasks.where((t) => t.dueAt != null && !t.dueAt!.isAfter(fireAt)).toList()
      ..sort((a, b) => a.dueAt!.compareTo(b.dueAt!));
    // Gel et chaleur : seulement ce qui tombe dans les vingt-quatre heures
    // qui suivent le rappel. Au-delà, l'avertissement reviendrait trois
    // matins de suite pour la même nuit, et on cesserait de le lire.
    final alerts = [
      for (final a in await _outdoorAlerts(fireAt))
        if (a.daysFrom(fireAt) <= 1) a,
    ];
    if (digest.isEmpty && lowStock.isEmpty && dueTasks.isEmpty && alerts.isEmpty) {
      await notifications.cancelAll();
      return;
    }
    final l10n = resolveLocalizations(prefs.locale);
    await notifications.scheduleDaily(
      at: fireAt,
      title: l10n.notificationTitle,
      body: buildBody(
        l10n,
        digest,
        lowStockNames: lowStock.map((i) => i.name).toList(),
        taskTitles: dueTasks.map((t) => t.title).toList(),
        alerts: alerts,
        at: fireAt,
      ),
      channelName: l10n.notificationChannel,
      payload: '/today',
    );
  }

  /// Gel et chaleur des prochains jours, pour les plantes qui vivent dehors.
  ///
  /// Les dépôts sont relus ici plutôt que par les providers de l'écran : ceux
  /// de l'affichage se libèrent dès qu'on ne les regarde plus, et le
  /// planificateur, lui, tourne sans écran.
  Future<List<OutdoorAlert>> _outdoorAlerts(DateTime at) async {
    final forecast = _ref.read(forecastDaysProvider);
    if (forecast.isEmpty) return const [];
    final locations = await _ref.read(locationRepositoryProvider).watchAll().first;
    final outdoor = {for (final l in locations) if (l.isOutdoor) l.id};
    if (outdoor.isEmpty) return const [];
    final plants = await _ref.read(plantRepositoryProvider).watchSummaries(const PlantFilter()).first;
    final guide = _ref.read(careGuideProvider);
    final family = speciesFamilyLookupIn(_ref);
    final outdoorPlants = [
      for (final p in plants)
        if (outdoor.contains(p.plant.locationId))
          if (p.plant.speciesName case final species? when species.isNotEmpty)
            OutdoorPlant(name: p.plant.name, profile: guide.resolve(species, family: family(species)).profile),
    ];
    return OutdoorAlertAdvisor.alerts(forecast: forecast, plants: outdoorPlants, now: at);
  }

  /// Rappels ponctuels des événements du calendrier, à leur propre heure.
  /// Un mois d'avance suffit : le planificateur repasse à chaque changement.
  Future<void> _rescheduleEvents(DateTime now, AppPreferences prefs) async {
    final entries = await _ref.read(calendarRepositoryProvider).watchBetween(now, now.add(const Duration(days: 30))).first;
    final l10n = resolveLocalizations(prefs.locale);
    final reminders = [
      for (final e in entries)
        if (e.remindAt case final at? when at.isAfter(now))
          ScheduledReminder(at: at, title: e.title, body: eventReminderBody(l10n, e), payload: '/garden'),
    ]..sort((a, b) => a.at.compareTo(b.at));
    await _ref.read(notificationServiceProvider).scheduleEventReminders(reminders, channelName: l10n.notificationChannel);
  }

  /// Corps du rappel : les notes si l'utilisateur en a écrit, sinon l'heure
  /// de début — la seule chose qu'il ne voit pas déjà dans le titre.
  static String eventReminderBody(AppLocalizations l10n, CalendarEntry entry) {
    final notes = entry.notes?.trim();
    if (notes != null && notes.isNotEmpty) return notes;
    if (entry.allDay) return l10n.today;
    return DateFormat.jm(l10n.localeName).format(entry.startAt);
  }

  /// Texte humain, sans jargon : arrosage d'abord, le reste compté.
  static String buildBody(
    AppLocalizations l10n,
    ReminderDigest digest, {
    List<String> lowStockNames = const [],
    List<String> taskTitles = const [],
    List<OutdoorAlert> alerts = const [],
    DateTime? at,
  }) {
    final water = digest.byType[CareKind.watering.key] ?? const [];
    final others = digest.byType.entries.where((e) => e.key != CareKind.watering.key).fold(0, (s, e) => s + e.value.length);
    final parts = <String>[];
    // Le gel en tête : une notification se lit sur une ligne, et c'est la
    // seule chose qui ne peut pas attendre le lendemain.
    for (final alert in alerts) {
      final when = l10n.alertWhen(alert, at ?? DateTime.now());
      final names = l10n.namesWithMore(alert.plantNames, alert.plantCount);
      parts.add(switch (alert.kind) {
        OutdoorAlertKind.frost => l10n.notifFrost(when, names),
        OutdoorAlertKind.heat => l10n.notifHeat(when, names),
      });
    }
    if (water.length == 1) parts.add(l10n.notifWaterOne(water.first));
    if (water.length > 1) parts.add(l10n.notifWaterMany(l10n.joinNames(water.take(3).toList())));
    if (others > 0) parts.add(water.isEmpty ? l10n.notifOnlyOther(others) : l10n.notifOther(others));
    if (taskTitles.length == 1) parts.add(l10n.notifTasksOne(taskTitles.first));
    if (taskTitles.length > 1) parts.add(l10n.notifTasksMany(taskTitles.length, l10n.joinNames(taskTitles.take(2).toList())));
    if (lowStockNames.length == 1) parts.add(l10n.notifLowStockOne(lowStockNames.first));
    if (lowStockNames.length > 1) parts.add(l10n.notifLowStockMany(lowStockNames.length));
    return parts.join(' ');
  }
}

final reminderSchedulerProvider = Provider<ReminderScheduler>((ref) => ReminderScheduler(ref));
