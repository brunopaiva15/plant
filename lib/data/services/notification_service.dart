import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Notifications locales. Une seule notification quotidienne, groupée, à
/// l'heure choisie par l'utilisateur.
class NotificationService {
  NotificationService();

  final _plugin = FlutterLocalNotificationsPlugin();
  static const _dailyId = 1;

  /// Les rappels d'événements occupent leurs propres identifiants, pour être
  /// remplacés sans toucher à la notification quotidienne.
  static const _eventIdBase = 1000;
  static const _maxEventReminders = 32;
  static const _channelId = 'care_reminders';

  /// Callback quand l'utilisateur ouvre une notification (payload = route).
  void Function(String? payload)? onOpen;

  Future<void> init() async {
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // Fuseau inconnu : on reste sur UTC, les rappels restent fonctionnels.
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) => onOpen?.call(response.payload),
    );
  }

  /// Demande la permission (appelée en contexte, jamais au lancement).
  Future<bool> requestPermission() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      return await ios?.requestPermissions(alert: true, badge: true, sound: true) ?? false;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      return await android?.requestNotificationsPermission() ?? false;
    }
    return false;
  }

  /// Planifie (ou remplace) la notification quotidienne.
  Future<void> scheduleDaily({
    required DateTime at,
    required String title,
    required String body,
    required String channelName,
    String? payload,
  }) async {
    await _plugin.cancel(id: _dailyId);
    final scheduled = tz.TZDateTime.from(at, tz.local);
    await _plugin.zonedSchedule(
      id: _dailyId,
      scheduledDate: scheduled,
      title: title,
      body: body,
      payload: payload,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          channelName,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          styleInformation: BigTextStyleInformation(body),
        ),
        iOS: const DarwinNotificationDetails(interruptionLevel: InterruptionLevel.active),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  /// Remplace tous les rappels d'événements par [reminders], au plus
  /// [_maxEventReminders] : au-delà, le système en oublierait de toute façon.
  Future<void> scheduleEventReminders(List<ScheduledReminder> reminders, {required String channelName}) async {
    for (var i = 0; i < _maxEventReminders; i++) {
      await _plugin.cancel(id: _eventIdBase + i);
    }
    final now = DateTime.now();
    final upcoming = reminders.where((r) => r.at.isAfter(now)).take(_maxEventReminders).toList();
    for (final (i, r) in upcoming.indexed) {
      await _plugin.zonedSchedule(
        id: _eventIdBase + i,
        scheduledDate: tz.TZDateTime.from(r.at, tz.local),
        title: r.title,
        body: r.body,
        payload: r.payload,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            channelName,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            styleInformation: BigTextStyleInformation(r.body),
          ),
          iOS: const DarwinNotificationDetails(interruptionLevel: InterruptionLevel.active),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  Future<void> cancelAll() => _plugin.cancelAll();
}

/// Un rappel ponctuel à planifier (événement de calendrier).
class ScheduledReminder {
  const ScheduledReminder({required this.at, required this.title, required this.body, this.payload});

  final DateTime at;
  final String title;
  final String body;
  final String? payload;
}
