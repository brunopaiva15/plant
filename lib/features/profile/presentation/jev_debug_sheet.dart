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
    'identification_reliable': {
      'type': 'noul',
      'instructions':
          'Is the plant identification reliable enough to show as a result?',
      'criteria': {
        'true':
            'The available evidence strongly supports one candidate and displaying it would be reasonable.',
        'false':
            'The candidates remain too ambiguous and another observation would be safer.',
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
    'next_action': {
      'type': 'choice',
      'instructions':
          'What should Auxine do next to minimise a wrong identification?',
      'criteria': {
        'show_result': 'Show the current best species result.',
        'ask_whole_plant_photo':
            'Ask for another photo showing the whole plant.',
        'ask_leaf_closeup':
            'Ask for a close-up showing one mature leaf clearly.',
        'keep_uncertain':
            'Keep the identification explicitly uncertain without requesting another photo.',
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
            'Le test demande à Jev si le résultat est fiable, quelle espèce '
            'choisir et quelle action Auxine devrait prendre ensuite.',
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
