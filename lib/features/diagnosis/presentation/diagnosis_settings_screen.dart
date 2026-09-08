import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';

/// Le diagnostic n'a rien à régler : la clé est celle de l'éditeur, fournie
/// au build. L'écran dit seulement si le service est là et où partent les
/// photos.
class DiagnosisSettingsScreen extends ConsumerWidget {
  const DiagnosisSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final configured = ref.watch(plantDiagnoserProvider).isConfigured;
    return FloraPage(
      title: l10n.diagnosisSettings,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FloraCard(
            child: Row(
              children: [
                EmojiTile(emoji: configured ? '🩺' : '🔒', background: configured ? context.colors.sageSoft : null),
                const SizedBox(width: Space.sm),
                Expanded(child: Text(configured ? l10n.diagnosisEnabled : l10n.diagnosisUnavailable, style: context.text.title3)),
              ],
            ),
          ),
          const SizedBox(height: Space.md),
          Text(l10n.diagnosisSettingsHint, style: context.text.callout),
          if (configured) ...[
            const SizedBox(height: Space.lg),
            FloraGroup(
              children: [
                FloraListRow(
                  leading: const Text('📖', style: TextStyle(fontSize: 18)),
                  title: l10n.careAssistSetting,
                  trailing: AdaptiveSwitch(
                    value: ref.watch(preferencesProvider.select((p) => p.careAssistEnabled)),
                    onChanged: (v) => ref.read(preferencesProvider.notifier).setCareAssistEnabled(v),
                  ),
                  chevron: false,
                ),
              ],
            ),
            const SizedBox(height: Space.sm),
            Text(l10n.careAssistHint, style: context.text.caption),
          ],
        ],
      ),
    );
  }
}
