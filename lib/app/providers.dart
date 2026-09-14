import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
import '../core/config/diagnosis_config.dart';
import '../data/services/device_location_service.dart';
import '../data/services/infomaniak_advisor.dart';
import '../data/services/infomaniak_care_completer.dart';
import '../data/services/infomaniak_cutting_refiner.dart';
import '../data/services/infomaniak_diagnoser.dart';
import '../data/services/gbif_species_service.dart';
import '../data/services/home_kit_climate_service.dart';
import '../core/config/identification_config.dart';
import '../core/config/supabase_config.dart';
import '../data/sharing/supabase_collaboration_service.dart';
import '../data/sharing/supabase_sharing_service.dart';
import '../data/problems/problem_catalog.dart';
import '../data/problems/problem_catalog_loader.dart';
import '../data/species/catalog_care_guide.dart';
import '../data/species/species_catalog.dart';
import '../data/species/species_index.dart';
import '../data/species/species_index_loader.dart';
import '../domain/sharing/garden_collaboration.dart';
import '../domain/sharing/shared_link.dart';
import '../domain/care/care_completion.dart';
import '../domain/cuttings/cutting_guide.dart';
import '../domain/care/care_guide.dart';
import '../data/services/notification_service.dart';
import '../data/services/photo_maintenance.dart';
import '../data/services/photo_storage_service.dart';
import '../data/services/open_meteo_service.dart';
import '../data/services/plantnet_identifier.dart';
import '../data/services/preferences_care_store.dart';
import '../data/services/preferences_cutting_store.dart';
import '../data/services/preferences_service.dart';
import '../data/services/store_support_service.dart';
import '../domain/auth/auth_repository.dart';
import '../domain/diagnosis/plant_diagnoser.dart';
import '../domain/home/home_climate.dart';
import '../domain/species/plant_advisor.dart';
import '../domain/species/plant_finder.dart';
import '../domain/location/location_service.dart';
import '../domain/species/species_info.dart';
import '../core/utils/scientific_name.dart';
import '../data/services/preferences_metrics_store.dart';
import '../data/services/supabase_iris_feedback_recorder.dart';
import '../domain/identification/iris_feedback.dart';
import '../data/services/local_plant_model_factory.dart';
import '../domain/identification/cascade_identifier.dart';
import '../domain/identification/identification_metrics.dart';
import '../domain/identification/local_plant_model.dart';
import '../domain/identification/plant_identifier.dart';
import '../domain/support/support_service.dart';
import '../domain/weather/weather.dart';
import '../domain/weather/weather_trend.dart';
import '../features/export/export_service.dart';
import '../features/export/import_service.dart';
import '../domain/models/models.dart';
import '../domain/repositories/repositories.dart';

/// Dépendances construites au démarrage (main.dart) et injectées par override.
final databaseProvider = Provider<FloraDatabase>((ref) => throw UnimplementedError('override in main'));
final preferencesServiceProvider = Provider<PreferencesService>((ref) => throw UnimplementedError('override in main'));
final notificationServiceProvider = Provider<NotificationService>((ref) => throw UnimplementedError('override in main'));
final authRepositoryProvider = Provider<AuthRepository>((ref) => throw UnimplementedError('override in main'));

/// Le jardin ouvert. Celui de l'appareil tant que l'utilisateur n'en a pas
/// choisi un autre ; un jardin partagé dès qu'il bascule dessus.
///
/// Tout ce qui lit ou écrit passe par lui : les dépôts se reconstruisent au
/// changement, la synchronisation change de jardin, et l'écran suivant montre
/// les plantes de l'autre.
class ActiveGarden extends Notifier<String> {
  @override
  String build() {
    final prefs = ref.watch(preferencesServiceProvider);
    // Le flux d'authentification met un instant à livrer sa première valeur ;
    // le dépôt, lui, répond tout de suite. Sans cela l'application s'ouvrirait
    // une fraction de seconde sur le mauvais jardin.
    final user = ref.watch(currentUserProvider).value ?? ref.read(authRepositoryProvider).currentUser;
    final own = prefs.gardenId!;
    // Sans compte distant, il n'y a qu'un jardin : celui de l'appareil.
    if (user == null || user.isLocal) return own;
    final active = prefs.activeGardenId;
    if (active == null || active == own) return own;
    // Un autre compte s'est connecté sur cet appareil : son jardin partagé
    // n'est pas le nôtre, on repart du jardin local.
    if (prefs.syncedAccountId != null && prefs.syncedAccountId != user.id) return own;
    return active;
  }

