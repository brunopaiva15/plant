import 'dart:convert';
import 'dart:math' as math;

import 'identification_context.dart';
import 'plant_identifier.dart';

/// Le masque de lieu : ce qu'un modèle d'union sait de plus qu'un spécialiste.
///
/// Tout est ici plutôt que dans le modèle TensorFlow Lite parce que rien de
/// tout cela n'est du TensorFlow Lite : ce sont des divisions et un tri, et
/// ils doivent pouvoir être mesurés sans interpréteur natif.

/// Les masques déclarés par `model.json`, traduits en indices de sortie.
///
/// Le format est un objet `masks` dont chaque clé est un lieu et chaque valeur
/// la liste des identifiants internes qu'il couvre :
///
/// ```json
/// "masks": { "indoor": ["monstera-deliciosa", …], "outdoor": […] }
/// ```
///
/// Un modèle sans cet objet — tous ceux livrés jusqu'à Iris Indoor — n'a aucun
/// masque, et le contexte reste alors sans effet. Un masque qui couvre toutes
/// les sorties n'en est pas un : il est ignoré plutôt que de faire croire à un
/// contexte. Un `model.json` illisible ne coûte que les masques, jamais le
/// modèle.
Map<IdentificationContext, Set<int>> contextMasks(String meta, List<String> labels) {
  try {
    final masks = (jsonDecode(meta) as Map<String, dynamic>)['masks'];
    if (masks is! Map<String, dynamic>) return const {};
    final index = {for (var i = 0; i < labels.length; i++) labels[i]: i};
    final parsed = <IdentificationContext, Set<int>>{};
    for (final context in IdentificationContext.values) {
      final name = context.maskName;
      if (name == null) continue;
      final ids = masks[name];
      if (ids is! List) continue;
      final kept = <int>{
        for (final id in ids)
          if (id is String && index[id] != null) index[id]!,
      };
      if (kept.isNotEmpty && kept.length < labels.length) parsed[context] = kept;
    }
    return parsed;
  } on Object {
    return const {};
  }
}

/// Sous ce score, un candidat n'est pas rendu : il n'apporte rien à l'écran,
/// et la cascade sait qu'une espèce absente d'une liste vaut au plus cela.
const double minimumCandidateScore = 0.01;

/// Le nombre de candidats rendus par liste. L'écran en montre cinq.
const int maxCandidatesPerList = 5;

/// La masse en deçà de laquelle le masque est abandonné, faute de pouvoir
/// diviser par elle.
const double _minimumMass = 1e-6;

/// Les candidats d'un vecteur de scores, masque du lieu appliqué.
///
/// Sans masque, c'est la liste d'un modèle ordinaire : les meilleurs
/// au-dessus du seuil. Avec masque, **une seule inférence** donne deux listes
/// (§ 14.3 de `docs/09`) — les classes du lieu, renormalisées entre elles,
/// puis les autres telles que le réseau les a rendues, marquées
/// `inContext: false`.
///
/// Renormaliser sur les classes gardées, c'est exactement ce que fait
/// `retailler.py` en supprimant des colonnes : le softmax d'une couche
/// tronquée vaut `exp(zᵢ) / Σ_gardées exp(zⱼ)`, et diviser les probabilités
/// gardées par leur somme donne la même chose. **Le masque appliqué ici
/// n'approche pas le modèle retaillé, il l'égale** — d'où le choix de livrer
/// un seul fichier plutôt que deux (§ 14.2).
///
/// [nameOf] traduit un identifiant interne en nom scientifique lisible. Le
/// nom exact vient ensuite du catalogue ; celui-ci n'est qu'un repli.
List<IdentificationCandidate> maskedCandidates(
  List<double> scores,
  List<String> labels, {
  required String Function(String internalId) nameOf,
  Set<int>? mask,
  int maxCandidates = maxCandidatesPerList,
}) {
  final n = math.min(labels.length, scores.length);
  final all = [for (var i = 0; i < n; i++) i];
  List<IdentificationCandidate> best(List<int> indices, double mass, {required bool inContext}) {
    final candidates = <IdentificationCandidate>[];
    for (final i in indices) {
      final global = scores[i];
      final score = global / mass;
      if (score < minimumCandidateScore) continue;
      candidates.add(IdentificationCandidate(
        scientificName: nameOf(labels[i]),
        score: score.clamp(0.0, 1.0),
        globalScore: global.clamp(0.0, 1.0),
        inContext: inContext,
        source: IdentificationSource.local,
        internalId: labels[i],
      ));
    }
    candidates.sort((a, b) => b.score.compareTo(a.score));
    return candidates.take(maxCandidates).toList();
  }

  if (mask == null || mask.isEmpty) return best(all, 1, inContext: true);

  var mass = 0.0;
  for (final i in mask) {
    if (i < n) mass += scores[i];
  }
  // Diviser par une masse nulle fabriquerait des certitudes à partir de bruit.
  // Ce garde-fou n'est que numérique : jusqu'où la masse du lieu peut
  // descendre avant que la renormalisation ne mente reste à mesurer (§ 14.4),
  // et d'ici là le masque s'applique dès qu'il explique quelque chose.
  if (mass <= _minimumMass) return best(all, 1, inContext: true);

  final inside = <int>[];
  final outside = <int>[];
  for (final i in all) {
    (mask.contains(i) ? inside : outside).add(i);
  }
  return [
    ...best(inside, mass, inContext: true),
    ...best(outside, 1, inContext: false),
  ];
}
