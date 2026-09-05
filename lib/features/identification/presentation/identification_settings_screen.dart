import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';

/// Réglage de l'identification : clé Pl@ntNet fournie par l'utilisateur.
class IdentificationSettingsScreen extends ConsumerStatefulWidget {
  const IdentificationSettingsScreen({super.key});

  @override
  ConsumerState<IdentificationSettingsScreen> createState() => _IdentificationSettingsScreenState();
}

class _IdentificationSettingsScreenState extends ConsumerState<IdentificationSettingsScreen> {
  late final _key = TextEditingController(text: ref.read(preferencesProvider).plantNetApiKey);

  @override
  void dispose() {
    _key.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await ref.read(preferencesProvider.notifier).setPlantNetApiKey(_key.text);
    Haptics.success();
    if (mounted) ref.read(toastProvider.notifier).show(ToastData(message: context.l10n.saved));
  }

  @override
  Widget build(BuildContext context) {
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
          Text(l10n.apiKey, style: context.text.caption),
          const SizedBox(height: Space.xs),
          FloraTextField(controller: _key, hint: l10n.apiKeyHint, textCapitalization: TextCapitalization.none, keyboardType: TextInputType.visiblePassword, onSubmitted: (_) => _save()),
          const SizedBox(height: Space.md),
          FloraButton(label: l10n.save, expand: true, onPressed: _save),
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
