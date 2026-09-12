import 'package:flora/domain/care/care_profile.dart';
import 'package:flora/domain/home/home_climate.dart';
import 'package:flora/domain/home/home_climate_advisor.dart';
import 'package:flora/domain/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

CareProfile _profile({HumidityNeed humidity = HumidityNeed.average, int? minTempC, int? idealMin, int? idealMax}) => CareProfile(
      wateringSummerDays: 7,
      wateringWinterDays: 14,
      light: LightNeed.brightIndirect,
      humidity: humidity,
      difficulty: CareDifficulty.easy,
      soil: SoilKind.standard,
      minTempC: minTempC,
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
    final calathea = IndoorPlant(name: 'Calathea', profile: _profile(humidity: HumidityNeed.high, minTempC: 15, idealMin: 18, idealMax: 27));
    final cactus = IndoorPlant(name: 'Cactus', profile: _profile(humidity: HumidityNeed.low, minTempC: 5, idealMax: 35));
    final ficus = IndoorPlant(name: 'Ficus', profile: _profile(humidity: HumidityNeed.average, minTempC: 12));

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
    const sensor = HomeSensor(id: 'A|B', name: 'Eve Room', roomName: 'Salon');
    final back = HomeSensor.decode(sensor.encode())!;
    expect(back.id, 'A B');
    expect(back.name, 'Eve Room');
    expect(back.roomName, 'Salon');
    expect(back.label, 'Salon');
    expect(HomeSensor.decode('x|Capteur|')!.label, 'Capteur');
    expect(HomeSensor.decode(''), isNull);
    expect(HomeSensor.decode('seul'), isNull);
  });
}
