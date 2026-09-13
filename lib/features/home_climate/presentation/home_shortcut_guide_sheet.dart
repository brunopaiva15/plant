import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../core/config/app_config.dart';
import '../application/home_climate_providers.dart';
import '../application/home_shortcut_launcher.dart';
import 'home_climate_widgets.dart';

/// « Capteurs d'un HomePod » : pourquoi HomeKit ne le donne pas, et les quatre
/// gestes dans Raccourcis pour que sa mesure arrive quand même.
Future<void> showHomeShortcutGuide(BuildContext context) => showFloraSheet<void>(context, scrollable: true, builder: (_) => const _GuideBody());

class _GuideBody extends ConsumerWidget {
  const _GuideBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final shortcut = ref.watch(homeShortcutReadingProvider).value;
    final metric = ref.watch(preferencesProvider.select((p) => p.metricUnits));
    // D'un tap quand le raccourci partagé existe ; sinon à la main, en
    // quatre étapes. Dans les deux cas, l'automatisation reste facultative :
    // « Mettre à jour » lance le raccourci depuis ici.
    final steps = HomeShortcut.canAdd
        ? [
            (l10n.homeClimateOneTapStep1Title, l10n.homeClimateOneTapStep1Body(AppConfig.homeShortcutName)),
            (l10n.homeClimateStep4Title, l10n.homeClimateStep4Body),
            (l10n.homeClimateOneTapStep3Title, l10n.homeClimateOneTapStep3Body),
          ]
        : [
            (l10n.homeClimateStep1Title, l10n.homeClimateStep1Body),
            (l10n.homeClimateStep2Title, l10n.homeClimateStep2Body),
            (l10n.homeClimateStep3Title, l10n.homeClimateStep3Body),
            (l10n.homeClimateStep4Title, l10n.homeClimateStep4Body),
          ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(title: l10n.homeClimateGuideTitle),
          Text(l10n.homeClimateGuideWhy, style: context.text.callout),
          const SizedBox(height: Space.lg),
          for (final (i, (title, body)) in steps.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.sm),
              child: FloraCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Le numéro de l'étape, dans une pastille de la couleur de
                    // l'étape « Votre intérieur ».
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: c.sunSoft, shape: BoxShape.circle),
                      child: Text('${i + 1}', style: context.text.callout.copyWith(fontWeight: FontWeight.w700, color: c.ink)),
                    ),
                    const SizedBox(width: Space.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: context.text.title3),
                          const SizedBox(height: 2),
                          Text(body, style: context.text.callout),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: Space.sm),
          FloraGroup(
            children: [
              FloraListRow(
                leading: const Text('⚡️', style: TextStyle(fontSize: 18)),
                title: l10n.homeClimateShortcutLast,
                subtitle: shortcut == null
                    ? l10n.homeClimateShortcutNone
                    : shortcut.error == 'stale'
                        ? l10n.homeClimateShortcutStale
                        : [?shortcut.sensor?.roomName, l10n.homeClimateUpdatedAgo(DateTime.now().difference(shortcut.at).inMinutes)].join(' · '),
                trailing: shortcut == null || shortcut.isEmpty
                    ? null
                    : Text(homeReadingLabel(shortcut, metric: metric), style: context.text.callout.copyWith(color: c.ink, fontWeight: FontWeight.w600)),
                chevron: false,
                onTap: () => ref.invalidate(homeShortcutReadingProvider),
              ),
            ],
          ),
          const SizedBox(height: Space.md),
          if (HomeShortcut.canAdd) ...[
            FloraButton(label: l10n.homeClimateAddShortcut, icon: CupertinoIcons.add, expand: true, onPressed: HomeShortcut.add),
            const SizedBox(height: Space.xs),
          ],
          FloraButton(
            label: l10n.homeClimateRunShortcut,
            icon: CupertinoIcons.arrow_2_circlepath,
            style: HomeShortcut.canAdd ? FloraButtonStyle.tonal : FloraButtonStyle.primary,
            expand: true,
            onPressed: HomeShortcut.run,
          ),
          const SizedBox(height: Space.xs),
          FloraButton(label: l10n.homeClimateOpenShortcuts, style: FloraButtonStyle.ghost, expand: true, onPressed: HomeShortcut.openShortcuts),
        ],
      ),
    );
  }
}
