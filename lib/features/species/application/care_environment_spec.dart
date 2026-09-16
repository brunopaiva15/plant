import '../../../domain/care/care_profile.dart';
import '../../../domain/species/species_info.dart';
import 'care_environment_slots.dart';

/// Le décor de la scène d'environnement idéal : une pièce, ou un coin dehors.
enum CareEnvironmentKind { indoorRoom, outdoorPatch }

/// Les emplacements de plante dans le cadre, nommés comme les clés de
/// [CareEnvironmentSlots.slots] — la distance à la fenêtre encode le besoin
/// de lumière.
enum CarePlantSlot {
  backCorner,
  back,
  middle,
  nearWindowOutsideBeam,
  nearWindowEdgeOfBeam,
  sunZone,
}

/// Les silhouettes de plante livrées en assets (vague 1, cf.
/// `tool/care_scene/plants.py`). Chaque valeur doit avoir son image ;
/// `test/assets/care_scene_assets_test.dart` le verrouille.
enum PlantVisualKind {
  monstera,
  broadLeaf,
  uprightLeaf,
  vine,
  fern,
  rosette,
  cactus,
  conifer,
  orchid,
}

/// Ce que la scène d'environnement idéal doit montrer, déduit de la fiche.
///
/// C'est une projection pure et déterministe : les mêmes données donnent
/// toujours la même scène. Rien n'y est inventé — une information absente de
/// la fiche (l'air qui bouge, la température) n'y apparaît pas.
class CareEnvironmentVisualSpec {
  const CareEnvironmentVisualSpec({
    required this.environment,
    required this.light,
    required this.slot,
    required this.plant,
    required this.humidity,
    required this.humidityRange,
    this.airflow,
    this.tempRange,
    this.tempFloorC,
  });

  /// Pièce ou dehors.
  final CareEnvironmentKind environment;

  /// La variante lumineuse du décor : le besoin de la fiche, jamais la
  /// lumière réelle de l'emplacement — la scène montre l'idéal, pas l'état.
  final LightNeed light;

  /// Où la plante se pose dans le cadre.
  final CarePlantSlot slot;

  /// Sa silhouette.
  final PlantVisualKind plant;

  final HumidityNeed humidity;

  /// La plage d'hygrométrie affichée en callout : celle de l'espèce quand
  /// elle est renseignée, celle du besoin sinon (cf. [CareProfile.humidityRange]).
  final (int, int) humidityRange;

  /// L'air qui bouge, seulement quand la fiche le sait. `null` = la scène ne
  /// montre rien qui y touche.
  final AirflowPreference? airflow;

  /// La plage idéale, quand les deux bornes sont connues (« 18–27 °C »).
  final (int, int)? tempRange;

  /// Le seuil de dégâts, quand il est la seule chose connue (« ≥ 12 °C »).
  final int? tempFloorC;

  /// Le décor lumineux de la scène.
  String get backdropAsset => switch (environment) {
    CareEnvironmentKind.indoorRoom =>
      'assets/care_scene/indoor/light/${_lightFile(light)}.webp',
    CareEnvironmentKind.outdoorPatch =>
      'assets/care_scene/outdoor/light/${_lightFile(light)}.webp',
  };

  /// La silhouette, telle qu'elle est rendue par le pipeline.
  String get plantAsset => switch (plant) {
    PlantVisualKind.monstera => 'assets/care_scene/plants/monstera.webp',
    PlantVisualKind.broadLeaf => 'assets/care_scene/plants/broad_leaf.webp',
    PlantVisualKind.uprightLeaf => 'assets/care_scene/plants/upright_leaf.webp',
    PlantVisualKind.vine => 'assets/care_scene/plants/vine.webp',
    PlantVisualKind.fern => 'assets/care_scene/plants/fern.webp',
    PlantVisualKind.rosette => 'assets/care_scene/plants/rosette.webp',
    PlantVisualKind.cactus => 'assets/care_scene/plants/cactus.webp',
    PlantVisualKind.conifer => 'assets/care_scene/plants/conifer.webp',
    PlantVisualKind.orchid => 'assets/care_scene/plants/orchid.webp',
  };