  /// Bascule sur un autre jardin, et s'en souvient au prochain lancement.
  Future<void> select(String gardenId) async {
    if (gardenId == state) return;
    await ref.read(preferencesServiceProvider).setActiveGardenId(gardenId);
    state = gardenId;
  }

  /// Revient au jardin de l'appareil (déconnexion, départ d'un jardin partagé).
  Future<void> reset() async {
    final prefs = ref.read(preferencesServiceProvider);
    await prefs.setActiveGardenId(null);
    state = prefs.gardenId!;
  }
}

final activeGardenProvider = NotifierProvider<ActiveGarden, String>(ActiveGarden.new);

/// Identifiant du jardin courant. Indirection volontaire : les tests le
/// surchargent par une valeur fixe, sans passer par les préférences.
final gardenIdProvider = Provider<String>((ref) => ref.watch(activeGardenProvider));

final photoStorageProvider = Provider<PhotoStorageService>((ref) => PhotoStorageService());
final photoMaintenanceProvider = Provider<PhotoMaintenance>((ref) => PhotoMaintenance(ref.watch(databaseProvider), ref.watch(photoStorageProvider)));
final analyticsProvider = Provider<Analytics>((ref) => const NoopAnalytics());
final crashReporterProvider = Provider<CrashReporter>((ref) => const NoopCrashReporter());

/// Le jardin est-il dans l'hémisphère sud ? La latitude du lieu météo le dit
/// quand il est renseigné ; sinon on suppose le nord, faute de mieux.
///
/// Sans cela, décembre serait un mois de repos à Melbourne comme à Paris :
/// les intervalles saisonniers et les repères d'arrosage tomberaient à
/// contretemps six mois par an.
final southernHemisphereProvider = Provider<bool>((ref) {
  final place = ref.watch(preferencesProvider.select((p) => p.weatherPlace));
  return place != null && place.latitude < 0;
});

/// Lu et non observé : les dépôts recalculent une échéance au moment où ils
/// écrivent, et doivent voir l'hémisphère du jour sans être reconstruits.
bool _south(Ref ref) => ref.read(southernHemisphereProvider);

final plantRepositoryProvider = Provider<PlantRepository>((ref) =>
    DriftPlantRepository(ref.watch(databaseProvider), ref.watch(gardenIdProvider), southernHemisphere: () => _south(ref), weatherTrend: () => _trend(ref)));
final locationRepositoryProvider = Provider<LocationRepository>(
    (ref) => DriftLocationRepository(ref.watch(databaseProvider), ref.watch(gardenIdProvider)));
String? _remoteUserId(Ref ref) {
  final u = ref.read(authRepositoryProvider).currentUser;
  return u == null || u.isLocal ? null : u.id;
}

// La base peut contenir plusieurs jardins depuis le partage : les dépôts qui
// interrogent les plantes de tout l'appareil (journal, galerie, routines) se
// limitent au jardin ouvert.
final actionRepositoryProvider = Provider<ActionRepository>((ref) => DriftActionRepository(ref.watch(databaseProvider),
    gardenId: ref.watch(gardenIdProvider),
    currentUserId: () => _remoteUserId(ref),
    southernHemisphere: () => _south(ref),
    weatherTrend: () => _trend(ref)));
final careRepositoryProvider = Provider<CareRepository>((ref) => DriftCareRepository(ref.watch(databaseProvider), ref.watch(plantRepositoryProvider),
    gardenId: ref.watch(gardenIdProvider), southernHemisphere: () => _south(ref), weatherTrend: () => _trend(ref)));
