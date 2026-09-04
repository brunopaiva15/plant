import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/identification/plant_identifier.dart';

/// Lance l'identification sur une photo et laisse l'utilisateur choisir.
/// Retourne le candidat retenu, ou `null`.
Future<IdentificationCandidate?> showIdentificationSheet(BuildContext context, {required String absoluteImagePath}) =>
    showFloraSheet<IdentificationCandidate>(context, scrollable: true, builder: (_) => _IdentificationBody(path: absoluteImagePath));

class _IdentificationBody extends ConsumerStatefulWidget {
  const _IdentificationBody({required this.path});

  final String path;

  @override
  ConsumerState<_IdentificationBody> createState() => _IdentificationBodyState();
}

class _IdentificationBodyState extends ConsumerState<_IdentificationBody> {
  late Future<List<IdentificationCandidate>> _future;

  @override
  void initState() {
    super.initState();
    final lang = ref.read(preferencesProvider).locale?.languageCode ?? WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    _future = ref.read(plantIdentifierProvider).identify([File(widget.path)], language: lang);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(title: l10n.identifyTitle),
          FutureBuilder<List<IdentificationCandidate>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: Space.xxl),
                  child: Column(children: [const AdaptiveProgress(), const SizedBox(height: Space.sm), Text(l10n.identifying, style: context.text.callout)]),
                );
              }
              if (snap.hasError) return EmptyState(emoji: '📡', title: l10n.identifyError, compact: true);
              final results = (snap.data ?? const <IdentificationCandidate>[]).take(5).toList();
              if (results.isEmpty) return EmptyState(emoji: '🤔', title: l10n.identifyNone, compact: true);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.identifyHint, style: context.text.caption),
                  const SizedBox(height: Space.sm),
                  FloraGroup(children: [for (final c in results) CandidateRow(candidate: c, onUse: () => Navigator.of(context).pop(c))]),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class CandidateRow extends StatelessWidget {
  const CandidateRow({super.key, required this.candidate, required this.onUse});

  final IdentificationCandidate candidate;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final percent = (candidate.score * 100).round();
    return FloraListRow(
      title: candidate.scientificName,
      subtitle: candidate.commonName,
      leading: SizedBox(
        width: 32,
        height: 32,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CircularProgressIndicator(value: candidate.score.clamp(0, 1), strokeWidth: 3, color: percent >= 50 ? c.sage : c.inkTertiary, backgroundColor: c.surfaceMuted),
            Center(child: Text('$percent', style: context.text.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w700))),
          ],
        ),
      ),
      trailing: FloraButton(
        label: l10n.useThis,
        size: FloraButtonSize.small,
        style: FloraButtonStyle.tonal,
        onPressed: () {
          Haptics.success();
          onUse();
        },
      ),
      chevron: false,
    );
  }
}
