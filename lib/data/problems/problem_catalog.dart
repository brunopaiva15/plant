import 'dart:convert';

import '../../domain/care/care_profile.dart';
import '../../domain/problems/natural_cause.dart';
import '../../domain/problems/plant_problem.dart';

/// La base locale des 200 troubles, ravageurs et maladies, et celle des
/// phénomènes naturels qu'on leur prend pour des symptômes.
///
/// Elle sert de vocabulaire commun : le diagnostic soumet au modèle une
/// courte liste de numéros pris ici, et n'accepte en retour que ces
/// numéros-là. Le nom affiché vient ensuite de la base, dans la langue de
/// l'utilisateur — deux analyses de la même chose se lisent pareil.
///
/// Les deux listes restent séparées parce que les choses le sont : un
/// phénomène naturel n'est pas un problème de plus, il est ce qui n'en est
/// pas un. Seul le diagnostic lit la seconde ; la fiche de soin et
/// l'encyclopédie, qui parlent de ce qui se soigne, n'en voient rien.
class ProblemCatalog {
  ProblemCatalog(List<PlantProblem> problems, {List<NaturalCause> naturalCauses = const []})
      : problems = List.unmodifiable(problems),
        naturalCauses = List.unmodifiable(naturalCauses),
        _byId = {for (final p in problems) p.id: p},
        _naturalById = {for (final n in naturalCauses) n.id: n};

  final List<PlantProblem> problems;

  /// Ce que la plante fait normalement : nectar extrafloral, guttation,
  /// vieille feuille du bas qui jaunit.
  final List<NaturalCause> naturalCauses;

  final Map<String, PlantProblem> _byId;
  final Map<String, NaturalCause> _naturalById;

  bool get isEmpty => problems.isEmpty;

  PlantProblem? operator [](String? id) => id == null ? null : _byId[id.trim()];

  /// Le phénomène naturel portant ce numéro, ou `null` — un compte rendu
  /// d'avant cette base, un numéro inconnu.
  NaturalCause? natural(String? id) => id == null ? null : _naturalById[id.trim().toUpperCase()];

  /// Les phénomènes naturels qui peuvent concerner cette plante : ceux de
  /// toutes les plantes, plus ceux que son espèce, son genre ou sa famille
  /// montrent. Soumis au diagnostic à côté des problèmes.
  List<NaturalCause> naturalFor({String? species, String? family}) =>
      [for (final n in naturalCauses) if (n.affects(species: species, family: family)) n];

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

  /// Ce que la base connaît de cette plante en propre, pour la fiche de soin.
  ///
  /// Les troubles universels en sont retirés : « manque d'eau » vaut pour
  /// tout le monde et n'apprend rien sur l'espèce. [covered] retire ce que la
  /// fiche vient de dire ailleurs, pour ne pas le redire.
  ///
  /// La liste est souvent vide, et c'est bien ainsi : la base ne connaît rien
  /// de particulier à la moitié des plantes du catalogue, et le taire vaut
  /// mieux que de meubler.
  List<PlantProblem> specificTo({String? species, String? family, Iterable<CommonIssue> covered = const []}) {
    final deja = idsForIssues(covered).toSet();
    return candidatesFor(species: species, family: family)
        .where((p) => p.scope != ProblemScope.general && !deja.contains(p.id))
        .toList();
  }

  /// Le problème de la base qui correspond à un souci noté sur la fiche
  /// d'entretien, quand il y en a un sans ambiguïté.
  ///
  /// Plusieurs entrées de la fiche n'ont pas d'équivalent unique : « leafSpot »
  /// recouvre une dizaine de champignons et deux bactéries, « blight » autant,
  /// et « trueBugs » trois familles de punaises. Elles restent sans numéro
  /// plutôt que d'en recevoir un faux.
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
        CommonIssue.thrips => '059',
        CommonIssue.spiderMites => '060',
        CommonIssue.fungusGnats => '065',
        CommonIssue.slugs => '087',
        CommonIssue.powderyMildew => '126',
        CommonIssue.greyMould => '135',
        CommonIssue.rootRot => '173',
        _ => null,
      };

  static Iterable<String> idsForIssues(Iterable<CommonIssue> issues) =>
      issues.map(idForIssue).whereType<String>();

  /// Lit l'actif embarqué. Les lignes de commentaire et l'en-tête sautent ;
  /// une ligne mal formée est ignorée plutôt que de faire tomber le reste.
  ///
  /// Le neuvième champ, les synonymes de recherche, est facultatif : la
  /// plupart des entrées portent déjà le nom sous lequel on les cherche.
  static ProblemCatalog parse(String raw) => ProblemCatalog(parseProblems(raw));

  /// Les deux actifs lus ensemble : les problèmes, puis les phénomènes
  /// naturels. Une seule fonction pour un seul passage dans l'isolat.
  static ProblemCatalog parseAll((String, String) sources) =>
      ProblemCatalog(parseProblems(sources.$1), naturalCauses: parseNatural(sources.$2));

  /// Lit la base des phénomènes naturels : `id|fr|en|it|de|portée|hôtes`.
  /// Mêmes règles que ci-dessus — les commentaires et l'en-tête sautent, une
  /// ligne mal formée est ignorée.
  static List<NaturalCause> parseNatural(String raw) {
    final out = <NaturalCause>[];
    for (final line in const LineSplitter().convert(raw)) {
      if (line.isEmpty || line.startsWith('#') || line.startsWith('id|')) continue;
      final f = line.split('|');
      if (f.length != 7) continue;
      final scope = ProblemScope.parse(f[5]);
      if (scope == null || f[0].isEmpty) continue;
      out.add(NaturalCause(
        id: f[0].trim().toUpperCase(),
        scope: scope,
        fr: f[1],
        en: f[2],
        it: f[3],
        de: f[4],
        hosts: [
          for (final h in f[6].split(';'))
            if (h.trim().isNotEmpty) h.trim(),
        ],
      ));
    }
    return out;
  }

  static List<PlantProblem> parseProblems(String raw) {
    final out = <PlantProblem>[];
    for (final line in const LineSplitter().convert(raw)) {
      if (line.isEmpty || line.startsWith('#') || line.startsWith('id|')) continue;
      final f = line.split('|');
      if (f.length != 8 && f.length != 9) continue;
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
        aliases: [
          if (f.length == 9)
            for (final a in f[8].split(';'))
              if (a.trim().isNotEmpty) a.trim(),
        ],
      ));
    }
    return out;
  }
}