final photoRepositoryProvider = Provider<PhotoRepository>(
    (ref) => DriftPhotoRepository(ref.watch(databaseProvider), gardenId: ref.watch(gardenIdProvider), currentUserId: () => _remoteUserId(ref)));
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
    required this.identificationFallbackEnabled,
    required this.careAssistEnabled,
    required this.irisFeedbackEnabled,
    required this.irisFeedbackAsked,
    required this.weatherPlace,
    required this.rainCountsAsWatering,
    required this.homeSensor,
    required this.homeHumiditySensor,
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

  /// Repli Pl@ntNet autorisé quand le modèle local hésite.
  final bool identificationFallbackEnabled;

  /// Complément des fiches d'entretien par l'IA autorisé.
  final bool careAssistEnabled;

  /// Les photos identifiées partent entraîner Iris. Faux par défaut.
  final bool irisFeedbackEnabled;

  /// La question a déjà été posée, quelle qu'ait été la réponse.
  final bool irisFeedbackAsked;
  final WeatherPlace? weatherPlace;

  /// La pluie tombée sur un emplacement extérieur vaut un arrosage : la
  /// routine est notée faite au lieu d'être reportée.
  final bool rainCountsAsWatering;

  /// Le capteur d'Apple Maison qui donne le climat de l'intérieur, ou `null`
  /// tant que rien n'est branché.
  final HomeSensor? homeSensor;

  /// Le capteur qui donne l'humidité quand ce n'est pas le même ; `null`,
  /// et c'est [homeSensor] qui la donne, s'il la mesure.
  final HomeSensor? homeHumiditySensor;
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
      identificationFallbackEnabled: s.identificationFallbackEnabled,
      careAssistEnabled: s.careAssistEnabled,
      irisFeedbackEnabled: s.irisFeedbackEnabled,
      irisFeedbackAsked: s.irisFeedbackAsked,
      weatherPlace: s.weatherPlace == null ? null : WeatherPlace(name: s.weatherPlace!.name, latitude: s.weatherPlace!.lat, longitude: s.weatherPlace!.lon),
      rainCountsAsWatering: s.rainCountsAsWatering,
      homeSensor: HomeSensor.decode(s.homeSensor),
      homeHumiditySensor: HomeSensor.decode(s.homeHumiditySensor),
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
  Future<void> setIdentificationFallbackEnabled(bool value) => _apply((s) => s.setIdentificationFallbackEnabled(value));
  Future<void> setCareAssistEnabled(bool value) => _apply((s) => s.setCareAssistEnabled(value));
  Future<void> setIrisFeedbackEnabled(bool value) => _apply((s) => s.setIrisFeedbackEnabled(value));
  Future<void> setIrisFeedbackAsked() => _apply((s) => s.setIrisFeedbackAsked());
  /// Changer de lieu périme le climat mis de côté : celui de l'ancienne
  /// ville n'a plus rien à dire des plantes de la nouvelle.
  Future<void> setWeatherPlace(WeatherPlace? place) => _apply((s) async {
        await (place == null ? s.clearWeatherPlace() : s.setWeatherPlace(name: place.name, lat: place.latitude, lon: place.longitude));
        await s.clearRegionClimate();
      });
  Future<void> setRainCountsAsWatering(bool value) => _apply((s) => s.setRainCountsAsWatering(value));
  /// Le capteur de température. Retiré, il emporte celui de l'humidité :
  /// sans maison branchée, il n'y a plus rien à lire.
  Future<void> setHomeSensor(HomeSensor? sensor) => _apply((s) async {
        if (sensor == null) {
          await s.clearHomeSensor();
          await s.clearHomeHumiditySensor();
        } else {
          await s.setHomeSensor(sensor.encode());
        }
      });
  Future<void> setHomeHumiditySensor(HomeSensor? sensor) =>
      _apply((s) => sensor == null ? s.clearHomeHumiditySensor() : s.setHomeHumiditySensor(sensor.encode()));
  Future<void> setDisplayName(String name) async {
    await ref.read(authRepositoryProvider).updateDisplayName(name);
    state = _read();
  }
}

