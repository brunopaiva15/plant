import 'package:flora/domain/home/home_climate.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/fakes/fake_home_climate_service.dart';

/// Deux maisons sur un appareil : les capteurs gardent la leur, les
/// préférences s'en souviennent, et une mesure repart toujours à la bonne.
void main() {
  const eve = HomeSensor(id: 'A', name: 'Eve Room', roomName: 'Salon', homeName: 'Maison');
  const nest = HomeSensor(id: 'A', name: 'Nest', roomName: 'Salon', source: HomeSource.google, hasHumidity: false);

  group('le capteur', () {
    test('garde sa maison en préférences, et la relit', () {
      final again = HomeSensor.decode(nest.encode())!;
      expect(again.source, HomeSource.google);
      expect(again, nest);
      expect(HomeSensor.decode(eve.encode())!.source, HomeSource.apple);
    });

    test("une préférence écrite avant Google Home, c'était Apple Maison", () {
      final old = HomeSensor.decode('A|Eve Room|Salon|Maison|1|1')!;
      expect(old.source, HomeSource.apple);
      expect(old, eve);
    });

    test('deux maisons peuvent donner le même identifiant, pas la même clé', () {
      expect(nest.id, eve.id);
      expect(nest.key, isNot(eve.key));
      expect(nest, isNot(eve));
    });
  });

  group('les maisons ensemble', () {
    FakeHomeClimateService apple({bool supported = true}) =>
        FakeHomeClimateService(supported: supported, sensorList: const [eve], reading: HomeReading(at: _at, temperatureC: 21));
    FakeHomeClimateService google({bool supported = true, HomeAccess access = HomeAccess.authorized}) => FakeHomeClimateService(
          supported: supported,
          source: HomeSource.google,
          accessValue: access,
          sensorList: const [nest],
          reading: HomeReading(at: _at, temperatureC: 19),
          disconnectable: true,
        );

    test('écartent celle qui est muette ici', () {
      final only = MultiHomeClimateService([apple(supported: false), google()]);
      expect(only.sources, [HomeSource.google]);
      expect(only.of(HomeSource.apple), isNull);
      expect(only.of(HomeSource.google), isNotNull);
      expect(MultiHomeClimateService([apple(supported: false), google(supported: false)]).isSupported, isFalse);
    });

    test('rendent les capteurs des deux, chacun marqué', () async {
      final both = MultiHomeClimateService([apple(), google()]);
      final sensors = await both.sensors();
      expect(sensors.map((s) => s.key), [eve.key, nest.key]);
    });

    test('envoient une mesure à la maison du capteur', () async {
      final a = apple();
      final g = google();
      final both = MultiHomeClimateService([a, g]);
      expect((await both.read(eve))!.temperatureC, 21);
      expect(a.readCalls, 1);
      expect(g.readCalls, 0);
      expect((await both.read(nest))!.temperatureC, 19);
      expect(g.readCalls, 1);
    });

    test('un capteur dont la maison a disparu ne se lit pas', () async {
      final both = MultiHomeClimateService([apple()]);
      expect(await both.read(nest), isNull);
    });

    test('ne déconnectent que celle qui tient une session', () async {
      final a = apple();
      final g = google();
      final both = MultiHomeClimateService([a, g]);
      expect(both.canDisconnect, isTrue);
      await both.disconnect();
      // Apple Maison n'a pas de session : son accès est une permission du
      // système, qui ne se rend pas d'ici.
      expect(a.disconnectCalls, 0);
      expect(g.disconnectCalls, 1);
      expect(MultiHomeClimateService([apple()]).canDisconnect, isFalse);
      expect(MultiHomeClimateService([google(supported: false)]).canDisconnect, isFalse);
    });

    test("l'accès accordé quelque part vaut mieux qu'un refus ailleurs", () async {
      expect(await MultiHomeClimateService([apple(), google(access: HomeAccess.denied)]).access(), HomeAccess.authorized);
      expect(
        await MultiHomeClimateService([
          FakeHomeClimateService(accessValue: HomeAccess.notDetermined),
          google(access: HomeAccess.denied),
        ]).access(),
        HomeAccess.denied,
      );
      expect(await MultiHomeClimateService([apple(supported: false)]).access(), HomeAccess.unavailable);
    });
  });
}

final _at = DateTime(2026, 9, 12, 8);
