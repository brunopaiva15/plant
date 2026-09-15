import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../../../domain/care/care_profile.dart';
import '../../../domain/cuttings/propagation_guide.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Ce que dit la petite ligne sous le texte d'une étape.
enum PropagationNoteKind {
  /// Ce qu'il faut regarder — « Nœud et racine aérienne ».
  spot,

  /// L'erreur courante — « Couper au-dessus du nœud ».
  avoid,

  /// L'ordre de grandeur — « Premières racines en deux à six semaines ».
  usual,

  /// Le milieu d'enracinement, qui ne vient pas du guide mais de la fiche
  /// d'espèce — « Eau ou substrat léger ».
  medium,
}

/// Une précision secondaire, sous le texte de l'étape. Rare : elle n'est là
/// que là où elle change ce que la personne va faire.
class PropagationNote {
  const PropagationNote(this.kind, this.value);

  final PropagationNoteKind kind;
  final String Function(AppLocalizations) value;

  String label(AppLocalizations l) => switch (kind) {
        PropagationNoteKind.spot => l.pgNoteSpot,
        PropagationNoteKind.avoid => l.pgNoteAvoid,
        PropagationNoteKind.usual => l.pgNoteUsual,
        PropagationNoteKind.medium => l.pgNoteMedium,
      };
}

/// Une étape d'un guide de multiplication : son objet d'argile, son titre,
/// son texte local, sa couleur d'ambiance.
///
/// Le texte local vaut pour l'archétype, pas pour l'espèce : il est déjà
/// juste sans IA. Quand l'IA connaît l'espèce, elle le remplace. Le titre,
/// lui, ne change pas : c'est un nom, celui de ce qu'on regarde.
class PropagationStep {
  const PropagationStep({
    required this.id,
    required this.title,
    required this.fallbackBody,
    required this.asset,
    required this.tint,
    this.note,
    this.showsMedium = false,
  });

  /// Identifiant stable de l'étape, tel qu'il part vers l'IA et nomme son
  /// fichier d'images.
  final String id;

  final String Function(AppLocalizations) title;
  final String Function(AppLocalizations) fallbackBody;

  /// La séquence d'images de l'étape, rendue sous Blender.
  final String asset;

  /// Couleur d'ambiance de l'étape.
  final Color Function(FloraColors) tint;

  final PropagationNote? note;

  /// Cette étape met la bouture à enraciner : sa note dit le milieu que la
  /// fiche de l'espèce conseille, pas une généralité du guide.
  final bool showsMedium;
}

/// Un guide : l'archétype, son nom, et ses étapes dans l'ordre du geste.
///
/// Le nombre d'étapes appartient au guide. Rien, dans l'application, ne
/// suppose qu'il en faut six.
class PropagationGuide {
  const PropagationGuide({required this.kind, required this.name, required this.hint, required this.steps});

  final PropagationGuideKind kind;

  /// « Bouture de tige », « Division », « Séparer un rejet ».
  final String Function(AppLocalizations) name;

  /// Une ligne qui aide à choisir, sur l'écran des méthodes.
  final String Function(AppLocalizations) hint;

  final List<PropagationStep> steps;

  int get length => steps.length;

  List<String> get stepIds => [for (final s in steps) s.id];

  /// Le bouton qui clôt le guide : on crée une bouture, mais on sépare une
  /// division ou un rejet — appeler ça une bouture serait faux.
  String startLabel(AppLocalizations l) => switch (kind) {
        PropagationGuideKind.division || PropagationGuideKind.offset => l.pgStartPlant,
        _ => l.pgStartCutting,
      };
}

String _dossier(PropagationGuideKind kind) => switch (kind) {
      PropagationGuideKind.stemNodeVine => 'stem_node_vine',
      PropagationGuideKind.stemSoft => 'stem_soft',
      PropagationGuideKind.leafCutting => 'leaf_cutting',
      PropagationGuideKind.division => 'division',
      PropagationGuideKind.offset => 'offset',
      PropagationGuideKind.succulentSegment => 'succulent_segment',
    };

/// Le chemin de la séquence d'une étape.
String propagationAsset(PropagationGuideKind kind, String stepId) => 'assets/cutting/${_dossier(kind)}/$stepId.webp';

/// Ce qu'une étape porte en plus de son identifiant, dans l'ordre de
/// [propagationStepIds].
typedef _Texte = (
  String Function(AppLocalizations) titre,
  String Function(AppLocalizations) corps,
  Color Function(FloraColors) teinte,
  PropagationNote? note,
  bool milieu,
);