final preferencesProvider = NotifierProvider<PreferencesController, AppPreferences>(PreferencesController.new);

/// Modèle de reconnaissance embarqué (TensorFlow Lite). Sur le web, où le
/// moteur n'existe pas, la cascade passe directement au service distant.
/// Le chargement est paresseux : rien n'est lu tant qu'on n'identifie pas.
final localPlantModelProvider = Provider<LocalPlantModel>((ref) {
  final model = createLocalPlantModel();
  ref.onDispose(model.dispose);
  return model;
});

/// État du modèle embarqué : chargé ou non, et ce qu'il sait nommer.
/// Le chargement est déclenché à la lecture, ce qui permet à l'écran des
/// réglages de dire si le modèle fonctionne vraiment sur cet appareil —
/// autrement rien ne distingue « le modèle a hésité » de « le modèle n'est
/// jamais parti ».
final localModelStatusProvider = FutureProvider<LocalModelStatus>((ref) async {
  final model = ref.watch(localPlantModelProvider);
  final ready = await model.warmUp();
  return LocalModelStatus(ready: ready, version: model.version, speciesCount: model.speciesCount, error: model.loadError);
});

class LocalModelStatus {
  const LocalModelStatus({required this.ready, required this.version, required this.speciesCount, this.error});

  final bool ready;
  final String? version;
  final int speciesCount;

  /// La raison d'un échec de chargement, à montrer telle quelle.
  final String? error;
}

/// Compteurs de la cascade, persistés dans les réglages.
final identificationMetricsStoreProvider = Provider<IdentificationMetricsStore>((ref) => PreferencesMetricsStore(ref.watch(preferencesServiceProvider)));

/// Où partent les photos étiquetées en enregistrant, si elles partent :
/// nulle part sans le consentement des réglages, sans compte distant, ou
/// sans Supabase. Les trois se lisent ici, pas dans les écrans.
/// Un retour peut-il partir quelque part ? Supabase configuré et un compte
/// distant. Sans ça, demander la permission promettrait ce qu'on ne peut
/// pas tenir — la question ne se pose pas.
final irisFeedbackAvailableProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider).value;
  return SupabaseConfig.isConfigured && user != null && !user.isLocal;
});

final irisFeedbackRecorderProvider = Provider<IrisFeedbackRecorder>((ref) {
  final enabled = ref.watch(preferencesProvider.select((p) => p.irisFeedbackEnabled));
  final user = ref.watch(currentUserProvider).value;
  if (!enabled || !ref.watch(irisFeedbackAvailableProvider) || user == null) return const NoFeedbackRecorder();
  return SupabaseIrisFeedbackRecorder(Supabase.instance.client, userId: user.id);
});

/// Identification : modèle local puis Pl@ntNet en repli si une clé est
/// configurée. Sans modèle ni clé, service inactif.
final plantIdentifierProvider = Provider<PlantIdentifier>((ref) {
  const key = IdentificationConfig.plantNetApiKey;
  final fallbackEnabled = ref.watch(preferencesProvider.select((p) => p.identificationFallbackEnabled));
  final local = ref.watch(localPlantModelProvider);
  final remote = key.isEmpty ? const UnconfiguredIdentifier() as PlantIdentifier : PlantNetIdentifier(key);
  if (!local.isAvailable && !remote.isConfigured) return const UnconfiguredIdentifier();
  return CascadeIdentifier(
    local: local,
    fallback: remote,
    fallbackEnabled: fallbackEnabled,
    metrics: ref.watch(identificationMetricsStoreProvider),
    lookup: (name, language) => catalogLookup(name, ref.read(speciesIndexProvider).value, language),
  );
});

/// Identifiant interne d'une espèce si l'app la connaît : catalogue trié à
/// la main d'abord, puis catalogue étendu s'il est déjà chargé.
String? catalogPlantId(String scientificName, SpeciesIndex? index) => catalogLookup(scientificName, index, 'en')?.internalId;

