import '../care/care_profile.dart';
import 'propagation_guide.dart';

/// Une façon de multiplier une plante : la méthode telle que la fiche
/// d'entretien la nomme, le guide qui montre le geste, et le milieu où la
/// bouture prendra racine.
class PropagationOption {
  const PropagationOption({required this.method, required this.kind, required this.medium});

  final Propagation method;
  final PropagationGuideKind kind;
  final RootingMedium medium;

  @override
  bool operator ==(Object other) =>
      other is PropagationOption && other.method == method && other.kind == kind && other.medium == medium;

  @override
  int get hashCode => Object.hash(method, kind, medium);

  @override
  String toString() => 'PropagationOption(${method.name}, ${kind.name}, ${medium.name})';
}

// ── Les genres qu'on reconnaît ────────────────────────────────────────────
// Rien de botaniquement exhaustif : juste ce qu'il faut pour que le geste
// montré soit le bon. Une plante qui n'est dans aucune liste retombe sur la
// règle générale au bas de [_stemKindOf], qui ne se trompe pas souvent.

/// Lianes et plantes grimpantes à nœuds lisibles.
const _vineGenera = {
  'monstera', 'epipremnum', 'scindapsus', 'philodendron', 'rhaphidophora', 'syngonium',
  'cissus', 'hoya', 'ceropegia', 'tradescantia', 'callisia', 'piper', 'senecio',
  'epipremnoides', 'anthurium', 'thaumatophyllum',
};

/// Herbacées à tige tendre : la bouture se fait sur un jeune brin.
const _softStemGenera = {
  'mentha', 'ocimum', 'salvia', 'origanum', 'thymus', 'melissa', 'nepeta', 'lavandula',
  'plectranthus', 'coleus', 'solenostemon', 'pelargonium', 'impatiens', 'fuchsia',
  'petunia', 'basilicum', 'stevia', 'verbena', 'dahlia', 'chrysanthemum',
};
const _softStemFamilies = {'lamiaceae', 'balsaminaceae', 'geraniaceae', 'verbenaceae'};

/// Cactus et succulentes à segments : on détache, on laisse cicatriser.
const _cactusGenera = {
  'schlumbergera', 'rhipsalis', 'hatiora', 'epiphyllum', 'opuntia', 'cereus', 'echinopsis',
  'mammillaria', 'selenicereus', 'disocactus', 'aporocactus', 'gymnocalycium', 'ferocactus',
};
const _cactusFamilies = {'cactaceae'};

/// Succulentes non cactées qu'on bouture par feuille ou par segment, avec
/// cicatrisation : le geste du pack « segment » leur convient.
const _succulentGenera = {
  'crassula', 'sedum', 'kalanchoe', 'echeveria', 'graptopetalum', 'pachyphytum',
  'portulacaria', 'aeonium', 'sempervivum', 'cotyledon', 'x graptoveria',
};

/// Plantes à rosette ou à rejet franc : on sépare, on ne coupe pas.
const _offsetGenera = {
  'aloe', 'pilea', 'haworthia', 'haworthiopsis', 'gasteria', 'agave', 'chlorophytum',
  'phalaenopsis', 'guzmania', 'vriesea', 'aechmea', 'neoregelia', 'ananas', 'musa',
};

/// Plantes en touffe : on partage la motte.
const _divisionFamilies = {'poaceae', 'cyperaceae', 'juncaceae'};

/// Le genre d'un nom scientifique, en minuscules. « Monstera deliciosa » →
/// « monstera ».
String? genusOf(String? scientificName) {
  final name = scientificName?.trim() ?? '';
  if (name.isEmpty) return null;
  final genus = name.split(RegExp(r'\s+')).first.toLowerCase();
  return genus.isEmpty ? null : genus;
}

bool _isCactus(String? genus, String? family) =>
    (genus != null && _cactusGenera.contains(genus)) || (family != null && _cactusFamilies.contains(family));

bool _isSucculent(String? genus, CareProfile profile) =>
    (genus != null && _succulentGenera.contains(genus)) || profile.soil == SoilKind.cactus;

