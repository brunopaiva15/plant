import '../../../domain/care/care_profile.dart';
import '../../../domain/species/species_info.dart';
import 'care_environment_slots.dart';

/// Le décor de la scène d'environnement idéal : une pièce, un balcon, ou un
/// coin de jardin.
///
/// Les trois disent la même chose de l'espèce, à un cran près : elle vit
/// dedans, elle vit dehors mais en pot, ou elle vit dehors en pleine terre.
/// Ce n'est pas une préférence de décor, c'est ce que la fiche sait de sa
/// rusticité — et c'est [environmentFor] qui en décide, nulle part ailleurs.
enum CareEnvironmentKind { indoorRoom, balcony, outdoorPatch }

/// Le support visuel de la plante dans le diorama.
///
/// Dans la pièce, une plante de petit ou moyen gabarit est posée sur le
/// guéridon. Les plantes manifestement trop grandes restent au sol. Dehors,
/// le sol est toujours le support naturel.
enum CarePlantSupport { pedestal, floor }

/// Les emplacements de plante dans le cadre, nommés comme les clés de
/// [CareEnvironmentSlots.slots] — la distance à la fenêtre encode le besoin
/// de lumière. Pour une plante compacte, le guéridon se déplace jusqu'à ce
/// slot ; pour une grande plante, c'est directement le pot qui s'y pose.
///
/// Les six tiennent sur une droite, à pas constant, du fond de la pièce
/// jusque dans la tache de soleil : d'une fiche à l'autre la plante avance
/// d'un cran vers la lumière, elle ne saute pas d'un coin à l'autre. Les
/// trois derniers crans se lisent sur la tache : à côté, sur son bord,
/// dedans.
enum CarePlantSlot { backCorner, back, middle, besideBeam, beamEdge, sunZone }

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
    this.humidityMethods = const {},
    this.support = CarePlantSupport.floor,
    this.airflow,
    this.tempRange,
    this.tempFloorC,
  });

  /// Pièce ou dehors.
  final CareEnvironmentKind environment;

  /// La variante lumineuse du décor : le besoin de la fiche, jamais la
  /// lumière réelle de l'emplacement — la scène montre l'idéal, pas l'état.
  final LightNeed light;

  /// Où le support de la plante se pose dans le cadre.
  final CarePlantSlot slot;

  /// Sa silhouette.
  final PlantVisualKind plant;

  /// Guéridon pour les petits/moyens gabarits, sol pour les grands.
  final CarePlantSupport support;

  final HumidityNeed humidity;

  /// La plage d'hygrométrie affichée en callout : celle de l'espèce quand
  /// elle est renseignée, celle du besoin sinon (cf. [CareProfile.humidityRange]).
  final (int, int) humidityRange;

  /// Comment tenir l'air, quand la fiche le sait. Vide = rien n'est inventé
  /// dans la scène : pas de machine, pas de plateau.
  final Set<HumidityMethod> humidityMethods;

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
    CareEnvironmentKind.balcony =>
      'assets/care_scene/balcony/light/${_lightFile(light)}.webp',
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

  /// L'emplacement au sol qui correspond au besoin lumineux.
  (double, double) get slotFraction => CareEnvironmentSlots.slots[slot.name]!;

  /// Le guéridon n'existe que dans la pièce et uniquement pour les plantes
  /// dont le gabarit permet réellement de les y poser.
  bool get hasPedestal =>
      environment == CareEnvironmentKind.indoorRoom &&
      support == CarePlantSupport.pedestal;

  /// Le guéridon est un prop rendu seul, posé sur le slot lumineux.
  String get pedestalAsset => 'assets/care_scene/props/pedestal.webp';

  /// La base du pot : sur le plateau du guéridon posé au slot, ou directement
  /// au slot lumineux pour un grand gabarit. Le plateau est au-dessus de la
  /// base du meuble dans son image : le décalage est lu dans la table.
  (double, double) get plantFraction {
    if (!hasPedestal) return slotFraction;
    final s = slotFraction;
    const p = CareEnvironmentSlots.pedestalPot;
    const a = CareEnvironmentSlots.anchor;
    return (s.$1 + p.$1 - a.$1, s.$2 + p.$2 - a.$2);
  }

  /// L'humidificateur ne paraît que si la fiche le prescrit : air humide, et
  /// `HumidityMethod.humidifier` parmi les méthodes. Un besoin sans méthode,
  /// ou la brume seule, n'inventent pas une machine.
  bool get hasHumidifier =>
      humidity == HumidityNeed.high &&
      humidityMethods.contains(HumidityMethod.humidifier);

  /// Le plateau de billes, quand c'est lui qui tient l'air — et seulement
  /// s'il n'y a pas déjà l'humidificateur : un seul prop d'humidité.
  /// L'image n'est pas encore livrée : la scène ne le pose pas.
  bool get hasHumidityTray =>
      humidity == HumidityNeed.high &&
      !hasHumidifier &&
      humidityMethods.contains(HumidityMethod.tray);

  /// Le plateau, même emplacement que l'humidificateur, une fois rendu.
  String get humidityTrayAsset => 'assets/care_scene/props/humidity_tray.webp';

  /// Où il se pose : à côté de la plante, quel que soit son support.
  (double, double) get humidifierFraction =>
      CareEnvironmentSlots.humidifier[slot.name]!;

  /// D'où part la vapeur.
  (double, double) get steamOriginFraction =>
      CareEnvironmentSlots.humidifierTop[slot.name]!;

  /// D'où souffle l'air à abriter : la fenêtre dans la pièce, l'ouverture
  /// au-dessus de la haie dehors, le vide par-dessus le garde-corps sur un
  /// balcon. Un courant d'air vient d'une ouverture, jamais d'une machine.
  (double, double) get airflowOriginFraction =>
      CareEnvironmentSlots.airflow[switch (environment) {
        CareEnvironmentKind.indoorRoom => 'indoor',
        CareEnvironmentKind.balcony => 'balcony',
        CareEnvironmentKind.outdoorPatch => 'outdoor',
      }]!;

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
  final environment = environmentFor(profile, category);
  final plant = resolvePlantVisual(
    speciesName: speciesName,
    family: family,
    category: category,
  );
  return CareEnvironmentVisualSpec(
    environment: environment,
    light: profile.light,
    // Même caméra, même direction de soleil dans les deux décors : la table
    // des emplacements vaut pour la pièce comme pour le jardin.
    slot: slotFor(profile.light),
    plant: plant,
    support: resolvePlantSupport(
      environment: environment,
      speciesName: speciesName,
      family: family,
      plant: plant,
    ),
    humidity: profile.humidity,
    humidityRange: profile.humidityRange,
    humidityMethods: profile.humidityMethods,
    airflow: profile.airflow,
    tempRange: plage,
    // Le seuil de dégâts ne se dit que faute de plage idéale : les deux
    // ensemble feraient double emploi sur la même puce.
    tempFloorC: plage == null ? profile.damageBelowC : null,
  );
}

