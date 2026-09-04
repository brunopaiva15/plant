import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Réglages utilisateur persistés localement.
class PreferencesService {
  PreferencesService(this._prefs);

  final SharedPreferences _prefs;

  static Future<PreferencesService> load() async => PreferencesService(await SharedPreferences.getInstance());

  // Identité locale
  String? get userId => _prefs.getString('user_id');
  String? get gardenId => _prefs.getString('garden_id');
  Future<void> setIdentity({required String userId, required String gardenId}) async {
    await _prefs.setString('user_id', userId);
    await _prefs.setString('garden_id', gardenId);
  }

  String? get displayName => _prefs.getString('display_name');
  Future<void> setDisplayName(String value) => _prefs.setString('display_name', value);

  bool get onboardingDone => _prefs.getBool('onboarding_done') ?? false;
  Future<void> setOnboardingDone() => _prefs.setBool('onboarding_done', true);

  ThemeMode get themeMode => ThemeMode.values.byName(_prefs.getString('theme_mode') ?? 'system');
  Future<void> setThemeMode(ThemeMode mode) => _prefs.setString('theme_mode', mode.name);

  /// `null` = suivre le réglage système.
  bool? get reduceMotion => _prefs.getBool('reduce_motion');
  Future<void> setReduceMotion(bool? value) =>
      value == null ? _prefs.remove('reduce_motion') : _prefs.setBool('reduce_motion', value);

  String? get localeCode => _prefs.getString('locale');
  Future<void> setLocaleCode(String? code) => code == null ? _prefs.remove('locale') : _prefs.setString('locale', code);

  bool get metricUnits => _prefs.getBool('metric_units') ?? true;
  Future<void> setMetricUnits(bool value) => _prefs.setBool('metric_units', value);

  bool get gridView => _prefs.getBool('grid_view') ?? true;
  Future<void> setGridView(bool value) => _prefs.setBool('grid_view', value);

  // Notifications
  bool get notificationsEnabled => _prefs.getBool('notifications_enabled') ?? false;
  Future<void> setNotificationsEnabled(bool value) => _prefs.setBool('notifications_enabled', value);

  TimeOfDay get notificationTime => TimeOfDay(
        hour: _prefs.getInt('notification_hour') ?? 9,
        minute: _prefs.getInt('notification_minute') ?? 0,
      );
  Future<void> setNotificationTime(TimeOfDay time) async {
    await _prefs.setInt('notification_hour', time.hour);
    await _prefs.setInt('notification_minute', time.minute);
  }

  /// Jours sans notification (1 = lundi … 7 = dimanche).
  Set<int> get quietWeekdays => (_prefs.getStringList('quiet_weekdays') ?? const []).map(int.parse).toSet();
  Future<void> setQuietWeekdays(Set<int> days) =>
      _prefs.setStringList('quiet_weekdays', days.map((d) => d.toString()).toList());

  bool get notificationPromptShown => _prefs.getBool('notification_prompt_shown') ?? false;
  Future<void> setNotificationPromptShown() => _prefs.setBool('notification_prompt_shown', true);
}
