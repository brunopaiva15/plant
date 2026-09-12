import 'package:flora/domain/home/home_climate.dart';

/// Une maison de laboratoire : des capteurs donnés d'avance, une mesure
/// fixe, et le compte des lectures.
class FakeHomeClimateService implements HomeClimateService {
  FakeHomeClimateService({this.supported = true, this.sensorList = const [], this.reading, this.accessValue = HomeAccess.authorized});

  final bool supported;
  final List<HomeSensor> sensorList;
  final HomeReading? reading;
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
    return reading;
  }
}
