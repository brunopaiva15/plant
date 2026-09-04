import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';

/// Réglage du diagnostic : clé API Claude fournie par l'utilisateur.
class DiagnosisSettingsScreen extends ConsumerStatefulWidget {
  const DiagnosisSettingsScreen({super.key});

  @override
  ConsumerState<DiagnosisSettingsScreen> createState() => _DiagnosisSettingsScreenState();
}

class _DiagnosisSettingsScreenState extends ConsumerState<DiagnosisSettingsScreen> {
  late final _key = TextEditingController(text: ref.read(preferencesProvider).anthropicApiKey);

  @override
  void dispose() {
    _key.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await ref.read(preferencesProvider.notifier).setAnthropicApiKey(_key.text);
    Haptics.success();
    if (mounted) ref.read(toastProvider.notifier).show(ToastData(message: context.l10n.saved));
  }

  @override
  Widget build(BuildContext context) {
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
                Expanded(child: Text(configured ? l10n.diagnosisEnabled : l10n.identificationDisabled, style: context.text.title3)),
              ],
            ),
          ),
          const SizedBox(height: Space.md),
          Text(l10n.diagnosisSettingsHint, style: context.text.callout),
          const SizedBox(height: Space.lg),
          Text(l10n.apiKey, style: context.text.caption),
          const SizedBox(height: Space.xs),
          FloraTextField(controller: _key, hint: l10n.apiKeyHint, textCapitalization: TextCapitalization.none, keyboardType: TextInputType.visiblePassword, onSubmitted: (_) => _save()),
          const SizedBox(height: Space.md),
          FloraButton(label: l10n.save, expand: true, onPressed: _save),
        ],
      ),
    );
  }
}
