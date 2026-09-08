import 'dart:convert';

import '../../domain/care/care_profile.dart';
import '../../domain/problems/plant_problem.dart';

/// La base locale des 200 troubles, ravageurs et maladies.
///
/// Elle sert de vocabulaire commun : le diagnostic soumet au modèle une
/// courte liste de numéros pris ici, et n'accepte en retour que ces
/// numéros-là. Le nom affiché vient ensuite de la base, dans la langue de
/// l'utilisateur — deux analyses de la même chose se lisent pareil.
class ProblemCatalog {
  ProblemCatalog(List<PlantProblem> problems)
      : problems = List.unmodifiable(problems),
        _byId = {for (final p in problems) p.id: p};

  final List<PlantProblem> problems;
  final Map<String, PlantProblem> _byId;

  bool get isEmpty => problems.isEmpty;

  PlantProblem? operator [](String? id) => id == null ? null : _byId[id.trim()];

  /// Les pistes plausibles pour une plante donnée : tout ce qui touche les
  /// plantes vasculaires, plus ce qui vise son espèce, son genre ou sa
  /// famille, plus [pinned] — les problèmes que la fiche d'entretien signale
  /// pour cette espèce, qu'un rapprochement de taxons ne retrouverait pas
  /// forcément.
  ///
  /// Le tri suit les numéros, qui rangent déjà les troubles avant les
  /// ravageurs et les ravageurs avant les maladies.
  List<PlantProblem> candidatesFor({String? species, String? family, Iterable<String> pinned = const []}) {
    final keep = <String, PlantProblem>{};
    for (final id in pinned) {
      final p = _byId[id];
      if (p != null) keep[p.id] = p;
    }
    for (final p in problems) {
      if (p.affects(species: species, family: family)) keep[p.id] = p;
    }
    return keep.values.toList()..sort((a, b) => a.id.compareTo(b.id));
  }

  /// Le problème de la base qui correspond à un souci noté sur la fiche
  /// d'entretien, quand il y en a un sans ambiguïté.
  ///
  /// Plusieurs entrées de la fiche n'ont pas d'équivalent unique : « leafSpot »
  /// recouvre une dizaine de champignons et deux bactéries, « blight » autant.
  /// Elles restent sans numéro plutôt que d'en recevoir un faux.
  static String? idForIssue(CommonIssue issue) => switch (issue) {
        CommonIssue.underwatering => '001',
        CommonIssue.overwatering => '002',
        CommonIssue.etiolation => '008',
        CommonIssue.sunburn => '009',
        CommonIssue.dryTips => '013',
        CommonIssue.chlorosis => '028',
        CommonIssue.blossomEndRot => '039',
        CommonIssue.aphids => '051',
        CommonIssue.mealybugs => '054',
        CommonIssue.scale => '056',
        CommonIssue.whitefly => '058',
        CommonIssue.spiderMites => '060',
        CommonIssue.fungusGnats => '065',
        CommonIssue.slugs => '087',
        CommonIssue.powderyMildew => '126',
        CommonIssue.rootRot => '173',
        _ => null,
      };

  static Iterable<String> idsForIssues(Iterable<CommonIssue> issues) =>
      issues.map(idForIssue).whereType<String>();

  /// Lit l'actif embarqué. Les lignes de commentaire et l'en-tête sautent ;
  /// une ligne mal formée est ignorée plutôt que de faire tomber le reste.
  static ProblemCatalog parse(String raw) {
    final out = <PlantProblem>[];
    for (final line in const LineSplitter().convert(raw)) {
      if (line.isEmpty || line.startsWith('#') || line.startsWith('id|')) continue;
      final f = line.split('|');
      if (f.length != 8) continue;
      final kind = ProblemKind.parse(f[1]);
      final scope = ProblemScope.parse(f[6]);
      if (kind == null || scope == null || f[0].isEmpty) continue;
      out.add(PlantProblem(
        id: f[0],
        kind: kind,
        scope: scope,
        fr: f[2],
        en: f[3],
        it: f[4],
        de: f[5],
        hosts: [
          for (final h in f[7].split(';'))
            if (h.trim().isNotEmpty) h.trim(),
        ],
      ));
    }
    return ProblemCatalog(out);
  }
}
