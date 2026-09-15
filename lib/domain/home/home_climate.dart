/// Le climat de la maison, lu sur les capteurs d'Apple Maison ou de Google
/// Home.
///
/// La météo dit ce qu'il fait dehors ; les plantes d'intérieur, elles,
/// vivent dans un salon à 21° et 35 % d'humidité, et c'est cela qui compte
/// pour un calathea. Un capteur de la maison le mesure déjà : l'application
/// le lit, sans rien y ajouter.
library;

/// La maison d'où vient un capteur.
///
/// Les deux plateformes rendent la même chose — une température, une
/// humidité, une pièce, une maison — et l'application ne les distingue que
/// pour deux raisons : savoir à qui redemander la mesure, et savoir où
/// l'accès se rouvre quand il a été refusé.
enum HomeSource {
  /// Apple Maison, par HomeKit : iPhone et iPad.
  apple,

  /// Google Home, par les Home APIs : iPhone et Android.
  google;

  /// La maison gardée dans les préférences. Une préférence écrite avant que
  /// Google Home existe ici ne dit rien : c'était Apple Maison.
  static HomeSource decode(String? raw) => raw == 'google' ? HomeSource.google : HomeSource.apple;
}

/// Un capteur de la maison : un accessoire qui mesure la température, l'humidité
/// de l'air, ou les deux.
class HomeSensor {
  const HomeSensor({
    required this.id,
    required this.name,
    this.source = HomeSource.apple,
    this.roomName,
    this.homeName,
    this.hasTemperature = true,
    this.hasHumidity = true,
  });

  /// Identifiant stable de l'accessoire, celui que la maison lui donne.
  /// Unique chez elle seulement : c'est [source] qui dit à qui le présenter.
  final String id;
  final String name;

  /// La maison qui le connaît : Apple Maison ou Google Home.
  final HomeSource source;

  /// La pièce où la maison le range, s'il en a une.
  final String? roomName;
  final String? homeName;
  final bool hasTemperature;
  final bool hasHumidity;

  bool measures(HomeQuantity q) => q == HomeQuantity.temperature ? hasTemperature : hasHumidity;

  /// Le nom sous lequel il s'affiche : la pièce quand elle est connue, sinon
  /// l'accessoire lui-même.
  String get label => roomName?.trim().isNotEmpty == true ? roomName!.trim() : name;

  /// De quoi reconnaître un capteur d'un écran à l'autre : l'identifiant
  /// n'est unique que dans sa maison, alors la maison le précède.
  String get key => '${source.name}:$id';

  /// Sérialisation compacte pour les préférences
  /// (`id|nom|pièce|maison|température|humidité|plateforme`, les deux
  /// grandeurs à 1 ou 0). La plateforme vient en dernier : une préférence
  /// écrite avant Google Home se relit sans elle.
  String encode() => [
        id,
        name,
        roomName ?? '',
        homeName ?? '',
        hasTemperature ? '1' : '0',
        hasHumidity ? '1' : '0',
        source.name,
      ].map((s) => s.replaceAll('|', ' ')).join('|');

  /// Deux capteurs sont le même s'ils portent le même identifiant, dans la
  /// même maison, sous le même nom, la même pièce et la même installation :
  /// les préférences relisent le leur à chaque changement, et un `select` ne
  /// doit pas y voir un capteur neuf.
  @override
  bool operator ==(Object other) =>
      other is HomeSensor &&
      other.id == id &&
      other.source == source &&
      other.name == name &&
      other.roomName == roomName &&
      other.homeName == homeName &&
      other.hasTemperature == hasTemperature &&
      other.hasHumidity == hasHumidity;

  @override
  int get hashCode => Object.hash(id, source, name, roomName, homeName, hasTemperature, hasHumidity);

  static HomeSensor? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split('|');
    if (parts.length < 2 || parts[0].isEmpty) return null;
    final room = parts.length > 2 ? parts[2] : '';
    final home = parts.length > 3 ? parts[3] : '';
    // Une préférence écrite avant que l'on note ce que le capteur mesure :
    // on le suppose complet, la liste des capteurs corrigera à l'affichage.
    return HomeSensor(
      id: parts[0],
      name: parts[1],
      source: HomeSource.decode(parts.length > 6 ? parts[6] : null),
      roomName: room.isEmpty ? null : room,
      homeName: home.isEmpty ? null : home,
      hasTemperature: parts.length > 4 ? parts[4] != '0' : true,
      hasHumidity: parts.length > 5 ? parts[5] != '0' : true,
    );
  }
}

/// Ce qu'un capteur mesure, et ce qu'on lui demande.
enum HomeQuantity { temperature, humidity }

/// Une mesure, au moment où elle a été lue.
class HomeReading {
  const HomeReading({required this.at, this.temperatureC, this.humidity, this.sensor, this.humiditySensor, this.error});

  final DateTime at;

  /// Température de l'air (°C), ou `null` si le capteur ne la donne pas.
  final double? temperatureC;

  /// Humidité relative (0–100), ou `null` si le capteur ne la donne pas.
  final int? humidity;

  /// Le capteur de température, dont la pièce donne son nom à la mesure.
  final HomeSensor? sensor;

  /// Le capteur d'humidité, quand ce n'est pas le même.
  final HomeSensor? humiditySensor;

  /// Ce que la maison a répondu quand une lecture a échoué, tel quel : de
  /// quoi distinguer un capteur hors de portée d'un capteur qui ne mesure pas.
  final String? error;

  bool get isEmpty => temperatureC == null && humidity == null;
}

/// Ce que la maison laisse faire.
enum HomeAccess {
  /// Pas encore demandé : la première lecture ouvrira la demande du système.
  notDetermined,

