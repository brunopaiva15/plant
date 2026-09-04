import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/observability/observability.dart';
import '../data/db/database.dart';
import '../data/repositories/action_repository_impl.dart';
import '../data/repositories/action_type_repository_impl.dart';
import '../data/repositories/calendar_repository_impl.dart';
import '../data/repositories/care_repository_impl.dart';
import '../data/repositories/inventory_repository_impl.dart';
import '../data/repositories/measurement_repository_impl.dart';
import '../data/repositories/location_repository_impl.dart';
import '../data/repositories/photo_repository_impl.dart';
import '../data/repositories/plant_repository_impl.dart';
import '../data/repositories/tag_repository_impl.dart';
import '../data/repositories/attachment_repository_impl.dart';
import '../data/repositories/attribute_repository_impl.dart';
import '../data/repositories/task_repository_impl.dart';
import '../data/services/anthropic_diagnoser.dart';
import '../data/services/gbif_species_service.dart';
import '../core/config/supabase_config.dart';
import '../data/sharing/supabase_sharing_service.dart';
import '../data/species/catalog_care_guide.dart';
import '../data/species/species_catalog.dart';
import '../data/species/species_index.dart';
import '../data/species/species_index_loader.dart';
import '../domain/sharing/shared_link.dart';
import '../domain/care/care_guide.dart';
import '../data/services/notification_service.dart';
import '../data/services/photo_storage_service.dart';
import '../data/services/open_meteo_service.dart';
import '../data/services/plantnet_identifier.dart';
import '../data/services/preferences_service.dart';
import '../data/services/store_support_service.dart';
import '../domain/auth/auth_repository.dart';
import '../domain/diagnosis/plant_diagnoser.dart';
import '../domain/species/species_info.dart';
import '../domain/identification/plant_identifier.dart';
import '../domain/support/support_service.dart';
import '../domain/weather/weather.dart';
import '../features/export/export_service.dart';
import '../features/export/import_service.dart';
import '../domain/models/models.dart';
import '../domain/repositories/repositories.dart';

/// Dépendances construites au démarrage (main.dart) et injectées par override.
final databaseProvider = Provider<FloraDatabase>((ref) => throw UnimplementedError('override in main'));
final preferencesServiceProvider = Provider<PreferencesService>((ref) => throw UnimplementedError('override in main'));
final notificationServiceProvider = Provider<NotificationService>((ref) => throw UnimplementedError('override in main'));
final authRepositoryProvider = Provider<AuthRepository>((ref) => throw UnimplementedError('override in main'));
final gardenIdProvider = Provider<String>((ref) => throw UnimplementedError('override in main'));

final photoStorageProvider = Provider<PhotoStorageService>((ref) => PhotoStorageService());
final analyticsProvider = Provider<Analytics>((ref) => const NoopAnalytics());
final crashReporterProvider = Provider<CrashReporter>((ref) => const NoopCrashReporter());

final plantRepositoryProvider =
    Provider<PlantRepository>((ref) => DriftPlantRepository(ref.watch(databaseProvider), ref.watch(gardenIdProvider)));
final locationRepositoryProvider = Provider<LocationRepository>(
    (ref) => DriftLocationRepository(ref.watch(databaseProvider), ref.watch(gardenIdProvider)));
String? _remoteUserId(Ref ref) {
  final u = ref.read(authRepositoryProvider).currentUser;
  return u == null || u.isLocal ? null : u.id;
}

final actionRepositoryProvider =
    Provider<ActionRepository>((ref) => DriftActionRepository(ref.watch(databaseProvider), currentUserId: () => _remoteUserId(ref)));
final careRepositoryProvider =
    Provider<CareRepository>((ref) => DriftCareRepository(ref.watch(databaseProvider), ref.watch(plantRepositoryProvider)));
final photoRepositoryProvider = Provider<PhotoRepository>((ref) => DriftPhotoRepository(ref.watch(databaseProvider), currentUserId: () => _remoteUserId(ref)));
final actionTypeRepositoryProvider =
    Provider<ActionTypeRepository>((ref) => DriftActionTypeRepository(ref.watch(databaseProvider)));
final measurementRepositoryProvider =
    Provider<MeasurementRepository>((ref) => DriftMeasurementRepository(ref.watch(databaseProvider)));
final inventoryRepositoryProvider =
    Provider<InventoryRepository>((ref) => DriftInventoryRepository(ref.watch(databaseProvider), ref.watch(gardenIdProvider)));
final attachmentRepositoryProvider = Provider<AttachmentRepository>(
    (ref) => DriftAttachmentRepository(ref.watch(databaseProvider), ref.watch(gardenIdProvider), currentUserId: () => _remoteUserId(ref)));
