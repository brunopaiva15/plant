import 'dart:async';

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
class JevPipelineEvaluation {
  const JevPipelineEvaluation({
    required this.offer,
    required this.consultedJev,
    required this.usedFallback,
    this.decision,
  });

  final SecondPhotoOffer offer;
  final bool consultedJev;
  final bool usedFallback;
  final JevProductDecision? decision;

  /// État produit final : Auxine ne présente aucune espèce comme conclusion,
  /// mais garde les candidates accessibles comme suggestions manuelles.
  bool get keepsUncertain =>
      decision?.action == JevProductAction.keepUncertain;
}

/// Couche de décision facultative autour d'Iris.
///
/// Le pipeline local reste l'autorité de repli. Jev n'est consulté que quand
/// Iris reste ambigu : après une photo pour décider si une seconde vue vaut
/// la peine, puis après la seconde pour trancher entre afficher le résultat
/// ou le garder explicitement incertain. Il ne reçoit jamais la photo :
/// seulement le Top-5, ses scores et le nombre de vues.
///
/// Une décision rendue est mémorisée afin qu'un rebuild d'interface ne
/// refasse jamais le même appel réseau. Un appel qui n'a rien rendu, lui,
/// ne se mémorise pas : il se tait un moment, puis se laisse reposer.
class JevIdentificationPolicy {
  JevIdentificationPolicy({
    JevDecisionService? service,
    bool? configured,
    DateTime Function()? now,
  })  : _service = service ?? JevDecisionService(),
        _configuredOverride = configured,
        _now = now ?? DateTime.now;

  final JevDecisionService _service;
  final bool? _configuredOverride;
  final DateTime Function() _now;

  bool get _isConfigured => _configuredOverride ?? JevConfig.isConfigured;

  final _evaluationCache = <String, Future<JevPipelineEvaluation>>{};

  /// Quand le dernier incident réseau a fermé la porte, par état de scan.
  ///
  /// Une réponse Jev se mémorise pour de bon : le même Top-5 donnerait la
  /// même décision. Un incident, non — il ne dit rien de la plante, et le
  /// garder en cache condamnerait ce scan au repli local pour toute la
  /// session sur une simple coupure. Il ouvre donc une fenêtre de silence,
  /// assez longue pour qu'un écran qui se reconstruit ne rappelle pas
  /// OpenRouter à chaque image.
  final _incidents = <String, DateTime>{};

  /// Ce que l'interface peut attendre avant de montrer la réponse d'Iris.
  static const budget = Duration(seconds: 3);
  static const _retryCooldown = Duration(seconds: 20);
  static const _maxCacheEntries = 24;

  Future<SecondPhotoOffer> secondPhotoOfferFor({
    required FallbackPolicy policy,
    required List<IdentificationCandidate> candidates,
    required int photos,
    required int maxPhotos,
    bool online = true,
  }) =>
      evaluate(
        policy: policy,
        candidates: candidates,
        photos: photos,
        maxPhotos: maxPhotos,
        online: online,
      ).then((evaluation) => evaluation.offer);

  /// Ce qu'Auxine sait dire sans réseau, tout de suite.
  ///
  /// C'est la réponse d'Iris seule, celle que l'interface affiche pendant
  /// que Jev réfléchit : l'arbitrage distant corrige une proposition déjà
  /// là plutôt que de retenir l'écran le temps d'un appel.
  JevPipelineEvaluation localEvaluation({
    required FallbackPolicy policy,
    required List<IdentificationCandidate> candidates,
    required int photos,
    required int maxPhotos,
  }) =>
      JevPipelineEvaluation(
        offer: secondPhotoOffer(
          policy,
          candidates,
          photos: photos,
          maxPhotos: maxPhotos,
        ),
        consultedJev: false,
        usedFallback: false,
      );

  Future<JevPipelineEvaluation> evaluate({
    required FallbackPolicy policy,
    required List<IdentificationCandidate> candidates,
    required int photos,
    required int maxPhotos,
    bool online = true,
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

    // Sans clé ou sans réseau, l'appel ne peut qu'échouer : autant rendre
    // la réponse d'Iris tout de suite plutôt que de dépenser le budget à
    // attendre un échec. Rien n'est mémorisé, le retour du réseau
    // rouvre donc la question.
    if (!_isConfigured || !online) {
      return Future.value(_fallbackEvaluation(
        fallback,
        atPhotoLimit: photos >= maxPhotos,
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

    final incident = _incidents[key];
    if (incident != null) {
      if (_now().difference(incident) < _retryCooldown) {
        return Future.value(_fallbackEvaluation(
          fallback,
          atPhotoLimit: photos >= maxPhotos,
          consultedJev: true,
        ));
      }
      _incidents.remove(key);
    }

    final pending = _resolve(
      top5,
      fallback: fallback,
      photos: photos,
      maxPhotos: maxPhotos,
    );
    _evaluationCache[key] = pending;
    // Une décision se mémorise, un incident non : `consultedJev` avec
    // `usedFallback` est la signature exacte d'un appel parti sans rien
    // rendre.
    unawaited(pending.then((evaluation) {
      if (evaluation.consultedJev && evaluation.usedFallback) {
        _noteIncident(key);
      }
    }));
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
            timeout: budget,
          );

      final decision = _parseDecision(response, photos: photos, maxPhotos: maxPhotos);
      if (decision == null) {
        return _fallbackEvaluation(
          fallback,
          atPhotoLimit: atPhotoLimit,
          consultedJev: true,
        );
      }

      return JevPipelineEvaluation(
        offer: decision.action == JevProductAction.askAnotherPhoto
            ? SecondPhotoOffer.prominent
            : SecondPhotoOffer.none,
        consultedJev: true,
        usedFallback: false,
        decision: decision,
      );
    } catch (_) {
      return _fallbackEvaluation(
        fallback,
        atPhotoLimit: atPhotoLimit,
        consultedJev: true,
      );
    }
  }

  /// Un appel qui n'a rien rendu : on oublie le résultat pour que la
  /// question puisse se reposer, et on note l'heure pour ne pas la reposer
  /// à chaque image.
  ///
  /// Le ménage se fait ici, une fois la réponse connue, et non dans
  /// `_resolve` : l'entrée de cache n'existe pas encore quand celui-ci
  /// commence, et un échec immédiat la laisserait derrière lui.
  void _noteIncident(String key) {
    _evaluationCache.remove(key);
    _incidents[key] = _now();
    if (_incidents.length > _maxCacheEntries) {
      _incidents.remove(_incidents.keys.first);
    }
  }

  JevPipelineEvaluation _fallbackEvaluation(
    SecondPhotoOffer fallback, {
    required bool atPhotoLimit,
    bool consultedJev = false,
  }) {
    return JevPipelineEvaluation(
      offer: fallback,
      consultedJev: consultedJev,
      usedFallback: true,
      decision: atPhotoLimit
          ? const JevProductDecision(
              action: JevProductAction.keepUncertain,
              probability: null,
            )
          : null,
    );
  }

  /// Referme le client HTTP quand le fournisseur est jeté.
  void dispose() => _service.close();

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

}
