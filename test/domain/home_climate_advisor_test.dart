import 'package:flora/domain/care/care_profile.dart';
import 'package:flora/domain/home/home_climate.dart';
import 'package:flora/domain/home/home_climate_advisor.dart';
import 'package:flora/domain/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

CareProfile _profile({
  HumidityNeed humidity = HumidityNeed.average,
  int? humidityMin,
  int? humidityMax,
  int? damageBelowC,
  int? idealMin,
  int? idealMax,
}) =>
    CareProfile(
      wateringSummerDays: 7,
      wateringWinterDays: 14,
      light: LightNeed.brightIndirect,
      humidity: humidity,
      humidityMinPercent: humidityMin,
      humidityMaxPercent: humidityMax,
      difficulty: CareDifficulty.easy,
      soil: SoilKind.standard,
      damageBelowC: damageBelowC,
      idealTempMinC: idealMin,
      idealTempMaxC: idealMax,
    );

HomeReading _reading({double? temperature, int? humidity}) => HomeReading(at: DateTime(2026, 9, 12), temperatureC: temperature, humidity: humidity);

PlantSummary _plant(String name, {String? locationId, String? locationName}) {
  final now = DateTime(2026, 9, 12);
  return PlantSummary(
    plant: Plant(id: name, gardenId: 'g', name: name, locationId: locationId, status: PlantStatus.active, health: PlantHealth.healthy, isFavorite: false, createdAt: now, updatedAt: now),
    locationName: locationName,
  );
}

