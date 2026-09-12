/// Le climat de la maison, lu sur les capteurs d'Apple Maison.
///
/// La météo dit ce qu'il fait dehors ; les plantes d'intérieur, elles,
/// vivent dans un salon à 21° et 35 % d'humidité, et c'est cela qui compte
/// pour un calathea. Un capteur HomeKit le mesure déjà : l'application le
/// lit, sans rien y ajouter.
library;

/// Un capteur de la maison : un accessoire qui mesure la température, l'humidité
/// de l'air, ou les deux.
class HomeSensor {
  const HomeSensor({required this.id, required this.name, this.roomName, this.homeName, this.hasTemperature = true, this.hasHumidity = true});

  /// Identifiant stable de l'accessoire, celui de HomeKit.
  final String id;
  final String name;

  /// La pièce où Apple Maison le range, s'il en a une.
  final String? roomName;
  final String? homeName;
  final bool hasTemperature;
  final bool hasHumidity;

  bool measures(HomeQuantity q) => q == HomeQuantity.temperature ? hasTemperature : hasHumidity;

  /// Le nom sous lequel il s'affiche : la pièce quand elle est connue, sinon
  /// l'accessoire lui-même.
  String get label => roomName?.trim().isNotEmpty == true ? roomName!.trim() : name;

  /// Sérialisation compacte pour les préférences (`id|nom|pièce|maison`).
  String encode() => [id, name, roomName ?? '', homeName ?? ''].map((s) => s.replaceAll('|', ' ')).join('|');

  /// Deux capteurs sont le même s'ils portent le même identifiant, le même
  /// nom, la même pièce et la même maison : les préférences relisent le leur à chaque
  /// changement, et un `select` ne doit pas y voir un capteur neuf.
  @override
  bool operator ==(Object other) => other is HomeSensor && other.id == id && other.name == name && other.roomName == roomName && other.homeName == homeName;

  @override
  int get hashCode => Object.hash(id, name, roomName, homeName);

  static HomeSensor? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split('|');
    if (parts.length < 2 || parts[0].isEmpty) return null;
    final room = parts.length > 2 ? parts[2] : '';
    final home = parts.length > 3 ? parts[3] : '';
    return HomeSensor(id: parts[0], name: parts[1], roomName: room.isEmpty ? null : room, homeName: home.isEmpty ? null : home);
  }
}

/// Ce qu'un capteur mesure, et ce qu'on lui demande.
enum HomeQuantity { temperature, humidity }

/// Une mesure, au moment où elle a été lue.
class HomeReading {
  const HomeReading({required this.at, this.temperatureC, this.humidity, this.sensor, this.humiditySensor});

  final DateTime at;

  /// Température de l'air (°C), ou `null` si le capteur ne la donne pas.
  final double? temperatureC;

  /// Humidité relative (0–100), ou `null` si le capteur ne la donne pas.
  final int? humidity;

  /// Le capteur de température, dont la pièce donne son nom à la mesure.
  final HomeSensor? sensor;

  /// Le capteur d'humidité, quand ce n'est pas le même.
  final HomeSensor? humiditySensor;

  bool get isEmpty => temperatureC == null && humidity == null;
}

/// Ce que HomeKit laisse faire.
enum HomeAccess {
  /// Pas encore demandé : la première lecture ouvrira la demande du système.
  notDetermined,

  /// Accordé.
  authorized,

  /// Refusé, ou restreint par un profil : se règle dans Réglages › Confidentialité.
  denied,

  /// Pas de HomeKit ici (Android, web, simulateur sans maison).
  unavailable,
}

/// Lecture des capteurs de la maison.
abstract class HomeClimateService {
  /// Vrai là où Apple Maison existe : iPhone et iPad.
  bool get isSupported;

  Future<HomeAccess> access();

  /// Les capteurs de toutes les maisons, ou une liste vide sans accès.
  /// Le premier appel déclenche la demande d'accès du système.
  Future<List<HomeSensor>> sensors();

  /// La mesure d'un capteur, ou `null` s'il ne répond pas.
  Future<HomeReading?> read(String sensorId);
}

class UnavailableHomeClimateService implements HomeClimateService {
  const UnavailableHomeClimateService();

  @override
  bool get isSupported => false;

  @override
  Future<HomeAccess> access() async => HomeAccess.unavailable;

  @override
  Future<List<HomeSensor>> sensors() async => const [];

  @override
  Future<HomeReading?> read(String sensorId) async => null;
}
