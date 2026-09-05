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
    final model = ref.watch(localModelStatusProvider);
    final status = model.asData?.value;
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
          const SizedBox(height: Space.sm),
          // Sans cette ligne, rien ne distingue « le modèle a hésité » de
          // « le modèle ne s'est jamais chargé » : les deux donnent zéro
          // identification locale.
          FloraCard(
            child: Row(
              children: [
                EmojiTile(
                  emoji: status?.ready == true ? '📦' : (model.isLoading ? '⏳' : '⚠️'),
                  background: status?.ready == true ? context.colors.sageSoft : null,
                ),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Text(
                    model.isLoading
                        ? l10n.modelLoading
                        : (status != null && status.ready ? l10n.modelLoaded(status.speciesCount) : l10n.modelMissing),
                    style: context.text.callout,
                  ),
                ),
              ],
            ),
          ),
          if (status != null && !status.ready && status.error != null) ...[
            const SizedBox(height: Space.xs),
            // Le message natif, brut : c'est lui qui distingue un asset
            // absent d'une bibliothèque non liée, et il est copiable.
            SelectableText(status.error!, style: context.text.caption),
          ],
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
          Text(l10n.identificationStats(metrics.local, metrics.localAccepted, metrics.remote), style: context.text.caption),
        ],
      ),
    );
  }
}