final attributeRepositoryProvider = Provider<AttributeRepository>((ref) => DriftAttributeRepository(ref.watch(databaseProvider), ref.watch(gardenIdProvider)));
final taskRepositoryProvider = Provider<TaskRepository>((ref) => DriftTaskRepository(ref.watch(databaseProvider), ref.watch(gardenIdProvider)));
final tagRepositoryProvider =
    Provider<TagRepository>((ref) => DriftTagRepository(ref.watch(databaseProvider), ref.watch(gardenIdProvider)));
final calendarRepositoryProvider =
    Provider<CalendarRepository>((ref) => DriftCalendarRepository(ref.watch(databaseProvider), ref.watch(gardenIdProvider)));

/// Utilisateur courant (compte local en Phase 1).
final currentUserProvider = StreamProvider<AppUser?>((ref) => ref.watch(authRepositoryProvider).watchUser());

/// Types d'action (intégrés + personnalisés), indexés par clé.
final actionTypesProvider = StreamProvider<List<ActionType>>((ref) => ref.watch(actionTypeRepositoryProvider).watchAll());
final actionTypeByKeyProvider = Provider<Map<String, ActionType>>((ref) {
  final types = ref.watch(actionTypesProvider).value ?? const [];
  return {for (final t in types) t.key: t};
});

final locationsProvider = StreamProvider<List<Location>>((ref) => ref.watch(locationRepositoryProvider).watchAll());
final locationTreeProvider = StreamProvider<List<LocationNode>>((ref) => ref.watch(locationRepositoryProvider).watchTree());
final tagsProvider = StreamProvider<List<Tag>>((ref) => ref.watch(tagRepositoryProvider).watchAll());
final eventCategoriesProvider = StreamProvider<List<EventCategory>>((ref) => ref.watch(calendarRepositoryProvider).watchCategories());
final activePlantCountProvider = StreamProvider<int>((ref) => ref.watch(plantRepositoryProvider).watchActiveCount());

/// Réglages réactifs (thème, langue, notifications…).
class AppPreferences {
  const AppPreferences({
    required this.themeMode,
    required this.reduceMotion,
    required this.locale,
    required this.metricUnits,
    required this.gridView,
    required this.notificationsEnabled,
    required this.notificationTime,
    required this.quietWeekdays,
    required this.onboardingDone,
    required this.hasSupported,
    required this.displayName,
    required this.plantNetApiKey,
    required this.anthropicApiKey,
    required this.weatherPlace,
    required this.archiveName,
  });

  final ThemeMode themeMode;
  final bool? reduceMotion;
  final Locale? locale;
  final bool metricUnits;
  final bool gridView;
  final bool notificationsEnabled;
  final TimeOfDay notificationTime;
  final Set<int> quietWeekdays;
  final bool onboardingDone;

  /// L'utilisateur a déjà soutenu le développeur. Ne change rien à ce que
  /// l'application sait faire : tout y est, pour tout le monde.
  final bool hasSupported;
  final String displayName;
  final String plantNetApiKey;
  final String anthropicApiKey;
  final WeatherPlace? weatherPlace;

  /// Nom donné aux archives, vide si l'utilisateur garde celui par défaut.
  final String archiveName;
}

class PreferencesController extends Notifier<AppPreferences> {
  PreferencesService get _service => ref.read(preferencesServiceProvider);

  @override
  AppPreferences build() => _read();

  AppPreferences _read() {
    final s = _service;
    final code = s.localeCode;
    return AppPreferences(
      themeMode: s.themeMode,
      reduceMotion: s.reduceMotion,
      locale: code == null ? null : Locale(code),
      metricUnits: s.metricUnits,
      gridView: s.gridView,
      notificationsEnabled: s.notificationsEnabled,
      notificationTime: s.notificationTime,
      quietWeekdays: s.quietWeekdays,
      onboardingDone: s.onboardingDone,
      hasSupported: s.hasSupported,
      displayName: s.displayName ?? '',
      plantNetApiKey: s.plantNetApiKey,
      anthropicApiKey: s.anthropicApiKey,
      weatherPlace: s.weatherPlace == null ? null : WeatherPlace(name: s.weatherPlace!.name, latitude: s.weatherPlace!.lat, longitude: s.weatherPlace!.lon),
      archiveName: s.archiveName,
    );
  }

  Future<void> _apply(Future<void> Function(PreferencesService s) write) async {
    await write(_service);
    state = _read();
  }

