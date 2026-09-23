import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/haptics.dart';
import '../core/l10n/l10n.dart';
import '../core/native_shell.dart';
import '../design_system/design_system.dart';
import 'quick_actions.dart';
import 'tab_scroll.dart';

/// Coquille à 4 onglets avec barre flottante. Le contenu passe sous la barre
/// (extendBody) pour le rendu translucide.
///
/// La barre passe debout à droite quand la fenêtre est large sans être celle
/// d'une tablette — un pliable ouvert. Le contenu est alors posé à côté du
/// rail, pas dessous : voir [FloraTabRail.fitsIn].
///
/// C'est aussi le point d'atterrissage de l'application : [QuickActionsHost]
/// y pose les raccourcis de l'icône et exécute celui qui a ouvert
/// l'application.
///
/// Un second tap sur l'onglet courant ramène sa liste en haut, comme sur
/// iOS ; la branche revient aussi à sa racine, pour le jour où elle
/// empilerait quelque chose.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  /// Les boutons que la page ouverte veut voir dans le menu debout. Vide tant
  /// que la barre est en bas : les pages gardent alors leur haut de page.
  final RailActionsSlot _railActions = RailActionsSlot();

  StatefulNavigationShell get shell => widget.shell;

  @override
  void initState() {
    super.initState();
    // Sur iOS, la barre d'onglets est un `UITabBarController` : toucher un
    // onglet ne fait rien tout seul, le natif le dit ici, et c'est go_router
    // qui change de branche. Voir `core/native_shell.dart`.
    if (NativeShell.isSupported) {
      _surOnglet = (i) {
        if (mounted) _select(context, ref, i);
      };
      NativeShell.onTab = _surOnglet;
    }
  }

  /// Ce qu'on a posé sur le canal, pour ne décrocher que le sien.
  void Function(int)? _surOnglet;

  @override
  void dispose() {
    // Une coquille qui s'en va ne décroche que sa propre écoute : la
    // suivante est construite avant que celle-ci ne parte, et effacer sans
    // regarder laisserait les onglets sans réponse.
    if (identical(NativeShell.onTab, _surOnglet)) NativeShell.onTab = null;
    _railActions.dispose();
    super.dispose();
  }

  /// Les onglets, dits au système avec ses propres symboles.
  ///
  /// SF Symbols et non les icônes Cupertino : c'est UIKit qui les dessine, et
  /// il ne connaît que les siens. Les libellés, eux, viennent des ARB comme
  /// partout ailleurs.
  static const List<String> _symboles = ['sun.max', 'square.grid.2x2', 'house', 'person'];

  void _select(BuildContext context, WidgetRef ref, int i) {
    if (i != shell.currentIndex) {
      shell.goBranch(i);
      return;
    }
    // Déjà sur cet onglet. Un second tap remonte sa liste ; ce n'est qu'une
    // fois en haut qu'il revient à la racine de la branche. Les deux dans le
    // même geste se gêneraient : revenir à la racine reconstruit la page, et
    // la remontée n'aurait pas le temps de se jouer.
    if (ref.read(tabScrollsProvider).scrollToTop(context, i)) {
      Haptics.light();
      return;
    }
    shell.goBranch(i, initialLocation: true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tabs = [
      FloraTab(icon: CupertinoIcons.sun_max, activeIcon: CupertinoIcons.sun_max_fill, label: l10n.tabToday),
      FloraTab(icon: CupertinoIcons.square_grid_2x2, activeIcon: CupertinoIcons.square_grid_2x2_fill, label: l10n.tabPlants),
      FloraTab(icon: CupertinoIcons.house, activeIcon: CupertinoIcons.house_fill, label: l10n.tabGarden),
      FloraTab(icon: CupertinoIcons.person, activeIcon: CupertinoIcons.person_fill, label: l10n.tabProfile),
    ];
    // Sur iOS, la chrome part au natif : la pilule en argile ne se dessine
    // plus, et le `UITabBarController` prend sa place. C'est la seule façon
    // qu'iOS la range dans la bande verticale de l'iPhone Duo — il ne déplace
    // pas une barre dessinée par une application, si fidèle soit-elle.
    if (NativeShell.isSupported) {
      NativeShell.publish(
        tabs: [
          for (final (i, tab) in tabs.indexed) NativeTab(title: tab.label, symbol: _symboles[i]),
        ],
        selected: shell.currentIndex,
      );
    }
    // Le relais est posé dans les deux cas : il n'apparaît pas et ne
    // disparaît pas au gré de la taille de la fenêtre, ce qui éviterait aux
    // pages de se redéclarer à chaque pli.
    final content = RailActionsScope(
      slot: _railActions,
      child: QuickActionsHost(child: shell),
    );
    // Fenêtre large sans être une tablette — un pliable ouvert : le menu se
    // met debout à droite, et le contenu prend ce qui reste. Ailleurs, rien
    // ne bouge : la pilule reste en bas.
    // La chrome native se suffit : Flutter ne dessine plus de barre du tout.
    if (NativeShell.isSupported) {
      return Scaffold(backgroundColor: context.colors.canvas, extendBody: true, body: content);
    }
    if (!FloraTabRail.fitsIn(context)) {
      return Scaffold(
        backgroundColor: context.colors.canvas,
        extendBody: true,
        body: content,
        bottomNavigationBar: FloraTabBar(
          index: shell.currentIndex,
          onSelect: (i) => _select(context, ref, i),
          tabs: tabs,
        ),
      );
    }
    return Scaffold(
      backgroundColor: context.colors.canvas,
      extendBody: true,
      body: Row(
        children: [
          // Le rail occupe déjà la marge que le système réserve à droite : la
          // laisser au contenu la compterait deux fois, et les pages
          // s'écarteraient du rail sans raison.
          Expanded(
            child: Builder(
              builder: (ctx) => MediaQuery.removePadding(context: ctx, removeRight: true, child: content),
            ),
          ),
          ListenableBuilder(
            listenable: _railActions,
            builder: (context, _) => FloraTabRail(
              index: shell.currentIndex,
              onSelect: (i) => _select(context, ref, i),
              tabs: tabs,
              actions: _railActions.actions,
            ),
          ),
        ],
      ),
    );
  }
}
