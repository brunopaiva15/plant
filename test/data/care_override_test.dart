import 'package:flora/data/species/care_override_store.dart';
import 'package:flora/data/species/catalog_care_guide.dart';
import 'package:flora/data/species/overridden_care_guide.dart';
import 'package:flora/domain/care/care_guide.dart';
import 'package:flora/domain/care/care_override.dart';
import 'package:flora/domain/care/care_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('la retouche', () {
    test('remplace les champs qu\'elle porte, garde les autres', () {
      final base = const CatalogCareGuide().resolve('Monstera deliciosa').profile;
      const override = CareOverride(light: LightNeed.fullSun, wateringSummerDays: 3);
      final edited = override.applyTo(base);
      expect(edited.light, LightNeed.fullSun);
      expect(edited.wateringSummerDays, 3);
      expect(edited.humidity, base.humidity, reason: 'le reste vient du catalogue');
      expect(edited.soil, base.soil);
    });

    test('vide, elle ne dit rien', () {
      expect(const CareOverride().isEmpty, isTrue);
      expect(CareOverride.fromJson(const <String, Object?>{}), isNull);
    });

    test('fait un aller-retour par le JSON', () {
      const override = CareOverride(light: LightNeed.someSun, difficulty: CareDifficulty.demanding, damageBelowC: 5);
      final back = CareOverride.fromJson(override.toJson())!;
      expect(back.light, LightNeed.someSun);
      expect(back.difficulty, CareDifficulty.demanding);
      expect(back.damageBelowC, 5);
      expect(back.humidity, isNull, reason: 'les champs non retouchés restent absents');
    });

    test('fait circuler l\'air qui bouge', () {
      const profil = CareProfile(
        wateringSummerDays: 7,
        wateringWinterDays: 14,
        light: LightNeed.indirect,
        humidity: HumidityNeed.high,
        difficulty: CareDifficulty.demanding,
        soil: SoilKind.standard,
        airflow: AirflowPreference.sheltered,
      );
      // Sans retouche, la valeur de la fiche passe telle quelle.
      expect(const CareOverride().applyTo(profil).airflow, AirflowPreference.sheltered);
      // La retouche l'emporte.
      expect(const CareOverride(airflow: AirflowPreference.ventilated).applyTo(profil).airflow, AirflowPreference.ventilated);
      // Et elle survit au rangement.
      final back = CareOverride.fromJson(const CareOverride(airflow: AirflowPreference.sheltered).toJson())!;
      expect(back.airflow, AirflowPreference.sheltered);
      expect(back.isEmpty, isFalse);
    });
  });

  group('le guide retouché', () {
    final base = const CatalogCareGuide();

    test('applique la retouche et l\'annonce', () {
      final guide = OverriddenCareGuide(base: base, overrides: {
        CareOverrideStore.keyOf('Monstera deliciosa'): const CareOverride(light: LightNeed.fullSun),
      });
      final care = guide.resolve('Monstera deliciosa');
      expect(care.profile.light, LightNeed.fullSun);
      expect(care.match, CareMatch.edited);
      // Une espèce non retouchée garde sa provenance d'origine.
      expect(guide.resolve('Ficus lyrata').match, base.resolve('Ficus lyrata').match);
    });

    test('la casse du nom ne compte pas', () {
      final guide = OverriddenCareGuide(base: base, overrides: {
        CareOverrideStore.keyOf('Monstera deliciosa'): const CareOverride(difficulty: CareDifficulty.demanding),
      });
      expect(guide.resolve('MONSTERA DELICIOSA').profile.difficulty, CareDifficulty.demanding);
      expect(guide.resolve('monstera deliciosa').match, CareMatch.edited);
    });

    test('sans retouche, le guide se comporte comme le catalogue', () {
      const base = CatalogCareGuide();
      final guide = OverriddenCareGuide(base: base, overrides: const {});
      expect(guide.resolve('Monstera deliciosa').match, base.resolve('Monstera deliciosa').match);
    });
  });

  group('le rangement', () {
    test('encode et relit les retouches', () {
      final encoded = CareOverrideStore.encode({
        'monstera deliciosa': const CareOverride(humidity: HumidityNeed.high),
      });
      expect(CareOverrideStore.decode(encoded)['monstera deliciosa']?.humidity, HumidityNeed.high);
    });

    test('un contenu illisible ne casse rien', () {
      expect(CareOverrideStore.decode(null), isEmpty);
      expect(CareOverrideStore.decode(''), isEmpty);
      expect(CareOverrideStore.decode('pas du json'), isEmpty);
      expect(CareOverrideStore.decode('[1,2]'), isEmpty);
    });
  });
}
