import 'dart:async';

import '../../core/config/jev_config.dart';
import '../../domain/diagnosis/diagnosis_observations.dart';
import '../../domain/diagnosis/diagnosis_policy.dart';
import '../../domain/diagnosis/plant_diagnoser.dart';
import 'jev_decision_service.dart';

/// Couche de décision facultative autour du diagnostic, jumelle de celle de
/// l'identification (docs/16).
///
/// Le service d'analyse reste seul à regarder les photos et seul à nommer
/// les pistes. Jev n'arbitre qu'une question, celle que des seuils rigides
/// tranchaient mal : ce compte rendu se lit-il tel quel, vaut-il une photo
/// de plus, ou faut-il dire qu'on ne sait pas ?
///
/// Ce qui part est un état structuré, jamais une photo, jamais un mot écrit
/// par la personne : le rang des pistes, leur vraisemblance, leur numéro
/// dans la base des problèmes, ce qui a été vérifié à la main, le nombre de
/// photos. La règle locale reste l'autorité de repli — sans clé, sans
/// réseau, en cas de délai dépassé ou de réponse incohérente, c'est elle qui
/// répond, et l'analyse ne s'en trouve pas amputée.
class JevDiagnosisPolicy {
  JevDiagnosisPolicy({
    JevDecisionService? service,
    bool? configured,
    DateTime Function()? now,
  })  : _service = service ?? JevDecisionService(),
        _configuredOverride = configured,
        _now = now ?? DateTime.now;

  final JevDecisionService _service;
  final bool? _configuredOverride;
  final DateTime Function() _now;

  /// Ce que l'écran peut attendre après avoir déjà affiché le compte rendu.
  static const budget = Duration(seconds: 3);
  static const _retryCooldown = Duration(seconds: 20);
  static const _maxCacheEntries = 12;

  bool get _isConfigured => _configuredOverride ?? JevConfig.isConfigured;

  final _cache = <String, Future<DiagnosisNextStep>>{};
  final _incidents = <String, DateTime>{};

  /// Ce que l'application sait décider seule, tout de suite : la règle
  /// locale. C'est elle que l'écran applique pendant que Jev réfléchit.
  DiagnosisNextStep localStep(
    Diagnosis diagnosis, {
    required int photos,
    required int maxPhotos,
  }) =>
      diagnosisNextStep(diagnosis, photos: photos, maxPhotos: maxPhotos);

  Future<DiagnosisNextStep> evaluate({
    required Diagnosis diagnosis,
    required int photos,
    required int maxPhotos,
    DiagnosisObservations observations = DiagnosisObservations.none,
    bool symptomsGiven = false,
    bool online = true,
  }) {
    final local = localStep(diagnosis, photos: photos, maxPhotos: maxPhotos);
    // Un compte rendu qui désigne une piste et une seule n'a rien à arbitrer :
    // aucun appel ne part, comme pour un scan qu'Iris juge net.
    if (local == DiagnosisNextStep.showResult) return Future.value(local);
    // Sans clé ou sans réseau, l'appel ne peut qu'échouer : la règle locale
    // répond tout de suite. Rien n'est mémorisé, le retour du réseau rouvre
    // donc la question.
    if (!_isConfigured || !online) return Future.value(local);

    final key = _keyOf(diagnosis, photos: photos, maxPhotos: maxPhotos, observations: observations, symptomsGiven: symptomsGiven);
    final cached = _cache[key];
    if (cached != null) return cached;

    final incident = _incidents[key];
    if (incident != null) {
      if (_now().difference(incident) < _retryCooldown) return Future.value(local);
      _incidents.remove(key);
    }

    final pending = _resolve(
      diagnosis,
      local: local,
      photos: photos,
      maxPhotos: maxPhotos,
      observations: observations,
      symptomsGiven: symptomsGiven,
      key: key,
    );
    _cache[key] = pending;
    if (_cache.length > _maxCacheEntries) _cache.remove(_cache.keys.first);
    return pending;
  }

