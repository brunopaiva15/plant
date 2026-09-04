import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/l10n/l10n.dart';
import '../design_system/design_system.dart';

/// Coquille à 4 onglets avec barre flottante. Le contenu passe sous la barre
/// (extendBody) pour le rendu translucide.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: context.colors.canvas,
      extendBody: true,
      body: shell,
      bottomNavigationBar: FloraTabBar(
        index: shell.currentIndex,
        onSelect: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
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
