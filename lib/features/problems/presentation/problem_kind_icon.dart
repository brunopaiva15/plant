import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../data/problems/problem_catalog.dart';
import '../../../domain/care/care_profile.dart';
import '../../../domain/models/models.dart';
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

  /// Ce qui sépare une famille de l'autre, en une phrase. Ne se lit que dans
  /// le vocabulaire de l'encyclopédie : ailleurs, le nom suffit.
  String problemKindNote(ProblemKind kind) => switch (kind) {
        ProblemKind.disorder => problemKindDisorderNote,
        ProblemKind.pest => problemKindPestNote,
        ProblemKind.disease => problemKindDiseaseNote,
        ProblemKind.condition => problemKindConditionNote,
      };
}

/// L'étendue des hôtes d'un problème, telle que la base la déclare : le nom
/// court qui tient sur une ligne, et la réserve qui va avec.
///
/// La réserve n'est pas de la prudence d'affichage, c'est ce que la base dit
/// d'elle-même en en-tête : les taxons cités sont des exemples, et un genre
/// ne rend pas toutes ses espèces sensibles.
extension ProblemScopeLabels on AppLocalizations {
  String problemScopeName(ProblemScope scope) => switch (scope) {
        ProblemScope.general => problemScopeGeneral,
        ProblemScope.wide => problemScopeWide,
        ProblemScope.target => problemScopeTarget,
      };

  String problemScopeNote(ProblemScope scope) => switch (scope) {
        ProblemScope.general => problemScopeGeneralNote,
        ProblemScope.wide => problemScopeWideNote,
        ProblemScope.target => problemScopeTargetNote,
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
/// referment sur eux-mêmes. D'où le regroupement par famille dans
/// « Problèmes connus » : vingt lignes y partagent quatre symboles, et le
/// répéter à chacune n'apprendrait rien de plus.
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

/// L'image d'un problème de santé de la fiche d'une plante.
///
/// Les neuf entrées de [HealthIssue] disent la même chose que la base des
/// deux cents problèmes : chacune y désigne son entrée, et reprend donc son
/// illustration. Les deux familles — ravageurs, maladies — n'en désignent
/// aucune et portent le symbole de leur famille, qui est exactement ce
/// qu'elles nomment.
///
/// Plus petite que [ProblemIcon] — trente-deux points, ce qui pose la chip
/// pile sur la cible tactile de quarante-quatre. C'est la seule entorse à la
/// règle des quarante points : ici le nom est écrit juste à côté, et il n'y a
/// que neuf entrées, pas deux cents. L'image ne porte pas l'information, elle
/// donne la matière.
class HealthIssueIcon extends StatelessWidget {
  const HealthIssueIcon({super.key, required this.issue, this.side = 32});

  final HealthIssue issue;
  final double side;

  static String assetOf(HealthIssue issue) {
    final id = issue.problemId;
    return id != null && illustratedProblems.contains(id)
        ? 'assets/problems/icons/$id.webp'
        : ProblemKindIcon.assetOf(issue.kind);
  }

  @override
  Widget build(BuildContext context) {
    return Image(
      image: ClayIllustration.provider(assetOf(issue), side, MediaQuery.devicePixelRatioOf(context)),
      width: side,
      height: side,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      // Le nom est écrit juste à côté : l'image ne répète rien.
      excludeFromSemantics: true,
    );
  }
}

/// L'image d'un souci de la section « À surveiller » d'une fiche d'entretien.
///
/// Le vocabulaire des fiches d'espèce désigne la base des deux cents
/// problèmes comme celui des fiches de plante : « Thrips » y a son numéro, et
/// reprend donc son illustration. Quatre entrées n'en désignent aucune —
/// « Taches foliaires » recouvre une dizaine de champignons, « Mildiou »
/// autant, « Punaises » trois familles, et « Chute de feuilles » se dit de
/// tout. Elles portent le symbole de leur famille, qui est ce qu'on en sait.
///
/// Quarante points, comme la liste des problèmes de l'encyclopédie : c'est la
/// taille où le soleil et la goutte du trouble abiotique se lisent encore.
class CommonIssueIcon extends StatelessWidget {
  const CommonIssueIcon({super.key, required this.issue, this.side = 40});

  final CommonIssue issue;
  final double side;

  /// L'entrée de la base dont ce souci prend le dessin, quand il en désigne
  /// une et qu'elle est illustrée.
  static String? _drawn(CommonIssue issue) {
    final id = ProblemCatalog.idForIssue(issue);
    return id != null && illustratedProblems.contains(id) ? id : null;
  }

  /// Ce souci a-t-il le dessin d'une entrée, ou le symbole de sa famille ?
  static bool isIllustrated(CommonIssue issue) => _drawn(issue) != null;

  static String assetOf(CommonIssue issue) {
    final id = _drawn(issue);
    return id == null ? ProblemKindIcon.assetOf(issue.kind) : 'assets/problems/icons/$id.webp';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final own = isIllustrated(issue);
    return Image(
      image: ClayIllustration.provider(assetOf(issue), side, MediaQuery.devicePixelRatioOf(context)),
      width: side,
      height: side,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      // Le nom est écrit juste à côté : le dessin du souci ne répéterait que
      // lui. Le symbole de famille, lui, dit ce que le nom tait — de quoi
      // relèvent « Taches foliaires » —, et la liste ne le titre pas.
      semanticLabel: own ? null : l10n.problemKindName(issue.kind),
      excludeFromSemantics: own,
    );
  }
}
