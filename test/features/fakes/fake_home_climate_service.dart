import 'package:flora/domain/home/home_climate.dart';

/// Une maison de laboratoire : des capteurs donnés d'avance, une mesure
/// fixe, et le compte des lectures. Une seule plateforme, celle de [source]
/// — pour en éprouver deux, [MultiHomeClimateService] en assemble deux.
class FakeHomeClimateService extends SingleHomeClimateService {
  FakeHomeClimateService({
    this.supported = true,
    this.source = HomeSource.apple,
    this.sensorList = const [],
    this.reading,
    this.readings = const {},
    this.accessValue = HomeAccess.authorized,
  });

  final bool supported;

  @override
  final HomeSource source;

  final List<HomeSensor> sensorList;

  /// La mesure rendue pour tout capteur, à défaut d'une entrée dans [readings].
  final HomeReading? reading;

  /// Une mesure par identifiant de capteur.
  final Map<String, HomeReading?> readings;
  final HomeAccess accessValue;
  int sensorCalls = 0;
  int readCalls = 0;

  @override
  bool get isSupported => supported;

  @override
  Future<HomeAccess> access() async => accessValue;

  @override
  Future<List<HomeSensor>> sensors() async {
    sensorCalls++;
    return sensorList;
  }

  @override
  Future<HomeReading?> read(HomeSensor sensor) async {
    readCalls++;
    return readings.containsKey(sensor.id) ? readings[sensor.id] : reading;
  }
}