/// Identifiant interne et nom courant d'une espèce, dans la langue demandée :
/// catalogue trié à la main d'abord, catalogue étendu s'il est déjà chargé.
CatalogMatch? catalogLookup(String scientificName, SpeciesIndex? index, String languageCode) {
  // Le nom accepté d'abord : six plantes sont dans nos données sous deux
  // noms (§ 12.14), et sans ce passage la même plante donne deux fiches,
  // deux identifiants internes et deux profils de soin selon la photo.
  final canonical = acceptedSpeciesName(normalizeScientificName(scientificName));
  if (canonical.isEmpty) return null;
  final curated = SpeciesCatalog.find(canonical);
  if (curated != null) {
    final name = curated.commonName(languageCode);
    return CatalogMatch(internalId: internalPlantId(canonical), commonName: name.isEmpty ? null : name);
  }
  final extended = index?.find(canonical);
  if (extended != null) {
    final name = extended.commonName(languageCode);
    return CatalogMatch(internalId: internalPlantId(canonical), commonName: name.isEmpty ? null : name);
  }
  return null;
}

final weatherServiceProvider = Provider<WeatherService>((ref) => OpenMeteoService());

/// La fenêtre météo du lieu : trois jours passés, aujourd'hui, quatre jours
/// à venir. Un seul appel sert tout — la ligne du jour, les prévisions, la
/// pluie déjà tombée, la tendance des routines et les avertissements.
/// Rafraîchie toutes les heures. Vide sans lieu, vide hors ligne.
///
/// Elle vit ici, et non dans la fonctionnalité météo, parce que les dépôts
/// en dépendent : une routine en stratégie météo recalcule son échéance au
/// moment où elle est complétée, sans rien savoir de l'écran qui l'appelle.
final weatherWindowProvider = FutureProvider<List<DailyWeather>>((ref) async {
  final place = ref.watch(preferencesProvider.select((p) => p.weatherPlace));
  if (place == null) return const [];
  final timer = Future<void>.delayed(const Duration(hours: 1), () => ref.invalidateSelf());
  ref.onDispose(() => timer.ignore());
  try {
    return await ref.watch(weatherServiceProvider).forecast(place, days: 5, pastDays: 3);
  } catch (_) {
    // Hors ligne : pas de météo, l'app reste entièrement utilisable.
    return const [];
  }
});

/// Le temps qu'il fait, réduit à ce qui change un intervalle d'arrosage.
/// `null` sans fenêtre : la stratégie météo retombe alors sur la saison.
final weatherTrendProvider = Provider<WeatherTrend?>((ref) => WeatherTrend.of(ref.watch(weatherWindowProvider).value ?? const []));

/// Lue et non observée, comme l'hémisphère : un dépôt qui écrit veut la
/// tendance du moment, pas une reconstruction à chaque bulletin.
WeatherTrend? _trend(Ref ref) => ref.read(weatherTrendProvider);

/// La position de l'appareil, pour proposer le lieu de la météo à
/// l'onboarding. Remplacée dans les tests par un service muet.
final locationServiceProvider = Provider<LocationService>((ref) => const DeviceLocationService());

/// Les capteurs d'Apple Maison, là où HomeKit existe : iPhone et iPad.
/// Ailleurs le service est muet, et l'étape comme le réglage n'apparaissent
/// pas — on ne propose pas une maison qu'on ne peut pas lire.
final homeClimateServiceProvider = Provider<HomeClimateService>((ref) {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return const UnavailableHomeClimateService();
  return HomeKitClimateService();
});

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

/// Base locale des troubles, ravageurs et maladies, chargée au premier
/// diagnostic. C'est le vocabulaire commun : ce que l'IA a le droit de
/// nommer, et le nom que l'application affiche ensuite.
final problemCatalogLoaderProvider = Provider<ProblemCatalogLoader>((ref) => ProblemCatalogLoader());
final problemCatalogProvider = FutureProvider<ProblemCatalog>((ref) => ref.watch(problemCatalogLoaderProvider).load());