  /// L'emplacement dans le cadre, en coordonnées fractionnaires.
  (double, double) get slotFraction => CareEnvironmentSlots.slots[slot.name]!;

  /// L'humidificateur ne paraît que si l'air humide est un besoin : c'est
  /// lui qui rend l'humidité élevée perceptible dans la scène.
  bool get hasHumidifier => humidity == HumidityNeed.high;

  /// Où il se pose : à côté de la plante, quelle que soit sa place.
  (double, double) get humidifierFraction =>
      CareEnvironmentSlots.humidifier[slot.name]!;

  /// D'où part la vapeur.
  (double, double) get steamOriginFraction =>
      CareEnvironmentSlots.humidifierTop[slot.name]!;

  /// D'où souffle l'air à abriter : la fenêtre dans la pièce, l'ouverture
  /// au-dessus de la haie dehors. Un courant d'air vient d'une ouverture,
  /// jamais d'une machine.
  (double, double) get airflowOriginFraction =>
      CareEnvironmentSlots.airflow[environment == CareEnvironmentKind.indoorRoom
          ? 'indoor'
          : 'outdoor']!;

  /// L'air qui bouge ne se dessine que quand il dit quelque chose : à
  /// abriter ou bien ventilé. `normal` n'a pas d'emphase, `null` n'a rien.
  bool get hasAirflowEffect =>
      airflow == AirflowPreference.sheltered ||
      airflow == AirflowPreference.ventilated;

  static String _lightFile(LightNeed light) => switch (light) {
    LightNeed.shade => 'shade',
    LightNeed.lowLight => 'low_light',
    LightNeed.indirect => 'indirect',
    LightNeed.brightIndirect => 'bright_indirect',
    LightNeed.someSun => 'some_sun',
    LightNeed.fullSun => 'full_sun',
  };
}

/// La projection : de la fiche vers la description visuelle de la scène.
CareEnvironmentVisualSpec careEnvironmentSpec({
  required CareProfile profile,
  String? speciesName,
  String? family,
  SpeciesCategory? category,
}) {
  final idealMin = profile.idealTempMinC;
  final idealMax = profile.idealTempMaxC;
  final plage = idealMin != null && idealMax != null
      ? (idealMin, idealMax)
      : null;
  return CareEnvironmentVisualSpec(
    environment: environmentFor(profile, category),
    light: profile.light,
    // Même caméra, même direction de soleil dans les deux décors : la table
    // des emplacements vaut pour la pièce comme pour le jardin.
    slot: slotFor(profile.light),
    plant: resolvePlantVisual(
      speciesName: speciesName,
      family: family,
      category: category,
    ),
    humidity: profile.humidity,
    humidityRange: profile.humidityRange,
    airflow: profile.airflow,
    tempRange: plage,
    // Le seuil de dégâts ne se dit que faute de plage idéale : les deux
    // ensemble feraient double emploi sur la même puce.
    tempFloorC: plage == null ? profile.damageBelowC : null,
  );
}

/// L'emplacement qui dit le besoin de lumière : du fond de la pièce, loin
/// de la fenêtre, jusqu'au cœur de la tache de soleil.
CarePlantSlot slotFor(LightNeed light) => switch (light) {
  LightNeed.shade => CarePlantSlot.backCorner,
  LightNeed.lowLight => CarePlantSlot.back,
  LightNeed.indirect => CarePlantSlot.middle,
  LightNeed.brightIndirect => CarePlantSlot.nearWindowOutsideBeam,
  LightNeed.someSun => CarePlantSlot.nearWindowEdgeOfBeam,
  LightNeed.fullSun => CarePlantSlot.sunZone,
};

/// Pièce ou dehors, décidé ici et nulle part ailleurs.
///
/// La catégorie d'usage donne le premier mot ; la rusticité départage les
/// cas ambigus — une aromatique ou une fleur annuelle qui gèle vit en pot
/// dedans, une vivace rustique a sa place dehors. Sans catégorie (catalogue
/// étendu), la pièce est le repli : les plantes de l'app sont d'abord des
/// plantes d'intérieur.
CareEnvironmentKind environmentFor(
  CareProfile profile,
  SpeciesCategory? category,
) => switch (category) {
  SpeciesCategory.tree ||
  SpeciesCategory.fruit ||
  SpeciesCategory.vegetable => CareEnvironmentKind.outdoorPatch,
  SpeciesCategory.herb || SpeciesCategory.flower =>
    profile.frostHardy
        ? CareEnvironmentKind.outdoorPatch
        : CareEnvironmentKind.indoorRoom,
  SpeciesCategory.indoor ||
  SpeciesCategory.succulent ||
  null => CareEnvironmentKind.indoorRoom,
};