  Future<void> setThemeMode(ThemeMode mode) => _apply((s) => s.setThemeMode(mode));
  Future<void> setReduceMotion(bool? value) => _apply((s) => s.setReduceMotion(value));
  Future<void> setLocale(Locale? locale) => _apply((s) => s.setLocaleCode(locale?.languageCode));
  Future<void> setMetricUnits(bool value) => _apply((s) => s.setMetricUnits(value));
  Future<void> setGridView(bool value) => _apply((s) => s.setGridView(value));
  Future<void> setNotificationsEnabled(bool value) => _apply((s) => s.setNotificationsEnabled(value));
  Future<void> setNotificationTime(TimeOfDay time) => _apply((s) => s.setNotificationTime(time));
  Future<void> setQuietWeekdays(Set<int> days) => _apply((s) => s.setQuietWeekdays(days));
  Future<void> setOnboardingDone() => _apply((s) => s.setOnboardingDone());
  Future<void> setSupported(bool value) => _apply((s) => s.setSupported(value));
  Future<void> setPlantNetApiKey(String key) => _apply((s) => s.setPlantNetApiKey(key));
  Future<void> setAnthropicApiKey(String key) => _apply((s) => s.setAnthropicApiKey(key));
  Future<void> setWeatherPlace(WeatherPlace? place) => _apply(
        (s) => place == null ? s.clearWeatherPlace() : s.setWeatherPlace(name: place.name, lat: place.latitude, lon: place.longitude),
      );
  Future<void> setArchiveName(String name) => _apply((s) => s.setArchiveName(name));
  Future<void> setDisplayName(String name) async {
    await ref.read(authRepositoryProvider).updateDisplayName(name);
    state = _read();
  }
}

final preferencesProvider = NotifierProvider<PreferencesController, AppPreferences>(PreferencesController.new);

/// Identification : Pl@ntNet si une clé est configurée, sinon service inactif.
final plantIdentifierProvider = Provider<PlantIdentifier>((ref) {
  final key = ref.watch(preferencesProvider.select((p) => p.plantNetApiKey));
  return key.isEmpty ? const UnconfiguredIdentifier() : PlantNetIdentifier(key);
});

final weatherServiceProvider = Provider<WeatherService>((ref) => OpenMeteoService());

/// Soutien facultatif : le magasin de la plateforme là où il y en a un.
/// Ailleurs — le web, le bureau, les tests — l'offre est simplement absente.
final supportServiceProvider = Provider<SupportService>((ref) {
  final service = kIsWeb
      ? const NoStoreSupport()
      : switch (defaultTargetPlatform) {
          TargetPlatform.iOS || TargetPlatform.android => StoreSupportService(PluginPurchaseStore()),
          _ => const NoStoreSupport(),
        };
  ref.onDispose(service.dispose);
  return service;
});

/// L'offre du magasin, prix compris, ou `null` si l'achat n'est pas proposé.
final supportOfferProvider = FutureProvider<SupportOffer?>((ref) => ref.watch(supportServiceProvider).offer());

/// Catalogue étendu d'espèces, chargé à la première recherche seulement.
final speciesIndexLoaderProvider = Provider<SpeciesIndexLoader>((ref) => SpeciesIndexLoader());
final speciesIndexProvider = FutureProvider<SpeciesIndex>((ref) => ref.watch(speciesIndexLoaderProvider).load());

final exportServiceProvider = Provider<ExportService>((ref) => ExportService(ref.watch(databaseProvider), ref.watch(photoStorageProvider)));
final importServiceProvider = Provider<ImportService>((ref) => ImportService(ref.watch(databaseProvider), ref.watch(photoStorageProvider)));

/// Diagnostic : API Claude si une clé est configurée, sinon service inactif.
final plantDiagnoserProvider = Provider<PlantDiagnoser>((ref) {
  final key = ref.watch(preferencesProvider.select((p) => p.anthropicApiKey));
  return key.isEmpty ? const UnconfiguredDiagnoser() : AnthropicDiagnoser(key);
});

/// Informations sur les espèces : GBIF, sans clé, avec cache en mémoire.
final speciesServiceProvider = Provider<SpeciesService>((ref) => GbifSpeciesService());

/// Fiches d'entretien (catalogue intégré, hors ligne).
final sharingServiceProvider = Provider<SharingService>((ref) {
  if (!SupabaseConfig.isConfigured) return const UnavailableSharingService();
  return SupabaseSharingService(gardenId: ref.watch(gardenIdProvider));
});

final careGuideProvider = Provider<CareGuide>((ref) => const CatalogCareGuide());

/// Famille d'une espèce : le catalogue trié à la main d'abord, puis le
/// catalogue étendu s'il est déjà chargé. Sans lui, la fiche d'entretien
/// d'une plante hors catalogue retomberait sur le profil générique.
String? Function(String?) speciesFamilyLookup(WidgetRef ref) {
  final index = ref.watch(speciesIndexProvider).value;
  return (name) {
    if (name == null || name.trim().isEmpty) return null;
    final curated = SpeciesCatalog.find(name)?.family;
    if (curated != null) return curated;
    final found = index?.find(name)?.family;
    return found == null || found.isEmpty ? null : found;
  };
}
