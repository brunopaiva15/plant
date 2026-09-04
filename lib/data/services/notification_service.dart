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

  Future<void> cancelAll() => _plugin.cancelAll();
}
