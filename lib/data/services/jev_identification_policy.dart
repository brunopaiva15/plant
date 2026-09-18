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

/// Couche de décision facultative autour d'Iris.
///
/// Le pipeline local reste l'autorité de repli. Jev n'est consulté que dans
/// le cas où cette politique aurait proposé une seconde photo. Il ne reçoit
/// jamais la photo : seulement le Top-5, ses scores et le nombre de vues.
///
/// Les réponses sont mémorisées pour éviter qu'un rebuild Flutter ne refasse
/// le même appel réseau.
class JevIdentificationPolicy {
  JevIdentificationPolicy({
    JevDecisionService? service,
    bool? configured,
  })  : _service = service ?? JevDecisionService(),
        _configuredOverride = configured;

  final JevDecisionService _service;
  final bool? _configuredOverride;

  bool get _isConfigured => _configuredOverride ?? JevConfig.isConfigured;
  final _cache = <String, Future<JevProductDecision?>>{};

  static const _timeout = Duration(seconds: 3);
  static const _maxCacheEntries = 24;

  Future<SecondPhotoOffer> secondPhotoOfferFor({
    required FallbackPolicy policy,
    required List<IdentificationCandidate> candidates,
    required int photos,
    required int maxPhotos,
  }) async {
    final fallback = secondPhotoOffer(
      policy,
      candidates,
      photos: photos,
      maxPhotos: maxPhotos,
    );

    // Rien à arbitrer : Iris est déjà suffisamment sûr, la réponse n'est pas
    // locale, la liste est vide, ou le maximum de photos est atteint.
    if (fallback == SecondPhotoOffer.none) return fallback;
    if (!_isConfigured) return fallback;

    try {
      final decision = await _decision(
        candidates: candidates,
        photos: photos,
        maxPhotos: maxPhotos,
      ).timeout(_timeout);

      if (decision == null) return fallback;
      return decision.action == JevProductAction.askAnotherPhoto
          ? SecondPhotoOffer.prominent
          : SecondPhotoOffer.none;
    } catch (_) {
      // Jev est un enrichissement. Une panne réseau, un timeout ou une
      // réponse inattendue ne doit jamais casser le scan.
      return fallback;
    }
  }

  Future<JevProductDecision?> _decision({
    required List<IdentificationCandidate> candidates,
    required int photos,
    required int maxPhotos,
  }) {
    final top5 = candidates
        .where((c) => c.source == IdentificationSource.local)
        .take(5)
        .toList(growable: false);
    if (top5.isEmpty || photos >= maxPhotos) {
      return Future.value(null);
    }

    final key = [
      photos,
      maxPhotos,
      for (final c in top5)
        '${c.scientificName}:${c.score.toStringAsFixed(6)}',
    ].join('|');

    final cached = _cache[key];
    if (cached != null) return cached;

    final pending = _request(top5, photos: photos, maxPhotos: maxPhotos);
    _cache[key] = pending;
    if (_cache.length > _maxCacheEntries) {
      _cache.remove(_cache.keys.first);
    }
    return pending;
  }

  Future<JevProductDecision?> _request(
    List<IdentificationCandidate> candidates, {
    required int photos,
    required int maxPhotos,
  }) async {
    final response = await _service.decide(
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
          'instructions':
              'Choose the single product action Auxine should take now. Iris already considers this scan ambiguous enough that the local policy would ask for another photo. Decide whether another view is actually useful.',
          'criteria': {
            'show_result':
                'Do not ask for another photo because one Iris candidate already dominates enough that another view is unlikely to materially change the identification.',
            'ask_another_photo':
                'Ask for one more photo because two or more candidates remain close enough that another view could materially improve the identification. Only valid while photo_count is below max_photo_count.',
            'keep_uncertain':
                'Do not ask for another photo because the evidence is too weak or diffuse for another view to be a useful next step; keep the identification explicitly uncertain.',
          },
        },
      },
    );

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

    // Invariant produit : aucune troisième photo, même si un fournisseur
    // renvoyait une réponse incohérente.
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
