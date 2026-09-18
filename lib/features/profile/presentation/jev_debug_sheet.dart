import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/config/jev_config.dart';
import '../../../data/services/jev_decision_service.dart';
import '../../../design_system/design_system.dart';

Future<void> showJevDebugSheet(BuildContext context) => showFloraSheet<void>(
      context,
      scrollable: true,
      builder: (_) => const _JevDebugBody(),
    );

class _JevDebugBody extends StatefulWidget {
  const _JevDebugBody();

  @override
  State<_JevDebugBody> createState() => _JevDebugBodyState();
}

class _JevDebugBodyState extends State<_JevDebugBody> {
  static const _state = {
    'photo_count': 1,
    'iris_candidates': [
      ['Monstera adansonii', 0.45],
      ['Monstera deliciosa', 0.41],
      ['Rhaphidophora tetrasperma', 0.14],
    ],
    'environment': 'indoor',
    'leaf_length_cm': 28,
    'fenestrations': true,
    'mature_plant': true,
  };

  static const _questions = <String, dynamic>{
    'decision': {
      'type': 'choice',
      'instructions':
          'Choose the single product action Auxine should take now. This is the authoritative product decision; the species and confidence questions are explanatory only.',
      'criteria': {
        'show_result':
            'Show the best current species result when one candidate clearly dominates and another photo is unlikely to materially change the identification.',
        'ask_another_photo':
            'Ask for one more photo only when photo_count is below 2 and the candidates remain close enough that another view could materially change the identification.',
        'keep_uncertain':
            'Keep the identification explicitly uncertain when no candidate is sufficiently supported and another photo should not be requested.',
      },
    },
    'species': {
      'type': 'choice',
      'instructions':
          'Which Iris candidate best matches all the available information?',
      'criteria': {
        'monstera_adansonii':
            'Monstera adansonii, typically with many internal fenestrations on relatively narrower leaves.',
        'monstera_deliciosa':
            'Monstera deliciosa, typically with larger mature leaves and edge splits plus fenestrations.',
        'rhaphidophora_tetrasperma':
            'Rhaphidophora tetrasperma, typically smaller leaves with edge splits rather than internal holes.',
        'uncertain': 'The evidence is insufficient to choose safely.',
      },
    },
    'confidence': {
      'type': 'score',
      'instructions':
          'How strong is the combined evidence for a specific identification?',
      'criteria': ['Very uncertain', 'Uncertain', 'Plausible', 'Strong'],
    },
  };

  bool _loading = false;
  String? _result;
  String? _error;

  Future<void> _run() async {
    setState(() {
      _loading = true;
      _result = null;
      _error = null;
    });

    try {
      final json = await JevDecisionService().decide(
        state: _state,
        questions: _questions,
      );
      if (!mounted) return;
      setState(() => _result = const JsonEncoder.withIndent('  ').convert(json));
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final codeStyle = context.text.caption.copyWith(
      color: c.inkSecondary,
      fontFamily: 'monospace',
      height: 1.45,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SheetHeader(title: 'Debug · Jev'),
          Text(
            'Envoie un cas Iris ambigu à ${JevConfig.model} via OpenRouter. '
            'Le test demande à Jev une décision produit unique, puis une '
            'espèce et un score uniquement pour expliquer cette décision.',
            style: context.text.callout,
          ),
          const SizedBox(height: Space.md),
          Text('État envoyé', style: context.text.title3),
          const SizedBox(height: Space.xs),
          SelectableText(
            const JsonEncoder.withIndent('  ').convert(_state),
            style: codeStyle,
          ),
          const SizedBox(height: Space.lg),
          if (!JevConfig.isConfigured)
            Text(
              'OPENROUTER_API_KEY est absente du dart-define de ce build.',
              style: context.text.callout.copyWith(color: c.rose),
            ),
          FloraButton(
            label: _loading ? 'Requête en cours…' : 'Tester Jev',
            expand: true,
            onPressed: _loading || !JevConfig.isConfigured ? null : _run,
          ),
          if (_loading) ...[
            const SizedBox(height: Space.md),
            const Center(child: CircularProgressIndicator()),
          ],
          if (_error != null) ...[
            const SizedBox(height: Space.md),
            Text('Erreur', style: context.text.title3),
            const SizedBox(height: Space.xs),
            SelectableText(_error!, style: codeStyle.copyWith(color: c.rose)),
          ],
          if (_result != null) ...[
            const SizedBox(height: Space.lg),
            Text('Réponse OpenRouter', style: context.text.title3),
            const SizedBox(height: Space.xs),
            SelectableText(_result!, style: codeStyle),
          ],
        ],
      ),
    );
  }
}
