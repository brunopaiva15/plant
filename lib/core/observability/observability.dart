/// Interfaces d'observabilité. Implémentations no-op en Phase 1.
///
/// Aucune donnée privée (notes, photos, noms) ne doit transiter par ces
/// interfaces. Les événements portent uniquement des identifiants techniques.
abstract class Analytics {
  void track(String event, [Map<String, Object?> properties = const {}]);
}

abstract class CrashReporter {
  void report(Object error, StackTrace stackTrace, {String? context});
}

class NoopAnalytics implements Analytics {
  const NoopAnalytics();
  @override
  void track(String event, [Map<String, Object?> properties = const {}]) {}
}

class NoopCrashReporter implements CrashReporter {
  const NoopCrashReporter();
  @override
  void report(Object error, StackTrace stackTrace, {String? context}) {}
}

/// Noms d'événements analytics (stables, snake_case).
abstract final class AnalyticsEvents {
  static const plantCreated = 'plant_created';
  static const wateringLogged = 'watering_logged';
  static const actionLogged = 'action_logged';
  static const photoAdded = 'photo_added';
  static const locationCreated = 'location_created';
  static const reminderCompleted = 'reminder_completed';
  static const plantArchived = 'plant_archived';
}
