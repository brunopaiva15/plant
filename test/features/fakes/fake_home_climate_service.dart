import 'package:flora/domain/home/home_climate.dart';

/// Une maison de laboratoire : des capteurs donnés d'avance, une mesure
/// fixe, et le compte des lectures.
class FakeHomeClimateService implements HomeClimateService {
  FakeHomeClimateService({this.supported = true, this.sensorList = const [], this.reading, this.readings = const {}, this.accessValue = HomeAccess.authorized});

  final bool supported;
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
  Future<HomeReading?> read(String sensorId) async {
    readCalls++;
    return readings.containsKey(sensorId) ? readings[sensorId] : reading;
  }
}
