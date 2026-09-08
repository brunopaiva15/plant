import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../domain/problems/plant_problem.dart';
import '../../onboarding/presentation/clay_illustration.dart';
import 'illustrated_problems.dart';

/// Le nom d'une famille de problèmes, au singulier et au pluriel.
///
/// Le pluriel titre un groupe de la fiche de soin ; le singulier ne se lit
/// pas, il nomme l'image pour qui écoute l'écran.
extension ProblemKindLabels on AppLocalizations {
  String problemKindName(ProblemKind kind) => switch (kind) {
        ProblemKind.disorder => problemKindDisorder,
        ProblemKind.pest => problemKindPest,
        ProblemKind.disease => problemKindDisease,
        ProblemKind.condition => problemKindCondition,
      };

  String problemKindPlural(ProblemKind kind) => switch (kind) {
        ProblemKind.disorder => problemKindDisorders,
        ProblemKind.pest => problemKindPests,
        ProblemKind.disease => problemKindDiseases,
        ProblemKind.condition => problemKindConditions,
      };
}

/// Le symbole d'argile d'une famille de problèmes.
///
/// Quatre images rendues dans le même studio que les illustrations de
/// l'onboarding — même argile mate, même palette, même lumière — pour que la
/// fiche de soin et le diagnostic parlent la même matière que le reste.
///
/// Posé, sans respiration : une liste où chaque ligne flotte serait un
/// vivarium. La respiration reste disponible pour un usage en grand, en
/// enveloppant l'image dans [ClayFloat].
///
/// Les dessins sont chargés et lisibles autour de quarante points ; en
/// dessous de trente, le soleil et la goutte du trouble abiotique se
/// referment sur eux-mêmes. D'où le regroupement par famille sur la fiche,
/// plutôt qu'une vignette par ligne.
class ProblemKindIcon extends StatelessWidget {
  const ProblemKindIcon({super.key, required this.kind, this.side = 40});

  final ProblemKind kind;

  /// Côté en points. Les images font 512 px et sont décodées à la taille où
  /// elles s'affichent, pas à celle du fichier.
  final double side;

  static String assetOf(ProblemKind kind) => switch (kind) {
        ProblemKind.disorder => 'assets/problems/clay_abiotique.webp',
        ProblemKind.pest => 'assets/problems/clay_ravageur.webp',
        ProblemKind.disease => 'assets/problems/clay_maladie.webp',
        ProblemKind.condition => 'assets/problems/clay_affection.webp',
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Image(
      image: ClayIllustration.provider(assetOf(kind), side, MediaQuery.devicePixelRatioOf(context)),
      width: side,
      height: side,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      // L'image porte l'information que le nom seul ne donne pas : de quelle
      // famille relève ce problème.
      semanticLabel: l10n.problemKindName(kind),
    );
  }
}

/// L'image d'un problème : la sienne quand elle existe, celle de sa famille
/// sinon.
///
/// La base compte deux cents entrées et les illustrations arrivent par lots.
/// Le repli n'est donc pas un cas d'erreur mais l'état normal de la plupart
/// des entrées, et il ne se voit pas : un symbole de famille à la place d'une
/// illustration reste une image d'argile qui dit de quoi il s'agit.
///
/// Les illustrations sont détaillées — une plante en pot, un thermomètre, un
/// symbole chimique — et demandent de la place. En dessous de quarante points
/// elles se valent toutes ; c'est la carte de diagnostic qui les porte, pas
/// une ligne de liste.
class ProblemIcon extends StatelessWidget {
  const ProblemIcon({super.key, required this.problem, this.side = 52});

  final PlantProblem problem;
  final double side;

  /// Ce problème a-t-il son propre dessin ?
  static bool isIllustrated(PlantProblem problem) => illustratedProblems.contains(problem.id);

  static String assetOf(PlantProblem problem) =>
      isIllustrated(problem) ? 'assets/problems/icons/${problem.id}.webp' : ProblemKindIcon.assetOf(problem.kind);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final language = Localizations.localeOf(context).languageCode;
    return Image(
      image: ClayIllustration.provider(assetOf(problem), side, MediaQuery.devicePixelRatioOf(context)),
      width: side,
      height: side,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      // Le nom du problème quand l'image est la sienne ; la famille sinon,
      // parce que c'est tout ce que l'image dit alors.
      semanticLabel: isIllustrated(problem) ? problem.nameIn(language) : l10n.problemKindName(problem.kind),
    );
  }
}
