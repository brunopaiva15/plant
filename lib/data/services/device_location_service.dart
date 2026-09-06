import 'dart:ui' show Locale;

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../../domain/location/location_service.dart';
import '../../domain/weather/weather.dart';

/// La position de l'appareil, arrondie, et le nom de la ville qui va avec.
///
/// Précision basse : la météo se joue à l'échelle d'une ville, et demander
/// moins précis, c'est demander moins. Les coordonnées gardées sont
/// arrondies au centième de degré, soit un kilomètre. Le nom vient du
/// géocodeur du système ; s'il n'en a pas, un libellé neutre.
class DeviceLocationService implements LocationService {
  const DeviceLocationService({this.fallbackName = 'Ma position'});

  final String fallbackName;

  @override
  Future<WeatherPlace?> currentPlace({String? language}) async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return null;
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.low, timeLimit: Duration(seconds: 15)),
    );
    final lat = _round(position.latitude);
    final lon = _round(position.longitude);
    return WeatherPlace(name: await _nameOf(lat, lon, language) ?? fallbackName, latitude: lat, longitude: lon);
  }

  static double _round(double v) => (v * 100).round() / 100;

  Future<String?> _nameOf(double lat, double lon, String? language) async {
    try {
      final marks = await Geocoding(locale: language == null ? null : Locale(language)).placemarkFromCoordinates(lat, lon);
      for (final m in marks) {
        for (final candidate in [m.locality, m.subAdministrativeArea, m.administrativeArea]) {
          final city = candidate?.trim() ?? '';
          if (city.isEmpty) continue;
          final country = m.country?.trim() ?? '';
          return country.isEmpty ? city : '$city, $country';
        }
      }
    } on Object {
      // Le géocodeur manque (web) ou échoue : le lieu garde un libellé neutre.
    }
    return null;
  }
}