final exportServiceProvider = Provider<ExportService>((ref) => ExportService(ref.watch(databaseProvider), ref.watch(photoStorageProvider)));
final importServiceProvider = Provider<ImportService>((ref) => ImportService(ref.watch(databaseProvider), ref.watch(photoStorageProvider)));

/// Diagnostic : AI Services d'Infomaniak avec la clé de l'éditeur fournie au
/// build, sans plafond ; sans clé, service inactif et entrée absente des
/// écrans.
final plantDiagnoserProvider = Provider<PlantDiagnoser>((ref) {
  if (!DiagnosisConfig.isConfigured) return const UnconfiguredDiagnoser();
  return InfomaniakDiagnoser(apiKey: DiagnosisConfig.apiKey, productId: DiagnosisConfig.productId, model: DiagnosisConfig.model);
});

/// « Trouver une plante » : le catalogue intégré et les fiches d'entretien
/// répondent seuls, hors ligne et sans appel réseau.
final plantFinderProvider = Provider<PlantFinder>(
    (ref) => PlantFinder(entries: SpeciesCatalog.entries, guide: ref.watch(careGuideProvider)));

/// Second tour de « Trouver une plante », quand le catalogue n'a rien de
/// convaincant : même clé Infomaniak que le diagnostic, appelée seulement si
/// l'utilisateur le demande. Sans clé, le bouton n'apparaît pas.
final plantAdvisorProvider = Provider<PlantAdvisor>((ref) {
  if (!DiagnosisConfig.isConfigured) return const UnconfiguredAdvisor();
  return InfomaniakAdvisor(apiKey: DiagnosisConfig.apiKey, productId: DiagnosisConfig.productId, model: DiagnosisConfig.model);
});

/// Complément des fiches d'entretien par l'IA, pour les espèces dont le
/// catalogue n'a que des repères généraux. Même clé Infomaniak que le
/// diagnostic ; sans clé, la fiche s'en tient à ce qu'elle sait.
final careCompleterProvider = Provider<CareCompleter>((ref) {
  if (!DiagnosisConfig.isConfigured) return const UnconfiguredCareCompleter();
  return InfomaniakCareCompleter(apiKey: DiagnosisConfig.apiKey, productId: DiagnosisConfig.productId, model: DiagnosisConfig.model);
});

/// Les réponses déjà obtenues, gardées sur l'appareil.
final careCompletionStoreProvider = Provider<CareCompletionStore>((ref) => PreferencesCareStore(ref.watch(preferencesServiceProvider)));

/// Ce que l'IA sait d'une espèce, ou `null` si la question ne se pose pas.
///
/// La réponse déjà obtenue est rendue telle quelle, sans réseau. Sinon, et
/// seulement si l'utilisateur laisse faire, la question part une fois, et la
/// réponse est gardée — même vide, pour ne pas la reposer.
final careCompletionProvider = FutureProvider.autoDispose.family<CareCompletion?, ({String species, String language})>((ref, q) async {
  final species = q.species.trim();
  if (species.isEmpty) return null;
  final store = ref.watch(careCompletionStoreProvider);
  final known = store.read(species, q.language);
  if (known != null) return known.isEmpty ? null : known;
  if (!ref.watch(preferencesProvider.select((p) => p.careAssistEnabled))) return null;
  final completer = ref.watch(careCompleterProvider);
  if (!completer.isConfigured) return null;
  try {
    final completion = await completer.complete(scientificName: species, language: q.language);
    await store.write(species, q.language, completion);
    return completion.isEmpty ? null : completion;
  } catch (e, st) {
    // Une fiche sans complément reste une fiche : l'échec ne se voit pas, et
    // ne se garde pas non plus, pour que la question puisse repartir plus tard.
    ref.read(crashReporterProvider).report(e, st, context: 'care.completion');
    return null;
  }
});

