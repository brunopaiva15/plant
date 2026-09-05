import '../../domain/identification/identification_metrics.dart';
import 'preferences_service.dart';

/// Compteurs d'identification persistés dans les réglages de l'appareil.
class PreferencesMetricsStore implements IdentificationMetricsStore {
  PreferencesMetricsStore(this._service);

  final PreferencesService _service;
  IdentificationMetrics? _cached;

  @override
  IdentificationMetrics read() => _cached ??= IdentificationMetrics.decode(_service.identificationMetrics);

  @override
  Future<void> write(IdentificationMetrics metrics) {
    _cached = metrics;
    return _service.setIdentificationMetrics(metrics.encode());
  }
}