/// Les espèces dont la silhouette est connue, nom pour nom — y compris les
/// synonymes que le catalogue peut encore porter.
const _silhouettesParEspece = <String, PlantVisualKind>{
  'monstera deliciosa': PlantVisualKind.monstera,
  'monstera adansonii': PlantVisualKind.monstera,
  'sansevieria trifasciata': PlantVisualKind.uprightLeaf,
  // Le philodendron est un genre mixte : celui-ci grimpe et retombe, le
  // selloum pousse comme un arbre. La règle reste donc à l'espèce.
  'philodendron hederaceum': PlantVisualKind.vine,
};

/// Les genres dont toutes les espèces partagent une silhouette. Un genre ne
/// s'y range que quand la forme tient pour tout le genre : le dracaena, la
/// sansevieria, les fougères d'appartement.
const _silhouettesParGenre = <String, PlantVisualKind>{
  'monstera': PlantVisualKind.monstera,
  'dracaena': PlantVisualKind.uprightLeaf,
  'sansevieria': PlantVisualKind.uprightLeaf,
  'nephrolepis': PlantVisualKind.fern,
  'asplenium': PlantVisualKind.fern,
  'adiantum': PlantVisualKind.fern,
  'platycerium': PlantVisualKind.fern,
  // Les plantes qui retombent : leur tige sort du pot et pend.
  'epipremnum': PlantVisualKind.vine,
  'scindapsus': PlantVisualKind.vine,
  'tradescantia': PlantVisualKind.vine,
  'hedera': PlantVisualKind.vine,
  'cissus': PlantVisualKind.vine,
  'ceropegia': PlantVisualKind.vine,
  // Les orchidées d'appartement : la hampe arquée et ses fleurs plates.
  // Les orchidées terrestres du catalogue étendu gardent la feuille large,
  // la silhouette en pot ne leur allant pas.
  'phalaenopsis': PlantVisualKind.orchid,
  'dendrobium': PlantVisualKind.orchid,
  'cymbidium': PlantVisualKind.orchid,
  'oncidium': PlantVisualKind.orchid,
};

/// Les familles dont la forme est un trait de famille : un cactus est un
/// cactus, un pin est un conifère. Le palmier attend sa silhouette : en
/// attendant, ses palmes retombent sur les lames droites — ce qui est déjà
/// le port d'un palmier d'appartement.
const _silhouettesParFamille = <String, PlantVisualKind>{
  'Cactaceae': PlantVisualKind.cactus,
  'Pinaceae': PlantVisualKind.conifer,
  'Arecaceae': PlantVisualKind.uprightLeaf,
};

/// La silhouette de la plante dans la scène.
///
/// Ordre : l'espèce nommée, puis son genre, sa famille, sa catégorie d'usage
/// (une succulente qui n'est ni cactus ni palme tient de la rosette), et enfin
/// le repli [PlantVisualKind.broadLeaf] — une feuille large vaut mieux qu'une
/// mauvaise fougère.
PlantVisualKind resolvePlantVisual({
  String? speciesName,
  String? family,
  SpeciesCategory? category,
}) {
  final nom = speciesName?.trim().toLowerCase();
  if (nom != null && nom.isNotEmpty) {
    if (_silhouettesParEspece[nom] case final v?) return v;
    if (_silhouettesParGenre[nom.split(' ').first] case final v?) return v;
  }
  final famille = family?.trim();
  if (famille != null && famille.isNotEmpty) {
    if (_silhouettesParFamille[famille] case final v?) return v;
  }
  if (category == SpeciesCategory.succulent) return PlantVisualKind.rosette;
  return PlantVisualKind.broadLeaf;
}