/// Assemble un guide : les identifiants viennent du domaine, les textes
/// d'ici. Les deux listes ont forcément la même longueur — ajouter une
/// étape, c'est l'ajouter des deux côtés.
PropagationGuide _guide(
  PropagationGuideKind kind,
  String Function(AppLocalizations) name,
  String Function(AppLocalizations) hint,
  List<_Texte> textes,
) {
  final ids = propagationStepIds[kind]!;
  assert(ids.length == textes.length, 'le guide ${kind.name} n\'a pas le même nombre d\'étapes que ses identifiants');
  return PropagationGuide(
    kind: kind,
    name: name,
    hint: hint,
    steps: [
      for (final (i, id) in ids.indexed)
        PropagationStep(
          id: id,
          title: textes[i].$1,
          fallbackBody: textes[i].$2,
          asset: propagationAsset(kind, id),
          tint: textes[i].$3,
          note: textes[i].$4,
          showsMedium: textes[i].$5,
        ),
    ],
  );
}

// ── Les guides ───────────────────────────────────────────────────────────
// Les couleurs suivent la matière : la plante, la lame, l'eau, la terre.

/// Bouture de tige à nœud — pothos, monstera, philodendron.
final _stemNodeVine = _guide(
  PropagationGuideKind.stemNodeVine,
  (l) => l.pgVineName,
  (l) => l.pgVineHint,
  [
    ((l) => l.pgVineNodeTitle, (l) => l.pgVineNodeBody, (c) => c.sage, PropagationNote(PropagationNoteKind.spot, (l) => l.pgVineNodeNote), false),
    ((l) => l.pgVineCutTitle, (l) => l.pgVineCutBody, (c) => c.sun, PropagationNote(PropagationNoteKind.avoid, (l) => l.pgVineCutNote), false),
    ((l) => l.pgVineClearTitle, (l) => l.pgVineClearBody, (c) => c.sage, null, false),
    ((l) => l.pgVineWaterTitle, (l) => l.pgVineWaterBody, (c) => c.water, null, true),
    ((l) => l.pgVineRootsTitle, (l) => l.pgVineRootsBody, (c) => c.sage, PropagationNote(PropagationNoteKind.usual, (l) => l.pgVineRootsNote), false),
    ((l) => l.pgVinePotTitle, (l) => l.pgVinePotBody, (c) => c.terracotta, null, false),
  ],
);

/// Bouture de tige tendre — basilic, menthe, coleus.
final _stemSoft = _guide(
  PropagationGuideKind.stemSoft,
  (l) => l.pgSoftName,
  (l) => l.pgSoftHint,
  [
    ((l) => l.pgSoftStemTitle, (l) => l.pgSoftStemBody, (c) => c.sage, null, false),
    ((l) => l.pgSoftCutTitle, (l) => l.pgSoftCutBody, (c) => c.sun, null, false),
    ((l) => l.pgSoftStripTitle, (l) => l.pgSoftStripBody, (c) => c.sage, PropagationNote(PropagationNoteKind.avoid, (l) => l.pgSoftStripNote), false),
    ((l) => l.pgSoftRootTitle, (l) => l.pgSoftRootBody, (c) => c.water, null, true),
    ((l) => l.pgSoftRootsTitle, (l) => l.pgSoftRootsBody, (c) => c.sage, PropagationNote(PropagationNoteKind.usual, (l) => l.pgSoftRootsNote), false),
    ((l) => l.pgSoftPotTitle, (l) => l.pgSoftPotBody, (c) => c.terracotta, null, false),
  ],
);

/// Bouture de feuille — sansevieria, ZZ, bégonia.
final _leafCutting = _guide(
  PropagationGuideKind.leafCutting,
  (l) => l.pgLeafName,
  (l) => l.pgLeafHint,
  [
    ((l) => l.pgLeafChooseTitle, (l) => l.pgLeafChooseBody, (c) => c.sage, null, false),
    ((l) => l.pgLeafCutTitle, (l) => l.pgLeafCutBody, (c) => c.sun, null, false),
    ((l) => l.pgLeafSplitTitle, (l) => l.pgLeafSplitBody, (c) => c.sage, PropagationNote(PropagationNoteKind.spot, (l) => l.pgLeafSplitNote), false),
    ((l) => l.pgLeafCallusTitle, (l) => l.pgLeafCallusBody, (c) => c.sun, PropagationNote(PropagationNoteKind.usual, (l) => l.pgLeafCallusNote), false),
    ((l) => l.pgLeafPlantTitle, (l) => l.pgLeafPlantBody, (c) => c.terracotta, PropagationNote(PropagationNoteKind.avoid, (l) => l.pgLeafPlantNote), false),
    ((l) => l.pgLeafGrowthTitle, (l) => l.pgLeafGrowthBody, (c) => c.sage, PropagationNote(PropagationNoteKind.usual, (l) => l.pgLeafGrowthNote), false),
  ],
);

