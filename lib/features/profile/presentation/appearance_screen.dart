import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';

class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final prefs = ref.watch(preferencesProvider);
    final ctrl = ref.read(preferencesProvider.notifier);
    return FloraPage(
      title: l10n.appearance,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              for (final mode in ThemeMode.values) ...[
                Expanded(
                  child: Pressable(
                    onTap: () => ctrl.setThemeMode(mode),
                    scale: 0.96,
                    child: AnimatedContainer(
                      duration: Motion.of(context, Motion.standard),
                      padding: const EdgeInsets.all(Space.sm),
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: Radii.largeAll,
                        border: Border.all(color: prefs.themeMode == mode ? c.sage : c.line, width: prefs.themeMode == mode ? 2 : 1),
                      ),
                      child: Column(
                        children: [
                          _Preview(mode: mode),
                          const SizedBox(height: Space.xs),
                          Text(
                            switch (mode) { ThemeMode.system => l10n.themeSystem, ThemeMode.light => l10n.themeLight, ThemeMode.dark => l10n.themeDark },
                            style: context.text.caption.copyWith(color: c.ink, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (mode != ThemeMode.dark) const SizedBox(width: Space.sm),
              ],
            ],
          ),
          const SizedBox(height: Space.xl),
          FloraGroup(
            footer: l10n.reduceMotionHint,
            children: [
              FloraListRow(
                title: l10n.reduceMotion,
                trailing: AdaptiveSwitch(
                  value: prefs.reduceMotion ?? MediaQuery.disableAnimationsOf(context),
                  onChanged: (v) => ctrl.setReduceMotion(v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.mode});

  final ThemeMode mode;

  @override
  Widget build(BuildContext context) {
    final light = FloraColors.light;
    final dark = FloraColors.dark;
    Widget half(FloraColors p) => Container(
          color: p.canvas,
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 28, height: 6, decoration: BoxDecoration(color: p.ink, borderRadius: Radii.fullAll)),
              const SizedBox(height: 6),
              Container(height: 22, decoration: BoxDecoration(color: p.surface, borderRadius: Radii.smallAll, border: Border.all(color: p.line))),
              const SizedBox(height: 6),
              Container(width: 26, height: 10, decoration: BoxDecoration(color: p.sage, borderRadius: Radii.fullAll)),
            ],
          ),
        );
    return ClipRRect(
      borderRadius: Radii.mediumAll,
      child: SizedBox(
        height: 72,
        child: switch (mode) {
          ThemeMode.light => half(light),
          ThemeMode.dark => half(dark),
          ThemeMode.system => Row(children: [Expanded(child: half(light)), Expanded(child: half(dark))]),
        },
      ),
    );
  }
}