/// Précision des étapes du guide de bouturage par l'IA, pour l'espèce de la
/// plante mère. Même clé Infomaniak que le diagnostic ; sans clé, le guide
/// s'en tient à ses textes génériques.
final cuttingGuideRefinerProvider = Provider<CuttingGuideRefiner>((ref) {
  if (!DiagnosisConfig.isConfigured) return const UnconfiguredCuttingGuideRefiner();
  return InfomaniakCuttingRefiner(apiKey: DiagnosisConfig.apiKey, productId: DiagnosisConfig.productId, model: DiagnosisConfig.model);
});

/// Les guides déjà précisés, gardés sur l'appareil.
final cuttingGuideStoreProvider = Provider<CuttingGuideStore>((ref) => PreferencesCuttingStore(ref.watch(preferencesServiceProvider)));

/// Les étapes précisées pour une espèce, ou `null` si la question ne se pose
/// pas : espèce inconnue, IA coupée dans les réglages, ou réponse vide.
///
/// Même règle que le complément des fiches : la réponse déjà obtenue est
/// rendue telle quelle, sans réseau ; sinon, et seulement si l'utilisateur
/// laisse faire, la question part une fois et la réponse est gardée.
final cuttingGuideRefinementProvider =
    FutureProvider.autoDispose.family<CuttingGuideRefinement?, ({String species, String language})>((ref, q) async {
  final species = q.species.trim();
  if (species.isEmpty) return null;
  final store = ref.watch(cuttingGuideStoreProvider);
  final known = store.read(species, q.language);
  if (known != null) return known.isEmpty ? null : known;
  if (!ref.watch(preferencesProvider.select((p) => p.careAssistEnabled))) return null;
  final refiner = ref.watch(cuttingGuideRefinerProvider);
  if (!refiner.isConfigured) return null;
  try {
    final refinement = await refiner.refine(scientificName: species, language: q.language);
    await store.write(species, q.language, refinement);
    return refinement.isEmpty ? null : refinement;
  } catch (e, st) {
    // Un guide générique reste un guide : l'échec ne se voit pas, et ne se
    // garde pas non plus, pour que la question puisse repartir plus tard.
    ref.read(crashReporterProvider).report(e, st, context: 'cutting.guide');
    return null;
  }
});

/// Informations sur les espèces : GBIF, sans clé, avec cache en mémoire.
final speciesServiceProvider = Provider<SpeciesService>((ref) => GbifSpeciesService());

/// Partage d'un jardin entre comptes : invitations, membres, rôles.
final collaborationServiceProvider = Provider<CollaborationService>((ref) {
  if (!SupabaseConfig.isConfigured) return const UnavailableCollaborationService();
  return SupabaseCollaborationService();
});

/// Fiches d'entretien (catalogue intégré, hors ligne).
final sharingServiceProvider = Provider<SharingService>((ref) {
  if (!SupabaseConfig.isConfigured) return const UnavailableSharingService();
  return SupabaseSharingService(gardenId: ref.watch(gardenIdProvider));
});

final careGuideProvider = Provider<CareGuide>((ref) => const CatalogCareGuide());

/// Famille d'une espèce : le catalogue trié à la main d'abord, puis le
/// catalogue étendu s'il est déjà chargé. Sans lui, la fiche d'entretien
/// d'une plante hors catalogue retomberait sur le profil générique.
String? Function(String?) speciesFamilyLookup(WidgetRef ref) => _familyIn(ref.watch(speciesIndexProvider).value);

/// Même recherche depuis un provider, qui n'a qu'un `Ref`.
String? Function(String?) speciesFamilyLookupIn(Ref ref) => _familyIn(ref.watch(speciesIndexProvider).value);

/// Même recherche, mais hors `build` (initialisation d'un écran), là où
/// `watch` n'a pas cours.
String? speciesFamilyOf(WidgetRef ref, String? name) => _familyIn(ref.read(speciesIndexProvider).value)(name);

String? Function(String?) _familyIn(SpeciesIndex? index) {
  return (name) {
    if (name == null || name.trim().isEmpty) return null;
    final curated = SpeciesCatalog.find(name)?.family;
    if (curated != null) return curated;
    final found = index?.find(name)?.family;
    return found == null || found.isEmpty ? null : found;
  };
}