/// L'emplacement qui dit le besoin de lumière : du fond de la pièce, loin
/// de la fenêtre, jusqu'au cœur de la tache de soleil, un cran à la fois.
CarePlantSlot slotFor(LightNeed light) => switch (light) {
  LightNeed.shade => CarePlantSlot.backCorner,
  LightNeed.lowLight => CarePlantSlot.back,
  LightNeed.indirect => CarePlantSlot.middle,
  LightNeed.brightIndirect => CarePlantSlot.besideBeam,
  LightNeed.someSun => CarePlantSlot.beamEdge,
  LightNeed.fullSun => CarePlantSlot.sunZone,
};

/// Pièce, balcon ou jardin, décidé ici et nulle part ailleurs.
///
/// La catégorie d'usage donne le premier mot, la rusticité le second. Les
/// deux notions existaient déjà dans la fiche, avec exactement ce sens :
/// [CareProfile.frostHardy] dit qu'elle tient le gel, *donc qu'elle vit
/// dehors en pleine terre* ; [CareProfile.outdoorFriendly] qu'elle passe la
/// belle saison dehors sans pour autant la passer en terre. Entre les deux
/// il y a le balcon : dehors, mais en pot, et qui rentre l'hiver.
///
/// Ce que le balcon corrige : un citronnier — `fruit`, non rustique —
/// était planté dans une pelouse, et une aromatique gélive était envoyée
/// dans le salon alors que sa place est dehors en pot.
///
/// Rien n'est inventé : sans `outdoorFriendly`, une plante gélive dont la
/// fiche ne dit pas qu'elle sort reste dans la pièce.
///
/// Les succulentes suivent la même règle. Elle n'a pu être activée qu'après
/// correction de leurs fiches : quinze d'entre elles héritaient d'un profil
/// de genre ou de famille taillé pour leurs cousines de jardin et se
/// déclaraient rustiques — une *Euphorbia obesa* annonçait −10 °C. La règle
/// les aurait plantées dans une pelouse.
///
/// Sans catégorie (catalogue étendu), la pièce est le repli : les plantes de
/// l'app sont d'abord des plantes d'intérieur.
CareEnvironmentKind environmentFor(
  CareProfile profile,
  SpeciesCategory? category,
) => switch (category) {
  // Ce qui vit dehors de toute façon : la rusticité dit seulement si c'est
  // en pleine terre ou en pot. Un arbre ne finit jamais dans un salon.
  SpeciesCategory.tree ||
  SpeciesCategory.fruit ||
  SpeciesCategory.vegetable => profile.frostHardy
      ? CareEnvironmentKind.outdoorPatch
      : CareEnvironmentKind.balcony,
  // Ce qui peut aller dans les deux sens. Les succulentes en sont : un
  // sempervivum passe l'hiver sur un toit, une echeveria passe l'été
  // dehors en pot, une euphorbe de collection ne sort pas.
  SpeciesCategory.herb ||
  SpeciesCategory.flower ||
  SpeciesCategory.succulent => profile.frostHardy
      ? CareEnvironmentKind.outdoorPatch
      : profile.outdoorFriendly
      ? CareEnvironmentKind.balcony
      : CareEnvironmentKind.indoorRoom,
  SpeciesCategory.indoor || null => CareEnvironmentKind.indoorRoom,
};

