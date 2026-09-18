import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/config/jev_config.dart';
import '../../../data/services/jev_decision_service.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/identification/plant_identifier.dart';

/// Banc d'essai Jev branché sur la vraie sortie locale d'Iris.
///
/// Il ne change jamais l'identification retenue par Auxine : il montre
/// seulement, côte à côte, ce qu'Iris a rendu et ce que Jev décide à partir
/// de ce Top-5.
class JevIrisDebugPanel extends StatefulWidget {
  const JevIrisDebugPanel({
    super.key,
    required this.candidates,
    required this.photoCount,
  });

  final List<IdentificationCandidate> candidates;
  final int photoCount;

  @override
  State<JevIrisDebugPanel> createState() => _JevIrisDebugPanelState();
}

class _JevIrisDebugPanelState extends State<JevIrisDebugPanel> {
  @override
  void didUpdateWidget(covariant JevIrisDebugPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final before = oldWidget.candidates
        .take(5)
        .map((c) => '${c.scientificName}:${c.score.toStringAsFixed(6)}')
        .join('|');
    final after = widget.candidates
        .take(5)
        .map((c) => '${c.scientificName}:${c.score.toStringAsFixed(6)}')
        .join('|');
    if (before == after && oldWidget.photoCount == widget.photoCount) return;
    _response = null;
    _error = null;
    _latency = null;
  }
  bool _loading = false;
  Map<String, dynamic>? _response;
  String? _error;
  Duration? _latency;

  List<IdentificationCandidate> get _top5 =>
      widget.candidates.where((c) => c.source == IdentificationSource.local).take(5).toList(growable: false);

  Map<String, dynamic> get _state {
    final candidates = _top5;
    return {
      'source': 'Iris on-device classifier',
      'photo_count': widget.photoCount,
      'iris_candidates': [
        for (final (i, candidate) in candidates.indexed)
          {
            'id': 'candidate_${i + 1}',
            'scientific_name': candidate.scientificName,
            'iris_score': candidate.score,
          },
      ],
      if (candidates.length >= 2) 'top1_margin': candidates[0].score - candidates[1].score,
    };
  }

  Map<String, dynamic> get _questions {
    final candidates = _top5;
    return {
      'identification_reliable': {
        'type': 'noul',
        'instructions':
            'Based on the Iris score distribution, is the evidence strong enough for Auxine to present one species as the identification?',
        'criteria': {
          'true':
              'One candidate is sufficiently dominant relative to the alternatives that presenting it is reasonable.',
          'false':
              'The candidates remain ambiguous enough that Auxine should avoid presenting one species as reliable.',
        },
      },
      'species': {
        'type': 'choice',
        'instructions':
            'Which Iris candidate is the best-supported identification? Choose uncertain when the score distribution does not justify selecting one.',
        'criteria': {
          for (final (i, candidate) in candidates.indexed)
            'candidate_${i + 1}':
                '${candidate.scientificName}; Iris score ${candidate.score.toStringAsFixed(4)}.',
          'uncertain': 'No candidate is sufficiently supported by the available Iris scores.',
        },
      },
      'next_action': {
        'type': 'choice',
        'instructions':
            'What should Auxine do next to minimise the risk of a wrong identification?',
        'criteria': {
          'show_result': 'Show the best current species result.',
          'ask_another_photo':
              'Ask for another photo of the same plant and run Iris again before deciding.',
          'keep_uncertain':
              'Keep the current identification explicitly uncertain without selecting a species.',
        },
      },
      'confidence': {
        'type': 'score',
        'instructions':
            'How strong is the current evidence for a specific species identification?',
        'criteria': ['Very uncertain', 'Uncertain', 'Plausible', 'Strong'],
      },
    };
  }

