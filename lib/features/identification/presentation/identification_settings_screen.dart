import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';

/// Réglages de l'identification. Rien à configurer : le modèle est embarqué
/// et le service en ligne est fourni avec l'application. L'utilisateur décide
/// seulement si ses photos ont le droit de sortir de l'appareil.
class IdentificationSettingsScreen extends ConsumerWidget {
  const IdentificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final configured = ref.watch(plantIdentifierProvider).isConfigured;
    final metrics = ref.watch(identificationMetricsStoreProvider).read();
    return FloraPage(
      title: l10n.identificationSettings,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FloraCard(
            child: Row(
              children: [
                EmojiTile(emoji: configured ? '🔬' : '🔒', background: configured ? context.colors.sageSoft : null),
                const SizedBox(width: Space.sm),
                Expanded(child: Text(configured ? l10n.identificationEnabled : l10n.identificationDisabled, style: context.text.title3)),
              ],
            ),
          ),
          const SizedBox(height: Space.md),
          Text(l10n.identificationHint, style: context.text.callout),
          const SizedBox(height: Space.lg),
          FloraGroup(
            children: [
              FloraListRow(
                title: l10n.identificationFallback,
                trailing: AdaptiveSwitch(
                  value: ref.watch(preferencesProvider.select((p) => p.identificationFallbackEnabled)),
                  onChanged: (v) => ref.read(preferencesProvider.notifier).setIdentificationFallbackEnabled(v),
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.xs),
          Text(l10n.identificationFallbackHint, style: context.text.caption),
          const SizedBox(height: Space.sm),
          Text(l10n.identificationStats(metrics.localAccepted, metrics.remote, metrics.remoteCallsSaved), style: context.text.caption),
        ],
      ),
    );
  }
}