/// Espèces d'intérieur dont le gabarit adulte est sans ambiguïté celui d'une
/// plante de sol. La règle reste volontairement conservatrice : sans donnée
/// de taille fiable dans la fiche, mieux vaut garder un petit sujet sur le
/// guéridon que bannir à tort tout un genre qui contient aussi des formes
/// compactes.
const _floorSpecies = <String>{
  'monstera deliciosa',
  'dracaena marginata',
  'ficus elastica',
  'strelitzia nicolai',
  'strelitzia reginae',
  'yucca elephantipes',
  'yucca gigantea',
  'pachira aquatica',
  'beaucarnea recurvata',
  'philodendron bipinnatifidum',
  'thaumatophyllum bipinnatifidum',
  'alocasia macrorrhizos',
};

/// Genres dont le port vendu comme plante d'intérieur est presque toujours
/// celui d'un sujet posé au sol. Les genres très variables (Ficus, Monstera,
/// Philodendron…) restent traités à l'espèce ci-dessus.
const _floorGenera = <String>{'strelitzia', 'pachira', 'beaucarnea'};

/// Choisit le support sans inventer une taille précise absente des données.
///
/// Dehors : toujours au sol. Dedans : guéridon par défaut, sauf signaux
/// suffisamment forts qu'il s'agit d'une grande plante (espèce connue,
/// palmier, conifère). Cette fonction pourra être remplacée directement par
/// une hauteur adulte lorsque le catalogue la portera.
CarePlantSupport resolvePlantSupport({
  required CareEnvironmentKind environment,
  String? speciesName,
  String? family,
  required PlantVisualKind plant,
}) {
  // Le guéridon est un meuble de salon : dehors comme au balcon, un pot se
  // pose par terre.
  if (environment != CareEnvironmentKind.indoorRoom) {
    return CarePlantSupport.floor;
  }

  final nom = speciesName?.trim().toLowerCase();
  if (nom != null && nom.isNotEmpty) {
    if (_floorSpecies.contains(nom)) return CarePlantSupport.floor;
    if (_floorGenera.contains(nom.split(' ').first)) {
      return CarePlantSupport.floor;
    }
  }

  if (family?.trim().toLowerCase() == 'arecaceae') {
    return CarePlantSupport.floor;
  }
  if (plant == PlantVisualKind.conifer) return CarePlantSupport.floor;

  return CarePlantSupport.pedestal;
}

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