  Future<void> _run() async {
    if (_top5.isEmpty || _loading) return;
    setState(() {
      _loading = true;
      _response = null;
      _error = null;
      _latency = null;
    });

    final stopwatch = Stopwatch()..start();
    try {
      final response = await JevDecisionService().decide(
        state: _state,
        questions: _questions,
      );
      stopwatch.stop();
      if (!mounted) return;
      setState(() {
        _response = response;
        _latency = stopwatch.elapsed;
      });
    } catch (e) {
      stopwatch.stop();
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _latency = stopwatch.elapsed;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, dynamic>? _answer(String key) {
    final answers = _response?['answers'];
    if (answers is! Map<String, dynamic>) return null;
    final answer = answers[key];
    return answer is Map<String, dynamic> ? answer : null;
  }

  String _speciesLabel(String? choice) {
    if (choice == null) return '—';
    if (choice == 'uncertain') return 'Incertain';
    final match = RegExp(r'^candidate_(\d+)$').firstMatch(choice);
    if (match == null) return choice;
    final index = (int.tryParse(match.group(1) ?? '') ?? 0) - 1;
    final candidates = _top5;
    if (index < 0 || index >= candidates.length) return choice;
    return candidates[index].scientificName;
  }

  double? _selectedProbability(Map<String, dynamic>? answer) {
    if (answer == null) return null;
    final choice = answer['choice'];
    final probabilities = answer['probabilities'];
    if (choice is! String || probabilities is! Map<String, dynamic>) return null;
    return (probabilities[choice] as num?)?.toDouble();
  }

  String _pct(double? value) => value == null ? '—' : '${(value * 100).toStringAsFixed(0)} %';

  String _actionLabel(Object? choice) => switch (choice) {
        'show_result' => 'Afficher le résultat',
        'ask_another_photo' => 'Demander une autre photo',
        'keep_uncertain' => 'Rester incertain',
        null => '—',
        _ => choice.toString(),
      };

  @override
  Widget build(BuildContext context) {
    if (!JevConfig.isConfigured || _top5.isEmpty) return const SizedBox.shrink();

    final c = context.colors;
    final reliable = (_answer('identification_reliable')?['noul'] as num?)?.toDouble();
    final species = _answer('species');
    final nextAction = _answer('next_action');
    final score = (_answer('confidence')?['score'] as num?)?.toDouble();
    final cost = ((_response?['usage'] as Map<String, dynamic>?)?['cost'] as num?)?.toDouble();
    final model = _response?['model'] as String?;

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
                    'JEV DEBUG · IRIS TOP-5',
                    style: context.text.caption.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Text('${widget.photoCount} photo${widget.photoCount > 1 ? 's' : ''}', style: context.text.caption),
              ],
            ),
            const SizedBox(height: Space.sm),
            for (final (i, candidate) in _top5.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  children: [
                    SizedBox(width: 20, child: Text('${i + 1}.', style: context.text.caption)),
                    Expanded(child: Text(candidate.scientificName, style: context.text.callout)),
                    Text(_pct(candidate.score), style: context.text.callout.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            const SizedBox(height: Space.sm),
            Text(
              'Jev ne reçoit pas la photo : uniquement ce vrai Top-5 Iris et le nombre de photos.',
              style: context.text.caption.copyWith(color: c.inkSecondary),
            ),
            const SizedBox(height: Space.sm),
            FloraButton(
              label: _loading ? 'Analyse Jev…' : 'Comparer avec Jev',
              expand: true,
              style: FloraButtonStyle.secondary,
              onPressed: _loading ? null : _run,
            ),
            if (_loading) ...[
              const SizedBox(height: Space.sm),
              const Center(child: AdaptiveProgress(size: 24)),
            ],
            if (_error != null) ...[
              const SizedBox(height: Space.sm),
              Text(_error!, style: context.text.caption.copyWith(color: c.rose)),
            ],
            if (_response != null) ...[
              const SizedBox(height: Space.md),
              Divider(height: 1, color: c.line),
              const SizedBox(height: Space.sm),
              Text('Jev', style: context.text.title3),
              const SizedBox(height: Space.xs),
              _DebugMetric(label: 'Identification fiable', value: _pct(reliable)),
              _DebugMetric(
                label: 'Espèce',
                value: _speciesLabel(species?['choice'] as String?),
                detail: _pct(_selectedProbability(species)),
              ),
              _DebugMetric(
                label: 'Action',
                value: _actionLabel(nextAction?['choice']),
                detail: _pct(_selectedProbability(nextAction)),
              ),
              _DebugMetric(
                label: 'Force des indices',
                value: score == null ? '—' : '${score.toStringAsFixed(2)} / 3',
              ),
              _DebugMetric(
                label: 'Latence',
                value: _latency == null ? '—' : '${_latency!.inMilliseconds} ms',
              ),
              _DebugMetric(
                label: 'Coût',
                value: cost == null ? '—' : '\$${cost.toStringAsFixed(7)}',
              ),
              if (model != null) _DebugMetric(label: 'Modèle', value: model),
              const SizedBox(height: Space.xs),
              SelectableText(
                const JsonEncoder.withIndent('  ').convert(_response),
                style: context.text.caption.copyWith(
                  color: c.inkSecondary,
                  fontFamily: 'monospace',
                  height: 1.35,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DebugMetric extends StatelessWidget {
  const _DebugMetric({required this.label, required this.value, this.detail});

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
          Expanded(child: Text(label, style: context.text.caption.copyWith(color: c.inkSecondary))),
          const SizedBox(width: Space.sm),
          Flexible(
            child: Text(
              detail == null ? value : '$value · $detail',
              style: context.text.callout.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
