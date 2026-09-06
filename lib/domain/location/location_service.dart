import '../weather/weather.dart';

/// Où sont les plantes de l'utilisateur, d'après l'appareil.
///
/// Sert une seule fois, à l'onboarding, pour proposer le lieu de la météo
/// sans rien taper. Le lieu retenu est une ville et deux coordonnées
/// arrondies ; la position exacte n'est ni gardée ni envoyée.
abstract class LocationService {
  /// Le lieu courant, ou `null` si l'utilisateur refuse, si la position est
  /// coupée, ou si l'appareil ne sait pas la donner.
  Future<WeatherPlace?> currentPlace({String? language});
}

class UnavailableLocationService implements LocationService {
  const UnavailableLocationService();

  @override
  Future<WeatherPlace?> currentPlace({String? language}) async => null;
}