void main() {
  group('le conseil du climat de la maison', () {
    final calathea = IndoorPlant(name: 'Calathea', profile: _profile(humidity: HumidityNeed.high, damageBelowC: 15, idealMin: 18, idealMax: 27));
    final cactus = IndoorPlant(name: 'Cactus', profile: _profile(humidity: HumidityNeed.low, damageBelowC: 5, idealMax: 35));
    final ficus = IndoorPlant(name: 'Ficus', profile: _profile(humidity: HumidityNeed.average, damageBelowC: 12));

    test("l'air sec ne vise que les plantes qui en veulent", () {
      final tips = HomeClimateAdvisor.advise(reading: _reading(temperature: 21, humidity: 38), plants: [calathea, cactus, ficus]);
      expect(tips, hasLength(1));
      expect(tips.single.kind, HomeClimateTipKind.dryAir);
      expect(tips.single.value, 38);
      expect(tips.single.plantNames, ['Calathea']);
    });

    test("sous 30 %, même les plantes ordinaires sont concernées", () {
      final tips = HomeClimateAdvisor.advise(reading: _reading(humidity: 24), plants: [calathea, cactus, ficus]);
      expect(tips.single.plantNames, ['Calathea', 'Ficus']);
    });

    test("l'air humide s'annonce même sans plante fragile, avec celles qui aiment le sec", () {
      final tips = HomeClimateAdvisor.advise(reading: _reading(humidity: 78), plants: [calathea, cactus]);
      expect(tips.single.kind, HomeClimateTipKind.humidAir);
      expect(tips.single.plantNames, ['Cactus']);
      final alone = HomeClimateAdvisor.advise(reading: _reading(humidity: 78), plants: [calathea]);
      expect(alone.single.plantNames, isEmpty);
    });

    test('le froid compare au minimum supporté, la chaleur à la plage idéale', () {
      final cold = HomeClimateAdvisor.advise(reading: _reading(temperature: 13), plants: [calathea, cactus, ficus]);
      expect(cold.single.kind, HomeClimateTipKind.cold);
      expect(cold.single.plantNames, ['Calathea']);
      final hot = HomeClimateAdvisor.advise(reading: _reading(temperature: 31), plants: [calathea, cactus, ficus]);
      expect(hot.single.kind, HomeClimateTipKind.hot);
      // Le cactus tolère 35°, le ficus n'a pas de plage : le seuil général de 30° s'applique.
      expect(hot.single.plantNames, ['Calathea', 'Ficus']);
    });

    test("une fiche qui donne sa plage en pourcentage décale le seuil", () {
      // Deux plantes du même mot — « aime l'air humide » —, deux exigences :
      // l'orchidée se contente de 50 %, la calathéa en demande 65. À 40 %,
      // seule la seconde est en peine (65 − 15 > 40 ≥ 50 − 15).
      final orchidee = IndoorPlant(name: 'Orchidée', profile: _profile(humidity: HumidityNeed.high, humidityMin: 50, humidityMax: 70));
      final calathea = IndoorPlant(name: 'Calathéa', profile: _profile(humidity: HumidityNeed.high, humidityMin: 65, humidityMax: 85));
      final tips = HomeClimateAdvisor.advise(reading: _reading(humidity: 40), plants: [orchidee, calathea]);
      expect(tips.single.kind, HomeClimateTipKind.dryAir);
      expect(tips.single.plantNames, ['Calathéa']);
      // Plus bas, les deux y passent.
      final sec = HomeClimateAdvisor.advise(reading: _reading(humidity: 30), plants: [orchidee, calathea]);
      expect(sec.single.plantNames, ['Orchidée', 'Calathéa']);
    });

    test('une mesure dans les clous ne dit rien, et une maison sans plante non plus', () {
      expect(HomeClimateAdvisor.advise(reading: _reading(temperature: 22, humidity: 55), plants: [calathea, cactus, ficus]), isEmpty);
      expect(HomeClimateAdvisor.advise(reading: _reading(temperature: 5, humidity: 10), plants: const []), isEmpty);
    });

    test('quatre noms au plus, sans doublon', () {
      final many = [for (var i = 0; i < 6; i++) IndoorPlant(name: 'Fougère', profile: _profile(humidity: HumidityNeed.high)), calathea];
      final tips = HomeClimateAdvisor.advise(reading: _reading(humidity: 30), plants: many);
      expect(tips.single.plantNames, ['Fougère', 'Calathea']);
      final distinct = [for (var i = 0; i < 6; i++) IndoorPlant(name: 'P$i', profile: _profile(humidity: HumidityNeed.high))];
      expect(HomeClimateAdvisor.advise(reading: _reading(humidity: 30), plants: distinct).single.plantNames, hasLength(HomeClimateAdvisor.maxNames));
    });
  });

  group("les plantes d'intérieur", () {
    final plants = [
      _plant('Olivier', locationId: 'balcon', locationName: 'Balcon'),
      _plant('Monstera', locationId: 'salon', locationName: 'Salon'),
      _plant('Pothos', locationId: 'chambre', locationName: 'Chambre'),
      _plant('Sans place'),
    ];

    test('écarte ce qui est dehors', () {
      final indoor = HomeClimateAdvisor.indoorPlants(plants, outdoorLocationIds: {'balcon'});
      expect(indoor.map((p) => p.plant.name), ['Monstera', 'Pothos', 'Sans place']);
    });

    test('se limite à la pièce du capteur quand un emplacement porte son nom', () {
      final indoor = HomeClimateAdvisor.indoorPlants(plants, outdoorLocationIds: {'balcon'}, roomName: 'salon');
      expect(indoor.map((p) => p.plant.name), ['Monstera']);
    });

    test('garde tout l’intérieur quand la pièce ne correspond à rien', () {
      final indoor = HomeClimateAdvisor.indoorPlants(plants, outdoorLocationIds: {'balcon'}, roomName: 'Bureau');
      expect(indoor, hasLength(3));
    });
  });

  test('un capteur se garde et se relit en préférences', () {
    const sensor = HomeSensor(id: 'A|B', name: 'Eve Room', roomName: 'Salon', homeName: 'Chalet');
    final back = HomeSensor.decode(sensor.encode())!;
    expect(back.id, 'A B');
    expect(back.name, 'Eve Room');
    expect(back.roomName, 'Salon');
    expect(back.homeName, 'Chalet');
    expect(back.label, 'Salon');
    expect(back, const HomeSensor(id: 'A B', name: 'Eve Room', roomName: 'Salon', homeName: 'Chalet'));
    // Une préférence écrite avant la maison, ou avant ce que le capteur
    // mesure, se relit encore : on le suppose complet.
    expect(HomeSensor.decode('x|Capteur|')!.label, 'Capteur');
    expect(HomeSensor.decode('x|Capteur|')!.homeName, isNull);
    expect(HomeSensor.decode('x|Capteur||Chalet')!.hasHumidity, isTrue);
    final thermostat = HomeSensor.decode(const HomeSensor(id: 't', name: 'Thermostat', hasHumidity: false).encode())!;
    expect(thermostat.hasTemperature, isTrue);
    expect(thermostat.hasHumidity, isFalse);
    expect(HomeSensor.decode(''), isNull);
    expect(HomeSensor.decode('seul'), isNull);
  });
}