  Future<DiagnosisNextStep> _resolve(
    Diagnosis diagnosis, {
    required DiagnosisNextStep local,
    required int photos,
    required int maxPhotos,
    required DiagnosisObservations observations,
    required bool symptomsGiven,
    required String key,
  }) async {
    final atPhotoLimit = photos >= maxPhotos;
    try {
      final response = await _service.decide(
        state: {
          'source': 'vision model report on plant photos',
          'photo_count': photos,
          'max_photo_count': maxPhotos,
          'urgent': diagnosis.urgent,
          'owner_described_symptoms': symptomsGiven,
          'checked_by_hand': _checks(observations),
          'not_checked': _missing(observations),
          if (diagnosis.suggestedView != null) 'view_the_report_would_like': diagnosis.suggestedView!.wire,
          'causes': [
            for (final (i, c) in diagnosis.causes.indexed)
              {
                'rank': i + 1,
                'likelihood': c.likelihood.name,
                // Une piste qui n'est pas un problème : la plante fait ce
                // qu'elle fait normalement. Une photo de plus ne la
                // départagera pas d'un souci qui n'existe pas.
                'normal_phenomenon': c.natural,
                // Le numéro de la base, quand la piste en porte un : une
                // piste rattachée est une piste que l'application sait
                // nommer, illustrer et suivre.
                'known_problem': c.problemId != null,
              },
          ],
          'likely_count': diagnosis.causes.where((c) => c.likelihood == Likelihood.likely).length,
        },
        questions: {
          'decision': {
            'type': 'choice',
            'instructions': atPhotoLimit
                ? 'The maximum number of photos has already been analysed. Choose the final product state for this report. Asking for another photo is not available.'
                : 'Choose the single product action the app should take now. The report does not single out one probable cause. Decide whether another view would actually change it.',
            'criteria': {
              'show_result': atPhotoLimit
                  ? 'Show the report as it stands because it names causes the owner can act on, even without a single leading one.'
                  : 'Do not ask for another photo because the report is already actionable: the leading causes call for the same first gestures, or what is missing is a hand check rather than a view.',
              if (!atPhotoLimit)
                'ask_another_photo':
                    'Ask for one more photo because causes calling for different gestures remain equally plausible and a specific view could separate them.',
              'keep_uncertain': atPhotoLimit
                  ? 'Say plainly that the analysis does not settle it, because even with every photo the causes stay too scattered to point at one.'
                  : 'Do not ask for another photo because the evidence is too scattered for a view to help; say plainly that the analysis does not settle it.',
            },
          },
        },
        timeout: budget,
      );
      final step = _parse(response, atPhotoLimit: atPhotoLimit);
      if (step == null) {
        _noteIncident(key);
        return local;
      }
      return step;
    } catch (_) {
      // Erreur, délai dépassé, réponse illisible : la règle locale répond, et
      // la question se reposera passé la fenêtre de silence.
      _noteIncident(key);
      return local;
    }
  }

  /// Lit la décision rendue. Une réponse incohérente — un mot inconnu, une
  /// photo demandée alors qu'il n'en reste aucune — ne pilote rien.
  static DiagnosisNextStep? _parse(Map<String, dynamic> response, {required bool atPhotoLimit}) {
    final answers = response['answers'];
    if (answers is! Map<String, dynamic>) return null;
    final answer = answers['decision'];
    if (answer is! Map<String, dynamic>) return null;
    final choice = answer['choice'];
    final step = switch (choice) {
      'show_result' => DiagnosisNextStep.showResult,
      'ask_another_photo' => DiagnosisNextStep.askAnotherPhoto,
      'keep_uncertain' => DiagnosisNextStep.keepUncertain,
      _ => null,
    };
    if (step == null) return null;
    return atPhotoLimit && step == DiagnosisNextStep.askAnotherPhoto ? DiagnosisNextStep.keepUncertain : step;
  }

  /// Ce qui a été vérifié à la main, par sujet. Les mots seuls partent, pas
  /// ce qu'ils valent : savoir qu'on a regardé les racines suffit à juger
  /// si une photo de plus servirait.
  static List<String> _checks(DiagnosisObservations o) => [
        if (o.soil != null) 'soil',
        if (o.roots != null) 'roots',
        if (o.light != null) 'light',
        if (o.bugs != null) 'bugs',
      ];

  static List<String> _missing(DiagnosisObservations o) => [
        if (o.soil == null) 'soil',
        if (o.roots == null) 'roots',
        if (o.light == null) 'light',
        if (o.bugs == null) 'bugs',
      ];

  /// De quoi reconnaître deux fois le même compte rendu, sans en garder le
  /// texte : un rebuild d'écran ne doit pas refaire l'appel.
  static String _keyOf(
    Diagnosis diagnosis, {
    required int photos,
    required int maxPhotos,
    required DiagnosisObservations observations,
    required bool symptomsGiven,
  }) =>
      [
        photos,
        maxPhotos,
        diagnosis.urgent,
        symptomsGiven,
        diagnosis.suggestedView?.wire ?? '-',
        _checks(observations).join(','),
        for (final c in diagnosis.causes) '${c.likelihood.name}:${c.problemId ?? c.naturalId ?? '-'}:${c.natural}',
      ].join('|');

  void _noteIncident(String key) {
    _cache.remove(key);
    _incidents[key] = _now();
    if (_incidents.length > _maxCacheEntries) _incidents.remove(_incidents.keys.first);
  }

  /// Referme le client HTTP quand le fournisseur est jeté.
  void dispose() => _service.close();
}
