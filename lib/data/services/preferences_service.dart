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

  /// L'utilisateur a-t-il déjà soutenu le développeur ? Ne déverrouille rien :
  /// sert seulement à ne plus lui proposer, et à dire merci.
  bool get hasSupported => _prefs.getBool('has_supported') ?? false;
  Future<void> setSupported(bool value) => _prefs.setBool('has_supported', value);

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

  /// Dernier tri choisi dans la liste des plantes, restauré au lancement.
  String get plantSort => _prefs.getString('plant_sort') ?? 'name';
  Future<void> setPlantSort(String value) => _prefs.setString('plant_sort', value);

  /// Nom donné aux archives par l'utilisateur (« Mémorial », « Le passé »…).
  /// Vide = le libellé traduit par défaut.
  String get archiveName => _prefs.getString('archive_name') ?? '';
  Future<void> setArchiveName(String value) => _prefs.setString('archive_name', value.trim());

  /// Tri et vue des archives, mémorisés d'une session à l'autre.
  String get archiveSort => _prefs.getString('archive_sort') ?? 'archivedDesc';
  Future<void> setArchiveSort(String value) => _prefs.setString('archive_sort', value);

  bool get archiveGridView => _prefs.getBool('archive_grid_view') ?? false;
  Future<void> setArchiveGridView(bool value) => _prefs.setBool('archive_grid_view', value);

  /// Ce que le carrousel « dernières plantes » du tableau de bord montre :
  /// les dernières ajoutées, ou les dernières modifiées.
  String get recentPlantsMode => _prefs.getString('recent_plants_mode') ?? 'added';
  Future<void> setRecentPlantsMode(String value) => _prefs.setString('recent_plants_mode', value);

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

  /// Lieu météo : « nom|lat|lon ».
  ({String name, double lat, double lon})? get weatherPlace {
    final raw = _prefs.getString('weather_place');
    if (raw == null) return null;
    final parts = raw.split('|');
    if (parts.length != 3) return null;
    final lat = double.tryParse(parts[1]);
    final lon = double.tryParse(parts[2]);
    if (lat == null || lon == null) return null;
    return (name: parts[0], lat: lat, lon: lon);
  }

  Future<void> setWeatherPlace({required String name, required double lat, required double lon}) =>
      _prefs.setString('weather_place', '${name.replaceAll('|', ' ')}|$lat|$lon');
  Future<void> clearWeatherPlace() => _prefs.remove('weather_place');

  // Synchronisation
  DateTime? syncCursor(String table) {
    final raw = _prefs.getString('sync_cursor_$table');
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<void> setSyncCursor(String table, DateTime value) => _prefs.setString('sync_cursor_$table', value.toUtc().toIso8601String());

  Future<void> clearSyncCursors() async {
    for (final k in _prefs.getKeys().where((k) => k.startsWith('sync_cursor_')).toList()) {
      await _prefs.remove(k);
    }
  }

  String? get syncedAccountId => _prefs.getString('synced_account_id');
  Future<void> setSyncedAccountId(String id) => _prefs.setString('synced_account_id', id);

  String get anthropicApiKey => _prefs.getString('anthropic_api_key') ?? '';
  Future<void> setAnthropicApiKey(String key) => _prefs.setString('anthropic_api_key', key.trim());

  String get plantNetApiKey => _prefs.getString('plantnet_api_key') ?? '';
  Future<void> setPlantNetApiKey(String key) => _prefs.setString('plantnet_api_key', key.trim());

  bool get notificationPromptShown => _prefs.getBool('notification_prompt_shown') ?? false;
  Future<void> setNotificationPromptShown() => _prefs.setBool('notification_prompt_shown', true);
}
