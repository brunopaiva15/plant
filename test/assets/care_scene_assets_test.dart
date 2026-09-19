import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flora/domain/care/care_profile.dart';
import 'package:flora/domain/species/species_info.dart';
import 'package:flora/features/species/application/care_environment_slots.dart';
import 'package:flora/features/species/application/care_environment_spec.dart';
import 'package:flutter_test/flutter_test.dart';

/// Les assets de la scène d'environnement idéal. On vérifie les fichiers
/// réellement embarqués : une image renommée, oubliée dans le pubspec ou
/// jamais rendue ne se verrait qu'à l'exécution, sur l'appareil — et une
/// valeur d'enum ajoutée sans son image casserait ici.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  void expectWebp(File file, {int plancher = 2048}) {
    expect(file.existsSync(), isTrue, reason: file.path);
    expect(
      file.lengthSync(),
      greaterThan(plancher),
      reason: '${file.path} est vide ou presque',
    );
    // En-tête RIFF/WEBP : le fichier est bien ce qu'il prétend être.
    final head = file.openSync().readSync(12);
    expect(String.fromCharCodes(head.sublist(0, 4)), 'RIFF', reason: file.path);
    expect(
      String.fromCharCodes(head.sublist(8, 12)),
      'WEBP',
      reason: file.path,
    );
  }

  test(
    'chaque besoin de lumière a sa variante dans les trois décors',
    () {
      const noms = {
        LightNeed.shade: 'shade',
        LightNeed.lowLight: 'low_light',
        LightNeed.indirect: 'indirect',
        LightNeed.brightIndirect: 'bright_indirect',
        LightNeed.someSun: 'some_sun',
        LightNeed.fullSun: 'full_sun',
      };
      expect(noms, hasLength(LightNeed.values.length));
      for (final entree in noms.entries) {
        expectWebp(
          File('assets/care_scene/indoor/light/${entree.value}.webp'),
          plancher: 4096,
        );
        expectWebp(
          File('assets/care_scene/outdoor/light/${entree.value}.webp'),
          plancher: 4096,
        );
        expectWebp(
          File('assets/care_scene/balcony/light/${entree.value}.webp'),
          plancher: 4096,
        );
      }
    },
  );

  test('chaque silhouette a son image', () {
    for (final v in PlantVisualKind.values) {
      expectWebp(File(_spec(v).plantAsset));
    }
  });

  test('la pièce contient toute la silhouette, où qu\'elle se pose', () async {
    // Le décor et les plantes sortent de la même caméra à cadre fixe : à
    // taille d'image égale, un pixel de plante tombe sur le pixel de décor
    // qu'il couvrira dans l'application. Dans la pièce, les murs bornent la
    // plante : une silhouette trop grande les traverse et flotte sur le
    // fond — c'est ce qui se voyait avant `plants.ECHELLE_PIECE`.
    final decor = await _pixels(
      File('assets/care_scene/indoor/light/indirect.webp'),
    );
    const ancre = CareEnvironmentSlots.anchor;
    for (final v in PlantVisualKind.values) {
      final plante = await _pixels(File(_spec(v).plantAsset));
      final points = _opaques(plante);
      expect(points, isNotEmpty, reason: '${v.name} : silhouette vide');
      for (final emplacement in CarePlantSlot.values) {
        final f = CareEnvironmentSlots.slots[emplacement.name]!;
        final dx = ((f.$1 - ancre.$1) * plante.largeur).round();
        final dy = ((f.$2 - ancre.$2) * plante.hauteur).round();
        var dehors = 0;
        for (var i = 0; i < points.length; i += 2) {
          if (!_surLeDecor(decor, points[i] + dx, points[i + 1] + dy)) {
            dehors += 1;
          }
        }
        expect(
          dehors,
          0,
          reason:
              '${v.name} sur ${emplacement.name} : $dehors pixels hors du '
              'diorama — la silhouette est trop grande pour la pièce',
        );
      }
    }
  });

  test('dehors et au balcon, le pot se pose sur le sol', () async {
    // Le jardin et le balcon sont des maquettes posées, comme la pièce :
    // au-dessus de leur dalle il n'y a que du transparent. Une plante y
    // dépasse donc dans le ciel, et c'est normal — ce serait une faute
    // dans une pièce, pas dehors. Ce qui doit tenir ici, c'est le pied :
    // le pot se pose sur le sol, jamais dans le vide à côté de la dalle.
    const ancre = CareEnvironmentSlots.anchor;
    for (final decorAsset in [
      'assets/care_scene/outdoor/light/indirect.webp',
      'assets/care_scene/balcony/light/indirect.webp',
    ]) {
      final decor = await _pixels(File(decorAsset));
      for (final v in PlantVisualKind.values) {
        final plante = await _pixels(File(_spec(v).plantAsset));
        final pied = _pied(_opaques(plante));
        expect(pied, isNotEmpty, reason: '${v.name} : silhouette vide');
        for (final emplacement in CarePlantSlot.values) {
          final f = CareEnvironmentSlots.slots[emplacement.name]!;
          final dx = ((f.$1 - ancre.$1) * plante.largeur).round();
          final dy = ((f.$2 - ancre.$2) * plante.hauteur).round();
          var dehors = 0;
          for (var i = 0; i < pied.length; i += 2) {
            if (!_surLeDecor(decor, pied[i] + dx, pied[i + 1] + dy)) {
              dehors += 1;
            }
          }
          expect(
            dehors,
            0,
            reason:
                '${v.name} sur ${emplacement.name} dans $decorAsset : '
                '$dehors pixels de pot dans le vide',
          );
        }
      }
    }
  });

  test('les chemins rendus par la projection existent', () {
    for (final light in LightNeed.values) {
      for (final category in [SpeciesCategory.indoor, SpeciesCategory.tree]) {
        final spec = careEnvironmentSpec(
          profile: CareProfile(
            wateringSummerDays: 7,
            wateringWinterDays: 14,
            light: light,
            humidity: HumidityNeed.average,
            difficulty: CareDifficulty.easy,
            soil: SoilKind.standard,
          ),
          speciesName: 'Monstera deliciosa',
          category: category,
        );
        expect(
          File(spec.backdropAsset).existsSync(),
          isTrue,
          reason: '${light.name} / ${category.name}',
        );
        expect(File(spec.plantAsset).existsSync(), isTrue);
      }
    }
  });

  test(
    'la table des emplacements couvre exactement les valeurs de l\'enum',
    () {
      expect(
        CareEnvironmentSlots.slots.keys.toSet(),
        CarePlantSlot.values.map((s) => s.name).toSet(),
      );
      expect(
        CareEnvironmentSlots.humidifier.keys.toSet(),
        CarePlantSlot.values.map((s) => s.name).toSet(),
      );
      expect(
        CareEnvironmentSlots.humidifierTop.keys.toSet(),
        CarePlantSlot.values.map((s) => s.name).toSet(),
      );
    },
  );

  test('les props du climat ont leur image', () {
    for (final nom in ['humidifier', 'pedestal']) {
      expectWebp(File('assets/care_scene/props/$nom.webp'));
    }
  });

  test('le poids total reste sous le budget de la fonctionnalité', () {
    final dossier = Directory('assets/care_scene');
    final total = dossier
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.webp'))
        .fold<int>(0, (somme, f) => somme + f.lengthSync());
    // Le budget (docs/13, tool/build_care_scene_assets.py) : 8 Mo pour toute
    // la fonctionnalité ; la vague 1 en est loin.
    expect(total, lessThan(8 * 1024 * 1024), reason: '${total / 1e6} Mo');
  });

  test('les dossiers sont déclarés dans le pubspec', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('- assets/care_scene/indoor/light/'));
    expect(pubspec, contains('- assets/care_scene/outdoor/light/'));
    expect(pubspec, contains('- assets/care_scene/balcony/light/'));
    expect(pubspec, contains('- assets/care_scene/plants/'));
    expect(pubspec, contains('- assets/care_scene/props/'));
  });
}