/// Quel geste de bouture de tige : liane à nœud, tige tendre, ou segment de
/// succulente.
PropagationGuideKind _stemKindOf(String? genus, String? family, CareProfile profile) {
  if (_isCactus(genus, family)) return PropagationGuideKind.succulentSegment;
  if (genus != null && _softStemGenera.contains(genus)) return PropagationGuideKind.stemSoft;
  if (family != null && _softStemFamilies.contains(family)) return PropagationGuideKind.stemSoft;
  if (genus != null && _vineGenera.contains(genus)) return PropagationGuideKind.stemNodeVine;
  if (genus != null && _succulentGenera.contains(genus)) return PropagationGuideKind.succulentSegment;
  if (profile.soil == SoilKind.cactus) return PropagationGuideKind.succulentSegment;
  // Une annuelle n'a pas de vieux bois : sa tige est tendre.
  if (profile.repotEveryMonths == null) return PropagationGuideKind.stemSoft;
  return PropagationGuideKind.stemNodeVine;
}

/// Le guide qui montre [method] pour cette plante, ou `null` quand la
/// méthode ne se montre pas — un semis n'est pas une bouture.
PropagationGuideKind? _kindOf(Propagation method, String? genus, String? family, CareProfile profile) {
  final cactus = _isCactus(genus, family);
  return switch (method) {
    Propagation.stemCutting => _stemKindOf(genus, family, profile),
    // Une feuille de succulente se détache, cicatrise et se pose : c'est le
    // geste du segment, pas celui de la lame de sansevieria.
    Propagation.leafCutting =>
      _isSucculent(genus, profile) ? PropagationGuideKind.succulentSegment : PropagationGuideKind.leafCutting,
    Propagation.division => PropagationGuideKind.division,
    // Un rejet de cactus se traite comme un segment : on le détache et on le
    // laisse sécher. Pour tout le reste, c'est le geste du rejet.
    Propagation.offsets => cactus ? PropagationGuideKind.succulentSegment : PropagationGuideKind.offset,
    // Un tubercule se sépare comme une touffe.
    Propagation.tuber => PropagationGuideKind.division,
    // Le marcottage n'a pas son guide : le geste le plus proche est la
    // bouture de tige à nœud, dont la racine aérienne est déjà l'idée.
    Propagation.layering => PropagationGuideKind.stemNodeVine,
    Propagation.seed || Propagation.water => null,
  };
}

/// Les façons de multiplier cette plante, la conseillée d'abord.
///
/// L'ordre suit celui de `CareProfile.propagation` : la première méthode
/// écrite dans la fiche est celle qu'on conseille. Deux méthodes qui
/// montrent le même geste n'en font qu'une — inutile de proposer deux fois
/// la même animation.
///
/// Rend toujours au moins une option : une plante dont la fiche ne connaît
/// que le semis se bouture quand même, et le guide générique de son port
/// vaut mieux que rien.
List<PropagationOption> resolvePropagationOptions({
  required CareProfile profile,
  String? scientificName,
  String? family,
}) {
  final genus = genusOf(scientificName);
  final fam = family?.trim().toLowerCase();
  final medium = profile.rootingMedium;
  final options = <PropagationOption>[];
  final vus = <PropagationGuideKind>{};

  void ajoute(Propagation method, PropagationGuideKind kind) {
    if (!vus.add(kind)) return;
    options.add(PropagationOption(
      method: method,
      kind: kind,
      // Une division ou un rejet n'a rien à enraciner, quoi que dise la fiche.
      medium: switch (kind) {
        PropagationGuideKind.division || PropagationGuideKind.offset => RootingMedium.none,
        PropagationGuideKind.succulentSegment => RootingMedium.substrate,
        PropagationGuideKind.leafCutting => RootingMedium.substrate,
        _ => medium == RootingMedium.none ? RootingMedium.either : medium,
      },
    ));
  }

  final methods = profile.propagationMethods;
  // Le marcottage ne se montre que s'il est seul : ailleurs il ferait doublon
  // avec la bouture de tige.
  final retenues = methods.where((m) => m != Propagation.layering || methods.length == 1);
  for (final method in retenues) {
    final kind = _kindOf(method, genus, fam, profile);
    if (kind != null) ajoute(method, kind);
  }

  if (options.isEmpty) {
    final touffe = (fam != null && _divisionFamilies.contains(fam)) || (genus != null && _offsetGenera.contains(genus));
    if (touffe) {
      ajoute(Propagation.division, PropagationGuideKind.division);
    } else {
      ajoute(Propagation.stemCutting, _stemKindOf(genus, fam, profile));
    }
  }
  // Trois choix suffisent : au-delà, l'écran de choix devient une fiche.
  return options.length > 3 ? options.sublist(0, 3) : options;
}

/// Le guide conseillé pour cette plante.
PropagationOption resolvePropagationGuide({
  required CareProfile profile,
  String? scientificName,
  String? family,
}) =>
    resolvePropagationOptions(profile: profile, scientificName: scientificName, family: family).first;
