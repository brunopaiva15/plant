import '../../core/config/jev_config.dart';
import '../../domain/identification/identification_policy.dart';
import '../../domain/identification/plant_identifier.dart';
import 'jev_decision_service.dart';

enum JevProductAction {
  showResult,
  askAnotherPhoto,
  keepUncertain,
}

class JevProductDecision {
  const JevProductDecision({
    required this.action,
    required this.probability,
  });

  final JevProductAction action;
  final double? probability;
}

/// Résultat exact utilisé par le pipeline d'identification.
///
/// La vue debug lit ce même objet mis en cache : elle ne refait donc jamais
/// une requête OpenRouter pour expliquer une décision déjà prise.
class JevPipelineEvaluation {
  const JevPipelineEvaluation({
    required this.offer,
    required this.consultedJev,
    required this.usedFallback,
    this.decision,
    this.latency,
    this.cost,
    this.model,
    this.rawResponse,
    this.error,
  });

  final SecondPhotoOffer offer;
  final bool consultedJev;
  final bool usedFallback;
  final JevProductDecision? decision;
  final Duration? latency;
  final double? cost;
  final String? model;
  final Map<String, dynamic>? rawResponse;
  final String? error;
}

/// Couche de décision facultative autour d'Iris.
///
/// Le pipeline local reste l'autorité de repli. Jev n'est consulté que quand
/// Iris reste ambigu : après une photo pour décider si une seconde vue vaut
/// la peine, puis après la seconde pour trancher entre afficher le résultat
/// ou le garder explicitement incertain. Il ne reçoit jamais la photo :
/// seulement le Top-5, ses scores et le nombre de vues.
///
/// Les évaluations complètes sont mémorisées. L'UI de debug et le pipeline
/// partagent exactement le même Future et donc le même appel réseau.
class JevIdentificationPolicy {
  JevIdentificationPolicy({
    JevDecisionService? service,
    bool? configured,
  })  : _service = service ?? JevDecisionService(),
        _configuredOverride = configured;

  final JevDecisionService _service;
  final bool? _configuredOverride;

  bool get _isConfigured => _configuredOverride ?? JevConfig.isConfigured;

  final _evaluationCache = <String, Future<JevPipelineEvaluation>>{};

  static const _timeout = Duration(seconds: 3);
  static const _maxCacheEntries = 24;

  Future<SecondPhotoOffer> secondPhotoOfferFor({
    required FallbackPolicy policy,
    required List<IdentificationCandidate> candidates,
    required int photos,
    required int maxPhotos,
  }) =>
      evaluate(
        policy: policy,
        candidates: candidates,
        photos: photos,
        maxPhotos: maxPhotos,
      ).then((evaluation) => evaluation.offer);

  Future<JevPipelineEvaluation> evaluate({
    required FallbackPolicy policy,
    required List<IdentificationCandidate> candidates,
    required int photos,
    required int maxPhotos,
  }) {
    final fallback = secondPhotoOffer(
      policy,
      candidates,
      photos: photos,
      maxPhotos: maxPhotos,
    );

    // Jev n'arbitre que la sortie locale d'Iris.
    if (candidates.isEmpty ||
        candidates.first.source != IdentificationSource.local) {
      return Future.value(JevPipelineEvaluation(
        offer: fallback,
        consultedJev: false,
        usedFallback: false,
      ));
    }

    final top5 = candidates
        .where((c) => c.source == IdentificationSource.local)
        .take(5)
        .toList(growable: false);
    if (top5.isEmpty) {
      return Future.value(JevPipelineEvaluation(
        offer: fallback,
        consultedJev: false,
        usedFallback: false,
      ));
    }

    // Un résultat déjà accepté par Iris n'a besoin d'aucun arbitrage réseau,
    // que l'on soit à la première ou à la deuxième photo.
    if (policy.decide(top5) == IdentificationVerdict.accepted) {
      return Future.value(JevPipelineEvaluation(
        offer: fallback,
        consultedJev: false,
        usedFallback: false,
      ));
    }

    if (!_isConfigured) {
      return Future.value(JevPipelineEvaluation(
        offer: fallback,
        consultedJev: false,
        usedFallback: true,
        error: 'OPENROUTER_API_KEY absente',
      ));
    }

    final key = [
      photos,
      maxPhotos,
      policy.acceptThreshold.toStringAsFixed(6),
      policy.plausibleThreshold.toStringAsFixed(6),
      policy.minMargin.toStringAsFixed(6),
      policy.floor.toStringAsFixed(6),
      for (final c in top5)
        '${c.scientificName}:${c.score.toStringAsFixed(6)}',
    ].join('|');

    final cached = _evaluationCache[key];
    if (cached != null) return cached;

    final pending = _resolve(
      top5,
      fallback: fallback,
      photos: photos,
      maxPhotos: maxPhotos,
    );
    _evaluationCache[key] = pending;
    if (_evaluationCache.length > _maxCacheEntries) {
      _evaluationCache.remove(_evaluationCache.keys.first);
    }
    return pending;
  }

