import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/haptics.dart';
import '../core/l10n/l10n.dart';
import '../design_system/design_system.dart';
import '../features/whats_new/presentation/whats_new_gate.dart';
import 'quick_actions.dart';
import 'tab_scroll.dart';

/// Coquille à 4 onglets avec barre flottante. Le contenu passe sous la barre
/// (extendBody) pour le rendu translucide.
///
/// C'est aussi le point d'atterrissage de l'application : [WhatsNewGate] y
/// guette une mise à jour et ouvre, le cas échéant, la fenêtre des
/// nouveautés — une fois, au premier rendu. [QuickActionsHost] y pose les
/// raccourcis de l'icône et exécute celui qui a ouvert l'application.
///
/// Un second tap sur l'onglet courant ramène sa liste en haut, comme sur
/// iOS ; la branche revient aussi à sa racine, pour le jour où elle
/// empilerait quelque chose.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  void _select(BuildContext context, WidgetRef ref, int i) {
    final current = i == shell.currentIndex;
    if (current && ref.read(tabScrollsProvider).scrollToTop(context, i)) Haptics.light();
    shell.goBranch(i, initialLocation: current);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: context.colors.canvas,
      extendBody: true,
      body: WhatsNewGate(child: QuickActionsHost(child: shell)),
      bottomNavigationBar: FloraTabBar(
        index: shell.currentIndex,
        onSelect: (i) => _select(context, ref, i),
        tabs: [
          FloraTab(icon: CupertinoIcons.sun_max, activeIcon: CupertinoIcons.sun_max_fill, label: l10n.tabToday),
          FloraTab(icon: CupertinoIcons.square_grid_2x2, activeIcon: CupertinoIcons.square_grid_2x2_fill, label: l10n.tabPlants),
          FloraTab(icon: CupertinoIcons.house, activeIcon: CupertinoIcons.house_fill, label: l10n.tabGarden),
          FloraTab(icon: CupertinoIcons.person, activeIcon: CupertinoIcons.person_fill, label: l10n.tabProfile),
        ],
      ),
    );
  }
}