/// Une silhouette dans son cadre, pour atteindre son chemin d'asset.
CareEnvironmentVisualSpec _spec(PlantVisualKind plante) =>
    CareEnvironmentVisualSpec(
      environment: CareEnvironmentKind.indoorRoom,
      light: LightNeed.indirect,
      slot: CarePlantSlot.middle,
      plant: plante,
      humidity: HumidityNeed.average,
      humidityRange: (40, 60),
    );

/// Les pixels bruts d'une image livrée, avec ses dimensions.
Future<({int largeur, int hauteur, ByteData octets})> _pixels(File f) async {
  final codec = await ui.instantiateImageCodec(await f.readAsBytes());
  final frame = await codec.getNextFrame();
  final octets = await frame.image.toByteData(
    format: ui.ImageByteFormat.rawRgba,
  );
  final lu = (
    largeur: frame.image.width,
    hauteur: frame.image.height,
    octets: octets!,
  );
  frame.image.dispose();
  codec.dispose();
  return lu;
}

/// Les pixels franchement opaques d'une silhouette, à plat : x, y, x, y…
List<int> _opaques(({int largeur, int hauteur, ByteData octets}) image) {
  final points = <int>[];
  for (var y = 0; y < image.hauteur; y++) {
    for (var x = 0; x < image.largeur; x++) {
      if (image.octets.getUint8((y * image.largeur + x) * 4 + 3) > 64) {
        points.add(x);
        points.add(y);
      }
    }
  }
  return points;
}

/// Le pied de la silhouette : la tranche basse, celle qui touche le sol.
/// Huit pour cent de sa hauteur suffisent à tenir la base du pot sans
/// attraper le feuillage.
List<int> _pied(List<int> points) {
  var haut = points[1], bas = points[1];
  for (var i = 1; i < points.length; i += 2) {
    if (points[i] < haut) haut = points[i];
    if (points[i] > bas) bas = points[i];
  }
  final seuil = bas - 0.08 * (bas - haut);
  final pied = <int>[];
  for (var i = 0; i < points.length; i += 2) {
    if (points[i + 1] >= seuil) {
      pied.add(points[i]);
      pied.add(points[i + 1]);
    }
  }
  return pied;
}

/// Ce pixel du cadre est-il du décor, ou du vide autour de la maquette ?
bool _surLeDecor(
  ({int largeur, int hauteur, ByteData octets}) decor,
  int x,
  int y,
) =>
    x >= 0 &&
    y >= 0 &&
    x < decor.largeur &&
    y < decor.hauteur &&
    decor.octets.getUint8((y * decor.largeur + x) * 4 + 3) > 8;
