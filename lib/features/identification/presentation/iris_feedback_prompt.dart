import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/config/app_config.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';

/// Demande, une seule fois, si les photos identifiées peuvent entraîner Iris.
///
/// Au bon moment — juste après le premier enregistrement d'une plante
/// identifiée, quand la question se comprend — et jamais deux fois : « plus
/// tard » vaut réponse, fermer la feuille aussi. L'interrupteur des réglages
/// d'identification reste là pour changer d'avis, dans les deux sens.
///
/// Un interrupteur que personne ne trouve n'obtient pas de oui ; une
/// demande comprise en obtient. C'est ce qui donne du volume à
/// l'entraînement sans rien prendre par défaut.
Future<void> showIrisFeedbackPrompt(BuildContext context, WidgetRef ref) async {
  final prefs = ref.read(preferencesProvider.notifier);
  // Marquée avant d'ouvrir : quoi qu'il arrive à la feuille, on ne redemande pas.
  await prefs.setIrisFeedbackAsked();
  if (!context.mounted) return;
  final enable = await showFloraSheet<bool>(context, builder: (_) => const _IrisFeedbackPromptView());
  if (enable == true) await prefs.setIrisFeedbackEnabled(true);
}

class _IrisFeedbackPromptView extends StatelessWidget {
  const _IrisFeedbackPromptView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final side = Space.page + readableInset(context);
    void close(bool enable) => Navigator.of(context, rootNavigator: true).pop(enable);
    return Padding(
      padding: EdgeInsets.fromLTRB(side, Space.lg, side, Space.sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.irisFeedbackAskTitle, style: context.text.title2),
          const SizedBox(height: Space.sm),
          Text(l10n.irisFeedbackAskBody(AppConfig.modelName), style: context.text.body.copyWith(color: c.inkSecondary)),
          const SizedBox(height: Space.xl),
          FloraButton(label: l10n.enable, expand: true, onPressed: () => close(true)),
          FloraButton(label: l10n.later, style: FloraButtonStyle.ghost, size: FloraButtonSize.small, onPressed: () => close(false)),
        ],
      ),
    );
  }
}