/// Division d'une touffe — spathiphyllum, graminées, fougères.
final _division = _guide(
  PropagationGuideKind.division,
  (l) => l.pgDivisionName,
  (l) => l.pgDivisionHint,
  [
    ((l) => l.pgDivPlantTitle, (l) => l.pgDivPlantBody, (c) => c.sage, null, false),
    ((l) => l.pgDivUnpotTitle, (l) => l.pgDivUnpotBody, (c) => c.terracotta, null, false),
    ((l) => l.pgDivRootsTitle, (l) => l.pgDivRootsBody, (c) => c.terracotta, null, false),
    ((l) => l.pgDivClustersTitle, (l) => l.pgDivClustersBody, (c) => c.sun, PropagationNote(PropagationNoteKind.spot, (l) => l.pgDivClustersNote), false),
    ((l) => l.pgDivSplitTitle, (l) => l.pgDivSplitBody, (c) => c.sage, PropagationNote(PropagationNoteKind.avoid, (l) => l.pgDivSplitNote), false),
    ((l) => l.pgDivRepotTitle, (l) => l.pgDivRepotBody, (c) => c.terracotta, null, false),
  ],
);

/// Séparation d'un rejet — pilea, aloe, chlorophytum.
final _offset = _guide(
  PropagationGuideKind.offset,
  (l) => l.pgOffsetName,
  (l) => l.pgOffsetHint,
  [
    ((l) => l.pgOffSpotTitle, (l) => l.pgOffSpotBody, (c) => c.sage, PropagationNote(PropagationNoteKind.spot, (l) => l.pgOffSpotNote), false),
    ((l) => l.pgOffClearTitle, (l) => l.pgOffClearBody, (c) => c.terracotta, null, false),
    ((l) => l.pgOffDetachTitle, (l) => l.pgOffDetachBody, (c) => c.sun, PropagationNote(PropagationNoteKind.avoid, (l) => l.pgOffDetachNote), false),
    ((l) => l.pgOffRootsTitle, (l) => l.pgOffRootsBody, (c) => c.sage, null, false),
    ((l) => l.pgOffPotTitle, (l) => l.pgOffPotBody, (c) => c.terracotta, null, false),
    ((l) => l.pgOffSettleTitle, (l) => l.pgOffSettleBody, (c) => c.sage, PropagationNote(PropagationNoteKind.usual, (l) => l.pgOffSettleNote), false),
  ],
);

/// Bouture de segment — cactus et succulentes à segments.
final _succulentSegment = _guide(
  PropagationGuideKind.succulentSegment,
  (l) => l.pgSegmentName,
  (l) => l.pgSegmentHint,
  [
    ((l) => l.pgSegChooseTitle, (l) => l.pgSegChooseBody, (c) => c.sage, null, false),
    ((l) => l.pgSegDetachTitle, (l) => l.pgSegDetachBody, (c) => c.sun, PropagationNote(PropagationNoteKind.avoid, (l) => l.pgSegDetachNote), false),
    ((l) => l.pgSegWoundTitle, (l) => l.pgSegWoundBody, (c) => c.rose, null, false),
    ((l) => l.pgSegCallusTitle, (l) => l.pgSegCallusBody, (c) => c.sun, PropagationNote(PropagationNoteKind.usual, (l) => l.pgSegCallusNote), false),
    ((l) => l.pgSegPlantTitle, (l) => l.pgSegPlantBody, (c) => c.terracotta, PropagationNote(PropagationNoteKind.avoid, (l) => l.pgSegPlantNote), false),
    ((l) => l.pgSegRootsTitle, (l) => l.pgSegRootsBody, (c) => c.sage, null, false),
  ],
);

/// Tous les guides, par archétype.
final propagationGuides = <PropagationGuideKind, PropagationGuide>{
  PropagationGuideKind.stemNodeVine: _stemNodeVine,
  PropagationGuideKind.stemSoft: _stemSoft,
  PropagationGuideKind.leafCutting: _leafCutting,
  PropagationGuideKind.division: _division,
  PropagationGuideKind.offset: _offset,
  PropagationGuideKind.succulentSegment: _succulentSegment,
};

PropagationGuide propagationGuideOf(PropagationGuideKind kind) => propagationGuides[kind]!;

/// Le milieu d'enracinement, dit en une ligne sous l'étape qui met en terre
/// ou dans l'eau. `none` ne se dit pas : il n'y a rien à enraciner.
String? rootingMediumLabel(AppLocalizations l, RootingMedium medium) => switch (medium) {
      RootingMedium.water => l.pgMediumWater,
      RootingMedium.substrate => l.pgMediumSubstrate,
      RootingMedium.either => l.pgMediumEither,
      RootingMedium.none => null,
    };
