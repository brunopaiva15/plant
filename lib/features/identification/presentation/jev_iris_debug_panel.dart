import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/config/jev_config.dart';
import '../../../data/services/jev_identification_policy.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/identification/cascade_identifier.dart';
import '../../../domain/identification/identification_policy.dart';
import '../../../domain/identification/plant_identifier.dart';

/// Inspection de la vraie décision Jev utilisée par le pipeline.
///
/// Cette carte ne possède aucun client OpenRouter. Elle demande au service de
/// pipeline son évaluation mise en cache, c'est-à-dire exactement le même
/// Future que celui utilisé pour décider d'afficher ou non la seconde photo.
class JevIrisDebugPanel extends ConsumerWidget {
  const JevIrisDebugPanel({
    super.key,
    required this.candidates,
    required this.photoCount,
    required this.maxPhotos,
  });

  final List<IdentificationCandidate> candidates;
  final int photoCount;
  final int maxPhotos;

  List<IdentificationCandidate> get _top5 => candidates
      .where((c) => c.source == IdentificationSource.local)
      .take(5)
      .toList(growable: false);

  String _pct(double? value) =>
      value == null ? '—' : '${(value * 100).toStringAsFixed(0)} %';

  String _actionLabel(JevProductAction? action) => switch (action) {
        JevProductAction.showResult => 'Afficher le résultat',
        JevProductAction.askAnotherPhoto => 'Demander une autre photo',
        JevProductAction.keepUncertain => 'Rester incertain',
        null => '—',
      };

  String _offerLabel(SecondPhotoOffer offer) => switch (offer) {
        SecondPhotoOffer.prominent => 'Deuxième photo proposée',
        SecondPhotoOffer.none => 'Aucune deuxième photo',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!JevConfig.isConfigured || _top5.isEmpty) {
      return const SizedBox.shrink();
    }

    final identifier = ref.read(plantIdentifierProvider);
    if (identifier is! CascadeIdentifier) return const SizedBox.shrink();

    final evaluation = ref.read(jevIdentificationPolicyProvider).evaluate(
          policy: identifier.policy,
          candidates: candidates,
          photos: photoCount,
          maxPhotos: maxPhotos,
        );

    final c = context.colors;

    return Padding(
      padding: const EdgeInsets.only(top: Space.md),
      child: FloraCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'JEV · DÉCISION PIPELINE',
                    style: context.text.caption.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${photoCount} photo${photoCount > 1 ? 's' : ''}',
                  style: context.text.caption,
                ),
              ],
            ),
            const SizedBox(height: Space.sm),
            for (final (i, candidate) in _top5.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      child: Text('${i + 1}.', style: context.text.caption),
                    ),
                    Expanded(
                      child: Text(
                        candidate.scientificName,
                        style: context.text.callout,
                      ),
                    ),
                    Text(
                      _pct(candidate.score),
                      style: context.text.callout.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: Space.sm),
            Text(
              'Lecture du même appel automatique que le pipeline. Aucun second appel Jev n’est envoyé par cette carte.',
              style: context.text.caption.copyWith(color: c.inkSecondary),
            ),
            const SizedBox(height: Space.md),
            FutureBuilder<JevPipelineEvaluation>(
              future: evaluation,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return Row(
                    children: [
                      const AdaptiveProgress(size: 22),
                      const SizedBox(width: Space.xs),
                      Expanded(
                        child: Text(
                          'Décision pipeline en cours…',
                          style: context.text.callout,
                        ),
                      ),
                    ],
                  );
                }

                final result = snap.data;
                if (result == null) {
                  return Text(
                    'Impossible de lire la décision pipeline.',
                    style: context.text.caption.copyWith(color: c.rose),
                  );
                }

                if (!result.consultedJev) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _DebugMetric(
                        label: 'Jev',
                        value: 'Non consulté',
                      ),
                      _DebugMetric(
                        label: 'Décision appliquée',
                        value: _offerLabel(result.offer),
                      ),
                      Text(
                        result.usedFallback
                            ? 'La politique Iris locale a été utilisée.'
                            : 'Iris était déjà suffisamment net : aucun appel réseau nécessaire.',
                        style: context.text.caption.copyWith(
                          color: c.inkSecondary,
                        ),
                      ),
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Divider(height: 1, color: c.line),
                    const SizedBox(height: Space.sm),
                    _DebugMetric(
                      label: 'Décision Jev',
                      value: _actionLabel(result.decision?.action),
                      detail: _pct(result.decision?.probability),
                    ),
                    _DebugMetric(
                      label: 'Effet appliqué',
                      value: _offerLabel(result.offer),
                    ),
                    _DebugMetric(
                      label: 'Source',
                      value: result.usedFallback
                          ? 'Fallback Iris'
                          : 'Appel automatique partagé',
                    ),
                    _DebugMetric(
                      label: 'Latence',
                      value: result.latency == null
                          ? '—'
                          : '${result.latency!.inMilliseconds} ms',
                    ),
                    _DebugMetric(
                      label: 'Coût',
                      value: result.cost == null
                          ? '—'
                          : '\$${result.cost!.toStringAsFixed(7)}',
                    ),
                    if (result.model != null)
                      _DebugMetric(label: 'Modèle', value: result.model!),
                    if (result.error != null) ...[
                      const SizedBox(height: Space.xs),
                      Text(
                        result.error!,
                        style: context.text.caption.copyWith(color: c.rose),
                      ),
                    ],
                    if (result.rawResponse != null) ...[
                      const SizedBox(height: Space.sm),
                      SelectableText(
                        const JsonEncoder.withIndent('  ')
                            .convert(result.rawResponse),
                        style: context.text.caption.copyWith(
                          color: c.inkSecondary,
                          fontFamily: 'monospace',
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DebugMetric extends StatelessWidget {
  const _DebugMetric({
    required this.label,
    required this.value,
    this.detail,
  });

  final String label;
  final String value;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: context.text.caption.copyWith(color: c.inkSecondary),
            ),
          ),
          const SizedBox(width: Space.sm),
          Flexible(
            child: Text(
              detail == null ? value : '${value} · ${detail}',
              style: context.text.callout.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
