/// L'état de la terre, au doigt, à deux ou trois centimètres.
enum SoilState { dry, moist, soggy }

/// Ce que montrent les racines, motte sortie du pot. Ne rien répondre veut
/// dire qu'on ne les a pas regardées : c'est le cas le plus fréquent, et une
/// case cochée au hasard vaudrait pire que rien.
enum RootState { firm, soft, crowded }

/// La lumière que la plante reçoit là où elle vit — ce qu'elle reçoit, pas
/// ce que son espèce demande.
enum LightExposure { direct, bright, dim }

/// Ce qu'on voit d'insectes, revers des feuilles compris.
enum BugSighting { none, onPlant, inSoil }

/// Ce que la personne est allée vérifier elle-même avant l'analyse.
///
/// Une feuille jaune se photographie ; une terre détrempée, des racines
/// brunes, une fenêtre plein sud et trois pucerons sous une feuille, non. Ce
/// sont pourtant ces quatre-là qui départagent l'excès d'eau du manque d'eau,
/// la pourriture du choc de rempotage, la brûlure de la carence.
///
/// Les quatre réponses sont facultatives, séparément : ne rien dire n'est pas
/// dire non, et rien de ce qui n'a pas été coché ne part.
class DiagnosisObservations {
  const DiagnosisObservations({this.soil, this.roots, this.light, this.bugs});

  static const none = DiagnosisObservations();

  final SoilState? soil;
  final RootState? roots;
  final LightExposure? light;
  final BugSighting? bugs;

  bool get isEmpty => soil == null && roots == null && light == null && bugs == null;
  bool get isNotEmpty => !isEmpty;

  Map<String, Object?> toJson() => {
        if (soil != null) 'soil': soil!.name,
        if (roots != null) 'roots': roots!.name,
        if (light != null) 'light': light!.name,
        if (bugs != null) 'bugs': bugs!.name,
      };

  /// Relit ce qui a été gardé. Un mot inconnu — un champ abîmé, une version
  /// ultérieure — vaut une case non répondue plutôt qu'une entrée perdue.
  factory DiagnosisObservations.fromJson(Map<String, Object?> json) => DiagnosisObservations(
        soil: _one(SoilState.values, json['soil']),
        roots: _one(RootState.values, json['roots']),
        light: _one(LightExposure.values, json['light']),
        bugs: _one(BugSighting.values, json['bugs']),
      );

  static T? _one<T extends Enum>(List<T> values, Object? raw) {
    for (final v in values) {
      if (v.name == raw) return v;
    }
    return null;
  }
}