  /// Accordé.
  authorized,

  /// Refusé, ou restreint par un profil : se règle dans les réglages du
  /// système, ou dans l'application Google Home.
  denied,

  /// Pas de maison de ce nom ici (Apple Maison hors iOS, Google Home sur le
  /// web, simulateur sans maison).
  unavailable,
}

/// Lecture des capteurs de la maison.
///
/// Une implémentation par plateforme ([SingleHomeClimateService]), et une
/// qui les rassemble quand l'appareil en a deux — l'écran, lui, ne voit
/// qu'un service et une liste de capteurs.
abstract class HomeClimateService {
  /// Vrai quand il y a au moins une maison à lire sur cet appareil.
  bool get isSupported;

  /// Les maisons lisibles ici, dans l'ordre où on les propose.
  List<HomeSource> get sources;

  /// Le service d'une seule maison, pour la brancher sans réveiller l'autre :
  /// deux demandes d'accès du système à la suite, personne n'en veut.
  HomeClimateService? of(HomeSource source);

  Future<HomeAccess> access();

  /// Les capteurs de toutes les maisons, ou une liste vide sans accès.
  /// Le premier appel déclenche la demande d'accès du système.
  Future<List<HomeSensor>> sensors();

  /// La mesure d'un capteur, ou `null` s'il ne répond pas. Le capteur entier,
  /// pas son identifiant : c'est lui qui dit à quelle maison la demander.
  Future<HomeReading?> read(HomeSensor sensor);

  /// Une maison dont la session se ferme depuis l'application.
  ///
  /// Apple Maison n'en ouvre pas : son accès est une permission du système,
  /// qui se retire dans les Réglages. Google Home, si — la session s'ouvre
  /// sur un compte Google, et ce qui s'ouvre doit pouvoir se fermer.
  bool get canDisconnect;

  /// Ferme la session. Ce que le compte a accordé, lui, ne se retire que
  /// depuis ce compte : cette méthode déconnecte, elle ne révoque pas.
  /// L'écran le dit avant de la déclencher, et mène au compte après.
  Future<void> disconnect();
}

/// Un service qui ne lit qu'une maison, celle de [source].
abstract class SingleHomeClimateService implements HomeClimateService {
  HomeSource get source;

  @override
  List<HomeSource> get sources => isSupported ? [source] : const [];

  @override
  HomeClimateService? of(HomeSource source) => source == this.source && isSupported ? this : null;

  /// Une maison lue par une permission du système n'ouvre pas de session :
  /// il n'y a rien à fermer, et l'écran ne propose rien.
  @override
  bool get canDisconnect => false;

  @override
  Future<void> disconnect() async {}
}

class UnavailableHomeClimateService implements HomeClimateService {
  const UnavailableHomeClimateService();

  @override
  bool get isSupported => false;

  @override
  List<HomeSource> get sources => const [];

  @override
  HomeClimateService? of(HomeSource source) => null;

  @override
  Future<HomeAccess> access() async => HomeAccess.unavailable;

  @override
  Future<List<HomeSensor>> sensors() async => const [];

  @override
  Future<HomeReading?> read(HomeSensor sensor) async => null;

  @override
  bool get canDisconnect => false;

  @override
  Future<void> disconnect() async {}
}

/// Les maisons de l'appareil, ensemble.
///
/// iPhone peut avoir les deux, Android n'a que Google Home : l'écran ne veut
/// pas le savoir. Il demande la liste des capteurs et reçoit ceux des deux
/// maisons, chacun marqué de la sienne ; il demande une mesure et elle part
/// à la bonne. Les services muets ici — Apple Maison sur Android, Google
/// Home sans son SDK — sont écartés à la construction.
class MultiHomeClimateService implements HomeClimateService {
  MultiHomeClimateService(Iterable<HomeClimateService> services) : services = [for (final s in services) if (s.isSupported) s];

  final List<HomeClimateService> services;

  @override
  bool get isSupported => services.isNotEmpty;

  @override
  List<HomeSource> get sources => [for (final s in services) ...s.sources];

  @override
  HomeClimateService? of(HomeSource source) {
    for (final s in services) {
      if (s.of(source) case final found?) return found;
    }
    return null;
  }

  /// L'accès le plus parlant des maisons branchées : accordé s'il l'est
  /// quelque part, sinon le refus, qui a quelque chose à dire, avant
  /// l'attente qui n'a rien.
  @override
  Future<HomeAccess> access() async {
    final all = <HomeAccess>[];
    for (final s in services) {
      all.add(await s.access());
    }
    for (final wanted in [HomeAccess.authorized, HomeAccess.denied, HomeAccess.notDetermined]) {
      if (all.contains(wanted)) return wanted;
    }
    return HomeAccess.unavailable;
  }

  /// Les capteurs des deux maisons, l'une après l'autre : deux demandes
  /// d'accès en parallèle se marcheraient dessus. Un écran qui n'en veut
  /// qu'une passe par [of].
  @override
  Future<List<HomeSensor>> sensors() async {
    final out = <HomeSensor>[];
    for (final s in services) {
      out.addAll(await s.sensors());
    }
    return out;
  }

  @override
  Future<HomeReading?> read(HomeSensor sensor) async => await of(sensor.source)?.read(sensor);

  @override
  bool get canDisconnect => services.any((s) => s.canDisconnect);

  /// Ferme les sessions de celles qui en ont une, et laisse les autres :
  /// une permission du système ne se rend pas d'ici. Un écran qui ne veut
  /// déconnecter qu'une maison passe par [of].
  @override
  Future<void> disconnect() async {
    for (final s in services) {
      if (s.canDisconnect) await s.disconnect();
    }
  }
}
