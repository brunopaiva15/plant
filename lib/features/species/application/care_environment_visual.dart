import '../../../domain/care/care_profile.dart';

/// Le décor dans lequel la fiche représente le besoin de la plante.
///
/// Ce n'est pas l'emplacement réel de la plante : la scène montre le milieu
/// conseillé par la fiche. Les mesures de la maison restent traitées à part.
enum CareEnvironmentKind { indoor, outdoor }

/// Silhouettes d'argile réutilisées par la scène. Elles décrivent une forme,
/// jamais une identification botanique : l'espèce exacte reste écrite dans la
/// fiche et le résolveur retombe sur une silhouette générique s'il ne sait pas.
enum CarePlantVisualKind {
  monstera('monstera'),
  broadLeaf('broad_leaf'),
  uprightLeaf('upright_leaf'),
  vine('vine'),
  fern('fern'),
  rosette('rosette'),
  cactus('cactus'),
  tree('tree'),
  conifer('conifer');

  const CarePlantVisualKind(this.assetKey);
  final String assetKey;
}

/// Projection pure d'une fiche d'entretien vers sa scène isométrique.
///
/// Elle ne contient aucune donnée supplémentaire : les valeurs sont des
/// instructions de mise en scène dérivées de [CareProfile].
class CareEnvironmentVisualSpec {
  const CareEnvironmentVisualSpec({
    required this.environment,
    required this.light,
    required this.humidity,
    required this.plant,
    required this.humidityMin,
    required this.humidityMax,
    this.temperatureMin,
    this.temperatureMax,
  });

  final CareEnvironmentKind environment;
  final LightNeed light;
  final HumidityNeed humidity;
  final CarePlantVisualKind plant;
  final int humidityMin;
  final int humidityMax;
  final int? temperatureMin;
  final int? temperatureMax;

  String get environmentAssetKey => environment.name;
  String get lightAssetKey => switch (light) {
        LightNeed.shade => 'shade',
        LightNeed.lowLight => 'low_light',
        LightNeed.indirect => 'indirect',
        LightNeed.brightIndirect => 'bright_indirect',
        LightNeed.someSun => 'some_sun',
        LightNeed.fullSun => 'full_sun',
      };

  String get backgroundAsset => 'assets/care_scene/$environmentAssetKey/$lightAssetKey.webp';
  String get plantAsset => 'assets/care_scene/plants/${plant.assetKey}.webp';
}

abstract final class CareEnvironmentVisualResolver {
  static const _outdoorGenera = <String>{
    'abies',
    'acer',
    'betula',
    'cedrus',
    'fagus',
    'malus',
    'picea',
    'pinus',
    'prunus',
    'pyrus',
    'quercus',
    'sequoia',
    'thuja',
    'ulmus',
  };

  static const _conifers = <String>{'abies', 'cedrus', 'picea', 'pinus', 'sequoia', 'thuja'};
  static const _cacti = <String>{
    'astrophytum',
    'carnegiea',
    'cereus',
    'echinocactus',
    'echinopsis',
    'ferocactus',
    'gymnocalycium',
    'mammillaria',
    'opuntia',
    'schlumbergera',
  };
  static const _rosettes = <String>{'aeonium', 'agave', 'aloe', 'echeveria', 'haworthia', 'sempervivum'};
  static const _ferns = <String>{'adiantum', 'asplenium', 'davallia', 'nephrolepis', 'platycerium', 'pteris'};
  static const _upright = <String>{'dracaena', 'sansevieria', 'strelitzia', 'yucca'};
  static const _vines = <String>{'epipremnum', 'hedera', 'hoya', 'philodendron', 'scindapsus', 'syngonium'};
  static const _broadLeaf = <String>{'alocasia', 'anthurium', 'calathea', 'ficus', 'goeppertia', 'maranta', 'spathiphyllum'};

  static CareEnvironmentVisualSpec resolve(CareProfile profile, {String? speciesName}) {
    final humidity = profile.humidityRange;
    final genus = _genus(speciesName);
    return CareEnvironmentVisualSpec(
      environment: _environment(profile, genus),
      light: profile.light,
      humidity: profile.humidity,
      plant: _plant(profile, speciesName, genus),
      humidityMin: humidity.$1,
      humidityMax: humidity.$2,
      temperatureMin: profile.idealTempMinC,
      temperatureMax: profile.idealTempMaxC,
    );
  }

  static CareEnvironmentKind _environment(CareProfile profile, String genus) {
    if (_outdoorGenera.contains(genus)) return CareEnvironmentKind.outdoor;
    // `outdoorFriendly` signifie que la plante peut sortir, pas qu'elle doit
    // vivre dehors. On ne l'emploie donc qu'avec un profil franchement
    // rustique ; une Monstera sortie l'été reste représentée dans une pièce.
    if (profile.outdoorFriendly && (profile.damageBelowC ?? 10) <= 2) {
      return CareEnvironmentKind.outdoor;
    }
    return CareEnvironmentKind.indoor;
  }

  static CarePlantVisualKind _plant(CareProfile profile, String? speciesName, String genus) {
    final normalized = (speciesName ?? '').trim().toLowerCase();
    if (normalized == 'monstera deliciosa' || genus == 'monstera') return CarePlantVisualKind.monstera;
    if (_conifers.contains(genus)) return CarePlantVisualKind.conifer;
    if (_outdoorGenera.contains(genus)) return CarePlantVisualKind.tree;
    if (_cacti.contains(genus)) return CarePlantVisualKind.cactus;
    if (_rosettes.contains(genus)) return CarePlantVisualKind.rosette;
    if (_ferns.contains(genus)) return CarePlantVisualKind.fern;
    if (_upright.contains(genus)) return CarePlantVisualKind.uprightLeaf;
    if (_vines.contains(genus)) return CarePlantVisualKind.vine;
    if (_broadLeaf.contains(genus)) return CarePlantVisualKind.broadLeaf;
    if (profile.soil == SoilKind.cactus) return CarePlantVisualKind.rosette;
    if (profile.support != null) return CarePlantVisualKind.vine;
    return CarePlantVisualKind.broadLeaf;
  }

  static String _genus(String? scientificName) {
    final value = scientificName?.trim().toLowerCase() ?? '';
    if (value.isEmpty) return '';
    return value.split(RegExp(r'\s+')).first;
  }
}
