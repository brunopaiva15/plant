import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/tokens/motion.dart';

/// Un contrôleur de défilement par onglet, pour qu'un second tap sur
/// l'onglet courant ramène sa liste en haut — ce que fait iOS.
///
/// Chaque branche du shell pose le sien en [PrimaryScrollController] *dans*
/// sa route ([TabScrollScope]) : il passe alors devant celui que la route
/// fournit d'elle-même, si bien que la liste de l'onglet s'y attache sans
/// qu'on le lui dise, et que le tap sur la barre d'état d'iOS — que le
/// `Scaffold` sert avec ce même contrôleur — continue de marcher.
class TabScrolls {
  TabScrolls(int count) : controllers = [for (var i = 0; i < count; i++) ScrollController(debugLabel: 'tab-$i')];

  final List<ScrollController> controllers;

  /// Ramène l'onglet [index] en haut. Rend `true` s'il y avait où remonter.
  bool scrollToTop(BuildContext context, int index) {
    final controller = controllers[index];
    var moved = false;
    // Sans passer par `offset`, qui suppose une seule vue attachée : une
    // page peut en compter d'autres, et chacune remonte.
    for (final position in controller.positions) {
      if (position.pixels <= position.minScrollExtent) continue;
      moved = true;
      final duration = Motion.of(context, Motion.slow);
      if (duration == Duration.zero) {
        position.jumpTo(position.minScrollExtent);
      } else {
        position.animateTo(position.minScrollExtent, duration: duration, curve: Curves.easeOutCirc);
      }
    }
    return moved;
  }

  void dispose() {
    for (final c in controllers) {
      c.dispose();
    }
  }
}

final tabScrollsProvider = Provider<TabScrolls>((ref) {
  final scrolls = TabScrolls(4);
  ref.onDispose(scrolls.dispose);
  return scrolls;
});

/// Pose le contrôleur de l'onglet [index] au-dessus de son écran.
class TabScrollScope extends ConsumerWidget {
  const TabScrollScope({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PrimaryScrollController(controller: ref.watch(tabScrollsProvider).controllers[index], child: child);
  }
}