  Future<JevPipelineEvaluation> _resolve(
    List<IdentificationCandidate> candidates, {
    required SecondPhotoOffer fallback,
    required int photos,
    required int maxPhotos,
  }) async {
    final stopwatch = Stopwatch()..start();
    final atPhotoLimit = photos >= maxPhotos;
    try {
      final response = await _service
          .decide(
            state: {
              'source': 'Iris on-device classifier',
              'photo_count': photos,
              'max_photo_count': maxPhotos,
              'iris_candidates': [
                for (final (i, candidate) in candidates.indexed)
                  {
                    'id': 'candidate_${i + 1}',
                    'scientific_name': candidate.scientificName,
                    'iris_score': candidate.score,
                  },
              ],
              if (candidates.length >= 2)
                'top1_margin': candidates[0].score - candidates[1].score,
            },
            questions: {
              'decision': {
                'type': 'choice',
                'instructions': atPhotoLimit
                    ? 'Auxine has already used the maximum number of photos. Choose the final product state for this still-ambiguous Iris result. Asking for another photo is not available.'
                    : 'Choose the single product action Auxine should take now. Iris considers this scan ambiguous. Decide whether another view is actually useful.',
                'criteria': {
                  'show_result': atPhotoLimit
                      ? 'Show the best current result because the combined two-photo Iris distribution now supports a useful leading candidate.'
                      : 'Do not ask for another photo because one Iris candidate already dominates enough that another view is unlikely to materially change the identification.',
                  if (!atPhotoLimit)
                    'ask_another_photo':
                        'Ask for one more photo because two or more candidates remain close enough that another view could materially improve the identification.',
                  'keep_uncertain': atPhotoLimit
                      ? 'Keep the result explicitly uncertain because even after the maximum number of photos the Iris distribution does not support a specific species strongly enough.'
                      : 'Do not ask for another photo because the evidence is too weak or diffuse for another view to be a useful next step; keep the identification explicitly uncertain.',
                },
              },
            },
          )
          .timeout(_timeout);
      stopwatch.stop();

      final decision = _parseDecision(response, photos: photos, maxPhotos: maxPhotos);
      if (decision == null) {
        return JevPipelineEvaluation(
          offer: fallback,
          consultedJev: true,
          usedFallback: true,
          latency: stopwatch.elapsed,
          cost: _cost(response),
          model: response['model'] as String?,
          rawResponse: response,
          error: 'Réponse Jev invalide',
        );
      }

      return JevPipelineEvaluation(
        offer: decision.action == JevProductAction.askAnotherPhoto
            ? SecondPhotoOffer.prominent
            : SecondPhotoOffer.none,
        consultedJev: true,
        usedFallback: false,
        decision: decision,
        latency: stopwatch.elapsed,
        cost: _cost(response),
        model: response['model'] as String?,
        rawResponse: response,
      );
    } catch (e) {
      stopwatch.stop();
      return JevPipelineEvaluation(
        offer: fallback,
        consultedJev: true,
        usedFallback: true,
        latency: stopwatch.elapsed,
        error: e.toString(),
      );
    }
  }

  JevProductDecision? _parseDecision(
    Map<String, dynamic> response, {
    required int photos,
    required int maxPhotos,
  }) {
    final answers = response['answers'];
    if (answers is! Map<String, dynamic>) return null;
    final answer = answers['decision'];
    if (answer is! Map<String, dynamic>) return null;
    final choice = answer['choice'];
    if (choice is! String) return null;

    final action = switch (choice) {
      'show_result' => JevProductAction.showResult,
      'ask_another_photo' => JevProductAction.askAnotherPhoto,
      'keep_uncertain' => JevProductAction.keepUncertain,
      _ => null,
    };
    if (action == null) return null;

    final safeAction =
        photos >= maxPhotos && action == JevProductAction.askAnotherPhoto
            ? JevProductAction.keepUncertain
            : action;

    final probabilities = answer['probabilities'];
    final probability = probabilities is Map<String, dynamic>
        ? (probabilities[choice] as num?)?.toDouble()
        : null;

    return JevProductDecision(
      action: safeAction,
      probability: probability,
    );
  }

  double? _cost(Map<String, dynamic> response) {
    final usage = response['usage'];
    return usage is Map<String, dynamic>
        ? (usage['cost'] as num?)?.toDouble()
        : null;
  }
}
