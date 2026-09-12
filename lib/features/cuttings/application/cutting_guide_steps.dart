import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../../../domain/cuttings/cutting_guide.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Une étape du guide de bouturage : son objet d'argile, son titre, son
/// texte générique, sa couleur d'ambiance.
///
/// Le texte générique vaut pour une bouture de tige dans l'eau ; l'IA le
/// précise pour l'espèce de la plante mère, quand elle la connaît. Le titre,
/// lui, ne change pas : c'est un nom, celui de la chose qu'on regarde.
class CuttingGuideStep {
  const CuttingGuideStep({required this.step, required this.title, required this.body, required this.tint});

  final CuttingStep step;
  final String Function(AppLocalizations) title;
  final String Function(AppLocalizations) body;

  /// Couleur d'ambiance de l'étape.
  final Color Function(FloraColors) tint;

  /// La séquence d'images de l'étape, rendue sous Blender.
  String get asset => assetOf(step);

  static String assetOf(CuttingStep step) => 'assets/cutting/etape_${step.index + 1}.webp';
}

/// Les six étapes, dans l'ordre du geste. Les couleurs suivent la matière :
/// la plante, la lame, la plante, l'eau, la plante, la terre.
final cuttingGuideSteps = <CuttingGuideStep>[
  CuttingGuideStep(step: CuttingStep.stem, title: (l) => l.cuttingGuideStemTitle, body: (l) => l.cuttingGuideStemBody, tint: (c) => c.sage),
  CuttingGuideStep(step: CuttingStep.cut, title: (l) => l.cuttingGuideCutTitle, body: (l) => l.cuttingGuideCutBody, tint: (c) => c.sun),
  CuttingGuideStep(step: CuttingStep.leaves, title: (l) => l.cuttingGuideLeavesTitle, body: (l) => l.cuttingGuideLeavesBody, tint: (c) => c.sage),
  CuttingGuideStep(step: CuttingStep.water, title: (l) => l.cuttingGuideWaterTitle, body: (l) => l.cuttingGuideWaterBody, tint: (c) => c.water),
  CuttingGuideStep(step: CuttingStep.roots, title: (l) => l.cuttingGuideRootsTitle, body: (l) => l.cuttingGuideRootsBody, tint: (c) => c.sage),
  CuttingGuideStep(step: CuttingStep.pot, title: (l) => l.cuttingGuidePotTitle, body: (l) => l.cuttingGuidePotBody, tint: (c) => c.terracotta),
];
